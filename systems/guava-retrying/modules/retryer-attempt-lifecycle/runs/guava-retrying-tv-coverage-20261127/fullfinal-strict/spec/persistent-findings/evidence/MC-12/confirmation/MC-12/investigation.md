# MC-12 — Phase 1 investigation (evidence only)

Finding: the first per-attempt timeout ends `Retryer.call` with `ExecutionException(UncheckedTimeoutException)` unless the user's rejection predicate matches Guava's exception class; the stop and wait strategies are never consulted. Source: model checking, invariant `TimeoutDoesNotEndCallWithExecutionException`, counterexample `spec/output/hunt_s4_shutdown_k29.out` (11 states, `MCHunt.tla`, derived cfg `hunt/s4_shutdown-k29.cfg` from `MC_hunt_s4_shutdown.cfg`). Ledger row D-14.

Code under review: worktree `177b6c9b9f3e7957f404f0bdb8e23374cb1de43f` (= `v2.0.0` + Travis workaround = upstream `master` HEAD, checked via `gh api repos/rholder/guava-retrying/commits`). Guava 22.0 sources: `/home/ubuntu/scratch/guava22-sources-dl/guava-22.0-sources.jar` (sha256 `6dc28492…`); runtime jar `~/.m2/repository/com/google/guava/guava/22.0/guava-22.0.jar`, SHA1 `3564ef3803de51fb0530a8377ec6100b33b0d073` (matches the Maven `.sha1`).

## Persistent-findings lookup

`specular findings --work .specular-output lookup --query UncheckedTimeoutException --query TimeoutDoesNotEndCallWithExecutionException --query "fixedTimeLimit timeout ExecutionException"` → `[]` (no prior record).

## Step 1 — Code audit

### Cited sites

- `src/main/java/com/github/rholder/retry/Retryer.java:159-164` — every outcome of `attemptTimeLimiter.call(callable)` other than a value, including the limiter's own timeout, becomes `new ExceptionAttempt<V>(t, …)` (`:162-163`). Nothing distinguishes "the callable threw" from "the limiter gave up on the attempt".
- `Retryer.java:166-168` — listeners see the timeout as an ordinary exception attempt.
- `Retryer.java:170-171` — `if (!rejectionPredicate.apply(attempt)) { return attempt.get(); }`. For an `ExceptionAttempt`, `get()` throws `new ExecutionException(cause)` (`Retryer.java:253-262`). This exit happens before `stopStrategy.shouldStop` (`:173`) and `waitStrategy.computeSleepTime` (`:176`).
- `src/main/java/com/github/rholder/retry/AttemptTimeLimiters.java:105-108` — `FixedAttemptTimeLimit.call` → `timeLimiter.callWithTimeout(callable, duration, timeUnit, true)` on a Guava `SimpleTimeLimiter` (`:89-95`).
- Guava 22.0 `com/google/common/util/concurrent/SimpleTimeLimiter.java:142-168` — `executor.submit(callable)`, `future.get(timeout)`; on `TimeoutException`: `future.cancel(true); throw new UncheckedTimeoutException(e);` (`:164-166`). `UncheckedTimeoutException extends RuntimeException`.
- `src/main/java/com/github/rholder/retry/RetryerBuilder.java:39` — default `rejectionPredicate = Predicates.alwaysFalse()`; `:153-157` `retryIfExceptionOfType(c)` ORs in `ExceptionClassPredicate(c)`, which is `c.isAssignableFrom(attempt.getExceptionCause().getClass())` (`:207-213`). For `c = IOException.class` and cause `UncheckedTimeoutException`, it is `false`.

### Call chain (public API → site)

