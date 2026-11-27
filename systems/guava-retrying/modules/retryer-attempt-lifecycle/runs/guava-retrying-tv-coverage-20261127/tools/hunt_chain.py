#!/usr/bin/env python3
"""Hunt chain on one spec dir: for each cfg, run TLC (BFS); on a violation,
disable that invariant/property and continue, until no violation, no
properties left, or the per-cfg budget (default 1800 s) is used up.
Usage: hunt_chain.py SPEC_DIR OUT_DIR CFG... ; env SPECULAR_LIB, TMPDIR, BUDGET, WORKERS
Writes OUT_DIR/<cfg>.chain.txt and prints one summary line per cfg."""
import os, re, subprocess, sys, time

LIB = os.environ["SPECULAR_LIB"]
BUDGET = int(os.environ.get("BUDGET", "1800"))
WORKERS = os.environ.get("WORKERS", "8")
spec, out = os.path.abspath(sys.argv[1]), os.path.abspath(sys.argv[2])
os.makedirs(out, exist_ok=True)


def module_of(cfg_text):
    return "MCHunt.tla" if "MCHunt" in cfg_text else "MC.tla"


def disable(text, name):
    lines = text.split("\n")
    res = []
    for ln in lines:
        s = ln.strip()
        if s == name or s in (f"INVARIANT {name}", f"PROPERTY {name}", f"PROPERTIES {name}", f"INVARIANTS {name}"):
            res.append("\\* hunt_chain disabled: " + ln)
        else:
            res.append(ln)
    return "\n".join(res)


def run(cfg):
    base = os.path.basename(cfg)
    text = open(os.path.join(spec, cfg)).read()
    mod = "MC.tla" if "MCHunt" not in base else "MCHunt.tla"
    t0 = time.time()
    chain = []
    i = 0
    log = open(os.path.join(out, base + ".chain.txt"), "w")
    while True:
        i += 1
        left = BUDGET - (time.time() - t0)
        if left < 20:
            chain.append("BUDGET")
            break
        tmpcfg = os.path.join(spec, f".hc_{base}_{i}.cfg")
        open(tmpcfg, "w").write(text)
        meta = os.path.join(os.environ["TMPDIR"], f"hcmeta_{os.path.basename(spec)}_{base}_{i}")
        cmd = ["timeout", str(int(left)), "java", "-XX:+UseParallelGC", "-Xmx" + os.environ.get("XMX", "8g"), "-cp",
               f"{LIB}/tla2tools.jar:{LIB}/CommunityModules-deps.jar", "tlc2.TLC", "-config", os.path.basename(tmpcfg),
               "-workers", WORKERS, "-metadir", meta, "-noGenerateSpecTE", mod]
        o = subprocess.run(cmd, cwd=spec, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True).stdout
        subprocess.run(["rm", "-rf", meta, tmpcfg])
        outf = os.path.join(out, f"{base}.{i}.out")
        open(outf, "w").write(o)
        m = re.search(r"(Invariant|Temporal property|property) (\w+) (is|was) violated", o)
        ds = re.findall(r"([\d,]+) distinct states found", o)
        states = ds[-1] if ds else "?"
        nst = len(re.findall(r"^State \d+:", o, re.M))
        if m:
            name = m.group(2)
            chain.append(f"{name}({nst} states)")
            log.write(f"run {i}: violated {name} (trace {nst} states, distinct {states})\n")
            new = disable(text, name)
            if new == text:
                chain.append("CANNOT-DISABLE")
                break
            text = new
            continue
        if "Temporal properties were violated" in o:
            chain.append(f"temporal({nst} states)")
            log.write(f"run {i}: temporal violation (unnamed)\n")
            break
        if "No error has been found" in o:
            chain.append(f"CLEAN({states})")
            log.write(f"run {i}: no error, distinct {states}\n")
            break
        chain.append("TIMEOUT" if "Progress" in o else "ERROR")
        log.write(f"run {i}: ended without verdict (distinct {states})\n" + o[-800:] + "\n")
        break
    log.close()
    line = f"{base}\t{int(time.time()-t0)}s\t" + " -> ".join(chain)
    print(line, flush=True)
    return line


if __name__ == "__main__":
    for c in sys.argv[3:]:
        run(c)
