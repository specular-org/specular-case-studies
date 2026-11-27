#!/usr/bin/env bash
# MC-3 — "A completed attempt is reported as a timeout; its result is discarded and the work is executed again"
#
# Escalation level 0 (pure black box): only public guava-retrying API, unmodified guava-retrying 2.0.0 and
# Guava 22.0. The callable is ordinary user code that finishes near the per-attempt time limit; the time
# limiter gets a user-supplied ExecutorService (public factory AttemptTimeLimiters.fixedTimeLimit(d, u, executor))
# that forwards everything and only remembers the Future that SimpleTimeLimiter received from submit(), so the
# test can look at that Future afterwards. No library code is modified, no state is injected.
#
# For every trial the test classifies attempt 1:
#   SUCCESS                       attempt 1 recorded as a result
#   TIMEOUT_CANCELLED             attempt 1 recorded as UncheckedTimeoutException, its Future was cancelled
#                                 (the CPU-bound callable still runs to completion: control for the visible outcome)
#   TIMEOUT_CANCELLED_BEFORE_START  same, but the worker had not started the callable before cancel
#   TIMEOUT_DISCARDED_COMPLETION  attempt 1 recorded as UncheckedTimeoutException, but its Future completed
#                                 NORMALLY with the callable's value (cancel(true) failed and was ignored,
#                                 SimpleTimeLimiter.java:164-166) — the NoDiscardedCompletion violation.
# It also records, per trial, how late the callable returned relative to the earliest possible deadline
# (submit() returned + limit), whether the worker was interrupted, how many times the callable executed, and
# what Retryer.call() returned or threw.
#
# Usage: test_bugMC-3_timeout_discards_completion.sh [trials-per-config]
# Exit 0 = TIMEOUT_DISCARDED_COMPLETION observed on at least one JVM; 1 = not observed; 2 = build error.
set -euo pipefail

TRIALS="${1:-${MC3_TRIALS:-4000}}"
SRC_ROOT="${MC3_SRC_ROOT:-/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-3/worktree}"
GUAVA_JAR="${MC3_GUAVA_JAR:-$HOME/.m2/repository/com/google/guava/guava/22.0/guava-22.0.jar}"
JSR305_JAR="${MC3_JSR305_JAR:-$HOME/.m2/repository/com/google/code/findbugs/jsr305/2.0.2/jsr305-2.0.2.jar}"
JDK21="${MC3_JDK21:-/usr/lib/jvm/java-21-openjdk-amd64}"
JDK11="${MC3_JDK11:-/usr/lib/jvm/java-11-openjdk-amd64}"

for f in "$GUAVA_JAR" "$JSR305_JAR" "$JDK21/bin/javac" "$JDK21/bin/java"; do
  [ -e "$f" ] || { echo "missing: $f" >&2; exit 2; }
done
[ -d "$SRC_ROOT/src/main/java/com/github/rholder/retry" ] || { echo "missing guava-retrying sources under $SRC_ROOT" >&2; exit 2; }

B="$(mktemp -d /tmp/mc3-repro.XXXXXX)"
trap 'rm -rf "$B"' EXIT
mkdir -p "$B/lib" "$B/test"

echo "== provenance"
echo "guava-retrying source: $SRC_ROOT ($(git -C "$SRC_ROOT" rev-parse HEAD 2>/dev/null || echo 'no git'))"
echo "guava jar: $GUAVA_JAR sha1=$(sha1sum "$GUAVA_JAR" | cut -d' ' -f1)"
echo "jsr305 jar: $JSR305_JAR"

echo "== build guava-retrying 2.0.0 (unmodified sources, --release 8)"
"$JDK21/bin/javac" -nowarn -Xlint:none --release 8 -d "$B/lib" -cp "$GUAVA_JAR:$JSR305_JAR" \
  $(find "$SRC_ROOT/src/main/java" -name '*.java') 2>&1 | grep -v '^Note:' || true
[ -f "$B/lib/com/github/rholder/retry/Retryer.class" ] || { echo "library build failed" >&2; exit 2; }

cat > "$B/test/MC3Repro.java" <<'JAVA'
import com.github.rholder.retry.Attempt;
import com.github.rholder.retry.AttemptTimeLimiters;
import com.github.rholder.retry.RetryListener;
import com.github.rholder.retry.Retryer;
import com.github.rholder.retry.RetryerBuilder;
import com.github.rholder.retry.StopStrategies;
import com.google.common.util.concurrent.ForwardingExecutorService;
import com.google.common.util.concurrent.UncheckedTimeoutException;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Random;
import java.util.concurrent.Callable;
import java.util.concurrent.CancellationException;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

