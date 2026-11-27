#!/usr/bin/env bash
# CR-D-17 reproduction — escalation Level 0 (pure black-box, public API only, no source change,
# no fail points, no timing help).
#
# Claim: WaitStrategies.exceptionWait (WaitStrategies.java:211-216, 386-394) returns the user
# function's value unclamped. A natural "sleep until the server-supplied retry time" function
# (retryAtMillis - now) is negative once that time has passed (clock skew, latency, the 1-second
# resolution of HTTP-date). Retryer.call (Retryer.java:176-182) hands it to the default
# ThreadSleepStrategy (BlockStrategies.java:46); Thread.sleep throws IllegalArgumentException,
# which escapes call() — an outcome call()'s Javadoc does not admit (only ExecutionException /
# RetryException) — after ONE attempt although the stop strategy allows more. Inside join() the
# negative value shortens the other strategies' waits, or makes the total negative (same IAE).
#
# The library is compiled from the UNMODIFIED worktree source with the known-good recipe
# (Guava 22.0, jsr305 2.0.2, --release 8). Exit code 0 = bug reproduced and all controls behaved.
set -euo pipefail

SRC_ROOT=${SRC_ROOT:-/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-17/worktree}
M2=${M2:-$HOME/.m2/repository}
GUAVA=$M2/com/google/guava/guava/22.0/guava-22.0.jar
JSR305=$M2/com/google/code/findbugs/jsr305/2.0.2/jsr305-2.0.2.jar
for f in "$GUAVA" "$JSR305" "$SRC_ROOT/src/main/java/com/github/rholder/retry/WaitStrategies.java"; do
  [ -f "$f" ] || { echo "missing: $f" >&2; exit 2; }
done

WORK=$(mktemp -d /tmp/crd17-repro.XXXXXX)
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/lib" "$WORK/drv-src" "$WORK/drv"

echo "== source: $SRC_ROOT @ $(git -C "$SRC_ROOT" rev-parse --short HEAD 2>/dev/null || echo '?') ($(git -C "$SRC_ROOT" describe --tags --always 2>/dev/null || echo '?')); dirty files: $(git -C "$SRC_ROOT" status --porcelain 2>/dev/null | wc -l)"
echo "== java: $(java -version 2>&1 | head -1)"
javac --release 8 -nowarn -Xlint:-options -d "$WORK/lib" -cp "$GUAVA:$JSR305" \
  $(find "$SRC_ROOT/src/main/java" -name '*.java')

cat > "$WORK/drv-src/ReproCRD17.java" <<'JAVA'
import com.github.rholder.retry.*;
import com.google.common.base.Function;
import com.sun.net.httpserver.HttpServer;

import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.time.ZoneOffset;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicLong;
import java.util.concurrent.atomic.AtomicReference;

public class ReproCRD17 {
    static final int MAX_ATTEMPTS = 5;

    /** What a client throws for a 429/503 response that carries an absolute "retry at" time. */
    static final class RetryAfterException extends RuntimeException {
        final long retryAtMillis;
        RetryAfterException(long retryAtMillis) {
            super("server: retry at " + Instant.ofEpochMilli(retryAtMillis));
            this.retryAtMillis = retryAtMillis;
        }
    }

    /** The natural exceptionWait function: sleep until the server-supplied retry time. */
    static final AtomicLong fnReturned = new AtomicLong(Long.MIN_VALUE);
    static final Function<RetryAfterException, Long> UNTIL_RETRY_AT = new Function<RetryAfterException, Long>() {
        @Override public Long apply(RetryAfterException e) {
            long v = e.retryAtMillis - System.currentTimeMillis();
            fnReturned.set(v);
            return v;
        }
    };

    static WaitStrategy untilRetryAt() {
        return WaitStrategies.exceptionWait(RetryAfterException.class, UNTIL_RETRY_AT);
    }

