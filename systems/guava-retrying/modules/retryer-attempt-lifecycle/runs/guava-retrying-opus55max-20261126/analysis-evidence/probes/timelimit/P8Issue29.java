import com.github.rholder.retry.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.*;

/** H1.8 (#29): what a per-attempt timeout looks like to predicates in 2.0.0. */
public class P8Issue29 {
  public static void main(String[] a) throws Exception {
    ExecutorService pool = Executors.newCachedThreadPool(r -> { Thread t = new Thread(r); t.setDaemon(true); return t; });
    run("retryIfExceptionOfType(TimeoutException.class)", RetryerBuilder.<Void>newBuilder().retryIfExceptionOfType(TimeoutException.class), pool);
    run("no retryIf* (issue #29 config)", RetryerBuilder.<Void>newBuilder(), pool);
    run("retryIfRuntimeException()", RetryerBuilder.<Void>newBuilder().retryIfRuntimeException(), pool);
  }
  static void run(String name, RetryerBuilder<Void> b, ExecutorService pool) {
    final AtomicInteger invocations = new AtomicInteger();
    Retryer<Void> r = b.withAttemptTimeLimiter(AttemptTimeLimiters.<Void>fixedTimeLimit(50, TimeUnit.MILLISECONDS, pool))
        .withStopStrategy(StopStrategies.stopAfterAttempt(3)).build();
    String out;
    try { r.call(() -> { invocations.incrementAndGet(); Thread.sleep(1000); return null; }); out = "returned"; }
    catch (RetryException e) { out = "RetryException attempts=" + e.getNumberOfFailedAttempts() + " cause=" + e.getCause(); }
    catch (ExecutionException e) { out = "ExecutionException cause=" + e.getCause(); }
    System.out.println(name + ": invocations=" + invocations + " -> " + out);
  }
}
