#!/usr/bin/env bash
# MC-12 reproduction: guava-retrying 2.0.0, known upstream issue #29
# (https://github.com/rholder/guava-retrying/issues/29, open, label "bug").
#
# Claim: with AttemptTimeLimiters.fixedTimeLimit, a per-attempt timeout becomes an ordinary
# ExceptionAttempt (Retryer.java:162-163) that the user's rejection predicate judges. When the
# predicate does not match Guava's UncheckedTimeoutException, the FIRST timeout ends call() with
# ExecutionException(UncheckedTimeoutException) at Retryer.java:170-171. The stop and wait
# strategies are never consulted and no further attempt is made, although the limit is
# documented as per attempt (RetryerBuilder.java:113).
#
# Escalation level: S2 and S3 are Level 0 (public API only). S1 is Level 1: a user-supplied
# ThreadFactory delays worker start so the limit expires before the callable starts, which is
# the exact counterexample interleaving. No library or Guava code is modified. Stop and wait
# strategies are the built-ins wrapped in counting delegates, passed through the public builder.
#
# Scenarios
#   S1  exact CE (spec/output/hunt_s4_shutdown_k29.out): a new worker is assigned the attempt but
#       has not started it; the limit expires; cancel(true) finds no runner; the listener is
#       notified; the predicate accepts; ExecutionException is thrown. The callable never runs.
#   S2  canonical: attempt 1 stalls past the limit and attempt 2 would succeed; config is
#       retryIfExceptionOfType(IOException) + stopAfterAttempt(5) + fixedWait(50 ms).
#   S3  the upstream #29 reporter's configuration, scaled down: no retryIf, with fixedWait and
#       stopAfterDelay.
#   C1  control: S2 config, but attempt 1 throws IOException. It is retried and returns "ok".
#   C2  control: S2 config + retryIfExceptionOfType(UncheckedTimeoutException) (the #29
#       workaround). The timeout is retried and the call returns "ok".
#
# Exit status: 0 = bug triggered in every run (PASS), 1 = not triggered, 2 = control failed or
# build/setup error.
#
# Usage: test_bugMC-12_timeout_ends_call_execution_exception.sh [SRC_DIR]
#   SRC_DIR is a guava-retrying checkout (default: the MC-12 confirmation worktree, then the
#   pipeline source checkout). Env: GUAVA_JAR, JSR305_JAR, JAVA_HOME, RUNS (default 5).
set -euo pipefail

OUT_ROOT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output
DEFAULT_SRC_A=$OUT_ROOT/confirmation/MC-12/worktree
DEFAULT_SRC_B=/home/ubuntu/scratch/guava-retrying-src/guava-retrying
SRC_DIR=${1:-}
if [[ -z "$SRC_DIR" ]]; then
  if [[ -d "$DEFAULT_SRC_A/src/main/java" ]]; then SRC_DIR=$DEFAULT_SRC_A; else SRC_DIR=$DEFAULT_SRC_B; fi
fi
GUAVA_JAR=${GUAVA_JAR:-$HOME/.m2/repository/com/google/guava/guava/22.0/guava-22.0.jar}
JSR305_JAR=${JSR305_JAR:-$HOME/.m2/repository/com/google/code/findbugs/jsr305/2.0.2/jsr305-2.0.2.jar}
RUNS=${RUNS:-5}
if [[ -n "${JAVA_HOME:-}" ]]; then JAVAC=$JAVA_HOME/bin/javac; JAVA=$JAVA_HOME/bin/java; else JAVAC=javac; JAVA=java; fi

for f in "$GUAVA_JAR" "$JSR305_JAR"; do [[ -f "$f" ]] || { echo "SETUP ERROR: missing $f"; exit 2; }; done
[[ -d "$SRC_DIR/src/main/java/com/github/rholder/retry" ]] || { echo "SETUP ERROR: no guava-retrying sources in $SRC_DIR"; exit 2; }

WORK=$(mktemp -d /tmp/mc12-repro.XXXXXX)
trap 'rm -rf "$WORK"' EXIT

