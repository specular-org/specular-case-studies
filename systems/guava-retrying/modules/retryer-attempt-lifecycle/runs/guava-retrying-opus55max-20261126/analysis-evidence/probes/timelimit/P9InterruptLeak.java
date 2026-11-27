import com.github.rholder.retry.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.*;

/** H1.9: does the cancel(true) interrupt for a timed-out attempt reach the next attempt on the same worker thread? */
public class P9InterruptLeak {
  /** A minimal single-thread ExecutorService that does NOT clear interrupt status between tasks (unlike ThreadPoolExecutor). */
  static class NaiveSingleThreadExecutor extends AbstractExecutorService {
    final BlockingQueue<Runnable> q = new LinkedBlockingQueue<>();
    final Thread worker = new Thread(() -> { while (true) { Runnable r; while ((r = q.poll()) == null) java.util.concurrent.locks.LockSupport.parkNanos(100_000L); r.run(); } }, "naive-worker");
    NaiveSingleThreadExecutor() { worker.setDaemon(true); worker.start(); }
    public void execute(Runnable r) { q.add(r); }
    public void shutdown() {} public java.util.List<Runnable> shutdownNow() { return null; } public boolean isShutdown() { return false; }
    public boolean isTerminated() { return false; } public boolean awaitTermination(long t, TimeUnit u) { return false; }
  }
  public static void main(String[] a) throws Exception {
    test("Executors.newSingleThreadExecutor()", Executors.newSingleThreadExecutor(r -> { Thread t = new Thread(r); t.setDaemon(true); return t; }));
    test("naive custom executor (poll()/parkNanos loop, never clears interrupt status)", new NaiveSingleThreadExecutor());
  }
  static void test(String name, ExecutorService pool) {
    final AtomicInteger invocations = new AtomicInteger();
    final StringBuffer seen = new StringBuffer();
    Retryer<Integer> r = RetryerBuilder.<Integer>newBuilder().retryIfException()
        .withAttemptTimeLimiter(AttemptTimeLimiters.<Integer>fixedTimeLimit(300, TimeUnit.MILLISECONDS, pool))
        .withStopStrategy(StopStrategies.stopAfterAttempt(3)).build();
    String out;
    try {
      out = "returned " + r.call(() -> {
        int k = invocations.incrementAndGet();
        seen.append(" attempt").append(k).append(":startedInterrupted=").append(Thread.currentThread().isInterrupted());
        if (k == 1) { long end = System.nanoTime() + 350_000_000L; while (System.nanoTime() < end) { } return k; } // ignores the cancel interrupt, ends at 350ms
        Thread.sleep(10);                       // a well-behaved second attempt doing a short interruptible wait
        return k;
      });
    } catch (Exception e) { out = e.getClass().getSimpleName() + " cause=" + e.getCause(); }
    System.out.println(name + ": " + out + " |" + seen);
  }
}
