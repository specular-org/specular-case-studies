#!/usr/bin/env bash
# CR-D-22 reproduction: StopStrategies.stopAfterDelay(duration, timeUnit) truncates the
# limit with timeUnit.toMillis (StopStrategies.java:87) and StopAfterDelayStrategy stops once
# getDelaySinceFirstAttempt() >= maxDelay (StopStrategies.java:124). A sub-millisecond limit
# therefore becomes 0 ms and Retryer.call gives up after the first failed attempt, although
# the Javadoc (StopStrategies.java:75-79) says retrying stops only once the time since the
# first attempt "has exceeded the given delay amount".
#
# Escalation level: 0 (pure black box). The library is compiled UNMODIFIED from the source
# checkout; the workload uses only public API (RetryerBuilder, StopStrategies, Retryer.call,
# RetryException, Attempt, StopStrategy). No sleeps/failpoints in library code, no state
# injection, no source patch. The only user-defined StopStrategy is the expected-behaviour
# oracle used as a control (limit rounded UP to whole ms instead of truncated).
#
# Bug criterion (observable outcome at the caller of Retryer.call): call() throws
# RetryException after exactly 1 failed attempt (the callable ran once; the attempt that
# would have returned "ok" never ran) while the WHOLE call() took less than the configured
# limit -- i.e. the stop decision was made before the limit elapsed.
#
# Scenarios: [A] sub-ms limit (500 us, 999_999 ns) with a transient failure, vs a 1_000_000 ns
# control and a ceil-rounding oracle; [B] 1900 us limit with a 1.2 ms first attempt (general
# shortening); [C] always-failing callable; [D] rejected-result path (retryIfResult);
# [E] Retryer.wrap(...) submitted to an ExecutorService.
#
# Exit codes: 0 = bug reproduced (and controls behaved as expected), 1 = not reproduced,
#             2 = build/environment error.
#
# Overridable env: SRC_ROOT, GUAVA_JAR, JSR305_JAR, JUNIT_JAR, HAMCREST_JAR, JAVA_HOME.
# Run: timeout 10m bash repro/test_bugCR-D-22_subms_stop_after_delay.sh 2>&1 | tee repro/CR-D-22.log
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_ROOT="${SRC_ROOT:-$HERE/../confirmation/CR-D-22/worktree}"
M2="${M2:-$HOME/.m2/repository}"
GUAVA_JAR="${GUAVA_JAR:-$M2/com/google/guava/guava/22.0/guava-22.0.jar}"
JSR305_JAR="${JSR305_JAR:-$M2/com/google/code/findbugs/jsr305/2.0.2/jsr305-2.0.2.jar}"
JUNIT_JAR="${JUNIT_JAR:-$M2/junit/junit/4.11/junit-4.11.jar}"
HAMCREST_JAR="${HAMCREST_JAR:-$M2/org/hamcrest/hamcrest-core/1.3/hamcrest-core-1.3.jar}"
JAVA="${JAVA_HOME:+$JAVA_HOME/bin/}java"
JAVAC="${JAVA_HOME:+$JAVA_HOME/bin/}javac"

for f in "$GUAVA_JAR" "$JSR305_JAR" "$JUNIT_JAR" "$HAMCREST_JAR"; do
  [ -f "$f" ] || { echo "ENV ERROR: missing $f"; exit 2; }
done
[ -f "$SRC_ROOT/src/main/java/com/github/rholder/retry/StopStrategies.java" ] || { echo "ENV ERROR: bad SRC_ROOT=$SRC_ROOT"; exit 2; }

BUILD="$(mktemp -d /tmp/crd22-build.XXXXXX)"
trap 'rm -rf "$BUILD"' EXIT

