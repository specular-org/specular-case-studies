# MC-3 — Phase 1 investigation (evidence only)

Finding: "A completed attempt is reported as a timeout; its result is discarded and the work is executed again" (source: model-checking, invariant `NoDiscardedCompletion`, cfg `MC_hunt_s1_timelimit.cfg`, CE `spec/output/hunt_s1_timelimit_bfs1.out`).

Persistent-findings lookup (`specular findings ... lookup --query SimpleTimeLimiter --query NoDiscardedCompletion --query callWithTimeout --query cancel --query UncheckedTimeoutException`) returned `[]`: no prior record to reuse.

## Step 1 — Code audit

Source under test: guava-retrying 2.0.0 (worktree at upstream `177b6c9`), Guava 22.0 (`~/.m2/.../guava-22.0.jar`, sha1 `3564ef3803de51fb0530a8377ec6100b33b0d073`, matches the published `.sha1`; sources from `guava-22.0-sources.jar`), JDK `FutureTask` (JDK 11 and JDK 21 copies; `cancel`, timed `get`, `awaitDone` are textually identical between 11 and 21, only line numbers shift).

### Cited code

- `guava-22.0/com/google/common/util/concurrent/SimpleTimeLimiter.java:149` — `Future<T> future = executor.submit(callable);`
- `SimpleTimeLimiter.java:152-158` — interruptible branch: `return future.get(timeoutDuration, timeoutUnit);` and on `InterruptedException` `future.cancel(true); throw e;` (cancel result ignored at :156 — the MC-4 variant, not handled here).
- `SimpleTimeLimiter.java:164-166` — `catch (TimeoutException e) { future.cancel(true); throw new UncheckedTimeoutException(e); }` — the boolean returned by `cancel` is ignored; the exception is thrown whether or not the task could be cancelled.
- JDK 11 `FutureTask.java:164-166` — `cancel` returns `false` unless `state == NEW` and the CAS `NEW -> INTERRUPTING` succeeds; `:181` returns `true` otherwise.
- JDK 11 `FutureTask.java:197-205` — timed `get`: `if (s <= COMPLETING && (s = awaitDone(true, ...)) <= COMPLETING) throw new TimeoutException();`
- JDK 11 `FutureTask.java:228-234` — `set(v)`: CAS `NEW -> COMPLETING`, `outcome = v`, `setRelease(NORMAL)`, `finishCompletion()`.
- JDK 11 `FutureTask.java:405-447` — `awaitDone`: loop-top read `int s = state` (:406); `COMPLETING` at loop top yields and re-loops (:412-415); only when the loop-top read is `NEW` does the timed branch run, and after `elapsed >= nanos` (:436) it returns a *fresh* read `return state;` (:438) which may be `NEW` or `COMPLETING`.
- guava-retrying `AttemptTimeLimiters.java:57-60`, `:69-72` — public factories `fixedTimeLimit(duration, unit)` / `fixedTimeLimit(duration, unit, executorService)`; `:89-95` wrap `new SimpleTimeLimiter()` / `new SimpleTimeLimiter(executorService)`; `:106-108` `call` → `timeLimiter.callWithTimeout(callable, duration, timeUnit, true)`.
- `Retryer.java:155-185` — `call` loop: `:160` `attemptTimeLimiter.call(callable)`; `:161` `ResultAttempt`; `:162-163` `catch (Throwable t)` → `ExceptionAttempt(t, …)`; `:166-168` listeners; `:170-172` if not rejected → `return attempt.get()` (an `ExceptionAttempt` throws `ExecutionException(cause)`); `:173-182` stop / wait / block, then the loop runs the callable again.
- `RetryerBuilder.java:39` default `rejectionPredicate = Predicates.alwaysFalse()`; `:130-132` `retryIfException()` → `ExceptionClassPredicate(Exception.class)`; `:141-143` `retryIfRuntimeException()` (`UncheckedTimeoutException extends RuntimeException`, so both retry it).

### Call chain (all public API)

`Retryer.call(callable)` (`Retryer.java:155`) → `FixedAttemptTimeLimit.call` (`AttemptTimeLimiters.java:106-107`) → `SimpleTimeLimiter.callWithTimeout(c, d, u, true)` (`SimpleTimeLimiter.java:142`) → `executor.submit` (:149) → `FutureTask.get(d, u)` (:154) → `TimeoutException` (`FutureTask.java:204`) → `future.cancel(true)` returns `false` because the worker's `set` CAS already moved the task out of `NEW` (:165) → `throw new UncheckedTimeoutException(e)` (:166) → `Retryer` records `ExceptionAttempt(UncheckedTimeoutException)` (`Retryer.java:162-163`) → rejection predicate: retried (`retryIfException`/`retryIfRuntimeException`) → callable runs again; or not retried (default predicate) → `call()` throws `ExecutionException(UncheckedTimeoutException)` (`Retryer.java:171`).

