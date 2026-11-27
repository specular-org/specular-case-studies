package grwork.w;

import com.github.rholder.retry.AttemptTimeLimiters;
import com.github.rholder.retry.Retryer;
import com.github.rholder.retry.RetryerBuilder;
import com.github.rholder.retry.StopStrategies;
import com.github.rholder.retry.WaitStrategies;
import grwork.Harness;
import grwork.IdListener;
import grwork.Modes;
import grwork.Work;

import java.io.IOException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

/**
 * TV-exp: stopAfterDelay under fixedTimeLimit (never traced by the Phase 2.5
 * harness): the Attempt built after a timeout, a cancel race or a completed
 * task can be "expired". retryIfException + retryIfResult(bad) so BadResult
 * comes back through FutureTask.get. exceptionWait(IOException -> 1 ms).
 */
public final class FixedDelay {
    static final String CONFIG = "{\"callers\":[\"c1\"],\"numInitListeners\":1,\"numExtraListeners\":0,"
            + "\"limiter\":\"Fixed\",\"execKind\":\"Cached\",\"poolSize\":3,\"queueCap\":0,"
            + "\"retryOn\":[\"Timeout\",\"CallerIE\",\"CallableExc\",\"CallableIE\",\"Rejected\",\"BadResult\"],"
            + "\"stopKind\":\"AfterDelay\",\"stopAfter\":3,\"stopDelayMs\":3,\"sleepClasses\":[\"Zero\",\"Positive\"],"
            + "\"modes\":[\"Ret\",\"RetBad\",\"Exc\",\"Stuck\"],\"wrapCallers\":[],\"wrapOnLimiterPool\":[]}";

    public static void main(String[] args) {
        ExecutorService pool = Executors.newCachedThreadPool();
        Retryer<Object> r = RetryerBuilder.<Object>newBuilder()
                .retryIfException()
                .retryIfResult(Modes.BAD::equals)
                .withAttemptTimeLimiter(AttemptTimeLimiters.<Object>fixedTimeLimit(1, TimeUnit.NANOSECONDS, pool))
                .withWaitStrategy(WaitStrategies.exceptionWait(IOException.class, (IOException e) -> 1L))
                .withStopStrategy(StopStrategies.stopAfterDelay(3, TimeUnit.MILLISECONDS))
                .withRetryListener(new IdListener(1))
                .build();
        Work w = new Work("RetBad|Exc|Stuck|Ret", "RetBad|Exc|Ret", "RetBad|Ret");
        Harness.begin(CONFIG, r, pool);
        Thread c1 = Harness.start("c1", () -> Harness.callQuietly(r, w));
        Harness.join(c1);
        pool.shutdown();
        Harness.end();
    }
}
