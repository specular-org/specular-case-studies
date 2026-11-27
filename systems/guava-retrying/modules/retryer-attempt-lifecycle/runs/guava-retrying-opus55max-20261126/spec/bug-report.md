# Bug Report — guava-retrying 2.0.0

Model-checking findings from the converged spec (`base.tla` + `MC.tla`, converged in 1 round: 379/379 traces replay, `MC.cfg` exhaustive without violation). Repair round 1 (RR-001, RR-002; 2026-11-26) revised `NoDiscardedCompletion` and `CountedImpliesInvokedNoStartRace` after Phase 4 reproduced two counterexamples and found them to be documented behavior; the spec still replays 380/380 traces and `MC.cfg` is still exhaustive without violation. Former Bugs 3 and 8 are withdrawn (section "Withdrawn after repair round 1"); the other bug numbers are unchanged. Every counterexample below was read state by state and checked against the target source (`src/main/java/com/github/rholder/retry/`, commit 177b6c9 = v2.0.0), Guava 22.0 `SimpleTimeLimiter`, and JDK 11 `FutureTask` / `ThreadPoolExecutor` / `SynchronousQueue` / `ArrayList`. "Case C" means the model is faithful, the property is a documented promise, and the implementation can reach the violation. These are model-level results; reproduction on a JVM is Phase 4's job (the analysis-phase probes cited in `modeling-brief.md` §6.2 are independent evidence).

## Summary

