#!/usr/bin/env bash
# MC-8 reproduction: bounded limiter executor -> attempts that time out while queued, or are
# rejected at submit, are counted as failed attempts although the callable never ran;
# wrap() submitted to the limiter's own one-thread pool times out every attempt.
#
# Escalation level: 0/1 -- public API only (RetryerBuilder, AttemptTimeLimiters.fixedTimeLimit(d, unit, executor),
# Retryer.call, Retryer.wrap, RetryListener, java.util.concurrent executors). The library sources are compiled
# unmodified from the worktree. Timing is controlled only inside the *user* callables (a slow operation that does
# not respond to interruption -- allowed by the target's assumptions -- and a latch so caller 2 submits after
# caller 1's task is running).
#
# Scenarios (each paired with a control using an unbounded/cached pool or a separate pool):
#   S1  (CE hunt_s4_executor_bfs1 + bfs3): two threads share one Retryer on TPE(1,1,ArrayBlockingQueue(1)).
#       caller-2's attempt #1 times out while queued (callable never ran) and is counted; caller-1's attempt #2 and
#       caller-2's attempt #2 are rejected (RejectedExecutionException) and counted.
#   S2  (CE hunt_s4_wrap_samepool_bfs1): pool.submit(retryer.wrap(c)) where the limiter uses the same 1-thread pool;
#       stopAfterAttempt(3) -> RetryException(3) with 0 invocations.
#   S2b (same, neverStop): attempts keep being made and counted for 3 s, 0 invocations, cancelled tasks pile up.
#
# Exit 0 = every scenario realised the counterexample's end state in the real code and every control behaved
# like the unbounded configuration; exit 1 otherwise.
set -euo pipefail

SRC_DIR="${SRC_DIR:-/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-8/worktree}"
GUAVA_JAR="${GUAVA_JAR:-/home/ubuntu/.m2/repository/com/google/guava/guava/22.0/guava-22.0.jar}"
JSR305_JAR="${JSR305_JAR:-/home/ubuntu/.m2/repository/com/google/code/findbugs/jsr305/2.0.2/jsr305-2.0.2.jar}"
RUNS="${RUNS:-3}"
WORK="$(mktemp -d /tmp/mc8-repro.XXXXXX)"
trap 'rm -rf "$WORK"' EXIT

echo "== MC-8 repro =="
echo "source tree : $SRC_DIR ($(git -C "$SRC_DIR" rev-parse --short HEAD 2>/dev/null || echo '?'), dirty files: $(git -C "$SRC_DIR" status --porcelain 2>/dev/null | wc -l))"
echo "guava       : $GUAVA_JAR (sha1 $(sha1sum "$GUAVA_JAR" | cut -c1-12))"
echo "java        : $(java -version 2>&1 | head -1)"

mkdir -p "$WORK/src" "$WORK/classes"
cat > "$WORK/src/MC8Repro.java" <<'JAVA'
import com.github.rholder.retry.Attempt;
import com.github.rholder.retry.AttemptTimeLimiters;
import com.github.rholder.retry.RetryException;
import com.github.rholder.retry.RetryListener;
import com.github.rholder.retry.Retryer;
import com.github.rholder.retry.RetryerBuilder;
import com.github.rholder.retry.StopStrategies;
import com.github.rholder.retry.StopStrategy;
import com.google.common.util.concurrent.UncheckedTimeoutException;
import com.google.common.util.concurrent.Uninterruptibles;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.Callable;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.RejectedExecutionException;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicReference;

public class MC8Repro {
    static final long T = 300;          // per-attempt time limit (ms) for S1/S2
    static final long T_LIVE = 100;     // per-attempt time limit (ms) for S2b
    static final long T0 = System.nanoTime();

    static long now() { return TimeUnit.NANOSECONDS.toMillis(System.nanoTime() - T0); }
    static void log(String s) { System.out.printf("  %6d ms  %-9s %s%n", now(), Thread.currentThread().getName(), s); }

    /** Records every Attempt the Retryer reports, with the limiter pool's queue length at that moment. */
    static final class Recorder implements RetryListener {
        final ThreadPoolExecutor pool;
        final List<String> events = Collections.synchronizedList(new ArrayList<String>());
        final AtomicInteger count = new AtomicInteger();
        final AtomicInteger maxQueue = new AtomicInteger();
        final boolean quiet;
        Recorder(ThreadPoolExecutor pool, boolean quiet) { this.pool = pool; this.quiet = quiet; }
        @Override
        public <V> void onRetry(Attempt<V> a) {
            int q = pool.getQueue().size();
            maxQueue.set(Math.max(maxQueue.get(), q));
            String what = a.hasException() ? "exception=" + a.getExceptionCause().getClass().getSimpleName()
                                           : "result=" + a.getResult();
            String e = Thread.currentThread().getName() + " attempt#" + a.getAttemptNumber() + " " + what
                    + " (limiter queue=" + q + ", busy workers=" + pool.getActiveCount() + ")";
            events.add(e);
            count.incrementAndGet();
            if (!quiet) log("[listener] attempt#" + a.getAttemptNumber() + " " + what + " | limiter queue=" + q
                    + " busy workers=" + pool.getActiveCount());
        }
        int countFor(String thread) {
            int n = 0;
            synchronized (events) { for (String e : events) if (e.startsWith(thread + " ")) n++; }
            return n;
        }
        String firstFor(String thread) {
            synchronized (events) { for (String e : events) if (e.startsWith(thread + " ")) return e; }
            return "<none>";
        }
    }

