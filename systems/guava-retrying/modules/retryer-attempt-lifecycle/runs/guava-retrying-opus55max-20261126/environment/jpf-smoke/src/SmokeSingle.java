import com.github.rholder.retry.*;
import java.util.concurrent.*;

/** Single-threaded retry: fails twice, then succeeds. */
public class SmokeSingle {
  public static void main(String[] args) throws Exception {
    final int[] calls = {0};
    Retryer<Integer> r = RetryerBuilder.<Integer>newBuilder()
        .retryIfException()
        .withWaitStrategy(WaitStrategies.fixedWait(10, TimeUnit.MILLISECONDS))
        .withStopStrategy(StopStrategies.stopAfterAttempt(5))
        .build();
    int v = r.call(() -> { if (++calls[0] < 3) throw new IllegalStateException("fail " + calls[0]); return calls[0]; });
    assert v == 3 : "unexpected result " + v;
    System.out.println("result=" + v);
  }
}
