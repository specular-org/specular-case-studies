# Instrumentation Spec: guava-retrying 2.0.0

Maps every `base.tla` action to the code point a recorder must observe, so recorded executions replay through `Trace.tla`. Category B: one NDJSON file per recorded execution, events grouped per thread by `Trace.tla`, ordered across threads by `[start, end]` (`ViablePIDs`).

The library source is not modified. The recommended recorder is a Java PathFinder (JPF) listener on JDK 11, as the guidance suggests (jpf-core `local/reachability-fence`, smoke example `/home/ubuntu/guava-retrying-20261126/jpf-smoke/`): JPF executes the real guava-retrying, Guava 22.0 and JDK 11 `FutureTask` / `ThreadPoolExecutor` / `ArrayList` bytecode, explores thread schedules, and lets a listener read fields (`FutureTask.state`, `runner`, `ArrayList.size` / `modCount`, thread interrupt status) at exact instructions. Every action below is defined by one shared-memory access in that code (its *commit point*); `base.tla` is split at exactly these accesses, which are also where JPF switches threads.

Code references: guava-retrying files are under `src/main/java/com/github/rholder/retry/`; `SimpleTimeLimiter` is Guava 22.0; `FutureTask`, `ThreadPoolExecutor` (TPE), `AbstractExecutorService` (AES), `ArrayList` are JDK 11 (`/home/ubuntu/scratch/jdk-src/11/`); `JVM_Sleep` is JDK 11 `hotspot/jvm.cpp`.

## Section 1: Trace Event Schema

### File

One file per recorded execution, in `traces/` (sibling of `spec/`), e.g. `traces/<workload>-<n>.ndjson`. `Trace.tla` reads `../traces/trace.ndjson` unless the `JSON` environment variable names another file (the validation tools set it).

Line 1 is the configuration line; every other line is an event line.

### Configuration line

```json
{"tag":"config",
 "callers":["c1"], "workers":["w1","w2"], "tasks":["t1","t2","t3"],
 "numInitListeners":1, "numExtraListeners":1,
 "limiter":"Fixed", "execKind":"Cached", "poolSize":2, "queueCap":0,
 "retryOn":["Timeout","CallerIE","CallableExc","CallableIE","Rejected"],
 "stopKind":"AfterAttempt", "stopAfter":3,
 "sleepClasses":["Zero"], "modes":["Ret","Stuck"],
 "wrapCallers":[], "wrapOnLimiterPool":[], "outerWorkers":{}}
```

| Field | `base.tla` constant | Value |
|---|---|---|
| `callers` | `Callers` | ids of the threads that run `Retryer.call` in this execution |
| `workers` | `Workers` | ids of every thread of the limiter's executor that appears |
| `tasks` | `TaskIds` | ids of every `FutureTask` created by `SimpleTimeLimiter.callWithTimeout` (`SimpleTimeLimiter.java:149`) |
| `numInitListeners` | `NumInitListeners` | listeners added with `withRetryListener` before `build()` |
| `numExtraListeners` | `NumExtraListeners` | listeners the workload may add after `build()` |
| `limiter` | `Limiter` | `"None"` (no `withAttemptTimeLimiter`, or `noTimeLimit()`), `"Fixed"` (`fixedTimeLimit`) |
| `execKind` | `ExecKind` | `"Cached"` (2-argument `fixedTimeLimit`, or `Executors.newCachedThreadPool()`), `"Fixed"` (`newFixedThreadPool(n)` / `newSingleThreadExecutor()`), `"Bounded"` (`new ThreadPoolExecutor(n, n, 0, ms, new ArrayBlockingQueue<>(q))`, default AbortPolicy) |
| `poolSize`, `queueCap` | `PoolSize`, `QueueCap` | `n`, `q` above (any positive value for `"Cached"`) |
| `retryOn` | `RetryOn` | attempt kinds (below) the rejection predicate accepts |
| `stopKind`, `stopAfter` | `StopKind`, `StopAfter` | `"Never"` (`neverStop`), `"AfterAttempt"` with `stopAfter = n` (`stopAfterAttempt(n)`), `"AfterDelay"` (`stopAfterDelay`) |
| `sleepClasses` | `SleepClasses` | classes the wait strategy can return: `"Zero"`, `"Positive"`, `"Negative"` |
| `modes` | `Modes` | callable behaviors (below) the workload uses |
| `wrapCallers` | `WrapCallers` | callers that run as `executor.submit(retryer.wrap(callable))` |
| `wrapOnLimiterPool` | `WrapOnLimiterPool` | wrap callers whose outer executor is the limiter's executor |
| `outerWorkers` | (pins `wOuter`) | `{caller: worker}` for each caller in `wrapOnLimiterPool`: the pool thread that runs its `RetryerCallable` |

