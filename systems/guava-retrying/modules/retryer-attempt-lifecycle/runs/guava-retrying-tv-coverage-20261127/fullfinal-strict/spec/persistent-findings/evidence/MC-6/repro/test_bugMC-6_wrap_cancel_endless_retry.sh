#!/usr/bin/env bash
# MC-6 reproduction: a Retryer.wrap() task cancelled with Future.cancel(true) / ExecutorService.shutdownNow()
# keeps retrying forever (or returns normally), and its executor worker is never released.
#
# Escalation level: 0 (pure black box). Only public API of the UNMODIFIED guava-retrying sources is used
# (RetryerBuilder, AttemptTimeLimiters.fixedTimeLimit, Retryer.wrap, RetryListener) together with standard JDK
# executors. No library source is patched, no state is injected, no sleeps are added to library code. The workload's
# callable simulates a remote call (~20 ms of interruptible I/O wait, then IOException "service unavailable").
#
# Mapping to the model-checking counterexample spec/output/hunt_s2_live_bfs.out (InterruptedCallEventuallyExits):
#   CE state 2  MCCallStart          -> the wrap() task starts Retryer.call on the app executor worker
#   CE state 3  MCCancelOuter        -> application calls task.cancel(true) (interrupt delivered to the worker)
#   CE state 5  MCGetInterrupted     -> Future.get inside SimpleTimeLimiter.callWithTimeout throws InterruptedException,
#                                       interrupt status cleared (curTag = "CallerIE")
#   CE states 6-14                   -> inner future cancelled; listeners see attempt #k = InterruptedException;
#                                       retryIfException() rejects it; neverStop; noWait -> Thread.sleep(0) returns
#   CE states 15-43, back to 30      -> later attempts fail with the callable's exception and are retried forever
# Safety views: hunt_s2_wrap_cancel_bfs3.out (an attempt starts after the cancellation) and
#               hunt_s2_wrap_cancel_bfs6.out (the cancelled task's call() returns normally, interrupt status clear).
#
# Scenarios (each runs in its own JVM, wrapped in `timeout`):
#   A  cancel              CE configuration, task.cancel(true), observe 10 s (10x the 1 s attempt time limit)
#   A' cancel x5 trials    same, 5 independent JVMs, 3 s observation each (trigger rate)
#   B  shutdownnow         CE configuration, executor.shutdownNow() (3 times) + awaitTermination for 10 s
#   C  control-cancel / control-shutdownnow
#                          retryIfExceptionOfType(IOException.class) instead of retryIfException() (CE control)
#   D  late-return         slow but successful callable; cancel(true) during attempt 1 -> attempt 2 runs after the
#                          cancellation, commits its side effect, and RetryerCallable.call() returns normally
#   E  cancel-notimelimit  no time limiter; the callable's own interruptible wait consumes the interrupt
#   F  jvm-exit            default (non-daemon) Executors.newFixedThreadPool(1): after shutdownNow() and main()
#                          returning, the JVM never exits (killed by `timeout`); control-jvm-exit exits by itself
#
# Usage: bash test_bugMC-6_wrap_cancel_endless_retry.sh
#   env SRC_ROOT   guava-retrying checkout to build (default: the MC-6 confirmation worktree)
#   env GUAVA_JAR  Guava 22.0 jar; env JSR305_JAR jsr305 2.0.2 jar
# Exit status 0 = MC-6 reproduced (all bug scenarios triggered and all controls behaved), 1 otherwise.
set -euo pipefail

SRC_ROOT=${SRC_ROOT:-/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-6/worktree}
GUAVA_JAR=${GUAVA_JAR:-$HOME/.m2/repository/com/google/guava/guava/22.0/guava-22.0.jar}
JSR305_JAR=${JSR305_JAR:-$HOME/.m2/repository/com/google/code/findbugs/jsr305/2.0.2/jsr305-2.0.2.jar}

WORK=$(mktemp -d /tmp/mc6-repro.XXXXXX)
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/lib-classes" "$WORK/test-src" "$WORK/test-classes"

echo "### MC-6 reproduction  ($(date -u +%Y-%m-%dT%H:%M:%SZ))"
echo "### source: $SRC_ROOT @ $(git -C "$SRC_ROOT" rev-parse HEAD 2>/dev/null || echo unknown) (dirty files: $(git -C "$SRC_ROOT" status --porcelain 2>/dev/null | wc -l))"
echo "### guava: $GUAVA_JAR sha256=$(sha256sum "$GUAVA_JAR" | cut -c1-16)..."
echo "### java: $(java -version 2>&1 | head -1)"

