import com.github.rholder.retry.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.*;

/** H1.4(d): ForkJoinPool as the time-limiter executor. */
public class P4bForkJoin {
  public static void main(String[] a) throws Exception {
    ExecutorService pool = a[0].equals("common") ? ForkJoinPool.commonPool() : new ForkJoinPool(2);
    for (int i = 0; i < 3; i++) {
      final AtomicBoolean interrupted = new AtomicBoolean(), completed = new AtomicBoolean();
      final AtomicLong completedAt = new AtomicLong();
      final AtomicReference<String> ranOn = new AtomicReference<>();
      Retryer<String> r = RetryerBuilder.<String>newBuilder()
          .withAttemptTimeLimiter(AttemptTimeLimiters.<String>fixedTimeLimit(50, TimeUnit.MILLISECONDS, pool)).build();
      long t0 = System.nanoTime();
      String out;
      try {
        out = "returned '" + r.call(() -> { ranOn.set(Thread.currentThread().getName());
          try { Thread.sleep(500); } catch (InterruptedException e) { interrupted.set(true); throw e; }
          completed.set(true); completedAt.set(System.nanoTime()); return "done"; }) + "'";
      } catch (ExecutionException e) { out = "ExecutionException(" + e.getCause().getClass().getSimpleName() + ")"; }
      long callMs = TimeUnit.NANOSECONDS.toMillis(System.nanoTime() - t0);
      Thread.sleep(600);
      System.out.println("java=" + System.getProperty("java.version") + " " + a[0] + " run" + i + ": call() " + out + " after " + callMs + "ms; attempt ran on " + ranOn
          + ", interrupted=" + interrupted + ", completedNormally=" + completed + " at +" + TimeUnit.NANOSECONDS.toMillis(completedAt.get() - t0) + "ms");
    }
  }
}
