#!/usr/bin/env bash
# CR-D-16 reproduction: WaitStrategies.join sums component sleeps with plain long
# addition (WaitStrategies.java:365-371). A total >= 2^63 ms wraps negative, the
# default ThreadSleepStrategy passes it to Thread.sleep (BlockStrategies.java:46),
# and Retryer.call (Retryer.java:176-182) lets the resulting
# IllegalArgumentException("timeout value is negative") escape: not one of the
# documented outcomes (result / ExecutionException / RetryException).
#
# Escalation level: 0 (pure black-box). Only public API of the UNMODIFIED library
# is used: WaitStrategies.{join,fixedWait,randomWait,exceptionWait},
# RetryerBuilder, StopStrategies, Retryer.call, Retryer.wrap. Bug cases use the
# default block strategy. A recording BlockStrategy wrapper (delegating to the
# built-in threadSleepStrategy) is used only in one diagnostic case to print the
# value handed to block(); a user-side saturating join is used only as the
# "expected behaviour" comparison.
#
# Usage: test_bugCR-D-16_join_sum_overflow.sh
#   env SRC=<guava-retrying checkout> GUAVA_JAR=<guava-22.0.jar> JSR305_JAR=<jsr305-2.0.2.jar>
#       JAVAS="<java bin> <java bin> ..." (JDKs to run the driver on)
# Exit 0 = bug reproduced on every JDK run and all controls behaved as documented.
set -euo pipefail

SRC=${SRC:-/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-16/worktree}
M2=${M2:-$HOME/.m2/repository}
GUAVA_JAR=${GUAVA_JAR:-$M2/com/google/guava/guava/22.0/guava-22.0.jar}
JSR305_JAR=${JSR305_JAR:-$M2/com/google/code/findbugs/jsr305/2.0.2/jsr305-2.0.2.jar}
JAVAC=${JAVAC:-javac}
DEFAULT_JAVAS="java"
[ -x /usr/lib/jvm/java-11-openjdk-amd64/bin/java ] && DEFAULT_JAVAS="$DEFAULT_JAVAS /usr/lib/jvm/java-11-openjdk-amd64/bin/java"
JAVAS=${JAVAS:-$DEFAULT_JAVAS}

BUILD=$(mktemp -d /tmp/crd16-build.XXXXXX)
trap 'rm -rf "$BUILD"' EXIT

echo "=== CR-D-16 repro: join() sum overflow -> negative sleep -> IAE escapes Retryer.call ==="
echo "date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "library source: $SRC"
echo "library HEAD:   $(git -C "$SRC" rev-parse HEAD)"
DIRTY=$(git -C "$SRC" status --porcelain | wc -l)
echo "library dirty files (must be 0, library unmodified): $DIRTY"
[ "$DIRTY" -eq 0 ] || { echo "ERROR: library checkout is modified"; exit 2; }
echo "guava:  $GUAVA_JAR sha1=$(sha1sum "$GUAVA_JAR" | cut -d' ' -f1)"
echo "jsr305: $JSR305_JAR sha1=$(sha1sum "$JSR305_JAR" | cut -d' ' -f1)"
echo "javac:  $($JAVAC -version 2>&1)"
echo "--- composite sum site (WaitStrategies.java:364-371) ---"
sed -n '364,371p' "$SRC/src/main/java/com/github/rholder/retry/WaitStrategies.java"
echo "--- block step (Retryer.java:173-183) ---"
sed -n '173,183p' "$SRC/src/main/java/com/github/rholder/retry/Retryer.java"
echo "--- default block strategy (BlockStrategies.java:44-47) ---"
sed -n '44,47p' "$SRC/src/main/java/com/github/rholder/retry/BlockStrategies.java"

mkdir -p "$BUILD/lib" "$BUILD/driver"
CP="$GUAVA_JAR:$JSR305_JAR"
find "$SRC/src/main/java" -name '*.java' > "$BUILD/sources.txt"
timeout 5m "$JAVAC" --release 8 -nowarn -encoding UTF-8 -cp "$CP" -d "$BUILD/lib" @"$BUILD/sources.txt" 2>&1 | grep -v '^warning\|^Note:\|^1 warning' || true
[ -f "$BUILD/lib/com/github/rholder/retry/Retryer.class" ] || { echo "ERROR: library build failed"; exit 2; }
echo "library compiled (javac --release 8 against guava 22.0 + jsr305 2.0.2)"

