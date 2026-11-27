#!/usr/bin/env bash
# CR-5 — Code-review Scenario 5: post-attempt decision steps (listeners, rejection
# predicate, stop, wait, block) run outside the attempt's try/catch, and the
# built-in wait/stop arithmetic is unchecked.
#
# D-16..D-22 (join overflow, exceptionWait negative/null, int counter wrap,
# incrementing overflow, Fibonacci wrap, sub-ms stopAfterDelay), MC-10 (negative
# sleep -> IAE pre-empting RetryException) and MC-7/D-8 (listener CME) are tracked
# as SEPARATE candidates. This test searches the same mechanism for OTHER defects:
#
#   Part A (Level 0, public API only): ~50 real Retryer.call() runs over every
#     built-in wait/stop strategy, the builder's rejection predicates, listeners
#     and interrupts at each decision step, judged against the documented
#     contract (Retryer.call Javadoc :146-153, factory Javadoc). Known anomalies
#     of the separate candidates are run as positive controls and labelled.
#   Part B (Level 2, public strategy API with user-implemented Attempt values
#     the real loop can reach: attempt numbers 1..Integer.MAX_VALUE, delays >= 0):
#     exhaustive arithmetic sweep of every built-in wait/stop strategy, plus an
#     exhaustive java.util.Random LCG check of the Math.abs(Long.MIN_VALUE) path.
#   Part C: O(n) fib() cost measurement (performance note).
#
# Any anomaly that is not one of the separate candidates' signatures is printed
# as [UNATTRIBUTED].
# Exit codes: 0 = sweep completed, no unattributed anomaly; 1 = unattributed
# anomaly found; 3 = build failure.
#
# Usage: test_bugCR-5_decision_step_sweep.sh [SOURCE_CHECKOUT] [BUILD_DIR]
#   JAVA_HOME_RUN selects the JDK used to run the sweep (default JDK 21).
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="${1:-$HERE/../confirmation/CR-5/worktree}"
OUT="${2:-$HERE/../confirmation/CR-5/build}"
JAVA_HOME_RUN="${JAVA_HOME_RUN:-/usr/lib/jvm/java-21-openjdk-amd64}"
GUAVA="$HOME/.m2/repository/com/google/guava/guava/22.0/guava-22.0.jar"
JSR="$HOME/.m2/repository/com/google/code/findbugs/jsr305/2.0.2/jsr305-2.0.2.jar"

echo "== CR-5 decision-step sweep"
echo "source:  $SRC  (git $(git -C "$SRC" rev-parse --short HEAD 2>/dev/null), status: $(git -C "$SRC" status --porcelain 2>/dev/null | wc -l) changed files)"
echo "guava:   $GUAVA sha1=$(sha1sum "$GUAVA" | cut -c1-40)"
echo "run JDK: $JAVA_HOME_RUN"

rm -rf "$OUT/lib-classes" "$OUT/sweep-classes" "$OUT/sweep"
mkdir -p "$OUT/lib-classes" "$OUT/sweep-classes" "$OUT/sweep"
# Build the UNMODIFIED library sources (Guava 22.0, --release 8), as in the
# target guidance's known-good recipe.
if ! javac -Xlint:-options -nowarn --release 8 -d "$OUT/lib-classes" -cp "$GUAVA:$JSR" \
      $(find "$SRC/src/main/java" -name '*.java') ; then
  echo "BUILD FAILED (library)"; exit 3
fi

cat > "$OUT/sweep/CR5Sweep.java" <<'JAVA'
import com.github.rholder.retry.Attempt;
import com.github.rholder.retry.RetryException;
import com.github.rholder.retry.RetryListener;
import com.github.rholder.retry.Retryer;
import com.github.rholder.retry.RetryerBuilder;
import com.github.rholder.retry.StopStrategies;
import com.github.rholder.retry.StopStrategy;
import com.github.rholder.retry.WaitStrategies;
import com.github.rholder.retry.WaitStrategy;
import com.google.common.base.Function;
import com.google.common.base.Predicate;
import com.google.common.base.Predicates;

import java.io.IOException;
import java.math.BigInteger;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicInteger;

import static java.util.concurrent.TimeUnit.DAYS;
import static java.util.concurrent.TimeUnit.HOURS;
import static java.util.concurrent.TimeUnit.MICROSECONDS;
import static java.util.concurrent.TimeUnit.MILLISECONDS;
import static java.util.concurrent.TimeUnit.MINUTES;
import static java.util.concurrent.TimeUnit.NANOSECONDS;
import static java.util.concurrent.TimeUnit.SECONDS;

public class CR5Sweep {
    static final BigInteger LMAX = BigInteger.valueOf(Long.MAX_VALUE);
    static final BigInteger LMIN = BigInteger.valueOf(Long.MIN_VALUE);
    static final BigInteger MILLION = BigInteger.valueOf(1000000L);
    static int nOk, nKnown, nNote;
    static long nEval;
    static final List<String> UNATTR = new ArrayList<String>();
    static final Map<String, Integer> KNOWN = new TreeMap<String, Integer>();
    static volatile long sink;

    static void ok(String id, String m) { nOk++; System.out.println("[OK]            " + id + "  " + m); }
    static void known(String tag, String id, String m) {
        nKnown++; Integer c = KNOWN.get(tag); KNOWN.put(tag, c == null ? 1 : c + 1);
        System.out.println("[SEPARATE " + tag + "]   " + id + "  " + m);
    }
    static void note(String id, String m) { nNote++; System.out.println("[NOTE]          " + id + "  " + m); }
    static void unattr(String id, String m) { UNATTR.add(id + ": " + m); System.out.println("[UNATTRIBUTED]  " + id + "  " + m); }

    // ------------------------------------------------------------------ Part A
    interface SleepCheck { String check(List<Long> s); }
    interface KnownCheck { boolean matches(Outcome o); }
    interface LongFn { long at(long n); }

    static final class Spec {
        final String id, desc; final WaitStrategy wait; final StopStrategy stop;
        String pred = "exc"; int failures = 3; String throwKind = "ioe"; boolean resultMode;
        boolean preInterrupt; long watchdogMs = 3000; int listenerInterruptAt = -1; int waitInterruptAt = -1;
        String expectKind = "RETURN"; int expectCalls = 4; SleepCheck sleepCheck;
        long stopDelayNanos = -1; int stopAfterN = -1; String knownTag; KnownCheck knownCheck;
        Spec(String id, String desc, WaitStrategy w, StopStrategy s) { this.id = id; this.desc = desc; this.wait = w; this.stop = s; }
        Spec pred(String p) { pred = p; return this; }
        Spec fail(int f) { failures = f; return this; }
        Spec thr(String k) { throwKind = k; return this; }
        Spec result() { resultMode = true; return this; }
        Spec preInt() { preInterrupt = true; return this; }
        Spec wd(long ms) { watchdogMs = ms; return this; }
        Spec lInt(int n) { listenerInterruptAt = n; return this; }
        Spec wInt(int n) { waitInterruptAt = n; return this; }
        Spec expect(String k, int calls) { expectKind = k; expectCalls = calls; return this; }
        Spec sleeps(SleepCheck c) { sleepCheck = c; return this; }
        Spec stopDelay(long ns) { stopDelayNanos = ns; return this; }
        Spec stopN(int n) { stopAfterN = n; return this; }
        Spec known(String tag, KnownCheck k) { knownTag = tag; knownCheck = k; return this; }
    }

