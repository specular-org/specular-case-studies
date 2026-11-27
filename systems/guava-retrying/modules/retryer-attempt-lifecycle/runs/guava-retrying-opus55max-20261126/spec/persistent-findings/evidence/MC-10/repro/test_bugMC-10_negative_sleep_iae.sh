#!/usr/bin/env bash
# MC-10 reproduction: a negative computed sleep makes Retryer.call() throw
# IllegalArgumentException (not one of call()'s documented outcomes), and on an
# interrupted thread that IAE pre-empts the RetryException the Javadoc promises.
#
# Code path under test (unmodified guava-retrying 2.0.0, 177b6c9):
#   Retryer.java:176  long sleepTime = waitStrategy.computeSleepTime(attempt);   // not validated
#   Retryer.java:178  blockStrategy.block(sleepTime);
#   Retryer.java:179  } catch (InterruptedException e) {                         // only IE caught
#   BlockStrategies.java:46  Thread.sleep(sleepTime);   // IAE for < 0, checked before the interrupt flag
#
# Counterexamples: spec/output/hunt_s5_decision_bfs1.out (DocumentedOutcomesOnly)
#                  spec/output/hunt_s5_decision_bfs3.out (InterruptedCallThrowsRetryException)
#
# Escalation level: 0. Public API only, built-in strategies, default block strategy, no library
# change. S2 orders the external Thread.interrupt() into the RetryListener loop (CE step 7) with a
# latch inside the test's own listener. That is user-level sequencing only.
#
# Negative-sleep producers used (both reachable through the public API, see investigation.md):
#   * WaitStrategies.join(fixedWait(Long.MAX_VALUE, MILLISECONDS), fixedWait(1, MILLISECONDS))
#     -> CompositeWaitStrategy's unchecked long sum = Long.MIN_VALUE (WaitStrategies.java:365-371)
#   * WaitStrategies.exceptionWait(cls, e -> retryAt - now) with a Retry-After instant that has
#     already passed -> negative value passed through unchanged (WaitStrategies.java:386-394)
#
# Usage: test_bugMC-10_negative_sleep_iae.sh [SRC_ROOT]
#   SRC_ROOT    guava-retrying checkout to build (default: the MC-10 confirmation worktree)
#   GUAVA_JAR / JSR305_JAR   dependency jars (default: ~/.m2 Guava 22.0, jsr305 2.0.2)
#   JAVA_HOMES  space-separated JDK homes to run on (default: JDK 21 and JDK 11 if present)
# Exit: 0 = bug reproduced on every JDK run; 1 = not reproduced; 2 = setup error.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_SRC="$HERE/../confirmation/MC-10/worktree"
SRC_ROOT="${1:-${SRC_ROOT:-$DEFAULT_SRC}}"
GUAVA_JAR="${GUAVA_JAR:-$HOME/.m2/repository/com/google/guava/guava/22.0/guava-22.0.jar}"
JSR305_JAR="${JSR305_JAR:-$HOME/.m2/repository/com/google/code/findbugs/jsr305/2.0.2/jsr305-2.0.2.jar}"
if [ -z "${JAVA_HOMES:-}" ]; then
  JAVA_HOMES=""
  for j in /usr/lib/jvm/java-21-openjdk-amd64 /usr/lib/jvm/java-11-openjdk-amd64; do
    [ -x "$j/bin/java" ] && JAVA_HOMES="$JAVA_HOMES $j"
  done
fi
JAVAC="${JAVAC:-javac}"

fetch_jar() { # groupId artifactId version -> fetch into ~/.m2 if missing
  command -v mvn >/dev/null 2>&1 || return 1
  timeout 5m mvn -q dependency:get -Dartifact="$1:$2:$3" >/dev/null 2>&1
}
[ -f "$GUAVA_JAR" ] || fetch_jar com.google.guava guava 22.0 || true
[ -f "$JSR305_JAR" ] || fetch_jar com.google.code.findbugs jsr305 2.0.2 || true
for f in "$GUAVA_JAR" "$JSR305_JAR"; do
  [ -f "$f" ] || { echo "SETUP ERROR: missing $f" >&2; exit 2; }
