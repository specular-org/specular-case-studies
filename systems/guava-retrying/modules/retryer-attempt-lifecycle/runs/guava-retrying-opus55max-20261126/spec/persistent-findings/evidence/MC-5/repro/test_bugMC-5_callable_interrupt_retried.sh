#!/usr/bin/env bash
# MC-5 reproduction — guava-retrying 2.0.0, noTimeLimit path.
#
# Claim: when the thread running Retryer.call(...) is interrupted while the callable
# is blocked in an interruptible call, the callable throws InterruptedException (the JDK
# clears the interrupt status), Retryer.call catches it as an ordinary failed attempt
# (Retryer.java:162-163) and — with a predicate that matches it, e.g. retryIfException() —
# retries. call() then returns normally with the interrupt status clear, contradicting
# Retryer.java:59-61 / 151-153 ("retry ... unless ... the thread is interrupted";
# "if the thread is interrupted, [RetryException] is thrown and the thread's interrupt
# status is set").
#
# Escalation level: 0 (pure black-box). Only public API is used: RetryerBuilder,
# Retryer.call, Retryer.wrap, Thread.interrupt, ExecutorService.shutdownNow. The library
# source is compiled unmodified from the confirmation worktree. The test only waits
# until the caller thread is parked inside LinkedBlockingQueue.take() before delivering
# the interrupt (test orchestration; no sleeps or hooks in library code).
#
# Scenarios
#   A  exact MC trace (hunt_s2_interrupt_nolimit_bfs1/bfs2): interrupt during attempt 1
#      -> attempt 2 starts -> attempt 2 returns -> call() returns normally, status clear.
#      Repeated N times (default 50) for determinism.
#   B  consumer harm: retryer.wrap(callable) submitted to a JDK ExecutorService;
#      shutdownNow() cannot stop it (awaitTermination(2s) == false), the task is retried
#      and later completes normally with a value.
#   C  supplementary, same catch-all: predicate does NOT match InterruptedException
#      (retryIfRuntimeException) -> ExecutionException(InterruptedException), status clear.
#   D  positive control: interrupt during the inter-attempt Thread.sleep -> the library's
#      own guard (Retryer.java:179-181) gives RetryException + status set.
# Fix control (not part of the trigger): the same program is run against a temp copy of
# Retryer.java with a 4-line fix to show the test discriminates bug vs. correct behaviour.
#
# Usage: test_bugMC-5_callable_interrupt_retried.sh [iterations]
#   env GUAVA_RETRYING_SRC  library checkout (default: MC-5 confirmation worktree)
#   env GUAVA_JAR / JSR305_JAR  dependency jars (default: ~/.m2, Guava 22.0, jsr305 2.0.2)
#   env JAVA_HOME_11  optional extra JDK to rerun the pristine build on (default: JDK 11 if present)
set -euo pipefail

ITER="${1:-50}"
HERE="$(cd "$(dirname "$0")" && pwd)"
SRC="${GUAVA_RETRYING_SRC:-$HERE/../confirmation/MC-5/worktree}"
GUAVA_JAR="${GUAVA_JAR:-$HOME/.m2/repository/com/google/guava/guava/22.0/guava-22.0.jar}"
JSR305_JAR="${JSR305_JAR:-$HOME/.m2/repository/com/google/code/findbugs/jsr305/2.0.2/jsr305-2.0.2.jar}"
JAVA_HOME_11="${JAVA_HOME_11:-/usr/lib/jvm/java-11-openjdk-amd64}"
JAVAC="${JAVAC:-javac}"
JAVA="${JAVA:-java}"

for f in "$SRC/src/main/java/com/github/rholder/retry/Retryer.java" "$GUAVA_JAR" "$JSR305_JAR"; do
  [ -e "$f" ] || { echo "missing: $f" >&2; exit 2; }
done

WORK="$(mktemp -d /tmp/mc5-repro.XXXXXX)"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/lib-pristine" "$WORK/lib-fixed" "$WORK/fixsrc" "$WORK/test-pristine" "$WORK/test-fixed" "$WORK/t"