    static final class Outcome {
        String kind, value; Throwable cause, other; int count = -1; long lastNo = -1;
        boolean flag, interruptedByUs, hung; int calls; long elapsedNs, watchdogFiredMs = -1;
        final List<Throwable> thrown = Collections.synchronizedList(new ArrayList<Throwable>());
        final List<long[]> seen = Collections.synchronizedList(new ArrayList<long[]>());
        final List<Long> sleeps = Collections.synchronizedList(new ArrayList<Long>());
    }

    static Outcome run(final Spec s) throws Exception {
        final Outcome o = new Outcome();
        final AtomicInteger calls = new AtomicInteger();
        final AtomicBoolean selfInt = new AtomicBoolean(false);
        Thread t = new Thread(new Runnable() { public void run() {
            final WaitStrategy inner = s.wait;
            // Transparent recorder: returns exactly the built-in strategy's value (or lets its exception through).
            WaitStrategy rec = new WaitStrategy() { public long computeSleepTime(Attempt a) {
                if (s.waitInterruptAt == a.getAttemptNumber()) { selfInt.set(true); Thread.currentThread().interrupt(); }
                long v = inner.computeSleepTime(a); o.sleeps.add(v); return v; } };
            RetryListener lst = new RetryListener() { public <V> void onRetry(Attempt<V> a) {
                o.seen.add(new long[]{a.getAttemptNumber(), a.getDelaySinceFirstAttempt(), a.hasException() ? 1 : 0});
                if (s.listenerInterruptAt == a.getAttemptNumber()) { selfInt.set(true); Thread.currentThread().interrupt(); } } };
            RetryerBuilder<String> b = RetryerBuilder.<String>newBuilder().withWaitStrategy(rec).withRetryListener(lst).withStopStrategy(s.stop);
            if ("exc".equals(s.pred)) b.retryIfException();
            else if ("rt".equals(s.pred)) b.retryIfRuntimeException();
            else if ("ioe".equals(s.pred)) b.retryIfExceptionOfType(IOException.class);
            else if ("pexc".equals(s.pred)) b.retryIfException(new Predicate<Throwable>() { public boolean apply(Throwable x) { return x instanceof IOException; } });
            else if ("res".equals(s.pred)) b.retryIfResult(Predicates.<String>isNull());
            Retryer<String> r = b.build();
            Callable<String> c = new Callable<String>() { public String call() throws Exception {
                int i = calls.incrementAndGet();
                if (s.failures < 0 || i <= s.failures) {
                    if (s.resultMode) return null;
                    Exception e = "ise".equals(s.throwKind) ? new IllegalStateException("fail#" + i)
                            : "rte".equals(s.throwKind) ? new RuntimeException("fail#" + i) : new IOException("fail#" + i);
                    o.thrown.add(e); throw e;
                }
                return "ok#" + i; } };
            if (s.preInterrupt) Thread.currentThread().interrupt();
            long t0 = System.nanoTime();
            try { o.value = r.call(c); o.kind = "RETURN"; }
            catch (ExecutionException e) { o.kind = "EXEC"; o.cause = e.getCause(); }
            catch (RetryException e) { o.kind = "RETRY"; o.count = e.getNumberOfFailedAttempts(); o.lastNo = e.getLastFailedAttempt().getAttemptNumber(); o.cause = e.getCause(); }
            catch (Throwable x) { o.kind = "OTHER"; o.other = x; }
            o.elapsedNs = System.nanoTime() - t0;
            o.flag = Thread.currentThread().isInterrupted();
            o.calls = calls.get(); } }, "run-" + s.id);
        t.setDaemon(true);
        long start = System.nanoTime();
        t.start();
        t.join(s.watchdogMs);
        if (t.isAlive()) { o.watchdogFiredMs = (System.nanoTime() - start) / 1000000L; t.interrupt(); t.join(5000); }
        if (t.isAlive()) o.hung = true;
        o.interruptedByUs = s.preInterrupt || o.watchdogFiredMs >= 0 || selfInt.get();
        return o;
    }

    static List<String> violations(Spec s, Outcome o) {
        List<String> v = new ArrayList<String>();
        if (o.hung) { v.add("HANG: call() did not end within watchdog+5s"); return v; }
        if ("OTHER".equals(o.kind)) v.add("undocumented exit " + o.other);
        if (s.expectKind != null && !s.expectKind.equals(o.kind)) v.add("exit " + o.kind + " but documented " + s.expectKind);
        if (s.expectCalls >= 0 && o.calls != s.expectCalls) v.add("callable ran " + o.calls + " times, documented " + s.expectCalls);
        Throwable last = o.thrown.isEmpty() ? null : o.thrown.get(o.thrown.size() - 1);
        if ("RETURN".equals(o.kind) && !("ok#" + o.calls).equals(o.value)) v.add("returned " + o.value + " but last callable value was ok#" + o.calls);
        if ("EXEC".equals(o.kind) && o.cause != last) v.add("ExecutionException cause is not the callable's last exception");
        if ("RETRY".equals(o.kind)) {
            if (o.count != o.calls) v.add("RetryException count " + o.count + " != attempts " + o.calls);
            if (o.lastNo != o.calls) v.add("lastFailedAttempt #" + o.lastNo + " != " + o.calls);
            Throwable expCause = s.resultMode ? null : last;
            if (o.cause != expCause) v.add("RetryException cause " + o.cause + " != last attempt's exception " + expCause);
            if (!o.interruptedByUs) {
                if (s.stopAfterN > 0 && o.count != s.stopAfterN) v.add("stopAfterAttempt(" + s.stopAfterN + ") stopped after " + o.count);
                if (s.stopDelayNanos >= 0 && o.elapsedNs < s.stopDelayNanos)
                    v.add("stopAfterDelay stopped after " + o.elapsedNs + " ns (whole call) < requested " + s.stopDelayNanos + " ns");
            }
        }
        if (o.interruptedByUs && !o.flag) v.add("thread was interrupted but the interrupt status is not set at exit");
        if (!o.interruptedByUs && o.flag) v.add("interrupt status set although nobody interrupted");
        if (o.seen.size() != o.calls) v.add("listener notified " + o.seen.size() + " times for " + o.calls + " attempts");
        long prevD = 0;
        for (int i = 0; i < o.seen.size(); i++) {
            long[] a = o.seen.get(i);
            if (a[0] != i + 1) { v.add("listener: attempt " + (i + 1) + " reported number " + a[0]); break; }
            if (a[1] < prevD || a[1] < 0) { v.add("delaySinceFirstAttempt not monotone at attempt " + (i + 1)); break; }
            prevD = a[1];
            boolean failed = s.failures < 0 || (i + 1) <= s.failures;
            long expExc = (failed && !s.resultMode) ? 1 : 0;
            if (a[2] != expExc) { v.add("attempt " + (i + 1) + " hasException=" + a[2]); break; }
        }
        for (Long x : o.sleeps) if (x < 0) { v.add("negative computed sleep " + x); break; }
        if (s.sleepCheck != null) { String e = s.sleepCheck.check(o.sleeps); if (e != null) v.add(e); }
        return v;
    }

    static String cn(Throwable t) { return t == null ? "null" : t.getClass().getSimpleName() + ":" + t.getMessage(); }
    static String head(List<Long> l, int k) {
        synchronized (l) {
            StringBuilder b = new StringBuilder("[");
            for (int i = 0; i < Math.min(k, l.size()); i++) { if (i > 0) b.append(','); b.append(l.get(i)); }
            if (l.size() > k) b.append(",...(+").append(l.size() - k).append(')');
            return b.append(']').toString();
        }
    }
    static String summary(Outcome o) {
        StringBuilder b = new StringBuilder(String.valueOf(o.kind));
        if ("RETURN".equals(o.kind)) b.append('(').append(o.value).append(')');
        if ("EXEC".equals(o.kind)) b.append("(cause=").append(cn(o.cause)).append(')');
        if ("RETRY".equals(o.kind)) b.append("(count=").append(o.count).append(",last#=").append(o.lastNo).append(",cause=").append(cn(o.cause)).append(')');
        if ("OTHER".equals(o.kind)) b.append('(').append(o.other).append(')');
        b.append(" calls=").append(o.calls).append(" flag=").append(o.flag).append(" sleeps=").append(head(o.sleeps, 6));
        b.append(String.format(" elapsed=%.3fms", o.elapsedNs / 1e6));
        if (o.watchdogFiredMs >= 0) b.append(" watchdog-interrupt@").append(o.watchdogFiredMs).append("ms");
        if (o.hung) b.append(" HUNG");
        return b.toString();
    }