    /** Plain builder usage; block strategy left at its default (BlockStrategies.threadSleepStrategy()). */
    static Retryer<String> retryer(WaitStrategy ws, RetryListener... listeners) {
        RetryerBuilder<String> b = RetryerBuilder.<String>newBuilder()
                .retryIfExceptionOfType(RetryAfterException.class)
                .withWaitStrategy(ws)
                .withStopStrategy(StopStrategies.stopAfterAttempt(MAX_ATTEMPTS));
        for (RetryListener l : listeners) b.withRetryListener(l);
        return b.build();
    }

    /** Invocation 1 fails with "retry at <client now + offset>" (offset < 0: that time has already passed); invocation 2 succeeds. */
    static final class Flaky implements Callable<String> {
        final long retryAtOffsetMillis;
        final AtomicInteger invocations = new AtomicInteger();
        volatile long failNanos, secondNanos;
        Flaky(long retryAtOffsetMillis) { this.retryAtOffsetMillis = retryAtOffsetMillis; }
        @Override public String call() {
            int n = invocations.incrementAndGet();
            if (n == 1) {
                failNanos = System.nanoTime();
                throw new RetryAfterException(System.currentTimeMillis() + retryAtOffsetMillis);
            }
            if (n == 2) secondNanos = System.nanoTime();
            return "ok";
        }
        long gapMillis() { return TimeUnit.NANOSECONDS.toMillis(secondNanos - failNanos); }
    }

    /** Fails n times with a RetryAfterException, then succeeds. */
    static final class FailNThenOk implements Callable<String> {
        final int n; final AtomicInteger invocations = new AtomicInteger();
        FailNThenOk(int n) { this.n = n; }
        @Override public String call() {
            if (invocations.incrementAndGet() <= n) throw new RetryAfterException(System.currentTimeMillis());
            return "ok";
        }
    }

    static int bugsTriggered = 0, controlsFailed = 0;

    static void bug(String msg) { bugsTriggered++; System.out.println("    >>> BUG TRIGGERED: " + msg); }
    static void controlOk(String msg) { System.out.println("    control OK: " + msg); }
    static void controlBad(String msg) { controlsFailed++; System.out.println("    !!! CONTROL FAILED: " + msg); }

    static String describe(Throwable t) {
        StringBuilder sb = new StringBuilder(t.getClass().getName() + ": " + t.getMessage());
        int shown = 0;
        for (StackTraceElement f : t.getStackTrace()) {
            sb.append("\n        at ").append(f);
            if (++shown == 4) break;
        }
        return sb.toString();
    }

    /** Runs retryer.call(callable) on the current thread and reports the outcome. */
    static Object outcome(Retryer<String> r, Callable<String> c) {
        try {
            return r.call(c);
        } catch (Throwable t) {
            return t;
        }
    }

    static boolean isSleepIae(Object o) {
        if (!(o instanceof IllegalArgumentException)) return false;
        StackTraceElement[] st = ((Throwable) o).getStackTrace();
        boolean sleep = false, block = false, call = false;
        for (StackTraceElement f : st) {
            if (f.getClassName().equals("java.lang.Thread") && f.getMethodName().equals("sleep")) sleep = true;
            if (f.getClassName().equals("com.github.rholder.retry.BlockStrategies$ThreadSleepStrategy") && f.getMethodName().equals("block")) block = true;
            if (f.getClassName().equals("com.github.rholder.retry.Retryer") && f.getMethodName().equals("call")) call = true;
        }
        return sleep && block && call;
    }

