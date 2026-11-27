#!/usr/bin/env bash
# CR-D-12 reproduction — guava-retrying 2.0.0 + Guava 22.0
#
# Claim: with AttemptTimeLimiters.fixedTimeLimit, every failed attempt goes through
#   AttemptTimeLimiters.java:107  timeLimiter.callWithTimeout(callable, duration, timeUnit, true)
#   SimpleTimeLimiter.java:162-163 throw throwCause(e, true /* combineStackTraces */)
#   SimpleTimeLimiter.java:256-259 cause.setStackTrace(concat(cause.getStackTrace(), e.getStackTrace()))
# which rewrites the stack trace of the very exception object the callable threw, appending the
# caller thread's stack. When the callable throws a reused exception object, the trace grows by
# one caller stack per failed attempt, forever (memory, CPU, log volume); noTimeLimit does not.
#
# Escalation level: 0 (public API only: RetryerBuilder / AttemptTimeLimiters / Retryer.call /
# Retryer.wrap / RetryListener). No source change, no sleeps, no failpoints, no state injection.
# The only "instrumentation" is a user exception subclass in scenario [attribution] that records
# who calls its setStackTrace(); the library is untouched.
#
# Scenarios (each in its own JVM so static exceptions start fresh):
#   growth       README-quickstart retryer, static sentinel / cached "cheap" exception, listener +
#                caller log every failure; control = noTimeLimit; both fixedTimeLimit factories;
#                mitigation check: a writableStackTrace=false exception is not modified
#   cf           CompletableFuture.join() on a memoised failed future (JDK rethrows the same object)
#   paths        predicate-accepted (ExecutionException) path, Retryer.wrap() on an executor,
#                builder defaults (neverStop) within one call()
#   attribution  who mutates the exception (TracingIOException overrides setStackTrace)
#   oom          bounded heap (-Xmx32m), caller at depth 100: reused exception -> OutOfMemoryError;
#                controls: noTimeLimit + reused exception, fixedTimeLimit + fresh exceptions
#   JDK 11 cross-check of growth/attribution
#
# Exit status: 0 = bug triggered (PASS), 1 = not triggered, 2 = setup error.
# Usage: bash test_bugCR-D-12_reused_exception_stack_growth.sh   (env overrides: WORKTREE, GUAVA_JAR,
#        JSR305_JAR, JAVA_HOME_21, JAVA_HOME_11, KEEP_BUILD=1)
set -uo pipefail

WORKTREE=${WORKTREE:-/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-12/worktree}
GUAVA_JAR=${GUAVA_JAR:-$HOME/.m2/repository/com/google/guava/guava/22.0/guava-22.0.jar}
JSR305_JAR=${JSR305_JAR:-$HOME/.m2/repository/com/google/code/findbugs/jsr305/2.0.2/jsr305-2.0.2.jar}
JAVA_HOME_21=${JAVA_HOME_21:-/usr/lib/jvm/java-21-openjdk-amd64}
JAVA_HOME_11=${JAVA_HOME_11:-/usr/lib/jvm/java-11-openjdk-amd64}

for f in "$GUAVA_JAR" "$JSR305_JAR" "$JAVA_HOME_21/bin/javac" "$WORKTREE/src/main/java/com/github/rholder/retry/AttemptTimeLimiters.java"; do
  [ -e "$f" ] || { echo "SETUP ERROR: missing $f"; exit 2; }
done

BUILD=$(mktemp -d /tmp/crd12-build.XXXXXX)
[ "${KEEP_BUILD:-0}" = 1 ] || trap 'rm -rf "$BUILD"' EXIT
mkdir -p "$BUILD/lib" "$BUILD/src" "$BUILD/cls"

