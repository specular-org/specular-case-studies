---
target: INVARIANT
counterexample: spec/output/hunt_s4_executor_bfs1.out
scope:
  actions: [MCSubmitQueued, MCGetTimeout, MCCancelFinish, MCSubmitRejected]
  invariants: [CountedImpliesInvokedNoStartRace]
  hunt_cfgs: [MC_hunt_s4_executor.cfg, MC_hunt_s4_wrap_samepool.cfg]
  fault_actions: []
---

## Trigger
INVARIANT: the counterexample path is real and reproduces exactly in guava-retrying 2.0.0 + Guava 22.0, but the property it violates — "every counted attempt invoked the callable (start race excepted)" — is not promised for a bounded limiter executor. The library points users of `fixedTimeLimit(d, unit, executor)` to Guava's documented warning that, with a bounded executor, queue time counts toward the limit and "the call may even time out before the target method is ever invoked", and by design every limiter failure is a failed attempt subject to the retry configuration. The reached state is the documented outcome, so no consumer observes a wrong result.

## Evidence
- CE step (`spec/output/hunt_s4_executor_bfs1.out`, states 5-9): `MCSubmitQueued(c2,t2)` → `MCGetTimeout(c2)` → `MCCancelCASWon/ReadRunner/Finish(c2)` leaves c2 `Classified` with `curQueued = TRUE`, `curInvoked = FALSE`, t2 still in `queue`. `hunt_s4_wrap_samepool_bfs1.out` states 3-7: the same with the RetryerCallable holding the only worker (`wOuter = w1 :> c1`). `hunt_s4_executor_bfs3.out` states 19-23: `MCSubmitRejected(c1)` counted, `MCStopStrategyStops(c1)` → RetryExc with count 2.
- Predicted vs realised: `repro/test_bugMC-8_bounded_executor_attempt_accounting.sh` (Level 0, unmodified sources at 177b6c9, 3/3 runs, log `repro/MC-8.log`) realises every predicted end state. TPE(1,1,ArrayBlockingQueue(1)) shared by two callers: caller-2 attempt#1 = `UncheckedTimeoutException` with its task still queued (`limiter queue=1`), then attempt#2 = `RejectedExecutionException`; `RetryException(numberOfFailedAttempts=2)` with 0 invocations; caller-1 `RetryException(2)` with 1 invocation, last = `RejectedExecutionException`. `pool.submit(retryer.wrap(c))` on the limiter's own 1-thread pool: `RetryException(3)`, 0 invocations, queue 1→2→3. With `neverStop`: 29 attempts in 3 s, 0 invocations, 30 cancelled tasks queued. Controls: with `Executors.newCachedThreadPool()` (the default kind of pool) or wrap() on a separate pool, counted == invoked (caller-2 succeeds on attempt#1 with 1 invocation; caller-1 2 attempts / 2 invocations; wrap control returns on attempt#1).
- Developer intent — the property is not promised:
  - `src/main/java/com/github/rholder/retry/AttemptTimeLimiters.java:47-50` (added with the feature in commit 7e474be, 2013-01-16): "For control over thread management, it is preferable to offer an ExecutorService through the other factory method, fixedTimeLimit(long, TimeUnit, ExecutorService). See the note on SimpleTimeLimiter#SimpleTimeLimiter(ExecutorService), which this AttemptTimeLimiter uses."
  - That note, Guava 22.0 `com/google/common/util/concurrent/SimpleTimeLimiter.java:56-58` (identical in Guava 10.0, the version 7e474be compiled against, lines 56-60): "Warning: using a bounded executor may be counterproductive! If the thread pool fills up, any time callers spend waiting for a thread may count toward their time limit, and in this case the call may even time out before the target method is ever invoked."
  - `src/main/java/com/github/rholder/retry/AttemptTimeLimiter.java:22` ("A rule to wrap any single attempt in a time limit") and `:31` ("@throws Exception any exception from this invocation"): the limiter, including the executor's submit, is part of the attempt.
  - Issue #29 (https://github.com/rholder/guava-retrying/issues/29), dirkraft (time-limiter author): "the attempt timeout should at a minimum behave like any other exception thrown by an attempt, and be subject to the exception-related retryer configuration"; owner rholder agrees the timeout affects a single Attempt.
  - `src/test/java/com/github/rholder/retry/AttemptTimeLimiterTest.java:44-50` asserts that a timed-out attempt surfaces as the attempt's exception (`ExecutionException` caused by `UncheckedTimeoutException`).
- Not counted against this request: the zombie activity visible in bfs3 (attempt 1's callable still running after `call()` ended) is a separate property, `NoActivityAfterOutcome`, outside this scope.

## Proposed change
Make `CountedImpliesInvokedNoStartRace` express what the implementation supports. Option A: keep counted ⇒ invoked (start race excepted) only for limiter executors that can neither queue nor reject (unbounded threads, as with the default `newCachedThreadPool()`), and drop that requirement in the bounded-executor cfgs. Option B, for the bounded cfgs: a counted attempt whose callable never ran must carry a limiter-originated failure (Timeout or Rejected tag, i.e. `UncheckedTimeoutException` / `RejectedExecutionException`), never a result or a callable-originated exception. A model that misreported a never-invoked attempt as a result or a callable failure would still violate this. Keep the CE traces as regression witnesses that the revised predicate accepts.
