package grwork.w;

import com.github.rholder.retry.Retryer;
import com.github.rholder.retry.RetryerBuilder;
import com.github.rholder.retry.StopStrategies;
import grwork.Harness;
import grwork.IdListener;
import grwork.Modes;
import grwork.Work;

/**
 * noTimeLimit, one caller, stopAfterAttempt(3), retryIfException +
 * retryIfResult(BAD), noWait. Each attempt's body is chosen among Ret, RetBad,
 * Exc, Err: results, retried failures, the ExecutionException exit for an
 * Error (#67), BadResult retries and the stop strategy.
 */
public final class NolimitBasic {
    static final String CONFIG = "{\"callers\":[\"c1\"],\"numInitListeners\":1,\"numExtraListeners\":0,"
            + "\"limiter\":\"None\",\"execKind\":\"Cached\",\"poolSize\":1,\"queueCap\":0,"
            + "\"retryOn\":[\"Timeout\",\"CallerIE\",\"CallableExc\",\"CallableIE\",\"Rejected\",\"BadResult\"],"
            + "\"stopKind\":\"AfterAttempt\",\"stopAfter\":3,\"sleepClasses\":[\"Zero\"],"
            + "\"modes\":[\"Ret\",\"RetBad\",\"Exc\",\"Err\"],\"wrapCallers\":[],\"wrapOnLimiterPool\":[]}";

    public static void main(String[] args) {
        Retryer<Object> r = RetryerBuilder.<Object>newBuilder()
                .retryIfException()
                .retryIfResult(Modes.BAD::equals)
                .withStopStrategy(StopStrategies.stopAfterAttempt(3))
                .withRetryListener(new IdListener(1))
                .build();
        Work w = new Work("Ret|RetBad|Exc|Err");
        Harness.begin(CONFIG, r, null);
        Thread c1 = Harness.start("c1", () -> Harness.callQuietly(r, w));
        Harness.join(c1);
        Harness.end();
    }
}
