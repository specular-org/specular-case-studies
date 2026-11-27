import com.github.rholder.retry.*;

import java.io.IOException;
import java.io.InterruptedIOException;
import java.util.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.*;
import java.util.concurrent.locks.LockSupport;

public class MC4ReproR1 {

    // ------------------------------------------------------------------ user-side helpers
    /** RetryListener with one log per calling thread (a shared Retryer invokes it on every caller thread). */
    static final class Recorder implements RetryListener {
        final ConcurrentHashMap<Thread, List<String>> logs = new ConcurrentHashMap<Thread, List<String>>();
        List<String> of(Thread t) {
            List<String> l = logs.get(t);
            if (l == null) return new ArrayList<String>();
            synchronized (l) { return new ArrayList<String>(l); }
        }
        @Override public <V> void onRetry(Attempt<V> a) {
            Thread me = Thread.currentThread();
            List<String> l = logs.get(me);
            if (l == null) { l = Collections.synchronizedList(new ArrayList<String>()); logs.put(me, l); }
            String what = a.hasException() ? a.getExceptionCause().getClass().getSimpleName()
                                           : "result(" + a.getResult() + ")";
            l.add("#" + a.getAttemptNumber() + " " + what + (me.isInterrupted() ? " [interrupt pending]" : ""));
        }
    }

    /** User-supplied executor for fixedTimeLimit(d, unit, executor): newCachedThreadPool() semantics. For the watched
     *  callable it keeps each attempt's FutureTask and records whether that attempt's callable body was entered. */
    static final class TrackingExecutor extends ThreadPoolExecutor {
        static final class Task<T> extends FutureTask<T> {
            final AtomicBoolean bodyEntered;
            Task(final Callable<T> c, final AtomicBoolean entered) {
                super(new Callable<T>() {
                    @Override public T call() throws Exception { entered.set(true); return c.call(); }
                });
                this.bodyEntered = entered;
            }
        }
        volatile Callable<?> watched;
        final List<Task<?>> watchedTasks = Collections.synchronizedList(new ArrayList<Task<?>>());
        TrackingExecutor() { super(0, Integer.MAX_VALUE, 60L, TimeUnit.SECONDS, new SynchronousQueue<Runnable>()); }
        void watch(Callable<?> c) { watchedTasks.clear(); watched = c; }
        Task<?> first() { synchronized (watchedTasks) { return watchedTasks.isEmpty() ? null : watchedTasks.get(0); } }
        @Override protected <T> RunnableFuture<T> newTaskFor(Callable<T> c) {
            Task<T> t = new Task<T>(c, new AtomicBoolean());
            if (c == watched) watchedTasks.add(t);
            return t;
        }
    }

    /** A flaky remote service: each invocation works ~100 ms, cooperates with interruption (throws
     *  InterruptedIOException and leaves the interrupt status SET, the NIO convention), fails while the service is down. */
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

    /** The application's task: runs the wrapped retryer and records how RetryerCallable.call() ended. */
    static final class AppTask implements Callable<String> {
        final Retryer.RetryerCallable<String> rc;
        final AtomicReference<String> outcome = new AtomicReference<String>("still running");
        final AtomicBoolean statusAfter = new AtomicBoolean();
        final AtomicLong endNanos = new AtomicLong();
        AppTask(Retryer.RetryerCallable<String> rc) { this.rc = rc; }
        @Override public String call() throws Exception {
            try { String v = rc.call(); outcome.set("returned " + v); return v; }
            catch (Exception e) { outcome.set(e.getClass().getSimpleName() + ": " + e.getMessage()); throw e; }
            finally { statusAfter.set(Thread.currentThread().isInterrupted()); endNanos.set(System.nanoTime()); }
        }
    }

    static ExecutorService singleThreadPool(final Thread[] holder, final String name) {
        return Executors.newSingleThreadExecutor(new ThreadFactory() {
            @Override public Thread newThread(Runnable r) { Thread t = new Thread(r, name); holder[0] = t; return t; }
        });
    }