public class MC3Repro {
    static final long LIMIT_MS = 1;
    static final long LIMIT_NANOS = TimeUnit.MILLISECONDS.toNanos(LIMIT_MS);

    /** User-supplied executor for fixedTimeLimit(d, u, executor): forwards every call, remembers submitted Futures. */
    static final class RecordingExecutor extends ForwardingExecutorService {
        private final ExecutorService delegate;
        final List<Future<?>> futures = new CopyOnWriteArrayList<>();
        final List<Long> submitReturnedAt = new CopyOnWriteArrayList<>();
        RecordingExecutor(ExecutorService delegate) { this.delegate = delegate; }
        @Override protected ExecutorService delegate() { return delegate; }
        @Override public <T> Future<T> submit(Callable<T> task) {
            Future<T> f = delegate.submit(task);
            submitReturnedAt.add(System.nanoTime());
            futures.add(f);
            return f;
        }
        void reset() { futures.clear(); submitReturnedAt.clear(); }
    }

    /** User callable with a side effect (execution counter). Execution 1 is CPU-bound work that ends at a chosen
     *  instant near the limit (it does not poll the interrupt flag); later executions return at once. */
    static final class Work implements Callable<String> {
        final AtomicInteger executions = new AtomicInteger();
        final AtomicInteger completedBodies = new AtomicInteger();
        final CountDownLatch firstDone = new CountDownLatch(1);
        volatile long firstFinishAt;
        volatile long firstReturnedAt;
        volatile boolean firstInterrupted;
        @Override public String call() {
            int n = executions.incrementAndGet();
            try {
                if (n == 1) {
                    long until = firstFinishAt;
                    while (System.nanoTime() < until) { Thread.onSpinWait(); }
                    firstInterrupted = Thread.currentThread().isInterrupted();
                    completedBodies.incrementAndGet();
                    firstReturnedAt = System.nanoTime();
                    return "result-of-execution-1";
                }
                completedBodies.incrementAndGet();
                return "result-of-execution-" + n;
            } finally {
                if (n == 1) firstDone.countDown();
            }
        }
    }

    enum Kind { SUCCESS, TIMEOUT_CANCELLED, TIMEOUT_CANCELLED_BEFORE_START, TIMEOUT_DISCARDED_COMPLETION, OTHER }

    static final class Trial {
        int index; long offsetNanos; Kind kind; String attempt1; String future1; int executions; int completedBodies;
        int attemptsSeen; String callOutcome; long lateNanos; boolean workerInterrupted;
    }

    static final class Config {
        final String name; final Retryer<String> retryer; final RecordingExecutor exec; final List<Attempt<?>> attempts;
        Config(String name, Retryer<String> retryer, RecordingExecutor exec, List<Attempt<?>> attempts) {
            this.name = name; this.retryer = retryer; this.exec = exec; this.attempts = attempts;
        }
    }

    static Config build(String name, boolean retryIfException, ExecutorService pool) {
        RecordingExecutor exec = new RecordingExecutor(pool);
        final List<Attempt<?>> attempts = new CopyOnWriteArrayList<>();
        RetryerBuilder<String> b = RetryerBuilder.<String>newBuilder()
                .withAttemptTimeLimiter(AttemptTimeLimiters.<String>fixedTimeLimit(LIMIT_MS, TimeUnit.MILLISECONDS, exec))
                .withRetryListener(new RetryListener() {
                    @Override public <V> void onRetry(Attempt<V> attempt) { attempts.add(attempt); }
                });
        if (retryIfException) {
            b.retryIfException().withStopStrategy(StopStrategies.stopAfterAttempt(2));
        }
        return new Config(name, b.build(), exec, attempts);
    }

    static String describeAttempt(Attempt<?> a) {
        if (a.hasResult()) return "result(" + a.getResult() + ")";
        Throwable c = a.getExceptionCause();
        return "exception(" + c.getClass().getSimpleName() + ")";
    }