done
[ -d "$SRC_ROOT/src/main/java/com/github/rholder/retry" ] || { echo "SETUP ERROR: bad SRC_ROOT $SRC_ROOT" >&2; exit 2; }
[ -n "${JAVA_HOMES// /}" ] || { echo "SETUP ERROR: no JDK found" >&2; exit 2; }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/mc10-repro.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/lib-classes" "$WORK/test-src" "$WORK/test-classes"

echo "== source: $SRC_ROOT ($(cd "$SRC_ROOT" && git rev-parse HEAD 2>/dev/null || echo 'no git'); $(cd "$SRC_ROOT" && git status --porcelain 2>/dev/null | wc -l | tr -d ' ') local modifications)"
echo "== compiling unmodified library sources with $("$JAVAC" -version 2>&1) --release 8"
find "$SRC_ROOT/src/main/java" -name '*.java' > "$WORK/lib-sources.txt"
timeout 5m "$JAVAC" --release 8 -g -nowarn -encoding UTF-8 -cp "$GUAVA_JAR:$JSR305_JAR" \
  -d "$WORK/lib-classes" @"$WORK/lib-sources.txt" 2>&1 | grep -v -E '^(Note:|warning:)' || true
[ -f "$WORK/lib-classes/com/github/rholder/retry/Retryer.class" ] || { echo "SETUP ERROR: library build failed" >&2; exit 2; }

cat > "$WORK/test-src/MC10Repro.java" <<'JAVA'
import com.github.rholder.retry.Attempt;
import com.github.rholder.retry.RetryException;
import com.github.rholder.retry.RetryListener;
import com.github.rholder.retry.Retryer;
import com.github.rholder.retry.RetryerBuilder;
import com.github.rholder.retry.StopStrategies;
import com.github.rholder.retry.WaitStrategies;
import com.github.rholder.retry.WaitStrategy;
import com.google.common.base.Function;

import java.io.IOException;
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
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicReference;

public class MC10Repro {

    /** What one Retryer.call() ended with, observed on the calling thread itself. */
    static final class Outcome {
        volatile String kind = "NOT_FINISHED";
        volatile Object result;
        volatile Throwable thrown;
        volatile boolean interruptedAtExit;
        volatile long elapsedMs = -1;
        final AtomicInteger callableInvocations = new AtomicInteger();
        final List<Long> listenerAttempts = Collections.synchronizedList(new ArrayList<Long>());
        final AtomicReference<Attempt<?>> lastAttempt = new AtomicReference<Attempt<?>>();
        final AtomicBoolean interruptSeenInListener = new AtomicBoolean();
        Thread thread;

        boolean documented() {
            return kind.equals("RETURNED") || kind.equals("RetryException") || kind.equals("ExecutionException");
        }

        boolean isIae() {
            return thrown instanceof IllegalArgumentException;
        }

        boolean isRetryExceptionWith(int attempts, Class<?> causeType) {
            if (!(thrown instanceof RetryException)) return false;
            RetryException re = (RetryException) thrown;
            return re.getNumberOfFailedAttempts() == attempts && causeType.isInstance(re.getCause());
        }

        void print(String indent) {
            StringBuilder sb = new StringBuilder();
            sb.append(indent).append("call() ended with      : ").append(kind);
            if (thrown != null) sb.append("  [").append(thrown.getClass().getName()).append(": ").append(thrown.getMessage()).append("]");
            if (kind.equals("RETURNED")) sb.append("  value=").append(result);
            sb.append('\n').append(indent).append("documented outcome?   : ").append(documented());
            sb.append('\n').append(indent).append("interrupt status @exit: ").append(interruptedAtExit);
            sb.append('\n').append(indent).append("callable invocations  : ").append(callableInvocations.get())
              .append("; listener saw attempts ").append(listenerAttempts)
              .append("; elapsed ").append(elapsedMs).append(" ms");
            if (thrown instanceof RetryException) {
                RetryException re = (RetryException) thrown;
                sb.append('\n').append(indent).append("RetryException        : numberOfFailedAttempts=").append(re.getNumberOfFailedAttempts())
                  .append(", cause=").append(re.getCause());
            } else if (thrown != null) {
                sb.append('\n').append(indent).append("thrown.getCause()     : ").append(thrown.getCause())
                  .append("  (attempt count / last failure reachable from the thrown exception: ")
                  .append(thrown.getCause() != null).append(")");
            }
            System.out.println(sb);
        }
    }

