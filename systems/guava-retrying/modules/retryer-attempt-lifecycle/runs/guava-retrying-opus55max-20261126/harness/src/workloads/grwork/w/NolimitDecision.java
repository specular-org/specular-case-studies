package grwork.w;

import com.github.rholder.retry.Retryer;
import com.github.rholder.retry.RetryerBuilder;
import com.github.rholder.retry.StopStrategies;
import com.github.rholder.retry.WaitStrategies;
import grwork.Harness;
import grwork.IdListener;
import grwork.Modes;
import grwork.Work;

import java.io.IOException;
import java.util.concurrent.TimeUnit;

/**
 * S5: the post-attempt decision steps. stopAfterDelay(5 ms) and
 * join(exceptionWait(IOException -> Long.MAX_VALUE), fixedWait(1 ms)): after
 * an Exc attempt the joined sleep overflows to a negative value and
 * Thread.sleep's IllegalArgumentException escapes call() (D-16 composition);
 * after a RetBad attempt the sleep is 1 ms. Whether the delay has passed when
 * an attempt is built depends on how long the attempts took.
 */
public final class NolimitDecision {
    static final String CONFIG = "{\"callers\":[\"c1\"],\"numInitListeners\":1,\"numExtraListeners\":0,"
            + "\"limiter\":\"None\",\"execKind\":\"Cached\",\"poolSize\":1,\"queueCap\":0,"
            + "\"retryOn\":[\"Timeout\",\"CallerIE\",\"CallableExc\",\"CallableIE\",\"Rejected\",\"BadResult\"],"
            + "\"stopKind\":\"AfterDelay\",\"stopAfter\":3,\"stopDelayMs\":5,\"sleepClasses\":[\"Positive\",\"Negative\"],"
            + "\"modes\":[\"Ret\",\"RetBad\",\"Exc\"],\"wrapCallers\":[],\"wrapOnLimiterPool\":[]}";

    public static void main(String[] args) {
        Retryer<Object> r = RetryerBuilder.<Object>newBuilder()
                .retryIfException()
                .retryIfResult(Modes.BAD::equals)
                .withWaitStrategy(WaitStrategies.join(
                        WaitStrategies.exceptionWait(IOException.class, (IOException e) -> Long.MAX_VALUE),
                        WaitStrategies.fixedWait(1, TimeUnit.MILLISECONDS)))
                .withStopStrategy(StopStrategies.stopAfterDelay(5, TimeUnit.MILLISECONDS))
                .withRetryListener(new IdListener(1))
                .build();
        Work w = new Work("RetBad|Exc|Ret", "RetBad|Exc|Ret", "RetBad|Ret");
        Harness.begin(CONFIG, r, null);
        Thread c1 = Harness.start("c1", () -> Harness.callQuietly(r, w));
        Harness.join(c1);
        Harness.end();
    }
}