echo "== provenance"
echo "worktree HEAD: $(git -C "$WORKTREE" rev-parse HEAD 2>/dev/null) ($(git -C "$WORKTREE" describe --tags --always 2>/dev/null)); dirty files: $(git -C "$WORKTREE" status --porcelain 2>/dev/null | wc -l)"
echo "guava jar:  $GUAVA_JAR sha1=$(sha1sum "$GUAVA_JAR" | cut -d' ' -f1)"
echo "jsr305 jar: $JSR305_JAR sha1=$(sha1sum "$JSR305_JAR" | cut -d' ' -f1)"
echo "AttemptTimeLimiters.java:107 => $(sed -n '107p' "$WORKTREE/src/main/java/com/github/rholder/retry/AttemptTimeLimiters.java" | sed 's/^ *//')"
"$JAVA_HOME_21/bin/java" -version 2>&1 | head -1

echo "== build guava-retrying (unmodified worktree sources, --release 8)"
CP="$GUAVA_JAR:$JSR305_JAR"
timeout 300 "$JAVA_HOME_21/bin/javac" --release 8 -nowarn -g -encoding UTF-8 -d "$BUILD/lib" -cp "$CP" \
  $(find "$WORKTREE/src/main/java" -name '*.java') 2>&1 | grep -v '^Note:' || true
[ -f "$BUILD/lib/com/github/rholder/retry/AttemptTimeLimiters.class" ] || { echo "SETUP ERROR: library build failed"; exit 2; }

cat > "$BUILD/src/ReproCRD12.java" <<'JAVA'
import com.github.rholder.retry.Attempt;
import com.github.rholder.retry.AttemptTimeLimiters;
import com.github.rholder.retry.RetryException;
import com.github.rholder.retry.RetryListener;
import com.github.rholder.retry.Retryer;
import com.github.rholder.retry.RetryerBuilder;
import com.github.rholder.retry.StopStrategies;

import java.io.IOException;
import java.io.PrintWriter;
import java.io.Writer;
import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.Callable;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CompletionException;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

public class ReproCRD12 {

    // ---- reused exception objects, created the way applications create them ----

    /** Preallocated sentinel thrown whenever the backend is not ready (normal, writable stack trace). */
    static final IOException NOT_READY = new IOException("backend not ready (preallocated sentinel)");

    /** The classic cheap cached exception: fillInStackTrace() is a no-op, but the stack trace stays writable. */
    static final class CheapIOException extends IOException {
        CheapIOException(String m) { super(m); }
        @Override public synchronized Throwable fillInStackTrace() { return this; }
    }
    static final IOException CHEAP = new CheapIOException("backend not ready (cached cheap exception)");

    /** User-side mitigation check: a reused exception built with writableStackTrace=false ignores setStackTrace(). */
    static final class FrozenRuntimeException extends RuntimeException {
        FrozenRuntimeException(String m) { super(m, null, false, false); }   // enableSuppression=false, writableStackTrace=false
    }
    static final RuntimeException FROZEN = new FrozenRuntimeException("backend not ready (writableStackTrace=false)");

    /** Records who rewrites the exception's stack trace; used only to attribute the root cause. */
    static final List<String> SET_STACK_TRACE_CALLERS = Collections.synchronizedList(new ArrayList<String>());
    static final class TracingIOException extends IOException {
        TracingIOException(String m) { super(m); }
        @Override public void setStackTrace(StackTraceElement[] stackTrace) {
            StackTraceElement[] here = new Throwable().getStackTrace();
            SET_STACK_TRACE_CALLERS.add(here.length > 1 ? here[1].toString() : "?");
            super.setStackTrace(stackTrace);
        }
    }

    static final String STL = "com.google.common.util.concurrent.SimpleTimeLimiter";

    static ExecutorService daemonPool(final String name) {
        return Executors.newCachedThreadPool(r -> { Thread t = new Thread(r, name); t.setDaemon(true); return t; });
    }

