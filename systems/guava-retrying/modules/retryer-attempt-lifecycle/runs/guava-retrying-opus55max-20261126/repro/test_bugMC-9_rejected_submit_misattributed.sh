#!/usr/bin/env bash
# MC-9: after the limiter's executor is shut down, RejectedExecutionException is
# recorded as the callable's failure.
#
# Escalation level: 0 (pure black box). The script uses only the public guava-retrying
# API (RetryerBuilder, AttemptTimeLimiters.fixedTimeLimit(d, unit, executor),
# RetryListener, Retryer.call) and the JDK ExecutorService API. The library source
# is compiled unmodified from the checkout. No sleeps, failpoints, or state injection
# are added to the system under test.
#
# MC counterexamples reproduced (repair round 1 regenerated them on the repaired spec;
# the action sequence and violated invariants are unchanged, and after MCSubmitRejected
# the repaired model has curQueued = FALSE where the original had TRUE):
#   spec/output/repair-r1/repair1_s4_shutdown_bfs2.out  (invariant ExecutionExceptionMeansCallableThrewExcept29;
#     originally spec/output/hunt_s4_shutdown_bfs2.out)
#     MCExecutorShutdown -> MCCallStart -> MCSubmitRejected (attempt 1 counted: made=1,
#     curInvoked=FALSE, curQueued=FALSE) -> MCListenersBegin/Notify/End -> MCPredicateAccepts
#     (outcome ExecExc, exitInfo [count 1, tag Rejected, invoked FALSE])
#   spec/output/repair-r1/repair1_ctl_s4_shutdown_cir.out  (invariant CountedImpliesInvokedNoStartRace
#     as revised by RR-002; originally spec/output/hunt_s4_shutdown_bfs1.out)
#     the prefix up to MCSubmitRejected: the rejected submit is counted as attempt 1
#   The repro checks curQueued = FALSE directly: after the rejection the executor reports
#   taskCount=0, an empty queue and largestPoolSize=0 (the task was never queued or started).
#
# Scenarios:
#   S1  exact bfs2 trace, plus executor-type and shutdown/shutdownNow matrix, plus controls
#   S2  bfs1 consequence: RetryException counts N "failed attempts" that never ran
#   S3  retryIfRuntimeException()/retryIfException() with default neverStop+noWait:
#       call() spins through attempts that never run (busy loop until interrupted)
#   S3b the README "Exponential Backoff" configuration verbatim plus fixedTimeLimit(1s, executor):
#       call() keeps retrying rejected submits and never returns (until interrupted)
#   S4  realistic trigger: executor shut down while a call() is waiting between attempts
#
# Exit code: 0 = bug reproduced (S1, the MC counterexample, manifests);
#            1 = not reproduced (documented behaviour observed); 2 = harness/build error.
#
# Usage: ./test_bugMC-9_rejected_submit_misattributed.sh
#   Overrides: GR_SRC (guava-retrying checkout), GUAVA_JAR, JSR305_JAR, JAVA_HOME
set -uo pipefail

DEFAULT_SRC=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-9/worktree
FALLBACK_SRC=/home/ubuntu/scratch/guava-retrying-src/guava-retrying
GR_SRC=${GR_SRC:-$DEFAULT_SRC}
[ -d "$GR_SRC/src/main/java" ] || GR_SRC=$FALLBACK_SRC
GUAVA_JAR=${GUAVA_JAR:-$HOME/.m2/repository/com/google/guava/guava/22.0/guava-22.0.jar}
JSR305_JAR=${JSR305_JAR:-$HOME/.m2/repository/com/google/code/findbugs/jsr305/2.0.2/jsr305-2.0.2.jar}
JAVA=${JAVA_HOME:+$JAVA_HOME/bin/}java
JAVAC=${JAVA_HOME:+$JAVA_HOME/bin/}javac

for f in "$GUAVA_JAR" "$JSR305_JAR"; do
  [ -f "$f" ] || { echo "HARNESS ERROR: missing $f"; exit 2; }
