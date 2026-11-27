package com.github.rholder.retry;
import java.util.concurrent.TimeUnit;
public class WrapWaits {
    public static void main(String[] a) {
        Attempt<Object> neg = new Retryer.ResultAttempt<Object>(null, Integer.MIN_VALUE, 0);
        Attempt<Object> max = new Retryer.ResultAttempt<Object>(null, Integer.MAX_VALUE - 1, 0);
        WaitStrategy[] ws = { WaitStrategies.exponentialWait(100, 60000, TimeUnit.MILLISECONDS),
                              WaitStrategies.fibonacciWait(100, 60000, TimeUnit.MILLISECONDS),
                              WaitStrategies.incrementingWait(500, TimeUnit.MILLISECONDS, 100, TimeUnit.MILLISECONDS) };
        String[] names = { "exponentialWait(100,60s)", "fibonacciWait(100,60s)", "incrementingWait(500ms,+100ms)" };
        for (int i = 0; i < ws.length; i++) {
            long t0 = System.nanoTime();
            long atMax = ws[i].computeSleepTime(max);
            long ms = (System.nanoTime() - t0) / 1000000;
            System.out.println(names[i] + ": attempt MAX-1 -> " + atMax + " ms (computed in " + ms + " ms); attempt MIN_VALUE -> " + ws[i].computeSleepTime(neg) + " ms");
        }
    }
}
