#!/usr/bin/env bash
# MC-4 reproduction: a caller interrupt during a fixedTimeLimit attempt is swallowed by Retryer.call.
#
# Level 0 (public API only, unmodified library source). The test thread only orders events
# (it interrupts the caller after attempt 1 has started and the caller is parked); nothing is
# injected into or patched in guava-retrying, Guava or the JDK.
#
# Every scenario runs twice with the identical retryer configuration and callable:
#   [fixedTimeLimit] AttemptTimeLimiters.fixedTimeLimit(10, SECONDS)   <- finding under test
#   [control]        no time limiter (builder default)                 <- same contract, other path
# Contract (Retryer.java:151-153): "if the thread is interrupted, [RetryException] is thrown and
# the thread's interrupt status is set"; (Retryer.java:59-61) a rejected attempt is retried
# "unless the stop strategy indicates otherwise or the thread is interrupted".
#
# Scenarios (MC trace / ledger exit they instantiate):
#   A  retryIfException(), interrupt during attempt 1           -> bfs5 (InterruptPreserved) + bfs3 (retry after interrupt)
#   B  retryIfExceptionOfType(IOException), thread already
#      interrupted when call() starts (repeated 200x)           -> narrow_bfs1 (ExecutionException) + bfs1 (counted, 0 invocations)
#   B2 retryIfExceptionOfType(IOException), interrupt during attempt 1 -> ExecutionException exit, interrupt mid-attempt
#   C  retryIfException() + stopAfterAttempt(1), interrupt during attempt 1 -> ledger D-5 RetryException-with-status-clear exit
#   D  real consumer: retryer.wrap() task on an ExecutorService, shutdownNow() + awaitTermination()
#   F  timing race (statistical, Level 1: the callable spins to a chosen instant): completion vs. interrupt
#      -> bfs2 (NoDiscardedCompletion: a completed attempt's result is discarded and the work repeated)
#
# Usage: test_bugMC-4_interrupt_swallowed.sh [WORKTREE] ; exit 0 = bug reproduced on every JDK run.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="$(cd "$HERE/.." && pwd)"
WORKTREE="${1:-$OUT/confirmation/MC-4/worktree}"
BUILD="${MC4_BUILD:-$OUT/confirmation/MC-4/build}"
M2="${HOME}/.m2/repository"
GUAVA="$M2/com/google/guava/guava/22.0/guava-22.0.jar"
JSR305="$M2/com/google/code/findbugs/jsr305/2.0.2/jsr305-2.0.2.jar"
JAVAC="${JAVAC:-javac}"
JAVAS=("${JAVA21:-java}" "${JAVA11:-/usr/lib/jvm/java-11-openjdk-amd64/bin/java}")

echo "== MC-4 repro: worktree=$WORKTREE"
echo "== library HEAD: $(git -C "$WORKTREE" rev-parse HEAD)  dirty-files: $(git -C "$WORKTREE" status --porcelain | wc -l)"
echo "== guava: $GUAVA sha1=$(sha1sum "$GUAVA" | cut -d' ' -f1)"
rm -rf "$BUILD"; mkdir -p "$BUILD/lib" "$BUILD/test"

# 1. Build the unmodified library (Guava 22.0, --release 8, as in the known-good analysis build recipe).
"$JAVAC" --release 8 -nowarn -encoding UTF-8 -cp "$GUAVA:$JSR305" -d "$BUILD/lib" \
  $(find "$WORKTREE/src/main/java" -name '*.java') 2>&1 | grep -v -e '^Note:' -e 'warning' || true
test -f "$BUILD/lib/com/github/rholder/retry/Retryer.class"

# 2. The reproduction program (user code: a callable, a listener, and threads that interrupt).
cat > "$BUILD/test/MC4Repro.java" <<'JAVA'
import com.github.rholder.retry.*;

import java.io.IOException;
import java.io.InterruptedIOException;
import java.util.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.*;
import java.util.concurrent.locks.LockSupport;

