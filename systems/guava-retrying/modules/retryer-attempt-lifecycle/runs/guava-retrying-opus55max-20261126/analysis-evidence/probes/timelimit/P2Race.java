import com.github.rholder.retry.*;
import com.google.common.util.concurrent.ForwardingExecutorService;
import java.util.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.*;

/** H1.2: an attempt whose Future completed NORMALLY is still reported as a timeout and re-executed. */
public class P2Race {
  public static void main(String[] a) throws Exception {
    final int trials = Integer.parseInt(a[0]);
    final long limitMicros = Long.parseLong(a[1]);
    final long spreadMicros = Long.parseLong(a[2]);
    final ThreadPoolExecutor tpe = new ThreadPoolExecutor(4, 4, 60, TimeUnit.SECONDS, new LinkedBlockingQueue<Runnable>(), r -> {
      Thread t = new Thread(r); t.setDaemon(true); return t; });
    tpe.prestartAllCoreThreads();
    final List<Future<?>> submitted = Collections.synchronizedList(new ArrayList<Future<?>>());
    ExecutorService recording = new ForwardingExecutorService() {      // user-supplied executor that only records futures
      @Override protected ExecutorService delegate() { return tpe; }
      @Override public <T> Future<T> submit(Callable<T> task) { Future<T> f = super.submit(task); submitted.add(f); return f; }
    };
    Retryer<Integer> r = RetryerBuilder.<Integer>newBuilder()
        .retryIfRuntimeException()
        .withAttemptTimeLimiter(AttemptTimeLimiters.<Integer>fixedTimeLimit(limitMicros, TimeUnit.MICROSECONDS, recording))
        .withStopStrategy(StopStrategies.stopAfterAttempt(2))
        .build();
    Random rnd = new Random(42);
    int okFirst = 0, cancelled = 0, normalButRetried = 0, other = 0;
    for (int i = 0; i < trials; i++) {
      submitted.clear();
      final AtomicInteger invocations = new AtomicInteger();
      final AtomicBoolean firstReturned = new AtomicBoolean();
      final long offsetNanos = (long) ((rnd.nextDouble() * 2 - 1) * spreadMicros * 1000);
      final long base = System.nanoTime();
      Callable<Integer> c = () -> {
        int k = invocations.incrementAndGet();
        if (k == 1) {
          long target = base + limitMicros * 1000 + offsetNanos;
          while (System.nanoTime() < target) { /* spin; finish near the deadline */ }
          firstReturned.set(true);
        }
        return k;
      };
      int res;
      try { res = r.call(c); } catch (Exception e) { res = -1; }
      Future<?> f1 = submitted.get(0);
      boolean f1Normal = f1.isDone() && !f1.isCancelled();
      if (invocations.get() == 1 && res == 1) okFirst++;
      else if (invocations.get() == 2 && f1Normal) normalButRetried++;
      else if (invocations.get() == 2 && f1.isCancelled()) cancelled++;
      else other++;
    }
    System.out.println("java=" + System.getProperty("java.version") + " trials=" + trials + " limit=" + limitMicros + "us spread=+-" + spreadMicros + "us");
    System.out.println("  firstAttemptResultReturned=" + okFirst + "  firstCancelledThenRetried=" + cancelled
        + "  FIRST_FUTURE_COMPLETED_NORMALLY_BUT_REPORTED_TIMEOUT_AND_REEXECUTED=" + normalButRetried + "  other=" + other);
  }
}
