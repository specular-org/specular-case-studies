import com.github.rholder.retry.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.*;

/** H2.8: caller interrupted while attempt 1 (ignores interrupts) runs under fixedTimeLimit: cancelled attempt keeps running. */
public class IntProbe4 {
  static final long T0 = System.nanoTime();
  static long now() { return (System.nanoTime() - T0) / 1_000_000; }
  public static void main(String[] args) throws Exception {
    System.out.println("java.version=" + System.getProperty("java.version"));
    ExecutorService pool = Executors.newCachedThreadPool(new ThreadFactory() {
      public Thread newThread(Runnable r) { Thread t = new Thread(r, "limiter-worker"); t.setDaemon(true); return t; }});
    final AtomicInteger calls = new AtomicInteger(), running = new AtomicInteger(), maxRunning = new AtomicInteger();
    final AtomicLong attempt1End = new AtomicLong(-1);
    final Callable<String> c = new Callable<String>() { public String call() {
      int n = calls.incrementAndGet();
      int r = running.incrementAndGet(); maxRunning.accumulateAndGet(r, Math::max);
      try {
        if (n == 1) { long end = System.nanoTime() + 1_500_000_000L; while (System.nanoTime() < end) { /* ignores interrupts */ } attempt1End.set(now()); return "late-first"; }
        return "ok";
      } finally { running.decrementAndGet(); }
    }};
    final Retryer<String> r = RetryerBuilder.<String>newBuilder().retryIfException()
        .withAttemptTimeLimiter(AttemptTimeLimiters.<String>fixedTimeLimit(5, TimeUnit.SECONDS, pool)).build();
    final AtomicReference<String> out = new AtomicReference<String>();
    final AtomicLong callEnd = new AtomicLong();
    Thread t = new Thread(new Runnable() { public void run() {
      try { out.set("RETURNED " + r.call(c)); } catch (Exception e) { out.set("THREW " + e); }
      callEnd.set(now()); out.set(out.get() + " flagAtExit=" + Thread.currentThread().isInterrupted());
    }});
    t.start(); Thread.sleep(300); long tInt = now(); t.interrupt(); t.join();
    Thread.sleep(1700);
    System.out.println("H2.8 interrupt at t=" + tInt + "ms; call() " + out.get() + " at t=" + callEnd.get()
        + "ms; attempt-1 callable finished at t=" + attempt1End.get() + "ms; invocations=" + calls.get() + " maxConcurrentAttempts=" + maxRunning.get());
    pool.shutdownNow();
  }
}
