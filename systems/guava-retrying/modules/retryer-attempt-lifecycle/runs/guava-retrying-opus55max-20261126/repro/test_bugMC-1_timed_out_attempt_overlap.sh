#!/usr/bin/env bash
# MC-1 reproduction: a timed-out (or caller-interrupted) attempt keeps running alongside
# later attempts and after Retryer.call() has returned or thrown.
#
# Escalation level: 0 (pure black-box). Only the public guava-retrying 2.0.0 API is used
# (RetryerBuilder, AttemptTimeLimiters.fixedTimeLimit, StopStrategies, RetryListener,
# Retryer.call / Retryer.wrap). The library source is compiled unmodified from $MC1_SRC.
# The callable is ordinary user code: it fetches a value from a local TCP service with a
# blocking java.net.Socket read (not aborted by Thread.interrupt() on a platform thread)
# and publishes the value to an application cache. The service answers slowly for some
# requests, which is the situation per-attempt time limits exist for. No sleeps, hooks or
# patches are added to guava-retrying or Guava.
#
# Scenarios: A/B (S1 timeout; hunt_s1_overlap_bfs1/bfs2, repair1_s1_timelimit_bfs1/bfs2),
# C/C2 (S2 caller interrupt; hunt_s2_interrupt_narrow_bfs3), F (wrap() + user executor),
# G (S4; repair1_s4_executor_bfs1: two call()s share one Retryer whose limiter executor is a
# user-supplied ThreadPoolExecutor with 1 thread and queue capacity 1), G0 (S4 without rejection:
# single-thread limiter executor), D (control: noTimeLimit), E (info: interrupt-responsive body).
#
# Exit code: 0 = bug reproduced in every round and the noTimeLimit control is clean;
#            1 = not reproduced (or control dirty); 2 = setup/build error.
#
# Usage: timeout 5m ./test_bugMC-1_timed_out_attempt_overlap.sh
#   env: MC1_SRC (guava-retrying checkout), GUAVA_JAR, JSR305_JAR, JAVA_BIN, JAVAC_BIN, MC1_ROUNDS
set -euo pipefail

DEFAULT_SRC=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-1/worktree
MC1_SRC=${MC1_SRC:-$DEFAULT_SRC}
GUAVA_JAR=${GUAVA_JAR:-$HOME/.m2/repository/com/google/guava/guava/22.0/guava-22.0.jar}
JSR305_JAR=${JSR305_JAR:-$HOME/.m2/repository/com/google/code/findbugs/jsr305/2.0.2/jsr305-2.0.2.jar}
JAVA_BIN=${JAVA_BIN:-java}
JAVAC_BIN=${JAVAC_BIN:-javac}
MC1_ROUNDS=${MC1_ROUNDS:-3}

for f in "$GUAVA_JAR" "$JSR305_JAR"; do
  [[ -f "$f" ]] || { echo "SETUP ERROR: missing $f"; exit 2; }
done
[[ -d "$MC1_SRC/src/main/java/com/github/rholder/retry" ]] || { echo "SETUP ERROR: no guava-retrying source at $MC1_SRC"; exit 2; }

GUAVA_SHA1=$(sha1sum "$GUAVA_JAR" | cut -d' ' -f1)
echo "guava jar : $GUAVA_JAR (sha1 $GUAVA_SHA1; Maven Central guava-22.0.jar = 3564ef3803de51fb0530a8377ec6100b33b0d073)"
echo "source    : $MC1_SRC (git HEAD $(git -C "$MC1_SRC" rev-parse HEAD 2>/dev/null || echo unknown), dirty files: $(git -C "$MC1_SRC" status --porcelain 2>/dev/null | wc -l)"
echo "java      : $("$JAVA_BIN" -version 2>&1 | head -1)"

WORK=$(mktemp -d /tmp/mc1-repro.XXXXXX)
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/lib" "$WORK/test"

cat > "$WORK/MC1Repro.java" <<'JAVA_EOF'
import com.github.rholder.retry.Attempt;
import com.github.rholder.retry.AttemptTimeLimiters;
import com.github.rholder.retry.RetryException;
import com.github.rholder.retry.RetryListener;
import com.github.rholder.retry.Retryer;
import com.github.rholder.retry.RetryerBuilder;
import com.github.rholder.retry.StopStrategies;

