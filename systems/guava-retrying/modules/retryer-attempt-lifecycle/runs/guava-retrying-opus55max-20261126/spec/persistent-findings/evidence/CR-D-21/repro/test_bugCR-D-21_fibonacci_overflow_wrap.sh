#!/usr/bin/env bash
# CR-D-21 — FibonacciWaitStrategy overflow wraps to a positive value that the guard misses
# (WaitStrategies.java:326-335 computeSleepTime, :337-352 fib), so the wait handed to the
# BlockStrategy drops below the cap instead of growing "up to the maximumTime".
#
# Self-contained: compiles the PRISTINE library sources of the target checkout (no
# instrumentation, no source edits) with JDK 21 --release 8 against Guava 22.0 + jsr305 2.0.2,
# then drives it only through public API (RetryerBuilder / Retryer.call / WaitStrategies /
# BlockStrategy / Attempt / RetryListener).
#
# Escalation ladder (single-threaded arithmetic defect, no race involved):
#   L0-A  real Retryer + built-in ThreadSleepStrategy (the default), always-failing callable,
#         neverStop, 3 s budget: shows how far a really-sleeping Retryer gets (gating).
#   L0-B  real Retryer + a user BlockStrategy (public extension point) that records each
#         designated sleep and advances a virtual clock instead of sleeping. Retryer.call hands
#         the wrapped value to BlockStrategy.block -> the defect path is reached end-to-end.
#         NOTE: this BlockStrategy does not block for the designated time, which the
#         BlockStrategy Javadoc cautions against; it is used to reach the attempt numbers.
#   L0-C  direct evaluation of the public WaitStrategy with a user-implemented Attempt (as the
#         project's own WaitStrategiesTest does) - cross-check of L0-B values.
#   L1    timing assistance: n/a (no race window; the barrier is total designated sleep time,
#         which L0-B already measures on a virtual clock).
#   L2    state injection: L0-C is the only "injection" (attempt number supplied directly); the
#         injected attempt number is reachable through Retryer.call only after the designated
#         sleeps measured below (mask M1).
#   L3    source modification: not used to create the symptom. The pristine code is only
#         compared against a temp copy carrying the recommended fix (negative control).
#   SCAN  exhaustive scan of attempt numbers 1..Integer.MAX_VALUE (the whole domain of
#         Retryer's int attempt counter) for the two finding configs and realistic caps,
#         replicating WaitStrategies.java:326-352 step for step, cross-checked against the
#         real computeSleepTime at sample points.
#   MASKS M1 time barrier before the first below-cap value; M2 guard coverage for realistic
#         caps; M3 JDK 21 Thread.sleep ms->ns saturation at attempt 94.
set -euo pipefail

SRC_DIR="${SRC_DIR:-/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-21/worktree}"
M2_REPO="${M2_REPO:-$HOME/.m2/repository}"
JAVA_HOME_21="${JAVA_HOME_21:-/usr/lib/jvm/java-21-openjdk-amd64}"
GUAVA="$M2_REPO/com/google/guava/guava/22.0/guava-22.0.jar"
JSR305="$M2_REPO/com/google/code/findbugs/jsr305/2.0.2/jsr305-2.0.2.jar"
JUNIT="$M2_REPO/junit/junit/4.11/junit-4.11.jar"
HAMCREST="$M2_REPO/org/hamcrest/hamcrest-core/1.3/hamcrest-core-1.3.jar"
JAVAC="$JAVA_HOME_21/bin/javac"
JAVA="$JAVA_HOME_21/bin/java"
JAVAP="$JAVA_HOME_21/bin/javap"

for f in "$GUAVA" "$JSR305" "$JUNIT" "$HAMCREST" "$JAVAC" "$JAVA" "$JAVAP"; do
  [[ -e "$f" ]] || { echo "missing prerequisite: $f" >&2; exit 2; }
done

WORK="$(mktemp -d /tmp/cr21.XXXXXX)"
trap 'rm -rf "$WORK"' EXIT
DEPS="$GUAVA:$JSR305"

echo "== CR-D-21 reproduction  ($(date -u +%Y-%m-%dT%H:%M:%SZ))"
echo "source checkout : $SRC_DIR"
echo "source HEAD     : $(git -C "$SRC_DIR" rev-parse HEAD 2>/dev/null || echo n/a)"
echo "source dirty?   : $(git -C "$SRC_DIR" status --porcelain 2>/dev/null | wc -l) changed paths"
echo "WaitStrategies  : sha256 $(sha256sum "$SRC_DIR/src/main/java/com/github/rholder/retry/WaitStrategies.java" | cut -c1-16)…"
echo "java            : $("$JAVA" -version 2>&1 | head -1)"
echo