# 1. Build the unmodified library sources (Gradle 2.4 does not run on current JDKs; same recipe as the harness pom).
javac --release 8 -nowarn -encoding UTF-8 -cp "$GUAVA_JAR:$JSR305_JAR" -d "$WORK/lib-classes" \
    $(find "$SRC_ROOT/src/main/java" -name '*.java') 2>&1 | grep -v '^Note:' || true
test -f "$WORK/lib-classes/com/github/rholder/retry/Retryer.class" || { echo "library build failed"; exit 2; }

# 2. The workload (application code using the public API only).
cat > "$WORK/test-src/MC6WrapCancelRepro.java" <<'JAVA'
import com.github.rholder.retry.Attempt;
import com.github.rholder.retry.AttemptTimeLimiters;
import com.github.rholder.retry.RetryListener;
import com.github.rholder.retry.Retryer;
import com.github.rholder.retry.RetryerBuilder;

import java.io.IOException;
import java.util.List;
import java.util.concurrent.Callable;
import java.util.concurrent.CancellationException;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.ThreadFactory;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicReference;
import java.util.function.BooleanSupplier;

public class MC6WrapCancelRepro {
    static final long T0 = System.nanoTime();
    static final long ATTEMPT_TIME_LIMIT_MS = 1000;  // AttemptTimeLimiters.fixedTimeLimit(1000 ms, ...)
    static final long REMOTE_CALL_MS = 20;           // latency of the simulated remote call
    // Wait between attempts: WaitStrategies.noWait() (RetryerBuilder default) = 0 ms. Stop: neverStop() (default).

    static double now() { return (System.nanoTime() - T0) / 1e9; }

    static void log(String fmt, Object... args) {
        System.out.println(String.format("[t=%7.3fs] ", now()) + String.format(fmt, args));
        System.out.flush();
    }

    /** RetryListener: runs on the thread that executes Retryer.call (the executor worker running the wrap() task). */
    static final class Recorder implements RetryListener {
        final AtomicInteger attempts = new AtomicInteger();
        final AtomicInteger interruptedAttemptsAfterCancel = new AtomicInteger();
        final AtomicInteger printedAfterCancel = new AtomicInteger();
        volatile double cancelAt = Double.MAX_VALUE;
        volatile int attemptsAtCancel = -1;
        volatile double lastAttemptAt = -1;
        volatile String lastOutcome = "-";
        volatile String firstAfterCancel = null;
        volatile Boolean interruptStatusAtFirstAfterCancel = null;
        volatile Thread retryThread;

        @Override
        public <V> void onRetry(Attempt<V> attempt) {
            int n = attempts.incrementAndGet();
            double t = now();
            retryThread = Thread.currentThread();
            String what;
            if (attempt.hasException()) {
                Throwable c = attempt.getExceptionCause();
                what = "exception " + c.getClass().getName() + (c.getMessage() == null ? "" : ": " + c.getMessage());
            } else {
                what = "result '" + attempt.getResult() + "'";
            }
            lastAttemptAt = t;
            lastOutcome = what;
            boolean interrupted = Thread.currentThread().isInterrupted();
            boolean afterCancel = t >= cancelAt;
            if (afterCancel && firstAfterCancel == null) {
                firstAfterCancel = what;
                interruptStatusAtFirstAfterCancel = interrupted;
            }
            if (afterCancel && attempt.hasException() && attempt.getExceptionCause() instanceof InterruptedException) {
                interruptedAttemptsAfterCancel.incrementAndGet();
            }
            boolean print = n <= 2 || (afterCancel && (printedAfterCancel.incrementAndGet() <= 4
                    || attempt.hasException() && attempt.getExceptionCause() instanceof InterruptedException));
            if (print) {
                log("  onRetry: attempt #%d %s: %s | thread '%s' interrupt status=%s",
                        attempt.getAttemptNumber(), afterCancel ? "(AFTER cancellation)" : "(before cancellation)",
                        what, Thread.currentThread().getName(), interrupted);
            }
        }

        void markCancel() {
            attemptsAtCancel = attempts.get();
            cancelAt = now();
        }