cat > "$BUILD/driver/CrD16Repro.java" <<'JAVA'
import com.github.rholder.retry.Attempt;
import com.github.rholder.retry.BlockStrategies;
import com.github.rholder.retry.BlockStrategy;
import com.github.rholder.retry.RetryException;
import com.github.rholder.retry.Retryer;
import com.github.rholder.retry.RetryerBuilder;
import com.github.rholder.retry.StopStrategies;
import com.github.rholder.retry.WaitStrategies;
import com.github.rholder.retry.WaitStrategy;
import com.google.common.base.Function;

import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.channels.Pipe;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.concurrent.Callable;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicReference;

public class CrD16Repro {
    static final int MAX_ATTEMPTS = 5;
    static int bugCases = 0, bugTriggered = 0, controls = 0, controlsOk = 0;

    // ---------- user-level helpers (public API only) ----------

    /** Exception carrying a server back-off hint, e.g. parsed from a Retry-After header. */
    static final class RateLimitedException extends Exception {
        final long retryAfterSeconds;
        RateLimitedException(long s) { super("rate limited, retry after " + s + " s"); retryAfterSeconds = s; }
    }

    /** Diagnostic only: records the value Retryer hands to block(), delegates to the built-in strategy. */
    static final class RecordingBlock implements BlockStrategy {
        final List<Long> seen = Collections.synchronizedList(new ArrayList<Long>());
        final BlockStrategy delegate = BlockStrategies.threadSleepStrategy();
        @Override public void block(long sleepTime) throws InterruptedException { seen.add(sleepTime); delegate.block(sleepTime); }
    }

    /** Expected-behaviour comparison only: the same join, but with a saturating sum (user-side). */
    static WaitStrategy saturatingJoin(final WaitStrategy... ws) {
        return new WaitStrategy() {
            @Override public long computeSleepTime(Attempt failedAttempt) {
                long total = 0L;
                for (WaitStrategy w : ws) {
                    long v = w.computeSleepTime(failedAttempt);
                    total = (v > 0 && total > Long.MAX_VALUE - v) ? Long.MAX_VALUE : total + v;
                }
                return total;
            }
        };
    }

    static Retryer<String> retryer(WaitStrategy wait, BlockStrategy block) {
        RetryerBuilder<String> b = RetryerBuilder.<String>newBuilder()
                .retryIfException()
                .withStopStrategy(StopStrategies.stopAfterAttempt(MAX_ATTEMPTS))
                .withWaitStrategy(wait);
        if (block != null) b.withBlockStrategy(block);
        return b.build();
    }

    /** A backend call that always fails with an IOException (counts invocations, remembers last failure). */
    static Callable<String> failing(final AtomicInteger inv, final AtomicReference<Throwable> last) {
        return new Callable<String>() {
            @Override public String call() throws Exception {
                IOException e = new IOException("backend unavailable (invocation " + inv.incrementAndGet() + ")");
                last.set(e);
                throw e;
            }
        };
    }

    /** A backend call that is rate limited with the given Retry-After hint (seconds). */
    static Callable<String> rateLimited(final AtomicInteger inv, final AtomicReference<Throwable> last, final long retryAfterSeconds) {
        return new Callable<String>() {
            @Override public String call() throws Exception {
                inv.incrementAndGet();
                RateLimitedException e = new RateLimitedException(retryAfterSeconds);
                last.set(e);
                throw e;
            }
        };
    }

    /** A blocking NIO read; an interrupt of the caller makes it fail with ClosedByInterruptException (interrupt status stays set). */
    static Callable<String> blockingRead(final AtomicInteger inv, final AtomicReference<Throwable> last, final CountDownLatch aboutToBlock) {
        return new Callable<String>() {
            @Override public String call() throws Exception {
                inv.incrementAndGet();
                Pipe p = Pipe.open();
                try {
                    aboutToBlock.countDown();
                    p.source().read(ByteBuffer.allocate(1)); // nobody writes: blocks until interrupted
                    return "unexpected data";
                } catch (IOException e) {
                    last.set(e);
                    throw e;
                } finally {
                    p.sink().close();
                    p.source().close();
                }
            }
        };
    }

