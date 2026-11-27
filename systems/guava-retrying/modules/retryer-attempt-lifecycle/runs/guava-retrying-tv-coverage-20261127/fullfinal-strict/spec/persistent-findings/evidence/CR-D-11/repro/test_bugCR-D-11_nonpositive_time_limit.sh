#!/usr/bin/env bash
# CR-D-11 reproduction: AttemptTimeLimiters.fixedTimeLimit accepts a zero or negative duration;
# every attempt then fails inside Guava's SimpleTimeLimiter.callWithTimeout with
# IllegalArgumentException("timeout must be positive: d") BEFORE the callable is submitted,
# and Retryer.call (Retryer.java:162-163) records it as the callable's failure.
#
# Escalation level: 0 (pure black box). Only public guava-retrying API calls, no failpoints,
# no sleeps inside library code, no state injection, no source modification. The library is
# compiled unmodified from the confirmation worktree (guava-retrying 2.0.0 source) with
# javac --release 8 against Guava 22.0 + jsr305 2.0.2, as the target guidance prescribes.
#
# Exit status: 0 = bug reproduced on Guava 22.0 and all controls behaved,
#              1 = bug NOT observed (e.g. the factory now rejects non-positive durations),
#              2 = harness problem (build failure, control failure, missing jars).
#
# Optional env: GR_SRC (guava-retrying source root), GUAVA_JAR, JSR305_JAR, SPIN_MS,
#               CROSS_GUAVA=0 to skip the secondary Guava 10.0.1/14.0.1/16.0.1 runs.
# Fix validation (discriminating power): point GR_SRC at a copy whose FixedAttemptTimeLimit
# constructor adds checkArgument(duration > 0, ...); the script then exits 1 (bug not observed).
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
GR_SRC="${GR_SRC:-$OUT_DIR/confirmation/CR-D-11/worktree}"
M2="${M2:-$HOME/.m2/repository}"
GUAVA_JAR="${GUAVA_JAR:-$M2/com/google/guava/guava/22.0/guava-22.0.jar}"
JSR305_JAR="${JSR305_JAR:-$M2/com/google/code/findbugs/jsr305/2.0.2/jsr305-2.0.2.jar}"
SPIN_MS="${SPIN_MS:-3000}"
CROSS_GUAVA="${CROSS_GUAVA:-1}"

for f in "$GUAVA_JAR" "$JSR305_JAR" "$GR_SRC/src/main/java/com/github/rholder/retry/AttemptTimeLimiters.java"; do
  [ -f "$f" ] || { echo "HARNESS: missing $f"; exit 2; }
done

WORK="$(mktemp -d /tmp/crd11-repro.XXXXXX)"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/lib-22.0" "$WORK/drv-src" "$WORK/drv"

echo "== environment"
echo "java:   $(java -version 2>&1 | head -1)"
echo "javac:  $(javac -version 2>&1)"
echo "source: $GR_SRC  (git HEAD $(git -C "$GR_SRC" rev-parse --short HEAD 2>/dev/null || echo n/a); src diff vs v2.0.0: '$(git -C "$GR_SRC" diff --stat v2.0.0 HEAD -- src 2>/dev/null | tail -1)')"
echo "guava:  $GUAVA_JAR  sha256=$(sha256sum "$GUAVA_JAR" | cut -c1-16)…"
echo "jsr305: $JSR305_JAR"
echo "site:   $(grep -n 'public static <V> AttemptTimeLimiter<V> fixedTimeLimit' "$GR_SRC/src/main/java/com/github/rholder/retry/AttemptTimeLimiters.java" | tr '\n' ' ')"

SRCS=$(find "$GR_SRC/src/main/java" -name '*.java' | sort)
if ! javac --release 8 -nowarn -Xlint:none -d "$WORK/lib-22.0" -cp "$GUAVA_JAR:$JSR305_JAR" $SRCS 2>"$WORK/javac-lib.err"; then
  echo "HARNESS: library build failed"; cat "$WORK/javac-lib.err"; exit 2
fi

cat > "$WORK/drv-src/CrD11Repro.java" <<'JAVA'
import com.github.rholder.retry.Attempt;
import com.github.rholder.retry.AttemptTimeLimiter;
import com.github.rholder.retry.AttemptTimeLimiters;
import com.github.rholder.retry.RetryException;
import com.github.rholder.retry.RetryListener;
import com.github.rholder.retry.Retryer;
import com.github.rholder.retry.RetryerBuilder;
import com.github.rholder.retry.StopStrategies;
import com.github.rholder.retry.WaitStrategies;

