---- MODULE MC_TTrace_1795680446 ----
EXTENDS Sequences, TLCExt, MC, Toolbox, Naturals, TLC, MC_TEConstants

_expression ==
    LET MC_TEExpression == INSTANCE MC_TEExpression
    IN MC_TEExpression!expression
----

_trace ==
    LET MC_TETrace == INSTANCE MC_TETrace
    IN MC_TETrace!trace
----

_inv ==
    ~(
        TLCGet("level") = Len(_TETrace)
        /\
        tmode = ((t1 :> "none" @@ t2 :> "none" @@ t3 :> "none" @@ t4 :> "none"))
        /\
        tbody = ((t1 :> "NotStarted" @@ t2 :> "NotStarted" @@ t3 :> "NotStarted" @@ t4 :> "NotStarted"))
        /\
        itCursor = ((c1 :> 0 @@ c2 :> 0))
        /\
        intrDelivered = ((c1 :> FALSE @@ c2 :> FALSE))
        /\
        itExpMod = ((c1 :> 0 @@ c2 :> 0))
        /\
        curInvoked = ((c1 :> FALSE @@ c2 :> FALSE))
        /\
        bmod = (1)
        /\
        decided = ((c1 :> FALSE @@ c2 :> FALSE))
        /\
        ttag = ((t1 :> "none" @@ t2 :> "Timeout" @@ t3 :> "none" @@ t4 :> "none"))
        /\
        intr = ((c1 :> FALSE @@ c2 :> FALSE @@ w1 :> FALSE))
        /\
        cancelR = ((c1 :> NoWorker @@ c2 :> NoWorker))
        /\
        mc = ([interrupt |-> 0, outer |-> 0, timeout |-> 1, shutdown |-> 0, idleExit |-> 0, addl |-> 0])
        /\
        cpc = ((c1 :> "Wait" @@ c2 :> "Classified"))
        /\
        blist = (<<1>>)
        /\
        exitInfo = ((c1 :> [flag |-> FALSE, count |-> 0, tag |-> "none", invoked |-> FALSE] @@ c2 :> [flag |-> FALSE, count |-> 0, tag |-> "none", invoked |-> FALSE]))
        /\
        tres = ((t1 :> "none" @@ t2 :> "none" @@ t3 :> "none" @@ t4 :> "none"))
        /\
        outerState = ((c1 :> "NA" @@ c2 :> "NA"))
        /\
        trunner = ((t1 :> NoWorker @@ t2 :> NoWorker @@ t3 :> NoWorker @@ t4 :> NoWorker))
        /\
        outcome = ((c1 :> "None" @@ c2 :> "None"))
        /\
        ieAt = ((c1 :> 0 @@ c2 :> 0))
        /\
        bAdding = (0)
        /\
        tstate = ((t1 :> "NEW" @@ t2 :> "INTERRUPTED" @@ t3 :> "NEW" @@ t4 :> "NEW"))
        /\
        tqueued = ((t1 :> FALSE @@ t2 :> TRUE @@ t3 :> FALSE @@ t4 :> FALSE))
        /\
        wOuter = ((w1 :> NoCaller))
        /\
        cbody = ((c1 :> "none" @@ c2 :> "none"))
        /\
        elapsedOver = ((c1 :> FALSE @@ c2 :> FALSE))
        /\
        cancelAt = ((c1 :> -1 @@ c2 :> -1))
        /\
        made = ((c1 :> 1 @@ c2 :> 1))
        /\
        notified = ((c1 :> <<>> @@ c2 :> <<>>))
        /\
        curExpired = ((c1 :> FALSE @@ c2 :> FALSE))
        /\
        wpc = ((w1 :> "Assigned"))
        /\
        curQueued = ((c1 :> FALSE @@ c2 :> TRUE))
        /\
        curTag = ((c1 :> "none" @@ c2 :> "Timeout"))
        /\
        sleepCls = ((c1 :> "none" @@ c2 :> "none"))
        /\
        attemptNo = ((c1 :> 1 @@ c2 :> 1))
        /\
        exShutdown = (FALSE)
        /\
        towner = ((t1 :> c1 @@ t2 :> c2 @@ t3 :> NoCaller @@ t4 :> NoCaller))
        /\
        intrSrc = ((w1 :> NoTask))
        /\
        curTask = ((c1 :> t1 @@ c2 :> NoTask))
        /\
        queue = (<<t2>>)
        /\
        wtask = ((w1 :> t1))
    )
----

_init ==
    /\ curTag = _TETrace[1].curTag
    /\ wOuter = _TETrace[1].wOuter
    /\ tstate = _TETrace[1].tstate
    /\ trunner = _TETrace[1].trunner
    /\ curQueued = _TETrace[1].curQueued
    /\ wtask = _TETrace[1].wtask
    /\ cancelR = _TETrace[1].cancelR
    /\ tqueued = _TETrace[1].tqueued
    /\ attemptNo = _TETrace[1].attemptNo
    /\ cancelAt = _TETrace[1].cancelAt
    /\ outcome = _TETrace[1].outcome
    /\ made = _TETrace[1].made
    /\ itCursor = _TETrace[1].itCursor
    /\ intrSrc = _TETrace[1].intrSrc
    /\ curInvoked = _TETrace[1].curInvoked
    /\ cbody = _TETrace[1].cbody
    /\ mc = _TETrace[1].mc
    /\ exShutdown = _TETrace[1].exShutdown
    /\ intrDelivered = _TETrace[1].intrDelivered
    /\ notified = _TETrace[1].notified
    /\ itExpMod = _TETrace[1].itExpMod
    /\ bmod = _TETrace[1].bmod
    /\ queue = _TETrace[1].queue
    /\ tres = _TETrace[1].tres
    /\ ieAt = _TETrace[1].ieAt
    /\ cpc = _TETrace[1].cpc
    /\ tbody = _TETrace[1].tbody
    /\ bAdding = _TETrace[1].bAdding
    /\ outerState = _TETrace[1].outerState
    /\ wpc = _TETrace[1].wpc
    /\ exitInfo = _TETrace[1].exitInfo
    /\ elapsedOver = _TETrace[1].elapsedOver
    /\ sleepCls = _TETrace[1].sleepCls
    /\ decided = _TETrace[1].decided
    /\ curTask = _TETrace[1].curTask
    /\ tmode = _TETrace[1].tmode
    /\ curExpired = _TETrace[1].curExpired
    /\ ttag = _TETrace[1].ttag
    /\ blist = _TETrace[1].blist
    /\ intr = _TETrace[1].intr
    /\ towner = _TETrace[1].towner
