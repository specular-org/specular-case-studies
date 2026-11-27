package grwork.w;

import com.github.rholder.retry.AttemptTimeLimiters;
import com.github.rholder.retry.Retryer;
import com.github.rholder.retry.RetryerBuilder;
import com.github.rholder.retry.StopStrategies;
import com.github.rholder.retry.WaitStrategies;
import grwork.Delay;
import grwork.Harness;
import grwork.IdListener;
import grwork.Work;

import java.io.IOException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

/**
 * S2 with fixedTimeLimit (1 ns) on a cached pool: thread "e" interrupts c1
 * once, possibly while c1 waits in FutureTask.get (GetInterrupted, cancel,
 * "CallerIE" attempt), during the listeners, or while it sleeps between
 * attempts. stopAfterAttempt(2), retryIfException, exceptionWait(IOException
 * -> 1 ms). Bodies: Ret | Exc | Stuck.
 */
public final class FixedCachedInterrupt {
    static final String CONFIG = "{\"callers\":[\"c1\"],\"numInitListeners\":1,\"numExtraListeners\":0,"
            + "\"limiter\":\"Fixed\",\"execKind\":\"Cached\",\"poolSize\":3,\"queueCap\":0,"
            + "\"retryOn\":[\"Timeout\",\"CallerIE\",\"CallableExc\",\"CallableIE\",\"Rejected\"],"
            + "\"stopKind\":\"AfterAttempt\",\"stopAfter\":2,\"sleepClasses\":[\"Zero\",\"Positive\"],"
            + "\"modes\":[\"Ret\",\"Exc\",\"Stuck\"],\"wrapCallers\":[],\"wrapOnLimiterPool\":[]}";

    public static void main(String[] args) {
        ExecutorService pool = Executors.newCachedThreadPool();
        Retryer<Object> r = RetryerBuilder.<Object>newBuilder()
                .retryIfException()
                .withAttemptTimeLimiter(AttemptTimeLimiters.<Object>fixedTimeLimit(1, TimeUnit.NANOSECONDS, pool))
                .withWaitStrategy(WaitStrategies.exceptionWait(IOException.class, (IOException e) -> 1L))
                .withStopStrategy(StopStrategies.stopAfterAttempt(2))
                .withRetryListener(new IdListener(1))
                .build();
        Work w = new Work("Ret|Exc|Stuck", "Ret|Exc");
        Harness.begin(CONFIG, r, pool);
        Thread c1 = Harness.start("c1", () -> Harness.callQuietly(r, w));
        Thread e = Harness.start("e", () -> {
            Delay.some(8);
            c1.interrupt();
        });
        Harness.join(c1);
        Harness.join(e);
        pool.shutdown();
        Harness.end();
    }
}