echo "== CR-D-22 repro  $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "== source: $(cd "$SRC_ROOT" && pwd)"
echo "== source HEAD: $(git -C "$SRC_ROOT" rev-parse HEAD 2>/dev/null || echo n/a)"
echo "== source local modifications (git status --porcelain, empty = unmodified):"
git -C "$SRC_ROOT" status --porcelain 2>/dev/null | sed 's/^/   /'
echo "== cited lines:"
sed -n '85,88p;122,125p' "$SRC_ROOT/src/main/java/com/github/rholder/retry/StopStrategies.java" | sed 's/^/   /'
echo "== $("$JAVA" -version 2>&1 | head -1); guava=$(basename "$GUAVA_JAR"); jsr305=$(basename "$JSR305_JAR")"

# ---- 1. compile the unmodified library ----
mkdir -p "$BUILD/lib" "$BUILD/test" "$BUILD/repro"
if ! "$JAVAC" --release 8 -nowarn -Xlint:-options -cp "$GUAVA_JAR:$JSR305_JAR" -d "$BUILD/lib" \
      $(find "$SRC_ROOT/src/main/java" -name '*.java') > "$BUILD/javac-lib.log" 2>&1; then
  cat "$BUILD/javac-lib.log"; echo "ENV ERROR: library compile failed"; exit 2
fi
echo "== library compiled: $(find "$BUILD/lib" -name '*.class' | wc -l) classes"

# ---- 2. the upstream StopStrategiesTest (informational: what the existing suite covers) ----
if "$JAVAC" --release 8 -nowarn -Xlint:-options -cp "$BUILD/lib:$GUAVA_JAR:$JSR305_JAR:$JUNIT_JAR" -d "$BUILD/test" \
      "$SRC_ROOT/src/test/java/com/github/rholder/retry/StopStrategiesTest.java" > "$BUILD/javac-test.log" 2>&1; then
  echo "== upstream StopStrategiesTest (only MILLISECONDS / SECONDS limits are tested):"
  timeout 120 "$JAVA" -cp "$BUILD/test:$BUILD/lib:$GUAVA_JAR:$JSR305_JAR:$JUNIT_JAR:$HAMCREST_JAR" \
      org.junit.runner.JUnitCore com.github.rholder.retry.StopStrategiesTest 2>&1 | grep -E '^(OK|FAIL|Tests run)' | sed 's/^/   /'
else
  echo "== (upstream StopStrategiesTest did not compile; skipped)"; cat "$BUILD/javac-test.log"
fi

# ---- 3. the reproduction workload (public API only) ----
cat > "$BUILD/repro/ReproCRD22.java" <<'JAVA'
import com.github.rholder.retry.Attempt;
import com.github.rholder.retry.RetryException;
import com.github.rholder.retry.Retryer;
import com.github.rholder.retry.RetryerBuilder;
import com.github.rholder.retry.StopStrategies;
import com.github.rholder.retry.StopStrategy;

import com.google.common.base.Predicates;

import java.io.IOException;
import java.util.Arrays;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;

public final class ReproCRD22 {

    interface CountingCallable extends Callable<String> { int invocations(); }

    /** User workload: attempt 1 runs for spinNanos and fails with a transient IOException; attempt 2 returns "ok". */
    static final class FailOnceThenSucceed implements CountingCallable {
        private final long spinNanos;
        int invocations;
        FailOnceThenSucceed(long spinNanos) { this.spinNanos = spinNanos; }
        @Override public int invocations() { return invocations; }
        @Override public String call() throws Exception {
            invocations++;
            if (invocations == 1) {
                long end = System.nanoTime() + spinNanos;
                while (System.nanoTime() < end) { /* the attempt's own work */ }
                throw new IOException("transient failure on attempt 1");
            }
            return "ok";
        }
    }

    /** User workload for the result-rejection path: attempt 1 returns null (rejected by retryIfResult(isNull)), attempt 2 returns "ok". */
    static final class NullOnceThenOk implements CountingCallable {
        int invocations;
        @Override public int invocations() { return invocations; }
        @Override public String call() {
            invocations++;
            return invocations == 1 ? null : "ok";
        }
    }

