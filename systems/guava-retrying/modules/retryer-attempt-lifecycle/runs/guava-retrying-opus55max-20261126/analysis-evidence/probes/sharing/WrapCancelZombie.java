import com.github.rholder.retry.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.*;

/**
 * wrap() on an executor: cancel(true) / shutdownNow() interrupt the thread running Retryer.call.
 * mode=limiter: attempts use fixedTimeLimit on a separate cached pool; mode=nolimit: plain attempts that sleep.
 * With retryIfException() the interrupt is consumed as an ordinary attempt failure and the loop keeps going.
 */
public class WrapCancelZombie {
  public static void main(String[] args) throws Exception {
    final boolean limiter = args.length > 0 && args[0].equals("limiter");
    final AtomicInteger attempts = new AtomicInteger();
    RetryerBuilder<String> b = RetryerBuilder.<String>newBuilder()
        .retryIfException()                                            // common "retry on any exception"
        .withWaitStrategy(WaitStrategies.fixedWait(10, TimeUnit.MILLISECONDS))
        .withRetryListener(new RetryListener() { public <V> void onRetry(Attempt<V> a) { attempts.incrementAndGet(); } });
    if (limiter) b.withAttemptTimeLimiter(AttemptTimeLimiters.<String>fixedTimeLimit(1, TimeUnit.SECONDS));
    final Retryer<String> r = b.build();                                // neverStop
    Callable<String> work = new Callable<String>() { public String call() throws Exception {
      Thread.sleep(200); throw new java.io.IOException("backend down"); } };
    ExecutorService outer = Executors.newSingleThreadExecutor();
    Future<String> f = outer.submit(r.wrap(work));
    Thread.sleep(500);
    boolean c = f.cancel(true);
    int atCancel = attempts.get();
    outer.shutdownNow();
    boolean term = outer.awaitTermination(2, TimeUnit.SECONDS);
    System.out.println("mode=" + (limiter ? "fixedTimeLimit" : "noTimeLimit") + " cancel()=" + c + " isCancelled=" + f.isCancelled()
        + " attempts at cancel=" + atCancel + " attempts 2s after cancel+shutdownNow=" + attempts.get()
        + " outer pool terminated=" + term);
    System.exit(0);
  }
}