import java.io.BufferedReader;
import java.io.Closeable;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.InetAddress;
import java.net.ServerSocket;
import java.net.Socket;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.Callable;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicReference;

public class MC1Repro {

    // ------------------------------------------------------------------ timeline
    static volatile long scenarioStart = System.nanoTime();

    static long now() {
        return (System.nanoTime() - scenarioStart) / 1000000L;
    }

    static synchronized void log(String fmt, Object... args) {
        System.out.printf("  [t=%5d ms] %-17s %s%n", now(), Thread.currentThread().getName(), String.format(fmt, args));
    }

    // ------------------------------------------------- environment: a slow TCP service
    /** Real loopback TCP service. Request "REQ n" is answered after delayMs[n-1] (last entry repeats). */
    static final class SlowService implements Closeable {
        final ServerSocket server;
        final long[] delayMs;
        final boolean errorAnswers;
        final AtomicInteger inFlight = new AtomicInteger();
        final AtomicInteger maxInFlight = new AtomicInteger();

        SlowService(boolean errorAnswers, long... delayMs) throws IOException {
            this.server = new ServerSocket(0, 50, InetAddress.getLoopbackAddress());
            this.delayMs = delayMs;
            this.errorAnswers = errorAnswers;
            Thread acceptor = new Thread(new Runnable() {
                public void run() {
                    acceptLoop();
                }
            }, "service-acceptor");
            acceptor.setDaemon(true);
            acceptor.start();
        }

        int port() {
            return server.getLocalPort();
        }

        void acceptLoop() {
            while (!server.isClosed()) {
                try {
                    final Socket s = server.accept();
                    Thread h = new Thread(new Runnable() {
                        public void run() {
                            handle(s);
                        }
                    }, "service-handler");
                    h.setDaemon(true);
                    h.start();
                } catch (IOException e) {
                    return;
                }
            }
        }

        void handle(Socket s) {
            boolean counted = false;
            try (Socket sock = s) {
                BufferedReader in = new BufferedReader(new InputStreamReader(sock.getInputStream(), StandardCharsets.UTF_8));
                String req = in.readLine();
                if (req == null) {
                    return;
                }
                int n = Integer.parseInt(req.substring(4).trim());
                int cur = inFlight.incrementAndGet();
                counted = true;
                maxInFlight.accumulateAndGet(cur, Math::max);
                Thread.sleep(delayMs[Math.min(n, delayMs.length) - 1]);
                OutputStream out = sock.getOutputStream();
                out.write(((errorAnswers ? "ERR-" : "VALUE-") + n + "\n").getBytes(StandardCharsets.UTF_8));
                out.flush();
            } catch (Exception ignored) {
                // client went away; irrelevant here
            } finally {
                if (counted) {
                    inFlight.decrementAndGet();
                }
            }
        }

        public void close() throws IOException {
            server.close();
        }
    }

    // ------------------------------------------------ ordinary user callable (one instance per call())
    /**
     * Fetches a value from the service and publishes it to an application cache. The blocking
     * java.net.Socket read is the classic operation that Thread.interrupt() does not abort on a
     * platform thread. With interruptibleBody=true the body is Thread.sleep instead (control E).
     */
    static final class FetchAndCache implements Callable<String> {
        final int port;
        final AtomicReference<String> cache;
        final boolean interruptibleBody;
        final long sleepMs;
        final AtomicInteger attempts = new AtomicInteger();
        final AtomicInteger bodiesInFlight = new AtomicInteger();
        final AtomicInteger maxBodiesInFlight = new AtomicInteger();
        final Map<Integer, Long> enterAt = new ConcurrentHashMap<Integer, Long>();
        final Map<Integer, Long> exitAt = new ConcurrentHashMap<Integer, Long>();
        final Map<Integer, String> outcome = new ConcurrentHashMap<Integer, String>();
        final Map<Integer, Boolean> interruptFlagAtExit = new ConcurrentHashMap<Integer, Boolean>();

        FetchAndCache(int port, AtomicReference<String> cache) {
            this(port, cache, false, 0);
        }

        FetchAndCache(int port, AtomicReference<String> cache, boolean interruptibleBody, long sleepMs) {
            this.port = port;
            this.cache = cache;
            this.interruptibleBody = interruptibleBody;
            this.sleepMs = sleepMs;
        }

