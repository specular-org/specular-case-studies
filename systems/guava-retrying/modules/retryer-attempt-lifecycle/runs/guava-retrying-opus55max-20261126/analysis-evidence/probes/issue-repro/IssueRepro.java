import com.github.rholder.retry.*;
import com.google.common.base.Predicates;

import java.io.IOException;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicInteger;

/** Executes guava-retrying 2.0.0 (compiled unmodified) to check issue claims. Not a test suite. */
public class IssueRepro {

    static void p(String s) { System.out.println(s); }

    static String describe(Throwable t) {
        if (t == null) return "null";
        String s = t.getClass().getName();
        if (t.getCause() != null) s += " <- " + describe(t.getCause());
        return s;
    }

    static <V> void run(String label, Retryer<V> r, Callable<V> c) {
        long t0 = System.nanoTime();
        String out;
        try {
            V v = r.call(c);
            out = "RETURNED " + v;
        } catch (RetryException e) {
            out = "RetryException(numberOfFailedAttempts=" + e.getNumberOfFailedAttempts() + ") cause=" + describe(e.getCause());
        } catch (ExecutionException e) {
            out = "ExecutionException cause=" + describe(e.getCause());
        } catch (Throwable t) {
            out = "RAW " + describe(t) + " msg=" + t.getMessage();
        }
        long ms = TimeUnit.NANOSECONDS.toMillis(System.nanoTime() - t0);
        p(label + " -> " + out + " | interrupted=" + Thread.currentThread().isInterrupted() + " | " + ms + "ms");
        Thread.interrupted(); // reset for next case
    }

    static Attempt<Object> fakeAttempt(final long n) {
        return new Attempt<Object>() {
            public Object get() { return null; }
            public boolean hasResult() { return true; }
            public boolean hasException() { return false; }
            public Object getResult() { return null; }
            public Throwable getExceptionCause() { throw new IllegalStateException(); }
            public long getAttemptNumber() { return n; }
            public long getDelaySinceFirstAttempt() { return 0; }
        };
    }