echo "== MC-12 provenance"
echo "source dir : $SRC_DIR"
echo "source HEAD: $(git -C "$SRC_DIR" rev-parse HEAD 2>/dev/null || echo unknown)  dirty-files: $(git -C "$SRC_DIR" status --porcelain 2>/dev/null | wc -l)"
echo "guava jar  : $GUAVA_JAR sha1=$(sha1sum "$GUAVA_JAR" | cut -d' ' -f1)"
echo "jsr305 jar : $JSR305_JAR"
echo "java       : $("$JAVA" -version 2>&1 | head -1)"

mkdir -p "$WORK/lib" "$WORK/test"
CP="$GUAVA_JAR:$JSR305_JAR"
find "$SRC_DIR/src/main/java" -name '*.java' > "$WORK/sources.txt"
timeout 300 "$JAVAC" --release 8 -nowarn -Xlint:-options -encoding UTF-8 -cp "$CP" -d "$WORK/lib" @"$WORK/sources.txt" 2>&1 | grep -v -E '^Note:' || true
[[ -f "$WORK/lib/com/github/rholder/retry/Retryer.class" ]] || { echo "BUILD ERROR: library did not compile"; exit 2; }
echo "built      : $(wc -l < "$WORK/sources.txt") unmodified library sources with javac --release 8"

cat > "$WORK/test/MC12Repro.java" <<'JAVA'
import com.github.rholder.retry.Attempt;
import com.github.rholder.retry.AttemptTimeLimiters;
import com.github.rholder.retry.RetryException;
import com.github.rholder.retry.RetryListener;
import com.github.rholder.retry.Retryer;
import com.github.rholder.retry.RetryerBuilder;
import com.github.rholder.retry.StopStrategies;
import com.github.rholder.retry.StopStrategy;
import com.github.rholder.retry.WaitStrategies;
import com.github.rholder.retry.WaitStrategy;
import com.google.common.util.concurrent.UncheckedTimeoutException;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.concurrent.Callable;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Future;
import java.util.concurrent.SynchronousQueue;
import java.util.concurrent.ThreadFactory;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicInteger;

public class MC12Repro {
    static final long T0 = System.nanoTime();
    static volatile boolean verbose = true;

    // Time limits leave wide margins so that scheduling noise cannot flip an outcome.
    static final long LIMIT_MS = 500;        // per-attempt limit for S2, S3, C1, C2
    static final long STALL_MS = 10000;      // attempt 1 stall in S2, S3, C2 (interruptible)
    static final long S1_LIMIT_MS = 300;     // per-attempt limit for S1
    static final long S1_START_DELAY_MS = 1500; // S1 worker start delay (> S1_LIMIT_MS)

    static long now() { return TimeUnit.NANOSECONDS.toMillis(System.nanoTime() - T0); }
    static void log(String s) { if (verbose) System.out.println(String.format("[%6d ms] %s", now(), s)); }

    /** Delegates unchanged to a built-in StopStrategy and counts how often Retryer consults it. */
    static final class CountingStop implements StopStrategy {
        final String name; final StopStrategy delegate; final AtomicInteger calls = new AtomicInteger();
        CountingStop(String name, StopStrategy delegate) { this.name = name; this.delegate = delegate; }
        @Override public boolean shouldStop(Attempt failedAttempt) {
            calls.incrementAndGet();
            boolean r = delegate.shouldStop(failedAttempt);
            log("    " + name + ".shouldStop(attempt #" + failedAttempt.getAttemptNumber() + ") -> " + r);
            return r;
        }
    }

    /** Delegates unchanged to a built-in WaitStrategy and counts how often Retryer consults it. */
    static final class CountingWait implements WaitStrategy {
        final String name; final WaitStrategy delegate; final AtomicInteger calls = new AtomicInteger();
        CountingWait(String name, WaitStrategy delegate) { this.name = name; this.delegate = delegate; }
        @Override public long computeSleepTime(Attempt failedAttempt) {
            calls.incrementAndGet();
            long r = delegate.computeSleepTime(failedAttempt);
            log("    " + name + ".computeSleepTime(attempt #" + failedAttempt.getAttemptNumber() + ") -> " + r + " ms");
            return r;
        }
    }

    static final class RecordingListener implements RetryListener {
        final List<String> attempts = Collections.synchronizedList(new ArrayList<String>());
        @Override public <V> void onRetry(Attempt<V> a) {
            String s = a.hasException()
                    ? "#" + a.getAttemptNumber() + " exception " + a.getExceptionCause().getClass().getSimpleName()
                    : "#" + a.getAttemptNumber() + " result " + a.getResult();
            attempts.add(s);
            log("    listener.onRetry: attempt " + s + " (delaySinceFirstAttempt=" + a.getDelaySinceFirstAttempt() + " ms)");
        }
    }

