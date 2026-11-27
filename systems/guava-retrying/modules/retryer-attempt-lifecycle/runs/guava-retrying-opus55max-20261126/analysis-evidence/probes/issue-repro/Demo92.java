import com.github.rholder.retry.*;
import com.google.common.base.Predicate;

import java.util.Objects;
import java.util.concurrent.Callable;
import java.util.concurrent.TimeUnit;

/** Issue #92 demo, adapted from the issue body (logging replaced by System.out; RetryLogListener dropped). */
public class Demo92 {
    public static void main(String[] args) throws Exception {
        Retryer<Boolean> retryer = RetryerBuilder.<Boolean>newBuilder()
                .retryIfException()
                .retryIfResult(new Predicate<Boolean>() { public boolean apply(Boolean b) { return Objects.equals(b, false); } })
                .withWaitStrategy(WaitStrategies.fixedWait(1, TimeUnit.SECONDS))
                .withStopStrategy(StopStrategies.stopAfterAttempt(20))
                .withAttemptTimeLimiter(AttemptTimeLimiters.<Boolean>fixedTimeLimit(5, TimeUnit.SECONDS))
                .build();
        final int successNum = 3, maxCount = 10;
        Callable<Boolean> callable = new Callable<Boolean>() {
            int times = 0;
            public Boolean call() throws Exception {
                times++;
                System.out.println("call times=" + times + " on " + Thread.currentThread().getName());
                if (successNum == times || times == maxCount) return true;
                if (times == 1) throw new NullPointerException();
                else if (times == 2) throw new Exception();
                else if (times == 3) throw new RuntimeException();
                return false;
            }
        };
        Boolean result = retryer.call(callable);
        System.out.println("result = " + result + " ; main() returns at epoch ms " + System.currentTimeMillis());
    }
}
