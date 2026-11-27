import com.github.rholder.retry.*;
import java.io.InputStream;
import java.net.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.*;

/** H1.3: attempts blocked in a non-interruptible socket read leak one non-daemon pool thread each, forever. */
public class P3ThreadGrowth {
  public static void main(String[] a) throws Exception {
    final boolean exitExplicitly = a.length > 0 && a[0].equals("exit");
    final ServerSocket server = new ServerSocket(0);           // accepts, never writes
    Thread acceptor = new Thread(() -> { try { while (true) server.accept(); } catch (Exception ignored) {} });
    acceptor.setDaemon(true); acceptor.start();
    final AtomicInteger invocations = new AtomicInteger();
    Retryer<Integer> r = RetryerBuilder.<Integer>newBuilder()
        .retryIfRuntimeException()
        .withAttemptTimeLimiter(AttemptTimeLimiters.<Integer>fixedTimeLimit(100, TimeUnit.MILLISECONDS))
        .withStopStrategy(StopStrategies.stopAfterDelay(2, TimeUnit.SECONDS))
        .build();
    Callable<Integer> c = () -> {
      invocations.incrementAndGet();
      Socket s = new Socket("127.0.0.1", server.getLocalPort());  // no SO_TIMEOUT: read() blocks; interrupt does not unblock it
      InputStream in = s.getInputStream();
      return in.read();
    };
    try { r.call(c); } catch (RetryException e) {
      System.out.println("RetryException after attempts=" + e.getNumberOfFailedAttempts() + " cause=" + e.getCause());
    }
    for (int i = 0; i < 3; i++) {
      System.out.println("t+" + i * 2 + "s after call(): invocations=" + invocations + " live pool threads=" + poolThreads()
          + " (blocked in read: " + blockedInRead() + ")");
      Thread.sleep(2000);
    }
    if (exitExplicitly) System.exit(0);
    System.out.println("main() returning without System.exit");
  }
  static long poolThreads() { long n = 0; for (Thread t : Thread.getAllStackTraces().keySet()) if (t.getName().startsWith("pool-") && t.isAlive()) n++; return n; }
  static long blockedInRead() {
    long n = 0;
    for (java.util.Map.Entry<Thread, StackTraceElement[]> e : Thread.getAllStackTraces().entrySet())
      if (e.getKey().getName().startsWith("pool-")) for (StackTraceElement f : e.getValue()) if (f.getMethodName().contains("read")) { n++; break; }
    return n;
  }
}