    /** User workload: every attempt fails immediately. */
    static final class AlwaysFail implements Callable<String> {
        int invocations;
        @Override public String call() throws Exception {
            invocations++;
            throw new IOException("always fails");
        }
    }

    /**
     * CONTROL ORACLE, not a library patch: the documented contract of stopAfterDelay(duration, unit)
     * ("stop once the time since the first attempt has exceeded the delay") at the millisecond
     * resolution Attempt exposes -- the limit is rounded UP to whole ms instead of truncated.
     */
    static final class CeilStopAfterDelay implements StopStrategy {
        private final long maxDelayMillis;
        CeilStopAfterDelay(long duration, TimeUnit unit) {
            long nanos = unit.toNanos(duration);
            long ms = TimeUnit.NANOSECONDS.toMillis(nanos);
            if (TimeUnit.MILLISECONDS.toNanos(ms) < nanos) ms++;
            maxDelayMillis = ms;
        }
        @Override public boolean shouldStop(Attempt failedAttempt) {
            return failedAttempt.getDelaySinceFirstAttempt() >= maxDelayMillis;
        }
    }

    static Retryer<String> builtIn(long d, TimeUnit u) {
        return RetryerBuilder.<String>newBuilder().retryIfException()
                .withStopStrategy(StopStrategies.stopAfterDelay(d, u)).build();
    }

    static Retryer<String> oracle(long d, TimeUnit u) {
        return RetryerBuilder.<String>newBuilder().retryIfException()
                .withStopStrategy(new CeilStopAfterDelay(d, u)).build();
    }

    static String us(long nanos) { return String.format("%.1f", nanos / 1000.0); }

    static final class Result {
        final String label; final long limitNanos; final int trials;
        int ok, gaveUpAfter1, gaveUpOther, other, provenEarly;
        long lastReportedDelayMs = -1; long[] durs; long[] attempts; int n;
        Result(String label, long limitNanos, int trials) {
            this.label = label; this.limitNanos = limitNanos; this.trials = trials;
            durs = new long[trials]; attempts = new long[trials];
        }
        String durSummary() {
            long[] d = Arrays.copyOf(durs, n); Arrays.sort(d);
            return "call() duration us min/p50/max=" + us(d[0]) + "/" + us(d[n / 2]) + "/" + us(d[n - 1]);
        }
        String attemptSummary() {
            long[] a = Arrays.copyOf(attempts, n); Arrays.sort(a);
            return "attempts min/p50/max=" + a[0] + "/" + a[n / 2] + "/" + a[n - 1];
        }
    }

    interface Factory { CountingCallable make(); }

    /** Scenario A: transient failure on attempt 1, success on attempt 2. */
    static Result failOnce(String label, Retryer<String> r, long limitNanos, final long spinNanos, int trials) {
        return firstRejectedThenOk(label, r, limitNanos, new Factory() {
            public CountingCallable make() { return new FailOnceThenSucceed(spinNanos); }
        }, trials, null);
    }