done
[ -d "$GR_SRC/src/main/java" ] || { echo "HARNESS ERROR: no guava-retrying source at $GR_SRC"; exit 2; }

WORK=$(mktemp -d "${TMPDIR:-/tmp}/mc9-repro.XXXXXX")
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/lib" "$WORK/drv"

echo "== environment"
echo "source       : $GR_SRC"
echo "source HEAD  : $(git -C "$GR_SRC" rev-parse HEAD 2>/dev/null || echo n/a)"
echo "source dirty : $(git -C "$GR_SRC" status --porcelain -- src 2>/dev/null | wc -l) modified file(s) under src/ (0 = unmodified library)"
echo "Retryer.java sha256            : $(sha256sum "$GR_SRC/src/main/java/com/github/rholder/retry/Retryer.java" | cut -c1-16)"
echo "AttemptTimeLimiters.java sha256: $(sha256sum "$GR_SRC/src/main/java/com/github/rholder/retry/AttemptTimeLimiters.java" | cut -c1-16)"
echo "guava jar    : $GUAVA_JAR (sha1 $(sha1sum "$GUAVA_JAR" | cut -d' ' -f1))"
echo "jsr305 jar   : $JSR305_JAR (sha1 $(sha1sum "$JSR305_JAR" | cut -d' ' -f1))"
echo "java         : $("$JAVA" -version 2>&1 | head -1)"

echo "== compiling unmodified guava-retrying main sources (--release 8)"
if ! "$JAVAC" --release 8 -nowarn -g -encoding UTF-8 -d "$WORK/lib" -cp "$GUAVA_JAR:$JSR305_JAR" \
     $(find "$GR_SRC/src/main/java" -name '*.java') 2> "$WORK/javac-lib.err"; then
  cat "$WORK/javac-lib.err"; echo "HARNESS ERROR: library compile failed"; exit 2
fi

cat > "$WORK/drv/MC9Repro.java" <<'JAVA'
import com.github.rholder.retry.Attempt;
import com.github.rholder.retry.AttemptTimeLimiters;
import com.github.rholder.retry.RetryException;
import com.github.rholder.retry.RetryListener;
import com.github.rholder.retry.Retryer;
import com.github.rholder.retry.RetryerBuilder;
import com.github.rholder.retry.StopStrategies;
import com.github.rholder.retry.WaitStrategies;

import java.io.IOException;
import java.lang.management.ManagementFactory;
import java.lang.management.ThreadMXBean;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.concurrent.Callable;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.ForkJoinPool;
import java.util.concurrent.RejectedExecutionException;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicLong;
import java.util.concurrent.atomic.AtomicReference;

public class MC9Repro {
    static final long T0 = System.nanoTime();
    static final List<String> BUG = new ArrayList<String>();
    static final List<String> NOT_REPRODUCED = new ArrayList<String>();
    static boolean s1Reproduced = false;

    static void log(String fmt, Object... args) {
        System.out.println(String.format("[%8.1f ms] ", (System.nanoTime() - T0) / 1e6) + String.format(fmt, args));
    }

    /** Public RetryListener: records what the Retryer reports as an attempt. */
    static final class RecordingListener implements RetryListener {
        final AtomicLong notified = new AtomicLong();
        final List<String> firstFew = Collections.synchronizedList(new ArrayList<String>());
        final AtomicInteger invocations;
        volatile CountDownLatch onFirst;
        /** If set, onRetry also records whether any attempt's task ever reached this executor
         *  (repaired counterexample state 4: curQueued = FALSE after MCSubmitRejected). */
        volatile ThreadPoolExecutor watch;
        volatile boolean taskEverReachedExecutor = false;
        RecordingListener(AtomicInteger invocations) { this.invocations = invocations; }
        @Override
        public <V> void onRetry(Attempt<V> a) {
            long n = notified.incrementAndGet();
            ThreadPoolExecutor w = watch;
            String exState = "";
            if (w != null) {
                long tasks = w.getTaskCount();
                int queued = w.getQueue().size();
                int largest = w.getLargestPoolSize();
                if (tasks != 0 || queued != 0 || largest != 0) taskEverReachedExecutor = true;
                exState = " | executor taskCount=" + tasks + " queue.size=" + queued + " largestPoolSize=" + largest;
            }
            if (n <= 3) {
                firstFew.add("listener.onRetry: attempt#" + a.getAttemptNumber()
                        + " hasException=" + a.hasException()
                        + (a.hasException() ? " getExceptionCause()=" + a.getExceptionCause().getClass().getName()
                                            : " getResult()=" + a.getResult())
                        + " | callable invocations so far=" + invocations.get() + exState);
            }
            CountDownLatch l = onFirst;
            if (l != null) l.countDown();
        }
    }

