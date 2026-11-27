import com.github.rholder.retry.*;
import java.util.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.*;

/** Same race as RacyListenerStress, but the configured listener does ~20us of work (e.g. logging/metrics),
 *  and the reusing thread adds one listener per ~1ms (e.g. building retryers for other components over time). */
public class RacyListenerStressSlow {
  public static void main(String[] args) throws Exception {
    long seconds = Long.parseLong(args.length > 0 ? args[0] : "10");
    final RetryListener slow = new RetryListener() { public <V> void onRetry(Attempt<V> a) {
      long end = System.nanoTime() + 20_000; while (System.nanoTime() < end) { } } };
    final RetryListener noop = new RetryListener() { public <V> void onRetry(Attempt<V> a) { } };
    final RetryerBuilder<Integer> builder = RetryerBuilder.<Integer>newBuilder().withRetryListener(slow);
    final Retryer<Integer> first = builder.build();
    final Callable<Integer> work = new Callable<Integer>() { public Integer call() { return 1; } };
    final Map<String, AtomicLong> outcomes = new ConcurrentHashMap<String, AtomicLong>();
    final AtomicBoolean stop = new AtomicBoolean();
    Thread caller = new Thread(new Runnable() { public void run() {
      while (!stop.get()) {
        String k;
        try { first.call(work); k = "returned"; } catch (Throwable e) { k = e.getClass().getSimpleName(); }
        outcomes.computeIfAbsent(k, x -> new AtomicLong()).incrementAndGet();
      }
    }});
    caller.start();
    long deadline = System.nanoTime() + TimeUnit.SECONDS.toNanos(seconds);
    int added = 0;
    while (System.nanoTime() < deadline) { Thread.sleep(1); builder.withRetryListener(noop); builder.build(); added++; }
    stop.set(true); caller.join();
    System.out.println("listeners added to builder after build()=" + added + " outcomes of first.call=" + new TreeMap<String, AtomicLong>(outcomes));
  }
}
