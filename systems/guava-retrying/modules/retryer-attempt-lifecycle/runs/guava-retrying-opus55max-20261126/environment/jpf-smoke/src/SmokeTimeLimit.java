import com.github.rholder.retry.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicInteger;

/** Retry with a per-attempt time limit on a pool thread; reports how each run ended. */
public class SmokeTimeLimit {
  public static void main(String[] args) throws Exception {
    ExecutorService pool = Executors.newSingleThreadExecutor();
    AtomicInteger started = new AtomicInteger();
    Retryer<Integer> r = RetryerBuilder.<Integer>newBuilder()
        .retryIfException()
        .withAttemptTimeLimiter(AttemptTimeLimiters.<Integer>fixedTimeLimit(50, TimeUnit.MILLISECONDS, pool))
        .withStopStrategy(StopStrategies.stopAfterAttempt(2))
        .build();
    String outcome;
    try {
      outcome = "result=" + r.call(() -> started.incrementAndGet());
    } catch (RetryException e) {
      outcome = "retryException attempts=" + e.getNumberOfFailedAttempts() + " cause=" + e.getCause();
    } finally {
      pool.shutdownNow();
    }
    System.out.println(outcome + " started=" + started.get());
  }
}
