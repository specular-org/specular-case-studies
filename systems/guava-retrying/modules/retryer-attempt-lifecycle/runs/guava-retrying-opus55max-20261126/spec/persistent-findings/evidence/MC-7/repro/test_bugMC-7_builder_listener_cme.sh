#!/usr/bin/env bash
# MC-7: RetryerBuilder.withRetryListener() called on one thread while a Retryer built from that builder
# is inside call() on another thread makes call() throw java.util.ConcurrentModificationException AFTER
# the attempt has executed. The attempt's outcome (return value, exception, retry decision) is lost, and
# the rejection predicate and stop strategy never run.
#
# Root cause: RetryerBuilder.build() hands its own ArrayList to the Retryer (RetryerBuilder.java:40,63,196).
# Retryer stores it uncopied (Retryer.java:137) and iterates it with a fail-fast iterator outside the
# attempt's try/catch (Retryer.java:166-168).
#
# Escalation levels used:
#   Level 0: pure black box. A caller thread loops retryer.call()/wrap(); the main thread calls
#            builder.withRetryListener() once, at an uncoordinated moment. No sleeps, no hooks.
#   Level 1: timing help only. A user-supplied RetryListener (public API) blocks on a latch during
#            attempt 1, so the main thread's withRetryListener() deterministically lands inside the
#            caller's listener loop. Library logic is unchanged.
# The guava-retrying sources are compiled UNMODIFIED from $SRC_ROOT.
# Negative control: a temp copy whose RetryerBuilder.build() copies the list (the fix proposed in
# upstream #48) is compiled separately and must NOT show the symptom. $SRC_ROOT is never modified.
#
# Exit 0 = bug reproduced on the unmodified build and absent in the negative control; 1 = not reproduced;
# 2 = setup error.
set -euo pipefail

SRC_ROOT="${SRC_ROOT:-/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-7/worktree}"
M2="${M2_REPO:-$HOME/.m2/repository}"
GUAVA_JAR="$M2/com/google/guava/guava/22.0/guava-22.0.jar"
JSR305_JAR="$M2/com/google/code/findbugs/jsr305/2.0.2/jsr305-2.0.2.jar"
if [[ -n "${JAVA_HOME:-}" ]]; then JAVA="$JAVA_HOME/bin/java"; JAVAC="$JAVA_HOME/bin/javac"; else JAVA=java; JAVAC=javac; fi
TRIALS="${TRIALS:-2000}"

die() { echo "SETUP ERROR: $*" >&2; exit 2; }
[[ -d "$SRC_ROOT/src/main/java/com/github/rholder/retry" ]] || die "no guava-retrying sources under $SRC_ROOT"
if [[ ! -f "$GUAVA_JAR" || ! -f "$JSR305_JAR" ]]; then
  echo "fetching Guava 22.0 / jsr305 2.0.2 into $M2 ..."
  timeout 300 mvn -q dependency:get -Dartifact=com.google.guava:guava:22.0 >/dev/null || die "cannot fetch guava 22.0"
  timeout 300 mvn -q dependency:get -Dartifact=com.google.code.findbugs:jsr305:2.0.2 >/dev/null || die "cannot fetch jsr305"
fi

WORK="$(mktemp -d "${TMPDIR:-/tmp}/mc7-repro.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
CP_DEPS="$GUAVA_JAR:$JSR305_JAR"

echo "== provenance"
echo "source root : $SRC_ROOT"
echo "source HEAD : $(git -C "$SRC_ROOT" rev-parse HEAD 2>/dev/null || echo n/a)  dirty-files=$(git -C "$SRC_ROOT" status --porcelain 2>/dev/null | wc -l)"
echo "sha256 RetryerBuilder.java $(sha256sum "$SRC_ROOT/src/main/java/com/github/rholder/retry/RetryerBuilder.java" | cut -c1-16)  Retryer.java $(sha256sum "$SRC_ROOT/src/main/java/com/github/rholder/retry/Retryer.java" | cut -c1-16)"
echo "cited lines (unmodified source):"
sed -n '40p;63p;196p' "$SRC_ROOT/src/main/java/com/github/rholder/retry/RetryerBuilder.java" | sed 's/^/  RetryerBuilder: /'
sed -n '137p;166,168p' "$SRC_ROOT/src/main/java/com/github/rholder/retry/Retryer.java" | sed 's/^/  Retryer      : /'
"$JAVA" -version 2>&1 | head -1