    /** Thrown by the service: HTTP 503 with a Retry-After instant (HTTP-date) from the server's clock. */
    static final class ServiceUnavailableException extends IOException {
        final long retryAtEpochMillis;

        ServiceUnavailableException(long retryAtEpochMillis) {
            super("503 Service Unavailable, Retry-After=" + retryAtEpochMillis);
            this.retryAtEpochMillis = retryAtEpochMillis;
        }
    }

    static WaitStrategy overflowingJoin() {
        // Both components are valid built-ins: each passes FixedWaitStrategy's sleepTime >= 0 check.
        // join's Javadoc: "wait time which is total of all wait times" = Long.MAX_VALUE + 1 ms.
        return WaitStrategies.join(
                WaitStrategies.fixedWait(Long.MAX_VALUE, TimeUnit.MILLISECONDS),
                WaitStrategies.fixedWait(1L, TimeUnit.MILLISECONDS));
    }

    static WaitStrategy nonNegativeJoin() {
        return WaitStrategies.join(
                WaitStrategies.fixedWait(10L, TimeUnit.MILLISECONDS),
                WaitStrategies.fixedWait(1L, TimeUnit.MILLISECONDS));
    }

    static WaitStrategy retryAfterWait(final boolean clampAtZero) {
        return WaitStrategies.exceptionWait(ServiceUnavailableException.class,
                new Function<ServiceUnavailableException, Long>() {
                    @Override
                    public Long apply(ServiceUnavailableException e) {
                        long delay = e.retryAtEpochMillis - System.currentTimeMillis();
                        return clampAtZero ? Math.max(0L, delay) : delay;
                    }
                });
    }

    static RetryListener recordingListener(final Outcome o, final CountDownLatch inListenerLoop) {
        return new RetryListener() {
            @Override
            public <V> void onRetry(Attempt<V> attempt) {
                o.listenerAttempts.add(attempt.getAttemptNumber());
                o.lastAttempt.set(attempt);
                if (inListenerLoop != null && attempt.getAttemptNumber() == 1) {
                    // CE step 6 -> 7: we are inside the listener loop; let the other thread interrupt us.
                    inListenerLoop.countDown();
                    long deadline = System.nanoTime() + TimeUnit.SECONDS.toNanos(10);
                    while (!Thread.currentThread().isInterrupted() && System.nanoTime() < deadline) {
                        Thread.yield(); // isInterrupted() does not clear the flag
                    }
                    o.interruptSeenInListener.set(Thread.currentThread().isInterrupted());
                }
            }
        };
    }

    static Callable<String> alwaysFailsWithIOException(final Outcome o) {
        return new Callable<String>() {
            @Override
            public String call() throws Exception {
                int n = o.callableInvocations.incrementAndGet();
                throw new IOException("transient failure on attempt " + n);
            }
        };
    }

    /** Attempt 1: 503 whose Retry-After instant is already past on the client clock (server clock 2 s behind). Attempt 2: success. */
    static Callable<String> fails503ThenSucceeds(final Outcome o) {
        return new Callable<String>() {
            @Override
            public String call() throws Exception {
                int n = o.callableInvocations.incrementAndGet();
                if (n == 1) {
                    long serverNow = System.currentTimeMillis() - 2000L;
                    throw new ServiceUnavailableException(serverNow); // "Retry-After: <now on the server>"
                }
                return "ok";
            }
        };
    }

    static void startCall(final Outcome o, final Retryer<String> retryer, final Callable<String> callable,
                          final boolean preInterrupted, String threadName) {
        o.thread = new Thread(new Runnable() {
            @Override
            public void run() {
                if (preInterrupted) Thread.currentThread().interrupt();
                long t0 = System.nanoTime();
                try {
                    o.result = retryer.call(callable);
                    o.kind = "RETURNED";
                } catch (RetryException e) {
                    o.thrown = e;
                    o.kind = "RetryException";
                } catch (ExecutionException e) {
                    o.thrown = e;
                    o.kind = "ExecutionException";
                } catch (Throwable e) {
                    o.thrown = e;
                    o.kind = "UNDOCUMENTED " + e.getClass().getSimpleName();
                } finally {
                    o.interruptedAtExit = Thread.currentThread().isInterrupted();
                    o.elapsedMs = TimeUnit.NANOSECONDS.toMillis(System.nanoTime() - t0);
                }
            }
        }, threadName);
        o.thread.setDaemon(true);
        o.thread.start();
    }

