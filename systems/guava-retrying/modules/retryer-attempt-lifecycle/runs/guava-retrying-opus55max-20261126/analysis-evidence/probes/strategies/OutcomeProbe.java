import com.github.rholder.retry.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicInteger;
import static java.util.concurrent.TimeUnit.*;

/** Enumerates how Retryer.call ends for non-callable failure sources and for Errors / odd Throwables. */
public class OutcomeProbe {
  static class Weird extends Throwable { Weird() { super("weird"); } }
  @SuppressWarnings("unchecked") static <T extends Throwable> void sneaky(Throwable t) throws T { throw (T) t; }
  static final AtomicInteger calls = new AtomicInteger();
  static String outcome(Retryer<String> r, Callable<String> c) {
    calls.set(0);
    try { return "returned " + r.call(c) + " ; callable ran " + calls.get(); }
    catch (RetryException e) { return "RetryException(n=" + e.getNumberOfFailedAttempts() + ", cause=" + e.getCause() + ") ; callable ran " + calls.get(); }
    catch (ExecutionException e) { return "ExecutionException(cause=" + e.getCause() + (e.getCause() != null && e.getCause().getCause() != null ? " <- " + e.getCause().getCause() : "") + ") ; callable ran " + calls.get(); }
    catch (Throwable t) { return "ESCAPED " + t + " ; callable ran " + calls.get(); }
  }
  public static void main(String[] args) throws Exception {
    Callable<String> err = new Callable<String>() { public String call() { calls.incrementAndGet(); throw new AssertionError("boom"); } };
    Callable<String> weird = new Callable<String>() { public String call() { calls.incrementAndGet(); OutcomeProbe.<RuntimeException>sneaky(new Weird()); return "x"; } };
    Callable<String> slow = new Callable<String>() { public String call() throws Exception { calls.incrementAndGet(); Thread.sleep(500); return "late"; } };
    Callable<String> ok = new Callable<String>() { public String call() { calls.incrementAndGet(); return "ok"; } };
    System.out.println("1 Error + retryIfException (noTimeLimit):            " + outcome(RetryerBuilder.<String>newBuilder().retryIfException().withStopStrategy(StopStrategies.stopAfterAttempt(3)).build(), err));
    System.out.println("2 Error + retryIfExceptionOfType(Throwable):          " + outcome(RetryerBuilder.<String>newBuilder().retryIfExceptionOfType(Throwable.class).withStopStrategy(StopStrategies.stopAfterAttempt(3)).build(), err));
    System.out.println("3 Weird Throwable + retryIfExceptionOfType(Weird) noTimeLimit:  " + outcome(RetryerBuilder.<String>newBuilder().retryIfExceptionOfType(Weird.class).withStopStrategy(StopStrategies.stopAfterAttempt(3)).build(), weird));
    ExecutorService pool = Executors.newCachedThreadPool();
    System.out.println("4 Weird Throwable + retryIfExceptionOfType(Weird) fixedTimeLimit: " + outcome(RetryerBuilder.<String>newBuilder().retryIfExceptionOfType(Weird.class).withStopStrategy(StopStrategies.stopAfterAttempt(3)).withAttemptTimeLimiter(AttemptTimeLimiters.<String>fixedTimeLimit(1, SECONDS, pool)).build(), weird));
    System.out.println("5 fixedTimeLimit(0s) + retryIfRuntimeException:       " + outcome(RetryerBuilder.<String>newBuilder().retryIfRuntimeException().withStopStrategy(StopStrategies.stopAfterAttempt(3)).withAttemptTimeLimiter(AttemptTimeLimiters.<String>fixedTimeLimit(0, SECONDS, pool)).build(), ok));
    System.out.println("6 fixedTimeLimit(0s), no retry predicate:              " + outcome(RetryerBuilder.<String>newBuilder().withAttemptTimeLimiter(AttemptTimeLimiters.<String>fixedTimeLimit(0, SECONDS, pool)).build(), ok));
    ExecutorService dead = Executors.newSingleThreadExecutor(); dead.shutdown();
    System.out.println("7 shut-down executor + retryIfException:               " + outcome(RetryerBuilder.<String>newBuilder().retryIfException().withStopStrategy(StopStrategies.stopAfterAttempt(3)).withAttemptTimeLimiter(AttemptTimeLimiters.<String>fixedTimeLimit(1, SECONDS, dead)).build(), ok));
    System.out.println("8 timeout + retryIfExceptionOfType(TimeoutException):  " + outcome(RetryerBuilder.<String>newBuilder().retryIfExceptionOfType(TimeoutException.class).withStopStrategy(StopStrategies.stopAfterAttempt(3)).withAttemptTimeLimiter(AttemptTimeLimiters.<String>fixedTimeLimit(50, MILLISECONDS, pool)).build(), slow));
    System.out.println("9 null callable + retryIfRuntimeException:             " + outcome(RetryerBuilder.<String>newBuilder().retryIfRuntimeException().withStopStrategy(StopStrategies.stopAfterAttempt(2)).build(), null));
    pool.shutdownNow();
  }
}
