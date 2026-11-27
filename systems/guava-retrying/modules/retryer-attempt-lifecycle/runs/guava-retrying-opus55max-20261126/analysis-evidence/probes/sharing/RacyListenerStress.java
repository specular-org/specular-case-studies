import com.github.rholder.retry.*;
import java.util.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.*;

/**
 * H3.1 without any coordination: thread A reuses the builder (adds listeners, builds new retryers)
 * while thread B keeps calling a Retryer built earlier from that builder. Counts outcomes of B's calls.
 */
public class RacyListenerStress {
  static final RetryListener NOOP = new RetryListener() { public <V> void onRetry(Attempt<V> a) { } };
  public static void main(String[] args) throws Exception {
    long seconds = Long.parseLong(args.length > 0 ? args[0] : "20");
    final Map<String, AtomicLong> outcomes = new ConcurrentHashMap<String, AtomicLong>();
    final Callable<Integer> work = new Callable<Integer>() { public Integer call() { return 1; } };
    final long deadline = System.nanoTime() + TimeUnit.SECONDS.toNanos(seconds);
    long rounds = 0;
    while (System.nanoTime() < deadline) {
      rounds++;
      final RetryerBuilder<Integer> builder = RetryerBuilder.<Integer>newBuilder().withRetryListener(NOOP);
      for (int i = 0; i < 8; i++) builder.withRetryListener(NOOP);       // 9 listeners; capacity 10
      final Retryer<Integer> first = builder.build();
      final AtomicBoolean stop = new AtomicBoolean();
      Thread caller = new Thread(new Runnable() { public void run() {
        while (!stop.get()) {
          String k;
          try { first.call(work); k = "returned"; }
          catch (Throwable e) { k = e.getClass().getSimpleName(); }
          AtomicLong c = outcomes.get(k);
          if (c == null) { outcomes.putIfAbsent(k, new AtomicLong()); c = outcomes.get(k); }
          c.incrementAndGet();
        }
      }});
      caller.start();
      for (int i = 0; i < 40; i++) { builder.withRetryListener(NOOP); }   // crosses capacity 10 -> 15 -> 22 -> 33 -> 49 (array copies)
      builder.build();
      stop.set(true);
      caller.join();
    }
    System.out.println("rounds=" + rounds + " outcomes=" + new TreeMap<String, AtomicLong>(outcomes));
  }
}
