import com.github.rholder.retry.*;
import java.io.IOException;
import java.util.concurrent.*;
import java.util.concurrent.atomic.*;

/** H2.7: wrap() submitted to an executor; Future.cancel(true) / shutdownNow() interrupt the thread running Retryer.call. */
public class IntProbe3 {
  static volatile boolean stopAll = false;

  static void scenario(String name, Retryer<String> retryer, final long callableSleepMs, String how) throws Exception {
    stopAll = false;
    final AtomicInteger calls = new AtomicInteger();
    final AtomicReference<String> taskEnd = new AtomicReference<String>("still running");
    Callable<String> failing = new Callable<String>() { public String call() throws Exception {
      calls.incrementAndGet();
      if (stopAll) return "stopped-by-probe";
      Thread.sleep(callableSleepMs);          // interruptible blocking work, like an I/O wait
      throw new IOException("transient failure");
    }};
    final Callable<String> wrapped = retryer.wrap(failing);
    ExecutorService exec = Executors.newSingleThreadExecutor();
    Future<String> f = exec.submit(new Callable<String>() { public String call() throws Exception {
      try { String r = wrapped.call(); taskEnd.set("returned " + r); return r; }
      catch (Throwable t) { taskEnd.set("threw " + t); throw (t instanceof Exception) ? (Exception) t : new RuntimeException(t); }
    }});
    Thread.sleep(1200);
    int atInterrupt = calls.get();
    boolean cancelled = false;
    if (how.equals("cancel")) cancelled = f.cancel(true); else exec.shutdownNow();
    Thread.sleep(2000);
    int after2s = calls.get();
    if (how.equals("cancel")) exec.shutdown();
    boolean terminated = exec.awaitTermination(1, TimeUnit.SECONDS);
    System.out.println(name + " [" + how + "] cancelReturned=" + cancelled + " isCancelled=" + f.isCancelled()
        + " callableInvocations atInterrupt=" + atInterrupt + " +2s=" + after2s
        + " | retry task: " + taskEnd.get() + " | executor terminated within 1s after shutdown=" + terminated);
    stopAll = true; // let the loop finish so the probe can exit
    exec.shutdownNow();
    exec.awaitTermination(10, TimeUnit.SECONDS);
  }

  public static void main(String[] args) throws Exception {
    System.out.println("java.version=" + System.getProperty("java.version"));
    ExecutorService limiterPool = Executors.newCachedThreadPool(new ThreadFactory() {
      public Thread newThread(Runnable r) { Thread t = new Thread(r, "limiter-worker"); t.setDaemon(true); return t; }});
    AttemptTimeLimiter<String> fixed5s = AttemptTimeLimiters.<String>fixedTimeLimit(5, TimeUnit.SECONDS, limiterPool);

    for (String how : new String[]{"cancel", "shutdownNow"}) {
      scenario("H2.7a noLimit retryIfException neverStop noWait",
          RetryerBuilder.<String>newBuilder().retryIfException().build(), 300, how);
      scenario("H2.7b fixed5s retryIfException neverStop noWait",
          RetryerBuilder.<String>newBuilder().retryIfException().withAttemptTimeLimiter(fixed5s).build(), 300, how);
      scenario("H2.7c noLimit retryIfException neverStop fixedWait(10ms)",
          RetryerBuilder.<String>newBuilder().retryIfException().withWaitStrategy(WaitStrategies.fixedWait(10, TimeUnit.MILLISECONDS)).build(), 300, how);
      scenario("H2.7d noLimit retryIfExceptionOfType(IOException) neverStop noWait (control: IE not matched)",
          RetryerBuilder.<String>newBuilder().retryIfExceptionOfType(IOException.class).build(), 300, how);
    }
    limiterPool.shutdownNow();
  }
}