    static void judge(Spec s) throws Exception {
        Outcome o = run(s);
        List<String> v = violations(s, o);
        String sum = s.desc + " -> " + summary(o);
        if (s.knownTag != null && s.knownCheck.matches(o)) { known(s.knownTag, s.id, sum); return; }
        if (s.knownTag != null && v.isEmpty()) { note(s.id, "control for " + s.knownTag + " not observed this run; outcome documented: " + sum); return; }
        if (v.isEmpty()) ok(s.id, sum); else unattr(s.id, sum + "  VIOLATIONS " + v);
    }

    static LongFn c(final long v) { return new LongFn() { public long at(long n) { return v; } }; }
    static long clampSat(BigInteger e) { return e.signum() < 0 ? 0L : (e.compareTo(LMAX) > 0 ? Long.MAX_VALUE : e.longValue()); }
    static LongFn inc(final long i, final long d) { return new LongFn() { public long at(long n) {
        return clampSat(BigInteger.valueOf(i).add(BigInteger.valueOf(d).multiply(BigInteger.valueOf(n - 1)))); } }; }
    static LongFn expo(final long m, final long cap) { return new LongFn() { public long at(long n) {
        BigInteger e = n > 200 ? LMAX.add(BigInteger.ONE) : BigInteger.valueOf(m).shiftLeft((int) n);
        return e.min(BigInteger.valueOf(cap)).longValue(); } }; }
    static final BigInteger[] FIB = new BigInteger[400];
    static { FIB[0] = BigInteger.ZERO; FIB[1] = BigInteger.ONE; for (int i = 2; i < FIB.length; i++) FIB[i] = FIB[i - 1].add(FIB[i - 2]); }
    static BigInteger fibExact(long n) { return n < FIB.length ? FIB[(int) n] : LMAX.multiply(LMAX); }
    static LongFn fibo(final long m, final long cap) { return new LongFn() { public long at(long n) {
        return BigInteger.valueOf(m).multiply(fibExact(n)).min(BigInteger.valueOf(cap)).longValue(); } }; }
    static SleepCheck exact(final LongFn f) { return new SleepCheck() { public String check(List<Long> s) {
        synchronized (s) { for (int i = 0; i < s.size(); i++) { long e = f.at(i + 1);
            if (s.get(i) != e) return "sleep after attempt " + (i + 1) + " = " + s.get(i) + ", documented " + e; } } return null; } }; }
    static SleepCheck range(final LongFn lo, final LongFn hiExcl) { return new SleepCheck() { public String check(List<Long> s) {
        synchronized (s) { for (int i = 0; i < s.size(); i++) { long l = lo.at(i + 1), h = hiExcl.at(i + 1);
            if (s.get(i) < l || s.get(i) >= h) return "sleep after attempt " + (i + 1) + " = " + s.get(i) + " outside [" + l + "," + h + ")"; } } return null; } }; }
    static boolean nondecreasing(List<Long> s) { synchronized (s) { for (int i = 1; i < s.size(); i++) if (s.get(i) < s.get(i - 1)) return false; } return true; }
    static boolean stackHas(Throwable t, String cls) { for (StackTraceElement e : t.getStackTrace()) if (e.getClassName().contains(cls)) return true; return false; }

    static KnownCheck iaeNegativeSleep() { return new KnownCheck() { public boolean matches(Outcome o) {
        return "OTHER".equals(o.kind) && o.other instanceof IllegalArgumentException && String.valueOf(o.other.getMessage()).contains("negative")
                && !o.sleeps.isEmpty() && o.sleeps.get(o.sleeps.size() - 1) < 0; } }; }
    static KnownCheck npeInExceptionWait() { return new KnownCheck() { public boolean matches(Outcome o) {
        return "OTHER".equals(o.kind) && o.other instanceof NullPointerException && stackHas(o.other, "ExceptionWaitStrategy"); } }; }
    static KnownCheck decreasingSleeps() { return new KnownCheck() { public boolean matches(Outcome o) {
        return "RETRY".equals(o.kind) && !nondecreasing(o.sleeps); } }; }
    static KnownCheck earlyStop(final long reqNs) { return new KnownCheck() { public boolean matches(Outcome o) {
        return "RETRY".equals(o.kind) && !o.interruptedByUs && o.elapsedNs < reqNs; } }; }
    static KnownCheck iaePreemptsInterrupt() { return new KnownCheck() { public boolean matches(Outcome o) {
        return o.interruptedByUs && o.flag && "OTHER".equals(o.kind) && o.other instanceof IllegalArgumentException; } }; }

    static <T extends Throwable> Function<T, Long> fn(final Long v) { return new Function<T, Long>() { public Long apply(T x) { return v; } }; }

    static void warmup() throws Exception {
        for (int i = 0; i < 200; i++) {
            Retryer<String> r = RetryerBuilder.<String>newBuilder().retryIfException().withStopStrategy(StopStrategies.stopAfterAttempt(2)).build();
            try { r.call(new Callable<String>() { public String call() throws Exception { throw new IOException("w"); } }); } catch (RetryException e) { sink += e.getNumberOfFailedAttempts(); }
        }
    }

