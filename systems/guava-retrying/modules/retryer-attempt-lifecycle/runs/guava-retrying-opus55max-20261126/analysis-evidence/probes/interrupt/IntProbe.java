import com.github.rholder.retry.*;
import com.google.common.base.Predicate;
import com.google.common.base.Predicates;
import java.io.IOException;
import java.util.concurrent.*;
import java.util.concurrent.atomic.*;

/** Interrupt-handling probes for guava-retrying 2.0.0 Retryer.call. Each scenario runs call() on a fresh thread. */
public class IntProbe {
  static final long T0 = System.nanoTime();
  static long now() { return (System.nanoTime() - T0) / 1_000_000; }

  static String run(String name, final Retryer<String> retryer, final Callable<String> callable,
                    long interruptAfterMs, final boolean preInterrupt, AtomicInteger calls) throws Exception {
    final AtomicReference<String> outcome = new AtomicReference<String>();
    final AtomicBoolean flagAtExit = new AtomicBoolean();
    Thread t = new Thread(new Runnable() { public void run() {
      if (preInterrupt) Thread.currentThread().interrupt();
      String o;
      try {
        o = "RETURNED " + retryer.call(callable);
      } catch (RetryException e) {
        o = "RetryException attempts=" + e.getNumberOfFailedAttempts() + " cause=" + e.getCause();
      } catch (ExecutionException e) {
        o = "ExecutionException cause=" + e.getCause();
      } catch (Throwable e) {
        o = "OTHER " + e;
      }
      flagAtExit.set(Thread.currentThread().isInterrupted());
      outcome.set(o);
    }}, "caller-" + name);
    t.start();
    if (interruptAfterMs >= 0) { Thread.sleep(interruptAfterMs); t.interrupt(); }
    t.join(15000);
    String line = name + " -> " + outcome.get() + " | interruptFlagAtExit=" + flagAtExit.get()
        + " | callableInvocations=" + calls.get() + (t.isAlive() ? " | CALLER STILL RUNNING" : "");
    System.out.println(line);
    return line;
  }

  /** attempt 1 sleeps 1000 ms (interruptibly); later attempts return "ok". */
  static Callable<String> slowFirst(final AtomicInteger calls) {
    return new Callable<String>() { public String call() throws Exception {
      int n = calls.incrementAndGet();
      if (n == 1) { Thread.sleep(1000); return "slow-first"; }
      return "ok";
    }};
  }

  public static void main(String[] args) throws Exception {
    System.out.println("java.version=" + System.getProperty("java.version"));
    ExecutorService pool = Executors.newCachedThreadPool(new ThreadFactory() {
      public Thread newThread(Runnable r) { Thread t = new Thread(r, "limiter-worker"); t.setDaemon(true); return t; }});
    AttemptTimeLimiter<String> fixed5s = AttemptTimeLimiters.<String>fixedTimeLimit(5, TimeUnit.SECONDS, pool);

    // ---- H2.1: caller interrupted while blocked in SimpleTimeLimiter future.get ----
    AtomicInteger c;
    c = new AtomicInteger();
    run("H2.1a fixed5s retryIfException neverStop", RetryerBuilder.<String>newBuilder().retryIfException()
        .withAttemptTimeLimiter(fixed5s).build(), slowFirst(c), 300, false, c);
    c = new AtomicInteger();
    run("H2.1b fixed5s retryIfException stopAfterAttempt(1)", RetryerBuilder.<String>newBuilder().retryIfException()
        .withAttemptTimeLimiter(fixed5s).withStopStrategy(StopStrategies.stopAfterAttempt(1)).build(), slowFirst(c), 300, false, c);
    c = new AtomicInteger();
    run("H2.1c fixed5s retryIfRuntimeException", RetryerBuilder.<String>newBuilder().retryIfRuntimeException()
        .withAttemptTimeLimiter(fixed5s).build(), slowFirst(c), 300, false, c);
    c = new AtomicInteger();
    run("H2.1d fixed5s retryIfExceptionOfType(IOException)", RetryerBuilder.<String>newBuilder().retryIfExceptionOfType(IOException.class)
        .withAttemptTimeLimiter(fixed5s).build(), slowFirst(c), 300, false, c);
    c = new AtomicInteger();
    run("H2.1e fixed5s retryIfResult(isNull)", RetryerBuilder.<String>newBuilder().retryIfResult(Predicates.<String>isNull())
        .withAttemptTimeLimiter(fixed5s).build(), slowFirst(c), 300, false, c);
    c = new AtomicInteger();
    run("H2.1f fixed5s retryIfException fixedWait(50ms) neverStop", RetryerBuilder.<String>newBuilder().retryIfException()
        .withAttemptTimeLimiter(fixed5s).withWaitStrategy(WaitStrategies.fixedWait(50, TimeUnit.MILLISECONDS)).build(), slowFirst(c), 300, false, c);

    // ---- H2.3: noTimeLimit, callable consumes the interrupt and throws InterruptedException ----
    c = new AtomicInteger();
    run("H2.3a noLimit retryIfException neverStop", RetryerBuilder.<String>newBuilder().retryIfException().build(), slowFirst(c), 300, false, c);
    c = new AtomicInteger();
    run("H2.3b noLimit retryIfException stopAfterAttempt(1)", RetryerBuilder.<String>newBuilder().retryIfException()
        .withStopStrategy(StopStrategies.stopAfterAttempt(1)).build(), slowFirst(c), 300, false, c);
    c = new AtomicInteger();
    run("H2.3c noLimit retryIfRuntimeException", RetryerBuilder.<String>newBuilder().retryIfRuntimeException().build(), slowFirst(c), 300, false, c);
    c = new AtomicInteger();
    run("H2.3d noLimit retryIfResult(isNull)", RetryerBuilder.<String>newBuilder().retryIfResult(Predicates.<String>isNull()).build(), slowFirst(c), 300, false, c);

    // ---- H2.5 control: interrupt during the inter-attempt sleep ----
    c = new AtomicInteger();
    final AtomicInteger c5 = c;
    run("H2.5 noLimit retryIfResult(isNull) fixedWait(5s), interrupt in sleep", RetryerBuilder.<String>newBuilder()
        .retryIfResult(Predicates.<String>isNull()).withWaitStrategy(WaitStrategies.fixedWait(5, TimeUnit.SECONDS)).build(),
        new Callable<String>() { public String call() { c5.incrementAndGet(); return null; }}, 300, false, c);
    c = new AtomicInteger();
    final AtomicInteger c5b = c;
    run("H2.5b fixed5s retryIfException fixedWait(5s), interrupt in sleep", RetryerBuilder.<String>newBuilder()
        .retryIfException().withAttemptTimeLimiter(fixed5s).withWaitStrategy(WaitStrategies.fixedWait(5, TimeUnit.SECONDS)).build(),
        new Callable<String>() { public String call() throws Exception { c5b.incrementAndGet(); throw new IOException("fail"); }}, 300, false, c);
    pool.shutdownNow();
  }
}
