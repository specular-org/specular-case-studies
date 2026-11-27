# guava-retrying 2.0.0 — trace instrumentation guide

For the Phase 3 agent: how the traces in `../traces/` are produced, where each event comes from, and how to change the instrumentation.

## How it works

The library source is not modified. Java PathFinder (JPF, jpf-core `local/reachability-fence` on JDK 11) executes the real guava-retrying classes (built from the unmodified source by `pom.xml`), Guava 22.0 and the JDK 11 `java.util.concurrent` / `ArrayList` bytecode. A JPF listener, `src/recorder/grtrace/GrTraceRecorder.java`, watches the instruction or native call that is each `base.tla` action's commit point (instrumentation-spec.md §2) and emits one event per action. `src/recorder/grtrace/TraceSearch.java` is a random-walk search with restarts: every path is one complete execution under one JPF-chosen thread schedule (and one choice of callable behavior), and every kept path is one trace file.

| File | Role |
|---|---|
| `src/recorder/grtrace/GrTraceRecorder.java` | the recorder (all commit points; trace writing; trace selection) |
| `src/recorder/grtrace/TraceSearch.java` | random-walk search, one execution per path |
| `src/recorder/grtrace/Json.java` | JSON read/write for the recorder |
| `src/workloads/grwork/{Harness,Modes,Work,IdListener,Delay}.java` | workload support run inside JPF: recording markers, the callable behaviors (`mode`), the per-attempt mode plan, listeners with ids, JPF-chosen delays |
| `src/workloads/grwork/w/*.java` | the 13 workloads (one per trace family, aligned with the `MC_hunt_*.cfg` configurations) |
| `patches/jpf-core/*.patch` | jpf-core JDK 11 model fixes (applied by `apply.sh` if missing) |
| `pom.xml` | Maven build of the unmodified library (Guava 22.0, jsr305 2.0.2, `--release 8`) |
| `apply.sh` / `run.sh` | build / build + run + report (`--validate` also replays every trace with TLC) |
| `tools/validate_traces.py` | TLC replay of traces through `spec/Trace.tla`, labels failures at the known spec gaps below |
| `tools/report.py` | per-workload trace counts and event coverage |

Trace format (instrumentation-spec.md §1): line 1 is the `{"tag":"config"}` line (static fields declared by the workload, plus `workers`, `tasks`, `outerWorkers` computed per execution, plus informational `workload`, `path`, `endReason`, `prefix`); every other line is `{"tag":"trace","event","tid","start","end",fields...,"ts"}`. `start = end` = a global logical clock taken at the commit point (one tick per observed commit point, so values have gaps), which gives the total order `Trace.cfg`'s `TraceMatched` expects. `ts` is the host `System.nanoTime()` (string) at which the commit point was observed, for reference only. Events are written sorted by clock; `GetTimeout`, `GetReturn`, `SubmitNewWorker` and `SubmitRejected` are decided earlier than the code shows them, so they are emitted later with the earlier clock. All events carry every field the spec makes mandatory (full capture level); `Trace.tla` checks all of them.

Fields the code only determines after the commit point are filled in later on the same thread, keeping the commit point's clock: `attemptKind`/`expired` (when `Retryer.java:161/163` builds the Attempt), `count` (when the `RetryException` is built; for `BlockInterrupted`/`SleepInterrupted` also `intr`, after `Retryer.java:180` restores the status, as the spec's merged action needs), `mode` (when the body enters a `Modes` method), `attemptNo` of `BlockZero`/`SleepReturns` and of a wrap caller's `CallStart` (when `Retryer.call` updates slot 4), `listener`/`cursor` (when `ArrayList.Itr.next()` returns), `task` of `WorkerTake` (when the dequeue returns). If a path ends while such a field is open, the trace is cut before the earliest open event (`"prefix": true` on the config line).

## Commit points

