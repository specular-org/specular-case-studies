#!/usr/bin/env bash
# CR-D-18 reproduction: `WaitStrategies.exceptionWait(E.class, fn)` whose `fn` returns null makes
# `Retryer.call()` throw a raw NullPointerException (auto-unboxing at WaitStrategies.java:390,
# computed outside the attempt's try/catch at Retryer.java:176).
#
# Escalation level: 0 (pure black box). Only public API is used: RetryerBuilder, WaitStrategies,
# StopStrategies, RetryListener, Retryer.call, Retryer.wrap. No sleeps, no state injection, no
# source modification. The library is compiled unmodified from the target checkout.
#
# Usage:  test_bugCR-D-18_exceptionwait_null_npe.sh [SOURCE_REPO] [GUAVA_JAR] [JSR305_JAR]
# Exit:   0 = bug reproduced (every bug scenario escaped as NPE, every control behaved as documented)
#         1 = bug NOT reproduced (library behaved as documented)
#         2 = build/environment error
#         3 = harness error (a control scenario misbehaved, so the result is not interpretable)
set -euo pipefail

SRC_REPO="${1:-/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-18/worktree}"
GUAVA_JAR="${2:-$HOME/.m2/repository/com/google/guava/guava/22.0/guava-22.0.jar}"
JSR305_JAR="${3:-$HOME/.m2/repository/com/google/code/findbugs/jsr305/2.0.2/jsr305-2.0.2.jar}"

for f in "$GUAVA_JAR" "$JSR305_JAR" "$SRC_REPO/src/main/java/com/github/rholder/retry/Retryer.java"; do
  [ -e "$f" ] || { echo "missing: $f" >&2; exit 2; }
done

WORK="$(mktemp -d /tmp/crd18-repro.XXXXXX)"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/classes" "$WORK/test"

echo "== environment"
echo "source repo : $SRC_REPO"
echo "source HEAD : $(git -C "$SRC_REPO" rev-parse HEAD 2>/dev/null || echo unknown)"
echo "source dirty: $(git -C "$SRC_REPO" status --porcelain -- src 2>/dev/null | wc -l) changed file(s) under src/"
echo "guava jar   : $GUAVA_JAR"
echo "jsr305 jar  : $JSR305_JAR"
java -version 2>&1 | head -1
echo "Retryer.java:176        |$(sed -n '176p' "$SRC_REPO/src/main/java/com/github/rholder/retry/Retryer.java")"
echo "WaitStrategies.java:390 |$(sed -n '390p' "$SRC_REPO/src/main/java/com/github/rholder/retry/WaitStrategies.java")"
echo

cat > "$WORK/test/CRD18Repro.java" <<'JAVA'
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
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

public class CRD18Repro {

    /** HTTP-style failure; the Retry-After header is optional in HTTP, so the hint may be absent (null). */
    static final class HttpStatusException extends IOException {
        private final Long retryAfterMillis;

        HttpStatusException(int status, Long retryAfterMillis) {
            super("HTTP " + status);
            this.retryAfterMillis = retryAfterMillis;
        }

        Long getRetryAfterMillis() {
            return retryAfterMillis;
        }
    }

    /** Transient failure: throws once, then succeeds with "OK". Counts invocations. */
    static final class FlakyCall implements Callable<String> {
        final AtomicInteger invocations = new AtomicInteger();
        private final Exception firstFailure;

        FlakyCall(Exception firstFailure) {
            this.firstFailure = firstFailure;
        }

        @Override
        public String call() throws Exception {
            if (invocations.incrementAndGet() == 1) {
                throw firstFailure;
            }
            return "OK";
        }
    }

    static final class RecordingListener implements RetryListener {
        final List<String> seen = Collections.synchronizedList(new ArrayList<String>());

        @Override
        public <V> void onRetry(Attempt<V> attempt) {
            seen.add("#" + attempt.getAttemptNumber()
                    + (attempt.hasException() ? " threw " + attempt.getExceptionCause() : " returned " + attempt.getResult()));
        }
    }

    /** Outcome of one call as seen by an application coded against Retryer.call's Javadoc. */
    static final class Outcome {
        String kind;          // RETURNED | EXECUTION_EXCEPTION | RETRY_EXCEPTION | ESCAPED
        String detail;
        Throwable escaped;    // set when an exception escaped the documented handlers
    }

    /**
     * A caller written against the documented contract of Retryer.call(): it handles the return value,
     * ExecutionException and RetryException. Anything else escapes to our outer catch and is recorded.
     */
    static Outcome documentedContractCaller(Retryer<String> retryer, Callable<String> callable) {
        Outcome o = new Outcome();
        try {
            try {
                String v = retryer.call(callable);
                o.kind = "RETURNED";
                o.detail = "value=" + v;
            } catch (ExecutionException e) {
                o.kind = "EXECUTION_EXCEPTION";
                o.detail = "cause=" + e.getCause();
            } catch (RetryException e) {
                o.kind = "RETRY_EXCEPTION";
                o.detail = "attempts=" + e.getNumberOfFailedAttempts() + " cause=" + e.getCause();
            }
        } catch (Throwable t) {
            o.kind = "ESCAPED";
            o.detail = t.toString();
            o.escaped = t;
        }
        return o;
    }