echo "== MC-5 repro: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "== library source: $SRC (git HEAD: $(git -C "$SRC" rev-parse --short HEAD 2>/dev/null || echo n/a); dirty files: $(git -C "$SRC" status --porcelain 2>/dev/null | wc -l))"
echo "== Retryer.java sha256: $(sha256sum "$SRC/src/main/java/com/github/rholder/retry/Retryer.java" | cut -c1-16)"
echo "== deps: $(basename "$GUAVA_JAR"), $(basename "$JSR305_JAR"); javac: $($JAVAC -version 2>&1)"

# ---------------------------------------------------------------- test program
cat > "$WORK/t/ReproMC5.java" <<'JAVA'
import com.github.rholder.retry.Attempt;
import com.github.rholder.retry.RetryException;
import com.github.rholder.retry.RetryListener;
import com.github.rholder.retry.Retryer;
import com.github.rholder.retry.RetryerBuilder;
import com.github.rholder.retry.StopStrategies;
import com.github.rholder.retry.WaitStrategies;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.ThreadFactory;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicReference;

public class ReproMC5 {

    static void log(String s) { System.out.println(s); System.out.flush(); }

    static RetryListener recordingListener(final List<String> out) {
        return new RetryListener() {
            @Override
            public <V> void onRetry(Attempt<V> a) {
                out.add("attempt#" + a.getAttemptNumber() + "="
                        + (a.hasException() ? "exception:" + a.getExceptionCause() : "result:" + a.getResult())
                        + " (interrupt status seen by listener=" + Thread.currentThread().isInterrupted() + ")");
            }
        };
    }

    static boolean inFrame(Thread t, String cls, String methodPrefix) {
        for (StackTraceElement e : t.getStackTrace()) {
            if (e.getClassName().equals(cls) && e.getMethodName().startsWith(methodPrefix)) return true;
        }
        return false;
    }

    /** t is parked inside LinkedBlockingQueue.take() (i.e. the callable is blocked in an interruptible call). */
    static boolean blockedInTake(Thread t) {
        return t.getState() == Thread.State.WAITING && inFrame(t, "java.util.concurrent.LinkedBlockingQueue", "take");
    }

    /** Wait until attempt #n has started and is parked in take() (true) or t has terminated (false). */
    static boolean awaitAttemptBlocked(Thread t, AtomicInteger attempts, int n, long timeoutMs) throws InterruptedException {
        long deadline = System.nanoTime() + TimeUnit.MILLISECONDS.toNanos(timeoutMs);
        while (System.nanoTime() < deadline) {
            if (attempts.get() == n && blockedInTake(t)) return true;
            if (t.getState() == Thread.State.TERMINATED) return false;
            Thread.sleep(1);
        }
        throw new IllegalStateException("timeout: attempts=" + attempts.get() + " state=" + t.getState());
    }

    static final class Obs {
        String outcome = "<none>";
        boolean interruptedAfter;
        int attempts;
        boolean secondAttemptStarted;
        List<String> listenerLog;
    }