    /** Invocation 1 stalls (interruptibly) far past the limit; later invocations return "ok" at once. */
    static final class StallOnceThenOk implements Callable<String> {
        final AtomicInteger invocations = new AtomicInteger();
        final AtomicBoolean firstInterrupted = new AtomicBoolean();
        final CountDownLatch firstEnded = new CountDownLatch(1);
        @Override public String call() throws Exception {
            int n = invocations.incrementAndGet();
            if (n == 1) {
                log("    callable invocation #1 on " + Thread.currentThread().getName() + ": stalls " + STALL_MS + " ms (transient stall)");
                try {
                    Thread.sleep(STALL_MS);
                    return "late";
                } catch (InterruptedException e) {
                    firstInterrupted.set(true);
                    log("    callable invocation #1 interrupted by the limiter's future.cancel(true)");
                    throw e;
                } finally {
                    firstEnded.countDown();
                }
            }
            log("    callable invocation #" + n + " returns \"ok\"");
            return "ok";
        }
    }

    /** Invocation 1 throws IOException (an ordinary transient failure); later invocations return "ok". */
    static final class FailOnceThenOk implements Callable<String> {
        final AtomicInteger invocations = new AtomicInteger();
        @Override public String call() throws Exception {
            int n = invocations.incrementAndGet();
            if (n == 1) {
                log("    callable invocation #1 throws IOException(\"transient\")");
                throw new IOException("transient");
            }
            log("    callable invocation #" + n + " returns \"ok\"");
            return "ok";
        }
    }

    static final class AlwaysOk implements Callable<String> {
        final AtomicInteger invocations = new AtomicInteger();
        @Override public String call() {
            int n = invocations.incrementAndGet();
            log("    callable invocation #" + n + " returns \"ok\"");
            return "ok";
        }
    }

    /** Same construction as Executors.newCachedThreadPool(factory), plus observation hooks. */
    static final class ObservingCachedPool extends ThreadPoolExecutor {
        final CountDownLatch firstTaskProcessed = new CountDownLatch(1);
        volatile String firstTaskState = "never processed";
        ObservingCachedPool(ThreadFactory f) {
            super(0, Integer.MAX_VALUE, 60L, TimeUnit.SECONDS, new SynchronousQueue<Runnable>(), f);
        }
        @Override protected void beforeExecute(Thread t, Runnable r) {
            log("    worker " + t.getName() + " now runs the attempt's FutureTask: isCancelled()=" + ((Future<?>) r).isCancelled());
        }
        @Override protected void afterExecute(Runnable r, Throwable t) {
            firstTaskState = "isCancelled()=" + ((Future<?>) r).isCancelled() + " isDone()=" + ((Future<?>) r).isDone();
            firstTaskProcessed.countDown();
        }
    }

    /** User-supplied ThreadFactory: each new worker begins its pool loop only after delayMs (a slow thread start). */
    static final class DelayedStartFactory implements ThreadFactory {
        final long delayMs; final AtomicInteger made = new AtomicInteger();
        DelayedStartFactory(long delayMs) { this.delayMs = delayMs; }
        @Override public Thread newThread(final Runnable worker) {
            final String name = "mc12-w" + made.incrementAndGet();
            Thread t = new Thread(new Runnable() {
                @Override public void run() {
                    log("    worker " + name + " created with the attempt task assigned; its start is delayed " + delayMs + " ms");
                    try { Thread.sleep(delayMs); } catch (InterruptedException e) { Thread.currentThread().interrupt(); }
                    worker.run();
                }
            }, name);
            t.setDaemon(true);
            return t;
        }
    }

    static final class Outcome {
        String kind; Object value; Throwable cause; long ms;
        boolean execOfTimeout() { return "ExecutionException".equals(kind) && cause instanceof UncheckedTimeoutException; }
        boolean returnedOk() { return "RETURNED".equals(kind) && "ok".equals(value); }
        String brief() {
            if ("RETURNED".equals(kind)) return "returned \"" + value + "\"";
            return kind + "(" + (cause == null ? "null" : cause.getClass().getSimpleName()) + ")";
        }
        @Override public String toString() {
            if ("RETURNED".equals(kind)) return "call() RETURNED \"" + value + "\" after " + ms + " ms";
            return "call() THREW " + kind + " with cause " + (cause == null ? "null" : cause.getClass().getName()) + " after " + ms + " ms";
        }
    }

