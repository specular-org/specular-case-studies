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
 * TV-exp: MC_hunt_s2_live / s2_wrap_cancel configuration (StopKind Never,
 * never traced by the Phase 2.5 harness): wrap() caller on a separate outer
 * executor, cancel(true) at a JPF-chosen point, neverStop. A cancelled wrap
 * task that keeps retrying (MC-6) produces a prefix cut at max_events.
 */
public final class WrapNever {
    static final String CONFIG = "{\"callers\":[\"c1\"],\"numInitListeners\":1,\"numExtraListeners\":0,"
            + "\"limiter\":\"Fixed\",\"execKind\":\"Cached\",\"poolSize\":3,\"queueCap\":0,"
            + "\"retryOn\":[\"Timeout\",\"CallerIE\",\"CallableExc\",\"CallableIE\",\"Rejected\"],"
            + "\"stopKind\":\"Never\",\"stopAfter\":3,\"sleepClasses\":[\"Zero\"],"
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
                .withStopStrategy(StopStrategies.neverStop())
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
