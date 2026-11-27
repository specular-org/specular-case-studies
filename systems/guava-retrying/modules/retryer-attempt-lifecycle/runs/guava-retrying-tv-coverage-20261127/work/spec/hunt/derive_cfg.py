#!/usr/bin/env python3
"""Derive a hunting cfg from a canonical MC_hunt_*.cfg.

usage: derive_cfg.py BASE.cfg OUT.cfg [--off NAME:reason]... [--on NAME]... [--set CONST=VALUE]...

--off comments out an enabled INVARIANT entry (keeping the reason),
--on  adds an invariant (e.g. a filtered variant defined in MC.tla/base.tla),
--set replaces the value of a CONSTANTS assignment.
"""
import re, sys

def main(argv):
    base, out = argv[0], argv[1]
    offs, ons, sets = {}, [], {}
    i = 2
    while i < len(argv):
        if argv[i] == '--off':
            name, _, why = argv[i+1].partition(':'); offs[name] = why; i += 2
        elif argv[i] == '--on':
            ons.append(argv[i+1]); i += 2
        elif argv[i] == '--set':
            k, _, v = argv[i+1].partition('='); sets[k.strip()] = v.strip(); i += 2
        else:
            raise SystemExit('bad arg ' + argv[i])
    lines = open(base).read().split('\n')
    res, seen_off, seen_set = [], set(), set()
    in_inv = False
    for ln in lines:
        s = ln.strip()
        if re.match(r'^(INVARIANTS?|PROPERTY|PROPERTIES|CONSTRAINT|SYMMETRY|CHECK_DEADLOCK|SPECIFICATION|CONSTANTS)\b', s):
            in_inv = s.startswith('INVARIANT')
        m = re.match(r'^(\s*)([A-Za-z0-9_]+)\s*$', ln)
        if in_inv and m and m.group(2) in offs:
            res.append(f"{m.group(1)}\\* {m.group(2)}    \\* off (hunt): {offs[m.group(2)]}")
            seen_off.add(m.group(2)); continue
        m2 = re.match(r'^(\s*)([A-Za-z0-9_]+)\s*=\s*(.*)$', ln)
        if m2 and m2.group(2) in sets and not s.startswith('\\*'):
            res.append(f"{m2.group(1)}{m2.group(2)} = {sets[m2.group(2)]}")
            seen_set.add(m2.group(2)); continue
        res.append(ln)
        if s.startswith('INVARIANT') and ons:
            for n in ons:
                res.append(f"    {n}")
    missing = (set(offs) - seen_off) | (set(sets) - seen_set)
    if missing:
        raise SystemExit(f'not found in {base}: {sorted(missing)}')
    hdr = f"\\* derived from {base.split('/')[-1]} by hunt/derive_cfg.py " + ' '.join(argv[2:])
    open(out, 'w').write(hdr + '\n' + '\n'.join(res))

if __name__ == '__main__':
    main(sys.argv[1:])