    static Outcome invoke(Retryer<String> retryer, Callable<String> callable) {
        Outcome o = new Outcome();
        long s = System.nanoTime();
        try {
            o.value = retryer.call(callable);
            o.kind = "RETURNED";
        } catch (ExecutionException e) {
            o.kind = "ExecutionException";
            o.cause = e.getCause();
        } catch (RetryException e) {
            o.kind = "RetryException";
            Attempt<?> last = e.getLastFailedAttempt();
            o.cause = last.hasException() ? last.getExceptionCause() : null;
        }
        o.ms = TimeUnit.NANOSECONDS.toMillis(System.nanoTime() - s);
        return o;
    }

    static void summary(String id, Outcome o, RecordingListener l, CountingStop stop, CountingWait wait, int invocations, boolean bug) {
        System.out.println(id + " OBSERVED: " + o.brief() + " after " + o.ms + " ms | attempts seen by listener=" + l.attempts
                + " | stop.shouldStop calls=" + stop.calls.get() + " | wait.computeSleepTime calls=" + wait.calls.get()
                + " | callable invocations=" + invocations + " => " + (bug ? "BUG" : "no bug"));
    }

    static void ctlSummary(String id, Outcome o, RecordingListener l, CountingStop stop, CountingWait wait, int invocations, boolean ok) {
        System.out.println(id + " OBSERVED: " + o.brief() + " after " + o.ms + " ms | attempts seen by listener=" + l.attempts
                + " | stop.shouldStop calls=" + stop.calls.get() + " | wait.computeSleepTime calls=" + wait.calls.get()
                + " | callable invocations=" + invocations + " => control " + (ok ? "OK" : "FAILED"));
    }

    /** S1: the exact counterexample interleaving. */
    static boolean s1() throws Exception {
        log("S1  exact CE: the limit expires before the new worker starts the callable (Level 1: user ThreadFactory delays thread start)");
        log("    config: fixedTimeLimit(" + S1_LIMIT_MS + " ms, cachedPool(delayed-start " + S1_START_DELAY_MS + " ms)), retryIfExceptionOfType(IOException), stopAfterAttempt(5), fixedWait(50 ms)");
        ObservingCachedPool pool = new ObservingCachedPool(new DelayedStartFactory(S1_START_DELAY_MS));
        CountingStop stop = new CountingStop("stopAfterAttempt(5)", StopStrategies.stopAfterAttempt(5));
        CountingWait wait = new CountingWait("fixedWait(50 ms)", WaitStrategies.fixedWait(50, TimeUnit.MILLISECONDS));
        RecordingListener listener = new RecordingListener();
        Retryer<String> retryer = RetryerBuilder.<String>newBuilder()
                .withAttemptTimeLimiter(AttemptTimeLimiters.<String>fixedTimeLimit(S1_LIMIT_MS, TimeUnit.MILLISECONDS, pool))
                .retryIfExceptionOfType(IOException.class)
                .withStopStrategy(stop)
                .withWaitStrategy(wait)
                .withRetryListener(listener)
                .build();
        AlwaysOk callable = new AlwaysOk();
        Outcome o = invoke(retryer, callable);
        log("    " + o);
        boolean processed = pool.firstTaskProcessed.await(10, TimeUnit.SECONDS);
        log("    the delayed worker has processed the attempt's FutureTask: " + processed + " (" + pool.firstTaskState + ")");
        int inv = callable.invocations.get();
        pool.shutdownNow();
        boolean bug = o.execOfTimeout() && stop.calls.get() == 0 && wait.calls.get() == 0
                && listener.attempts.size() == 1 && inv == 0 && processed;
        summary("S1", o, listener, stop, wait, inv, bug);
        return bug;
    }