Reachability: normal usage of `withAttemptTimeLimiter(AttemptTimeLimiters.fixedTimeLimit(...))`. No guard in guava-retrying inspects the `Future` or the result of `cancel`.

### Trigger scenario (mapped to the CE)

CE `hunt_s1_timelimit_bfs1.out`, 10 states: `MCCallStart(c1)` → `MCSubmitNewWorker(c1,t1,w1)` → `MCWorkerRunTaskStart(w1)` → `MCWorkerRunnerCAS(w1)` → `MCBodyStart(w1,"Ret")` → `MCBodyReturns(w1)` (state 7, `tres[t1] = "Result"`) → `MCSetCASWon(w1)` (state 8, `tstate[t1] = "COMPLETING"`) → `MCGetTimeout(c1)` (state 9, `curTag = "Timeout"`, `cpc = "CancelTO"`, task still `COMPLETING`) → `MCSetFinish(w1)` (state 10, `tstate[t1] = "NORMAL"`) — `NoDiscardedCompletion` violated: the caller is on the timeout/cancel path for a task that holds a normal result.

Code-level interleavings that realise it:

- Window A (the CE's literal order): caller's loop-top read sees `NEW` (`FutureTask.java:406`); worker's `set` CAS → `COMPLETING`; caller's `elapsed >= nanos` (:436) and `return state` (:438) reads `COMPLETING` → `TimeoutException` (:204); worker publishes `NORMAL`; caller's `cancel(true)` fails; `UncheckedTimeoutException`.
- Window B (wider in practice): caller's `return state` (:438) reads `NEW` after the deadline → `new TimeoutException()` (stack-trace fill) → catch at `SimpleTimeLimiter.java:164`; meanwhile the worker's callable returns and `set` CAS succeeds → `cancel(true)` (:165) returns `false` → `UncheckedTimeoutException`. The `Future` ends `NORMAL` with the result.

In both windows the caller has already measured `elapsed >= nanos` (deadline passed) while the task was not yet `NORMAL`; the completion lands in the few-microsecond gap between that decision and the `cancel` CAS. For the completion to precede the deadline itself, the caller would have to be awake before the deadline (spurious/early unpark) and the worker would have to stall between its CAS and `setRelease(NORMAL)` across the caller's whole check (Window A only).

Safeguards / masks recorded (not yet judged): none in guava-retrying. The documented contracts below classify "time limit reached" as a timeout irrespective of whether the abort succeeds.

## Step 2 — Developer-knowledge evidence (verbatim, uncategorised)

- Guava 22.0 `TimeLimiter.java:79-83` (the 4-arg `callWithTimeout` used here): "Invokes a specified Callable, timing out after the specified time limit. If the target method call finished before the limit is reached, the return value or exception is propagated to the caller exactly as-is. If, on the other hand, the time limit is reached, we attempt to abort the call to the target, and throw an {@link UncheckedTimeoutException} to the caller." `:94` "@throws UncheckedTimeoutException if the time limit is reached".
- Guava 22.0 `TimeLimiter.java:47-51` (newProxy): "the primary purpose of the proxy object is to return control to the caller when the timeout elapses; aborting the target method call is of secondary concern. The particular nature and strength of the guarantees made by the proxy is implementation-dependent."
- Guava 22.0 `SimpleTimeLimiter.java:38-40`: "If the time limit expires for a given method call, the thread running the call will be interrupted."
- Guava current `master` still ignores `cancel`'s result on every timeout path (`SimpleTimeLimiter.java:129-131`, `:149-150`, `:172-173`, `:192-193`, `:212-213`; newest commit touching the file `3b1c73103d`, 2026-07-28) and keeps the same Javadoc (`TimeLimiter.java:52-58`, `:96-102`, `:135-143`).
- guava-retrying `AttemptTimeLimiter.java:22` (dirkraft, `7e474be`, 2013-01-16): "A rule to wrap any single attempt in a time limit, where it will possibly be interrupted if the limit is exceeded."
- guava-retrying `AttemptTimeLimiters.java:52` and `:63`: "@param duration that an attempt may persist before being circumvented".
- guava-retrying `RetryerBuilder.java:111`: "Configures the retryer to limit the duration of any particular attempt by the given duration."
- Upstream PR #1 (the feature, merged 2013-01-16): "This provides a mechanism to limit any one single attempt from clobbering a Retryer."
- Upstream issue #29 (open, "Retry following timeout"): dirkraft: "the attempt timeout should at a minimum behave like any other exception thrown by an attempt, and be subject to the exception-related retryer configuration." rholder: the retryer "effectively stops retrying instead of giving up on the attempt and trying again".
- `git log` on `AttemptTimeLimiter(s).java`: only `7e474be` (feature), Javadoc/licence touch-ups (`8515e4a`, `4da9dda`, `5cc1018`, `a5a069f`); `git blame` of `AttemptTimeLimiters.java:105-108` and `Retryer.java:160-163` shows no later change to the timeout path. No TODO/FIXME/comment near any cited site.
- Test `AttemptTimeLimiterTest.java:36-51`: a 0 ms callable must not time out; a 10 s callable under a 1 s limit must fail with `ExecutionException` caused by `UncheckedTimeoutException`. No test covers completion at the deadline.

## Step 3 — Known-status / precedent

Searches run on 2026-11-26:

- guava-retrying: full issue list (all states, #2–#106) and full PR list (all states, #1–#107, including #107 "Modernize" closed 2026-09-05 and the open #95 that edits `AttemptTimeLimiters.java` for Guava 29 compatibility); keyword searches `cancel`, `timeout result`, `SimpleTimeLimiter`, `UncheckedTimeoutException`, `executed twice`, `runs twice`, `time limit completed`, `callWithTimeout`. Hits: #18 (HashedWheelTimer suggestion), #29 (timeout not retried by default — different mechanism), #94/#96 (Guava 23 API removal). None reports a completed attempt being reported as a timeout or the ignored `cancel` result.
- google/guava: searches `SimpleTimeLimiter cancel`, `SimpleTimeLimiter race`, `TimeLimiter cancel result`, `callWithTimeout completed timeout`, `SimpleTimeLimiter TimeoutException result`, `TimeLimiter discards result`, `SimpleTimeLimiter`, `TimeLimiter`. Hits #6599 (nested try style), #3550 (thread not interrupted), #2458, #3725, #3603, #3907, #3242, #1530, #1257, #2210, #490 — none about the ignored `cancel` result or a completed call being reported as timed out.

Outcome: no existing report of this mechanism (→ `Novelty: NEW` if it is a defect). Source is MC with an actual counterexample, so the code-review × known pre-filter does not apply; proceed to Phase 2.

## Phase 2 — reproduction record (2026-11-26)

- Test: `repro/test_bugMC-3_timeout_discards_completion.sh` (Level 0: public API only; unmodified guava-retrying `177b6c9` built with `--release 8` against Guava 22.0; a pass-through `ForwardingExecutorService` given to `AttemptTimeLimiters.fixedTimeLimit(1, MILLISECONDS, executor)` only records the `Future` returned by `submit`; the callable is CPU-bound and finishes at a chosen instant near the limit, staircase-tracked around the success/timeout boundary). Log: `repro/MC-3.log`.
- Command: `timeout 1200 repro/test_bugMC-3_timeout_discards_completion.sh 4000` (4000 trials × 2 configs × JDK 21.0.13.1 and JDK 11.0.33.1), exit 0.
- CE path realised 1079/16000 times (JDK 21: A 261, B 247; JDK 11: A 319, B 252): attempt 1 recorded as `UncheckedTimeoutException` while `Future#1` is `NORMAL` with `result-of-execution-1`, `isCancelled()=false`, worker not interrupted.
- Every realised instance returned +42.3 … +117.1 µs after (submit() returned + 1 ms) — after the earliest possible deadline. Cancelled timeouts: min +36.0 µs; successes: up to +1486.7 µs (late caller wake-up).
- What Retryer's caller and listeners observe in the MC-3 state equals the ordinary cancelled-timeout control: config A "attempt#1=exception(UncheckedTimeoutException), callable executions=2, call() returned result-of-execution-2"; config B "call() threw ExecutionException(UncheckedTimeoutException)". Only the private `Future` state (NORMAL vs CANCELLED) and the worker's interrupt flag differ.
- Verdict input: path reachable; outcome is the documented "limit reached → abort attempted → UncheckedTimeoutException" behaviour (Step 2 evidence) → invariant artifact; semantic draft `repair-request.body.md` (target INVARIANT).