echo "== build pristine library (javac --release 8, Guava 22.0, jsr305 2.0.2)"
mkdir -p "$WORK/lib"
"$JAVAC" --release 8 -nowarn -Xlint:none -cp "$DEPS" -d "$WORK/lib" \
  $(find "$SRC_DIR/src/main/java" -name '*.java') 2>&1 | grep -v -E '^(Note|warning: \[options\])' || true
ls "$WORK/lib/com/github/rholder/retry/WaitStrategies.class" >/dev/null
echo "   ok"

mkdir -p "$WORK/drv/cr21" "$WORK/drv-classes"
cat > "$WORK/drv/cr21/CR21Repro.java" <<'JAVA_EOF'
package cr21;

import com.github.rholder.retry.Attempt;
import com.github.rholder.retry.BlockStrategies;
import com.github.rholder.retry.BlockStrategy;
import com.github.rholder.retry.RetryException;
import com.github.rholder.retry.RetryListener;
import com.github.rholder.retry.Retryer;
import com.github.rholder.retry.RetryerBuilder;
import com.github.rholder.retry.StopStrategies;
import com.github.rholder.retry.WaitStrategies;
import com.github.rholder.retry.WaitStrategy;
import com.google.common.base.Predicates;

import java.math.BigDecimal;
import java.math.BigInteger;
import java.math.MathContext;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicLong;
import java.util.concurrent.atomic.AtomicReference;

/** Public-API-only driver for CR-D-21 (package cr21: package-private library types are not reachable). */
public final class CR21Repro {
    static final long LMAX = Long.MAX_VALUE;
    static final long MS_PER_HOUR = 3_600_000L;
    static final long MS_PER_DAY = 86_400_000L;
    static final long MS_PER_YEAR = 31_557_600_000L;             // Julian year
    /** JDK 21 Thread.sleep(ms) sleeps MILLISECONDS.toNanos(ms), which saturates for ms > this. */
    static final long JDK21_SAT_MS = Long.MAX_VALUE / 1_000_000L; // 9_223_372_036_854 ms = 292.47 years

    static int failures = 0;

    static void check(boolean ok, String what) {
        System.out.println((ok ? "  [ok]   " : "  [FAIL] ") + what);
        if (!ok) failures++;
    }

    static String dur(double ms) {
        if (ms < 1000) return String.format("%.0f ms", ms);
        if (ms < MS_PER_HOUR) return String.format("%.2f s", ms / 1000);
        if (ms < MS_PER_DAY) return String.format("%.2f h", ms / MS_PER_HOUR);
        if (ms < MS_PER_YEAR) return String.format("%.2f days", ms / MS_PER_DAY);
        return String.format("%.4g years", ms / MS_PER_YEAR);
    }

    static String dur(BigInteger ms) {
        return dur(new BigDecimal(ms).round(MathContext.DECIMAL64).doubleValue());
    }

    /** A user-written Attempt; Attempt is a public interface. */
    static final class UserAttempt implements Attempt<Integer> {
        final long n;
        UserAttempt(long n) { this.n = n; }
        public Integer get() { return 0; }
        public boolean hasResult() { return true; }
        public boolean hasException() { return false; }
        public Integer getResult() { return 0; }
        public Throwable getExceptionCause() { throw new IllegalStateException("result attempt"); }
        public long getAttemptNumber() { return n; }
        public long getDelaySinceFirstAttempt() { return 0L; }
    }

    /**
     * User BlockStrategy: records each designated sleep and advances a virtual clock by it
     * instead of sleeping on the wall clock (it does NOT block for the designated time).
     */
    static final class VirtualClockBlockStrategy implements BlockStrategy {
        final List<Long> requested = new ArrayList<Long>();
        public void block(long sleepTime) { requested.add(sleepTime); }
    }

    static final class Cfg {
        final String label; final WaitStrategy ws; final long m; final long cap;
        Cfg(String label, WaitStrategy ws, long m, long cap) { this.label = label; this.ws = ws; this.m = m; this.cap = cap; }
    }

    static Cfg uncapped() {
        return new Cfg("WaitStrategies.fibonacciWait()", WaitStrategies.fibonacciWait(), 1L, LMAX);
    }

