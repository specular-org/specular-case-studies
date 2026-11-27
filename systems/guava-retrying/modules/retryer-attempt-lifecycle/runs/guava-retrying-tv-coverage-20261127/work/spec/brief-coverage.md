# Brief Coverage Audit: guava-retrying 2.0.0

Self-audit of `spec/` against the target guidance (scope, priority questions Q1–Q5, must-cover interactions) and `modeling-brief.md` §2 / §5 / §6. The "enabled in" columns were extracted from the cfg files (exact `INVARIANT`/`PROPERTY` lines), not written from memory.

Category B. Threads: callers (`Retryer.call`, direct or as `wrap()` tasks), limiter pool workers (`ThreadPoolExecutor.runWorker` → `FutureTask.run`), the builder thread, and the environment (interrupts, outer cancellation, executor shutdown, wall-clock time). Every action is one shared-memory access of the real code (FutureTask CAS / volatile read / write, interrupt-status test or set, queue operation, `ArrayList` field access) plus the thread-local code around it; each merge of two accesses is argued in a `base.tla` comment.

## 1. Requested scope → model

| Scope item (guidance) | In the model | Not modeled (route) |
|---|---|---|
| `Retryer.call` loop (`Retryer.java:155-185`) | caller pcs `Attempt` … `Done`; `CallStart`, attempt actions, `ListenersBegin/Notify/CME/End`, `PredicateAccepts`, `StopStrategyStops`, `WaitStrategyComputes`, `Block*`, `Sleep*` | — |
| `wrap` / `RetryerCallable` (`:195-197, 301-320`) | `WrapCallers`, `outerState`, `CancelOuter`, wrap branch of `CallStart`; `WrapOnLimiterPool` + `OuterWorkerRelease` for wrap tasks on the limiter's own pool | outer executor internals other than cancellation and thread occupancy |
| `RetryerBuilder` (`withRetryListener`, `build`) | shared `ArrayList` (`blist`, `bmod`, `bAdding`), `AddListenerBegin/End` (modCount++, then store + size++); build at `Init` hands the same list to the Retryer | `retryIf*` composition (predicates are configured as the `RetryOn` tag set); builder used by several threads (no thread-safety claim, brief §3.2) |
| Stop strategies | `ShouldStop`: `neverStop`, `stopAfterAttempt(K)`, `stopAfterDelay` (abstract elapsed time `elapsedOver`, sampled when the `Attempt` is built) | sub-ms truncation D-22 (CR) |
| Wait strategies | `WaitStrategyComputes` returns a class `Zero` / `Positive` / `Negative` | arithmetic D-16 … D-21 (CR, brief §3.2); `Negative` only checks how the block step composes with interrupts |
| Block strategy (`Thread.sleep`) | `BlockNegative` (IAE first), `BlockInterrupted`, `BlockZero`, `BlockSleepStart`, `SleepReturns`, `SleepInterrupted` (JVM_Sleep order) | user block strategies (assumption: honor the interface) |
| Time limiters | `noTimeLimit`: `CallerBody*` on the caller thread; `fixedTimeLimit`: `Submit*`, `Get*`, `Cancel*` over Guava `SimpleTimeLimiter.callWithTimeout(…, true)` and JDK `FutureTask` / `ThreadPoolExecutor` (cached, fixed, bounded pools; shutdown) | invalid duration D-11, stack growth D-12, non-Exception throwables D-13 (CR); ForkJoinPool / direct executors (environment, brief §3.2) |
| `Attempt` | classification tag per attempt (`curTag`, `Tags`), `curInvoked`, `curExpired`; `ResultAttempt` vs `ExceptionAttempt` paths | `delaySinceFirstAttempt` values |
| `RetryException` | count and last tag at exit (`exitInfo`), checked by `RetryAccounting` | serialization D-23 (CR); `int` wrap D-19 (CR) |
| Guava `SimpleTimeLimiter` as used by `AttemptTimeLimiters` | `callWithTimeout` steps (`:145-168`): submit, timed get, IE → cancel → rethrow, timeout → cancel → `UncheckedTimeoutException`, `cancel`'s result ignored | the proxy API |