echo "== build (javac --release 8, Guava 22.0, jsr305 2.0.2)"
mkdir -p "$WORK/lib-orig" "$WORK/lib-fixed" "$WORK/src-fixed" "$WORK/harness"
"$JAVAC" --release 8 -nowarn -encoding UTF-8 -d "$WORK/lib-orig" -cp "$CP_DEPS" \
  $(find "$SRC_ROOT/src/main/java" -name '*.java') 2>&1 | grep -v '^Note:' || true
[[ -f "$WORK/lib-orig/com/github/rholder/retry/Retryer.class" ]] || die "library build failed"
cp -r "$SRC_ROOT/src/main/java" "$WORK/src-fixed/"
FIXED_RB="$WORK/src-fixed/java/com/github/rholder/retry/RetryerBuilder.java"
sed -i 's/rejectionPredicate, listeners);/rejectionPredicate, com.google.common.collect.ImmutableList.copyOf(listeners));/' "$FIXED_RB"
grep -q 'ImmutableList.copyOf(listeners)' "$FIXED_RB" || die "negative-control patch did not apply"
echo "negative-control build only (temp copy): $(grep -n 'ImmutableList.copyOf(listeners)' "$FIXED_RB" | sed 's/^ *//;s/  */ /g')"
"$JAVAC" --release 8 -nowarn -encoding UTF-8 -d "$WORK/lib-fixed" -cp "$CP_DEPS" \
  $(find "$WORK/src-fixed/java" -name '*.java') 2>&1 | grep -v '^Note:' || true
[[ -f "$WORK/lib-fixed/com/github/rholder/retry/Retryer.class" ]] || die "negative-control build failed"

cat > "$WORK/harness/ReproMC7.java" <<'JAVA'
import com.github.rholder.retry.Attempt;
import com.github.rholder.retry.AttemptTimeLimiters;
import com.github.rholder.retry.RetryException;
import com.github.rholder.retry.RetryListener;
import com.github.rholder.retry.Retryer;
import com.github.rholder.retry.RetryerBuilder;
import com.github.rholder.retry.StopStrategies;
import com.github.rholder.retry.StopStrategy;
import com.google.common.base.Predicate;
import com.google.common.base.Predicates;
import com.google.common.util.concurrent.UncheckedTimeoutException;

import java.io.IOException;
import java.util.ArrayList;
import java.util.ConcurrentModificationException;
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
import java.util.concurrent.atomic.AtomicLong;

/** Black-box driver: only public guava-retrying API is used; all probes live in user-supplied code. */
public final class ReproMC7 {

    // ------------------------------------------------------------------ user-side probes
    static final class Probe {
        final AtomicInteger callableRuns = new AtomicInteger();
        final AtomicInteger predicateCalls = new AtomicInteger();
        final AtomicInteger stopCalls = new AtomicInteger();
        final AtomicInteger lateListenerCalls = new AtomicInteger();

        String counts() {
            return "callable executions=" + callableRuns.get()
                    + ", rejection-predicate invocations=" + predicateCalls.get()
                    + ", stop-strategy invocations=" + stopCalls.get()
                    + ", late listener notified=" + lateListenerCalls.get();
        }
    }

