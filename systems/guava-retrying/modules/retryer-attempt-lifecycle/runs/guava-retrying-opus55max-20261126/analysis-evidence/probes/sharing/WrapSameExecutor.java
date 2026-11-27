import com.github.rholder.retry.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.*;

/**
 * H3.5: Retryer.wrap() tasks submitted to the same bounded executor that the fixedTimeLimit uses.
 * The outer RetryerCallables occupy every worker, so every attempt waits in the queue and times out
 * before it starts. With neverStop this is a livelock: attempts keep "failing" and the callable never runs.
 */
public class WrapSameExecutor {
  public static void main(String[] args) throws Exception {
    final ExecutorService pool = Executors.newFixedThreadPool(2);
    final AtomicInteger attempts = new AtomicInteger(), runs = new AtomicInteger();
    final Retryer<String> r = RetryerBuilder.<String>newBuilder()
        .retryIfRuntimeException()
        .withAttemptTimeLimiter(AttemptTimeLimiters.<String>fixedTimeLimit(100, TimeUnit.MILLISECONDS, pool))
        .withRetryListener(new RetryListener() { public <V> void onRetry(Attempt<V> a) { attempts.incrementAndGet(); } })
        .build();                                                     // default stop = neverStop
    Callable<String> work = new Callable<String>() { public String call() { runs.incrementAndGet(); return "done"; } };
    Future<String> f1 = pool.submit(r.wrap(work));
    Future<String> f2 = pool.submit(r.wrap(work));
    Thread.sleep(3000);
    System.out.println("after 3s: attempts made=" + attempts.get() + ", callable executions=" + runs.get()
        + ", f1.done=" + f1.isDone() + ", f2.done=" + f2.isDone());
    pool.shutdownNow();                                               // interrupts the outer tasks
    Thread.sleep(1000);
    System.out.println("1s after shutdownNow: attempts made=" + attempts.get() + ", pool terminated=" + pool.isTerminated()
        + ", f1.done=" + f1.isDone() + ", f2.done=" + f2.isDone());
    try { f1.get(1, TimeUnit.SECONDS); } catch (Exception e) { System.out.println("f1.get -> " + e); }
    System.exit(0);
  }
}
