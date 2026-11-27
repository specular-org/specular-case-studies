---- MODULE Trace_TTrace_1795679760 ----
EXTENDS Trace, Sequences, TLCExt, Toolbox, Naturals, TLC

_expression ==
    LET Trace_TEExpression == INSTANCE Trace_TEExpression
    IN Trace_TEExpression!expression
----

_trace ==
    LET Trace_TETrace == INSTANCE Trace_TETrace
    IN Trace_TETrace!trace
----

_prop ==
    ~<>[](
        tmode = ([t1 |-> "none", t2 |-> "none", t3 |-> "none"])
        /\
        tbody = ([t1 |-> "NotStarted", t2 |-> "NotStarted", t3 |-> "NotStarted"])
        /\
        itCursor = ([c1 |-> 0, c2 |-> 0])
        /\
        intrDelivered = ([c1 |-> FALSE, c2 |-> FALSE])
        /\
        itExpMod = ([c1 |-> 0, c2 |-> 0])
        /\
        curInvoked = ([c1 |-> FALSE, c2 |-> FALSE])
        /\
        bmod = (2)
        /\
        decided = ([c1 |-> FALSE, c2 |-> FALSE])
        /\
        ttag = ([t1 |-> "Timeout", t2 |-> "none", t3 |-> "none"])
        /\
        intr = ([w1 |-> TRUE, w2 |-> FALSE, c1 |-> FALSE, c2 |-> FALSE])
        /\
        cancelR = ([c1 |-> "NoWorker", c2 |-> "NoWorker"])
        /\
        cpc = ([c1 |-> "Classified", c2 |-> "Wait"])
        /\
        blist = (<<1, 2>>)
        /\
        exitInfo = ([c1 |-> [tag |-> "none", count |-> 0, flag |-> FALSE, invoked |-> FALSE], c2 |-> [tag |-> "none", count |-> 0, flag |-> FALSE, invoked |-> FALSE]])
        /\
        tres = ([t1 |-> "none", t2 |-> "none", t3 |-> "none"])
        /\
        outerState = ([c1 |-> "NA", c2 |-> "NA"])
        /\
        trunner = ([t1 |-> "NoWorker", t2 |-> "NoWorker", t3 |-> "NoWorker"])
        /\
        outcome = ([c1 |-> "None", c2 |-> "None"])
        /\
        ieAt = ([c1 |-> 0, c2 |-> 0])
        /\
        bAdding = (0)
        /\
        tstate = ([t1 |-> "INTERRUPTED", t2 |-> "NEW", t3 |-> "NEW"])
        /\
        tqueued = ([t1 |-> FALSE, t2 |-> FALSE, t3 |-> FALSE])
        /\
        wOuter = ([w1 |-> "NoCaller", w2 |-> "NoCaller"])
        /\
        cbody = ([c1 |-> "none", c2 |-> "none"])
        /\
        elapsedOver = ([c1 |-> FALSE, c2 |-> FALSE])
        /\
        cancelAt = ([c1 |-> -1, c2 |-> -1])
        /\
        made = ([c1 |-> 1, c2 |-> 1])
        /\
        notified = ([c1 |-> <<>>, c2 |-> <<>>])
        /\
        curExpired = ([c1 |-> FALSE, c2 |-> FALSE])
        /\
        wpc = ([w1 |-> "Idle", w2 |-> "Assigned"])
        /\
        curQueued = ([c1 |-> FALSE, c2 |-> FALSE])
        /\
        l = (17)
        /\
        curTag = ([c1 |-> "Timeout", c2 |-> "none"])
        /\
        tc = ([w1 |-> 6, w2 |-> 1, b |-> 3, c1 |-> 8, c2 |-> 3, main |-> 1])
        /\
        sleepCls = ([c1 |-> "none", c2 |-> "none"])
        /\
        attemptNo = ([c1 |-> 1, c2 |-> 1])
        /\
        exShutdown = (FALSE)
        /\
        towner = ([t1 |-> "c1", t2 |-> "c2", t3 |-> "NoCaller"])
        /\
        intrSrc = ([w1 |-> "t1", w2 |-> "NoTask"])
        /\
        curTask = ([c1 |-> "NoTask", c2 |-> "t2"])
        /\
        queue = (<<>>)
        /\
        wtask = ([w1 |-> "NoTask", w2 |-> "t2"])
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
    /\ l = _TETrace[1].l
    /\ attemptNo = _TETrace[1].attemptNo
    /\ cancelAt = _TETrace[1].cancelAt
    /\ outcome = _TETrace[1].outcome
    /\ made = _TETrace[1].made
    /\ itCursor = _TETrace[1].itCursor
    /\ intrSrc = _TETrace[1].intrSrc
    /\ curInvoked = _TETrace[1].curInvoked
    /\ cbody = _TETrace[1].cbody
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
    /\ tc = _TETrace[1].tc
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
        /\ l  = _TETrace[i].l
        /\ l' = _TETrace[j].l
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
        /\ tc  = _TETrace[i].tc
        /\ tc' = _TETrace[j].tc
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
    \*         IN J!JsonSerialize("Trace_TTrace_1795679760.json", _TETrace)

=============================================================================

 Note that you can extract this module `Trace_TEExpression`
  to a dedicated file to reuse `expression` (the module in the 
  dedicated `Trace_TEExpression.tla` file takes precedence 
  over the module `Trace_TEExpression` below).

---- MODULE Trace_TEExpression ----
EXTENDS Trace, Sequences, TLCExt, Toolbox, Naturals, TLC

expression == 
    [
        \* To hide variables of the `Trace` spec from the error trace,
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
        ,l |-> l
        ,attemptNo |-> attemptNo
        ,cancelAt |-> cancelAt
        ,outcome |-> outcome
        ,made |-> made
        ,itCursor |-> itCursor
        ,intrSrc |-> intrSrc
        ,curInvoked |-> curInvoked
        ,cbody |-> cbody
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
        ,tc |-> tc
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
\*---- MODULE Trace_TETrace ----
\*EXTENDS Trace, IOUtils, TLC
\*
\*trace == IODeserialize("Trace_TTrace_1795679760.bin", TRUE)
\*
\*=============================================================================
\*

---- MODULE Trace_TETrace ----
EXTENDS Trace, TLC

trace == 
    <<
    ([tmode |-> [t1 |-> "none", t2 |-> "none", t3 |-> "none"],tbody |-> [t1 |-> "NotStarted", t2 |-> "NotStarted", t3 |-> "NotStarted"],itCursor |-> [c1 |-> 0, c2 |-> 0],intrDelivered |-> [c1 |-> FALSE, c2 |-> FALSE],itExpMod |-> [c1 |-> 0, c2 |-> 0],curInvoked |-> [c1 |-> FALSE, c2 |-> FALSE],bmod |-> 1,decided |-> [c1 |-> FALSE, c2 |-> FALSE],ttag |-> [t1 |-> "none", t2 |-> "none", t3 |-> "none"],intr |-> [w1 |-> FALSE, w2 |-> FALSE, c1 |-> FALSE, c2 |-> FALSE],cancelR |-> [c1 |-> "NoWorker", c2 |-> "NoWorker"],cpc |-> [c1 |-> "Idle", c2 |-> "Idle"],blist |-> <<1>>,exitInfo |-> [c1 |-> [tag |-> "none", count |-> 0, flag |-> FALSE, invoked |-> FALSE], c2 |-> [tag |-> "none", count |-> 0, flag |-> FALSE, invoked |-> FALSE]],tres |-> [t1 |-> "none", t2 |-> "none", t3 |-> "none"],outerState |-> [c1 |-> "NA", c2 |-> "NA"],trunner |-> [t1 |-> "NoWorker", t2 |-> "NoWorker", t3 |-> "NoWorker"],outcome |-> [c1 |-> "None", c2 |-> "None"],ieAt |-> [c1 |-> 0, c2 |-> 0],bAdding |-> 0,tstate |-> [t1 |-> "NEW", t2 |-> "NEW", t3 |-> "NEW"],tqueued |-> [t1 |-> FALSE, t2 |-> FALSE, t3 |-> FALSE],wOuter |-> [w1 |-> "NoCaller", w2 |-> "NoCaller"],cbody |-> [c1 |-> "none", c2 |-> "none"],elapsedOver |-> [c1 |-> FALSE, c2 |-> FALSE],cancelAt |-> [c1 |-> -1, c2 |-> -1],made |-> [c1 |-> 0, c2 |-> 0],notified |-> [c1 |-> <<>>, c2 |-> <<>>],curExpired |-> [c1 |-> FALSE, c2 |-> FALSE],wpc |-> [w1 |-> "Absent", w2 |-> "Absent"],curQueued |-> [c1 |-> FALSE, c2 |-> FALSE],l |-> 1,curTag |-> [c1 |-> "none", c2 |-> "none"],tc |-> [w1 |-> 1, w2 |-> 1, b |-> 1, c1 |-> 1, c2 |-> 1, main |-> 1],sleepCls |-> [c1 |-> "none", c2 |-> "none"],attemptNo |-> [c1 |-> 0, c2 |-> 0],exShutdown |-> FALSE,towner |-> [t1 |-> "NoCaller", t2 |-> "NoCaller", t3 |-> "NoCaller"],intrSrc |-> [w1 |-> "NoTask", w2 |-> "NoTask"],curTask |-> [c1 |-> "NoTask", c2 |-> "NoTask"],queue |-> <<>>,wtask |-> [w1 |-> "NoTask", w2 |-> "NoTask"]]),
    ([tmode |-> [t1 |-> "none", t2 |-> "none", t3 |-> "none"],tbody |-> [t1 |-> "NotStarted", t2 |-> "NotStarted", t3 |-> "NotStarted"],itCursor |-> [c1 |-> 0, c2 |-> 0],intrDelivered |-> [c1 |-> FALSE, c2 |-> FALSE],itExpMod |-> [c1 |-> 0, c2 |-> 0],curInvoked |-> [c1 |-> FALSE, c2 |-> FALSE],bmod |-> 1,decided |-> [c1 |-> FALSE, c2 |-> FALSE],ttag |-> [t1 |-> "none", t2 |-> "none", t3 |-> "none"],intr |-> [w1 |-> FALSE, w2 |-> FALSE, c1 |-> FALSE, c2 |-> FALSE],cancelR |-> [c1 |-> "NoWorker", c2 |-> "NoWorker"],cpc |-> [c1 |-> "Attempt", c2 |-> "Idle"],blist |-> <<1>>,exitInfo |-> [c1 |-> [tag |-> "none", count |-> 0, flag |-> FALSE, invoked |-> FALSE], c2 |-> [tag |-> "none", count |-> 0, flag |-> FALSE, invoked |-> FALSE]],tres |-> [t1 |-> "none", t2 |-> "none", t3 |-> "none"],outerState |-> [c1 |-> "NA", c2 |-> "NA"],trunner |-> [t1 |-> "NoWorker", t2 |-> "NoWorker", t3 |-> "NoWorker"],outcome |-> [c1 |-> "None", c2 |-> "None"],ieAt |-> [c1 |-> 0, c2 |-> 0],bAdding |-> 0,tstate |-> [t1 |-> "NEW", t2 |-> "NEW", t3 |-> "NEW"],tqueued |-> [t1 |-> FALSE, t2 |-> FALSE, t3 |-> FALSE],wOuter |-> [w1 |-> "NoCaller", w2 |-> "NoCaller"],cbody |-> [c1 |-> "none", c2 |-> "none"],elapsedOver |-> [c1 |-> FALSE, c2 |-> FALSE],cancelAt |-> [c1 |-> -1, c2 |-> -1],made |-> [c1 |-> 0, c2 |-> 0],notified |-> [c1 |-> <<>>, c2 |-> <<>>],curExpired |-> [c1 |-> FALSE, c2 |-> FALSE],wpc |-> [w1 |-> "Absent", w2 |-> "Absent"],curQueued |-> [c1 |-> FALSE, c2 |-> FALSE],l |-> 2,curTag |-> [c1 |-> "none", c2 |-> "none"],tc |-> [w1 |-> 1, w2 |-> 1, b |-> 1, c1 |-> 2, c2 |-> 1, main |-> 1],sleepCls |-> [c1 |-> "none", c2 |-> "none"],attemptNo |-> [c1 |-> 1, c2 |-> 0],exShutdown |-> FALSE,towner |-> [t1 |-> "NoCaller", t2 |-> "NoCaller", t3 |-> "NoCaller"],intrSrc |-> [w1 |-> "NoTask", w2 |-> "NoTask"],curTask |-> [c1 |-> "NoTask", c2 |-> "NoTask"],queue |-> <<>>,wtask |-> [w1 |-> "NoTask", w2 |-> "NoTask"]]),
    ([tmode |-> [t1 |-> "none", t2 |-> "none", t3 |-> "none"],tbody |-> [t1 |-> "NotStarted", t2 |-> "NotStarted", t3 |-> "NotStarted"],itCursor |-> [c1 |-> 0, c2 |-> 0],intrDelivered |-> [c1 |-> FALSE, c2 |-> FALSE],itExpMod |-> [c1 |-> 0, c2 |-> 0],curInvoked |-> [c1 |-> FALSE, c2 |-> FALSE],bmod |-> 1,decided |-> [c1 |-> FALSE, c2 |-> FALSE],ttag |-> [t1 |-> "none", t2 |-> "none", t3 |-> "none"],intr |-> [w1 |-> FALSE, w2 |-> FALSE, c1 |-> FALSE, c2 |-> FALSE],cancelR |-> [c1 |-> "NoWorker", c2 |-> "NoWorker"],cpc |-> [c1 |-> "Attempt", c2 |-> "Attempt"],blist |-> <<1>>,exitInfo |-> [c1 |-> [tag |-> "none", count |-> 0, flag |-> FALSE, invoked |-> FALSE], c2 |-> [tag |-> "none", count |-> 0, flag |-> FALSE, invoked |-> FALSE]],tres |-> [t1 |-> "none", t2 |-> "none", t3 |-> "none"],outerState |-> [c1 |-> "NA", c2 |-> "NA"],trunner |-> [t1 |-> "NoWorker", t2 |-> "NoWorker", t3 |-> "NoWorker"],outcome |-> [c1 |-> "None", c2 |-> "None"],ieAt |-> [c1 |-> 0, c2 |-> 0],bAdding |-> 0,tstate |-> [t1 |-> "NEW", t2 |-> "NEW", t3 |-> "NEW"],tqueued |-> [t1 |-> FALSE, t2 |-> FALSE, t3 |-> FALSE],wOuter |-> [w1 |-> "NoCaller", w2 |-> "NoCaller"],cbody |-> [c1 |-> "none", c2 |-> "none"],elapsedOver |-> [c1 |-> FALSE, c2 |-> FALSE],cancelAt |-> [c1 |-> -1, c2 |-> -1],made |-> [c1 |-> 0, c2 |-> 0],notified |-> [c1 |-> <<>>, c2 |-> <<>>],curExpired |-> [c1 |-> FALSE, c2 |-> FALSE],wpc |-> [w1 |-> "Absent", w2 |-> "Absent"],curQueued |-> [c1 |-> FALSE, c2 |-> FALSE],l |-> 3,curTag |-> [c1 |-> "none", c2 |-> "none"],tc |-> [w1 |-> 1, w2 |-> 1, b |-> 1, c1 |-> 2, c2 |-> 2, main |-> 1],sleepCls |-> [c1 |-> "none", c2 |-> "none"],attemptNo |-> [c1 |-> 1, c2 |-> 1],exShutdown |-> FALSE,towner |-> [t1 |-> "NoCaller", t2 |-> "NoCaller", t3 |-> "NoCaller"],intrSrc |-> [w1 |-> "NoTask", w2 |-> "NoTask"],curTask |-> [c1 |-> "NoTask", c2 |-> "NoTask"],queue |-> <<>>,wtask |-> [w1 |-> "NoTask", w2 |-> "NoTask"]]),
    ([tmode |-> [t1 |-> "none", t2 |-> "none", t3 |-> "none"],tbody |-> [t1 |-> "NotStarted", t2 |-> "NotStarted", t3 |-> "NotStarted"],itCursor |-> [c1 |-> 0, c2 |-> 0],intrDelivered |-> [c1 |-> FALSE, c2 |-> FALSE],itExpMod |-> [c1 |-> 0, c2 |-> 0],curInvoked |-> [c1 |-> FALSE, c2 |-> FALSE],bmod |-> 1,decided |-> [c1 |-> FALSE, c2 |-> FALSE],ttag |-> [t1 |-> "none", t2 |-> "none", t3 |-> "none"],intr |-> [w1 |-> FALSE, w2 |-> FALSE, c1 |-> FALSE, c2 |-> FALSE],cancelR |-> [c1 |-> "NoWorker", c2 |-> "NoWorker"],cpc |-> [c1 |-> "Wait", c2 |-> "Attempt"],blist |-> <<1>>,exitInfo |-> [c1 |-> [tag |-> "none", count |-> 0, flag |-> FALSE, invoked |-> FALSE], c2 |-> [tag |-> "none", count |-> 0, flag |-> FALSE, invoked |-> FALSE]],tres |-> [t1 |-> "none", t2 |-> "none", t3 |-> "none"],outerState |-> [c1 |-> "NA", c2 |-> "NA"],trunner |-> [t1 |-> "NoWorker", t2 |-> "NoWorker", t3 |-> "NoWorker"],outcome |-> [c1 |-> "None", c2 |-> "None"],ieAt |-> [c1 |-> 0, c2 |-> 0],bAdding |-> 0,tstate |-> [t1 |-> "NEW", t2 |-> "NEW", t3 |-> "NEW"],tqueued |-> [t1 |-> FALSE, t2 |-> FALSE, t3 |-> FALSE],wOuter |-> [w1 |-> "NoCaller", w2 |-> "NoCaller"],cbody |-> [c1 |-> "none", c2 |-> "none"],elapsedOver |-> [c1 |-> FALSE, c2 |-> FALSE],cancelAt |-> [c1 |-> -1, c2 |-> -1],made |-> [c1 |-> 1, c2 |-> 0],notified |-> [c1 |-> <<>>, c2 |-> <<>>],curExpired |-> [c1 |-> FALSE, c2 |-> FALSE],wpc |-> [w1 |-> "Assigned", w2 |-> "Absent"],curQueued |-> [c1 |-> FALSE, c2 |-> FALSE],l |-> 4,curTag |-> [c1 |-> "none", c2 |-> "none"],tc |-> [w1 |-> 1, w2 |-> 1, b |-> 1, c1 |-> 3, c2 |-> 2, main |-> 1],sleepCls |-> [c1 |-> "none", c2 |-> "none"],attemptNo |-> [c1 |-> 1, c2 |-> 1],exShutdown |-> FALSE,towner |-> [t1 |-> "c1", t2 |-> "NoCaller", t3 |-> "NoCaller"],intrSrc |-> [w1 |-> "NoTask", w2 |-> "NoTask"],curTask |-> [c1 |-> "t1", c2 |-> "NoTask"],queue |-> <<>>,wtask |-> [w1 |-> "t1", w2 |-> "NoTask"]]),
    ([tmode |-> [t1 |-> "none", t2 |-> "none", t3 |-> "none"],tbody |-> [t1 |-> "NotStarted", t2 |-> "NotStarted", t3 |-> "NotStarted"],itCursor |-> [c1 |-> 0, c2 |-> 0],intrDelivered |-> [c1 |-> FALSE, c2 |-> FALSE],itExpMod |-> [c1 |-> 0, c2 |-> 0],curInvoked |-> [c1 |-> FALSE, c2 |-> FALSE],bmod |-> 1,decided |-> [c1 |-> FALSE, c2 |-> FALSE],ttag |-> [t1 |-> "none", t2 |-> "none", t3 |-> "none"],intr |-> [w1 |-> FALSE, w2 |-> FALSE, c1 |-> FALSE, c2 |-> FALSE],cancelR |-> [c1 |-> "NoWorker", c2 |-> "NoWorker"],cpc |-> [c1 |-> "Wait", c2 |-> "Wait"],blist |-> <<1>>,exitInfo |-> [c1 |-> [tag |-> "none", count |-> 0, flag |-> FALSE, invoked |-> FALSE], c2 |-> [tag |-> "none", count |-> 0, flag |-> FALSE, invoked |-> FALSE]],tres |-> [t1 |-> "none", t2 |-> "none", t3 |-> "none"],outerState |-> [c1 |-> "NA", c2 |-> "NA"],trunner |-> [t1 |-> "NoWorker", t2 |-> "NoWorker", t3 |-> "NoWorker"],outcome |-> [c1 |-> "None", c2 |-> "None"],ieAt |-> [c1 |-> 0, c2 |-> 0],bAdding |-> 0,tstate |-> [t1 |-> "NEW", t2 |-> "NEW", t3 |-> "NEW"],tqueued |-> [t1 |-> FALSE, t2 |-> FALSE, t3 |-> FALSE],wOuter |-> [w1 |-> "NoCaller", w2 |-> "NoCaller"],cbody |-> [c1 |-> "none", c2 |-> "none"],elapsedOver |-> [c1 |-> FALSE, c2 |-> FALSE],cancelAt |-> [c1 |-> -1, c2 |-> -1],made |-> [c1 |-> 1, c2 |-> 1],notified |-> [c1 |-> <<>>, c2 |-> <<>>],curExpired |-> [c1 |-> FALSE, c2 |-> FALSE],wpc |-> [w1 |-> "Assigned", w2 |-> "Assigned"],curQueued |-> [c1 |-> FALSE, c2 |-> FALSE],l |-> 5,curTag |-> [c1 |-> "none", c2 |-> "none"],tc |-> [w1 |-> 1, w2 |-> 1, b |-> 1, c1 |-> 3, c2 |-> 3, main |-> 1],sleepCls |-> [c1 |-> "none", c2 |-> "none"],attemptNo |-> [c1 |-> 1, c2 |-> 1],exShutdown |-> FALSE,towner |-> [t1 |-> "c1", t2 |-> "c2", t3 |-> "NoCaller"],intrSrc |-> [w1 |-> "NoTask", w2 |-> "NoTask"],curTask |-> [c1 |-> "t1", c2 |-> "t2"],queue |-> <<>>,wtask |-> [w1 |-> "t1", w2 |-> "t2"]]),
    ([tmode |-> [t1 |-> "none", t2 |-> "none", t3 |-> "none"],tbody |-> [t1 |-> "NotStarted", t2 |-> "NotStarted", t3 |-> "NotStarted"],itCursor |-> [c1 |-> 0, c2 |-> 0],intrDelivered |-> [c1 |-> FALSE, c2 |-> FALSE],itExpMod |-> [c1 |-> 0, c2 |-> 0],curInvoked |-> [c1 |-> FALSE, c2 |-> FALSE],bmod |-> 2,decided |-> [c1 |-> FALSE, c2 |-> FALSE],ttag |-> [t1 |-> "none", t2 |-> "none", t3 |-> "none"],intr |-> [w1 |-> FALSE, w2 |-> FALSE, c1 |-> FALSE, c2 |-> FALSE],cancelR |-> [c1 |-> "NoWorker", c2 |-> "NoWorker"],cpc |-> [c1 |-> "Wait", c2 |-> "Wait"],blist |-> <<1>>,exitInfo |-> [c1 |-> [tag |-> "none", count |-> 0, flag |-> FALSE, invoked |-> FALSE], c2 |-> [tag |-> "none", count |-> 0, flag |-> FALSE, invoked |-> FALSE]],tres |-> [t1 |-> "none", t2 |-> "none", t3 |-> "none"],outerState |-> [c1 |-> "NA", c2 |-> "NA"],trunner |-> [t1 |-> "NoWorker", t2 |-> "NoWorker", t3 |-> "NoWorker"],outcome |-> [c1 |-> "None", c2 |-> "None"],ieAt |-> [c1 |-> 0, c2 |-> 0],bAdding |-> 2,tstate |-> [t1 |-> "NEW", t2 |-> "NEW", t3 |-> "NEW"],tqueued |-> [t1 |-> FALSE, t2 |-> FALSE, t3 |-> FALSE],wOuter |-> [w1 |-> "NoCaller", w2 |-> "NoCaller"],cbody |-> [c1 |-> "none", c2 |-> "none"],elapsedOver |-> [c1 |-> FALSE, c2 |-> FALSE],cancelAt |-> [c1 |-> -1, c2 |-> -1],made |-> [c1 |-> 1, c2 |-> 1],notified |-> [c1 |-> <<>>, c2 |-> <<>>],curExpired |-> [c1 |-> FALSE, c2 |-> FALSE],wpc |-> [w1 |-> "Assigned", w2 |-> "Assigned"],curQueued |-> [c1 |-> FALSE, c2 |-> FALSE],l |-> 6,curTag |-> [c1 |-> "none", c2 |-> "none"],tc |-> [w1 |-> 1, w2 |-> 1, b |-> 2, c1 |-> 3, c2 |-> 3, main |-> 1],sleepCls |-> [c1 |-> "none", c2 |-> "none"],attemptNo |-> [c1 |-> 1, c2 |-> 1],exShutdown |-> FALSE,towner |-> [t1 |-> "c1", t2 |-> "c2", t3 |-> "NoCaller"],intrSrc |-> [w1 |-> "NoTask", w2 |-> "NoTask"],curTask |-> [c1 |-> "t1", c2 |-> "t2"],queue |-> <<>>,wtask |-> [w1 |-> "t1", w2 |-> "t2"]]),
    ([tmode |-> [t1 |-> "none", t2 |-> "none", t3 |-> "none"],tbody |-> [t1 |-> "NotStarted", t2 |-> "NotStarted", t3 |-> "NotStarted"],itCursor |-> [c1 |-> 0, c2 |-> 0],intrDelivered |-> [c1 |-> FALSE, c2 |-> FALSE],itExpMod |-> [c1 |-> 0, c2 |-> 0],curInvoked |-> [c1 |-> FALSE, c2 |-> FALSE],bmod |-> 2,decided |-> [c1 |-> FALSE, c2 |-> FALSE],ttag |-> [t1 |-> "none", t2 |-> "none", t3 |-> "none"],intr |-> [w1 |-> FALSE, w2 |-> FALSE, c1 |-> FALSE, c2 |-> FALSE],cancelR |-> [c1 |-> "NoWorker", c2 |-> "NoWorker"],cpc |-> [c1 |-> "Wait", c2 |-> "Wait"],blist |-> <<1>>,exitInfo |-> [c1 |-> [tag |-> "none", count |-> 0, flag |-> FALSE, invoked |-> FALSE], c2 |-> [tag |-> "none", count |-> 0, flag |-> FALSE, invoked |-> FALSE]],tres |-> [t1 |-> "none", t2 |-> "none", t3 |-> "none"],outerState |-> [c1 |-> "NA", c2 |-> "NA"],trunner |-> [t1 |-> "NoWorker", t2 |-> "NoWorker", t3 |-> "NoWorker"],outcome |-> [c1 |-> "None", c2 |-> "None"],ieAt |-> [c1 |-> 0, c2 |-> 0],bAdding |-> 2,tstate |-> [t1 |-> "NEW", t2 |-> "NEW", t3 |-> "NEW"],tqueued |-> [t1 |-> FALSE, t2 |-> FALSE, t3 |-> FALSE],wOuter |-> [w1 |-> "NoCaller", w2 |-> "NoCaller"],cbody |-> [c1 |-> "none", c2 |-> "none"],elapsedOver |-> [c1 |-> FALSE, c2 |-> FALSE],cancelAt |-> [c1 |-> -1, c2 |-> -1],made |-> [c1 |-> 1, c2 |-> 1],notified |-> [c1 |-> <<>>, c2 |-> <<>>],curExpired |-> [c1 |-> FALSE, c2 |-> FALSE],wpc |-> [w1 |-> "RunCAS", w2 |-> "Assigned"],curQueued |-> [c1 |-> FALSE, c2 |-> FALSE],l |-> 7,curTag |-> [c1 |-> "none", c2 |-> "none"],tc |-> [w1 |-> 2, w2 |-> 1, b |-> 2, c1 |-> 3, c2 |-> 3, main |-> 1],sleepCls |-> [c1 |-> "none", c2 |-> "none"],attemptNo |-> [c1 |-> 1, c2 |-> 1],exShutdown |-> FALSE,towner |-> [t1 |-> "c1", t2 |-> "c2", t3 |-> "NoCaller"],intrSrc |-> [w1 |-> "NoTask", w2 |-> "NoTask"],curTask |-> [c1 |-> "t1", c2 |-> "t2"],queue |-> <<>>,wtask |-> [w1 |-> "t1", w2 |-> "t2"]]),
    ([tmode |-> [t1 |-> "none", t2 |-> "none", t3 |-> "none"],tbody |-> [t1 |-> "NotStarted", t2 |-> "NotStarted", t3 |-> "NotStarted"],itCursor |-> [c1 |-> 0, c2 |-> 0],intrDelivered |-> [c1 |-> FALSE, c2 |-> FALSE],itExpMod |-> [c1 |-> 0, c2 |-> 0],curInvoked |-> [c1 |-> FALSE, c2 |-> FALSE],bmod |-> 2,decided |-> [c1 |-> FALSE, c2 |-> FALSE],ttag |-> [t1 |-> "none", t2 |-> "none", t3 |-> "none"],intr |-> [w1 |-> FALSE, w2 |-> FALSE, c1 |-> FALSE, c2 |-> FALSE],cancelR |-> [c1 |-> "NoWorker", c2 |-> "NoWorker"],cpc |-> [c1 |-> "Wait", c2 |-> "Wait"],blist |-> <<1, 2>>,exitInfo |-> [c1 |-> [tag |-> "none", count |-> 0, flag |-> FALSE, invoked |-> FALSE], c2 |-> [tag |-> "none", count |-> 0, flag |-> FALSE, invoked |-> FALSE]],tres |-> [t1 |-> "none", t2 |-> "none", t3 |-> "none"],outerState |-> [c1 |-> "NA", c2 |-> "NA"],trunner |-> [t1 |-> "NoWorker", t2 |-> "NoWorker", t3 |-> "NoWorker"],outcome |-> [c1 |-> "None", c2 |-> "None"],ieAt |-> [c1 |-> 0, c2 |-> 0],bAdding |-> 0,tstate |-> [t1 |-> "NEW", t2 |-> "NEW", t3 |-> "NEW"],tqueued |-> [t1 |-> FALSE, t2 |-> FALSE, t3 |-> FALSE],wOuter |-> [w1 |-> "NoCaller", w2 |-> "NoCaller"],cbody |-> [c1 |-> "none", c2 |-> "none"],elapsedOver |-> [c1 |-> FALSE, c2 |-> FALSE],cancelAt |-> [c1 |-> -1, c2 |-> -1],made |-> [c1 |-> 1, c2 |-> 1],notified |-> [c1 |-> <<>>, c2 |-> <<>>],curExpired |-> [c1 |-> FALSE, c2 |-> FALSE],wpc |-> [w1 |-> "RunCAS", w2 |-> "Assigned"],curQueued |-> [c1 |-> FALSE, c2 |-> FALSE],l |-> 8,curTag |-> [c1 |-> "none", c2 |-> "none"],tc |-> [w1 |-> 2, w2 |-> 1, b |-> 3, c1 |-> 3, c2 |-> 3, main |-> 1],sleepCls |-> [c1 |-> "none", c2 |-> "none"],attemptNo |-> [c1 |-> 1, c2 |-> 1],exShutdown |-> FALSE,towner |-> [t1 |-> "c1", t2 |-> "c2", t3 |-> "NoCaller"],intrSrc |-> [w1 |-> "NoTask", w2 |-> "NoTask"],curTask |-> [c1 |-> "t1", c2 |-> "t2"],queue |-> <<>>,wtask |-> [w1 |-> "t1", w2 |-> "t2"]]),
    ([tmode |-> [t1 |-> "none", t2 |-> "none", t3 |-> "none"],tbody |-> [t1 |-> "NotStarted", t2 |-> "NotStarted", t3 |-> "NotStarted"],itCursor |-> [c1 |-> 0, c2 |-> 0],intrDelivered |-> [c1 |-> FALSE, c2 |-> FALSE],itExpMod |-> [c1 |-> 0, c2 |-> 0],curInvoked |-> [c1 |-> FALSE, c2 |-> FALSE],bmod |-> 2,decided |-> [c1 |-> FALSE, c2 |-> FALSE],ttag |-> [t1 |-> "Timeout", t2 |-> "none", t3 |-> "none"],intr |-> [w1 |-> FALSE, w2 |-> FALSE, c1 |-> FALSE, c2 |-> FALSE],cancelR |-> [c1 |-> "NoWorker", c2 |-> "NoWorker"],cpc |-> [c1 |-> "CancelTO", c2 |-> "Wait"],blist |-> <<1, 2>>,exitInfo |-> [c1 |-> [tag |-> "none", count |-> 0, flag |-> FALSE, invoked |-> FALSE], c2 |-> [tag |-> "none", count |-> 0, flag |-> FALSE, invoked |-> FALSE]],tres |-> [t1 |-> "none", t2 |-> "none", t3 |-> "none"],outerState |-> [c1 |-> "NA", c2 |-> "NA"],trunner |-> [t1 |-> "NoWorker", t2 |-> "NoWorker", t3 |-> "NoWorker"],outcome |-> [c1 |-> "None", c2 |-> "None"],ieAt |-> [c1 |-> 0, c2 |-> 0],bAdding |-> 0,tstate |-> [t1 |-> "NEW", t2 |-> "NEW", t3 |-> "NEW"],tqueued |-> [t1 |-> FALSE, t2 |-> FALSE, t3 |-> FALSE],wOuter |-> [w1 |-> "NoCaller", w2 |-> "NoCaller"],cbody |-> [c1 |-> "none", c2 |-> "none"],elapsedOver |-> [c1 |-> FALSE, c2 |-> FALSE],cancelAt |-> [c1 |-> -1, c2 |-> -1],made |-> [c1 |-> 1, c2 |-> 1],notified |-> [c1 |-> <<>>, c2 |-> <<>>],curExpired |-> [c1 |-> FALSE, c2 |-> FALSE],wpc |-> [w1 |-> "RunCAS", w2 |-> "Assigned"],curQueued |-> [c1 |-> FALSE, c2 |-> FALSE],l |-> 9,curTag |-> [c1 |-> "Timeout", c2 |-> "none"],tc |-> [w1 |-> 2, w2 |-> 1, b |-> 3, c1 |-> 4, c2 |-> 3, main |-> 1],sleepCls |-> [c1 |-> "none", c2 |-> "none"],attemptNo |-> [c1 |-> 1, c2 |-> 1],exShutdown |-> FALSE,towner |-> [t1 |-> "c1", t2 |-> "c2", t3 |-> "NoCaller"],intrSrc |-> [w1 |-> "NoTask", w2 |-> "NoTask"],curTask |-> [c1 |-> "t1", c2 |-> "t2"],queue |-> <<>>,wtask |-> [w1 |-> "t1", w2 |-> "t2"]]),
    ([tmode |-> [t1 |-> "none", t2 |-> "none", t3 |-> "none"],tbody |-> [t1 |-> "NotStarted", t2 |-> "NotStarted", t3 |-> "NotStarted"],itCursor |-> [c1 |-> 0, c2 |-> 0],intrDelivered |-> [c1 |-> FALSE, c2 |-> FALSE],itExpMod |-> [c1 |-> 0, c2 |-> 0],curInvoked |-> [c1 |-> FALSE, c2 |-> FALSE],bmod |-> 2,decided |-> [c1 |-> FALSE, c2 |-> FALSE],ttag |-> [t1 |-> "Timeout", t2 |-> "none", t3 |-> "none"],intr |-> [w1 |-> FALSE, w2 |-> FALSE, c1 |-> FALSE, c2 |-> FALSE],cancelR |-> [c1 |-> "NoWorker", c2 |-> "NoWorker"],cpc |-> [c1 |-> "CancelTO", c2 |-> "Wait"],blist |-> <<1, 2>>,exitInfo |-> [c1 |-> [tag |-> "none", count |-> 0, flag |-> FALSE, invoked |-> FALSE], c2 |-> [tag |-> "none", count |-> 0, flag |-> FALSE, invoked |-> FALSE]],tres |-> [t1 |-> "none", t2 |-> "none", t3 |-> "none"],outerState |-> [c1 |-> "NA", c2 |-> "NA"],trunner |-> [t1 |-> "w1", t2 |-> "NoWorker", t3 |-> "NoWorker"],outcome |-> [c1 |-> "None", c2 |-> "None"],ieAt |-> [c1 |-> 0, c2 |-> 0],bAdding |-> 0,tstate |-> [t1 |-> "NEW", t2 |-> "NEW", t3 |-> "NEW"],tqueued |-> [t1 |-> FALSE, t2 |-> FALSE, t3 |-> FALSE],wOuter |-> [w1 |-> "NoCaller", w2 |-> "NoCaller"],cbody |-> [c1 |-> "none", c2 |-> "none"],elapsedOver |-> [c1 |-> FALSE, c2 |-> FALSE],cancelAt |-> [c1 |-> -1, c2 |-> -1],made |-> [c1 |-> 1, c2 |-> 1],notified |-> [c1 |-> <<>>, c2 |-> <<>>],curExpired |-> [c1 |-> FALSE, c2 |-> FALSE],wpc |-> [w1 |-> "InRun", w2 |-> "Assigned"],curQueued |-> [c1 |-> FALSE, c2 |-> FALSE],l |-> 10,curTag |-> [c1 |-> "Timeout", c2 |-> "none"],tc |-> [w1 |-> 3, w2 |-> 1, b |-> 3, c1 |-> 4, c2 |-> 3, main |-> 1],sleepCls |-> [c1 |-> "none", c2 |-> "none"],attemptNo |-> [c1 |-> 1, c2 |-> 1],exShutdown |-> FALSE,towner |-> [t1 |-> "c1", t2 |-> "c2", t3 |-> "NoCaller"],intrSrc |-> [w1 |-> "NoTask", w2 |-> "NoTask"],curTask |-> [c1 |-> "t1", c2 |-> "t2"],queue |-> <<>>,wtask |-> [w1 |-> "t1", w2 |-> "t2"]]),
    ([tmode |-> [t1 |-> "none", t2 |-> "none", t3 |-> "none"],tbody |-> [t1 |-> "NotStarted", t2 |-> "NotStarted", t3 |-> "NotStarted"],itCursor |-> [c1 |-> 0, c2 |-> 0],intrDelivered |-> [c1 |-> FALSE, c2 |-> FALSE],itExpMod |-> [c1 |-> 0, c2 |-> 0],curInvoked |-> [c1 |-> FALSE, c2 |-> FALSE],bmod |-> 2,decided |-> [c1 |-> FALSE, c2 |-> FALSE],ttag |-> [t1 |-> "Timeout", t2 |-> "none", t3 |-> "none"],intr |-> [w1 |-> FALSE, w2 |-> FALSE, c1 |-> FALSE, c2 |-> FALSE],cancelR |-> [c1 |-> "NoWorker", c2 |-> "NoWorker"],cpc |-> [c1 |-> "CancelRead", c2 |-> "Wait"],blist |-> <<1, 2>>,exitInfo |-> [c1 |-> [tag |-> "none", count |-> 0, flag |-> FALSE, invoked |-> FALSE], c2 |-> [tag |-> "none", count |-> 0, flag |-> FALSE, invoked |-> FALSE]],tres |-> [t1 |-> "none", t2 |-> "none", t3 |-> "none"],outerState |-> [c1 |-> "NA", c2 |-> "NA"],trunner |-> [t1 |-> "w1", t2 |-> "NoWorker", t3 |-> "NoWorker"],outcome |-> [c1 |-> "None", c2 |-> "None"],ieAt |-> [c1 |-> 0, c2 |-> 0],bAdding |-> 0,tstate |-> [t1 |-> "INTERRUPTING", t2 |-> "NEW", t3 |-> "NEW"],tqueued |-> [t1 |-> FALSE, t2 |-> FALSE, t3 |-> FALSE],wOuter |-> [w1 |-> "NoCaller", w2 |-> "NoCaller"],cbody |-> [c1 |-> "none", c2 |-> "none"],elapsedOver |-> [c1 |-> FALSE, c2 |-> FALSE],cancelAt |-> [c1 |-> -1, c2 |-> -1],made |-> [c1 |-> 1, c2 |-> 1],notified |-> [c1 |-> <<>>, c2 |-> <<>>],curExpired |-> [c1 |-> FALSE, c2 |-> FALSE],wpc |-> [w1 |-> "InRun", w2 |-> "Assigned"],curQueued |-> [c1 |-> FALSE, c2 |-> FALSE],l |-> 11,curTag |-> [c1 |-> "Timeout", c2 |-> "none"],tc |-> [w1 |-> 3, w2 |-> 1, b |-> 3, c1 |-> 5, c2 |-> 3, main |-> 1],sleepCls |-> [c1 |-> "none", c2 |-> "none"],attemptNo |-> [c1 |-> 1, c2 |-> 1],exShutdown |-> FALSE,towner |-> [t1 |-> "c1", t2 |-> "c2", t3 |-> "NoCaller"],intrSrc |-> [w1 |-> "NoTask", w2 |-> "NoTask"],curTask |-> [c1 |-> "t1", c2 |-> "t2"],queue |-> <<>>,wtask |-> [w1 |-> "t1", w2 |-> "t2"]]),
    ([tmode |-> [t1 |-> "none", t2 |-> "none", t3 |-> "none"],tbody |-> [t1 |-> "NotStarted", t2 |-> "NotStarted", t3 |-> "NotStarted"],itCursor |-> [c1 |-> 0, c2 |-> 0],intrDelivered |-> [c1 |-> FALSE, c2 |-> FALSE],itExpMod |-> [c1 |-> 0, c2 |-> 0],curInvoked |-> [c1 |-> FALSE, c2 |-> FALSE],bmod |-> 2,decided |-> [c1 |-> FALSE, c2 |-> FALSE],ttag |-> [t1 |-> "Timeout", t2 |-> "none", t3 |-> "none"],intr |-> [w1 |-> FALSE, w2 |-> FALSE, c1 |-> FALSE, c2 |-> FALSE],cancelR |-> [c1 |-> "w1", c2 |-> "NoWorker"],cpc |-> [c1 |-> "CancelIntr", c2 |-> "Wait"],blist |-> <<1, 2>>,exitInfo |-> [c1 |-> [tag |-> "none", count |-> 0, flag |-> FALSE, invoked |-> FALSE], c2 |-> [tag |-> "none", count |-> 0, flag |-> FALSE, invoked |-> FALSE]],tres |-> [t1 |-> "none", t2 |-> "none", t3 |-> "none"],outerState |-> [c1 |-> "NA", c2 |-> "NA"],trunner |-> [t1 |-> "w1", t2 |-> "NoWorker", t3 |-> "NoWorker"],outcome |-> [c1 |-> "None", c2 |-> "None"],ieAt |-> [c1 |-> 0, c2 |-> 0],bAdding |-> 0,tstate |-> [t1 |-> "INTERRUPTING", t2 |-> "NEW", t3 |-> "NEW"],tqueued |-> [t1 |-> FALSE, t2 |-> FALSE, t3 |-> FALSE],wOuter |-> [w1 |-> "NoCaller", w2 |-> "NoCaller"],cbody |-> [c1 |-> "none", c2 |-> "none"],elapsedOver |-> [c1 |-> FALSE, c2 |-> FALSE],cancelAt |-> [c1 |-> -1, c2 |-> -1],made |-> [c1 |-> 1, c2 |-> 1],notified |-> [c1 |-> <<>>, c2 |-> <<>>],curExpired |-> [c1 |-> FALSE, c2 |-> FALSE],wpc |-> [w1 |-> "InRun", w2 |-> "Assigned"],curQueued |-> [c1 |-> FALSE, c2 |-> FALSE],l |-> 12,curTag |-> [c1 |-> "Timeout", c2 |-> "none"],tc |-> [w1 |-> 3, w2 |-> 1, b |-> 3, c1 |-> 6, c2 |-> 3, main |-> 1],sleepCls |-> [c1 |-> "none", c2 |-> "none"],attemptNo |-> [c1 |-> 1, c2 |-> 1],exShutdown |-> FALSE,towner |-> [t1 |-> "c1", t2 |-> "c2", t3 |-> "NoCaller"],intrSrc |-> [w1 |-> "NoTask", w2 |-> "NoTask"],curTask |-> [c1 |-> "t1", c2 |-> "t2"],queue |-> <<>>,wtask |-> [w1 |-> "t1", w2 |-> "t2"]]),
    ([tmode |-> [t1 |-> "none", t2 |-> "none", t3 |-> "none"],tbody |-> [t1 |-> "NotStarted", t2 |-> "NotStarted", t3 |-> "NotStarted"],itCursor |-> [c1 |-> 0, c2 |-> 0],intrDelivered |-> [c1 |-> FALSE, c2 |-> FALSE],itExpMod |-> [c1 |-> 0, c2 |-> 0],curInvoked |-> [c1 |-> FALSE, c2 |-> FALSE],bmod |-> 2,decided |-> [c1 |-> FALSE, c2 |-> FALSE],ttag |-> [t1 |-> "Timeout", t2 |-> "none", t3 |-> "none"],intr |-> [w1 |-> TRUE, w2 |-> FALSE, c1 |-> FALSE, c2 |-> FALSE],cancelR |-> [c1 |-> "w1", c2 |-> "NoWorker"],cpc |-> [c1 |-> "CancelSet", c2 |-> "Wait"],blist |-> <<1, 2>>,exitInfo |-> [c1 |-> [tag |-> "none", count |-> 0, flag |-> FALSE, invoked |-> FALSE], c2 |-> [tag |-> "none", count |-> 0, flag |-> FALSE, invoked |-> FALSE]],tres |-> [t1 |-> "none", t2 |-> "none", t3 |-> "none"],outerState |-> [c1 |-> "NA", c2 |-> "NA"],trunner |-> [t1 |-> "w1", t2 |-> "NoWorker", t3 |-> "NoWorker"],outcome |-> [c1 |-> "None", c2 |-> "None"],ieAt |-> [c1 |-> 0, c2 |-> 0],bAdding |-> 0,tstate |-> [t1 |-> "INTERRUPTING", t2 |-> "NEW", t3 |-> "NEW"],tqueued |-> [t1 |-> FALSE, t2 |-> FALSE, t3 |-> FALSE],wOuter |-> [w1 |-> "NoCaller", w2 |-> "NoCaller"],cbody |-> [c1 |-> "none", c2 |-> "none"],elapsedOver |-> [c1 |-> FALSE, c2 |-> FALSE],cancelAt |-> [c1 |-> -1, c2 |-> -1],made |-> [c1 |-> 1, c2 |-> 1],notified |-> [c1 |-> <<>>, c2 |-> <<>>],curExpired |-> [c1 |-> FALSE, c2 |-> FALSE],wpc |-> [w1 |-> "InRun", w2 |-> "Assigned"],curQueued |-> [c1 |-> FALSE, c2 |-> FALSE],l |-> 13,curTag |-> [c1 |-> "Timeout", c2 |-> "none"],tc |-> [w1 |-> 3, w2 |-> 1, b |-> 3, c1 |-> 7, c2 |-> 3, main |-> 1],sleepCls |-> [c1 |-> "none", c2 |-> "none"],attemptNo |-> [c1 |-> 1, c2 |-> 1],exShutdown |-> FALSE,towner |-> [t1 |-> "c1", t2 |-> "c2", t3 |-> "NoCaller"],intrSrc |-> [w1 |-> "t1", w2 |-> "NoTask"],curTask |-> [c1 |-> "t1", c2 |-> "t2"],queue |-> <<>>,wtask |-> [w1 |-> "t1", w2 |-> "t2"]]),
    ([tmode |-> [t1 |-> "none", t2 |-> "none", t3 |-> "none"],tbody |-> [t1 |-> "NotStarted", t2 |-> "NotStarted", t3 |-> "NotStarted"],itCursor |-> [c1 |-> 0, c2 |-> 0],intrDelivered |-> [c1 |-> FALSE, c2 |-> FALSE],itExpMod |-> [c1 |-> 0, c2 |-> 0],curInvoked |-> [c1 |-> FALSE, c2 |-> FALSE],bmod |-> 2,decided |-> [c1 |-> FALSE, c2 |-> FALSE],ttag |-> [t1 |-> "Timeout", t2 |-> "none", t3 |-> "none"],intr |-> [w1 |-> TRUE, w2 |-> FALSE, c1 |-> FALSE, c2 |-> FALSE],cancelR |-> [c1 |-> "NoWorker", c2 |-> "NoWorker"],cpc |-> [c1 |-> "Classified", c2 |-> "Wait"],blist |-> <<1, 2>>,exitInfo |-> [c1 |-> [tag |-> "none", count |-> 0, flag |-> FALSE, invoked |-> FALSE], c2 |-> [tag |-> "none", count |-> 0, flag |-> FALSE, invoked |-> FALSE]],tres |-> [t1 |-> "none", t2 |-> "none", t3 |-> "none"],outerState |-> [c1 |-> "NA", c2 |-> "NA"],trunner |-> [t1 |-> "w1", t2 |-> "NoWorker", t3 |-> "NoWorker"],outcome |-> [c1 |-> "None", c2 |-> "None"],ieAt |-> [c1 |-> 0, c2 |-> 0],bAdding |-> 0,tstate |-> [t1 |-> "INTERRUPTED", t2 |-> "NEW", t3 |-> "NEW"],tqueued |-> [t1 |-> FALSE, t2 |-> FALSE, t3 |-> FALSE],wOuter |-> [w1 |-> "NoCaller", w2 |-> "NoCaller"],cbody |-> [c1 |-> "none", c2 |-> "none"],elapsedOver |-> [c1 |-> FALSE, c2 |-> FALSE],cancelAt |-> [c1 |-> -1, c2 |-> -1],made |-> [c1 |-> 1, c2 |-> 1],notified |-> [c1 |-> <<>>, c2 |-> <<>>],curExpired |-> [c1 |-> FALSE, c2 |-> FALSE],wpc |-> [w1 |-> "InRun", w2 |-> "Assigned"],curQueued |-> [c1 |-> FALSE, c2 |-> FALSE],l |-> 14,curTag |-> [c1 |-> "Timeout", c2 |-> "none"],tc |-> [w1 |-> 3, w2 |-> 1, b |-> 3, c1 |-> 8, c2 |-> 3, main |-> 1],sleepCls |-> [c1 |-> "none", c2 |-> "none"],attemptNo |-> [c1 |-> 1, c2 |-> 1],exShutdown |-> FALSE,towner |-> [t1 |-> "c1", t2 |-> "c2", t3 |-> "NoCaller"],intrSrc |-> [w1 |-> "t1", w2 |-> "NoTask"],curTask |-> [c1 |-> "NoTask", c2 |-> "t2"],queue |-> <<>>,wtask |-> [w1 |-> "t1", w2 |-> "t2"]]),
    ([tmode |-> [t1 |-> "none", t2 |-> "none", t3 |-> "none"],tbody |-> [t1 |-> "NotStarted", t2 |-> "NotStarted", t3 |-> "NotStarted"],itCursor |-> [c1 |-> 0, c2 |-> 0],intrDelivered |-> [c1 |-> FALSE, c2 |-> FALSE],itExpMod |-> [c1 |-> 0, c2 |-> 0],curInvoked |-> [c1 |-> FALSE, c2 |-> FALSE],bmod |-> 2,decided |-> [c1 |-> FALSE, c2 |-> FALSE],ttag |-> [t1 |-> "Timeout", t2 |-> "none", t3 |-> "none"],intr |-> [w1 |-> TRUE, w2 |-> FALSE, c1 |-> FALSE, c2 |-> FALSE],cancelR |-> [c1 |-> "NoWorker", c2 |-> "NoWorker"],cpc |-> [c1 |-> "Classified", c2 |-> "Wait"],blist |-> <<1, 2>>,exitInfo |-> [c1 |-> [tag |-> "none", count |-> 0, flag |-> FALSE, invoked |-> FALSE], c2 |-> [tag |-> "none", count |-> 0, flag |-> FALSE, invoked |-> FALSE]],tres |-> [t1 |-> "none", t2 |-> "none", t3 |-> "none"],outerState |-> [c1 |-> "NA", c2 |-> "NA"],trunner |-> [t1 |-> "NoWorker", t2 |-> "NoWorker", t3 |-> "NoWorker"],outcome |-> [c1 |-> "None", c2 |-> "None"],ieAt |-> [c1 |-> 0, c2 |-> 0],bAdding |-> 0,tstate |-> [t1 |-> "INTERRUPTED", t2 |-> "NEW", t3 |-> "NEW"],tqueued |-> [t1 |-> FALSE, t2 |-> FALSE, t3 |-> FALSE],wOuter |-> [w1 |-> "NoCaller", w2 |-> "NoCaller"],cbody |-> [c1 |-> "none", c2 |-> "none"],elapsedOver |-> [c1 |-> FALSE, c2 |-> FALSE],cancelAt |-> [c1 |-> -1, c2 |-> -1],made |-> [c1 |-> 1, c2 |-> 1],notified |-> [c1 |-> <<>>, c2 |-> <<>>],curExpired |-> [c1 |-> FALSE, c2 |-> FALSE],wpc |-> [w1 |-> "Finally", w2 |-> "Assigned"],curQueued |-> [c1 |-> FALSE, c2 |-> FALSE],l |-> 15,curTag |-> [c1 |-> "Timeout", c2 |-> "none"],tc |-> [w1 |-> 4, w2 |-> 1, b |-> 3, c1 |-> 8, c2 |-> 3, main |-> 1],sleepCls |-> [c1 |-> "none", c2 |-> "none"],attemptNo |-> [c1 |-> 1, c2 |-> 1],exShutdown |-> FALSE,towner |-> [t1 |-> "c1", t2 |-> "c2", t3 |-> "NoCaller"],intrSrc |-> [w1 |-> "t1", w2 |-> "NoTask"],curTask |-> [c1 |-> "NoTask", c2 |-> "t2"],queue |-> <<>>,wtask |-> [w1 |-> "t1", w2 |-> "t2"]]),
    ([tmode |-> [t1 |-> "none", t2 |-> "none", t3 |-> "none"],tbody |-> [t1 |-> "NotStarted", t2 |-> "NotStarted", t3 |-> "NotStarted"],itCursor |-> [c1 |-> 0, c2 |-> 0],intrDelivered |-> [c1 |-> FALSE, c2 |-> FALSE],itExpMod |-> [c1 |-> 0, c2 |-> 0],curInvoked |-> [c1 |-> FALSE, c2 |-> FALSE],bmod |-> 2,decided |-> [c1 |-> FALSE, c2 |-> FALSE],ttag |-> [t1 |-> "Timeout", t2 |-> "none", t3 |-> "none"],intr |-> [w1 |-> TRUE, w2 |-> FALSE, c1 |-> FALSE, c2 |-> FALSE],cancelR |-> [c1 |-> "NoWorker", c2 |-> "NoWorker"],cpc |-> [c1 |-> "Classified", c2 |-> "Wait"],blist |-> <<1, 2>>,exitInfo |-> [c1 |-> [tag |-> "none", count |-> 0, flag |-> FALSE, invoked |-> FALSE], c2 |-> [tag |-> "none", count |-> 0, flag |-> FALSE, invoked |-> FALSE]],tres |-> [t1 |-> "none", t2 |-> "none", t3 |-> "none"],outerState |-> [c1 |-> "NA", c2 |-> "NA"],trunner |-> [t1 |-> "NoWorker", t2 |-> "NoWorker", t3 |-> "NoWorker"],outcome |-> [c1 |-> "None", c2 |-> "None"],ieAt |-> [c1 |-> 0, c2 |-> 0],bAdding |-> 0,tstate |-> [t1 |-> "INTERRUPTED", t2 |-> "NEW", t3 |-> "NEW"],tqueued |-> [t1 |-> FALSE, t2 |-> FALSE, t3 |-> FALSE],wOuter |-> [w1 |-> "NoCaller", w2 |-> "NoCaller"],cbody |-> [c1 |-> "none", c2 |-> "none"],elapsedOver |-> [c1 |-> FALSE, c2 |-> FALSE],cancelAt |-> [c1 |-> -1, c2 |-> -1],made |-> [c1 |-> 1, c2 |-> 1],notified |-> [c1 |-> <<>>, c2 |-> <<>>],curExpired |-> [c1 |-> FALSE, c2 |-> FALSE],wpc |-> [w1 |-> "GetTask", w2 |-> "Assigned"],curQueued |-> [c1 |-> FALSE, c2 |-> FALSE],l |-> 16,curTag |-> [c1 |-> "Timeout", c2 |-> "none"],tc |-> [w1 |-> 5, w2 |-> 1, b |-> 3, c1 |-> 8, c2 |-> 3, main |-> 1],sleepCls |-> [c1 |-> "none", c2 |-> "none"],attemptNo |-> [c1 |-> 1, c2 |-> 1],exShutdown |-> FALSE,towner |-> [t1 |-> "c1", t2 |-> "c2", t3 |-> "NoCaller"],intrSrc |-> [w1 |-> "t1", w2 |-> "NoTask"],curTask |-> [c1 |-> "NoTask", c2 |-> "t2"],queue |-> <<>>,wtask |-> [w1 |-> "NoTask", w2 |-> "t2"]]),
    ([tmode |-> [t1 |-> "none", t2 |-> "none", t3 |-> "none"],tbody |-> [t1 |-> "NotStarted", t2 |-> "NotStarted", t3 |-> "NotStarted"],itCursor |-> [c1 |-> 0, c2 |-> 0],intrDelivered |-> [c1 |-> FALSE, c2 |-> FALSE],itExpMod |-> [c1 |-> 0, c2 |-> 0],curInvoked |-> [c1 |-> FALSE, c2 |-> FALSE],bmod |-> 2,decided |-> [c1 |-> FALSE, c2 |-> FALSE],ttag |-> [t1 |-> "Timeout", t2 |-> "none", t3 |-> "none"],intr |-> [w1 |-> TRUE, w2 |-> FALSE, c1 |-> FALSE, c2 |-> FALSE],cancelR |-> [c1 |-> "NoWorker", c2 |-> "NoWorker"],cpc |-> [c1 |-> "Classified", c2 |-> "Wait"],blist |-> <<1, 2>>,exitInfo |-> [c1 |-> [tag |-> "none", count |-> 0, flag |-> FALSE, invoked |-> FALSE], c2 |-> [tag |-> "none", count |-> 0, flag |-> FALSE, invoked |-> FALSE]],tres |-> [t1 |-> "none", t2 |-> "none", t3 |-> "none"],outerState |-> [c1 |-> "NA", c2 |-> "NA"],trunner |-> [t1 |-> "NoWorker", t2 |-> "NoWorker", t3 |-> "NoWorker"],outcome |-> [c1 |-> "None", c2 |-> "None"],ieAt |-> [c1 |-> 0, c2 |-> 0],bAdding |-> 0,tstate |-> [t1 |-> "INTERRUPTED", t2 |-> "NEW", t3 |-> "NEW"],tqueued |-> [t1 |-> FALSE, t2 |-> FALSE, t3 |-> FALSE],wOuter |-> [w1 |-> "NoCaller", w2 |-> "NoCaller"],cbody |-> [c1 |-> "none", c2 |-> "none"],elapsedOver |-> [c1 |-> FALSE, c2 |-> FALSE],cancelAt |-> [c1 |-> -1, c2 |-> -1],made |-> [c1 |-> 1, c2 |-> 1],notified |-> [c1 |-> <<>>, c2 |-> <<>>],curExpired |-> [c1 |-> FALSE, c2 |-> FALSE],wpc |-> [w1 |-> "Idle", w2 |-> "Assigned"],curQueued |-> [c1 |-> FALSE, c2 |-> FALSE],l |-> 17,curTag |-> [c1 |-> "Timeout", c2 |-> "none"],tc |-> [w1 |-> 6, w2 |-> 1, b |-> 3, c1 |-> 8, c2 |-> 3, main |-> 1],sleepCls |-> [c1 |-> "none", c2 |-> "none"],attemptNo |-> [c1 |-> 1, c2 |-> 1],exShutdown |-> FALSE,towner |-> [t1 |-> "c1", t2 |-> "c2", t3 |-> "NoCaller"],intrSrc |-> [w1 |-> "t1", w2 |-> "NoTask"],curTask |-> [c1 |-> "NoTask", c2 |-> "t2"],queue |-> <<>>,wtask |-> [w1 |-> "NoTask", w2 |-> "t2"]])
    >>
----


=============================================================================

---- CONFIG Trace_TTrace_1795679760 ----
CONSTANTS
    Callers <- TraceCallers
    Workers <- TraceWorkers
    TaskIds <- TraceTaskIds
    NumInitListeners <- TraceNumInitListeners
    NumExtraListeners <- TraceNumExtraListeners
    Limiter <- TraceLimiter
    ExecKind <- TraceExecKind
    PoolSize <- TracePoolSize
    QueueCap <- TraceQueueCap
    RetryOn <- TraceRetryOn
    StopKind <- TraceStopKind
    StopAfter <- TraceStopAfter
    SleepClasses <- TraceSleepClasses
    Modes <- TraceModes
    WrapCallers <- TraceWrapCallers
    WrapOnLimiterPool <- TraceWrapOnLimiterPool
    NoTask = "NoTask"
    NoWorker = "NoWorker"
    NoCaller = "NoCaller"

PROPERTY
    _prop

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
\* Generated on Thu Nov 26 07:56:05 UTC 2026