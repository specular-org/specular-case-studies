#!/usr/bin/env bash
# MC-11 (KNOWN upstream #48): a RetryListener added to a RetryerBuilder AFTER build()
# is notified by an already-built Retryer -- including by a call() that is already in flight.
#
# Root cause: RetryerBuilder.java:40 (one mutable ArrayList per builder), :63 (withRetryListener
# appends to it), :196 (build() hands that same list to the Retryer), Retryer.java:137 (stored by
# reference), Retryer.java:166-168 (call() iterates the live list after every attempt).
#
# Model-checking counterexample reproduced: spec/output/hunt_s3_listeners_bfs2.out
#   (MC_hunt_s3_listeners.cfg, invariant ListenersFixedAtBuild violated at State 9).
#
# Escalation level: Scenario 1 = Level 0 (pure public API, one thread, deterministic).
#                   Scenarios 2/3 = Level 1 (public API, two threads; ordering is forced with
#                   CountDownLatches inside the *user* callable only). The library is NOT modified.
#
# What the script does (all in a private temp dir; the source checkout is never written):
#   1. compiles the UNMODIFIED library sources (provenance: git HEAD + clean status are printed);
#   2. compiles + runs MC11Repro against them  -> the bug must show up (PASS = bug triggered);
#   3. fix control: compiles a COPY of the sources with the one-line fix proposed in #48
#      (ImmutableList.copyOf(listeners) at RetryerBuilder.java:196) and re-runs the same
#      program -> the anomaly must disappear (proves the aliasing at :196 is the cause);
#   4. runs the 36 upstream JUnit tests against the original and the fixed build.
#
# Exit status: 0 = bug reproduced on the unmodified code AND the fix control is clean;
#              1 = bug not reproduced / control failed; 2 = environment/setup problem.
#
# Usage: bash test_bugMC-11_listener_added_after_build.sh
#   env overrides: SRC_DIR (guava-retrying checkout), M2_REPO, JAVA_HOME, RUN_UPSTREAM_TESTS=0
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_SRC="$SCRIPT_DIR/../confirmation/MC-11/worktree"
SRC_DIR="${SRC_DIR:-$DEFAULT_SRC}"
M2_REPO="${M2_REPO:-$HOME/.m2/repository}"
RUN_UPSTREAM_TESTS="${RUN_UPSTREAM_TESTS:-1}"
if [ -n "${JAVA_HOME:-}" ]; then JAVAC="$JAVA_HOME/bin/javac"; JAVA="$JAVA_HOME/bin/java"; else JAVAC=javac; JAVA=java; fi

GUAVA="$M2_REPO/com/google/guava/guava/22.0/guava-22.0.jar"
JSR305="$M2_REPO/com/google/code/findbugs/jsr305/2.0.2/jsr305-2.0.2.jar"
JUNIT="$M2_REPO/junit/junit/4.11/junit-4.11.jar"
HAMCREST="$M2_REPO/org/hamcrest/hamcrest-core/1.3/hamcrest-core-1.3.jar"
MOCKITO="$M2_REPO/org/mockito/mockito-all/1.9.5/mockito-all-1.9.5.jar"

die_env() { echo "ENV ERROR: $*" >&2; exit 2; }
[ -d "$SRC_DIR/src/main/java/com/github/rholder/retry" ] || die_env "guava-retrying sources not found under SRC_DIR=$SRC_DIR"
for j in "$GUAVA" "$JSR305"; do [ -f "$j" ] || die_env "missing dependency jar $j"; done
command -v "$JAVAC" >/dev/null || die_env "javac not found"

WORK="$(mktemp -d /tmp/mc11-repro.XXXXXX)"
trap 'rm -rf "$WORK"' EXIT
DEPS="$GUAVA:$JSR305"
JFLAGS=(--release 8 -nowarn -Xlint:-options -encoding UTF-8)

