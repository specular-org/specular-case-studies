# MC-5 — Investigation (Phase 1, evidence only)

Finding: without a time limit, an `InterruptedException` thrown by the callable on the caller thread is retried and the interrupt status is lost. Source: model checking (S2 `noTimeLimit`, ledger D-6), real counterexamples `spec/output/hunt_s2_interrupt_nolimit_bfs1.out` (NoRetryAfterObservedInterrupt, 11 states) and `spec/output/hunt_s2_interrupt_nolimit_bfs2.out` (InterruptPreserved, 16 states).

Source checked: `confirmation/MC-5/worktree` at `177b6c9` (= upstream `rholder/guava-retrying` master HEAD, release 2.0.0 + a travis tweak; `git status` clean). The live upstream `Retryer.java` lines 155-185 fetched via the GitHub API are byte-identical to the worktree.

## Step 1 — Code audit

### Cited code

- `AttemptTimeLimiters.java:75-80` — `NoAttemptTimeLimit.call` is `return callable.call();`: the callable runs on the thread that called `Retryer.call`, so an interrupt of that thread reaches the callable directly.
- `RetryerBuilder.java:191` — `build()` uses `AttemptTimeLimiters.noTimeLimit()` when no limiter is configured, i.e. this is the default path for every `Retryer` built without `withAttemptTimeLimiter`.
- `Retryer.java:159-164` — the attempt is wrapped in `try { ... } catch (Throwable t) { attempt = new ExceptionAttempt<V>(t, ...); }`. An `InterruptedException` from the callable is recorded as an ordinary failed attempt. Nothing re-asserts `Thread.currentThread().interrupt()` and nothing checks `Thread.interrupted()`/`isInterrupted()` here.
- `Retryer.java:166-168` — listeners notified (no interrupt check).
- `Retryer.java:170-172` — if the rejection predicate does not reject, `attempt.get()` returns the result or throws `ExecutionException(cause)`.
- `Retryer.java:173-174` — stop strategy; `RetryException` if it says stop.
- `Retryer.java:176-182` — otherwise `blockStrategy.block(sleepTime)`; ONLY here is `InterruptedException` translated to `Thread.currentThread().interrupt(); throw new RetryException(...)`.
- `BlockStrategies.java:45-46` — the default block is `Thread.sleep(sleepTime)`; it throws only if the interrupt flag is still set (or a new interrupt arrives during the sleep).
- `RetryerBuilder.java:130-133` — `retryIfException()` = `ExceptionClassPredicate(Exception.class)`, which matches `InterruptedException` (`RetryerBuilder.java:208-213`). `retryIfExceptionOfType(InterruptedException.class)` / `retryIfException(Predicate)` can also match it.

### Call chain (public entry points → site)

`Retryer.call(Callable)` (public, `Retryer.java:155`) or `Retryer.wrap(callable).call()` (`RetryerCallable.call`, `Retryer.java:317-318`, intended for submission to an executor) → `attemptTimeLimiter.call(callable)` (`Retryer.java:160`) → `NoAttemptTimeLimit.call` → `callable.call()` (`AttemptTimeLimiters.java:78`) → user code blocks in an interruptible JDK call (`Thread.sleep`, `BlockingQueue.take`, `Object.wait`, `Future.get`, `CountDownLatch.await`, `Lock.lockInterruptibly`, ...).

Reachability: normal usage. A builder with only `retryIfException()` and the defaults (`noTimeLimit`, `neverStop`, `noWait`, `threadSleepStrategy`) reaches it. Interrupts are the JDK's standard cancellation signal (`Future.cancel(true)`, `ExecutorService.shutdownNow()`, `Thread.interrupt()`).

### Trigger scenario

1. Thread T calls `retryer.call(callable)` on a retryer built with `retryIfException()` and a stop strategy that allows ≥ 2 attempts (default `neverStop`), default `noTimeLimit`/`noWait`.
2. Attempt 1: the callable blocks in an interruptible call (e.g. `queue.take()`).
3. Another thread interrupts T (directly, or via `Future.cancel(true)` / `shutdownNow()`).
4. The JDK clears T's interrupt status and throws `InterruptedException`; the callable propagates it (`Callable.call() throws Exception`).
5. `Retryer.java:162-163` records it as `ExceptionAttempt`; the predicate rejects; the stop strategy continues; `Thread.sleep(0)` does not throw because the status is now clear (`Retryer.java:178`).
6. Attempt 2 runs. If it returns a value, `call()` returns it normally with T's interrupt status clear; if it blocks again, T is stuck in the new attempt and the cancellation has been consumed.