`retryOn` follows from the `retryIf*` calls and the workload's exception classes (one class per mode): `retryIfException()` accepts `CallableExc`, `CallableIE`, `Timeout`, `CallerIE`, `Rejected`; `retryIfRuntimeException()` accepts `Timeout`, `Rejected`, and `CallableExc` if the workload throws a `RuntimeException`; `retryIfExceptionOfType(X)` accepts the kinds whose throwable is an `X`; `retryIfResult(p)` accepts `BadResult`.

### Event line envelope

```json
{"tag":"trace","event":"<base action>","tid":"<thread id>","start":17,"end":17, ...fields}
```

- `event`: the `base.tla` action name (Section 2); one event per action execution, no other events.
- `tid`: callers `"c1"`, `"c2"`, … (the thread executing `Retryer.call`; for `wrap()` the outer pool thread while it executes `RetryerCallable.call`); limiter workers `"w1"`, `"w2"`, … (in order of thread creation); any other thread (test main, builder, interrupter) any stable id, e.g. `"main"`, `"b"`, `"e"`.
- `start`, `end`: a global logical clock maintained by the recorder, incremented at every recorded commit point. Use `start = end =` the clock value at the action's commit point. This makes the recording totally ordered, so exactly one interleaving replays it (`Trace.cfg` checks `TraceMatched` over all behaviors). Overlapping intervals are only for recordings without exact commit points (e.g. a real JVM with `nanoTime`); validate those with `INVARIANT TraceNotFullyConsumed` instead of the property (valid iff the invariant is reported violated).
- Within one `tid`, lines must appear in program order. Across threads the file order is irrelevant: `Trace.tla` orders by `start`/`end`. A recorder may therefore write an event later than its commit point (e.g. `GetTimeout`, `SubmitHandoff.worker`, `attemptKind`), as long as its `start`/`end` carry the commit point's clock value.

### Identifiers and value vocabularies

| Name | Values |
|---|---|
| task id | `"t1"`, `"t2"`, … per `FutureTask` object, in creation order (`AES.java:107-109`) |
| listener id | integers `1`, `2`, … in order of `ArrayList.add` on the builder's list (`RetryerBuilder.java:63`); the first `numInitListeners` are added before `build()` |
| `state` | `FutureTask.state` (`FutureTask.java:93-99`): 0 `"NEW"`, 1 `"COMPLETING"`, 2 `"NORMAL"`, 3 `"EXCEPTIONAL"`, 4 `"CANCELLED"`, 5 `"INTERRUPTING"`, 6 `"INTERRUPTED"` |
| `attemptKind` | from the `Attempt` built at `Retryer.java:161/163`: `ResultAttempt` → `"Result"`, or `"BadResult"` if the workload's `retryIfResult` predicate matches the value; `ExceptionAttempt` with cause `UncheckedTimeoutException` → `"Timeout"`; `InterruptedException` raised by `FutureTask.get` on the caller (a `GetInterrupted` event preceded it) → `"CallerIE"`; `RejectedExecutionException` → `"Rejected"`; `InterruptedException` thrown by the callable → `"CallableIE"`; an `Error` → `"CallableErr"`; any other `Exception` → `"CallableExc"` |
| `result` | what the callable body produced: `"Result"`, `"BadResult"`, `"CallableExc"`, `"CallableErr"`, `"CallableIE"` |
| `mode` | the behavior the workload's callable implements for this attempt (below) |
| `sleep` | class of `waitStrategy.computeSleepTime(attempt)` (`Retryer.java:176`): `< 0` `"Negative"`, `0` `"Zero"`, `> 0` `"Positive"` |
| `outcome` | `"Returned"` (`call()` returned) or `"ExecExc"` (`call()` threw `ExecutionException`) |
| `intr` | the interrupt status of the event's thread at the commit point, read without clearing (JPF: `ThreadInfo.isInterrupted(false)`) |
| `attemptNo` | Retryer.call's local `attemptNumber` at the commit point: local slot 4 of `Retryer.call(Callable)` (slots: 0 this, 1 callable, 2-3 startTime, 4 attemptNumber; confirmed with `javap -l` on the analysis build, whose classes carry a LocalVariableTable). It is initialized by `istore 4` at bytecode offset 5 |
| `expired` | `attempt.getDelaySinceFirstAttempt() >= ` the `stopAfterDelay` limit, read from the `Attempt` object built right after the event (`false` when `stopKind` is not `"AfterDelay"`) |

### Example