    static void partA() throws Exception {
        System.out.println("\n---- Part A: Level 0, real Retryer.call() (default ThreadSleepStrategy), documented-contract oracle");
        StopStrategy ten = StopStrategies.stopAfterAttempt(10), never = StopStrategies.neverStop();
        List<Spec> L = new ArrayList<Spec>();
        // Wait strategies, callable fails 3 times then succeeds -> documented RETURN(ok#4)
        L.add(new Spec("W01", "noWait()", WaitStrategies.noWait(), ten).sleeps(exact(c(0))));
        L.add(new Spec("W02", "fixedWait(0ms)", WaitStrategies.fixedWait(0, MILLISECONDS), ten).sleeps(exact(c(0))));
        L.add(new Spec("W03", "fixedWait(3ms)", WaitStrategies.fixedWait(3, MILLISECONDS), ten).sleeps(exact(c(3))));
        L.add(new Spec("W04", "fixedWait(999us) [ms resolution per WaitStrategy Javadoc]", WaitStrategies.fixedWait(999, MICROSECONDS), ten).sleeps(exact(c(0))));
        L.add(new Spec("W05", "randomWait(1ms)", WaitStrategies.randomWait(1, MILLISECONDS), ten).sleeps(range(c(0), c(1))));
        L.add(new Spec("W06", "randomWait(5ms)", WaitStrategies.randomWait(5, MILLISECONDS), ten).sleeps(range(c(0), c(5))));
        L.add(new Spec("W07", "randomWait(2ms,6ms)", WaitStrategies.randomWait(2, MILLISECONDS, 6, MILLISECONDS), ten).sleeps(range(c(2), c(6))));
        L.add(new Spec("W08", "incrementingWait(1ms,+2ms)", WaitStrategies.incrementingWait(1, MILLISECONDS, 2, MILLISECONDS), ten).sleeps(exact(inc(1, 2))));
        L.add(new Spec("W09", "incrementingWait(5ms,-2ms) [negative increment]", WaitStrategies.incrementingWait(5, MILLISECONDS, -2, MILLISECONDS), ten).sleeps(exact(inc(5, -2))));
        L.add(new Spec("W10", "incrementingWait(1ms,-5ms) [clamped at 0]", WaitStrategies.incrementingWait(1, MILLISECONDS, -5, MILLISECONDS), ten).sleeps(exact(inc(1, -5))));
        L.add(new Spec("W11", "exponentialWait()", WaitStrategies.exponentialWait(), ten).sleeps(exact(expo(1, Long.MAX_VALUE))));
        L.add(new Spec("W12", "exponentialWait(20ms)", WaitStrategies.exponentialWait(20, MILLISECONDS), ten).sleeps(exact(expo(1, 20))));
        L.add(new Spec("W13", "exponentialWait(3,20ms)", WaitStrategies.exponentialWait(3, 20, MILLISECONDS), ten).sleeps(exact(expo(3, 20))));
        L.add(new Spec("W14", "fibonacciWait()", WaitStrategies.fibonacciWait(), ten).sleeps(exact(fibo(1, Long.MAX_VALUE))));
        L.add(new Spec("W15", "fibonacciWait(5ms)", WaitStrategies.fibonacciWait(5, MILLISECONDS), ten).sleeps(exact(fibo(1, 5))));
        L.add(new Spec("W16", "fibonacciWait(3,10ms)", WaitStrategies.fibonacciWait(3, 10, MILLISECONDS), ten).sleeps(exact(fibo(3, 10))));
        L.add(new Spec("W17", "exceptionWait(IOException, ->4)", WaitStrategies.exceptionWait(IOException.class, CR5Sweep.<IOException>fn(4L)), ten).sleeps(exact(c(4))));
        L.add(new Spec("W18", "exceptionWait(RuntimeException, ->4) on IOException [no match -> 0]", WaitStrategies.exceptionWait(RuntimeException.class, CR5Sweep.<RuntimeException>fn(4L)), ten).sleeps(exact(c(0))));
        L.add(new Spec("W19", "exceptionWait(IOException, ->0)", WaitStrategies.exceptionWait(IOException.class, CR5Sweep.<IOException>fn(0L)), ten).sleeps(exact(c(0))));
        L.add(new Spec("W20", "join(fixed 1ms, random 2ms, exponential(4ms))",
                WaitStrategies.join(WaitStrategies.fixedWait(1, MILLISECONDS), WaitStrategies.randomWait(2, MILLISECONDS), WaitStrategies.exponentialWait(4, MILLISECONDS)), ten)
                .sleeps(range(new LongFn() { public long at(long n) { return 1 + expo(1, 4).at(n); } }, new LongFn() { public long at(long n) { return 3 + expo(1, 4).at(n); } })));
        L.add(new Spec("W21", "join(noWait())", WaitStrategies.join(WaitStrategies.noWait()), ten).sleeps(exact(c(0))));
        L.add(new Spec("W22", "exponentialWait(Long.MAX_VALUE DAYS) [saturating cap]", WaitStrategies.exponentialWait(Long.MAX_VALUE, DAYS), ten).sleeps(exact(expo(1, Long.MAX_VALUE))));
        L.add(new Spec("W23", "fibonacciWait(7, Long.MAX_VALUE DAYS)", WaitStrategies.fibonacciWait(7, Long.MAX_VALUE, DAYS), ten).sleeps(exact(fibo(7, Long.MAX_VALUE))));
        // Saturating toMillis -> Long.MAX_VALUE sleep ("forever"): documented exit is RetryException + interrupt status after an interrupt
        L.add(new Spec("W24", "fixedWait(Long.MAX_VALUE DAYS) [saturates], neverStop, interrupt after 300ms", WaitStrategies.fixedWait(Long.MAX_VALUE, DAYS), never)
                .fail(-1).wd(300).expect("RETRY", 1).sleeps(exact(c(Long.MAX_VALUE))));
        L.add(new Spec("W25", "join(fixedWait(Long.MAX_VALUE DAYS), noWait()), interrupt after 300ms", WaitStrategies.join(WaitStrategies.fixedWait(Long.MAX_VALUE, DAYS), WaitStrategies.noWait()), never)
                .fail(-1).wd(300).expect("RETRY", 1).sleeps(exact(c(Long.MAX_VALUE))));
        L.add(new Spec("W26", "randomWait(0, Long.MAX_VALUE DAYS), interrupt after 300ms", WaitStrategies.randomWait(0, MILLISECONDS, Long.MAX_VALUE, DAYS), never)
                .fail(-1).wd(300).expect("RETRY", 1).sleeps(range(c(0), c(Long.MAX_VALUE))));
        L.add(new Spec("W27", "incrementingWait(Long.MAX_VALUE DAYS, 0), interrupt after 300ms", WaitStrategies.incrementingWait(Long.MAX_VALUE, DAYS, 0, MILLISECONDS), never)
                .fail(-1).wd(300).expect("RETRY", 1).sleeps(exact(c(Long.MAX_VALUE))));
        // Stop strategies
        L.add(new Spec("S01", "stopAfterAttempt(1), always failing", WaitStrategies.noWait(), StopStrategies.stopAfterAttempt(1)).fail(-1).expect("RETRY", 1).stopN(1));
        L.add(new Spec("S02", "stopAfterAttempt(3) + fixedWait(1ms), always failing", WaitStrategies.fixedWait(1, MILLISECONDS), StopStrategies.stopAfterAttempt(3)).fail(-1).expect("RETRY", 3).stopN(3).sleeps(exact(c(1))));
        L.add(new Spec("S03", "stopAfterAttempt(Integer.MAX_VALUE), success at #4", WaitStrategies.noWait(), StopStrategies.stopAfterAttempt(Integer.MAX_VALUE)));
        L.add(new Spec("S04", "stopAfterDelay(0ms), always failing", WaitStrategies.noWait(), StopStrategies.stopAfterDelay(0, MILLISECONDS)).fail(-1).expect("RETRY", 1).stopDelay(0));
        L.add(new Spec("S05", "stopAfterDelay(30ms) + fixedWait(5ms), always failing", WaitStrategies.fixedWait(5, MILLISECONDS), StopStrategies.stopAfterDelay(30, MILLISECONDS)).fail(-1).expect("RETRY", -1).stopDelay(30000000L).sleeps(exact(c(5))));
        L.add(new Spec("S06", "stopAfterDelay(30ms) + noWait, always failing", WaitStrategies.noWait(), StopStrategies.stopAfterDelay(30, MILLISECONDS)).fail(-1).expect("RETRY", -1).stopDelay(30000000L));
        L.add(new Spec("S07", "stopAfterDelay(Long.MAX_VALUE DAYS) [saturates], success at #4", WaitStrategies.noWait(), StopStrategies.stopAfterDelay(Long.MAX_VALUE, DAYS)));
        @SuppressWarnings("deprecation") StopStrategy dep = StopStrategies.stopAfterDelay(20L);
        L.add(new Spec("S08", "stopAfterDelay(20) [deprecated ms overload] + fixedWait(3ms)", WaitStrategies.fixedWait(3, MILLISECONDS), dep).fail(-1).expect("RETRY", -1).stopDelay(20000000L).sleeps(exact(c(3))));
        L.add(new Spec("S09", "neverStop, success at #6", WaitStrategies.noWait(), never).fail(5).expect("RETURN", 6));
        L.add(new Spec("S10", "stopAfterDelay(25ms) + exponentialWait(3,20ms)", WaitStrategies.exponentialWait(3, 20, MILLISECONDS), StopStrategies.stopAfterDelay(25, MILLISECONDS)).fail(-1).expect("RETRY", -1).stopDelay(25000000L).sleeps(exact(expo(3, 20))));
        L.add(new Spec("S11", "stopAfterAttempt(5) + fibonacciWait(2,8ms)", WaitStrategies.fibonacciWait(2, 8, MILLISECONDS), StopStrategies.stopAfterAttempt(5)).fail(-1).expect("RETRY", 5).stopN(5).sleeps(exact(fibo(2, 8))));
        // Rejection predicates
        L.add(new Spec("P01", "retryIfRuntimeException + IOException -> not rejected", WaitStrategies.noWait(), ten).pred("rt").fail(-1).expect("EXEC", 1));
        L.add(new Spec("P02", "retryIfRuntimeException + IllegalStateException x3", WaitStrategies.noWait(), ten).pred("rt").thr("ise"));
        L.add(new Spec("P03", "retryIfExceptionOfType(IOException) + RuntimeException", WaitStrategies.noWait(), ten).pred("ioe").thr("rte").fail(-1).expect("EXEC", 1));
        L.add(new Spec("P04", "retryIfException(Predicate instanceof IOException) x3", WaitStrategies.noWait(), ten).pred("pexc"));
        L.add(new Spec("P05", "retryIfResult(isNull) always null + stopAfterAttempt(2)", WaitStrategies.noWait(), StopStrategies.stopAfterAttempt(2)).pred("res").result().fail(-1).expect("RETRY", 2).stopN(2));
        L.add(new Spec("P06", "no retryIf (alwaysFalse) + IOException", WaitStrategies.noWait(), ten).pred("none").fail(-1).expect("EXEC", 1));
        L.add(new Spec("P07", "retryIfResult(isNull) null x3", WaitStrategies.noWait(), ten).pred("res").result());
        // Interrupt at each decision step, built-in strategies
        L.add(new Spec("I01", "pre-interrupted + noWait + neverStop", WaitStrategies.noWait(), never).preInt().fail(-1).expect("RETRY", 1));
        L.add(new Spec("I02", "pre-interrupted + fixedWait(5ms) + stopAfterAttempt(5)", WaitStrategies.fixedWait(5, MILLISECONDS), StopStrategies.stopAfterAttempt(5)).preInt().fail(-1).expect("RETRY", 1));
        L.add(new Spec("I03", "interrupt during fixedWait(10s) sleep", WaitStrategies.fixedWait(10, SECONDS), never).fail(-1).wd(150).expect("RETRY", 1));
        L.add(new Spec("I04", "interrupt while listeners run (attempt 2) + noWait", WaitStrategies.noWait(), never).lInt(2).fail(-1).expect("RETRY", 2));
        L.add(new Spec("I05", "interrupt while the wait is computed (attempt 2) + fixedWait(1ms)", WaitStrategies.fixedWait(1, MILLISECONDS), never).wInt(2).fail(-1).expect("RETRY", 2));
        L.add(new Spec("I06", "pre-interrupted + stopAfterAttempt(1) [stop exit]", WaitStrategies.noWait(), StopStrategies.stopAfterAttempt(1)).preInt().fail(-1).expect("RETRY", 1));
        L.add(new Spec("I07", "pre-interrupted + first attempt succeeds", WaitStrategies.noWait(), never).preInt().fail(0).expect("RETURN", 1));
        L.add(new Spec("I08", "pre-interrupted + retryIfRuntimeException + IOException", WaitStrategies.noWait(), never).pred("rt").preInt().fail(-1).expect("EXEC", 1));
        L.add(new Spec("I09", "pre-interrupted + exponentialWait()", WaitStrategies.exponentialWait(), never).preInt().fail(-1).expect("RETRY", 1));
        L.add(new Spec("I10", "pre-interrupted + randomWait(1ms) [always 0]", WaitStrategies.randomWait(1, MILLISECONDS), never).preInt().fail(-1).expect("RETRY", 1));
        // Positive controls: signatures of the SEPARATE candidates (not CR-5's own claim)
        L.add(new Spec("K16a", "join(fixedWait(Long.MAX_VALUE ms), fixedWait(1s))", WaitStrategies.join(WaitStrategies.fixedWait(Long.MAX_VALUE, MILLISECONDS), WaitStrategies.fixedWait(1, SECONDS)), never)
                .fail(-1).wd(300).expect("RETRY", 1).known("D-16", iaeNegativeSleep()));
        L.add(new Spec("K16b", "join(fixedWait(Long.MAX_VALUE DAYS), fixedWait(1ms))", WaitStrategies.join(WaitStrategies.fixedWait(Long.MAX_VALUE, DAYS), WaitStrategies.fixedWait(1, MILLISECONDS)), never)
                .fail(-1).wd(300).expect("RETRY", 1).known("D-16", iaeNegativeSleep()));
        L.add(new Spec("K17", "exceptionWait(IOException, ->-5)", WaitStrategies.exceptionWait(IOException.class, CR5Sweep.<IOException>fn(-5L)), never)
                .fail(-1).expect("RETRY", -1).known("D-17", iaeNegativeSleep()));
        L.add(new Spec("K18", "exceptionWait(IOException, ->null)", WaitStrategies.exceptionWait(IOException.class, CR5Sweep.<IOException>fn(null)), never)
                .fail(-1).expect("RETRY", -1).known("D-18", npeInExceptionWait()));
        L.add(new Spec("K20", "incrementingWait(20ms, +Long.MAX_VALUE ms) + stopAfterAttempt(4)", WaitStrategies.incrementingWait(20, MILLISECONDS, Long.MAX_VALUE, MILLISECONDS), StopStrategies.stopAfterAttempt(4))
                .fail(-1).expect("RETRY", 4).stopN(4).sleeps(exact(inc(20, Long.MAX_VALUE))).known("D-20", decreasingSleeps()));
        L.add(new Spec("K22", "stopAfterDelay(500us) + noWait", WaitStrategies.noWait(), StopStrategies.stopAfterDelay(500, MICROSECONDS))
                .fail(-1).expect("RETRY", -1).stopDelay(500000L).known("D-22", earlyStop(500000L)));
        L.add(new Spec("K10", "pre-interrupted + exceptionWait(->-5)", WaitStrategies.exceptionWait(IOException.class, CR5Sweep.<IOException>fn(-5L)), never)
                .preInt().fail(-1).expect("RETRY", 1).known("MC-10/D-17", iaePreemptsInterrupt()));
        for (Spec s : L) judge(s);
    }