    /** Builder whose predicate and stop strategy only count how often Retryer.call consults them. */
    @SuppressWarnings("rawtypes")
    static RetryerBuilder<Integer> probedBuilder(final Probe p) {
        return RetryerBuilder.<Integer>newBuilder()
                .retryIfResult(new Predicate<Integer>() {
                    @Override public boolean apply(Integer r) {
                        p.predicateCalls.incrementAndGet();
                        return r == null;
                    }
                })
                .retryIfException(new Predicate<Throwable>() {
                    @Override public boolean apply(Throwable t) {
                        p.predicateCalls.incrementAndGet();
                        return t instanceof IOException || t instanceof UncheckedTimeoutException;
                    }
                })
                .withStopStrategy(new StopStrategy() {
                    private final StopStrategy delegate = StopStrategies.stopAfterAttempt(3);
                    @Override public boolean shouldStop(Attempt failedAttempt) {
                        p.stopCalls.incrementAndGet();
                        return delegate.shouldStop(failedAttempt);
                    }
                });
    }

    /** Level-1 timing aid: a listener that is slow on one attempt (e.g. a synchronous metrics push). */
    static final class SlowListener implements RetryListener {
        final long slowAttempt;
        final CountDownLatch entered = new CountDownLatch(1);
        final CountDownLatch proceed = new CountDownLatch(1);
        SlowListener(long slowAttempt) { this.slowAttempt = slowAttempt; }
        @Override public <V> void onRetry(Attempt<V> attempt) {
            if (attempt.getAttemptNumber() == slowAttempt) {
                entered.countDown();
                try {
                    proceed.await(10, TimeUnit.SECONDS);
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
            }
        }
    }

    static RetryListener counting(final AtomicInteger counter) {
        return new RetryListener() {
            @Override public <V> void onRetry(Attempt<V> attempt) { counter.incrementAndGet(); }
        };
    }

    static Throwable cmeIn(Throwable t) {
        for (Throwable x = t; x != null; x = x.getCause()) {
            if (x instanceof ConcurrentModificationException) return x;
        }
        return null;
    }

    static String trace(Throwable t) {
        StringBuilder sb = new StringBuilder();
        for (Throwable x = t; x != null; x = x.getCause()) {
            if (x != t) sb.append("        Caused by: ");
            else sb.append("        ");
            sb.append(x).append('\n');
            int n = 0;
            for (StackTraceElement e : x.getStackTrace()) {
                sb.append("          at ").append(e).append('\n');
                if (("com.github.rholder.retry.Retryer".equals(e.getClassName()) && "call".equals(e.getMethodName())) || ++n >= 4) break;
            }
        }
        return sb.toString();
    }

    // ------------------------------------------------------------------ Level 1 (deterministic)
    enum Kind {
        RESULT("attempt 1 returns 42", "call() returns 42 after 1 attempt"),
        IOEXCEPTION_THEN_RESULT("attempt 1 throws IOException (retryable), attempt 2 returns 42",
                "call() retries and returns 42 after 2 attempts"),
        TIMEOUT_THEN_RESULT("attempt 1 exceeds fixedTimeLimit(200ms) (retryable), attempt 2 returns 42",
                "call() retries and returns 42 after 2 attempts");
        final String what;
        final String documented;
        Kind(String what, String documented) { this.what = what; this.documented = documented; }
    }

    static final class Outcome {
        final Probe probe = new Probe();
        volatile Integer value;
        volatile Throwable thrown;
    }