    static void printFrames(String label, Throwable t, int max) {
        log("    %s %s", label, t.getClass().getName() + (t.getMessage() == null ? "" : ": " + abbreviate(t.getMessage())));
        int i = 0;
        for (StackTraceElement e : t.getStackTrace()) {
            log("        at %s", e);
            if (++i >= max || e.toString().startsWith("com.github.rholder.retry.Retryer.call(")) break;
        }
    }

    static String abbreviate(String s) { return s.length() > 110 ? s.substring(0, 110) + "..." : s; }

    static Retryer<String> limited(ExecutorService ex, RecordingListener l, String predicate) {
        RetryerBuilder<String> b = RetryerBuilder.<String>newBuilder()
                .withAttemptTimeLimiter(AttemptTimeLimiters.<String>fixedTimeLimit(1, TimeUnit.SECONDS, ex))
                .withRetryListener(l);
        if (predicate.equals("IOException")) b.retryIfExceptionOfType(IOException.class);
        else if (predicate.equals("RuntimeException")) b.retryIfRuntimeException();
        else if (predicate.equals("Exception")) b.retryIfException();
        return b.build();
    }

    // ---------------------------------------------------------------- S1
    static void s1() throws Exception {
        log("=== S1: exact MC counterexample repair-r1/repair1_s4_shutdown_bfs2 (originally hunt_s4_shutdown_bfs2)"
                + " (retryIfExceptionOfType(IOException), fixedTimeLimit(1s, executor))");
        ExecutorService ex = Executors.newCachedThreadPool();
        ex.shutdown();
        log("[CE state 2 MCExecutorShutdown] executor.shutdown() -> isShutdown=%s", ex.isShutdown());
        final AtomicInteger inv = new AtomicInteger();
        RecordingListener l = new RecordingListener(inv);
        l.watch = (ThreadPoolExecutor) ex;
        Retryer<String> r = limited(ex, l, "IOException");
        Callable<String> callable = new Callable<String>() {
            public String call() { inv.incrementAndGet(); return "callable-ran"; }
        };
        log("[CE state 3 MCCallStart] retryer.call(callable)");
        Throwable thrown = null;
        String ret = null;
        try { ret = r.call(callable); } catch (Throwable t) { thrown = t; }
        for (String s : l.firstFew) log("[CE states 4-7 MCSubmitRejected + MCListener*] %s", s);
        if (thrown == null) {
            log("[outcome] call() RETURNED %s; callable invocations=%d", ret, inv.get());
            NOT_REPRODUCED.add("S1: call() returned normally");
            return;
        }
        log("[CE state 8 MCPredicateAccepts -> outcome ExecExc] call() threw %s", thrown);
        printFrames("thrown exception created at:", thrown, 2);
        if (thrown.getCause() != null) printFrames("its cause (the 'callable exception'):", thrown.getCause(), 12);
        log("    callable invocations=%d  listener notifications=%d", inv.get(), l.notified.get());
        ThreadPoolExecutor tpe = (ThreadPoolExecutor) ex;
        log("[repaired CE state 4: made=1, curInvoked=FALSE, curQueued=FALSE] executor after call(): taskCount=%d queue.size=%d"
                + " largestPoolSize=%d completedTaskCount=%d isTerminated=%s -> task ever queued or started: %s",
                tpe.getTaskCount(), tpe.getQueue().size(), tpe.getLargestPoolSize(), tpe.getCompletedTaskCount(),
                tpe.isTerminated(), l.taskEverReachedExecutor);
        if (thrown instanceof ExecutionException && thrown.getCause() instanceof RejectedExecutionException && inv.get() == 0
                && !l.taskEverReachedExecutor && tpe.getTaskCount() == 0) {
            s1Reproduced = true;
            BUG.add("S1 (repair1_s4_shutdown_bfs2): call() threw ExecutionException(RejectedExecutionException) while the callable was invoked 0 times"
                    + " and its task never reached the executor (taskCount=0); the listener was told attempt#1 threw"
                    + " (Retryer.call Javadoc: ExecutionException only 'if the given callable throws an exception')");
        } else {
            NOT_REPRODUCED.add("S1: outcome " + thrown + " invocations=" + inv.get() + " taskEverReachedExecutor=" + l.taskEverReachedExecutor);
        }

        log("--- S1 controls: same Retryer configuration, executor NOT shut down");
        ExecutorService live = Executors.newCachedThreadPool();
        try {
            final AtomicInteger inv2 = new AtomicInteger();
            Retryer<String> r2 = limited(live, new RecordingListener(inv2), "IOException");
            try {
                r2.call(new Callable<String>() { public String call() { inv2.incrementAndGet(); throw new IllegalStateException("callable's own failure"); } });
                log("control C1 (callable throws IllegalStateException): call() returned ?!");
            } catch (ExecutionException e) {
                log("control C1 (callable throws IllegalStateException): call() threw ExecutionException(cause=%s); callable invocations=%d  <- documented case",
                        e.getCause().getClass().getSimpleName(), inv2.get());
            }
            final AtomicInteger inv3 = new AtomicInteger();
            Retryer<String> r3 = limited(live, new RecordingListener(inv3), "IOException");
            String v = r3.call(new Callable<String>() { public String call() { inv3.incrementAndGet(); return "callable-ran"; } });
            log("control C2 (callable returns): call() returned \"%s\"; callable invocations=%d", v, inv3.get());
        } finally {
            live.shutdownNow();
        }

        log("--- S1 matrix: executor kind x shutdown()/shutdownNow(), same Retryer configuration");
        String[] kinds = {"newCachedThreadPool", "newFixedThreadPool(2)", "newSingleThreadExecutor", "ForkJoinPool(2)"};
        int matrixHits = 0, matrixRuns = 0;
        for (String kind : kinds) {
            for (String mode : new String[]{"shutdown", "shutdownNow"}) {
                ExecutorService e2 = kind.startsWith("newCached") ? Executors.newCachedThreadPool()
                        : kind.startsWith("newFixed") ? Executors.newFixedThreadPool(2)
                        : kind.startsWith("newSingle") ? Executors.newSingleThreadExecutor()
                        : new ForkJoinPool(2);
                if (mode.equals("shutdown")) e2.shutdown(); else e2.shutdownNow();
                final AtomicInteger inv4 = new AtomicInteger();
                RecordingListener l4 = new RecordingListener(inv4);
                Retryer<String> r4 = limited(e2, l4, "IOException");
                String outcome;
                boolean hit = false;
                try {
                    outcome = "returned " + r4.call(new Callable<String>() { public String call() { inv4.incrementAndGet(); return "x"; } });
                } catch (ExecutionException e) {
                    outcome = "ExecutionException(cause=" + e.getCause().getClass().getSimpleName() + ")";
                    hit = e.getCause() instanceof RejectedExecutionException && inv4.get() == 0;
                } catch (Throwable t) {
                    outcome = t.toString();
                }
                matrixRuns++;
                if (hit) matrixHits++;
                log("    %-24s %-11s -> %-55s callable invocations=%d attempts reported to listener=%d",
                        kind, mode + "()", outcome, inv4.get(), l4.notified.get());
            }
        }
        log("    matrix: %d/%d configurations misattribute the rejected submit as the callable's exception", matrixHits, matrixRuns);
        if (matrixHits > 0) BUG.add("S1 matrix: " + matrixHits + "/" + matrixRuns + " executor kinds/shutdown modes give ExecutionException(RejectedExecutionException) with 0 invocations");
    }