Callable behaviors (assumption "arbitrary user code"): `Ret`, `RetBad`, `Exc`, `Err`, `IntrRet`, `IntrBlock`, `Stuck`, chosen per attempt from `Modes`.

## 2. Guidance priority questions

| Question | Representation |
|---|---|
| Q1 time limit: overlap, activity after `call()`, discarded result, threads outliving use | `SequentialAttempts`, `NoActivityAfterOutcome` (D-1, D-3 with `Stuck`), `NoDiscardedCompletion` (D-2: the decision `GetTimeout` / `GetInterrupted` and `CancelCASWon/Lost` are separate steps; since repair round 1 only the `GetInterrupted` path is checked — a completion that lands between `GetTimeout` and the cancel CAS is the documented timeout outcome, RR-001/MC-3); worker lifetime: `Stuck` bodies stay in `Body` after `Done`, cached pool grows (`SubmitNewWorker`), `ModelBoundsAdequate` sizes the pool. Cfgs `MC_hunt_s1_timelimit`, `MC_hunt_s1_overlap`. Documentation question (does C5 "possibly interrupted" admit it): for Bug Confirmation; the model shows which outcomes are reachable. |
| Q2 interrupts at every step, callable throwing IE | `Interrupt` enabled at every caller pc (also before `call()`), `CancelOuter` for `wrap()`; IE consumed by `GetInterrupted` or an interruptible callable (`CallerBodyThrows`), restored only by `BlockInterrupted` / `SleepInterrupted`. `InterruptPreserved`, `NoRetryAfterObservedInterrupt`, `CancelledWrapperStops`, liveness `InterruptedCallEventuallyExits`. Cfgs `MC_hunt_s2_*`. |
| Q3 builder modified while a built Retryer runs | `AddListenerBegin/End` interleaved with `ListenersBegin/Notify/CME/End` of a running call. `DocumentedOutcomesOnly`, `NoLostAttemptOutcome` (D-8), `ListenersFixedAtBuild` (#48 known). Cfgs `MC_hunt_s3_listeners`, `MC_hunt_sharing`. |
| Q4 undocumented endings, wrong count / last failure | `DocumentedOutcomesOnly` (CME, IAE), `ExecutionExceptionMeansCallableThrew` (+ `…Except29`), `CountedImpliesInvoked` (+ `…NoStartRace`, which since repair round 1 accepts timeouts and capacity rejections of a running bounded executor, RR-002/MC-8), `RetryAccounting`. NPE from `exceptionWait` (D-18) and the counter wrap (D-19) are CR. |
| Q5 extreme parameters of waits / stops | CR (deterministic arithmetic, brief §3.2 and Scenario 5). The model checks only the composition of an invalid (negative) sleep with interrupts (`MC_hunt_s5_decision`). |

## 3. Must-cover interactions

| Interaction | Representation |
|---|---|
| `Retryer.call` ↔ `AttemptTimeLimiter` ↔ `SimpleTimeLimiter` ↔ callable (submit, timeout, cancel, interrupt, outcome → `Attempt`) | `Submit{Rejected,Handoff,NewWorker,Queued}`, `GetReturn` / `GetInterrupted` / `GetTimeout`, `CancelCASWon/Lost`, `CancelReadRunner`, `CancelDoInterrupt`, `CancelFinish`; worker side `WorkerRunTask*`, `WorkerRunnerCAS`, `BodyStart/Skip/Returns/Throws`, `SetCASWon/Lost`, `SetFinish`, `RunFinallySpin/Exit`, `SpinExit`; classification in `SetClassified` |
| decision order and interrupt status throughout | caller pcs `Classified → Listeners → Decide → Block/Sleeping`; `intr[c]` tested/cleared exactly at `GetInterrupted`, interruptible callables, `Block*`/`Sleep*`, restored only at `Retryer.java:180` |
| `RetryerBuilder` ↔ `Retryer` handoff | `Init` (list shared, other fields fixed), `AddListenerBegin/End` |
| one Retryer / one executor shared by threads, `wrap()` on an executor | `Callers = {c1, c2}` on one executor (`MC_hunt_s4_executor`, `MC_hunt_sharing`); `WrapCallers` (`MC_hunt_s2_wrap_cancel`); `WrapOnLimiterPool` (`MC_hunt_s4_wrap_samepool`) |
| interrupts at each step, timeout racing completion, callables ignoring interrupts / blocking / throwing `Error`, saturated or shut-down executors | `Interrupt` at every pc; `GetTimeout` vs `SetCASWon`; `Ret`/`Stuck`/`IntrBlock`/`Err` modes; `ExecKind = "Bounded"` with `QueueCap`, `ExecutorShutdown` |

## 4. Scenarios (brief §2) → hunt cfgs

| Scenario | Hunt cfg(s) |
|---|---|
| S1 time-limited attempts escape the attempt sequence | `MC_hunt_s1_timelimit` (all properties; D-2 first — withdrawn by RR-001, after which `NoDiscardedCompletion` is off here and the cfg checks the same properties as `s1_overlap`), `MC_hunt_s1_overlap` (same model, `NoDiscardedCompletion` off so the run reaches D-1/D-3) |
| S2 interrupts consumed inside an attempt | `MC_hunt_s2_interrupt_fixed` (retrying predicate), `MC_hunt_s2_interrupt_narrow` (predicate not matching IE), `MC_hunt_s2_interrupt_nolimit` (callable on the caller thread), `MC_hunt_s2_wrap_cancel` (`wrap()` cancelled), `MC_hunt_s2_live` (liveness) |
| S3 listener list aliased between builder and Retryers | `MC_hunt_s3_listeners`; composed with two callers in `MC_hunt_sharing` |
| S4 attempt-outcome attribution at the limiter boundary | `MC_hunt_s4_executor` (saturation by own / other caller's attempts), `MC_hunt_s4_shutdown` (rejection after shutdown), `MC_hunt_s4_wrap_samepool` (`wrap()` on the limiter's pool; `stopAfterAttempt(3)` so the call ends and the pool thread returns and discards the cancelled queued tasks — with `neverStop` it livelocks) |
| S5 post-attempt decision steps (composition only) | `MC_hunt_s5_decision` |
| Must-cover sharing (all scenarios composed) | `MC_hunt_sharing` (run with `-C`; its first counterexamples repeat single-caller ones) |

## 5. Properties (brief §5)

All are defined in `base.tla`; `MC.tla` EXTENDS `base`, so every cfg references them directly.

| Property | Type | Enabled in |
|---|---|---|
| SequentialAttempts | Safety | all 12 safety hunt cfgs |
| NoActivityAfterOutcome | Safety | all 12 safety hunt cfgs |
| NoDiscardedCompletion | Safety (caller-interrupt path only since RR-001) | `s2_interrupt_fixed`, `s2_interrupt_narrow`, `s2_wrap_cancel`, `sharing` (falsifiable: a caller interrupt or an outer `cancel(true)` reaches `GetInterrupted`; violated there, Bug 4). Also wired in `s2_interrupt_nolimit`, `s3_listeners`, `s5_decision`, where it is vacuous (no time limiter, so no task is ever tagged; unchanged by RR-001) and not counted. Not applicable, off: `s1_overlap`, `s1_timelimit`, `s4_executor`, `s4_shutdown`, `s4_wrap_samepool` (no caller interrupt; the timeout path is not a promised property, RR-001) |
| CountedImpliesInvoked | Safety | `s2_interrupt_fixed`, `s2_interrupt_nolimit`, `s3_listeners`, `s5_decision` (cfgs without deadline expiries) |
| CountedImpliesInvokedNoStartRace (variant) | Safety | `s4_shutdown` (rejection after `shutdown()`, Bug 9) and `sharing` (attempt cancelled before it ran by a caller interrupt, Bug 4): falsifiable and violated. Also wired in `s1_timelimit`, `s1_overlap`, where it cannot fail (cached pool, no interrupt, no shutdown: every never-run attempt is a start-race timeout; so before RR-002 too) and is not counted. Not applicable, off: `s4_executor`, `s4_wrap_samepool` (only timeouts and capacity rejections there, which RR-002 found documented) |
| ExecutionExceptionMeansCallableThrew | Safety | all safety hunt cfgs except `s4_shutdown` |
| ExecutionExceptionMeansCallableThrewExcept29 (variant) | Safety | `s4_shutdown` |
| InterruptPreserved | Safety | all 12 safety hunt cfgs |
| NoRetryAfterObservedInterrupt | Safety | all 12 safety hunt cfgs |
| CancelledWrapperStops | Safety | all 12 safety hunt cfgs (triggered only where `WrapCallers` is non-empty) |
| DocumentedOutcomesOnly | Safety | all 12 safety hunt cfgs |
| NoLostAttemptOutcome | Safety | all 12 safety hunt cfgs |
| ListenersFixedAtBuild | Safety (known #48: expected violation) | all 12 safety hunt cfgs (triggered only where `MaxAddListeners > 0`) |
| InterruptContainment | Safety (baseline MC-8, expected to hold) | `MC`, all safety hunt cfgs, `Trace`, `base` |
| RetryAccounting | Safety (baseline MC-9, expected to hold) | `MC`, all safety hunt cfgs, `Trace`, `base` |
| InterruptedCallEventuallyExits | Liveness | `MC_hunt_s2_live` (`LiveSpec`; one `PROPERTY`; no SYMMETRY / CONSTRAINT / VIEW) |

Variants: `CountedImpliesInvokedNoStartRace` originally excused only a timed-out attempt whose task never waited in a queue (the deadline passed before an idle or new thread reached it), the shallowest counterexample of the general invariant in every time-limited model. Since repair round 1 (RR-002) it accepts every timed-out attempt and every rejection by a running executor that had no free thread or queue room (ghost `curQueued = ~exShutdown` at `SubmitRejected`), the documented bounded-executor behavior (`AttemptTimeLimiters.java:47-50` → Guava `SimpleTimeLimiter.java:56-58`); it still flags an attempt cancelled before it ran by a caller interrupt and a rejection by a shut-down executor. `ExecutionExceptionMeansCallableThrewExcept29` excludes the known #29 timeout case. The general invariants stay enabled wherever their shallow cases cannot occur.

Fairness of `LiveSpec` (`MC.tla`): weak fairness per caller on all its non-fault steps, including the timed get's deadline (`FutureTask.java:427-439`), and per worker on all its run/getTask steps (`TPE.java:1107-1144`, `FutureTask.java:254-284`). No fairness on `Interrupt`, `CancelOuter`, `AddListenerBegin`, `ExecutorShutdown`, `DelayElapses`, keep-alive exits. The `_live` cfg disables deadline expiries (the always-failing callable completes on its own) and saturates the attempt counters at `CountCap = 2` (`NextCount <- MCNextCount`).

Standard / structural (also on in `MC.cfg`): `TypeOK`, `StructuralOK` (runner, body, holder, worker/caller task consistency, pool bound), and the model-capacity alarm `ModelBoundsAdequate` (not a system property; MC cfgs use `MCModelBoundsAdequate`, which ignores the successor states cut off by `StateConstraint`, because TLC checks invariants on those too). Cached-pool cfgs give |Callers| × MaxAttempts thread and task identities, since a worker that has just finished is not yet polling and the pool starts a new thread.

## 6. Findings (brief §6.1) → hunt cfgs

| ID | Trigger in the model | Expected violation | Hunt cfg |
|---|---|---|---|
| MC-1 | `fixedTimeLimit`, `Ret`/`Stuck` body, `GetTimeout` (or `GetInterrupted`) → cancel; next attempt or exit while the body runs | SequentialAttempts, NoActivityAfterOutcome | `s1_overlap` (timeouts); interrupt trigger in `s2_interrupt_fixed` |
| MC-2 | `GetTimeout` / `GetInterrupted` decided while NEW, then `SetCASWon` before `CancelCASWon` → `CancelCASLost` | NoDiscardedCompletion (`GetInterrupted` path only since RR-001; the `GetTimeout` path is the documented timeout outcome) | `s1_timelimit` (timeout path, withdrawn); interrupt variant `s2_interrupt_narrow`, `s2_interrupt_fixed`, `s2_wrap_cancel`, `sharing` |
| MC-3 | bounded pool held by a `Stuck` attempt or another caller; `wrap()` on the limiter's pool; shut-down executor | CountedImpliesInvoked(NoStartRace), ExecutionExceptionMeansCallableThrew(Except29) | `s4_executor`, `s4_wrap_samepool` (queued timeouts / capacity rejections: documented, RR-002), `s4_shutdown` |
| MC-4 | `Interrupt` at any caller pc (before `call()`, in `Wait`, in the callable, listeners / decide, before or during the sleep) | InterruptPreserved, NoRetryAfterObservedInterrupt, ExecutionExceptionMeansCallableThrew | `s2_interrupt_fixed`, `s2_interrupt_narrow`, `s2_interrupt_nolimit` |
| MC-5 | `CancelOuter` of a `wrap()` task during an attempt, retrying predicate, `neverStop` | CancelledWrapperStops; InterruptedCallEventuallyExits | `s2_wrap_cancel`; `s2_live` |
| MC-6 | `AddListenerBegin` (modCount++) while the running call is in its listener loop | DocumentedOutcomesOnly, NoLostAttemptOutcome | `s3_listeners`, `sharing` |
| MC-7 | (known #48) a listener added after `build()` notified by a running call | ListenersFixedAtBuild (expected) | `s3_listeners`, `sharing` |
| MC-8 | cancel interrupt of task t landing on a worker that later runs task u | InterruptContainment (expected to hold) | `MC`, all hunts; `Trace` |
| MC-9 | `RetryException` exits under `stopAfterAttempt(K)` | RetryAccounting (expected to hold) | `MC`, all hunts; `Trace` |

## 7. Defect ledger (brief §6.2)

MC rows and the scenario that models them: D-1, D-2, D-3, D-4 → S1 (`s1_*`, `s4_*`); D-5, D-6, D-7 → S2 (`s2_*`); D-8, D-9 → S3 (`s3_listeners`); D-10 → S4 (`s4_shutdown`, `s4_executor`). CR rows D-11 … D-23 go to Bug Confirmation directly; the model only composes an invalid sleep (D-16/D-17) with interrupts in S5.

Known upstream issues are labelled where they surface: #48 = `ListenersFixedAtBuild` (D-9; D-8 is its new concurrent consequence), #29 = the `Timeout` case of `ExecutionExceptionMeansCallableThrew` (excluded by the `Except29` variant), #67 = `Err` mode classified as an attempt (policy, CR), #92 is related to D-3 (idle threads are not a property here), #94 excluded.

## 8. Modeling decisions that differ from the brief's suggestions

- No JDK-version constant. JDK 8 tests the interrupt before reading the state in `awaitDone`, JDK 9+ the other way round, but a caller can be preempted between the two reads. So both orders reach the same outcomes: on JDK 9+ the interrupt can also win against a task that completes meanwhile, and on JDK 8 a completed task is also returned when the interrupt arrives after the test. `GetInterrupted` therefore needs only the interrupt status, and `GetReturn` only a terminal state.
- Steps split beyond the brief's list, at each access another thread can interleave with (needed for step-for-step replay of JPF recordings): cancel = CAS / read runner / interrupt / `setRelease`; worker run = state check / runner CAS / body check; `finally` = null runner / re-read state; cached-pool workers pass through `GetTask` before they can be matched by `offer`; `ArrayList.add` = `modCount++` / store + `size++`.
- `CancelledWrapperStops` was strict here (an attempt submitted after the outer cancellation violated it even when its start was already decided, since there is no interrupt check before an attempt). Phase 3 revised it (Case A, `changelog.md` "Bug Hunting - Spec Adjustments"): the ghost `cancelAt` now allows the one attempt whose start was already decided (`cpc = "Attempt"`) when the cancel arrives, and any further attempt (a retry after the cancellation, D-7) still violates it.
- Not modeled: `shutdownNow()` of the limiter's executor; a `shutdown()` racing an in-flight `execute` (stale `ctl`); `ThreadPoolExecutor` thread factories / rejection policies other than AbortPolicy; JMM reorderings of the unsynchronized `ArrayList` (brief §3.2).

## 9. Checks run during spec generation

- SANY: `base.tla`, `MC.tla`, `Trace.tla` parse.
- `base.cfg`: complete, no violation (7.4M distinct states, depth 45). `MC.cfg`: complete, no violation of the standard / structural / baseline properties (5.1M distinct states, depth 61).
- Size of the two-caller composition model (`MC_hunt_sharing`, structural invariants only): more than 45M distinct states at depth 42 after 17 minutes on 48 workers, queue still growing; it is meant for `-C` runs with a time budget, not for exhaustive search.
- Structural pass: every hunt model run with only `TypeOK`, `StructuralOK`, `MCModelBoundsAdequate`, `InterruptContainment`, `RetryAccounting` completes without a violation, and TLC's action coverage shows every `base.tla` action producing new states in at least one model.
- Reachability (spec generation; for repair round 1 see `bug-report.md` "Repair round 1 checks": after RR-001/RR-002 the first reports are `s1_timelimit` SequentialAttempts, `s4_executor` NoActivityAfterOutcome, `s4_shutdown` CountedImpliesInvokedNoStartRace (rejection after shutdown), and `s4_wrap_samepool` none, exhaustive): each safety hunt cfg reports a counterexample of a scenario property within seconds. Observed first reports (the first property reported at a given depth can vary between runs with several workers): `s1_timelimit` NoDiscardedCompletion; `s1_overlap` SequentialAttempts; `s2_interrupt_fixed` CountedImpliesInvoked (attempt cancelled before it ran); `s2_interrupt_narrow` NoDiscardedCompletion or ExecutionExceptionMeansCallableThrew; `s2_interrupt_nolimit` NoRetryAfterObservedInterrupt; `s2_wrap_cancel` CancelledWrapperStops; `s3_listeners` DocumentedOutcomesOnly (CME); `s4_executor` CountedImpliesInvokedNoStartRace or NoDiscardedCompletion; `s4_shutdown`, `s4_wrap_samepool` CountedImpliesInvokedNoStartRace; `s5_decision` DocumentedOutcomesOnly (IAE); `sharing` DocumentedOutcomesOnly. These are model counterexamples for the bug-hunting phase to analyze, not confirmed defects.
- Liveness: `MC_hunt_s2_live` violated (lasso: the cancellation interrupt is consumed by `Future.get`, then the always-failing callable is retried forever); premise check (`INVARIANT NoInterruptDeliveredInv`) violated as required; control with `RetryOn = {"CallableExc"}` completes without violation.
- `Trace.tla`: hand-written recordings (time-limited zombie attempt; CME; interrupt during sleep; the cancel / spinning-runner interleaving) replay to completion; a recording with one corrupted state fails at exactly that event (`l`); an overlapping-interval recording passes the `TraceNotFullyConsumed` existence check.