        @Override
        public String call() throws Exception {
            int n = attempts.incrementAndGet();
            int cur = bodiesInFlight.incrementAndGet();
            maxBodiesInFlight.accumulateAndGet(cur, Math::max);
            enterAt.put(n, now());
            log("attempt %d ENTER callable body (bodies of this call() in flight = %d)", n, cur);
            String result = null;
            String failure = null;
            try {
                if (interruptibleBody) {
                    Thread.sleep(sleepMs);             // interrupt-responsive body (control E)
                    result = "VALUE-" + n;
                } else {
                    try (Socket s = new Socket(InetAddress.getLoopbackAddress(), port)) {
                        s.getOutputStream().write(("REQ " + n + "\n").getBytes(StandardCharsets.UTF_8));
                        s.getOutputStream().flush();
                        // blocking socket read: Thread.interrupt() does not abort it on a platform thread
                        String line = new BufferedReader(new InputStreamReader(s.getInputStream(), StandardCharsets.UTF_8)).readLine();
                        if (line == null || line.startsWith("ERR")) {
                            throw new IOException("service answered " + line);
                        }
                        result = line;
                    }
                }
                cache.set(result);                     // side effect of a successful fetch
                return result;
            } catch (Exception e) {
                failure = e.getClass().getSimpleName() + ": " + e.getMessage();
                throw e;
            } finally {
                exitAt.put(n, now());
                boolean flag = Thread.currentThread().isInterrupted();
                interruptFlagAtExit.put(n, flag);
                outcome.put(n, failure == null ? "returned " + result : "threw " + failure);
                int left = bodiesInFlight.decrementAndGet();
                log("attempt %d EXIT  callable body: %s (worker interrupt flag = %s; bodies still in flight = %d)",
                        n, outcome.get(n), flag, left);
            }
        }

        void awaitQuiescence(long maxMs) throws InterruptedException {
            long deadline = System.nanoTime() + TimeUnit.MILLISECONDS.toNanos(maxMs);
            while (bodiesInFlight.get() > 0 && System.nanoTime() < deadline) {
                Thread.sleep(10);
            }
        }
    }

    static RetryListener listener() {
        return new RetryListener() {
            @Override
            public <V> void onRetry(Attempt<V> attempt) {
                if (attempt.hasException()) {
                    log("listener: attempt #%d failed with %s", attempt.getAttemptNumber(),
                            attempt.getExceptionCause().getClass().getSimpleName());
                } else {
                    log("listener: attempt #%d produced %s", attempt.getAttemptNumber(), attempt.getResult());
                }
            }
        };
    }

    // ------------------------------------------------------------------ scenario bookkeeping
    static final Map<String, int[]> tally = new LinkedHashMap<String, int[]>(); // name -> {anomaly, runs}

    static void record(String name, boolean anomaly) {
        int[] t = tally.get(name);
        if (t == null) {
            t = new int[2];
            tally.put(name, t);
        }
        if (anomaly) {
            t[0]++;
        }
        t[1]++;
    }

    static void header(String id, String text) {
        System.out.println();
        System.out.println("=== Scenario " + id + ": " + text);
        scenarioStart = System.nanoTime();
    }

    /** Invariant check from the model: prints VIOLATED when the bad condition is observed. */
    static boolean check(String label, boolean cond, String detail) {
        System.out.printf("  CHECK %-46s %s  (%s)%n", label, cond ? "VIOLATED" : "holds", detail);
        return cond;
    }

    /** Observed consequence / fact: prints YES when observed. */
    static boolean fact(String label, boolean cond, String detail) {
        System.out.printf("  FACT  %-46s %s  (%s)%n", label, cond ? "YES" : "no", detail);
        return cond;
    }

    static Retryer<String> retryer(com.github.rholder.retry.AttemptTimeLimiter<String> limiter, boolean retryAnyException, int attempts) {
        RetryerBuilder<String> b = RetryerBuilder.<String>newBuilder()
                .withAttemptTimeLimiter(limiter)
                .withStopStrategy(StopStrategies.stopAfterAttempt(attempts))
                .withRetryListener(listener());
        if (retryAnyException) {
            b.retryIfException();
        } else {
            b.retryIfRuntimeException();           // UncheckedTimeoutException is a RuntimeException
        }
        return b.build();
    }