import java.lang.management.ManagementFactory;
import java.lang.management.ThreadMXBean;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.ThreadFactory;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicLong;
import java.util.concurrent.atomic.AtomicReference;

/** Plays the role of an application using guava-retrying 2.0.0 through its public API only. */
public class CrD11Repro {

    static int bugChecks, bugHits, ctrlChecks, ctrlFails;
    static final long SPIN_MS = Long.getLong("crd11.spinMs", 3000L);

    static void bug(boolean observed, String what) {
        bugChecks++;
        if (observed) bugHits++;
        System.out.println((observed ? "  [BUG    ] " : "  [NO-BUG ] ") + what);
    }

    static void ctrl(boolean ok, String what) {
        ctrlChecks++;
        if (!ok) ctrlFails++;
        System.out.println((ok ? "  [CTRL ok] " : "  [CTRL FAIL] ") + what);
    }

    static final ThreadFactory DAEMON = new ThreadFactory() {
        final AtomicInteger n = new AtomicInteger();
        @Override public Thread newThread(Runnable r) {
            Thread t = new Thread(r, "user-pool-" + n.incrementAndGet());
            t.setDaemon(true);
            return t;
        }
    };

    /** The user's operation. Counts how many times it really ran. */
    static final class Op implements Callable<String> {
        final AtomicInteger invocations = new AtomicInteger();
        final int failFirst;
        final long sleepMs;
        Op() { this(0, 0); }
        Op(int failFirst, long sleepMs) { this.failFirst = failFirst; this.sleepMs = sleepMs; }
        @Override public String call() throws Exception {
            int n = invocations.incrementAndGet();
            if (sleepMs > 0) Thread.sleep(sleepMs);
            if (n <= failFirst) throw new IllegalStateException("transient failure #" + n + " thrown by the callable");
            return "ok";
        }
    }

    /** A user RetryListener (e.g. logging / metrics). */
    static final class Listener implements RetryListener {
        final AtomicLong attempts = new AtomicLong();
        final AtomicLong failed = new AtomicLong();
        volatile Attempt<?> last;
        @Override public <V> void onRetry(Attempt<V> attempt) {
            attempts.incrementAndGet();
            if (attempt.hasException()) failed.incrementAndGet();
            last = attempt;
        }
    }

    /** One per-attempt time limiter built through the public factory, plus the user executor (3-arg form). */
    static final class Lim {
        final AttemptTimeLimiter<String> limiter;
        final ThreadPoolExecutor exec; // null for the 2-arg factory
        final String desc;
        Lim(long d, TimeUnit u, boolean withExecutor) {
            if (withExecutor) {
                exec = new ThreadPoolExecutor(1, 1, 0L, TimeUnit.MILLISECONDS, new LinkedBlockingQueue<Runnable>(), DAEMON);
                limiter = AttemptTimeLimiters.<String>fixedTimeLimit(d, u, exec);
                desc = "fixedTimeLimit(" + d + ", " + u + ", userExecutor)";
            } else {
                exec = null;
                limiter = AttemptTimeLimiters.<String>fixedTimeLimit(d, u);
                desc = "fixedTimeLimit(" + d + ", " + u + ")";
            }
        }
        String submitted() { return exec == null ? "n/a" : String.valueOf(exec.getTaskCount()); }
    }

    static String frames(Throwable t, int n) {
        StringBuilder sb = new StringBuilder();
        StackTraceElement[] st = t.getStackTrace();
        for (int i = 0; i < Math.min(n, st.length); i++) sb.append("\n        at ").append(st[i]);
        return sb.toString();
    }

    static boolean thrownByLimiterNotCallable(Throwable t) {
        boolean limiter = false, callable = false;
        for (StackTraceElement e : t.getStackTrace()) {
            if (e.getClassName().endsWith("SimpleTimeLimiter")) limiter = true;
            if (e.getClassName().startsWith("CrD11Repro$Op")) callable = true;
        }
        return limiter && !callable;
    }

    static boolean isIAE(Throwable t) {
        return t instanceof IllegalArgumentException && String.valueOf(t.getMessage()).startsWith("timeout must be positive");
    }