    static void printEscape(Throwable t) {
        System.out.println("    escaped type   : " + t.getClass().getName());
        System.out.println("    message        : " + t.getMessage());
        System.out.println("    getCause()     : " + t.getCause());
        StackTraceElement[] st = t.getStackTrace();
        for (int i = 0; i < Math.min(4, st.length); i++) {
            System.out.println("    at " + st[i]);
        }
    }

    static int failures = 0;      // bug expectations not met
    static int harnessErrors = 0; // control expectations not met

    static void expectBug(String what, boolean ok) {
        System.out.println("  [" + (ok ? "BUG-CONFIRMED" : "BUG-NOT-SEEN") + "] " + what);
        if (!ok) failures++;
    }

    static void expectControl(String what, boolean ok) {
        System.out.println("  [" + (ok ? "CONTROL-OK" : "CONTROL-FAILED") + "] " + what);
        if (!ok) harnessErrors++;
    }

    static boolean isUnboxingNpeFromExceptionWait(Throwable t) {
        if (!(t instanceof NullPointerException)) return false;
        StackTraceElement[] st = t.getStackTrace();
        boolean inWait = false, inCall = false;
        for (StackTraceElement e : st) {
            if (e.getClassName().equals("com.github.rholder.retry.WaitStrategies$ExceptionWaitStrategy")
                    && e.getMethodName().equals("computeSleepTime")) inWait = true;
            if (e.getClassName().equals("com.github.rholder.retry.Retryer")
                    && e.getMethodName().equals("call")) inCall = true;
        }
        return inWait && inCall;
    }

