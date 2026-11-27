#!/usr/bin/env python3
"""Replay NDJSON traces through spec/Trace.tla with TLC (one TLC run per trace).

Usage: validate_traces.py [--jobs N] [--timeout S] TRACE...

Reports, per trace, PASS or the first event Trace.tla could not match (the
trace line, counting events from 1, and its content). Exit status 0 iff all pass.
Environment: SPECULAR_LIB (dir with tla2tools.jar and CommunityModules-deps.jar),
JAVA (java executable; default 'java').
"""
import argparse
import json
import os
import re
import subprocess
import sys
import tempfile
from concurrent.futures import ThreadPoolExecutor

HERE = os.path.dirname(os.path.abspath(__file__))
SPEC_DIR = os.path.normpath(os.path.join(HERE, "..", "..", "spec"))
DEFAULT_LIB = os.path.normpath(os.path.join(HERE, "..", "..", "..", "..", "..", "..", "lib"))


def known_gap(events, k):
    """Label a replay failure at event k (1-based) that matches a known
    base.tla gap (see harness/INSTRUMENTATION.md, "Known spec gaps")."""
    if not 0 < k <= len(events):
        return ""
    ev = events[k - 1]
    prior = [e for e in events[:k - 1] if e["tid"] == ev["tid"]]
    if ev["event"] == "WorkerPollBlock":
        if any(e["event"] == "ExecutorShutdown" for e in events[:k - 1]):
            return "GAP-2 (poll node pushed after shutdown)"
        if prior and prior[-1]["event"] == "WorkerPollBlock" and prior[-1].get("intr") is True:
            return "GAP-1 (stale cancel interrupt consumed by SynchronousQueue.poll)"
    if ev["event"] == "WorkerTake" and ev.get("intr") is False and prior and prior[-1].get("intr") is True:
        return "GAP-1 (stale cancel interrupt consumed by the work queue's take)"
    return ""


def run_one(trace, lib, java, timeout, metaroot):
    trace = os.path.abspath(trace)
    meta = tempfile.mkdtemp(prefix="meta-", dir=metaroot)
    cmd = [java, "-XX:+UseParallelGC", "-Xmx2G", "-cp",
           os.path.join(lib, "tla2tools.jar") + ":" + os.path.join(lib, "CommunityModules-deps.jar"),
           "tlc2.TLC", "-config", "Trace.cfg", "Trace.tla", "-lncheck", "final",
           "-metadir", meta, "-workers", "1", "-nowarning", "-noGenerateSpecTE"]
    env = dict(os.environ, JSON=trace)
    try:
        out = subprocess.run(cmd, cwd=SPEC_DIR, env=env, stdout=subprocess.PIPE,
                             stderr=subprocess.STDOUT, timeout=timeout, text=True).stdout
    except subprocess.TimeoutExpired:
        return trace, "TIMEOUT", ""
    finally:
        subprocess.run(["rm", "-rf", meta])
    if "Model checking completed. No error has been found." in out:
        return trace, "PASS", ""
    if re.search(r"Temporal propert(y \w+ was|ies were) violated", out) or re.search(r"Invariant \w+ is violated", out):
        ls = [int(x) for x in re.findall(r"/\\ l = (\d+)", out)]
        inv = re.search(r"Invariant (\w+) is violated", out)
        events = [json.loads(x) for x in open(trace) if '"tag":"trace"' in x]
        if inv:
            k = max(ls) - 1 if ls else 0
            return trace, "INVARIANT", "%s violated after event %d: %s" % (
                inv.group(1), k, json.dumps(events[k - 1]) if 0 < k <= len(events) else "?")
        k = max(ls) if ls else 1
        ev = events[k - 1] if 0 < k <= len(events) else None
        gap = known_gap(events, k)
        return trace, "MISMATCH", "stuck before event %d of %d%s: %s" % (
            k, len(events), (" [" + gap + "]") if gap else "", json.dumps(ev))
    tail = "\n".join(out.strip().splitlines()[-15:])
    return trace, "ERROR", tail


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--jobs", type=int, default=max(1, min(8, (os.cpu_count() or 2) // 2)))
    ap.add_argument("--timeout", type=int, default=600)
    ap.add_argument("traces", nargs="+")
    a = ap.parse_args()
    lib = os.environ.get("SPECULAR_LIB", DEFAULT_LIB)
    java = os.environ.get("JAVA", "java")
    metaroot = os.path.join(HERE, "..", "build", "tlc-meta")
    os.makedirs(metaroot, exist_ok=True)
    results = []
    with ThreadPoolExecutor(a.jobs) as ex:
        for r in ex.map(lambda t: run_one(t, lib, java, a.timeout, metaroot), a.traces):
            results.append(r)
            name = os.path.basename(r[0])
            print("%-9s %s%s" % (r[1], name, ("  " + r[2]) if r[2] else ""), flush=True)
    bad = [r for r in results if r[1] != "PASS"]
    gaps = [r for r in bad if "[GAP-" in r[2]]
    print("SUMMARY: %d traces, %d pass, %d fail (%d at a known spec gap, %d other)" % (
        len(results), len(results) - len(bad), len(bad), len(gaps), len(bad) - len(gaps)))
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
