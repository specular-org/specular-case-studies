import com.github.rholder.retry.*;
import static java.util.concurrent.TimeUnit.*;

/** Replicates FibonacciWaitStrategy.computeSleepTime incrementally (same wrapping long arithmetic), scans n=1..N for
 *  sleeps that decrease, and cross-checks sampled values against the real strategy. */
public class FibScan {
  public static void main(String[] args) {
    long N = Long.parseLong(args[0]);
    long[][] settings = { {1, Long.MAX_VALUE}, {1, 60000}, {100, 120000}, {1000, 3600000}, {500, 10000}, {1024, 60000}, {4096, 600000}, {1L << 20, 3600000}, {65536, 3600000}, {3, 180000} };
    for (long[] s : settings) {
      long mult = s[0], max = s[1];
      WaitStrategy real = mult == 1 && max == Long.MAX_VALUE ? WaitStrategies.fibonacciWait() : WaitStrategies.fibonacciWait(mult, max, MILLISECONDS);
      long pp = 0, p = 1; // fib(n-2), fib(n-1) for n>=2 ; we track fib(n)
      long prevSleep = -1, capAt = -1, firstDecrease = -1, firstBelowCapAfterCap = -1, decreases = 0;
      for (long n = 1; n <= N; n++) {
        long fib;
        if (n == 1) fib = 1; else { fib = p + pp; pp = p; p = fib; }
        // n==1: fib=1 and state stays pp=0,p=1 -> for n=2: fib=1 (p+pp=1), pp=1, p=1 -> n=3: 2 ... matches strategy loop
        long result = mult * fib;
        if (result > max || result < 0L) result = max;
        long v = result >= 0L ? result : 0L;
        if (n <= 3000 || n % 9999991 == 0) {
          long rv = real.computeSleepTime(A.fail(n));
          if (rv != v) { System.out.println("MISMATCH n=" + n + " mine=" + v + " real=" + rv); return; }
        }
        if (capAt < 0 && v == max) capAt = n;
        if (prevSleep >= 0 && v < prevSleep) { decreases++; if (firstDecrease < 0) firstDecrease = n; }
        if (capAt > 0 && n > capAt && v < max && firstBelowCapAfterCap < 0) firstBelowCapAfterCap = n;
        prevSleep = v;
      }
      System.out.println("fibonacci(mult=" + mult + ", max=" + max + "ms): cap reached n=" + capAt + " ; first decrease n=" + firstDecrease
          + " (count " + decreases + ") ; first below-cap after cap n=" + firstBelowCapAfterCap + "  [scanned n<=" + N + "]");
      if (firstDecrease > 0 && firstDecrease <= 3000) System.out.println("   real strategy: n=" + (firstDecrease - 1) + " -> " + real.computeSleepTime(A.fail(firstDecrease - 1)) + " ; n=" + firstDecrease + " -> " + real.computeSleepTime(A.fail(firstDecrease)));
    }
  }
}