    public static void main(String[] args) throws Exception {
        // ---------------------------------------------------------------------------------------------
        // Scenario 1: one Retryer, HTTP Retry-After driven backoff. The function returns the optional
        // header value as-is (Guava 22 Function.apply is declared @Nullable).
        // ---------------------------------------------------------------------------------------------
        Function<HttpStatusException, Long> retryAfter = new Function<HttpStatusException, Long>() {
            @Override
            public Long apply(HttpStatusException e) {
                return e.getRetryAfterMillis(); // null when the server sent no Retry-After header
            }
        };
        RecordingListener listener1 = new RecordingListener();
        Retryer<String> retryer1 = RetryerBuilder.<String>newBuilder()
                .retryIfExceptionOfType(IOException.class)
                .withWaitStrategy(WaitStrategies.exceptionWait(HttpStatusException.class, retryAfter))
                .withStopStrategy(StopStrategies.stopAfterAttempt(3))
                .withRetryListener(listener1)
                .build();

        System.out.println("== Scenario 1a (control): HTTP 429 WITH Retry-After: 20 ms, then success");
        FlakyCall c1a = new FlakyCall(new HttpStatusException(429, 20L));
        Outcome o1a = documentedContractCaller(retryer1, c1a);
        System.out.println("  outcome=" + o1a.kind + " " + o1a.detail + " | callable invocations=" + c1a.invocations.get()
                + " | listener saw " + listener1.seen);
        expectControl("same Retryer returns OK on attempt 2 when the function yields a non-null wait",
                "RETURNED".equals(o1a.kind) && "value=OK".equals(o1a.detail) && c1a.invocations.get() == 2);

        listener1.seen.clear();
        System.out.println("== Scenario 1b (bug): HTTP 503 WITHOUT Retry-After (function returns null), then success");
        FlakyCall c1b = new FlakyCall(new HttpStatusException(503, null));
        Outcome o1b = documentedContractCaller(retryer1, c1b);
        System.out.println("  outcome=" + o1b.kind + " " + o1b.detail + " | callable invocations=" + c1b.invocations.get()
                + " | listener saw " + listener1.seen);
        if (o1b.escaped != null) printEscape(o1b.escaped);
        expectBug("call() let an exception escape the documented handlers (not a value / ExecutionException / RetryException)",
                "ESCAPED".equals(o1b.kind));
        expectBug("escaped exception is the unboxing NPE raised in ExceptionWaitStrategy.computeSleepTime under Retryer.call",
                o1b.escaped != null && isUnboxingNpeFromExceptionWait(o1b.escaped));
        expectBug("attempt #1 had already run and been reported to the listener before the NPE",
                listener1.seen.size() == 1 && listener1.seen.get(0).startsWith("#1 threw"));
        expectBug("retrying was abandoned after 1 attempt although stopAfterAttempt(3) allowed more and attempt #2 would succeed",
                c1b.invocations.get() == 1);
        expectBug("the attempt's real failure (HttpStatusException: HTTP 503) is not attached to the escaped exception",
                o1b.escaped != null && o1b.escaped.getCause() == null);

        // ---------------------------------------------------------------------------------------------
        // Scenario 2: composite wait via join(), neverStop(), lambda doing a Map lookup that misses.
        // ---------------------------------------------------------------------------------------------
        final Map<String, Long> backoffByMessage = new HashMap<String, Long>();
        backoffByMessage.put("HTTP 429", 50L);
        WaitStrategy joined = WaitStrategies.join(
                WaitStrategies.fixedWait(1, TimeUnit.MILLISECONDS),
                WaitStrategies.exceptionWait(IOException.class, (IOException e) -> backoffByMessage.get(e.getMessage())));
        Retryer<String> retryer2 = RetryerBuilder.<String>newBuilder()
                .retryIfExceptionOfType(IOException.class)
                .withWaitStrategy(joined)
                .withStopStrategy(StopStrategies.neverStop())
                .build();

        System.out.println("== Scenario 2a (control): join(fixedWait, exceptionWait(map lookup hit)), neverStop");
        FlakyCall c2a = new FlakyCall(new IOException("HTTP 429"));
        Outcome o2a = documentedContractCaller(retryer2, c2a);
        System.out.println("  outcome=" + o2a.kind + " " + o2a.detail + " | callable invocations=" + c2a.invocations.get());
        expectControl("joined strategy returns OK on attempt 2 when the lookup hits",
                "RETURNED".equals(o2a.kind) && c2a.invocations.get() == 2);

        System.out.println("== Scenario 2b (bug): same Retryer, IOException(\"connection reset\") -> lookup miss -> null");
        FlakyCall c2b = new FlakyCall(new IOException("connection reset"));
        Outcome o2b = documentedContractCaller(retryer2, c2b);
        System.out.println("  outcome=" + o2b.kind + " " + o2b.detail + " | callable invocations=" + c2b.invocations.get());
        if (o2b.escaped != null) printEscape(o2b.escaped);
        expectBug("NPE escapes call() through CompositeWaitStrategy; a neverStop() retryer gave up after 1 attempt",
                "ESCAPED".equals(o2b.kind) && isUnboxingNpeFromExceptionWait(o2b.escaped) && c2b.invocations.get() == 1);

        // ---------------------------------------------------------------------------------------------
        // Scenario 3: Retryer.wrap() submitted to an executor (RetryerCallable declares
        // `throws ExecutionException, RetryException`).
        // ---------------------------------------------------------------------------------------------
        System.out.println("== Scenario 3 (bug): retryer1.wrap(callable) on an ExecutorService, HTTP 503 without Retry-After");
        ExecutorService pool = Executors.newSingleThreadExecutor();
        try {
            FlakyCall c3 = new FlakyCall(new HttpStatusException(503, null));
            Future<String> f = pool.submit(retryer1.wrap(c3));
            Throwable futureCause = null;
            String value = null;
            try {
                value = f.get(30, TimeUnit.SECONDS);
            } catch (ExecutionException e) {
                futureCause = e.getCause();
            }
            System.out.println("  future value=" + value + " | future failure cause=" + futureCause
                    + " | callable invocations=" + c3.invocations.get());
            expectBug("Future fails with the unboxing NPE instead of a RetryException / the callable's exception",
                    futureCause != null && isUnboxingNpeFromExceptionWait(futureCause) && c3.invocations.get() == 1);
        } finally {
            pool.shutdownNow();
        }

        System.out.println();
        if (harnessErrors > 0) {
            System.out.println("RESULT: HARNESS ERROR (" + harnessErrors + " control expectation(s) failed)");
            System.exit(3);
        }
        if (failures > 0) {
            System.out.println("RESULT: BUG NOT REPRODUCED (" + failures + " bug expectation(s) not met)");
            System.exit(1);
        }
        System.out.println("RESULT: BUG REPRODUCED -- exceptionWait function returning null makes Retryer.call() throw an "
                + "undocumented NullPointerException after the attempt ran, abandoning the retry and dropping the failure cause");
        System.exit(0);
    }
}
JAVA

echo "== build (library sources compiled unmodified from the target checkout, --release 8, Guava 22.0)"
CP="$GUAVA_JAR:$JSR305_JAR"
find "$SRC_REPO/src/main/java" -name '*.java' > "$WORK/sources.txt"
if ! javac --release 8 -Xlint:-options -nowarn -encoding UTF-8 -cp "$CP" -d "$WORK/classes" @"$WORK/sources.txt" "$WORK/test/CRD18Repro.java" > "$WORK/javac.log" 2>&1; then
  cat "$WORK/javac.log"; echo "BUILD FAILED"; exit 2
fi
grep -v -E '^Note: ' "$WORK/javac.log" || true
echo "compiled $(wc -l < "$WORK/sources.txt") library source files + CRD18Repro.java"
echo

echo "== run"
set +e
java -cp "$WORK/classes:$CP" CRD18Repro
rc=$?
set -e
echo "exit code: $rc"
exit $rc