    static Cfg x1000() {
        return new Cfg("WaitStrategies.fibonacciWait(1000, Long.MAX_VALUE, MILLISECONDS)",
                WaitStrategies.fibonacciWait(1000L, Long.MAX_VALUE, TimeUnit.MILLISECONDS), 1000L, LMAX);
    }

    /** Retryer.call with every attempt rejected, stopAfterAttempt(attempts), virtual-clock block strategy. */
    static List<Long> runRetryerVirtual(Cfg c, int attempts) throws Exception {
        VirtualClockBlockStrategy vc = new VirtualClockBlockStrategy();
        final AtomicLong calls = new AtomicLong();
        Retryer<Integer> retryer = RetryerBuilder.<Integer>newBuilder()
                .retryIfResult(Predicates.<Integer>alwaysTrue())
                .withWaitStrategy(c.ws)
                .withStopStrategy(StopStrategies.stopAfterAttempt(attempts))
                .withBlockStrategy(vc)
                .build();
        try {
            retryer.call(new Callable<Integer>() {
                public Integer call() { calls.incrementAndGet(); return 0; }
            });
            check(false, "Retryer.call returned although every attempt is rejected");
        } catch (RetryException e) {
            System.out.println("  Retryer.call -> RetryException after " + e.getNumberOfFailedAttempts()
                    + " attempts; callable ran " + calls.get() + "x; BlockStrategy.block called "
                    + vc.requested.size() + "x (once after each failed attempt 1.." + (attempts - 1) + ")");
        }
        return vc.requested; // requested.get(k-1) = sleep designated by Retryer.java:176-178 after failed attempt k
    }

    static int firstDecrease(List<Long> req) {
        for (int k = 2; k <= req.size(); k++) if (req.get(k - 1) < req.get(k - 2)) return k;
        return -1;
    }

    static void printWindow(List<Long> req, long cap, int lo, int hi) {
        boolean capSeen = false;
        for (int k = 1; k < lo; k++) if (req.get(k - 1) == cap) capSeen = true;
        for (int k = lo; k <= hi; k++) {
            long v = req.get(k - 1);
            long prev = req.get(k - 2);
            String mark = "";
            if (v < prev) mark += "   <-- DECREASE vs attempt " + (k - 1);
            if (capSeen && v < cap) mark += ", below the cap that attempt " + firstCapAttempt(req, cap) + " already reached";
            System.out.printf("  attempt %3d -> block(%,26d ms)  = %s%s%n", k, v, dur((double) v), mark);
            if (v == cap) capSeen = true;
        }
    }

    static int firstCapAttempt(List<Long> req, long cap) {
        for (int k = 1; k <= req.size(); k++) if (req.get(k - 1) == cap) return k;
        return -1;
    }

    /** Designated (wall-clock-honouring) time and JDK 21 effective Thread.sleep time before attempt k's wait is computed. */
    static void printBarrier(List<Long> req, int k) {
        BigInteger designated = BigInteger.ZERO, jdk21Ns = BigInteger.ZERO;
        for (int i = 1; i < k; i++) {
            long v = req.get(i - 1);
            designated = designated.add(BigInteger.valueOf(v));
            jdk21Ns = jdk21Ns.add(BigInteger.valueOf(TimeUnit.MILLISECONDS.toNanos(v)));
        }
        BigInteger jdk21Ms = jdk21Ns.divide(BigInteger.valueOf(1_000_000L));
        System.out.println("  sleeps that must complete before attempt " + k + "'s wait is computed (attempts 1.." + (k - 1) + "):");
        System.out.println("    designated total          = " + designated + " ms = " + dur(designated)
                + "   (>= 2^63-1 ms: " + (designated.compareTo(BigInteger.valueOf(LMAX)) >= 0) + ")");
        System.out.println("    JDK 21 Thread.sleep total = " + jdk21Ms + " ms = " + dur(jdk21Ms)
                + "   (each sleep saturates at Long.MAX_VALUE ns = " + dur((double) JDK21_SAT_MS) + ")");
        check(designated.compareTo(BigInteger.valueOf(LMAX)) >= 0,
                "M1 time barrier: >= 2^63-1 ms (" + dur(designated) + ") of designated sleep precede the first below-cap value");
        check(jdk21Ms.compareTo(BigInteger.valueOf(1000L * MS_PER_YEAR)) > 0,
                "M1 time barrier on JDK 21: > 1000 years (" + dur(jdk21Ms) + ") of real Thread.sleep precede it");
    }