    // ---------------------------------------------------------------- S2
    static void s2() throws Exception {
        log("=== S2: MC counterexample repair-r1/repair1_ctl_s4_shutdown_cir (originally hunt_s4_shutdown_bfs1) consequence:"
                + " rejected submits counted as failed attempts (retryIfException(), stopAfterAttempt(3))");
        ExecutorService ex = Executors.newCachedThreadPool();
        ex.shutdown();
        final AtomicInteger inv = new AtomicInteger();
        RecordingListener l = new RecordingListener(inv);
        l.watch = (ThreadPoolExecutor) ex;
        Retryer<String> r = RetryerBuilder.<String>newBuilder()
                .withAttemptTimeLimiter(AttemptTimeLimiters.<String>fixedTimeLimit(1, TimeUnit.SECONDS, ex))
                .retryIfException()
                .withStopStrategy(StopStrategies.stopAfterAttempt(3))
                .withRetryListener(l)
                .build();
        try {
            String v = r.call(new Callable<String>() { public String call() { inv.incrementAndGet(); return "callable-ran"; } });
            log("call() returned %s", v);
            NOT_REPRODUCED.add("S2: returned normally");
        } catch (RetryException e) {
            for (String s : l.firstFew) log("    %s", s);
            log("call() threw RetryException: \"%s\"", e.getMessage());
            log("    getNumberOfFailedAttempts()=%d  getLastFailedAttempt().getAttemptNumber()=%d  getLastFailedAttempt().getExceptionCause()=%s",
                    e.getNumberOfFailedAttempts(), e.getLastFailedAttempt().getAttemptNumber(),
                    e.getLastFailedAttempt().getExceptionCause().getClass().getName());
            log("    callable invocations=%d  listener notifications=%d  executor taskCount=%d (task ever queued or started: %s)",
                    inv.get(), l.notified.get(), ((ThreadPoolExecutor) ex).getTaskCount(), l.taskEverReachedExecutor);
            if (e.getNumberOfFailedAttempts() == 3 && inv.get() == 0 && !l.taskEverReachedExecutor
                    && e.getLastFailedAttempt().getExceptionCause() instanceof RejectedExecutionException) {
                BUG.add("S2 (repair1_ctl_s4_shutdown_cir): RetryException reports 3 failed attempts (last cause RejectedExecutionException)"
                        + " although the callable was invoked 0 times and no task ever reached the executor");
            } else {
                NOT_REPRODUCED.add("S2: " + e);
            }
        }
    }

