#!/usr/bin/env bash
# CR-D-20 reproduction: WaitStrategies.incrementingWait overflows
#   initialSleepTime + increment * (attemptNumber - 1)
# (WaitStrategies.java:282) for increments near Long.MAX_VALUE; the negative
# result is clamped to 0 (WaitStrategies.java:283), so Retryer.call
# (Retryer.java:176-178) sleeps 1000, 0, 998, 0, 996 ms ... instead of
# "incrementing amounts of time after each additional failed attempt".
#
# Escalation level: 0 (pure black-box). The test class lives in its own
# package and uses only the public API: RetryerBuilder, WaitStrategies,
# StopStrategies, BlockStrategies/BlockStrategy, Retryer.call, Attempt,
# RetryException. No library source is modified; no state is injected.
#
# Scenarios
#   A  finding's exact config, DEFAULT block strategy (Thread.sleep):
#      incrementingWait(1000, MILLISECONDS, Long.MAX_VALUE, MILLISECONDS),
#      stopAfterAttempt(6); wall-clock gaps between callable invocations.
#   B  saturating unit conversion incrementingWait(1, SECONDS, Long.MAX_VALUE, DAYS)
#      (DAYS.toMillis(Long.MAX_VALUE) saturates to Long.MAX_VALUE); a user
#      BlockStrategy records the sleep Retryer.call requests, then delegates to
#      the built-in BlockStrategies.threadSleepStrategy() (it really sleeps).
#   C  positive control: incrementingWait(100 ms, +100 ms) -> 100,200,300,400,500.
#   D  supplementary: public WaitStrategy.computeSleepTime(Attempt) table vs the
#      Javadoc formula evaluated exactly (BigInteger).
#
# Oracle: for a non-negative increment the factory Javadoc promises
# "incrementing amounts of time after each additional failed attempt"
# (@param increment "added to the previous sleep time after each failed
# attempt"), i.e. sleep(n+1) >= sleep(n). A decrease / a 0 ms retry after a
# 1000 ms one violates it. If the strategy behaved as documented, the sleep
# after attempt 2 would be >= 1000 + Long.MAX_VALUE ms, so scenarios A/B run in
# a background thread with a bounded budget and report NOT REPRODUCED if the
# retryer is still sleeping.
#
# Exit status: 0 = bug reproduced (A and B) with control C behaving;
#              1 = bug NOT reproduced; 2 = harness / control failure.
set -euo pipefail

SRC="${GUAVA_RETRYING_SRC:-/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-20/worktree}"
GUAVA_JAR="${GUAVA_JAR:-$HOME/.m2/repository/com/google/guava/guava/22.0/guava-22.0.jar}"
JSR305_JAR="${JSR305_JAR:-$HOME/.m2/repository/com/google/code/findbugs/jsr305/2.0.2/jsr305-2.0.2.jar}"
JAVAC="${JAVAC:-javac}"
JAVA="${JAVA:-java}"

for f in "$GUAVA_JAR" "$JSR305_JAR"; do
  [ -f "$f" ] || { echo "missing dependency jar: $f" >&2; exit 2; }
done
[ -f "$SRC/src/main/java/com/github/rholder/retry/WaitStrategies.java" ] || { echo "missing source tree: $SRC" >&2; exit 2; }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/crd20.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/lib-classes" "$WORK/test-src/reprocrd20" "$WORK/test-classes"

echo "== source: $SRC"
if git -C "$SRC" rev-parse HEAD >/dev/null 2>&1; then
  echo "== source HEAD: $(git -C "$SRC" rev-parse HEAD)  dirty-files: $(git -C "$SRC" status --porcelain | wc -l)"
fi
echo "== $("$JAVAC" -version 2>&1)  guava: $(basename "$GUAVA_JAR")  jsr305: $(basename "$JSR305_JAR")"

# 1. Compile the unmodified library sources.
find "$SRC/src/main/java" -name '*.java' > "$WORK/lib-sources.txt"
"$JAVAC" --release 8 -nowarn -Xlint:none -cp "$GUAVA_JAR:$JSR305_JAR" -d "$WORK/lib-classes" @"$WORK/lib-sources.txt" 2>&1 | grep -v '^Note:' || true
[ -f "$WORK/lib-classes/com/github/rholder/retry/WaitStrategies.class" ] || { echo "library compile failed" >&2; exit 2; }

# 2. The black-box test (separate package => public API only).
cat > "$WORK/test-src/reprocrd20/ReproCRD20.java" <<'JAVA'
package reprocrd20;

import com.github.rholder.retry.Attempt;
import com.github.rholder.retry.BlockStrategies;
import com.github.rholder.retry.BlockStrategy;
import com.github.rholder.retry.RetryException;
import com.github.rholder.retry.Retryer;
import com.github.rholder.retry.RetryerBuilder;
import com.github.rholder.retry.StopStrategies;
import com.github.rholder.retry.WaitStrategies;
import com.github.rholder.retry.WaitStrategy;
import com.google.common.base.Predicates;

