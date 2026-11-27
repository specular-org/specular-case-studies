#!/usr/bin/env bash
################################################################################
# CR-D-19 reproduction: the `int` attempt counter in Retryer.call wraps after
# 2^31-1 attempts (Retryer.java:157). Attempt numbers handed to listeners and
# strategies become non-positive, RetryException.getNumberOfFailedAttempts()
# reports the count truncated to int, and attempt-number-based waits change
# abruptly at the wrap.
#
# Builds the UNMODIFIED guava-retrying 2.0.0 sources (javac --release 8,
# Guava 22.0, jsr305 2.0.2 -- the harness/pom.xml recipe) and drives them only
# through the public API (RetryerBuilder, Retryer.call / Retryer.wrap,
# RetryListener, BlockStrategy, StopStrategies, WaitStrategies).
#
# Scenarios (SCENARIOS env var selects; default = all):
#   P0  control: stopAfterAttempt(3) -> count 3, listener sees 1,2,3.
#   A   Level 0, builder DEFAULTS (neverStop, noWait, Thread.sleep block),
#       retryer.wrap() on an executor, ended by executor.shutdownNow() after
#       the wrap. ~65-75 min on this host (Thread.sleep(0) per attempt).
#   B1  Level 0, neverStop/noWait + a user BlockStrategy that blocks exactly
#       the requested time (Thread.sleep for t>0, interrupt check for t==0,
#       i.e. Thread.sleep semantics without the sched_yield), interrupted
#       after ~4.44e9 attempts -> count reported modulo 2^32.
#   B2  Level 0, built-in stopAfterDelay(D) + noWait + same block strategy,
#       D calibrated for ~1.5 * 2^31 attempts -> RetryException from the stop
#       strategy with a negative count.
#   C1  Level 0, incrementingWait(50 ms, -10 ms) (a decreasing back-off that
#       the strategy clamps to 0) + same block strategy: at the wrap the
#       built-in strategy asks for a ~248-day sleep.
#   C2  Level 1 (timing assistance: virtual-time BlockStrategy that records
#       the requested sleep instead of sleeping), exponentialWait(1, 2 ms):
#       requested back-off collapses from 2 ms to 0 at the wrap. Reaching the
#       wrap for real needs >= 2^31 * 2 ms of sleeping (~49.7 days).
#   C4  cost probe: FibonacciWaitStrategy.computeSleepTime at attempt number
#       Integer.MAX_VALUE (O(n) loop) -> shows the Fibonacci wrap is not
#       reachable in practice.
#
# Exit: 0 = bug triggered (core consequences observed), 1 = not triggered,
#       2 = harness/build error.
################################################################################
set -uo pipefail

SRC_ROOT="${SRC_ROOT:-/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-19/worktree}"
M2="${M2:-$HOME/.m2/repository}"
GUAVA="$M2/com/google/guava/guava/22.0/guava-22.0.jar"
JSR305="$M2/com/google/code/findbugs/jsr305/2.0.2/jsr305-2.0.2.jar"
SCENARIOS="${SCENARIOS:-P0 A B1 B2 C1 C2 C4}"
JAVA_OPTS="${JAVA_OPTS:--Xms256m -Xmx1g}"

for f in "$GUAVA" "$JSR305" "$SRC_ROOT/src/main/java/com/github/rholder/retry/Retryer.java"; do
  [[ -f "$f" ]] || { echo "ERROR: missing $f"; exit 2; }
done
command -v javac >/dev/null || { echo "ERROR: javac not found"; exit 2; }

WORK="$(mktemp -d /tmp/crd19-repro.XXXXXX)"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/lib" "$WORK/test"
CP="$GUAVA:$JSR305"

echo "=== CR-D-19 reproduction ($(date -u +%Y-%m-%dT%H:%M:%SZ)) ==="
echo "host: $(uname -srm), cpus=$(nproc), load: $(cut -d' ' -f1-3 /proc/loadavg)"
java -version 2>&1 | sed 's/^/java: /'
echo "source tree: $SRC_ROOT"
( cd "$SRC_ROOT" && echo "source HEAD: $(git rev-parse HEAD 2>/dev/null)" && echo "source tree modifications (git status --porcelain):" && git status --porcelain 2>/dev/null | sed 's/^/  /' && echo "  (end)" )
sha256sum "$SRC_ROOT"/src/main/java/com/github/rholder/retry/{Retryer,RetryException,Attempt,WaitStrategies,StopStrategies}.java | sed "s#$SRC_ROOT/##; s/^/sha256: /"
echo "scenarios: $SCENARIOS"

