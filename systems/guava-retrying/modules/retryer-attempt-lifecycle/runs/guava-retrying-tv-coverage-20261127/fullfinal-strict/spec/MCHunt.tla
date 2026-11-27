-------------------------------- MODULE MCHunt --------------------------------
(***************************************************************************)
(* Bug-hunting-only refinements of base.tla properties (filtered variants  *)
(* that isolate one mechanism after the general property's counterexample  *)
(* has been analyzed).  Same behavior as MC.tla; only extra invariants.    *)
(***************************************************************************)

EXTENDS MC

\* S5 composition (C3, Retryer.java:151-153): once the thread running call()
\* has been interrupted and call() ends other than by returning a result, it
\* ends with RetryException.  In MC_hunt_s5_decision the callable always
\* throws an IOException that is retried, so the only other exits are the
\* stop strategy and the interrupted sleep (both RetryException) -- and the
\* IllegalArgumentException of a negative sleep, which Thread.sleep raises
\* before it looks at the interrupt status (JDK11 jvm.cpp JVM_Sleep).
InterruptedCallThrowsRetryException ==
    \A c \in Callers :
        (intrDelivered[c] /\ outcome[c] \notin {"None", "Returned"})
            => outcome[c] = "RetryExc"

\* D-3 (S1): a body that ignores interrupts and never returns ("Stuck", e.g.
\* a socket read without SO_TIMEOUT) keeps its pool thread for good.
\* (a) After call() has ended, none of its stuck bodies still holds a thread.
StuckBodiesEndWithCall ==
    \A c \in Callers :
        outcome[c] # "None" =>
            \A t \in TaskIds : ~(towner[t] = c /\ tmode[t] = "Stuck" /\ tbody[t] = "Running")

\* (b) One call pins at most one pool thread with stuck bodies (thread
\* accumulation: each timed-out stuck attempt keeps a thread and the cached
\* pool starts a new one for the next attempt).
StuckBodiesPerCallAtMostOne ==
    \A c \in Callers :
        Cardinality({t \in TaskIds : towner[t] = c /\ tmode[t] = "Stuck"
                                     /\ tbody[t] = "Running"}) <= 1

\* Known #29 (check against 2.0.0): a per-attempt timeout is an ordinary
\* attempt failure, so with a predicate that does not match Guava's
\* UncheckedTimeoutException the first timeout ends call() with
\* ExecutionException (Retryer.java:162-163, 170-171), although the callable
\* threw nothing and the limit is documented per attempt
\* (RetryerBuilder.java:113).
TimeoutDoesNotEndCallWithExecutionException ==
    \A c \in Callers : ~(outcome[c] = "ExecExc" /\ exitInfo[c].tag = "Timeout")

=============================================================================
