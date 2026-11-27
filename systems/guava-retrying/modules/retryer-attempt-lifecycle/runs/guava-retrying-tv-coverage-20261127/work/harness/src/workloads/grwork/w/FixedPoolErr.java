package grwork.w;

import com.github.rholder.retry.AttemptTimeLimiters;
import com.github.rholder.retry.Retryer;
import com.github.rholder.retry.RetryerBuilder;
import com.github.rholder.retry.StopStrategies;
import grwork.Harness;
import grwork.IdListener;
import grwork.Modes;
import grwork.Work;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

/**
 * TV-exp: RetBad / Err bodies on limiter workers (BodyReturns BadResult,
 * GetReturn BadResult / CallableErr, PredicateAccepts ExecExc on an Error) -
 * the Phase 2.5 harness only ran Ret|Exc|Err|IntrRet|IntrBlock|Stuck with
 * retryIfException on the cached pool. Fixed(2) pool, retryIfRuntimeException
 * + retryIfResult(bad): an IOException or an Error ends the call.
 */
public final class FixedPoolErr {
    static final String CONFIG = "{\"callers\":[\"c1\"],\"numInitListeners\":1,\"numExtraListeners\":0,"
            + "\"limiter\":\"Fixed\",\"execKind\":\"Fixed\",\"poolSize\":2,\"queueCap\":0,"
            + "\"retryOn\":[\"Timeout\",\"Rejected\",\"BadResult\"],"
            + "\"stopKind\":\"AfterAttempt\",\"stopAfter\":3,\"sleepClasses\":[\"Zero\"],"
            + "\"modes\":[\"Ret\",\"RetBad\",\"Exc\",\"Err\"],\"wrapCallers\":[],\"wrapOnLimiterPool\":[]}";

    public static void main(String[] args) {
        ExecutorService pool = Executors.newFixedThreadPool(2);
        Retryer<Object> r = RetryerBuilder.<Object>newBuilder()
                .retryIfRuntimeException()
                .retryIfResult(Modes.BAD::equals)
                .withAttemptTimeLimiter(AttemptTimeLimiters.<Object>fixedTimeLimit(1, TimeUnit.NANOSECONDS, pool))
                .withStopStrategy(StopStrategies.stopAfterAttempt(3))
                .withRetryListener(new IdListener(1))
                .build();
        Work w = new Work("RetBad|Err|Exc|Ret", "RetBad|Err|Ret", "Ret|RetBad");
        Harness.begin(CONFIG, r, pool);
        Thread c1 = Harness.start("c1", () -> Harness.callQuietly(r, w));
        Harness.join(c1);
        pool.shutdown();
        Harness.end();
    }
}