Line numbers are the JDK 11 class files JPF runs (identical to `/home/ubuntu/scratch/jdk-src/11/` and jdk11u; the queue classes the spec does not cite are in `/home/ubuntu/scratch/jdk11u-src/`). "GTR:n" is a line of `src/recorder/grtrace/GrTraceRecorder.java`.

| Event | Observed at | Recorder |
|---|---|---|
| `CallStart` | direct caller: `istore 4` (`attemptNumber = 1`) in `Retryer.call`; wrap caller: `FutureTask.run:260` state read of the outer task whose callable is the registered `RetryerCallable` | `onAttemptNoStore` GTR:829, `onRunStateRead` GTR:1128 |
| `CallerBodyStart` | entry of `grwork.Work.call` called by `AttemptTimeLimiters$NoAttemptTimeLimit.call` | `onWorkCall` GTR:853 |
| `CallerBodyReturns` / `CallerBodyThrows`, `BodyReturns` / `BodyThrows` | mode end points in `grwork.Modes`: `areturn` (Ret, RetBad), `athrow` (Exc, Err; before execution), `Thread.interrupted()` return (IntrRet), `InterruptedException` raised by `Object.wait()` (IntrBlock) | `onBodyEnd` GTR:878 (from `instructionExecuted`, `executeInstruction`, `onInterrupted`, `exceptionThrown`) |
| `SubmitHandoff` | the successful `SMATCH` CAS in `SynchronousQueue$TransferStack$SNode.tryMatch` — executed by the offering caller or by any thread helping that fulfiller; attributed to the caller that pushed the fulfilling node (`casHead` at `SynchronousQueue.java:373`) | `onCasObj` GTR:1288, `onCasHead` GTR:1546 |
| `SubmitNewWorker` | cached pool: `SynchronousQueue.offer` returning false (`TPE.java:1347`); fixed/bounded: `compareAndIncrementWorkerCount` returning true (`TPE.java:899`); emitted when `addWorker` returns true, `worker` = the thread of the new `ThreadPoolExecutor$Worker` | `onQueueOffer` GTR:1401, `onCaiwc` GTR:1414, `onWorkerInit` GTR:1427, `onAddWorkerExit` GTR:1439 |
| `SubmitQueued` | `LinkedBlockingQueue.offer`'s `count.getAndIncrement()` / `ArrayBlockingQueue.enqueue`'s `count++` | `onAtomicInc` GTR:1482, `onAbqCount` GTR:1507 |
| `SubmitRejected` | bounded pool, still RUNNING: the failed `ArrayBlockingQueue.offer`; otherwise (shut down) entry of `TPE.reject` | `onReject` GTR:1458 |
| `GetReturn` | the `state` read of `FutureTask.get(long,TimeUnit):201` or `awaitDone:406/438` that returned the terminal state; emitted at `report()` entry | `onGetStateRead` GTR:1350, `onReport` GTR:1363 |
| `GetInterrupted` | `Thread.interrupted()` at `awaitDone:416` returning true | `onInterrupted` GTR:1067 |
| `GetTimeout` | the `awaitDone:416` `Thread.interrupted()` (false) of the iteration whose `return state` (`:438`) returns NEW/COMPLETING; emitted at that `ireturn` | `onInterrupted` GTR:1067, `onAwaitDeadlineReturn` GTR:1381 |
| `CancelCASWon` / `CancelCASLost` | `FutureTask.cancel:165`: state read finding non-NEW (lost), else the `STATE.compareAndSet` result | `onCancelStateRead` GTR:1213, `onCasInt` GTR:1240 |
| `CancelReadRunner` | `cancel:171` `runner` read | `onCancelRunnerRead` GTR:1227 |
| `CancelDoInterrupt` | entry of `Thread.interrupt()` called from `cancel:173` | `onInterruptCall` GTR:1024 |
| `CancelFinish` | `STATE.setRelease(INTERRUPTED)` at `cancel:175` | `onSetRelease` GTR:1324 |
| `ListenersBegin` | `ArrayList$Itr.<init>` `modCount` read (`ArrayList.java:986`) on the Retryer's listener list | `onItrInit` GTR:1591 |
| `ListenerNotify` / `ListenerCME` | `Itr.checkForComodification` `modCount` read (`:1042`) called from `next()`: equal / different | `onItrCheck` GTR:1601, `onItrNextExit` GTR:1621 |
| `ListenersEnd` | `Itr.hasNext` `size` read equal to `cursor` (`:992`) | `onItrHasNext` GTR:1630 |
| `PredicateAccepts` / `StopStrategyStops` / `WaitStrategyComputes` | return of `apply` / `shouldStop` / `computeSleepTime` called directly by `Retryer.call` (`:170/173/176`) | `onDecision` GTR:952 |
| `BlockNegative` / `BlockInterrupted` / `BlockZero` / `BlockSleepStart` | JPF `Thread.sleep(long)` model (patch 0003, JDK 11 `JVM_Sleep` semantics): the IAE `athrow`; the entry `interrupted()` check | `onSleepThrow` GTR:980, `onSleepCheck` GTR:990 |
| `SleepReturns` / `SleepInterrupted` | the final `interrupted()` check after the sleep's scheduling point (`sleep0`) | `onSleepCheck` GTR:990 |
| `WorkerPollBlock` | successful `casHead` at `SynchronousQueue.java:360` pushing a REQUEST node in `getTask`'s poll | `onCasHead` GTR:1546 |
| `WorkerTake` | `LinkedBlockingQueue.take/poll`'s `count.getAndDecrement()` / `ArrayBlockingQueue.dequeue`'s `count--` | `onAtomicDec` GTR:1495, `onAbqCount` GTR:1507, `onDequeued` GTR:1524 |
| `WorkerRunTaskStart` / `WorkerRunTaskSkip` | `FutureTask.run:255` state read on a limiter worker (after `runWorker`'s interrupt clear) | `onRunStateRead` GTR:1128 |
| `WorkerRunnerCAS` | `RUNNER.compareAndSet` at `run:256` | `onCasObj` GTR:1288 |
| `BodyStart` / `BodySkip` | `run:260` state read finding NEW / `runner = null` at `run:277` after the body was skipped | `onRunStateRead` GTR:1128, `onRunnerCleared` GTR:1176 |
| `SetCASWon` / `SetCASLost` | `STATE.compareAndSet(NEW, COMPLETING)` in `set:229` / `setException:247`; lost: the following `runner = null` (`run:277`) | `onCasInt` GTR:1240, `onRunnerCleared` GTR:1176 |
| `SetFinish` | `STATE.setRelease` at `set:231` / `setException:249` | `onSetRelease` GTR:1324 |
| `RunFinallySpin` / `RunFinallyExit` | `run:280` state read after `BodySkip`/`SetCASLost` | `onRunStateRead` GTR:1128 |
| `SpinExit` | `handlePossibleCancellationInterrupt:332` state read that is not INTERRUPTING | `onSpinRead` GTR:1191 |
| `WorkerExit` | `ThreadPoolExecutor.getTask()` returning null on a limiter worker | `onGetTaskExit` GTR:1567 |
| `OuterWorkerRelease` | return of the outer `FutureTask.run` of a `wrapOnLimiterPool` caller | `onRunExit` GTR:1204 |
| `Interrupt` | entry of `Thread.interrupt()` on a direct caller from another thread (not from `FutureTask.cancel`) | `onInterruptCall` GTR:1024 |
| `CancelOuter` | outer `Future.cancel(true)`: the CAS if `call()` has not started, else the `interrupt()` of its thread | `onCasInt` GTR:1240, `onInterruptCall` GTR:1024 |
| `AddListenerBegin` / `AddListenerEnd` | `ArrayList.add(E):498` `modCount` write / `add(E,Object[],int):488` `size` write on the Retryer's list by a non-caller thread | `onAddModCount` GTR:1643, `onAddSize` GTR:1652 |
| `ExecutorShutdown` | return of `TPE.advanceRunState` called by `shutdown()` on the limiter executor | `onAdvanceRunState` GTR:1575 |
| `DelayElapses` | silent (no event), as the spec says | — |

Commit points that differ from, or refine, the instrumentation spec's wording:

- `WorkerExit` is stamped where `getTask()` returns null. Under JPF's default `vm.shared.never_break_methods` (which contains `ThreadPoolExecutor.getTask`, transitively) the decision inside `getTask` (SynchronousQueue keep-alive cancel, or the SHUTDOWN check) and that return are one transition, so no other thread's event can fall between them. With a finer JPF configuration the commit point must move to the `tryCancel` of the timed-out wait node (cached pool) or the SHUTDOWN-branch `decrementWorkerCount` (`TPE.java:1035`).
- `SubmitHandoff` can be committed by a thread other than the caller (TransferStack "help a fulfiller"); the event is still the caller's (its `tid`, `attemptNo`, `intr`), stamped at that CAS.
- `SubmitRejected` after a failed cached-pool offer and a concurrent `shutdown()` is stamped at `reject`, not at the failed offer (only a saturated bounded pool rejects at the offer).
- `Interrupt` and `CancelOuter` aimed at a caller whose `call()` already ended are not emitted (`base.tla` treats the call as done: `Interrupt` needs `cpc # "Done"`, and `ExitCall` completes the outer future).

## Workloads and JPF configuration

Each workload builds a Retryer, calls `Harness.begin(config, retryer, limiterExecutor)` (recording starts), runs caller threads `c1`/`c2` (and environment threads `e` = interrupter, `b` = builder, `main`), and ends with `Harness.end()`. Callable behaviors come from `Work` plans (`"Ret|Exc|Stuck"` = JPF chooses one per attempt via `Verify.getInt`); environment threads wait a JPF-chosen number of yields (`Delay.some`). Time limits are `fixedTimeLimit(1, NANOSECONDS, ...)`: an attempt times out exactly when JPF lets the caller's `parkNanos` in `FutureTask.awaitDone` time out, so JPF explores timeouts at every scheduling point (with a longer limit, JPF's spurious park timeouts would just re-park, because JPF's default `SystemTime` time model is host time). The cached pools keep their 60 s keep-alive, so idle workers exit only after `shutdown()` (or never, in `default_limiter`).

| Workload | Configuration (base.tla constants) | Targets |
|---|---|---|
| `nolimit_basic` | None, c1, AfterAttempt 3, Ret/RetBad/Exc/Err | results, BadResult, #67 Error exit, stop |
| `nolimit_interrupt` | None, c1 + interrupter, AfterAttempt 3, Zero/Positive sleeps, Ret/Exc/IntrRet/IntrBlock | S2: interrupts in bodies, listeners, sleeps (D-6) |
| `nolimit_decision` | None, AfterDelay (5 ms), join overflow → Negative / Positive, RetBad/Exc/Ret | S5: BlockNegative (IAE escape), expiry |
| `listeners_add` | None, builder thread adds listener 2 after build | S3: D-8 CME, D-9/#48 |
| `fixed_cached` | Fixed/Cached, AfterAttempt 3, Ret/Exc/Err/IntrRet/IntrBlock/Stuck | S1: D-1..D-3 timeout races |
| `fixed_cached_interrupt` | Fixed/Cached, interrupter, AfterAttempt 2, Ret/Exc/Stuck | S2 with limits: CallerIE (D-5) |
| `fixed_pool` | Fixed/Fixed(1), AfterAttempt 3, Stuck/IntrBlock/Ret/Exc | S4/D-4 queued timeouts |
| `bounded_shared` | Fixed/Bounded(1,1), callers c1+c2, Ret/Stuck | D-10 rejection, sharing |
| `shutdown_race` | Fixed/Cached, retryOn {CallableExc}, concurrent shutdown | D-10 / #29 ExecExc exits |
| `wrap_cancel` | wrap caller on a separate outer pool, outer `cancel(true)` | D-7 |
| `wrap_samepool` | wrap caller on the limiter's own Fixed(1) pool | starvation, OuterWorkerRelease |
| `sharing` | Fixed/Cached, c1+c2 on one Retryer, builder adds listener 2 | sharing, #48 |
| `default_limiter` | two-argument `fixedTimeLimit` (SimpleTimeLimiter's own cached pool) | #92 |

JPF settings (`run.sh`): `+search.class=grtrace.TraceSearch`, `+cg.randomize_choices=FIXED_SEED +cg.seed=<per workload>` (reproducible), `+vm.storage.class=` (no state matching), `+search.properties=gov.nasa.jpf.vm.NoUncaughtExceptionsProperty`, `+search.depth_limit=20000`, recorder options `grtrace.max_paths/max_traces/min_traces/budget_ms/quiesce_steps/max_events`. A path ends when all threads terminated, or 150 scheduling steps after `Harness.end()` (threads that never end: `Stuck` bodies, idle pools that are not shut down), or after 400 events. A trace is kept if it is new and, after the first 5, adds a coverage feature (an event with new key field values, or a new per-thread or global event pair); `max_traces` caps each workload. Only `nolimit_decision` depends on host time (`stopAfterDelay`), so its traces vary between runs.

jpf-core fixes (`patches/jpf-core/`, commits on `local/reachability-fence`): 0001–0002 were part of the provided environment (`Reference.reachabilityFence`, `JPFFieldVarHandle.weakCompareAndSet/setRelease`). Added here: 0003 `Thread.sleep(long)` follows JDK 11 `JVM_Sleep` (IAE on a negative time, a pending interrupt is cleared and thrown, 0 ms yields, a positive sleep is a scheduling point followed by an interrupt check) — JPF's model had no argument or interrupt checks, so `BlockNegative`, `BlockInterrupted` and `SleepInterrupted` were unreachable; 0004 `Thread.interrupt()` sets the flag of a SLEEPING thread (JPF dropped it); 0005 `Object.wait()` with a pending interrupt throws at once (JPF also registered a wait choice point, which lost the exception and blocked the thread).

## Current traces

`bash harness/run.sh --validate` (2026-11-26): 379 traces (13,096 events) from 13 workloads, none cut to a prefix; every one of the 51 traced actions occurs in at least one trace (rarest: `SleepInterrupted` 1, `BlockNegative` 1, `OuterWorkerRelease` 2, `ListenerCME` 3). TLC replay through `spec/Trace.tla`: 321 pass, 58 stop at a known spec gap (57 GAP-1, 1 GAP-2), 0 other failures. Per-trace results: `build/run/validation.txt`; counts and coverage: `build/full-run.log`. `traces/trace.ndjson` (the file `Trace.tla` reads when `JSON` is unset) is a copy of `fixed_cached-001.ndjson`.

## Known spec gaps (traces are correct; base.tla cannot replay them)

Resolved in Phase 3 (`spec/changelog.md` Round 1): `base.tla` now has `WorkerPollCancel` (silent `SilentPollCancel` in `Trace.tla`), `WorkerTake` clears the interrupt, and `ExecutorShutdown` interrupts idle workers; all 379 traces replay. The description below is kept for reference.

`tools/validate_traces.py` labels these failures `GAP-1` / `GAP-2`. All other events of these traces are consistent up to the failing event.

- **GAP-1: getTask consumes a stale cancellation interrupt.** After `CancelDoInterrupt`, the worker's interrupt usually survives `FutureTask.run` (`:343` does not clear it). `base.tla` keeps it until the next `WorkerRunTaskStart`, but the worker consumes it in `getTask` first. Cached pool: `SynchronousQueue.poll` pushes the node (`WorkerPollBlock`, `intr` true), sees the interrupt, cancels the node and throws `InterruptedException`, which `getTask` swallows (`TPE.java:1058`), so the worker pushes again (a second `WorkerPollBlock`, `intr` false) — replay stops there (`wpc` is already `Idle`). Fixed/bounded pools: `take()` → `lockInterruptibly()` throws and clears, `getTask` retries, and `WorkerTake` reports `intr` false where `base.tla` has true. A fix in `base.tla`: let the poll/take step from `GetTask`/`Idle` with `intr[w]` consume it (`intr' = FALSE`, back to `GetTask` without becoming matchable), and let `WorkerTake` clear `intr`. If the spec gets a separate action for the cancelled poll, add an event at `SNode.tryCancel` reached from `awaitFulfill`'s `isInterrupted` branch (`SynchronousQueue.java:441-442`).
- **GAP-2: a worker can push its poll node after `shutdown()`.** `getTask` checks the run state (`TPE.java:1033`) before polling; a `shutdown()` in between is followed by `WorkerPollBlock` (with `intr` true from `interruptIdleWorkers`), but `base.tla`'s `WorkerPollBlock` requires `~exShutdown`. Under JPF this needs a scheduling point inside `getTask` (the first `SynchronousQueue$TransferStack$SNode` class initialization), so it is rare. The worker then cancels and exits; no offer can match it after shutdown.

## Changing the instrumentation

- **Add a field to an event**: find the event's handler in the table above and add `e.put("field", value)` where the event is created. Read the value from the JVM state at that point: `intField(ref, "f")` / `refField(ref, "f")` for heap objects, `ti.getTopFrame().peek()` for the value an instruction just produced, `frame.getLocalVariable(slot)` for locals (`attemptNo(ti)` reads `Retryer.call`'s slot 4). For a value only known later, `e.open("field")` and fill it in from a later hook with `e.put` (open fields cut the trace at path end if never filled).
- **Add an event type**: add the method to `CODES` (key `class.name(signature)`), dispatch it in `methodEntered` / `methodExited` / `instructionExecuted` / `executeInstruction` (the last two receive the instruction: match `GETFIELD`/`PUTFIELD` field names and `insn.getLineNumber()`), and call `callerEv(...)` (caller: adds `attemptNo`, `intr`), `workerEv(...)` (worker: adds `intr`) or `emit(name, tid)`. Ignore `instructionExecuted` calls with `next == insn` (JPF re-executes an instruction after a choice point; only the second execution does the access) — the dispatcher already does. Then add the name to `ACTIONS` in `tools/report.py`.
- **Move a capture point**: change which hook calls the handler; to stamp an event earlier than it is emitted, record `tick()`/`ts()` at the new point and emit later with `emitAt(name, tid, clock, ts)` (see `GetTimeout`).
- **Workloads**: copy one in `src/workloads/grwork/w/`, keep its `CONFIG` JSON in sync with its builder calls (the recorder copies it into the config line; `stopDelayMs` is consumed by the recorder for `expired`), and add a row to `WORKLOADS` in `run.sh`.

## Rebuild and re-run

```bash
cd .specular-output
bash harness/run.sh                      # build + all workloads -> traces/*.ndjson (+ report)
bash harness/run.sh --validate           # ... and replay every trace through spec/Trace.tla
bash harness/run.sh fixed_cached sharing # only these workloads (their old traces are replaced)
bash harness/run.sh --quick              # small budgets
python3 -I harness/tools/validate_traces.py traces/fixed_cached-001.ndjson   # replay one trace
```

Per-workload JPF logs and selection statistics: `harness/build/run/<workload>.log` and `<workload>.summary.json`. Debug output (every emitted event): add `+grtrace.debug=true` to the JPF command in `run.sh`. Exploration is reproducible for a given seed and budget, except `nolimit_decision` (host time).