- Scenarios tested: 5 (S1–S5 of `modeling-brief.md` §2) through 12 safety hunt configs, 1 liveness config, and 5 filtered hunting checks (`MCHunt.tla`)
- Bugs found: 10 current — 8 new candidates (Bugs 1, 2, 4–7, 9, 10) and 2 known upstream issues reproduced (Bug 11 = #48, Bug 12 = #29). Bugs 3 and 8 (12 before repair round 1) were withdrawn as documented behavior (RR-001, RR-002); their numbers are not reused
- Configs run: MC_hunt_s1_timelimit.cfg, MC_hunt_s1_overlap.cfg, MC_hunt_s2_interrupt_fixed.cfg, MC_hunt_s2_interrupt_narrow.cfg, MC_hunt_s2_interrupt_nolimit.cfg, MC_hunt_s2_wrap_cancel.cfg, MC_hunt_s2_live.cfg, MC_hunt_s3_listeners.cfg, MC_hunt_s4_executor.cfg, MC_hunt_s4_shutdown.cfg, MC_hunt_s4_wrap_samepool.cfg, MC_hunt_s5_decision.cfg, MC_hunt_sharing.cfg
- Method per config: BFS until the first violation; analyze it; disable the property it violates (with the counterexample's file noted in the derived cfg, `hunt/*.cfg`) or check a filtered variant; rerun until BFS exhausts the state space or the 30-minute budget ends; a simulation follow-up for configs whose BFS did not exhaust.
- Shared root causes (relevant for counting): Bugs 4, 5 and 6 are three consequences of one catch-all at `Retryer.java:162-163` that turns an `InterruptedException` into an ordinary failed attempt (a single fix covers all three). Bugs 1 and 2 share Guava's cancel-and-forget in `SimpleTimeLimiter.callWithTimeout`; Bug 2 adds the private, never-shut-down cached pool of the two-argument `fixedTimeLimit`. Bug 7 is a new consequence of the aliasing reported in #48 (Bug 11).

### Model Checking Coverage

| Config | Run | Distinct states | Depth | Exhausted | Result |
|---|---|---|---|---|---|
| MC.cfg (convergence) | BFS | 5,839,963 | 61 | yes | no violation (TypeOK, StructuralOK, MCModelBoundsAdequate, InterruptContainment, RetryAccounting) |
| MC.cfg (repair round 1) | BFS | 5,867,867 | 61 | yes | no violation, same invariants (`output/repair-r1/repair1_MC.out`); +27,904 states because the RR-002 ghost now separates a rejection after `shutdown()` from a capacity rejection followed by `shutdown()`, which had identical values before |
| MC_hunt_s1_timelimit | BFS 1 | 173 | 13 | stopped | NoDiscardedCompletion (former Bug 3, withdrawn by RR-001); continuation = s1_overlap (same model minus that property) |
| MC_hunt_s1_timelimit (repair round 1; NoDiscardedCompletion off, see Not Reproduced) | BFS 1–3 + MCHunt d3a, d3b | 301,871 (final) | 51 | yes (r3) | **SequentialAttempts**, **NoActivityAfterOutcome** (Bug 1); **StuckBodiesEndWithCall**, **StuckBodiesPerCallAtMostOne** (Bug 2); rest hold. Same model and properties as s1_overlap, same results (`output/repair-r1/repair1_s1_timelimit_*.out`) |
| MC_hunt_s1_overlap | BFS 1–3 | 301,871 (final) | 51 | yes (r3) | **SequentialAttempts**, **NoActivityAfterOutcome** (Bug 1); rest hold |
| MC_hunt_s1_overlap + MCHunt (d3a, d3b) | BFS | 18,306 / 2,078 | 29 / 23 | stopped | **StuckBodiesEndWithCall**, **StuckBodiesPerCallAtMostOne** (Bug 2) |
| MC_hunt_s2_interrupt_fixed | BFS 1–7 | 7,566 (final) | 35 | yes (r7) | CountedImpliesInvoked, NoDiscardedCompletion, NoRetryAfterObservedInterrupt, InterruptPreserved (Bug 4); SequentialAttempts, NoActivityAfterOutcome (Bug 1); rest hold |
| MC_hunt_s2_interrupt_narrow | BFS 1–4 | 4,076 (final) | 35 | yes (r4) | ExecutionExceptionMeansCallableThrew + InterruptPreserved, NoDiscardedCompletion (Bug 4); NoActivityAfterOutcome (Bug 1); rest hold |
| MC_hunt_s2_interrupt_nolimit | BFS 1–3 | 145 (final) | 17 | yes (r3) | NoRetryAfterObservedInterrupt, InterruptPreserved (Bug 5); rest hold |
| MC_hunt_s2_wrap_cancel | BFS 1–7 | 519,542 (final) | 52 | yes (r7) | CancelledWrapperStops first counterexample = invariant mismatch (Case A, revised); then NoDiscardedCompletion (timeout path: former Bug 3, withdrawn; repair round 1 found the remaining caller-interrupt path violated as well, Bug 4), NoRetryAfterObservedInterrupt + CancelledWrapperStops, InterruptPreserved (Bug 6), NoActivityAfterOutcome, SequentialAttempts (Bug 1); rest hold |
| MC_hunt_s2_live (liveness) | BFS | 23,212 | 71 | yes (BFS finished, then liveness check) | **InterruptedCallEventuallyExits** violated (Bug 6); persists with CountCap 2 → 3 (21,732 states); premise `NoInterruptDeliveredInv` violated (premise reachable); control RetryOn = {CallableExc}: exhaustive (9,264), property holds |
| MC_hunt_s3_listeners | BFS 1–3 | 152 (final) | 18 | yes (r3) | DocumentedOutcomesOnly + NoLostAttemptOutcome (Bug 7); ListenersFixedAtBuild (Bug 11, known #48); rest hold |
| MC_hunt_s4_executor | BFS 1–4 | 168,438 (final) | 62 | yes (r4) | CountedImpliesInvokedNoStartRace (former Bug 8), NoDiscardedCompletion (former Bug 3), both withdrawn; NoActivityAfterOutcome (Bug 1); rest hold |
| MC_hunt_s4_executor (repair round 1; both properties off, see Not Reproduced) | BFS 1–2 | 168,438 (final) | 62 | yes (r2) | **NoActivityAfterOutcome** (Bug 1: the timed-out body keeps the only thread while `call()` ends with `RetryException`; `output/repair-r1/repair1_s4_executor_bfs1.out`); rest hold |
| MC_hunt_s4_shutdown | BFS 1–5 | 35,037 (final) | 51 | yes (r5) | CountedImpliesInvokedNoStartRace, ExecutionExceptionMeansCallableThrewExcept29 (Bug 9; both regenerated on the repaired spec in repair round 1); NoDiscardedCompletion (former Bug 3, withdrawn; now off here); NoActivityAfterOutcome (Bug 1); rest hold |
| MC_hunt_s4_shutdown + MCHunt (k29) | BFS | 135 | 13 | stopped | **TimeoutDoesNotEndCallWithExecutionException** (Bug 12, known #29) |
| MC_hunt_s4_wrap_samepool | BFS 1–2 | 38 (final) | 38 | yes (r2) | CountedImpliesInvokedNoStartRace (former Bug 8, withdrawn); rest hold |
| MC_hunt_s4_wrap_samepool (repair round 1; both properties off) | BFS 1 | 38 | 38 | yes | no violation (`output/repair-r1/repair1_s4_wrap_samepool_bfs1.out`) |
| MC_hunt_s5_decision | BFS 1–2 | 244 (final) | 25 | yes (r2) | DocumentedOutcomesOnly (Bug 10); rest hold |
| MC_hunt_s5_decision + MCHunt (r3) | BFS | 135 | 16 | stopped | **InterruptedCallThrowsRetryException** (Bug 10, interrupt composition) |
| MC_hunt_sharing | BFS 1–9 + simulation | BFS r9: 29,551,969 in 30 min (6.48M left on queue); simulation: 12,731,503 traces, 823,550,887 states (~65 steps/trace, depth limit 200) | 39 (BFS level at the budget) | no (budget-limited) | DocumentedOutcomesOnly + NoLostAttemptOutcome (Bug 7); CountedImpliesInvokedNoStartRace, InterruptPreserved, NoRetryAfterObservedInterrupt (Bug 4); NoDiscardedCompletion (timeout path: former Bug 3, withdrawn; repair round 1 found the caller-interrupt path violated too, Bug 4); ListenersFixedAtBuild (Bug 11); NoActivityAfterOutcome, SequentialAttempts (Bug 1); after those were analyzed and disabled, the 30-min BFS and the 30-min simulation found no violation of ExecutionExceptionMeansCallableThrew, CancelledWrapperStops or the structural / baseline invariants (`hunt_sharing_bfs9.out`, `hunt_sharing_sim.out`) |

### Repair round 1 checks of the revised invariants

Derived cfgs in `hunt/repair-r1/` (same model as the named hunt cfg; INVARIANTS = TypeOK, StructuralOK, MCModelBoundsAdequate, InterruptContainment, RetryAccounting plus the listed properties); outputs in `output/repair-r1/`.

| Check | Cfg (model) | Properties | Result |
|---|---|---|---|
| Acceptance: the revised predicates hold on every reachable state, including the MC-3 path | `ctl_s1_timelimit_revised` (s1_timelimit) | NoDiscardedCompletion, CountedImpliesInvokedNoStartRace | exhaustive, 301,871 states, depth 51, no violation |
| Acceptance, including the MC-8 paths (queued timeout, capacity rejection) | `ctl_s4_executor_revised` (s4_executor) | both | exhaustive, 168,438 states, depth 62, no violation |
| Acceptance, `wrap()` on the limiter's pool | `ctl_s4_wrap_samepool_revised` | both | exhaustive, 38 states, no violation |
| Falsifiability: completion discarded by the caller-interrupt path | `ctl_s2_interrupt_fixed_ndc` | NoDiscardedCompletion | violated, 11 states: the caller's state read saw NEW, the task became NORMAL, then the interrupt test wins (Bug 4) |
| Caller-interrupt path through a `wrap()` cancellation (never hunted before: the timeout path fired first) | `ctl_s2_wrap_cancel_ndc` | NoDiscardedCompletion | violated, 11 states: the outer `cancel(true)` interrupt reaches the caller between its state read (NEW) and its interrupt test; by then the task is EXCEPTIONAL, and its outcome is discarded (Bug 4) |
| Same with two callers | `ctl_sharing_ndc` | NoDiscardedCompletion | violated, 11 states: c1's `get` throws on the interrupt while its task is NEW, the body then completes NORMAL before the cancel CAS (Bug 4) |
| Falsifiability: rejection by a shut-down executor counted as an attempt | `ctl_s4_shutdown_cir` | CountedImpliesInvokedNoStartRace | violated, 4 states (Bug 9; `curQueued` FALSE after `shutdown()`) |
| Falsifiability: attempt cancelled before it ran because of a caller interrupt | `ctl_sharing_cir` | CountedImpliesInvokedNoStartRace | violated, 8 states (Bug 4, D-5) |
| Bug 9 counterexample on the repaired spec | `s4_shutdown-r2` (canonical s4_shutdown, CountedImpliesInvokedNoStartRace off) | all others | ExecutionExceptionMeansCallableThrewExcept29 violated, 8 states (`repair1_s4_shutdown_bfs2.out`) |

`InterruptContainment` (brief MC-8: a cancellation interrupt never reaches another task's body) and `RetryAccounting` (MC-9: `RetryException` count = attempts made, `stopAfterAttempt(K)` bounds attempts) held in every run, including `MC.cfg` and the 379 replayed traces.

Liveness used 4 short BFS runs (seconds each), well under 30% of the hunting compute.

---

## Bug 1: A timed-out attempt keeps running alongside later attempts and after `call()` has returned or thrown

- **Scenario**: S1 (time-limited attempts escape the attempt sequence); the same overlap is reached through a caller interrupt (S2) and a saturated executor (S4). Ledger D-1. Guidance Q1.
- **Severity**: High
- **Invariant violated**: `SequentialAttempts`, `NoActivityAfterOutcome`
- **Config**: MC_hunt_s1_overlap.cfg (also MC_hunt_s2_interrupt_fixed.cfg, MC_hunt_s2_interrupt_narrow.cfg, MC_hunt_s2_wrap_cancel.cfg, MC_hunt_s4_executor.cfg, MC_hunt_s4_shutdown.cfg, MC_hunt_sharing.cfg)
- **Counterexample**: 20 states, `spec/output/hunt_s1_overlap_bfs1.out` (SequentialAttempts); 28 states, `spec/output/hunt_s1_overlap_bfs2.out` (NoActivityAfterOutcome); interrupt trigger: 16 states, `spec/output/hunt_s2_interrupt_narrow_bfs3.out`. Repair round 1 (current spec): the same two violations in MC_hunt_s1_timelimit.cfg (`spec/output/repair-r1/repair1_s1_timelimit_bfs1.out`, `_bfs2.out`) and, with a saturated bounded executor, 23 states, `spec/output/repair-r1/repair1_s4_executor_bfs1.out` (c1's timed-out body keeps the only thread, c1's next attempt is rejected, `call()` throws `RetryException` while the body still runs)

### Trace Summary

`hunt_s1_overlap_bfs1.out` — `fixedTimeLimit(d, unit)` (private cached pool), `retryIfException()`, `stopAfterAttempt(3)`, `noWait`:
1. States 2–5: `call()` starts; attempt 1 is submitted (`SimpleTimeLimiter.java:149`) to a new pool thread w1, which passes `FutureTask.run`'s state check and runner CAS.
2. State 6: the caller's timed `get` reaches the deadline with the task still NEW → `TimeoutException` (`FutureTask.java:437-438, 202-204`).
3. State 7: w1 enters the callable body (behavior `Ret`: long-running, never looks at the interrupt status, e.g. a blocking socket read).
4. States 8–11: Guava's `future.cancel(true)` wins the CAS, reads the runner w1, interrupts it and sets INTERRUPTED (`FutureTask.java:164-181`); `UncheckedTimeoutException` is thrown (`SimpleTimeLimiter.java:164-166`) and recorded as attempt 1 (`Retryer.java:162-163`).
5. States 12–16: listener, predicate (retries timeouts), `noWait`, `Thread.sleep(0)`, `attemptNumber++`.
6. States 17–20: attempt 2 is submitted; no pool thread is idle (w1 is still inside attempt 1's body), so a new thread w2 starts and enters the body. **Two bodies of the same `call()` — the same `Callable` instance — now run concurrently.**

`hunt_s1_overlap_bfs2.out` continues the same pattern: attempt 2 completes (states 21–23), `call()` returns its result (state 28) while attempt 1's body is still running; its eventual result or exception will be dropped when its `set` CAS fails against INTERRUPTED (`FutureTask.java:229, 247`). In `hunt_s2_interrupt_narrow_bfs3.out` the trigger is a caller interrupt instead of the deadline: `Future.get` throws `InterruptedException`, Guava cancels, and `call()` throws `ExecutionException(InterruptedException)` (state 16) while the cancelled body keeps running.

### Root Cause

`SimpleTimeLimiter.callWithTimeout` (Guava 22.0, `SimpleTimeLimiter.java:142-168`) reacts to a timeout or a caller interrupt by calling `future.cancel(true)` and returning at once (`:155-157`, `:164-166`); it never waits for, joins or tracks the worker. Cancellation only interrupts the runner, so a callable that ignores interrupts (or blocks uninterruptibly) keeps running. `FixedAttemptTimeLimit.call` (`AttemptTimeLimiters.java:107`) hands that straight to `Retryer.call`, which immediately builds the `Attempt` and either starts the next attempt or returns/throws (`Retryer.java:157-184`). Nothing in guava-retrying admits overlap: the class Javadoc describes a call that is executed and retried "until it succeeds, or a stop strategy decides to stop" (`Retryer.java:32-35`), and `AttemptTimeLimiter` only says the attempt "will possibly be interrupted".

### Affected Code

- `AttemptTimeLimiters.java:105-108`: `FixedAttemptTimeLimit.call` delegates to `callWithTimeout(callable, d, unit, true)`
- `Retryer.java:157-184`: the next attempt starts (or `call()` ends) right after the limiter returns
- Guava `SimpleTimeLimiter.java:149-166`: submit, timed get, cancel-and-forget

### Recommendation

Keep the `Future` of a timed-out or interrupted attempt and do not start the next attempt (or return) until it has terminated — or at least wait a bounded time and report a still-running attempt explicitly. If overlap is accepted, document that timed-out attempts may run concurrently with later attempts and after `call()` ends, and that callables must respond to interruption.

---

## Bug 2: A never-returning timed-out attempt pins a pool thread forever, and each further attempt takes another thread

- **Scenario**: S1. Ledger D-3. Guidance Q1 ("worker threads outlive the retryer's use"). Related known issue #92 reports only the ~60 s exit delay caused by idle pool threads after a normal run; the per-attempt accumulation is not reported.
- **Severity**: High
- **Invariant violated**: `StuckBodiesEndWithCall`, `StuckBodiesPerCallAtMostOne` (`MCHunt.tla`, filtered refinements of `NoActivityAfterOutcome` / `SequentialAttempts` for uninterruptible never-returning bodies)
- **Config**: MC_hunt_s1_overlap.cfg (derived `hunt/s1_overlap-d3a.cfg`, `hunt/s1_overlap-d3b.cfg`, spec `MCHunt.tla`)
- **Counterexample**: 28 states, `spec/output/hunt_s1_overlap_d3a.out`; 20 states, `spec/output/hunt_s1_overlap_d3b.out`. Repair round 1 (current spec, MC_hunt_s1_timelimit.cfg = the s1_overlap model): `spec/output/repair-r1/repair1_s1_timelimit_d3a.out`, `spec/output/repair-r1/repair1_s1_timelimit_d3b.out`

### Trace Summary

`hunt_s1_overlap_d3b.out`: attempt 1 runs a `Stuck` body (uninterruptible, never returns — a socket read without `SO_TIMEOUT`) on w1; the deadline passes and `cancel(true)` interrupts w1, which ignores it; attempt 2 (also `Stuck`) finds no idle pool thread and the cached pool starts w2 (state 17), which also gets stuck (state 20). One `call()` now pins two pool threads, and the count grows by one per timed-out attempt. `hunt_s1_overlap_d3a.out`: attempt 2 is a normal body; `call()` returns its result (state 28) while w1 stays inside attempt 1's stuck body with no way to ever leave it.

### Root Cause

Bug 1's cancel-and-forget, combined with the two-argument factory: `fixedTimeLimit(d, unit)` builds `new SimpleTimeLimiter()` (`AttemptTimeLimiters.java:57-60, 89-91`), whose executor is a private `Executors.newCachedThreadPool()` (`SimpleTimeLimiter.java:82-83`): unbounded, non-daemon threads, never shut down, and unreachable from the API (`AttemptTimeLimiter` has only `call`, `AttemptTimeLimiter.java:27-34`). A thread stuck in a timed-out body is never reclaimed, so the thread count grows with the number of timed-out attempts (without bound under `neverStop` or a long `stopAfterDelay`), the threads outlive `call()` and the `Retryer`, and (from the code, not modeled) the non-daemon threads keep the JVM from exiting.

### Affected Code

- `AttemptTimeLimiters.java:57-60, 89-91`: per-limiter private cached pool, no shutdown path
- Guava `SimpleTimeLimiter.java:82-83, 155-157, 164-166`
- `Retryer.java:157-184`

### Recommendation

Use a daemon, bounded (or caller-supplied and caller-owned) executor for `fixedTimeLimit(d, unit)` and give the limiter a lifecycle (`close()`/`shutdown()`), or deprecate the two-argument factory; document that a timed-out attempt that never returns keeps its thread.

---

## Bug 4: A caller interrupt during a time-limited attempt is swallowed: retrying continues, `call()` returns normally or throws `ExecutionException`, and the interrupt status is lost

- **Scenario**: S2 (with `fixedTimeLimit`). Ledger D-5. Guidance Q2.
- **Severity**: High
- **Invariant violated**: `NoRetryAfterObservedInterrupt`, `InterruptPreserved`, `ExecutionExceptionMeansCallableThrew`, `CountedImpliesInvoked` (and `CountedImpliesInvokedNoStartRace` with two callers), `NoDiscardedCompletion` (since RR-001 this property checks only this interrupt path)
- **Config**: MC_hunt_s2_interrupt_fixed.cfg, MC_hunt_s2_interrupt_narrow.cfg (also MC_hunt_sharing.cfg, MC_hunt_s2_wrap_cancel.cfg)
- **Counterexample**: 25 states, `spec/output/hunt_s2_interrupt_fixed_bfs5.out` (InterruptPreserved); 14 states, `hunt_s2_interrupt_fixed_bfs3.out` (NoRetryAfterObservedInterrupt); 12 states, `hunt_s2_interrupt_narrow_bfs1.out` (ExecutionExceptionMeansCallableThrew + InterruptPreserved); 8 states, `hunt_s2_interrupt_fixed_bfs1.out` (CountedImpliesInvoked); 11 states, `hunt_s2_interrupt_fixed_bfs2.out` (NoDiscardedCompletion). Repair round 1 (current spec): NoDiscardedCompletion, 11 states each, `spec/output/repair-r1/repair1_ctl_s2_interrupt_fixed_ndc.out`, `repair1_ctl_s2_wrap_cancel_ndc.out` (interrupt from a `wrap()` cancellation), `repair1_ctl_sharing_ndc.out` (two callers); CountedImpliesInvokedNoStartRace, 8 states, `repair1_ctl_sharing_cir.out`

### Trace Summary

`hunt_s2_interrupt_fixed_bfs5.out` (`retryIfException()`, `stopAfterAttempt(2)`):
1. States 2–4: `call()` submits attempt 1; the calling thread is interrupted (another thread calls `Thread.interrupt()`).
2. State 5: `FutureTask.awaitDone` finds the task NEW, `Thread.interrupted()` returns true and **clears the status**, and `get` throws `InterruptedException` (`FutureTask.java:406, 416-419`).
3. States 6–8: Guava cancels attempt 1 (its runner is still null, so the callable never runs) and rethrows (`SimpleTimeLimiter.java:155-157`); `Retryer.call` records it as an ordinary failed attempt (`Retryer.java:162-163`).
4. States 9–13: the predicate matches it; `Thread.sleep(0)` finds no pending interrupt (already cleared), so no `RetryException`; attempt 2 starts.
5. States 14–25: attempt 2 returns a value and `call()` **returns normally with the interrupt status clear**.

`hunt_s2_interrupt_narrow_bfs1.out` (`retryIfExceptionOfType(IOException)`): the caller is interrupted before `call()`; `submit` ignores it, `get` throws and clears it, the attempt is cancelled before it runs, the predicate does not match, and `call()` throws `ExecutionException(InterruptedException)` with the status clear (state 12) — documented only for "the given callable throws an exception" (`Retryer.java:148-150`), although the callable never ran. `hunt_s2_interrupt_fixed_bfs2.out`: the attempt completes between the caller's state read and its interrupt test; the interrupt wins, `cancel` returns `false` (ignored) and the completed attempt is recorded as interrupted and repeated. Repair round 1 reaches the same discard when the interrupt comes from `cancel(true)` on a `wrap()` future (`repair1_ctl_s2_wrap_cancel_ndc.out`) and with two callers (`repair1_ctl_sharing_ndc.out`). The timeout-path counterpart (former Bug 3) was withdrawn by RR-001 as the documented timeout outcome; RR-001 left this interrupt path unchanged, and Phase 4 reproduced it (MC-4).

### Root Cause

With `amInterruptible = true` (`AttemptTimeLimiters.java:107`), Guava's `Future.get` consumes the caller's interrupt and rethrows `InterruptedException` after cancelling the attempt (`SimpleTimeLimiter.java:152-157`); Guava documents this as "aborting the operation and throwing InterruptedException" (`TimeLimiter.java:88-93`), so restoring the interrupt is the caller's job. `Retryer.call` catches every `Throwable` from the limiter (`Retryer.java:162-163`) and lets the rejection predicate, not the interrupt, decide; it restores the interrupt status only around `blockStrategy.block` (`Retryer.java:179-181`). This contradicts `Retryer.java:151-153` ("if the thread is interrupted, this exception is thrown and the thread's interrupt status is set") and `Retryer.java:59-61` (no retry once the thread is interrupted).

### Affected Code

- `Retryer.java:162-163`: catch-all turns `InterruptedException` into an attempt
- `Retryer.java:170-182`: predicate / stop / sleep decide; the only restore point is `:179-181`
- `AttemptTimeLimiters.java:107`; Guava `SimpleTimeLimiter.java:152-157`

### Recommendation

In `Retryer.call`, treat an `InterruptedException` from the attempt (and, defensively, a set interrupt status after the attempt) like the interrupted sleep: restore the status with `Thread.currentThread().interrupt()` and throw `RetryException` without consulting the predicate.

---

## Bug 5: Without a time limit, an `InterruptedException` thrown by the callable on the caller thread is retried and the interrupt status is lost

- **Scenario**: S2 (no time limiter). Ledger D-6. Guidance Q2 ("or when the callable itself throws InterruptedException"). Same root cause as Bug 4.
- **Severity**: High
- **Invariant violated**: `NoRetryAfterObservedInterrupt`, `InterruptPreserved`
- **Config**: MC_hunt_s2_interrupt_nolimit.cfg
- **Counterexample**: 11 states, `spec/output/hunt_s2_interrupt_nolimit_bfs1.out`; 16 states, `spec/output/hunt_s2_interrupt_nolimit_bfs2.out`

### Trace Summary

`hunt_s2_interrupt_nolimit_bfs2.out` (`noTimeLimit`, `retryIfException()`, `stopAfterAttempt(2)`):
1. State 3: attempt 1's callable runs on the caller thread (`AttemptTimeLimiters.java:77-78`) and blocks in an interruptible call (`IntrBlock`, e.g. `Object.wait`).
2. States 4–5: the calling thread is interrupted; the callable throws `InterruptedException`, which clears the status; `Retryer.java:162-163` records it as attempt 1.
3. States 6–10: the predicate matches; `Thread.sleep(0)` sees no interrupt; attempt 2 starts.
4. States 11–16: attempt 2 returns a value and `call()` **returns normally with the status clear**. `bfs1` shows the retry itself (attempt 2 starts after the interrupt was observed).

### Root Cause

Same catch-all as Bug 4 (`Retryer.java:162-163`): an interrupt of the thread running `call()`, observed by the callable, becomes an ordinary failed attempt; the status is restored only at `Retryer.java:179-181`. Contradicts `Retryer.java:59-61, 151-153`.

### Affected Code

- `Retryer.java:162-163, 170-182`
- `AttemptTimeLimiters.java:77-78`

### Recommendation

As Bug 4 (one fix in `Retryer.call` covers both).

---

## Bug 6: A `wrap()` task cancelled with `cancel(true)` / `shutdownNow()` keeps retrying forever (or returns normally), and its worker thread is never released

- **Scenario**: S2 (`wrap()` on an executor). Ledger D-7. Guidance Q2 and must-cover "`wrap()` on an executor". Consequence of Bug 4/5's root cause.
- **Severity**: High
- **Invariant violated**: `InterruptedCallEventuallyExits` (liveness, the cfg's `PROPERTY`); safety: `NoRetryAfterObservedInterrupt`, `CancelledWrapperStops`, `InterruptPreserved`
- **Config**: MC_hunt_s2_live.cfg (liveness); MC_hunt_s2_wrap_cancel.cfg (safety)
- **Counterexample**: 43-state lasso (back to state 30), `spec/output/hunt_s2_live_bfs.out`; persists with CountCap 3: `spec/output/hunt_s2_live_cap3.out`; 14 states, `spec/output/hunt_s2_wrap_cancel_bfs3.out`; 25 states, `spec/output/hunt_s2_wrap_cancel_bfs6.out`

### Trace Summary

Liveness (`executor.submit(retryer.wrap(callable))`, `fixedTimeLimit`, `retryIfException()`, `neverStop`, a callable that always throws `IOException`):
1. States 2–3: the outer task starts `RetryerCallable.call` → `retryer.call` (`Retryer.java:317-319`); the outer future is cancelled with `cancel(true)`, which interrupts the thread running `call()`.
2. States 4–8: attempt 1's `get` consumes the interrupt (`InterruptedException`, status cleared); Guava cancels attempt 1; it is recorded as a failed attempt (Bug 4).
3. States 9–29: the predicate retries; attempt 2 runs and throws `IOException`; retried.
4. States 30–43, repeating forever: submit, the callable throws, `GetReturn`, listener, predicate, `sleep(0)`, next attempt. **The cancelled task never ends**: the thread of the outer executor is never released and `awaitTermination` never succeeds.

The loop uses only caller steps (`Retryer.call`, `Retryer.java:157-184`) and pool-worker steps (`TPE.runWorker` / `FutureTask.run`), which have weak fairness in `LiveSpec` (`MC.tla` `Fairness`); no fault action repeats. The premise check (`NoInterruptDeliveredInv`) is violated, so the premise is reachable; raising `CountCap` from 2 to 3 keeps the violation; the control `RetryOn = {"CallableExc"}` (`retryIfExceptionOfType(IOException)`) makes BFS finish without violation. Safety views: `hunt_s2_wrap_cancel_bfs3.out` shows attempt 2 submitted after the cancellation was observed (state 14); `hunt_s2_wrap_cancel_bfs6.out` shows the cancelled task's `call()` **returning normally** with the status clear (state 25).

### Root Cause

`wrap()` (`Retryer.java:195-197, 301-320`) relies only on the thread interrupt for cancellation, and `Retryer.call` turns the interrupt into an ordinary failed attempt (`Retryer.java:162-163`, Bug 4) — with or without a time limiter (Bug 5). With a predicate that matches `InterruptedException` and a stop strategy that does not fire, the loop never ends.

### Affected Code

- `Retryer.java:162-163, 170-182`: interrupt consumed and retried
- `Retryer.java:195-197, 317-319`: `wrap()` / `RetryerCallable.call`

### Recommendation

The Bug 4 fix (stop with `RetryException` and restore the status when an attempt ends with `InterruptedException`) also makes cancelled `wrap()` tasks terminate.

---

## Bug 7: Adding a listener to the builder while a built `Retryer` runs makes `call()` throw `ConcurrentModificationException` after the attempt executed; its outcome is lost

- **Scenario**: S3. Ledger D-8. Guidance Q3. Same root cause as known #48 (Bug 11); this concurrent consequence is not reported upstream.
- **Severity**: Medium
- **Invariant violated**: `DocumentedOutcomesOnly`, `NoLostAttemptOutcome`
- **Config**: MC_hunt_s3_listeners.cfg (also MC_hunt_sharing.cfg)
- **Counterexample**: 7 states, `spec/output/hunt_s3_listeners_bfs1.out`; 10 states, `spec/output/hunt_sharing_bfs1.out`

### Trace Summary

1. States 2–4: `call()` runs attempt 1 (`noTimeLimit`); the callable returns a value.
2. State 5: the listener loop starts: `ArrayList.iterator()` records `expectedModCount = modCount = 1` (`Retryer.java:166`; JDK `ArrayList.java:986`).
3. State 6: another thread calls `builder.withRetryListener(l2)` → `ArrayList.add` → `modCount++` (`RetryerBuilder.java:63`; `ArrayList.java:498`).
4. State 7: the caller's `next()` → `checkForComodification` → `ConcurrentModificationException` (`ArrayList.java:1041-1044`), which nothing in `Retryer.call` catches: **`call()` throws an undocumented exception after the callable ran**; the result is lost and the rejection predicate and stop strategy never run. In `hunt_sharing_bfs1.out` the same happens to one of two callers sharing the Retryer.

### Root Cause

`RetryerBuilder.build()` passes the builder's own `ArrayList` to the `Retryer` (`RetryerBuilder.java:40, 196`), which stores it without copying (`Retryer.java:137`); the fail-fast iteration over it (`Retryer.java:166-168`) runs outside the attempt's try/catch. A later `withRetryListener` on the builder (e.g. reusing it to build a second Retryer, the #48 pattern) races with running calls. Contradicts "A retryer is thread-safe" (`Retryer.java:39-40`) and the documented outcomes (`Retryer.java:146-153`).

### Affected Code

- `RetryerBuilder.java:40, 61-65, 196`
- `Retryer.java:137, 166-168`

### Recommendation

Copy the listener list in `build()` (e.g. `ImmutableList.copyOf(listeners)`) — this also fixes #48.

---

## Bug 9: After the limiter's executor is shut down, `RejectedExecutionException` is recorded as the callable's failure: `call()` throws `ExecutionException` though the callable never ran, or spins through attempts that never run

- **Scenario**: S4. Ledger D-10. Guidance Q4 and "user-supplied executors that are … shut down".
- **Severity**: Medium
- **Invariant violated**: `CountedImpliesInvokedNoStartRace` (after RR-002 it accepts only capacity rejections of a running executor, so a rejection after `shutdown()` still violates it), `ExecutionExceptionMeansCallableThrewExcept29`
- **Config**: MC_hunt_s4_shutdown.cfg
- **Counterexample**: 4 states, `spec/output/repair-r1/repair1_ctl_s4_shutdown_cir.out`; 8 states, `spec/output/repair-r1/repair1_s4_shutdown_bfs2.out` (both regenerated on the repaired spec in repair round 1; the original runs are `spec/output/hunt_s4_shutdown_bfs1.out` and `hunt_s4_shutdown_bfs2.out`, which differ only in the ghost `curQueued` of the rejected attempt)

### Trace Summary

`repair1_s4_shutdown_bfs2.out` / `hunt_s4_shutdown_bfs2.out` (`fixedTimeLimit(d, unit, executor)`, `retryIfExceptionOfType(IOException)`): the application shuts the executor down (state 2); `call()` starts (state 3); `executor.submit` throws `RejectedExecutionException` (`SimpleTimeLimiter.java:149`; `TPE.java:1347-1355`) and it is recorded as attempt 1 (state 4); listeners are notified; the predicate does not match; `call()` throws `ExecutionException(RejectedExecutionException)` (state 8) — documented for "the given callable throws an exception" (`Retryer.java:148-150`), although the callable never ran. With `retryIfException()` / `retryIfRuntimeException()` the same rejection is retried as a callable failure (a busy loop with `neverStop` and `noWait`).

### Root Cause

`Retryer.java:162-163` treats a failure to start the attempt like a failure of the callable.

### Affected Code

- `Retryer.java:162-163, 170-171`
- `AttemptTimeLimiters.java:69-72, 107`; Guava `SimpleTimeLimiter.java:149`

### Recommendation

Propagate `RejectedExecutionException` from the limiter as a terminal error (or wrap it in a dedicated exception) instead of offering it to the rejection predicate.

---

## Bug 10: A negative computed sleep makes `call()` throw `IllegalArgumentException` — an undocumented outcome that also pre-empts the `RetryException` owed to an interrupted thread

- **Scenario**: S5 (composition of the block step). The negative value comes from the unvalidated `join` sum (ledger D-16) or `exceptionWait` (D-17), which are code-review findings; the model offers "Negative" as the class of those results. Guidance Q4/Q5.
- **Severity**: Medium
- **Invariant violated**: `DocumentedOutcomesOnly`; `InterruptedCallThrowsRetryException` (`MCHunt.tla`)
- **Config**: MC_hunt_s5_decision.cfg
- **Counterexample**: 9 states, `spec/output/hunt_s5_decision_bfs1.out`; 10 states, `spec/output/hunt_s5_decision_bfs3.out`

### Trace Summary

`hunt_s5_decision_bfs3.out` (`noTimeLimit`, `retryIfExceptionOfType(IOException)`, `stopAfterDelay`): attempt 1 throws `IOException` (states 2–4); during the listener loop the calling thread is interrupted (state 7); the stop strategy does not stop; the wait strategy returns a negative value (state 9); `Thread.sleep(negative)` throws `IllegalArgumentException` before it looks at the interrupt status (JDK `JVM_Sleep` checks the sign first), and `Retryer.java:179` catches only `InterruptedException`, so **`call()` throws `IllegalArgumentException` instead of `RetryException`** (state 10), losing the last failure and the attempt count. `bfs1` is the same exit without an interrupt.

### Root Cause

`Retryer.call` passes the computed sleep to the block strategy unvalidated and catches only `InterruptedException` (`Retryer.java:176-182`); `ThreadSleepStrategy` calls `Thread.sleep` directly (`BlockStrategies.java:46`); `join` sums without overflow protection and `exceptionWait` returns the user function's value unclamped (`WaitStrategies.java:225-230, 365-371, 386-394`).

### Affected Code

- `Retryer.java:176-182`
- `BlockStrategies.java:46`
- `WaitStrategies.java:225-230, 365-371, 386-394`

### Recommendation

Clamp the computed sleep to `>= 0` in `Retryer.call` (or validate in `join` / `exceptionWait` with saturating addition).

---

## Bug 11: (Known #48) A listener added to the builder after `build()` is notified by an already-built Retryer, including by a call already in flight

- **Scenario**: S3. Ledger D-9. **Status: Known** — issue #48 (open, unfixed); reproduced here as a check of the model.
- **Severity**: Medium
- **Invariant violated**: `ListenersFixedAtBuild`
- **Config**: MC_hunt_s3_listeners.cfg (also MC_hunt_sharing.cfg)
- **Counterexample**: 9 states, `spec/output/hunt_s3_listeners_bfs2.out`; 12 states, `spec/output/hunt_sharing_bfs4.out`

### Trace Summary

`hunt_s3_listeners_bfs2.out`: while attempt 1's callable runs, the builder thread completes `withRetryListener(l2)` (`modCount++`, then `size++`, states 4–5); the attempt ends and the running call's listener loop notifies listeners 1 **and 2** (states 8–9). In `hunt_sharing_bfs4.out` the `modCount++` lands before the iterator is created and the `size++` during the iteration, so no CME occurs and listener 2 is still notified.

### Root Cause

Same aliasing as Bug 7: `RetryerBuilder.java:40, 196` → `Retryer.java:137`.

### Affected Code

- `RetryerBuilder.java:40, 63, 196`; `Retryer.java:137, 166-168`

### Recommendation

As Bug 7 (copy the list in `build()`).

---

## Bug 12: (Known #29) The first attempt timeout ends retrying with `ExecutionException(UncheckedTimeoutException)` unless the predicate matches Guava's exception

- **Scenario**: S4 (attribution at the limiter boundary). Ledger D-14. **Status: Known** — issue #29 (open; maintainer acknowledged it as a bug; reported against 1.0.6). The guidance asks to check 2.0.0: still present.
- **Severity**: Medium
- **Invariant violated**: `TimeoutDoesNotEndCallWithExecutionException` (`MCHunt.tla`; the hunt cfgs exclude this case from `ExecutionExceptionMeansCallableThrew` via the `…Except29` variant)
- **Config**: MC_hunt_s4_shutdown.cfg (derived `hunt/s4_shutdown-k29.cfg`, `MaxShutdowns = 0`, spec `MCHunt.tla`)
- **Counterexample**: 11 states, `spec/output/hunt_s4_shutdown_k29.out`

### Trace Summary

`fixedTimeLimit(d, unit, executor)`, `retryIfExceptionOfType(IOException)`, `stopAfterAttempt(3)`: attempt 1 is submitted (state 3); its deadline passes (state 4); Guava cancels it and throws `UncheckedTimeoutException` (states 5–7); the predicate does not match it, so `call()` throws `ExecutionException(UncheckedTimeoutException)` (state 11) after one attempt, without consulting the stop or wait strategy — although the callable threw nothing and the limit is documented as per attempt (`RetryerBuilder.java:113`).

### Root Cause

`Retryer.java:162-163, 170-171`: a timeout is an ordinary attempt failure judged by the user's predicate.

### Affected Code

- `Retryer.java:162-163, 170-171`; Guava `SimpleTimeLimiter.java:164-166`

### Recommendation

Treat limiter timeouts as retryable attempt failures independent of the predicate (or document that predicates must match `UncheckedTimeoutException`).

---

## Withdrawn after repair round 1

Phase 4 reproduced both counterexamples on the real library (Level 0) and found each to be documented behavior, so it returned INVARIANT repair requests instead of bugs. Repair round 1 revised the invariants in `base.tla`, replayed all 380 traces, re-ran `MC.cfg` and the requests' hunt cfgs, and checked that the revised invariants still fail on the behaviors the evidence does not cover ("Repair round 1 checks" above). The reachable behaviors below are unchanged; only their classification changed. The numbers 3 and 8 are not reused.

### Former Bug 3 (MC-3, RR-001): A completed attempt is reported as a timeout; its result is discarded and the work is executed again

- **Why withdrawn**: the caller-visible result is the documented timeout outcome. The timed `get` decides "timeout" only while the task is NEW or COMPLETING (JDK `FutureTask.java:406-410, 436-438, 202-204`); a task already NORMAL/EXCEPTIONAL at that point yields its result. Once the limit is reached, Guava attempts to abort the call and throws `UncheckedTimeoutException` (Guava 22.0 `TimeLimiter.java:79-83, 94`; aborting is "of secondary concern", `:47-51`), and guava-retrying documents that an attempt "will possibly be interrupted if the limit is exceeded" (`AttemptTimeLimiter.java:22`). Phase 4 hit this state in 1079 of 16000 trials on JDK 21 and JDK 11, each time 42–117 µs after the earliest possible deadline, and Retryer's caller and listeners saw exactly what a cancelled timeout shows (`repro/MC-3.log`, `spec/repair-requests/RR-001.md`).
- **What remains checked**: `NoDiscardedCompletion` now covers only the caller-interrupt path (Bug 4), which RR-001 left unchanged.

Original analysis (kept for reference):

- **Scenario**: S1. Ledger D-2. Guidance Q1 ("a finished attempt's result be discarded and its work repeated").
- **Severity**: Medium (µs window, but it silently repeats non-idempotent work)
- **Invariant violated**: `NoDiscardedCompletion`
- **Config**: MC_hunt_s1_timelimit.cfg (also MC_hunt_s2_wrap_cancel.cfg, MC_hunt_s4_executor.cfg, MC_hunt_s4_shutdown.cfg, MC_hunt_sharing.cfg)
- **Counterexample**: 10 states, `spec/output/hunt_s1_timelimit_bfs1.out`

#### Trace Summary

1. States 2–7: attempt 1 is submitted to w1; w1 starts the body (`Ret`), and the body returns a value.
2. State 8: w1's `set` CAS NEW → COMPLETING succeeds (`FutureTask.java:229`).
3. State 9: the caller's deadline iteration removes its waiter and re-reads the state (`FutureTask.java:437-438`): COMPLETING, so `get` throws `TimeoutException` (`s <= COMPLETING`, `:202-204`).
4. State 10: w1 publishes NORMAL (`:231`). The task now holds a normal result, yet the caller is in `SimpleTimeLimiter`'s timeout branch: `future.cancel(true)` returns `false` (state is not NEW), the return value is ignored (`SimpleTimeLimiter.java:165`), and `UncheckedTimeoutException` is thrown and recorded as attempt 1 (`Retryer.java:162-163`). Under `retryIfException()` the callable is executed a second time; with a predicate that does not match timeouts, `call()` fails although the callable succeeded.

The same race through the interrupt path (completion between the caller's state read and its interrupt test; `cancel` result ignored at `SimpleTimeLimiter.java:156`) is reported with Bug 4.

#### Root Cause

Guava ignores the result of `future.cancel(true)` after a `TimeoutException` (`SimpleTimeLimiter.java:164-166`); `false` means the task already completed, and its outcome is available via `future.get()`. `FutureTask.get(timeout)` also reports a timeout while the result is being published (COMPLETING). guava-retrying records the timeout as an ordinary failed attempt (`Retryer.java:162-163`) and retries.

#### Affected Code

- Guava `SimpleTimeLimiter.java:164-166` (and `:155-157` for the interrupt path)
- `AttemptTimeLimiters.java:107`
- `Retryer.java:162-163, 170-176`

#### Recommendation

In guava-retrying's limiter, when `cancel` returns `false` (or `future.isDone()` after the timeout), return the task's outcome via `future.get()` instead of reporting a timeout; Guava's three-argument `callWithTimeout` path would need the same check.

### Former Bug 8 (MC-8, RR-002): With a bounded limiter executor, attempts that time out in the queue or are rejected are counted as failed attempts although the callable never ran; `wrap()` on the limiter's own pool times out every attempt

- **Why withdrawn**: the behavior is what the library documents for a bounded limiter executor. `AttemptTimeLimiters.java:47-50` refers users of the three-argument factory to Guava's `SimpleTimeLimiter(ExecutorService)` note, which warns that with a bounded executor "any time callers spend waiting for a thread may count toward their time limit, and in this case the call may even time out before the target method is ever invoked" (Guava 22.0 `SimpleTimeLimiter.java:56-58`, unchanged since Guava 10.0). The limiter, including the executor's `submit`, is part of the attempt (`AttemptTimeLimiter.java:22, 31`), and limiter failures are failed attempts by design (issue #29; `AttemptTimeLimiterTest.java:44-50`). Phase 4 reproduced every predicted end state in 3/3 runs; with an unbounded cached pool, or `wrap()` on a separate pool, counted attempts equal invocations (`repro/MC-8.log`, `spec/repair-requests/RR-002.md`).
- **What remains checked**: `CountedImpliesInvokedNoStartRace` still rejects a never-run counted attempt that was cancelled because of a caller interrupt (Bug 4, D-5) or rejected by a shut-down executor (Bug 9, D-10). The zombie that keeps the only thread in `hunt_s4_executor_bfs3.out` is Bug 1 (`repair1_s4_executor_bfs1.out`).

Original analysis (kept for reference):

- **Scenario**: S1/S4 (executor saturation; `wrap()` on the limiter's pool). Ledger D-4. Guidance Q1/Q4, must-cover "one time limiter's executor shared by several threads".
- **Severity**: Medium
- **Invariant violated**: `CountedImpliesInvokedNoStartRace` (excludes only the timing-only start race of a task that never waited in a queue)
- **Config**: MC_hunt_s4_executor.cfg, MC_hunt_s4_wrap_samepool.cfg
- **Counterexample**: 9 states, `spec/output/hunt_s4_executor_bfs1.out`; 7 states, `spec/output/hunt_s4_wrap_samepool_bfs1.out`; 23 states (with a zombie of Bug 1 and a rejection), `spec/output/hunt_s4_executor_bfs3.out`

#### Trace Summary

`hunt_s4_executor_bfs1.out` — two callers share one Retryer whose `fixedTimeLimit(d, unit, executor)` uses `ThreadPoolExecutor(1, 1, …, ArrayBlockingQueue(1))`: c1's attempt takes the only thread (state 3); c2's attempt is queued (state 5); c2's deadline passes, `cancel(true)` marks the queued task INTERRUPTED (it stays in the queue), and attempt 1 of c2 is recorded as a timeout although its callable never started (state 9). `hunt_s4_wrap_samepool_bfs1.out` — the caller is `executor.submit(retryer.wrap(callable))` on the same one-thread fixed pool the limiter uses: the `RetryerCallable` holds the only thread, so every attempt waits in the queue and times out unrun (state 7); with `neverStop` this never ends. `hunt_s4_executor_bfs3.out`: c1's own timed-out attempt keeps the thread (Bug 1), c2's task fills the queue, c1's next attempt is rejected by `AbortPolicy` and counted, and `call()` throws `RetryException` reporting 2 attempts with 1 invocation while the zombie still runs.

#### Root Cause

The per-attempt deadline starts at `submit`, so queue time counts against it (`SimpleTimeLimiter.java:149-154`); a cancelled task is not removed from the queue; and `Retryer.call` counts every limiter failure — timeout or `RejectedExecutionException` — as an attempt of the callable (`Retryer.java:162-163`), feeding it to listeners, the stop budget and `RetryException`.

#### Affected Code

- `AttemptTimeLimiters.java:69-72, 93-95, 105-108`
- Guava `SimpleTimeLimiter.java:149-166`
- `Retryer.java:162-163, 170-174`

#### Recommendation

Distinguish attempts whose callable never started (e.g. wrap the callable to record its start) and do not count them as callable failures; document that the limiter executor needs a free thread per concurrent attempt and must not be the executor running `wrap()` tasks.

---

## Not Reproduced

| Scenario | Config | States Explored | Result |
|------------|--------|-----------------|--------|
| MC-8 InterruptContainment (cancellation interrupt never reaches another task's body; TPE clears it in `runWorker`, the work queue's `take()`/`poll` consume it) | MC.cfg and all 12 safety hunt cfgs; 379 traces (380/380 replays after repair round 1) | MC.cfg 5,839,963 (exhaustive; 5,867,867 after repair round 1); hunt final runs as in the coverage table | No violation (holds within bounds) |
| MC-9 RetryAccounting (`RetryException` count = attempts made, last attempt's cause; `stopAfterAttempt(K)` bounds attempts) | MC.cfg and all 12 safety hunt cfgs; 379 traces | as above | No violation (holds within bounds) |
| `CancelledWrapperStops` for the attempt already decided when the outer cancel arrives | MC_hunt_s2_wrap_cancel.cfg | 143 (bfs1) | Not a bug: invariant mismatch (Case A), revised; the retry after the cancellation is Bug 6 |
| Interrupt arriving during listeners, predicate, stop or wait computation, or during the sleep | MC_hunt_s2_interrupt_fixed / _narrow / _nolimit, MC_hunt_s5_decision | exhaustive final runs (7,566 / 4,076 / 145 / 244) | No violation: `RetryException` with the status set (or a result returned with the status set) — the only failures are the ones where the interrupt is consumed inside the attempt (Bugs 4–6) or a negative sleep pre-empts it (Bug 10) |
| Liveness control: interrupt delivered with `retryIfExceptionOfType(IOException)` | MC_hunt_s2_live.cfg (control) | 9,264 (exhaustive) | `InterruptedCallEventuallyExits` holds |
| Completion published between the timeout decision and `cancel(true)`, reported as a timeout (former Bug 3, MC-3) | MC_hunt_s1_timelimit.cfg (+ s2_wrap_cancel, s4_executor, s4_shutdown, sharing) | 10 states (`hunt_s1_timelimit_bfs1.out`) | Not a bug (RR-001): the documented timeout outcome. `NoDiscardedCompletion` no longer checks the timeout path; its supported part (a task already NORMAL/EXCEPTIONAL when the timed get decides yields its result) is `GetTimeout`'s guard and cannot fail. Not applicable, and removed from the wiring, in s1_timelimit, s4_executor, s4_shutdown, s4_wrap_samepool (no caller interrupt there): not counted as coverage in those cfgs |
| Attempt that timed out in a bounded/fixed pool's queue, or was rejected by a saturated running pool, counted although the callable never ran (former Bug 8, MC-8) | MC_hunt_s4_executor.cfg, MC_hunt_s4_wrap_samepool.cfg | 9 / 7 / 23 states (`hunt_s4_executor_bfs1.out`, `hunt_s4_wrap_samepool_bfs1.out`, `hunt_s4_executor_bfs3.out`) | Not a bug (RR-002): documented bounded-executor behavior (`AttemptTimeLimiters.java:47-50` → Guava `SimpleTimeLimiter.java:56-58`). `CountedImpliesInvokedNoStartRace` accepts these cases; in these two cfgs nothing else can violate it, so it is not applicable there, removed from the wiring and not counted as coverage. It still flags caller-interrupt cancellations (Bug 4) and rejections after `shutdown()` (Bug 9) |
| Wait/stop arithmetic (D-16…D-22), `int` counter wrap (D-19), `Error` wrapping (#67, D-15), stack-trace growth (D-12), non-`Exception` throwables (D-13), invalid duration (D-11), `RetryException` serialization (D-23) | — | — | Not testable here: deterministic value computations or API policy, outside the model by design (`modeling-brief.md` §3.2); code-review findings |
| JMM reorderings of the unsynchronized listener `ArrayList` (stale or null reads) | — | — | Not testable: TLC and JPF are sequentially consistent |
| ForkJoinPool / same-thread / `CallerRunsPolicy` executors, executors that never clear interrupts, `shutdownNow()` of the limiter executor, `shutdown()` racing an in-flight `execute` | — | — | Not modeled (environment choices, brief §3.2 / brief-coverage §8) |

## Spec adjustments during bug hunting

- `CancelledWrapperStops` (Case A, `changelog.md` "Bug Hunting"): the ghost `cancelAt` now allows the one attempt whose start was already decided when the outer cancel arrives (`Retryer.java:157-160` has no interrupt check before `submit`); the D-7 retry still violates it (`hunt_s2_wrap_cancel_bfs3.out`). Ghost-only; the 42 wrap traces still replay.
- `MCHunt.tla` (new, hunting only): filtered properties `InterruptedCallThrowsRetryException` (Bug 10), `StuckBodiesEndWithCall` and `StuckBodiesPerCallAtMostOne` (Bug 2), `TimeoutDoesNotEndCallWithExecutionException` (Bug 12). `base.tla` / `MC.tla` behavior is unchanged by it.
- Derived per-round hunting cfgs are in `spec/hunt/` (each records which analyzed property it disables and why); the run-to-output map is `spec/hunt/tasks.tsv`.
- Repair round 1 (RR-001, RR-002; `changelog.md` "Repair Round 1"): `NoDiscardedCompletion` checks only the caller-interrupt path; `CountedImpliesInvokedNoStartRace` accepts timeouts and capacity rejections of a running executor; the ghost `curQueued` of a rejected attempt is now `~exShutdown` (ghost-only, read only by that invariant). Wiring: `NoDiscardedCompletion` is off in s1_timelimit, s4_executor, s4_shutdown and s4_wrap_samepool, and `CountedImpliesInvokedNoStartRace` is off in s4_executor and s4_wrap_samepool, because the revised predicates cannot fail there. Derived cfgs, controls and the run map are in `spec/hunt/repair-r1/` (`tasks.tsv`); outputs are in `spec/output/repair-r1/`.