echo "=== MC-11 reproduction: listener added after build() is notified by an already-built Retryer ==="
echo "java     : $("$JAVA" -version 2>&1 | head -1)"
echo "source   : $(cd "$SRC_DIR" && pwd)"
echo "git HEAD : $(git -C "$SRC_DIR" rev-parse HEAD 2>/dev/null || echo n/a)"
DIRTY="$(git -C "$SRC_DIR" status --porcelain -- src 2>/dev/null || true)"
echo "src dirty: ${DIRTY:-<clean -- library sources unmodified>}"
echo "guava    : $GUAVA ($(sha1sum "$GUAVA" | cut -c1-12))"
echo "cited code (unmodified):"
grep -n "private List<RetryListener> listeners" "$SRC_DIR/src/main/java/com/github/rholder/retry/RetryerBuilder.java" | sed 's/^/  RetryerBuilder.java:/'
grep -n "listeners.add(listener)"               "$SRC_DIR/src/main/java/com/github/rholder/retry/RetryerBuilder.java" | sed 's/^/  RetryerBuilder.java:/'
grep -n "rejectionPredicate, listeners);"       "$SRC_DIR/src/main/java/com/github/rholder/retry/RetryerBuilder.java" | sed 's/^/  RetryerBuilder.java:/'
grep -n "this.listeners = listeners;"           "$SRC_DIR/src/main/java/com/github/rholder/retry/Retryer.java"        | sed 's/^/  Retryer.java:/'
grep -n "for (RetryListener listener : listeners)" "$SRC_DIR/src/main/java/com/github/rholder/retry/Retryer.java"     | sed 's/^/  Retryer.java:/'

# ---------------------------------------------------------------- 1. library (unmodified)
mkdir -p "$WORK/lib-orig" "$WORK/src-fixed" "$WORK/lib-fixed" "$WORK/repro-src" "$WORK/repro-orig" "$WORK/repro-fixed"
"$JAVAC" "${JFLAGS[@]}" -cp "$DEPS" -d "$WORK/lib-orig" $(find "$SRC_DIR/src/main/java" -name '*.java')

# ---------------------------------------------------------------- 2. the reproduction program
cat > "$WORK/repro-src/MC11Repro.java" <<'JAVA'
import com.github.rholder.retry.Attempt;
import com.github.rholder.retry.RetryListener;
import com.github.rholder.retry.Retryer;
import com.github.rholder.retry.RetryerBuilder;
import com.github.rholder.retry.StopStrategies;
import com.google.common.base.Predicates;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.concurrent.Callable;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicReference;

/** Public-API-only reproduction of MC-11 / upstream #48. Nothing here touches library internals. */
public class MC11Repro {
    private static final AtomicInteger SEQ = new AtomicInteger();

    static void ev(String msg) {
        System.out.printf("    [%02d] %-9s %s%n", SEQ.incrementAndGet(), Thread.currentThread().getName(), msg);
        System.out.flush();
    }

    static void header(String s) {
        SEQ.set(0);
        System.out.println();
        System.out.println("--- " + s);
    }

    /** An ordinary user listener (think: per-retryer metrics / audit log) that records what it is told. */
    static final class RecordingListener implements RetryListener {
        final String name;
        private final List<Long> attempts = Collections.synchronizedList(new ArrayList<Long>());
        RecordingListener(String name) { this.name = name; }
        @Override
        public <V> void onRetry(Attempt<V> attempt) {
            attempts.add(attempt.getAttemptNumber());
            ev(name + ".onRetry(attempt #" + attempt.getAttemptNumber() + ", "
                    + (attempt.hasResult() ? "result=\"" + attempt.getResult() + "\"" : "exception=" + attempt.getExceptionCause()) + ")");
        }
        List<Long> seen() { synchronized (attempts) { return new ArrayList<Long>(attempts); } }
    }

    static boolean verdict(String expected, String observed, boolean anomaly) {
        System.out.println("    expected (listener set fixed at build()): " + expected);
        System.out.println("    observed                                : " + observed);
        System.out.println("    => " + (anomaly ? "ANOMALY: a listener added to the builder after build() was notified by the already-built Retryer"
                                                : "no anomaly: the built Retryer kept the listener set it was built with"));
        return anomaly;
    }

