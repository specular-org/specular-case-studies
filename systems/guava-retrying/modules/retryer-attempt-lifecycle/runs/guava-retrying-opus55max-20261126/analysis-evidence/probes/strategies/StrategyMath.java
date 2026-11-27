import com.github.rholder.retry.*;
import com.google.common.base.Function;
import java.util.concurrent.TimeUnit;
import static java.util.concurrent.TimeUnit.*;

public class StrategyMath {
  static void p(String s) { System.out.println(s); }
  static String t(WaitStrategy w, long n) { try { return String.valueOf(w.computeSleepTime(A.fail(n))); } catch (Throwable e) { return "THROWS " + e; } }
  public static void main(String[] args) throws Exception {
    p("== H4.1 CompositeWaitStrategy (join) overflow / negative");
    p("fixedWait(Long.MAX_VALUE, DAYS) toMillis = " + t(WaitStrategies.fixedWait(Long.MAX_VALUE, DAYS), 1));
    p("join(fixedWait(Long.MAX_VALUE, ms), fixedWait(1, ms)) n=1 -> " + t(WaitStrategies.join(WaitStrategies.fixedWait(Long.MAX_VALUE, MILLISECONDS), WaitStrategies.fixedWait(1, MILLISECONDS)), 1));
    p("join(fixedWait(106751991167301L, DAYS)=sat, randomWait(1s)) n=1 -> " + t(WaitStrategies.join(WaitStrategies.fixedWait(106751991167301L, DAYS), WaitStrategies.randomWait(1, SECONDS)), 1));
    WaitStrategy je = WaitStrategies.join(WaitStrategies.exponentialWait(), WaitStrategies.fixedWait(1, MILLISECONDS));
    for (long n : new long[]{61, 62, 63, 64}) p("join(exponentialWait(), fixedWait(1ms)) n=" + n + " -> " + t(je, n) + "   (exponentialWait() alone = " + t(WaitStrategies.exponentialWait(), n) + ")");
    WaitStrategy jf = WaitStrategies.join(WaitStrategies.fibonacciWait(), WaitStrategies.fibonacciWait());
    for (long n : new long[]{90, 91, 92, 93}) p("join(fibonacciWait(), fibonacciWait()) n=" + n + " -> " + t(jf, n) + "   (fibonacciWait() alone = " + t(WaitStrategies.fibonacciWait(), n) + ")");
    WaitStrategy jx = WaitStrategies.join(WaitStrategies.exceptionWait(RuntimeException.class, new Function<RuntimeException, Long>() { public Long apply(RuntimeException e) { return Long.MAX_VALUE; } }), WaitStrategies.fixedWait(500, MILLISECONDS));
    p("join(exceptionWait(->Long.MAX_VALUE), fixedWait(500ms)) n=1 -> " + t(jx, 1));
    p("== H4.2 ExceptionWaitStrategy pass-through");
    WaitStrategy neg = WaitStrategies.exceptionWait(RuntimeException.class, new Function<RuntimeException, Long>() { public Long apply(RuntimeException e) { return -250L; } });
    p("exceptionWait(-> -250) -> " + t(neg, 1));
    WaitStrategy nul = WaitStrategies.exceptionWait(RuntimeException.class, new Function<RuntimeException, Long>() { public Long apply(RuntimeException e) { return null; } });
    p("exceptionWait(-> null) -> " + t(nul, 1));
    p("join(exceptionWait(-> -250), fixedWait(100ms)) -> " + t(WaitStrategies.join(neg, WaitStrategies.fixedWait(100, MILLISECONDS)), 1));
    p("== H4.4 IncrementingWaitStrategy");
    WaitStrategy inc = WaitStrategies.incrementingWait(0, MILLISECONDS, Long.MAX_VALUE, MILLISECONDS);
    for (long n = 1; n <= 6; n++) p("incrementingWait(0, MAX) n=" + n + " -> " + t(inc, n));
    long thr = (Long.MAX_VALUE - 0) / (Integer.MAX_VALUE - 1L) + 1;
    p("smallest increment (initial=0) overflowing before int wrap (n=2^31-1): " + thr + " ms = " + (thr / 86400000.0) + " days");
    WaitStrategy inc50 = WaitStrategies.incrementingWait(0, MILLISECONDS, 50, DAYS);
    long nOv = Long.MAX_VALUE / DAYS.toMillis(50) + 2; p("incrementingWait(0, 50 DAYS): first overflowing n = " + nOv + " -> " + t(inc50, nOv) + " (n-1 -> " + t(inc50, nOv - 1) + ")");
    WaitStrategy incNeg = WaitStrategies.incrementingWait(1000, MILLISECONDS, -300, MILLISECONDS);
    p("incrementingWait(1000, -300) n=1..5 -> " + t(incNeg, 1) + "," + t(incNeg, 2) + "," + t(incNeg, 3) + "," + t(incNeg, 4) + "," + t(incNeg, 5) + "  (negative increment accepted, clamped)");
    p("== H4.6 ExponentialWaitStrategy");
    WaitStrategy ex = WaitStrategies.exponentialWait();
    long prev = -1; boolean mono = true, nonneg = true;
    for (long n = 1; n <= 5000; n++) { long v = ex.computeSleepTime(A.fail(n)); if (v < prev) mono = false; if (v < 0) nonneg = false; prev = v; }
    p("exponentialWait() n=1..5000 monotone=" + mono + " nonneg=" + nonneg + " n=1->" + t(ex, 1) + " n=62->" + t(ex, 62) + " n=63->" + t(ex, 63) + " n=1024->" + t(ex, 1024) + " n=Integer.MAX_VALUE->" + t(ex, Integer.MAX_VALUE));
    WaitStrategy ex5 = WaitStrategies.exponentialWait(100, 5, MINUTES);
    prev = -1; mono = true; boolean capOk = true; long capAt = -1;
    for (long n = 1; n <= 100000000L; n++) { long v = ex5.computeSleepTime(A.fail(n)); if (v < prev) mono = false; if (v > 300000) capOk = false; if (capAt < 0 && v == 300000) capAt = n; prev = v; }
    p("exponentialWait(100, 5 MIN) (README) n=1..1e8: monotone=" + mono + " <=cap=" + capOk + " cap reached at n=" + capAt + " ; n=1 -> " + t(ex5, 1) + " (2*multiplier, not multiplier)");
    p("== H4.7 waits after int wrap of attempt counter (Attempt numbers -2147483648, -1, 0)");
    WaitStrategy[] ws = { WaitStrategies.exponentialWait(100, 5, MINUTES), WaitStrategies.fibonacciWait(100, 2, MINUTES), WaitStrategies.incrementingWait(500, MILLISECONDS, 100, MILLISECONDS) };
    String[] nm = {"exponentialWait(100,5min)", "fibonacciWait(100,2min)", "incrementingWait(500,100)"};
    for (int i = 0; i < ws.length; i++) p(nm[i] + ": n=2147483647 -> " + t(ws[i], 2147483647L) + " ; n=-2147483648 -> " + t(ws[i], -2147483648L) + " ; n=-1 -> " + t(ws[i], -1) + " ; n=0 -> " + t(ws[i], 0));
    p("stopAfterAttempt(5).shouldStop(n=-2147483648) = " + StopStrategies.stopAfterAttempt(5).shouldStop(A.fail(-2147483648L)) + " ; stopAfterAttempt(Integer.MAX_VALUE).shouldStop(2147483647) = " + StopStrategies.stopAfterAttempt(Integer.MAX_VALUE).shouldStop(A.fail(2147483647L)));
    p("== H4.8 sub-millisecond truncation");
    StopStrategy sd = StopStrategies.stopAfterDelay(500, MICROSECONDS);
    p("stopAfterDelay(500 us).shouldStop(delay=0ms) = " + sd.shouldStop(A.failDelay(1, 0)));
    StopStrategy sd2 = StopStrategies.stopAfterDelay(1999, MICROSECONDS);
    p("stopAfterDelay(1999 us) -> maxDelay=" + MICROSECONDS.toMillis(1999) + " ms ; shouldStop(delay=1ms) = " + sd2.shouldStop(A.failDelay(1, 1)));
    p("fixedWait(999 us) -> " + t(WaitStrategies.fixedWait(999, MICROSECONDS), 1));
    try { WaitStrategies.randomWait(500, MICROSECONDS); p("randomWait(500us) constructed"); } catch (Throwable e) { p("randomWait(500 us) -> " + e); }
    try { WaitStrategies.exponentialWait(500, MICROSECONDS); p("exponentialWait(500us) constructed"); } catch (Throwable e) { p("exponentialWait(500 us) -> " + e); }
    try { WaitStrategies.exponentialWait(1, MILLISECONDS); p("exponentialWait(1ms) constructed"); } catch (Throwable e) { p("exponentialWait(1 ms) -> " + e); }
    p("== H4.10 stop boundaries");
    p("stopAfterDelay(1000ms).shouldStop(delay=1000) = " + StopStrategies.stopAfterDelay(1000, MILLISECONDS).shouldStop(A.failDelay(1, 1000)) + " (doc: 'has exceeded')");
    p("stopAfterAttempt(3): n=2 -> " + StopStrategies.stopAfterAttempt(3).shouldStop(A.fail(2)) + " n=3 -> " + StopStrategies.stopAfterAttempt(3).shouldStop(A.fail(3)));
    p("== docs: fixedWait(-1) exception type");
    try { WaitStrategies.fixedWait(-1, SECONDS); } catch (Throwable e) { p("fixedWait(-1s) -> " + e.getClass().getName() + " (Javadoc says IllegalStateException)"); }
    try { WaitStrategies.randomWait(0, SECONDS); } catch (Throwable e) { p("randomWait(0) -> " + e.getClass().getName() + ": " + e.getMessage()); }
  }
}