Matches the TLC trace: bfs2 states 2 `MCCallStart` → 3 `MCCallerBodyStart(c1,"IntrBlock")` → 4 `MCInterrupt(c1)` (`intr[c1]=TRUE`, `intrDelivered=TRUE`) → 5 `MCCallerBodyThrows(c1)` (`curTag="CallableIE"`, `intr[c1]=FALSE`) → 6-8 listeners → 9 `MCWaitStrategyComputes(c1,"Zero")` → 10 `MCBlockZero(c1)` (`attemptNo=2`) → 11 `MCCallerBodyStart(c1,"Ret")` → 12 `MCCallerBodyReturns` → 13-15 listeners → 16 `MCPredicateAccepts` (`outcome="Returned"`, `intr[c1]=FALSE`, `intrDelivered=TRUE`) ⇒ InterruptPreserved violated. bfs1 is the same prefix with body `"IntrRet"`, stopping at state 11 (attempt 2 starts after the interrupt was observed) ⇒ NoRetryAfterObservedInterrupt violated.

### Safeguards encountered (recorded, to be tested in Phase 2)

- `Retryer.java:179-181` restores the status and throws `RetryException`, but only for an `InterruptedException` thrown by `blockStrategy.block`. With the status already cleared by the callable's IE, `Thread.sleep(0)`/`Thread.sleep(n)` does not throw, so this guard does not fire on this path.
- No listener/stop/wait built-in checks the interrupt status.
- A stop strategy that stops after attempt 1 would end the loop with `RetryException`, but the status would still be clear (variant, not a mask of the status loss).
- A predicate that does not match `InterruptedException` (e.g. `retryIfRuntimeException()`) ends the call with `ExecutionException(InterruptedException)` and the status clear (same catch-all, no retry).

## Step 2 — Developer-knowledge search

### Comments / docs (verbatim)

- `Retryer.java:59-61` (also 76-78, 94-96, 113-115), constructor `rejectionPredicate` param: "If an attempt is rejected, the retryer will retry the call, unless the stop strategy indicates otherwise or the thread is interrupted."
- `Retryer.java:151-153`, `call()`: "@throws RetryException if all the attempts failed before the stop strategy decided to abort, or the thread was interrupted. Note that if the thread is interrupted, this exception is thrown and the thread's interrupt status is set."
- `RetryerBuilder.java:124-129` `retryIfException()`: "retry if an exception (i.e. any `Exception` or subclass of `Exception`) is thrown by the call." (no carve-out for `InterruptedException` in the builder doc; the carve-out is in the `Retryer` docs above).
- `AttemptTimeLimiter.java:22`: "A rule to wrap any single attempt in a time limit, where it will possibly be interrupted if the limit is exceeded." (not about caller interrupts).

### Commits / blame

- The interrupt contract text and the `catch (Throwable t)` both come from the original import `c531b61` (2012-08-26, "Adding original source code from JB"); in that version the only interrupt handling was already `Thread.sleep` → `interrupt(); throw new RetryException(...)`. `fbe3177` (2013-06-06) only reformatted the catch; `7e474be` (2013-01-16) introduced `attemptTimeLimiter.call(callable)` in place of `callable.call()`; `5cc1018` (2014-03-15) reformatted the Javadoc. No commit message discusses interrupts thrown from the callable. `git log --all | grep -i interrupt` → nothing.

### Tests

- `RetryerBuilderTest.java:384-414` `testInterruption`: interrupt arrives during the inter-attempt wait (`fixedWait(1000ms)`, callable returns null and `retryIfResult(isNull)`); asserts `RetryException`, `!e.getLastFailedAttempt().hasException()`, `e.getCause()==null`, and `Thread.currentThread().isInterrupted()`. This encodes the documented contract (RetryException + status set). No test covers an interrupt delivered while the callable runs, nor a callable that throws `InterruptedException`.

### Issue tracker (searched 2026-11-26)

