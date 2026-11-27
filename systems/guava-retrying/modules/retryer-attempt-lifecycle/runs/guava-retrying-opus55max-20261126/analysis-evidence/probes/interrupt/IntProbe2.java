import com.github.rholder.retry.*;
import com.google.common.base.Predicates;
import java.io.IOException;
import java.util.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.*;

/** H2.2 (interrupt pending before an attempt), H2.4 (interrupt during listener/decision), H2.6 (negative sleep + interrupt). */
public class IntProbe2 {
  interface Body { String go() throws Exception; }

  /** Runs body on the current thread after optionally pre-interrupting; returns outcome + final flag. */
  static String outcome(Retryer<String> r, Callable<String> c, boolean pre) {
    if (pre) Thread.currentThread().interrupt();
    String o;
    try { o = "RETURNED " + r.call(c); }
    catch (RetryException e) { o = "RetryException attempts=" + e.getNumberOfFailedAttempts() + " cause=" + e.getCause(); }
    catch (ExecutionException e) { o = "ExecutionException cause=" + e.getCause(); }
    catch (Throwable e) { o = "OTHER " + e; }
    boolean flag = Thread.interrupted(); // read and clear for the next trial
    return o + " | flagAtExit=" + flag;
  }

  public static void main(String[] args) throws Exception {
    System.out.println("java.version=" + System.getProperty("java.version"));
    // Direct JDK check: Thread.sleep(0) with the flag set
    Thread.currentThread().interrupt();
    try { Thread.sleep(0); System.out.println("sleep(0) with flag set: returned normally, flag=" + Thread.interrupted()); }
    catch (InterruptedException e) { System.out.println("sleep(0) with flag set: threw InterruptedException, flag after=" + Thread.currentThread().isInterrupted()); }
    Thread.currentThread().interrupt();
    try { Thread.sleep(-1); } catch (IllegalArgumentException e) { System.out.println("sleep(-1) with flag set: IAE, flag after=" + Thread.interrupted()); }
    catch (InterruptedException e) { System.out.println("sleep(-1) with flag set: IE"); }

    ExecutorService pool = Executors.newCachedThreadPool(new ThreadFactory() {
      public Thread newThread(Runnable r) { Thread t = new Thread(r, "limiter-worker"); t.setDaemon(true); return t; }});
    AttemptTimeLimiter<String> fixed5s = AttemptTimeLimiters.<String>fixedTimeLimit(5, TimeUnit.SECONDS, pool);

    // ---- H2.2: caller already interrupted when call() starts; fast callable that ignores interrupts ----
    for (String pred : new String[]{"retryIfException", "retryIfRuntimeException"}) {
      Map<String, Integer> hist = new TreeMap<String, Integer>();
      for (int trial = 0; trial < 300; trial++) {
        final AtomicInteger calls = new AtomicInteger();
        Callable<String> fast = new Callable<String>() { public String call() { calls.incrementAndGet(); return "ok"; }};
        RetryerBuilder<String> b = RetryerBuilder.<String>newBuilder().withAttemptTimeLimiter(fixed5s);
        b = pred.equals("retryIfException") ? b.retryIfException() : b.retryIfRuntimeException();
        String o = outcome(b.build(), fast, true);
        Thread.sleep(1); // let the worker settle
        String key = o.replaceAll("attempts=\\d+", "attempts=N") + " | invocations=" + calls.get();
        Integer v = hist.get(key); hist.put(key, v == null ? 1 : v + 1);
      }
      System.out.println("H2.2 fixed5s " + pred + " pre-interrupted, fast callable, 300 trials:");
      for (Map.Entry<String, Integer> e : hist.entrySet()) System.out.println("   " + e.getValue() + " x  " + e.getKey());
    }
    // H2.2 noTimeLimit: callable ignores interrupts -> returns with flag set (expected-correct)
    {
      final AtomicInteger calls = new AtomicInteger();
      System.out.println("H2.2n noLimit retryIfException pre-interrupted, callable ignores interrupt: " +
        outcome(RetryerBuilder.<String>newBuilder().retryIfException().build(),
          new Callable<String>() { public String call() { calls.incrementAndGet(); return "ok"; }}, true) + " | invocations=" + calls.get());
    }
    // H2.2n2 noTimeLimit: callable does an interruptible wait on attempt 1 -> IE -> retried
    {
      final AtomicInteger calls = new AtomicInteger();
      System.out.println("H2.2n2 noLimit retryIfException pre-interrupted, callable sleeps(10) on attempt 1: " +
        outcome(RetryerBuilder.<String>newBuilder().retryIfException().build(),
          new Callable<String>() { public String call() throws Exception { if (calls.incrementAndGet() == 1) Thread.sleep(10); return "ok"; }}, true) + " | invocations=" + calls.get());
    }

    // ---- H2.4: interrupt arrives during listener notification (simulated by the listener interrupting its own thread) ----
    final RetryListener interruptOnFirst = new RetryListener() {
      public <V> void onRetry(Attempt<V> a) { if (a.getAttemptNumber() == 1) Thread.currentThread().interrupt(); }};
    {
      final AtomicInteger calls = new AtomicInteger();
      Callable<String> bad = new Callable<String>() { public String call() { calls.incrementAndGet(); return "bad"; }};
      System.out.println("H2.4a listener-interrupt, rejected(result), neverStop, noWait (sleep(0)): " +
        outcome(RetryerBuilder.<String>newBuilder().retryIfResult(Predicates.equalTo("bad")).withRetryListener(interruptOnFirst).build(), bad, false)
        + " | invocations=" + calls.get());
    }
    {
      final AtomicInteger calls = new AtomicInteger();
      Callable<String> bad = new Callable<String>() { public String call() { calls.incrementAndGet(); return "bad"; }};
      System.out.println("H2.4b listener-interrupt, rejected(result), stopAfterAttempt(1): " +
        outcome(RetryerBuilder.<String>newBuilder().retryIfResult(Predicates.equalTo("bad")).withStopStrategy(StopStrategies.stopAfterAttempt(1))
          .withRetryListener(interruptOnFirst).build(), bad, false) + " | invocations=" + calls.get());
    }
    {
      final AtomicInteger calls = new AtomicInteger();
      Callable<String> good = new Callable<String>() { public String call() { calls.incrementAndGet(); return "ok"; }};
      System.out.println("H2.4c listener-interrupt, accepted: " +
        outcome(RetryerBuilder.<String>newBuilder().retryIfResult(Predicates.equalTo("bad")).withRetryListener(interruptOnFirst).build(), good, false)
        + " | invocations=" + calls.get());
    }
    {
      final AtomicInteger calls = new AtomicInteger();
      Callable<String> bad = new Callable<String>() { public String call() throws Exception { calls.incrementAndGet(); throw new IOException("x"); }};
      System.out.println("H2.4d listener-interrupt, fixed5s, rejected(exception), neverStop, noWait: " +
        outcome(RetryerBuilder.<String>newBuilder().retryIfException().withAttemptTimeLimiter(fixed5s).withRetryListener(interruptOnFirst).build(), bad, false)
        + " | invocations=" + calls.get());
    }

    // ---- H2.6: negative sleep from a built-in composite wait, with and without interrupt pending ----
    WaitStrategy overflow = WaitStrategies.join(WaitStrategies.fixedWait(Long.MAX_VALUE, TimeUnit.MILLISECONDS), WaitStrategies.fixedWait(1, TimeUnit.MILLISECONDS));
    {
      final AtomicInteger calls = new AtomicInteger();
      Callable<String> bad = new Callable<String>() { public String call() { calls.incrementAndGet(); return "bad"; }};
      System.out.println("H2.6a join overflow, no interrupt: " +
        outcome(RetryerBuilder.<String>newBuilder().retryIfResult(Predicates.equalTo("bad")).withWaitStrategy(overflow).build(), bad, false)
        + " | invocations=" + calls.get());
    }
    {
      final AtomicInteger calls = new AtomicInteger();
      Callable<String> bad = new Callable<String>() { public String call() { calls.incrementAndGet(); return "bad"; }};
      System.out.println("H2.6b join overflow, interrupt arrives in listener: " +
        outcome(RetryerBuilder.<String>newBuilder().retryIfResult(Predicates.equalTo("bad")).withWaitStrategy(overflow)
          .withRetryListener(interruptOnFirst).build(), bad, false) + " | invocations=" + calls.get());
    }
    pool.shutdownNow();
  }
}