import java.math.BigInteger;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

public final class ReproCRD20 {

    /** User BlockStrategy: records the requested sleep, then really sleeps via the built-in strategy. */
    static final class RecordingBlockStrategy implements BlockStrategy {
        final List<Long> requested = Collections.synchronizedList(new ArrayList<Long>());

        @Override
        public void block(long sleepTime) throws InterruptedException {
            requested.add(sleepTime);
            BlockStrategies.threadSleepStrategy().block(sleepTime);
        }
    }

    static final class Run {
        final List<Long> attemptNanos = Collections.synchronizedList(new ArrayList<Long>());
        RecordingBlockStrategy recorder;
        boolean finished;
        Object outcome;

        List<Long> gapsMs() {
            List<Long> g = new ArrayList<Long>();
            synchronized (attemptNanos) {
                for (int i = 1; i < attemptNanos.size(); i++) {
                    g.add(TimeUnit.NANOSECONDS.toMillis(attemptNanos.get(i) - attemptNanos.get(i - 1)));
                }
            }
            return g;
        }
    }

    static Run run(WaitStrategy wait, int maxAttempts, boolean recordBlock, long budgetMs) throws Exception {
        final Run r = new Run();
        RetryerBuilder<Boolean> b = RetryerBuilder.<Boolean>newBuilder()
                .retryIfResult(Predicates.equalTo(Boolean.FALSE))      // every attempt "fails"
                .withWaitStrategy(wait)
                .withStopStrategy(StopStrategies.stopAfterAttempt(maxAttempts));
        if (recordBlock) {
            r.recorder = new RecordingBlockStrategy();
            b.withBlockStrategy(r.recorder);
        }
        final Retryer<Boolean> retryer = b.build();
        final Callable<Boolean> callable = new Callable<Boolean>() {
            @Override
            public Boolean call() {
                r.attemptNanos.add(System.nanoTime());
                return Boolean.FALSE;
            }
        };
        ExecutorService ex = Executors.newSingleThreadExecutor();
        try {
            Future<Object> f = ex.submit(new Callable<Object>() {
                @Override
                public Object call() throws Exception {
                    try {
                        return "returned " + retryer.call(callable);
                    } catch (RetryException e) {
                        return "RetryException(numberOfFailedAttempts=" + e.getNumberOfFailedAttempts() + ")";
                    } catch (ExecutionException e) {
                        return "ExecutionException(" + e.getCause() + ")";
                    }
                }
            });
            try {
                r.outcome = f.get(budgetMs, TimeUnit.MILLISECONDS);
                r.finished = true;
            } catch (TimeoutException te) {
                r.finished = false;
                f.cancel(true);
            }
        } finally {
            ex.shutdownNow();
            ex.awaitTermination(5, TimeUnit.SECONDS);
        }
        return r;
    }

    /** Javadoc-specified sleep after failed attempt n: initial + (n-1)*increment, evaluated exactly. */
    static String documented(long initial, long increment, long n) {
        BigInteger v = BigInteger.valueOf(initial).add(BigInteger.valueOf(increment).multiply(BigInteger.valueOf(n - 1)));
        if (v.compareTo(BigInteger.valueOf(Long.MAX_VALUE)) > 0) {
            return v + " (> Long.MAX_VALUE; saturated: " + Long.MAX_VALUE + ")";
        }
        return v.toString();
    }

    static boolean nonDecreasing(List<Long> xs) {
        for (int i = 1; i < xs.size(); i++) {
            if (xs.get(i) < xs.get(i - 1)) return false;
        }
        return true;
    }

    /** Minimal public-interface Attempt for the supplementary unit-level table (scenario D). */
    static Attempt<Boolean> failed(final long n) {
        return new Attempt<Boolean>() {
            public Boolean get() throws ExecutionException { throw new ExecutionException(new RuntimeException("fail")); }
            public boolean hasResult() { return false; }
            public boolean hasException() { return true; }
            public Boolean getResult() throws IllegalStateException { throw new IllegalStateException(); }
            public Throwable getExceptionCause() throws IllegalStateException { return new RuntimeException("fail"); }
            public long getAttemptNumber() { return n; }
            public long getDelaySinceFirstAttempt() { return 0L; }
        };
    }

