# MC-1 — Phase 1 investigation (evidence only, no verdict)

Finding: a timed-out (or caller-interrupted) attempt keeps running alongside later attempts and after `Retryer.call()` has returned or thrown. Source: model checking (actual counterexamples). Ledger row D-1.

## Persistent-findings lookup (before analysis)

`specular findings --work .specular-output lookup` with queries `SimpleTimeLimiter`, `callWithTimeout`, `SequentialAttempts`, `NoActivityAfterOutcome`, `fixedTimeLimit`, `Retryer.call`, `AttemptTimeLimiters`, `overlapping attempts`, `D-1`, `MC-1` → `[]`. `persistent-findings-context.json` has `previous: null`, no inherited records. Nothing to reuse; normal analysis.

## Step 1 — Code audit

Source under test: worktree HEAD `177b6c9b9f3e7957f404f0bdb8e23374cb1de43f` (2.0.0 + a Travis workaround). `diff -r` against the pipeline source checkout `/home/ubuntu/scratch/guava-retrying-src/guava-retrying/src` is empty. Upstream `rholder/guava-retrying` master HEAD is also `177b6c9` (GitHub API, 2026-11-26), so the code is unfixed upstream.

Guava environment: 22.0. Binary `~/.m2/.../guava-22.0.jar` sha1 `3564ef3803de51fb0530a8377ec6100b33b0d073` = its Maven `.sha1`. Sources `guava-22.0-sources.jar` sha1 `55edc69e4fc937f4e58e577bb144b824c0ec7c55` = its `.sha1`; extracted at `/home/ubuntu/scratch/guava22-sources-dl/extracted/`.

### Cited code (read in full)

- `AttemptTimeLimiters.java:57-60` `fixedTimeLimit(duration, unit)` → `new FixedAttemptTimeLimit(duration, unit)` → `:90` `new SimpleTimeLimiter()` (Guava: `Executors.newCachedThreadPool()`, unbounded). `:69-72`/`:94` same with a user `ExecutorService`.
- `AttemptTimeLimiters.java:105-108` `FixedAttemptTimeLimit.call` → `timeLimiter.callWithTimeout(callable, duration, timeUnit, true)` (`amInterruptible = true`).
- Guava 22.0 `SimpleTimeLimiter.java:142-168` (deprecated 4-arg `callWithTimeout`):
  - `:149` `Future<T> future = executor.submit(callable);`
  - `:154` `return future.get(timeoutDuration, timeoutUnit);`
  - `:155-157` `catch (InterruptedException e) { future.cancel(true); throw e; }`
  - `:164-166` `catch (TimeoutException e) { future.cancel(true); throw new UncheckedTimeoutException(e); }`
  - No join/wait on the worker after `cancel(true)`. JDK `FutureTask.cancel(true)` CASes the state to INTERRUPTING, calls `runner.interrupt()`, sets INTERRUPTED and returns; the worker keeps executing `callable.call()` until the callable itself reacts to the interrupt. When it later finishes, `FutureTask.set/setException` fails its CAS (state is already cancelled) and the outcome is discarded.
- `Retryer.java:155-185` `call`:
  - `:157` loop; `:160` `V result = attemptTimeLimiter.call(callable);` — every attempt submits the **same** `Callable` instance.
  - `:162-163` any `Throwable` (incl. `UncheckedTimeoutException`, `InterruptedException`) → `ExceptionAttempt`.
  - `:166-168` listeners; `:170-171` predicate does not reject → `return attempt.get()` (returns, or throws `ExecutionException`); `:173-174` stop → `throw new RetryException`; `:176-182` wait/block, then the next iteration goes straight back to `:160`.
  - Nothing tracks, joins or checks the previous attempt's future/worker.

### Call chain (public API → cited code)

`RetryerBuilder.newBuilder().withAttemptTimeLimiter(AttemptTimeLimiters.fixedTimeLimit(d, u)).retryIf…().withStopStrategy(…).build()` → `Retryer.call(callable)` (or `Retryer.wrap(callable)` → `RetryerCallable.call()` `Retryer.java:317-319`) → `FixedAttemptTimeLimit.call` (`AttemptTimeLimiters.java:107`) → `SimpleTimeLimiter.callWithTimeout(…, true)` → `executor.submit(callable)` → pool thread runs `callable.call()`.

