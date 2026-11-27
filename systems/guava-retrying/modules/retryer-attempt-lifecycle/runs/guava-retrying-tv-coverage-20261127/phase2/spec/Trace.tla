-------------------------------- MODULE Trace --------------------------------
(***************************************************************************)
(* Trace validation for guava-retrying 2.0.0 (Category B, per-thread       *)
(* timebox pattern).                                                       *)
(*                                                                         *)
(* Input: one NDJSON file (instrumentation-spec.md section 1):            *)
(*   - one line {"tag":"config", ...}: the workload's configuration (thread *)
(*     and task identities, limiter, executor, predicate, strategies)      *)
(*   - lines {"tag":"trace","event":<base action>,"tid":<thread>,          *)
(*     "start":n,"end":m, ...fields}: one line per base-spec action        *)
(* Events are grouped per thread; tc[tid] is the per-thread cursor.  A     *)
(* thread may take its next event only if no other thread has a pending   *)
(* event that ended before it started (ViablePIDs).  JPF recordings use    *)
(* the action's commit point for both start and end, which gives a total  *)
(* order; real-JVM recordings may use [start, end] intervals.  l counts    *)
(* consumed events (+1) for the validator's failure report.                *)
(*                                                                         *)
(* Every wrapper calls the base action unchanged and checks the post-state *)
(* fields that instrumentation-spec.md makes mandatory for that event.     *)
(***************************************************************************)

EXTENDS base, Json, IOUtils, Sequences, FiniteSets, TLC

\* ==========================================================================
\* Trace loading
\* ==========================================================================

JsonFile ==
    IF "JSON" \in DOMAIN IOEnv THEN IOEnv.JSON
    ELSE "../traces/trace.ndjson"

RawLines == ndJsonDeserialize(JsonFile)

IsTagged(x, t) == "tag" \in DOMAIN x /\ x.tag = t

ConfigLines == TLCEval(SelectSeq(RawLines, LAMBDA x : IsTagged(x, "config")))
ASSUME Len(ConfigLines) = 1
Cfg == ConfigLines[1]

TraceLog == TLCEval(SelectSeq(RawLines, LAMBDA x : IsTagged(x, "trace")))
ASSUME Len(TraceLog) > 0

SetOf(s) == {s[i] : i \in 1..Len(s)}

\* --------------------------------------------------------------------------
\* Constant overrides (Trace.cfg: `Const <- TraceConst`)
\* --------------------------------------------------------------------------

TraceCallers           == SetOf(Cfg.callers)
TraceWorkers           == SetOf(Cfg.workers)
TraceTaskIds           == SetOf(Cfg.tasks)
TraceNumInitListeners  == Cfg.numInitListeners
TraceNumExtraListeners == Cfg.numExtraListeners
TraceLimiter           == Cfg.limiter
TraceExecKind          == Cfg.execKind
TracePoolSize          == Cfg.poolSize
TraceQueueCap          == Cfg.queueCap
TraceRetryOn           == SetOf(Cfg.retryOn)
TraceStopKind          == Cfg.stopKind
TraceStopAfter         == Cfg.stopAfter
TraceSleepClasses      == SetOf(Cfg.sleepClasses)
TraceModes             == SetOf(Cfg.modes)
TraceWrapCallers       == SetOf(Cfg.wrapCallers)
TraceWrapOnLimiterPool == SetOf(Cfg.wrapOnLimiterPool)

\* ==========================================================================
\* Per-thread cursors and the timebox partial order
\* ==========================================================================

TraceThreads == TLCEval({TraceLog[k].tid : k \in 1..Len(TraceLog)})

traces == TLCEval([tid \in TraceThreads |->
                     SelectSeq(TraceLog, LAMBDA x : x.tid = tid)])

VARIABLES
    tc,   \* tc[tid]: index of thread tid's next event in traces[tid]
    l     \* 1 + number of consumed events

traceVars == <<tc, l>>

ThreadsWithEvents == {tid \in TraceThreads : tc[tid] <= Len(traces[tid])}

NextEv(tid) == traces[tid][tc[tid]]

ViablePIDs ==
    {tid \in ThreadsWithEvents :
        ~ \E tid2 \in ThreadsWithEvents :
            /\ tid2 # tid
            /\ NextEv(tid2).end < NextEv(tid).start}

\* ==========================================================================
\* Post-state validation (fields per instrumentation-spec.md section 2)
\* ==========================================================================

\* Every caller event: the loop counter and the caller's interrupt status
\* after the step.
CallerPost(tid, e) ==
    /\ attemptNo'[tid] = e.attemptNo
    /\ intr'[tid] = e.intr

\* Events that build the Attempt (Retryer.java:161/163): its classification
\* and whether stopAfterDelay's limit had passed when it was built.
ClassPost(tid, e) ==
    /\ curTag'[tid] = e.attemptKind
    /\ curExpired'[tid] = e.expired

\* Every worker event: the worker's interrupt status after the step.
WorkerPost(tid, e) ==
    intr'[tid] = e.intr

RunnerOf(e) == IF e.runner = "none" THEN NoWorker ELSE e.runner

\* ==========================================================================
\* Caller event wrappers (Retryer.call)
\* ==========================================================================

TCallStart(tid, e) ==
    /\ e.event = "CallStart" /\ tid \in Callers
    /\ CallStart(tid)
    /\ CallerPost(tid, e)

TCallerBodyStart(tid, e) ==
    /\ e.event = "CallerBodyStart" /\ tid \in Callers
    /\ CallerBodyStart(tid, e.mode)
    /\ CallerPost(tid, e)

TCallerBodyReturns(tid, e) ==
    /\ e.event = "CallerBodyReturns" /\ tid \in Callers
    /\ CallerBodyReturns(tid)
    /\ CallerPost(tid, e)
    /\ ClassPost(tid, e)

TCallerBodyThrows(tid, e) ==
    /\ e.event = "CallerBodyThrows" /\ tid \in Callers
    /\ CallerBodyThrows(tid)
    /\ CallerPost(tid, e)
    /\ ClassPost(tid, e)

TSubmitRejected(tid, e) ==
    /\ e.event = "SubmitRejected" /\ tid \in Callers
    /\ SubmitRejected(tid)
    /\ CallerPost(tid, e)
    /\ ClassPost(tid, e)

\* `worker` is the thread that receives the task; "unknown" only when the
\* recording ends before that thread touches the task.
TSubmitHandoff(tid, e) ==
    /\ e.event = "SubmitHandoff" /\ tid \in Callers
    /\ IF e.worker = "unknown"
       THEN \E w \in Workers : SubmitHandoff(tid, e.task, w)
       ELSE SubmitHandoff(tid, e.task, e.worker)
    /\ CallerPost(tid, e)
    /\ curTask'[tid] = e.task
    /\ tstate'[e.task] = "NEW"

TSubmitNewWorker(tid, e) ==
    /\ e.event = "SubmitNewWorker" /\ tid \in Callers
    /\ IF e.worker = "unknown"
       THEN \E w \in Workers : SubmitNewWorker(tid, e.task, w)
       ELSE SubmitNewWorker(tid, e.task, e.worker)
    /\ CallerPost(tid, e)
    /\ curTask'[tid] = e.task
    /\ tstate'[e.task] = "NEW"

TSubmitQueued(tid, e) ==
    /\ e.event = "SubmitQueued" /\ tid \in Callers
    /\ SubmitQueued(tid, e.task)
    /\ CallerPost(tid, e)
    /\ curTask'[tid] = e.task
    /\ Len(queue') = e.queueLen

TGetReturn(tid, e) ==
    /\ e.event = "GetReturn" /\ tid \in Callers
    /\ curTask[tid] = e.task
    /\ tstate[e.task] = e.state
    /\ GetReturn(tid)
    /\ CallerPost(tid, e)
    /\ ClassPost(tid, e)

TGetInterrupted(tid, e) ==
    /\ e.event = "GetInterrupted" /\ tid \in Callers
    /\ curTask[tid] = e.task
    /\ tstate[e.task] = e.state
    /\ GetInterrupted(tid)
    /\ CallerPost(tid, e)

TGetTimeout(tid, e) ==
    /\ e.event = "GetTimeout" /\ tid \in Callers
    /\ curTask[tid] = e.task
    /\ tstate[e.task] = e.state
    /\ GetTimeout(tid)
    /\ CallerPost(tid, e)

TCancelCASWon(tid, e) ==
    /\ e.event = "CancelCASWon" /\ tid \in Callers
    /\ curTask[tid] = e.task
    /\ CancelCASWon(tid)
    /\ CallerPost(tid, e)
    /\ tstate'[e.task] = e.state

TCancelCASLost(tid, e) ==
    /\ e.event = "CancelCASLost" /\ tid \in Callers
    /\ curTask[tid] = e.task
    /\ tstate[e.task] = e.state
    /\ CancelCASLost(tid)
    /\ CallerPost(tid, e)
    /\ ClassPost(tid, e)

TCancelReadRunner(tid, e) ==
    /\ e.event = "CancelReadRunner" /\ tid \in Callers
    /\ curTask[tid] = e.task
    /\ CancelReadRunner(tid)
    /\ CallerPost(tid, e)
    /\ cancelR'[tid] = RunnerOf(e)

TCancelDoInterrupt(tid, e) ==
    /\ e.event = "CancelDoInterrupt" /\ tid \in Callers
    /\ curTask[tid] = e.task
    /\ cancelR[tid] = e.target
    /\ CancelDoInterrupt(tid)
    /\ CallerPost(tid, e)
    /\ intr'[e.target] = TRUE

TCancelFinish(tid, e) ==
    /\ e.event = "CancelFinish" /\ tid \in Callers
    /\ curTask[tid] = e.task
    /\ CancelFinish(tid)
    /\ CallerPost(tid, e)
    /\ ClassPost(tid, e)
    /\ tstate'[e.task] = e.state

TListenersBegin(tid, e) ==
    /\ e.event = "ListenersBegin" /\ tid \in Callers
    /\ ListenersBegin(tid)
    /\ CallerPost(tid, e)
    /\ itExpMod'[tid] = e.modCount
    /\ Len(blist) = e.size

TListenerNotify(tid, e) ==
    /\ e.event = "ListenerNotify" /\ tid \in Callers
    /\ ListenerNotify(tid)
    /\ CallerPost(tid, e)
    /\ notified'[tid][Len(notified'[tid])] = e.listener
    /\ itCursor'[tid] = e.cursor

TListenerCME(tid, e) ==
    /\ e.event = "ListenerCME" /\ tid \in Callers
    /\ bmod = e.modCount
    /\ itExpMod[tid] = e.expectedModCount
    /\ ListenerCME(tid)
    /\ CallerPost(tid, e)

TListenersEnd(tid, e) ==
    /\ e.event = "ListenersEnd" /\ tid \in Callers
    /\ itCursor[tid] = e.cursor
    /\ Len(blist) = e.size
    /\ ListenersEnd(tid)
    /\ CallerPost(tid, e)

TPredicateAccepts(tid, e) ==
    /\ e.event = "PredicateAccepts" /\ tid \in Callers
    /\ PredicateAccepts(tid)
    /\ CallerPost(tid, e)
    /\ outcome'[tid] = e.outcome

TStopStrategyStops(tid, e) ==
    /\ e.event = "StopStrategyStops" /\ tid \in Callers
    /\ StopStrategyStops(tid)
    /\ CallerPost(tid, e)
    /\ exitInfo'[tid].count = e.count

TWaitStrategyComputes(tid, e) ==
    /\ e.event = "WaitStrategyComputes" /\ tid \in Callers
    /\ WaitStrategyComputes(tid, e.sleep)
    /\ CallerPost(tid, e)

TBlockNegative(tid, e) ==
    /\ e.event = "BlockNegative" /\ tid \in Callers
    /\ BlockNegative(tid)
    /\ CallerPost(tid, e)

TBlockInterrupted(tid, e) ==
    /\ e.event = "BlockInterrupted" /\ tid \in Callers
    /\ BlockInterrupted(tid)
    /\ CallerPost(tid, e)
    /\ exitInfo'[tid].count = e.count

TBlockZero(tid, e) ==
    /\ e.event = "BlockZero" /\ tid \in Callers
    /\ BlockZero(tid)
    /\ CallerPost(tid, e)

TBlockSleepStart(tid, e) ==
    /\ e.event = "BlockSleepStart" /\ tid \in Callers
    /\ BlockSleepStart(tid)
    /\ CallerPost(tid, e)

TSleepReturns(tid, e) ==
    /\ e.event = "SleepReturns" /\ tid \in Callers
    /\ SleepReturns(tid)
    /\ CallerPost(tid, e)

TSleepInterrupted(tid, e) ==
    /\ e.event = "SleepInterrupted" /\ tid \in Callers
    /\ SleepInterrupted(tid)
    /\ CallerPost(tid, e)
    /\ exitInfo'[tid].count = e.count

\* ==========================================================================
\* Worker event wrappers (ThreadPoolExecutor.runWorker / FutureTask.run)
\* ==========================================================================

TWorkerPollBlock(tid, e) ==
    /\ e.event = "WorkerPollBlock" /\ tid \in Workers
    /\ WorkerPollBlock(tid)
    /\ WorkerPost(tid, e)

TWorkerTake(tid, e) ==
    /\ e.event = "WorkerTake" /\ tid \in Workers
    /\ WorkerTake(tid)
    /\ wtask'[tid] = e.task
    /\ WorkerPost(tid, e)

TWorkerRunTaskSkip(tid, e) ==
    /\ e.event = "WorkerRunTaskSkip" /\ tid \in Workers
    /\ wtask[tid] = e.task
    /\ tstate[e.task] = e.state
    /\ WorkerRunTaskSkip(tid)
    /\ WorkerPost(tid, e)

TWorkerRunTaskStart(tid, e) ==
    /\ e.event = "WorkerRunTaskStart" /\ tid \in Workers
    /\ wtask[tid] = e.task
    /\ tstate[e.task] = e.state
    /\ WorkerRunTaskStart(tid)
    /\ WorkerPost(tid, e)

TWorkerRunnerCAS(tid, e) ==
    /\ e.event = "WorkerRunnerCAS" /\ tid \in Workers
    /\ wtask[tid] = e.task
    /\ WorkerRunnerCAS(tid)
    /\ WorkerPost(tid, e)

TBodyStart(tid, e) ==
    /\ e.event = "BodyStart" /\ tid \in Workers
    /\ wtask[tid] = e.task
    /\ BodyStart(tid, e.mode)
    /\ WorkerPost(tid, e)

TBodySkip(tid, e) ==
    /\ e.event = "BodySkip" /\ tid \in Workers
    /\ wtask[tid] = e.task
    /\ tstate[e.task] = e.state
    /\ BodySkip(tid)
    /\ WorkerPost(tid, e)

TBodyReturns(tid, e) ==
    /\ e.event = "BodyReturns" /\ tid \in Workers
    /\ wtask[tid] = e.task
    /\ BodyReturns(tid)
    /\ tres'[e.task] = e.result
    /\ WorkerPost(tid, e)

TBodyThrows(tid, e) ==
    /\ e.event = "BodyThrows" /\ tid \in Workers
    /\ wtask[tid] = e.task
    /\ BodyThrows(tid)
    /\ tres'[e.task] = e.result
    /\ WorkerPost(tid, e)

TSetCASWon(tid, e) ==
    /\ e.event = "SetCASWon" /\ tid \in Workers
    /\ wtask[tid] = e.task
    /\ SetCASWon(tid)
    /\ tstate'[e.task] = e.state
    /\ WorkerPost(tid, e)

TSetCASLost(tid, e) ==
    /\ e.event = "SetCASLost" /\ tid \in Workers
    /\ wtask[tid] = e.task
    /\ tstate[e.task] = e.state
    /\ SetCASLost(tid)
    /\ WorkerPost(tid, e)

TSetFinish(tid, e) ==
    /\ e.event = "SetFinish" /\ tid \in Workers
    /\ wtask[tid] = e.task
    /\ SetFinish(tid)
    /\ tstate'[e.task] = e.state
    /\ WorkerPost(tid, e)

TRunFinallySpin(tid, e) ==
    /\ e.event = "RunFinallySpin" /\ tid \in Workers
    /\ wtask[tid] = e.task
    /\ tstate[e.task] = e.state
    /\ RunFinallySpin(tid)
    /\ WorkerPost(tid, e)

TRunFinallyExit(tid, e) ==
    /\ e.event = "RunFinallyExit" /\ tid \in Workers
    /\ wtask[tid] = e.task
    /\ tstate[e.task] = e.state
    /\ RunFinallyExit(tid)
    /\ WorkerPost(tid, e)

TSpinExit(tid, e) ==
    /\ e.event = "SpinExit" /\ tid \in Workers
    /\ wtask[tid] = e.task
    /\ tstate[e.task] = e.state
    /\ SpinExit(tid)
    /\ WorkerPost(tid, e)

TWorkerExit(tid, e) ==
    /\ e.event = "WorkerExit" /\ tid \in Workers
    /\ WorkerExit(tid)

TOuterWorkerRelease(tid, e) ==
    /\ e.event = "OuterWorkerRelease" /\ tid \in Workers
    /\ wOuter[tid] = e.caller
    /\ OuterWorkerRelease(tid)

\* ==========================================================================
\* Builder and environment event wrappers (any recording thread)
\* ==========================================================================

TInterrupt(tid, e) ==
    /\ e.event = "Interrupt"
    /\ e.target \in Callers
    /\ Interrupt(e.target)

TCancelOuter(tid, e) ==
    /\ e.event = "CancelOuter"
    /\ e.target \in Callers
    /\ CancelOuter(e.target)

TAddListenerBegin(tid, e) ==
    /\ e.event = "AddListenerBegin"
    /\ AddListenerBegin(e.listener)
    /\ bmod' = e.modCount

TAddListenerEnd(tid, e) ==
    /\ e.event = "AddListenerEnd"
    /\ bAdding = e.listener
    /\ AddListenerEnd
    /\ Len(blist') = e.size

TExecutorShutdown(tid, e) ==
    /\ e.event = "ExecutorShutdown"
    /\ ExecutorShutdown

\* ==========================================================================
\* Event dispatch
\* ==========================================================================

MatchEvent(tid, e) ==
    \/ TCallStart(tid, e)
    \/ TCallerBodyStart(tid, e)
    \/ TCallerBodyReturns(tid, e)
    \/ TCallerBodyThrows(tid, e)
    \/ TSubmitRejected(tid, e)
    \/ TSubmitHandoff(tid, e)
    \/ TSubmitNewWorker(tid, e)
    \/ TSubmitQueued(tid, e)
    \/ TGetReturn(tid, e)
    \/ TGetInterrupted(tid, e)
    \/ TGetTimeout(tid, e)
    \/ TCancelCASWon(tid, e)
    \/ TCancelCASLost(tid, e)
    \/ TCancelReadRunner(tid, e)
    \/ TCancelDoInterrupt(tid, e)
    \/ TCancelFinish(tid, e)
    \/ TListenersBegin(tid, e)
    \/ TListenerNotify(tid, e)
    \/ TListenerCME(tid, e)
    \/ TListenersEnd(tid, e)
    \/ TPredicateAccepts(tid, e)
    \/ TStopStrategyStops(tid, e)
    \/ TWaitStrategyComputes(tid, e)
    \/ TBlockNegative(tid, e)
    \/ TBlockInterrupted(tid, e)
    \/ TBlockZero(tid, e)
    \/ TBlockSleepStart(tid, e)
    \/ TSleepReturns(tid, e)
    \/ TSleepInterrupted(tid, e)
    \/ TWorkerPollBlock(tid, e)
    \/ TWorkerTake(tid, e)
    \/ TWorkerRunTaskSkip(tid, e)
    \/ TWorkerRunTaskStart(tid, e)
    \/ TWorkerRunnerCAS(tid, e)
    \/ TBodyStart(tid, e)
    \/ TBodySkip(tid, e)
    \/ TBodyReturns(tid, e)
    \/ TBodyThrows(tid, e)
    \/ TSetCASWon(tid, e)
    \/ TSetCASLost(tid, e)
    \/ TSetFinish(tid, e)
    \/ TRunFinallySpin(tid, e)
    \/ TRunFinallyExit(tid, e)
    \/ TSpinExit(tid, e)
    \/ TWorkerExit(tid, e)
    \/ TOuterWorkerRelease(tid, e)
    \/ TInterrupt(tid, e)
    \/ TCancelOuter(tid, e)
    \/ TAddListenerBegin(tid, e)
    \/ TAddListenerEnd(tid, e)
    \/ TExecutorShutdown(tid, e)

\* ==========================================================================
\* Silent action
\* ==========================================================================

\* Wall-clock time is not an event.  stopAfterDelay's limit passing
\* (DelayElapses) fires only right before the caller's next event builds an
\* Attempt that the recording marks as expired, and only once per caller.
ClassEvents == {"CallerBodyReturns", "CallerBodyThrows", "SubmitRejected",
                "GetReturn", "CancelCASLost", "CancelFinish"}

SilentDelayElapses ==
    \E c \in Callers \cap ThreadsWithEvents :
        /\ NextEv(c).event \in ClassEvents
        /\ NextEv(c).expired = TRUE
        /\ ~elapsedOver[c]
        /\ DelayElapses(c)

\* ==========================================================================
\* Spec
\* ==========================================================================

\* WrapOnLimiterPool: the recording names the pool thread that runs each
\* wrap() RetryerCallable (config field "outerWorkers": {caller: worker}).
TraceInit ==
    /\ Init
    /\ \A c \in WrapOnLimiterPool : wOuter[Cfg.outerWorkers[c]] = c
    /\ tc = [tid \in TraceThreads |-> 1]
    /\ l = 1

TraceNext ==
    \/ /\ ThreadsWithEvents # {}
       /\ \E tid \in ViablePIDs :
            /\ MatchEvent(tid, NextEv(tid))
            /\ tc' = [tc EXCEPT ![tid] = @ + 1]
            /\ l' = l + 1
    \/ /\ ThreadsWithEvents # {}
       /\ SilentDelayElapses
       /\ UNCHANGED traceVars
    \/ /\ ThreadsWithEvents = {}
       /\ UNCHANGED <<vars, traceVars>>

TraceSpec == TraceInit /\ [][TraceNext]_<<vars, traceVars>>
                       /\ WF_<<vars, traceVars>>(TraceNext)

\* The whole recording is consumed (all per-thread cursors at the end).
\* TLC checks this over every behavior, so a recording must leave no choice
\* that can dead-end: totally ordered events (start = end = commit point)
\* and pinned choices (worker, mode, outerWorkers), as instrumentation-spec.md
\* requires.  Then exactly one behavior replays the recording.
TraceMatched == <>(l > Len(TraceLog))

\* Existence check for recordings with overlapping [start, end] intervals,
\* where some interleavings dead-end: run with INVARIANT TraceNotFullyConsumed
\* (and without the PROPERTY); the recording is valid iff TLC reports this
\* invariant violated (some interleaving consumed every event).
TraceNotFullyConsumed == l <= Len(TraceLog)

=============================================================================