    interface Thrower { Object run() throws Exception; }

    static void expectEagerIAE(String expr, Thrower body) {
        try {
            body.run();
            ctrl(false, expr + " was accepted (expected eager IllegalArgumentException)");
        } catch (IllegalArgumentException e) {
            ctrl(true, expr + " -> IllegalArgumentException at the factory call (eager validation): " + e.getMessage());
        } catch (Exception e) {
            ctrl(false, expr + " -> unexpected " + e);
        }
    }

    public static void main(String[] args) throws Exception {
        System.out.println("== C0 control: other parameterized built-in factories reject bad values eagerly");
        expectEagerIAE("WaitStrategies.fixedWait(-1, SECONDS)", new Thrower() { public Object run() { return WaitStrategies.fixedWait(-1, TimeUnit.SECONDS); } });
        expectEagerIAE("WaitStrategies.randomWait(-1, SECONDS)", new Thrower() { public Object run() { return WaitStrategies.randomWait(-1, TimeUnit.SECONDS); } });
        expectEagerIAE("StopStrategies.stopAfterAttempt(0)", new Thrower() { public Object run() { return StopStrategies.stopAfterAttempt(0); } });
        expectEagerIAE("StopStrategies.stopAfterDelay(-1, SECONDS)", new Thrower() { public Object run() { return StopStrategies.stopAfterDelay(-1, TimeUnit.SECONDS); } });

        System.out.println("== C1 control: positive limit, default predicate -> callable runs once, call() returns");
        for (boolean withExec : new boolean[]{false, true}) {
            Lim lim = new Lim(1, TimeUnit.SECONDS, withExec);
            Op op = new Op();
            Retryer<String> r = RetryerBuilder.<String>newBuilder().withAttemptTimeLimiter(lim.limiter).build();
            String v = r.call(op);
            ctrl("ok".equals(v) && op.invocations.get() == 1,
                 lim.desc + ": call() returned '" + v + "', callable invocations=" + op.invocations.get() + ", tasks submitted to user executor=" + lim.submitted());
        }

        System.out.println("== B1: fixedTimeLimit with a zero / negative duration is accepted at construction and build()");
        for (long d : new long[]{0L, -1L}) {
            for (boolean withExec : new boolean[]{false, true}) {
                try {
                    Lim lim = new Lim(d, TimeUnit.SECONDS, withExec);
                    RetryerBuilder.<String>newBuilder().withAttemptTimeLimiter(lim.limiter).build();
                    bug(true, lim.desc + " + RetryerBuilder.build(): accepted, no exception");
                } catch (IllegalArgumentException e) {
                    bug(false, "fixedTimeLimit(" + d + ", ..., withExecutor=" + withExec + ") rejected eagerly: " + e.getMessage());
                }
            }
        }
        if (bugHits != bugChecks) {
            System.out.println("  fixedTimeLimit rejects non-positive durations at the factory call; the remaining scenarios cannot arise.");
            finish();
        }

        System.out.println("== B2: default rejection predicate -> call() throws ExecutionException(IAE) although the callable never ran");
        for (long d : new long[]{0L, -1L}) {
            for (boolean withExec : new boolean[]{false, true}) {
                Lim lim = new Lim(d, TimeUnit.SECONDS, withExec);
                Op op = new Op();
                Retryer<String> r = RetryerBuilder.<String>newBuilder().withAttemptTimeLimiter(lim.limiter).build();
                for (int round = 1; round <= 2; round++) { // same Retryer twice: the state is permanent
                    try {
                        String v = r.call(op);
                        bug(false, lim.desc + " round " + round + ": call() returned '" + v + "', invocations=" + op.invocations.get());
                    } catch (ExecutionException e) {
                        Throwable c = e.getCause();
                        bug(isIAE(c) && thrownByLimiterNotCallable(c) && op.invocations.get() == 0
                                && (lim.exec == null || lim.exec.getTaskCount() == 0),
                            lim.desc + " round " + round + ": ExecutionException(cause=" + c + "), callable invocations="
                                + op.invocations.get() + ", tasks submitted to user executor=" + lim.submitted()
                                + (round == 1 && !withExec && d == 0 ? "; cause thrown at:" + frames(c, 6) : ""));
                    }
                }
            }
        }
        // A user who (as upstream #29 suggests) retries only timeouts: still ExecutionException(IAE), still 0 runs.
        {
            @SuppressWarnings("unchecked")
            Class<? extends Throwable> ute = (Class<? extends Throwable>) Class.forName("com.google.common.util.concurrent.UncheckedTimeoutException");
            Lim lim = new Lim(0, TimeUnit.MILLISECONDS, false);
            Op op = new Op();
            Retryer<String> r = RetryerBuilder.<String>newBuilder().retryIfExceptionOfType(ute)
                    .withStopStrategy(StopStrategies.stopAfterAttempt(3)).withAttemptTimeLimiter(lim.limiter).build();
            try {
                r.call(op);
                bug(false, lim.desc + " + retryIfExceptionOfType(UncheckedTimeoutException): returned");
            } catch (ExecutionException e) {
                bug(isIAE(e.getCause()) && op.invocations.get() == 0,
                    lim.desc + " + retryIfExceptionOfType(UncheckedTimeoutException): ExecutionException(cause=" + e.getCause() + "), invocations=" + op.invocations.get());
            }
        }

        System.out.println("== B3: retry predicate + stopAfterAttempt(5) + fixedWait(20ms) -> RetryException('after 5 attempts') with 0 runs");
        Object[][] cfgs = { {0L, false, "retryIfException"}, {-1L, true, "retryIfException"}, {0L, true, "retryIfRuntimeException"} };
        for (Object[] cfg : cfgs) {
            long d = (Long) cfg[0];
            boolean withExec = (Boolean) cfg[1];
            String pred = (String) cfg[2];
            Lim lim = new Lim(d, TimeUnit.SECONDS, withExec);
            Op op = new Op();
            Listener l = new Listener();
            RetryerBuilder<String> b = RetryerBuilder.<String>newBuilder();
            b = "retryIfException".equals(pred) ? b.retryIfException() : b.retryIfRuntimeException();
            Retryer<String> r = b.withStopStrategy(StopStrategies.stopAfterAttempt(5))
                    .withWaitStrategy(WaitStrategies.fixedWait(20, TimeUnit.MILLISECONDS))
                    .withRetryListener(l).withAttemptTimeLimiter(lim.limiter).build();
            long t0 = System.nanoTime();
            try {
                r.call(op);
                bug(false, lim.desc + " + " + pred + ": returned normally");
            } catch (RetryException e) {
                long ms = TimeUnit.NANOSECONDS.toMillis(System.nanoTime() - t0);
                Throwable last = e.getLastFailedAttempt().getExceptionCause();
                bug(e.getNumberOfFailedAttempts() == 5 && isIAE(last) && isIAE(e.getCause()) && l.attempts.get() == 5
                        && l.failed.get() == 5 && op.invocations.get() == 0,
                    lim.desc + " + " + pred + ": RetryException(\"" + e.getMessage() + "\"), getNumberOfFailedAttempts()="
                        + e.getNumberOfFailedAttempts() + ", lastFailedAttempt.getExceptionCause()=" + last
                        + ", listener saw " + l.attempts.get() + " failed attempts, waited ~" + ms + " ms between them,"
                        + " callable invocations=" + op.invocations.get() + ", tasks submitted to user executor=" + lim.submitted());
            }
        }

        System.out.println("== C4 control: retryIfException + builder defaults (neverStop, noWait), positive limit, callable fails twice then succeeds");
        {
            Lim lim = new Lim(1, TimeUnit.SECONDS, false);
            Op op = new Op(2, 0);
            Listener l = new Listener();
            Retryer<String> r = RetryerBuilder.<String>newBuilder().retryIfException().withRetryListener(l).withAttemptTimeLimiter(lim.limiter).build();
            String v = r.call(op);
            ctrl("ok".equals(v) && op.invocations.get() == 3 && l.attempts.get() == 3,
                 lim.desc + ": call() returned '" + v + "' after " + l.attempts.get() + " attempts, callable invocations=" + op.invocations.get());
        }

        ThreadMXBean mx = ManagementFactory.getThreadMXBean();
        boolean cpuSupported = mx.isThreadCpuTimeSupported();
        if (cpuSupported && !mx.isThreadCpuTimeEnabled()) mx.setThreadCpuTimeEnabled(true);

        System.out.println("== B4: same configuration with fixedTimeLimit(0, MILLISECONDS) -> call() never returns, busy-loops, callable never runs");
        spin("retryIfException() + defaults neverStop()/noWait()",
             RetryerBuilder.<String>newBuilder().retryIfException(), new Lim(0, TimeUnit.MILLISECONDS, false), mx, cpuSupported, true);

        System.out.println("== B4b: README 'retry forever with exponential backoff' config + fixedTimeLimit(0, MILLISECONDS, userExecutor)");
        spin("README: retryIfExceptionOfType(IOException).retryIfRuntimeException().exponentialWait(100, 5, MINUTES).neverStop()",
             RetryerBuilder.<String>newBuilder().retryIfExceptionOfType(java.io.IOException.class).retryIfRuntimeException()
                 .withWaitStrategy(WaitStrategies.exponentialWait(100, 5, TimeUnit.MINUTES)).withStopStrategy(StopStrategies.neverStop()),
             new Lim(0, TimeUnit.MILLISECONDS, true), mx, cpuSupported, false);

        System.out.println("== B5: Retryer.wrap() submitted to an executor (retryIfRuntimeException, neverStop, noWait, fixedTimeLimit(-1, SECONDS))");
        {
            Lim lim = new Lim(-1, TimeUnit.SECONDS, false);
            Op op = new Op();
            Listener l = new Listener();
            Retryer<String> r = RetryerBuilder.<String>newBuilder().retryIfRuntimeException().withRetryListener(l).withAttemptTimeLimiter(lim.limiter).build();
            ExecutorService pool = Executors.newSingleThreadExecutor(DAEMON);
            Future<String> f = pool.submit(r.wrap(op));
            boolean timedOut = false;
            try { f.get(Math.min(SPIN_MS, 2000L), TimeUnit.MILLISECONDS); } catch (TimeoutException te) { timedOut = true; } catch (ExecutionException ee) { /* ended */ }
            long attempts = l.attempts.get();
            bug(timedOut && !f.isDone() && attempts > 1000 && op.invocations.get() == 0,
                lim.desc + ": Future of wrap(callable) not done after " + Math.min(SPIN_MS, 2000L) + " ms; pool thread made " + attempts
                    + " attempts; callable invocations=" + op.invocations.get());
            pool.shutdownNow();
            try { f.get(5, TimeUnit.SECONDS); } catch (ExecutionException ee) {
                System.out.println("        (cleanup) after shutdownNow(): Future failed with " + ee.getCause());
            } catch (TimeoutException te) {
                System.out.println("        (cleanup) pool thread still spinning 5 s after shutdownNow()");
            }
        }

        System.out.println("== C5 contrast: a positive but far-too-small limit is a real timeout AFTER submission (not an argument error)");
        {
            Lim lim = new Lim(1, TimeUnit.NANOSECONDS, true);
            Op op = new Op(0, 300);
            Retryer<String> r = RetryerBuilder.<String>newBuilder().withAttemptTimeLimiter(lim.limiter).build();
            try {
                r.call(op);
                ctrl(false, lim.desc + ": returned");
            } catch (ExecutionException e) {
                ctrl(e.getCause().getClass().getName().endsWith("UncheckedTimeoutException") && lim.exec.getTaskCount() == 1,
                     lim.desc + ": ExecutionException(cause=" + e.getCause().getClass().getName() + "), tasks submitted to user executor=" + lim.submitted());
            }
        }

        finish();
    }