    /** Common checks after call() ended at tEnd while 'inFlightAtEnd' bodies were still executing. */
    static boolean afterOutcomeChecks(FetchAndCache task, long tEnd, int inFlightAtEnd, String delivered) {
        boolean seq = check("SequentialAttempts (max bodies at once > 1)", task.maxBodiesInFlight.get() > 1,
                "max bodies of ONE call() executing at the same time = " + task.maxBodiesInFlight.get());
        long lastExit = 0;
        StringBuilder late = new StringBuilder();
        for (Map.Entry<Integer, Long> e : task.exitAt.entrySet()) {
            if (e.getValue() > tEnd) {
                late.append(String.format("attempt %d exited %d ms after call() ended and %s; ", e.getKey(),
                        e.getValue() - tEnd, task.outcome.get(e.getKey())));
            }
            lastExit = Math.max(lastExit, e.getValue());
        }
        boolean after = check("NoActivityAfterOutcome", inFlightAtEnd > 0 && lastExit > tEnd,
                inFlightAtEnd + " body(ies) still executing when call() ended; " + late);
        boolean dropped = false;
        for (Map.Entry<Integer, Long> e : task.exitAt.entrySet()) {
            if (e.getValue() > tEnd) {
                dropped = true;
            }
        }
        fact("late outcome silently dropped", dropped,
                "call() delivered: " + delivered + "; the late outcomes above reached nobody");
        return after;
    }

    // ------------------------------------------------------------------ scenarios
    /** A — timeout trigger, call() returns attempt 2's value while attempt 1 still runs (bfs1 + bfs2). */
    static void scenarioA() throws Exception {
        header("A", "timeout trigger, call() RETURNS. fixedTimeLimit(300 ms), retryIfRuntimeException, stopAfterAttempt(3); "
                + "service answers request 1 after 1500 ms, later requests after 50 ms");
        try (SlowService svc = new SlowService(false, 1500, 50)) {
            AtomicReference<String> cache = new AtomicReference<String>("<empty>");
            FetchAndCache task = new FetchAndCache(svc.port(), cache);
            Retryer<String> r = retryer(AttemptTimeLimiters.<String>fixedTimeLimit(300, TimeUnit.MILLISECONDS), false, 3);
            scenarioStart = System.nanoTime();
            String v = r.call(task);
            long tEnd = now();
            int inFlight = task.bodiesInFlight.get();
            String cacheAtReturn = cache.get();
            log("call() RETURNED %s; bodies of this call() still executing = %d; application cache = %s", v, inFlight, cacheAtReturn);
            task.awaitQuiescence(5000);
            log("later: application cache = %s, although call() returned %s", cache.get(), v);
            boolean seq = task.maxBodiesInFlight.get() > 1;
            boolean after = afterOutcomeChecks(task, tEnd, inFlight, "returned " + v);
            boolean stale = fact("consumer-visible stale cache", "VALUE-2".equals(v) && "VALUE-1".equals(cache.get()),
                    "cache = " + cache.get() + " after call() returned " + v);
            fact("service saw 2+ concurrent requests of one call", svc.maxInFlight.get() > 1,
                    "max concurrent requests at the service = " + svc.maxInFlight.get());
            fact("cancel(true) interrupt reached attempt 1", Boolean.TRUE.equals(task.interruptFlagAtExit.get(1)),
                    "worker interrupt flag when attempt 1's blocking read finally returned = " + task.interruptFlagAtExit.get(1));
            record("A timeout -> return (S1)", seq && after && stale);
        }
    }

    /** B — timeout trigger, stop strategy fires: call() throws RetryException while attempts still run. */
    static void scenarioB() throws Exception {
        header("B", "timeout trigger, call() THROWS RetryException. fixedTimeLimit(200 ms), stopAfterAttempt(3); "
                + "every request is answered with an error after 1000 ms");
        try (SlowService svc = new SlowService(true, 1000)) {
            AtomicReference<String> cache = new AtomicReference<String>("<empty>");
            FetchAndCache task = new FetchAndCache(svc.port(), cache);
            Retryer<String> r = retryer(AttemptTimeLimiters.<String>fixedTimeLimit(200, TimeUnit.MILLISECONDS), false, 3);
            scenarioStart = System.nanoTime();
            String delivered;
            boolean threwRetry = false;
            try {
                delivered = "returned " + r.call(task);
            } catch (RetryException e) {
                threwRetry = true;
                delivered = "RetryException(failedAttempts=" + e.getNumberOfFailedAttempts() + ", last cause="
                        + e.getLastFailedAttempt().getExceptionCause().getClass().getSimpleName() + ")";
            }
            long tEnd = now();
            int inFlight = task.bodiesInFlight.get();
            log("call() ended: %s; bodies of this call() still executing = %d", delivered, inFlight);
            task.awaitQuiescence(5000);
            boolean seq = task.maxBodiesInFlight.get() > 1;
            boolean after = afterOutcomeChecks(task, tEnd, inFlight, delivered);
            record("B timeout -> RetryException (S1)", threwRetry && seq && after);
        }
    }