    // ------------------------------------------------------------------ A
    /** Exact MC trace: IntrBlock -> MCInterrupt -> CallableIE -> BlockZero -> attempt 2 "Ret" -> PredicateAccepts. */
    static Obs scenarioA() throws Exception {
        final LinkedBlockingQueue<String> queue = new LinkedBlockingQueue<String>();
        final AtomicInteger attempts = new AtomicInteger();
        final List<String> listenerLog = Collections.synchronizedList(new ArrayList<String>());
        final Retryer<String> retryer = RetryerBuilder.<String>newBuilder()
                .retryIfException()                                   // InterruptedException is an Exception
                .withStopStrategy(StopStrategies.stopAfterAttempt(5)) // a retry is allowed
                .withRetryListener(recordingListener(listenerLog))
                .build();                                             // defaults: noTimeLimit, noWait, Thread.sleep block
        final Obs o = new Obs();
        final AtomicReference<String> outcome = new AtomicReference<String>("<none>");
        final AtomicBoolean interruptedAfter = new AtomicBoolean();
        Thread caller = new Thread(new Runnable() {
            @Override
            public void run() {
                try {
                    String r = retryer.call(new Callable<String>() {
                        @Override
                        public String call() throws Exception {
                            attempts.incrementAndGet();
                            return queue.take();   // interruptible; InterruptedException propagates to Retryer
                        }
                    });
                    outcome.set("call() returned normally: \"" + r + "\"");
                } catch (RetryException e) {
                    outcome.set("RetryException(numberOfFailedAttempts=" + e.getNumberOfFailedAttempts() + ", cause=" + e.getCause() + ")");
                } catch (ExecutionException e) {
                    outcome.set("ExecutionException(cause=" + e.getCause() + ")");
                } catch (Throwable t) {
                    outcome.set("unexpected " + t);
                }
                interruptedAfter.set(Thread.currentThread().isInterrupted());
            }
        }, "caller-A");
        caller.setDaemon(true);
        caller.start();
        awaitAttemptBlocked(caller, attempts, 1, 5000); // attempt 1 parked in take()   (MCCallerBodyStart "IntrBlock")
        caller.interrupt();                             // caller thread interrupted     (MCInterrupt)
        o.secondAttemptStarted = awaitAttemptBlocked(caller, attempts, 2, 5000); // (MCBlockZero -> MCCallerBodyStart)
        if (o.secondAttemptStarted) {
            queue.offer("value-for-attempt-2");         // attempt 2 returns normally   (MCCallerBodyReturns)
        }
        caller.join(5000);
        if (caller.isAlive()) throw new IllegalStateException("caller-A still alive");
        o.outcome = outcome.get();
        o.interruptedAfter = interruptedAfter.get();
        o.attempts = attempts.get();
        o.listenerLog = new ArrayList<String>(listenerLog);
        return o;
    }

    static String classifyA(Obs o) {
        boolean bug = o.outcome.startsWith("call() returned normally") && !o.interruptedAfter && o.attempts == 2
                && o.secondAttemptStarted && !o.listenerLog.isEmpty()
                && o.listenerLog.get(0).contains("java.lang.InterruptedException");
        boolean ok = o.outcome.startsWith("RetryException") && o.interruptedAfter && o.attempts == 1;
        return bug ? "BUG_TRIGGERED" : ok ? "CONTRACT_HELD" : "OTHER";
    }

    // ------------------------------------------------------------------ B
    static String scenarioB() throws Exception {
        final LinkedBlockingQueue<String> queue = new LinkedBlockingQueue<String>();
        final AtomicInteger attempts = new AtomicInteger();
        final List<String> listenerLog = Collections.synchronizedList(new ArrayList<String>());
        final Retryer<String> retryer = RetryerBuilder.<String>newBuilder()
                .retryIfException()
                .withRetryListener(recordingListener(listenerLog))
                .build();                                   // all defaults: neverStop, noWait, noTimeLimit
        final AtomicReference<Thread> worker = new AtomicReference<Thread>();
        ExecutorService pool = Executors.newSingleThreadExecutor(new ThreadFactory() {
            @Override
            public Thread newThread(Runnable r) {
                Thread t = new Thread(r, "pool-worker-B");
                t.setDaemon(true);
                worker.set(t);
                return t;
            }
        });
        Future<String> f = pool.submit(retryer.wrap(new Callable<String>() {
            @Override
            public String call() throws Exception {
                attempts.incrementAndGet();
                return queue.take();
            }
        }));
        long deadline = System.nanoTime() + TimeUnit.SECONDS.toNanos(5);
        while (worker.get() == null && System.nanoTime() < deadline) Thread.sleep(1);
        Thread w = worker.get();
        awaitAttemptBlocked(w, attempts, 1, 5000);
        List<Runnable> neverRun = pool.shutdownNow();       // JDK cancellation: interrupts the running task
        boolean terminated = pool.awaitTermination(2, TimeUnit.SECONDS);
        int attemptsAfterShutdown = attempts.get();
        boolean blockedAgain = blockedInTake(w);
        log("  B: shutdownNow() -> " + neverRun.size() + " never-run tasks; isShutdown=" + pool.isShutdown()
                + "; awaitTermination(2s)=" + terminated);
        log("  B: attempts after shutdownNow = " + attemptsAfterShutdown + "; worker state=" + w.getState()
                + "; worker parked in take() again=" + blockedAgain);
        log("  B: listener log = " + listenerLog);
        queue.offer("late-value");                          // data arrives later
        String fo;
        try {
            fo = "Future.get() returned normally: \"" + f.get(5, TimeUnit.SECONDS) + "\"";
        } catch (ExecutionException e) {
            fo = "Future.get() threw ExecutionException(cause=" + e.getCause() + ")";
        }
        boolean terminated2 = pool.awaitTermination(5, TimeUnit.SECONDS);
        log("  B: after offering a value: " + fo + "; awaitTermination(5s)=" + terminated2
                + "; total attempts=" + attempts.get());
        boolean bug = !terminated && attemptsAfterShutdown == 2 && blockedAgain && fo.contains("returned normally");
        boolean ok = terminated && attemptsAfterShutdown == 1 && fo.contains("RetryException");
        return bug ? "BUG_TRIGGERED" : ok ? "CONTRACT_HELD" : "OTHER";
    }