        int sinceCancel() { return attempts.get() - attemptsAtCancel; }
    }

    static ThreadFactory threads(final String prefix, final boolean daemon, final List<Thread> created) {
        final AtomicInteger seq = new AtomicInteger();
        return new ThreadFactory() {
            @Override
            public Thread newThread(Runnable r) {
                Thread t = new Thread(r, prefix + "-" + seq.incrementAndGet());
                t.setDaemon(daemon);
                if (created != null) created.add(t);
                return t;
            }
        };
    }

    /** Same configuration as Executors.newFixedThreadPool(1, tf); afterExecute only records when the worker is released. */
    static final class AppExecutor extends ThreadPoolExecutor {
        volatile double taskReleasedAt = -1;

        AppExecutor(ThreadFactory tf) {
            super(1, 1, 0L, TimeUnit.MILLISECONDS, new LinkedBlockingQueue<Runnable>(), tf);
        }

        @Override
        protected void afterExecute(Runnable r, Throwable t) {
            taskReleasedAt = now();
        }
    }

    /** Simulated remote call that is currently failing: ~20 ms (interruptible) I/O wait, then IOException. */
    static Callable<String> failingRemoteCall(final AtomicInteger bodyRuns) {
        return new Callable<String>() {
            @Override
            public String call() throws Exception {
                bodyRuns.incrementAndGet();
                Thread.sleep(REMOTE_CALL_MS);
                throw new IOException("service unavailable");
            }
        };
    }

    /** The counterexample's configuration (control = the CE control predicate). */
    static Retryer<String> ceRetryer(ExecutorService timeLimiterPool, Recorder rec, boolean control) {
        RetryerBuilder<String> b = RetryerBuilder.<String>newBuilder();
        if (control) {
            b.retryIfExceptionOfType(IOException.class);
        } else {
            b.retryIfException();
        }
        return b.withAttemptTimeLimiter(AttemptTimeLimiters.<String>fixedTimeLimit(ATTEMPT_TIME_LIMIT_MS, TimeUnit.MILLISECONDS, timeLimiterPool))
                .withRetryListener(rec)
                .build(); // defaults: StopStrategies.neverStop(), WaitStrategies.noWait(), BlockStrategies.threadSleepStrategy()
    }

    static void waitUntil(BooleanSupplier cond, long timeoutMs) throws InterruptedException {
        long end = System.nanoTime() + TimeUnit.MILLISECONDS.toNanos(timeoutMs);
        while (!cond.getAsBoolean()) {
            if (System.nanoTime() > end) throw new IllegalStateException("setup condition not reached");
            Thread.sleep(2);
        }
    }

    static void observe(Future<?> task, ExecutorService app, AppExecutor appx, Thread worker, Recorder rec, AtomicInteger bodyRuns) {
        log("OBSERVE: task.isCancelled()=%s app.isShutdown()=%s | attempts since cancellation=%d (callable bodies run=%d) | "
                        + "worker '%s' alive=%s state=%s interruptStatus=%s | last attempt %.0f ms ago: %s | task released by worker=%s",
                task == null ? "n/a" : String.valueOf(task.isCancelled()), app.isShutdown(), rec.sinceCancel(), bodyRuns.get(),
                worker.getName(), worker.isAlive(), worker.getState(), worker.isInterrupted(),
                (now() - rec.lastAttemptAt) * 1000, rec.lastOutcome,
                appx == null ? "n/a" : (appx.taskReleasedAt < 0 ? "NO" : String.format("yes at t=%.3fs", appx.taskReleasedAt)));
    }

    static void printStack(Thread t) {
        StackTraceElement[] st = t.getStackTrace();
        log("STACK of '%s' (state %s):", t.getName(), t.getState());
        for (int i = 0; i < st.length && i < 16; i++) {
            System.out.println("        at " + st[i]);
        }
        System.out.flush();
    }