    static Trial runTrial(Config cfg, int index, long offsetNanos) throws Exception {
        cfg.exec.reset();
        cfg.attempts.clear();
        Work work = new Work();
        Trial t = new Trial();
        t.index = index; t.offsetNanos = offsetNanos;
        long t0 = System.nanoTime();
        work.firstFinishAt = t0 + LIMIT_NANOS + offsetNanos;
        try {
            String r = cfg.retryer.call(work);
            t.callOutcome = "returned \"" + r + "\"";
        } catch (ExecutionException e) {
            t.callOutcome = "threw ExecutionException(" + e.getCause().getClass().getSimpleName() + ")";
        } catch (Exception e) {
            t.callOutcome = "threw " + e.getClass().getSimpleName();
        }
        boolean firstRan = work.firstDone.await(2, TimeUnit.SECONDS);
        Future<?> f1 = cfg.exec.futures.get(0);
        Attempt<?> a1 = cfg.attempts.get(0);
        t.attempt1 = describeAttempt(a1);
        t.attemptsSeen = cfg.attempts.size();
        boolean a1Timeout = a1.hasException() && a1.getExceptionCause() instanceof UncheckedTimeoutException;
        if (!firstRan) {
            // Attempt 1 was cancelled while still queued (the worker had not started it within the limit), so the
            // callable never ran: an ordinary timeout before start, not the MC-3 path.
            if (a1Timeout && f1.isCancelled() && work.executions.get() == 0) {
                t.kind = Kind.TIMEOUT_CANCELLED_BEFORE_START; t.future1 = "CANCELLED isCancelled()=true";
                t.executions = 0; t.completedBodies = 0; t.lateNanos = Long.MIN_VALUE;
                return t;
            }
            throw new IllegalStateException("execution 1 never finished");
        }
        Object v1 = null; boolean cancelled = false;
        try { v1 = f1.get(10, TimeUnit.SECONDS); } catch (CancellationException ce) { cancelled = true; }
        t.future1 = (cancelled ? "CANCELLED" : "NORMAL value=\"" + v1 + "\"") + " isCancelled()=" + f1.isCancelled();
        t.executions = work.executions.get();
        t.completedBodies = work.completedBodies.get();
        t.lateNanos = work.firstReturnedAt - (cfg.exec.submitReturnedAt.get(0) + LIMIT_NANOS);
        t.workerInterrupted = work.firstInterrupted;
        if (a1.hasResult()) t.kind = Kind.SUCCESS;
        else if (a1Timeout && cancelled && t.executions < t.attemptsSeen) {
            // Attempt 1 cancelled before it started; "execution 1" was attempt 2's run.
            t.kind = Kind.TIMEOUT_CANCELLED_BEFORE_START; t.lateNanos = Long.MIN_VALUE;
        }
        else if (a1Timeout && cancelled) t.kind = Kind.TIMEOUT_CANCELLED;
        else if (a1Timeout && !f1.isCancelled() && "result-of-execution-1".equals(v1)) t.kind = Kind.TIMEOUT_DISCARDED_COMPLETION;
        else t.kind = Kind.OTHER;
        return t;
    }

    static String us(long nanos) { return String.format("%+.1fus", nanos / 1000.0); }

    static String stats(List<Long> xs) {
        if (xs.isEmpty()) return "n/a";
        List<Long> s = new ArrayList<>(xs);
        Collections.sort(s);
        return "min " + us(s.get(0)) + ", median " + us(s.get(s.size() / 2)) + ", max " + us(s.get(s.size() - 1));
    }

