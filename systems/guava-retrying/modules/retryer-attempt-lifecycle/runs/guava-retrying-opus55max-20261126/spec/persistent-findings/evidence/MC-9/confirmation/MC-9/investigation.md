# MC-9 — Phase 1 investigation (evidence only)

Finding: after the limiter's executor is shut down, `RejectedExecutionException` is recorded as the callable's failure.
Source: model checking. Current counterexamples, regenerated in repair round 1 on the repaired spec: `spec/output/repair-r1/repair1_s4_shutdown_bfs2.out` (invariant `ExecutionExceptionMeansCallableThrewExcept29`, 8 states) and `spec/output/repair-r1/repair1_ctl_s4_shutdown_cir.out` (invariant `CountedImpliesInvokedNoStartRace` as revised by RR-002, 4 states). They were originally `spec/output/hunt_s4_shutdown_bfs2.out` and `spec/output/hunt_s4_shutdown_bfs1.out`. Config `MC_hunt_s4_shutdown.cfg`. See "Repair round 1 continuation" at the end for what changed.
Source tree: worktree at upstream commit `177b6c9` (2.0.0 release plus a Travis workaround), clean.

Persistent-findings lookup (`specular findings lookup --query RejectedExecutionException --query ExecutionExceptionMeansCallableThrew --query "executor shut down" --query SimpleTimeLimiter`) returned `[]`. There are no prior records.

## Step 1: Code audit

### Cited code

- `src/main/java/com/github/rholder/retry/AttemptTimeLimiters.java:69-72`: `fixedTimeLimit(long, TimeUnit, ExecutorService)` wraps the caller-supplied executor in `new SimpleTimeLimiter(executorService)` (line 94). The library does not check the executor's lifecycle.
- `AttemptTimeLimiters.java:106-108`: `FixedAttemptTimeLimit.call(callable)` returns `timeLimiter.callWithTimeout(callable, duration, timeUnit, true)`.
- Guava 22.0 `com/google/common/util/concurrent/SimpleTimeLimiter.java:149` (from `guava-22.0-sources.jar`): `Future<T> future = executor.submit(callable);` runs before the `try` at line 151. For a shut-down `ThreadPoolExecutor`, `submit` calls `execute`, then `reject`, and the default `AbortPolicy` throws `RejectedExecutionException`, which is a `RuntimeException`. The exception propagates unwrapped and the callable is never queued or run.
- `src/main/java/com/github/rholder/retry/Retryer.java:157-164`:
  ```java
  for (int attemptNumber = 1; ; attemptNumber++) {
      Attempt<V> attempt;
      try {
          V result = attemptTimeLimiter.call(callable);           // 160
          attempt = new ResultAttempt<V>(result, attemptNumber, ...);
      } catch (Throwable t) {                                      // 162
          attempt = new ExceptionAttempt<V>(t, attemptNumber, ...); // 163
      }
  ```
  Every `Throwable` from the limiter becomes the attempt's exception, numbered `attemptNumber`, including one thrown before the callable was submitted.
- `Retryer.java:166-168`: listeners receive `onRetry(attempt)` for that fabricated attempt.
- `Retryer.java:170-171`: if the rejection predicate does not match, `return attempt.get()` throws `ExecutionException(RejectedExecutionException)`, constructed at `Retryer.java:254`.
- `Retryer.java:173-182`: if the predicate matches, the stop strategy runs. `RetryException(attemptNumber, attempt)` counts the rejected submissions as failed attempts. Otherwise the loop waits and resubmits to the same shut-down executor, which rejects again every time because shutdown cannot be undone.
- `RetryerBuilder.java:130-144`: `retryIfException()` (`Exception.class`) and `retryIfRuntimeException()` (`RuntimeException.class`) both match `RejectedExecutionException`. `retryIfExceptionOfType(IOException.class)` does not. Defaults (`RetryerBuilder.java:190-197`): `neverStop`, `noWait`, `threadSleepStrategy`.

### Call chain (public API to cited code)