public class MC4Repro {

    // ------------------------------------------------------------------ user code
    /** A remote call. Invocations 1..hanging hang (slow service) until their thread is interrupted and then
     *  throw InterruptedIOException, leaving the interrupt status SET (the NIO ClosedByInterruptException
     *  convention) -- i.e. a callable that cooperates with cancellation and never swallows an interrupt.
     *  Later invocations return immediately. */
    static final class RemoteCall implements Callable<String> {
        final int hanging;
        final AtomicInteger invocations = new AtomicInteger();
        final CountDownLatch firstStarted = new CountDownLatch(1);
        RemoteCall(int hanging) { this.hanging = hanging; }
        @Override public String call() throws Exception {
            int n = invocations.incrementAndGet();
            if (n <= hanging) {
                firstStarted.countDown();
                long deadline = System.nanoTime() + TimeUnit.SECONDS.toNanos(20);
                while (System.nanoTime() < deadline) {
                    if (Thread.currentThread().isInterrupted()) {          // non-clearing check
                        throw new InterruptedIOException("invocation " + n + " aborted by interrupt");
                    }
                    LockSupport.parkNanos(1000000L);
                }
                throw new IOException("invocation " + n + " gave up after 20 s");
            }
            return "result-of-invocation-" + n;
        }
    }

    /** RetryListener recording what Retryer.call decided each attempt was (runs on the caller thread). */
    static final class Recorder implements RetryListener {
        final List<String> log = Collections.synchronizedList(new ArrayList<String>());
        @Override public <V> void onRetry(Attempt<V> a) {
            String what = a.hasException() ? a.getExceptionCause().getClass().getSimpleName()
                                           : "result(" + a.getResult() + ")";
            log.add("#" + a.getAttemptNumber() + " " + what
                    + (Thread.currentThread().isInterrupted() ? " [interrupt pending]" : ""));
        }
    }

    static final class Outcome {
        String kind = "?", detail = "";
        boolean interruptedAfter;
        long elapsedMs;
        int invocations;
        String attempts = "";
        String callerStackAtInterrupt = "";
        boolean contractHolds() { return "RetryException".equals(kind) && interruptedAfter; }
        @Override public String toString() {
            return kind + (detail.isEmpty() ? "" : " {" + detail + "}") + ", interruptStatusAfterCall=" + interruptedAfter
                   + ", callableInvocations=" + invocations + ", attemptsSeenByListener=" + attempts
                   + ", elapsed=" + elapsedMs + "ms";
        }
    }

    static String describe(Attempt<?> a) {
        if (a == null) return "null";
        return "#" + a.getAttemptNumber() + " " + (a.hasException() ? a.getExceptionCause().getClass().getSimpleName()
                                                                    : "result(" + a.getResult() + ")");
    }

    static void waitUntilParked(Thread t) throws InterruptedException {
        long until = System.nanoTime() + TimeUnit.SECONDS.toNanos(10);
        int stable = 0;
        while (System.nanoTime() < until) {
            stable = (t.getState() == Thread.State.TIMED_WAITING) ? stable + 1 : 0;
            if (stable >= 3) return;
            Thread.sleep(2);
        }
        throw new IllegalStateException("caller never parked: " + t.getState());
    }

    static String topFrames(Thread t, int n) {
        StringBuilder sb = new StringBuilder();
        StackTraceElement[] st = t.getStackTrace();
        for (int i = 0; i < Math.min(n, st.length); i++) sb.append("\n        at ").append(st[i]);
        return sb.toString();
    }