    // ------------------------------------------------------------------ C
    static String scenarioC() throws Exception {
        final LinkedBlockingQueue<String> queue = new LinkedBlockingQueue<String>();
        final AtomicInteger attempts = new AtomicInteger();
        final Retryer<String> retryer = RetryerBuilder.<String>newBuilder()
                .retryIfRuntimeException()                  // does NOT match InterruptedException
                .withStopStrategy(StopStrategies.stopAfterAttempt(5))
                .build();
        final AtomicReference<String> outcome = new AtomicReference<String>("<none>");
        final AtomicBoolean interruptedAfter = new AtomicBoolean();
        Thread caller = new Thread(new Runnable() {
            @Override
            public void run() {
                try {
                    String r = retryer.call(new Callable<String>() {
                        @Override
                        public String call() throws Exception {
                            attempts.incrementAndGet();
                            return queue.take();
                        }
                    });
                    outcome.set("call() returned normally: \"" + r + "\"");
                } catch (RetryException e) {
                    outcome.set("RetryException(numberOfFailedAttempts=" + e.getNumberOfFailedAttempts() + ", cause=" + e.getCause() + ")");
                } catch (ExecutionException e) {
                    outcome.set("ExecutionException(cause=" + e.getCause() + ")");
                } catch (Throwable t) {
                    outcome.set("unexpected " + t);
                }
                interruptedAfter.set(Thread.currentThread().isInterrupted());
            }
        }, "caller-C");
        caller.setDaemon(true);
        caller.start();
        awaitAttemptBlocked(caller, attempts, 1, 5000);
        caller.interrupt();
        caller.join(5000);
        if (caller.isAlive()) throw new IllegalStateException("caller-C still alive");
        log("  C: outcome=" + outcome.get() + "; interrupt status after call()=" + interruptedAfter.get()
                + "; attempts=" + attempts.get());
        boolean bug = outcome.get().startsWith("ExecutionException(cause=java.lang.InterruptedException") && !interruptedAfter.get();
        boolean ok = outcome.get().startsWith("RetryException") && interruptedAfter.get();
        return bug ? "BUG_TRIGGERED" : ok ? "CONTRACT_HELD" : "OTHER";
    }

    // ------------------------------------------------------------------ D
    static String controlD() throws Exception {
        final AtomicInteger attempts = new AtomicInteger();
        final Retryer<String> retryer = RetryerBuilder.<String>newBuilder()
                .retryIfException()
                .withWaitStrategy(WaitStrategies.fixedWait(30, TimeUnit.SECONDS))
                .withStopStrategy(StopStrategies.stopAfterAttempt(5))
                .build();
        final AtomicReference<String> outcome = new AtomicReference<String>("<none>");
        final AtomicBoolean interruptedAfter = new AtomicBoolean();
        final Thread caller = new Thread(new Runnable() {
            @Override
            public void run() {
                try {
                    String r = retryer.call(new Callable<String>() {
                        @Override
                        public String call() throws Exception {
                            throw new IOException("transient failure #" + attempts.incrementAndGet());
                        }
                    });
                    outcome.set("call() returned normally: \"" + r + "\"");
                } catch (RetryException e) {
                    outcome.set("RetryException(numberOfFailedAttempts=" + e.getNumberOfFailedAttempts() + ", cause=" + e.getCause() + ")");
                } catch (ExecutionException e) {
                    outcome.set("ExecutionException(cause=" + e.getCause() + ")");
                } catch (Throwable t) {
                    outcome.set("unexpected " + t);
                }
                interruptedAfter.set(Thread.currentThread().isInterrupted());
            }
        }, "caller-D");
        caller.setDaemon(true);
        caller.start();
        long deadline = System.nanoTime() + TimeUnit.SECONDS.toNanos(5);
        while (!(attempts.get() == 1 && caller.getState() == Thread.State.TIMED_WAITING
                && inFrame(caller, "java.lang.Thread", "sleep"))) {
            if (System.nanoTime() > deadline) throw new IllegalStateException("caller-D never slept");
            Thread.sleep(1);
        }
        caller.interrupt();                                  // interrupt during the inter-attempt wait
        caller.join(5000);
        log("  D: outcome=" + outcome.get() + "; interrupt status after call()=" + interruptedAfter.get()
                + "; attempts=" + attempts.get());
        boolean ok = outcome.get().startsWith("RetryException(numberOfFailedAttempts=1") && interruptedAfter.get();
        return ok ? "CONTRACT_HELD" : "OTHER";
    }

