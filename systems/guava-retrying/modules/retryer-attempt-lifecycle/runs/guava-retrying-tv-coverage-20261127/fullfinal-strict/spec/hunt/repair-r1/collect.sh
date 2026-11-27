#!/bin/bash
# collect.sh TASKID NAME : copy a finished task's log to spec/output/repair-r1/NAME.out and print a one-line status
D=$(cd "$(dirname "$0")/../.." && pwd)
J=$D/../.tlc-tasks/jobs/$1
O=$D/output/repair-r1/$2.out
cp "$J/tlc.log" "$O"
v=$(grep -m1 -E "^Error: (Invariant .* is violated|Temporal propert.* violated)" "$O")
c=$(grep -m1 -E 'Model checking completed|Simulation completed' "$O")
s=$(grep -E 'distinct states found|states generated' "$O" | tail -1)
d=$(grep -m1 -E 'depth of the complete state graph' "$O")
echo "$2 | ${v:-no violation} | ${c:-not completed} | $s | $d"