    /** README quickstart retryer; limiter selects the AttemptTimeLimiter ("none" = library default noTimeLimit()). */
    static <V> RetryerBuilder<V> readmeBuilder(String limiter, ExecutorService pool, int attempts) {
        RetryerBuilder<V> b = RetryerBuilder.<V>newBuilder()
                .retryIfExceptionOfType(IOException.class)
                .retryIfRuntimeException()
                .withStopStrategy(StopStrategies.stopAfterAttempt(attempts));
        return withLimiter(b, limiter, pool);
    }

    static <V> RetryerBuilder<V> withLimiter(RetryerBuilder<V> b, String limiter, ExecutorService pool) {
        if (limiter.equals("none")) return b;
        if (limiter.equals("fixed")) return b.withAttemptTimeLimiter(AttemptTimeLimiters.<V>fixedTimeLimit(5, TimeUnit.SECONDS, pool));
        if (limiter.equals("fixed2")) return b.withAttemptTimeLimiter(AttemptTimeLimiters.<V>fixedTimeLimit(5, TimeUnit.SECONDS));
        throw new IllegalArgumentException(limiter);
    }

    static String label(String limiter) {
        return limiter.equals("none") ? "noTimeLimit (control)"
             : limiter.equals("fixed") ? "fixedTimeLimit(5s, executor)" : "fixedTimeLimit(5s)";
    }

    /** A log sink that only counts characters (stands in for the application's log file). */
    static final class CountingWriter extends Writer {
        long chars;
        @Override public void write(char[] c, int off, int len) { chars += len; }
        @Override public void write(String s, int off, int len) { chars += len; }
        @Override public void flush() { }
        @Override public void close() { }
    }

    static long printedChars(Throwable t) {
        CountingWriter w = new CountingWriter();
        PrintWriter pw = new PrintWriter(w);
        t.printStackTrace(pw);
        pw.flush();
        return w.chars;
    }

    static int frames(Throwable t, String cls, String method) {
        int n = 0;
        for (StackTraceElement e : t.getStackTrace()) {
            if (e.getClassName().equals(cls) && e.getMethodName().equals(method)) n++;
        }
        return n;
    }

    /** Runs body with depth extra frames on the stack (an application's normal call depth). */
    static <T> T atDepth(int depth, Callable<T> body) throws Exception {
        return depth <= 0 ? body.call() : ReproCRD12.<T>atDepth(depth - 1, body);
    }

    // ------------------------------------------------------------------ growth
    static void growth(String limiter, String kind) throws Exception {
        final Exception shared = kind.equals("sentinel") ? NOT_READY : kind.equals("cheap") ? CHEAP : FROZEN;
        ExecutorService pool = daemonPool("time-limiter");
        final CountingWriter log = new CountingWriter();
        final PrintWriter logOut = new PrintWriter(log);
        final long[] lastListenerEntry = {0};
        Retryer<String> retryer = ReproCRD12.<String>readmeBuilder(limiter, pool, 3)
                .withRetryListener(new RetryListener() {
                    @Override public <V> void onRetry(Attempt<V> attempt) {
                        if (attempt.hasException()) {           // a typical listener: log every failed attempt
                            long before = log.chars;
                            logOut.println("WARN attempt " + attempt.getAttemptNumber() + " failed");
                            attempt.getExceptionCause().printStackTrace(logOut);
                            logOut.flush();
                            lastListenerEntry[0] = log.chars - before;
                        }
                    }
                })
                .build();
        Callable<String> callable = () -> { throw shared; };   // the backend keeps failing with the reused exception
        System.out.printf("[growth] limiter=%s exception=%s (%s) initial stackTrace.length=%d%n",
                label(limiter), kind, shared.getClass().getSimpleName(), shared.getStackTrace().length);
        int calls = 0;
        long failedAttempts = 0;
        RetryException last = null;
        for (int checkpoint : new int[] {1, 3, 10, 30, 100, 300}) {
            for (; calls < checkpoint; calls++) {
                try {
                    retryer.call(callable);
                    throw new AssertionError("call() unexpectedly succeeded");
                } catch (RetryException e) {             // README quickstart: catch (RetryException e) { e.printStackTrace(); }
                    if (e.getCause() != shared) throw new AssertionError("RetryException cause is not the callable's exception");
                    last = e;
                    failedAttempts += e.getNumberOfFailedAttempts();
                    e.printStackTrace(logOut);
                    logOut.flush();
                }
            }
            System.out.printf("  after %3d call()s / %3d failed attempts: stackTrace.length=%6d (SimpleTimeLimiter.callWithTimeout frames: %3d)"
                    + "  listener log entry=%9d chars  caller's RetryException.printStackTrace=%9d chars  log total=%,13d chars%n",
                    calls, failedAttempts, shared.getStackTrace().length, frames(shared, STL, "callWithTimeout"),
                    lastListenerEntry[0], printedChars(last), log.chars);
        }
        StackTraceElement[] st = shared.getStackTrace();
        System.out.println("  first frames of the reused exception's stack trace:");
        for (int i = 0; i < Math.min(st.length, 17); i++) System.out.println("    [" + i + "] " + st[i]);
        if (st.length > 17) System.out.println("    ... " + (st.length - 17) + " more frames");
    }

