import com.github.rholder.retry.*;
import com.google.common.base.Predicates;
import java.util.concurrent.Callable;
import static java.util.concurrent.TimeUnit.*;

/** Attempts per second for a trivial polling callable with noWait (default ThreadSleepStrategy -> Thread.sleep(0)). */
public class RateProbe {
  public static void main(String[] args) throws Exception {
    int secs = Integer.parseInt(args[0]);
    boolean noopBlock = args.length > 1 && args[1].equals("noop");
    RetryerBuilder<Boolean> b = RetryerBuilder.<Boolean>newBuilder()
        .retryIfResult(Predicates.equalTo(Boolean.FALSE))
        .withWaitStrategy(WaitStrategies.noWait())
        .withStopStrategy(StopStrategies.stopAfterDelay(secs, SECONDS));
    if (noopBlock) b.withBlockStrategy(new BlockStrategy() { public void block(long t) { } });
    Retryer<Boolean> r = b.build();
    long t0 = System.nanoTime();
    try {
      r.call(new Callable<Boolean>() { public Boolean call() { return Boolean.FALSE; } });
    } catch (RetryException e) {
      double el = (System.nanoTime() - t0) / 1e9;
      long n = e.getNumberOfFailedAttempts();
      double rate = n / el;
      System.out.printf("block=%s attempts=%d in %.2fs -> %.3g attempts/s ; 2^31 attempts would take %.1f s (%.1f min)%n",
          noopBlock ? "noop" : "Thread.sleep(0)", n, el, rate, Math.pow(2, 31) / rate, Math.pow(2, 31) / rate / 60);
    }
  }
}