    static final class Outcome {
        volatile String result; volatile Throwable error;
        String describe() {
            if (error == null) return "returned " + result;
            if (error instanceof RetryException) {
                RetryException re = (RetryException) error;
                Attempt<?> last = re.getLastFailedAttempt();
                return "RetryException(numberOfFailedAttempts=" + re.getNumberOfFailedAttempts() + ", last cause="
                        + (last.hasException() ? last.getExceptionCause().getClass().getSimpleName() : "result") + ")";
            }
            return error.getClass().getSimpleName() + "(cause=" + (error.getCause() == null ? null : error.getCause().getClass().getSimpleName()) + ")";
        }
        int failedAttempts() { return error instanceof RetryException ? ((RetryException) error).getNumberOfFailedAttempts() : 0; }
        Class<?> lastCause() {
            if (!(error instanceof RetryException)) return null;
            Attempt<?> last = ((RetryException) error).getLastFailedAttempt();
            return last.hasException() ? last.getExceptionCause().getClass() : null;
        }
    }

    static Thread caller(final String name, final Retryer<String> r, final Callable<String> c, final Outcome out) {
        Thread t = new Thread(new Runnable() {
            public void run() {
                log("Retryer.call() begins");
                try { out.result = r.call(c); } catch (Throwable e) { out.error = e; }
                log("Retryer.call() ends: " + out.describe());
            }
        }, name);
        return t;
    }

    static boolean check(String label, boolean ok) {
        System.out.println("  [" + (ok ? "OK  " : "FAIL") + "] " + label);
        return ok;
    }

    // ---------------------------------------------------------------- S1: two callers share one Retryer
    static boolean s1(boolean bounded) throws Exception {
        String cfg = bounded ? "ThreadPoolExecutor(1,1,ArrayBlockingQueue(1))  [bounded, as in MC_hunt_s4_executor]"
                             : "Executors.newCachedThreadPool()  [CONTROL: the library's default kind of pool]";
        System.out.println("\n--- S1 " + (bounded ? "" : "control ") + "| limiter pool = " + cfg
                + " | fixedTimeLimit(" + T + " ms), retryIfRuntimeException(), stopAfterAttempt(2), fixedWait 0");
        final ThreadPoolExecutor pool = bounded
                ? new ThreadPoolExecutor(1, 1, 0L, TimeUnit.MILLISECONDS, new ArrayBlockingQueue<Runnable>(1))
                : (ThreadPoolExecutor) Executors.newCachedThreadPool();
        Recorder rec = new Recorder(pool, false);
        Retryer<String> shared = RetryerBuilder.<String>newBuilder()
                .retryIfRuntimeException()
                .withAttemptTimeLimiter(AttemptTimeLimiters.<String>fixedTimeLimit(T, TimeUnit.MILLISECONDS, pool))
                .withStopStrategy(StopStrategies.stopAfterAttempt(2))
                .withRetryListener(rec)
                .build();
        final AtomicInteger inv1 = new AtomicInteger(), inv2 = new AtomicInteger();
        final CountDownLatch c1Running = new CountDownLatch(1);
        // caller-1: a slow operation that does not respond to interruption (e.g. a blocking java.io read)
        Callable<String> slow = new Callable<String>() { public String call() {
            inv1.incrementAndGet(); log("caller-1 callable INVOKED (#" + inv1.get() + "), ignores interrupts, runs " + (5 * T) + " ms");
            c1Running.countDown();
            Uninterruptibles.sleepUninterruptibly(5 * T, TimeUnit.MILLISECONDS);
            log("caller-1 callable finished (#" + inv1.get() + ")");
            return "c1-done"; } };
        // caller-2: a fast operation
        Callable<String> fast = new Callable<String>() { public String call() {
            inv2.incrementAndGet(); log("caller-2 callable INVOKED (#" + inv2.get() + ")");
            return "c2-done"; } };
        Outcome o1 = new Outcome(), o2 = new Outcome();
        Thread t1 = caller("caller-1", shared, slow, o1);
        Thread t2 = caller("caller-2", shared, fast, o2);
        t1.start();
        if (!c1Running.await(10, TimeUnit.SECONDS)) throw new IllegalStateException("caller-1 never ran");
        t2.start();
        t1.join(20000); t2.join(20000);
        // let the pool drain (the zombie finishes, the cancelled queued task is dequeued and skipped)
        Thread.sleep(6 * T);
        pool.shutdown();
        pool.awaitTermination(10, TimeUnit.SECONDS);
        System.out.println("  summary: caller-1 -> " + o1.describe() + ", callable invocations=" + inv1.get()
                + "; caller-2 -> " + o2.describe() + ", callable invocations=" + inv2.get()
                + " (after the pool drained and terminated)");
        System.out.println("  caller-2 first attempt as seen by the listener: " + rec.firstFor("caller-2"));
        boolean ok = true;
        if (bounded) {
            ok &= check("caller-2 attempt#1 counted as UncheckedTimeoutException while its task sat in the queue (CE bfs1 end state)",
                    rec.firstFor("caller-2").contains("attempt#1 exception=UncheckedTimeoutException")
                    && rec.firstFor("caller-2").contains("limiter queue=1"));
            ok &= check("caller-2: RetryException counts 2 failed attempts, callable invoked 0 times",
                    o2.failedAttempts() == 2 && inv2.get() == 0);
            ok &= check("caller-2 attempt#2 = RejectedExecutionException (its own cancelled task still fills the queue)",
                    o2.lastCause() == RejectedExecutionException.class);
            ok &= check("caller-1: RetryException counts 2 failed attempts, callable invoked 1 time, last = RejectedExecutionException (CE bfs3 end state)",
                    o1.failedAttempts() == 2 && inv1.get() == 1 && o1.lastCause() == RejectedExecutionException.class);
        } else {
            ok &= check("control: caller-2 succeeds on attempt#1 and its callable ran once",
                    "c2-done".equals(o2.result) && inv2.get() == 1 && rec.countFor("caller-2") == 1);
            ok &= check("control: caller-1 RetryException counts 2 attempts and its callable ran 2 times (counted == invoked)",
                    o1.failedAttempts() == 2 && inv1.get() == 2);
        }
        return ok;
    }

