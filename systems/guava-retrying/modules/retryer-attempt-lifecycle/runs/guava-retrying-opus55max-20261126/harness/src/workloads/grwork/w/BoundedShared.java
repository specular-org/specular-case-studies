package grwork.w;

import com.github.rholder.retry.AttemptTimeLimiters;
import com.github.rholder.retry.Retryer;
import com.github.rholder.retry.RetryerBuilder;
import com.github.rholder.retry.StopStrategies;
import grwork.Harness;
import grwork.IdListener;
import grwork.Work;

import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;

/**
 * S4 / D-10 and sharing: one Retryer used by two callers, fixedTimeLimit (1 ns)
 * on a bounded pool (1 thread, queue of 1, AbortPolicy). With the thread busy
 * (or stuck) and the queue full, submit is rejected and the
 * RejectedExecutionException becomes an attempt that never ran.
 * stopAfterAttempt(2), retryIfException, noWait. Bodies: Ret | Stuck.
 */
public final class BoundedShared {
    static final String CONFIG = "{\"callers\":[\"c1\",\"c2\"],\"numInitListeners\":1,\"numExtraListeners\":0,"
            + "\"limiter\":\"Fixed\",\"execKind\":\"Bounded\",\"poolSize\":1,\"queueCap\":1,"
            + "\"retryOn\":[\"Timeout\",\"CallerIE\",\"CallableExc\",\"CallableIE\",\"Rejected\"],"
            + "\"stopKind\":\"AfterAttempt\",\"stopAfter\":2,\"sleepClasses\":[\"Zero\"],"
            + "\"modes\":[\"Ret\",\"Stuck\"],\"wrapCallers\":[],\"wrapOnLimiterPool\":[]}";

    public static void main(String[] args) {
        ThreadPoolExecutor pool = new ThreadPoolExecutor(1, 1, 0L, TimeUnit.MILLISECONDS,
                new ArrayBlockingQueue<Runnable>(1));
        Retryer<Object> r = RetryerBuilder.<Object>newBuilder()
                .retryIfException()
                .withAttemptTimeLimiter(AttemptTimeLimiters.<Object>fixedTimeLimit(1, TimeUnit.NANOSECONDS, pool))
                .withStopStrategy(StopStrategies.stopAfterAttempt(2))
                .withRetryListener(new IdListener(1))
                .build();
        Work w1 = new Work("Ret|Stuck", "Ret");
        Work w2 = new Work("Ret|Stuck", "Ret");
        Harness.begin(CONFIG, r, pool);
        Thread c1 = Harness.start("c1", () -> Harness.callQuietly(r, w1));
        Thread c2 = Harness.start("c2", () -> Harness.callQuietly(r, w2));
        Harness.join(c1);
        Harness.join(c2);
        pool.shutdown();
        Harness.end();
    }
}
