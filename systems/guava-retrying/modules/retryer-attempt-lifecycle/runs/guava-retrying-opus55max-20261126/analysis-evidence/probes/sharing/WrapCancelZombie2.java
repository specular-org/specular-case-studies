import com.github.rholder.retry.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.*;

/** Separate the two stop signals: (a) Future.cancel(true) only, (b) ExecutorService.shutdownNow() only. */
public class WrapCancelZombie2 {
  public static void main(String[] args) throws Exception {
    final boolean limiter = args[0].equals("limiter");
    final boolean useCancel = args[1].equals("cancel");
    final AtomicInteger attempts = new AtomicInteger();
    RetryerBuilder<String> b = RetryerBuilder.<String>newBuilder()
        .retryIfException()
        .withWaitStrategy(WaitStrategies.fixedWait(10, TimeUnit.MILLISECONDS))
        .withRetryListener(new RetryListener() { public <V> void onRetry(Attempt<V> a) { attempts.incrementAndGet(); } });
    if (limiter) b.withAttemptTimeLimiter(AttemptTimeLimiters.<String>fixedTimeLimit(1, TimeUnit.SECONDS));
    final Retryer<String> r = b.build();
    Callable<String> work = new Callable<String>() { public String call() throws Exception {
      Thread.sleep(200); throw new java.io.IOException("backend down"); } };
    ExecutorService outer = Executors.newSingleThreadExecutor();
    Future<String> f = outer.submit(r.wrap(work));
    Thread.sleep(500);
    int before = attempts.get();
    String act;
    if (useCancel) { act = "cancel(true)=" + f.cancel(true); outer.shutdown(); }
    else { act = "shutdownNow() pending=" + outer.shutdownNow().size(); }
    boolean term = outer.awaitTermination(2, TimeUnit.SECONDS);
    System.out.println("mode=" + (limiter ? "fixedTimeLimit" : "noTimeLimit") + " " + act + " attempts before=" + before
        + " attempts 2s later=" + attempts.get() + " executor terminated=" + term);
    System.exit(0);
  }
}