    // ---------------------------------------------------------------- S2: wrap() on the limiter's own pool
    static boolean s2(boolean samePool) throws Exception {
        System.out.println("\n--- S2 " + (samePool ? "" : "control ") + "| limiter pool = 1-thread pool; RetryerCallable submitted to "
                + (samePool ? "THE SAME pool  [as in MC_hunt_s4_wrap_samepool]" : "a SEPARATE pool  [CONTROL]")
                + " | fixedTimeLimit(" + T + " ms), retryIfExceptionOfType(UncheckedTimeoutException), stopAfterAttempt(3)");
        final ThreadPoolExecutor limiterPool = new ThreadPoolExecutor(1, 1, 0L, TimeUnit.MILLISECONDS, new LinkedBlockingQueue<Runnable>());
        ExecutorService outerPool = samePool ? limiterPool : Executors.newFixedThreadPool(1);
        Recorder rec = new Recorder(limiterPool, false);
        Retryer<String> r = RetryerBuilder.<String>newBuilder()
                .retryIfExceptionOfType(UncheckedTimeoutException.class)
                .withAttemptTimeLimiter(AttemptTimeLimiters.<String>fixedTimeLimit(T, TimeUnit.MILLISECONDS, limiterPool))
                .withStopStrategy(StopStrategies.stopAfterAttempt(3))
                .withRetryListener(rec)
                .build();
        final AtomicInteger inv = new AtomicInteger();
        Callable<String> c = new Callable<String>() { public String call() {
            inv.incrementAndGet(); log("callable INVOKED (#" + inv.get() + ")"); return "ok"; } };
        Future<String> f = outerPool.submit(r.wrap(c));
        Outcome o = new Outcome();
        try { o.result = f.get(30, TimeUnit.SECONDS); }
        catch (ExecutionException e) { o.error = e.getCause(); }
        int queuedAfterCall = limiterPool.getQueue().size();
        outerPool.shutdown(); limiterPool.shutdown();
        outerPool.awaitTermination(10, TimeUnit.SECONDS); limiterPool.awaitTermination(10, TimeUnit.SECONDS);
        System.out.println("  summary: RetryerCallable -> " + o.describe() + ", callable invocations=" + inv.get()
                + " (after both pools terminated); cancelled attempt tasks left in the limiter queue when call() ended="
                + queuedAfterCall);
        boolean ok = true;
        if (samePool) {
            ok &= check("RetryException counts 3 failed attempts (each UncheckedTimeoutException while queued), callable invoked 0 times (CE wrap_samepool end state)",
                    o.failedAttempts() == 3 && o.lastCause() == UncheckedTimeoutException.class && inv.get() == 0);
            ok &= check("each cancelled attempt task stayed queued behind the RetryerCallable (queue grew to 3)",
                    rec.maxQueue.get() == 3);
        } else {
            ok &= check("control: returns 'ok' on attempt#1, callable invoked once", "ok".equals(o.result) && inv.get() == 1 && rec.count.get() == 1);
        }
        return ok;
    }