    // ---------------------------------------------------------------- S3
    static void s3(final String predicate, int seconds) throws Exception {
        log("=== S3: retry%s() with builder defaults neverStop + noWait, executor shut down: run call() for %d s",
                predicate.equals("Exception") ? "IfException" : "IfRuntimeException", seconds);
        ExecutorService ex = Executors.newCachedThreadPool();
        ex.shutdown();
        final AtomicInteger inv = new AtomicInteger();
        final RecordingListener l = new RecordingListener(inv);
        final Retryer<String> r = limited(ex, l, predicate);
        runAndSample("S3 (" + predicate + ")", r, inv, l, seconds, 1000, true);
    }

    static void s3Readme(int seconds) throws Exception {
        log("=== S3b: README 'Exponential Backoff' configuration verbatim (retryIfExceptionOfType(IOException), retryIfRuntimeException(),"
                + " exponentialWait(100, 5, MINUTES), neverStop()) + withAttemptTimeLimiter(fixedTimeLimit(1s, executor)); executor shut down; run call() for %d s", seconds);
        ExecutorService ex = Executors.newCachedThreadPool();
        ex.shutdown();
        final AtomicInteger inv = new AtomicInteger();
        final RecordingListener l = new RecordingListener(inv);
        final Retryer<String> r = RetryerBuilder.<String>newBuilder()
                .retryIfExceptionOfType(IOException.class)
                .retryIfRuntimeException()
                .withWaitStrategy(WaitStrategies.exponentialWait(100, 5, TimeUnit.MINUTES))
                .withStopStrategy(StopStrategies.neverStop())
                .withAttemptTimeLimiter(AttemptTimeLimiters.<String>fixedTimeLimit(1, TimeUnit.SECONDS, ex))
                .withRetryListener(l)
                .build();
        runAndSample("S3b (README exponential backoff)", r, inv, l, seconds, 3, false);
    }