    // ------------------------------------------------------------------ cf
    static void completableFuture(String limiter) throws Exception {
        ExecutorService pool = daemonPool("worker");
        // An asynchronously initialised client whose failure is memoised by the CompletableFuture.
        final CompletableFuture<String> clientInit = CompletableFuture.supplyAsync(() -> {
            throw new IllegalStateException("connection refused");
        }, pool);
        Throwable first = null;
        Throwable second = null;
        try { clientInit.join(); } catch (CompletionException e) { first = e; }
        try { clientInit.join(); } catch (CompletionException e) { second = e; }
        System.out.printf("[cf] limiter=%s  CompletableFuture.join() rethrows the same object on every call: %s  initial stackTrace.length=%d%n",
                label(limiter), first == second, first.getStackTrace().length);
        Retryer<String> retryer = ReproCRD12.<String>readmeBuilder(limiter, pool, 3).build();
        Callable<String> callable = () -> clientInit.join();     // use the client; fails with the memoised exception
        int calls = 0;
        for (int checkpoint : new int[] {1, 10, 100}) {
            for (; calls < checkpoint; calls++) {
                try {
                    retryer.call(callable);
                    throw new AssertionError("unexpected success");
                } catch (RetryException e) {
                    if (e.getCause() != first) throw new AssertionError("a different exception object: " + e.getCause());
                }
            }
            System.out.printf("  after %3d call()s / %3d failed attempts: CompletionException stackTrace.length=%5d (SimpleTimeLimiter.callWithTimeout frames: %3d)%n",
                    calls, calls * 3, first.getStackTrace().length, frames(first, STL, "callWithTimeout"));
        }
    }