    // ------------------------------------------------------------------ Part B
    static final class Att implements Attempt<Object> {
        final long n, d; final Throwable cause;
        Att(long n, long d) { this(n, d, new IOException("x")); }
        Att(long n, long d, Throwable cause) { this.n = n; this.d = d; this.cause = cause; }
        public Object get() throws ExecutionException { throw new ExecutionException(cause); }
        public boolean hasResult() { return false; }
        public boolean hasException() { return true; }
        public Object getResult() { throw new IllegalStateException("exception attempt"); }
        public Throwable getExceptionCause() { return cause; }
        public long getAttemptNumber() { return n; }
        public long getDelaySinceFirstAttempt() { return d; }
    }

    static long[] nlist(int upto, long... extra) {
        long[] r = new long[upto + extra.length];
        for (int i = 0; i < upto; i++) r[i] = i + 1;
        for (int i = 0; i < extra.length; i++) r[upto + i] = extra[i];
        return r;
    }

    static final class Fam {
        final String id; long evals, configs; int unattr; final Map<String, Integer> known = new TreeMap<String, Integer>();
        final List<String> knownEx = new ArrayList<String>();
        Fam(String id) { this.id = id; }
        void k(String tag, String ex) { Integer c = known.get(tag); known.put(tag, c == null ? 1 : c + 1); if (knownEx.size() < 3) knownEx.add(ex); }
        void u(String m) { unattr++; unattr(id, m); }
        void done(String what) {
            nEval += evals;
            String line = what + ": " + configs + " configs, " + evals + " evaluations, unattributed=" + unattr + (known.isEmpty() ? "" : ", known " + known + " e.g. " + knownEx);
            for (String t : known.keySet()) { Integer c = KNOWN.get(t); KNOWN.put(t, (c == null ? 0 : c) + known.get(t)); }
            if (unattr == 0 && known.isEmpty()) ok(id, line);
            else if (unattr == 0) { nKnown++; System.out.println("[SEPARATE " + known.keySet() + "]  " + id + "  " + line); }
            else System.out.println("[SUMMARY]       " + id + "  " + line);
        }
    }