    /** Scenarios A / A' / C(cancel) / E. */
    static int cancelScenario(boolean control, boolean useTimeLimiter, long observeMs) throws Exception {
        List<Thread> appThreads = new CopyOnWriteArrayList<Thread>();
        AppExecutor app = new AppExecutor(threads("app-worker", true, appThreads));
        ExecutorService tlPool = Executors.newCachedThreadPool(threads("timelimiter-pool", true, null));
        Recorder rec = new Recorder();
        AtomicInteger bodyRuns = new AtomicInteger();
        Retryer<String> retryer = useTimeLimiter
                ? ceRetryer(tlPool, rec, control)
                : RetryerBuilder.<String>newBuilder().retryIfException().withRetryListener(rec).build();
        log("CONFIG: rejection=%s, timeLimiter=%s, stop=neverStop (default), wait=noWait (default), block=Thread.sleep (default); "
                        + "callable = %d ms remote call that fails with IOException",
                control ? "retryIfExceptionOfType(IOException.class) [CONTROL]" : "retryIfException()",
                useTimeLimiter ? "fixedTimeLimit(" + ATTEMPT_TIME_LIMIT_MS + " ms, cached pool)" : "none (noTimeLimit default)",
                REMOTE_CALL_MS);

        Future<String> task = app.submit(retryer.wrap(failingRemoteCall(bodyRuns)));
        waitUntil(() -> rec.attempts.get() >= 3, 10000);
        Thread worker = appThreads.get(0);

        rec.markCancel();
        boolean cancelResult = task.cancel(true);
        log("APP: task.cancel(true) returned %s; isCancelled()=%s isDone()=%s (attempts before cancellation: %d)",
                cancelResult, task.isCancelled(), task.isDone(), rec.attemptsAtCancel);
        try {
            task.get();
            log("APP: task.get() returned a value?!");
        } catch (CancellationException e) {
            log("APP: task.get() threw CancellationException -> the application considers the task finished");
        }

        for (long waited = 0; waited < observeMs; waited += 2000) {
            Thread.sleep(Math.min(2000, observeMs - waited));
            observe(task, app, app, worker, rec, bodyRuns);
            if (control && app.taskReleasedAt >= 0) break;
        }
        if (worker.isAlive() && app.taskReleasedAt < 0) printStack(worker);

        int rc;
        if (!control) {
            boolean triggered = app.taskReleasedAt < 0 && worker.isAlive() && rec.sinceCancel() >= 10
                    && rec.firstAfterCancel != null && rec.firstAfterCancel.contains("InterruptedException");
            log("RESULT %s: %s — %d attempts after cancel(true) (first one: %s, interrupt status at that point=%s); "
                            + "RetryerCallable.call() has neither returned nor thrown after %.1f s; worker never released",
                    useTimeLimiter ? "cancel" : "cancel-notimelimit", triggered ? "BUG TRIGGERED" : "NOT TRIGGERED",
                    rec.sinceCancel(), rec.firstAfterCancel, rec.interruptStatusAtFirstAfterCancel, observeMs / 1000.0);
            rc = triggered ? 0 : 1;
        } else {
            app.shutdown();
            boolean terminated = app.awaitTermination(2, TimeUnit.SECONDS);
            boolean ok = app.taskReleasedAt >= 0 && rec.sinceCancel() <= 1 && terminated;
            log("RESULT control-cancel: %s — attempts after cancel(true)=%d (%s); worker released at t=%.3fs; shutdown()+awaitTermination(2 s)=%s",
                    ok ? "CONTROL OK (call exits after the cancellation)" : "CONTROL FAILED",
                    rec.sinceCancel(), rec.firstAfterCancel, app.taskReleasedAt, terminated);
            rc = ok ? 0 : 1;
        }
        return rc;
    }