Reachability: normal usage. `fixedTimeLimit` is the public, documented way to bound an attempt; the trigger only needs a callable that does not stop on interrupt within the limit — e.g. a blocking `java.net.Socket` stream read on a platform thread, a JDBC call, monitor entry, a CPU loop, or code that swallows `InterruptedException`. The target guidance explicitly admits such callables ("may ignore interrupts, block indefinitely").

### Trigger scenarios

S1 (timeout), matches `hunt_s1_overlap_bfs1/bfs2`:
1. Caller runs `call(c)` with `fixedTimeLimit(T)`, a predicate that retries `UncheckedTimeoutException` (e.g. `retryIfRuntimeException`), `stopAfterAttempt(N)`.
2. Attempt 1: `c.call()` on pool thread P1 blocks in a socket read longer than `T`.
3. At `T`, `future.get` times out → `cancel(true)` interrupts P1 (the read ignores it) → `UncheckedTimeoutException` thrown immediately.
4. Retryer records the failed attempt, notifies listeners, waits, and submits `c` again → P2 runs `c.call()` while P1 is still inside `c.call()` (SequentialAttempts).
5. If attempt 2 succeeds, `call()` returns its result while P1 is still running; P1's later result/exception is discarded (NoActivityAfterOutcome). If the stop strategy fires, `call()` throws `RetryException` while P1..Pn still run.

S2 (caller interrupt), matches `hunt_s2_interrupt_narrow_bfs3`: caller interrupted while blocked in `future.get` → `:155-157` cancel + rethrow `InterruptedException` → `Retryer.java:162-163` wraps it → predicate does not reject (checked exception, `retryIfRuntimeException`) → `Retryer.java:171` throws `ExecutionException(InterruptedException)` while attempt 1 still runs. With `retryIfException`, the next attempt overlaps attempt 1 instead.

### Safeguards encountered (recorded, not dismissed)

- `future.cancel(true)` → `Thread.interrupt()` of the worker: stops only interrupt-responsive callables.
- Retryer: none (no join, no in-flight tracking).
- A user-supplied bounded executor (`fixedTimeLimit(d, u, executor)` with one thread) would serialize attempts behind the stuck one: no overlap, but the next attempt waits in the queue and times out without running, and the stuck attempt still outlives `call()`. The default factory uses an unbounded cached pool.

### MC counterexamples (only the cited ones were read)

- `spec/output/hunt_s1_overlap_bfs1.out` — `SequentialAttempts` violated, 20 states: `CallStart(c1)` → `SubmitNewWorker(c1,t1,w1)` → `WorkerRunTaskStart(w1)` → `WorkerRunnerCAS(w1)` → `GetTimeout(c1)` → `BodyStart(w1,"Ret")` → `CancelCASWon` → `CancelReadRunner` → `CancelDoInterrupt` → `CancelFinish` → `ListenersBegin/Notify/End` → `WaitStrategyComputes(c1,"Zero")` → `BlockZero` → `SubmitNewWorker(c1,t2,w2)` → `WorkerRunTaskStart(w2)` → `WorkerRunnerCAS(w2)` → `BodyStart(w2,"Ret")`. Final: `tbody = (t1 :> "Running" @@ t2 :> "Running")`, `intr[w1] = TRUE`.
- `spec/output/hunt_s1_overlap_bfs2.out` — `NoActivityAfterOutcome` violated, 28 states: same prefix with `BodyStart(w1,"Exc")`, then `BodyReturns(w2)` → `SetCASWon/SetFinish(w2)` → `GetReturn(c1)` → listeners → `PredicateAccepts(c1)`. Final: `outcome = "Returned"`, `tbody[t1] = "Running"`, `tres[t1] = "none"`.
- `spec/output/hunt_s2_interrupt_narrow_bfs3.out` — `NoActivityAfterOutcome` violated, 16 states: `CallStart` → submit/run `t1` → `BodyStart(w1,"Ret")` → `Interrupt(c1)` → `GetInterrupted(c1)` → `Cancel*` → listeners → `PredicateAccepts(c1)`. Final: `outcome = "ExecExc"`, exit tag `CallerIE`, `tbody[t1] = "Running"`.