    public static void main(String[] args) throws Exception {
        int n = args.length > 0 ? Integer.parseInt(args[0]) : 50;
        log("java.version=" + System.getProperty("java.version") + "; Retryer from "
                + Retryer.class.getProtectionDomain().getCodeSource().getLocation());

        log("SCENARIO A detail (run 1 of " + n + "): retryIfException + stopAfterAttempt(5), defaults noTimeLimit/noWait;"
                + " interrupt the caller while attempt 1 is parked in queue.take()");
        int bug = 0, ok = 0, other = 0;
        for (int i = 1; i <= n; i++) {
            Obs o = scenarioA();
            String c = classifyA(o);
            if (i == 1) {
                log("  A: listener log = " + o.listenerLog);
                log("  A: attempt 2 started after the interrupt = " + o.secondAttemptStarted);
                log("  A: outcome = " + o.outcome);
                log("  A: Thread.currentThread().isInterrupted() right after call() = " + o.interruptedAfter);
                log("  A: total attempts = " + o.attempts + " -> " + c);
            }
            if (c.equals("BUG_TRIGGERED")) bug++; else if (c.equals("CONTRACT_HELD")) ok++; else { other++; log("  A run " + i + " OTHER: " + o.outcome + " intr=" + o.interruptedAfter + " attempts=" + o.attempts); }
        }
        log("SCENARIO A (MC trace bfs1/bfs2): BUG_TRIGGERED in " + bug + "/" + n + " runs; CONTRACT_HELD in " + ok + "/" + n + "; OTHER " + other);

        log("SCENARIO B detail: retryer.wrap(callable) on Executors.newSingleThreadExecutor(); all-default retryer + retryIfException; shutdownNow()");
        log("SCENARIO B (ExecutorService.shutdownNow consumer): " + scenarioB());

        log("SCENARIO C detail (supplementary, same catch-all): retryIfRuntimeException (does not match InterruptedException)");
        log("SCENARIO C (no retry, status still lost): " + scenarioC());

        log("CONTROL D detail: interrupt during the inter-attempt Thread.sleep (fixedWait 30s)");
        log("CONTROL D (interrupt during wait, Retryer.java:179-181): " + controlD());
        System.exit(0);
    }
}
JAVA

# ---------------------------------------------------------------- builds
LIBSRC=$(find "$SRC/src/main/java" -name '*.java' | sort)
"$JAVAC" --release 8 -nowarn -encoding UTF-8 -cp "$GUAVA_JAR:$JSR305_JAR" -d "$WORK/lib-pristine" $LIBSRC 2>&1 | grep -v '^Note:' || true
"$JAVAC" --release 8 -nowarn -encoding UTF-8 -cp "$WORK/lib-pristine:$GUAVA_JAR:$JSR305_JAR" -d "$WORK/test-pristine" "$WORK/t/ReproMC5.java"

# Fix control: temp copy of the library with a minimal fix in Retryer.call (never touches $SRC).
cp -r "$SRC/src/main/java/." "$WORK/fixsrc/"
python3 -I - "$WORK/fixsrc/com/github/rholder/retry/Retryer.java" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
anchor = ("            for (RetryListener listener : listeners) {\n"
          "                listener.onRetry(attempt);\n"
          "            }\n")