`RetryerBuilder.newBuilder().withAttemptTimeLimiter(AttemptTimeLimiters.fixedTimeLimit(d, unit, executor))...build()`, then `Retryer.call(callable)` (`Retryer.java:155`), then `FixedAttemptTimeLimit.call` (`AttemptTimeLimiters.java:107`), then `SimpleTimeLimiter.callWithTimeout` (`SimpleTimeLimiter.java:142-149`), then `executor.submit`, which throws `RejectedExecutionException`. Control returns to the `catch (Throwable)` at `Retryer.java:162-163`. The same path is reached through `Retryer.wrap(callable).call()` (`Retryer.java:317-318`).

All steps go through public API and normal operations. The 3-argument `fixedTimeLimit` overload exists so that callers can supply and manage their own executor; its Javadoc (`AttemptTimeLimiters.java:47-50`) recommends it "for control over thread management". Shutting that executor down is ordinary lifecycle management. The 2-argument overload's internal cached pool cannot be shut down by users, so the trigger needs the 3-argument overload.

### Trigger scenarios

1. **MC bfs2 (exact counterexample):** `executor.shutdown()`, then build with `fixedTimeLimit(1s, executor)` and `retryIfExceptionOfType(IOException.class)`, plus a listener, then `call(callable)`. The submit is rejected and becomes attempt 1. The listener is notified of attempt 1 with an exception. The predicate does not match, so `call()` throws `ExecutionException(RejectedExecutionException)` and the callable is invoked 0 times.
2. **MC bfs1 / repaired cir (prefix):** the same until the rejected submit is counted as attempt 1 (`made = 1`, `curInvoked = FALSE`; in the repaired trace also `curQueued = FALSE`).
3. **Retry-all variant (summary):** with `retryIfException()` or `retryIfRuntimeException()` and `neverStop` + `noWait` (the builder defaults), each rejected submit is "retried", so `call()` never returns and spins through attempts that never run. With `stopAfterAttempt(n)`, `RetryException` reports `n` failed attempts, none of which ran.
4. **Realistic mid-call shutdown:** attempt 1 runs and throws `IOException` (retried), and during the wait the application shuts the executor down. Attempt 2 is rejected and recorded as the callable's failure.

### Safeguards encountered (recorded, not judged)

- None in the library. `Retryer.call` does not distinguish limiter or infrastructure failures from callable failures; there is a single `catch (Throwable)`.
- `SimpleTimeLimiter.callWithTimeout` does not catch `RejectedExecutionException`.
- Interruption ends the retry-all loop: `Thread.sleep(0)` in `BlockStrategies.threadSleepStrategy` throws `InterruptedException` on an interrupted thread, giving `RetryException` with the interrupt flag set. That is the documented interrupt exit, not a safeguard against the misattribution.
- A caller could special-case `e.getCause() instanceof RejectedExecutionException`, but nothing in the library's contract tells callers to do so.

## Step 2: Developer-knowledge evidence

