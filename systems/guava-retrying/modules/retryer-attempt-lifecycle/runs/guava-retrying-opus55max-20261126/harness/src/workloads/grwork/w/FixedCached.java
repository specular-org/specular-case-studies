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
import java.util.concurrent.TimeUnit;

/**
 * S1: fixedTimeLimit on Executors.newCachedThreadPool(), one caller,
 * stopAfterAttempt(3), retryIfException, noWait. The limit is 1 ns, so an
 * attempt times out exactly when JPF lets the caller's parkNanos in
 * FutureTask.get time out: timeouts race the body's start and completion.
 * Bodies: Ret | Exc | Err | IntrRet | IntrBlock | Stuck. The pool is shut down at the end.
 */
public final class FixedCached {
    static final String CONFIG = "{\"callers\":[\"c1\"],\"numInitListeners\":1,\"numExtraListeners\":0,"
            + "\"limiter\":\"Fixed\",\"execKind\":\"Cached\",\"poolSize\":3,\"queueCap\":0,"
            + "\"retryOn\":[\"Timeout\",\"CallerIE\",\"CallableExc\",\"CallableIE\",\"Rejected\"],"
            + "\"stopKind\":\"AfterAttempt\",\"stopAfter\":3,\"sleepClasses\":[\"Zero\"],"
            + "\"modes\":[\"Ret\",\"Exc\",\"Err\",\"IntrRet\",\"IntrBlock\",\"Stuck\"],\"wrapCallers\":[],\"wrapOnLimiterPool\":[]}";

    public static void main(String[] args) {
        ExecutorService pool = Executors.newCachedThreadPool();
        Retryer<Object> r = RetryerBuilder.<Object>newBuilder()
                .retryIfException()
                .withAttemptTimeLimiter(AttemptTimeLimiters.<Object>fixedTimeLimit(1, TimeUnit.NANOSECONDS, pool))
                .withStopStrategy(StopStrategies.stopAfterAttempt(3))
                .withRetryListener(new IdListener(1))
                .build();
        Work w = new Work("Ret|Exc|Err|IntrRet|IntrBlock|Stuck");
        Harness.begin(CONFIG, r, pool);
        Thread c1 = Harness.start("c1", () -> Harness.callQuietly(r, w));
        Harness.join(c1);
        pool.shutdown();
        Harness.end();
    }
}