fix = anchor + ("\n"
          "            if (attempt.hasException() && attempt.getExceptionCause() instanceof InterruptedException) {\n"
          "                Thread.currentThread().interrupt();\n"
          "                throw new RetryException(attemptNumber, attempt);\n"
          "            }\n")
assert s.count(anchor) == 1, "anchor not unique"
open(p, "w", encoding="utf-8").write(s.replace(anchor, fix))
PY
echo "== fix control diff (temp copy only):"
diff -u "$SRC/src/main/java/com/github/rholder/retry/Retryer.java" "$WORK/fixsrc/com/github/rholder/retry/Retryer.java" | sed -n '3,$p' || true
"$JAVAC" --release 8 -nowarn -encoding UTF-8 -cp "$GUAVA_JAR:$JSR305_JAR" -d "$WORK/lib-fixed" $(find "$WORK/fixsrc" -name '*.java' | sort) 2>&1 | grep -v '^Note:' || true
"$JAVAC" --release 8 -nowarn -encoding UTF-8 -cp "$WORK/lib-fixed:$GUAVA_JAR:$JSR305_JAR" -d "$WORK/test-fixed" "$WORK/t/ReproMC5.java"

# ---------------------------------------------------------------- runs
run() { # label java-binary classpath
  echo
  echo "==================== $1"
  timeout 180 "$2" -cp "$3:$GUAVA_JAR:$JSR305_JAR" ReproMC5 "$ITER" | tee "$WORK/$1.out"
}
run pristine-jdk-default "$JAVA" "$WORK/test-pristine:$WORK/lib-pristine"
P="$WORK/pristine-jdk-default.out"
P11=""
if [ -x "$JAVA_HOME_11/bin/java" ]; then
  run pristine-jdk11 "$JAVA_HOME_11/bin/java" "$WORK/test-pristine:$WORK/lib-pristine"
  P11="$WORK/pristine-jdk11.out"
fi
run fixed-control-jdk-default "$JAVA" "$WORK/test-fixed:$WORK/lib-fixed"
F="$WORK/fixed-control-jdk-default.out"

# ---------------------------------------------------------------- verdict
echo
echo "==================== summary"
expect() { # file pattern description
  if grep -qF -- "$2" "$1"; then echo "  [ok]   $3"; return 0; else echo "  [FAIL] $3 (missing: $2)"; return 1; fi
}
rc=0
for out in "$P" $P11; do
  echo " pristine library ($(basename "$out" .out)):"
  expect "$out" "BUG_TRIGGERED in $ITER/$ITER runs" "A: interrupted attempt retried, call() returned normally, status clear ($ITER/$ITER)" || rc=1
  expect "$out" "SCENARIO B (ExecutorService.shutdownNow consumer): BUG_TRIGGERED" "B: shutdownNow() could not stop the task; it was retried and completed normally" || rc=1
  expect "$out" "SCENARIO C (no retry, status still lost): BUG_TRIGGERED" "C: ExecutionException(InterruptedException) with status clear" || rc=1
  expect "$out" "CONTROL D (interrupt during wait, Retryer.java:179-181): CONTRACT_HELD" "D: positive control - interrupt during the wait honoured" || rc=1
done
echo " fix control (temp copy with the 4-line fix):"
fc=0
expect "$F" "BUG_TRIGGERED in 0/$ITER runs; CONTRACT_HELD in $ITER/$ITER;" "A: RetryException + status set ($ITER/$ITER)" || fc=1
expect "$F" "SCENARIO B (ExecutorService.shutdownNow consumer): CONTRACT_HELD" "B: shutdownNow() terminates the task" || fc=1
expect "$F" "SCENARIO C (no retry, status still lost): CONTRACT_HELD" "C: RetryException + status set" || fc=1
expect "$F" "CONTROL D (interrupt during wait, Retryer.java:179-181): CONTRACT_HELD" "D: unchanged" || fc=1
echo
if [ "$rc" -eq 0 ]; then
  echo "RESULT: MC-5 REPRODUCED (Level 0) on the unmodified library; fix control $( [ "$fc" -eq 0 ] && echo 'restores the documented contract' || echo 'DID NOT behave as expected')"
  exit 0
else
  echo "RESULT: MC-5 NOT REPRODUCED"
  exit 1
fi