    // ------------------------------------------------------------------ repro (L0-A/B/C, M1, M3)
    static void repro() throws Exception {
        System.out.println("### L0-B  Retryer.call -> WaitStrategy.computeSleepTime -> BlockStrategy.block (Retryer.java:176-178)");
        Cfg u = uncapped();
        System.out.println("# config: " + u.label + "  (multiplier 1, cap Long.MAX_VALUE)");
        List<Long> ru = runRetryerVirtual(u, 101);
        printWindow(ru, u.cap, 88, 100);
        int du = firstDecrease(ru);
        System.out.println("  first decrease at attempt " + du);
        check(ru.get(92) == LMAX, "attempt 93 -> block(Long.MAX_VALUE): F(93) wrapped negative, guard (:330) mapped it to the cap");
        check(ru.get(93) == 1293530146158671551L,
                "attempt 94 -> block(1293530146158671551): F(94) wrapped POSITIVE below the cap, guard did not fire");
        check(du == 94, "first decrease of the designated sleep is at attempt 94");
        printBarrier(ru, du);
        System.out.println();

        Cfg x = x1000();
        System.out.println("# config: " + x.label + "  (multiplier 1000, cap Long.MAX_VALUE)");
        List<Long> rx = runRetryerVirtual(x, 101);
        printWindow(rx, x.cap, 76, 86);
        int dx = firstDecrease(rx);
        System.out.println("  first decrease at attempt " + dx);
        check(rx.get(78) == LMAX, "attempt 79 -> block(Long.MAX_VALUE): 1000*F(79) wrapped negative, mapped to the cap");
        check(rx.get(79) == 4969984274758133384L,
                "attempt 80 -> block(4969984274758133384): 1000*F(80) wrapped POSITIVE below the cap, guard did not fire");
        check(dx == 80, "first decrease of the designated sleep is at attempt 80");
        printBarrier(rx, dx);
        System.out.println();

        System.out.println("### L0-C  direct evaluation: WaitStrategy.computeSleepTime(user Attempt) == values handed to block()");
        boolean same = true;
        for (int k = 1; k <= 100; k++) {
            same &= u.ws.computeSleepTime(new UserAttempt(k)) == ru.get(k - 1);
            same &= x.ws.computeSleepTime(new UserAttempt(k)) == rx.get(k - 1);
        }
        check(same, "direct evaluation of attempts 1..100 matches what Retryer.call passed to BlockStrategy.block");
        System.out.println();

        System.out.println("### L0-A  real Retryer with the built-in ThreadSleepStrategy (default), neverStop, 3 s budget");
        realSleepRun(u, 3000);
        realSleepRun(x, 3000);
        System.out.println();

        System.out.println("### M3  JDK " + System.getProperty("java.version") + ": Thread.sleep(ms) sleeps MILLISECONDS.toNanos(ms) (see javap above)");
        long a = TimeUnit.MILLISECONDS.toNanos(1293530146158671551L);
        long b = TimeUnit.MILLISECONDS.toNanos(LMAX);
        System.out.println("  toNanos(1293530146158671551 ms) = " + a + " ns;  toNanos(Long.MAX_VALUE ms) = " + b + " ns");
        check(a == b && a == LMAX,
                "M3: on JDK 21 ThreadSleepStrategy.block(attempt-94 value) and block(Long.MAX_VALUE) sleep the same Long.MAX_VALUE ns");
        long c = TimeUnit.MILLISECONDS.toNanos(4969984274758133384L);
        check(c == LMAX, "M3: same for the x1000 config at attempt 80 (toNanos(4969984274758133384 ms) = Long.MAX_VALUE ns)");
        System.out.println();
        System.out.println("REPRO-SUMMARY failures=" + failures);
        if (failures != 0) System.exit(1);
    }

