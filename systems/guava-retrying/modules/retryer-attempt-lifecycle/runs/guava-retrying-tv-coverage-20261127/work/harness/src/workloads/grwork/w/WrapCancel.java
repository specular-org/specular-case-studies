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
import java.util.concurrent.Future;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;

/**
 * S2 (D-7): c1 is a Retryer.wrap() callable run by a separate single-thread
 * outer executor; main cancels its Future with cancel(true) at a point JPF
 * chooses: before it runs (it never runs), or while call() retries (the
 * interrupt reaches FutureTask.get, a body, or the gap between attempts).
 * fixedTimeLimit (1 ns) on a cached pool, retryIfException,
 * stopAfterAttempt(3), noWait. Bodies: Exc | IntrRet.
 */
public final class WrapCancel {
    static final String CONFIG = "{\"callers\":[\"c1\"],\"numInitListeners\":1,\"numExtraListeners\":0,"
            + "\"limiter\":\"Fixed\",\"execKind\":\"Cached\",\"poolSize\":3,\"queueCap\":0,"
            + "\"retryOn\":[\"Timeout\",\"CallerIE\",\"CallableExc\",\"CallableIE\",\"Rejected\"],"
            + "\"stopKind\":\"AfterAttempt\",\"stopAfter\":3,\"sleepClasses\":[\"Zero\"],"
            + "\"modes\":[\"Exc\",\"IntrRet\"],\"wrapCallers\":[\"c1\"],\"wrapOnLimiterPool\":[]}";

    static volatile Thread outerThread;

    public static void main(String[] args) {
        ExecutorService pool = Executors.newCachedThreadPool();
        ThreadPoolExecutor outer = new ThreadPoolExecutor(1, 1, 0L, TimeUnit.MILLISECONDS,
                new LinkedBlockingQueue<Runnable>(), run -> {
                    Thread t = new Thread(run, "o1");
                    outerThread = t;
                    return t;
                });
        Retryer<Object> r = RetryerBuilder.<Object>newBuilder()
                .retryIfException()
                .withAttemptTimeLimiter(AttemptTimeLimiters.<Object>fixedTimeLimit(1, TimeUnit.NANOSECONDS, pool))
                .withStopStrategy(StopStrategies.stopAfterAttempt(3))
                .withRetryListener(new IdListener(1))
                .build();
        Retryer.RetryerCallable<Object> rc = r.wrap(new Work("Exc|IntrRet"));
        Harness.begin(CONFIG, r, pool);
        Harness.wrapCaller("c1", rc);
        Future<Object> f = outer.submit(rc);
        Delay.some(12);
        f.cancel(true);
        outer.shutdown();
        Harness.join(outerThread);
        pool.shutdown();
        Harness.end();
    }
}