    /**
     * Attempt 1 is rejected (exception or rejected result), attempt 2 would return "ok". With executor != null the
     * call goes through Retryer.wrap(...) submitted to that executor (the RetryerCallable path).
     */
    static Result firstRejectedThenOk(String label, Retryer<String> r, long limitNanos, Factory factory, int trials,
                                      ExecutorService executor) {
        Result res = new Result(label, limitNanos, trials);
        for (int i = 0; i < trials; i++) {
            CountingCallable c = factory.make();
            long t0 = System.nanoTime();
            RetryException gaveUp = null;
            String v = null;
            boolean returned = false;
            try {
                if (executor == null) {
                    v = r.call(c);
                } else {
                    Future<String> f = executor.submit(r.wrap(c));
                    v = f.get(60, TimeUnit.SECONDS);
                }
                returned = true;
            } catch (RetryException e) {
                gaveUp = e;
            } catch (ExecutionException e) {
                if (e.getCause() instanceof RetryException) gaveUp = (RetryException) e.getCause();
            } catch (Exception e) {
                // counted as "other" below
            }
            long el = System.nanoTime() - t0;
            res.durs[res.n] = el; res.attempts[res.n++] = c.invocations();
            if (returned) {
                if ("ok".equals(v) && c.invocations() == 2) res.ok++; else res.other++;
            } else if (gaveUp != null) {
                if (gaveUp.getNumberOfFailedAttempts() == 1 && c.invocations() == 1) {
                    res.gaveUpAfter1++;
                    if (el < limitNanos) res.provenEarly++;
                    res.lastReportedDelayMs = gaveUp.getLastFailedAttempt().getDelaySinceFirstAttempt();
                } else {
                    res.gaveUpOther++;
                }
            } else {
                res.other++;
            }
        }
        System.out.printf("  %-58s trials=%d  returned \"ok\"=%d  RetryException after 1 attempt=%d  other RetryException=%d  other=%d%n",
                res.label, trials, res.ok, res.gaveUpAfter1, res.gaveUpOther, res.other);
        System.out.printf("  %-58s   gave up after 1 attempt with WHOLE call() < limit (%s us): %d/%d;  %s;  lastFailedAttempt.getDelaySinceFirstAttempt()=%s%n",
                "", us(limitNanos), res.provenEarly, trials, res.durSummary(),
                res.lastReportedDelayMs < 0 ? "n/a" : res.lastReportedDelayMs + " ms");
        return res;
    }

    /** Scenario B: every attempt fails; how many attempts are made and when does call() give up? */
    static Result alwaysFail(String label, Retryer<String> r, long limitNanos, int trials) {
        Result res = new Result(label, limitNanos, trials);
        for (int i = 0; i < trials; i++) {
            AlwaysFail c = new AlwaysFail();
            long t0 = System.nanoTime();
            try {
                r.call(c);
                res.other++;
            } catch (RetryException e) {
                long el = System.nanoTime() - t0;
                res.durs[res.n] = el; res.attempts[res.n++] = e.getNumberOfFailedAttempts();
                if (e.getNumberOfFailedAttempts() == 1) {
                    res.gaveUpAfter1++;
                    if (el < limitNanos) res.provenEarly++;
                } else {
                    res.gaveUpOther++;
                }
            } catch (ExecutionException e) {
                res.other++;
            }
        }
        System.out.printf("  %-58s trials=%d  gave up after 1 attempt=%d (with WHOLE call() < limit: %d)  after >1 attempts=%d;  %s;  %s%n",
                res.label, trials, res.gaveUpAfter1, res.provenEarly, res.gaveUpOther, res.attemptSummary(), res.durSummary());
        return res;
    }