# ---- build the unmodified library ----
if ! javac -nowarn --release 8 -cp "$CP" -d "$WORK/lib" "$SRC_ROOT"/src/main/java/com/github/rholder/retry/*.java > "$WORK/javac-lib.log" 2>&1; then
  cat "$WORK/javac-lib.log"; echo "ERROR: library build failed"; exit 2
fi

# ---- the client program (public API only) ----
cat > "$WORK/test/CRD19Repro.java" <<'JAVA'
import com.github.rholder.retry.Attempt;
import com.github.rholder.retry.BlockStrategy;
import com.github.rholder.retry.RetryException;
import com.github.rholder.retry.RetryListener;
import com.github.rholder.retry.Retryer;
import com.github.rholder.retry.RetryerBuilder;
import com.github.rholder.retry.StopStrategies;
import com.github.rholder.retry.WaitStrategies;
import com.github.rholder.retry.WaitStrategy;
import com.google.common.base.Predicates;

import java.util.concurrent.Callable;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.ThreadFactory;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicLong;

public class CRD19Repro {
    static final long INT_MAX = Integer.MAX_VALUE;  // 2,147,483,647
    static final long WRAP = INT_MAX + 1L;          // first real attempt the int counter cannot represent
    static final long TWO32 = 1L << 32;

    /** Counts the attempts it is notified of in a long and compares each with Attempt.getAttemptNumber(). */
    static final class WrapListener implements RetryListener {
        long real;                                  // written only by the retrying thread
        final AtomicLong published = new AtomicLong();
        long firstMismatchReal = -1, firstMismatchValue;
        long firstNonPosReal = -1, firstNonPosValue;
        long nonPositive;
        long maxValue = Long.MIN_VALUE, minValue = Long.MAX_VALUE;
        boolean alwaysIntTruncation = true;         // getAttemptNumber() == (long)(int) real, every attempt
        final long[] probeReal = {WRAP - 2, WRAP - 1, WRAP, WRAP + 1, TWO32 - 1, TWO32, TWO32 + 1};
        final long[] probeVal = new long[probeReal.length];
        final boolean[] probeHit = new boolean[probeReal.length];

        @Override
        public <V> void onRetry(Attempt<V> attempt) {
            long r = ++real;
            long n = attempt.getAttemptNumber();
            if (n != r && firstMismatchReal < 0) { firstMismatchReal = r; firstMismatchValue = n; }
            if (n <= 0) { nonPositive++; if (firstNonPosReal < 0) { firstNonPosReal = r; firstNonPosValue = n; } }
            if (n > maxValue) maxValue = n;
            if (n < minValue) minValue = n;
            if (n != (long) (int) r) alwaysIntTruncation = false;
            if ((r >= WRAP - 2 && r <= WRAP + 1) || (r >= TWO32 - 1 && r <= TWO32 + 1)) {
                for (int i = 0; i < probeReal.length; i++) {
                    if (probeReal[i] == r) { probeVal[i] = n; probeHit[i] = true; }
                }
            }
            if ((r & 0xFFFFL) == 0) published.lazySet(r);
        }

        long progress() { return published.get(); }

        void report(String tag) {
            System.out.printf("[%s] listener: real attempts notified = %,d (long counter kept by the listener)%n", tag, real);
            if (firstMismatchReal < 0) {
                System.out.printf("[%s] listener: getAttemptNumber() matched the real attempt index for every attempt%n", tag);
            } else {
                System.out.printf("[%s] listener: getAttemptNumber() matched the real index for attempts 1..%,d; first mismatch at real attempt %,d: getAttemptNumber() = %,d%n",
                        tag, firstMismatchReal - 1, firstMismatchReal, firstMismatchValue);
            }
            for (int i = 0; i < probeReal.length; i++) {
                if (probeHit[i]) System.out.printf("[%s] listener: real attempt %,d -> getAttemptNumber() = %,d%n", tag, probeReal[i], probeVal[i]);
            }
            System.out.printf("[%s] listener: attempts with getAttemptNumber() <= 0: %,d (first at real attempt %,d, value %,d); min seen %,d; max seen %,d%n",
                    tag, nonPositive, firstNonPosReal, firstNonPosValue, minValue, maxValue);
            System.out.printf("[%s] listener: getAttemptNumber() == (long)(int) realIndex for every attempt: %s%n", tag, alwaysIntTruncation);
        }
    }

    /** Blocks exactly the requested time with Thread.sleep semantics (InterruptedException if interrupted), but skips the sched_yield of Thread.sleep(0). */
    static final class ExactSleepBlock implements BlockStrategy {
        final WrapListener l;
        volatile long positiveRequests, lastPositiveRequest, lastPositiveRequestReal = -1;
        ExactSleepBlock(WrapListener l) { this.l = l; }
        @Override
        public void block(long sleepTime) throws InterruptedException {
            if (sleepTime > 0) {
                positiveRequests++;
                lastPositiveRequest = sleepTime;
                lastPositiveRequestReal = l.real;   // same thread: the listener ran for this attempt just before
                Thread.sleep(sleepTime);
            } else if (Thread.interrupted()) {
                throw new InterruptedException("sleep interrupted");
            }
        }
    }

    /** Level 1 timing assistance: records the requested sleep on a virtual clock instead of sleeping. */
    static final class VirtualClockBlock implements BlockStrategy {
        final WrapListener l;
        long virtualMillisBeforeWrap, positiveBeforeWrap, zeroBeforeWrap, positiveAfterWrap, zeroAfterWrap, maxBeforeWrap, maxAfterWrap;
        long reqWrapMinus1 = Long.MIN_VALUE, reqWrap = Long.MIN_VALUE, reqWrapPlus1 = Long.MIN_VALUE;
        VirtualClockBlock(WrapListener l) { this.l = l; }
        @Override
        public void block(long sleepTime) throws InterruptedException {
            if (Thread.interrupted()) throw new InterruptedException("sleep interrupted");
            long r = l.real;
            if (r < WRAP) {
                virtualMillisBeforeWrap += sleepTime;
                if (sleepTime > 0) positiveBeforeWrap++; else zeroBeforeWrap++;
                if (sleepTime > maxBeforeWrap) maxBeforeWrap = sleepTime;
            } else {
                if (sleepTime > 0) positiveAfterWrap++; else zeroAfterWrap++;
                if (sleepTime > maxAfterWrap) maxAfterWrap = sleepTime;
            }
            if (r == WRAP - 1) reqWrapMinus1 = sleepTime;
            else if (r == WRAP) reqWrap = sleepTime;
            else if (r == WRAP + 1) reqWrapPlus1 = sleepTime;
        }
    }

    /** "Poll until a resource is ready" -- the resource never becomes ready in these runs. */
    static final AtomicBoolean READY = new AtomicBoolean(false);
    static final Callable<Boolean> POLL = new Callable<Boolean>() {
        @Override public Boolean call() { return READY.get(); }
    };

    static RetryerBuilder<Boolean> pollingBuilder(WrapListener l) {
        return RetryerBuilder.<Boolean>newBuilder()
                .retryIfResult(Predicates.equalTo(Boolean.FALSE))
                .withRetryListener(l);
    }

    static final class Worker {
        volatile Thread thread;
        ExecutorService executor(final String name) {
            return Executors.newSingleThreadExecutor(new ThreadFactory() {
                @Override public Thread newThread(Runnable r) {
                    Thread t = new Thread(r, name);
                    t.setDaemon(true);
                    thread = t;
                    return t;
                }
            });
        }
    }

    /** Submits retryer.wrap(POLL) to an executor, waits until the listener has seen `target` attempts, then shuts the executor down (interrupt). */
    static RetryException runWrappedUntil(String tag, Retryer<Boolean> retryer, WrapListener l, long target,
                                          long timeoutSec, long progressEverySec, Runnable beforeShutdown) throws Exception {
        Worker w = new Worker();
        ExecutorService ex = w.executor("crd19-" + tag);
        long t0 = System.nanoTime(), lastPrint = t0;
        Future<Boolean> f = ex.submit(retryer.wrap(POLL));
        while (l.progress() < target && !f.isDone()) {
            Thread.sleep(20);
            long now = System.nanoTime();
            if (now - lastPrint >= TimeUnit.SECONDS.toNanos(progressEverySec)) {
                long p = l.progress();
                double s = (now - t0) / 1e9;
                System.out.printf("[%s] progress: %,d attempts after %.0f s (%.3e/s), target %,d%n", tag, p, s, p / s, target);
                lastPrint = now;
            }
            if (now - t0 > TimeUnit.SECONDS.toNanos(timeoutSec)) {
                System.out.printf("[%s] TIMEOUT waiting for %,d attempts (reached %,d)%n", tag, target, l.progress());
                break;
            }
        }
        double s = (System.nanoTime() - t0) / 1e9;
        System.out.printf("[%s] reached %,d attempts after %.1f s (%.3e attempts/s)%n", tag, l.progress(), s, l.progress() / s);
        if (beforeShutdown != null) beforeShutdown.run();
        ex.shutdownNow();   // service shutdown: interrupts the retrying worker
        try {
            Boolean v = f.get(120, TimeUnit.SECONDS);
            System.out.printf("[%s] call() returned normally: %s%n", tag, v);
            return null;
        } catch (ExecutionException ee) {
            if (ee.getCause() instanceof RetryException) return (RetryException) ee.getCause();
            throw ee;
        }
    }

    /** Prints the RetryException vs the real count; returns true if the reported count is wrong. */
    static boolean reportRetryException(String tag, RetryException e, WrapListener l) {
        if (e == null) { System.out.printf("[%s] no RetryException%n", tag); return false; }
        long reported = e.getNumberOfFailedAttempts();
        long lastNo = e.getLastFailedAttempt().getAttemptNumber();
        System.out.printf("[%s] RetryException.getNumberOfFailedAttempts() = %,d%n", tag, reported);
        System.out.printf("[%s] RetryException.getMessage() = \"%s\"%n", tag, e.getMessage());
        System.out.printf("[%s] RetryException.getLastFailedAttempt().getAttemptNumber() = %,d%n", tag, lastNo);
        System.out.printf("[%s] actual failed attempts (listener long counter) = %,d ; (int) actual = %,d ; actual - reported = %,d%n",
                tag, l.real, (long) (int) l.real, l.real - reported);
        return reported != l.real;
    }

    static void result(String tag, boolean triggered, String what) {
        System.out.printf("[%s] RESULT: %s -- %s%n", tag, triggered ? "BUG TRIGGERED" : "NOT TRIGGERED", what);
    }

    // ---------------------------------------------------------------- scenarios

    static void p0() throws Exception {
        WrapListener l = new WrapListener();
        Retryer<Boolean> r = pollingBuilder(l).withStopStrategy(StopStrategies.stopAfterAttempt(3)).build();
        try {
            r.call(POLL);
            System.out.println("[P0] unexpected normal return");
        } catch (RetryException e) {
            boolean wrong = reportRetryException("P0", e, l);
            l.report("P0");
            boolean ok = !wrong && e.getNumberOfFailedAttempts() == 3 && l.real == 3 && l.firstMismatchReal < 0;
            System.out.printf("[P0] CONTROL %s (expected count 3, listener numbers 1..3)%n", ok ? "OK" : "FAILED");
        }
    }

    static void scenarioA() throws Exception {
        System.out.println("[A] config: RetryerBuilder defaults (neverStop, noWait, BlockStrategies.threadSleepStrategy -> Thread.sleep(0)) + retryIfResult(equalTo(FALSE)) + listener; retryer.wrap(poll) on a single-thread executor; executor.shutdownNow() once the listener has seen 2^31 + 5,000,000 attempts");
        WrapListener l = new WrapListener();
        Retryer<Boolean> r = pollingBuilder(l).build();
        RetryException e = runWrappedUntil("A", r, l, WRAP + 5000000L, 3 * 3600, 300, null);
        boolean wrongCount = reportRetryException("A", e, l);
        l.report("A");
        boolean listenerWrong = l.firstMismatchReal == WRAP && l.firstMismatchValue == Integer.MIN_VALUE && l.nonPositive > 0;
        result("A", wrongCount && listenerWrong, "builder defaults: listeners saw attempt number " + l.firstMismatchValue
                + " at real attempt " + l.firstMismatchReal + "; RetryException reports " + (e == null ? "n/a" : String.valueOf(e.getNumberOfFailedAttempts()))
                + " failed attempts after " + l.real);
    }

    static void scenarioB1() throws Exception {
        final long target = 4439235284L;
        System.out.printf("[B1] config: neverStop + noWait + ExactSleepBlock; retryer.wrap(poll) on an executor; shutdownNow() once the listener has seen %,d attempts%n", target);
        WrapListener l = new WrapListener();
        Retryer<Boolean> r = pollingBuilder(l).withBlockStrategy(new ExactSleepBlock(l)).build();
        RetryException e = runWrappedUntil("B1", r, l, target, 1800, 60, null);
        boolean wrongCount = reportRetryException("B1", e, l);
        l.report("B1");
        System.out.printf("[B1] largest attempt number any listener/strategy ever saw: %,d although %,d attempts were made%n", l.maxValue, l.real);
        result("B1", wrongCount && l.real > TWO32 && e != null && e.getNumberOfFailedAttempts() == (int) l.real,
                "count reported modulo 2^32: " + (e == null ? "n/a" : String.valueOf(e.getNumberOfFailedAttempts())) + " for " + l.real + " failed attempts");
    }

    static void scenarioB2() throws Exception {
        // calibrate the attempt rate of this configuration on this host
        WrapListener cl = new WrapListener();
        Retryer<Boolean> cr = pollingBuilder(cl).withBlockStrategy(new ExactSleepBlock(cl)).build();
        Worker w = new Worker();
        ExecutorService ex = w.executor("crd19-B2-calibration");
        Future<Boolean> f = ex.submit(cr.wrap(POLL));
        Thread.sleep(2000);
        long a0 = cl.progress(); long t0 = System.nanoTime();
        Thread.sleep(4000);
        long a1 = cl.progress(); long t1 = System.nanoTime();
        ex.shutdownNow();
        try { f.get(60, TimeUnit.SECONDS); } catch (ExecutionException ignored) { }
        double rate = (a1 - a0) / ((t1 - t0) / 1e9);
        long delayMs = (long) Math.ceil(1.5 * WRAP / rate * 1000.0);
        System.out.printf("[B2] calibration: %.3e attempts/s -> stopAfterDelay(%,d ms) targets ~%,d attempts%n", rate, delayMs, (long) (rate * delayMs / 1000.0));
        System.out.printf("[B2] config: StopStrategies.stopAfterDelay(%d, MILLISECONDS) + noWait + ExactSleepBlock + retryIfResult(equalTo(FALSE)); retryer.call(poll) on the main thread%n", delayMs);
        WrapListener l = new WrapListener();
        Retryer<Boolean> r = pollingBuilder(l)
                .withStopStrategy(StopStrategies.stopAfterDelay(delayMs, TimeUnit.MILLISECONDS))
                .withBlockStrategy(new ExactSleepBlock(l)).build();
        long s0 = System.nanoTime();
        RetryException e = null;
        try {
            Boolean v = r.call(POLL);
            System.out.println("[B2] unexpected normal return: " + v);
        } catch (RetryException re) {
            e = re;
        }
        System.out.printf("[B2] call() ended after %.1f s%n", (System.nanoTime() - s0) / 1e9);
        boolean wrongCount = reportRetryException("B2", e, l);
        l.report("B2");
        if (e == null) {
            result("B2", false, "no RetryException");
        } else if (l.real <= INT_MAX) {
            result("B2", false, "INCONCLUSIVE: only " + l.real + " attempts happened before the delay elapsed (need > 2^31-1)");
        } else {
            result("B2", wrongCount && e.getNumberOfFailedAttempts() == (int) l.real,
                    "stopAfterDelay ended the call with RetryException count " + e.getNumberOfFailedAttempts() + " after " + l.real + " failed attempts");
        }
    }

    static void scenarioC1() throws Exception {
        System.out.println("[C1] config: neverStop + WaitStrategies.incrementingWait(50, MILLISECONDS, -10, MILLISECONDS) (50,40,30,20,10 ms, then clamped to 0) + ExactSleepBlock; retryer.wrap(poll) on an executor");
        WrapListener l = new WrapListener();
        final ExactSleepBlock block = new ExactSleepBlock(l);
        Retryer<Boolean> r = pollingBuilder(l)
                .withWaitStrategy(WaitStrategies.incrementingWait(50, TimeUnit.MILLISECONDS, -10, TimeUnit.MILLISECONDS))
                .withBlockStrategy(block).build();
        final Worker w = new Worker();
        ExecutorService ex = w.executor("crd19-C1");
        long t0 = System.nanoTime();
        Future<Boolean> f = ex.submit(r.wrap(POLL));
        while (l.progress() < WRAP && !f.isDone() && System.nanoTime() - t0 < TimeUnit.MINUTES.toNanos(30)) Thread.sleep(20);
        System.out.printf("[C1] listener reached %,d attempts after %.1f s%n", l.progress(), (System.nanoTime() - t0) / 1e9);
        long before = l.progress();
        Thread.sleep(5000);
        long after = l.progress();
        Thread.State st = w.thread.getState();
        StackTraceElement[] stack = w.thread.getStackTrace();
        String top = stack.length > 0 ? stack[0].toString() : "?";
        System.out.printf("[C1] 5 s later: attempts %,d -> %,d; worker state %s, top frame %s%n", before, after, st, top);
        System.out.printf("[C1] positive sleep requests: %,d; last one: %,d ms (= %.1f days) requested after real attempt %,d%n",
                block.positiveRequests, block.lastPositiveRequest, block.lastPositiveRequest / 86400000.0, block.lastPositiveRequestReal);
        ex.shutdownNow();
        RetryException e = null;
        try { f.get(120, TimeUnit.SECONDS); } catch (ExecutionException ee) { if (ee.getCause() instanceof RetryException) e = (RetryException) ee.getCause(); else throw ee; }
        reportRetryException("C1", e, l);
        l.report("C1");
        boolean stuck = after == before && st == Thread.State.TIMED_WAITING && block.lastPositiveRequestReal == WRAP
                && block.lastPositiveRequest == 50L + 10L * (WRAP + 1L);
        result("C1", stuck, "decreasing incrementingWait asked for a " + block.lastPositiveRequest + " ms sleep right after attempt " + block.lastPositiveRequestReal);
    }

    static void scenarioC2() throws Exception {
        System.out.println("[C2] LEVEL 1 (virtual time): neverStop + WaitStrategies.exponentialWait(1, 2, MILLISECONDS) + VirtualClockBlock (records requested sleeps, does not sleep); retryer.wrap(poll) on an executor");
        WrapListener l = new WrapListener();
        VirtualClockBlock vb = new VirtualClockBlock(l);
        Retryer<Boolean> r = pollingBuilder(l)
                .withWaitStrategy(WaitStrategies.exponentialWait(1, 2, TimeUnit.MILLISECONDS))
                .withBlockStrategy(vb).build();
        RetryException e = runWrappedUntil("C2", r, l, WRAP + 10000000L, 1800, 60, null);
        reportRetryException("C2", e, l);
        l.report("C2");
        System.out.printf("[C2] before the wrap: %,d positive and %,d zero sleep requests, max %,d ms; virtual time slept = %,d ms (= %.1f days)%n",
                vb.positiveBeforeWrap, vb.zeroBeforeWrap, vb.maxBeforeWrap, vb.virtualMillisBeforeWrap, vb.virtualMillisBeforeWrap / 86400000.0);
        System.out.printf("[C2] requested sleep after real attempt %,d: %d ms; after %,d: %d ms; after %,d: %d ms%n",
                WRAP - 1, vb.reqWrapMinus1, WRAP, vb.reqWrap, WRAP + 1, vb.reqWrapPlus1);
        System.out.printf("[C2] after the wrap: %,d positive and %,d zero sleep requests, max %,d ms%n", vb.positiveAfterWrap, vb.zeroAfterWrap, vb.maxAfterWrap);
        result("C2", vb.reqWrapMinus1 == 2 && vb.reqWrap == 0 && vb.positiveAfterWrap == 0 && vb.zeroAfterWrap > 0,
                "exponential back-off (cap 2 ms) collapsed to 0 ms at the wrap (Level 1 virtual time; ~49.7 days of real sleeping needed to get there)");
    }

    static void scenarioC4() {
        WaitStrategy fib = WaitStrategies.fibonacciWait(10, TimeUnit.MILLISECONDS);
        long[] ns = {1L << 24, 1L << 27, INT_MAX};
        double perIter = 0;
        for (long n : ns) {
            final long nn = n;
            Attempt<Boolean> a = new Attempt<Boolean>() {   // user-implemented Attempt, only to time the strategy
                public Boolean get() { return Boolean.FALSE; }
                public boolean hasResult() { return true; }
                public boolean hasException() { return false; }
                public Boolean getResult() { return Boolean.FALSE; }
                public Throwable getExceptionCause() { throw new IllegalStateException(); }
                public long getAttemptNumber() { return nn; }
                public long getDelaySinceFirstAttempt() { return 0L; }
            };
            long t0 = System.nanoTime();
            long v = fib.computeSleepTime(a);
            double secs = (System.nanoTime() - t0) / 1e9;
            perIter = secs / n;
            System.out.printf("[C4] fibonacciWait(10 ms).computeSleepTime(attempt %,d) = %d ms, took %.3f s (%.2f ns per loop iteration)%n", n, v, secs, perIter * 1e9);
        }
        double iterations = (double) INT_MAX * (INT_MAX + 1) / 2.0;
        double years = iterations * perIter / (365.25 * 86400);
        System.out.printf("[C4] reaching the wrap with fibonacciWait needs sum_{n=1}^{2^31-1} n = %.3e fib-loop iterations ~ %.0f years of CPU in computeSleepTime alone%n", iterations, years);
        System.out.println("[C4] RESULT: NOT TRIGGERED -- the Fibonacci 'collapse to 0' after the wrap is not reachable in practice (O(n) fib per attempt)");
    }

    public static void main(String[] args) throws Exception {
        String s = args[0];
        if (s.equals("P0")) p0();
        else if (s.equals("A")) scenarioA();
        else if (s.equals("B1")) scenarioB1();
        else if (s.equals("B2")) scenarioB2();
        else if (s.equals("C1")) scenarioC1();
        else if (s.equals("C2")) scenarioC2();
        else if (s.equals("C4")) scenarioC4();
        else throw new IllegalArgumentException(s);
    }
}
JAVA