    /** Runs retryer.call(callable) on a fresh caller thread, optionally interrupting it. */
    static Outcome runCall(final Retryer<String> retryer, final RemoteCall callable, final Recorder rec,
                           final boolean preInterrupted, boolean interruptDuringAttempt1) throws Exception {
        rec.log.clear();
        final Outcome o = new Outcome();
        Thread caller = new Thread(new Runnable() {
            @Override public void run() {
                if (preInterrupted) Thread.currentThread().interrupt();   // interrupted just before call()
                long t0 = System.nanoTime();
                try {
                    String v = retryer.call(callable);
                    o.kind = "returned normally"; o.detail = "value=" + v;
                } catch (ExecutionException e) {
                    o.kind = "ExecutionException"; o.detail = "cause=" + e.getCause();
                } catch (RetryException e) {
                    o.kind = "RetryException"; o.detail = "failedAttempts=" + e.getNumberOfFailedAttempts()
                            + ", last=" + describe(e.getLastFailedAttempt());
                } catch (Throwable e) {
                    o.kind = "unexpected"; o.detail = e.toString();
                }
                o.interruptedAfter = Thread.currentThread().isInterrupted();
                o.elapsedMs = TimeUnit.NANOSECONDS.toMillis(System.nanoTime() - t0);
            }
        }, "caller");
        caller.start();
        if (interruptDuringAttempt1) {
            if (!callable.firstStarted.await(10, TimeUnit.SECONDS)) throw new IllegalStateException("attempt 1 never started");
            waitUntilParked(caller);
            o.callerStackAtInterrupt = topFrames(caller, 8);
            caller.interrupt();
        }
        caller.join(30000);
        if (caller.isAlive()) { o.kind = "HUNG"; }
        o.invocations = callable.invocations.get();
        o.attempts = rec.log.toString();
        return o;
    }

    static RetryerBuilder<String> base(boolean timeLimited, Recorder rec) {
        RetryerBuilder<String> b = RetryerBuilder.<String>newBuilder().withRetryListener(rec);
        if (timeLimited) b.withAttemptTimeLimiter(AttemptTimeLimiters.<String>fixedTimeLimit(10, TimeUnit.SECONDS));
        return b;
    }

    static final String EXPECT = "RetryException with interrupt status set (Retryer.java:151-153)";
    static int failures = 0;      // harness/control problems
    static final List<String> bugs = new ArrayList<String>();

    static void report(String id, String arm, Outcome o) {
        System.out.println("  [" + arm + "] " + o);
        if (!o.callerStackAtInterrupt.isEmpty()) System.out.println("      caller stack when interrupted:" + o.callerStackAtInterrupt);
    }

    // ------------------------------------------------------------------ scenarios
    static void scenarioA() throws Exception {
        System.out.println("\n=== A: retryIfException() (stop=never, wait=none); caller interrupted while attempt 1 runs   [bfs5, bfs3]");
        System.out.println("  expected: " + EXPECT + "; no further attempt after the interrupt");
        Recorder rf = new Recorder(), rc = new Recorder();
        Outcome f = runCall(base(true, rf).retryIfException().build(), new RemoteCall(1), rf, false, true);
        report("A", "fixedTimeLimit", f);
        Outcome c = runCall(base(false, rc).retryIfException().build(), new RemoteCall(1), rc, false, true);
        report("A", "control       ", c);
        if (!c.contractHolds()) { failures++; System.out.println("  !! control did not follow the contract"); }
        if (f.kind.equals("returned normally") && !f.interruptedAfter && f.invocations >= 2) {
            bugs.add("A: interrupted call() retried, then RETURNED NORMALLY with interrupt status CLEAR (" + f.detail + ")");
            System.out.println("  >> BUG: interrupt swallowed; Retryer started attempt #2 after the interrupt and returned normally");
        }
    }