    public static void main(String[] args) throws Exception {
        final long US = 1_000L, MS = 1_000_000L;
        System.out.println("JDK TimeUnit.toMillis (used by StopStrategies.java:87): MICROSECONDS.toMillis(500)="
                + TimeUnit.MICROSECONDS.toMillis(500) + "  NANOSECONDS.toMillis(999_999)=" + TimeUnit.NANOSECONDS.toMillis(999_999)
                + "  NANOSECONDS.toMillis(1_000_000)=" + TimeUnit.NANOSECONDS.toMillis(1_000_000)
                + "  MICROSECONDS.toMillis(1900)=" + TimeUnit.MICROSECONDS.toMillis(1900));

        // Warm-up (not counted): load classes and JIT the retry loop so call() timings reflect steady state.
        Retryer<String> warm = builtIn(1, TimeUnit.MILLISECONDS);
        for (int i = 0; i < 3000; i++) {
            try { warm.call(new FailOnceThenSucceed(0)); } catch (RetryException ignored) { }
            try { builtIn(500, TimeUnit.MICROSECONDS).call(new AlwaysFail()); } catch (RetryException ignored) { }
        }

        System.out.println();
        System.out.println("[A] transient failure: attempt 1 fails immediately, attempt 2 would return \"ok\" (default noWait)");
        Result a1 = failOnce("built-in stopAfterDelay(500, MICROSECONDS)", builtIn(500, TimeUnit.MICROSECONDS), 500 * US, 0, 1000);
        Result a2 = failOnce("built-in stopAfterDelay(999_999, NANOSECONDS)", builtIn(999_999, TimeUnit.NANOSECONDS), 999_999L, 0, 1000);
        Result a3 = failOnce("CONTROL built-in stopAfterDelay(1_000_000, NANOSECONDS)", builtIn(1_000_000, TimeUnit.NANOSECONDS), 1 * MS, 0, 1000);
        Result a4 = failOnce("CONTROL oracle (ceil) for 500 MICROSECONDS", oracle(500, TimeUnit.MICROSECONDS), 500 * US, 0, 1000);

        System.out.println();
        System.out.println("[B] general shortening: attempt 1 works ~1200 us then fails, attempt 2 would return \"ok\"");
        Result b1 = failOnce("built-in stopAfterDelay(1900, MICROSECONDS)", builtIn(1900, TimeUnit.MICROSECONDS), 1900 * US, 1200 * US, 300);
        Result b2 = failOnce("CONTROL oracle (ceil) for 1900 MICROSECONDS", oracle(1900, TimeUnit.MICROSECONDS), 1900 * US, 1200 * US, 300);

        System.out.println();
        System.out.println("[C] every attempt fails immediately: how long is retrying actually kept up?");
        Result c1 = alwaysFail("built-in stopAfterDelay(500, MICROSECONDS)", builtIn(500, TimeUnit.MICROSECONDS), 500 * US, 200);
        Result c2 = alwaysFail("CONTROL oracle (ceil) for 500 MICROSECONDS", oracle(500, TimeUnit.MICROSECONDS), 500 * US, 200);

        System.out.println();
        System.out.println("[D] result-rejection path: retryIfResult(isNull()); attempt 1 returns null, attempt 2 would return \"ok\"");
        Factory nullOnce = new Factory() { public CountingCallable make() { return new NullOnceThenOk(); } };
        Result d1 = firstRejectedThenOk("built-in stopAfterDelay(500, MICROSECONDS)",
                RetryerBuilder.<String>newBuilder().retryIfResult(Predicates.<String>isNull())
                        .withStopStrategy(StopStrategies.stopAfterDelay(500, TimeUnit.MICROSECONDS)).build(),
                500 * US, nullOnce, 1000, null);
        Result d2 = firstRejectedThenOk("CONTROL built-in stopAfterDelay(1_000_000, NANOSECONDS)",
                RetryerBuilder.<String>newBuilder().retryIfResult(Predicates.<String>isNull())
                        .withStopStrategy(StopStrategies.stopAfterDelay(1_000_000, TimeUnit.NANOSECONDS)).build(),
                1 * MS, nullOnce, 1000, null);

        System.out.println();
        System.out.println("[E] Retryer.wrap(callable) submitted to an ExecutorService (RetryerCallable path), scenario A workload");
        ExecutorService ex = Executors.newSingleThreadExecutor();
        Factory failOnceNoSpin = new Factory() { public CountingCallable make() { return new FailOnceThenSucceed(0); } };
        Result e1 = firstRejectedThenOk("built-in stopAfterDelay(500, MICROSECONDS) via wrap()",
                builtIn(500, TimeUnit.MICROSECONDS), 500 * US, failOnceNoSpin, 500, ex);
        Result e2 = firstRejectedThenOk("CONTROL built-in stopAfterDelay(1_000_000, NANOSECONDS) via wrap()",
                builtIn(1_000_000, TimeUnit.NANOSECONDS), 1 * MS, failOnceNoSpin, 500, ex);
        ex.shutdown();

        boolean bugA = a1.provenEarly > 0 && a2.provenEarly > 0;
        boolean bugB = b1.provenEarly > 0;
        boolean bugC = c1.provenEarly > 0;
        boolean bugD = d1.provenEarly > 0;
        boolean bugE = e1.provenEarly > 0;
        boolean controlsOk = a3.ok >= a3.trials * 9 / 10 && a4.ok >= a4.trials * 9 / 10
                && b2.ok >= b2.trials * 9 / 10 && c2.gaveUpOther == c2.trials
                && d2.ok >= d2.trials * 9 / 10 && e2.ok >= e2.trials * 9 / 10;

        System.out.println();
        System.out.println("RESULT A (sub-ms limit -> 0 ms): " + (bugA ? "BUG TRIGGERED" : "not triggered")
                + " -- stopAfterDelay(500, MICROSECONDS): " + a1.provenEarly + "/" + a1.trials
                + " calls threw RetryException after the 1st failed attempt although the whole call() took < 500 us; "
                + "stopAfterDelay(999_999, NANOSECONDS): " + a2.provenEarly + "/" + a2.trials
                + "; 1 ns more (1_000_000 NANOSECONDS) returns \"ok\" in " + a3.ok + "/" + a3.trials + ".");
        System.out.println("RESULT B (limit shortened by up to 0.999 ms): " + (bugB ? "BUG TRIGGERED" : "not triggered")
                + " -- stopAfterDelay(1900, MICROSECONDS) gave up after 1 attempt with the whole call() < 1900 us in "
                + b1.provenEarly + "/" + b1.trials + " calls (oracle returns \"ok\" in " + b2.ok + "/" + b2.trials + ").");
        System.out.println("RESULT C (always failing): " + (bugC ? "BUG TRIGGERED" : "not triggered")
                + " -- stopAfterDelay(500, MICROSECONDS) stopped after 1 attempt, before 500 us elapsed, in "
                + c1.provenEarly + "/" + c1.trials + " calls; oracle kept retrying until >= 1 ms in " + c2.gaveUpOther + "/" + c2.trials + ".");
        System.out.println("RESULT D (rejected-result path): " + (bugD ? "BUG TRIGGERED" : "not triggered")
                + " -- " + d1.provenEarly + "/" + d1.trials + " calls gave up after 1 attempt before 500 us; control returns \"ok\" in "
                + d2.ok + "/" + d2.trials + ".");
        System.out.println("RESULT E (wrap()/executor path): " + (bugE ? "BUG TRIGGERED" : "not triggered")
                + " -- Future.get() threw ExecutionException(RetryException after 1 attempt) before 500 us in " + e1.provenEarly + "/" + e1.trials
                + " submissions; control returns \"ok\" in " + e2.ok + "/" + e2.trials + ".");
        System.out.println("CONTROLS " + (controlsOk ? "OK" : "UNEXPECTED"));
        System.exit(bugA && controlsOk ? 0 : 1);
    }
}
JAVA

if ! "$JAVAC" --release 8 -nowarn -Xlint:-options -cp "$BUILD/lib:$GUAVA_JAR:$JSR305_JAR" -d "$BUILD/repro" \
      "$BUILD/repro/ReproCRD22.java" > "$BUILD/javac-repro.log" 2>&1; then
  cat "$BUILD/javac-repro.log"; echo "ENV ERROR: repro compile failed"; exit 2
fi

echo "== running: java -cp <repro>:<unmodified lib>:guava-22.0:jsr305-2.0.2 ReproCRD22"
echo
timeout 300 "$JAVA" -cp "$BUILD/repro:$BUILD/lib:$GUAVA_JAR:$JSR305_JAR" ReproCRD22
rc=$?
echo
echo "== exit code: $rc (0 = bug reproduced, 1 = not reproduced, 124 = timeout)"
exit $rc
