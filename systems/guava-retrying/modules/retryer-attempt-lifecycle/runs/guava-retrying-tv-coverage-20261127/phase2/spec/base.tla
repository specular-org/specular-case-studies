-------------------------------- MODULE base --------------------------------
(***************************************************************************)
(* guava-retrying 2.0.0: the attempt lifecycle of Retryer.call under       *)
(* per-attempt time limits, thread interruption and sharing across        *)
(* threads.                                                                *)
(*                                                                         *)
(* Category B (concurrent / runtime).  Thread kinds:                       *)
(*   callers : threads running Retryer.call, either directly or as the     *)
(*             RetryerCallable of wrap() executed by an outer executor     *)
(*   workers : threads of the time limiter's ThreadPoolExecutor, running   *)
(*             FutureTask.run -> the user callable                         *)
(*   builder : the thread holding the RetryerBuilder (AddListenerBegin/End)*)
(*   env     : Thread.interrupt() on a caller, outer cancellation,         *)
(*             executor shutdown, wall-clock time for stopAfterDelay       *)
(*                                                                         *)
(* Target source (src/main/java/com/github/rholder/retry/ at 177b6c9,     *)
(* byte-identical to v2.0.0):                                              *)
(*   Retryer.java, RetryerBuilder.java, AttemptTimeLimiters.java,          *)
(*   StopStrategies.java, BlockStrategies.java, RetryException.java        *)
(* Environment code the model follows (cited with a prefix):               *)
(*   Guava 22.0  SimpleTimeLimiter.java                                    *)
(*   JDK 11      FutureTask.java, ThreadPoolExecutor.java (TPE),           *)
(*               AbstractExecutorService.java (AES), ArrayList.java,       *)
(*               hotspot jvm.cpp (JVM_Sleep)                               *)
(*   JDK 11 is the version JPF runs; JDK 21 FutureTask equivalents:        *)
(*   set 281-287, setException 299-305, run 307-337,                       *)
(*   handlePossibleCancellationInterrupt 381-397, awaitDone 446-500        *)
(*   (cancel 164-182 and get 197-206 are identical).                       *)
(*                                                                         *)
(* Granularity: every action is one shared-memory access of the code (a    *)
(* volatile read/write, CAS, interrupt-status test/set, queue operation,   *)
(* or ArrayList field access) plus the thread-local code around it.  Two   *)
(* accesses are merged into one action only where no other thread's step   *)
(* can observe or change anything between them (argued at each merge).    *)
(* This is the granularity at which JPF interleaves threads, so recorded   *)
(* executions replay step for step (instrumentation-spec.md).              *)
(*                                                                         *)
(* Scenarios (modeling-brief.md section 2):                                *)
(*   S1 time-limited attempts escape the attempt sequence (D-1..D-4)       *)
(*   S2 interrupts consumed inside an attempt are never restored (D-5..7)  *)
(*   S3 listener list aliased between builder and Retryers (D-8, D-9=#48)  *)
(*   S4 attempt-outcome attribution at the limiter boundary (D-10)         *)
(*   S5 post-attempt decision steps (composition of the block step)        *)
(***************************************************************************)

EXTENDS Integers, Sequences, FiniteSets, TLC

\* ==========================================================================
\* Constants
\* ==========================================================================

CONSTANTS
    Callers,            \* threads that call Retryer.call (one call each)
    Workers,            \* thread identities available to the limiter's executor
    TaskIds,            \* FutureTask identities (slots are reused once unreferenced)
    NumInitListeners,   \* listeners added to the builder before build() (ids 1..n)
    NumExtraListeners,  \* listeners the builder may add after build() (S3)
    Limiter,            \* "None"  = AttemptTimeLimiters.noTimeLimit()      (AttemptTimeLimiters.java:43-45)
                        \* "Fixed" = AttemptTimeLimiters.fixedTimeLimit(..) (AttemptTimeLimiters.java:57-60, 69-72)
    ExecKind,           \* executor behind fixedTimeLimit:
                        \*  "Cached"  = Executors.newCachedThreadPool() (2-arg factory,
                        \*              SimpleTimeLimiter.java:81-84; JDK11 Executors.java:217-221)
                        \*  "Fixed"   = newFixedThreadPool(PoolSize), unbounded queue (Executors.java:91-95)
                        \*  "Bounded" = TPE(PoolSize, PoolSize, ArrayBlockingQueue(QueueCap), AbortPolicy)
    PoolSize,           \* core = max pool size for "Fixed" / "Bounded"
    QueueCap,           \* work-queue capacity for "Bounded"
    RetryOn,            \* attempt tags the rejection predicate accepts (=> retry)
    StopKind,           \* "Never" | "AfterAttempt" | "AfterDelay"   (StopStrategies.java)
    StopAfter,          \* stopAfterAttempt(StopAfter)
    SleepClasses,       \* abstract computeSleepTime results offered: "Zero" | "Positive" | "Negative"
    Modes,              \* callable behaviors offered per attempt (see AllModes)
    WrapCallers,        \* callers that run as wrap(callable) tasks of an outer executor
    WrapOnLimiterPool,  \* wrap callers whose outer executor is the limiter's own executor
    NoTask, NoWorker, NoCaller   \* sentinels

\* --------------------------------------------------------------------------
\* Value domains
\* --------------------------------------------------------------------------

\* Callable behaviors (guidance assumption: the callable is arbitrary user code)
\*   Ret       returns a result; never looks at the interrupt status; may run
\*             arbitrarily long
\*   RetBad    returns a result that retryIfResult(..) rejects
\*   Exc       throws an Exception
\*   Err       throws an Error (#67)
\*   IntrRet   one interruptible check: InterruptedException (status cleared)
\*             if its thread is interrupted at the check, otherwise returns
\*   IntrBlock interruptible blocking call that only ends when interrupted
\*   Stuck     uninterruptible call that never returns (e.g. a socket read
\*             without SO_TIMEOUT)
AllModes == {"Ret", "RetBad", "Exc", "Err", "IntrRet", "IntrBlock", "Stuck"}

\* Attempt classification (brief section 1.3).  Retryer.java:159-164 turns
\* every Throwable out of attemptTimeLimiter.call into an ExceptionAttempt, so
\* infrastructure failures (Timeout, CallerIE, Rejected) look like callable
\* failures to predicates, listeners, stop strategies and RetryException.
Tags == {"Result", "BadResult",                      \* ResultAttempt (Retryer.java:161)
         "CallableExc", "CallableErr", "CallableIE",  \* the callable threw
         "Timeout",                                   \* UncheckedTimeoutException (SimpleTimeLimiter.java:164-166)
         "CallerIE",                                  \* InterruptedException from Future.get (SimpleTimeLimiter.java:155-157)
         "Rejected"}                                  \* RejectedExecutionException from submit (SimpleTimeLimiter.java:149)
ResultTags        == {"Result", "BadResult"}
CallableThrowTags == {"CallableExc", "CallableErr", "CallableIE"}
ResultKinds       == {"none", "Result", "BadResult", "CallableExc", "CallableErr", "CallableIE"}

\* JDK11 FutureTask.java:92-99
TaskStates == {"NEW", "COMPLETING", "NORMAL", "EXCEPTIONAL",
               "CANCELLED", "INTERRUPTING", "INTERRUPTED"}

CallerPCs == {"Idle",        \* call() not started
              "Attempt",     \* at Retryer.java:160, about to call attemptTimeLimiter.call
              "CBody",       \* noTimeLimit: the callable runs on the caller thread
              "Wait",        \* fixedTimeLimit: in FutureTask.get(d) / awaitDone
              "CancelTO",    \* timed out, about to future.cancel(true)
              "CancelIE",    \* interrupted in get, about to future.cancel(true)
              "CancelRead",  \* cancel CAS won, about to read runner
              "CancelIntr",  \* runner read non-null, about to interrupt it
              "CancelSet",   \* about to setRelease(INTERRUPTED)
              "Classified",  \* Attempt object built (Retryer.java:161/163)
              "Listeners",   \* iterating the listener list (Retryer.java:166-168)
              "Decide",      \* predicate / stop / wait computation (Retryer.java:170-176)
              "Block",       \* about to call blockStrategy.block(sleepTime) (Retryer.java:178)
              "Sleeping",    \* inside Thread.sleep(positive)
              "Done"}        \* call() returned or threw

WorkerPCs == {"Absent",      \* thread does not exist (never started, or exited)
              "GetTask",     \* cached pool: back in getTask(), not yet polling
              "Idle",        \* in getTask(): cached pool = blocked in SynchronousQueue.poll
                             \* (matchable by offer); queue pools = taking from the queue
              "Assigned",    \* holds a task (firstTask, handoff or queue head), not yet run
              "RunCAS",      \* FutureTask.run saw state NEW, about to CAS runner
              "InRun",       \* runner CAS done, body not yet invoked
              "Body",        \* executing the user callable
              "BodyDone",    \* callable returned/threw, about to set/setException
              "Completing",  \* set CAS won (state COMPLETING), about to publish
              "Finally",     \* run()'s finally: runner nulled, about to re-read state
              "Spin",        \* handlePossibleCancellationInterrupt: waiting out INTERRUPTING
              "Outer"}       \* running a wrap() RetryerCallable (WrapOnLimiterPool)

Outcomes == {"None", "Returned", "ExecExc", "RetryExc", "CME", "IAE"}

Threads == Callers \cup Workers

\* Listener ids are numbers in order of addition to the builder's list.
InitListeners  == [i \in 1..NumInitListeners |-> i]
ExtraListeners == {NumInitListeners + j : j \in 1..NumExtraListeners}
AllListenerIds == 1..(NumInitListeners + NumExtraListeners)

NoExit == [flag |-> FALSE, count |-> 0, tag |-> "none", invoked |-> FALSE]

ASSUME Limiter \in {"None", "Fixed"}
ASSUME ExecKind \in {"Cached", "Fixed", "Bounded"}
ASSUME PoolSize \in Nat \ {0} /\ QueueCap \in Nat
ASSUME RetryOn \subseteq Tags
ASSUME StopKind \in {"Never", "AfterAttempt", "AfterDelay"} /\ StopAfter \in Nat \ {0}
ASSUME SleepClasses \subseteq {"Zero", "Positive", "Negative"} /\ SleepClasses # {}
ASSUME Modes \subseteq AllModes /\ Modes # {}
ASSUME WrapCallers \subseteq Callers /\ WrapOnLimiterPool \subseteq WrapCallers
ASSUME Limiter = "None" => WrapOnLimiterPool = {}
ASSUME Cardinality(WrapOnLimiterPool) <= Cardinality(Workers)
ASSUME ExecKind \in {"Fixed", "Bounded"} => Cardinality(WrapOnLimiterPool) <= PoolSize
ASSUME NumInitListeners \in Nat /\ NumExtraListeners \in Nat
ASSUME Callers \cap Workers = {}
ASSUME NoTask \notin TaskIds /\ NoWorker \notin Workers /\ NoCaller \notin Callers

\* ==========================================================================
\* Variables
\* ==========================================================================

\* --- Caller thread: Retryer.call locals and program counter -------------
VARIABLES
    cpc,          \* program counter (CallerPCs)
    attemptNo,    \* int attemptNumber, the loop counter (Retryer.java:157)
    curTask,      \* the Future of the current time-limited attempt (SimpleTimeLimiter.java:149)
    curTag,       \* classification of the current Attempt (Tags)
    curInvoked,   \* ghost: the current attempt's callable body ever started
    curExpired,   \* delaySinceFirstAttempt >= maxDelay, sampled when the Attempt
                  \* is built (Retryer.java:161/163; StopStrategies.java:123-124)
    curQueued,    \* ghost: the current attempt's task waited in the executor queue,
                  \* or the attempt was rejected (no thread was available)
    cancelR,      \* FutureTask.cancel local `Thread t = runner` (FutureTask.java:171)
    cbody,        \* noTimeLimit: behavior of the callable running on the caller
    itCursor,     \* ArrayList.Itr.cursor (ArrayList.java:984)
    itExpMod,     \* ArrayList.Itr.expectedModCount (ArrayList.java:986)
    sleepCls      \* sleepTime class computed at Retryer.java:176

\* --- Caller ghosts (properties; not implementation state) ---------------
VARIABLES
    made,          \* attempts started by this call (counted independently of attemptNo)
    notified,      \* listener ids notified for the current attempt, in order
    decided,       \* the current attempt reached the rejection predicate (Retryer.java:170)
    outcome,       \* how call() ended (Outcomes)
    exitInfo,      \* [flag, count, tag, invoked] at exit: caller interrupt status,
                   \* RetryException count, last attempt's tag, whether its body ran
    intrDelivered, \* an interrupt was delivered to the thread running call()
    ieAt,          \* attempt (made) during which an InterruptedException was raised
                   \* on the caller thread inside the attempt; 0 = never
    cancelAt,      \* made at the time the outer wrap() future was cancelled; -1 = never
    outerState,    \* wrap(): state of the outer FutureTask ("NA" for direct callers)
    elapsedOver    \* wall-clock time since startTime exceeds stopAfterDelay's limit

\* --- Interrupt status of every thread -----------------------------------
VARIABLES
    intr

\* --- FutureTask instances created by SimpleTimeLimiter (one per attempt) -
VARIABLES
    tstate,   \* FutureTask.state (JDK11 FutureTask.java:92)
    towner,   \* caller whose attempt created the task (NoCaller: slot never used)
    trunner,  \* FutureTask.runner (JDK11 FutureTask.java:106)
    tbody,    \* ghost: "NotStarted" | "Running" | "Done" — the callable body
    tmode,    \* behavior of this attempt's callable
    tres,     \* what the body produced (ResultKinds)
    ttag,     \* ghost: the owner classified this task as "Timeout"/"CallerIE"
    tqueued   \* ghost: the task was placed in the work queue (no thread free)

\* --- Executor worker threads --------------------------------------------
VARIABLES
    wpc,      \* WorkerPCs
    wtask,    \* task held by the worker (TPE.runWorker local `task`)
    wOuter,   \* WrapOnLimiterPool: caller whose RetryerCallable this worker runs
    intrSrc   \* ghost: task whose cancel(true) last interrupted this worker

\* --- Executor ------------------------------------------------------------
VARIABLES
    queue,      \* TPE workQueue (always empty for the cached pool's SynchronousQueue)
    exShutdown  \* runState >= SHUTDOWN (TPE.java:1369-1381)

\* --- RetryerBuilder.listeners: the ArrayList shared with every Retryer ---
VARIABLES
    blist,    \* ArrayList elements 0..size-1 (RetryerBuilder.java:40)
    bmod,     \* ArrayList.modCount
    bAdding   \* builder thread: listener whose ArrayList.add is half done (0: none)

callerLocal == <<cpc, attemptNo, curTask, curTag, curInvoked, curExpired,
                 curQueued, cancelR, cbody, itCursor, itExpMod, sleepCls>>
callerGhost == <<made, notified, decided, outcome, exitInfo, intrDelivered,
                 ieAt, cancelAt, outerState, elapsedOver>>
taskVars    == <<tstate, towner, trunner, tbody, tmode, tres, ttag, tqueued>>
workerVars  == <<wpc, wtask, wOuter, intrSrc>>
execVars    == <<queue, exShutdown>>
listVars    == <<blist, bmod, bAdding>>

vars == <<callerLocal, callerGhost, intr, taskVars, workerVars, execVars, listVars>>

\* ==========================================================================
\* Helpers
\* ==========================================================================

Range(f) == {f[x] : x \in DOMAIN f}

IsPrefix(s, t) == Len(s) <= Len(t) /\ SubSeq(t, 1, Len(s)) = s

\* attemptNumber++ (Retryer.java:157).  An operator so that a liveness model
\* can bound the counter by overriding it; the base spec counts exactly.
NextCount(n) == n + 1

LiveWorkers   == {w \in Workers : wpc[w] # "Absent"}
IdleWorkers   == {w \in Workers : wpc[w] = "Idle"}
AbsentWorkers == {w \in Workers : wpc[w] = "Absent"}

InQueue(t) == \E i \in 1..Len(queue) : queue[i] = t

\* A FutureTask slot can be reused once nothing references it any more: the
\* owner dropped the Future (SimpleTimeLimiter returns or throws), no worker
\* holds it, and it is not in the work queue.  A cancelled task left in a
\* bounded queue keeps its slot (and the queue capacity) until a worker
\* dequeues and discards it.
FreeTasks == {t \in TaskIds :
                /\ \A c \in Callers : curTask[c] # t
                /\ \A w \in Workers : wtask[w] # t
                /\ ~InQueue(t)}

\* Body behavior -> what FutureTask.run / NoAttemptTimeLimit sees
ThrowTag(m) == CASE m = "Exc" -> "CallableExc"
                 [] m = "Err" -> "CallableErr"
                 [] OTHER     -> "CallableIE"

\* Retryer.java:161 / :163 — the Attempt object is built: ResultAttempt(result,
\* attemptNumber, delay) or ExceptionAttempt(t, attemptNumber, delay) wrapping t
\* in a new ExecutionException (:253-257).  delaySinceFirstAttempt is sampled
\* now (TimeUnit.NANOSECONDS.toMillis(nanoTime() - startTime)).  The caller
\* drops its reference to the Future.  Thread-local code: it is merged into
\* the step that produced the attempt's outcome.
SetClassified(c, tag, inv, q) ==
    /\ cpc'        = [cpc        EXCEPT ![c] = "Classified"]
    /\ curTag'     = [curTag     EXCEPT ![c] = tag]
    /\ curInvoked' = [curInvoked EXCEPT ![c] = inv]
    /\ curQueued'  = [curQueued  EXCEPT ![c] = q]
    /\ curExpired' = [curExpired EXCEPT ![c] = elapsedOver[c]]
    /\ curTask'    = [curTask    EXCEPT ![c] = NoTask]
    /\ decided'    = [decided    EXCEPT ![c] = FALSE]

\* call() ends.  For wrap() callers the outer FutureTask.run then calls
\* set/setException, which completes the outer future unless it was
\* cancelled (JDK11 FutureTask.java:228-252).
ExitCall(c, kind, flag) ==
    /\ cpc'        = [cpc        EXCEPT ![c] = "Done"]
    /\ outcome'    = [outcome    EXCEPT ![c] = kind]
    /\ exitInfo'   = [exitInfo   EXCEPT ![c] = [flag    |-> flag,
                                                count   |-> attemptNo[c],
                                                tag     |-> curTag[c],
                                                invoked |-> curInvoked[c]]]
    /\ outerState' = [outerState EXCEPT ![c] = IF @ = "NEW" THEN "DONE" ELSE @]

\* JDK11 AES.java:107-109 newTaskFor -> new FutureTask(callable): state = NEW
\* (FutureTask.java:132-137), runner = null, outcome unset.
AllocTask(t, c, q) ==
    /\ tqueued' = [tqueued EXCEPT ![t] = q]
    /\ tstate'  = [tstate  EXCEPT ![t] = "NEW"]
    /\ towner'  = [towner  EXCEPT ![t] = c]
    /\ trunner' = [trunner EXCEPT ![t] = NoWorker]
    /\ tbody'   = [tbody   EXCEPT ![t] = "NotStarted"]
    /\ tmode'   = [tmode   EXCEPT ![t] = "none"]
    /\ tres'    = [tres    EXCEPT ![t] = "none"]
    /\ ttag'    = [ttag    EXCEPT ![t] = "none"]

\* TPE.runWorker after a task: `task = null` (TPE.java:1135), w.unlock(),
\* then `(task = getTask()) != null` (:1114).  The cached pool's worker must
\* still reach SynchronousQueue.poll before an offer can match it, so it
\* passes through "GetTask"; a queue pool's worker takes from the queue
\* whenever it is non-empty, whichever point of getTask it is at.
NextAfterTask(w) ==
    /\ wpc'   = [wpc   EXCEPT ![w] = IF ExecKind = "Cached" THEN "GetTask" ELSE "Idle"]
    /\ wtask' = [wtask EXCEPT ![w] = NoTask]

\* Stop strategies (StopStrategies.java)
ShouldStop(c) ==
    CASE StopKind = "Never"        -> FALSE                     \* :93-94
      [] StopKind = "AfterAttempt" -> attemptNo[c] >= StopAfter \* :108-109
      [] StopKind = "AfterDelay"   -> curExpired[c]             \* :123-124

\* TPE.execute (JDK11 TPE.java:1318-1356) rejects when not RUNNING (:1347
\* isRunning fails, :1354 addWorker fails) or when a bounded pool is
\* saturated (:1347 offer fails on a full ArrayBlockingQueue, :1354
\* addWorker(command,false) fails since wc >= maximumPoolSize) -> reject
\* (:1355, :824-826) -> AbortPolicy throws RejectedExecutionException
\* (:2052-2056).
SubmitRejects ==
    \/ exShutdown
    \/ /\ ExecKind = "Bounded"
       /\ Cardinality(LiveWorkers) >= PoolSize
       /\ Len(queue) >= QueueCap

\* Initial assignment of wrap() callers to the pool threads running them.
OuterAssignments ==
    {f \in [Workers -> WrapOnLimiterPool \cup {NoCaller}] :
        \A c \in WrapOnLimiterPool : Cardinality({w \in Workers : f[w] = c}) = 1}

\* ==========================================================================
\* Init
\* ==========================================================================

Init ==
    /\ cpc        = [c \in Callers |-> "Idle"]
    /\ attemptNo  = [c \in Callers |-> 0]
    /\ curTask    = [c \in Callers |-> NoTask]
    /\ curTag     = [c \in Callers |-> "none"]
    /\ curInvoked = [c \in Callers |-> FALSE]
    /\ curExpired = [c \in Callers |-> FALSE]
    /\ curQueued  = [c \in Callers |-> FALSE]
    /\ cancelR    = [c \in Callers |-> NoWorker]
    /\ cbody      = [c \in Callers |-> "none"]
    /\ itCursor   = [c \in Callers |-> 0]
    /\ itExpMod   = [c \in Callers |-> 0]
    /\ sleepCls   = [c \in Callers |-> "none"]
    /\ made          = [c \in Callers |-> 0]
    /\ notified      = [c \in Callers |-> <<>>]
    /\ decided       = [c \in Callers |-> FALSE]
    /\ outcome       = [c \in Callers |-> "None"]
    /\ exitInfo      = [c \in Callers |-> NoExit]
    /\ intrDelivered = [c \in Callers |-> FALSE]
    /\ ieAt          = [c \in Callers |-> 0]
    /\ cancelAt      = [c \in Callers |-> -1]
    /\ outerState    = [c \in Callers |-> IF c \in WrapCallers THEN "NEW" ELSE "NA"]
    /\ elapsedOver   = [c \in Callers |-> FALSE]
    /\ intr = [x \in Threads |-> FALSE]
    /\ tstate  = [t \in TaskIds |-> "NEW"]
    /\ towner  = [t \in TaskIds |-> NoCaller]
    /\ trunner = [t \in TaskIds |-> NoWorker]
    /\ tbody   = [t \in TaskIds |-> "NotStarted"]
    /\ tmode   = [t \in TaskIds |-> "none"]
    /\ tres    = [t \in TaskIds |-> "none"]
    /\ ttag    = [t \in TaskIds |-> "none"]
    /\ tqueued = [t \in TaskIds |-> FALSE]
    /\ wOuter \in OuterAssignments
    /\ wpc     = [w \in Workers |-> IF wOuter[w] # NoCaller THEN "Outer" ELSE "Absent"]
    /\ wtask   = [w \in Workers |-> NoTask]
    /\ intrSrc = [w \in Workers |-> NoTask]
    /\ queue = <<>>
    /\ exShutdown = FALSE
    \* RetryerBuilder.java:40 new ArrayList; withRetryListener before build()
    \* (:61-65) adds InitListeners; each ArrayList.add increments modCount
    \* (ArrayList.java:497-499).  build() (:190-197) hands this very list to
    \* the Retryer, which stores it without copying (Retryer.java:137).
    /\ blist   = InitListeners
    /\ bmod    = NumInitListeners
    /\ bAdding = 0

\* ==========================================================================
\* Caller: Retryer.call (Retryer.java:155-185)
\* ==========================================================================

\* Retryer.java:155-157 — call() entry: startTime = nanoTime(); attemptNumber = 1
CallStart(c) ==
    /\ cpc[c] = "Idle"
    \* wrap(): Retryer.java:195-197, 317-319 — RetryerCallable.call runs inside
    \* the outer executor's FutureTask.run, which skips it once the outer
    \* future was cancelled (JDK11 FutureTask.java:255-260).
    /\ c \in WrapCallers => outerState[c] = "NEW"
    /\ cpc'       = [cpc       EXCEPT ![c] = "Attempt"]
    /\ attemptNo' = [attemptNo EXCEPT ![c] = 1]
    \* wrap(): the outer TPE clears the pool thread's interrupt status before
    \* running a task (TPE.java:1120-1124); until the outer run() passes its
    \* state check only the outer cancel could interrupt it, and that cancel
    \* would make the check fail.  A direct caller keeps a pending interrupt.
    /\ intr' = IF c \in WrapCallers THEN [intr EXCEPT ![c] = FALSE] ELSE intr
    /\ UNCHANGED <<curTask, curTag, curInvoked, curExpired, curQueued, cancelR, cbody, itCursor, itExpMod, sleepCls>>
    /\ UNCHANGED callerGhost
    /\ UNCHANGED <<taskVars, workerVars, execVars, listVars>>

\* --------------------------------------------------------------------------
\* noTimeLimit: Retryer.java:160 -> NoAttemptTimeLimit.call
\* (AttemptTimeLimiters.java:77-78) -> callable.call() on the caller thread
\* --------------------------------------------------------------------------

CallerBodyStart(c, m) ==
    /\ cpc[c] = "Attempt"
    /\ Limiter = "None"
    /\ m \in Modes
    /\ cpc'   = [cpc   EXCEPT ![c] = "CBody"]
    /\ cbody' = [cbody EXCEPT ![c] = m]
    /\ made'  = [made  EXCEPT ![c] = NextCount(made[c])]
    /\ UNCHANGED <<attemptNo, curTask, curTag, curInvoked, curExpired, curQueued, cancelR, itCursor, itExpMod, sleepCls>>
    /\ UNCHANGED <<notified, decided, outcome, exitInfo, intrDelivered, ieAt, cancelAt, outerState, elapsedOver>>
    /\ UNCHANGED <<intr, taskVars, workerVars, execVars, listVars>>

\* Retryer.java:160-161 — the callable returned: ResultAttempt.  For IntrRet
\* this is the interruptible check finding the status clear.
CallerBodyReturns(c) ==
    /\ cpc[c] = "CBody"
    /\ \/ cbody[c] \in {"Ret", "RetBad"}
       \/ cbody[c] = "IntrRet" /\ ~intr[c]
    /\ SetClassified(c, IF cbody[c] = "RetBad" THEN "BadResult" ELSE "Result", TRUE, FALSE)
    /\ cbody' = [cbody EXCEPT ![c] = "none"]
    /\ UNCHANGED <<attemptNo, cancelR, itCursor, itExpMod, sleepCls>>
    /\ UNCHANGED <<made, notified, outcome, exitInfo, intrDelivered, ieAt, cancelAt, outerState, elapsedOver>>
    /\ UNCHANGED <<intr, taskVars, workerVars, execVars, listVars>>

\* Retryer.java:162-163 — catch (Throwable t): ExceptionAttempt(t).  An
\* interruptible call inside the callable throws InterruptedException when the
\* caller thread is interrupted and clears its status; Retryer records it as
\* an ordinary failed attempt (D-6).
CallerBodyThrows(c) ==
    /\ cpc[c] = "CBody"
    /\ LET m  == cbody[c]
           ie == m \in {"IntrRet", "IntrBlock"} /\ intr[c]
       IN /\ m \in {"Exc", "Err"} \/ ie
          /\ SetClassified(c, ThrowTag(m), TRUE, FALSE)
          /\ intr' = IF ie THEN [intr EXCEPT ![c] = FALSE] ELSE intr
          /\ ieAt' = IF ie THEN [ieAt EXCEPT ![c] = made[c]] ELSE ieAt
    /\ cbody' = [cbody EXCEPT ![c] = "none"]
    /\ UNCHANGED <<attemptNo, cancelR, itCursor, itExpMod, sleepCls>>
    /\ UNCHANGED <<made, notified, outcome, exitInfo, intrDelivered, cancelAt, outerState, elapsedOver>>
    /\ UNCHANGED <<taskVars, workerVars, execVars, listVars>>

\* --------------------------------------------------------------------------
\* fixedTimeLimit: Retryer.java:160 -> FixedAttemptTimeLimit.call
\* (AttemptTimeLimiters.java:106-107) -> SimpleTimeLimiter.callWithTimeout(
\* callable, d, unit, amInterruptible = true) (SimpleTimeLimiter.java:142-168).
\* The argument checks (:145-147) pass (D-11 is out of model scope).
\* `future = executor.submit(callable)` (:149) -> AES.submit (JDK11
\* AES.java:137-141): newTaskFor (FutureTask NEW) + TPE.execute.  Each submit
\* action is one execute decision, taken at the access that commits it
\* (instrumentation-spec.md); the reads before it do not change the outcome.
\* A shutdown racing an in-flight execute (task queued with a stale ctl, then
\* removed or run) is not modeled: a submit after shutdown is rejected.
\* --------------------------------------------------------------------------

\* Caller side of an accepted submit; the caller then calls future.get(d)
\* (SimpleTimeLimiter.java:154).  The get() entry read (FutureTask.java:201)
\* adds no behavior beyond awaitDone's reads, so it is part of "Wait".
SubmitAccepted(c, t, q) ==
    /\ cpc'     = [cpc     EXCEPT ![c] = "Wait"]
    /\ curTask' = [curTask EXCEPT ![c] = t]
    /\ made'    = [made    EXCEPT ![c] = NextCount(made[c])]
    /\ AllocTask(t, c, q)

\* execute rejects (see SubmitRejects): the RejectedExecutionException leaves
\* submit (SimpleTimeLimiter.java:149) and Retryer.java:162-163 records it as
\* the attempt's Throwable although the callable never ran (D-10).
SubmitRejected(c) ==
    /\ cpc[c] = "Attempt"
    /\ Limiter = "Fixed"
    /\ SubmitRejects
    /\ made' = [made EXCEPT ![c] = NextCount(made[c])]
    /\ SetClassified(c, "Rejected", FALSE, TRUE)
    /\ UNCHANGED <<attemptNo, cancelR, cbody, itCursor, itExpMod, sleepCls>>
    /\ UNCHANGED <<notified, outcome, exitInfo, intrDelivered, ieAt, cancelAt, outerState, elapsedOver>>
    /\ UNCHANGED <<intr, taskVars, workerVars, execVars, listVars>>

\* Cached pool: TPE.java:1342 corePoolSize = 0 is skipped; :1347
\* SynchronousQueue.offer succeeds by handing the task to a worker blocked
\* in poll (getTask :1052-1053), whose poll returns the task.
SubmitHandoff(c, t, w) ==
    /\ cpc[c] = "Attempt"
    /\ Limiter = "Fixed"
    /\ ~SubmitRejects
    /\ ExecKind = "Cached"
    /\ t \in FreeTasks
    /\ w \in IdleWorkers
    /\ SubmitAccepted(c, t, FALSE)
    /\ wpc'   = [wpc   EXCEPT ![w] = "Assigned"]
    /\ wtask' = [wtask EXCEPT ![w] = t]
    /\ UNCHANGED <<attemptNo, curTag, curInvoked, curExpired, curQueued, cancelR, cbody, itCursor, itExpMod, sleepCls>>
    /\ UNCHANGED <<notified, decided, outcome, exitInfo, intrDelivered, ieAt, cancelAt, outerState, elapsedOver>>
    /\ UNCHANGED <<intr, wOuter, intrSrc, execVars, listVars>>

\* A new pool thread is started with the task as firstTask:
\*   cached pool: no worker is polling, so :1347 offer fails and :1354
\*     addWorker(command, false) succeeds (maximumPoolSize = MAX_VALUE);
\*   fixed / bounded pool: workerCount < corePoolSize -> :1342-1344
\*     addWorker(command, true), even if other workers are idle.
SubmitNewWorker(c, t, w) ==
    /\ cpc[c] = "Attempt"
    /\ Limiter = "Fixed"
    /\ ~SubmitRejects
    /\ \/ ExecKind = "Cached" /\ IdleWorkers = {}
       \/ ExecKind \in {"Fixed", "Bounded"} /\ Cardinality(LiveWorkers) < PoolSize
    /\ t \in FreeTasks
    /\ w \in AbsentWorkers
    /\ SubmitAccepted(c, t, FALSE)
    /\ wpc'     = [wpc     EXCEPT ![w] = "Assigned"]
    /\ wtask'   = [wtask   EXCEPT ![w] = t]
    \* a new Thread starts with a clear interrupt status
    /\ intr'    = [intr    EXCEPT ![w] = FALSE]
    /\ intrSrc' = [intrSrc EXCEPT ![w] = NoTask]
    /\ UNCHANGED <<attemptNo, curTag, curInvoked, curExpired, curQueued, cancelR, cbody, itCursor, itExpMod, sleepCls>>
    /\ UNCHANGED <<notified, decided, outcome, exitInfo, intrDelivered, ieAt, cancelAt, outerState, elapsedOver>>
    /\ UNCHANGED <<wOuter, execVars, listVars>>

\* Fixed / bounded pool with corePoolSize threads: :1347 workQueue.offer
\* succeeds (unbounded LinkedBlockingQueue, or room in the ArrayBlockingQueue).
SubmitQueued(c, t) ==
    /\ cpc[c] = "Attempt"
    /\ Limiter = "Fixed"
    /\ ~SubmitRejects
    /\ ExecKind \in {"Fixed", "Bounded"}
    /\ Cardinality(LiveWorkers) >= PoolSize
    /\ t \in FreeTasks
    /\ SubmitAccepted(c, t, TRUE)
    /\ queue' = Append(queue, t)
    /\ UNCHANGED <<attemptNo, curTag, curInvoked, curExpired, curQueued, cancelR, cbody, itCursor, itExpMod, sleepCls>>
    /\ UNCHANGED <<notified, decided, outcome, exitInfo, intrDelivered, ieAt, cancelAt, outerState, elapsedOver>>
    /\ UNCHANGED <<intr, exShutdown, workerVars, listVars>>

\* --------------------------------------------------------------------------
\* future.get(d, unit) (SimpleTimeLimiter.java:154) -> FutureTask.get
\* (JDK11 FutureTask.java:197-206) -> awaitDone (:393-449).  Each iteration
\* reads the state (:406), then, if NEW, tests and clears the interrupt
\* status (:416-419), then parks or, past the deadline, re-reads the state
\* and returns it (:435-439).  The three actions below are the three ways
\* get can end, each taken at the access that decides it.
\*
\* JDK 8 tests the interrupt before reading the state (JDK8 FutureTask.java
\* 402-412) and JDK 9+ the other way round, but the reachable outcomes are
\* the same: a caller can be preempted between the two reads, so on JDK 9+
\* too the interrupt can win against a task that completes in between, and
\* on JDK 8 too a completed task is returned when the interrupt arrives after
\* the test.  Hence no JDK-version constant.
\* --------------------------------------------------------------------------

\* A read finds the task done: report(s) (FutureTask.java:116-123) returns
\* the value (NORMAL) or throws ExecutionException(outcome) (EXCEPTIONAL),
\* which SimpleTimeLimiter.throwCause (:162-163, :251-266) unwraps and
\* rethrows.  The interrupt status is not consumed (it may be set).
GetReturn(c) ==
    LET t == curTask[c] IN
    /\ cpc[c] = "Wait"
    /\ tstate[t] \in {"NORMAL", "EXCEPTIONAL"}
    /\ SetClassified(c, tres[t], TRUE, tqueued[t])
    /\ UNCHANGED <<attemptNo, cancelR, cbody, itCursor, itExpMod, sleepCls>>
    /\ UNCHANGED <<made, notified, outcome, exitInfo, intrDelivered, ieAt, cancelAt, outerState, elapsedOver>>
    /\ UNCHANGED <<intr, taskVars, workerVars, execVars, listVars>>

\* The interrupt test sees the caller's status: Thread.interrupted() clears
\* it, removeWaiter, throw InterruptedException (JDK11 :416-419).  The state
\* read of that iteration found NEW, but the task may have completed since.
\* SimpleTimeLimiter.java:155-157: catch IE -> future.cancel(true); throw e.
\* (D-5: the status stays cleared.)
GetInterrupted(c) ==
    LET t == curTask[c] IN
    /\ cpc[c] = "Wait"
    /\ intr[c]
    /\ intr'   = [intr   EXCEPT ![c] = FALSE]
    /\ cpc'    = [cpc    EXCEPT ![c] = "CancelIE"]
    /\ curTag' = [curTag EXCEPT ![c] = "CallerIE"]
    /\ ttag'   = [ttag   EXCEPT ![t] = "CallerIE"]
    /\ ieAt'   = [ieAt   EXCEPT ![c] = made[c]]
    /\ UNCHANGED <<attemptNo, curTask, curInvoked, curExpired, curQueued, cancelR, cbody, itCursor, itExpMod, sleepCls>>
    /\ UNCHANGED <<made, notified, decided, outcome, exitInfo, intrDelivered, cancelAt, outerState, elapsedOver>>
    /\ UNCHANGED <<tstate, towner, tqueued, trunner, tbody, tmode, tres>>
    /\ UNCHANGED <<workerVars, execVars, listVars>>

\* The deadline passes (nondeterministic: d and the callable's duration are
\* arbitrary).  Decided at the interrupt test of the deadline iteration, which
\* finds the status clear; that iteration's state read found NEW and its final
\* `return state` (JDK11 :438) reads NEW or COMPLETING (the worker may have won
\* its set CAS in between), so get throws TimeoutException (:202-204).
\* SimpleTimeLimiter.java:164-166: catch TimeoutException -> future.cancel(true)
\* -> throw UncheckedTimeoutException.  The decision (this step) and the
\* cancel CAS (next step) are separate: the D-2 window lies between them.
GetTimeout(c) ==
    LET t == curTask[c] IN
    /\ cpc[c] = "Wait"
    /\ ~intr[c]
    /\ tstate[t] \in {"NEW", "COMPLETING"}
    /\ cpc'    = [cpc    EXCEPT ![c] = "CancelTO"]
    /\ curTag' = [curTag EXCEPT ![c] = "Timeout"]
    /\ ttag'   = [ttag   EXCEPT ![t] = "Timeout"]
    /\ UNCHANGED <<attemptNo, curTask, curInvoked, curExpired, curQueued, cancelR, cbody, itCursor, itExpMod, sleepCls>>
    /\ UNCHANGED callerGhost
    /\ UNCHANGED <<intr, tstate, towner, tqueued, trunner, tbody, tmode, tres>>
    /\ UNCHANGED <<workerVars, execVars, listVars>>

\* --------------------------------------------------------------------------
\* future.cancel(true) (JDK11 FutureTask.java:164-182): CAS, read runner,
\* interrupt it, setRelease(INTERRUPTED), finishCompletion — each a separate
\* step because the runner's finally block (null runner, re-read state, spin
\* while INTERRUPTING) can interleave with each of them.
\* --------------------------------------------------------------------------

\* :165-166 — `state == NEW && STATE.compareAndSet(this, NEW, INTERRUPTING)`
CancelCASWon(c) ==
    LET t == curTask[c] IN
    /\ cpc[c] \in {"CancelTO", "CancelIE"}
    /\ tstate[t] = "NEW"
    /\ tstate' = [tstate EXCEPT ![t] = "INTERRUPTING"]
    /\ cpc'    = [cpc    EXCEPT ![c] = "CancelRead"]
    /\ UNCHANGED <<attemptNo, curTask, curTag, curInvoked, curExpired, curQueued, cancelR, cbody, itCursor, itExpMod, sleepCls>>
    /\ UNCHANGED callerGhost
    /\ UNCHANGED <<intr, towner, tqueued, trunner, tbody, tmode, tres, ttag>>
    /\ UNCHANGED <<workerVars, execVars, listVars>>

\* :165-167 — the task already completed: cancel returns false.
\* SimpleTimeLimiter ignores the result (:156, :165) and throws anyway, so
\* Retryer.java:162-163 records a timeout / interrupt although the task
\* reached (or is reaching) NORMAL or EXCEPTIONAL: the result is discarded (D-2).
CancelCASLost(c) ==
    LET t == curTask[c] IN
    /\ cpc[c] \in {"CancelTO", "CancelIE"}
    /\ tstate[t] # "NEW"
    /\ SetClassified(c, curTag[c], tbody[t] # "NotStarted", tqueued[t])
    /\ UNCHANGED <<attemptNo, cancelR, cbody, itCursor, itExpMod, sleepCls>>
    /\ UNCHANGED <<made, notified, outcome, exitInfo, intrDelivered, ieAt, cancelAt, outerState, elapsedOver>>
    /\ UNCHANGED <<intr, taskVars, workerVars, execVars, listVars>>

\* :171 — `Thread t = runner;`
CancelReadRunner(c) ==
    LET t == curTask[c] IN
    /\ cpc[c] = "CancelRead"
    /\ cancelR' = [cancelR EXCEPT ![c] = trunner[t]]
    /\ cpc'     = [cpc     EXCEPT ![c] = IF trunner[t] # NoWorker THEN "CancelIntr" ELSE "CancelSet"]
    /\ UNCHANGED <<attemptNo, curTask, curTag, curInvoked, curExpired, curQueued, cbody, itCursor, itExpMod, sleepCls>>
    /\ UNCHANGED callerGhost
    /\ UNCHANGED <<intr, taskVars, workerVars, execVars, listVars>>

\* :172-173 — `if (t != null) t.interrupt();`  The runner cannot leave run()
\* before INTERRUPTED (it spins, :331-333), so the interrupt lands while it is
\* still in this task's run().  Nothing waits for the body (D-1).
CancelDoInterrupt(c) ==
    LET t == curTask[c]
        r == cancelR[c]
    IN
    /\ cpc[c] = "CancelIntr"
    /\ intr'    = [intr    EXCEPT ![r] = TRUE]
    /\ intrSrc' = [intrSrc EXCEPT ![r] = t]
    /\ cpc'     = [cpc     EXCEPT ![c] = "CancelSet"]
    /\ UNCHANGED <<attemptNo, curTask, curTag, curInvoked, curExpired, curQueued, cancelR, cbody, itCursor, itExpMod, sleepCls>>
    /\ UNCHANGED callerGhost
    /\ UNCHANGED <<taskVars, wpc, wtask, wOuter, execVars, listVars>>

\* :175 `STATE.setRelease(this, INTERRUPTED)`; :179 finishCompletion() (the
\* caller itself was the only waiter; nulling `callable` changes nothing a
\* runner can still do, since the state is no longer NEW).  SimpleTimeLimiter
\* then throws UncheckedTimeoutException / rethrows the InterruptedException
\* and Retryer.java:162-163 records it as the attempt's Throwable.
CancelFinish(c) ==
    LET t == curTask[c] IN
    /\ cpc[c] = "CancelSet"
    /\ tstate'  = [tstate  EXCEPT ![t] = "INTERRUPTED"]
    /\ cancelR' = [cancelR EXCEPT ![c] = NoWorker]
    /\ SetClassified(c, curTag[c], tbody[t] # "NotStarted", tqueued[t])
    /\ UNCHANGED <<attemptNo, cbody, itCursor, itExpMod, sleepCls>>
    /\ UNCHANGED <<made, notified, outcome, exitInfo, intrDelivered, ieAt, cancelAt, outerState, elapsedOver>>
    /\ UNCHANGED <<intr, towner, tqueued, trunner, tbody, tmode, tres, ttag>>
    /\ UNCHANGED <<workerVars, execVars, listVars>>

\* --------------------------------------------------------------------------
\* Listener notification: Retryer.java:166-168
\*   for (RetryListener listener : listeners) listener.onRetry(attempt);
\* `listeners` is the builder's own ArrayList (RetryerBuilder.java:196 ->
\* Retryer.java:137).  The loop runs outside the attempt's try/catch.
\* JDK11 ArrayList.Itr (ArrayList.java:983-1045): iterator() captures
\* expectedModCount = modCount (:986); hasNext() = cursor != size (:991-993);
\* next() calls checkForComodification() first (:996-997, :1041-1044), then
\* re-checks the size and reads elementData[cursor] (:998-1004).
\* hasNext and next form one step decided at next()'s modCount read: size
\* and modCount only grow, so hasNext's earlier answer still holds there.
\* A false hasNext is its own step (ListenersEnd) decided at the size read.
\* --------------------------------------------------------------------------

ListenersBegin(c) ==
    /\ cpc[c] = "Classified"
    /\ cpc'      = [cpc      EXCEPT ![c] = "Listeners"]
    /\ itCursor' = [itCursor EXCEPT ![c] = 0]
    /\ itExpMod' = [itExpMod EXCEPT ![c] = bmod]
    /\ notified' = [notified EXCEPT ![c] = <<>>]
    /\ UNCHANGED <<attemptNo, curTask, curTag, curInvoked, curExpired, curQueued, cancelR, cbody, sleepCls>>
    /\ UNCHANGED <<made, decided, outcome, exitInfo, intrDelivered, ieAt, cancelAt, outerState, elapsedOver>>
    /\ UNCHANGED <<intr, taskVars, workerVars, execVars, listVars>>

\* checkForComodification passes, next() returns elementData[cursor];
\* Retryer.java:167 listener.onRetry(attempt).
ListenerNotify(c) ==
    /\ cpc[c] = "Listeners"
    /\ itCursor[c] # Len(blist)
    /\ bmod = itExpMod[c]
    /\ notified' = [notified EXCEPT ![c] = Append(@, blist[itCursor[c] + 1])]
    /\ itCursor' = [itCursor EXCEPT ![c] = @ + 1]
    /\ UNCHANGED <<cpc, attemptNo, curTask, curTag, curInvoked, curExpired, curQueued, cancelR, cbody, itExpMod, sleepCls>>
    /\ UNCHANGED <<made, decided, outcome, exitInfo, intrDelivered, ieAt, cancelAt, outerState, elapsedOver>>
    /\ UNCHANGED <<intr, taskVars, workerVars, execVars, listVars>>

\* modCount != expectedModCount: next() throws ConcurrentModificationException
\* (:1041-1044).  Nothing in Retryer.call catches it: call() ends after the
\* attempt ran, skipping the predicate and the stop strategy (D-8).
ListenerCME(c) ==
    /\ cpc[c] = "Listeners"
    /\ itCursor[c] # Len(blist)
    /\ bmod # itExpMod[c]
    /\ ExitCall(c, "CME", intr[c])
    /\ UNCHANGED <<attemptNo, curTask, curTag, curInvoked, curExpired, curQueued, cancelR, cbody, itCursor, itExpMod, sleepCls>>
    /\ UNCHANGED <<made, notified, decided, intrDelivered, ieAt, cancelAt, elapsedOver>>
    /\ UNCHANGED <<intr, taskVars, workerVars, execVars, listVars>>

\* hasNext() false (cursor == size): the loop ends.
ListenersEnd(c) ==
    /\ cpc[c] = "Listeners"
    /\ itCursor[c] = Len(blist)
    /\ cpc' = [cpc EXCEPT ![c] = "Decide"]
    /\ UNCHANGED <<attemptNo, curTask, curTag, curInvoked, curExpired, curQueued, cancelR, cbody, itCursor, itExpMod, sleepCls>>
    /\ UNCHANGED callerGhost
    /\ UNCHANGED <<intr, taskVars, workerVars, execVars, listVars>>

\* --------------------------------------------------------------------------
\* Decision steps: Retryer.java:170-176.  They do not touch shared state, so
\* an interrupt arriving during any of them is equivalent to one arriving just
\* before the block step; the three paths are separate actions.
\* --------------------------------------------------------------------------

\* :170 !rejectionPredicate.apply(attempt) -> :171 return attempt.get():
\* ResultAttempt.get returns the result (:212-214); ExceptionAttempt.get throws
\* the ExecutionException built in its constructor (:254, :260-262).
PredicateAccepts(c) ==
    /\ cpc[c] = "Decide"
    /\ curTag[c] \notin RetryOn
    /\ decided' = [decided EXCEPT ![c] = TRUE]
    /\ ExitCall(c, IF curTag[c] \in ResultTags THEN "Returned" ELSE "ExecExc", intr[c])
    /\ UNCHANGED <<attemptNo, curTask, curTag, curInvoked, curExpired, curQueued, cancelR, cbody, itCursor, itExpMod, sleepCls>>
    /\ UNCHANGED <<made, notified, intrDelivered, ieAt, cancelAt, elapsedOver>>
    /\ UNCHANGED <<intr, taskVars, workerVars, execVars, listVars>>

\* :173-174 stopStrategy.shouldStop(attempt) -> throw new RetryException(
\* attemptNumber, attempt): count = attemptNumber, cause = the attempt's
\* exception or null (RetryException.java:44-45, 57-58).
StopStrategyStops(c) ==
    /\ cpc[c] = "Decide"
    /\ curTag[c] \in RetryOn
    /\ ShouldStop(c)
    /\ decided' = [decided EXCEPT ![c] = TRUE]
    /\ ExitCall(c, "RetryExc", intr[c])
    /\ UNCHANGED <<attemptNo, curTask, curTag, curInvoked, curExpired, curQueued, cancelR, cbody, itCursor, itExpMod, sleepCls>>
    /\ UNCHANGED <<made, notified, intrDelivered, ieAt, cancelAt, elapsedOver>>
    /\ UNCHANGED <<intr, taskVars, workerVars, execVars, listVars>>

\* :176 sleepTime = waitStrategy.computeSleepTime(attempt).  The value is
\* abstracted to a class; "Negative" stands for the unvalidated results of
\* join / exceptionWait (D-16, D-17), offered only to check how the block
\* step composes with interrupts.
WaitStrategyComputes(c, s) ==
    /\ cpc[c] = "Decide"
    /\ curTag[c] \in RetryOn
    /\ ~ShouldStop(c)
    /\ s \in SleepClasses
    /\ decided'  = [decided  EXCEPT ![c] = TRUE]
    /\ sleepCls' = [sleepCls EXCEPT ![c] = s]
    /\ cpc'      = [cpc      EXCEPT ![c] = "Block"]
    /\ UNCHANGED <<attemptNo, curTask, curTag, curInvoked, curExpired, curQueued, cancelR, cbody, itCursor, itExpMod>>
    /\ UNCHANGED <<made, notified, outcome, exitInfo, intrDelivered, ieAt, cancelAt, outerState, elapsedOver>>
    /\ UNCHANGED <<intr, taskVars, workerVars, execVars, listVars>>

\* --------------------------------------------------------------------------
\* Block: Retryer.java:177-182 -> ThreadSleepStrategy.block
\* (BlockStrategies.java:45-46) -> Thread.sleep(sleepTime) -> JVM_Sleep
\* (JDK11 jvm.cpp:3094-3134): negative -> IllegalArgumentException
\* (:3097-3099); interrupted -> clear, InterruptedException (:3101-3103);
\* 0 -> yield (:3112-3113); otherwise an interruptible sleep (:3114-3131).
\* This is the only place Retryer restores the interrupt status (:180).
\* --------------------------------------------------------------------------

\* IAE is checked before the interrupt; only InterruptedException is caught
\* (:179), so the IAE escapes call() (D-16/D-17 composition).
BlockNegative(c) ==
    /\ cpc[c] = "Block"
    /\ sleepCls[c] = "Negative"
    /\ ExitCall(c, "IAE", intr[c])
    /\ UNCHANGED <<attemptNo, curTask, curTag, curInvoked, curExpired, curQueued, cancelR, cbody, itCursor, itExpMod, sleepCls>>
    /\ UNCHANGED <<made, notified, decided, intrDelivered, ieAt, cancelAt, elapsedOver>>
    /\ UNCHANGED <<intr, taskVars, workerVars, execVars, listVars>>

\* Interrupt pending at sleep entry: sleep clears the status and throws IE;
\* :179-181 Thread.currentThread().interrupt(); throw new RetryException(
\* attemptNumber, attempt).  Net effect on the status: still set.
BlockInterrupted(c) ==
    /\ cpc[c] = "Block"
    /\ sleepCls[c] \in {"Zero", "Positive"}
    /\ intr[c]
    /\ ExitCall(c, "RetryExc", TRUE)
    /\ UNCHANGED <<attemptNo, curTask, curTag, curInvoked, curExpired, curQueued, cancelR, cbody, itCursor, itExpMod, sleepCls>>
    /\ UNCHANGED <<made, notified, decided, intrDelivered, ieAt, cancelAt, elapsedOver>>
    /\ UNCHANGED <<intr, taskVars, workerVars, execVars, listVars>>

\* sleep(0) yields and returns; Retryer.java:157 attemptNumber++; next attempt.
BlockZero(c) ==
    /\ cpc[c] = "Block"
    /\ sleepCls[c] = "Zero"
    /\ ~intr[c]
    /\ attemptNo' = [attemptNo EXCEPT ![c] = NextCount(attemptNo[c])]
    /\ cpc'       = [cpc       EXCEPT ![c] = "Attempt"]
    /\ UNCHANGED <<curTask, curTag, curInvoked, curExpired, curQueued, cancelR, cbody, itCursor, itExpMod, sleepCls>>
    /\ UNCHANGED callerGhost
    /\ UNCHANGED <<intr, taskVars, workerVars, execVars, listVars>>

\* sleep(positive) starts (os::sleep, interruptible)
BlockSleepStart(c) ==
    /\ cpc[c] = "Block"
    /\ sleepCls[c] = "Positive"
    /\ ~intr[c]
    /\ cpc' = [cpc EXCEPT ![c] = "Sleeping"]
    /\ UNCHANGED <<attemptNo, curTask, curTag, curInvoked, curExpired, curQueued, cancelR, cbody, itCursor, itExpMod, sleepCls>>
    /\ UNCHANGED callerGhost
    /\ UNCHANGED <<intr, taskVars, workerVars, execVars, listVars>>

\* the sleep elapses; :157 attemptNumber++; next attempt
SleepReturns(c) ==
    /\ cpc[c] = "Sleeping"
    /\ attemptNo' = [attemptNo EXCEPT ![c] = NextCount(attemptNo[c])]
    /\ cpc'       = [cpc       EXCEPT ![c] = "Attempt"]
    /\ UNCHANGED <<curTask, curTag, curInvoked, curExpired, curQueued, cancelR, cbody, itCursor, itExpMod, sleepCls>>
    /\ UNCHANGED callerGhost
    /\ UNCHANGED <<intr, taskVars, workerVars, execVars, listVars>>

\* interrupted while sleeping: os::sleep returns OS_INTRPT with the status
\* cleared (jvm.cpp:3117-3128); :179-181 restore it and throw RetryException.
SleepInterrupted(c) ==
    /\ cpc[c] = "Sleeping"
    /\ intr[c]
    /\ ExitCall(c, "RetryExc", TRUE)
    /\ UNCHANGED <<attemptNo, curTask, curTag, curInvoked, curExpired, curQueued, cancelR, cbody, itCursor, itExpMod, sleepCls>>
    /\ UNCHANGED <<made, notified, decided, intrDelivered, ieAt, cancelAt, elapsedOver>>
    /\ UNCHANGED <<intr, taskVars, workerVars, execVars, listVars>>

\* ==========================================================================
\* Worker: TPE.runWorker (JDK11 TPE.java:1107-1144) -> getTask (:1026-1062)
\* -> FutureTask.run (JDK11 FutureTask.java:254-284) -> the user callable
\* ==========================================================================

\* Cached pool: the worker reaches SynchronousQueue.poll(keepAlive) (getTask
\* :1052-1053) and becomes matchable by an offer.
WorkerPollBlock(w) ==
    /\ wpc[w] = "GetTask"
    /\ ~exShutdown
    /\ wpc' = [wpc EXCEPT ![w] = "Idle"]
    /\ UNCHANGED <<callerLocal, callerGhost, intr, taskVars, wtask, wOuter, intrSrc, execVars, listVars>>

\* Queue pools: take()/poll() returns the queue head (getTask :1052-1056).
WorkerTake(w) ==
    /\ wpc[w] = "Idle"
    /\ queue # <<>>
    /\ wpc'   = [wpc   EXCEPT ![w] = "Assigned"]
    /\ wtask' = [wtask EXCEPT ![w] = Head(queue)]
    /\ queue' = Tail(queue)
    /\ UNCHANGED <<callerLocal, callerGhost, intr, taskVars, wOuter, intrSrc, exShutdown, listVars>>

\* runWorker :1115-1124 — w.lock(); not STOP: `Thread.interrupted()` clears a
\* stale (cancellation) interrupt before the task runs; no interrupt can reach
\* the worker between this clear and the runner CAS (cancel only interrupts a
\* published runner).  FutureTask.run :255 — `state != NEW` -> return: a task
\* cancelled while queued or before its worker reached run() never runs its
\* body (D-4, D-5).
WorkerRunTaskSkip(w) ==
    LET t == wtask[w] IN
    /\ wpc[w] = "Assigned"
    /\ tstate[t] # "NEW"
    /\ intr'    = [intr    EXCEPT ![w] = FALSE]
    /\ intrSrc' = [intrSrc EXCEPT ![w] = NoTask]
    /\ NextAfterTask(w)
    /\ UNCHANGED <<callerLocal, callerGhost, taskVars, wOuter, execVars, listVars>>

\* runWorker :1120-1124 clear; FutureTask.run :255 finds state == NEW.
WorkerRunTaskStart(w) ==
    LET t == wtask[w] IN
    /\ wpc[w] = "Assigned"
    /\ tstate[t] = "NEW"
    /\ intr'    = [intr    EXCEPT ![w] = FALSE]
    /\ intrSrc' = [intrSrc EXCEPT ![w] = NoTask]
    /\ wpc'     = [wpc     EXCEPT ![w] = "RunCAS"]
    /\ UNCHANGED <<callerLocal, callerGhost, taskVars, wtask, wOuter, execVars, listVars>>

\* run :256 — RUNNER.compareAndSet(this, null, currentThread) (no other
\* thread runs this task, so it succeeds; a cancel may already have won its
\* CAS, then the body check below fails).
WorkerRunnerCAS(w) ==
    LET t == wtask[w] IN
    /\ wpc[w] = "RunCAS"
    /\ trunner' = [trunner EXCEPT ![t] = w]
    /\ wpc'     = [wpc     EXCEPT ![w] = "InRun"]
    /\ UNCHANGED <<callerLocal, callerGhost, intr, tstate, towner, tqueued, tbody, tmode, tres, ttag>>
    /\ UNCHANGED <<wtask, wOuter, intrSrc, execVars, listVars>>

\* run :259-264 — `c = callable; if (c != null && state == NEW)` ->
\* `result = c.call()`: the body starts.  The behavior is chosen here.
BodyStart(w, m) ==
    LET t == wtask[w] IN
    /\ wpc[w] = "InRun"
    /\ tstate[t] = "NEW"
    /\ m \in Modes
    /\ tbody' = [tbody EXCEPT ![t] = "Running"]
    /\ tmode' = [tmode EXCEPT ![t] = m]
    /\ wpc'   = [wpc   EXCEPT ![w] = "Body"]
    /\ UNCHANGED <<callerLocal, callerGhost, intr, tstate, towner, tqueued, trunner, tres, ttag>>
    /\ UNCHANGED <<wtask, wOuter, intrSrc, execVars, listVars>>

\* run :260 — cancelled after the runner CAS: the body is skipped; finally
\* `runner = null` (:277).  The state check is merged into the runner write:
\* the state stays non-NEW, and nothing else of this worker is visible.
BodySkip(w) ==
    LET t == wtask[w] IN
    /\ wpc[w] = "InRun"
    /\ tstate[t] # "NEW"
    /\ trunner' = [trunner EXCEPT ![t] = NoWorker]
    /\ wpc'     = [wpc     EXCEPT ![w] = "Finally"]
    /\ UNCHANGED <<callerLocal, callerGhost, intr, tstate, towner, tqueued, tbody, tmode, tres, ttag>>
    /\ UNCHANGED <<wtask, wOuter, intrSrc, execVars, listVars>>

\* run :264-265 — `result = c.call(); ran = true`.  For IntrRet this is its
\* interruptible check finding the status clear.
BodyReturns(w) ==
    LET t == wtask[w]
        m == tmode[t]
    IN
    /\ wpc[w] = "Body"
    /\ \/ m \in {"Ret", "RetBad"}
       \/ m = "IntrRet" /\ ~intr[w]
    /\ tbody' = [tbody EXCEPT ![t] = "Done"]
    /\ tres'  = [tres  EXCEPT ![t] = IF m = "RetBad" THEN "BadResult" ELSE "Result"]
    /\ wpc'   = [wpc   EXCEPT ![w] = "BodyDone"]
    /\ UNCHANGED <<callerLocal, callerGhost, intr, tstate, towner, tqueued, trunner, tmode, ttag>>
    /\ UNCHANGED <<wtask, wOuter, intrSrc, execVars, listVars>>

\* run :266-269 — `catch (Throwable ex) { result = null; ran = false;
\* setException(ex); }`.  An interruptible callable whose worker was
\* interrupted by cancel(true) throws InterruptedException, clearing the
\* worker's status.
BodyThrows(w) ==
    LET t  == wtask[w]
        m  == tmode[t]
        ie == m \in {"IntrRet", "IntrBlock"} /\ intr[w]
    IN
    /\ wpc[w] = "Body"
    /\ m \in {"Exc", "Err"} \/ ie
    /\ tbody'   = [tbody EXCEPT ![t] = "Done"]
    /\ tres'    = [tres  EXCEPT ![t] = ThrowTag(m)]
    /\ wpc'     = [wpc   EXCEPT ![w] = "BodyDone"]
    /\ intr'    = IF ie THEN [intr    EXCEPT ![w] = FALSE]  ELSE intr
    /\ intrSrc' = IF ie THEN [intrSrc EXCEPT ![w] = NoTask] ELSE intrSrc
    /\ UNCHANGED <<callerLocal, callerGhost, tstate, towner, tqueued, trunner, tmode, ttag>>
    /\ UNCHANGED <<wtask, wOuter, execVars, listVars>>

\* set (:228-234) / setException (:246-252):
\* `if (STATE.compareAndSet(this, NEW, COMPLETING))` succeeds
SetCASWon(w) ==
    LET t == wtask[w] IN
    /\ wpc[w] = "BodyDone"
    /\ tstate[t] = "NEW"
    /\ tstate' = [tstate EXCEPT ![t] = "COMPLETING"]
    /\ wpc'    = [wpc    EXCEPT ![w] = "Completing"]
    /\ UNCHANGED <<callerLocal, callerGhost, intr, towner, tqueued, trunner, tbody, tmode, tres, ttag>>
    /\ UNCHANGED <<wtask, wOuter, intrSrc, execVars, listVars>>

\* The CAS fails because cancel won: the result or exception (even an Error)
\* is dropped silently (D-1, D-2 ii).  Then finally: `runner = null` (:277),
\* merged as in BodySkip.
SetCASLost(w) ==
    LET t == wtask[w] IN
    /\ wpc[w] = "BodyDone"
    /\ tstate[t] # "NEW"
    /\ trunner' = [trunner EXCEPT ![t] = NoWorker]
    /\ wpc'     = [wpc     EXCEPT ![w] = "Finally"]
    /\ UNCHANGED <<callerLocal, callerGhost, intr, tstate, towner, tqueued, tbody, tmode, tres, ttag>>
    /\ UNCHANGED <<wtask, wOuter, intrSrc, execVars, listVars>>

\* set :230-232 `outcome = v; setRelease(NORMAL); finishCompletion()` (or
\* setException :248-250 with EXCEPTIONAL); finishCompletion unparks the
\* waiting caller (:361-384).  Then finally: runner = null, the re-read state
\* is terminal, no spin.  No cancel can act any more (its CAS needs NEW), so
\* the rest of run() is invisible and merged.
SetFinish(w) ==
    LET t == wtask[w] IN
    /\ wpc[w] = "Completing"
    /\ tstate'  = [tstate  EXCEPT ![t] = IF tres[t] \in ResultTags THEN "NORMAL" ELSE "EXCEPTIONAL"]
    /\ trunner' = [trunner EXCEPT ![t] = NoWorker]
    /\ NextAfterTask(w)
    /\ UNCHANGED <<callerLocal, callerGhost, intr, towner, tqueued, tbody, tmode, tres, ttag>>
    /\ UNCHANGED <<wOuter, intrSrc, execVars, listVars>>

\* finally :280-282 — `int s = state; if (s >= INTERRUPTING)
\* handlePossibleCancellationInterrupt(s)`: INTERRUPTING -> spin (:331-333).
RunFinallySpin(w) ==
    /\ wpc[w] = "Finally"
    /\ tstate[wtask[w]] = "INTERRUPTING"
    /\ wpc' = [wpc EXCEPT ![w] = "Spin"]
    /\ UNCHANGED <<callerLocal, callerGhost, intr, taskVars, wtask, wOuter, intrSrc, execVars, listVars>>

\* finally :280-282 — any other state: run() returns (the interrupt is not
\* cleared, :343) and runWorker goes back to getTask.
RunFinallyExit(w) ==
    /\ wpc[w] = "Finally"
    /\ tstate[wtask[w]] # "INTERRUPTING"
    /\ NextAfterTask(w)
    /\ UNCHANGED <<callerLocal, callerGhost, intr, taskVars, wOuter, intrSrc, execVars, listVars>>

\* handlePossibleCancellationInterrupt (:328-344): `while (state ==
\* INTERRUPTING) Thread.yield()` ends; run() returns.
SpinExit(w) ==
    /\ wpc[w] = "Spin"
    /\ tstate[wtask[w]] # "INTERRUPTING"
    /\ NextAfterTask(w)
    /\ UNCHANGED <<callerLocal, callerGhost, intr, taskVars, wOuter, intrSrc, execVars, listVars>>

\* getTask returns null and the thread exits: SHUTDOWN with an empty queue
\* (TPE.java:1033-1037; shutdown() interrupts idle workers, :1375), or the
\* cached pool's keep-alive poll timed out (:1042-1048; 60 s,
\* Executors.java:218-220).  Core threads of fixed pools do not time out.
WorkerExit(w) ==
    /\ queue = <<>>
    /\ \/ wpc[w] \in {"GetTask", "Idle"} /\ exShutdown
       \/ wpc[w] = "Idle" /\ ExecKind = "Cached"
    /\ wpc' = [wpc EXCEPT ![w] = "Absent"]
    /\ UNCHANGED <<callerLocal, callerGhost, intr, taskVars, wtask, wOuter, intrSrc, execVars, listVars>>

\* WrapOnLimiterPool: the pool thread that ran a wrap() RetryerCallable gets
\* it back when call() ended (or at once if the outer future was cancelled
\* before it ran, FutureTask.java:255-260) and returns to getTask.
OuterWorkerRelease(w) ==
    LET c == wOuter[w] IN
    /\ wpc[w] = "Outer"
    /\ \/ cpc[c] = "Done"
       \/ cpc[c] = "Idle" /\ outerState[c] = "CANCELLED"
    /\ wOuter' = [wOuter EXCEPT ![w] = NoCaller]
    /\ NextAfterTask(w)
    /\ UNCHANGED <<callerLocal, callerGhost, intr, taskVars, intrSrc, execVars, listVars>>

\* ==========================================================================
\* Builder thread and environment
\* ==========================================================================

\* Thread.interrupt() on a direct caller by another thread (C3 trigger),
\* possibly before call() starts (a pending interrupt at entry).
Interrupt(c) ==
    /\ c \notin WrapCallers
    /\ cpc[c] # "Done"
    /\ intr'          = [intr          EXCEPT ![c] = TRUE]
    /\ intrDelivered' = [intrDelivered EXCEPT ![c] = TRUE]
    /\ UNCHANGED <<callerLocal, made, notified, decided, outcome, exitInfo, ieAt, cancelAt, outerState, elapsedOver>>
    /\ UNCHANGED <<taskVars, workerVars, execVars, listVars>>

\* wrap(): the outer future is cancelled with cancel(true) (JDK11
\* FutureTask.java:164-182: CAS NEW -> INTERRUPTING, interrupt the runner, the
\* thread running call()), or the outer executor is shutdownNow()'ed
\* (TPE.java:1400-1414 interruptWorkers).  Before the RetryerCallable runs,
\* the cancel only prevents it from ever running.
CancelOuter(c) ==
    /\ c \in WrapCallers
    /\ outerState[c] = "NEW"
    /\ outerState' = [outerState EXCEPT ![c] = "CANCELLED"]
    /\ cancelAt'   = [cancelAt   EXCEPT ![c] = made[c]]
    /\ IF cpc[c] # "Idle"
       THEN /\ intr'          = [intr          EXCEPT ![c] = TRUE]
            /\ intrDelivered' = [intrDelivered EXCEPT ![c] = TRUE]
       ELSE UNCHANGED <<intr, intrDelivered>>
    /\ UNCHANGED <<callerLocal, made, notified, decided, outcome, exitInfo, ieAt, elapsedOver>>
    /\ UNCHANGED <<taskVars, workerVars, execVars, listVars>>

\* RetryerBuilder.withRetryListener (RetryerBuilder.java:61-65) after build():
\* listeners.add(listener) (:63) on the list every built Retryer iterates.
\* ArrayList.add (JDK11 ArrayList.java:497-500): `modCount++` first ...
AddListenerBegin(l) ==
    /\ bAdding = 0
    /\ l \in ExtraListeners
    /\ l \notin Range(blist)
    /\ bmod'    = bmod + 1
    /\ bAdding' = l
    /\ UNCHANGED <<callerLocal, callerGhost, intr, taskVars, workerVars, execVars, blist>>

\* ... then add(e, elementData, s) (:484-489): `elementData[s] = e; size = s + 1`.
\* The store and the size write are one step: an iterator only reads indexes
\* below the size it saw, so the store is invisible until the size grows.
AddListenerEnd ==
    /\ bAdding # 0
    /\ blist'   = Append(blist, bAdding)
    /\ bAdding' = 0
    /\ UNCHANGED <<callerLocal, callerGhost, intr, taskVars, workerVars, execVars, bmod>>

\* ExecutorService.shutdown() on the executor passed to
\* fixedTimeLimit(d, unit, executor) (AttemptTimeLimiters.java:69-72):
\* TPE.java:1369-1381 advanceRunState(SHUTDOWN); interruptIdleWorkers().
\* Queued tasks still run; new submissions are rejected.
ExecutorShutdown ==
    /\ Limiter = "Fixed"
    /\ ~exShutdown
    /\ exShutdown' = TRUE
    /\ UNCHANGED <<callerLocal, callerGhost, intr, taskVars, workerVars, queue, listVars>>

\* Wall-clock time passes the stopAfterDelay limit (StopStrategies.java:85-88,
\* 122-125).  Sampled into the next Attempt (Retryer.java:161/163).
DelayElapses(c) ==
    /\ StopKind = "AfterDelay"
    /\ ~elapsedOver[c]
    /\ cpc[c] \notin {"Idle", "Done"}
    /\ elapsedOver' = [elapsedOver EXCEPT ![c] = TRUE]
    /\ UNCHANGED <<callerLocal, made, notified, decided, outcome, exitInfo, intrDelivered, ieAt, cancelAt, outerState>>
    /\ UNCHANGED <<intr, taskVars, workerVars, execVars, listVars>>

\* ==========================================================================
\* Next
\* ==========================================================================

CallerNext(c) ==
    \/ CallStart(c)
    \/ \E m \in Modes : CallerBodyStart(c, m)
    \/ CallerBodyReturns(c)
    \/ CallerBodyThrows(c)
    \/ SubmitRejected(c)
    \/ \E t \in TaskIds, w \in Workers : SubmitHandoff(c, t, w)
    \/ \E t \in TaskIds, w \in Workers : SubmitNewWorker(c, t, w)
    \/ \E t \in TaskIds : SubmitQueued(c, t)
    \/ GetReturn(c)
    \/ GetInterrupted(c)
    \/ GetTimeout(c)
    \/ CancelCASWon(c)
    \/ CancelCASLost(c)
    \/ CancelReadRunner(c)
    \/ CancelDoInterrupt(c)
    \/ CancelFinish(c)
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

WorkerNext(w) ==
    \/ WorkerPollBlock(w)
    \/ WorkerTake(w)
    \/ WorkerRunTaskSkip(w)
    \/ WorkerRunTaskStart(w)
    \/ WorkerRunnerCAS(w)
    \/ \E m \in Modes : BodyStart(w, m)
    \/ BodySkip(w)
    \/ BodyReturns(w)
    \/ BodyThrows(w)
    \/ SetCASWon(w)
    \/ SetCASLost(w)
    \/ SetFinish(w)
    \/ RunFinallySpin(w)
    \/ RunFinallyExit(w)
    \/ SpinExit(w)
    \/ WorkerExit(w)
    \/ OuterWorkerRelease(w)

EnvNext ==
    \/ \E c \in Callers : Interrupt(c) \/ CancelOuter(c) \/ DelayElapses(c)
    \/ \E l \in ExtraListeners : AddListenerBegin(l)
    \/ AddListenerEnd
    \/ ExecutorShutdown

Next ==
    \/ \E c \in Callers : CallerNext(c)
    \/ \E w \in Workers : WorkerNext(w)
    \/ EnvNext

Spec == Init /\ [][Next]_vars

\* ==========================================================================
\* Type and structural invariants
\* ==========================================================================

TypeOK ==
    /\ cpc        \in [Callers -> CallerPCs]
    /\ attemptNo  \in [Callers -> Nat]
    /\ curTask    \in [Callers -> TaskIds \cup {NoTask}]
    /\ curTag     \in [Callers -> Tags \cup {"none"}]
    /\ curInvoked \in [Callers -> BOOLEAN]
    /\ curExpired \in [Callers -> BOOLEAN]
    /\ curQueued  \in [Callers -> BOOLEAN]
    /\ cancelR    \in [Callers -> Workers \cup {NoWorker}]
    /\ cbody      \in [Callers -> Modes \cup {"none"}]
    /\ itCursor   \in [Callers -> Nat]
    /\ itExpMod   \in [Callers -> Nat]
    /\ sleepCls   \in [Callers -> SleepClasses \cup {"none"}]
    /\ made       \in [Callers -> Nat]
    /\ \A c \in Callers : notified[c] \in Seq(AllListenerIds)
    /\ decided    \in [Callers -> BOOLEAN]
    /\ outcome    \in [Callers -> Outcomes]
    /\ \A c \in Callers :
          /\ exitInfo[c].flag \in BOOLEAN
          /\ exitInfo[c].count \in Nat
          /\ exitInfo[c].tag \in Tags \cup {"none"}
          /\ exitInfo[c].invoked \in BOOLEAN
    /\ intrDelivered \in [Callers -> BOOLEAN]
    /\ ieAt          \in [Callers -> Nat]
    /\ cancelAt      \in [Callers -> Nat \cup {-1}]
    /\ outerState    \in [Callers -> {"NA", "NEW", "DONE", "CANCELLED"}]
    /\ elapsedOver   \in [Callers -> BOOLEAN]
    /\ intr    \in [Threads -> BOOLEAN]
    /\ tstate  \in [TaskIds -> TaskStates]
    /\ towner  \in [TaskIds -> Callers \cup {NoCaller}]
    /\ trunner \in [TaskIds -> Workers \cup {NoWorker}]
    /\ tbody   \in [TaskIds -> {"NotStarted", "Running", "Done"}]
    /\ tmode   \in [TaskIds -> Modes \cup {"none"}]
    /\ tres    \in [TaskIds -> ResultKinds]
    /\ ttag    \in [TaskIds -> {"none", "Timeout", "CallerIE"}]
    /\ tqueued \in [TaskIds -> BOOLEAN]
    /\ wpc     \in [Workers -> WorkerPCs]
    /\ wtask   \in [Workers -> TaskIds \cup {NoTask}]
    /\ wOuter  \in [Workers -> Callers \cup {NoCaller}]
    /\ intrSrc \in [Workers -> TaskIds \cup {NoTask}]
    /\ queue \in Seq(TaskIds)
    /\ exShutdown \in BOOLEAN
    /\ blist \in Seq(AllListenerIds)
    /\ bmod \in Nat
    /\ bAdding \in {0} \cup ExtraListeners

\* runner is non-null exactly from the runner CAS to the finally block
\* (FutureTask.java:256, 277), on the thread that holds the task.
TaskRunnerConsistent ==
    \A t \in TaskIds :
        trunner[t] # NoWorker =>
            /\ wtask[trunner[t]] = t
            /\ wpc[trunner[t]] \in {"InRun", "Body", "BodyDone", "Completing"}

\* A body is running iff a worker executes it.
BodyRunningConsistent ==
    \A t \in TaskIds :
        tbody[t] = "Running" <=> \E w \in Workers : wtask[w] = t /\ wpc[w] = "Body"

\* A task is held by at most one worker, and a queued task by none.
TaskHolderConsistent ==
    /\ \A w1, w2 \in Workers : (w1 # w2 /\ wtask[w1] # NoTask) => wtask[w1] # wtask[w2]
    /\ \A i, j \in 1..Len(queue) : i # j => queue[i] # queue[j]
    /\ \A i \in 1..Len(queue) :
          /\ \A w \in Workers : wtask[w] # queue[i]
          /\ tbody[queue[i]] = "NotStarted"

WorkerTaskConsistent ==
    \A w \in Workers :
        /\ (wpc[w] \in {"Assigned", "RunCAS", "InRun", "Body", "BodyDone",
                        "Completing", "Finally", "Spin"}) <=> wtask[w] # NoTask
        /\ (wpc[w] = "Outer") <=> wOuter[w] # NoCaller
        /\ wpc[w] = "GetTask" => ExecKind = "Cached"

CallerTaskConsistent ==
    \A c \in Callers :
        /\ (cpc[c] \in {"Wait", "CancelTO", "CancelIE", "CancelRead",
                        "CancelIntr", "CancelSet"}) <=> curTask[c] # NoTask
        /\ curTask[c] # NoTask => towner[curTask[c]] = c
        /\ cpc[c] = "CancelIntr" => cancelR[c] # NoWorker
        /\ cpc[c] \notin {"CancelIntr", "CancelSet"} => cancelR[c] = NoWorker

\* Fixed / bounded pools never exceed corePoolSize = maximumPoolSize threads.
PoolBound ==
    ExecKind \in {"Fixed", "Bounded"} => Cardinality(LiveWorkers) <= PoolSize

StructuralOK ==
    /\ TaskRunnerConsistent
    /\ BodyRunningConsistent
    /\ TaskHolderConsistent
    /\ WorkerTaskConsistent
    /\ CallerTaskConsistent
    /\ PoolBound

\* Model-capacity alarm (not a property of the system): a caller ready to
\* submit always finds a free FutureTask slot and, where the executor would
\* start a thread, an unused thread identity.  If violated, enlarge TaskIds
\* or Workers.
ModelBoundsAdequate ==
    \A c \in Callers :
        (cpc[c] = "Attempt" /\ Limiter = "Fixed" /\ ~SubmitRejects) =>
            /\ FreeTasks # {}
            /\ (ExecKind = "Cached" /\ IdleWorkers = {}) => AbsentWorkers # {}
            /\ (ExecKind \in {"Fixed", "Bounded"} /\ Cardinality(LiveWorkers) < PoolSize)
                  => AbsentWorkers # {}

\* ==========================================================================
\* Safety properties (brief section 5)
\* ==========================================================================

RunningBodies(c) == {t \in TaskIds : towner[t] = c /\ tbody[t] = "Running"}
RunningCount(c)  == Cardinality(RunningBodies(c)) + (IF cpc[c] = "CBody" THEN 1 ELSE 0)

\* C1 (Retryer.java:31-35): attempts form a sequence.  At most one body of a
\* call runs at any time.  (S1; D-1)
SequentialAttempts ==
    \A c \in Callers : RunningCount(c) <= 1

\* Once call() has returned or thrown, no body of that call still runs.
\* (S1; D-1, D-3)
NoActivityAfterOutcome ==
    \A c \in Callers : outcome[c] # "None" => RunningCount(c) = 0

\* C6 (Guava TimeLimiter.java:80-93): a call that finished before the limit is
\* propagated as-is.  No task that reached NORMAL/EXCEPTIONAL is classified as
\* a timeout or interrupt by its owner.  (S1; D-2, and its interrupt variant
\* in D-5)
NoDiscardedCompletion ==
    \A t \in TaskIds :
        ttag[t] \in {"Timeout", "CallerIE"} => tstate[t] \notin {"NORMAL", "EXCEPTIONAL"}

\* Every attempt that is counted (attempt number, listener notification, stop
\* budget, RetryException count) actually invoked the callable.  (S1, S4;
\* D-4, D-10, 0-invocation D-5)
CountedPCs == {"Classified", "Listeners", "Decide", "Block", "Sleeping"}

CountedImpliesInvoked ==
    \A c \in Callers :
        /\ cpc[c] \in CountedPCs => curInvoked[c]
        /\ outcome[c] # "None" => exitInfo[c].invoked

\* Hunt variant of CountedImpliesInvoked.  It excuses exactly one case: a
\* timed-out attempt whose task never waited in the work queue, i.e. the
\* deadline passed before an idle or newly started thread reached the task.
\* That case needs a deadline shorter than thread hand-off/start-up and is
\* the shallowest counterexample of the general invariant in every
\* time-limited model.  Still flagged: rejected attempts (D-10, saturated
\* bounded pools), timeouts of tasks that waited in the queue (D-4), and
\* attempts cancelled before they ran because of a caller interrupt (D-5).
CountedImpliesInvokedNoStartRace ==
    \A c \in Callers :
        (cpc[c] \in CountedPCs /\ ~curInvoked[c]) =>
            (curTag[c] = "Timeout" /\ ~curQueued[c])

\* C3 (Retryer.java:148-150): ExecutionException means the callable threw.
\* (S2, S4; D-5, D-10, and the known #29 / D-14 for "Timeout")
ExecutionExceptionMeansCallableThrew ==
    \A c \in Callers :
        outcome[c] = "ExecExc" =>
            /\ exitInfo[c].tag \in CallableThrowTags
            /\ exitInfo[c].invoked

\* The same, excluding the known #29 classification of timeouts, so a hunt
\* can run past an already-labelled #29 counterexample.
ExecutionExceptionMeansCallableThrewExcept29 ==
    \A c \in Callers :
        (outcome[c] = "ExecExc" /\ exitInfo[c].tag # "Timeout") =>
            /\ exitInfo[c].tag \in CallableThrowTags
            /\ exitInfo[c].invoked

\* C3 (Retryer.java:151-153): if the thread is interrupted, its interrupt
\* status is set when call() ends.  (S2; D-5, D-6)
InterruptPreserved ==
    \A c \in Callers :
        (intrDelivered[c] /\ outcome[c] # "None") => exitInfo[c].flag

\* C4 (Retryer.java:59-61): no retry once the thread was interrupted.  After an
\* InterruptedException was raised on the caller thread inside attempt n, no
\* attempt n+1 starts.  (S2; D-5, D-6, D-7)
NoRetryAfterObservedInterrupt ==
    \A c \in Callers : ieAt[c] # 0 => made[c] <= ieAt[c]

\* After the outer wrap() future was cancelled, no new attempt starts.
\* (S2; D-7)
CancelledWrapperStops ==
    \A c \in Callers : cancelAt[c] >= 0 => made[c] <= cancelAt[c]

\* C3: call() returns, throws ExecutionException or throws RetryException.
\* (S3: D-8; S5 composition: IAE)
DocumentedOutcomesOnly ==
    \A c \in Callers : outcome[c] \in {"None", "Returned", "ExecExc", "RetryExc"}

\* Every classified attempt reaches the rejection predicate before call()
\* ends.  (S3; D-8)
NoLostAttemptOutcome ==
    \A c \in Callers : outcome[c] # "None" => decided[c]

\* C7 / C2: a running call notifies exactly the listeners configured when its
\* Retryer was built, each once per attempt, in order.  (S3; D-9 = known #48:
\* expected violation)
ListenersFixedAtBuild ==
    \A c \in Callers :
        /\ IsPrefix(notified[c], InitListeners)
        /\ (cpc[c] \in {"Decide", "Block", "Sleeping"} \/ (outcome[c] # "None" /\ decided[c]))
              => notified[c] = InitListeners

\* A cancellation interrupt never reaches the body of another task: TPE clears
\* the interrupt before each task (TPE.java:1120-1124) and cancel's interrupt
\* lands before the runner leaves run() (FutureTask.java:331-333).
\* (S1 baseline / regression; MC-8: expected to hold)
InterruptContainment ==
    \A w \in Workers :
        (wpc[w] = "Body" /\ intr[w]) => intrSrc[w] = wtask[w]

\* RetryException reports the attempts made and a real last attempt
\* (RetryException.java:44-45, 57-58; Retryer.java:174, 181);
\* stopAfterAttempt(K) bounds the attempts (StopStrategies.java:108-109).
\* (baseline; MC-9: expected to hold)
RetryAccounting ==
    /\ \A c \in Callers :
          outcome[c] = "RetryExc" =>
              /\ exitInfo[c].count = made[c]
              /\ exitInfo[c].tag \in Tags
    /\ StopKind = "AfterAttempt" => \A c \in Callers : made[c] <= StopAfter

\* ==========================================================================
\* Liveness (brief section 5) — checked against MC!LiveSpec
\* ==========================================================================

\* An interrupt delivered to the thread running call() (directly or by
\* outer cancellation) eventually ends the call.  (S2; D-7, D-5)
InterruptedCallEventuallyExits ==
    \A c \in Callers : intrDelivered[c] ~> (cpc[c] = "Done")

=============================================================================