The start of a recording that replays through `Trace.tla` (hand-written to check the spec, not from the implementation): attempt 1 times out, its `Ret` body returns between the timeout decision and the cancel, and the runner spins on INTERRUPTING while the cancel interrupts it.

```json
{"tag":"config","callers":["c1"],"workers":["w1","w2"],"tasks":["t1","t2"],"numInitListeners":1,"numExtraListeners":0,"limiter":"Fixed","execKind":"Cached","poolSize":2,"queueCap":0,"retryOn":["Timeout","CallerIE","CallableExc","CallableIE","Rejected"],"stopKind":"AfterAttempt","stopAfter":3,"sleepClasses":["Zero"],"modes":["Ret"],"wrapCallers":[],"wrapOnLimiterPool":[],"outerWorkers":{}}
{"tag":"trace","event":"CallStart","tid":"c1","start":1,"end":1,"attemptNo":1,"intr":false}
{"tag":"trace","event":"SubmitNewWorker","tid":"c1","start":2,"end":2,"attemptNo":1,"intr":false,"task":"t1","worker":"w1"}
{"tag":"trace","event":"WorkerRunTaskStart","tid":"w1","start":3,"end":3,"intr":false,"task":"t1","state":"NEW"}
{"tag":"trace","event":"WorkerRunnerCAS","tid":"w1","start":4,"end":4,"intr":false,"task":"t1"}
{"tag":"trace","event":"BodyStart","tid":"w1","start":5,"end":5,"intr":false,"task":"t1","mode":"Ret"}
{"tag":"trace","event":"GetTimeout","tid":"c1","start":6,"end":6,"attemptNo":1,"intr":false,"task":"t1","state":"NEW"}
{"tag":"trace","event":"BodyReturns","tid":"w1","start":7,"end":7,"intr":false,"task":"t1","result":"Result"}
{"tag":"trace","event":"CancelCASWon","tid":"c1","start":8,"end":8,"attemptNo":1,"intr":false,"task":"t1","state":"INTERRUPTING"}
{"tag":"trace","event":"CancelReadRunner","tid":"c1","start":9,"end":9,"attemptNo":1,"intr":false,"task":"t1","runner":"w1"}
{"tag":"trace","event":"SetCASLost","tid":"w1","start":10,"end":10,"intr":false,"task":"t1","state":"INTERRUPTING"}
{"tag":"trace","event":"RunFinallySpin","tid":"w1","start":11,"end":11,"intr":false,"task":"t1","state":"INTERRUPTING"}
{"tag":"trace","event":"CancelDoInterrupt","tid":"c1","start":12,"end":12,"attemptNo":1,"intr":false,"task":"t1","target":"w1"}
{"tag":"trace","event":"CancelFinish","tid":"c1","start":13,"end":13,"attemptNo":1,"intr":false,"task":"t1","state":"INTERRUPTED","attemptKind":"Timeout","expired":false}
{"tag":"trace","event":"SpinExit","tid":"w1","start":14,"end":14,"intr":true,"task":"t1","state":"INTERRUPTED"}
```

### Workload callable behaviors (`mode`)

The model's body behaviors fix where a callable looks at its interrupt status. A workload callable implements exactly one per attempt and reports it as `mode`; the commit points of `*BodyReturns` / `*BodyThrows` depend on it.

| `mode` | Implementation | End commit point |
|---|---|---|
| `Ret` | compute and `return v;` without touching the interrupt status | the `return` |
| `RetBad` | `return bad;` where `retryIfResult` matches `bad` | the `return` |
| `Exc` | `throw new IOException()` (or the configured `RuntimeException`) | the `throw` |
| `Err` | `throw new AssertionError()` | the `throw` |
| `IntrRet` | `if (Thread.interrupted()) throw new InterruptedException(); return v;` | the `Thread.interrupted()` call (true: throws, status cleared; false: returns) |
| `IntrBlock` | `synchronized (lock) { lock.wait(); }` with no notifier: ends only by `InterruptedException` | the `InterruptedException` thrown by `wait()` (status cleared) |
| `Stuck` | never returns and never reads or clears the status, e.g. `for (;;) Thread.yield();` (JPF matches the repeated state) | none |

## Section 2: Action-to-Code Mapping

Common fields: every caller event carries `attemptNo` and `intr` (checked by `CallerPost`); every worker event except `WorkerExit` / `OuterWorkerRelease` carries `intr` (`WorkerPost`); classification events additionally carry `attemptKind` and `expired` (`ClassPost`). All listed fields are mandatory; `Trace.tla` validates each of them.

### Caller: `Retryer.call`