    static String topFrames(Thread t, int n) {
        StringBuilder sb = new StringBuilder();
        StackTraceElement[] st = t.getStackTrace();
        for (int i = 0; i < Math.min(n, st.length); i++) sb.append("\n        at ").append(st[i]);
        return sb.toString();
    }

    static String abbreviate(List<String> l) {
        if (l.size() <= 6) return l.toString();
        return "[" + l.get(0) + ", " + l.get(1) + ", " + l.get(2) + ", ... (" + l.size() + " attempts in total) ..., "
               + l.get(l.size() - 2) + ", " + l.get(l.size() - 1) + "]";
    }

    static long ms(long nanos) { return TimeUnit.NANOSECONDS.toMillis(nanos); }

    static String taskState(TrackingExecutor.Task<?> t) {
        if (t == null) return "no task";
        if (t.isCancelled()) return "cancelled, callable " + (t.bodyEntered.get() ? "entered" : "NEVER entered");
        if (!t.isDone()) return "not done";
        try { return "done NOT cancelled, value=" + t.get(); }
        catch (ExecutionException e) { return "done NOT cancelled, threw " + e.getCause(); }
        catch (Exception e) { return "done, " + e; }
    }

    static final String EXPECT = "RetryException with interrupt status set, no further attempt (Retryer.java:59-61, 151-153)";
    static int failures = 0;      // controls that did not follow the contract, or anomalies on the non-interrupted sharer
    static final List<String> bugs = new ArrayList<String>();
    static boolean w1Bug = false;
    static int s1Cir = 0;

    // ------------------------------------------------------------------ W1
    static void scenarioW1() throws Exception {
        System.out.println("\n=== W1: outer.cancel(true) of ExecutorService.submit(<task running retryer.wrap(svc)>) while attempt 1 is in flight   [repair1_ctl_s2_wrap_cancel_ndc: MCCancelOuter]");
        System.out.println("  retryIfException(), fixedWait(10 ms), stop=never; cancel(true) interrupts the pool thread running RetryerCallable.call() -> Retryer.call()");
        System.out.println("  expected: " + EXPECT + "; no invocation after cancel; the pool thread is free for the next task");
        boolean controlOk = false;
        for (boolean timeLimited : new boolean[] {true, false}) {
            final FlakyService svc = new FlakyService();
            final Recorder rec = new Recorder();
            final Thread[] poolThread = new Thread[1];
            ExecutorService pool = singleThreadPool(poolThread, "app-pool");
            RetryerBuilder<String> b = RetryerBuilder.<String>newBuilder().retryIfException().withRetryListener(rec)
                    .withWaitStrategy(WaitStrategies.fixedWait(10, TimeUnit.MILLISECONDS));
            if (timeLimited) b.withAttemptTimeLimiter(AttemptTimeLimiters.<String>fixedTimeLimit(10, TimeUnit.SECONDS));
            AppTask task = new AppTask(b.build().wrap(svc));
            Future<String> outer = pool.submit(task);
            long until = System.nanoTime() + TimeUnit.SECONDS.toNanos(10);
            while (true) {   // attempt 1 in flight for 20-60 ms: the pool thread is parked (in future.get, or in the callable)
                long age = System.nanoTime() - svc.attemptStartNanos;
                if (svc.invocations.get() >= 1 && age > TimeUnit.MILLISECONDS.toNanos(20) && age < TimeUnit.MILLISECONDS.toNanos(60)) break;
                if (System.nanoTime() > until) throw new IllegalStateException("attempt 1 never observed");
                Thread.sleep(1);
            }
            String stack = topFrames(poolThread[0], 7);
            int atCancel = svc.invocations.get();
            long t0 = System.nanoTime();
            boolean cancelResult = outer.cancel(true);
            Future<Long> probe = pool.submit(new Callable<Long>() { @Override public Long call() { return System.nanoTime(); } });
            Long probeStart = null;
            try { probeStart = probe.get(2, TimeUnit.SECONDS); } catch (TimeoutException e) { /* pool thread still busy */ }
            int after2s = svc.invocations.get();
            svc.down = false;                          // the service recovers: lets a still-running retry loop finish
            if (probeStart == null) probeStart = probe.get(15, TimeUnit.SECONDS);
            String outerGet;
            try { outerGet = "returned " + outer.get(1, TimeUnit.SECONDS); } catch (CancellationException e) { outerGet = "CancellationException"; }
            List<String> log = rec.of(poolThread[0]);
            pool.shutdown();
            pool.awaitTermination(5, TimeUnit.SECONDS);
            int startedAfter = after2s - atCancel;
            long probeDelay = ms(probeStart - t0);
            String arm = timeLimited ? "fixedTimeLimit" : "control       ";
            System.out.println("  [" + arm + "] outer.cancel(true)=" + cancelResult + ", outer.get(): " + outerGet
                    + "; invocations at cancel=" + atCancel + ", invocations started in the 2 s after cancel=" + startedAfter
                    + ", next task on the pool started " + probeDelay + " ms after cancel");
            System.out.println("      RetryerCallable.call(): " + task.outcome.get() + ", interrupt status after call()=" + task.statusAfter.get()
                    + ", ended " + ms(task.endNanos.get() - t0) + " ms after cancel");
            System.out.println("      listener (pool thread): " + abbreviate(log));
            System.out.println("      pool thread stack at cancel:" + stack);
            if (timeLimited && cancelResult && startedAfter >= 2 && probeDelay >= 2000
                    && task.outcome.get().startsWith("returned") && !task.statusAfter.get()) w1Bug = true;
            if (!timeLimited && cancelResult && startedAfter == 0 && probeDelay < 1000
                    && task.outcome.get().startsWith("RetryException") && task.statusAfter.get()) controlOk = true;
        }
        if (!controlOk) { failures++; System.out.println("  !! control did not follow the contract"); }
        if (w1Bug) {
            bugs.add("W1: after outer.cancel(true) returned true, the wrapped retry loop kept invoking the service, held the pool thread, and RetryerCallable.call() finally RETURNED NORMALLY with interrupt status CLEAR");
            System.out.println("  >> BUG: cancel(true) of the wrapped task was swallowed; the retry loop kept calling the service and returned normally with the status clear");
        }
    }