    /** S2: canonical shape; attempt 1 stalls past the limit and attempt 2 would succeed. Level 0. */
    static boolean s2() throws Exception {
        log("S2  canonical: attempt 1 stalls past the limit, attempt 2 would succeed (Level 0: public API only)");
        log("    config: fixedTimeLimit(" + LIMIT_MS + " ms) [library-default executor], retryIfExceptionOfType(IOException), stopAfterAttempt(5), fixedWait(50 ms)");
        CountingStop stop = new CountingStop("stopAfterAttempt(5)", StopStrategies.stopAfterAttempt(5));
        CountingWait wait = new CountingWait("fixedWait(50 ms)", WaitStrategies.fixedWait(50, TimeUnit.MILLISECONDS));
        RecordingListener listener = new RecordingListener();
        Retryer<String> retryer = RetryerBuilder.<String>newBuilder()
                .withAttemptTimeLimiter(AttemptTimeLimiters.<String>fixedTimeLimit(LIMIT_MS, TimeUnit.MILLISECONDS))
                .retryIfExceptionOfType(IOException.class)
                .withStopStrategy(stop)
                .withWaitStrategy(wait)
                .withRetryListener(listener)
                .build();
        StallOnceThenOk callable = new StallOnceThenOk();
        Outcome o = invoke(retryer, callable);
        log("    " + o);
        callable.firstEnded.await(5, TimeUnit.SECONDS);
        int inv = callable.invocations.get();
        boolean bug = o.execOfTimeout() && stop.calls.get() == 0 && wait.calls.get() == 0
                && listener.attempts.size() == 1 && inv <= 1;
        summary("S2", o, listener, stop, wait, inv, bug);
        return bug;
    }

    /** S3: the upstream #29 reporter's configuration (no retryIf), scaled down. Level 0. */
    static boolean s3() throws Exception {
        log("S3  upstream #29 configuration: no retryIf; fixedWait + stopAfterDelay (Level 0)");
        log("    config: fixedTimeLimit(" + LIMIT_MS + " ms), fixedWait(100 ms), stopAfterDelay(3000 ms)");
        CountingStop stop = new CountingStop("stopAfterDelay(3000 ms)", StopStrategies.stopAfterDelay(3000, TimeUnit.MILLISECONDS));
        CountingWait wait = new CountingWait("fixedWait(100 ms)", WaitStrategies.fixedWait(100, TimeUnit.MILLISECONDS));
        RecordingListener listener = new RecordingListener();
        Retryer<String> retryer = RetryerBuilder.<String>newBuilder()
                .withAttemptTimeLimiter(AttemptTimeLimiters.<String>fixedTimeLimit(LIMIT_MS, TimeUnit.MILLISECONDS))
                .withWaitStrategy(wait)
                .withStopStrategy(stop)
                .withRetryListener(listener)
                .build();
        StallOnceThenOk callable = new StallOnceThenOk();
        Outcome o = invoke(retryer, callable);
        log("    " + o);
        callable.firstEnded.await(5, TimeUnit.SECONDS);
        int inv = callable.invocations.get();
        boolean bug = o.execOfTimeout() && stop.calls.get() == 0 && wait.calls.get() == 0
                && listener.attempts.size() == 1 && inv <= 1;
        summary("S3", o, listener, stop, wait, inv, bug);
        return bug;
    }

    /** C1: same config as S2, but attempt 1 fails with IOException instead of timing out. */
    static boolean c1() throws Exception {
        log("C1  control: S2 config, attempt 1 throws IOException (an ordinary transient failure)");
        CountingStop stop = new CountingStop("stopAfterAttempt(5)", StopStrategies.stopAfterAttempt(5));
        CountingWait wait = new CountingWait("fixedWait(50 ms)", WaitStrategies.fixedWait(50, TimeUnit.MILLISECONDS));
        RecordingListener listener = new RecordingListener();
        Retryer<String> retryer = RetryerBuilder.<String>newBuilder()
                .withAttemptTimeLimiter(AttemptTimeLimiters.<String>fixedTimeLimit(LIMIT_MS, TimeUnit.MILLISECONDS))
                .retryIfExceptionOfType(IOException.class)
                .withStopStrategy(stop)
                .withWaitStrategy(wait)
                .withRetryListener(listener)
                .build();
        FailOnceThenOk callable = new FailOnceThenOk();
        Outcome o = invoke(retryer, callable);
        log("    " + o);
        int inv = callable.invocations.get();
        boolean ok = o.returnedOk() && stop.calls.get() == 1 && wait.calls.get() == 1 && inv == 2;
        ctlSummary("C1", o, listener, stop, wait, inv, ok);
        return ok;
    }