if ! javac -nowarn --release 8 -cp "$CP:$WORK/lib" -d "$WORK/test" "$WORK/test/CRD19Repro.java" > "$WORK/javac-test.log" 2>&1; then
  cat "$WORK/javac-test.log"; echo "ERROR: test build failed"; exit 2
fi
RUNCP="$CP:$WORK/lib:$WORK/test"

run_scenario() {  # $1 = scenario, $2 = timeout
  echo
  echo "----- scenario $1 (start $(date -u +%H:%M:%S)) -----"
  timeout "$2" java $JAVA_OPTS -cp "$RUNCP" CRD19Repro "$1" 2>&1
  local rc=$?
  [[ $rc -eq 124 ]] && echo "[$1] TIMEOUT ($2) -- scenario killed"
  echo "----- scenario $1 end (rc=$rc, $(date -u +%H:%M:%S)) -----"
}

has() { [[ " $SCENARIOS " == *" $1 "* ]]; }

A_PID=""
if has A; then
  echo
  echo "scenario A (builder defaults) runs in the background; its output follows the other scenarios"
  ( run_scenario A 200m ) > "$WORK/A.out" 2>&1 &
  A_PID=$!
fi
for s in P0 B1 B2 C1 C2 C4; do
  if has "$s"; then run_scenario "$s" 45m; fi
done | tee "$WORK/fg.out"
if [[ -n "$A_PID" ]]; then
  wait "$A_PID"
  cat "$WORK/A.out"
fi

echo
echo "===== summary ====="
grep -h -E "RESULT:|CONTROL" "$WORK/fg.out" ${A_PID:+"$WORK/A.out"} 2>/dev/null
CORE=0
for s in A B1 B2; do
  grep -h "^\[$s\] RESULT: BUG TRIGGERED" "$WORK/fg.out" ${A_PID:+"$WORK/A.out"} >/dev/null 2>&1 && CORE=1
done
if [[ $CORE -eq 1 ]]; then
  echo "OVERALL: BUG TRIGGERED (int attempt counter wrap observed through the public API)"
  exit 0
fi
echo "OVERALL: NOT TRIGGERED"
exit 1
