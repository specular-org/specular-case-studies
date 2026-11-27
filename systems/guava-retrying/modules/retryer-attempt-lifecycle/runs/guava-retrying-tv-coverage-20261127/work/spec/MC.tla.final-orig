--------------------------------- MODULE MC ---------------------------------
(***************************************************************************)
(* Model-checking wrapper for base.tla (guava-retrying 2.0.0).             *)
(*                                                                         *)
(* Bounded (they introduce nondeterminism):                                *)
(*   Interrupt            Thread.interrupt() on a direct caller            *)
(*   CancelOuter          cancel(true) / shutdownNow of a wrap() task      *)
(*   GetTimeout           the per-attempt deadline passing                 *)
(*   ExecutorShutdown     shutdown() of a user-supplied limiter executor   *)
(*   WorkerExit           only the cached pool's keep-alive expiry         *)
(*                        (exits after shutdown are reactive)              *)
(*   AddListenerBegin     builder modifications after build()             *)
(* Not bounded (they react to existing state): every Retryer.call step,    *)
(* every FutureTask / ThreadPoolExecutor worker step, AddListenerEnd (the  *)
(* builder finishing an add it began), and DelayElapses (fires at most     *)
(* once per caller by construction).  Attempts per call are                *)
(* bounded by StateConstraint (neverStop loops forever) or, in liveness    *)
(* models, by saturating the counters (MCNextCount).                       *)
(***************************************************************************)

EXTENDS base, TLC

CONSTANTS
    MaxInterrupts,     \* Interrupt(c) budget
    MaxOuterCancels,   \* CancelOuter(c) budget
    MaxTimeouts,       \* GetTimeout budget
    TimeoutsBounded,   \* FALSE in liveness models: a timed get always times out eventually
    MaxShutdowns,      \* ExecutorShutdown budget (0 or 1)
    MaxIdleExits,      \* cached-pool keep-alive expiries
    MaxAddListeners,   \* builder modifications after build()
    MaxAttempts,       \* StateConstraint: attempts per call
    CountCap           \* MCNextCount saturation (liveness models only)

ASSUME TimeoutsBounded \in BOOLEAN
ASSUME \A n \in {MaxInterrupts, MaxOuterCancels, MaxTimeouts, MaxShutdowns,
                 MaxIdleExits, MaxAddListeners, MaxAttempts, CountCap} : n \in Nat

VARIABLE mc     \* fault / timer counters

mcVars  == <<mc>>
allVars == <<vars, mc>>

MCInit ==
    /\ Init
    /\ mc = [interrupt |-> 0, outer |-> 0, timeout |-> 0, shutdown |-> 0,
             idleExit |-> 0, addl |-> 0]

\* --------------------------------------------------------------------------
\* Counter-bounded environment and timer actions
\* --------------------------------------------------------------------------

MCInterrupt(c) ==
    /\ mc.interrupt < MaxInterrupts
    /\ Interrupt(c)
    /\ mc' = [mc EXCEPT !.interrupt = @ + 1]

MCCancelOuter(c) ==
    /\ mc.outer < MaxOuterCancels
    /\ CancelOuter(c)
    /\ mc' = [mc EXCEPT !.outer = @ + 1]

\* In liveness models the timed get is not bounded: FutureTask.get(d) returns
\* after the deadline (JDK11 FutureTask.java:427-439), so it is a guaranteed
\* step of the caller, not a fault.
MCGetTimeout(c) ==
    /\ TimeoutsBounded => mc.timeout < MaxTimeouts
    /\ GetTimeout(c)
    /\ mc' = IF TimeoutsBounded THEN [mc EXCEPT !.timeout = @ + 1] ELSE mc

MCExecutorShutdown ==
    /\ mc.shutdown < MaxShutdowns
    /\ ExecutorShutdown
    /\ mc' = [mc EXCEPT !.shutdown = @ + 1]

MCWorkerExit(w) ==
    /\ WorkerExit(w)
    /\ IF exShutdown
       THEN mc' = mc
       ELSE /\ mc.idleExit < MaxIdleExits
            /\ mc' = [mc EXCEPT !.idleExit = @ + 1]

MCAddListenerBegin(l) ==
    /\ mc.addl < MaxAddListeners
    /\ AddListenerBegin(l)
    /\ mc' = [mc EXCEPT !.addl = @ + 1]

MCDelayElapses(c) == DelayElapses(c) /\ UNCHANGED mcVars

\* --------------------------------------------------------------------------
\* Unbounded reactive steps
\* --------------------------------------------------------------------------

\* Pass-through wrappers (one per base action, so counterexamples name the
\* exact step).  Every Retryer.call step of a caller (Retryer.java:155-185 and
\* the SimpleTimeLimiter / FutureTask code it calls) except the deadline:
MCCallStart(c)                 == CallStart(c) /\ UNCHANGED mcVars
MCCallerBodyStart(c, m)        == CallerBodyStart(c, m) /\ UNCHANGED mcVars
MCCallerBodyReturns(c)         == CallerBodyReturns(c) /\ UNCHANGED mcVars
MCCallerBodyThrows(c)          == CallerBodyThrows(c) /\ UNCHANGED mcVars
MCSubmitRejected(c)            == SubmitRejected(c) /\ UNCHANGED mcVars
MCSubmitHandoff(c, t, w)       == SubmitHandoff(c, t, w) /\ UNCHANGED mcVars
MCSubmitNewWorker(c, t, w)     == SubmitNewWorker(c, t, w) /\ UNCHANGED mcVars
MCSubmitQueued(c, t)           == SubmitQueued(c, t) /\ UNCHANGED mcVars
MCGetReturn(c)                 == GetReturn(c) /\ UNCHANGED mcVars
MCGetInterrupted(c)            == GetInterrupted(c) /\ UNCHANGED mcVars
MCCancelCASWon(c)              == CancelCASWon(c) /\ UNCHANGED mcVars
MCCancelCASLost(c)             == CancelCASLost(c) /\ UNCHANGED mcVars
MCCancelReadRunner(c)          == CancelReadRunner(c) /\ UNCHANGED mcVars
MCCancelDoInterrupt(c)         == CancelDoInterrupt(c) /\ UNCHANGED mcVars
MCCancelFinish(c)              == CancelFinish(c) /\ UNCHANGED mcVars
MCListenersBegin(c)            == ListenersBegin(c) /\ UNCHANGED mcVars
MCListenerNotify(c)            == ListenerNotify(c) /\ UNCHANGED mcVars
MCListenerCME(c)               == ListenerCME(c) /\ UNCHANGED mcVars
MCListenersEnd(c)              == ListenersEnd(c) /\ UNCHANGED mcVars
MCPredicateAccepts(c)          == PredicateAccepts(c) /\ UNCHANGED mcVars
MCStopStrategyStops(c)         == StopStrategyStops(c) /\ UNCHANGED mcVars
MCWaitStrategyComputes(c, s)   == WaitStrategyComputes(c, s) /\ UNCHANGED mcVars
MCBlockNegative(c)             == BlockNegative(c) /\ UNCHANGED mcVars
MCBlockInterrupted(c)          == BlockInterrupted(c) /\ UNCHANGED mcVars
MCBlockZero(c)                 == BlockZero(c) /\ UNCHANGED mcVars
MCBlockSleepStart(c)           == BlockSleepStart(c) /\ UNCHANGED mcVars
MCSleepReturns(c)              == SleepReturns(c) /\ UNCHANGED mcVars
MCSleepInterrupted(c)          == SleepInterrupted(c) /\ UNCHANGED mcVars

\* Every runWorker / getTask / FutureTask.run step of a worker except exit:
MCWorkerPollBlock(w)           == WorkerPollBlock(w) /\ UNCHANGED mcVars
MCWorkerPollCancel(w)          == WorkerPollCancel(w) /\ UNCHANGED mcVars
MCWorkerTake(w)                == WorkerTake(w) /\ UNCHANGED mcVars
MCWorkerRunTaskSkip(w)         == WorkerRunTaskSkip(w) /\ UNCHANGED mcVars
MCWorkerRunTaskStart(w)        == WorkerRunTaskStart(w) /\ UNCHANGED mcVars
MCWorkerRunnerCAS(w)           == WorkerRunnerCAS(w) /\ UNCHANGED mcVars
MCBodyStart(w, m)              == BodyStart(w, m) /\ UNCHANGED mcVars
MCBodySkip(w)                  == BodySkip(w) /\ UNCHANGED mcVars
MCBodyReturns(w)               == BodyReturns(w) /\ UNCHANGED mcVars
MCBodyThrows(w)                == BodyThrows(w) /\ UNCHANGED mcVars
MCSetCASWon(w)                 == SetCASWon(w) /\ UNCHANGED mcVars
MCSetCASLost(w)                == SetCASLost(w) /\ UNCHANGED mcVars
MCSetFinish(w)                 == SetFinish(w) /\ UNCHANGED mcVars
MCRunFinallySpin(w)            == RunFinallySpin(w) /\ UNCHANGED mcVars
MCRunFinallyExit(w)            == RunFinallyExit(w) /\ UNCHANGED mcVars
MCSpinExit(w)                  == SpinExit(w) /\ UNCHANGED mcVars
MCOuterWorkerRelease(w)        == OuterWorkerRelease(w) /\ UNCHANGED mcVars

\* The builder thread finishing an ArrayList.add it started.
MCAddListenerEnd               == AddListenerEnd /\ UNCHANGED mcVars

\* All non-fault steps of caller c (the fairness unit for LiveSpec).
MCCallerStep(c) ==
    \/ MCCallStart(c)
    \/ \E m \in Modes : MCCallerBodyStart(c, m)
    \/ MCCallerBodyReturns(c)
    \/ MCCallerBodyThrows(c)
    \/ MCSubmitRejected(c)
    \/ \E t \in TaskIds, w \in Workers : MCSubmitHandoff(c, t, w)
    \/ \E t \in TaskIds, w \in Workers : MCSubmitNewWorker(c, t, w)
    \/ \E t \in TaskIds : MCSubmitQueued(c, t)
    \/ MCGetReturn(c)
    \/ MCGetInterrupted(c)
    \/ MCCancelCASWon(c)
    \/ MCCancelCASLost(c)
    \/ MCCancelReadRunner(c)
    \/ MCCancelDoInterrupt(c)
    \/ MCCancelFinish(c)
    \/ MCListenersBegin(c)
    \/ MCListenerNotify(c)
    \/ MCListenerCME(c)
    \/ MCListenersEnd(c)
    \/ MCPredicateAccepts(c)
    \/ MCStopStrategyStops(c)
    \/ \E s \in SleepClasses : MCWaitStrategyComputes(c, s)
    \/ MCBlockNegative(c)
    \/ MCBlockInterrupted(c)
    \/ MCBlockZero(c)
    \/ MCBlockSleepStart(c)
    \/ MCSleepReturns(c)
    \/ MCSleepInterrupted(c)
    \/ MCGetTimeout(c)

\* All non-fault steps of worker w (the fairness unit for LiveSpec).
MCWorkerStep(w) ==
    \/ MCWorkerPollBlock(w)
    \/ MCWorkerPollCancel(w)
    \/ MCWorkerTake(w)
    \/ MCWorkerRunTaskSkip(w)
    \/ MCWorkerRunTaskStart(w)
    \/ MCWorkerRunnerCAS(w)
    \/ \E m \in Modes : MCBodyStart(w, m)
    \/ MCBodySkip(w)
    \/ MCBodyReturns(w)
    \/ MCBodyThrows(w)
    \/ MCSetCASWon(w)
    \/ MCSetCASLost(w)
    \/ MCSetFinish(w)
    \/ MCRunFinallySpin(w)
    \/ MCRunFinallyExit(w)
    \/ MCSpinExit(w)
    \/ MCOuterWorkerRelease(w)

MCEnv ==
    \/ \E c \in Callers : MCInterrupt(c) \/ MCCancelOuter(c) \/ MCDelayElapses(c)
    \/ \E l \in ExtraListeners : MCAddListenerBegin(l)
    \/ MCAddListenerEnd
    \/ MCExecutorShutdown

MCNext ==
    \/ \E c \in Callers : MCCallerStep(c)
    \/ \E w \in Workers : MCWorkerStep(w) \/ MCWorkerExit(w)
    \/ MCEnv

MCSpec == MCInit /\ [][MCNext]_allVars

\* --------------------------------------------------------------------------
\* Finitization, symmetry
\* --------------------------------------------------------------------------

\* neverStop / stopAfterDelay retry without bound: explore at most
\* MaxAttempts attempts per call (states beyond are checked, not expanded).
WithinAttemptBound ==
    \A c \in Callers : attemptNo[c] <= MaxAttempts /\ made[c] <= MaxAttempts

StateConstraint == WithinAttemptBound

\* The model-capacity alarm applies to the explored states only: TLC also
\* checks invariants on the successor states that StateConstraint cuts off.
MCModelBoundsAdequate == WithinAttemptBound => ModelBoundsAdequate

\* Liveness models: `NextCount <- MCNextCount` saturates attemptNumber and the
\* attempt ghost at CountCap so neverStop loops become finite cycles.  Only
\* RetryException counts and stopAfterAttempt read the exact value; liveness
\* cfgs use neverStop and do not check RetryAccounting.
MCNextCount(n) == IF n >= CountCap THEN n ELSE n + 1

\* Thread and FutureTask identities are interchangeable (allocation uses \E,
\* never CHOOSE).
Perms == Permutations(Workers) \cup Permutations(TaskIds)

\* --------------------------------------------------------------------------
\* Liveness: fairness from the implementation's scheduling
\* --------------------------------------------------------------------------

\* Weak fairness per thread on all of its non-fault steps:
\*  - a caller thread keeps executing Retryer.call (Retryer.java:155-185);
\*    its timed get returns at the deadline (JDK11 FutureTask.java:427-439),
\*    and a positive sleep ends (jvm.cpp:3114-3131);
\*  - a pool thread keeps executing runWorker / FutureTask.run
\*    (TPE.java:1107-1144, FutureTask.java:254-284); a callable body that
\*    completes (Ret, RetBad, Exc, Err, IntrRet) or that was interrupted while
\*    interruptible (IntrRet, IntrBlock) eventually ends (brief section 5).
\* No fairness on Interrupt, CancelOuter, AddListener, ExecutorShutdown,
\* DelayElapses or keep-alive exits.
Fairness ==
    /\ \A c \in Callers : WF_allVars(MCCallerStep(c))
    /\ \A w \in Workers : WF_allVars(MCWorkerStep(w))

LiveSpec == MCSpec /\ Fairness

\* Premise check for InterruptedCallEventuallyExits: run the _live cfg with
\* this INVARIANT instead of the PROPERTY; TLC must report it violated.
NoInterruptDeliveredInv == \A c \in Callers : ~intrDelivered[c]

=============================================================================
