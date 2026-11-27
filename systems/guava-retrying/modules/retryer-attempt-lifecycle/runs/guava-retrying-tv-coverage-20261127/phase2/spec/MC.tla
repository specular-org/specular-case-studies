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
(*   AddListener          builder modifications after build()             *)
(* Not bounded (they react to existing state): every Retryer.call step,    *)
(* every FutureTask / ThreadPoolExecutor worker step, DelayElapses (fires  *)
(* at most once per caller by construction).  Attempts per call are       *)
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
    /\ mc = [intr |-> 0, outer |-> 0, timeout |-> 0, shutdown |-> 0,
             idleExit |-> 0, addl |-> 0]

\* --------------------------------------------------------------------------
\* Counter-bounded environment and timer actions
\* --------------------------------------------------------------------------

MCInterrupt(c) ==
    /\ mc.intr < MaxInterrupts
    /\ Interrupt(c)
    /\ mc' = [mc EXCEPT !.intr = @ + 1]

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

MCAddListener(l) ==
    /\ mc.addl < MaxAddListeners
    /\ AddListener(l)
    /\ mc' = [mc EXCEPT !.addl = @ + 1]

MCDelayElapses(c) == DelayElapses(c) /\ UNCHANGED mcVars

\* --------------------------------------------------------------------------
\* Unbounded reactive steps
\* --------------------------------------------------------------------------

\* Every Retryer.call step of caller c (Retryer.java:155-185 and the
\* SimpleTimeLimiter / FutureTask code it calls) except the deadline.
CallerReactive(c) ==
    \/ CallStart(c)
    \/ \E m \in Modes : CallerBodyStart(c, m)
    \/ CallerBodyReturns(c)
    \/ CallerBodyThrows(c)
    \/ SubmitRejected(c)
    \/ \E t \in TaskIds, w \in Workers : SubmitHandoff(c, t, w)
    \/ \E t \in TaskIds, w \in Workers : SubmitNewWorker(c, t, w)
    \/ \E t \in TaskIds : SubmitQueued(c, t)
    \/ GetEnterWait(c)
    \/ GetReturn(c)
    \/ GetInterrupted(c)
    \/ CancelCASWon(c)
    \/ CancelCASLost(c)
    \/ CancelInterrupt(c)
    \/ ListenersBegin(c)
    \/ ListenerNotify(c)
    \/ ListenerCME(c)
    \/ ListenersEnd(c)
    \/ PredicateAccepts(c)
    \/ StopStrategyStops(c)
    \/ \E s \in SleepClasses : WaitStrategyComputes(c, s)
    \/ BlockNegative(c)
    \/ BlockInterrupted(c)
    \/ BlockZero(c)
    \/ BlockSleepStart(c)
    \/ SleepReturns(c)
    \/ SleepInterrupted(c)

MCCallerStep(c) ==
    \/ CallerReactive(c) /\ UNCHANGED mcVars
    \/ MCGetTimeout(c)

\* Every runWorker / FutureTask.run step of worker w except thread exit.
MCWorkerStep(w) ==
    /\ \/ WorkerTake(w)
       \/ WorkerRunTaskSkip(w)
       \/ WorkerRunTaskStart(w)
       \/ \E m \in Modes : BodyStart(w, m)
       \/ BodySkip(w)
       \/ BodyReturns(w)
       \/ BodyThrows(w)
       \/ SetCASWon(w)
       \/ SetCASLost(w)
       \/ SetFinish(w)
       \/ SpinExit(w)
       \/ OuterWorkerRelease(w)
    /\ UNCHANGED mcVars

MCEnv ==
    \/ \E c \in Callers : MCInterrupt(c) \/ MCCancelOuter(c) \/ MCDelayElapses(c)
    \/ \E l \in ExtraListeners : MCAddListener(l)
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
StateConstraint ==
    \A c \in Callers : attemptNo[c] <= MaxAttempts /\ made[c] <= MaxAttempts

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