    public static void main(String[] args) throws Exception {
        String which = args.length > 0 ? args[0] : "all";
        p("guava SimpleTimeLimiter from: " + com.google.common.util.concurrent.SimpleTimeLimiter.class.getProtectionDomain().getCodeSource().getLocation());

        if (which.equals("all") || which.equals("i29")) {
            final AtomicInteger calls = new AtomicInteger();
            Callable<String> slow = new Callable<String>() {
                public String call() throws Exception { calls.incrementAndGet(); Thread.sleep(2000); return "late"; }
            };
            run("#29 a: timeout, predicate=retryIfExceptionOfType(IOException), stopAfterAttempt(3)",
                RetryerBuilder.<String>newBuilder()
                    .withAttemptTimeLimiter(AttemptTimeLimiters.<String>fixedTimeLimit(200, TimeUnit.MILLISECONDS))
                    .retryIfExceptionOfType(IOException.class)
                    .withStopStrategy(StopStrategies.stopAfterAttempt(3)).build(), slow);
            p("   callable invocations=" + calls.getAndSet(0));
            run("#29 b: timeout, predicate=retryIfRuntimeException(), stopAfterAttempt(3)",
                RetryerBuilder.<String>newBuilder()
                    .withAttemptTimeLimiter(AttemptTimeLimiters.<String>fixedTimeLimit(200, TimeUnit.MILLISECONDS))
                    .retryIfRuntimeException()
                    .withStopStrategy(StopStrategies.stopAfterAttempt(3)).build(), slow);
            p("   callable invocations=" + calls.getAndSet(0));
        }

        if (which.equals("all") || which.equals("q1overlap")) {
            final AtomicInteger running = new AtomicInteger();
            final AtomicInteger maxRunning = new AtomicInteger();
            final AtomicInteger calls = new AtomicInteger();
            Callable<String> stubborn = new Callable<String>() {
                public String call() {
                    calls.incrementAndGet();
                    int now = running.incrementAndGet();
                    maxRunning.accumulateAndGet(now, Math::max);
                    long end = System.nanoTime() + TimeUnit.MILLISECONDS.toNanos(700);
                    while (System.nanoTime() < end) { /* ignores interrupt */ }
                    running.decrementAndGet();
                    return "done";
                }
            };
            run("Q1 overlap: interrupt-ignoring 700ms callable, fixedTimeLimit(100ms), retryIfRuntimeException, stopAfterAttempt(4)",
                RetryerBuilder.<String>newBuilder()
                    .withAttemptTimeLimiter(AttemptTimeLimiters.<String>fixedTimeLimit(100, TimeUnit.MILLISECONDS))
                    .retryIfRuntimeException()
                    .withStopStrategy(StopStrategies.stopAfterAttempt(4)).build(), stubborn);
            p("   callable invocations=" + calls.get() + " maxConcurrentExecutionsOfSameCallable=" + maxRunning.get()
                + " stillRunningAfterCallReturned=" + running.get());
            Thread.sleep(1000);
        }

        if (which.equals("all") || which.equals("q2")) {
            final AtomicInteger calls = new AtomicInteger();
            final Callable<String> sleeper = new Callable<String>() {
                public String call() throws Exception { calls.incrementAndGet(); Thread.sleep(300); return "ok"; }
            };
            final Thread me = Thread.currentThread();
            ScheduledExecutorService ses = Executors.newSingleThreadScheduledExecutor();
            ses.schedule(new Runnable() { public void run() { me.interrupt(); } }, 100, TimeUnit.MILLISECONDS);
            run("Q2 a: caller interrupted during timed attempt; fixedTimeLimit(5s), retryIfException(), stopAfterAttempt(3)",
                RetryerBuilder.<String>newBuilder()
                    .withAttemptTimeLimiter(AttemptTimeLimiters.<String>fixedTimeLimit(5, TimeUnit.SECONDS))
                    .retryIfException()
                    .withStopStrategy(StopStrategies.stopAfterAttempt(3)).build(), sleeper);
            p("   callable invocations=" + calls.getAndSet(0));
            ses.schedule(new Runnable() { public void run() { me.interrupt(); } }, 100, TimeUnit.MILLISECONDS);
            run("Q2 b: caller interrupted during timed attempt; fixedTimeLimit(5s), no retry predicate",
                RetryerBuilder.<String>newBuilder()
                    .withAttemptTimeLimiter(AttemptTimeLimiters.<String>fixedTimeLimit(5, TimeUnit.SECONDS))
                    .build(), sleeper);
            p("   callable invocations=" + calls.getAndSet(0));
            ses.schedule(new Runnable() { public void run() { me.interrupt(); } }, 100, TimeUnit.MILLISECONDS);
            run("Q2 c: caller interrupted inside callable (noTimeLimit), retryIfException(), stopAfterAttempt(3)",
                RetryerBuilder.<String>newBuilder()
                    .retryIfException()
                    .withStopStrategy(StopStrategies.stopAfterAttempt(3)).build(), sleeper);
            p("   callable invocations=" + calls.getAndSet(0));
            ses.shutdownNow();
        }

        if (which.equals("all") || which.equals("i48")) {
            final AtomicInteger l1 = new AtomicInteger(), l2 = new AtomicInteger();
            RetryerBuilder<String> b = RetryerBuilder.<String>newBuilder()
                .withRetryListener(new RetryListener() { public <V> void onRetry(Attempt<V> a) { l1.incrementAndGet(); } });
            Retryer<String> first = b.build();
            b.withRetryListener(new RetryListener() { public <V> void onRetry(Attempt<V> a) { l2.incrementAndGet(); } });
            run("#48 a: first Retryer built before 2nd listener was added", first, new Callable<String>() { public String call() { return "x"; } });
            p("   listener1 calls=" + l1.get() + " listener2 calls=" + l2.get() + " (listener2 should be 0 if Retryer had its own copy)");

            final RetryerBuilder<String> b2 = RetryerBuilder.<String>newBuilder();
            b2.withRetryListener(new RetryListener() {
                public <V> void onRetry(Attempt<V> a) {
                    b2.withRetryListener(new RetryListener() { public <W> void onRetry(Attempt<W> x) { } });
                }
            });
            Retryer<String> r2 = b2.build();
            run("#48 b: builder mutated while built Retryer iterates listeners", r2, new Callable<String>() { public String call() { return "x"; } });
        }

        if (which.equals("all") || which.equals("i67")) {
            final AtomicInteger calls = new AtomicInteger();
            Callable<String> err = new Callable<String>() { public String call() { calls.incrementAndGet(); throw new StackOverflowError("simulated"); } };
            run("#67 a: callable throws Error, no predicate", RetryerBuilder.<String>newBuilder().build(), err);
            p("   callable invocations=" + calls.getAndSet(0));
            run("#67 b: callable throws Error, retryIfException(Predicates.alwaysTrue()), stopAfterAttempt(3)",
                RetryerBuilder.<String>newBuilder().retryIfException(Predicates.<Throwable>alwaysTrue())
                    .withStopStrategy(StopStrategies.stopAfterAttempt(3)).build(), err);
            p("   callable invocations=" + calls.getAndSet(0));
            run("#67 c: callable throws Error, retryIfException() (Exception.class)",
                RetryerBuilder.<String>newBuilder().retryIfException()
                    .withStopStrategy(StopStrategies.stopAfterAttempt(3)).build(), err);
            p("   callable invocations=" + calls.getAndSet(0));
        }

        if (which.equals("all") || which.equals("q4")) {
            final AtomicInteger calls = new AtomicInteger();
            Callable<String> failing = new Callable<String>() { public String call() throws Exception { calls.incrementAndGet(); throw new IOException("boom"); } };
            run("Q4 a: RetryListener throws on 1st attempt, retryIfException, stopAfterAttempt(3)",
                RetryerBuilder.<String>newBuilder().retryIfException()
                    .withRetryListener(new RetryListener() { public <V> void onRetry(Attempt<V> a) { throw new IllegalStateException("listener bug"); } })
                    .withStopStrategy(StopStrategies.stopAfterAttempt(3)).build(), failing);
            p("   callable invocations=" + calls.getAndSet(0));
            run("Q4/Q5 b: join(fixedWait(Long.MAX_VALUE ms), fixedWait(1 ms)) wait strategy",
                RetryerBuilder.<String>newBuilder().retryIfException()
                    .withWaitStrategy(WaitStrategies.join(WaitStrategies.fixedWait(Long.MAX_VALUE, TimeUnit.MILLISECONDS), WaitStrategies.fixedWait(1, TimeUnit.MILLISECONDS)))
                    .withStopStrategy(StopStrategies.stopAfterAttempt(3)).build(), failing);
            p("   callable invocations=" + calls.getAndSet(0));
            run("Q5 c: fixedTimeLimit(0 ms) accepted; retryIfRuntimeException, stopAfterAttempt(3)",
                RetryerBuilder.<String>newBuilder().retryIfRuntimeException()
                    .withAttemptTimeLimiter(AttemptTimeLimiters.<String>fixedTimeLimit(0, TimeUnit.MILLISECONDS))
                    .withStopStrategy(StopStrategies.stopAfterAttempt(3)).build(), failing);
            p("   callable invocations=" + calls.getAndSet(0));
        }

        if (which.equals("all") || which.equals("q5")) {
            WaitStrategy inc = WaitStrategies.incrementingWait(1, TimeUnit.DAYS, Long.MAX_VALUE, TimeUnit.DAYS);
            p("Q5 incrementingWait(1 DAY, +Long.MAX_VALUE DAYS): attempt1=" + inc.computeSleepTime(fakeAttempt(1))
                + " attempt2=" + inc.computeSleepTime(fakeAttempt(2)) + " attempt3=" + inc.computeSleepTime(fakeAttempt(3)));
            WaitStrategy fib = WaitStrategies.fibonacciWait();
            p("Q5 fibonacciWait(): n=92 -> " + fib.computeSleepTime(fakeAttempt(92)) + " n=93 -> " + fib.computeSleepTime(fakeAttempt(93))
                + " n=94 -> " + fib.computeSleepTime(fakeAttempt(94)));
            WaitStrategy fibm = WaitStrategies.fibonacciWait(1000, Long.MAX_VALUE, TimeUnit.MILLISECONDS);
            long prev = 0; StringBuilder drops = new StringBuilder();
            for (int n = 1; n <= 200; n++) {
                long v = fibm.computeSleepTime(fakeAttempt(n));
                if (v < prev) drops.append(" n=").append(n).append(':').append(prev).append("->").append(v);
                prev = v;
            }
            p("Q5 fibonacciWait(multiplier=1000, max=Long.MAX_VALUE ms) non-monotonic steps (n<=200):" + (drops.length() == 0 ? " none" : drops.toString()));
            WaitStrategy exp = WaitStrategies.exponentialWait();
            p("Q5 exponentialWait(): n=1 -> " + exp.computeSleepTime(fakeAttempt(1)) + " n=62 -> " + exp.computeSleepTime(fakeAttempt(62))
                + " n=63 -> " + exp.computeSleepTime(fakeAttempt(63)) + " n=2000 -> " + exp.computeSleepTime(fakeAttempt(2000)));
            p("Q5 attempt number wrap (int attemptNumber): exponentialWait at Integer.MIN_VALUE -> " + exp.computeSleepTime(fakeAttempt(Integer.MIN_VALUE))
                + ", stopAfterAttempt(5).shouldStop(Integer.MIN_VALUE) -> " + StopStrategies.stopAfterAttempt(5).shouldStop(fakeAttempt(Integer.MIN_VALUE)));
        }

        if (which.equals("all") || which.equals("i97")) {
            try { StopStrategies.stopAfterAttempt(0); } catch (IllegalArgumentException e) { p("#97 stopAfterAttempt(0) message: " + e.getMessage()); }
            try { WaitStrategies.randomWait(5, TimeUnit.MILLISECONDS, 1, TimeUnit.MILLISECONDS); } catch (IllegalArgumentException e) { p("#97 randomWait(5ms,1ms) message: " + e.getMessage()); }
        }

        if (which.equals("i94")) {
            try { AttemptTimeLimiters.fixedTimeLimit(1, TimeUnit.SECONDS); p("#94 fixedTimeLimit(d,u) OK"); }
            catch (Throwable t) { p("#94 fixedTimeLimit(d,u) -> " + describe(t) + " msg=" + t.getMessage()); }
            ExecutorService ex = Executors.newCachedThreadPool();
            try { AttemptTimeLimiters.fixedTimeLimit(1, TimeUnit.SECONDS, ex); p("#94 fixedTimeLimit(d,u,exec) OK"); }
            catch (Throwable t) { p("#94 fixedTimeLimit(d,u,exec) -> " + describe(t) + " msg=" + t.getMessage()); }
            ex.shutdownNow();
        }
        p("main() returning; non-daemon live threads besides main/DestroyJavaVM:");
        for (Thread t : Thread.getAllStackTraces().keySet()) {
            if (!t.isDaemon() && !t.getName().equals("main") && !t.getName().equals("DestroyJavaVM")) p("   " + t.getName() + " state=" + t.getState());
        }
    }
}