    /** Scenario B / C(shutdownNow). */
    static int shutdownNowScenario(boolean control, long observeMs) throws Exception {
        List<Thread> appThreads = new CopyOnWriteArrayList<Thread>();
        AppExecutor app = new AppExecutor(threads("app-worker", true, appThreads));
        ExecutorService tlPool = Executors.newCachedThreadPool(threads("timelimiter-pool", true, null));
        Recorder rec = new Recorder();
        AtomicInteger bodyRuns = new AtomicInteger();
        Retryer<String> retryer = ceRetryer(tlPool, rec, control);
        log("CONFIG: rejection=%s, timeLimiter=fixedTimeLimit(%d ms, cached pool), stop=neverStop, wait=noWait (defaults); callable = %d ms failing remote call",
                control ? "retryIfExceptionOfType(IOException.class) [CONTROL]" : "retryIfException()", ATTEMPT_TIME_LIMIT_MS, REMOTE_CALL_MS);

        Future<String> task = app.submit(retryer.wrap(failingRemoteCall(bodyRuns)));
        waitUntil(() -> rec.attempts.get() >= 3, 10000);
        Thread worker = appThreads.get(0);

        rec.markCancel();
        List<Runnable> neverStarted = app.shutdownNow();
        int shutdownNowCalls = 1;
        log("APP: shutdownNow() called (returned %d never-started tasks); isShutdown()=%s", neverStarted.size(), app.isShutdown());
        boolean terminated = false;
        for (long waited = 0; waited < observeMs && !terminated; waited += 2000) {
            terminated = app.awaitTermination(Math.min(2000, observeMs - waited), TimeUnit.MILLISECONDS);
            log("APP: awaitTermination(2000 ms) returned %s; isTerminated()=%s", terminated, app.isTerminated());
            observe(task, app, app, worker, rec, bodyRuns);
            if (!terminated && !control && shutdownNowCalls < 3) {
                app.shutdownNow();
                shutdownNowCalls++;
                log("APP: shutdownNow() called again (#%d) -> another interrupt delivered to '%s'", shutdownNowCalls, worker.getName());
            }
        }
        if (worker.isAlive() && !terminated) printStack(worker);

        if (!control) {
            boolean triggered = !terminated && worker.isAlive() && app.taskReleasedAt < 0 && rec.sinceCancel() >= 10
                    && rec.interruptedAttemptsAfterCancel.get() >= 1;
            log("RESULT shutdownnow: %s — after %d shutdownNow() calls and %.1f s of awaitTermination, isTerminated()=%s; "
                            + "%d attempts after the first shutdownNow(), %d of them InterruptedException attempts that were retried",
                    triggered ? "BUG TRIGGERED" : "NOT TRIGGERED", shutdownNowCalls, observeMs / 1000.0, app.isTerminated(),
                    rec.sinceCancel(), rec.interruptedAttemptsAfterCancel.get());
            return triggered ? 0 : 1;
        } else {
            boolean ok = terminated && rec.sinceCancel() <= 1;
            log("RESULT control-shutdownnow: %s — awaitTermination returned %s; attempts after shutdownNow()=%d (%s)",
                    ok ? "CONTROL OK (pool terminates)" : "CONTROL FAILED", terminated, rec.sinceCancel(), rec.firstAfterCancel);
            return ok ? 0 : 1;
        }
    }

    /** Scenario D: the cancelled task performs a new attempt after the cancellation and call() returns normally. */
    static int lateReturnScenario() throws Exception {
        List<Thread> appThreads = new CopyOnWriteArrayList<Thread>();
        AppExecutor app = new AppExecutor(threads("app-worker", true, appThreads));
        ExecutorService tlPool = Executors.newCachedThreadPool(threads("timelimiter-pool", true, null));
        final Recorder rec = new Recorder();
        final AtomicInteger bodyRuns = new AtomicInteger();
        final AtomicInteger delivered = new AtomicInteger();
        final AtomicReference<Double> deliveredAt = new AtomicReference<Double>();
        Callable<String> sendInvoice = new Callable<String>() {
            @Override
            public String call() throws Exception {
                int n = bodyRuns.incrementAndGet();
                log("  callable body #%d starts on '%s' (remote call takes 300 ms)", n, Thread.currentThread().getName());
                Thread.sleep(300);
                delivered.incrementAndGet();
                deliveredAt.compareAndSet(null, now());
                log("  callable body #%d: invoice DELIVERED (side effect committed)", n);
                return "receipt-" + n;
            }
        };
        Retryer<String> retryer = RetryerBuilder.<String>newBuilder()
                .retryIfException()
                .withAttemptTimeLimiter(AttemptTimeLimiters.<String>fixedTimeLimit(5, TimeUnit.SECONDS, tlPool))
                .withRetryListener(rec)
                .build();
        log("CONFIG: retryIfException(), fixedTimeLimit(5 s, cached pool), neverStop, noWait; callable = 300 ms remote call that succeeds");
        final Retryer.RetryerCallable<String> wrapped = retryer.wrap(sendInvoice);
        final AtomicReference<String> outcome = new AtomicReference<String>();
        Callable<String> observed = new Callable<String>() { // thin observer around the public RetryerCallable.call()
            @Override
            public String call() throws Exception {
                try {
                    String v = wrapped.call();
                    outcome.set("RETURNED NORMALLY with value '" + v + "'; Thread.currentThread().isInterrupted()=" + Thread.currentThread().isInterrupted());
                    return v;
                } catch (Exception e) {
                    outcome.set("THREW " + e + "; Thread.currentThread().isInterrupted()=" + Thread.currentThread().isInterrupted());
                    throw e;
                }
            }
        };
        Future<String> task = app.submit(observed);
        waitUntil(() -> bodyRuns.get() >= 1, 5000);
        Thread.sleep(100); // attempt #1 is in flight

        rec.markCancel();
        double cancelAt = now();
        int bodiesAtCancel = bodyRuns.get();
        boolean cancelResult = task.cancel(true);
        log("APP: task.cancel(true) returned %s; isCancelled()=%s; invoices delivered so far=%d", cancelResult, task.isCancelled(), delivered.get());
        try {
            task.get();
        } catch (CancellationException e) {
            log("APP: task.get() threw CancellationException -> the application considers the invoice NOT sent");
        }
        waitUntil(() -> outcome.get() != null, 3000);
        Thread.sleep(200);
        log("RESULT late-return: RetryerCallable.call() %s", outcome.get());
        int startedAfter = bodyRuns.get() - bodiesAtCancel;
        Double dAt = deliveredAt.get();
        log("RESULT late-return: callable bodies started after cancel(true): %d; invoices delivered: %d (first at t=%s, cancel(true) at t=%.3fs)",
                startedAfter, delivered.get(), dAt == null ? "-" : String.format("%.3fs", dAt), cancelAt);
        boolean triggered = outcome.get() != null && outcome.get().startsWith("RETURNED NORMALLY") && outcome.get().endsWith("isInterrupted()=false")
                && startedAfter >= 1 && dAt != null && dAt > cancelAt;
        log("RESULT late-return: %s", triggered
                ? "BUG TRIGGERED — a new attempt ran after the cancellation, its side effect was committed, and call() returned normally with the interrupt status clear"
                : "NOT TRIGGERED");
        return triggered ? 0 : 1;
    }