    /* Scenario 1 -- Level 0, single thread. Issue #48's sequence with a realistic template-builder use:
     * one builder is the shared config; each service adds its own metrics listener and builds its Retryer.
     * Control in the same run: a retry predicate added to the builder after build() does NOT leak into
     * retryerA (captured by value), whereas the listener added after build() DOES (captured by reference). */
    static boolean scenario1() throws Exception {
        header("Scenario 1 (Level 0, one thread): builder used as a template for two Retryers (issue #48 sequence)");
        RecordingListener metricsA = new RecordingListener("metricsA");
        RecordingListener metricsB = new RecordingListener("metricsB");
        RetryerBuilder<String> template = RetryerBuilder.<String>newBuilder()
                .retryIfResult(Predicates.equalTo("busy"))
                .withStopStrategy(StopStrategies.stopAfterAttempt(5));
        Retryer<String> retryerA = template.withRetryListener(metricsA).build();
        ev("retryerA = template.withRetryListener(metricsA).build()          -> retryerA: retry on \"busy\", listeners [metricsA]");
        Retryer<String> retryerB = template.retryIfResult(Predicates.equalTo("slow")).withRetryListener(metricsB).build();
        ev("retryerB = template.retryIfResult(\"slow\").withRetryListener(metricsB).build()  (retryerB is never called)");
        final String[] results = {"busy", "slow", "ok"};
        final AtomicInteger n = new AtomicInteger();
        String r = retryerA.call(new Callable<String>() {
            @Override public String call() { return results[n.getAndIncrement()]; }
        });
        ev("retryerA.call(...) returned \"" + r + "\" after " + n.get() + " attempt(s)");
        boolean predicateFixed = "slow".equals(r) && n.get() == 2;
        System.out.println("    control: retryIfResult(\"slow\") added after retryerA was built "
                + (predicateFixed ? "did NOT affect retryerA (it accepted \"slow\") -> predicates are fixed at build()"
                                  : "affected retryerA (unexpected)"));
        boolean anomaly = !metricsB.seen().isEmpty();
        verdict("metricsA=[1, 2]  metricsB=[]   (retryerB never ran)",
                "metricsA=" + metricsA.seen() + "  metricsB=" + metricsB.seen()
                        + (anomaly ? "   <-- retryerB's listener counted retryerA's attempts" : ""), anomaly);
        return anomaly;
    }

    /* Scenario 2 -- Level 1, two threads. Step-by-step instance of hunt_s3_listeners_bfs2.out:
     *   State 1 Init               blist=<<1>>        : builder has [L1]; retryer = builder.build()
     *   State 2 MCCallStart(c1)                       : caller-c1 enters retryer.call(callable)
     *   State 3 MCCallerBodyStart(c1,"Ret")           : attempt 1's callable is running
     *   State 4 MCAddListenerBegin(2) / State 5 MCAddListenerEnd  blist=<<1,2>> : main: builder.withRetryListener(L2)
     *   State 6 MCCallerBodyReturns(c1)               : callable returns "Ret"
     *   State 7 MCListenersBegin(c1)                  : Retryer.java:166 creates the iterator (after the add -> no CME)
     *   State 8/9 MCListenerNotify(c1) x2  notified=<<1,2>> : L1.onRetry, then L2.onRetry  -> ListenersFixedAtBuild violated
     * The latches live only in the user callable; they force the trace's interleaving deterministically. */
    static boolean scenario2() throws Exception {
        header("Scenario 2 (Level 1, two threads): MC counterexample hunt_s3_listeners_bfs2.out -- add completes while attempt 1 runs");
        final RetryerBuilder<String> builder = RetryerBuilder.<String>newBuilder();
        final RecordingListener l1 = new RecordingListener("L1");
        final RecordingListener l2 = new RecordingListener("L2");
        builder.withRetryListener(l1);
        final Retryer<String> retryer = builder.build();
        ev("retryer = builder.withRetryListener(L1).build()                 [State 1: listeners at build = [L1]]");
        final CountDownLatch bodyStarted = new CountDownLatch(1);
        final CountDownLatch addDone = new CountDownLatch(1);
        final Callable<String> callable = new Callable<String>() {
            @Override public String call() throws Exception {
                ev("attempt 1: callable body running                            [State 3: MCCallerBodyStart(c1,\"Ret\")]");
                bodyStarted.countDown();
                if (!addDone.await(30, TimeUnit.SECONDS)) throw new IllegalStateException("harness timeout");
                ev("attempt 1: callable returns \"Ret\"                            [State 6: MCCallerBodyReturns(c1)]");
                return "Ret";
            }
        };
        final AtomicReference<Object> outcome = new AtomicReference<Object>();
        Thread c1 = new Thread(new Runnable() {
            @Override public void run() {
                ev("retryer.call(callable) entered                              [State 2: MCCallStart(c1)]");
                try {
                    String v = retryer.call(callable);
                    outcome.set(v);
                    ev("retryer.call(callable) returned \"" + v + "\"");
                } catch (Throwable t) {
                    outcome.set(t);
                    ev("retryer.call(callable) threw " + t);
                }
            }
        }, "caller-c1");
        Thread.currentThread().setName("main");
        c1.start();
        if (!bodyStarted.await(30, TimeUnit.SECONDS)) throw new IllegalStateException("harness timeout");
        ev("builder.withRetryListener(L2) begins                        [State 4: MCAddListenerBegin(2)]");
        builder.withRetryListener(l2);
        ev("builder.withRetryListener(L2) returned                      [State 5: MCAddListenerEnd]");
        addDone.countDown();
        c1.join(30000);
        if (c1.isAlive()) throw new IllegalStateException("caller thread still running");
        boolean anomaly = l2.seen().contains(1L);
        verdict("in-flight call notifies [L1] only            outcome=\"Ret\"",
                "L1=" + l1.seen() + "  L2=" + l2.seen() + "  outcome=" + (outcome.get() instanceof String ? "\"" + outcome.get() + "\"" : outcome.get())
                        + (anomaly ? "   <-- notified=<<1,2>> as in State 9 (no ConcurrentModificationException)" : ""), anomaly);
        return anomaly;
    }

