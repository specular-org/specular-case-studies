import com.github.rholder.retry.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.*;

/** H1.7: a Throwable that is neither Exception nor Error is classified differently with and without a time limit. */
public class P7Weird {
  static class Weird extends Throwable { Weird() { super("weird"); } }
  @SuppressWarnings("unchecked") static <T extends Throwable> void sneaky(Throwable t) throws T { throw (T) t; }
  public static void main(String[] a) throws Exception {
    ExecutorService pool = Executors.newCachedThreadPool(r -> { Thread t = new Thread(r); t.setDaemon(true); return t; });
    for (boolean timed : new boolean[] {false, true}) {
      final AtomicInteger invocations = new AtomicInteger();
      RetryerBuilder<Void> b = RetryerBuilder.<Void>newBuilder().retryIfExceptionOfType(Weird.class).withStopStrategy(StopStrategies.stopAfterAttempt(3));
      if (timed) b.withAttemptTimeLimiter(AttemptTimeLimiters.<Void>fixedTimeLimit(1, TimeUnit.SECONDS, pool));
      String out;
      try { b.build().call(() -> { invocations.incrementAndGet(); P7Weird.<RuntimeException>sneaky(new Weird()); return null; }); out = "returned"; }
      catch (RetryException e) { out = "RetryException attempts=" + e.getNumberOfFailedAttempts() + " cause=" + e.getCause(); }
      catch (ExecutionException e) { out = "ExecutionException cause=" + e.getCause() + (e.getCause() != null && e.getCause().getCause() != null ? " / inner=" + e.getCause().getCause() : ""); }
      System.out.println((timed ? "fixedTimeLimit" : "noTimeLimit   ") + " + retryIfExceptionOfType(Weird): invocations=" + invocations + " -> " + out);
    }
  }
}
