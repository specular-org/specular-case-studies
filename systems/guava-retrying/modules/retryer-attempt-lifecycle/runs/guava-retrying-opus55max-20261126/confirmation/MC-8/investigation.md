# MC-8 — Phase 1 investigation (evidence only, no verdict)

Finding: with a bounded limiter executor, attempts that time out in the queue or are rejected are counted as failed attempts although the callable never ran; `wrap()` on the limiter's own pool times out every attempt. Source: model checking (`CountedImpliesInvokedNoStartRace`, `MC_hunt_s4_executor.cfg`, CE `spec/output/hunt_s4_executor_bfs1.out`; also `hunt_s4_wrap_samepool_bfs1.out`, and `hunt_s4_executor_bfs3.out` which violates `NoActivityAfterOutcome`).

Source tree: `confirmation/MC-8/worktree` at `177b6c9` (guava-retrying 2.0.0). Guava 22.0 sources: `/home/ubuntu/scratch/guava22-sources-dl/guava-22.0-sources.jar` (sha1 `55edc69e…` matches its `.sha1`). Persistent-findings lookup (`specular findings lookup` for AttemptTimeLimiters / SimpleTimeLimiter / CountedImpliesInvokedNoStartRace / executor saturation): no records.

## Step 1 — Code audit

### Cited sites

- `AttemptTimeLimiters.java:69-72` — `fixedTimeLimit(duration, unit, executorService)` → `new FixedAttemptTimeLimit<V>(duration, timeUnit, executorService)`; `:93-95` → `new SimpleTimeLimiter(executorService)` (user-supplied executor used as is, no sizing check).
- `AttemptTimeLimiters.java:105-108` — `FixedAttemptTimeLimit.call` → `timeLimiter.callWithTimeout(callable, duration, timeUnit, true)`.
- Guava 22.0 `SimpleTimeLimiter.java:142-168` (4-arg `callWithTimeout`):
  - `:149` `Future<T> future = executor.submit(callable);` — a saturated executor's `RejectedExecutionException` propagates out of `callWithTimeout` unchanged.
  - `:154` `return future.get(timeoutDuration, timeoutUnit);` — the deadline is measured from after `submit`, so time spent queued counts against the attempt.
  - `:164-166` `catch (TimeoutException e) { future.cancel(true); throw new UncheckedTimeoutException(e); }` — a cancelled `FutureTask` that is still queued is not removed from a `ThreadPoolExecutor` queue (JDK: cancelled tasks "may accumulate in work queues until worker threads can actively remove them", `ThreadPoolExecutor.purge()` Javadoc); when a worker later dequeues it, `FutureTask.run` sees state != NEW and skips the callable.
- `Retryer.java:157-174` — loop: `attemptTimeLimiter.call(callable)` (`:160`); `catch (Throwable t)` → `new ExceptionAttempt<V>(t, attemptNumber, …)` (`:162-163`); listeners (`:166-168`); rejection predicate (`:170-171`); stop strategy → `new RetryException(attemptNumber, attempt)` (`:173-174`). No distinction between a limiter failure before the callable started (queued timeout, rejection) and one while it ran.
- `Retryer.java:195-197, 301-320` — `wrap(callable)` returns a `RetryerCallable` whose `call()` runs `retryer.call(callable)` on whatever thread executes it.

### Call chain (public API → cited code)

`RetryerBuilder.newBuilder().withAttemptTimeLimiter(AttemptTimeLimiters.fixedTimeLimit(d, unit, executor))…build()` → `Retryer.call(c)` (`Retryer.java:155`) → `FixedAttemptTimeLimit.call` (`AttemptTimeLimiters.java:106`) → `SimpleTimeLimiter.callWithTimeout(c, d, unit, true)` (`SimpleTimeLimiter.java:142`) → `executor.submit` (`:149`) / `future.get(d)` (`:154`) / `cancel(true)` + `UncheckedTimeoutException` (`:165-166`) → back in `Retryer.call` → `ExceptionAttempt` (`:163`) → listeners / predicate / stop → `RetryException(attemptNumber, …)` (`:174`).
`executor.submit(retryer.wrap(c))` → `RetryerCallable.call()` (`Retryer.java:317`) → same chain on a worker thread.

Reachability: all public API, normal usage. Requires the user to pass a bounded executor (bounded thread count and/or bounded queue) to the 3-arg `fixedTimeLimit`. The default 2-arg `fixedTimeLimit` uses `Executors.newCachedThreadPool()` (unbounded threads, `SynchronousQueue`), where attempts are never queued or rejected.

### Trigger scenarios (to exercise in Phase 2)

- S-A (CE `hunt_s4_executor_bfs1`): `ThreadPoolExecutor(1, 1, …, ArrayBlockingQueue(1))`; two threads share one `Retryer` built with `fixedTimeLimit(T, ms, pool)`. Caller 1's attempt holds the only worker longer than T; caller 2's attempt is queued, `future.get` times out, it is cancelled but stays in the queue; `Retryer` records attempt #1 of caller 2 as `ExceptionAttempt(UncheckedTimeoutException)`; caller 2's callable was not invoked during that attempt.
- S-B (CE `hunt_s4_wrap_samepool_bfs1`): `pool = newSingleThreadExecutor()`; `pool.submit(retryer.wrap(c))` where the retryer's limiter uses the same `pool`. The `RetryerCallable` occupies the only worker; every attempt is queued behind it and times out unrun. `stopAfterAttempt(N)` → `RetryException(N)` with 0 invocations; `neverStop()` → loops forever (and the unbounded queue accumulates cancelled tasks).
- S-C (CE `hunt_s4_executor_bfs3`): same 1-thread / queue-1 pool; caller 1's attempt 1 runs, times out, but the callable ignores interrupts and keeps the worker; caller 2's task fills the queue; caller 1's attempt 2 is rejected (`RejectedExecutionException`) and counted; with `stopAfterAttempt(2)` caller 1 gets `RetryException(2)` after 1 invocation.