    /** C — caller-interrupt trigger (S2), call() throws ExecutionException while attempt 1 still runs (bfs3). */
    static void scenarioC(final boolean retryAnyException) throws Exception {
        String id = retryAnyException ? "C2" : "C";
        header(id, "caller-interrupt trigger. fixedTimeLimit(5 s, never expires here), "
                + (retryAnyException ? "retryIfException" : "retryIfRuntimeException") + ", stopAfterAttempt(3); "
                + "service answers request 1 after 1000 ms, later requests after 50 ms; caller interrupted at ~200 ms");
        try (SlowService svc = new SlowService(false, 1000, 50)) {
            final AtomicReference<String> cache = new AtomicReference<String>("<empty>");
            final FetchAndCache task = new FetchAndCache(svc.port(), cache);
            final Retryer<String> r = retryer(AttemptTimeLimiters.<String>fixedTimeLimit(5, TimeUnit.SECONDS), retryAnyException, 3);
            final AtomicReference<String> delivered = new AtomicReference<String>();
            final long[] tEnd = new long[1];
            final int[] inFlight = new int[1];
            final boolean[] callerFlag = new boolean[1];
            Thread caller = new Thread(new Runnable() {
                public void run() {
                    try {
                        delivered.set("returned " + r.call(task));
                    } catch (ExecutionException e) {
                        delivered.set("ExecutionException(cause=" + e.getCause().getClass().getSimpleName() + ")");
                    } catch (RetryException e) {
                        delivered.set("RetryException(failedAttempts=" + e.getNumberOfFailedAttempts() + ")");
                    }
                    tEnd[0] = now();
                    inFlight[0] = task.bodiesInFlight.get();
                    callerFlag[0] = Thread.currentThread().isInterrupted();
                    log("call() ended: %s; bodies of this call() still executing = %d; application cache = %s",
                            delivered.get(), inFlight[0], cache.get());
                }
            }, "caller");
            scenarioStart = System.nanoTime();
            caller.start();
            Thread.sleep(200);
            log("interrupting the caller thread");
            caller.interrupt();
            caller.join(10000);
            task.awaitQuiescence(5000);
            log("later: application cache = %s", cache.get());
            boolean seq = task.maxBodiesInFlight.get() > 1;
            boolean after = afterOutcomeChecks(task, tEnd[0], inFlight[0], delivered.get());
            System.out.printf("  note (separate concern, not MC-1): caller interrupt status after call() = %s%n", callerFlag[0]);
            if (retryAnyException) {
                record("C2 caller interrupt -> next attempt overlaps (S2)", seq && after);
            } else {
                record("C  caller interrupt -> ExecutionException (S2)", after);
            }
        }
    }

    /** F — 3-arg factory with a user executor, call through Retryer.wrap() on an executor. */
    static void scenarioF() throws Exception {
        header("F", "user-executor factory + Retryer.wrap(). fixedTimeLimit(300 ms, newCachedThreadPool()), "
                + "wrapped callable submitted to an ExecutorService; same service timing as A");
        ExecutorService limiterPool = Executors.newCachedThreadPool();
        ExecutorService appPool = Executors.newSingleThreadExecutor();
        try (SlowService svc = new SlowService(false, 1500, 50)) {
            AtomicReference<String> cache = new AtomicReference<String>("<empty>");
            FetchAndCache task = new FetchAndCache(svc.port(), cache);
            Retryer<String> r = retryer(AttemptTimeLimiters.<String>fixedTimeLimit(300, TimeUnit.MILLISECONDS, limiterPool), false, 3);
            scenarioStart = System.nanoTime();
            Future<String> f = appPool.submit(r.wrap(task));
            String v = f.get();
            long tEnd = now();
            int inFlight = task.bodiesInFlight.get();
            log("wrapped call completed with %s (Future.isDone=%s); bodies still executing = %d", v, f.isDone(), inFlight);
            task.awaitQuiescence(5000);
            boolean seq = task.maxBodiesInFlight.get() > 1;
            boolean after = afterOutcomeChecks(task, tEnd, inFlight, "Future value " + v);
            record("F wrap() + user executor (S1)", seq && after);
        } finally {
            limiterPool.shutdownNow();
            appPool.shutdownNow();
        }
    }