----

_next ==
    /\ \E i,j \in DOMAIN _TETrace:
        /\ \/ /\ j = i + 1
              /\ i = TLCGet("level")
        /\ curTag  = _TETrace[i].curTag
        /\ curTag' = _TETrace[j].curTag
        /\ wOuter  = _TETrace[i].wOuter
        /\ wOuter' = _TETrace[j].wOuter
        /\ tstate  = _TETrace[i].tstate
        /\ tstate' = _TETrace[j].tstate
        /\ trunner  = _TETrace[i].trunner
        /\ trunner' = _TETrace[j].trunner
        /\ curQueued  = _TETrace[i].curQueued
        /\ curQueued' = _TETrace[j].curQueued
        /\ wtask  = _TETrace[i].wtask
        /\ wtask' = _TETrace[j].wtask
        /\ cancelR  = _TETrace[i].cancelR
        /\ cancelR' = _TETrace[j].cancelR
        /\ tqueued  = _TETrace[i].tqueued
        /\ tqueued' = _TETrace[j].tqueued
        /\ attemptNo  = _TETrace[i].attemptNo
        /\ attemptNo' = _TETrace[j].attemptNo
        /\ cancelAt  = _TETrace[i].cancelAt
        /\ cancelAt' = _TETrace[j].cancelAt
        /\ outcome  = _TETrace[i].outcome
        /\ outcome' = _TETrace[j].outcome
        /\ made  = _TETrace[i].made
        /\ made' = _TETrace[j].made
        /\ itCursor  = _TETrace[i].itCursor
        /\ itCursor' = _TETrace[j].itCursor
        /\ intrSrc  = _TETrace[i].intrSrc
        /\ intrSrc' = _TETrace[j].intrSrc
        /\ curInvoked  = _TETrace[i].curInvoked
        /\ curInvoked' = _TETrace[j].curInvoked
        /\ cbody  = _TETrace[i].cbody
        /\ cbody' = _TETrace[j].cbody
        /\ mc  = _TETrace[i].mc
        /\ mc' = _TETrace[j].mc
        /\ exShutdown  = _TETrace[i].exShutdown
        /\ exShutdown' = _TETrace[j].exShutdown
        /\ intrDelivered  = _TETrace[i].intrDelivered
        /\ intrDelivered' = _TETrace[j].intrDelivered
        /\ notified  = _TETrace[i].notified
        /\ notified' = _TETrace[j].notified
        /\ itExpMod  = _TETrace[i].itExpMod
        /\ itExpMod' = _TETrace[j].itExpMod
        /\ bmod  = _TETrace[i].bmod
        /\ bmod' = _TETrace[j].bmod
        /\ queue  = _TETrace[i].queue
        /\ queue' = _TETrace[j].queue
        /\ tres  = _TETrace[i].tres
        /\ tres' = _TETrace[j].tres
        /\ ieAt  = _TETrace[i].ieAt
        /\ ieAt' = _TETrace[j].ieAt
        /\ cpc  = _TETrace[i].cpc
        /\ cpc' = _TETrace[j].cpc
        /\ tbody  = _TETrace[i].tbody
        /\ tbody' = _TETrace[j].tbody
        /\ bAdding  = _TETrace[i].bAdding
        /\ bAdding' = _TETrace[j].bAdding
        /\ outerState  = _TETrace[i].outerState
        /\ outerState' = _TETrace[j].outerState
        /\ wpc  = _TETrace[i].wpc
        /\ wpc' = _TETrace[j].wpc
        /\ exitInfo  = _TETrace[i].exitInfo
        /\ exitInfo' = _TETrace[j].exitInfo
        /\ elapsedOver  = _TETrace[i].elapsedOver
        /\ elapsedOver' = _TETrace[j].elapsedOver
        /\ sleepCls  = _TETrace[i].sleepCls
        /\ sleepCls' = _TETrace[j].sleepCls
        /\ decided  = _TETrace[i].decided
        /\ decided' = _TETrace[j].decided
        /\ curTask  = _TETrace[i].curTask
        /\ curTask' = _TETrace[j].curTask
        /\ tmode  = _TETrace[i].tmode
        /\ tmode' = _TETrace[j].tmode
        /\ curExpired  = _TETrace[i].curExpired
        /\ curExpired' = _TETrace[j].curExpired
        /\ ttag  = _TETrace[i].ttag
        /\ ttag' = _TETrace[j].ttag
        /\ blist  = _TETrace[i].blist
        /\ blist' = _TETrace[j].blist
        /\ intr  = _TETrace[i].intr
        /\ intr' = _TETrace[j].intr
        /\ towner  = _TETrace[i].towner
        /\ towner' = _TETrace[j].towner

\* Uncomment the ASSUME below to write the states of the error trace
\* to the given file in Json format. Note that you can pass any tuple
\* to `JsonSerialize`. For example, a sub-sequence of _TETrace.
    \* ASSUME
    \*     LET J == INSTANCE Json
    \*         IN J!JsonSerialize("MC_TTrace_1795680446.json", _TETrace)

=============================================================================

 Note that you can extract this module `MC_TEExpression`
  to a dedicated file to reuse `expression` (the module in the 
  dedicated `MC_TEExpression.tla` file takes precedence 
  over the module `MC_TEExpression` below).

---- MODULE MC_TEExpression ----
EXTENDS Sequences, TLCExt, MC, Toolbox, Naturals, TLC, MC_TEConstants

