import com.github.rholder.retry.Attempt;
import com.github.rholder.retry.RetryListener;
import com.github.rholder.retry.Retryer;
import com.github.rholder.retry.RetryerBuilder;
import com.github.rholder.retry.StopStrategies;
import com.google.common.base.Predicates;

import java.util.concurrent.Callable;

/**
 * JPF workload for the "straddle" variant of MC-11 (spec/output/hunt_sharing_bfs4.out):
 * the builder thread's ArrayList.add(L2) runs concurrently with an in-flight Retryer.call() on
 * caller-c1. Public API only; the library is unmodified. Two attempts so that c1 has already
 * touched the listener list (attempt 1) before the add, which makes the list a shared object for
 * JPF's PathSharednessPolicy and lets JPF schedule c1 between the add's internal writes.
 */
public class MC11Straddle {
    static final class L1 implements RetryListener {
        @Override public <V> void onRetry(Attempt<V> attempt) { }
    }

    static final class L2 implements RetryListener {
        @Override public <V> void onRetry(Attempt<V> attempt) { }
    }

    public static void main(String[] args) throws Exception {
        final RetryerBuilder<String> builder = RetryerBuilder.<String>newBuilder()
                .retryIfResult(Predicates.equalTo("retry"))
                .withStopStrategy(StopStrategies.stopAfterAttempt(2))
                .withRetryListener(new L1());
        final Retryer<String> retryer = builder.build();
        Thread c1 = new Thread(new Runnable() {
            @Override public void run() {
                final int[] n = {0};
                try {
                    retryer.call(new Callable<String>() {
                        @Override public String call() { return ++n[0] == 1 ? "retry" : "ok"; }
                    });
                } catch (Exception e) {
                    // a ConcurrentModificationException escaping Retryer.java:166 is the other (CME) half
                    // of the same aliasing (not this finding); swallow it so JPF keeps exploring.
                }
            }
        }, "caller-c1");
        c1.start();
        builder.withRetryListener(new L2());   // builder thread adds a listener after build()
        c1.join();
    }
}