    static void runAndSample(final String label, final Retryer<String> r, final AtomicInteger inv, final RecordingListener l,
                             int seconds, long minAttempts, boolean requireGrowthEverySecond) throws Exception {
        final AtomicReference<Throwable> outcome = new AtomicReference<Throwable>();
        final AtomicReference<String> returned = new AtomicReference<String>();
        final AtomicReference<Boolean> interruptFlagAfter = new AtomicReference<Boolean>();
        Thread caller = new Thread(new Runnable() {
            public void run() {
                try {
                    returned.set(r.call(new Callable<String>() { public String call() { inv.incrementAndGet(); return "callable-ran"; } }));
                } catch (Throwable t) {
                    outcome.set(t);
                }
                interruptFlagAfter.set(Thread.currentThread().isInterrupted());
            }
        }, "retry-caller");
        ThreadMXBean mx = ManagementFactory.getThreadMXBean();
        long wall0 = System.nanoTime();
        caller.start();
        long prevAttempts = -1;
        boolean growing = true;
        for (int s = 1; s <= seconds; s++) {
            Thread.sleep(1000);
            long attempts = l.notified.get();
            long cpuMs = mx.isThreadCpuTimeSupported() ? mx.getThreadCpuTime(caller.getId()) / 1000000L : -1;
            long wallMs = (System.nanoTime() - wall0) / 1000000L;
            log("    t=%ds: caller alive=%s state=%s | attempts reported to listener=%,d | callable invocations=%d | caller CPU %d ms of %d ms wall",
                    s, caller.isAlive(), caller.getState(), attempts, inv.get(), cpuMs, wallMs);
            if (attempts <= prevAttempts) growing = false;
            prevAttempts = attempts;
        }
        for (String s : l.firstFew) log("    first notifications: %s", s);
        boolean aliveBeforeInterrupt = caller.isAlive();
        long attemptsBeforeInterrupt = l.notified.get();
        caller.interrupt();
        caller.join(5000);
        log("    after Thread.interrupt(): caller alive=%s, call() outcome=%s (interrupt flag set=%s), total attempts=%,d, callable invocations=%d",
                caller.isAlive(), returned.get() != null ? "returned " + returned.get() : String.valueOf(outcome.get()),
                interruptFlagAfter.get(), l.notified.get(), inv.get());
        if (aliveBeforeInterrupt && (growing || !requireGrowthEverySecond) && inv.get() == 0 && attemptsBeforeInterrupt >= minAttempts) {
            BUG.add(label + ": call() had not returned after " + seconds + " s (" + seconds + "x the 1 s per-attempt limit); "
                    + String.format("%,d", attemptsBeforeInterrupt) + " attempts reported to listeners, 0 callable invocations");
        } else {
            NOT_REPRODUCED.add(label + ": alive=" + aliveBeforeInterrupt + " growing=" + growing + " inv=" + inv.get() + " attempts=" + attemptsBeforeInterrupt);
        }
    }

