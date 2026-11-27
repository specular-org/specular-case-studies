package grwork.w;

import com.github.rholder.retry.Retryer;
import com.github.rholder.retry.RetryerBuilder;
import com.github.rholder.retry.StopStrategies;
import com.github.rholder.retry.WaitStrategies;
import grwork.Delay;
import grwork.Harness;
import grwork.IdListener;
import grwork.Work;

import java.io.IOException;

/**
 * S2 without a time limit: thread "e" interrupts caller c1 once, at a point
 * JPF chooses (before the call, inside a body, during listeners, or while
 * sleeping between attempts). stopAfterAttempt(3), retryIfException, and
 * exceptionWait(IOException -> 1 ms): an Exc attempt sleeps (Positive), an
 * InterruptedException attempt does not (Zero). The first body may block until
 * interrupted (IntrBlock); nothing can consume the interrupt before it.
 */
public final class NolimitInterrupt {
    static final String CONFIG = "{\"callers\":[\"c1\"],\"numInitListeners\":1,\"numExtraListeners\":0,"
            + "\"limiter\":\"None\",\"execKind\":\"Cached\",\"poolSize\":1,\"queueCap\":0,"
            + "\"retryOn\":[\"Timeout\",\"CallerIE\",\"CallableExc\",\"CallableIE\",\"Rejected\"],"
            + "\"stopKind\":\"AfterAttempt\",\"stopAfter\":3,\"sleepClasses\":[\"Zero\",\"Positive\"],"
            + "\"modes\":[\"Ret\",\"Exc\",\"IntrRet\",\"IntrBlock\"],\"wrapCallers\":[],\"wrapOnLimiterPool\":[]}";

    public static void main(String[] args) {
        Retryer<Object> r = RetryerBuilder.<Object>newBuilder()
                .retryIfException()
                .withWaitStrategy(WaitStrategies.exceptionWait(IOException.class, (IOException e) -> 1L))
                .withStopStrategy(StopStrategies.stopAfterAttempt(3))
                .withRetryListener(new IdListener(1))
                .build();
        Work w = new Work("IntrBlock|IntrRet|Exc", "IntrRet|Exc|Ret", "Ret|Exc");
        Harness.begin(CONFIG, r, null);
        Thread c1 = Harness.start("c1", () -> Harness.callQuietly(r, w));
        Thread e = Harness.start("e", () -> {
            Delay.some(6);
            c1.interrupt();
        });
        Harness.join(c1);
        Harness.join(e);
        Harness.end();
    }
}