- `Retryer.call` Javadoc (`Retryer.java:148-150`): "@throws ExecutionException if the given callable throws an exception, and the rejection predicate considers the attempt as successful. The original exception is wrapped into an ExecutionException."
- `Retryer.call` Javadoc (`Retryer.java:151-153`): "@throws RetryException if all the attempts failed before the stop strategy decided to abort, or the thread was interrupted."
- `Attempt` Javadoc (`Attempt.java:21-23`): "An attempt of a call, which resulted either in a result returned by the call, or in a Throwable thrown by the call." `hasException()`: "true if the call threw an exception". `getExceptionCause()`: "the exception thrown by the call".
- `RetryException` Javadoc (`RetryException.java:24-27, 41`): "none of the attempts of the Retryer succeeded"; `numberOfFailedAttempts` means "times we've tried and failed".
- `RetryListener.onRetry` Javadoc (`RetryListener.java:28-31`): "This method with fire no matter what the result is and before the rejection predicate and stop strategies are applied."
- `AttemptTimeLimiter.call` Javadoc (`AttemptTimeLimiter.java:28-32`): "@throws Exception any exception from this invocation". The interface lets the limiter throw its own exceptions but does not say they are the callable's exceptions.
- Guava `SimpleTimeLimiter` Javadoc (lines 56-58, 74-76, 89-91) warns about bounded executors ("the call may even time out before the target method is ever invoked") and says nothing about shut-down executors. `ExecutorService.submit` is specified to throw `RejectedExecutionException` "if the task cannot be scheduled for execution".
- git blame: the `catch (Throwable t)` dates from `6d2d838b` (2012). Commit `fbe31777` (2013, "minor formatting changes") only reformatted it. `ExceptionAttempt(t, attemptNumber, ...)` comes from `1e7f2bdc` (2015, Attempt refactor). No commit message discusses limiter or executor failures.
- Tests: `AttemptTimeLimiterTest.testAttemptTimeLimit` asserts that a **timeout** becomes `ExecutionException` with cause `UncheckedTimeoutException`, the #29 behaviour. No test covers a rejected, shut-down, or saturated executor.
- Upstream issue #29 "Retry following timeout" (open, https://github.com/rholder/guava-retrying/issues/29):
  - Reporter: "any exception thrown by the `AttemptTimeLimiter` will cause `Retryer` to abort. This is includes `TimeoutException`." The proposed fix would make timeouts throw `TimeoutException`, wrap callable exceptions in `ExecutionException`, and have `Retryer#call` handle them differently.
  - Maintainer rholder (2015-05-02): "I agree with your assessment and would also consider it a bug, too, since the documentation seems to indicate it would affect a single `Attempt` without really noting that its failure is tied to any `Exception` that might pop out. ... Catchall `retryIfException()` or `retryIfRuntimeException()` retrying appears to mask this behavior as well."
  - dirkraft (the limiter's author, 2015-05-04): "the attempt timeout should at a minimum behave like any other exception thrown by an attempt, and be subject to the exception-related retryer configuration."
  - All discussion concerns the timeout, where the callable was submitted and cut off. Nobody discusses a rejected submission, a shut-down executor, or attempts that never ran.
- Upstream issue #67 "Retryer.call should not catch Errors like OOME" (open) concerns the `Error` policy of the same catch block, a different aspect.

## Step 3: Known-status / precedent

Tracker search (run 2026-11-26 with `gh api search/issues`, plus a full listing of all 107 issues and PRs in state `all`, sorted by update time):

- `repo:rholder/guava-retrying` returned 0 hits for each of "RejectedExecutionException", "shutdown", "rejected", "busy loop", and "never executed". "executor" and "ExecutorService" hit #69 and #65, both feature requests about which executor runs the retry, not rejection. "SimpleTimeLimiter", "fixedTimeLimit", and "AttemptTimeLimiter" hit #94 (Guava 23 incompatibility), #92 (process does not exit), #29 (timeout not retried), #18 (HashedWheelTimer suggestion), #46 (generics), #96 (Guava constructor question), and #30/#39 (parameter naming). A grep of the bodies and comments of #69, #65, #94, #18, #67, #29, #100, #92, #35, and #96 for shutdown, reject, terminate, or executor found nothing about rejected submissions.
- Recently closed or merged PRs: #84 (README, closed 2026-09-20) and #107 "Modernize" (closed 2026-09-05, **not merged**, a PHP port that deletes the Java sources). No fix for this mechanism has landed.
- Fork `rhuffman/re-retrying` (#81 points to it): "RejectedExecutionException" and "shutdown" returned 0 hits. "rejected" hit #26 and #32, which concern Runnables and interrupts.
- Specular persistent-findings registry: no records. The `Specular/case-studies` dataset has no guava-retrying entry.

Closest precedent is #29: the same `catch (Throwable)` site, where a limiter-originated **timeout** is treated as the attempt's exception. This is a same-shape precedent at a different step. The timeout comes from `future.get` (`SimpleTimeLimiter.java:154, 164-166`) after the callable was submitted and possibly ran, while MC-9's exception comes from `executor.submit` (`SimpleTimeLimiter.java:149`) before anything runs. The fix proposed in #29 (`TimeoutException` versus `ExecutionException` from the limiter) would still let a raw `RejectedExecutionException` escape to the same catch block, so it would not cover this defect. The MC invariant explicitly excludes the #29 case.

Pre-filter: the finding is MC-sourced with an actual counterexample, so it proceeds to Phase 2. It is not a code-review × known drop.

## Repair round 1 continuation (2026-11-26)

This section continues the evidence above after repair round 1; it does not restart the investigation.

### Regenerated counterexamples compared with the originals

- `diff hunt_s4_shutdown_bfs2.out repair-r1/repair1_s4_shutdown_bfs2.out`: same 8 actions in the same order (`MCExecutorShutdown`, `MCCallStart`, `MCSubmitRejected`, `MCListenersBegin`, `MCListenerNotify`, `MCListenersEnd`, `MCPredicateAccepts`) and the same violated invariant `ExecutionExceptionMeansCallableThrewExcept29`. Apart from TLC run metadata, the only state difference is `curQueued`: `TRUE` in states 4-8 of the original, `FALSE` in the repaired trace. State 8 still ends with `outcome = "ExecExc"`, `exitInfo = [flag |-> FALSE, count |-> 1, tag |-> "Rejected", invoked |-> FALSE]`, `notified = <<1>>`, `curInvoked = FALSE`.
- `diff hunt_s4_shutdown_bfs1.out repair-r1/repair1_ctl_s4_shutdown_cir.out` (and `repair-r1/repair1_s4_shutdown_bfs1.out`): same 4 actions, same invariant `CountedImpliesInvokedNoStartRace`, and the same single difference (`curQueued = FALSE` in state 4). After RR-002 the invariant still flags a submit rejected by a shut-down executor.
- The repaired value matches the implementation. On a shut-down pool, JDK `ThreadPoolExecutor.execute` calls `reject` without enqueueing the task (stack frame `ThreadPoolExecutor.execute(ThreadPoolExecutor.java:1376)` → `reject` → `AbortPolicy.rejectedExecution`). The round-1 repro observes this directly: inside `onRetry`, that is, between CE states 4 and 8, the executor reports `taskCount=0 queue.size=0 largestPoolSize=0`.
- Correction: the original traces' `curQueued = TRUE` after `MCSubmitRejected` was a model inaccuracy, since the rejected task never reaches the queue. Neither the round-0 investigation nor the round-0 verdict used `curQueued`, so no earlier conclusion depends on it. The only earlier statements that change are the counterexample citations, now updated above.

### Re-verification of the code facts

- The worktree is at `177b6c9b9f3e7957f404f0bdb8e23374cb1de43f` with no changes under `src/`. The `Retryer.java` and `AttemptTimeLimiters.java` sha256 prefixes (`62e792c48a5fc9d5`, `b98b9da0ee59c5ec`) and the guava-22.0 jar sha1 (`3564ef3803de51fb0530a8377ec6100b33b0d073`) are identical in the round-0 and round-1 runs.
- `Retryer.java:155-185` and Guava 22.0 `SimpleTimeLimiter.java:142-168` were re-read and match the citations in Step 1. In particular, `executor.submit(callable)` at line 149 still runs before the `try` at line 151.

### Known-status refresh

- `specular findings lookup` with the queries `RejectedExecutionException`, `ExecutionExceptionMeansCallableThrewExcept29`, `CountedImpliesInvokedNoStartRace`, `executor shut down`, and `MCSubmitRejected` returned `[]`. There is no registered record to reuse or revise.
- Upstream `rholder/guava-retrying`, re-searched 2026-11-26:
  - `RejectedExecutionException`, `shutdown`, `rejected`, and `executor shut` each returned 0 hits.
  - The most recently updated items are still #84 (closed 2026-09-20, not merged) and #107 (closed 2026-09-05, not merged). No closed PR in the latest ten was merged.
  - The master head is still `177b6c9` (2016-05-10).
- Novelty is unchanged.
