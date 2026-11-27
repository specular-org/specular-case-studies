import com.github.rholder.retry.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.*;

/** H1.5: fixedTimeLimit accepts non-positive durations; every attempt fails before the callable runs. */
public class P5Duration {
  public static void main(String[] a) throws Exception {
    for (long d : new long[] {0, -1}) {
      final AtomicInteger invocations = new AtomicInteger();
      AttemptTimeLimiter<Integer> lim = AttemptTimeLimiters.<Integer>fixedTimeLimit(d, TimeUnit.SECONDS); // no exception here
      Retryer<Integer> r = RetryerBuilder.<Integer>newBuilder().retryIfRuntimeException()
          .withAttemptTimeLimiter(lim).withStopStrategy(StopStrategies.stopAfterDelay(100, TimeUnit.MILLISECONDS)).build();
      try { r.call(() -> invocations.incrementAndGet()); }
      catch (RetryException e) { System.out.println("fixedTimeLimit(" + d + ", SECONDS) built fine; call(): RetryException attempts=" + e.getNumberOfFailedAttempts()
          + " in 100ms, callableInvocations=" + invocations + " cause=" + e.getCause()); }
    }
    System.exit(0);
  }
}