    public static void main(String[] args) throws Exception {
        final long M = Long.MAX_VALUE;
        System.out.println("TimeUnit.DAYS.toMillis(Long.MAX_VALUE) = " + TimeUnit.DAYS.toMillis(M) + "  (saturates)");

        // ---------------- Scenario A ----------------
        System.out.println();
        System.out.println("[A] Retryer.call with DEFAULT block strategy (Thread.sleep), "
                + "incrementingWait(1000, MILLISECONDS, Long.MAX_VALUE, MILLISECONDS), stopAfterAttempt(6)");
        long t0 = System.nanoTime();
        Run a = run(WaitStrategies.incrementingWait(1000L, TimeUnit.MILLISECONDS, M, TimeUnit.MILLISECONDS), 6, false, 30000L);
        System.out.println("    finished=" + a.finished + " outcome=" + a.outcome + " attempts=" + a.attemptNanos.size()
                + " wall=" + TimeUnit.NANOSECONDS.toMillis(System.nanoTime() - t0) + "ms");
        List<Long> ga = a.gapsMs();
        for (int i = 0; i < ga.size(); i++) {
            System.out.println("    gap attempt " + (i + 1) + " -> " + (i + 2) + ": observed " + ga.get(i)
                    + " ms   documented sleep: " + documented(1000L, M, i + 1) + " ms");
        }
        boolean aBug = a.finished && ga.size() >= 2 && ga.get(0) >= 900L && ga.get(1) < 100L;
        System.out.println("    A: " + (aBug
                ? "BUG -> attempt 3 ran " + ga.get(1) + " ms after attempt 2 (immediate retry) although the first wait was "
                  + ga.get(0) + " ms; waits are not incrementing"
                : (a.finished ? "not triggered (gaps " + ga + ")" : "not triggered: retryer still sleeping after attempt "
                  + a.attemptNanos.size() + " (documented behavior)")));

        // ---------------- Scenario B ----------------
        System.out.println();
        System.out.println("[B] Retryer.call, incrementingWait(1, SECONDS, Long.MAX_VALUE, DAYS), stopAfterAttempt(6), "
                + "recording BlockStrategy delegating to BlockStrategies.threadSleepStrategy()");
        Run bRun = run(WaitStrategies.incrementingWait(1L, TimeUnit.SECONDS, M, TimeUnit.DAYS), 6, true, 30000L);
        System.out.println("    finished=" + bRun.finished + " outcome=" + bRun.outcome + " attempts=" + bRun.attemptNanos.size());
        System.out.println("    sleeps requested by Retryer.call : " + bRun.recorder.requested);
        System.out.println("    observed gaps between attempts   : " + bRun.gapsMs() + " ms");
        boolean bBug = bRun.finished && !nonDecreasing(bRun.recorder.requested) && bRun.recorder.requested.contains(0L);
        System.out.println("    B: " + (bBug ? "BUG -> requested sleeps decrease and include 0 ms (immediate retries)"
                : "not triggered"));

        // ---------------- Scenario C (control) ----------------
        System.out.println();
        System.out.println("[C] control: incrementingWait(100, MILLISECONDS, 100, MILLISECONDS), stopAfterAttempt(6)");
        Run c = run(WaitStrategies.incrementingWait(100L, TimeUnit.MILLISECONDS, 100L, TimeUnit.MILLISECONDS), 6, true, 30000L);
        System.out.println("    finished=" + c.finished + " outcome=" + c.outcome);
        System.out.println("    sleeps requested by Retryer.call : " + c.recorder.requested);
        System.out.println("    observed gaps between attempts   : " + c.gapsMs() + " ms");
        boolean cOk = c.finished && c.recorder.requested.equals(java.util.Arrays.asList(100L, 200L, 300L, 400L, 500L))
                && nonDecreasing(c.recorder.requested);
        System.out.println("    C: " + (cOk ? "OK (incrementing as documented)" : "CONTROL FAILED"));

        // ---------------- Scenario D (supplementary) ----------------
        System.out.println();
        System.out.println("[D] public WaitStrategy.computeSleepTime(Attempt) for incrementingWait(1000 ms, +Long.MAX_VALUE ms)");
        WaitStrategy w = WaitStrategies.incrementingWait(1000L, TimeUnit.MILLISECONDS, M, TimeUnit.MILLISECONDS);
        long[] ns = {1, 2, 3, 4, 5, 6, 7, 999, 1000, 1001, 1002, 1003};
        for (long n : ns) {
            System.out.println("    attempt " + n + ": computeSleepTime=" + w.computeSleepTime(failed(n))
                    + "   documented=" + documented(1000L, M, n));
        }

        System.out.println();
        if (!cOk) {
            System.out.println("RESULT: HARNESS/CONTROL FAILURE");
            System.exit(2);
        }
        if (aBug && bBug) {
            System.out.println("RESULT: BUG REPRODUCED (CR-D-20) - incrementingWait yields decreasing sleeps "
                    + "alternating with 0 ms immediate retries for an increment near Long.MAX_VALUE");
            System.exit(0);
        }
        System.out.println("RESULT: NOT REPRODUCED");
        System.exit(1);
    }
}
JAVA

"$JAVAC" --release 8 -nowarn -cp "$WORK/lib-classes:$GUAVA_JAR:$JSR305_JAR" -d "$WORK/test-classes" \
  "$WORK/test-src/reprocrd20/ReproCRD20.java"

# 3. Run (bounded).
set +e
timeout 120 "$JAVA" -cp "$WORK/test-classes:$WORK/lib-classes:$GUAVA_JAR:$JSR305_JAR" reprocrd20.ReproCRD20
rc=$?
set -e
echo "== exit status: $rc"
exit $rc