    /** Scenario F: default (non-daemon) executor; after shutdownNow() and main() returning, the JVM should exit. */
    static void jvmExitScenario(boolean control) throws Exception {
        ExecutorService app = Executors.newFixedThreadPool(1); // default thread factory: NON-daemon worker
        // Daemon time-limiter pool so idle time-limiter threads (issue #92) cannot be what keeps the JVM alive.
        ExecutorService tlPool = Executors.newCachedThreadPool(threads("timelimiter-pool", true, null));
        final Recorder rec = new Recorder();
        final AtomicInteger bodyRuns = new AtomicInteger();
        Retryer<String> retryer = ceRetryer(tlPool, rec, control);
        log("CONFIG: Executors.newFixedThreadPool(1) (non-daemon worker); rejection=%s; fixedTimeLimit(%d ms, daemon cached pool); neverStop; noWait",
                control ? "retryIfExceptionOfType(IOException.class) [CONTROL]" : "retryIfException()", ATTEMPT_TIME_LIMIT_MS);
        app.submit(retryer.wrap(failingRemoteCall(bodyRuns)));
        waitUntil(() -> rec.attempts.get() >= 3, 10000);
        final Thread worker = rec.retryThread;
        rec.markCancel();
        app.shutdownNow();
        boolean terminated = app.awaitTermination(3, TimeUnit.SECONDS);
        log("APP: shutdownNow(); awaitTermination(3 s) returned %s; worker '%s' daemon=%s alive=%s", terminated, worker.getName(), worker.isDaemon(), worker.isAlive());
        Thread monitor = new Thread(new Runnable() {
            @Override
            public void run() {
                while (true) {
                    try {
                        Thread.sleep(1500);
                    } catch (InterruptedException e) {
                        return;
                    }
                    log("MONITOR (main() has returned): worker '%s' (non-daemon) alive=%s state=%s | attempts since shutdownNow()=%d, last %.0f ms ago: %s",
                            worker.getName(), worker.isAlive(), worker.getState(), rec.sinceCancel(), (now() - rec.lastAttemptAt) * 1000, rec.lastOutcome);
                }
            }
        }, "monitor");
        monitor.setDaemon(true);
        monitor.start();
        log("APP: main() returns now; the JVM can exit only when every non-daemon thread has finished");
    }