    static void realSleepRun(final Cfg c, long budgetMs) throws Exception {
        final AtomicLong lastAttempt = new AtomicLong();
        final AtomicReference<String> outcome = new AtomicReference<String>("still running");
        final Retryer<Integer> retryer = RetryerBuilder.<Integer>newBuilder()
                .retryIfResult(Predicates.<Integer>alwaysTrue())
                .withWaitStrategy(c.ws)
                .withStopStrategy(StopStrategies.neverStop())
                .withRetryListener(new RetryListener() {
                    public <V> void onRetry(Attempt<V> attempt) { lastAttempt.set(attempt.getAttemptNumber()); }
                })
                .build(); // default block strategy = BlockStrategies.threadSleepStrategy()
        Thread t = new Thread(new Runnable() {
            public void run() {
                try {
                    retryer.call(new Callable<Integer>() { public Integer call() { return 0; } });
                    outcome.set("returned normally");
                } catch (RetryException e) {
                    outcome.set("RetryException after " + e.getNumberOfFailedAttempts()
                            + " attempts, interrupt status set=" + Thread.currentThread().isInterrupted());
                } catch (ExecutionException e) {
                    outcome.set("ExecutionException " + e);
                }
            }
        }, "cr21-real-sleep");
        long t0 = System.nanoTime();
        t.start();
        Thread.sleep(budgetMs);
        long reached = lastAttempt.get();
        Thread.State state = t.getState();
        long current = c.ws.computeSleepTime(new UserAttempt(reached));
        t.interrupt();
        t.join(10_000L);
        double wall = (System.nanoTime() - t0) / 1e9;
        System.out.printf("  %s: after %.1f s wall clock the Retryer had made %d attempts and was %s in Thread.sleep(%d ms = %s)%n",
                c.label, wall, reached, state, current, dur((double) current));
        System.out.println("    after interrupt: " + outcome.get());
        check(reached < 40 && state == Thread.State.TIMED_WAITING,
                "really-sleeping Retryer is gated by the designated sleeps (attempt " + reached + " << 94/80)");
    }

    // ------------------------------------------------------------------ exhaustive scan (M1 law, M2)
    static final long[] SAMPLES = {94L, 98L, 1_000L, 12_345L, 1_000_000L, 10_000_000L, 100_000_000L, 1_000_000_000L, Integer.MAX_VALUE};

