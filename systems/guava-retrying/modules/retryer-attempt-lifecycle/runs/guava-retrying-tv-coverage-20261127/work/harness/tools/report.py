#!/usr/bin/env python3
"""Summarize the traces in a directory: per workload counts and event coverage.

Usage: report.py TRACES_DIR [SUMMARY_DIR]
"""
import collections
import glob
import json
import os
import re
import statistics
import sys

# base.tla actions with a trace event (instrumentation-spec.md section 2);
# DelayElapses is silent by design.
ACTIONS = """CallStart CallerBodyStart CallerBodyReturns CallerBodyThrows SubmitRejected
SubmitHandoff SubmitNewWorker SubmitQueued GetReturn GetInterrupted GetTimeout CancelCASWon
CancelCASLost CancelReadRunner CancelDoInterrupt CancelFinish ListenersBegin ListenerNotify
ListenerCME ListenersEnd PredicateAccepts StopStrategyStops WaitStrategyComputes BlockNegative
BlockInterrupted BlockZero BlockSleepStart SleepReturns SleepInterrupted WorkerPollBlock
WorkerTake WorkerRunTaskSkip WorkerRunTaskStart WorkerRunnerCAS BodyStart BodySkip BodyReturns
BodyThrows SetCASWon SetCASLost SetFinish RunFinallySpin RunFinallyExit SpinExit WorkerExit
OuterWorkerRelease Interrupt CancelOuter AddListenerBegin AddListenerEnd ExecutorShutdown""".split()


def main():
    tdir = sys.argv[1]
    sdir = sys.argv[2] if len(sys.argv) > 2 else tdir
    files = sorted(f for f in glob.glob(os.path.join(tdir, "*.ndjson"))
                   if re.search(r"-\d+\.ndjson$", f))
    per = collections.OrderedDict()
    cover = collections.Counter()
    total_events = 0
    for f in files:
        wl = re.sub(r"-\d+\.ndjson$", "", os.path.basename(f))
        cfg, evs = None, []
        for line in open(f):
            d = json.loads(line)
            if d.get("tag") == "config":
                cfg = d
            elif d.get("tag") == "trace":
                evs.append(d)
        st = per.setdefault(wl, {"traces": 0, "prefix": 0, "events": [], "switches": [], "threads": []})
        st["traces"] += 1
        st["prefix"] += 1 if cfg and cfg.get("prefix") else 0
        st["events"].append(len(evs))
        st["switches"].append(sum(1 for a, b in zip(evs, evs[1:]) if a["tid"] != b["tid"]))
        st["threads"].append(len({e["tid"] for e in evs}))
        total_events += len(evs)
        for name in {e["event"] for e in evs}:
            cover[name] += 1
    print("%-24s %6s %6s %18s %16s %8s %s" % ("workload", "traces", "prefix", "events min/med/max",
                                              "thread switches", "threads", "paths (JPF)"))
    for wl, st in per.items():
        summ = os.path.join(sdir, wl + ".summary.json")
        paths = json.load(open(summ))["paths"] if os.path.exists(summ) else "?"
        ev = st["events"]
        sw = st["switches"]
        print("%-24s %6d %6d %18s %16s %8s %s" % (
            wl, st["traces"], st["prefix"],
            "%d/%d/%d" % (min(ev), statistics.median(ev), max(ev)),
            "%d/%d/%d" % (min(sw), statistics.median(sw), max(sw)),
            "%d-%d" % (min(st["threads"]), max(st["threads"])), paths))
    print("TOTAL: %d traces, %d events" % (len(files), total_events))
    print("")
    print("event coverage (number of traces containing the event):")
    missing = [a for a in ACTIONS if cover[a] == 0]
    row = []
    for a in ACTIONS:
        row.append("%s=%d" % (a, cover[a]))
    for i in range(0, len(row), 6):
        print("  " + "  ".join(row[i:i + 6]))
    unknown = sorted(set(cover) - set(ACTIONS))
    if unknown:
        print("UNKNOWN event names: %s" % unknown)
    print("never observed: %s" % (", ".join(missing) if missing else "none"))


if __name__ == "__main__":
    main()
