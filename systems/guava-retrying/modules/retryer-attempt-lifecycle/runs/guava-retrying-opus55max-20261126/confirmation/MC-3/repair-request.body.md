---
target: INVARIANT
counterexample: spec/output/hunt_s1_timelimit_bfs1.out
scope:
  actions: [MCGetTimeout, MCSetCASWon, MCSetFinish]
  invariants: [NoDiscardedCompletion]
  hunt_cfgs: [MC_hunt_s1_timelimit.cfg]
  fault_actions: []
---

## Trigger
INVARIANT: the counterexample path is real and reproduces with only the public API (Level 0). It hit 1079 times in 16000 trials across JDK 21 and JDK 11. The state that `NoDiscardedCompletion` flags is the documented time-limit outcome, not a defect. In that state the caller's timed `get` has already decided "timeout" (CE state 9, `MCGetTimeout`, task `COMPLETING`), and the task then publishes `NORMAL` (state 10) before `cancel(true)` runs. In every reproduced instance the callable returned after the earliest possible deadline: +42.3 µs to +117.1 µs after `submit()` returned plus the 1 ms limit. Retryer's caller and listeners see exactly what they see in an ordinary cancelled timeout.

## Evidence
- CE step: in state 8 `MCSetCASWon(w1)` sets `tstate[t1] = "COMPLETING"`. In state 9 `MCGetTimeout(c1)` sets `curTag[c1] = "Timeout"` and `cpc[c1] = "CancelTO"`, with `mc.timeout` going 0 -> 1. In state 10 `MCSetFinish(w1)` sets `tstate[t1] = "NORMAL"` while `curTag[c1]` is still `"Timeout"`, which violates `NoDiscardedCompletion`.
- The predicted state is the state that was realized. `repro/test_bugMC-3_timeout_discards_completion.sh` (Level 0) uses unmodified guava-retrying 2.0.0 at `177b6c9` and Guava 22.0 (sha1 `3564ef3803de51fb0530a8377ec6100b33b0d073`). It passes a forwarding `ExecutorService` to the public `AttemptTimeLimiters.fixedTimeLimit(1, MILLISECONDS, executor)`. Results are in `repro/MC-3.log`:
  - On a hit, attempt 1 is recorded as `UncheckedTimeoutException` (`Retryer.java:162-163`), while `Future#1` is `NORMAL value="result-of-execution-1" isCancelled()=false` and the worker was not interrupted.
  - Hit counts: JDK 21 had 261 (A) and 247 (B); JDK 11 had 319 (A) and 252 (B).
  - Return time relative to `submit()` + limit for those hits ranged from +42.3 µs to +117.1 µs.
- The outcome is indistinguishable from the admitted timeout (same log, "visible outcome per kind"):
  - Config A (`retryIfException()` + `stopAfterAttempt(2)`): both the MC-3 state and the control (Future cancelled) give "attempt#1=exception(UncheckedTimeoutException), callable executions=2, call() returned result-of-execution-2" (261 vs 1714 trials on JDK 21).
  - Config B (default predicate): both give "call() threw ExecutionException(UncheckedTimeoutException)" (247 vs 1730 trials).
  - Timeouts that never reached `cancel` (the `TIMEOUT_CANCELLED` control) also had completions as early as +36.0 µs. `SUCCESS` trials had completions as late as +1486.7 µs, because the caller woke up late.
- Developer intent: the implementation does not promise that a completion racing the abort wins.
  - Guava 22.0 `TimeLimiter.java:79-83`, `:94` (contract of the 4-argument `callWithTimeout` called at `AttemptTimeLimiters.java:107`): "If the target method call finished before the limit is reached, the return value or exception is propagated to the caller exactly as-is. If, on the other hand, the time limit is reached, we attempt to abort the call to the target, and throw an UncheckedTimeoutException to the caller." Also "@throws UncheckedTimeoutException if the time limit is reached".
  - Guava 22.0 `TimeLimiter.java:47-51`: "the primary purpose of the proxy object is to return control to the caller when the timeout elapses; aborting the target method call is of secondary concern".
  - Guava `master` still ignores `cancel`'s result on every timeout path (`SimpleTimeLimiter.java:129-131`, `:149-150`, `:172-173`, `:192-193`, `:212-213`; the newest commit touching the file is 3b1c73103d, 2026-07-28).
  - guava-retrying `AttemptTimeLimiter.java:22` ("where it will possibly be interrupted if the limit is exceeded") and `AttemptTimeLimiters.java:52`, `:63` ("@param duration that an attempt may persist before being circumvented"), both from 7e474be by dirkraft. Also `RetryerBuilder.java:111`.
  - Upstream issue #29 maintainer comment: "the attempt timeout should at a minimum behave like any other exception thrown by an attempt, and be subject to the exception-related retryer configuration".
  - Test `AttemptTimeLimiterTest.java:44-50` asserts `ExecutionException` caused by `UncheckedTimeoutException` for an attempt that runs over the limit.
- Code: the timeout is decided only after the deadline has elapsed and the task was not `NORMAL`. In JDK 11 `FutureTask.java:406-415`, `NORMAL` at the loop top returns the result and `COMPLETING` at the loop top yields. Lines `:436-438` mean the deadline elapsed and the method returns `state`. Lines `:202-204` throw `TimeoutException` only when `state <= COMPLETING`. JDK 21 `cancel`, `awaitDone` and timed `get` are textually identical. A task that is already `NORMAL` when the decision is taken always yields its result, so nothing in the implementation treats the flagged state as bad.

## Proposed change
Revise `NoDiscardedCompletion` to the property the contract supports: a timeout may be recorded for an attempt only if the caller's timed get decided while the task was not yet `NORMAL`. A task completed before the timeout decision must yield its result; the code guarantees this at `FutureTask.java:406-410` and `:202-204`. A completion that lands between that decision and `cancel(true)` should no longer be flagged; that covers both the `NEW`-at-decision and the `COMPLETING`-at-decision interleavings. If this cannot be stated non-vacuously in the model (for example because `MCGetTimeout` is already guarded on `tstate` in {NEW, COMPLETING}), remove `NoDiscardedCompletion` from `MC_hunt_s1_timelimit.cfg` and mark it not applicable rather than replacing it with a tautology. Leave the caller-interrupt variant (`SimpleTimeLimiter.java:156`, MC-4) untouched.