    static Outcome runGated(final Kind kind, boolean concurrentAdd, boolean viaWrapOnExecutor) throws Exception {
        final Outcome out = new Outcome();
        final Probe p = out.probe;
        final SlowListener slow = new SlowListener(1);
        final RetryerBuilder<Integer> builder = probedBuilder(p).withRetryListener(slow);
        ExecutorService limiterPool = null;
        if (kind == Kind.TIMEOUT_THEN_RESULT) {
            limiterPool = Executors.newCachedThreadPool();
            builder.withAttemptTimeLimiter(AttemptTimeLimiters.<Integer>fixedTimeLimit(200, TimeUnit.MILLISECONDS, limiterPool));
        }
        final Retryer<Integer> retryer = builder.build();
        final Callable<Integer> callable = new Callable<Integer>() {
            @Override public Integer call() throws Exception {
                int n = p.callableRuns.incrementAndGet();
                if (n == 1 && kind == Kind.IOEXCEPTION_THEN_RESULT) throw new IOException("transient failure in attempt 1");
                if (n == 1 && kind == Kind.TIMEOUT_THEN_RESULT) { Thread.sleep(5000); return -1; }
                return 42;
            }
        };
        ExecutorService callerPool = null;
        Future<Integer> future = null;
        Thread caller = null;
        if (viaWrapOnExecutor) {
            callerPool = Executors.newSingleThreadExecutor();
            future = callerPool.submit(retryer.wrap(callable));      // RetryerCallable.call -> Retryer.call
        } else {
            caller = new Thread(new Runnable() {
                @Override public void run() {
                    try { out.value = retryer.call(callable); } catch (Throwable t) { out.thrown = t; }
                }
            }, "retryer-caller");
            caller.start();
        }
        try {
            if (!slow.entered.await(10, TimeUnit.SECONDS)) throw new IllegalStateException("listener loop never reached");
            // The caller thread is now inside Retryer.call's listener loop; attempt 1 has already executed.
            if (concurrentAdd) {
                builder.withRetryListener(counting(p.lateListenerCalls));   // public API, main thread
            }
            slow.proceed.countDown();
            if (viaWrapOnExecutor) {
                try { out.value = future.get(30, TimeUnit.SECONDS); } catch (ExecutionException e) { out.thrown = e; }
            } else {
                caller.join(30000);
                if (caller.isAlive()) throw new IllegalStateException("caller thread hung");
            }
        } finally {
            if (callerPool != null) callerPool.shutdownNow();
            if (limiterPool != null) limiterPool.shutdownNow();
        }
        return out;
    }

    static boolean level1Case(String id, Kind kind, boolean viaWrap, boolean expectBug) throws Exception {
        Outcome o = runGated(kind, true, viaWrap);
        String how = viaWrap ? "executor.submit(retryer.wrap(c)).get()" : "retryer.call(c)";
        System.out.println("[" + id + "] " + how + " | " + kind.what);
        System.out.println("    concurrent step    : main thread calls builder.withRetryListener(late) while the caller is inside its listener loop");
        System.out.println("    documented outcome : " + kind.documented);
        String observed = o.thrown == null ? ("returned " + o.value) : ("threw " + o.thrown.getClass().getName()
                + (o.thrown.getCause() != null ? " (cause: " + o.thrown.getCause().getClass().getName() + ")" : ""));
        System.out.println("    observed           : " + observed + "; value delivered to caller = " + (o.value == null ? "none" : o.value));
        System.out.println("    probes             : " + o.probe.counts());
        if (o.thrown != null) System.out.print(trace(o.thrown));
        boolean cme = cmeIn(o.thrown) != null;
        boolean lost = cme && o.value == null && o.probe.callableRuns.get() == 1
                && o.probe.predicateCalls.get() == 0 && o.probe.stopCalls.get() == 0;
        boolean documented = o.thrown == null && Integer.valueOf(42).equals(o.value) && o.probe.lateListenerCalls.get() == 0;
        if (expectBug) {
            System.out.println(lost ? "    => BUG TRIGGERED: attempt executed, call() ended with ConcurrentModificationException,"
                    + " outcome lost, predicate/stop strategy never consulted"
                    : "    => not triggered");
            return lost;
        }
        System.out.println(documented ? "    => documented outcome (no CME)" : "    => UNEXPECTED in negative control");
        return documented;
    }