`RetryerBuilder.newBuilder().withAttemptTimeLimiter(AttemptTimeLimiters.fixedTimeLimit(d, unit[, executor]))…build()` (`RetryerBuilder.java:118-122,190-197`) → `Retryer.call(callable)` (`Retryer.java:155`) or `Retryer.wrap(callable).call()` (`Retryer.java:195-197,317-318`) → `FixedAttemptTimeLimit.call` (`AttemptTimeLimiters.java:106-107`) → `SimpleTimeLimiter.callWithTimeout(…, true)` → timeout → `UncheckedTimeoutException` → `Retryer.java:162-163` → `:170-171` → caller receives `ExecutionException(UncheckedTimeoutException)`.

Reachability: normal usage. Any attempt that runs longer than the configured limit takes this path; so does an attempt whose worker has not started when the limit expires (the CE's interleaving — `SimpleTimeLimiter`'s own Javadoc, `SimpleTimeLimiter.java:56-58`, says "the call may even time out before the target method is ever invoked").

### Trigger scenario

1. User builds `fixedTimeLimit(200 ms)` + `retryIfExceptionOfType(IOException.class)` + `stopAfterAttempt(5)` + `fixedWait(50 ms)`.
2. Attempt 1 stalls past 200 ms (or its worker has not started yet).
3. `SimpleTimeLimiter` cancels the future with interrupt and throws `UncheckedTimeoutException`.
4. `Retryer.java:162-163` records an `ExceptionAttempt`; listeners run; the predicate does not match `UncheckedTimeoutException`; `Retryer.java:171` throws `ExecutionException(UncheckedTimeoutException)`.
5. `stopAfterAttempt(5)` and `fixedWait` are never called; no second attempt is made even though the stop strategy permits four more.

Same outcome with no `retryIf` at all (default `alwaysFalse`), which is the configuration reported in upstream #29.

### Safeguards / masks encountered

- A predicate that happens to match `UncheckedTimeoutException` (`retryIfException()`, `retryIfRuntimeException()`, or explicitly `retryIfExceptionOfType(UncheckedTimeoutException.class)`) makes the timeout retried. The maintainer says in #29 that these catch-all predicates "mask this behavior". This only covers configurations outside the finding's precondition; nothing in the library makes the timeout retried for a predicate that does not match Guava's exception class.
- No downstream mechanism retries after `call()` throws; the outcome is final for that call.

### Counterexample mapping (`hunt_s4_shutdown_k29.out`)

| CE state | Action | Code |
|---|---|---|
| 2 | `MCCallStart(c1)` | `Retryer.java:155-160`, attempt 1 |
| 3 | `MCSubmitNewWorker(c1,t1,w1)` — a new worker gets task `t1`; `tbody[t1] = NotStarted` | `SimpleTimeLimiter.java:149` → `ThreadPoolExecutor.addWorker` (cached pool) |
| 4 | `MCGetTimeout(c1)` — `curTag = "Timeout"` | `SimpleTimeLimiter.java:154` times out |
| 5-7 | `MCCancelCASWon` / `MCCancelReadRunner` (runner = `NoWorker`) / `MCCancelFinish` (`tstate[t1] = INTERRUPTED`) | `SimpleTimeLimiter.java:165` `future.cancel(true)` on a not-yet-run task |
| 8-10 | `MCListenersBegin` / `MCListenerNotify` / `MCListenersEnd` | `Retryer.java:162-168` |
| 11 | `MCPredicateAccepts(c1)` — `outcome = "ExecExc"`, `exitInfo.tag = "Timeout"`, `count = 1` | `Retryer.java:170-171` |

In the CE the callable never runs (`tbody[t1]` stays `NotStarted`); stop/wait are not reached.

## Step 2 — Developer-knowledge evidence (verbatim)