expression == 
    [
        \* To hide variables of the `MC` spec from the error trace,
        \* remove the variables below.  The trace will be written in the order
        \* of the fields of this record.
        curTag |-> curTag
        ,wOuter |-> wOuter
        ,tstate |-> tstate
        ,trunner |-> trunner
        ,curQueued |-> curQueued
        ,wtask |-> wtask
        ,cancelR |-> cancelR
        ,tqueued |-> tqueued
        ,attemptNo |-> attemptNo
        ,cancelAt |-> cancelAt
        ,outcome |-> outcome
        ,made |-> made
        ,itCursor |-> itCursor
        ,intrSrc |-> intrSrc
        ,curInvoked |-> curInvoked
        ,cbody |-> cbody
        ,mc |-> mc
        ,exShutdown |-> exShutdown
        ,intrDelivered |-> intrDelivered
        ,notified |-> notified
        ,itExpMod |-> itExpMod
        ,bmod |-> bmod
        ,queue |-> queue
        ,tres |-> tres
        ,ieAt |-> ieAt
        ,cpc |-> cpc
        ,tbody |-> tbody
        ,bAdding |-> bAdding
        ,outerState |-> outerState
        ,wpc |-> wpc
        ,exitInfo |-> exitInfo
        ,elapsedOver |-> elapsedOver
        ,sleepCls |-> sleepCls
        ,decided |-> decided
        ,curTask |-> curTask
        ,tmode |-> tmode
        ,curExpired |-> curExpired
        ,ttag |-> ttag
        ,blist |-> blist
        ,intr |-> intr
        ,towner |-> towner
        
        \* Put additional constant-, state-, and action-level expressions here:
        \* ,_stateNumber |-> _TEPosition
        \* ,_curTagUnchanged |-> curTag = curTag'
        
        \* Format the `curTag` variable as Json value.
        \* ,_curTagJson |->
        \*     LET J == INSTANCE Json
        \*     IN J!ToJson(curTag)
        
        \* Lastly, you may build expressions over arbitrary sets of states by
        \* leveraging the _TETrace operator.  For example, this is how to
        \* count the number of times a spec variable changed up to the current
        \* state in the trace.
        \* ,_curTagModCount |->
        \*     LET F[s \in DOMAIN _TETrace] ==
        \*         IF s = 1 THEN 0
        \*         ELSE IF _TETrace[s].curTag # _TETrace[s-1].curTag
        \*             THEN 1 + F[s-1] ELSE F[s-1]
        \*     IN F[_TEPosition - 1]
    ]

=============================================================================



Parsing and semantic processing can take forever if the trace below is long.
 In this case, it is advised to uncomment the module below to deserialize the
 trace from a generated binary file.

\*
\*---- MODULE MC_TETrace ----
\*EXTENDS IOUtils, MC, TLC, MC_TEConstants
\*
\*trace == IODeserialize("MC_TTrace_1795680446.bin", TRUE)
\*
\*=============================================================================
\*

---- MODULE MC_TETrace ----
EXTENDS MC, TLC, MC_TEConstants