    // ------------------------------------------------------------------ W2
    static void scenarioW2() throws Exception {
        System.out.println("\n=== W2: attempt 1 completes at t0+offset, outer.cancel(true) of the wrapped task at t0 (statistical, Level 1)   [repair1_ctl_s2_wrap_cancel_ndc: NoDiscardedCompletion]");
        System.out.println("  retryIfException() + stopAfterAttempt(3), fixedTimeLimit(10 s, user executor keeping each attempt's FutureTask); offset random in [-40,160] us");
        System.out.println("  even trials: attempt 1 returns r1 (NORMAL); odd trials: attempt 1 throws IOException (EXCEPTIONAL, as the trace's MCBodyThrows)");
        final TrackingExecutor ex = new TrackingExecutor();
        final Recorder rec = new Recorder();
        final Retryer<String> r = RetryerBuilder.<String>newBuilder().retryIfException()
                .withStopStrategy(StopStrategies.stopAfterAttempt(3)).withRetryListener(rec)
                .withAttemptTimeLimiter(AttemptTimeLimiters.<String>fixedTimeLimit(10, TimeUnit.SECONDS, ex)).build();
        final Thread[] poolThread = new Thread[1];
        final ExecutorService pool = singleThreadPool(poolThread, "app-pool");
        final Random rnd = new Random(11);
        final int trials = 4000;
        // per mode: 0 observed attempt-1 outcome, 1 observed but swallowed in a later attempt, 2 attempt cancelled + retried,
        //           3 COMPLETED attempt discarded + retried, 4 other
        int[][] cnt = new int[2][5];
        String[] example = new String[2];
        for (int i = 0; i < trials; i++) {
            final int mode = i % 2;
            rec.logs.clear();
            final AtomicLong t0 = new AtomicLong();
            final long offset = TimeUnit.MICROSECONDS.toNanos(rnd.nextInt(200) - 40);
            final AtomicInteger inv = new AtomicInteger();
            final Callable<String> c = new Callable<String>() {
                @Override public String call() throws Exception {
                    int n = inv.incrementAndGet();
                    if (n == 1) {
                        long target = System.nanoTime() + TimeUnit.MICROSECONDS.toNanos(300);
                        t0.set(target);
                        while (System.nanoTime() < target + offset) { /* work in progress */ }
                        if (mode == 1) throw new IOException("attempt-1 failed");
                        return "r1";
                    }
                    return "r" + n;
                }
            };
            ex.watch(c);
            AppTask task = new AppTask(r.wrap(c));
            Future<String> outer = pool.submit(task);
            while (t0.get() == 0) Thread.yield();
            long target = t0.get();
            while (System.nanoTime() < target) { /* spin */ }
            boolean cancelResult = outer.cancel(true);
            pool.submit(new Runnable() { @Override public void run() { } }).get(10, TimeUnit.SECONDS);  // FIFO: the wrapped call has ended
            TrackingExecutor.Task<?> t1 = ex.first();
            List<String> log = rec.of(poolThread[0]);
            String first = log.isEmpty() ? "" : log.get(0);
            int k;
            if (first.startsWith("#1 InterruptedException")) {
                if (t1 != null && t1.isCancelled()) k = 2;
                else if (t1 != null && t1.isDone()) k = 3;
                else k = 4;
            } else if (first.startsWith("#1 result(r1)") || first.startsWith("#1 IOException")) {
                k = log.toString().contains("InterruptedException") && !task.statusAfter.get() ? 1 : 0;
            } else k = 4;
            cnt[mode][k]++;
            if (k == 3 && example[mode] == null) {
                example[mode] = "outer.cancel(true)=" + cancelResult + "; attempt-1 FutureTask: " + taskState(t1)
                        + "; listener: " + log + "; RetryerCallable.call(): " + task.outcome.get()
                        + "; interrupt status after: " + task.statusAfter.get() + "; callable invocations: " + inv.get();
            }
        }
        pool.shutdownNow();
        ex.shutdownNow();
        String[] names = {"NORMAL", "EXCEPTIONAL"};
        int ndc = 0;
        for (int m = 0; m < 2; m++) {
            System.out.println("  [fixedTimeLimit, attempt 1 " + names[m] + "] " + trials / 2 + " trials: attempt-1 outcome observed (benign)=" + cnt[m][0]
                    + ", observed but interrupt swallowed in a later attempt=" + cnt[m][1]
                    + ", attempt cancelled+retried after cancel(true)=" + cnt[m][2]
                    + ", COMPLETED attempt discarded+retried=" + cnt[m][3] + ", other=" + cnt[m][4]);
            if (example[m] != null) System.out.println("      example: " + example[m]);
            ndc += cnt[m][3];
        }
        if (cnt[0][2] + cnt[1][2] > 0)
            bugs.add("W2: " + (cnt[0][2] + cnt[1][2]) + "/" + trials + " trials: after outer.cancel(true) the interrupted attempt was cancelled and the callable re-run (status clear)");
        if (ndc > 0) {
            bugs.add("W2: " + ndc + "/" + trials + " trials discarded an attempt whose FutureTask had COMPLETED (NORMAL " + cnt[0][3]
                     + ", EXCEPTIONAL " + cnt[1][3] + ") and re-ran the callable after outer.cancel(true)");
            System.out.println("  >> BUG: NoDiscardedCompletion reached through cancel(true) of a wrapped task");
        }
    }