    static void scan(Cfg c) {
        final long N = Integer.MAX_VALUE;
        final long m = c.m, cap = c.cap;
        // nStar: first attempt whose exact multiplier*F(n) exceeds the cap (exact arithmetic)
        BigInteger bm = BigInteger.valueOf(m), bcap = BigInteger.valueOf(cap), fa = BigInteger.ZERO, fb = BigInteger.ONE;
        long nStar = -1;
        for (long n = 2; nStar < 0; n++) {
            BigInteger fc = fa.add(fb); fa = fb; fb = fc;
            if (bm.multiply(fb).compareTo(bcap) > 0) nStar = n;
        }
        long[] thr = {MS_PER_HOUR, MS_PER_DAY, MS_PER_YEAR, JDK21_SAT_MS};
        String[] thrName = {"< 1 hour", "< 1 day", "< 1 year", "< 292.3 y (shorter than a saturated JDK 21 sleep)"};
        long[] thrCount = new long[4];
        long[] thrFirstN = {-1, -1, -1, -1};
        double[] thrFirstCumJ21 = new double[4];
        long escapes = 0, decreases = 0, firstEscN = -1, firstEscV = -1, minEscN = -1, minEscV = LMAX;
        double firstEscCumMs = 0, firstEscCumJ21 = 0, minEscCumMs = 0, minEscCumJ21 = 0;
        long[] sampleV = new long[SAMPLES.length];
        int si = 0;

        long prevPrev = 0L, prev = 1L;                    // F(0), F(1) as in fib() :341-342
        long r1 = m * 1L;                                 // attempt 1: fib(1) = 1
        if (r1 > cap || r1 < 0L) r1 = cap;
        long rPrev = r1 >= 0L ? r1 : 0L;
        double cumMs = rPrev;                             // sum of r(1..n-1) maintained below
        double cumJ21 = (rPrev > JDK21_SAT_MS) ? (double) JDK21_SAT_MS : rPrev;
        long t0 = System.nanoTime();
        for (long n = 2; n <= N; n++) {
            long f = prev + prevPrev; prevPrev = prev; prev = f;   // fib(n), :345-349 (unchecked)
            long result = m * f;                                   // :328 (unchecked)
            if (result > cap || result < 0L) result = cap;         // :330-332
            long r = result >= 0L ? result : 0L;                   // :334
            if (r < rPrev) decreases++;
            if (n >= nStar && r != cap) {
                escapes++;
                if (firstEscN < 0) { firstEscN = n; firstEscV = r; firstEscCumMs = cumMs; firstEscCumJ21 = cumJ21; }
                if (r < minEscV) { minEscV = r; minEscN = n; minEscCumMs = cumMs; minEscCumJ21 = cumJ21; }
                for (int i = 0; i < 4; i++) {
                    if (r < thr[i]) { thrCount[i]++; if (thrFirstN[i] < 0) { thrFirstN[i] = n; thrFirstCumJ21[i] = cumJ21; } }
                }
            }
            if (si < SAMPLES.length && n == SAMPLES[si]) { sampleV[si] = r; si++; }
            cumMs += r;
            cumJ21 += (r > JDK21_SAT_MS) ? (double) JDK21_SAT_MS : (double) r;
            rPrev = r;
        }
        double secs = (System.nanoTime() - t0) / 1e9;

        System.out.println("# " + c.label + "   multiplier=" + m + "  cap=" + cap + " ms (" + dur((double) cap) + ")");
        System.out.printf("  scanned attempts 1..%d in %.1f s; true value exceeds the cap from attempt %d on%n", N, secs, nStar);
        System.out.println("  guard escapes (value != cap at attempt >= " + nStar + "): " + escapes + "   decreases: " + decreases);
        if (escapes > 0) {
            System.out.println("  first escape: attempt " + firstEscN + " -> " + firstEscV + " ms (" + dur((double) firstEscV) + ")");
            System.out.println("    designated sleep before it ~ " + dur(firstEscCumMs) + ";  JDK 21 Thread.sleep before it ~ " + dur(firstEscCumJ21));
            System.out.println("  smallest escape: attempt " + minEscN + " -> " + minEscV + " ms (" + dur((double) minEscV) + ")");
            System.out.println("    designated sleep before it ~ " + dur(minEscCumMs) + ";  JDK 21 Thread.sleep before it ~ " + dur(minEscCumJ21));
            for (int i = 0; i < 4; i++) {
                System.out.println("  escapes " + thrName[i] + ": " + thrCount[i]
                        + (thrFirstN[i] > 0 ? " (first at attempt " + thrFirstN[i] + "; JDK 21 Thread.sleep before it ~ " + dur(thrFirstCumJ21[i]) + ")" : ""));
            }
        }
        // cross-check the replicated arithmetic against the real library at sample points
        boolean ok = true;
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < SAMPLES.length; i++) {
            long real = c.ws.computeSleepTime(new UserAttempt(SAMPLES[i]));
            ok &= real == sampleV[i];
            if (i < 3) sb.append(" n=").append(SAMPLES[i]).append(':').append(real);
        }
        if (firstEscN > 0) ok &= c.ws.computeSleepTime(new UserAttempt(firstEscN)) == firstEscV;
        if (minEscN > 0) ok &= c.ws.computeSleepTime(new UserAttempt(minEscN)) == minEscV;
        check(ok, "scan == real computeSleepTime at " + SAMPLES.length + " sample attempts (up to Integer.MAX_VALUE)"
                + (escapes > 0 ? " and at the first/smallest escape" : "") + ";" + sb);
        if (cap != LMAX) {
            boolean realistic = cap <= MS_PER_DAY;
            if (realistic) {
                check(escapes == 0 && decreases == 0,
                        "M2 guard (:330) absorbs every overflow for this realistic cap over the whole Retryer attempt domain");
            } else {
                System.out.println("  (cap > 1 day: not a realistic setting; shown for the time-to-escape law)");
                if (escapes > 0) check(firstEscCumMs > 1000.0 * MS_PER_YEAR,
                        "M1 law: designated sleep before the first escape > 1000 years (" + dur(firstEscCumMs) + ")");
            }
        } else {
            check(escapes > 0 && firstEscCumMs >= (double) LMAX,
                    "M1: every escape is preceded by >= 2^63-1 ms designated sleep (first: " + dur(firstEscCumMs) + ")");
        }
        System.out.println();
    }

    static void scanAll() {
        System.out.println("### SCAN  attempts 1..Integer.MAX_VALUE (Retryer.java:157 'int attemptNumber')");
        scan(uncapped());
        scan(x1000());
        scan(new Cfg("fibonacciWait(100, 2, MINUTES)  [README example]",
                WaitStrategies.fibonacciWait(100L, 2L, TimeUnit.MINUTES), 100L, TimeUnit.MINUTES.toMillis(2L)));
        scan(new Cfg("fibonacciWait(10, SECONDS)",
                WaitStrategies.fibonacciWait(10L, TimeUnit.SECONDS), 1L, TimeUnit.SECONDS.toMillis(10L)));
        scan(new Cfg("fibonacciWait(1, HOURS)",
                WaitStrategies.fibonacciWait(1L, TimeUnit.HOURS), 1L, TimeUnit.HOURS.toMillis(1L)));
        scan(new Cfg("fibonacciWait(1000, 1, DAYS)",
                WaitStrategies.fibonacciWait(1000L, 1L, TimeUnit.DAYS), 1000L, TimeUnit.DAYS.toMillis(1L)));
        scan(new Cfg("fibonacciWait(365, DAYS)",
                WaitStrategies.fibonacciWait(365L, TimeUnit.DAYS), 1L, TimeUnit.DAYS.toMillis(365L)));
        System.out.println("SCAN-SUMMARY failures=" + failures);
        if (failures != 0) System.exit(1);
    }

    // ------------------------------------------------------------------ fix check (negative control)
    static void fixcheck() throws Exception {
        System.out.println("### FIXCHECK  same public-API runs against a temp copy carrying the recommended fix");
        Cfg[] cfgs = {uncapped(), x1000()};
        for (Cfg c : cfgs) {
            List<Long> req = runRetryerVirtual(c, 151);
            int d = firstDecrease(req);
            int capAt = firstCapAttempt(req, c.cap);
            boolean capAfter = true;
            for (int k = capAt; k <= req.size(); k++) capAfter &= req.get(k - 1) == c.cap;
            System.out.println("  " + c.label + ": first decrease=" + d + ", cap first reached at attempt " + capAt
                    + ", attempts 93/94 -> " + req.get(92) + " / " + req.get(93));
            check(d < 0 && capAfter, "fixed: non-decreasing and pinned to the cap from attempt " + capAt + " through 150");
            long t0 = System.nanoTime();
            long big = c.ws.computeSleepTime(new UserAttempt(Integer.MAX_VALUE));
            double ms = (System.nanoTime() - t0) / 1e6;
            check(big == c.cap, String.format("fixed: computeSleepTime(Integer.MAX_VALUE) == cap (%.2f ms)", ms));
        }
        WaitStrategy readme = WaitStrategies.fibonacciWait(100L, 2L, TimeUnit.MINUTES);
        long[] want = {100, 100, 200, 300, 500, 800, 1300, 2100, 3400, 5500};
        boolean ok = true;
        for (int k = 1; k <= want.length; k++) ok &= readme.computeSleepTime(new UserAttempt(k)) == want[k - 1];
        ok &= readme.computeSleepTime(new UserAttempt(17)) == 120000L && readme.computeSleepTime(new UserAttempt(16)) == 98700L;
        check(ok, "fixed: README config still yields 100,100,200,...,98700 then 120000 from attempt 17");
        System.out.println("FIXCHECK-SUMMARY failures=" + failures);
        if (failures != 0) System.exit(1);
    }

    public static void main(String[] args) throws Exception {
        String mode = args.length > 0 ? args[0] : "repro";
        if ("repro".equals(mode)) repro();
        else if ("scan".equals(mode)) scanAll();
        else if ("fixcheck".equals(mode)) fixcheck();
        else throw new IllegalArgumentException(mode);
    }
}
JAVA_EOF