    static boolean control(String id, Kind kind, int expRuns, int expPred, int expStop) throws Exception {
        Outcome o = runGated(kind, false, false);
        boolean ok = o.thrown == null && Integer.valueOf(42).equals(o.value) && o.probe.callableRuns.get() == expRuns
                && o.probe.predicateCalls.get() == expPred && o.probe.stopCalls.get() == expStop;
        System.out.println("[" + id + "] control, same as above but NO concurrent withRetryListener | " + kind.what);
        System.out.println("    observed           : " + (o.thrown == null ? "returned " + o.value : "threw " + o.thrown)
                + " | " + o.probe.counts() + (ok ? "  => documented outcome" : "  => UNEXPECTED"));
        if (o.thrown != null) System.out.print(trace(o.thrown));
        return ok;
    }

    // ------------------------------------------------------------------ Level 0 (pure black box)
    static final class CallerState {   // written only by the caller thread, read by main after join()
        boolean listenerRanThisCall;
        int callableRunsThisCall;
        int predicateCallsThisCall;
        long completedCalls;
        Throwable failure;
    }

    /** One caller thread loops retryer.call(); main calls builder.withRetryListener() once, uncoordinated. */
    static int level0SingleCaller(int trials, boolean expectBug) throws Exception {
        int cme = 0, cmeBeforeFirstListener = 0, cmeAfterFirstListener = 0, lostWithNoDecision = 0, other = 0;
        Throwable sample = null;
        long t0 = System.nanoTime();
        for (int t = 0; t < trials; t++) {
            final CallerState cs = new CallerState();
            final RetryerBuilder<Integer> builder = RetryerBuilder.<Integer>newBuilder()
                    .retryIfResult(new Predicate<Integer>() {
                        @Override public boolean apply(Integer r) { cs.predicateCallsThisCall++; return r == null; }
                    })
                    .withStopStrategy(StopStrategies.stopAfterAttempt(3))
                    .withRetryListener(new RetryListener() {          // an ordinary logging listener
                        private String lastLine;
                        @Override public <V> void onRetry(Attempt<V> a) {
                            cs.listenerRanThisCall = true;
                            lastLine = String.format("attempt #%d hasResult=%s delaySinceFirstAttempt=%dms",
                                    a.getAttemptNumber(), a.hasResult(), a.getDelaySinceFirstAttempt());
                        }
                    });
            final Retryer<Integer> retryer = builder.build();
            final Callable<Integer> callable = new Callable<Integer>() {
                @Override public Integer call() { cs.callableRunsThisCall++; return 42; }
            };
            final AtomicBoolean stop = new AtomicBoolean(false);
            final AtomicLong progress = new AtomicLong();
            Thread caller = new Thread(new Runnable() {
                @Override public void run() {
                    while (!stop.get()) {
                        cs.listenerRanThisCall = false;
                        cs.callableRunsThisCall = 0;
                        cs.predicateCallsThisCall = 0;
                        try {
                            Integer v = retryer.call(callable);
                            if (v == null || v.intValue() != 42) throw new AssertionError("unexpected value " + v);
                            cs.completedCalls++;
                            progress.set(cs.completedCalls);
                        } catch (Throwable th) {
                            cs.failure = th;
                            return;
                        }
                    }
                }
            }, "retryer-caller-" + t);
            caller.start();
            while (progress.get() < 100 && caller.isAlive()) Thread.yield();   // caller is busy looping call()
            builder.withRetryListener(new RetryListener() {                     // e.g. configuring a second variant
                @Override public <V> void onRetry(Attempt<V> a) { }
            });
            stop.set(true);
            caller.join(10000);
            if (caller.isAlive()) throw new IllegalStateException("caller hung in trial " + t);
            if (cs.failure instanceof ConcurrentModificationException) {
                cme++;
                if (cs.listenerRanThisCall) cmeAfterFirstListener++; else cmeBeforeFirstListener++;
                if (cs.callableRunsThisCall == 1 && cs.predicateCallsThisCall == 0) lostWithNoDecision++;
                if (sample == null) sample = cs.failure;
            } else if (cs.failure != null) {
                other++;
                if (other == 1) System.out.println("    other failure: " + cs.failure);
            }
        }
        long ms = (System.nanoTime() - t0) / 1_000_000;
        System.out.println("[L0-a] pure black box, 1 caller thread looping retryer.call() + 1 uncoordinated builder.withRetryListener() per trial");
        System.out.println("    trials=" + trials + " (" + ms + " ms): call() threw ConcurrentModificationException in " + cme + " trials"
                + " (" + cmeBeforeFirstListener + " before the first listener ran = exact TLC interleaving, "
                + cmeAfterFirstListener + " after it ran); other failures=" + other);
        System.out.println("    of the CME trials, attempt executed (callable ran once) with predicate never consulted: " + lostWithNoDecision);
        if (sample != null) System.out.print(trace(sample));
        if (expectBug) {
            System.out.println(cme > 0 && lostWithNoDecision == cme && other == 0
                    ? "    => BUG TRIGGERED at Level 0" : "    => not triggered at Level 0 in this run");
        } else {
            System.out.println(cme == 0 && other == 0 ? "    => no CME (negative control)" : "    => UNEXPECTED in negative control");
        }
        return expectBug ? (lostWithNoDecision == cme ? cme : -1) : (cme == 0 && other == 0 ? 0 : -1);
    }