    // ---------------------------------------------------------------- S4
    static void s4(boolean shutDownDuringWait) throws Exception {
        log("=== S4%s: executor %s while call() waits between attempts (retryIfExceptionOfType(IOException), fixedWait(500ms), stopAfterAttempt(5))",
                shutDownDuringWait ? "" : " control", shutDownDuringWait ? "shut down" : "NOT shut down");
        final ExecutorService ex = Executors.newCachedThreadPool();
        final AtomicInteger inv = new AtomicInteger();
        final RecordingListener l = new RecordingListener(inv);
        l.onFirst = new CountDownLatch(1);
        Retryer<String> r = RetryerBuilder.<String>newBuilder()
                .withAttemptTimeLimiter(AttemptTimeLimiters.<String>fixedTimeLimit(1, TimeUnit.SECONDS, ex))
                .retryIfExceptionOfType(IOException.class)
                .withWaitStrategy(WaitStrategies.fixedWait(500, TimeUnit.MILLISECONDS))
                .withStopStrategy(StopStrategies.stopAfterAttempt(5))
                .withRetryListener(l)
                .build();
        Thread app = null;
        if (shutDownDuringWait) {
            app = new Thread(new Runnable() {
                public void run() {
                    try {
                        l.onFirst.await();          // attempt 1 has run and failed with IOException
                        ex.shutdown();              // application shutdown during the retry wait
                        log("    [app thread] executor.shutdown() after attempt#1 was reported (callable invocations=%d)", inv.get());
                    } catch (InterruptedException ignored) { }
                }
            }, "app-shutdown");
            app.start();
        }
        Callable<String> callable = new Callable<String>() {
            public String call() throws IOException {
                int n = inv.incrementAndGet();
                if (n == 1) throw new IOException("transient failure on invocation 1");
                return "ok-on-invocation-" + n;
            }
        };
        try {
            String v = r.call(callable);
            log("    call() returned \"%s\"; callable invocations=%d", v, inv.get());
            if (shutDownDuringWait) NOT_REPRODUCED.add("S4: returned " + v);
        } catch (ExecutionException e) {
            for (String s : l.firstFew) log("    %s", s);
            log("    call() threw ExecutionException(cause=%s); callable invocations=%d; attempts reported=%d",
                    e.getCause().getClass().getName(), inv.get(), l.notified.get());
            if (shutDownDuringWait && e.getCause() instanceof RejectedExecutionException && inv.get() == 1) {
                BUG.add("S4: shutdown during the retry wait -> attempt#2 never ran, yet call() threw ExecutionException(RejectedExecutionException) as the callable's failure");
            }
        } finally {
            if (app != null) app.join(5000);
            ex.shutdownNow();
        }
    }

    public static void main(String[] args) throws Exception {
        s1();
        s2();
        s3("RuntimeException", 3);
        s3("Exception", 1);
        s3Readme(4);
        s4(true);
        s4(false);
        System.out.println();
        log("=== SUMMARY");
        for (String b : BUG) log("BUG TRIGGERED: %s", b);
        for (String n : NOT_REPRODUCED) log("not reproduced: %s", n);
        if (s1Reproduced) {
            log("RESULT: BUG REPRODUCED (MC-9; %d scenario checks triggered)", BUG.size());
            System.exit(0);
        }
        log("RESULT: NOT REPRODUCED");
        System.exit(1);
    }
}
JAVA

echo "== compiling driver"
if ! "$JAVAC" --release 8 -nowarn -g -d "$WORK/drv" -cp "$WORK/lib:$GUAVA_JAR:$JSR305_JAR" "$WORK/drv/MC9Repro.java" 2> "$WORK/javac-drv.err"; then
  cat "$WORK/javac-drv.err"; echo "HARNESS ERROR: driver compile failed"; exit 2
fi

echo "== running"
timeout 180 "$JAVA" -cp "$WORK/drv:$WORK/lib:$GUAVA_JAR:$JSR305_JAR" MC9Repro
rc=$?
if [ $rc -eq 124 ]; then echo "HARNESS: java run hit the 180 s timeout"; exit 2; fi
exit $rc