    // ------------------------------------------------------------------ paths
    static void paths(String limiter) throws Exception {
        ExecutorService pool = daemonPool("time-limiter");

        // (b) the predicate does not retry this exception: Retryer.call -> attempt.get() -> ExecutionException (Retryer.java:171)
        final IOException notRetried = new IOException("reused, not retried");
        Retryer<String> r1 = withLimiter(RetryerBuilder.<String>newBuilder().retryIfRuntimeException(), limiter, pool).build();
        int before = notRetried.getStackTrace().length;
        for (int i = 0; i < 100; i++) {
            try {
                r1.call(() -> { throw notRetried; });
                throw new AssertionError("unexpected success");
            } catch (ExecutionException e) {
                if (e.getCause() != notRetried) throw new AssertionError("a different exception object");
            }
        }
        System.out.printf("[paths] limiter=%s (b) predicate accepts the exception -> ExecutionException: stackTrace.length %d -> %d after 100 call()s x 1 attempt%n",
                label(limiter), before, notRetried.getStackTrace().length);

        // (d) Retryer.wrap() submitted to an application executor
        final IOException viaWrap = new IOException("reused, via wrap()");
        Retryer<String> r2 = ReproCRD12.<String>readmeBuilder(limiter, pool, 3).build();
        ExecutorService app = daemonPool("app-worker");
        before = viaWrap.getStackTrace().length;
        for (int i = 0; i < 100; i++) {
            try {
                app.submit(r2.wrap(() -> { throw viaWrap; })).get();
                throw new AssertionError("unexpected success");
            } catch (ExecutionException e) {
                if (!(e.getCause() instanceof RetryException) || e.getCause().getCause() != viaWrap) throw new AssertionError(e);
            }
        }
        System.out.printf("[paths] limiter=%s (d) Retryer.wrap() run on an executor: stackTrace.length %d -> %d after 100 call()s x 3 attempts%n",
                label(limiter), before, viaWrap.getStackTrace().length);

        // (e) builder defaults (neverStop, noWait): one call() keeps retrying until the backend recovers
        final IOException untilRecovery = new IOException("reused, until recovery");
        final int[] n = {0};
        Retryer<String> r3 = withLimiter(RetryerBuilder.<String>newBuilder().retryIfException(), limiter, pool).build();
        before = untilRecovery.getStackTrace().length;
        String result = r3.call(() -> {
            if (++n[0] < 2000) throw untilRecovery;
            return "ok";
        });
        System.out.printf("[paths] limiter=%s (e) default neverStop, one call() that succeeds on attempt %d (result=%s): stackTrace.length %d -> %d%n",
                label(limiter), n[0], result, before, untilRecovery.getStackTrace().length);
    }

    // ------------------------------------------------------------------ attribution
    static void attribution() throws Exception {
        ExecutorService pool = daemonPool("time-limiter");
        for (String limiter : new String[] {"none", "fixed"}) {
            SET_STACK_TRACE_CALLERS.clear();
            final TracingIOException ex = new TracingIOException("reused");
            int before = ex.getStackTrace().length;
            Retryer<String> retryer = ReproCRD12.<String>readmeBuilder(limiter, pool, 3).build();
            try {
                retryer.call(() -> { throw ex; });
            } catch (RetryException expected) {
                // all 3 attempts failed
            }
            Map<String, Integer> byCaller = new LinkedHashMap<String, Integer>();
            for (String c : SET_STACK_TRACE_CALLERS) byCaller.merge(c, 1, Integer::sum);
            System.out.printf("[attribution] limiter=%s  1 call() x 3 failed attempts: setStackTrace() called %d time(s) on the callable's exception, by %s; stackTrace.length %d -> %d%n",
                    label(limiter), SET_STACK_TRACE_CALLERS.size(), byCaller, before, ex.getStackTrace().length);
        }
    }