    public static void main(String[] args) throws Exception {
        String mode = args[0];
        long observeMs = args.length > 1 ? Long.parseLong(args[1]) : 10000;
        int rc;
        switch (mode) {
            case "cancel": rc = cancelScenario(false, true, observeMs); break;
            case "cancel-notimelimit": rc = cancelScenario(false, false, observeMs); break;
            case "control-cancel": rc = cancelScenario(true, true, observeMs); break;
            case "shutdownnow": rc = shutdownNowScenario(false, observeMs); break;
            case "control-shutdownnow": rc = shutdownNowScenario(true, observeMs); break;
            case "late-return": rc = lateReturnScenario(); break;
            case "jvm-exit": jvmExitScenario(false); return;          // no System.exit: the JVM must exit by itself
            case "control-jvm-exit": jvmExitScenario(true); return;
            default: throw new IllegalArgumentException(mode);
        }
        System.exit(rc);
    }
}
JAVA

javac --release 8 -nowarn -encoding UTF-8 -cp "$WORK/lib-classes:$GUAVA_JAR:$JSR305_JAR" -d "$WORK/test-classes" \
    "$WORK/test-src/MC6WrapCancelRepro.java" 2>&1 | grep -v '^Note:' || true
CP="$WORK/test-classes:$WORK/lib-classes:$GUAVA_JAR:$JSR305_JAR"

declare -A RC
run() { # run <label> <timeout> <mode> [observeMs]
    local label=$1 to=$2; shift 2
    echo
    echo "================ scenario $label: java MC6WrapCancelRepro $* (timeout $to) ================"
    set +e
    timeout "$to" java -cp "$CP" MC6WrapCancelRepro "$@"
    local rc=$?
    set -e
    echo "================ scenario $label exit code: $rc"
    RC[$label]=$rc
}

run A-cancel 60s cancel 10000
for i in 1 2 3 4 5; do run "A-trial$i" 60s cancel 3000; done
run B-shutdownnow 60s shutdownnow 10000
run C-control-cancel 60s control-cancel 10000
run C-control-shutdownnow 60s control-shutdownnow 10000
run D-late-return 60s late-return
run E-cancel-notimelimit 60s cancel-notimelimit 6000
run F-jvm-exit 12s jvm-exit
run F-control-jvm-exit 12s control-jvm-exit

echo
echo "################ SUMMARY ################"
ok=1
trials=0
for i in 1 2 3 4 5; do [ "${RC[A-trial$i]}" = 0 ] && trials=$((trials + 1)); done
echo "A  cancel(true), CE config, 10 s window : exit ${RC[A-cancel]} (0 = endless retry after cancellation)"
echo "A' cancel(true) trials                  : $trials/5 triggered"
echo "B  shutdownNow + awaitTermination       : exit ${RC[B-shutdownnow]} (0 = pool never terminates)"
echo "C  control (IOException predicate)      : cancel exit ${RC[C-control-cancel]}, shutdownNow exit ${RC[C-control-shutdownnow]} (0 = exits/terminates)"
echo "D  late normal return after cancel      : exit ${RC[D-late-return]} (0 = call() returned normally, side effect after cancel)"
echo "E  cancel(true), no time limiter        : exit ${RC[E-cancel-notimelimit]} (0 = endless retry after cancellation)"
echo "F  JVM exit after shutdownNow           : exit ${RC[F-jvm-exit]} (124 = JVM never exited, killed by timeout)"
echo "F  control JVM exit                     : exit ${RC[F-control-jvm-exit]} (0 = JVM exited by itself)"
[ "${RC[A-cancel]}" = 0 ] || ok=0
[ "$trials" -ge 4 ] || ok=0
[ "${RC[B-shutdownnow]}" = 0 ] || ok=0
[ "${RC[C-control-cancel]}" = 0 ] || ok=0
[ "${RC[C-control-shutdownnow]}" = 0 ] || ok=0
[ "${RC[D-late-return]}" = 0 ] || ok=0
[ "${RC[E-cancel-notimelimit]}" = 0 ] || ok=0
[ "${RC[F-jvm-exit]}" = 124 ] || ok=0
[ "${RC[F-control-jvm-exit]}" = 0 ] || ok=0
if [ $ok = 1 ]; then
    echo "MC-6 REPRODUCED (Level 0): cancelled/shut-down wrap() tasks keep retrying (or return normally) and never release their worker; the control exits."
    exit 0
else
    echo "MC-6 NOT fully reproduced; see per-scenario output above."
    exit 1
fi