    static void scenarioB() throws Exception {
        System.out.println("\n=== B: retryIfExceptionOfType(IOException); thread already interrupted when call() starts   [narrow_bfs1, bfs1]");
        System.out.println("  expected: " + EXPECT);
        Recorder rf = new Recorder(), rc = new Recorder();
        Retryer<String> rfix = base(true, rf).retryIfExceptionOfType(IOException.class).build();
        Outcome first = null;
        int runs = 200, execExcClear = 0, zeroInvocations = 0, contractOk = 0;
        Map<String, Integer> dist = new TreeMap<String, Integer>();
        for (int i = 0; i < runs; i++) {
            Outcome f = runCall(rfix, new RemoteCall(1), rf, true, false);
            if (first == null) first = f;
            String key = f.kind + " / status=" + (f.interruptedAfter ? "set" : "clear") + " / invocations=" + f.invocations;
            Integer v = dist.get(key); dist.put(key, v == null ? 1 : v + 1);
            if (f.kind.equals("ExecutionException") && f.detail.contains("InterruptedException") && !f.interruptedAfter) execExcClear++;
            if (f.kind.equals("ExecutionException") && f.invocations == 0 && f.attempts.contains("#1 InterruptedException")) zeroInvocations++;
            if (f.contractHolds()) contractOk++;
        }
        report("B", "fixedTimeLimit", first);
        System.out.println("  [fixedTimeLimit] " + runs + " runs: " + dist);
        Recorder rc2 = rc;
        Outcome c = runCall(base(false, rc2).retryIfExceptionOfType(IOException.class).build(), new RemoteCall(1), rc2, true, false);
        report("B", "control       ", c);
        if (!c.contractHolds()) { failures++; System.out.println("  !! control did not follow the contract"); }
        if (execExcClear > 0) {
            bugs.add("B: " + execExcClear + "/" + runs + " runs threw ExecutionException(InterruptedException) with interrupt status CLEAR; "
                     + zeroInvocations + " of them counted attempt #1 although the callable was invoked 0 times");
            System.out.println("  >> BUG: ExecutionException(InterruptedException), status clear, in " + execExcClear + "/" + runs
                               + " runs; attempt #1 counted with 0 callable invocations in " + zeroInvocations + " runs");
        }
    }

    static void scenarioB2() throws Exception {
        System.out.println("\n=== B2: retryIfExceptionOfType(IOException); caller interrupted while attempt 1 runs");
        System.out.println("  expected: " + EXPECT);
        Recorder rf = new Recorder(), rc = new Recorder();
        Outcome f = runCall(base(true, rf).retryIfExceptionOfType(IOException.class).build(), new RemoteCall(1), rf, false, true);
        report("B2", "fixedTimeLimit", f);
        Outcome c = runCall(base(false, rc).retryIfExceptionOfType(IOException.class).build(), new RemoteCall(1), rc, false, true);
        report("B2", "control       ", c);
        if (!c.contractHolds()) { failures++; System.out.println("  !! control did not follow the contract"); }
        if (f.kind.equals("ExecutionException") && f.detail.contains("InterruptedException") && !f.interruptedAfter) {
            bugs.add("B2: ExecutionException(InterruptedException) with interrupt status CLEAR");
            System.out.println("  >> BUG: ExecutionException(InterruptedException) and the interrupt status is clear");
        }
    }

    static void scenarioC() throws Exception {
        System.out.println("\n=== C: retryIfException() + stopAfterAttempt(1); caller interrupted while attempt 1 runs   [ledger D-5 RetryException exit]");
        System.out.println("  expected: " + EXPECT);
        Recorder rf = new Recorder(), rc = new Recorder();
        Outcome f = runCall(base(true, rf).retryIfException().withStopStrategy(StopStrategies.stopAfterAttempt(1)).build(),
                            new RemoteCall(1), rf, false, true);
        report("C", "fixedTimeLimit", f);
        Outcome c = runCall(base(false, rc).retryIfException().withStopStrategy(StopStrategies.stopAfterAttempt(1)).build(),
                            new RemoteCall(1), rc, false, true);
        report("C", "control       ", c);
        if (!c.contractHolds()) { failures++; System.out.println("  !! control did not follow the contract"); }
        if (f.kind.equals("RetryException") && !f.interruptedAfter) {
            bugs.add("C: RetryException thrown but interrupt status CLEAR");
            System.out.println("  >> BUG: RetryException, but the caller's interrupt status is clear");
        }
    }