    // ------------------------------------------------------------------ oom
    static void oom(String limiter, String kind, int depth, int maxCalls) throws Exception {
        ExecutorService pool = daemonPool("time-limiter");
        final Retryer<String> retryer = ReproCRD12.<String>readmeBuilder(limiter, pool, 3).build();
        final Callable<String> callable = kind.equals("shared")
                ? () -> { throw NOT_READY; }
                : () -> { throw new IOException("fresh exception per attempt"); };
        Runtime rt = Runtime.getRuntime();
        String tag = label(limiter) + " / " + (kind.equals("shared") ? "reused static sentinel" : "fresh object per attempt");
        System.out.printf("[oom] %s, callerDepth=%d, maxHeap=%dMB, maxCalls=%d%n", tag, depth, rt.maxMemory() >> 20, maxCalls);
        java.util.Set<Integer> checkpoints = new java.util.HashSet<Integer>(java.util.Arrays.asList(250, 500, 750, 1000, 1250, 1500, 3000, 4500, 6000));
        long t0 = System.nanoTime();
        long tBatch = t0;
        int callsAtBatch = 0;
        int calls = 0;
        long attempts = 0;
        String end = "all " + maxCalls + " call()s ended with RetryException(IOException) as configured";
        try {
            while (calls < maxCalls) {
                String outcome = ReproCRD12.<String>atDepth(depth, () -> {
                    try {
                        retryer.call(callable);
                        return "returned normally";
                    } catch (RetryException e) {
                        return "RetryException";
                    } catch (ExecutionException e) {
                        return "ExecutionException caused by " + e.getCause();
                    }
                });
                calls++;
                if (!outcome.equals("RetryException")) {
                    end = "call() #" + calls + " ended with " + outcome + "  <-- not the configured outcome";
                    break;
                }
                attempts += 3;
                if (checkpoints.contains(calls)) {
                    long now = System.nanoTime();
                    try {
                        System.gc();
                        long used = rt.totalMemory() - rt.freeMemory();
                        System.out.printf("  %5d call()s / %6d failed attempts: heap used after GC=%6.1f MB  NOT_READY.stackTrace.length=%,9d  %7.2f ms per call() since previous line%n",
                                calls, attempts, used / 1048576.0, NOT_READY.getStackTrace().length, (now - tBatch) / 1e6 / (calls - callsAtBatch));
                    } catch (OutOfMemoryError e) {
                        end = "OutOfMemoryError while the application only read NOT_READY.getStackTrace() after call() #" + calls + ": " + e;
                        break;
                    }
                    tBatch = System.nanoTime();
                    callsAtBatch = calls;
                }
            }
        } catch (OutOfMemoryError e) {
            end = "OutOfMemoryError escaped to the caller during call() #" + (calls + 1) + ": " + e;
        }
        System.out.printf("  RESULT[%s]: %s (%.1f s; %d failed attempts completed before)%n", tag, end, (System.nanoTime() - t0) / 1e9, attempts);
        // Is the memory released afterwards? The backend recovers; nothing else references the old attempts.
        String healthy = retryer.call(() -> "ok");
        System.gc();
        System.out.printf("  AFTER[%s]: a later call() succeeded (result=%s); after GC heap used=%6.1f MB of %d MB, NOT_READY.stackTrace.length=%,d%n",
                tag, healthy, (rt.totalMemory() - rt.freeMemory()) / 1048576.0, rt.maxMemory() >> 20, NOT_READY.getStackTrace().length);
    }

    public static void main(String[] a) throws Exception {
        try {
            switch (a[0]) {
                case "growth": growth(a[1], a[2]); break;
                case "cf": completableFuture(a[1]); break;
                case "paths": paths(a[1]); break;
                case "attribution": attribution(); break;
                case "oom": oom(a[1], a[2], Integer.parseInt(a[3]), Integer.parseInt(a[4])); break;
                default: throw new IllegalArgumentException(a[0]);
            }
        } finally {
            System.out.flush();
            System.exit(0);   // fixedTimeLimit(d, unit) creates non-daemon pool threads (known issue #92); do not wait for them
        }
    }
}
JAVA

echo "== build reproduction program"
timeout 300 "$JAVA_HOME_21/bin/javac" --release 8 -nowarn -encoding UTF-8 -d "$BUILD/cls" -cp "$BUILD/lib:$CP" "$BUILD/src/ReproCRD12.java" 2>&1 | grep -v '^Note:' || true
[ -f "$BUILD/cls/ReproCRD12.class" ] || { echo "SETUP ERROR: repro build failed"; exit 2; }