    /**
     * G — S4 (repair1_s4_executor_bfs1): two call()s share one Retryer whose fixedTimeLimit uses a
     * user-supplied bounded executor (1 thread, queue capacity 1, default AbortPolicy). caller-1's
     * timed-out attempt keeps the only thread, caller-2's attempt fills the queue, caller-1's attempt 2
     * is rejected and caller-1's call() ends with RetryException while its attempt-1 body still runs.
     */
    static void scenarioG() throws Exception {
        header("G", "S4 saturated bounded limiter executor shared by two call()s. fixedTimeLimit(300 ms, "
                + "ThreadPoolExecutor(1 thread, ArrayBlockingQueue(1))), retryIfRuntimeException, stopAfterAttempt(2); "
                + "caller-1's service answers after 1500 ms, caller-2's after 50 ms; caller-2 starts at ~100 ms");
        final ThreadPoolExecutor limiterPool = new ThreadPoolExecutor(1, 1, 0L, TimeUnit.MILLISECONDS,
                new ArrayBlockingQueue<Runnable>(1));
        try (SlowService svc1 = new SlowService(false, 1500); SlowService svc2 = new SlowService(false, 50)) {
            final AtomicReference<String> cache1 = new AtomicReference<String>("<empty>");
            final AtomicReference<String> cache2 = new AtomicReference<String>("<empty>");
            final FetchAndCache[] tasks = {new FetchAndCache(svc1.port(), cache1), new FetchAndCache(svc2.port(), cache2)};
            final Retryer<String> r = retryer(AttemptTimeLimiters.<String>fixedTimeLimit(300, TimeUnit.MILLISECONDS, limiterPool), false, 2);
            final String[] delivered = new String[2];
            final long[] tEnd = new long[2];
            final int[] inFlight = new int[2];
            Thread[] callers = new Thread[2];
            for (int i = 0; i < 2; i++) {
                final int k = i;
                callers[i] = new Thread(new Runnable() {
                    public void run() {
                        try {
                            delivered[k] = "returned " + r.call(tasks[k]);
                        } catch (RetryException e) {
                            Attempt<?> last = e.getLastFailedAttempt();
                            delivered[k] = "RetryException(failedAttempts=" + e.getNumberOfFailedAttempts() + ", last cause="
                                    + (last.hasException() ? last.getExceptionCause().getClass().getSimpleName() : "result " + last.getResult()) + ")";
                        } catch (ExecutionException e) {
                            delivered[k] = "ExecutionException(cause=" + e.getCause().getClass().getSimpleName() + ")";
                        }
                        tEnd[k] = now();
                        inFlight[k] = tasks[k].bodiesInFlight.get();
                        log("call() ended: %s; bodies of this call() still executing = %d; bodies of this call() ever started = %d; "
                                + "limiter pool: active threads = %d, queued tasks = %d",
                                delivered[k], inFlight[k], tasks[k].attempts.get(), limiterPool.getActiveCount(), limiterPool.getQueue().size());
                    }
                }, "caller-" + (i + 1));
            }
            scenarioStart = System.nanoTime();
            callers[0].start();
            Thread.sleep(100);
            log("starting caller-2 on the same Retryer");
            callers[1].start();
            callers[0].join(10000);
            callers[1].join(10000);
            tasks[0].awaitQuiescence(5000);
            log("later: caller-1's application cache = %s, although caller-1's call() ended with %s", cache1.get(), delivered[0]);
            System.out.println("  -- caller-1 (its attempt 1 timed out and kept the limiter's only thread):");
            boolean after = afterOutcomeChecks(tasks[0], tEnd[0], inFlight[0], delivered[0]);
            boolean rejected = fact("caller-1 ended via rejected re-submission", delivered[0] != null
                    && delivered[0].startsWith("RetryException") && delivered[0].contains("RejectedExecutionException"),
                    "caller-1 call() ended with " + delivered[0]);
            fact("late side effect after call() threw", "VALUE-1".equals(cache1.get()) && delivered[0] != null
                    && delivered[0].startsWith("RetryException"), "caller-1 cache = " + cache1.get());
            System.out.println("  -- caller-2 (shares the Retryer and its limiter executor):");
            fact("caller-2's callable never ran, its call() failed", tasks[1].attempts.get() == 0 && delivered[1] != null
                    && !delivered[1].startsWith("returned"),
                    "caller-2 call() ended with " + delivered[1] + "; caller-2 bodies ever started = " + tasks[1].attempts.get());
            record("G  shared bounded executor -> rejection (S4)", after && rejected);
        } finally {
            limiterPool.shutdownNow();
        }
    }