    /** A flaky service: each invocation works ~100 ms (cooperating with interrupts, status preserved) and
     *  fails while the service is down. */
    static final class FlakyService implements Callable<String> {
        volatile boolean down = true;
        volatile long attemptStartNanos;
        final AtomicInteger invocations = new AtomicInteger();
        @Override public String call() throws Exception {
            int n = invocations.incrementAndGet();
            attemptStartNanos = System.nanoTime();
            long deadline = attemptStartNanos + TimeUnit.MILLISECONDS.toNanos(100);
            while (System.nanoTime() < deadline) {
                if (Thread.currentThread().isInterrupted()) throw new InterruptedIOException("invocation " + n + " aborted by interrupt");
                LockSupport.parkNanos(1000000L);
            }
            if (down) throw new IOException("service unavailable (invocation " + n + ")");
            return "ok (invocation " + n + ")";
        }
    }

    static void scenarioD() throws Exception {
        System.out.println("\n=== D: real consumer -- ExecutorService.submit(retryer.wrap(svc)); shutdownNow(); awaitTermination(2 s)");
        System.out.println("  (retryIfException(), fixedWait(10 ms), stop=never; shutdownNow() interrupts the pool thread while an attempt is in flight)");
        System.out.println("  expected: the interrupted RetryerCallable ends with RetryException, the pool terminates, no further invocations");
        boolean[] arms = {true, false};
        boolean bug = false, controlOk = false;
        for (boolean timeLimited : arms) {
            final FlakyService svc = new FlakyService();
            final Thread[] poolThread = new Thread[1];
            ExecutorService pool = Executors.newSingleThreadExecutor(new ThreadFactory() {
                @Override public Thread newThread(Runnable r) { Thread t = new Thread(r, "pool-worker"); poolThread[0] = t; return t; }
            });
            RetryerBuilder<String> b = RetryerBuilder.<String>newBuilder().retryIfException()
                    .withWaitStrategy(WaitStrategies.fixedWait(10, TimeUnit.MILLISECONDS));
            if (timeLimited) b.withAttemptTimeLimiter(AttemptTimeLimiters.<String>fixedTimeLimit(10, TimeUnit.SECONDS));
            Future<String> f = pool.submit(b.build().wrap(svc));
            // wait until the retry loop is running and attempt >= 2 has just started (caller inside the attempt)
            long until = System.nanoTime() + TimeUnit.SECONDS.toNanos(10);
            while (true) {
                long age = System.nanoTime() - svc.attemptStartNanos;
                if (svc.invocations.get() >= 2 && age > TimeUnit.MILLISECONDS.toNanos(20) && age < TimeUnit.MILLISECONDS.toNanos(60)) break;
                if (System.nanoTime() > until) throw new IllegalStateException("retry loop not observed");
                Thread.sleep(1);
            }
            String stack = topFrames(poolThread[0], 6);
            int atShutdown = svc.invocations.get();
            long t0 = System.nanoTime();
            pool.shutdownNow();
            boolean terminated = pool.awaitTermination(2, TimeUnit.SECONDS);
            long waitedMs = TimeUnit.NANOSECONDS.toMillis(System.nanoTime() - t0);
            int afterWait = svc.invocations.get();
            svc.down = false;   // service recovers; lets a still-running retry loop finish
            boolean terminatedLater = pool.awaitTermination(10, TimeUnit.SECONDS);
            String result;
            try { result = "returned " + f.get(1, TimeUnit.SECONDS); }
            catch (ExecutionException e) { result = "ExecutionException(" + e.getCause() + ")"; }
            catch (Exception e) { result = e.toString(); }
            String arm = timeLimited ? "fixedTimeLimit" : "control       ";
            System.out.println("  [" + arm + "] invocations at shutdownNow=" + atShutdown + ", awaitTermination(2s)=" + terminated
                    + " after " + waitedMs + "ms, invocations started after shutdownNow=" + (afterWait - atShutdown)
                    + ", terminated after service recovered=" + terminatedLater + ", task outcome: " + result);
            System.out.println("      pool thread stack at shutdownNow:" + stack);
            if (timeLimited && !terminated && afterWait - atShutdown >= 2 && result.startsWith("returned")) bug = true;
            if (!timeLimited && terminated && afterWait - atShutdown <= 1 && result.contains("RetryException")) controlOk = true;
        }
        if (!controlOk) { failures++; System.out.println("  !! control did not follow the contract"); }
        if (bug) {
            bugs.add("D: after ExecutorService.shutdownNow() the retry loop kept invoking the service, awaitTermination(2s) returned false, and the task later returned normally");
            System.out.println("  >> BUG: shutdownNow() could not stop the retrying task; it kept calling the service and finally returned normally");
        }
    }

