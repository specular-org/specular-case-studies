import com.github.rholder.retry.*;
import com.google.common.util.concurrent.MoreExecutors;
import java.io.IOException;
import java.util.concurrent.*;
import java.util.concurrent.atomic.*;

/** H1.4: user-supplied executors that are saturated, bounded, shut down, direct/caller-runs, or ForkJoin. */
public class P4Executors {
  static ThreadFactory daemon = r -> { Thread t = new Thread(r); t.setDaemon(true); return t; };

  public static void main(String[] a) throws Exception {
    String which = a[0];
    switch (which) {
      case "saturatedFixed1": saturated(Executors.newFixedThreadPool(1, daemon), "newFixedThreadPool(1)"); break;
      case "boundedQueue":   saturated(new ThreadPoolExecutor(1, 1, 0, TimeUnit.MILLISECONDS, new ArrayBlockingQueue<Runnable>(1), daemon), "TPE(1,1,ArrayBlockingQueue(1),AbortPolicy)"); break;
      case "shutdown": shutdown(); break;
      case "direct": noLimit(MoreExecutors.newDirectExecutorService(), "newDirectExecutorService()", false); break;
      case "callerRuns": {
        ThreadPoolExecutor tpe = new ThreadPoolExecutor(1, 1, 0, TimeUnit.MILLISECONDS, new SynchronousQueue<Runnable>(), daemon, new ThreadPoolExecutor.CallerRunsPolicy());
        noLimit(tpe, "TPE(1,1,SynchronousQueue,CallerRunsPolicy) with its only worker busy", true); break; }
      case "forkjoin": forkJoin(); break;
    }
  }

  /** attempt 1 ignores interrupts for 1s; later attempts would succeed instantly if they ever ran */
  static void saturated(ExecutorService pool, String name) throws Exception {
    final AtomicInteger invocations = new AtomicInteger();
    Retryer<Integer> r = RetryerBuilder.<Integer>newBuilder().retryIfRuntimeException()
        .withAttemptTimeLimiter(AttemptTimeLimiters.<Integer>fixedTimeLimit(100, TimeUnit.MILLISECONDS, pool))
        .withStopStrategy(StopStrategies.stopAfterAttempt(5)).build();
    final StringBuffer causes = new StringBuffer();
    r = RetryerBuilder.<Integer>newBuilder().retryIfRuntimeException()
        .withAttemptTimeLimiter(AttemptTimeLimiters.<Integer>fixedTimeLimit(100, TimeUnit.MILLISECONDS, pool))
        .withStopStrategy(StopStrategies.stopAfterAttempt(5))
        .withRetryListener(new RetryListener() { public <V> void onRetry(Attempt<V> at) {
          causes.append(" #").append(at.getAttemptNumber()).append('=').append(at.hasException() ? at.getExceptionCause().getClass().getSimpleName() : "result"); } })
        .build();
    long t0 = System.nanoTime();
    try {
      Integer v = r.call(() -> {
        int k = invocations.incrementAndGet();
        if (k == 1) { long end = System.nanoTime() + 1_000_000_000L; while (System.nanoTime() < end) { try { Thread.sleep(5); } catch (InterruptedException ignored) {} } }
        return k;
      });
      System.out.println(name + ": returned " + v);
    } catch (RetryException e) {
      System.out.println(name + ": RetryException attempts=" + e.getNumberOfFailedAttempts() + " lastCause=" + e.getCause());
    }
    System.out.println("  elapsed=" + TimeUnit.NANOSECONDS.toMillis(System.nanoTime() - t0) + "ms callableInvocations=" + invocations + " attemptOutcomes:" + causes);
  }

  static void shutdown() throws Exception {
    ExecutorService pool = Executors.newCachedThreadPool(daemon);
    pool.shutdown();
    final AtomicInteger invocations = new AtomicInteger();
    Retryer<Integer> busy = RetryerBuilder.<Integer>newBuilder().retryIfRuntimeException()
        .withAttemptTimeLimiter(AttemptTimeLimiters.<Integer>fixedTimeLimit(1, TimeUnit.SECONDS, pool))
        .withStopStrategy(StopStrategies.stopAfterDelay(200, TimeUnit.MILLISECONDS)).build();
    try { busy.call(() -> invocations.incrementAndGet()); }
    catch (RetryException e) { System.out.println("shutdown executor + retryIfRuntimeException + noWait: RetryException attempts=" + e.getNumberOfFailedAttempts()
        + " in 200ms, callableInvocations=" + invocations + " lastCause=" + e.getCause()); }
    Retryer<Integer> narrow = RetryerBuilder.<Integer>newBuilder().retryIfExceptionOfType(IOException.class)
        .withAttemptTimeLimiter(AttemptTimeLimiters.<Integer>fixedTimeLimit(1, TimeUnit.SECONDS, pool))
        .withStopStrategy(StopStrategies.stopAfterAttempt(3)).build();
    try { narrow.call(() -> invocations.incrementAndGet()); }
    catch (ExecutionException e) { System.out.println("shutdown executor + retryIfExceptionOfType(IOException): ExecutionException cause=" + e.getCause() + " callableInvocations=" + invocations); }
  }

  static void noLimit(ExecutorService pool, String name, boolean occupyWorker) throws Exception {
    if (occupyWorker) pool.submit(() -> { try { Thread.sleep(5000); } catch (InterruptedException ignored) {} });
    Retryer<String> r = RetryerBuilder.<String>newBuilder().retryIfRuntimeException()
        .withAttemptTimeLimiter(AttemptTimeLimiters.<String>fixedTimeLimit(50, TimeUnit.MILLISECONDS, pool))
        .withStopStrategy(StopStrategies.stopAfterAttempt(3)).build();
    long t0 = System.nanoTime();
    String v = r.call(() -> { Thread.sleep(500); return "ran on " + Thread.currentThread().getName(); });
    System.out.println(name + ": 50ms limit, 500ms callable -> returned '" + v + "' after " + TimeUnit.NANOSECONDS.toMillis(System.nanoTime() - t0) + "ms (no timeout enforced)");
  }

  static void forkJoin() throws Exception {
    final AtomicBoolean interrupted = new AtomicBoolean(), completed = new AtomicBoolean();
    final AtomicLong completedAt = new AtomicLong();
    Retryer<String> r = RetryerBuilder.<String>newBuilder()
        .withAttemptTimeLimiter(AttemptTimeLimiters.<String>fixedTimeLimit(50, TimeUnit.MILLISECONDS, ForkJoinPool.commonPool()))
        .build();
    long t0 = System.nanoTime();
    try {
      r.call(() -> { try { Thread.sleep(500); } catch (InterruptedException e) { interrupted.set(true); throw e; }
                      completed.set(true); completedAt.set(System.nanoTime()); return "done"; });
    } catch (ExecutionException e) {
      System.out.println("ForkJoinPool.commonPool(): call() threw ExecutionException(" + e.getCause().getClass().getSimpleName() + ") after "
          + TimeUnit.NANOSECONDS.toMillis(System.nanoTime() - t0) + "ms");
    }
    Thread.sleep(700);
    System.out.println("  interruptible sleep(500) in the timed-out attempt: interrupted=" + interrupted + " completedNormally=" + completed
        + " at +" + TimeUnit.NANOSECONDS.toMillis(completedAt.get() - t0) + "ms (cancel(true) does not interrupt FJ tasks)");
  }
}
