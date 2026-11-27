import com.github.rholder.retry.*;
import com.google.common.base.Function;
import java.io.IOException;
import java.util.concurrent.Callable;
import java.util.concurrent.atomic.AtomicInteger;
import static java.util.concurrent.TimeUnit.*;

/** Built-in wait strategies feeding the default ThreadSleepStrategy: which exception leaves Retryer.call? */
public class EscapeProbe {
  static class RetryAfterException extends IOException { final long retryAtMillis; RetryAfterException(long t) { retryAtMillis = t; } }
  static void run(String label, WaitStrategy w, boolean interruptFirst) {
    final AtomicInteger calls = new AtomicInteger();
    Retryer<String> r = RetryerBuilder.<String>newBuilder().retryIfException().withWaitStrategy(w)
        .withStopStrategy(StopStrategies.stopAfterAttempt(3)).build();
    if (interruptFirst) Thread.currentThread().interrupt();
    try {
      String v = r.call(new Callable<String>() { public String call() throws Exception {
        calls.incrementAndGet();
        throw new RetryAfterException(System.currentTimeMillis() - 5000); // server said "retry at <time>", already 5 s in the past
      } });
      System.out.println(label + ": returned " + v);
    } catch (RetryException e) {
      System.out.println(label + ": RetryException attempts=" + e.getNumberOfFailedAttempts());
    } catch (java.util.concurrent.ExecutionException e) {
      System.out.println(label + ": ExecutionException " + e.getCause());
    } catch (Throwable t) {
      System.out.println(label + ": ESCAPED " + t + " after callable ran " + calls.get() + " time(s); interrupted=" + Thread.interrupted());
    }
  }
  public static void main(String[] args) {
    run("(a) join(exceptionWait(e -> Long.MAX_VALUE), randomWait(1s))",
        WaitStrategies.join(WaitStrategies.exceptionWait(RetryAfterException.class, new Function<RetryAfterException, Long>() { public Long apply(RetryAfterException e) { return Long.MAX_VALUE; } }),
                            WaitStrategies.randomWait(1, SECONDS)), false);
    run("(b) exceptionWait(e -> retryAt - now) with retryAt in the past",
        WaitStrategies.exceptionWait(RetryAfterException.class, new Function<RetryAfterException, Long>() { public Long apply(RetryAfterException e) { return e.retryAtMillis - System.currentTimeMillis(); } }), false);
    run("(c) exceptionWait(e -> null)",
        WaitStrategies.exceptionWait(RetryAfterException.class, new Function<RetryAfterException, Long>() { public Long apply(RetryAfterException e) { return null; } }), false);
    run("(d) join(fixedWait(Long.MAX_VALUE, MILLISECONDS), fixedWait(1, SECONDS))",
        WaitStrategies.join(WaitStrategies.fixedWait(Long.MAX_VALUE, MILLISECONDS), WaitStrategies.fixedWait(1, SECONDS)), false);
    run("(e) as (b) but caller thread already interrupted",
        WaitStrategies.exceptionWait(RetryAfterException.class, new Function<RetryAfterException, Long>() { public Long apply(RetryAfterException e) { return e.retryAtMillis - System.currentTimeMillis(); } }), true);
  }
}