    /** A shared retryer used by 2 pool threads through wrap(); main adds a listener once per trial. */
    static int level0SharedViaWrap(int trials) throws Exception {
        ExecutorService pool = Executors.newFixedThreadPool(2);
        int trialsWithCme = 0;
        long futuresCme = 0, futuresOk = 0, futuresOther = 0;
        Throwable sample = null;
        try {
            for (int t = 0; t < trials; t++) {
                final AtomicLong attemptsSeen = new AtomicLong();
                final RetryerBuilder<Integer> builder = RetryerBuilder.<Integer>newBuilder()
                        .retryIfResult(Predicates.<Integer>isNull())
                        .withStopStrategy(StopStrategies.stopAfterAttempt(3))
                        .withRetryListener(new RetryListener() {     // metrics/logging listener
                            private volatile String lastLine;
                            @Override public <V> void onRetry(Attempt<V> a) {
                                attemptsSeen.incrementAndGet();
                                lastLine = String.format("attempt #%d hasResult=%s", a.getAttemptNumber(), a.hasResult());
                            }
                        });
                final Retryer<Integer> retryer = builder.build();
                final Callable<Integer> task = new Callable<Integer>() {
                    @Override public Integer call() { return 42; }
                };
                List<Future<Integer>> fs = new ArrayList<Future<Integer>>();
                for (int i = 0; i < 400; i++) fs.add(pool.submit(retryer.wrap(task)));
                while (attemptsSeen.get() < 100) Thread.yield();
                builder.withRetryListener(new RetryListener() {
                    @Override public <V> void onRetry(Attempt<V> a) { }
                });
                boolean any = false;
                for (Future<Integer> f : fs) {
                    try {
                        f.get(10, TimeUnit.SECONDS);
                        futuresOk++;
                    } catch (ExecutionException e) {
                        if (e.getCause() instanceof ConcurrentModificationException) {
                            futuresCme++;
                            any = true;
                            if (sample == null) sample = e;
                        } else {
                            futuresOther++;
                        }
                    }
                }
                if (any) trialsWithCme++;
            }
        } finally {
            pool.shutdownNow();
        }
        System.out.println("[L0-b] pure black box, one Retryer shared by 2 pool threads via wrap(); main adds 1 listener per trial");
        System.out.println("    trials=" + trials + ": trials with a CME-failed Future=" + trialsWithCme
                + "; futures ok=" + futuresOk + ", failed with ExecutionException(cause=CME)=" + futuresCme + ", other=" + futuresOther);
        if (sample != null) System.out.print(trace(sample));
        return trialsWithCme;
    }