    /** G0 — S4 without rejection: single-thread limiter executor (unbounded queue), one call(). */
    static void scenarioG0() throws Exception {
        header("G0", "S4 single-thread limiter executor (unbounded queue). fixedTimeLimit(300 ms, Executors.newSingleThreadExecutor()), "
                + "retryIfRuntimeException, stopAfterAttempt(3); service answers request 1 after 1500 ms, later requests after 50 ms");
        ExecutorService limiterPool = Executors.newSingleThreadExecutor();
        try (SlowService svc = new SlowService(false, 1500, 50)) {
            AtomicReference<String> cache = new AtomicReference<String>("<empty>");
            FetchAndCache task = new FetchAndCache(svc.port(), cache);
            Retryer<String> r = retryer(AttemptTimeLimiters.<String>fixedTimeLimit(300, TimeUnit.MILLISECONDS, limiterPool), false, 3);
            scenarioStart = System.nanoTime();
            String delivered;
            boolean threwRetry = false;
            try {
                delivered = "returned " + r.call(task);
            } catch (RetryException e) {
                threwRetry = true;
                delivered = "RetryException(failedAttempts=" + e.getNumberOfFailedAttempts() + ", last cause="
                        + e.getLastFailedAttempt().getExceptionCause().getClass().getSimpleName() + ")";
            }
            long tEnd = now();
            int inFlight = task.bodiesInFlight.get();
            log("call() ended: %s; bodies of this call() still executing = %d; bodies ever started = %d", delivered, inFlight, task.attempts.get());
            task.awaitQuiescence(5000);
            Thread.sleep(100); // let the single worker drain the cancelled, queued attempts
            log("later: application cache = %s; bodies ever started = %d", cache.get(), task.attempts.get());
            boolean after = afterOutcomeChecks(task, tEnd, inFlight, delivered);
            fact("attempts counted that never ran (queued, timed out)", threwRetry && task.attempts.get() == 1,
                    "Retryer counted 3 failed attempts; callable bodies ever started = " + task.attempts.get());
            record("G0 single-thread limiter executor (S4)", threwRetry && after);
        } finally {
            limiterPool.shutdownNow();
        }
    }

    /** D — control: same callable and service timing as A, but noTimeLimit(). Must be sequential. */
    static void controlD() throws Exception {
        header("D (control)", "same callable and service timing as A, AttemptTimeLimiters.noTimeLimit()");
        try (SlowService svc = new SlowService(false, 1500, 50)) {
            AtomicReference<String> cache = new AtomicReference<String>("<empty>");
            FetchAndCache task = new FetchAndCache(svc.port(), cache);
            Retryer<String> r = retryer(AttemptTimeLimiters.<String>noTimeLimit(), false, 3);
            scenarioStart = System.nanoTime();
            String v = r.call(task);
            long tEnd = now();
            int inFlight = task.bodiesInFlight.get();
            log("call() RETURNED %s; bodies still executing = %d; cache = %s", v, inFlight, cache.get());
            task.awaitQuiescence(5000);
            boolean seq = task.maxBodiesInFlight.get() > 1;
            boolean after = afterOutcomeChecks(task, tEnd, inFlight, "returned " + v);
            record("D control: noTimeLimit (expect clean)", seq || after);
        }
    }

