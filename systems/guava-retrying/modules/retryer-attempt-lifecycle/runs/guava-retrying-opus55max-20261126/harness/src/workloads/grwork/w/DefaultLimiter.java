package grwork.w;

import com.github.rholder.retry.AttemptTimeLimiters;
import com.github.rholder.retry.Retryer;
import com.github.rholder.retry.RetryerBuilder;
import com.github.rholder.retry.StopStrategies;
import grwork.Harness;
import grwork.IdListener;
import grwork.Work;

import java.util.concurrent.TimeUnit;

/**
 * The two-argument fixedTimeLimit(1 ns): SimpleTimeLimiter() creates its own
 * Executors.newCachedThreadPool(), which the program cannot shut down; its
 * threads outlive call() (#92). retryIfException, stopAfterAttempt(2),
 * noWait. Bodies: Ret | Exc.
 */
public final class DefaultLimiter {
    static final String CONFIG = "{\"callers\":[\"c1\"],\"numInitListeners\":1,\"numExtraListeners\":0,"
            + "\"limiter\":\"Fixed\",\"execKind\":\"Cached\",\"poolSize\":3,\"queueCap\":0,"
            + "\"retryOn\":[\"Timeout\",\"CallerIE\",\"CallableExc\",\"CallableIE\",\"Rejected\"],"
            + "\"stopKind\":\"AfterAttempt\",\"stopAfter\":2,\"sleepClasses\":[\"Zero\"],"
            + "\"modes\":[\"Ret\",\"Exc\"],\"wrapCallers\":[],\"wrapOnLimiterPool\":[]}";

    public static void main(String[] args) {
        Retryer<Object> r = RetryerBuilder.<Object>newBuilder()
                .retryIfException()
                .withAttemptTimeLimiter(AttemptTimeLimiters.<Object>fixedTimeLimit(1, TimeUnit.NANOSECONDS))
                .withStopStrategy(StopStrategies.stopAfterAttempt(2))
                .withRetryListener(new IdListener(1))
                .build();
        Work w = new Work("Ret|Exc");
        Harness.begin(CONFIG, r, null);
        Thread c1 = Harness.start("c1", () -> Harness.callQuietly(r, w));
        Harness.join(c1);
        Harness.end();
    }
}
