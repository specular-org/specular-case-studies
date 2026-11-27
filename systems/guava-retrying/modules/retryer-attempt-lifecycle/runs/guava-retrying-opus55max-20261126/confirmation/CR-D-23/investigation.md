# CR-D-23 — Phase 1 investigation (evidence record)

Finding: `RetryException` is `Serializable` but holds a non-transient `Attempt` whose implementations are not serializable. Source: code review (ledger row D-23, no MC counterexample, no Scenario). Checked source: worktree at `177b6c9` (= upstream `rholder/guava-retrying` default-branch HEAD, 2016-05-10, i.e. the 2.0.0 code line).

## Persistent-findings lookup (before analysis)

`specular findings --work <.specular-output> lookup --query RetryException --query Serializable --query lastFailedAttempt --query NotSerializableException --query ExceptionAttempt` → `[]`. No prior Specular record for this defect.

## Step 1 — Code audit

Cited code (verified in the worktree):

- `src/main/java/com/github/rholder/retry/RetryException.java:31-35`
  ```java
  @Immutable
  public final class RetryException extends Exception {     // :32  -> Throwable implements Serializable
      private final int numberOfFailedAttempts;
      private final Attempt<?> lastFailedAttempt;           // :35  non-transient
  ```
  Constructor `RetryException(String, int, Attempt<?>)` (`:56-60`) stores the attempt in that field and sets the attempt's exception (if any) as the `Throwable` cause. No `serialVersionUID`, `writeObject`, `writeReplace`, or `transient` anywhere in `src/main` (`grep -rn "Serializable\|transient\|serialVersionUID" src/main` → none).
- `src/main/java/com/github/rholder/retry/Attempt.java:28` — `public interface Attempt<V>` does not extend `Serializable`.
- `src/main/java/com/github/rholder/retry/Retryer.java:199-200` — `@Immutable static final class ResultAttempt<R> implements Attempt<R>` (fields `R result`, `long attemptNumber`, `long delaySinceFirstAttempt`); not `Serializable`.
- `src/main/java/com/github/rholder/retry/Retryer.java:247-248` — `@Immutable static final class ExceptionAttempt<R> implements Attempt<R>` (fields `ExecutionException e`, two longs); not `Serializable`.

Call chain (public API → cited code):

- `Retryer.call(Callable)` (`Retryer.java:155`) builds each attempt as `new ResultAttempt<V>(...)` (`:161`) or `new ExceptionAttempt<V>(...)` (`:163`); these are the only `Attempt` implementations in the library.
- When the stop strategy stops: `throw new RetryException(attemptNumber, attempt)` (`:174`); when the block step is interrupted: same (`:181`).
- `Retryer.RetryerCallable.call()` (`:317-318`, from `Retryer.wrap`) delegates to `call()`; when submitted to an `ExecutorService`, `Future.get()` throws `ExecutionException` whose cause is that `RetryException`.

Reachability: every `RetryException` the library throws carries a `Retryer$ResultAttempt` or `Retryer$ExceptionAttempt`. Normal usage reaches it: any `call()` that ends with the stop strategy stopping, or an interrupt during the wait.

Trigger scenario: a caller lets a `RetryException` (or an `ExecutionException`/wrapper whose cause chain contains it) cross a Java-serialization boundary, e.g. an RMI method declaring/propagating it, a remote task framework that ships task failures between JVMs, session replication, or a plain `ObjectOutputStream.writeObject(e)`. Default serialization walks the non-transient `lastFailedAttempt` field and throws `java.io.NotSerializableException: com.github.rholder.retry.Retryer$ExceptionAttempt` (or `$ResultAttempt` when the last attempt had a rejected result).

Safeguards encountered: none in the library. A consumer could catch the serialization failure, but no library code does.

Pre-existing analysis-stage evidence for this finding (not a Phase-2 reproduction): `analysis-evidence/probes/main/SerProbe.java` (a 2-attempt `retryIfException` retryer whose callable throws `IOException`, then `ObjectOutputStream.writeObject(e)`), log `analysis-evidence/probes/main/SerProbe_.jdk21.log`:
```
NotSerializableException: com.github.rholder.retry.Retryer$ExceptionAttempt
exit=0
```

## Step 2 — Developer-knowledge search

Upstream issue tracker (`rholder/guava-retrying`), fetched via `gh api --paginate` on 2026-11-26:

- All 106 issues/PRs in every state (numbers up to #107), 185 issue comments, and 5 PR review comments were grepped for `serializ`, `notserializ`, `transient`, `rmi `, `ExceptionAttempt`, `ResultAttempt`, and `lastFailedAttempt`. No issue, PR, or comment mentions serialization.
- Keyword hits unrelated to serialization: PR #78 "Make ExceptionAttempt and ResultAttempt public" (closed 2023-04-18, **not merged**, about visibility only) and issue #65 "Any interest in a Future's retryer?" (open, a feature proposal).
- `gh search issues --repo rholder/guava-retrying` for `serializ`, `Serializable`, `NotSerializableException`, `ResultAttempt`, `lastFailedAttempt`, `transient`, and `RMI` returned no hits. `ExceptionAttempt` matched only #65.
- Recently merged/closed PRs: upstream default-branch HEAD is still `177b6c9b9f` (2016-05-10). The latest file-level commits on `RetryException.java` (`a5a069f6e6`, 2015-01-21) and `Retryer.java` (`37449897bd`, 2015-06-22) predate 2.0.0. No fix landed upstream.

Commits / blame: `git blame -L 31,35 RetryException.java` attributes the class declaration and both fields to `6d2d838b` (Ray Holder, 2012-11-17, "update package, clean up some Javadoc"; the code came from the original JB import `c531b61`). No commit message in the history (`git log --all -i --grep=serializ`) mentions serialization.

Comments / docs: `RetryException`, `ResultAttempt`, and `ExceptionAttempt` are annotated `@Immutable`. `README.md:55` says the stop path throws "a `RetryException` that contains information about the last failed attempt", so carrying the attempt is intended. No doc or comment says anything about serialization.

Tests: `RetryerBuilderTest` asserts `getLastFailedAttempt()` contents (e.g. `:155-156`, `:330-331`). No test serializes a `RetryException`.

GitHub-wide search: `"Retryer$ExceptionAttempt"` (14 hits) and `"Retryer$ResultAttempt"` (1 hit) are stack traces in unrelated projects (Graylog2, TypeDB, Netflix conductor, ...). Their bodies and comments were checked, and none mentions serialization. `NotSerializableException RetryException rholder` and `"RetryException" serializable guava-retrying` returned nothing.

## Step 3 — Known-status / precedent

Existing public report of this exact defect: **https://github.com/rhuffman/re-retrying/issues/40** — "RetryException is not serializable bc Attempt is not", opened 2019-05-31 by eschultink, **open**, with one comment (2021-04-05, jgiardin: "I am experiencing this serialization issue as well"). Body (verbatim excerpt): "`RetryException` implements `Serialzable`, but does not fulfill the contract, because it has a field `Attempt<>` [link: `src/main/java/com/github/rholder/retry/RetryException.java#L32-L34` @ `5c75a68`] which does not implement `Serializable` [link: `Attempt.java#L30-L38`]". It proposes making `Attempt` `Serializable` or the field `transient`.

Why this is the same mechanism at the same site, not a same-shape precedent elsewhere:

- `rhuffman/re-retrying` is a declared fork of guava-retrying. Its README says "This is a fork of the guava-retrying library", and its history contains upstream HEAD: `git merge-base --is-ancestor 177b6c9b9f 5c75a68` succeeds, and the fork has tag `v2.0.0`.
- The lines issue #40 links are inherited unchanged from guava-retrying. `git blame -L 31,34 5c75a68 -- RetryException.java` in the fork attributes `@Immutable` / `public final class RetryException extends Exception {` / `private final Attempt<?> lastFailedAttempt;` to the same upstream commit `6d2d838b` that `git blame` assigns to guava-retrying 2.0.0 `RetryException.java:31-35`.
- The mechanism is the same: a `Serializable` exception holds a non-transient `Attempt` reference whose runtime type is not `Serializable`. The only difference is the secondary site. The fork later merged the two implementations into one concrete `Attempt` class, whereas 2.0.0 has `Retryer$ResultAttempt` and `Retryer$ExceptionAttempt` (`Retryer.java:199-200`, `247-248`). Neither implements `Serializable`, so the reported cause applies to 2.0.0 unchanged. The ledger row D-23 already records this report ("Not reported upstream; reported against the fork rhuffman/re-retrying#40 (open)").
- Fix status: **unfixed**. The issue is still open. Fork HEAD is still `5c75a68` (the commit the issue links), and its `src/main` has no `Serializable`/`transient`. Upstream HEAD `177b6c9` is unchanged.

None of the target's listed upstream incidents (#48, #92, #29, #67, #94) covers this. Prior Specular dataset entry: none.

Pre-filter outcome: code-review-sourced AND an existing public issue already reports THIS exact defect (same mechanism, same inherited field and class lines) → **Status: DROPPED (code-review × known, cite: https://github.com/rhuffman/re-retrying/issues/40)**. Novelty: `KNOWN (cite: https://github.com/rhuffman/re-retrying/issues/40; fix-status: unfixed)`. Per the skill, Phase 2 is skipped, no `repro/test_bugCR-D-23_*` is written, and no `issue.json` is proposed, because persistent records cover only unresolved REPRODUCED/ENV_LIMITED/MASKED findings.