    static void finish() {
        System.out.println();
        System.out.println("SUMMARY: bug observations " + bugHits + "/" + bugChecks + ", controls ok " + (ctrlChecks - ctrlFails) + "/" + ctrlChecks);
        int code;
        if (ctrlFails > 0) { System.out.println("RESULT: HARNESS/CONTROL PROBLEM"); code = 2; }
        else if (bugHits == bugChecks && bugChecks > 0) { System.out.println("RESULT: BUG REPRODUCED"); code = 0; }
        else { System.out.println("RESULT: BUG NOT (fully) REPRODUCED"); code = 1; }
        System.out.flush();
        System.exit(code); // the 2-arg factory's internal cached pool has non-daemon threads (upstream #92)
    }

    static void spin(String cfg, RetryerBuilder<String> b, Lim lim, ThreadMXBean mx, boolean cpuSupported, boolean expectBusy) throws Exception {
        final Op op = new Op();
        final Listener l = new Listener();
        final Retryer<String> r = b.withRetryListener(l).withAttemptTimeLimiter(lim.limiter).build();
        final AtomicReference<Object> outcome = new AtomicReference<Object>();
        Thread caller = new Thread(new Runnable() {
            @Override public void run() {
                try { outcome.set("returned " + r.call(op)); } catch (Throwable t) { outcome.set(t); }
            }
        }, "app-caller");
        caller.setDaemon(true);
        long w0 = System.nanoTime();
        caller.start();
        caller.join(SPIN_MS);
        long wallMs = TimeUnit.NANOSECONDS.toMillis(System.nanoTime() - w0);
        boolean alive = caller.isAlive();
        long cpuMs = cpuSupported && alive ? TimeUnit.NANOSECONDS.toMillis(mx.getThreadCpuTime(caller.getId())) : -1;
        long attempts = l.attempts.get();
        Attempt<?> last = l.last;
        String lastCause = last == null ? "none" : String.valueOf(last.getExceptionCause());
        boolean observed = alive && outcome.get() == null && op.invocations.get() == 0 && attempts >= (expectBusy ? 1000 : 3)
                && last != null && isIAE(last.getExceptionCause());
        bug(observed, lim.desc + " + " + cfg + ": after " + wallMs + " ms call() has not returned (caller alive=" + alive
                + "), attempts so far=" + attempts + ", last attempt cause=" + lastCause + ", callable invocations=" + op.invocations.get()
                + ", tasks submitted to user executor=" + lim.submitted()
                + (cpuMs >= 0 ? ", caller CPU time=" + cpuMs + " ms (" + (100 * cpuMs / Math.max(1, wallMs)) + "% of wall)" : ""));
        // Nothing in the library ever ends this loop; the application has to interrupt its own thread.
        caller.interrupt();
        caller.join(10000);
        Object o = outcome.get();
        System.out.println("        (cleanup) after interrupting the caller: alive=" + caller.isAlive() + ", call() ended with "
                + (o instanceof Throwable ? o.toString() : String.valueOf(o)));
    }
}
JAVA