    public static void main(String[] args) throws Exception {
        String mode = args.length > 0 ? args[0] : "buggy";
        int trials = args.length > 1 ? Integer.parseInt(args[1]) : 2000;
        boolean expectBug = !"fixed".equals(mode);
        System.out.println("mode=" + mode + " java.version=" + System.getProperty("java.version")
                + " cpus=" + Runtime.getRuntime().availableProcessors()
                + " library=" + Retryer.class.getProtectionDomain().getCodeSource().getLocation());
        boolean ok = true;
        if (expectBug) {
            System.out.println("---- Level 0: pure black box (public API only, no sleeps, no hooks)");
            int l0a = level0SingleCaller(trials, true);
            int l0b = level0SharedViaWrap(Math.max(50, trials / 10));
            System.out.println("---- Level 1: timing help only (a user-supplied listener blocks on a latch during attempt 1)");
            boolean a = level1Case("L1-a", Kind.RESULT, false, true);
            boolean b = level1Case("L1-b", Kind.IOEXCEPTION_THEN_RESULT, false, true);
            boolean c = level1Case("L1-c", Kind.TIMEOUT_THEN_RESULT, false, true);
            boolean d = level1Case("L1-d", Kind.RESULT, true, true);
            System.out.println("---- controls on the same unmodified build (no concurrent builder modification)");
            boolean ca = control("C-a", Kind.RESULT, 1, 1, 0);
            boolean cb = control("C-b", Kind.IOEXCEPTION_THEN_RESULT, 2, 2, 1);
            boolean cc = control("C-c", Kind.TIMEOUT_THEN_RESULT, 2, 2, 1);
            boolean level1 = a && b && c && d;
            boolean controls = ca && cb && cc;
            System.out.println("SUMMARY(unmodified 2.0.0): Level0 single-caller CME trials=" + l0a + "/" + trials
                    + ", Level0 shared-wrap trials with CME=" + l0b + ", Level1 reproduced=" + level1 + ", controls documented=" + controls);
            ok = l0a >= 0 && level1 && controls;
        } else {
            System.out.println("---- negative control: RetryerBuilder.build() copies the listener list (fix proposed in #48)");
            boolean a = level1Case("F-a", Kind.RESULT, false, false);
            boolean b = level1Case("F-b", Kind.IOEXCEPTION_THEN_RESULT, false, false);
            boolean c = level1Case("F-c", Kind.TIMEOUT_THEN_RESULT, false, false);
            boolean d = level1Case("F-d", Kind.RESULT, true, false);
            int l0 = level0SingleCaller(trials, false);
            ok = a && b && c && d && l0 == 0;
            System.out.println("SUMMARY(negative control): documented outcomes=" + (a && b && c && d) + ", Level0 CME trials=" + (l0 == 0 ? 0 : "nonzero"));
        }
        System.exit(ok ? 0 : 1);
    }
}
JAVA
"$JAVAC" --release 8 -nowarn -encoding UTF-8 -d "$WORK/harness" -cp "$WORK/lib-orig:$CP_DEPS" "$WORK/harness/ReproMC7.java" 2>&1 | grep -v '^Note:' || true
[[ -f "$WORK/harness/ReproMC7.class" ]] || die "harness build failed"

echo
echo "== run 1: UNMODIFIED guava-retrying 2.0.0"
set +e
timeout 300 "$JAVA" -cp "$WORK/harness:$WORK/lib-orig:$CP_DEPS" ReproMC7 buggy "$TRIALS"
RC_BUG=$?
echo
echo "== run 2: negative control (temp copy; build() copies the listener list)"
timeout 300 "$JAVA" -cp "$WORK/harness:$WORK/lib-fixed:$CP_DEPS" ReproMC7 fixed "$TRIALS"
RC_FIX=$?
set -e
echo
echo "exit codes: unmodified=$RC_BUG (0 = bug reproduced)  negative-control=$RC_FIX (0 = symptom absent)"
if [[ $RC_BUG -eq 0 && $RC_FIX -eq 0 ]]; then
  echo "RESULT: BUG REPRODUCED on unmodified guava-retrying 2.0.0; symptom absent when build() copies the listener list"
  exit 0
fi
echo "RESULT: NOT REPRODUCED (see output above)"
exit 1
