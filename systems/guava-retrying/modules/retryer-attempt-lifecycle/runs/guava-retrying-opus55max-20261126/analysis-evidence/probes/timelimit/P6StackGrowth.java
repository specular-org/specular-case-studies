import com.github.rholder.retry.*;
import java.io.IOException;
import java.util.concurrent.*;

/** H1.6: Guava throwCause(e, true) appends the caller's stack to a reused exception on every timed attempt. */
public class P6StackGrowth {
  static final IOException SHARED = new IOException("cached failure");   // common "preallocated exception" pattern
  public static void main(String[] a) throws Exception {
    ExecutorService pool = Executors.newCachedThreadPool(r -> { Thread t = new Thread(r); t.setDaemon(true); return t; });
    boolean timed = a[0].equals("timed");
    System.out.println((timed ? "fixedTimeLimit" : "noTimeLimit") + ": initial stack length=" + SHARED.getStackTrace().length);
    for (int n : new int[] {1, 10, 100, 1000, 10000}) {
      RetryerBuilder<Void> b = RetryerBuilder.<Void>newBuilder().retryIfException().withStopStrategy(StopStrategies.stopAfterAttempt(n));
      if (timed) b.withAttemptTimeLimiter(AttemptTimeLimiters.<Void>fixedTimeLimit(1, TimeUnit.SECONDS, pool));
      try { b.build().call(() -> { throw SHARED; }); } catch (RetryException e) { }
      System.out.println("  after +" + n + " attempts: SHARED.getStackTrace().length=" + SHARED.getStackTrace().length);
    }
  }
}