    /** C2: S2 config plus the #29 workaround predicate retryIfExceptionOfType(UncheckedTimeoutException). */
    static boolean c2() throws Exception {
        log("C2  control: S2 config + retryIfExceptionOfType(UncheckedTimeoutException) (the #29 workaround)");
        CountingStop stop = new CountingStop("stopAfterAttempt(5)", StopStrategies.stopAfterAttempt(5));
        CountingWait wait = new CountingWait("fixedWait(50 ms)", WaitStrategies.fixedWait(50, TimeUnit.MILLISECONDS));
        RecordingListener listener = new RecordingListener();
        Retryer<String> retryer = RetryerBuilder.<String>newBuilder()
                .withAttemptTimeLimiter(AttemptTimeLimiters.<String>fixedTimeLimit(LIMIT_MS, TimeUnit.MILLISECONDS))
                .retryIfExceptionOfType(IOException.class)
                .retryIfExceptionOfType(UncheckedTimeoutException.class)
                .withStopStrategy(stop)
                .withWaitStrategy(wait)
                .withRetryListener(listener)
                .build();
        StallOnceThenOk callable = new StallOnceThenOk();
        Outcome o = invoke(retryer, callable);
        log("    " + o);
        int inv = callable.invocations.get();
        boolean ok = o.returnedOk() && stop.calls.get() >= 1 && wait.calls.get() >= 1
                && !listener.attempts.isEmpty() && listener.attempts.get(0).endsWith("UncheckedTimeoutException");
        ctlSummary("C2", o, listener, stop, wait, inv, ok);
        return ok;
    }

    public static void main(String[] args) throws Exception {
        verbose = !(args.length > 0 && "--quiet".equals(args[0]));
        boolean b1 = s1();
        boolean b2 = s2();
        boolean b3 = s3();
        boolean k1 = c1();
        boolean k2 = c2();
        int code;
        if (!k1 || !k2) {
            System.out.println("RESULT: INCONCLUSIVE (a control did not behave as expected)");
            code = 2;
        } else if (b1 && b2 && b3) {
            System.out.println("RESULT: PASS (bug triggered: the first attempt timeout ended call() with "
                    + "ExecutionException(UncheckedTimeoutException); stop/wait strategies never consulted)");
            code = 0;
        } else {
            System.out.println("RESULT: FAIL (bug not triggered in every scenario: S1=" + b1 + " S2=" + b2 + " S3=" + b3 + ")");
            code = 1;
        }
        System.out.flush();
        // fixedTimeLimit(d, unit) owns a cached pool with non-daemon threads (upstream #92); exit explicitly.
        System.exit(code);
    }
}
JAVA

timeout 300 "$JAVAC" --release 8 -nowarn -Xlint:-options -encoding UTF-8 -cp "$WORK/lib:$CP" -d "$WORK/test" "$WORK/test/MC12Repro.java"
RUN_CP="$WORK/test:$WORK/lib:$CP"

pass=0; fail=0; inconclusive=0
for ((i = 1; i <= RUNS; i++)); do
  if (( i == 1 )); then
    echo; echo "== run $i/$RUNS (verbose): timeout 120 java -cp <lib+test+guava-22.0+jsr305> MC12Repro"
    set +e; timeout 120 "$JAVA" -cp "$RUN_CP" MC12Repro; rc=$?; set -e
  else
    echo; echo "== run $i/$RUNS (quiet)"
    set +e; timeout 120 "$JAVA" -cp "$RUN_CP" MC12Repro --quiet; rc=$?; set -e
  fi
  case $rc in
    0) pass=$((pass + 1)) ;;
    1) fail=$((fail + 1)) ;;
    *) inconclusive=$((inconclusive + 1)); echo "(run $i exit status $rc)" ;;
  esac
done

echo
if (( inconclusive > 0 )); then
  echo "OVERALL: INCONCLUSIVE (pass=$pass fail=$fail inconclusive=$inconclusive of $RUNS runs)"; exit 2
elif (( fail > 0 )); then
  echo "OVERALL: FAIL (bug not triggered in $fail of $RUNS runs; pass=$pass)"; exit 1
else
  echo "OVERALL: PASS (bug triggered in $pass/$RUNS runs)"; exit 0
fi