    // ---------- runner ----------

    enum Mode { NONE, PRE_INTERRUPTED, INTERRUPT_DURING_ATTEMPT }

    static final class Outcome {
        String result; Throwable thrown; boolean interruptStatusAfter; long elapsedMs;
        boolean blockedInSleep; String blockedState; String blockedTopFrames = "";
    }

    static Outcome run(final Retryer<String> r, final Callable<String> c, final Mode mode,
                       final CountDownLatch aboutToBlock, long watchdogMs) throws Exception {
        final Outcome o = new Outcome();
        final long t0 = System.nanoTime();
        Thread t = new Thread(new Runnable() {
            @Override public void run() {
                if (mode == Mode.PRE_INTERRUPTED) Thread.currentThread().interrupt();
                try {
                    o.result = r.call(c);
                } catch (Throwable th) {
                    o.thrown = th;
                } finally {
                    o.interruptStatusAfter = Thread.currentThread().isInterrupted();
                    o.elapsedMs = TimeUnit.NANOSECONDS.toMillis(System.nanoTime() - t0);
                }
            }
        }, "retryer-caller");
        t.start();
        if (mode == Mode.INTERRUPT_DURING_ATTEMPT) {
            if (!aboutToBlock.await(10, TimeUnit.SECONDS)) throw new IllegalStateException("callable never started");
            Thread.sleep(300);           // caller is now blocked in Pipe.read inside the attempt
            t.interrupt();               // e.g. a shutdown/cancel signal
        }
        t.join(watchdogMs);
        if (t.isAlive()) {               // still inside call(): inspect where it is, then interrupt it
            StackTraceElement[] st = t.getStackTrace();
            o.blockedState = String.valueOf(t.getState());
            StringBuilder sb = new StringBuilder();
            for (int i = 0; i < Math.min(4, st.length); i++) {
                sb.append("\n        at ").append(st[i]);
                if ("java.lang.Thread".equals(st[i].getClassName()) && st[i].getMethodName().startsWith("sleep")) o.blockedInSleep = true;
            }
            o.blockedTopFrames = sb.toString();
            t.interrupt();
            t.join(10000);
            if (t.isAlive()) throw new IllegalStateException("caller thread did not finish after interrupt");
        }
        return o;
    }

    static boolean reachable(Throwable from, Throwable target) {
        for (Throwable x = from; x != null; x = x.getCause()) {
            if (x == target) return true;
            for (Throwable s : x.getSuppressed()) if (s == target) return true;
        }
        return false;
    }

    static void print(String label, Outcome o, int invocations, Throwable last) {
        System.out.println("  [" + label + "] callable invocations = " + invocations + " (stop strategy allows " + MAX_ATTEMPTS + ")");
        if (o.blockedState != null) {
            System.out.println("  [" + label + "] after watchdog: caller still inside call(), state=" + o.blockedState
                    + ", blocked in Thread.sleep=" + o.blockedInSleep + o.blockedTopFrames);
            System.out.println("  [" + label + "] watchdog interrupted the caller");
        }
        if (o.thrown == null) {
            System.out.println("  [" + label + "] call() returned: " + o.result);
        } else {
            System.out.println("  [" + label + "] call() threw: " + o.thrown);
            if (o.thrown instanceof RetryException) {
                RetryException re = (RetryException) o.thrown;
                System.out.println("  [" + label + "]   RetryException.getNumberOfFailedAttempts() = " + re.getNumberOfFailedAttempts());
                System.out.println("  [" + label + "]   RetryException.getLastFailedAttempt().getExceptionCause() = " + re.getLastFailedAttempt().getExceptionCause());
            } else {
                StackTraceElement[] st = o.thrown.getStackTrace();
                for (int i = 0; i < Math.min(5, st.length); i++) System.out.println("  [" + label + "]     at " + st[i]);
                System.out.println("  [" + label + "]   thrown.getCause() = " + o.thrown.getCause());
            }
            System.out.println("  [" + label + "]   last callable failure reachable from the thrown exception: " + reachable(o.thrown, last));
        }
        System.out.println("  [" + label + "] caller interrupt status after call() = " + o.interruptStatusAfter + ", elapsed " + o.elapsedMs + " ms");
    }