echo "== build driver (public API only, package cr21)"
"$JAVAC" -nowarn -cp "$WORK/lib:$DEPS" -d "$WORK/drv-classes" "$WORK/drv/cr21/CR21Repro.java"
echo "   ok"
echo

echo "== JDK evidence for M3: java.lang.Thread.sleep(long) on this JDK"
"$JAVAP" -c java.lang.Thread | awk '/public static void sleep\(long\) throws/{p=1} p{print} p&&/toNanos/{exit}' | sed -n '1p;/toNanos/p' || true
echo

echo "== L0 reproduction against the PRISTINE build"
REPRO_RC=0; "$JAVA" -cp "$WORK/drv-classes:$WORK/lib:$DEPS" cr21.CR21Repro repro || REPRO_RC=$?
echo

echo "== exhaustive scan against the PRISTINE build"
SCAN_RC=0; "$JAVA" -cp "$WORK/drv-classes:$WORK/lib:$DEPS" cr21.CR21Repro scan || SCAN_RC=$?
echo

echo "== negative control: recommended fix applied to a TEMP COPY (the checkout is not modified)"
mkdir -p "$WORK/fixsrc" "$WORK/fixlib"
cp -r "$SRC_DIR/src/main/java/." "$WORK/fixsrc/"
python3 - "$WORK/fixsrc/com/github/rholder/retry/WaitStrategies.java" <<'PY_EOF'
import sys
p = sys.argv[1]
s = open(p).read()
old = """        @Override
        public long computeSleepTime(Attempt failedAttempt) {
            long fib = fib(failedAttempt.getAttemptNumber());
            long result = multiplier * fib;

            if (result > maximumWait || result < 0L) {
                result = maximumWait;
            }

            return result >= 0L ? result : 0L;
        }

        private long fib(long n) {
            if (n == 0L) return 0L;
            if (n == 1L) return 1L;

            long prevPrev = 0L;
            long prev = 1L;
            long result = 0L;

            for (long i = 2L; i <= n; i++) {
                result = prev + prevPrev;
                prevPrev = prev;
                prev = result;
            }

            return result;
        }
"""
new = """        @Override
        public long computeSleepTime(Attempt failedAttempt) {
            long n = failedAttempt.getAttemptNumber();
            if (n <= 0L) {
                return 0L;
            }
            // largest Fibonacci term whose product with the multiplier stays within maximumWait
            long limit = maximumWait / multiplier;
            long prevPrev = 0L;
            long prev = 1L;
            for (long i = 2L; i <= n; i++) {
                if (prevPrev > limit - prev) {
                    return maximumWait; // F(i) * multiplier would exceed maximumWait; nothing overflowed
                }
                long next = prev + prevPrev;
                prevPrev = prev;
                prev = next;
            }
            return prev * multiplier; // prev <= limit, so this cannot overflow and is <= maximumWait
        }
"""
assert s.count(old) == 1, "pristine FibonacciWaitStrategy block not found exactly once"
open(p, "w").write(s.replace(old, new))
print("   patched temp copy:", p)
PY_EOF
"$JAVAC" --release 8 -nowarn -Xlint:none -cp "$DEPS" -d "$WORK/fixlib" \
  $(find "$WORK/fixsrc" -name '*.java') 2>&1 | grep -v -E '^(Note|warning: \[options\])' || true
