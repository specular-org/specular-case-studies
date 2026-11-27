import com.github.rholder.retry.*;
import com.google.common.base.Predicates;
import java.util.concurrent.*;
import java.util.concurrent.atomic.*;
public class Cal {
  public static void main(String[] a) throws Exception {
    final String mode = a[0]; final long secs = Long.parseLong(a[1]);
    final long deadline = System.nanoTime() + TimeUnit.SECONDS.toNanos(secs);
    final long[] count = {0};
    RetryerBuilder<Boolean> b = RetryerBuilder.<Boolean>newBuilder()
        .retryIfResult(Predicates.equalTo(Boolean.FALSE))
        .withRetryListener(new RetryListener() { public <V> void onRetry(Attempt<V> at) { count[0]++; } });
    if (mode.equals("zeroskip")) b.withBlockStrategy(new BlockStrategy() {
        public void block(long t) throws InterruptedException { if (Thread.interrupted()) throw new InterruptedException(); if (t > 0) Thread.sleep(t); } });
    Retryer<Boolean> r = b.build();
    long t0 = System.nanoTime();
    r.call(new Callable<Boolean>() { int k = 0; public Boolean call() { return ((++k & 0xFFF) == 0) && System.nanoTime() > deadline; } });
    double s = (System.nanoTime() - t0) / 1e9;
    System.out.printf("mode=%s attempts=%d secs=%.2f rate=%.3e/s est_secs_to_2^31=%.0f%n", mode, count[0], s, count[0]/s, Math.pow(2,31)/(count[0]/s));
  }
}