    // ---------------------------------------------------------------- S2b: same as S2 with neverStop
    static boolean s2b() throws Exception {
        long window = 3000;
        System.out.println("\n--- S2b | wrap() on the limiter's own 1-thread pool, fixedTimeLimit(" + T_LIVE
                + " ms), retryIfExceptionOfType(UncheckedTimeoutException), neverStop; observe " + window + " ms");
        final ThreadPoolExecutor pool = new ThreadPoolExecutor(1, 1, 0L, TimeUnit.MILLISECONDS, new LinkedBlockingQueue<Runnable>());
        Recorder rec = new Recorder(pool, true);
        Retryer<String> r = RetryerBuilder.<String>newBuilder()
                .retryIfExceptionOfType(UncheckedTimeoutException.class)
                .withAttemptTimeLimiter(AttemptTimeLimiters.<String>fixedTimeLimit(T_LIVE, TimeUnit.MILLISECONDS, pool))
                .withStopStrategy(StopStrategies.neverStop())
                .withRetryListener(rec)
                .build();
        final AtomicInteger inv = new AtomicInteger();
        Callable<String> c = new Callable<String>() { public String call() { inv.incrementAndGet(); return "ok"; } };
        Future<String> f = pool.submit(r.wrap(c));
        int[] attemptsAt = new int[3];
        for (int i = 0; i < 3; i++) {
            Thread.sleep(window / 3);
            attemptsAt[i] = rec.count.get();
            log("after " + ((i + 1) * window / 3) + " ms: attempts counted=" + attemptsAt[i] + ", callable invocations="
                    + inv.get() + ", limiter queue=" + pool.getQueue().size() + ", outer done=" + f.isDone());
        }
        boolean progressing = attemptsAt[0] > 0 && attemptsAt[1] > attemptsAt[0] && attemptsAt[2] > attemptsAt[1];
        int invBefore = inv.get();
        int queueBefore = pool.getQueue().size();
        boolean stillRunning = !f.isDone();
        f.cancel(true);                      // stop the loop (interrupt reaches future.get in SimpleTimeLimiter)
        pool.shutdown();
        boolean terminated = pool.awaitTermination(10, TimeUnit.SECONDS);
        log("after cancelling the outer task: pool terminated=" + terminated + ", callable invocations=" + inv.get());
        boolean ok = true;
        ok &= check("neverStop: the call kept making and counting attempts for " + window + " ms (" + attemptsAt[2]
                + " attempts) without ever invoking the callable", stillRunning && progressing && invBefore == 0);
        ok &= check("cancelled attempt tasks accumulated in the limiter queue (" + queueBefore + " queued)", queueBefore >= attemptsAt[2] - 1);
        ok &= check("after the outer task was cancelled the queued (cancelled) attempts were drained without running the callable",
                terminated && inv.get() == 0);
        return ok;
    }

    public static void main(String[] args) throws Exception {
        boolean ok = true;
        ok &= s1(true);
        ok &= s1(false);
        ok &= s2(true);
        ok &= s2(false);
        ok &= s2b();
        System.out.println("\nRESULT: " + (ok ? "MC-8 counterexample path realised in the real library (all scenarios + controls as predicted)"
                                              : "NOT all scenarios/controls behaved as predicted"));
        System.exit(ok ? 0 : 1);
    }
}
JAVA

echo "== compiling unmodified library sources + harness (javac --release 8) =="
find "$SRC_DIR/src/main/java" -name '*.java' > "$WORK/sources.txt"
javac -nowarn -Xlint:-options -Xlint:-deprecation --release 8 -cp "$GUAVA_JAR:$JSR305_JAR" -d "$WORK/classes" \
      @"$WORK/sources.txt" "$WORK/src/MC8Repro.java" 2>&1 | grep -v '^Note:' || true
test -f "$WORK/classes/MC8Repro.class"

overall=0
for i in $(seq 1 "$RUNS"); do
    echo
    echo "================ run $i/$RUNS ================"
    if timeout 120 java -cp "$WORK/classes:$GUAVA_JAR:$JSR305_JAR" MC8Repro; then
        echo "run $i: exit 0"
    else
        rc=$?; echo "run $i: exit $rc"; overall=1
    fi
done
echo
if [ "$overall" -eq 0 ]; then
    echo "MC-8 REPRO: counterexample path realised in $RUNS/$RUNS runs"
else
    echo "MC-8 REPRO: at least one run deviated from the prediction"
fi
exit "$overall"
