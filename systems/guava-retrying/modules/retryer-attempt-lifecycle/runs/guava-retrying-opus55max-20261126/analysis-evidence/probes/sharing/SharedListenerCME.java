import com.github.rholder.retry.*;
import com.google.common.base.Predicate;
import java.util.concurrent.*;
import java.util.concurrent.atomic.*;

/**
 * H3.1: a builder reused after build() (as in #48) while a Retryer it built is inside the
 * listener loop on another thread. Deterministic schedule via latches (the latches give
 * happens-before, so this is a legal sequentially-consistent interleaving, not a JMM artefact).
 */
public class SharedListenerCME {
  static AtomicInteger sideEffects = new AtomicInteger();
  static AtomicInteger predicateCalls = new AtomicInteger();
  static AtomicInteger stopCalls = new AtomicInteger();

  public static void main(String[] args) throws Exception {
    boolean failingCallable = args.length > 0 && args[0].equals("failing");
    final CountDownLatch inListener = new CountDownLatch(1);
    final CountDownLatch proceed = new CountDownLatch(1);
    final AtomicInteger l1Calls = new AtomicInteger(), l2Calls = new AtomicInteger();

    RetryListener l1 = new RetryListener() {
      @Override public <V> void onRetry(Attempt<V> attempt) {
        l1Calls.incrementAndGet();
        if (attempt.getAttemptNumber() == 1) {
          inListener.countDown();
          try { proceed.await(); } catch (InterruptedException e) { Thread.currentThread().interrupt(); }
        }
      }
    };
    RetryListener l2 = new RetryListener() {
      @Override public <V> void onRetry(Attempt<V> attempt) { l2Calls.incrementAndGet(); }
    };

    final RetryerBuilder<String> builder = RetryerBuilder.<String>newBuilder()
        .retryIfResult(new Predicate<String>() {
          @Override public boolean apply(String s) { predicateCalls.incrementAndGet(); return false; }
        })
        .retryIfException()
        .withStopStrategy(new StopStrategy() {
          @Override public boolean shouldStop(Attempt a) { stopCalls.incrementAndGet(); return a.getAttemptNumber() >= 3; }
        })
        .withRetryListener(l1);
    final Retryer<String> first = builder.build();

    final Callable<String> work = new Callable<String>() {
      @Override public String call() throws Exception {
        sideEffects.incrementAndGet();          // e.g. "charge the card"
        if (failingCallable) throw new java.io.IOException("transient");
        return "ok";
      }
    };
    final AtomicReference<Object> outcome = new AtomicReference<Object>();
    Thread t = new Thread(new Runnable() {
      @Override public void run() {
        try { outcome.set("returned " + first.call(work)); }
        catch (Throwable e) { outcome.set(e); }
      }
    }, "caller");
    t.start();

    inListener.await();
    // Another component reuses the builder to configure a second retryer (#48 pattern).
    builder.withRetryListener(l2);
    Retryer<String> second = builder.build();
    proceed.countDown();
    t.join(10000);

    Object o = outcome.get();
    System.out.println("mode=" + (failingCallable ? "failing-callable(should be retried)" : "succeeding-callable"));
    System.out.println("first.call outcome: " + (o instanceof Throwable ? ((Throwable) o).getClass().getName() + ": " + ((Throwable) o).getMessage() : o));
    if (o instanceof Throwable) {
      StackTraceElement[] st = ((Throwable) o).getStackTrace();
      for (int i = 0; i < Math.min(4, st.length); i++) System.out.println("   at " + st[i]);
    }
    System.out.println("callable side effects executed: " + sideEffects.get());
    System.out.println("rejection-predicate result calls: " + predicateCalls.get() + ", stop-strategy calls: " + stopCalls.get());
    System.out.println("l1 calls=" + l1Calls.get() + " l2 calls=" + l2Calls.get());
  }
}