    /* Scenario 3 -- Level 1, two threads. Same mechanism over a multi-attempt call: the listener set of ONE
     * call() changes between attempts (attempt 1 -> [L1], attempts 2,3 -> [L1, L2]). */
    static boolean scenario3() throws Exception {
        header("Scenario 3 (Level 1, two threads): listener set of one in-flight call() changes between attempts");
        final RetryerBuilder<String> builder = RetryerBuilder.<String>newBuilder()
                .retryIfResult(Predicates.equalTo("retry"))
                .withStopStrategy(StopStrategies.stopAfterAttempt(3));
        final RecordingListener l1 = new RecordingListener("L1");
        final RecordingListener l2 = new RecordingListener("L2");
        final Retryer<String> retryer = builder.withRetryListener(l1).build();
        ev("retryer = builder(retry on \"retry\", stopAfterAttempt(3)).withRetryListener(L1).build()");
        final CountDownLatch inAttempt2 = new CountDownLatch(1);
        final CountDownLatch addDone = new CountDownLatch(1);
        final AtomicInteger n = new AtomicInteger();
        final Callable<String> callable = new Callable<String>() {
            @Override public String call() throws Exception {
                int a = n.incrementAndGet();
                if (a == 2) {
                    ev("attempt 2: callable body running, builder gets a new listener meanwhile");
                    inAttempt2.countDown();
                    if (!addDone.await(30, TimeUnit.SECONDS)) throw new IllegalStateException("harness timeout");
                }
                return a < 3 ? "retry" : "ok";
            }
        };
        final AtomicReference<Object> outcome = new AtomicReference<Object>();
        Thread c1 = new Thread(new Runnable() {
            @Override public void run() {
                try { outcome.set(retryer.call(callable)); ev("retryer.call(callable) returned \"" + outcome.get() + "\""); }
                catch (Throwable t) { outcome.set(t); ev("retryer.call(callable) threw " + t); }
            }
        }, "caller-c1");
        c1.start();
        if (!inAttempt2.await(30, TimeUnit.SECONDS)) throw new IllegalStateException("harness timeout");
        builder.withRetryListener(l2);
        ev("builder.withRetryListener(L2) returned (retryer's call() is in attempt 2)");
        addDone.countDown();
        c1.join(30000);
        if (c1.isAlive()) throw new IllegalStateException("caller thread still running");
        boolean anomaly = !l2.seen().isEmpty();
        verdict("L1=[1, 2, 3]  L2=[]",
                "L1=" + l1.seen() + "  L2=" + l2.seen() + (anomaly ? "   <-- same call() notified [L1] for attempt 1 but [L1, L2] for later attempts" : ""), anomaly);
        return anomaly;
    }

    public static void main(String[] args) throws Exception {
        String build = args.length > 0 ? args[0] : "original";
        System.out.println("MC11Repro running against the " + build + " library build");
        int anomalies = 0;
        if (scenario1()) anomalies++;
        if (scenario2()) anomalies++;
        if (scenario3()) anomalies++;
        System.out.println();
        System.out.println("SUMMARY build=" + build + " anomalies=" + anomalies + "/3");
    }
}
JAVA

"$JAVAC" "${JFLAGS[@]}" -cp "$WORK/lib-orig:$DEPS" -d "$WORK/repro-orig" "$WORK/repro-src/MC11Repro.java"