#### CallStart
- **Code**: `Retryer.java:155-157` (`call` entry; `attemptNumber = 1`). For `wrap()`: `Retryer.java:317-319` inside the outer `FutureTask.run`.
- **Commit point**: direct caller: entry of `Retryer.call`. Wrap caller: the outer `FutureTask.run` state check `state == NEW` at `FutureTask.java:260` that lets it call `RetryerCallable.call` (an outer cancel before that point means `call()` never starts and no event is emitted).
- **Fields**: `attemptNo` (slot 4 just after its `istore 4` at offset 5, i.e. 1; nothing shared lies between the entry and that store), `intr`.
- **Notes**: a direct caller may already be interrupted (a preceding `Interrupt` event).

#### CallerBodyStart (noTimeLimit)
- **Code**: `AttemptTimeLimiters.java:77-78` (`NoAttemptTimeLimit.call` → `callable.call()`).
- **Commit point**: entry of the workload callable's `call()` on the caller thread.
- **Fields**: `attemptNo`, `intr`, `mode`.

#### CallerBodyReturns (noTimeLimit)
- **Code**: `Retryer.java:160-161`.
- **Commit point**: the mode's end commit point (Section 1), normal completion.
- **Fields**: `attemptNo`, `intr`, `attemptKind` (`"Result"` / `"BadResult"`), `expired`.

#### CallerBodyThrows (noTimeLimit)
- **Code**: `Retryer.java:162-163` (`catch (Throwable t)`).
- **Commit point**: the mode's end commit point, abrupt completion (for `IntrRet` / `IntrBlock` the interrupt check that throws and clears the status).
- **Fields**: `attemptNo`, `intr` (after the clear), `attemptKind` (`"CallableExc"` / `"CallableErr"` / `"CallableIE"`), `expired`.

#### SubmitRejected
- **Code**: `SimpleTimeLimiter.java:149` → `TPE.execute` (`TPE.java:1318-1356`) → `reject` (`:824-826`) → `AbortPolicy.rejectedExecution` (`:2052-2056`); caught at `Retryer.java:162-163`.
- **Commit point**: saturated bounded pool: the failed `workQueue.offer` at `TPE.java:1347` (queue full; the following `addWorker(command,false)` at `:1354` then fails). Shut-down executor: the `reject` call.
- **Fields**: `attemptNo`, `intr`, `attemptKind` (`"Rejected"`), `expired`.