RUNCP="$BUILD/cls:$BUILD/lib:$CP"
run() {  # run <name> <timeout-seconds> <java-home> [jvm-args...] -- <program args...>; output -> $BUILD/<name>.txt
  local name=$1 t=$2 jh=$3; shift 3
  local jvm=()
  while [ "$1" != "--" ]; do jvm+=("$1"); shift; done; shift
  echo "\$ timeout $t $jh/bin/java ${jvm[*]} -cp <build> ReproCRD12 $*"
  timeout "$t" "$jh/bin/java" "${jvm[@]}" -cp "$RUNCP" ReproCRD12 "$@" > "$BUILD/$name.txt" 2>&1
  local rc=$?
  cat "$BUILD/$name.txt"
  if [ "$rc" = 124 ]; then echo "  (TIMEOUT after ${t}s)"; elif [ "$rc" != 0 ]; then echo "  (exit status $rc)"; fi
  echo
}

J21=$JAVA_HOME_21
echo "== [growth] README-quickstart retryer (retryIfExceptionOfType(IOException), retryIfRuntimeException, stopAfterAttempt(3)); listener + caller log every failure"
run g_none     300 "$J21" -- growth none sentinel
run g_fixed    300 "$J21" -- growth fixed sentinel
run g_fixed2   300 "$J21" -- growth fixed2 sentinel
run g_none_ch  300 "$J21" -- growth none cheap
run g_fixed_ch 300 "$J21" -- growth fixed cheap
run g_fixed_fz 300 "$J21" -- growth fixed frozen

echo "== [cf] a memoised failed CompletableFuture: join() rethrows the same CompletionException object"
run cf_none  120 "$J21" -- cf none
run cf_fixed 120 "$J21" -- cf fixed

echo "== [paths] other Retryer.call outcomes"
run p_none  300 "$J21" -- paths none
run p_fixed 300 "$J21" -- paths fixed

echo "== [attribution] who rewrites the callable's exception"
run attr 120 "$J21" -- attribution

echo "== [oom] bounded heap (-Xmx32m), caller at a modest application depth of 100 frames, README retryer called repeatedly"
run oom_none  600 "$J21" -Xmx32m -- oom none shared 100 6000
run oom_fresh 600 "$J21" -Xmx32m -- oom fixed fresh 100 6000
run oom_bug   900 "$J21" -Xmx32m -- oom fixed shared 100 6000

if [ -x "$JAVA_HOME_11/bin/java" ]; then
  echo "== JDK 11 cross-check"
  run j11_none  300 "$JAVA_HOME_11" -- growth none sentinel
  run j11_fixed 300 "$JAVA_HOME_11" -- growth fixed sentinel
  run j11_attr  120 "$JAVA_HOME_11" -- attribution
fi

