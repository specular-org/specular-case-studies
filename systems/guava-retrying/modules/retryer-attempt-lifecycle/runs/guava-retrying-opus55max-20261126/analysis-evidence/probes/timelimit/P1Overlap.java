import com.github.rholder.retry.*;
import java.util.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.*;

/** H1.1: timed-out attempts that ignore interrupts overlap later attempts and outlive call(). */
public class P1Overlap {
  static final AtomicInteger running = new AtomicInteger(), maxRunning = new AtomicInteger(), started = new AtomicInteger(),
      finished = new AtomicInteger(), finishedAfterCallEnded = new AtomicInteger(), interruptsSeen = new AtomicInteger();
  static volatile boolean callEnded = false;

  public static void main(String[] a) throws Exception {
    final String mode = a.length > 0 ? a[0] : "allTimeout";   // allTimeout | lastSucceeds
    Retryer<Integer> r = RetryerBuilder.<Integer>newBuilder()
        .retryIfRuntimeException()
        .withAttemptTimeLimiter(AttemptTimeLimiters.<Integer>fixedTimeLimit(100, TimeUnit.MILLISECONDS)) // default 2-arg factory
        .withStopStrategy(StopStrategies.stopAfterAttempt(4))
        .build();
    Callable<Integer> c = new Callable<Integer>() {
      public Integer call() {
        int n = started.incrementAndGet();
        int now = running.incrementAndGet();
        maxRunning.accumulateAndGet(now, Math::max);
        try {
          if (mode.equals("lastSucceeds") && n == 4) return n;      // quick success on the last attempt
          long end = System.nanoTime() + TimeUnit.MILLISECONDS.toNanos(500);
          while (System.nanoTime() < end) {                          // ignores interrupts (e.g. blocking socket read)
            try { Thread.sleep(5); } catch (InterruptedException ie) { interruptsSeen.incrementAndGet(); }
          }
          finished.incrementAndGet();                                 // the attempt's side effect
          if (callEnded) finishedAfterCallEnded.incrementAndGet();
          return n;
        } finally { running.decrementAndGet(); }
      }
    };
    long t0 = System.nanoTime();
    String outcome;
    try { outcome = "call() returned " + r.call(c); }
    catch (RetryException e) { outcome = "RetryException attempts=" + e.getNumberOfFailedAttempts() + " cause=" + e.getCause(); }
    catch (ExecutionException e) { outcome = "ExecutionException cause=" + e.getCause(); }
    callEnded = true;
    long ms = TimeUnit.NANOSECONDS.toMillis(System.nanoTime() - t0);
    System.out.println("mode=" + mode + " | " + outcome + " after " + ms + "ms");
    System.out.println("at call() end: attemptsStarted=" + started + " stillRunning=" + running + " maxConcurrentAttempts=" + maxRunning
        + " poolThreads=" + poolThreads());
    Thread.sleep(1000);
    System.out.println("1s later: finished=" + finished + " finishedAfterCallEnded=" + finishedAfterCallEnded
        + " interruptsDeliveredToAttempts=" + interruptsSeen + " stillRunning=" + running + " poolThreads=" + poolThreads());
    System.exit(0); // avoid the 60s idle keep-alive of the private cached pool (#92)
  }
  static long poolThreads() {
    long n = 0; for (Thread t : Thread.getAllStackTraces().keySet()) if (t.getName().startsWith("pool-")) n++; return n;
  }
}
