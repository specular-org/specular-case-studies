package com.github.rholder.retry;

import com.google.common.base.Function;
import com.google.common.base.Predicates;

import java.io.IOException;
import java.util.ConcurrentModificationException;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicReference;

/** Small runtime checks of 2.0.0 behaviors referenced by the PR archaeology. */
public class ArchRepro {

    static void out(String s) { System.out.println(s); }

    static String outcome(Retryer<Object> r, Callable<Object> c) {
        try {
            Object v = r.call(c);
            return "returned " + v + " interrupted=" + Thread.currentThread().isInterrupted();
        } catch (ExecutionException e) {
            return "ExecutionException(cause=" + e.getCause() + ") interrupted=" + Thread.currentThread().isInterrupted();
        } catch (RetryException e) {
            return "RetryException(attempts=" + e.getNumberOfFailedAttempts() + ", cause=" + e.getCause() + ") interrupted=" + Thread.currentThread().isInterrupted();
        } catch (Throwable t) {
            return "ESCAPED " + t + " interrupted=" + Thread.currentThread().isInterrupted();
        }
    }

    static String runInThread(final Retryer<Object> r, final Callable<Object> c, long interruptAfterMs) throws Exception {
        final AtomicReference<String> res = new AtomicReference<String>();
        Thread t = new Thread(new Runnable() { public void run() { res.set(outcome(r, c)); } });
        long t0 = System.nanoTime();
        t.start();
        if (interruptAfterMs >= 0) { Thread.sleep(interruptAfterMs); t.interrupt(); }
        t.join();
        return res.get() + " elapsedMs=" + TimeUnit.NANOSECONDS.toMillis(System.nanoTime() - t0);
    }