# ---------------------------------------------------------------- evaluation
echo "== evaluation"
pass=1
chk() {  # chk <file> <description> <extended regex>
  if [ -f "$BUILD/$1.txt" ] && grep -Eq -- "$3" "$BUILD/$1.txt"; then echo "  ok   [$1] $2"; else echo "  FAIL [$1] $2"; pass=0; fi
}
GROWN='after 300 call\(\)s / 900 failed attempts: stackTrace.length= *[0-9]{4,} \(SimpleTimeLimiter.callWithTimeout frames: 900\)'
FLAT='after 300 call\(\)s / 900 failed attempts: stackTrace.length= +[01] \(SimpleTimeLimiter.callWithTimeout frames: +0\)'
chk g_none     "control noTimeLimit: sentinel trace unchanged after 900 failed attempts"                 "$FLAT"
chk g_none     "control noTimeLimit: listener log entry stays small"                                      'after 300 call.*listener log entry= +[0-9]{1,3} chars'
chk g_fixed    "fixedTimeLimit(d,u,executor): one appended caller stack per failed attempt"               "$GROWN"
chk g_fixed    "fixedTimeLimit(d,u,executor): listener log entry for one attempt exceeds 100,000 chars"   'after 300 call.*listener log entry= +[0-9]{6,} chars'
chk g_fixed2   "fixedTimeLimit(d,u): same growth"                                                         "$GROWN"
chk g_none_ch  "control noTimeLimit: cheap (fillInStackTrace no-op) exception unchanged"                  "$FLAT"
chk g_fixed_ch "fixedTimeLimit: cheap (fillInStackTrace no-op) exception grows too"                       "$GROWN"
chk g_fixed_fz "mitigation: writableStackTrace=false exception stays empty under fixedTimeLimit"         'after 300 call\(\)s / 900 failed attempts: stackTrace.length= +0 \(SimpleTimeLimiter.callWithTimeout frames: +0\)'
chk cf_fixed   "cf: JDK CompletableFuture.join() rethrows the same object"                                'rethrows the same object on every call: true'
chk cf_none    "cf control: noTimeLimit leaves the CompletionException trace unchanged"                   'after 100 call\(\)s / 300 failed attempts: CompletionException stackTrace.length= +[0-9]{1,2} \(SimpleTimeLimiter.callWithTimeout frames: +0\)'
chk cf_fixed   "cf: CompletionException trace grows under fixedTimeLimit"                                 'after 100 call\(\)s / 300 failed attempts: CompletionException stackTrace.length= *[0-9]{4,} \(SimpleTimeLimiter.callWithTimeout frames: 300\)'
chk p_none     "paths control: (b) unchanged under noTimeLimit"                                           '\(b\) .*stackTrace.length 2 -> 2 after 100'
chk p_none     "paths control: (d) unchanged under noTimeLimit"                                           '\(d\) .*stackTrace.length 2 -> 2 after 100'
chk p_none     "paths control: (e) unchanged under noTimeLimit"                                           '\(e\) default neverStop.*stackTrace.length 2 -> 2$'
chk p_fixed    "paths: (b) ExecutionException path grows"                                                 '\(b\) .*stackTrace.length 2 -> [0-9]{3,} after 100'
chk p_fixed    "paths: (d) Retryer.wrap() path grows"                                                     '\(d\) .*stackTrace.length 2 -> [0-9]{4,} after 100'
chk p_fixed    "paths: (e) neverStop grows within a single call()"                                        '\(e\) .*stackTrace.length 2 -> [0-9]{4,}$'
chk attr       "attribution: SimpleTimeLimiter.throwCause rewrites the exception once per attempt"        'fixedTimeLimit\(5s, executor\)  1 call\(\) x 3 failed attempts: setStackTrace\(\) called 3 time\(s\) .* by \{com.google.common.util.concurrent.SimpleTimeLimiter.throwCause\(SimpleTimeLimiter.java:259\)=3\}'
chk attr       "attribution control: noTimeLimit never rewrites it"                                      'noTimeLimit \(control\)  1 call\(\) x 3 failed attempts: setStackTrace\(\) called 0 time'
chk oom_none   "oom control: noTimeLimit + reused exception completes all calls"                          'RESULT\[.*\]: all 6000 call\(\)s ended with RetryException'
chk oom_fresh  "oom control: fixedTimeLimit + fresh exceptions completes all calls"                       'RESULT\[.*\]: all 6000 call\(\)s ended with RetryException'
chk oom_bug    "oom: fixedTimeLimit + reused exception ends in OutOfMemoryError"                          'RESULT\[.*\]: .*OutOfMemoryError'
chk oom_bug    "oom: memory stays retained after a later successful call()"                               'AFTER\[.*\]: a later call\(\) succeeded .*NOT_READY.stackTrace.length=[0-9]{3},[0-9]{3}'
if [ -x "$JAVA_HOME_11/bin/java" ]; then
  chk j11_none  "JDK 11 control unchanged"                                                                "$FLAT"
  chk j11_fixed "JDK 11 fixedTimeLimit grows"                                                             "$GROWN"
  chk j11_attr  "JDK 11 attribution"                                                                      'SimpleTimeLimiter.throwCause\(SimpleTimeLimiter.java:259\)=3'
fi
if [ "$pass" = 1 ]; then echo "RESULT: BUG TRIGGERED (PASS)"; exit 0; else echo "RESULT: not (fully) triggered"; exit 1; fi
