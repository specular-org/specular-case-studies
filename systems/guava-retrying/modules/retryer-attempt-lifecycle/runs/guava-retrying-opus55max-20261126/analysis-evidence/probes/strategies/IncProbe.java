import com.github.rholder.retry.*;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.Callable;
import static java.util.concurrent.TimeUnit.*;

/** incrementingWait with a saturated ("practically infinite") increment: sleeps the Retryer actually requests. */
public class IncProbe {
  public static void main(String[] args) throws Exception {
    for (long[] cfg : new long[][]{{1000, Long.MAX_VALUE}, {0, Long.MAX_VALUE}}) {
      final List<Long> sleeps = new ArrayList<Long>();
      WaitStrategy w = WaitStrategies.incrementingWait(cfg[0], MILLISECONDS, cfg[1], MILLISECONDS);
      Retryer<String> r = RetryerBuilder.<String>newBuilder().retryIfException().withWaitStrategy(w)
          .withStopStrategy(StopStrategies.stopAfterAttempt(7))
          .withBlockStrategy(new BlockStrategy() { public void block(long t) { sleeps.add(t); } }) // records the requested sleep instead of sleeping
          .build();
      try { r.call(new Callable<String>() { public String call() { throw new IllegalStateException("fail"); } }); }
      catch (RetryException e) { System.out.println("incrementingWait(" + cfg[0] + " ms, " + cfg[1] + " ms): requested sleeps after attempts 1..6 = " + sleeps); }
    }
    System.out.println("incrementingWait(1, SECONDS, Long.MAX_VALUE, DAYS) increment toMillis = " + DAYS.toMillis(Long.MAX_VALUE));
  }
}