    static boolean isNegativeSleepIae(Throwable t) {
        return t instanceof IllegalArgumentException && String.valueOf(t.getMessage()).contains("timeout value is negative");
    }

    static void bug(String label, boolean triggered, String what) {
        bugCases++; if (triggered) bugTriggered++;
        System.out.println("  => " + (triggered ? "[BUG TRIGGERED] " : "[BUG NOT TRIGGERED] ") + label + ": " + what);
    }

    static void control(String label, boolean ok, String what) {
        controls++; if (ok) controlsOk++;
        System.out.println("  => " + (ok ? "[CONTROL OK] " : "[CONTROL UNEXPECTED] ") + label + ": " + what);
    }

    // ---------- cases ----------

    public static void main(String[] args) throws Exception {
        System.out.println("java.version=" + System.getProperty("java.version") + " java.vendor=" + System.getProperty("java.vendor"));
        System.out.println("Long.MAX_VALUE = " + Long.MAX_VALUE + ";  Long.MAX_VALUE + 1000 (plain long add) = " + (Long.MAX_VALUE + 1000L));
        System.out.println("TimeUnit.DAYS.toMillis(Long.MAX_VALUE) = " + TimeUnit.DAYS.toMillis(Long.MAX_VALUE)
                + ";  TimeUnit.SECONDS.toMillis(10^16) = " + TimeUnit.SECONDS.toMillis(10000000000000000L));

        // C0: join semantics on ordinary values (diagnostic recorder, built-in sleep underneath)
        {
            System.out.println("\n--- C0 control: join(fixedWait(50ms), fixedWait(70ms)) waits the documented total ---");
            AtomicInteger inv = new AtomicInteger(); AtomicReference<Throwable> last = new AtomicReference<Throwable>();
            RecordingBlock rec = new RecordingBlock();
            Retryer<String> r = RetryerBuilder.<String>newBuilder().retryIfException()
                    .withStopStrategy(StopStrategies.stopAfterAttempt(2))
                    .withWaitStrategy(WaitStrategies.join(WaitStrategies.fixedWait(50, TimeUnit.MILLISECONDS), WaitStrategies.fixedWait(70, TimeUnit.MILLISECONDS)))
                    .withBlockStrategy(rec).build();
            Outcome o = run(r, failing(inv, last), Mode.NONE, null, 10000);
            print("C0", o, inv.get(), last.get());
            System.out.println("  [C0] values passed to block(): " + rec.seen);
            control("C0", rec.seen.size() == 1 && rec.seen.get(0) == 120L && o.thrown instanceof RetryException,
                    "block(120) then RetryException after 2 attempts");
        }

        // C1: a single huge component alone (no join) is a legal 'wait practically forever'
        {
            System.out.println("\n--- C1 control: fixedWait(Long.MAX_VALUE, MILLISECONDS) alone (no join), default block strategy ---");
            AtomicInteger inv = new AtomicInteger(); AtomicReference<Throwable> last = new AtomicReference<Throwable>();
            Retryer<String> r = retryer(WaitStrategies.fixedWait(Long.MAX_VALUE, TimeUnit.MILLISECONDS), null);
            Outcome o = run(r, failing(inv, last), Mode.NONE, null, 1500);
            print("C1", o, inv.get(), last.get());
            control("C1", o.blockedInSleep && o.thrown instanceof RetryException
                            && ((RetryException) o.thrown).getNumberOfFailedAttempts() == 1 && o.interruptStatusAfter,
                    "caller sleeps; on interrupt -> documented RetryException(1 attempt, last failure kept), interrupt status set");
        }

        // B1: finding example (a)
        {
            System.out.println("\n--- B1 bug: join(fixedWait(Long.MAX_VALUE, MILLISECONDS), fixedWait(1, SECONDS)), default block strategy ---");
            AtomicInteger inv = new AtomicInteger(); AtomicReference<Throwable> last = new AtomicReference<Throwable>();
            Retryer<String> r = retryer(WaitStrategies.join(
                    WaitStrategies.fixedWait(Long.MAX_VALUE, TimeUnit.MILLISECONDS),
                    WaitStrategies.fixedWait(1, TimeUnit.SECONDS)), null);
            Outcome o = run(r, failing(inv, last), Mode.NONE, null, 5000);
            print("B1", o, inv.get(), last.get());
            bug("B1", isNegativeSleepIae(o.thrown) && inv.get() == 1 && o.blockedState == null,
                    "call() escaped with IllegalArgumentException after 1 attempt instead of waiting (documented: total wait)");
        }

        // B1-diag: same config, recorder shows the wrapped value handed to block()
        {
            System.out.println("\n--- B1-diag: same join, recording wrapper around the built-in threadSleepStrategy ---");
            AtomicInteger inv = new AtomicInteger(); AtomicReference<Throwable> last = new AtomicReference<Throwable>();
            RecordingBlock rec = new RecordingBlock();
            Retryer<String> r = retryer(WaitStrategies.join(
                    WaitStrategies.fixedWait(Long.MAX_VALUE, TimeUnit.MILLISECONDS),
                    WaitStrategies.fixedWait(1, TimeUnit.SECONDS)), rec);
            Outcome o = run(r, failing(inv, last), Mode.NONE, null, 5000);
            System.out.println("  [B1-diag] values passed to block(): " + rec.seen + "  (expected total 9223372036854775807 + 1000, not representable)");
            System.out.println("  [B1-diag] call() threw: " + o.thrown);
            bug("B1-diag", rec.seen.size() == 1 && rec.seen.get(0) == Long.MAX_VALUE + 1000L && rec.seen.get(0) < 0 && isNegativeSleepIae(o.thrown),
                    "CompositeWaitStrategy returned " + (rec.seen.isEmpty() ? "?" : rec.seen.get(0)) + " (negative)");
        }

        // B2: saturating TimeUnit conversion inside a component
        {
            System.out.println("\n--- B2 bug: join(fixedWait(Long.MAX_VALUE, DAYS), fixedWait(1, MILLISECONDS)) ---");
            AtomicInteger inv = new AtomicInteger(); AtomicReference<Throwable> last = new AtomicReference<Throwable>();
            Retryer<String> r = retryer(WaitStrategies.join(
                    WaitStrategies.fixedWait(Long.MAX_VALUE, TimeUnit.DAYS),
                    WaitStrategies.fixedWait(1, TimeUnit.MILLISECONDS)), null);
            Outcome o = run(r, failing(inv, last), Mode.NONE, null, 5000);
            print("B2", o, inv.get(), last.get());
            bug("B2", isNegativeSleepIae(o.thrown) && inv.get() == 1, "saturated component + 1 ms wraps negative");
        }

        // B3: data-driven component (server back-off hint) + jitter, finding example (e)
        {
            System.out.println("\n--- B3 bug: join(exceptionWait(RateLimitedException, e -> SECONDS.toMillis(e.retryAfterSeconds)), randomWait(1, SECONDS)), hint = 10^16 s ---");
            Function<RateLimitedException, Long> hint = new Function<RateLimitedException, Long>() {
                @Override public Long apply(RateLimitedException e) { return TimeUnit.SECONDS.toMillis(e.retryAfterSeconds); }
            };
            int runs = 20, iae = 0, blocked = 0, other = 0;
            Outcome first = null; int firstInv = 0; Throwable firstLast = null;
            for (int i = 0; i < runs; i++) {
                AtomicInteger inv = new AtomicInteger(); AtomicReference<Throwable> last = new AtomicReference<Throwable>();
                Retryer<String> r = retryer(WaitStrategies.join(
                        WaitStrategies.exceptionWait(RateLimitedException.class, hint),
                        WaitStrategies.randomWait(1, TimeUnit.SECONDS)), null);
                Outcome o = run(r, rateLimited(inv, last, 10000000000000000L), Mode.NONE, null, 1500);
                if (o.blockedState != null) blocked++;
                else if (isNegativeSleepIae(o.thrown)) iae++;
                else other++;
                if (first == null) { first = o; firstInv = inv.get(); firstLast = last.get(); }
            }
            print("B3 run#1", first, firstInv, firstLast);
            System.out.println("  [B3] " + runs + " runs: IllegalArgumentException=" + iae + ", slept (jitter happened to be 0 ms)=" + blocked + ", other=" + other);
            bug("B3", iae > 0 && other == 0, "back-off hint saturates to Long.MAX_VALUE, + jitter wraps negative in " + iae + "/" + runs + " runs");
        }

        // C2 / B4: caller interrupted during the attempt (NIO read -> ClosedByInterruptException, status set)
        {
            System.out.println("\n--- C2 control: caller interrupted during attempt, non-overflowing join(fixedWait(10ms), randomWait(1, SECONDS)) ---");
            AtomicInteger inv = new AtomicInteger(); AtomicReference<Throwable> last = new AtomicReference<Throwable>();
            CountDownLatch latch = new CountDownLatch(1);
            Retryer<String> r = retryer(WaitStrategies.join(WaitStrategies.fixedWait(10, TimeUnit.MILLISECONDS), WaitStrategies.randomWait(1, TimeUnit.SECONDS)), null);
            Outcome o = run(r, blockingRead(inv, last, latch), Mode.INTERRUPT_DURING_ATTEMPT, latch, 5000);
            print("C2", o, inv.get(), last.get());
            control("C2", o.thrown instanceof RetryException && o.interruptStatusAfter && o.blockedState == null,
                    "documented: RetryException and interrupt status set");
        }
        {
            System.out.println("\n--- C3 control: caller interrupted during attempt, fixedWait(Long.MAX_VALUE, MILLISECONDS) alone ---");
            AtomicInteger inv = new AtomicInteger(); AtomicReference<Throwable> last = new AtomicReference<Throwable>();
            CountDownLatch latch = new CountDownLatch(1);
            Retryer<String> r = retryer(WaitStrategies.fixedWait(Long.MAX_VALUE, TimeUnit.MILLISECONDS), null);
            Outcome o = run(r, blockingRead(inv, last, latch), Mode.INTERRUPT_DURING_ATTEMPT, latch, 5000);
            print("C3", o, inv.get(), last.get());
            control("C3", o.thrown instanceof RetryException && o.interruptStatusAfter && o.blockedState == null,
                    "documented: RetryException and interrupt status set");
        }
        {
            System.out.println("\n--- B4 bug: caller interrupted during attempt, join(fixedWait(Long.MAX_VALUE, MILLISECONDS), fixedWait(1, SECONDS)) ---");
            AtomicInteger inv = new AtomicInteger(); AtomicReference<Throwable> last = new AtomicReference<Throwable>();
            CountDownLatch latch = new CountDownLatch(1);
            Retryer<String> r = retryer(WaitStrategies.join(
                    WaitStrategies.fixedWait(Long.MAX_VALUE, TimeUnit.MILLISECONDS),
                    WaitStrategies.fixedWait(1, TimeUnit.SECONDS)), null);
            Outcome o = run(r, blockingRead(inv, last, latch), Mode.INTERRUPT_DURING_ATTEMPT, latch, 5000);
            print("B4", o, inv.get(), last.get());
            bug("B4", isNegativeSleepIae(o.thrown) && !(o.thrown instanceof RetryException),
                    "interrupted caller gets IllegalArgumentException, not the documented RetryException");
        }

        // C4 / B5: caller already interrupted when call() starts
        {
            System.out.println("\n--- C4 control: caller pre-interrupted, non-overflowing join(fixedWait(10ms), fixedWait(1, SECONDS)) ---");
            AtomicInteger inv = new AtomicInteger(); AtomicReference<Throwable> last = new AtomicReference<Throwable>();
            Retryer<String> r = retryer(WaitStrategies.join(WaitStrategies.fixedWait(10, TimeUnit.MILLISECONDS), WaitStrategies.fixedWait(1, TimeUnit.SECONDS)), null);
            Outcome o = run(r, failing(inv, last), Mode.PRE_INTERRUPTED, null, 5000);
            print("C4", o, inv.get(), last.get());
            control("C4", o.thrown instanceof RetryException && o.interruptStatusAfter, "documented: RetryException and interrupt status set");
        }
        {
            System.out.println("\n--- B5 bug: caller pre-interrupted, join(fixedWait(Long.MAX_VALUE, MILLISECONDS), fixedWait(1, SECONDS)) ---");
            AtomicInteger inv = new AtomicInteger(); AtomicReference<Throwable> last = new AtomicReference<Throwable>();
            Retryer<String> r = retryer(WaitStrategies.join(
                    WaitStrategies.fixedWait(Long.MAX_VALUE, TimeUnit.MILLISECONDS),
                    WaitStrategies.fixedWait(1, TimeUnit.SECONDS)), null);
            Outcome o = run(r, failing(inv, last), Mode.PRE_INTERRUPTED, null, 5000);
            print("B5", o, inv.get(), last.get());
            bug("B5", isNegativeSleepIae(o.thrown), "interrupted caller gets IllegalArgumentException, not the documented RetryException");
        }

        // B6: consumer through Retryer.wrap() on an executor
        {
            System.out.println("\n--- B6 bug: Retryer.wrap(callable) submitted to an ExecutorService, same overflowing join ---");
            AtomicInteger inv = new AtomicInteger(); AtomicReference<Throwable> last = new AtomicReference<Throwable>();
            Retryer<String> r = retryer(WaitStrategies.join(
                    WaitStrategies.fixedWait(Long.MAX_VALUE, TimeUnit.MILLISECONDS),
                    WaitStrategies.fixedWait(1, TimeUnit.SECONDS)), null);
            ExecutorService ex = Executors.newSingleThreadExecutor();
            Throwable cause = null;
            try {
                Future<String> f = ex.submit(r.wrap(failing(inv, last)));
                try { f.get(10, TimeUnit.SECONDS); } catch (ExecutionException ee) { cause = ee.getCause(); }
            } finally { ex.shutdownNow(); }
            System.out.println("  [B6] Future.get() -> ExecutionException cause = " + cause + ", callable invocations = " + inv.get());
            bug("B6", isNegativeSleepIae(cause) && !(cause instanceof RetryException), "RetryerCallable surfaces IllegalArgumentException as the task failure");
        }

        // F1: expected behaviour if the sum saturated (user-side saturating join, same components)
        {
            System.out.println("\n--- F1 expected behaviour: same components with a saturating sum (user-side WaitStrategy) ---");
            AtomicInteger inv = new AtomicInteger(); AtomicReference<Throwable> last = new AtomicReference<Throwable>();
            Retryer<String> r = retryer(saturatingJoin(
                    WaitStrategies.fixedWait(Long.MAX_VALUE, TimeUnit.MILLISECONDS),
                    WaitStrategies.fixedWait(1, TimeUnit.SECONDS)), null);
            Outcome o = run(r, failing(inv, last), Mode.NONE, null, 1500);
            print("F1", o, inv.get(), last.get());
            control("F1", o.blockedInSleep && o.thrown instanceof RetryException && reachable(o.thrown, last.get()) && o.interruptStatusAfter,
                    "caller waits (Long.MAX_VALUE ms); interrupt -> RetryException(1 attempt, last failure kept), interrupt status set");
        }

        System.out.println("\nSUMMARY (java " + System.getProperty("java.version") + "): bug cases triggered " + bugTriggered + "/" + bugCases
                + "; controls as documented " + controlsOk + "/" + controls);
        boolean reproduced = bugTriggered == bugCases && controlsOk == controls;
        System.out.println(reproduced ? "RESULT: BUG REPRODUCED" : "RESULT: NOT REPRODUCED (see cases above)");
        System.exit(reproduced ? 0 : 1);
    }
}
JAVA

timeout 5m "$JAVAC" --release 8 -nowarn -encoding UTF-8 -cp "$BUILD/lib:$CP" -d "$BUILD/driver" "$BUILD/driver/CrD16Repro.java" 2>&1 | grep -v '^warning\|^Note:\|^1 warning' || true
[ -f "$BUILD/driver/CrD16Repro.class" ] || { echo "ERROR: driver build failed"; exit 2; }

overall=0
for J in $JAVAS; do
    echo
    echo "################ running driver on: $J ($("$J" -version 2>&1 | head -1)) ################"
    echo "command: timeout 300 $J -cp <driver>:<lib>:guava-22.0.jar:jsr305-2.0.2.jar CrD16Repro"
    set +e
    timeout 300 "$J" -cp "$BUILD/driver:$BUILD/lib:$CP" CrD16Repro
    rc=$?
    set -e
    echo "driver exit code on $J: $rc"
    [ "$rc" -eq 0 ] || overall=1
done
echo
if [ "$overall" -eq 0 ]; then echo "FINAL: BUG REPRODUCED on all JDKs run"; else echo "FINAL: NOT REPRODUCED on at least one JDK"; fi
exit $overall
