#!/usr/bin/env python3
"""Strict TV coverage for guava-retrying (TV high-coverage experiment rules).

Usage: cov.py VALIDATION_TXT TRACE... [--rt RT_TRACE...]

Counts, over the traces that PASS in VALIDATION_TXT, which base.tla actions were
observed with a real post-state check.  Denominator = code-mapped actions
(base.tla actions minus DelayElapses, which is wall-clock time).
Strict rules:
  * WorkerPollCancel only counts if an explicit WorkerPollCancel event exists
    (the SilentPollCancel step infers it; inferred = 0).
  * Block*/Sleep* events recorded under JPF are observed inside the harness's
    own Thread.sleep model (jpf-core patch 0003) -> count 0; they count only
    from real-HotSpot traces (--rt).
  * Interrupt / CancelOuter / ExecutorShutdown count only when the event carries
    a read-back of the state they write (fields targetIntr / outerState /
    idleIntr) - the original recorder emits none.
Also prints per-action branch values (state/kind/mode/sleep/outcome fields).
"""
import collections
import json
import os
import sys

ACTIONS = """CallStart CallerBodyStart CallerBodyReturns CallerBodyThrows SubmitRejected
SubmitHandoff SubmitNewWorker SubmitQueued GetReturn GetInterrupted GetTimeout CancelCASWon
CancelCASLost CancelReadRunner CancelDoInterrupt CancelFinish ListenersBegin ListenerNotify
ListenerCME ListenersEnd PredicateAccepts StopStrategyStops WaitStrategyComputes BlockNegative
BlockInterrupted BlockZero BlockSleepStart SleepReturns SleepInterrupted
WorkerUnlock WorkerPollBlock WorkerPollCancel WorkerTake WorkerRunTaskSkip WorkerRunTaskStart WorkerRunnerCAS
BodyStart BodySkip BodyReturns BodyThrows SetCASWon SetCASLost SetFinish RunFinallySpin
RunFinallyExit SpinExit WorkerExit OuterWorkerRelease
Interrupt CancelOuter AddListenerBegin AddListenerEnd ExecutorShutdown""".split()
SLEEP_MODEL = {"BlockNegative", "BlockInterrupted", "BlockZero", "BlockSleepStart",
               "SleepReturns", "SleepInterrupted"}
READBACK = {"Interrupt": "targetIntr", "CancelOuter": "outerState", "ExecutorShutdown": "idleIntr", "CancelDoInterrupt": "targetIntr"}
BRANCH_FIELDS = ["state", "attemptKind", "mode", "sleep", "outcome", "expired", "result", "intr"]


def load(path):
    ev = []
    for line in open(path):
        line = line.strip()
        if not line:
            continue
        x = json.loads(line)
        if x.get("tag") == "trace":
            ev.append(x)
    return ev


def main(argv):
    rt = []
    if "--rt" in argv:
        i = argv.index("--rt")
        rt = argv[i + 1:]
        argv = argv[:i]
    val, traces = argv[0], argv[1:]
    passed = set()
    for line in open(val):
        p = line.split()
        if len(p) >= 2 and p[0] == "PASS":
            passed.add(os.path.basename(p[1]))
    seen = collections.Counter()      # real, checked observations
    raw = collections.Counter()       # any occurrence in passing traces
    branches = collections.defaultdict(collections.Counter)
    files = collections.defaultdict(set)
    for src, lst in (("jpf", traces), ("rt", rt)):
        for t in lst:
            if os.path.basename(t) not in passed:
                continue
            for e in load(t):
                a = e["event"]
                raw[a] += 1
                files[a].add(os.path.basename(t))
                ok = True
                if a in SLEEP_MODEL and src == "jpf":
                    ok = False
                if a in READBACK and READBACK[a] not in e:
                    ok = False
                if ok:
                    seen[a] += 1
                key = tuple((f, json.dumps(e[f])) for f in BRANCH_FIELDS if f in e and f != "intr")
                branches[a][(src,) + key] += 1
    cov = [a for a in ACTIONS if seen[a] > 0]
    print(f"traces passing: {len(passed)}; real coverage {len(cov)}/{len(ACTIONS)} = {100*len(cov)/len(ACTIONS):.1f}%")
    for a in ACTIONS:
        why = ""
        if seen[a] == 0:
            if raw[a] == 0:
                why = "never observed" + (" (inferred by SilentPollCancel)" if a == "WorkerPollCancel" else "")
            elif a in SLEEP_MODEL:
                why = "only inside the JPF Thread.sleep model (patch 0003)"
            elif a in READBACK:
                why = f"no read-back of written state ({READBACK[a]})"
        print(f"  {'Y' if seen[a] else '-'} {a:22s} occ={raw[a]:5d} files={len(files[a]):4d} {why}")
    if "--branches" in os.environ.get("COV_OPTS", ""):
        for a in ACTIONS:
            if branches[a]:
                print(f"\n[{a}]")
                for k, n in sorted(branches[a].items(), key=lambda kv: -kv[1]):
                    print(f"   {n:6d} {k}")


if __name__ == "__main__":
    main(sys.argv[1:])