    // ---- F: completion racing the interrupt (statistical) ----
    static final class TrackingExecutor extends ThreadPoolExecutor {
        final List<FutureTask<?>> tasks = Collections.synchronizedList(new ArrayList<FutureTask<?>>());
        TrackingExecutor() { super(0, Integer.MAX_VALUE, 60L, TimeUnit.SECONDS, new SynchronousQueue<Runnable>()); } // = newCachedThreadPool
        @Override protected <T> RunnableFuture<T> newTaskFor(Callable<T> c) { FutureTask<T> t = new FutureTask<T>(c); tasks.add(t); return t; }
    }

    static void scenarioF() throws Exception {
        System.out.println("\n=== F: retryIfException() + stopAfterAttempt(3); attempt 1 returns at t0+offset, caller interrupted at t0   [bfs2]");
        System.out.println("  (user-supplied executor = newCachedThreadPool equivalent that keeps the FutureTasks for inspection; offset random in [-40,160] us)");
        final TrackingExecutor ex = new TrackingExecutor();
        final Recorder rec = new Recorder();
        final Retryer<String> r = RetryerBuilder.<String>newBuilder().retryIfException()
                .withStopStrategy(StopStrategies.stopAfterAttempt(3)).withRetryListener(rec)
                .withAttemptTimeLimiter(AttemptTimeLimiters.<String>fixedTimeLimit(10, TimeUnit.SECONDS, ex)).build();
        final Random rnd = new Random(4);
        int trials = 3000, onTime = 0, cancelledRetried = 0, discardedCompletion = 0, other = 0;
        String example = null;
        for (int i = 0; i < trials; i++) {
            ex.tasks.clear(); rec.log.clear();
            final AtomicLong t0 = new AtomicLong(0);
            final long offset = TimeUnit.MICROSECONDS.toNanos(rnd.nextInt(200) - 40);
            final AtomicInteger inv = new AtomicInteger();
            final AtomicReference<String> body1 = new AtomicReference<String>("not run");
            final Callable<String> c = new Callable<String>() {
                @Override public String call() {
                    int n = inv.incrementAndGet();
                    if (n == 1) {
                        long target = System.nanoTime() + TimeUnit.MICROSECONDS.toNanos(300);
                        t0.set(target);
                        while (System.nanoTime() < target + offset) { /* spin: work in progress */ }
                        body1.set("returned r1");
                        return "r1";
                    }
                    return "r" + n;
                }
            };
            final String[] res = new String[1];
            final boolean[] intrAfter = new boolean[1];
            Thread caller = new Thread(new Runnable() {
                @Override public void run() {
                    try { res[0] = r.call(c); } catch (Exception e) { res[0] = e.getClass().getSimpleName(); }
                    intrAfter[0] = Thread.interrupted();
                }
            });
            caller.start();
            while (t0.get() == 0) { Thread.yield(); }
            long target = t0.get();
            while (System.nanoTime() < target) { /* spin */ }
            caller.interrupt();
            caller.join(10000);
            FutureTask<?> task1 = ex.tasks.isEmpty() ? null : ex.tasks.get(0);
            boolean t1Completed = task1 != null && task1.isDone() && !task1.isCancelled();
            if ("r1".equals(res[0])) onTime++;   // completion published before the interrupt was observed: benign
            else if (res[0] != null && res[0].matches("r[23]") && !intrAfter[0] && rec.log.size() >= 2
                     && rec.log.get(0).startsWith("#1 InterruptedException")) {
                if (t1Completed) {
                    discardedCompletion++;
                    if (example == null) {
                        Object v; try { v = task1.get(); } catch (Exception e) { v = e; }
                        example = "attempt-1 FutureTask state: done, NOT cancelled, value=" + v + "; attempt-1 body: " + body1.get()
                                + "; listener: " + rec.log + "; call() returned " + res[0] + "; interrupt status after call: " + intrAfter[0]
                                + "; callable invocations: " + inv.get();
                    }
                } else cancelledRetried++;
            } else other++;
        }
        ex.shutdownNow();
        System.out.println("  [fixedTimeLimit] " + trials + " trials: attempt 1 result returned (benign)=" + onTime
                + ", attempt cancelled+retried with status cleared=" + cancelledRetried
                + ", COMPLETED attempt discarded+retried with status cleared=" + discardedCompletion + ", other=" + other);
        if (example != null) System.out.println("      example: " + example);
        if (cancelledRetried > 0) bugs.add("F: " + cancelledRetried + "/" + trials + " random-timing trials retried after the interrupt and returned with status clear");
        if (discardedCompletion > 0) {
            bugs.add("F: " + discardedCompletion + "/" + trials + " trials discarded an attempt whose FutureTask had COMPLETED (value r1) and re-ran the callable");
            System.out.println("  >> BUG: a completed attempt's result was discarded and the work repeated (bfs2)");
        }
    }

