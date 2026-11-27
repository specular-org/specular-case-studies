import com.github.rholder.retry.*;
import com.google.common.base.Predicates;
import java.util.concurrent.Callable;
import static java.util.concurrent.TimeUnit.*;

/** Drives Retryer.call past 2^31-1 attempts (noWait; a BlockStrategy that returns at once for the 0 ms sleeps it is given)
 *  and records what listeners and RetryException report around the int wrap of Retryer.call's attempt counter. */
public class WrapProbe {
  static volatile long firstNonPositive = Long.MAX_VALUE; static long seenAtMax = 0, after1 = 0, after2 = 0; static long calls = 0;
  public static void main(String[] args) throws Exception {
    int secs = Integer.parseInt(args[0]);
    Retryer<Boolean> r = RetryerBuilder.<Boolean>newBuilder()
        .retryIfResult(Predicates.equalTo(Boolean.FALSE))
        .withWaitStrategy(WaitStrategies.noWait())
        .withStopStrategy(StopStrategies.stopAfterDelay(secs, SECONDS))
        .withBlockStrategy(new BlockStrategy() { public void block(long t) throws InterruptedException { if (t != 0) Thread.sleep(t); } })
        .withRetryListener(new RetryListener() {
          long prev = 0;
          public <V> void onRetry(Attempt<V> a) {
            long n = a.getAttemptNumber();
            if (prev == Integer.MAX_VALUE) { after1 = n; }
            if (prev == Integer.MIN_VALUE) { after2 = n; }
            if (n == Integer.MAX_VALUE) seenAtMax++;
            if (n <= 0 && firstNonPositive == Long.MAX_VALUE) firstNonPositive = n;
            prev = n;
          }
        })
        .build();
    long t0 = System.nanoTime();
    try {
      r.call(new Callable<Boolean>() { public Boolean call() { calls++; return Boolean.FALSE; } });
    } catch (RetryException e) {
      System.out.printf("elapsed %.1fs ; callable ran %d times ; RetryException.getNumberOfFailedAttempts()=%d ; lastFailedAttempt.getAttemptNumber()=%d%n",
          (System.nanoTime() - t0) / 1e9, calls, e.getNumberOfFailedAttempts(), e.getLastFailedAttempt().getAttemptNumber());
      System.out.println("listener: attempt after 2147483647 had number " + after1 + " ; attempt after -2147483648 had number " + after2 + " ; first non-positive number seen " + firstNonPositive);
      System.out.println("message: " + e.getMessage());
    }
  }
}