trace == 
    <<
    ([tmode |-> (t1 :> "none" @@ t2 :> "none" @@ t3 :> "none" @@ t4 :> "none"),tbody |-> (t1 :> "NotStarted" @@ t2 :> "NotStarted" @@ t3 :> "NotStarted" @@ t4 :> "NotStarted"),itCursor |-> (c1 :> 0 @@ c2 :> 0),intrDelivered |-> (c1 :> FALSE @@ c2 :> FALSE),itExpMod |-> (c1 :> 0 @@ c2 :> 0),curInvoked |-> (c1 :> FALSE @@ c2 :> FALSE),bmod |-> 1,decided |-> (c1 :> FALSE @@ c2 :> FALSE),ttag |-> (t1 :> "none" @@ t2 :> "none" @@ t3 :> "none" @@ t4 :> "none"),intr |-> (c1 :> FALSE @@ c2 :> FALSE @@ w1 :> FALSE),cancelR |-> (c1 :> NoWorker @@ c2 :> NoWorker),mc |-> [interrupt |-> 0, outer |-> 0, timeout |-> 0, shutdown |-> 0, idleExit |-> 0, addl |-> 0],cpc |-> (c1 :> "Idle" @@ c2 :> "Idle"),blist |-> <<1>>,exitInfo |-> (c1 :> [flag |-> FALSE, count |-> 0, tag |-> "none", invoked |-> FALSE] @@ c2 :> [flag |-> FALSE, count |-> 0, tag |-> "none", invoked |-> FALSE]),tres |-> (t1 :> "none" @@ t2 :> "none" @@ t3 :> "none" @@ t4 :> "none"),outerState |-> (c1 :> "NA" @@ c2 :> "NA"),trunner |-> (t1 :> NoWorker @@ t2 :> NoWorker @@ t3 :> NoWorker @@ t4 :> NoWorker),outcome |-> (c1 :> "None" @@ c2 :> "None"),ieAt |-> (c1 :> 0 @@ c2 :> 0),bAdding |-> 0,tstate |-> (t1 :> "NEW" @@ t2 :> "NEW" @@ t3 :> "NEW" @@ t4 :> "NEW"),tqueued |-> (t1 :> FALSE @@ t2 :> FALSE @@ t3 :> FALSE @@ t4 :> FALSE),wOuter |-> (w1 :> NoCaller),cbody |-> (c1 :> "none" @@ c2 :> "none"),elapsedOver |-> (c1 :> FALSE @@ c2 :> FALSE),cancelAt |-> (c1 :> -1 @@ c2 :> -1),made |-> (c1 :> 0 @@ c2 :> 0),notified |-> (c1 :> <<>> @@ c2 :> <<>>),curExpired |-> (c1 :> FALSE @@ c2 :> FALSE),wpc |-> (w1 :> "Absent"),curQueued |-> (c1 :> FALSE @@ c2 :> FALSE),curTag |-> (c1 :> "none" @@ c2 :> "none"),sleepCls |-> (c1 :> "none" @@ c2 :> "none"),attemptNo |-> (c1 :> 0 @@ c2 :> 0),exShutdown |-> FALSE,towner |-> (t1 :> NoCaller @@ t2 :> NoCaller @@ t3 :> NoCaller @@ t4 :> NoCaller),intrSrc |-> (w1 :> NoTask),curTask |-> (c1 :> NoTask @@ c2 :> NoTask),queue |-> <<>>,wtask |-> (w1 :> NoTask)]),
    ([tmode |-> (t1 :> "none" @@ t2 :> "none" @@ t3 :> "none" @@ t4 :> "none"),tbody |-> (t1 :> "NotStarted" @@ t2 :> "NotStarted" @@ t3 :> "NotStarted" @@ t4 :> "NotStarted"),itCursor |-> (c1 :> 0 @@ c2 :> 0),intrDelivered |-> (c1 :> FALSE @@ c2 :> FALSE),itExpMod |-> (c1 :> 0 @@ c2 :> 0),curInvoked |-> (c1 :> FALSE @@ c2 :> FALSE),bmod |-> 1,decided |-> (c1 :> FALSE @@ c2 :> FALSE),ttag |-> (t1 :> "none" @@ t2 :> "none" @@ t3 :> "none" @@ t4 :> "none"),intr |-> (c1 :> FALSE @@ c2 :> FALSE @@ w1 :> FALSE),cancelR |-> (c1 :> NoWorker @@ c2 :> NoWorker),mc |-> [interrupt |-> 0, outer |-> 0, timeout |-> 0, shutdown |-> 0, idleExit |-> 0, addl |-> 0],cpc |-> (c1 :> "Attempt" @@ c2 :> "Idle"),blist |-> <<1>>,exitInfo |-> (c1 :> [flag |-> FALSE, count |-> 0, tag |-> "none", invoked |-> FALSE] @@ c2 :> [flag |-> FALSE, count |-> 0, tag |-> "none", invoked |-> FALSE]),tres |-> (t1 :> "none" @@ t2 :> "none" @@ t3 :> "none" @@ t4 :> "none"),outerState |-> (c1 :> "NA" @@ c2 :> "NA"),trunner |-> (t1 :> NoWorker @@ t2 :> NoWorker @@ t3 :> NoWorker @@ t4 :> NoWorker),outcome |-> (c1 :> "None" @@ c2 :> "None"),ieAt |-> (c1 :> 0 @@ c2 :> 0),bAdding |-> 0,tstate |-> (t1 :> "NEW" @@ t2 :> "NEW" @@ t3 :> "NEW" @@ t4 :> "NEW"),tqueued |-> (t1 :> FALSE @@ t2 :> FALSE @@ t3 :> FALSE @@ t4 :> FALSE),wOuter |-> (w1 :> NoCaller),cbody |-> (c1 :> "none" @@ c2 :> "none"),elapsedOver |-> (c1 :> FALSE @@ c2 :> FALSE),cancelAt |-> (c1 :> -1 @@ c2 :> -1),made |-> (c1 :> 0 @@ c2 :> 0),notified |-> (c1 :> <<>> @@ c2 :> <<>>),curExpired |-> (c1 :> FALSE @@ c2 :> FALSE),wpc |-> (w1 :> "Absent"),curQueued |-> (c1 :> FALSE @@ c2 :> FALSE),curTag |-> (c1 :> "none" @@ c2 :> "none"),sleepCls |-> (c1 :> "none" @@ c2 :> "none"),attemptNo |-> (c1 :> 1 @@ c2 :> 0),exShutdown |-> FALSE,towner |-> (t1 :> NoCaller @@ t2 :> NoCaller @@ t3 :> NoCaller @@ t4 :> NoCaller),intrSrc |-> (w1 :> NoTask),curTask |-> (c1 :> NoTask @@ c2 :> NoTask),queue |-> <<>>,wtask |-> (w1 :> NoTask)]),
    ([tmode |-> (t1 :> "none" @@ t2 :> "none" @@ t3 :> "none" @@ t4 :> "none"),tbody |-> (t1 :> "NotStarted" @@ t2 :> "NotStarted" @@ t3 :> "NotStarted" @@ t4 :> "NotStarted"),itCursor |-> (c1 :> 0 @@ c2 :> 0),intrDelivered |-> (c1 :> FALSE @@ c2 :> FALSE),itExpMod |-> (c1 :> 0 @@ c2 :> 0),curInvoked |-> (c1 :> FALSE @@ c2 :> FALSE),bmod |-> 1,decided |-> (c1 :> FALSE @@ c2 :> FALSE),ttag |-> (t1 :> "none" @@ t2 :> "none" @@ t3 :> "none" @@ t4 :> "none"),intr |-> (c1 :> FALSE @@ c2 :> FALSE @@ w1 :> FALSE),cancelR |-> (c1 :> NoWorker @@ c2 :> NoWorker),mc |-> [interrupt |-> 0, outer |-> 0, timeout |-> 0, shutdown |-> 0, idleExit |-> 0, addl |-> 0],cpc |-> (c1 :> "Wait" @@ c2 :> "Idle"),blist |-> <<1>>,exitInfo |-> (c1 :> [flag |-> FALSE, count |-> 0, tag |-> "none", invoked |-> FALSE] @@ c2 :> [flag |-> FALSE, count |-> 0, tag |-> "none", invoked |-> FALSE]),tres |-> (t1 :> "none" @@ t2 :> "none" @@ t3 :> "none" @@ t4 :> "none"),outerState |-> (c1 :> "NA" @@ c2 :> "NA"),trunner |-> (t1 :> NoWorker @@ t2 :> NoWorker @@ t3 :> NoWorker @@ t4 :> NoWorker),outcome |-> (c1 :> "None" @@ c2 :> "None"),ieAt |-> (c1 :> 0 @@ c2 :> 0),bAdding |-> 0,tstate |-> (t1 :> "NEW" @@ t2 :> "NEW" @@ t3 :> "NEW" @@ t4 :> "NEW"),tqueued |-> (t1 :> FALSE @@ t2 :> FALSE @@ t3 :> FALSE @@ t4 :> FALSE),wOuter |-> (w1 :> NoCaller),cbody |-> (c1 :> "none" @@ c2 :> "none"),elapsedOver |-> (c1 :> FALSE @@ c2 :> FALSE),cancelAt |-> (c1 :> -1 @@ c2 :> -1),made |-> (c1 :> 1 @@ c2 :> 0),notified |-> (c1 :> <<>> @@ c2 :> <<>>),curExpired |-> (c1 :> FALSE @@ c2 :> FALSE),wpc |-> (w1 :> "Assigned"),curQueued |-> (c1 :> FALSE @@ c2 :> FALSE),curTag |-> (c1 :> "none" @@ c2 :> "none"),sleepCls |-> (c1 :> "none" @@ c2 :> "none"),attemptNo |-> (c1 :> 1 @@ c2 :> 0),exShutdown |-> FALSE,towner |-> (t1 :> c1 @@ t2 :> NoCaller @@ t3 :> NoCaller @@ t4 :> NoCaller),intrSrc |-> (w1 :> NoTask),curTask |-> (c1 :> t1 @@ c2 :> NoTask),queue |-> <<>>,wtask |-> (w1 :> t1)]),
    ([tmode |-> (t1 :> "none" @@ t2 :> "none" @@ t3 :> "none" @@ t4 :> "none"),tbody |-> (t1 :> "NotStarted" @@ t2 :> "NotStarted" @@ t3 :> "NotStarted" @@ t4 :> "NotStarted"),itCursor |-> (c1 :> 0 @@ c2 :> 0),intrDelivered |-> (c1 :> FALSE @@ c2 :> FALSE),itExpMod |-> (c1 :> 0 @@ c2 :> 0),curInvoked |-> (c1 :> FALSE @@ c2 :> FALSE),bmod |-> 1,decided |-> (c1 :> FALSE @@ c2 :> FALSE),ttag |-> (t1 :> "none" @@ t2 :> "none" @@ t3 :> "none" @@ t4 :> "none"),intr |-> (c1 :> FALSE @@ c2 :> FALSE @@ w1 :> FALSE),cancelR |-> (c1 :> NoWorker @@ c2 :> NoWorker),mc |-> [interrupt |-> 0, outer |-> 0, timeout |-> 0, shutdown |-> 0, idleExit |-> 0, addl |-> 0],cpc |-> (c1 :> "Wait" @@ c2 :> "Attempt"),blist |-> <<1>>,exitInfo |-> (c1 :> [flag |-> FALSE, count |-> 0, tag |-> "none", invoked |-> FALSE] @@ c2 :> [flag |-> FALSE, count |-> 0, tag |-> "none", invoked |-> FALSE]),tres |-> (t1 :> "none" @@ t2 :> "none" @@ t3 :> "none" @@ t4 :> "none"),outerState |-> (c1 :> "NA" @@ c2 :> "NA"),trunner |-> (t1 :> NoWorker @@ t2 :> NoWorker @@ t3 :> NoWorker @@ t4 :> NoWorker),outcome |-> (c1 :> "None" @@ c2 :> "None"),ieAt |-> (c1 :> 0 @@ c2 :> 0),bAdding |-> 0,tstate |-> (t1 :> "NEW" @@ t2 :> "NEW" @@ t3 :> "NEW" @@ t4 :> "NEW"),tqueued |-> (t1 :> FALSE @@ t2 :> FALSE @@ t3 :> FALSE @@ t4 :> FALSE),wOuter |-> (w1 :> NoCaller),cbody |-> (c1 :> "none" @@ c2 :> "none"),elapsedOver |-> (c1 :> FALSE @@ c2 :> FALSE),cancelAt |-> (c1 :> -1 @@ c2 :> -1),made |-> (c1 :> 1 @@ c2 :> 0),notified |-> (c1 :> <<>> @@ c2 :> <<>>),curExpired |-> (c1 :> FALSE @@ c2 :> FALSE),wpc |-> (w1 :> "Assigned"),curQueued |-> (c1 :> FALSE @@ c2 :> FALSE),curTag |-> (c1 :> "none" @@ c2 :> "none"),sleepCls |-> (c1 :> "none" @@ c2 :> "none"),attemptNo |-> (c1 :> 1 @@ c2 :> 1),exShutdown |-> FALSE,towner |-> (t1 :> c1 @@ t2 :> NoCaller @@ t3 :> NoCaller @@ t4 :> NoCaller),intrSrc |-> (w1 :> NoTask),curTask |-> (c1 :> t1 @@ c2 :> NoTask),queue |-> <<>>,wtask |-> (w1 :> t1)]),
    ([tmode |-> (t1 :> "none" @@ t2 :> "none" @@ t3 :> "none" @@ t4 :> "none"),tbody |-> (t1 :> "NotStarted" @@ t2 :> "NotStarted" @@ t3 :> "NotStarted" @@ t4 :> "NotStarted"),itCursor |-> (c1 :> 0 @@ c2 :> 0),intrDelivered |-> (c1 :> FALSE @@ c2 :> FALSE),itExpMod |-> (c1 :> 0 @@ c2 :> 0),curInvoked |-> (c1 :> FALSE @@ c2 :> FALSE),bmod |-> 1,decided |-> (c1 :> FALSE @@ c2 :> FALSE),ttag |-> (t1 :> "none" @@ t2 :> "none" @@ t3 :> "none" @@ t4 :> "none"),intr |-> (c1 :> FALSE @@ c2 :> FALSE @@ w1 :> FALSE),cancelR |-> (c1 :> NoWorker @@ c2 :> NoWorker),mc |-> [interrupt |-> 0, outer |-> 0, timeout |-> 0, shutdown |-> 0, idleExit |-> 0, addl |-> 0],cpc |-> (c1 :> "Wait" @@ c2 :> "Wait"),blist |-> <<1>>,exitInfo |-> (c1 :> [flag |-> FALSE, count |-> 0, tag |-> "none", invoked |-> FALSE] @@ c2 :> [flag |-> FALSE, count |-> 0, tag |-> "none", invoked |-> FALSE]),tres |-> (t1 :> "none" @@ t2 :> "none" @@ t3 :> "none" @@ t4 :> "none"),outerState |-> (c1 :> "NA" @@ c2 :> "NA"),trunner |-> (t1 :> NoWorker @@ t2 :> NoWorker @@ t3 :> NoWorker @@ t4 :> NoWorker),outcome |-> (c1 :> "None" @@ c2 :> "None"),ieAt |-> (c1 :> 0 @@ c2 :> 0),bAdding |-> 0,tstate |-> (t1 :> "NEW" @@ t2 :> "NEW" @@ t3 :> "NEW" @@ t4 :> "NEW"),tqueued |-> (t1 :> FALSE @@ t2 :> TRUE @@ t3 :> FALSE @@ t4 :> FALSE),wOuter |-> (w1 :> NoCaller),cbody |-> (c1 :> "none" @@ c2 :> "none"),elapsedOver |-> (c1 :> FALSE @@ c2 :> FALSE),cancelAt |-> (c1 :> -1 @@ c2 :> -1),made |-> (c1 :> 1 @@ c2 :> 1),notified |-> (c1 :> <<>> @@ c2 :> <<>>),curExpired |-> (c1 :> FALSE @@ c2 :> FALSE),wpc |-> (w1 :> "Assigned"),curQueued |-> (c1 :> FALSE @@ c2 :> FALSE),curTag |-> (c1 :> "none" @@ c2 :> "none"),sleepCls |-> (c1 :> "none" @@ c2 :> "none"),attemptNo |-> (c1 :> 1 @@ c2 :> 1),exShutdown |-> FALSE,towner |-> (t1 :> c1 @@ t2 :> c2 @@ t3 :> NoCaller @@ t4 :> NoCaller),intrSrc |-> (w1 :> NoTask),curTask |-> (c1 :> t1 @@ c2 :> t2),queue |-> <<t2>>,wtask |-> (w1 :> t1)]),
    ([tmode |-> (t1 :> "none" @@ t2 :> "none" @@ t3 :> "none" @@ t4 :> "none"),tbody |-> (t1 :> "NotStarted" @@ t2 :> "NotStarted" @@ t3 :> "NotStarted" @@ t4 :> "NotStarted"),itCursor |-> (c1 :> 0 @@ c2 :> 0),intrDelivered |-> (c1 :> FALSE @@ c2 :> FALSE),itExpMod |-> (c1 :> 0 @@ c2 :> 0),curInvoked |-> (c1 :> FALSE @@ c2 :> FALSE),bmod |-> 1,decided |-> (c1 :> FALSE @@ c2 :> FALSE),ttag |-> (t1 :> "none" @@ t2 :> "Timeout" @@ t3 :> "none" @@ t4 :> "none"),intr |-> (c1 :> FALSE @@ c2 :> FALSE @@ w1 :> FALSE),cancelR |-> (c1 :> NoWorker @@ c2 :> NoWorker),mc |-> [interrupt |-> 0, outer |-> 0, timeout |-> 1, shutdown |-> 0, idleExit |-> 0, addl |-> 0],cpc |-> (c1 :> "Wait" @@ c2 :> "CancelTO"),blist |-> <<1>>,exitInfo |-> (c1 :> [flag |-> FALSE, count |-> 0, tag |-> "none", invoked |-> FALSE] @@ c2 :> [flag |-> FALSE, count |-> 0, tag |-> "none", invoked |-> FALSE]),tres |-> (t1 :> "none" @@ t2 :> "none" @@ t3 :> "none" @@ t4 :> "none"),outerState |-> (c1 :> "NA" @@ c2 :> "NA"),trunner |-> (t1 :> NoWorker @@ t2 :> NoWorker @@ t3 :> NoWorker @@ t4 :> NoWorker),outcome |-> (c1 :> "None" @@ c2 :> "None"),ieAt |-> (c1 :> 0 @@ c2 :> 0),bAdding |-> 0,tstate |-> (t1 :> "NEW" @@ t2 :> "NEW" @@ t3 :> "NEW" @@ t4 :> "NEW"),tqueued |-> (t1 :> FALSE @@ t2 :> TRUE @@ t3 :> FALSE @@ t4 :> FALSE),wOuter |-> (w1 :> NoCaller),cbody |-> (c1 :> "none" @@ c2 :> "none"),elapsedOver |-> (c1 :> FALSE @@ c2 :> FALSE),cancelAt |-> (c1 :> -1 @@ c2 :> -1),made |-> (c1 :> 1 @@ c2 :> 1),notified |-> (c1 :> <<>> @@ c2 :> <<>>),curExpired |-> (c1 :> FALSE @@ c2 :> FALSE),wpc |-> (w1 :> "Assigned"),curQueued |-> (c1 :> FALSE @@ c2 :> FALSE),curTag |-> (c1 :> "none" @@ c2 :> "Timeout"),sleepCls |-> (c1 :> "none" @@ c2 :> "none"),attemptNo |-> (c1 :> 1 @@ c2 :> 1),exShutdown |-> FALSE,towner |-> (t1 :> c1 @@ t2 :> c2 @@ t3 :> NoCaller @@ t4 :> NoCaller),intrSrc |-> (w1 :> NoTask),curTask |-> (c1 :> t1 @@ c2 :> t2),queue |-> <<t2>>,wtask |-> (w1 :> t1)]),
    ([tmode |-> (t1 :> "none" @@ t2 :> "none" @@ t3 :> "none" @@ t4 :> "none"),tbody |-> (t1 :> "NotStarted" @@ t2 :> "NotStarted" @@ t3 :> "NotStarted" @@ t4 :> "NotStarted"),itCursor |-> (c1 :> 0 @@ c2 :> 0),intrDelivered |-> (c1 :> FALSE @@ c2 :> FALSE),itExpMod |-> (c1 :> 0 @@ c2 :> 0),curInvoked |-> (c1 :> FALSE @@ c2 :> FALSE),bmod |-> 1,decided |-> (c1 :> FALSE @@ c2 :> FALSE),ttag |-> (t1 :> "none" @@ t2 :> "Timeout" @@ t3 :> "none" @@ t4 :> "none"),intr |-> (c1 :> FALSE @@ c2 :> FALSE @@ w1 :> FALSE),cancelR |-> (c1 :> NoWorker @@ c2 :> NoWorker),mc |-> [interrupt |-> 0, outer |-> 0, timeout |-> 1, shutdown |-> 0, idleExit |-> 0, addl |-> 0],cpc |-> (c1 :> "Wait" @@ c2 :> "CancelRead"),blist |-> <<1>>,exitInfo |-> (c1 :> [flag |-> FALSE, count |-> 0, tag |-> "none", invoked |-> FALSE] @@ c2 :> [flag |-> FALSE, count |-> 0, tag |-> "none", invoked |-> FALSE]),tres |-> (t1 :> "none" @@ t2 :> "none" @@ t3 :> "none" @@ t4 :> "none"),outerState |-> (c1 :> "NA" @@ c2 :> "NA"),trunner |-> (t1 :> NoWorker @@ t2 :> NoWorker @@ t3 :> NoWorker @@ t4 :> NoWorker),outcome |-> (c1 :> "None" @@ c2 :> "None"),ieAt |-> (c1 :> 0 @@ c2 :> 0),bAdding |-> 0,tstate |-> (t1 :> "NEW" @@ t2 :> "INTERRUPTING" @@ t3 :> "NEW" @@ t4 :> "NEW"),tqueued |-> (t1 :> FALSE @@ t2 :> TRUE @@ t3 :> FALSE @@ t4 :> FALSE),wOuter |-> (w1 :> NoCaller),cbody |-> (c1 :> "none" @@ c2 :> "none"),elapsedOver |-> (c1 :> FALSE @@ c2 :> FALSE),cancelAt |-> (c1 :> -1 @@ c2 :> -1),made |-> (c1 :> 1 @@ c2 :> 1),notified |-> (c1 :> <<>> @@ c2 :> <<>>),curExpired |-> (c1 :> FALSE @@ c2 :> FALSE),wpc |-> (w1 :> "Assigned"),curQueued |-> (c1 :> FALSE @@ c2 :> FALSE),curTag |-> (c1 :> "none" @@ c2 :> "Timeout"),sleepCls |-> (c1 :> "none" @@ c2 :> "none"),attemptNo |-> (c1 :> 1 @@ c2 :> 1),exShutdown |-> FALSE,towner |-> (t1 :> c1 @@ t2 :> c2 @@ t3 :> NoCaller @@ t4 :> NoCaller),intrSrc |-> (w1 :> NoTask),curTask |-> (c1 :> t1 @@ c2 :> t2),queue |-> <<t2>>,wtask |-> (w1 :> t1)]),
    ([tmode |-> (t1 :> "none" @@ t2 :> "none" @@ t3 :> "none" @@ t4 :> "none"),tbody |-> (t1 :> "NotStarted" @@ t2 :> "NotStarted" @@ t3 :> "NotStarted" @@ t4 :> "NotStarted"),itCursor |-> (c1 :> 0 @@ c2 :> 0),intrDelivered |-> (c1 :> FALSE @@ c2 :> FALSE),itExpMod |-> (c1 :> 0 @@ c2 :> 0),curInvoked |-> (c1 :> FALSE @@ c2 :> FALSE),bmod |-> 1,decided |-> (c1 :> FALSE @@ c2 :> FALSE),ttag |-> (t1 :> "none" @@ t2 :> "Timeout" @@ t3 :> "none" @@ t4 :> "none"),intr |-> (c1 :> FALSE @@ c2 :> FALSE @@ w1 :> FALSE),cancelR |-> (c1 :> NoWorker @@ c2 :> NoWorker),mc |-> [interrupt |-> 0, outer |-> 0, timeout |-> 1, shutdown |-> 0, idleExit |-> 0, addl |-> 0],cpc |-> (c1 :> "Wait" @@ c2 :> "CancelSet"),blist |-> <<1>>,exitInfo |-> (c1 :> [flag |-> FALSE, count |-> 0, tag |-> "none", invoked |-> FALSE] @@ c2 :> [flag |-> FALSE, count |-> 0, tag |-> "none", invoked |-> FALSE]),tres |-> (t1 :> "none" @@ t2 :> "none" @@ t3 :> "none" @@ t4 :> "none"),outerState |-> (c1 :> "NA" @@ c2 :> "NA"),trunner |-> (t1 :> NoWorker @@ t2 :> NoWorker @@ t3 :> NoWorker @@ t4 :> NoWorker),outcome |-> (c1 :> "None" @@ c2 :> "None"),ieAt |-> (c1 :> 0 @@ c2 :> 0),bAdding |-> 0,tstate |-> (t1 :> "NEW" @@ t2 :> "INTERRUPTING" @@ t3 :> "NEW" @@ t4 :> "NEW"),tqueued |-> (t1 :> FALSE @@ t2 :> TRUE @@ t3 :> FALSE @@ t4 :> FALSE),wOuter |-> (w1 :> NoCaller),cbody |-> (c1 :> "none" @@ c2 :> "none"),elapsedOver |-> (c1 :> FALSE @@ c2 :> FALSE),cancelAt |-> (c1 :> -1 @@ c2 :> -1),made |-> (c1 :> 1 @@ c2 :> 1),notified |-> (c1 :> <<>> @@ c2 :> <<>>),curExpired |-> (c1 :> FALSE @@ c2 :> FALSE),wpc |-> (w1 :> "Assigned"),curQueued |-> (c1 :> FALSE @@ c2 :> FALSE),curTag |-> (c1 :> "none" @@ c2 :> "Timeout"),sleepCls |-> (c1 :> "none" @@ c2 :> "none"),attemptNo |-> (c1 :> 1 @@ c2 :> 1),exShutdown |-> FALSE,towner |-> (t1 :> c1 @@ t2 :> c2 @@ t3 :> NoCaller @@ t4 :> NoCaller),intrSrc |-> (w1 :> NoTask),curTask |-> (c1 :> t1 @@ c2 :> t2),queue |-> <<t2>>,wtask |-> (w1 :> t1)]),
    ([tmode |-> (t1 :> "none" @@ t2 :> "none" @@ t3 :> "none" @@ t4 :> "none"),tbody |-> (t1 :> "NotStarted" @@ t2 :> "NotStarted" @@ t3 :> "NotStarted" @@ t4 :> "NotStarted"),itCursor |-> (c1 :> 0 @@ c2 :> 0),intrDelivered |-> (c1 :> FALSE @@ c2 :> FALSE),itExpMod |-> (c1 :> 0 @@ c2 :> 0),curInvoked |-> (c1 :> FALSE @@ c2 :> FALSE),bmod |-> 1,decided |-> (c1 :> FALSE @@ c2 :> FALSE),ttag |-> (t1 :> "none" @@ t2 :> "Timeout" @@ t3 :> "none" @@ t4 :> "none"),intr |-> (c1 :> FALSE @@ c2 :> FALSE @@ w1 :> FALSE),cancelR |-> (c1 :> NoWorker @@ c2 :> NoWorker),mc |-> [interrupt |-> 0, outer |-> 0, timeout |-> 1, shutdown |-> 0, idleExit |-> 0, addl |-> 0],cpc |-> (c1 :> "Wait" @@ c2 :> "Classified"),blist |-> <<1>>,exitInfo |-> (c1 :> [flag |-> FALSE, count |-> 0, tag |-> "none", invoked |-> FALSE] @@ c2 :> [flag |-> FALSE, count |-> 0, tag |-> "none", invoked |-> FALSE]),tres |-> (t1 :> "none" @@ t2 :> "none" @@ t3 :> "none" @@ t4 :> "none"),outerState |-> (c1 :> "NA" @@ c2 :> "NA"),trunner |-> (t1 :> NoWorker @@ t2 :> NoWorker @@ t3 :> NoWorker @@ t4 :> NoWorker),outcome |-> (c1 :> "None" @@ c2 :> "None"),ieAt |-> (c1 :> 0 @@ c2 :> 0),bAdding |-> 0,tstate |-> (t1 :> "NEW" @@ t2 :> "INTERRUPTED" @@ t3 :> "NEW" @@ t4 :> "NEW"),tqueued |-> (t1 :> FALSE @@ t2 :> TRUE @@ t3 :> FALSE @@ t4 :> FALSE),wOuter |-> (w1 :> NoCaller),cbody |-> (c1 :> "none" @@ c2 :> "none"),elapsedOver |-> (c1 :> FALSE @@ c2 :> FALSE),cancelAt |-> (c1 :> -1 @@ c2 :> -1),made |-> (c1 :> 1 @@ c2 :> 1),notified |-> (c1 :> <<>> @@ c2 :> <<>>),curExpired |-> (c1 :> FALSE @@ c2 :> FALSE),wpc |-> (w1 :> "Assigned"),curQueued |-> (c1 :> FALSE @@ c2 :> TRUE),curTag |-> (c1 :> "none" @@ c2 :> "Timeout"),sleepCls |-> (c1 :> "none" @@ c2 :> "none"),attemptNo |-> (c1 :> 1 @@ c2 :> 1),exShutdown |-> FALSE,towner |-> (t1 :> c1 @@ t2 :> c2 @@ t3 :> NoCaller @@ t4 :> NoCaller),intrSrc |-> (w1 :> NoTask),curTask |-> (c1 :> t1 @@ c2 :> NoTask),queue |-> <<t2>>,wtask |-> (w1 :> t1)])
    >>