    // ------------------------------------------------------------------ S1 + S2
    static void scenarioS() throws Exception {
        System.out.println("\n=== S: two threads share ONE Retryer (one fixedTimeLimit, one executor); c2 calls it continuously while c1 is interrupted   [repair1_ctl_sharing_cir, repair1_ctl_sharing_ndc]");
        System.out.println("  retryIfException() + stopAfterAttempt(3), fixedTimeLimit(10 s, shared user executor); c2 is never interrupted");
        System.out.println("  expected for c1: " + EXPECT + "; expected for c2: every call returns its result after 1 attempt, status clear");
        final TrackingExecutor ex = new TrackingExecutor();
        final Recorder rec = new Recorder();
        final Retryer<String> shared = RetryerBuilder.<String>newBuilder().retryIfException()
                .withStopStrategy(StopStrategies.stopAfterAttempt(3)).withRetryListener(rec)
                .withAttemptTimeLimiter(AttemptTimeLimiters.<String>fixedTimeLimit(10, TimeUnit.SECONDS, ex)).build();
        final AtomicBoolean stop = new AtomicBoolean();
        final AtomicInteger c2Calls = new AtomicInteger(), c2Anomalies = new AtomicInteger();
        final AtomicReference<String> c2First = new AtomicReference<String>();
        Thread c2 = new Thread(new Runnable() {
            @Override public void run() {
                final Callable<String> fast = new Callable<String>() { @Override public String call() { return "c2-ok"; } };
                while (!stop.get()) {
                    String res;
                    try { res = shared.call(fast); } catch (Exception e) { res = e.toString(); }
                    boolean intr = Thread.interrupted();
                    List<String> l = rec.of(Thread.currentThread());
                    rec.logs.remove(Thread.currentThread());
                    if (!"c2-ok".equals(res) || intr || l.size() != 1) {
                        c2Anomalies.incrementAndGet();
                        c2First.compareAndSet(null, res + ", interrupted=" + intr + ", listener=" + l);
                    }
                    c2Calls.incrementAndGet();
                }
            }
        }, "c2");
        c2.start();
        while (c2Calls.get() < 50) Thread.sleep(1);

        // S1: c1 enters call() with its interrupt status already set (the trace interrupts c1 right after it submitted t1).
        final int s1Runs = 200;
        Map<String, Integer> dist = new TreeMap<String, Integer>();
        String s1Example = null;
        for (int i = 0; i < s1Runs; i++) {
            final AtomicInteger inv = new AtomicInteger();
            final Callable<String> c = new Callable<String>() { @Override public String call() { inv.incrementAndGet(); return "c1-ok"; } };
            ex.watch(c);
            final Object[] res = new Object[1];
            final boolean[] intrAfter = new boolean[1];
            Thread c1 = new Thread(new Runnable() {
                @Override public void run() {
                    Thread.currentThread().interrupt();
                    try { res[0] = shared.call(c); } catch (Exception e) { res[0] = e; }
                    intrAfter[0] = Thread.currentThread().isInterrupted();
                }
            }, "c1");
            c1.start();
            c1.join(10000);
            TrackingExecutor.Task<?> t1 = ex.first();
            List<String> log = rec.of(c1);
            rec.logs.remove(c1);
            boolean a1NeverRan = t1 != null && t1.isCancelled() && !t1.bodyEntered.get();
            String kind = res[0] instanceof Exception ? res[0].getClass().getSimpleName() : "returned " + res[0];
            String key = kind + " / status=" + (intrAfter[0] ? "set" : "clear") + " / " + (log.isEmpty() ? "?" : log.get(0))
                         + (a1NeverRan ? " (attempt-1 callable NEVER entered)" : " (attempt-1 callable entered)");
            Integer v = dist.get(key);
            dist.put(key, v == null ? 1 : v + 1);
            if (a1NeverRan && !log.isEmpty() && log.get(0).startsWith("#1 InterruptedException")) {
                s1Cir++;
                if (s1Example == null) s1Example = "attempt-1 FutureTask: " + taskState(t1) + "; listener: " + log + "; call(): " + kind
                                                   + "; interrupt status after: " + intrAfter[0] + "; callable invocations: " + inv.get();
            }
        }
        System.out.println("  [S1 c1 pre-interrupted] " + s1Runs + " runs: " + dist);
        if (s1Example != null) System.out.println("      example: " + s1Example);
        if (s1Cir > 0) {
            bugs.add("S1: " + s1Cir + "/" + s1Runs + " runs on the shared Retryer counted attempt #1 (InterruptedException) whose callable was NEVER entered, then retried and returned with interrupt status CLEAR");
            System.out.println("  >> BUG: attempt counted with 0 invocations, interrupt swallowed, retry continued (CountedImpliesInvokedNoStartRace + InterruptPreserved)");
        }

        // S2: c1's attempt 1 completes at t0+offset, c1 interrupted at t0 (as F of the base repro), c2 still running.
        final int s2Trials = 3000;
        int[] cnt = new int[5];
        String s2Example = null;
        final Random rnd = new Random(5);
        for (int i = 0; i < s2Trials; i++) {
            final AtomicLong t0 = new AtomicLong();
            final long offset = TimeUnit.MICROSECONDS.toNanos(rnd.nextInt(200) - 40);
            final AtomicInteger inv = new AtomicInteger();
            final Callable<String> c = new Callable<String>() {
                @Override public String call() {
                    int n = inv.incrementAndGet();
                    if (n == 1) {
                        long target = System.nanoTime() + TimeUnit.MICROSECONDS.toNanos(300);
                        t0.set(target);
                        while (System.nanoTime() < target + offset) { /* work in progress */ }
                        return "r1";
                    }
                    return "r" + n;
                }
            };
            ex.watch(c);
            final Object[] res = new Object[1];
            final boolean[] intrAfter = new boolean[1];
            Thread c1 = new Thread(new Runnable() {
                @Override public void run() {
                    try { res[0] = shared.call(c); } catch (Exception e) { res[0] = e; }
                    intrAfter[0] = Thread.interrupted();
                }
            }, "c1");
            c1.start();
            while (t0.get() == 0) Thread.yield();
            long target = t0.get();
            while (System.nanoTime() < target) { /* spin */ }
            c1.interrupt();
            c1.join(10000);
            TrackingExecutor.Task<?> t1 = ex.first();
            List<String> log = rec.of(c1);
            rec.logs.remove(c1);
            String first = log.isEmpty() ? "" : log.get(0);
            int k;
            if (first.startsWith("#1 InterruptedException")) {
                if (t1 != null && t1.isCancelled()) k = 2;
                else if (t1 != null && t1.isDone()) k = 3;
                else k = 4;
            } else if (first.startsWith("#1 result(r1)")) k = 0;
            else k = 4;
            cnt[k]++;
            if (k == 3 && s2Example == null) {
                s2Example = "attempt-1 FutureTask: " + taskState(t1) + "; listener: " + log + "; call() returned " + res[0]
                            + "; interrupt status after: " + intrAfter[0] + "; callable invocations: " + inv.get();
            }
        }
        System.out.println("  [S2 c1 interrupted at t0] " + s2Trials + " trials: attempt-1 result returned (benign)=" + cnt[0]
                + ", attempt cancelled+retried with status cleared=" + cnt[2]
                + ", COMPLETED attempt discarded+retried=" + cnt[3] + ", other=" + cnt[4]);
        if (s2Example != null) System.out.println("      example: " + s2Example);
        if (cnt[3] > 0) {
            bugs.add("S2: " + cnt[3] + "/" + s2Trials + " trials on the shared Retryer discarded c1's COMPLETED attempt (value r1) and re-ran the callable");
            System.out.println("  >> BUG: NoDiscardedCompletion on the shared Retryer");
        }

        stop.set(true);
        c2.join(10000);
        ex.shutdownNow();
        System.out.println("  [c2, sharing the Retryer, never interrupted] " + c2Calls.get() + " calls during S, anomalies=" + c2Anomalies.get()
                + (c2First.get() == null ? "" : " (first: " + c2First.get() + ")"));
        if (c2Anomalies.get() > 0) { failures++; System.out.println("  !! the non-interrupted sharer saw an anomaly"); }
    }

    public static void main(String[] args) throws Exception {
        System.out.println("java.version=" + System.getProperty("java.version") + "  vm=" + System.getProperty("java.vm.name"));
        scenarioW1();
        scenarioW2();
        scenarioS();
        System.out.println("\n=== SUMMARY (" + System.getProperty("java.version") + ")");
        for (String b : bugs) System.out.println("  BUG  " + b);
        System.out.println("  controls violating the contract + anomalies on the non-interrupted sharer: " + failures);
        boolean core = w1Bug && s1Cir > 0 && failures == 0;
        System.out.println(core ? "RESULT: BUG REPRODUCED" : "RESULT: NOT REPRODUCED");
        System.out.flush();
        // fixedTimeLimit(d, unit) creates a cached pool per Retryer whose idle threads keep the JVM alive for 60 s (#92).
        System.exit(core ? 0 : 1);
    }
}
