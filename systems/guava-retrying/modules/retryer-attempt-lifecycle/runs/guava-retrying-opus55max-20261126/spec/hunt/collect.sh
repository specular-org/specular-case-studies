#!/bin/bash
# collect.sh TASKID NAME : copy a finished task's log to spec/output/hunt_NAME.out and print a one-line status
J=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/.tlc-tasks/jobs/$1
O=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec/output/hunt_$2.out
cp "$J/tlc.log" "$O"
v=$(grep -m1 -E "^Error: (Invariant .* is violated|Temporal propert.* violated)" "$O")
c=$(grep -m1 -E 'Model checking completed|Simulation completed' "$O")
s=$(grep -E 'distinct states found|states generated' "$O" | tail -1)
d=$(grep -m1 -E 'depth of the complete state graph' "$O")
echo "$2 | ${v:-no violation} | ${c:-not completed} | $s | $d"