- `rholder/guava-retrying` (upstream, inactive since 2016-05-10, HEAD `177b6c9`): `gh search issues --repo rholder/guava-retrying interrupt` and `InterruptedException` → only #63 ("Why WaitStrategy use BlockStrategy#block to sleep ?", about block implementations that don't sleep — unrelated). `gh search prs` for `interrupt` → none. Full listing of all 106 issues/PRs (open + closed, incl. recently closed PRs #84 2026-09-20 and #107 "Modernize" 2026-09-05, which was opened by mistake and closed unmerged) → no report of this mechanism. #67 ("Retryer.call should not catch Errors like OOME", open) is the same `catch (Throwable)` site but a different mechanism (Errors, not interrupts). #101 (open PR, "Not calling Thread.sleep() if sleepTime is Zero") is unrelated (and would remove even the zero-sleep interrupt check if merged).
- Hard fork `rhuffman/re-retrying` (announced in upstream #81 by its maintainer; same package and file `src/main/java/com/github/rholder/retry/Retryer.java`):
  - https://github.com/rhuffman/re-retrying/issues/32 (2018-02-09, nseniak, closed as dup of #24): "Thread interruption when executing the callback is not propagated … The doc of rejectionPredicates would lead to think that if the thread is interrupted during the execption of the callback, the call won't be retried … However, this is not the case." Maintainer: "Thanks, and I agree."
  - https://github.com/rhuffman/re-retrying/issues/36 (2018-07-11, rhuffman): "InterruptedException thrown by a Callable is not handled correctly … if the Callable being retried is in a method that throws and InterruptedException when the interrupt happens, retry will not throw an InterruptedException."
  - Fixed only in the fork by https://github.com/rhuffman/re-retrying/pull/37 (merged 2018-07-11, commit `f1ff0bf`): adds `} catch(InterruptedException e) { throw e; }` before `catch (Throwable t)` in `Retryer.call`. Never ported to `rholder/guava-retrying`.
- GitHub-wide search `"guava-retrying InterruptedException"` / `"Retryer interrupt status"` → no other reports.
- Persistent findings: `specular findings lookup --query InterruptPreserved --query AttemptTimeLimiters.java:NoAttemptTimeLimit --query "InterruptedException retried interrupt status lost noTimeLimit"` → `[]` (no prior Specular record; this run has `previous: null`).

## Step 3 — Known-status / precedent

- Same mechanism at the same site was publicly reported against the inherited code in the hard fork (re-retrying #32 / #36) and fixed there (re-retrying PR #37). Upstream guava-retrying, the target, has no report and no fix: Novelty = `KNOWN (cite: https://github.com/rhuffman/re-retrying/issues/32, https://github.com/rhuffman/re-retrying/issues/36; fix-status: unfixed)` — unfixed in `rholder/guava-retrying` 2.0.0/master; fixed only in the fork.
- Not in the target guidance's known list (#48, #92, #29, #67, #94). #67 shares the site, not the mechanism.
- Pre-filter: MC-sourced with an actual counterexample → no drop; proceed to Phase 2.

## Repair round 1 — re-check (2026-11-26, continues the round-0 evidence above)

- Source: worktree still `177b6c9`, 0 dirty files, `src/` identical to the run's source repo (`diff -r`), `Retryer.java` sha256 `62e792c48a5fc9d5…`. Re-read every cited line (`Retryer.java` 59-61, 151-155, 159-185, 189-195, 317-318; `AttemptTimeLimiters.java` 75-80, 107; `RetryerBuilder.java` 124-133, 191, 208-213; `BlockStrategies.java` 42-47; `RetryerBuilderTest.java` 384-414): unchanged.
- Counterexamples: the round-1 Phase-3 result cites the same `spec/output/hunt_s2_interrupt_nolimit_bfs2.out`. Both CE files predate the round-0 confirmation (mtime 08:07 / 08:11 UTC; this file was written 09:53) and re-read identically. bfs2 (sha256 `f88fd1f69e1eb4fb…`): 16 states, `InterruptPreserved` violated; state 4 `intr[c1]=TRUE, intrDelivered=TRUE`; state 5 `curTag="CallableIE", intr[c1]=FALSE`; state 10 `attemptNo=2`; state 16 `outcome="Returned", intr[c1]=FALSE`. bfs1 (sha256 `6f055fba169b279d…`): 11 states, `NoRetryAfterObservedInterrupt` violated.
- Correction to the round-0 verdict body (this file was already right): that body attached the `NoRetryAfterObservedInterrupt` violation to `MCWaitStrategyComputes("Zero") → MCBlockZero`. The violating state is bfs1 state 11 `MCCallerBodyStart(c1,"Ret")`. From state 10 to 11 only `made` (1→2), `cbody` ("none"→"Ret") and `cpc` ("Attempt"→"CBody") change, so the violation is the second callable invocation actually starting; `MCBlockZero` (state 10) only advances `attemptNo` to 2.
- Upstream re-check: `rholder/guava-retrying` master HEAD still `177b6c9` (2016-05-10). The most recently updated issues/PRs are #84 (closed 2026-09-20) and #107 (closed 2026-09-05), both unrelated; `repo:rholder/guava-retrying interrupt` still returns only #63. Novelty and fix-status unchanged.
- Reproduction re-executed unchanged (script sha256 `931e9f43…`, Level 0) with the same results as round 0 on JDK 21.0.13.1 and JDK 11.0.33.1: A 50/50 BUG_TRIGGERED, B and C BUG_TRIGGERED, control D CONTRACT_HELD; fix control A 0/50 with B/C/D CONTRACT_HELD. The only log differences are the timestamp and the temp-dir name. `repro/MC-5.log` now holds the round-1 run.
- Fix-precision note (affects only the recommendation): `FixedAttemptTimeLimit` calls `callWithTimeout(callable, duration, timeUnit, true)` (`AttemptTimeLimiters.java:107`). Guava 22 `SimpleTimeLimiter.callWithTimeout` rethrows a worker-side cause through `throwCause(e, true)` (bytecode: `ExecutionException` handler → `throwCause` → `athrow`). With a time limit, an `InterruptedException` raised because the *worker* was interrupted (for example, the user's limiter executor was `shutdownNow`'d) therefore reaches `Retryer.call` looking the same as a caller interrupt. The recommended `instanceof InterruptedException` check would treat it as a caller interrupt, which is also what the fork's fix does. This does not touch the noTimeLimit path of this finding, where every `InterruptedException` comes from the caller thread.
