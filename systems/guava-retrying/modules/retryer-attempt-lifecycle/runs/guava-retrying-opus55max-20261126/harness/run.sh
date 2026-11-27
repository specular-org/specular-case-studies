#!/usr/bin/env bash
# One command: build the JPF instrumentation (apply.sh), run every workload
# under Java PathFinder with the trace recorder, collect the traces in
# ../traces/, and report trace counts and event coverage.
#
# Usage (from .specular-output/):
#   bash harness/run.sh [--validate] [--quick] [workload ...]
#     --validate   replay every trace through spec/Trace.tla with TLC afterwards
#                  (tools/validate_traces.py; failures at the known base.tla
#                  gaps of INSTRUMENTATION.md are labelled)
#     --quick      small budgets (smoke test)
#     workload     run only these (names from the table below)
# Environment: GR_JOBS (parallel JPF runs, default 4), plus apply.sh's.
set -euo pipefail

HARNESS=$(cd "$(dirname "$0")" && pwd)
OUT=$(cd "$HARNESS/.." && pwd)
TRACES=$OUT/traces
RUNDIR=$HARNESS/build/run
JOBS=${GR_JOBS:-4}

validate=0
quick=0
selected=()
for a in "$@"; do
    case "$a" in
        --validate) validate=1 ;;
        --quick) quick=1 ;;
        -*) echo "unknown option $a" >&2; exit 2 ;;
        *) selected+=("$a") ;;
    esac
done

bash "$HARNESS/apply.sh"
# shellcheck disable=SC1091
source "$HARNESS/build/env.sh"

# name  class  max_paths  max_traces  budget_seconds  seed
WORKLOADS=(
    "nolimit_basic           NolimitBasic          600   20  240  11"
    "nolimit_interrupt       NolimitInterrupt     1500   40  300  12"
    "nolimit_decision        NolimitDecision       600   20  240  13"
    "listeners_add           ListenersAdd         1500   40  300  14"
    "fixed_cached            FixedCached          3000   60  900  15"
    "fixed_cached_interrupt  FixedCachedInterrupt 3000   50  900  16"
    "fixed_pool              FixedPool            3000   40  900  17"
    "bounded_shared          BoundedShared        1500   40  900  18"
    "shutdown_race           ShutdownRace         1500   30  300  19"
    "wrap_cancel             WrapCancel           1500   40  600  20"
    "wrap_samepool           WrapSamePool          200    5  120  21"
    "sharing                 Sharing              1500   40  600  22"
    "default_limiter         DefaultLimiter       1000   25  600  23"
)

mkdir -p "$TRACES" "$RUNDIR"

run_workload() {
    local name=$1 cls=$2 paths=$3 traces=$4 budget=$5 seed=$6
    if [ "$quick" = 1 ]; then paths=60; traces=6; budget=60; fi
    rm -f "$TRACES/$name"-[0-9]*.ndjson "$RUNDIR/$name.summary.json"
    local rc=0
    timeout $((budget + 300)) "$JAVA11_HOME/bin/java" -Xmx4g \
        -cp "$JPF_HOME/build/jpf.jar:$HARNESS/build/recorder" gov.nasa.jpf.JPF \
        +classpath="$HARNESS/build/workloads:$GR_CLASSES:$GUAVA:$JSR305" \
        +native_classpath="$HARNESS/build/recorder" \
        +listener=grtrace.GrTraceRecorder \
        +search.class=grtrace.TraceSearch \
        +grtrace.out_dir="$TRACES" \
        +grtrace.summary_dir="$RUNDIR" \
        +grtrace.workload="$name" \
        +grtrace.max_paths="$paths" \
        +grtrace.max_traces="$traces" \
        +grtrace.min_traces=5 \
        +grtrace.budget_ms=$((budget * 1000)) \
        +grtrace.quiesce_steps=150 \
        +grtrace.max_events=400 \
        +cg.randomize_choices=FIXED_SEED \
        +cg.seed="$seed" \
        +vm.storage.class= \
        +search.properties=gov.nasa.jpf.vm.NoUncaughtExceptionsProperty \
        +search.depth_limit=20000 \
        "grwork.w.$cls" > "$RUNDIR/$name.log" 2>&1 || rc=$?
    if [ $rc -ne 0 ] || ! grep -q "no errors detected" "$RUNDIR/$name.log"; then
        echo "!! $name: JPF exit $rc (see $RUNDIR/$name.log)"
        return 1
    fi
    echo "   $name: $(ls "$TRACES/$name"-[0-9]*.ndjson 2>/dev/null | wc -l) traces"
}

echo "==> running workloads under JPF ($JOBS in parallel)"
pids=()
names=()
failed=0
for row in "${WORKLOADS[@]}"; do
    # shellcheck disable=SC2086
    set -- $row
    if [ ${#selected[@]} -gt 0 ] && [[ ! " ${selected[*]} " == *" $1 "* ]]; then continue; fi
    while [ "$(jobs -rp | wc -l)" -ge "$JOBS" ]; do sleep 1; done
    run_workload "$@" &
    pids+=($!)
    names+=("$1")
done
for i in "${!pids[@]}"; do
    if ! wait "${pids[$i]}"; then failed=1; fi
done

echo ""
echo "==> traces in $TRACES"
python3 -I "$HARNESS/tools/report.py" "$TRACES" "$RUNDIR"

if [ ! -f "$TRACES/trace.ndjson" ] || [ "$quick" = 0 ]; then
    first=$(ls "$TRACES"/fixed_cached-[0-9]*.ndjson 2>/dev/null | head -1 || true)
    [ -n "$first" ] && cp "$first" "$TRACES/trace.ndjson" && echo "   trace.ndjson (Trace.tla's default input) = $(basename "$first")"
fi

if [ "$validate" = 1 ]; then
    echo ""
    echo "==> TLC replay through spec/Trace.tla"
    python3 -I "$HARNESS/tools/validate_traces.py" --jobs "${GR_TLC_JOBS:-8}" \
        $(ls "$TRACES"/*-[0-9]*.ndjson) | tee "$RUNDIR/validation.txt" | grep -v '^PASS' || true
fi
exit $failed