    public static void main(String[] args) throws Exception {
        // ---------------------------------------------------------------------------------------------
        System.out.println("[1] exceptionWait(retryAt - now); server retry time already 250 ms in the past; stopAfterAttempt(" + MAX_ATTEMPTS + ")");
        System.out.println("    expected (call() Javadoc + the clamp-to-0 convention of the other built-ins): retry at once, return \"ok\" on invocation 2");
        {
            WaitStrategy ws = untilRetryAt();
            final AtomicReference<Attempt<?>> lastAttempt = new AtomicReference<Attempt<?>>();
            RetryListener observer = new RetryListener() {   // passive: records the Attempt that Retryer built
                @Override public <V> void onRetry(Attempt<V> attempt) { lastAttempt.set(attempt); }
            };
            Flaky c = new Flaky(-250);
            long t0 = System.nanoTime();
            Object o = outcome(retryer(ws, observer), c);
            long ms = TimeUnit.NANOSECONDS.toMillis(System.nanoTime() - t0);
            System.out.println("    callable invocations = " + c.invocations.get() + " (stop strategy allows " + MAX_ATTEMPTS + "), call() took " + ms + " ms");
            System.out.println("    user function returned " + fnReturned.get() + " ms; ExceptionWaitStrategy.computeSleepTime(attempt#"
                    + lastAttempt.get().getAttemptNumber() + ") now returns " + ws.computeSleepTime(lastAttempt.get()) + " (passed through, no clamp)");
            System.out.println("    call() outcome: " + (o instanceof Throwable ? describe((Throwable) o) : "returned " + o));
            if (isSleepIae(o) && c.invocations.get() == 1)
                bug("undocumented IllegalArgumentException escaped Retryer.call after 1 of " + MAX_ATTEMPTS + " permitted attempts");
        }

        System.out.println("[1-determinism] same scenario, 50 fresh calls");
        {
            int iae = 0, ok = 0, other = 0;
            for (int i = 0; i < 50; i++) {
                Object o = outcome(retryer(untilRetryAt()), new Flaky(-250));
                if (isSleepIae(o)) iae++; else if ("ok".equals(o)) ok++; else other++;
            }
            System.out.println("    IllegalArgumentException(Thread.sleep) = " + iae + "/50, returned ok = " + ok + ", other = " + other);
            if (iae == 50) bug("deterministic: 50/50 calls aborted with IllegalArgumentException");
        }

        System.out.println("[1-control] identical configuration, server retry time 300 ms in the future");
        {
            Flaky c = new Flaky(300);
            Object o = outcome(retryer(untilRetryAt()), c);
            if ("ok".equals(o) && c.invocations.get() == 2 && c.gapMillis() >= 250)
                controlOk("returned \"ok\" on invocation 2 after waiting " + c.gapMillis() + " ms (function returned " + fnReturned.get() + ")");
            else controlBad("outcome=" + o + " invocations=" + c.invocations.get() + " gap=" + c.gapMillis());
        }

        // ---------------------------------------------------------------------------------------------
        System.out.println("[2] library convention on the SAME Retryer/default-block path: incrementingWait(0 ms, increment -250 ms) also computes negative sleeps");
        {
            FailNThenOk c = new FailNThenOk(3);
            Object o = outcome(retryer(WaitStrategies.incrementingWait(0, TimeUnit.MILLISECONDS, -250, TimeUnit.MILLISECONDS)), c);
            // attempt 2 -> 0 + (-250)*1 = -250, attempt 3 -> -500; IncrementingWaitStrategy clamps both to 0 (WaitStrategies.java:283)
            if ("ok".equals(o) && c.invocations.get() == 4)
                controlOk("negative computed sleeps clamped to 0 by the built-in; call() returned \"ok\" on invocation 4");
            else controlBad("outcome=" + (o instanceof Throwable ? describe((Throwable) o) : o) + " invocations=" + c.invocations.get());
        }

        // ---------------------------------------------------------------------------------------------
        System.out.println("[3] consumer written exactly like README.md:44-50 (catch RetryException / catch ExecutionException), on its own thread");
        {
            final Retryer<String> r = retryer(untilRetryAt());
            final Flaky c = new Flaky(-250);
            final AtomicReference<String> handledBy = new AtomicReference<String>("<nothing>");
            final AtomicReference<Throwable> uncaught = new AtomicReference<Throwable>();
            Thread t = new Thread(new Runnable() {
                @Override public void run() {
                    try {
                        String v = r.call(c);
                        handledBy.set("normal return: " + v);
                    } catch (RetryException e) {
                        handledBy.set("RetryException handler");
                    } catch (ExecutionException e) {
                        handledBy.set("ExecutionException handler");
                    }
                }
            }, "readme-consumer");
            t.setUncaughtExceptionHandler(new Thread.UncaughtExceptionHandler() {
                @Override public void uncaughtException(Thread th, Throwable ex) { uncaught.set(ex); }
            });
            t.start();
            t.join(10000);
            System.out.println("    handled by: " + handledBy.get() + "; thread terminated by uncaught: "
                    + (uncaught.get() == null ? "none" : uncaught.get().getClass().getName() + ": " + uncaught.get().getMessage()));
            if (isSleepIae(uncaught.get()) && "<nothing>".equals(handledBy.get()))
                bug("neither documented handler ran; the consumer thread died with an uncaught IllegalArgumentException");
        }

        // ---------------------------------------------------------------------------------------------
        System.out.println("[4] Retryer.wrap(callable) submitted to an ExecutorService (RetryerCallable.call -> Retryer.call)");
        {
            ExecutorService ex = Executors.newSingleThreadExecutor();
            try {
                Flaky c = new Flaky(-250);
                Future<String> f = ex.submit(retryer(untilRetryAt()).wrap(c));
                Object o;
                try { o = f.get(10, TimeUnit.SECONDS); } catch (ExecutionException e) { o = e.getCause(); }
                System.out.println("    future outcome: " + (o instanceof Throwable ? "ExecutionException caused by " + describe((Throwable) o) : "value " + o)
                        + "; invocations = " + c.invocations.get());
                if (isSleepIae(o)) bug("Future failed with IllegalArgumentException instead of \"ok\" / RetryException");
            } finally { ex.shutdownNow(); }
        }

        // ---------------------------------------------------------------------------------------------
        System.out.println("[5] join(fixedWait(400 ms), exceptionWait(retryAt - now)) — Javadoc: wait is the total of all wait times");
        {
            Flaky c = new Flaky(-250);
            Object o = outcome(retryer(WaitStrategies.join(WaitStrategies.fixedWait(400, TimeUnit.MILLISECONDS), untilRetryAt())), c);
            System.out.println("    retry time 250 ms in the past: exceptionWait part = " + fnReturned.get() + " ms; outcome = " + o
                    + "; measured wait between attempts = " + c.gapMillis() + " ms (fixedWait alone is 400 ms; Thread.sleep never undershoots)");
            if ("ok".equals(o) && c.gapMillis() < 400)
                bug("the negative component cut the configured 400 ms fixed wait to " + c.gapMillis() + " ms");
        }
        {
            Flaky c = new Flaky(-600);
            Object o = outcome(retryer(WaitStrategies.join(WaitStrategies.fixedWait(400, TimeUnit.MILLISECONDS), untilRetryAt())), c);
            System.out.println("    retry time 600 ms in the past: exceptionWait part = " + fnReturned.get() + " ms; total ~ " + (400 + fnReturned.get())
                    + " ms; invocations = " + c.invocations.get() + "; outcome = " + (o instanceof Throwable ? describe((Throwable) o) : o));
            if (isSleepIae(o) && c.invocations.get() == 1)
                bug("negative total escaped Retryer.call as IllegalArgumentException");
        }
        {
            Flaky c = new Flaky(100);
            Object o = outcome(retryer(WaitStrategies.join(WaitStrategies.fixedWait(400, TimeUnit.MILLISECONDS), untilRetryAt())), c);
            if ("ok".equals(o) && c.gapMillis() >= 450)
                controlOk("retry time 100 ms ahead: waited " + c.gapMillis() + " ms (~400 + 100), returned \"ok\"");
            else controlBad("outcome=" + o + " gap=" + c.gapMillis());
        }

        // ---------------------------------------------------------------------------------------------
        System.out.println("[6] end-to-end over real HTTP: 503 + 'Retry-After: <HTTP-date>' (RFC 9110 10.2.3), client parses it in the callable");
        for (long serverClockOffset : new long[] {0L, -2000L}) {
            final long offset = serverClockOffset;
            final long aheadMillis = offset == 0L ? 2000L : 1000L;
            final AtomicInteger requests = new AtomicInteger();
            final AtomicReference<String> sentHeader = new AtomicReference<String>();
            HttpServer server = HttpServer.create(new InetSocketAddress(InetAddress.getLoopbackAddress(), 0), 0);
            server.createContext("/api", exchange -> {
                if (requests.incrementAndGet() == 1) {
                    long serverNow = System.currentTimeMillis() + offset;      // this host's clock
                    String date = DateTimeFormatter.RFC_1123_DATE_TIME.format(
                            ZonedDateTime.ofInstant(Instant.ofEpochMilli(serverNow + aheadMillis), ZoneOffset.UTC));
                    sentHeader.set(date);
                    exchange.getResponseHeaders().add("Retry-After", date);
                    exchange.sendResponseHeaders(503, -1);
                } else {
                    byte[] body = "ok".getBytes(StandardCharsets.UTF_8);
                    exchange.sendResponseHeaders(200, body.length);
                    exchange.getResponseBody().write(body);
                }
                exchange.close();
            });
            server.start();
            final String url = "http://127.0.0.1:" + server.getAddress().getPort() + "/api";
            Callable<String> httpCall = () -> {
                HttpURLConnection conn = (HttpURLConnection) new URL(url).openConnection();
                try {
                    int code = conn.getResponseCode();
                    if (code == 503 || code == 429) {
                        String ra = conn.getHeaderField("Retry-After");
                        long retryAt = ra.matches("\\d+")
                                ? System.currentTimeMillis() + Long.parseLong(ra) * 1000L
                                : ZonedDateTime.parse(ra, DateTimeFormatter.RFC_1123_DATE_TIME).toInstant().toEpochMilli();
                        throw new RetryAfterException(retryAt);
                    }
                    try (InputStream in = conn.getInputStream()) { return new String(in.readAllBytes(), StandardCharsets.UTF_8); }
                } finally { conn.disconnect(); }
            };
            Object o;
            try { o = outcome(retryer(untilRetryAt()), httpCall); } finally { server.stop(0); }
            String label = offset == 0L ? "server clock in sync, Retry-After = now+2s" : "server clock 2 s behind the client, Retry-After = server now+1s";
            System.out.println("    " + label + ": header '" + sentHeader.get() + "', function returned " + fnReturned.get()
                    + " ms, HTTP requests = " + requests.get() + ", outcome = " + (o instanceof Throwable ? describe((Throwable) o) : o));
            if (offset == 0L) {
                if ("ok".equals(o) && requests.get() == 2) controlOk("in-sync server: waited, retried, got \"ok\"");
                else controlBad("in-sync HTTP control did not return ok");
            } else if (isSleepIae(o) && requests.get() == 1) {
                bug("skewed-clock server: retry abandoned after 1 request with IllegalArgumentException");
            }
        }

        System.out.println();
        System.out.println("SUMMARY: bug triggers = " + bugsTriggered + "/7, failed controls = " + controlsFailed + "/5");
        boolean reproduced = bugsTriggered == 7 && controlsFailed == 0;
        System.out.println(reproduced ? "RESULT: BUG REPRODUCED (Level 0)" : "RESULT: NOT REPRODUCED / CONTROL FAILURE");
        System.exit(reproduced ? 0 : 1);
    }
}
JAVA

javac -nowarn -d "$WORK/drv" -cp "$WORK/lib:$GUAVA:$JSR305" "$WORK/drv-src/ReproCRD17.java"
echo "== running driver (outer timeout 120 s)"
timeout 120 java -cp "$WORK/drv:$WORK/lib:$GUAVA:$JSR305" ReproCRD17