#### SubmitHandoff (cached pool)
- **Code**: `TPE.java:1347` `SynchronousQueue.offer` succeeds.
- **Commit point**: the successful `offer` (it matches a worker blocked in `poll`).
- **Fields**: `attemptNo`, `intr`, `task`, `worker` (the polling worker whose `poll` returns this task; fill it in when that worker's next event names the task, or `"unknown"` only if the recording ends first).
- **Notes**: the worker's `poll` returning the task is part of this event (no worker event for it).

#### SubmitNewWorker
- **Code**: cached pool `TPE.java:1347` (offer fails) → `:1354` `addWorker(command, false)`; fixed/bounded pool `:1342-1344` `addWorker(command, true)` (`TPE.java:885-…`, thread start `:937`).
- **Commit point**: cached pool: the failed `SynchronousQueue.offer` at `:1347` that leads to a successful `addWorker` (the decision "no worker is polling" is made there). Fixed/bounded: the successful `compareAndIncrementWorkerCount` in `addWorker` (`:899`).
- **Fields**: `attemptNo`, `intr`, `task`, `worker` (the new thread's id).
- **Notes**: emit only if `addWorker` succeeds; if it fails after a shutdown, emit `SubmitRejected` instead.

#### SubmitQueued (fixed/bounded pool)
- **Code**: `TPE.java:1347` `workQueue.offer(command)` succeeds.
- **Commit point**: the successful `offer`.
- **Fields**: `attemptNo`, `intr`, `task`, `queueLen` (`workQueue.size()` right after the offer).
- **Notes**: do not race `shutdown()` with an in-flight `submit` in workloads: a task offered with a stale `ctl` and then removed or run (`:1348-1352`) is not modeled.

#### GetReturn
- **Code**: `SimpleTimeLimiter.java:154` → `FutureTask.get` (`FutureTask.java:197-206`) → `report` (`:116-123`); `SimpleTimeLimiter.java:162-163` unwraps an `ExecutionException`.
- **Commit point**: the read of `FutureTask.state` that returned a terminal state: `get`'s entry read (`:201`) when `awaitDone` is not called, `awaitDone`'s top-of-loop read (`:406`), or the deadline iteration's re-read (`:438`). Equivalently the entry of `FutureTask.report` on the caller thread (no shared access lies between).
- **Fields**: `attemptNo`, `intr`, `task`, `state` (`"NORMAL"` / `"EXCEPTIONAL"`), `attemptKind`, `expired`.

#### GetInterrupted
- **Code**: `FutureTask.java:416-419` (`Thread.interrupted()` → `removeWaiter` → `throw new InterruptedException()`); `SimpleTimeLimiter.java:155-157`.
- **Commit point**: the `Thread.interrupted()` call in `awaitDone` that returns true.
- **Fields**: `attemptNo`, `intr` (false: cleared), `task`, `state` (`FutureTask.state` at the commit point; any value, the task may have completed since the iteration's state read).

#### GetTimeout
- **Code**: `FutureTask.java:427-439` (deadline: `removeWaiter`, `return state`), `get` `:202-204` (`TimeoutException`); `SimpleTimeLimiter.java:164-166`.
- **Commit point**: the `Thread.interrupted()` call (`:416`, returning false) of the `awaitDone` iteration whose `return state` (`:438`) yields NEW or COMPLETING. Record the clock at every `:416` false return; when `awaitDone` returns ≤ COMPLETING, emit the event with the clock of that iteration's `:416` call.
- **Fields**: `attemptNo`, `intr` (false), `task`, `state` (`FutureTask.state` at the commit point: `"NEW"` or `"COMPLETING"`).
- **Notes**: if the re-read returns a terminal state the call returns normally: emit `GetReturn` at the re-read instead. Under JPF the deadline is the nondeterministic `parkNanos` timeout.

#### CancelCASWon / CancelCASLost
- **Code**: `FutureTask.java:165-167` (`state == NEW && STATE.compareAndSet(this, NEW, INTERRUPTING)`), called from `SimpleTimeLimiter.java:156` (after IE) or `:165` (after timeout).
- **Commit point**: the successful CAS (`CancelCASWon`), or the state read / CAS that found the state not NEW (`CancelCASLost`).
- **Fields**: `CancelCASWon`: `attemptNo`, `intr`, `task`, `state` (`"INTERRUPTING"`). `CancelCASLost`: `attemptNo`, `intr`, `task`, `state` (the non-NEW state that made it fail), `attemptKind` (`"Timeout"` / `"CallerIE"`), `expired`.
- **Notes**: `CancelCASLost` is the classification event of a discarded completion (D-2): Guava ignores `cancel`'s `false` and throws anyway.

#### CancelReadRunner
- **Code**: `FutureTask.java:171` `Thread t = runner;`
- **Commit point**: that read.
- **Fields**: `attemptNo`, `intr`, `task`, `runner` (worker id or `"none"`).

#### CancelDoInterrupt
- **Code**: `FutureTask.java:172-173` `t.interrupt()`.
- **Commit point**: the `interrupt()` call (the target's status becomes true).
- **Fields**: `attemptNo`, `intr`, `task`, `target` (worker id).
- **Notes**: no event when `runner` was null.

#### CancelFinish
- **Code**: `FutureTask.java:175` `STATE.setRelease(this, INTERRUPTED)`, `:179` `finishCompletion()`; `SimpleTimeLimiter.java:157/166` throws; `Retryer.java:162-163` builds the `ExceptionAttempt`.
- **Commit point**: the `setRelease(INTERRUPTED)` write.
- **Fields**: `attemptNo`, `intr`, `task`, `state` (`"INTERRUPTED"`), `attemptKind` (`"Timeout"` / `"CallerIE"`), `expired`.

#### ListenersBegin
- **Code**: `Retryer.java:166` → `ArrayList.iterator()` (`ArrayList.java:976-978`) → `Itr` field init `expectedModCount = modCount` (`:986`).
- **Commit point**: the read of `ArrayList.modCount` in the `Itr` constructor.
- **Fields**: `attemptNo`, `intr`, `modCount` (the value read), `size` (`ArrayList.size` at the commit point).

#### ListenerNotify
- **Code**: `ArrayList.java:991-1004` (`hasNext` true, `next()` → `checkForComodification` passes → `elementData[cursor]`); `Retryer.java:167` `listener.onRetry(attempt)`.
- **Commit point**: the `modCount` read in `Itr.checkForComodification` (`:1042`) that matches `expectedModCount`.
- **Fields**: `attemptNo`, `intr`, `listener` (id of the returned element), `cursor` (`Itr.cursor` after `next()`).

#### ListenerCME
- **Code**: `ArrayList.java:1041-1044` throws `ConcurrentModificationException`; not caught in `Retryer.call` (the loop `:166-168` is outside the try/catch `:159-164`).
- **Commit point**: the `modCount` read in `checkForComodification` that differs from `expectedModCount`.
- **Fields**: `attemptNo`, `intr`, `modCount` (the value read), `expectedModCount`.

#### ListenersEnd
- **Code**: `ArrayList.java:991-993` `hasNext()` returns false.
- **Commit point**: the `size` read in `hasNext` that equals `cursor`.
- **Fields**: `attemptNo`, `intr`, `cursor`, `size` (the value read).

#### PredicateAccepts
- **Code**: `Retryer.java:170-171` (`!rejectionPredicate.apply(attempt)` → `return attempt.get()`).
- **Commit point**: return of `rejectionPredicate.apply` with `false` (thread-local from there to the exit).
- **Fields**: `attemptNo`, `intr`, `outcome` (`"Returned"` / `"ExecExc"`).

#### StopStrategyStops
- **Code**: `Retryer.java:173-174` (`stopStrategy.shouldStop(attempt)` → `throw new RetryException(attemptNumber, attempt)`).
- **Commit point**: return of `shouldStop` with `true`.
- **Fields**: `attemptNo`, `intr`, `count` (`RetryException.getNumberOfFailedAttempts()`, `RetryException.java:44-45, 58`).

#### WaitStrategyComputes
- **Code**: `Retryer.java:176`.
- **Commit point**: return of `waitStrategy.computeSleepTime`.
- **Fields**: `attemptNo`, `intr`, `sleep`.

#### BlockNegative / BlockInterrupted / BlockZero / BlockSleepStart
- **Code**: `Retryer.java:177-182` → `BlockStrategies.java:45-46` → `Thread.sleep` → `JVM_Sleep` (`jvm.cpp:3094-3134`).
- **Commit point**: `BlockNegative`: the sign check throwing `IllegalArgumentException` (`:3097-3099`). The others: the interrupt test in `JVM_Sleep` (`:3101`): true → `BlockInterrupted` (IE; `Retryer.java:179-181` re-sets the status and throws `RetryException`); false with 0 ms → `BlockZero` (yield, return, `attemptNumber++` at `Retryer.java:157`); false with > 0 ms → `BlockSleepStart`.
- **Fields**: all: `attemptNo` (`BlockZero`: the incremented value), `intr`. `BlockInterrupted` also `count`.
- **Notes**: under JPF use the corresponding points of JPF's `Thread.sleep` model.

#### SleepReturns / SleepInterrupted
- **Code**: `jvm.cpp:3114-3131` (interruptible sleep); `Retryer.java:157` or `:179-181`.
- **Commit point**: the sleep's final interrupt check: false → `SleepReturns` (the sleep completed), true → `SleepInterrupted`.
- **Fields**: `attemptNo` (`SleepReturns`: the incremented value), `intr`; `SleepInterrupted` also `count`.

### Worker: `ThreadPoolExecutor.runWorker` / `getTask` / `FutureTask.run`

#### WorkerPollBlock (cached pool)
- **Code**: `TPE.getTask` (`TPE.java:1052-1053`) → `SynchronousQueue.poll(keepAlive)`.
- **Commit point**: the point where the worker becomes matchable by `offer` (the CAS that pushes its wait node inside `SynchronousQueue`'s transferer).
- **Fields**: `intr`.

#### WorkerTake (fixed/bounded pool)
- **Code**: `TPE.getTask` (`TPE.java:1052-1056`) `workQueue.take()` / `poll()` returns a task.
- **Commit point**: the dequeue.
- **Fields**: `task`, `intr`.

#### WorkerRunTaskSkip / WorkerRunTaskStart
- **Code**: `TPE.runWorker` `:1115-1124` (`w.lock()`; not STOP: `Thread.interrupted()` clears a stale interrupt) → `task.run()` (`:1128`) → `FutureTask.run` `:255` (`state != NEW` → return).
- **Commit point**: the `state` read at `FutureTask.java:255`. Not NEW → `WorkerRunTaskSkip` (run returns, back to `getTask`); NEW → `WorkerRunTaskStart`.
- **Fields**: `task`, `intr` (false after the clear), `state` (the value read).

#### WorkerRunnerCAS
- **Code**: `FutureTask.java:256` `RUNNER.compareAndSet(this, null, currentThread)`.
- **Commit point**: the CAS.
- **Fields**: `task`, `intr`.

#### BodyStart / BodySkip
- **Code**: `FutureTask.java:259-260` (`c = callable; if (c != null && state == NEW)`), `:264` `c.call()`; skip → finally `:277` `runner = null`.
- **Commit point**: `BodyStart`: the `state` read at `:260` finding NEW. `BodySkip`: the `runner = null` write at `:277` (after `:260` found the state not NEW).
- **Fields**: `BodyStart`: `task`, `intr`, `mode`. `BodySkip`: `task`, `intr`, `state` (at the commit point).

#### BodyReturns / BodyThrows
- **Code**: `FutureTask.java:264-269`.
- **Commit point**: the mode's end commit point (Section 1) on the worker thread.
- **Fields**: `task`, `intr` (after; `IntrRet`/`IntrBlock` throwing clear it), `result`.

#### SetCASWon / SetCASLost
- **Code**: `set` `FutureTask.java:228-234` / `setException` `:246-252` (`STATE.compareAndSet(this, NEW, COMPLETING)`); lost → finally `:277` `runner = null`.
- **Commit point**: `SetCASWon`: the successful CAS. `SetCASLost`: the `runner = null` write at `:277` after the failed CAS (the result or exception is dropped silently).
- **Fields**: `SetCASWon`: `task`, `intr`, `state` (`"COMPLETING"`). `SetCASLost`: `task`, `intr`, `state` (at the commit point).

#### SetFinish
- **Code**: `FutureTask.java:230-232` / `:248-250` (`outcome = …; setRelease(NORMAL|EXCEPTIONAL); finishCompletion()`), then finally `:277-282`.
- **Commit point**: the `setRelease` write.
- **Fields**: `task`, `intr`, `state` (`"NORMAL"` / `"EXCEPTIONAL"`).

#### RunFinallySpin / RunFinallyExit
- **Code**: `FutureTask.java:280-282` (`int s = state; if (s >= INTERRUPTING) handlePossibleCancellationInterrupt(s)`), `:331-333`.
- **Commit point**: the `state` read at `:280`: INTERRUPTING → `RunFinallySpin`; otherwise `RunFinallyExit` (run returns; the interrupt is not cleared, `:343`).
- **Fields**: `task`, `intr`, `state` (the value read).

#### SpinExit
- **Code**: `FutureTask.java:331-333` `while (state == INTERRUPTING) Thread.yield();`
- **Commit point**: the `state` read that ends the loop.
- **Fields**: `task`, `intr`, `state` (the value read).

#### WorkerExit
- **Code**: `TPE.getTask` returns null: SHUTDOWN with an empty queue (`TPE.java:1033-1037`) or the cached pool's keep-alive poll timed out (`:1042-1048`).
- **Commit point**: `getTask` deciding to return null.
- **Fields**: none.

#### OuterWorkerRelease (wrap on the limiter pool)
- **Code**: the outer `FutureTask.run` of a `RetryerCallable` returns on a limiter pool thread; `runWorker` continues (`TPE.java:1114`).
- **Commit point**: return of the outer `FutureTask.run`.
- **Fields**: `caller`.

### Builder and environment (any thread)

#### Interrupt
- **Code**: `Thread.interrupt()` on a direct caller's thread by another thread (not from `FutureTask.cancel`).
- **Commit point**: the interrupt-status write.
- **Fields**: `target` (caller id).

#### CancelOuter
- **Code**: the outer `Future.cancel(true)` of a `wrap()` task (`FutureTask.java:164-182`), or `shutdownNow()` of the outer executor (`TPE.java:1400-1414`).
- **Commit point**: when `call()` has started: the `interrupt()` of the thread running it; otherwise the cancel's CAS.
- **Fields**: `target` (caller id).

#### AddListenerBegin / AddListenerEnd
- **Code**: `RetryerBuilder.java:61-65` → `ArrayList.add` (`ArrayList.java:497-500`: `modCount++`; `:484-489`: `elementData[s] = e; size = s + 1`).
- **Commit point**: `AddListenerBegin`: the `modCount` write. `AddListenerEnd`: the `size` write.
- **Fields**: `AddListenerBegin`: `listener`, `modCount` (after). `AddListenerEnd`: `listener`, `size` (after).

#### ExecutorShutdown
- **Code**: `ExecutorService.shutdown()` on the executor passed to `fixedTimeLimit(d, unit, executor)` (`TPE.java:1369-1381`).
- **Commit point**: `advanceRunState(SHUTDOWN)`.
- **Fields**: none.
- **Notes**: the model merges the following `interruptIdleWorkers()` (`TPE.java:783-803`): every worker in `getTask` gets its interrupt status set, so their next `WorkerPollBlock` (allowed after the shutdown only with the status set) records `intr` true.

#### DelayElapses (silent, no event)
Wall-clock time passing `stopAfterDelay`'s limit has no code point. `Trace.tla` fires it silently before a classification event whose `expired` is `true`.

#### WorkerPollCancel (silent, no event)
A cached-pool worker that pushed its `SynchronousQueue.poll` node with its interrupt status set (a stale cancellation interrupt, or the one `shutdown()` sends to idle workers) cancels the node (`awaitFulfill` `isInterrupted()` → `tryCancel`, `SynchronousQueue.java:441-442`), `poll` clears the status and throws (`:938-940`), and `getTask` polls again (`TPE.java:1058-1059`). The recorder has no event for it; the recording shows the next push as another `WorkerPollBlock` (`intr` false). `Trace.tla` fires it silently (`SilentPollCancel`) when that worker's next event is the re-push and no shutdown has happened. Queue pools need no event: `take()`'s `lockInterruptibly()` consumes the stale interrupt, so `WorkerTake` clears `intr`.

## Section 3: Special Considerations

### Why commit points, not method boundaries

JPF switches threads at every volatile or shared-field access, and `base.tla` has one action per such access. If an event were stamped at a method boundary instead, another thread's step that JPF scheduled inside the method would appear on the wrong side of it, and replay would fail. Examples where this matters:

- `GetTimeout` is decided by the `Thread.interrupted()` test, not the later `return state`: an interrupt arriving between them is ordered after the timeout.
- `CancelReadRunner` / `CancelDoInterrupt` / `CancelFinish` are separate, because the runner's `finally` (`SetCASLost`, `RunFinallySpin`) can run between any two of them. The sample `f_cancel_spin` replays a runner that spins on INTERRUPTING while the cancel interrupts it.
- `ListenerNotify` / `ListenerCME` are decided at the `modCount` read and `ListenersEnd` at the `size` read; `AddListenerBegin` (`modCount++`) and `AddListenerEnd` (`size++`) can fall between them.

### Merged code regions

Some actions cover several statements; the commit point is the only shared access that matters, and the rest is thread-local or provably unobservable:

- Classification events (`CallerBody*`, `SubmitRejected`, `GetReturn`, `CancelCASLost`, `CancelFinish`) include building the `Attempt` (`Retryer.java:161/163`). Take `attemptKind` and `expired` from that `Attempt` object when its constructor returns, and attach them to the event already stamped at the commit point.
- `WorkerRunTaskStart` includes runWorker's interrupt clear (`TPE.java:1120-1124`): nothing can interrupt the worker between the clear and the runner CAS.
- `SetFinish` includes `finishCompletion` and the finally block: no cancel can act after COMPLETING.

### State capture

Read every field at the commit point from the JVM state (JPF: `ElementInfo` of the `FutureTask` / `ArrayList`, `ThreadInfo` interrupt status, the `Retryer.call` frame's local slot 4). JPF listener callbacks are atomic, so these reads are exact. Do not compute fields from the recorder's own bookkeeping: `attemptNo`, `state`, `intr`, `modCount`, `size` and `cursor` are what the trace checks.

### Recording with JPF

- JDK 11 is required; use the jpf-core checkout `/home/ubuntu/tools/jpf-core-mku-spurious` branch `local/reachability-fence` (VarHandle and `reachabilityFence` fixes for `FutureTask`). Record further JDK model fixes in that checkout.
- JPF explores `LockSupport.parkNanos` timeouts nondeterministically (the source of `GetTimeout`) and `SynchronousQueue.poll(keepAlive)` timeouts (the source of `WorkerExit` keep-alive). Its spurious-wakeup policy covers only `Object.wait`, not `LockSupport.park`.
- Write one trace per explored path. Writing every prefix at backtrack points (lemmy/BlockingQueue v40–v44) validates partial executions too; each prefix is a valid recording.
- Keep workloads small (one or two callers, two or three attempts) so each trace stays in the 30–200 event range recommended for Category B.

### Bootstrap

`Trace.tla` starts from `base.tla`'s `Init`: no call started, all threads with a clear interrupt status, no `FutureTask`, no live pool thread (except a `wrapOnLimiterPool` caller's outer thread, pinned by `outerWorkers`), the builder's list holding listeners `1..numInitListeners` with `modCount = numInitListeners`. Start recording after `build()` and before the first `call()` or `submit(wrap(...))`; build the Retryer from a fresh builder.

### What trace validation checks

`Trace.cfg` checks `TypeOK`, `StructuralOK`, `InterruptContainment` and `RetryAccounting` on every replayed state, plus `TraceMatched`. The scenario properties (`SequentialAttempts`, `InterruptPreserved`, …) are not checked during replay, because real executions violate them whenever a defect is exercised. Model checking hunts for those violations (`MC_hunt_*.cfg`).