FIX_RC=0; "$JAVA" -cp "$WORK/drv-classes:$WORK/fixlib:$DEPS" cr21.CR21Repro fixcheck || FIX_RC=$?
echo

echo "== upstream WaitStrategiesTest (JUnit 4.11) on pristine and fixed builds"
mkdir -p "$WORK/t-pristine" "$WORK/t-fixed"
TEST_SRC="$SRC_DIR/src/test/java/com/github/rholder/retry/WaitStrategiesTest.java"
"$JAVAC" -nowarn -cp "$WORK/lib:$DEPS:$JUNIT" -d "$WORK/t-pristine" "$TEST_SRC"
"$JAVAC" -nowarn -cp "$WORK/fixlib:$DEPS:$JUNIT" -d "$WORK/t-fixed" "$TEST_SRC"
echo "-- pristine:"; "$JAVA" -cp "$WORK/t-pristine:$WORK/lib:$DEPS:$JUNIT:$HAMCREST" org.junit.runner.JUnitCore com.github.rholder.retry.WaitStrategiesTest 2>&1 | grep -E '^(OK|FAIL|Tests run)' || true
echo "-- fixed:   "; "$JAVA" -cp "$WORK/t-fixed:$WORK/fixlib:$DEPS:$JUNIT:$HAMCREST" org.junit.runner.JUnitCore com.github.rholder.retry.WaitStrategiesTest 2>&1 | grep -E '^(OK|FAIL|Tests run)' || true
echo

echo "== RESULT"
echo "DEFECT PATH  : TRIGGERED via public API - Retryer.call handed BlockStrategy.block a wait that drops"
echo "               below the cap after the cap was reached (attempt 94: 1293530146158671551 after Long.MAX_VALUE;"
echo "               x1000 attempt 80: 4969984274758133384 after Long.MAX_VALUE)."
echo "LIVE HARM    : NOT TRIGGERED - masked: M1 (>= 2^63-1 ms designated / ~9e3 years JDK-21 real sleep before the"
echo "               first below-cap wait), M2 (guard absorbs every wrap for realistic caps over 1..Integer.MAX_VALUE),"
echo "               M3 (JDK 21 Thread.sleep saturates the attempt-94/80 values to the same Long.MAX_VALUE ns)."
echo "rc: repro=$REPRO_RC scan=$SCAN_RC fixcheck=$FIX_RC"
exit $(( REPRO_RC | SCAN_RC | FIX_RC ))