- `Retryer.call` Javadoc, `Retryer.java:141-153`: "If the rejection predicate accepts the attempt, the stop strategy is used to decide if a new attempt must be made." / "@throws ExecutionException if the given callable throws an exception, and the rejection predicate considers the attempt as successful. The original exception is wrapped into an ExecutionException." / "@throws RetryException if all the attempts failed before the stop strategy decided to abort, or the thread was interrupted."
- `RetryerBuilder.withAttemptTimeLimiter`, `RetryerBuilder.java:112-116`: "Configures the retryer to limit the duration of any particular attempt by the given duration." / "@param attemptTimeLimiter to apply to each attempt".
- `Retryer` constructor, `Retryer.java:73`: "@param attemptTimeLimiter to prevent from any single attempt from spinning infinitely".
- `AttemptTimeLimiter`, `AttemptTimeLimiter.java:22`: "A rule to wrap any single attempt in a time limit, where it will possibly be interrupted if the limit is exceeded."
- README (`README.md:53-56`): "If any other `Exception` pops out of the `call()` method it's wrapped and rethrown in an `ExecutionException`." The README never mentions time limits.
- Existing test `src/test/java/com/github/rholder/retry/AttemptTimeLimiterTest.java:32-50` (dirkraft, 2013): a retryer with only `fixedTimeLimit(1, SECONDS)` and no `retryIf` is asserted to throw `ExecutionException` whose cause is `UncheckedTimeoutException`. This asserts the current outcome for the no-predicate configuration; it predates #29.
- Upstream issue #29 "Retry following timeout", https://github.com/rholder/guava-retrying/issues/29 — open, label `bug`, reported 2015-01-17 against 1.0.6. Reporter: "any exception thrown by the `AttemptTimeLimiter` will cause `Retryer` to abort … The `Retryer` produced here will not retry an operation if it times out after one minute. I would have expected it to wait for 10 seconds and try again, until the time limit of 15 minutes was reached." Workaround named: `retryIfExceptionOfType(UncheckedTimeoutException.class)`, "unintuitive and dependent on the implementation of `AttemptTimeLimiter` used".
  - Maintainer rholder, 2015-05-02 (https://github.com/rholder/guava-retrying/issues/29#issuecomment-98264665): "I agree with your assessment and would also consider it a bug, too, since the documentation seems to indicate it would affect a single `Attempt` without really noting that its failure is tied to any `Exception` that might pop out. Without explicit handling of `com.google.common.util.concurrent.UncheckedTimeoutException` (or maybe more loosely any `RuntimeException`) the `Retryer` effectively stops retrying instead of giving up on the attempt and trying again. Catchall `retryIfException()` or `retryIfRuntimeException()` retrying appears to mask this behavior as well."
  - dirkraft (author of `AttemptTimeLimiter`), 2015-05-04 (https://github.com/rholder/guava-retrying/issues/29#issuecomment-98777141): "If I understand correctly, the attempt timeout should at a minimum behave like any other exception thrown by an attempt, and be subject to the exception-related retryer configuration."
- Blame: `Retryer.java:159-164` structure dates from `fbe31777` (2013-06-06) / `7e474be7` (dirkraft, 2013-01-16). `git show v1.0.6:…/Retryer.java` has the identical `try { attemptTimeLimiter.call } catch (Throwable t) { ExceptionAttempt }` → `if (!rejectionPredicate.apply(attempt)) return attempt.get();` sequence; `AttemptTimeLimiters.java` changed only in its copyright line between `v1.0.6` and `v2.0.0`.

## Step 3 — Known-status

Tracker searches run 2026-11-26 with `gh`: issues + PRs for "timeout", "UncheckedTimeoutException", "AttemptTimeLimiter", "time limit", "timed out", "TimeLimiter"; full PR list (`--state all`, 45 PRs, newest #107 closed unmerged 2026-09-05 — a PHP port, unrelated). No merged or open PR changes timeout handling; upstream `master` HEAD is still `177b6c9`.

Result: KNOWN — https://github.com/rholder/guava-retrying/issues/29 reports this mechanism at this site (the limiter exception is judged by the user's predicate and `Retryer.call` aborts with it). fix-status: unfixed.

Pre-filter: not applied — the finding is MC-sourced with an actual counterexample, so it proceeds to Phase 2.

## Repair round 1 continuation (2026-11-26, ~17:00 UTC)

The Phase 3 conformance result after repair round 1 still lists this finding with the same analysis and the same counterexample `spec/output/hunt_s4_shutdown_k29.out`. This section records what was re-checked; the evidence above stands except where corrected below.

- Source: worktree HEAD `177b6c9b9f3e7957f404f0bdb8e23374cb1de43f`, 0 dirty files. `Retryer.java:155-185`, `:248-262`, `:317-318`, `RetryerBuilder.java:39,113-122,153-157,207-213`, `AttemptTimeLimiter.java:22`, `AttemptTimeLimiters.java:83-109`, `AttemptTimeLimiterTest.java:32-50` and Guava 22.0 `SimpleTimeLimiter.java:56-58,142-168` (sources jar sha256 prefix `6dc2849225ae048b`) re-read; all cited lines unchanged.
- Model artifacts (metadata only; spec files not opened per the worker scope): the CE `spec/output/hunt_s4_shutdown_k29.out`, `spec/MCHunt.tla` and the derived cfg `spec/hunt/s4_shutdown-k29.cfg` all have mtime 08:22 UTC, before the first confirmation (10:14-10:17), so they are the same files the first round mapped. `spec/MC_hunt_s4_shutdown.cfg` was modified at 12:28 UTC during repair round 1; it is the base cfg, not the derived cfg that produced this CE. The CE still shows the same 11 states (`MCCallStart` … `MCPredicateAccepts`), invariant `TimeoutDoesNotEndCallWithExecutionException`, and final `outcome = "ExecExc"`, `exitInfo = [tag |-> "Timeout", count |-> 1, invoked |-> FALSE]`, `tbody[t1] = "NotStarted"`.
- Upstream status re-checked with `gh` at ~17:00 UTC: #29 `state=open`, label `bug`, `closed_at=null`; upstream `master` HEAD still `177b6c9` (2016-05-10); newest PR #107 "Modernize" closed unmerged 2026-09-05 — its file list deletes `src/main/java/com/github/rholder/retry/*.java` and adds `src/tagadvance/elephant/retry/*.php`, confirming the earlier "PHP port, unrelated" note. fix-status: unfixed.
- Reproduction re-executed at 2026-11-26T16:58:42Z with the unchanged script (sha256 `6d7fd74e…`): `OVERALL: PASS (bug triggered in 5/5 runs)`, S1/S2/S3 `=> BUG` and C1/C2 `=> control OK` in every run, script exit status 0. Log: `repro/MC-12.log` (sha256 `cc40a7b0c1eb5084557d0e9561cc855c9bc9aa60a9f98e007ea4c14e3b56960e`), replacing the first-round log, whose S1-S3/C1-C2 outcomes were identical.

Corrections to earlier statements:

- The first-round verdict body introduced its pasted output as "以下是第 1 次运行的原始输出" (the raw output of run 1). It was a hand-selected excerpt: it dropped the provenance header and, among others, the S1-S3/C1-C2 heading and `config:` lines, the S1 `the delayed worker has processed the attempt's FutureTask` line, and several `listener.onRetry` lines. The outcomes it showed were real; the label was wrong. The round-1 report pastes run 1 unfiltered and marks any excerpt explicitly.
- Precision on the reachability note in Step 1: Guava's `SimpleTimeLimiter.java:56-58` mentions a timeout "before the target method is ever invoked" in the context of a bounded executor that fills up. The CE step `MCSubmitNewWorker` (a new worker holds the task, `tbody[t1] = NotStarted`) is instead the case of an unbounded cached pool whose new thread has not started yet; S1 reaches it that way (user `ThreadFactory` delaying thread start). The Javadoc shows Guava admits pre-invocation timeouts, but S1, not that sentence, demonstrates the CE shape.