----


=============================================================================

---- MODULE MC_TEConstants ----
EXTENDS MC

CONSTANTS c1, c2, w1, t1, t2, t3, t4

=============================================================================

---- CONFIG MC_TTrace_1795680446 ----
CONSTANTS
    Callers = { c1 , c2 }
    Workers = { w1 }
    TaskIds = { t1 , t2 , t3 , t4 }
    NumInitListeners = 1
    NumExtraListeners = 0
    Limiter = "Fixed"
    ExecKind = "Bounded"
    PoolSize = 1
    QueueCap = 1
    RetryOn = { "Timeout" , "Rejected" , "CallableExc" }
    StopKind = "AfterAttempt"
    StopAfter = 2
    SleepClasses = { "Zero" }
    Modes = { "Ret" , "Stuck" }
    WrapCallers = { }
    WrapOnLimiterPool = { }
    NoTask = NoTask
    NoWorker = NoWorker
    NoCaller = NoCaller
    MaxInterrupts = 0
    MaxOuterCancels = 0
    MaxTimeouts = 2
    TimeoutsBounded = TRUE
    MaxShutdowns = 0
    MaxIdleExits = 0
    MaxAddListeners = 0
    MaxAttempts = 2
    CountCap = 100
    t1 = t1
    NoWorker = NoWorker
    w1 = w1
    c2 = c2
    t2 = t2
    NoCaller = NoCaller
    t4 = t4
    NoTask = NoTask
    t3 = t3
    c1 = c1

INVARIANT
    _inv

CHECK_DEADLOCK
    \* CHECK_DEADLOCK off because of PROPERTY or INVARIANT above.
    FALSE

INIT
    _init

NEXT
    _next

CONSTANT
    _TETrace <- _trace

ALIAS
    _expression
=============================================================================
\* Generated on Thu Nov 26 08:07:28 UTC 2026