    public static void main(String[] args) throws Exception {
        // T1: interrupt during the attempt; predicate does not match the InterruptedException.
        Retryer<Object> r1 = RetryerBuilder.newBuilder().retryIfResult(Predicates.isNull()).build();
        out("T1 interrupt-during-attempt (no exception predicate): " + runInThread(r1, new Callable<Object>() {
            public Object call() throws Exception { Thread.sleep(10000); return "x"; }
        }, 200));

        // T2: interrupt during the attempt with retryIfException(): interrupt swallowed, retrying continues.
        final AtomicInteger n2 = new AtomicInteger();
        Retryer<Object> r2 = RetryerBuilder.newBuilder().retryIfException()
                .withStopStrategy(StopStrategies.stopAfterAttempt(3)).build();
        out("T2 interrupt-during-attempt (retryIfException, stopAfterAttempt(3)): " + runInThread(r2, new Callable<Object>() {
            public Object call() throws Exception {
                if (n2.incrementAndGet() == 1) { Thread.sleep(10000); }
                Thread.sleep(300);
                throw new IOException("attempt " + n2.get());
            }
        }, 200) + " attemptsRun=" + n2.get());

        // T3: fixedTimeLimit; caller interrupted while waiting on the time limiter's future.
        Retryer<Object> r3 = RetryerBuilder.newBuilder().retryIfResult(Predicates.isNull())
                .withAttemptTimeLimiter(AttemptTimeLimiters.fixedTimeLimit(5, TimeUnit.SECONDS)).build();
        out("T3 fixedTimeLimit caller interrupted: " + runInThread(r3, new Callable<Object>() {
            public Object call() throws Exception { Thread.sleep(10000); return "x"; }
        }, 200));

        // T4: pre-interrupted caller, noWait: 2.0.0 ThreadSleepStrategy vs PR #101 zero-skip variant.
        final AtomicInteger n4 = new AtomicInteger();
        Callable<Object> nullCall = new Callable<Object>() { public Object call() { n4.incrementAndGet(); return null; } };
        Retryer<Object> r4a = RetryerBuilder.newBuilder().retryIfResult(Predicates.isNull())
                .withStopStrategy(StopStrategies.stopAfterAttempt(1000)).build();
        BlockStrategy pr101 = new BlockStrategy() {
            public void block(long sleepTime) throws InterruptedException {
                if (sleepTime == 0L) { return; }
                Thread.sleep(sleepTime);
            }
        };
        Retryer<Object> r4b = RetryerBuilder.newBuilder().retryIfResult(Predicates.isNull())
                .withStopStrategy(StopStrategies.stopAfterAttempt(1000)).withBlockStrategy(pr101).build();
        Thread.currentThread().interrupt();
        String a = outcome(r4a, nullCall); int na = n4.getAndSet(0);
        Thread.interrupted();
        Thread.currentThread().interrupt();
        String b = outcome(r4b, nullCall); int nb = n4.getAndSet(0);
        Thread.interrupted();
        out("T4 pre-interrupted, noWait, 2.0.0 sleep(0): " + a + " attemptsRun=" + na);
        out("T4 pre-interrupted, noWait, PR#101 variant: " + b + " attemptsRun=" + nb);

        // T5: composite wait overflow -> negative sleep -> IllegalArgumentException escapes call().
        Retryer<Object> r5 = RetryerBuilder.newBuilder().retryIfResult(Predicates.isNull())
                .withWaitStrategy(WaitStrategies.join(WaitStrategies.fixedWait(Long.MAX_VALUE, TimeUnit.MILLISECONDS),
                        WaitStrategies.fixedWait(1, TimeUnit.MILLISECONDS))).build();
        out("T5 join(fixedWait(MAX), fixedWait(1)): " + outcome(r5, new Callable<Object>() { public Object call() { return null; } }));
        WaitStrategy expPlus1 = WaitStrategies.join(WaitStrategies.exponentialWait(), WaitStrategies.fixedWait(1, TimeUnit.MILLISECONDS));
        out("T5b join(exponentialWait(), fixedWait(1)) sleep at attempt 62/63/64: "
                + expPlus1.computeSleepTime(new Retryer.ResultAttempt<Object>(null, 62, 0)) + " / "
                + expPlus1.computeSleepTime(new Retryer.ResultAttempt<Object>(null, 63, 0)) + " / "
                + expPlus1.computeSleepTime(new Retryer.ResultAttempt<Object>(null, 64, 0)));

        // T6: fibonacciWait() wrap: sleep time collapses after fib overflows.
        WaitStrategy fib = WaitStrategies.fibonacciWait();
        StringBuilder sb = new StringBuilder();
        for (int i = 90; i <= 100; i++) {
            sb.append(i).append('=').append(fib.computeSleepTime(new Retryer.ResultAttempt<Object>(null, i, 0))).append(' ');
        }
        out("T6 fibonacciWait() attempt->sleep: " + sb);
        WaitStrategy fibM = WaitStrategies.fibonacciWait(1000, 1000000000L, TimeUnit.MILLISECONDS);
        sb.setLength(0);
        for (int i = 80; i <= 90; i++) {
            sb.append(i).append('=').append(fibM.computeSleepTime(new Retryer.ResultAttempt<Object>(null, i, 0))).append(' ');
        }
        out("T6b fibonacciWait(1000, 1e9 ms) attempt->sleep: " + sb);
        WaitStrategy inc = WaitStrategies.incrementingWait(0, TimeUnit.MILLISECONDS, Long.MAX_VALUE / 2, TimeUnit.MILLISECONDS);
        out("T6c incrementingWait(0, MAX/2) attempt 2/3/4/5: "
                + inc.computeSleepTime(new Retryer.ResultAttempt<Object>(null, 2, 0)) + " / "
                + inc.computeSleepTime(new Retryer.ResultAttempt<Object>(null, 3, 0)) + " / "
                + inc.computeSleepTime(new Retryer.ResultAttempt<Object>(null, 4, 0)) + " / "
                + inc.computeSleepTime(new Retryer.ResultAttempt<Object>(null, 5, 0)));

        // T7: listener list shared between builder and built Retryer (#48), and CME under concurrent builder use.
        final AtomicInteger l1 = new AtomicInteger(), l2 = new AtomicInteger();
        final RetryerBuilder<Object> b7 = RetryerBuilder.newBuilder().withRetryListener(new RetryListener() {
            public <V> void onRetry(Attempt<V> attempt) { l1.incrementAndGet(); }
        });
        final Retryer<Object> r7 = b7.build();
        b7.withRetryListener(new RetryListener() { public <V> void onRetry(Attempt<V> attempt) { l2.incrementAndGet(); } });
        outcome(r7, new Callable<Object>() { public Object call() { return "ok"; } });
        out("T7 listener added to builder AFTER build(): firstRetryer fired l1=" + l1.get() + " l2=" + l2.get());
        final AtomicBoolean stop = new AtomicBoolean(false);
        final AtomicReference<Throwable> cme = new AtomicReference<Throwable>();
        final AtomicInteger calls = new AtomicInteger();
        Thread caller = new Thread(new Runnable() { public void run() {
            while (!stop.get() && cme.get() == null) {
                try { r7.call(new Callable<Object>() { public Object call() { return "ok"; } }); calls.incrementAndGet(); }
                catch (Throwable t) { cme.set(t); }
            }
        }});
        caller.start();
        long deadline = System.currentTimeMillis() + 5000;
        int added = 0;
        while (cme.get() == null && System.currentTimeMillis() < deadline) {
            b7.withRetryListener(new RetryListener() { public <V> void onRetry(Attempt<V> attempt) { } });
            added++;
        }
        stop.set(true); caller.join();
        out("T7b concurrent withRetryListener while sharing built Retryer: thrown=" + cme.get()
                + " (CME? " + (cme.get() instanceof ConcurrentModificationException) + ") afterCalls=" + calls.get() + " listenersAdded=" + added);

        // T8: exceptionWait returning null / negative.
        Retryer<Object> r8 = RetryerBuilder.newBuilder().retryIfException()
                .withWaitStrategy(WaitStrategies.exceptionWait(RuntimeException.class, new Function<RuntimeException, Long>() {
                    public Long apply(RuntimeException e) { return null; }
                })).build();
        out("T8 exceptionWait fn->null: " + outcome(r8, new Callable<Object>() { public Object call() { throw new IllegalStateException("x"); } }));
        Retryer<Object> r8b = RetryerBuilder.newBuilder().retryIfException()
                .withWaitStrategy(WaitStrategies.exceptionWait(RuntimeException.class, new Function<RuntimeException, Long>() {
                    public Long apply(RuntimeException e) { return -1L; }
                })).build();
        out("T8b exceptionWait fn->-1: " + outcome(r8b, new Callable<Object>() { public Object call() { throw new IllegalStateException("x"); } }));

        // T9: timeout -> overlapping attempts when the callable ignores interrupts.
        final AtomicInteger inFlight = new AtomicInteger(), maxInFlight = new AtomicInteger(), started = new AtomicInteger();
        Retryer<Object> r9 = RetryerBuilder.newBuilder().retryIfException()
                .withStopStrategy(StopStrategies.stopAfterAttempt(3))
                .withAttemptTimeLimiter(AttemptTimeLimiters.fixedTimeLimit(100, TimeUnit.MILLISECONDS)).build();
        String o9 = outcome(r9, new Callable<Object>() {
            public Object call() {
                started.incrementAndGet();
                int now = inFlight.incrementAndGet();
                for (;;) { int m = maxInFlight.get(); if (now <= m || maxInFlight.compareAndSet(m, now)) break; }
                long end = System.nanoTime() + TimeUnit.MILLISECONDS.toNanos(700);
                while (System.nanoTime() < end) { try { Thread.sleep(10); } catch (InterruptedException ignored) { } }
                inFlight.decrementAndGet();
                return "late";
            }
        });
        out("T9 fixedTimeLimit(100ms), interrupt-ignoring 700ms callable, stopAfterAttempt(3): " + o9
                + " started=" + started.get() + " maxConcurrentAttempts=" + maxInFlight.get() + " stillRunningAtReturn=" + inFlight.get());

        // #92 evidence: non-daemon time-limiter threads still alive after the work is done.
        int nonDaemonPool = 0;
        for (Thread t : Thread.getAllStackTraces().keySet()) {
            if (!t.isDaemon() && t.getName().startsWith("pool-")) nonDaemonPool++;
        }
        out("T10 live non-daemon 'pool-*' threads after all calls returned: " + nonDaemonPool);
        System.exit(0);
    }
}
