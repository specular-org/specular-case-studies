import com.github.rholder.retry.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.*;

/**
 * H3.5: one Retryer (one fixedTimeLimit executor) shared by several threads. Two callers run a callable that
 * ignores interruption; a third caller's fast callable then never gets a pool thread: its attempts time out
 * while queued and are reported as timeouts of *its* callable, although that callable never ran.
 */
public class SharedLimiterStarvation {
  public static void main(String[] args) throws Exception {
    ExecutorService pool = Executors.newFixedThreadPool(2);
    final Retryer<String> shared = RetryerBuilder.<String>newBuilder()
        .retryIfRuntimeException()
        .withAttemptTimeLimiter(AttemptTimeLimiters.<String>fixedTimeLimit(200, TimeUnit.MILLISECONDS, pool))
        .withStopStrategy(StopStrategies.stopAfterAttempt(3))
        .build();
    final Callable<String> stubborn = new Callable<String>() { public String call() {
      long end = System.nanoTime() + TimeUnit.SECONDS.toNanos(3);
      while (System.nanoTime() < end) { /* ignores interrupts (e.g. blocking socket read) */ }
      return "slow"; } };
    final AtomicInteger fastRuns = new AtomicInteger();
    final Callable<String> fast = new Callable<String>() { public String call() { fastRuns.incrementAndGet(); return "fast"; } };
    for (int i = 0; i < 2; i++) {
      new Thread(new Runnable() { public void run() {
        try { shared.call(stubborn); } catch (Throwable e) { /* expected RetryException */ }
      }}).start();
    }
    Thread.sleep(50);
    long t0 = System.nanoTime();
    try {
      System.out.println("good caller -> " + shared.call(fast));
    } catch (RetryException e) {
      System.out.println("good caller: RetryException after " + e.getNumberOfFailedAttempts() + " attempts; last cause = " + e.getCause()
          + " (" + TimeUnit.NANOSECONDS.toMillis(System.nanoTime() - t0) + " ms)");
    }
    System.out.println("good callable invocations: " + fastRuns.get());
    pool.shutdownNow();
    System.exit(0);
  }
}