    static void b1Exponential() {
        Fam f = new Fam("B1");
        long[] Ms = {1, 2, 3, 7, 100, 1000, 1L << 20, 1L << 40, 1L << 52, (1L << 53) + 1, 1L << 62, Long.MAX_VALUE - 1};
        long[] Cs = {50, 300000L, 86400000L, Long.MAX_VALUE / 2, Long.MAX_VALUE, 0};
        long[] ns = nlist(130, 1000, 1000000, Integer.MAX_VALUE);
        for (long m : Ms) for (int ci = 0; ci < Cs.length; ci++) {
            long cap = ci == Cs.length - 1 ? m + 1 : Cs[ci];
            if (!(m < cap)) continue;
            WaitStrategy w = WaitStrategies.exponentialWait(m, cap, MILLISECONDS); f.configs++;
            long prev = -1; LongFn doc = expo(m, cap);
            for (long n : ns) {
                long s = w.computeSleepTime(new Att(n, 0)); f.evals++;
                long e = doc.at(n);
                double rel = e == 0 ? Math.abs((double) s) : Math.abs((double) s - (double) e) / (double) e;
                if (s < 0 || s > cap || s < prev || rel > 1e-12)
                    f.u("exponentialWait(" + m + "," + cap + "ms) n=" + n + " -> " + s + " (documented min(cap, m*2^n)=" + e + ", prev=" + prev + ")");
                prev = s;
            }
        }
        // factory variants
        WaitStrategy[] ws = {WaitStrategies.exponentialWait(), WaitStrategies.exponentialWait(Long.MAX_VALUE, DAYS), WaitStrategies.exponentialWait(5, MINUTES)};
        long[] caps = {Long.MAX_VALUE, Long.MAX_VALUE, 300000L};
        for (int i = 0; i < ws.length; i++) { long prev = -1; f.configs++;
            for (long n : ns) { long s = ws[i].computeSleepTime(new Att(n, 0)); f.evals++; long e = expo(1, caps[i]).at(n);
                if (s < 0 || s > caps[i] || s < prev || s != e) f.u("exponential factory#" + i + " n=" + n + " -> " + s + " documented " + e); prev = s; } }
        f.done("ExponentialWait: >=0, <=cap, non-decreasing, = min(cap, m*2^n) (double rel.err <= 1e-12)");
    }

    static void b2Fibonacci() {
        Fam f = new Fam("B2");
        long[] Ms = {1, 3, 100, 1000, 1L << 20};
        long[] Cs = {50, 120000L, 3600000L, Long.MAX_VALUE / 2, Long.MAX_VALUE, 0};
        long[] ns = nlist(200, 1000, 100000);
        for (long m : Ms) for (int ci = 0; ci < Cs.length; ci++) {
            long cap = ci == Cs.length - 1 ? m + 1 : Cs[ci];
            if (!(m < cap)) continue;
            WaitStrategy w = WaitStrategies.fibonacciWait(m, cap, MILLISECONDS); f.configs++;
            long prev = -1;
            for (long n : ns) {
                long s = w.computeSleepTime(new Att(n, 0)); f.evals++;
                BigInteger prod = BigInteger.valueOf(m).multiply(fibExact(n));
                long e = prod.min(BigInteger.valueOf(cap)).longValue();
                boolean bad = s < 0 || s > cap || s != e || s < prev;
                if (bad) {
                    boolean overflowed = fibExact(n).compareTo(LMAX) > 0 || prod.compareTo(LMAX) > 0;
                    if (overflowed) f.k("D-21", "fibonacciWait(" + m + "," + cap + ") n=" + n + " -> " + s + " (documented " + e + ")");
                    else f.u("fibonacciWait(" + m + "," + cap + "ms) n=" + n + " -> " + s + " documented " + e + " prev " + prev);
                }
                prev = s;
            }
        }
        // upstream-test style extreme attempt number with realistic caps (2^31-1 loop iterations each)
        long[][] big = {{1, 10}, {1000, 50000}};
        for (long[] mc : big) {
            long s = WaitStrategies.fibonacciWait(mc[0], mc[1], MILLISECONDS).computeSleepTime(new Att(Integer.MAX_VALUE, 0)); f.evals++; f.configs++;
            if (s != mc[1]) f.k("D-21", "fibonacciWait(" + mc[0] + "," + mc[1] + ") at n=Integer.MAX_VALUE -> " + s + " (cap " + mc[1] + ", fib overflowed)");
        }
        f.done("FibonacciWait: >=0, <=cap, = min(cap, m*fib(n)), non-decreasing; overflow-caused deviations -> D-21");
    }

    static void b3Incrementing() {
        Fam f = new Fam("B3");
        long[] Is = {0, 1, 500, 3600000};
        long[] Ds = {0, 1, 100, 1000, 3600000, 1L << 32, 1L << 40, Long.MAX_VALUE / 2, Long.MAX_VALUE, -1, -100, -3600000, Long.MIN_VALUE / 2, Long.MIN_VALUE + 1, Long.MIN_VALUE};
        long[] ns = nlist(1000, 1000000, 1000000000, Integer.MAX_VALUE);
        for (long i0 : Is) for (long d : Ds) {
            WaitStrategy w = WaitStrategies.incrementingWait(i0, MILLISECONDS, d, MILLISECONDS); f.configs++;
            for (long n : ns) {
                long s = w.computeSleepTime(new Att(n, 0)); f.evals++;
                BigInteger prodX = BigInteger.valueOf(d).multiply(BigInteger.valueOf(n - 1));
                BigInteger exact = BigInteger.valueOf(i0).add(prodX);
                long e = clampSat(exact);
                if (s != e || s < 0) {
                    boolean overflow = prodX.compareTo(LMAX) > 0 || prodX.compareTo(LMIN) < 0 || exact.compareTo(LMAX) > 0 || exact.compareTo(LMIN) < 0;
                    if (overflow) f.k("D-20", "incrementingWait(" + i0 + "," + d + ") n=" + n + " -> " + s + " (documented " + e + (d < 0 ? ", negative-increment variant" : "") + ")");
                    else f.u("incrementingWait(" + i0 + "," + d + ") n=" + n + " -> " + s + " documented " + e);
                }
            }
        }
        f.done("IncrementingWait: = clamp(initial + increment*(n-1)) without overflow; overflow-caused deviations -> D-20");
        // Variant evidence, same unchecked expression (WaitStrategies.java:282): a negative increment wraps upward.
        WaitStrategy neg = WaitStrategies.incrementingWait(500, MILLISECONDS, Long.MIN_VALUE / 2, MILLISECONDS);
        StringBuilder vb = new StringBuilder();
        for (long n = 1; n <= 5; n++) vb.append(n == 1 ? "" : ", ").append(neg.computeSleepTime(new Att(n, 0)));
        System.out.println("[VARIANT D-20]  incrementingWait(500ms, Long.MIN_VALUE/2 ms) sleeps for attempts 1..5: " + vb + "  (documented: 500 then clamped 0s)");
        // D-19 consequence variant: attempt numbers after the int counter wraps, realistic negative increment.
        WaitStrategy dec = WaitStrategies.incrementingWait(5, SECONDS, -1, SECONDS);
        long[] wn = {1, 2, 6, 7, Integer.MAX_VALUE, Integer.MIN_VALUE, Integer.MIN_VALUE + 1L};
        StringBuilder wb = new StringBuilder();
        for (long n : wn) wb.append(" #").append(n).append("->").append(dec.computeSleepTime(new Att(n, 0)));
        System.out.println("[VARIANT D-19]  incrementingWait(5s, -1s) by attempt number, incl. the numbers Retryer passes after its int counter wraps (Integer.MIN_VALUE...):" + wb);
    }