## Step 2 — Developer-knowledge search (verbatim, not classified)

Docs/comments:
- `Retryer.java:31-35`: "A retryer, which executes a call, and retries it until it succeeds, or a stop strategy decides to stop retrying. A wait strategy is used to sleep between attempts."
- `Retryer.java:141-144` (`call`): "If the rejection predicate accepts the attempt, the stop strategy is used to decide if a new attempt must be made. Then the wait strategy is used to decide how much time to sleep and a new attempt is made."
- `Retryer.java:73/90/109`: "@param attemptTimeLimiter to prevent from any single attempt from spinning infinitely".
- `AttemptTimeLimiter.java:22`: "A rule to wrap any single attempt in a time limit, where it will possibly be interrupted if the limit is exceeded."
- `AttemptTimeLimiters.java:47-52`: "@param duration that an attempt may persist before being circumvented"; points to the `SimpleTimeLimiter(ExecutorService)` note (bounded-executor warning only).
- `RetryerBuilder.java:113`: "Configures the retryer to limit the duration of any particular attempt by the given duration."
- Guava 22.0 `TimeLimiter.newProxy`: "the primary purpose of the proxy object is to return control to the caller when the timeout elapses; aborting the target method call is of secondary concern … it is important that each of the methods on the target object behaves appropriately when its thread is interrupted." 4-arg `callWithTimeout`: "If … the time limit is reached, we attempt to abort the call to the target, and throw an UncheckedTimeoutException". `SimpleTimeLimiter` class doc: "If the time limit expires for a given method call, the thread running the call will be interrupted."
- No TODO/FIXME/"known limitation" at any cited site; README has no time-limit section.

Commits/blame: `7e474be` (dirkraft, 2013-01-16) "add time limit per attempt in a retryer" introduced `Retryer.java:160` and `AttemptTimeLimiters`; PR #1 body: "This provides a mechanism to limit any one single attempt from clobbering a Retryer. Combined with StopStrategies.stopAfterAttempt, it is easier to approximate the max run time." Loop body otherwise dates from 2012-2015 refactors; nothing mentions overlap.

Issue comments: #18 rholder: "The current implementation of an `AttemptTimeLimiter` using `SimpleTimeLimiter` can be fairly wasteful with respect to resources." #29 dirkraft: "the attempt timeout should at a minimum behave like any other exception thrown by an attempt, and be subject to the exception-related retryer configuration." #35 rholder: retryers "should all be thread-safe" and may be shared.

Tests: `AttemptTimeLimiterTest` uses `SleepyOut` (`Thread.sleep`, interrupt-responsive) and only asserts `ExecutionException` caused by `UncheckedTimeoutException`; no test covers interrupt-ignoring callables, overlap, or activity after `call()` ends.

## Step 3 — Known-status / precedent

