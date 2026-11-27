package grwork.w;

import com.github.rholder.retry.Retryer;
import com.github.rholder.retry.RetryerBuilder;
import com.github.rholder.retry.StopStrategies;
import grwork.Delay;
import grwork.Harness;
import grwork.IdListener;
import grwork.Work;

import java.io.IOException;

/**
 * S3 (D-8, D-9 = #48): build() hands the builder's own listener list to the
 * Retryer. Thread "b" adds listener 2 to the builder after build() while c1
 * runs call(): the running call may notify it, or its iterator may throw
 * ConcurrentModificationException out of call(). noTimeLimit,
 * retryIfExceptionOfType(IOException), stopAfterAttempt(2), noWait.
 */
public final class ListenersAdd {
    static final String CONFIG = "{\"callers\":[\"c1\"],\"numInitListeners\":1,\"numExtraListeners\":1,"
            + "\"limiter\":\"None\",\"execKind\":\"Cached\",\"poolSize\":1,\"queueCap\":0,"
            + "\"retryOn\":[\"CallableExc\"],"
            + "\"stopKind\":\"AfterAttempt\",\"stopAfter\":2,\"sleepClasses\":[\"Zero\"],"
            + "\"modes\":[\"Ret\",\"Exc\"],\"wrapCallers\":[],\"wrapOnLimiterPool\":[]}";

    public static void main(String[] args) {
        RetryerBuilder<Object> builder = RetryerBuilder.<Object>newBuilder()
                .retryIfExceptionOfType(IOException.class)
                .withStopStrategy(StopStrategies.stopAfterAttempt(2))
                .withRetryListener(new IdListener(1));
        Retryer<Object> r = builder.build();
        Work w = new Work("Exc|Ret", "Ret|Exc");
        Harness.begin(CONFIG, r, null);
        Thread c1 = Harness.start("c1", () -> Harness.callQuietly(r, w));
        Thread b = Harness.start("b", () -> {
            Delay.some(10);
            builder.withRetryListener(new IdListener(2));
        });
        Harness.join(c1);
        Harness.join(b);
        Harness.end();
    }
}
