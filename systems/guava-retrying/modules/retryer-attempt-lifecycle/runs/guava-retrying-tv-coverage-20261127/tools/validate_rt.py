#!/usr/bin/env python3
"""Existence check for interval traces: PASS iff TLC finds TraceNotFullyConsumed
violated (some interleaving consumes every event) and no other invariant fails.
Usage: validate_rt.py SPEC_DIR TRACE..."""
import os, re, subprocess, sys, tempfile
from concurrent.futures import ThreadPoolExecutor
LIB = os.environ["SPECULAR_LIB"]
spec = os.path.abspath(sys.argv[1])
def one(t):
    t = os.path.abspath(t)
    meta = tempfile.mkdtemp(prefix="rtmeta-", dir=os.environ.get("TMPDIR"))
    cmd = ["java", "-XX:+UseParallelGC", "-Xmx2G", "-cp", f"{LIB}/tla2tools.jar:{LIB}/CommunityModules-deps.jar",
           "tlc2.TLC", "-config", "Trace_rt.cfg", "Trace.tla", "-metadir", meta, "-workers", "1", "-nowarning", "-noGenerateSpecTE"]
    try:
        out = subprocess.run(cmd, cwd=spec, env=dict(os.environ, JSON=t), stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=900).stdout
    finally:
        subprocess.run(["rm", "-rf", meta])
    m = re.search(r"Invariant (\w+) is violated", out)
    if m and m.group(1) == "TraceNotFullyConsumed":
        return "PASS", t, ""
    if m:
        return "INVFAIL", t, m.group(1)
    if "No error has been found" in out:
        ls = [int(x) for x in re.findall(r"/\\ l = (\d+)", out)]
        return "MISMATCH", t, "no interleaving consumes the trace"
    return "ERROR", t, out[-600:]
with ThreadPoolExecutor(int(os.environ.get("JOBS", "16"))) as ex:
    res = list(ex.map(one, sys.argv[2:]))
for r, t, why in res:
    print(f"{r:9s} {os.path.basename(t)} {why}")
print(f"SUMMARY: {len(res)} traces, {sum(r=='PASS' for r,_,_ in res)} pass")