### Safeguards / mitigations encountered (recorded, not judged)

- No size/queue check on the user executor anywhere in guava-retrying.
- `FutureTask.run` skips a cancelled task, so a queued-and-cancelled attempt never runs later (no late execution).
- Default factory uses an unbounded cached pool, so the default configuration does not reach the path.

## Step 2 — Developer-knowledge search

### Comments / docs (verbatim)

- `AttemptTimeLimiters.java:47-50` (written with the feature, commit `7e474be`, dirkraft, 2013-01-16): "For control over thread management, it is preferable to offer an {@link ExecutorService} through the other factory method, {@link #fixedTimeLimit(long, TimeUnit, ExecutorService)}. See the note on {@link SimpleTimeLimiter#SimpleTimeLimiter(ExecutorService)}, which this AttemptTimeLimiter uses."
- That note, Guava 22.0 `SimpleTimeLimiter.java:56-58` (identical text on `SimpleTimeLimiter()` `:74-76` and `create(ExecutorService)` `:89-91`): "<b>Warning:</b> using a bounded executor may be counterproductive! If the thread pool fills up, any time callers spend waiting for a thread may count toward their time limit, and in this case the call may even time out before the target method is ever invoked."
- Same note in Guava 10.0 (the version guava-retrying compiled against when `7e474be` added the time limiter; `build.gradle` at `7e474be`: `compile "com.google.guava:guava:10.0"`), verified from `guava-10.0-sources.jar` (Maven Central) lines 56-60.
- `AttemptTimeLimiter.java:22`: "A rule to wrap any single attempt in a time limit, where it will possibly be interrupted if the limit is exceeded."; `:31` "@throws Exception any exception from this invocation".
- `RetryerBuilder.java:113`: "Configures the retryer to limit the duration of any particular attempt by the given duration."
- `Attempt.java:6-7` (counter-evidence): "An attempt of a call, which resulted either in a result returned by the call, or in a Throwable thrown by the call." (Already loose for every timeout: `UncheckedTimeoutException` is thrown by the limiter, not the call.)
- `Retryer.java:148-153`: ExecutionException "if the given callable throws an exception, and the rejection predicate considers the attempt as successful"; RetryException "if all the attempts failed before the stop strategy decided to abort".
- `RetryException.java:24-26`: "An exception indicating that none of the attempts of the {@link Retryer} succeeded."; `getNumberOfFailedAttempts()` "the number of failed attempts".
- `RetryListener.java:31-33`: "This method with fire no matter what the result is and before the rejection predicate and stop strategies are applied."

### Tests

- `AttemptTimeLimiterTest.java:44-50`: a timed-out attempt (default predicate) must surface as `ExecutionException` whose cause is `UncheckedTimeoutException` — the limiter's timeout is asserted to be the attempt's exception.
- `RetryerBuilderTest.java:417-424` (`testWrap`): calls `wrap(c).call()` directly; no executor test. No test uses a bounded or shared limiter executor.

### Issues / PRs / commits

- PR #1 (dirkraft, merged 2013-01-16, "added a per attempt time limit"): "This provides a mechanism to limit any one single attempt from clobbering a Retryer. Combined with StopStrategies.stopAfterAttempt, it is easier to approximate the max run time. Combined with StopStrategies.stopAfterDelay, it is possible to ensure that some minimum number of attempts were made in the allotted total delay window."
- Issue #29 (open, "Retry following timeout"): owner rholder: "…the documentation seems to indicate it would affect a single `Attempt`…"; dirkraft (time-limiter author): "the attempt timeout should at a minimum behave like any other exception thrown by an attempt, and be subject to the exception-related retryer configuration."
- Issue #18 (open): owner: "The current implementation of an `AttemptTimeLimiter` using `SimpleTimeLimiter` can be fairly wasteful with respect to resources."
- Issue #69 (open, "Could I build the Retryer with different executors?") — request to change the default cached pool; no report of queue timeouts or rejection counting.
- `git log` on `AttemptTimeLimiters.java` / `AttemptTimeLimiter.java`: `7e474be` (feature), `8515e4a` (license), `4da9dda`/`5cc1018` (Javadoc formatting), `a5a069f` (copyright). No intent statement beyond the Javadoc above.

## Step 3 — Known-status / precedent

Searched (2026-11-26) `rholder/guava-retrying` issues and PRs (all states) via `gh search issues` for: bounded, RejectedExecutionException, executor, thread pool, fixedTimeLimit, SimpleTimeLimiter, queue, starvation, deadlock, timeout attempt, wrap; and listed all PRs (`gh pr list --state all`, 60+ entries, including the most recently closed #84 2026-09-20 and #107 "Modernize" 2026-09-05, both closed unmerged, neither changes this mechanism). Checked the Specular case-studies dataset (`specular-org/specula-case-studies` `systems/`; local `Specular/case-studies`): no guava-retrying entry.

Result: no issue / PR / advisory / dataset entry reports this mechanism (queued timeouts or executor rejections counted as attempts; `wrap()` on the limiter's own pool). Not KNOWN. The behavior is, however, described in documentation the library points to (Guava's bounded-executor warning, referenced at `AttemptTimeLimiters.java:49-50`) — recorded above as developer-intent evidence, not as a filed report.

Pre-filter: MC-sourced with an actual counterexample → proceeds to Phase 2 (no drop).