    static int runConfig(Config cfg, int trials, long seed) throws Exception {
        System.out.println();
        System.out.println("### config " + cfg.name + " (limit " + LIMIT_MS + " ms, " + trials + " trials)");
        Random rnd = new Random(seed);
        long estimate = 30_000;            // staircase estimate of the success/timeout boundary (ns after t0+limit)
        int[] counts = new int[Kind.values().length];
        List<List<Long>> late = new ArrayList<>();
        List<java.util.Map<String, Integer>> visible = new ArrayList<>();
        for (int i = 0; i < Kind.values().length; i++) { late.add(new ArrayList<>()); visible.add(new java.util.TreeMap<>()); }
        int printed = 0;
        Trial exampleCancelled = null;
        for (int i = 0; i < trials; i++) {
            long offset = estimate + (long) ((rnd.nextDouble() * 2 - 1) * 40_000);   // +-40us around the estimate
            Trial t = runTrial(cfg, i, offset);
            counts[t.kind.ordinal()]++;
            if (t.lateNanos != Long.MIN_VALUE) late.get(t.kind.ordinal()).add(t.lateNanos);
            String vis = "attempt#1=" + t.attempt1 + ", callable executions=" + t.executions + ", call() " + t.callOutcome;
            visible.get(t.kind.ordinal()).merge(vis, 1, Integer::sum);
            if (t.kind == Kind.SUCCESS) estimate += 1_000; else estimate -= 1_000;
            if (t.kind == Kind.TIMEOUT_CANCELLED && exampleCancelled == null && i > trials / 2) exampleCancelled = t;
            if ((t.kind == Kind.TIMEOUT_DISCARDED_COMPLETION || t.kind == Kind.OTHER) && printed < 6) {
                printed++;
                System.out.println("[" + t.kind + "] trial " + t.index
                        + ": attempt#1 recorded as " + t.attempt1
                        + " | Future#1 = " + t.future1
                        + " | callable returned " + us(t.lateNanos) + " after (submit + limit)"
                        + ", worker interrupted=" + t.workerInterrupted
                        + " | callable executions=" + t.executions + " (bodies completed=" + t.completedBodies + ")"
                        + " | attempts seen by listener=" + t.attemptsSeen
                        + " | Retryer.call() " + t.callOutcome);
            }
        }
        if (exampleCancelled != null) {
            Trial t = exampleCancelled;
            System.out.println("[control TIMEOUT_CANCELLED] trial " + t.index
                    + ": attempt#1 recorded as " + t.attempt1
                    + " | Future#1 = " + t.future1
                    + " | callable returned " + us(t.lateNanos) + " after (submit + limit)"
                    + ", worker interrupted=" + t.workerInterrupted
                    + " | callable executions=" + t.executions + " (bodies completed=" + t.completedBodies + ")"
                    + " | Retryer.call() " + t.callOutcome);
        }
        System.out.println("summary " + cfg.name + ":");
        for (Kind k : Kind.values()) {
            System.out.println("  " + String.format("%-31s", k) + " " + String.format("%5d", counts[k.ordinal()])
                    + "   callable return time vs (submit + limit): " + stats(late.get(k.ordinal())));
        }
        System.out.println("visible outcome per kind (what Retryer's caller and listeners can observe):");
        for (Kind k : Kind.values()) {
            for (java.util.Map.Entry<String, Integer> e : visible.get(k.ordinal()).entrySet()) {
                System.out.println("  " + String.format("%-31s", k) + " x" + e.getValue() + "  " + e.getKey());
            }
        }
        return counts[Kind.TIMEOUT_DISCARDED_COMPLETION.ordinal()];
    }

    public static void main(String[] args) throws Exception {
        int trials = Integer.parseInt(args[0]);
        System.out.println("java.version=" + System.getProperty("java.version") + " vm=" + System.getProperty("java.vm.name")
                + " cpus=" + Runtime.getRuntime().availableProcessors());
        ExecutorService pool = Executors.newCachedThreadPool(r -> { Thread th = new Thread(r, "attempt-worker"); th.setDaemon(true); return th; });
        int hitsA = runConfig(build("A: retryIfException() + stopAfterAttempt(2)", true, pool), trials, 1);
        int hitsB = runConfig(build("B: default rejection predicate (no retry)", false, pool), trials, 2);
        pool.shutdownNow();
        System.out.println();
        System.out.println("RESULT: TIMEOUT_DISCARDED_COMPLETION hits: config A=" + hitsA + ", config B=" + hitsB);
        System.out.println(hitsA + hitsB > 0 ? "MC3_DISCARDED_COMPLETION_OBSERVED" : "MC3_NOT_OBSERVED");
        System.exit(hitsA + hitsB > 0 ? 0 : 1);
    }
}
JAVA

echo "== compile repro (--release 11)"
"$JDK21/bin/javac" --release 11 -d "$B/test" -cp "$B/lib:$GUAVA_JAR:$JSR305_JAR" "$B/test/MC3Repro.java"

CP="$B/test:$B/lib:$GUAVA_JAR:$JSR305_JAR"
observed=0
for JH in "$JDK21" "$JDK11"; do
  [ -x "$JH/bin/java" ] || { echo "skip $JH (no java)"; continue; }
  echo
  echo "================ run on $JH"
  set +e
  timeout 300 "$JH/bin/java" -cp "$CP" MC3Repro "$TRIALS"
  rc=$?
  set -e
  echo "exit code on $(basename "$JH"): $rc"
  [ "$rc" -eq 0 ] && observed=1
done
echo
if [ "$observed" -eq 1 ]; then echo "OVERALL: MC-3 path observed (completed attempt recorded as timeout)"; exit 0; fi
echo "OVERALL: MC-3 path not observed"; exit 1