echo
echo "################ RUN 1: unmodified library ################"
set +e
timeout 120 "$JAVA" -cp "$WORK/repro-orig:$WORK/lib-orig:$DEPS" MC11Repro original | tee "$WORK/run-orig.out"
RC1=${PIPESTATUS[0]}
set -e
[ "$RC1" -eq 0 ] || { echo "repro program failed/timed out (rc=$RC1)"; exit 1; }

# ---------------------------------------------------------------- 3. fix control (copy of the sources, never the checkout)
cp -r "$SRC_DIR/src/main/java/." "$WORK/src-fixed/"
FIXED_BUILDER="$WORK/src-fixed/com/github/rholder/retry/RetryerBuilder.java"
sed -i 's/theBlockStrategy, rejectionPredicate, listeners);/theBlockStrategy, rejectionPredicate, com.google.common.collect.ImmutableList.copyOf(listeners));/' "$FIXED_BUILDER"
echo
echo "################ RUN 2: fix control (copy of sources, #48's proposed one-line fix) ################"
diff -u "$SRC_DIR/src/main/java/com/github/rholder/retry/RetryerBuilder.java" "$FIXED_BUILDER" \
    | sed -e "s#$SRC_DIR/src/main/java/#a/#" -e "s#$WORK/src-fixed/#b/#" || true
"$JAVAC" "${JFLAGS[@]}" -cp "$DEPS" -d "$WORK/lib-fixed" $(find "$WORK/src-fixed" -name '*.java')
"$JAVAC" "${JFLAGS[@]}" -cp "$WORK/lib-fixed:$DEPS" -d "$WORK/repro-fixed" "$WORK/repro-src/MC11Repro.java"
set +e
timeout 120 "$JAVA" -cp "$WORK/repro-fixed:$WORK/lib-fixed:$DEPS" MC11Repro fixed | tee "$WORK/run-fixed.out"
RC2=${PIPESTATUS[0]}
set -e
[ "$RC2" -eq 0 ] || { echo "fix-control program failed/timed out (rc=$RC2)"; exit 1; }

# ---------------------------------------------------------------- 4. upstream unit tests (original and fixed)
UT_ORIG="skipped"; UT_FIXED="skipped"
if [ "$RUN_UPSTREAM_TESTS" = "1" ] && [ -f "$JUNIT" ] && [ -f "$HAMCREST" ] && [ -f "$MOCKITO" ] && [ -d "$SRC_DIR/src/test/java" ]; then
    TESTCP="$JUNIT:$HAMCREST:$MOCKITO:$DEPS"
    TESTS="com.github.rholder.retry.AttemptTimeLimiterTest com.github.rholder.retry.RetryerBuilderTest com.github.rholder.retry.StopStrategiesTest com.github.rholder.retry.WaitStrategiesTest"
    for v in orig fixed; do
        mkdir -p "$WORK/tests-$v"
        "$JAVAC" "${JFLAGS[@]}" -cp "$WORK/lib-$v:$TESTCP" -d "$WORK/tests-$v" $(find "$SRC_DIR/src/test/java" -name '*.java')
        set +e
        timeout 300 "$JAVA" -cp "$WORK/tests-$v:$WORK/lib-$v:$TESTCP" org.junit.runner.JUnitCore $TESTS > "$WORK/ut-$v.out" 2>&1
        set -e
        R="$(grep -E '^(OK \(|Tests run:)' "$WORK/ut-$v.out" | tail -1)"
        if [ "$v" = orig ]; then UT_ORIG="$R"; else UT_FIXED="$R"; fi
    done
fi

# ---------------------------------------------------------------- verdict
S1="$(grep '^SUMMARY' "$WORK/run-orig.out")"
S2="$(grep '^SUMMARY' "$WORK/run-fixed.out")"
echo
echo "================ RESULT ================"
echo "unmodified library : $S1"
echo "fix control        : $S2"
echo "upstream tests (unmodified library): $UT_ORIG"
echo "upstream tests (fixed copy)        : $UT_FIXED"
if [[ "$S1" == *"anomalies=3/3"* && "$S2" == *"anomalies=0/3"* ]]; then
    echo "MC-11 REPRODUCED: an already-built Retryer (including a call already in flight) notified a listener"
    echo "that was added to its RetryerBuilder after build(); copying the list at build() removes it."
    exit 0
fi
echo "MC-11 NOT REPRODUCED (or fix control not clean)"
exit 1