Search done 2026-11-26 (GitHub API, read-only):
- `rholder/guava-retrying`: all 106 issues + PRs (open and closed, incl. the most recent closed PRs #107 2026-09-05 and #103 2022-07-30) listed; bodies/comments read for #1, #12, #18, #29, #35, #63, #65, #69, #81, #92, #94, #95, #96, #100, #103, #107. Keyword searches (`cancel`, `still running`, `interrupt`, `keeps running`, `concurrently`, `parallel`, `callWithTimeout`, `SimpleTimeLimiter`, `thread leak`, `timeout thread`, `ignores interrupt`, `TimeLimiter`) hit only #12, #18, #63, #94, #96 — all different mechanisms.
- Forks: `rhuffman/re-retrying` (41 items: #17 new CachedThreadPool per `fixedTimeLimit`, #24/#32/#36 interrupt-status handling — different) and `itning/guava-retrying3` (115 items, dependabot plus #1/#71/#72 — nothing relevant).
- Closest: #92 (process does not exit promptly after `call()` returns, `fixedTimeLimit`): its callable never blocks or times out; the cause is idle non-daemon threads of the internally created cached pool (60 s keep-alive) — a different mechanism and site (`AttemptTimeLimiters.java:90` executor lifecycle), not a cancelled attempt still executing user code. #29 (timeout aborts retrying) — exception classification, different.

Recorded result: no issue/PR/advisory reports this mechanism (cancel-without-join of a timed-out/interrupted attempt → overlapping attempts and activity after `call()` ends). MC-sourced with real counterexamples → no pre-filter applies; proceed to Phase 2.

## Repair round 1 continuation (2026-11-26)

Prior disposition `REPRODUCED` (Level 0). This section adds the repair-round-1 evidence; everything above still holds unless stated here.

### Current state re-checked

- Source: worktree HEAD still `177b6c9`, 0 dirty files, `diff -r src` against the pipeline source is empty. Cited lines unchanged: `AttemptTimeLimiters.java:107`, `Retryer.java:155-185`; Guava 22.0 `SimpleTimeLimiter.java:149` (`executor.submit` is outside the `try`), `:155-157`, `:164-166`.
- Upstream: `rholder/guava-retrying` master still `177b6c9` (2016-05-10). Most recently updated items: #84 (README formatting PR, closed unmerged 2026-09-20) and #107 ("Modernize", closed unmerged 2026-09-05). Neither is related. New keyword searches (`RejectedExecutionException`, `bounded executor`, `thread pool full`, `fixedTimeLimit executor`, `overlap attempt`) returned nothing. Novelty unchanged: NEW.
- Persistent registry: `lookup` (incl. `RejectedExecutionException`, `bounded executor`, `MC_hunt_s4_executor`) → `[]`; `show --id MC-1` → no record. Nothing to reuse or revise.

### Repair-round-1 counterexamples (current spec)

- `spec/output/repair-r1/repair1_s1_timelimit_bfs1.out` (`MC_hunt_s1_timelimit.cfg`): `SequentialAttempts` violated, 20 states. `CallStart(c1)` → `SubmitNewWorker(c1,t1,w1)` → `WorkerRunTaskStart(w1)` → `WorkerRunnerCAS(w1)` → `BodyStart(w1,"Ret")` → `GetTimeout(c1)` → `Cancel*` → listeners → `WaitStrategyComputes(c1,"Zero")` → `BlockZero` → `SubmitNewWorker(c1,t2,w2)` → … → `BodyStart(w2,"Ret")`. Final state identical to `hunt_s1_overlap_bfs1`: `tbody = (t1 :> "Running" @@ t2 :> "Running" @@ t3 :> "NotStarted")`, `intr[w1] = TRUE`, `ttag[t1] = "Timeout"`. The only difference is that `BodyStart(w1)` comes before `GetTimeout(c1)`. That is the order scenario A observes (body entered at t≈1 ms, timeout at t≈301 ms).
- `spec/output/repair-r1/repair1_s1_timelimit_bfs2.out`: `NoActivityAfterOutcome` violated, 28 states. `GetTimeout(c1)` fires before `WorkerRunTaskStart(w1)`, and the body is entered (`BodyStart(w1,"Exc")`) before `CancelCASWon(c1)`. After that it matches `hunt_s1_overlap_bfs2`, and the final state is identical (`outcome = "Returned"`, `tbody[t1] = "Running"`, `tres[t1] = "none"`, `tstate[t1] = "INTERRUPTED"`). In real code, the worker enters the body between `future.get` throwing `TimeoutException` (`SimpleTimeLimiter.java:154`) and `future.cancel(true)` (`:165`). `FutureTask.state` stays `NEW` while the body runs, so the cancel CAS still wins and only interrupts.
- The three traces differ only in where `GetTimeout(c1)` (caller thread) falls relative to `WorkerRunTaskStart/WorkerRunnerCAS/BodyStart(w1)` (worker thread). These steps commute and reach the same state at `CancelCASWon`. The earlier trace descriptions in this file therefore remain correct, and the consequence does not depend on this ordering.
- `spec/output/repair-r1/repair1_s4_executor_bfs1.out` (`MC_hunt_s4_executor.cfg`, one worker): `NoActivityAfterOutcome` violated, 23 states. `CallStart(c2)`, `CallStart(c1)` → `SubmitNewWorker(c1,t1,w1)` → `GetTimeout(c1)` → `SubmitQueued(c2,t2)` → `WorkerRunTaskStart(w1)` → `WorkerRunnerCAS(w1)` → `BodyStart(w1,"Ret")` → `CancelCASWon/ReadRunner/DoInterrupt/Finish(c1)` → listeners → `WaitStrategyComputes(c1,"Zero")` → `BlockZero(c1)` → `SubmitRejected(c1)` → listeners → `StopStrategyStops(c1)`. Final: `outcome[c1] = "RetryExc"`, `curTag[c1] = "Rejected"`, `made[c1] = 2`, `tbody[t1] = "Running"`, `wpc[w1] = "Body"`, `queue = <<t2>>`, `cpc[c2] = "Wait"`, `intr[w1] = TRUE`.
  - Real-code path: two threads share one `Retryer` (documented as shareable, #35) built with the public `fixedTimeLimit(d, u, executorService)` (`AttemptTimeLimiters.java:69-72`) and a user `ThreadPoolExecutor` with 1 thread and queue capacity 1.
  - c1's timed-out attempt keeps the only thread, and c2's attempt fills the queue.
  - c1's next attempt hits `executor.submit` (`SimpleTimeLimiter.java:149`, outside the `try`), which throws `RejectedExecutionException` (AbortPolicy). This becomes an `ExceptionAttempt` at `Retryer.java:162-163`, `retryIfRuntimeException` accepts it, and `stopAfterAttempt(2)` makes `Retryer.java:174` throw `RetryException` while t1's body is still running.
  - Same root cause: cancel-without-join at `SimpleTimeLimiter.java:164-166`, with no tracking in `Retryer.call`.

### Prior statement refined (not disproved)

The "Safeguards" bullet above says a one-thread user executor serializes attempts behind the stuck one: there is no overlap, the next attempt waits in the queue and times out without running, and the stuck attempt still outlives `call()`. Repro scenario G0 (`Executors.newSingleThreadExecutor()`) confirms this. Attempts 2 and 3 time out in the queue, `RetryException(3)` is thrown at t≈901 ms with body 1 still running, and only 1 body is ever started. The current counterexample adds the bounded-queue case (S4, scenario G): the next attempt can be rejected outright (`RejectedExecutionException`), which ends `call()` even sooner. The stuck abandoned body also starves other callers sharing the limiter executor: caller-2's callable never ran, and its `call()` ended with `RetryException(2)`. A bounded executor therefore removes the overlap but not `NoActivityAfterOutcome`.

### Developer knowledge (addition)

Guava 22.0 `SimpleTimeLimiter.java:56-58` (same text at `:74-76`, `:89-91`): "Warning: using a bounded executor may be counterproductive! If the thread pool fills up, any time callers spend waiting for a thread may count toward their time limit, and in this case the call may even time out before the target method is ever invoked." This documents queue time counting toward the limit, i.e. attempts that never ran (G0, and caller-2 in G). It does not say that a cancelled attempt keeps executing after the caller's outcome, or that it keeps holding the thread. `AttemptTimeLimiters.java:47-50` points users to this note only for the 2-argument factory.

### Reproduction re-run (extended script)

`repro/test_bugMC-1_timed_out_attempt_overlap.sh` was extended in place with scenarios G and G0. Scenarios A–F and controls D/E are unchanged. Re-run with `timeout 5m` on JDK 21.0.13.1 and JDK 11.0.33.1 (logs `repro-output.jdk21.log`, `repro-output.jdk11.log`): A, B, C, C2, F, G and G0 show the anomaly in 3/3 runs on both JDKs, control D (`noTimeLimit`) in 0/3, and informational E in 0/3. Exit code 0.