    /** E — informational: fixedTimeLimit with an interrupt-responsive body (Thread.sleep). */
    static void controlE() throws Exception {
        header("E (info)", "fixedTimeLimit(300 ms) with an interrupt-RESPONSIVE body (Thread.sleep(1500)); not asserted");
        AtomicReference<String> cache = new AtomicReference<String>("<empty>");
        FetchAndCache task = new FetchAndCache(0, cache, true, 1500);
        Retryer<String> r = retryer(AttemptTimeLimiters.<String>fixedTimeLimit(300, TimeUnit.MILLISECONDS), false, 2);
        scenarioStart = System.nanoTime();
        String delivered;
        try {
            delivered = "returned " + r.call(task);
        } catch (RetryException e) {
            delivered = "RetryException(failedAttempts=" + e.getNumberOfFailedAttempts() + ")";
        }
        long tEnd = now();
        int inFlight = task.bodiesInFlight.get();
        log("call() ended: %s; bodies still executing = %d", delivered, inFlight);
        task.awaitQuiescence(5000);
        System.out.printf("  info: max bodies at once = %d; attempt 1 ran %s..%s ms (cancel at ~300 ms)%n",
                task.maxBodiesInFlight.get(), task.enterAt.get(1), task.exitAt.get(1));
        record("E info: interrupt-responsive body", task.maxBodiesInFlight.get() > 1 || inFlight > 0);
    }

    public static void main(String[] args) throws Exception {
        int rounds = args.length > 0 ? Integer.parseInt(args[0]) : 3;
        System.out.println("java.version=" + System.getProperty("java.version") + ", rounds=" + rounds);
        for (int i = 1; i <= rounds; i++) {
            System.out.println();
            System.out.println("############################## round " + i + " ##############################");
            scenarioA();
            scenarioB();
            scenarioC(false);
            scenarioC(true);
            scenarioF();
            scenarioG();
            scenarioG0();
            controlD();
            controlE();
        }
        System.out.println();
        System.out.println("=============================== SUMMARY ===============================");
        boolean reproduced = true;
        for (Map.Entry<String, int[]> e : tally.entrySet()) {
            System.out.printf("  %-52s anomaly in %d/%d runs%n", e.getKey(), e.getValue()[0], e.getValue()[1]);
            String k = e.getKey();
            if (k.startsWith("A ") || k.startsWith("B ") || k.startsWith("C ") || k.startsWith("C2 ") || k.startsWith("F ")
                    || k.startsWith("G ") || k.startsWith("G0 ")) {
                reproduced &= e.getValue()[0] == e.getValue()[1];
            } else if (k.startsWith("D ")) {
                reproduced &= e.getValue()[0] == 0;
            }
        }
        System.out.println(reproduced
                ? "RESULT: BUG REPRODUCED - attempts of one Retryer.call() overlap, and attempts keep running (their outcomes dropped) after call() returned/threw, "
                        + "also with a bounded/single-thread limiter executor (S4); noTimeLimit control is clean"
                : "RESULT: NOT REPRODUCED in every round (see tally)");
        System.out.flush();
        // fixedTimeLimit(d, u) creates non-daemon cached-pool threads that idle for 60 s; exit explicitly.
        System.exit(reproduced ? 0 : 1);
    }
}
JAVA_EOF

echo "compiling guava-retrying (unmodified) and the repro with --release 8 ..."
"$JAVAC_BIN" --release 8 -Xlint:-options -nowarn -cp "$GUAVA_JAR:$JSR305_JAR" -d "$WORK/lib" \
  $(find "$MC1_SRC/src/main/java" -name '*.java') >"$WORK/javac.log" 2>&1 || { cat "$WORK/javac.log"; echo "SETUP ERROR: library compile failed"; exit 2; }
"$JAVAC_BIN" --release 8 -Xlint:-options -cp "$WORK/lib:$GUAVA_JAR:$JSR305_JAR" -d "$WORK/test" "$WORK/MC1Repro.java" \
  >>"$WORK/javac.log" 2>&1 || { cat "$WORK/javac.log"; echo "SETUP ERROR: repro compile failed"; exit 2; }

set +e
"$JAVA_BIN" -cp "$WORK/test:$WORK/lib:$GUAVA_JAR:$JSR305_JAR" MC1Repro "$MC1_ROUNDS"
rc=$?
set -e
echo "exit code: $rc"
exit $rc