    public static void main(String[] args) throws Exception {
        System.out.println("java.version=" + System.getProperty("java.version") + "  vm=" + System.getProperty("java.vm.name"));
        scenarioA();
        scenarioB();
        scenarioB2();
        scenarioC();
        scenarioD();
        scenarioF();
        System.out.println("\n=== SUMMARY (" + System.getProperty("java.version") + ")");
        for (String b : bugs) System.out.println("  BUG  " + b);
        System.out.println("  controls (no time limiter) violating the contract: " + failures);
        boolean core = false;
        for (String b : bugs) if (b.startsWith("A:")) core = true;
        System.out.println(core && failures == 0 ? "RESULT: BUG REPRODUCED" : "RESULT: NOT REPRODUCED");
        System.out.flush();
        // fixedTimeLimit(d, unit) creates a cached pool per Retryer whose idle threads keep the JVM alive
        // for 60 s (upstream #92), so exit explicitly.
        System.exit(core && failures == 0 ? 0 : 1);
    }
}
JAVA
"$JAVAC" --release 8 -nowarn -encoding UTF-8 -cp "$BUILD/lib:$GUAVA:$JSR305" -d "$BUILD/test" "$BUILD/test/MC4Repro.java" 2>&1 \
  | grep -v -e '^Note:' -e 'warning' || true
test -f "$BUILD/test/MC4Repro.class"

# 3. Run on each JDK.
rc_all=0
for J in "${JAVAS[@]}"; do
  if ! "$J" -version >/dev/null 2>&1; then echo "== skip missing JVM $J"; continue; fi
  echo; echo "################ $("$J" -version 2>&1 | head -1)"
  set +e
  timeout 300 "$J" -cp "$BUILD/test:$BUILD/lib:$GUAVA:$JSR305" MC4Repro
  rc=$?
  set -e
  echo "== exit code: $rc"
  [ "$rc" -eq 0 ] || rc_all=1
done
exit $rc_all