    static void b4Random() {
        Fam f = new Fam("B4");
        long[][] R = {{0, 1}, {0, 2}, {0, 5}, {2, 6}, {0, Long.MAX_VALUE}, {Long.MAX_VALUE - 1, Long.MAX_VALUE}, {1, Long.MAX_VALUE}, {0, 1L << 62}, {12345, 12345 + (1L << 40)}};
        for (long[] r : R) {
            WaitStrategy w = WaitStrategies.randomWait(r[0], MILLISECONDS, r[1], MILLISECONDS); f.configs++;
            for (int i = 0; i < 200000; i++) { long s = w.computeSleepTime(new Att(1, 0)); f.evals++;
                if (s < r[0] || s >= r[1]) { f.u("randomWait(" + r[0] + "," + r[1] + ") -> " + s); break; } }
        }
        f.done("RandomWait: min <= s < max over 200k samples per range");
        // Math.abs(Long.MIN_VALUE): nextLong() == MIN_VALUE iff hi=next(32)=0x80000000 and lo=next(32)=0.
        Fam g = new Fam("B4-LCG");
        final long MULT = 0x5DEECE66DL, ADD = 0xBL, MASK = (1L << 48) - 1; final int G = 2000;
        long hits = 0; int firstLow = -1, firstGap = -1;
        for (int low = 0; low < 65536; low++) {
            long s = (0x80000000L << 16) | low; // state right after next(32) returned 0x80000000
            if ((int) (s >>> 16) != Integer.MIN_VALUE) throw new AssertionError();
            for (int k = 0; k <= G; k++) { s = (s * MULT + ADD) & MASK; g.evals++;
                if ((int) (s >>> 16) == 0) { hits++; if (firstGap < 0) { firstGap = k; firstLow = low; } } }
        }
        g.configs = 65536;
        if (hits != 0) note("B4-LCG", "nextLong()==Long.MIN_VALUE reachable with " + firstGap + " intervening draws (low16=" + firstLow + "), hits=" + hits);
        else ok("B4-LCG", "of the 65536 LCG states that yield hi=0x80000000, none yields lo=0 after 0.." + G + " intervening next() calls -> Math.abs(Long.MIN_VALUE) unreachable without >" + G + " concurrent draws inside one nextLong()");
        nEval += g.evals;
    }

    static void b5Fixed() {
        Fam f = new Fam("B5");
        long[] vs = {0, 1, 999, 1000, Long.MAX_VALUE};
        TimeUnit[] us = {NANOSECONDS, MICROSECONDS, MILLISECONDS, SECONDS, DAYS};
        for (long v : vs) for (TimeUnit u : us) { WaitStrategy w = WaitStrategies.fixedWait(v, u); f.configs++;
            for (long n : new long[]{1, 2, 1000, Integer.MAX_VALUE}) { long s = w.computeSleepTime(new Att(n, 0)); f.evals++;
                if (s != u.toMillis(v) || s < 0) f.u("fixedWait(" + v + " " + u + ") -> " + s); } }
        f.done("FixedWait: constant = unit.toMillis(v) (saturating), never negative");
    }

    static void b6Join() {
        Fam f = new Fam("B6");
        long[] vs = {0, 1, 1000, Long.MAX_VALUE / 2, Long.MAX_VALUE - 1, Long.MAX_VALUE};
        for (long a : vs) for (long b : vs) {
            WaitStrategy w = WaitStrategies.join(WaitStrategies.fixedWait(a, MILLISECONDS), WaitStrategies.fixedWait(b, MILLISECONDS)); f.configs++;
            long s = w.computeSleepTime(new Att(1, 0)); f.evals++;
            BigInteger exact = BigInteger.valueOf(a).add(BigInteger.valueOf(b));
            if (exact.compareTo(LMAX) <= 0) { if (s != exact.longValue()) f.u("join(fixed " + a + ", fixed " + b + ") -> " + s); }
            else if (s != Long.MAX_VALUE) f.k("D-16", "join(fixed " + a + ", fixed " + b + ") -> " + s);
        }
        // monotone components with realistic parameters: sum must equal the sum of the parts at every n
        WaitStrategy e = WaitStrategies.exponentialWait(100, 5, MINUTES), fi = WaitStrategies.fibonacciWait(100, 2, MINUTES), in = WaitStrategies.incrementingWait(500, MILLISECONDS, 100, MILLISECONDS);
        WaitStrategy j = WaitStrategies.join(e, fi, in); f.configs++;
        for (long n : nlist(1000, 1000000)) { Att a = new Att(n, 0); long s = j.computeSleepTime(a); f.evals++;
            long sum = e.computeSleepTime(a) + fi.computeSleepTime(a) + in.computeSleepTime(a);
            if (s != sum || s < 0) f.u("join(README exponential, README fibonacci, incrementing) n=" + n + " -> " + s + " parts " + sum); }
        // exceptionWait component values
        long[] xs = {0, 5, Long.MAX_VALUE, -1, -5};
        for (long x : xs) { WaitStrategy w = WaitStrategies.join(WaitStrategies.exceptionWait(IOException.class, CR5Sweep.<IOException>fn(x)), WaitStrategies.fixedWait(10, MILLISECONDS)); f.configs++;
            long s = w.computeSleepTime(new Att(1, 0)); f.evals++;
            BigInteger exact = BigInteger.valueOf(x).add(BigInteger.TEN);
            if (x < 0) { if (s != exact.longValue() || s < 10) f.k("D-17", "join(exceptionWait(->" + x + "), fixed 10) -> " + s + " (negative component lowers the total)"); }
            else if (exact.compareTo(LMAX) > 0) { if (s != Long.MAX_VALUE) f.k("D-16", "join(exceptionWait(->" + x + "), fixed 10) -> " + s); }
            else if (s != exact.longValue()) f.u("join(exceptionWait(->" + x + "), fixed 10) -> " + s); }
        f.done("join: = exact sum when it fits; overflow -> D-16; negative exceptionWait component -> D-17");
    }

