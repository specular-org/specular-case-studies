package grwork.w;

import com.github.rholder.retry.AttemptTimeLimiters;
import com.github.rholder.retry.Retryer;
import com.github.rholder.retry.RetryerBuilder;
import com.github.rholder.retry.StopStrategies;
import grwork.Harness;
import grwork.IdListener;
import grwork.Work;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;

/**
 * S4: c1 is a Retryer.wrap() callable submitted to the very executor its
 * fixedTimeLimit (1 ns) uses, newFixedThreadPool(1). The wrapper holds the
 * only thread, so every attempt waits in the queue and times out without
 * running; when call() ends the thread is released and dequeues the
 * cancelled attempts. retryIfException, stopAfterAttempt(3), noWait.
 */
public final class WrapSamePool {
    static final String CONFIG = "{\"callers\":[\"c1\"],\"numInitListeners\":1,\"numExtraListeners\":0,"
            + "\"limiter\":\"Fixed\",\"execKind\":\"Fixed\",\"poolSize\":1,\"queueCap\":0,"
            + "\"retryOn\":[\"Timeout\",\"CallerIE\",\"CallableExc\",\"CallableIE\",\"Rejected\"],"
            + "\"stopKind\":\"AfterAttempt\",\"stopAfter\":3,\"sleepClasses\":[\"Zero\"],"
            + "\"modes\":[\"Ret\"],\"wrapCallers\":[\"c1\"],\"wrapOnLimiterPool\":[\"c1\"]}";

    public static void main(String[] args) {
        ExecutorService pool = Executors.newFixedThreadPool(1);
        Retryer<Object> r = RetryerBuilder.<Object>newBuilder()
                .retryIfException()
                .withAttemptTimeLimiter(AttemptTimeLimiters.<Object>fixedTimeLimit(1, TimeUnit.NANOSECONDS, pool))
                .withStopStrategy(StopStrategies.stopAfterAttempt(3))
                .withRetryListener(new IdListener(1))
                .build();
        Retryer.RetryerCallable<Object> rc = r.wrap(new Work("Ret"));
        Harness.begin(CONFIG, r, pool);
        Harness.wrapCaller("c1", rc);
        Future<Object> f = pool.submit(rc);
        try {
            f.get();
        } catch (Exception e) {
            // RetryException wrapped in an ExecutionException, as expected here
        }
        pool.shutdown();
        Harness.end();
    }
}
