package com.github.rholder.retry;

import com.google.common.base.Predicates;

import java.util.concurrent.Callable;

/** Drives Retryer.call past Integer.MAX_VALUE attempts (no-op block strategy) and reports what the strategies see. */
public class AttemptOverflow {
    public static void main(String[] args) throws Exception {
        final long limit = Long.parseLong(args[0]);
        final WaitStrategy exp = WaitStrategies.exponentialWait(100, 60000, java.util.concurrent.TimeUnit.MILLISECONDS);
        final long[] seen = new long[3]; // [0]=last attempt number seen, [1]=wait at last attempt, [2]=RetryException count field
        Retryer<Object> r = RetryerBuilder.newBuilder()
                .retryIfResult(Predicates.isNull())
                .withWaitStrategy(exp)
                .withBlockStrategy(new BlockStrategy() { public void block(long t) { seen[1] = t; } })
                .withStopStrategy(new StopStrategy() {
                    public boolean shouldStop(Attempt a) {
                        seen[0] = a.getAttemptNumber();
                        return a.getAttemptNumber() < 0 || a.getAttemptNumber() >= limit;
                    }
                })
                .build();
        long t0 = System.nanoTime();
        try {
            r.call(new Callable<Object>() { public Object call() { return null; } });
        } catch (RetryException e) {
            seen[2] = e.getNumberOfFailedAttempts();
        }
        System.out.println("stoppedAtAttemptNumber=" + seen[0] + " lastComputedWaitMs=" + seen[1]
                + " RetryException.getNumberOfFailedAttempts=" + seen[2]
                + " elapsedS=" + (System.nanoTime() - t0) / 1e9);
    }
}
