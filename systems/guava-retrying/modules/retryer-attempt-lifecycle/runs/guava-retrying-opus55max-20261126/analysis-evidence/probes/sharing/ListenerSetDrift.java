import com.github.rholder.retry.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.*;

/** #48 aliasing observed by an in-flight call: listener added to the builder during the inter-attempt sleep. */
public class ListenerSetDrift {
  public static void main(String[] args) throws Exception {
    final AtomicInteger l1 = new AtomicInteger(), l2 = new AtomicInteger();
    final RetryerBuilder<String> builder = RetryerBuilder.<String>newBuilder()
        .retryIfException()
        .withWaitStrategy(WaitStrategies.fixedWait(300, TimeUnit.MILLISECONDS))
        .withStopStrategy(StopStrategies.stopAfterAttempt(3))
        .withRetryListener(new RetryListener() { public <V> void onRetry(Attempt<V> a) { l1.incrementAndGet(); } });
    final Retryer<String> first = builder.build();
    final AtomicInteger n = new AtomicInteger();
    Thread t = new Thread(new Runnable() { public void run() {
      try { System.out.println("first.call -> " + first.call(new Callable<String>() {
        public String call() throws Exception { if (n.incrementAndGet() < 3) throw new RuntimeException("x"); return "ok"; } })); }
      catch (Throwable e) { System.out.println("first.call threw " + e); }
    }});
    t.start();
    Thread.sleep(150); // first attempt done, caller sleeping 300ms before attempt 2
    builder.withRetryListener(new RetryListener() { public <V> void onRetry(Attempt<V> a) { l2.incrementAndGet(); } });
    Retryer<String> second = builder.build();
    t.join();
    System.out.println("listener configured for 'first' notified " + l1.get() + "x; listener added later (for 'second') notified by first.call " + l2.get() + "x");
  }
}
