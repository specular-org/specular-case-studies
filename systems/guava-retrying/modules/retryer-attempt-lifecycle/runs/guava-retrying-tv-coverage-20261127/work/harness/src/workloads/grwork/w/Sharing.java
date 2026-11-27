package grwork.w;

import com.github.rholder.retry.AttemptTimeLimiters;
import com.github.rholder.retry.Retryer;
import com.github.rholder.retry.RetryerBuilder;
import com.github.rholder.retry.StopStrategies;
import grwork.Delay;
import grwork.Harness;
import grwork.IdListener;
import grwork.Work;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

/**
 * Sharing: one Retryer (and one limiter executor, a cached pool, 1 ns limit)
 * used by two callers at once, while thread "b" adds a listener to the
 * builder it came from. retryIfException, stopAfterAttempt(2), noWait.
 * Bodies: Ret | Exc.
 */
public final class Sharing {
    static final String CONFIG = "{\"callers\":[\"c1\",\"c2\"],\"numInitListeners\":1,\"numExtraListeners\":1,"
            + "\"limiter\":\"Fixed\",\"execKind\":\"Cached\",\"poolSize\":3,\"queueCap\":0,"
            + "\"retryOn\":[\"Timeout\",\"CallerIE\",\"CallableExc\",\"CallableIE\",\"Rejected\"],"
            + "\"stopKind\":\"AfterAttempt\",\"stopAfter\":2,\"sleepClasses\":[\"Zero\"],"
            + "\"modes\":[\"Ret\",\"Exc\"],\"wrapCallers\":[],\"wrapOnLimiterPool\":[]}";

    public static void main(String[] args) {
        ExecutorService pool = Executors.newCachedThreadPool();
        RetryerBuilder<Object> builder = RetryerBuilder.<Object>newBuilder()
                .retryIfException()
                .withAttemptTimeLimiter(AttemptTimeLimiters.<Object>fixedTimeLimit(1, TimeUnit.NANOSECONDS, pool))
                .withStopStrategy(StopStrategies.stopAfterAttempt(2))
                .withRetryListener(new IdListener(1));
        Retryer<Object> r = builder.build();
        Work w1 = new Work("Exc|Ret", "Ret|Exc");
        Work w2 = new Work("Exc|Ret", "Ret|Exc");
        Harness.begin(CONFIG, r, pool);
        Thread c1 = Harness.start("c1", () -> Harness.callQuietly(r, w1));
        Thread c2 = Harness.start("c2", () -> Harness.callQuietly(r, w2));
        Thread b = Harness.start("b", () -> {
            Delay.some(12);
            builder.withRetryListener(new IdListener(2));
        });
        Harness.join(c1);
        Harness.join(c2);
        Harness.join(b);
        pool.shutdown();
        Harness.end();
    }
}