    static void b7ExceptionWait() {
        Fam f = new Fam("B7");
        Long[] xs = {0L, 5L, Long.MAX_VALUE, -1L, -Long.MAX_VALUE, null};
        for (Long x : xs) { WaitStrategy w = WaitStrategies.exceptionWait(IOException.class, CR5Sweep.<IOException>fn(x)); f.configs++; f.evals++;
            try { long s = w.computeSleepTime(new Att(1, 0));
                if (x == null) f.u("null function result -> " + s);
                else if (x < 0) { if (s == x) f.k("D-17", "exceptionWait(->" + x + ") -> " + s); else f.u("exceptionWait(->" + x + ") -> " + s); }
                else if (s != x) f.u("exceptionWait(->" + x + ") -> " + s);
            } catch (NullPointerException npe) { if (x == null) f.k("D-18", "exceptionWait(->null) -> NPE"); else f.u("NPE for " + x); } }
        // non-matching class and result attempts -> 0
        WaitStrategy w = WaitStrategies.exceptionWait(IllegalStateException.class, CR5Sweep.<IllegalStateException>fn(7L)); f.configs++; f.evals++;
        if (w.computeSleepTime(new Att(1, 0)) != 0L) f.u("non-matching exception class did not give 0");
        f.done("exceptionWait: pass-through of the function value; negative -> D-17, null -> D-18");
    }

    static void b8StopAttempt() {
        Fam f = new Fam("B8");
        int[] Ns = {1, 2, 3, 10, 1000, Integer.MAX_VALUE};
        for (int N : Ns) { StopStrategy st = StopStrategies.stopAfterAttempt(N); f.configs++;
            long[] ns = {1, (long) N - 1, N, (long) N + 1, Integer.MAX_VALUE};
            for (long n : ns) { if (n < 1 || n > Integer.MAX_VALUE) continue; boolean s = st.shouldStop(new Att(n, 0)); f.evals++;
                if (s != (n >= N)) f.u("stopAfterAttempt(" + N + ") at attempt " + n + " -> " + s); } }
        f.done("stopAfterAttempt(N): stops exactly when attempt >= N, for N up to Integer.MAX_VALUE");
    }

    static void b9StopDelay() {
        Fam f = new Fam("B9");
        TimeUnit[] us = {NANOSECONDS, MICROSECONDS, MILLISECONDS, SECONDS, MINUTES, HOURS, DAYS};
        long[] ds = {0, 1, 499, 500, 999, 1000, 1001, 123456789L, Long.MAX_VALUE};
        int sat = 0;
        for (TimeUnit u : us) for (long d : ds) {
            StopStrategy st = StopStrategies.stopAfterDelay(d, u); f.configs++;
            BigInteger reqNs = BigInteger.valueOf(d).multiply(BigInteger.valueOf(u.toNanos(1)));
            long lo = 0, hi = Long.MAX_VALUE; // minimal measured delay (ms) at which the strategy stops
            if (!st.shouldStop(new Att(1, Long.MAX_VALUE))) { f.u("stopAfterDelay(" + d + " " + u + ") never stops"); continue; }
            if (st.shouldStop(new Att(1, 0))) hi = 0; else {
                while (hi - lo > 1) { long mid = lo + (hi - lo) / 2; f.evals++; if (st.shouldStop(new Att(1, mid))) hi = mid; else lo = mid; } }
            f.evals += 2;
            long dStar = hi;
            // Retryer measures delay = floor(elapsedNs / 1e6); the stop can fire as soon as elapsedNs >= dStar*1e6.
            BigInteger earliestStopNs = BigInteger.valueOf(dStar).multiply(MILLION);
            if (earliestStopNs.compareTo(reqNs) < 0) {
                if (dStar == Long.MAX_VALUE) { sat++; continue; } // saturation beyond 2^63 ms (~292 million years): unreachable
                boolean subMs = reqNs.mod(MILLION).signum() != 0;
                if (subMs) f.k("D-22", "stopAfterDelay(" + d + " " + u + ") can stop at " + earliestStopNs + " ns < requested " + reqNs + " ns");
                else f.u("stopAfterDelay(" + d + " " + u + ") can stop at " + earliestStopNs + " ns < requested " + reqNs + " ns");
            }
        }
        f.done("stopAfterDelay: never stops before the requested duration except via sub-ms truncation (D-22); " + sat + " configs saturate beyond 2^63 ms (unreachable)");
    }

    static void b10NeverStop() {
        Fam f = new Fam("B10"); StopStrategy st = StopStrategies.neverStop(); f.configs++;
        for (long n : new long[]{1, Integer.MAX_VALUE}) for (long d : new long[]{0, Long.MAX_VALUE}) { f.evals++; if (st.shouldStop(new Att(n, d))) f.u("neverStop stopped"); }
        f.done("neverStop: never stops");
    }

    // ------------------------------------------------------------------ Part C
    static void partC() {
        System.out.println("\n---- Part C: FibonacciWait O(n) cost (performance note, not a value check)");
        WaitStrategy w = WaitStrategies.fibonacciWait(1, 50, MILLISECONDS);
        for (int i = 0; i < 40; i++) sink += w.computeSleepTime(new Att(1000000, 0));
        double perIter = 0;
        for (long n : new long[]{1000000L, 10000000L, 100000000L}) {
            long best = Long.MAX_VALUE;
            for (int r = 0; r < 3; r++) { long t0 = System.nanoTime(); sink += w.computeSleepTime(new Att(n, 0)); best = Math.min(best, System.nanoTime() - t0); }
            perIter = (double) best / n;
            System.out.println(String.format("[MEASURE]       fib(n) for n=%,d: %.3f ms per computeSleepTime (%.3f ns/iteration)", n, best / 1e6, perIter));
        }
        for (long capMs : new long[]{2, 10, 100, 1000, 120000}) {
            double nEq = capMs * 1e6 / perIter;              // attempt number where compute time == cap
            double wallS = nEq * capMs / 1000.0;              // time to get there while sleeping cap ms per attempt
            System.out.println(String.format("[PROJECTION]    cap=%,d ms: fib cost reaches the cap at attempt ~%.2e, i.e. after ~%.1f h (%.1f days) of uninterrupted retrying in one call()",
                    capMs, nEq, wallS / 3600, wallS / 86400));
        }
    }

    public static void main(String[] args) throws Exception {
        System.out.println("java.version=" + System.getProperty("java.version") + " (" + System.getProperty("java.vm.name") + ")");
        warmup();
        partA();
        System.out.println("\n---- Part B: Level 2, public strategy API over reachable attempt numbers (1..Integer.MAX_VALUE) and delays");
        b1Exponential(); b2Fibonacci(); b3Incrementing(); b4Random(); b5Fixed(); b6Join(); b7ExceptionWait(); b8StopAttempt(); b9StopDelay(); b10NeverStop();
        partC();
        System.out.println("\n==== SUMMARY ====");
        System.out.println("Part A runs / Part B families: OK=" + nOk + " SEPARATE-CANDIDATE signatures=" + nKnown + " NOTE=" + nNote + " UNATTRIBUTED=" + UNATTR.size());
        System.out.println("Part B strategy evaluations: " + nEval);
        System.out.println("Separate-candidate signatures observed (D-16..D-22, MC-10; not CR-5 defects): " + KNOWN);
        System.out.println("UNATTRIBUTED anomalies (candidate other defects): " + UNATTR.size());
        for (String u : UNATTR) System.out.println("  - " + u);
        System.out.println(UNATTR.isEmpty() ? "RESULT: NO_OTHER_DEFECT_FOUND" : "RESULT: UNATTRIBUTED_ANOMALY_FOUND");
        System.exit(UNATTR.isEmpty() ? 0 : 1);
    }
}
JAVA

if ! javac -Xlint:-options -nowarn --release 8 -d "$OUT/sweep-classes" -cp "$OUT/lib-classes:$GUAVA:$JSR" "$OUT/sweep/CR5Sweep.java"; then
  echo "BUILD FAILED (sweep)"; exit 3
fi
timeout 600 "$JAVA_HOME_RUN/bin/java" -cp "$OUT/sweep-classes:$OUT/lib-classes:$GUAVA:$JSR" CR5Sweep
rc=$?
echo "exit code: $rc"
exit $rc
