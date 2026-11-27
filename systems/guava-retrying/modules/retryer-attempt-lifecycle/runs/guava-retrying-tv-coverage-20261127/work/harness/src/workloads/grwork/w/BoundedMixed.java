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
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;

/**
 * TV-exp: the MC.cfg configuration (Bounded(1,1), Ret|Exc|IntrRet|Stuck,
 * Zero|Positive sleeps, one extra listener) - the Phase 2.5 bounded workload
 * only had Ret|Stuck and two callers. "e" interrupts c1 once, "b" adds
 * listener 2 to the builder after build().
 */
public final class BoundedMixed {
    static final String CONFIG = "{\"callers\":[\"c1\"],\"numInitListeners\":1,\"numExtraListeners\":1,"
            + "\"limiter\":\"Fixed\",\"execKind\":\"Bounded\",\"poolSize\":1,\"queueCap\":1,"
            + "\"retryOn\":[\"Timeout\",\"CallerIE\",\"CallableExc\",\"CallableIE\",\"Rejected\"],"
            + "\"stopKind\":\"AfterAttempt\",\"stopAfter\":3,\"sleepClasses\":[\"Zero\",\"Positive\"],"
            + "\"modes\":[\"Ret\",\"Exc\",\"IntrRet\",\"Stuck\"],\"wrapCallers\":[],\"wrapOnLimiterPool\":[]}";

    public static void main(String[] args) {
        ThreadPoolExecutor pool = new ThreadPoolExecutor(1, 1, 0L, TimeUnit.MILLISECONDS,
                new ArrayBlockingQueue<Runnable>(1), new ThreadPoolExecutor.AbortPolicy());
        RetryerBuilder<Object> b = RetryerBuilder.<Object>newBuilder()
                .retryIfException()
                .withAttemptTimeLimiter(AttemptTimeLimiters.<Object>fixedTimeLimit(1, TimeUnit.NANOSECONDS, pool))
                .withWaitStrategy(WaitStrategies.exceptionWait(IOException.class, (IOException e) -> 1L))
                .withStopStrategy(StopStrategies.stopAfterAttempt(3))
                .withRetryListener(new IdListener(1));
        Retryer<Object> r = b.build();
        Work w = new Work("Exc|IntrRet|Stuck|Ret", "Exc|IntrRet|Ret", "Ret|Exc");
        Harness.begin(CONFIG, r, pool);
        Thread c1 = Harness.start("c1", () -> Harness.callQuietly(r, w));
        Thread e = Harness.start("e", () -> {
            Delay.some(10);
            c1.interrupt();
        });
        Thread bt = Harness.start("b", () -> {
            Delay.some(10);
            b.withRetryListener(new IdListener(2));
        });
        Harness.join(c1);
        Harness.join(e);
        Harness.join(bt);
        pool.shutdown();
        Harness.end();
    }
}