    static void printOrigin(Throwable t) {
        System.out.println("      origin of the escaping exception (top frames):");
        StackTraceElement[] st = t.getStackTrace();
        for (int i = 0; i < Math.min(st.length, 4); i++) {
            System.out.println("        at " + st[i]);
        }
    }

    static int failures = 0;

    static void verdict(String id, boolean bug, String what) {
        System.out.println("  => " + id + ": " + (bug ? "BUG TRIGGERED - " : "not triggered - ") + what);
        if (!bug) failures++;
    }

    static void control(String id, boolean ok, String what) {
        System.out.println("  => " + id + ": " + (ok ? "control OK - " : "CONTROL FAILED - ") + what);
        if (!ok) failures++;
    }

    public static void main(String[] args) throws Exception {
        System.out.println("java.version=" + System.getProperty("java.version") + "  java.home=" + System.getProperty("java.home"));

        // ---------------------------------------------------------------- S1a (bfs1)
        System.out.println("\n[S1a] bfs1 / DocumentedOutcomesOnly: attempt 1 throws IOException, retryable, stopAfterAttempt(3),");
        System.out.println("      wait = join(fixedWait(Long.MAX_VALUE ms), fixedWait(1 ms)), default ThreadSleepStrategy, 1 listener");
        {
            Outcome o = new Outcome();
            WaitStrategy ws = overflowingJoin();
            Retryer<String> r = RetryerBuilder.<String>newBuilder()
                    .retryIfExceptionOfType(IOException.class)
                    .withStopStrategy(StopStrategies.stopAfterAttempt(3))
                    .withWaitStrategy(ws)
                    .withRetryListener(recordingListener(o, null))
                    .build();
            startCall(o, r, alwaysFailsWithIOException(o), false, "S1a-caller");
            o.thread.join(3000);
            boolean blocked = o.thread.isAlive();
            if (blocked) { // documented behaviour: still sleeping the (huge) total wait -> stop it
                o.thread.interrupt();
                o.thread.join(5000);
            }
            System.out.println("      wait strategy value for the failed attempt: computeSleepTime = "
                    + (o.lastAttempt.get() != null ? ws.computeSleepTime(o.lastAttempt.get()) : "n/a"));
            System.out.println("      still blocked in the wait after 3 s (documented behaviour): " + blocked);
            o.print("      ");
            if (o.thrown != null && !o.documented()) printOrigin(o.thrown);
            verdict("S1a", !blocked && o.isIae() && o.callableInvocations.get() == 1,
                    "IllegalArgumentException escaped Retryer.call() after attempt 1 (not result/ExecutionException/RetryException)");
        }

        // ---------------------------------------------------------------- S1b (bfs1, realistic producer)
        System.out.println("\n[S1b] bfs1 / DocumentedOutcomesOnly, realistic producer: attempt 1 -> 503 with a Retry-After instant");
        System.out.println("      that is already past on the client clock; wait = exceptionWait(503, e -> retryAt - now); attempt 2 would succeed");
        {
            Outcome o = new Outcome();
            WaitStrategy ws = retryAfterWait(false);
            Retryer<String> r = RetryerBuilder.<String>newBuilder()
                    .retryIfExceptionOfType(IOException.class)
                    .withStopStrategy(StopStrategies.stopAfterAttempt(3))
                    .withWaitStrategy(ws)
                    .withRetryListener(recordingListener(o, null))
                    .build();
            startCall(o, r, fails503ThenSucceeds(o), false, "S1b-caller");
            o.thread.join(10000);
            System.out.println("      wait strategy value for the failed attempt: computeSleepTime ~= "
                    + (o.lastAttempt.get() != null ? ws.computeSleepTime(o.lastAttempt.get()) : "n/a"));
            o.print("      ");
            if (o.thrown != null && !o.documented()) printOrigin(o.thrown);
            verdict("S1b", o.isIae() && o.callableInvocations.get() == 1,
                    "retrying aborted with IllegalArgumentException; attempt 2 (which would return \"ok\") never ran");
        }
        System.out.println("\n[S1b-ctl] same, but the function clamps at 0 (Math.max(0, retryAt - now))");
        {
            Outcome o = new Outcome();
            Retryer<String> r = RetryerBuilder.<String>newBuilder()
                    .retryIfExceptionOfType(IOException.class)
                    .withStopStrategy(StopStrategies.stopAfterAttempt(3))
                    .withWaitStrategy(retryAfterWait(true))
                    .withRetryListener(recordingListener(o, null))
                    .build();
            startCall(o, r, fails503ThenSucceeds(o), false, "S1b-ctl-caller");
            o.thread.join(10000);
            o.print("      ");
            control("S1b-ctl", "RETURNED".equals(o.kind) && "ok".equals(o.result) && o.callableInvocations.get() == 2,
                    "call() retried and returned \"ok\" from attempt 2");
        }

        // ---------------------------------------------------------------- S2 (bfs3)
        System.out.println("\n[S2] bfs3 / InterruptedCallThrowsRetryException: attempt 1 throws IOException; another thread interrupts");
        System.out.println("     the caller while the RetryListener loop runs (CE step 7); wait = overflowing join (CE step 9: Negative)");
        Outcome s2 = new Outcome();
        {
            CountDownLatch inListenerLoop = new CountDownLatch(1);
            Retryer<String> r = RetryerBuilder.<String>newBuilder()
                    .retryIfExceptionOfType(IOException.class)
                    .withStopStrategy(StopStrategies.stopAfterAttempt(3))
                    .withWaitStrategy(overflowingJoin())
                    .withRetryListener(recordingListener(s2, inListenerLoop))
                    .build();
            startCall(s2, r, alwaysFailsWithIOException(s2), false, "S2-caller");
            if (!inListenerLoop.await(10, TimeUnit.SECONDS)) throw new IllegalStateException("listener never ran");
            s2.thread.interrupt(); // external interrupt, Thread.interrupt() public API
            s2.thread.join(10000);
            if (s2.thread.isAlive()) { s2.thread.interrupt(); s2.thread.join(5000); }
            System.out.println("     interrupt observed inside the listener loop: " + s2.interruptSeenInListener.get());
            s2.print("     ");
            if (s2.thrown != null && !s2.documented()) printOrigin(s2.thrown);
            System.out.println("     documented (Retryer.call Javadoc): RetryException(numberOfFailedAttempts=1, cause=IOException), interrupt status set");
            verdict("S2", s2.interruptSeenInListener.get() && s2.isIae() && s2.interruptedAtExit
                            && !(s2.thrown instanceof RetryException),
                    "interrupted call ended with IllegalArgumentException instead of RetryException; attempt count and last failure lost");
        }
        System.out.println("\n[S2-ctl] identical, but a non-negative wait (join(fixedWait(10 ms), fixedWait(1 ms)))");
        {
            Outcome o = new Outcome();
            CountDownLatch inListenerLoop = new CountDownLatch(1);
            Retryer<String> r = RetryerBuilder.<String>newBuilder()
                    .retryIfExceptionOfType(IOException.class)
                    .withStopStrategy(StopStrategies.stopAfterAttempt(3))
                    .withWaitStrategy(nonNegativeJoin())
                    .withRetryListener(recordingListener(o, inListenerLoop))
                    .build();
            startCall(o, r, alwaysFailsWithIOException(o), false, "S2-ctl-caller");
            if (!inListenerLoop.await(10, TimeUnit.SECONDS)) throw new IllegalStateException("listener never ran");
            o.thread.interrupt();
            o.thread.join(10000);
            System.out.println("     interrupt observed inside the listener loop: " + o.interruptSeenInListener.get());
            o.print("     ");
            control("S2-ctl", o.interruptSeenInListener.get() && o.isRetryExceptionWith(1, IOException.class) && o.interruptedAtExit,
                    "RetryException(1 attempt, cause IOException) with interrupt status set - the documented outcome");
        }

        // ---------------------------------------------------------------- S3 (interrupt pending before call)
        System.out.println("\n[S3] interrupt already pending when call() starts (callable ignores it and fails); wait = overflowing join");
        {
            Outcome o = new Outcome();
            Retryer<String> r = RetryerBuilder.<String>newBuilder()
                    .retryIfExceptionOfType(IOException.class)
                    .withStopStrategy(StopStrategies.stopAfterAttempt(3))
                    .withWaitStrategy(overflowingJoin())
                    .build();
            startCall(o, r, alwaysFailsWithIOException(o), true, "S3-caller");
            o.thread.join(10000);
            if (o.thread.isAlive()) { o.thread.interrupt(); o.thread.join(5000); }
            o.print("     ");
            verdict("S3", o.isIae() && o.interruptedAtExit,
                    "interrupted call ended with IllegalArgumentException instead of RetryException");
        }
        System.out.println("\n[S3-ctl] identical, but wait = fixedWait(1 ms)");
        {
            Outcome o = new Outcome();
            Retryer<String> r = RetryerBuilder.<String>newBuilder()
                    .retryIfExceptionOfType(IOException.class)
                    .withStopStrategy(StopStrategies.stopAfterAttempt(3))
                    .withWaitStrategy(WaitStrategies.fixedWait(1L, TimeUnit.MILLISECONDS))
                    .build();
            startCall(o, r, alwaysFailsWithIOException(o), true, "S3-ctl-caller");
            o.thread.join(10000);
            o.print("     ");
            control("S3-ctl", o.isRetryExceptionWith(1, IOException.class) && o.interruptedAtExit,
                    "RetryException(1 attempt, cause IOException) with interrupt status set");
        }

        // ---------------------------------------------------------------- S4 (wrap -> executor consumer)
        System.out.println("\n[S4] same as S1b through Retryer.wrap() -> RetryerCallable submitted to an ExecutorService");
        {
            final Outcome o = new Outcome();
            Retryer<String> r = RetryerBuilder.<String>newBuilder()
                    .retryIfExceptionOfType(IOException.class)
                    .withStopStrategy(StopStrategies.stopAfterAttempt(3))
                    .withWaitStrategy(retryAfterWait(false))
                    .build();
            ExecutorService pool = Executors.newSingleThreadExecutor();
            try {
                Future<String> f = pool.submit(r.wrap(fails503ThenSucceeds(o)));
                String value = null;
                Throwable failure = null;
                try {
                    value = f.get(10, TimeUnit.SECONDS);
                } catch (ExecutionException e) {
                    failure = e.getCause();
                }
                System.out.println("     Future.get() -> " + (failure == null ? "value=" + value
                        : "ExecutionException, cause=" + failure.getClass().getName() + ": " + failure.getMessage())
                        + "; callable invocations=" + o.callableInvocations.get());
                verdict("S4", failure instanceof IllegalArgumentException && o.callableInvocations.get() == 1,
                        "RetryerCallable.call() (Retryer.java:317-319) propagated the IAE into the Future instead of retrying");
            } finally {
                pool.shutdownNow();
            }
        }

        System.out.println();
        if (failures == 0) {
            System.out.println("RESULT: MC-10 REPRODUCED on java " + System.getProperty("java.version")
                    + " - negative computed sleep -> Thread.sleep IAE escapes Retryer.call(); on an interrupted thread it replaces the RetryException");
            System.exit(0);
        } else {
            System.out.println("RESULT: MC-10 NOT REPRODUCED on java " + System.getProperty("java.version") + " (" + failures + " checks failed)");
            System.exit(1);
        }
    }
}
JAVA

timeout 5m "$JAVAC" --release 8 -g -nowarn -encoding UTF-8 -cp "$WORK/lib-classes:$GUAVA_JAR:$JSR305_JAR" \
  -d "$WORK/test-classes" "$WORK/test-src/MC10Repro.java"

overall=0
for jh in $JAVA_HOMES; do
  echo
  echo "================================================================ run on $jh"
  set +e
  timeout 2m "$jh/bin/java" -cp "$WORK/test-classes:$WORK/lib-classes:$GUAVA_JAR:$JSR305_JAR" MC10Repro
  rc=$?
  set -e
  echo "== exit code on $jh: $rc"
  if [ "$rc" -ne 0 ]; then overall=1; fi
done
echo
if [ "$overall" -eq 0 ]; then
  echo "OVERALL: MC-10 REPRODUCED on every JDK run"
else
  echo "OVERALL: MC-10 NOT REPRODUCED on at least one JDK run"
fi
exit "$overall"