if ! javac --release 8 -nowarn -Xlint:none -d "$WORK/drv" -cp "$WORK/lib-22.0:$GUAVA_JAR:$JSR305_JAR" "$WORK/drv-src/CrD11Repro.java" 2>"$WORK/javac-drv.err"; then
  echo "HARNESS: driver build failed"; cat "$WORK/javac-drv.err"; exit 2
fi

echo
echo "################ PRIMARY RUN: guava-retrying 2.0.0 source + Guava 22.0 ################"
timeout 120 java -Dcrd11.spinMs="$SPIN_MS" -cp "$WORK/drv:$WORK/lib-22.0:$GUAVA_JAR:$JSR305_JAR" CrD11Repro
PRIMARY=$?
echo "primary exit status: $PRIMARY"

if [ "$CROSS_GUAVA" = "1" ]; then
  # Secondary: the declared dependency range is [10.+,). Every Guava release before 23 (23 removed
  # the APIs this library calls) is checked here when its jar is cached locally.
  for V in 10.0.1 14.0.1 16.0.1; do
    GJ="$M2/com/google/guava/guava/$V/guava-$V.jar"
    echo
    echo "################ SECONDARY RUN: library rebuilt against Guava $V ################"
    if [ ! -f "$GJ" ]; then echo "SKIP: $GJ not cached"; continue; fi
    mkdir -p "$WORK/lib-$V"
    if ! javac --release 8 -nowarn -Xlint:none -d "$WORK/lib-$V" -cp "$GJ:$JSR305_JAR" $SRCS 2>"$WORK/javac-$V.err"; then
      echo "SKIP: library does not compile against Guava $V:"; head -5 "$WORK/javac-$V.err"; continue
    fi
    timeout 120 java -Dcrd11.spinMs=1000 -cp "$WORK/drv:$WORK/lib-$V:$GJ:$JSR305_JAR" CrD11Repro | grep -E '^(==|  \[BUG|  \[NO-BUG|  \[CTRL FAIL|SUMMARY|RESULT)'
    echo "Guava $V exit status: ${PIPESTATUS[0]}"
  done
fi

exit "$PRIMARY"
