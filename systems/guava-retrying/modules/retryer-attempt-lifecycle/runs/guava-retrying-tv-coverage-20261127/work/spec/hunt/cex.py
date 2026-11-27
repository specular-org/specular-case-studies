#!/usr/bin/env python3
"""Compact view of a TLC counterexample: violated property, then per state the
action and the variables that changed (selected vars only unless -a)."""
import re, sys
def parse(path):
    txt = open(path).read()
    viol = re.findall(r'Error: (Invariant \S+ is violated|Temporal properties were violated|.*violated.*)', txt)
    states = []
    for m in re.finditer(r'^State (\d+): (.*?)\n((?:(?:/\\| ).*\n?)+)', txt, re.M):
        body = m.group(3)
        vs = {}
        cur = None
        for line in body.split('\n'):
            mm = re.match(r'^/\\ (\w+) = (.*)$', line)
            if mm:
                cur = mm.group(1); vs[cur] = mm.group(2)
            elif cur and line.strip():
                vs[cur] += ' ' + line.strip()
        act = re.sub(r' line \d+, col \d+ to line \d+, col \d+ of module \w+', '', m.group(2))
        states.append((int(m.group(1)), act, vs))
    stut = re.findall(r'^State (\d+): Stuttering', txt, re.M)
    back = re.findall(r'^Back to state:? (\d+)', txt, re.M)
    return viol, states, stut, back
if __name__ == '__main__':
    path = sys.argv[1]
    show_all = '-a' in sys.argv
    keys = [a for a in sys.argv[2:] if a != '-a']
    viol, states, stut, back = parse(path)
    print('VIOLATION:', viol[:2])
    prev = {}
    for n, act, vs in states:
        ch = {k: v for k, v in vs.items() if prev.get(k) != v}
        if keys:
            ch = {k: v for k, v in ch.items() if k in keys}
        if n == 1 and not show_all:
            print(f'{n:3} {act}')
        else:
            print(f'{n:3} {act}  ' + '; '.join(f'{k}={v}' for k, v in sorted(ch.items())))
        prev = vs
    if stut: print('Stuttering at', stut)
    if back: print('Back to state', back)
