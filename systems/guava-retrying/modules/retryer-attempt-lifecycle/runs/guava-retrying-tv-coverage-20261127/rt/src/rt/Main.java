package rt;

import com.github.rholder.retry.*;

import java.io.IOException;
import java.util.*;
import java.util.concurrent.TimeUnit;

/**
 * Real-HotSpot workloads (Limiter = None), one execution per JVM:
 *   java rt.Main <scenario> <seed> <out.ndjson>
 * scenario: basic | interrupt | decision
 */
public final class Main {
    static String cfg(String retryOn, String stopKind, String extra, String sleeps, String modes) {
        return "{\"callers\":[\"c1\"],\"numInitListeners\":1,\"numExtraListeners\":0,"
                + "\"limiter\":\"None\",\"execKind\":\"Cached\",\"poolSize\":1,\"queueCap\":0,"
                + "\"retryOn\":" + retryOn + ",\"stopKind\":\"" + stopKind + "\",\"stopAfter\":3," + extra
                + "\"sleepClasses\":" + sleeps + ",\"modes\":" + modes
                + ",\"wrapCallers\":[],\"wrapOnLimiterPool\":[],\"workers\":[],\"tasks\":[],\"outerWorkers\":{}}";
    }

    @SuppressWarnings("unchecked")
    public static void main(String[] a) throws Exception {
        String scenario = a[0];
        long seed = Long.parseLong(a[1]);
        String out = a[2];
        Random rnd = new Random(seed * 7919 + 1);
        String all = "[\"Timeout\",\"CallerIE\",\"CallableExc\",\"CallableIE\",\"Rejected\"";
        String config;
        Caller c;
        RetryerBuilder<Object> b = RetryerBuilder.<Object>newBuilder().retryIfException();
        switch (scenario) {
            case "basic": {
                c = new Caller(seed, new String[]{"Ret|RetBad|Exc|Err"}, -1);
                b.retryIfResult(Modes.BAD::equals)
                 .withStopStrategy(c.stop(StopStrategies.stopAfterAttempt(3)))
                 .withWaitStrategy(c.waitS(WaitStrategies.noWait()));
                config = cfg(all + ",\"BadResult\"]", "AfterAttempt", "", "[\"Zero\"]", "[\"Ret\",\"RetBad\",\"Exc\",\"Err\"]");
                break;
            }
            case "interrupt": {
                c = new Caller(seed, new String[]{"Ret|Exc|IntrRet|IntrBlock"}, -1);
                b.withStopStrategy(c.stop(StopStrategies.stopAfterAttempt(3)))
                 .withWaitStrategy(c.waitS(WaitStrategies.exceptionWait(IOException.class, (IOException e) -> 150L)));
                config = cfg(all + "]", "AfterAttempt", "", "[\"Zero\",\"Positive\"]", "[\"Ret\",\"Exc\",\"IntrRet\",\"IntrBlock\"]");
                break;
            }
            case "isleep":    // interrupt while the caller sleeps between attempts
            case "ipre": {    // interrupt during an Exc body: the flag is set when block() starts
                c = new Caller(seed, new String[]{"Exc", "Exc|Ret", "Ret"}, -1);
                c.spinMicros = 5000;
                b.withStopStrategy(c.stop(StopStrategies.stopAfterAttempt(3)))
                 .withWaitStrategy(c.waitS(WaitStrategies.exceptionWait(IOException.class, (IOException e) -> 150L)));
                config = cfg(all + "]", "AfterAttempt", "", "[\"Zero\",\"Positive\"]", "[\"Ret\",\"Exc\"]");
                break;
            }
            case "decision": {
                c = new Caller(seed, new String[]{"RetBad|Exc|Ret", "RetBad|Exc|Ret", "RetBad|Ret"}, 5);
                b.retryIfResult(Modes.BAD::equals)
                 .withStopStrategy(c.stop(StopStrategies.stopAfterDelay(5, TimeUnit.MILLISECONDS)))
                 .withWaitStrategy(c.waitS(WaitStrategies.join(
                        WaitStrategies.exceptionWait(IOException.class, (IOException e) -> Long.MAX_VALUE),
                        WaitStrategies.fixedWait(1, TimeUnit.MILLISECONDS))));
                c.spinMicros = rnd.nextInt(4000);
                config = cfg(all + ",\"BadResult\"]", "AfterDelay", "", "[\"Positive\",\"Negative\"]", "[\"Ret\",\"RetBad\",\"Exc\"]");
                break;
            }
            default: throw new IllegalArgumentException(scenario);
        }
        b.withBlockStrategy(c.block()).withRetryListener(c.new L(1));
        c.listenerCount = 1;
        c.retryer = b.build();
        Caller cc = c;
        Thread t1 = new Thread(() -> { cc.run(); cc.done = true; }, "c1");
        Thread e = null;
        long[] intr = null;
        if (scenario.equals("interrupt") || scenario.equals("isleep") || scenario.equals("ipre")) {
            int how = scenario.equals("isleep") ? 1 : scenario.equals("ipre") ? 2 : rnd.nextInt(3);
            long delayMs = rnd.nextInt(60);
            long[] iv = new long[]{-1, -1};
            intr = iv;
            e = new Thread(() -> {
                try {
                    if (how == 0) Thread.sleep(delayMs);                 // anywhere
                    else if (how == 1) { while (!cc.inSleep && !cc.done) Thread.onSpinWait(); Thread.sleep(40); } // inside a sleep
                    else { while (!cc.inBody && !cc.done) Thread.onSpinWait(); }   // inside a body
                } catch (InterruptedException ignored) { }
                if (cc.done) return;
                iv[0] = Rec.now();
                t1.interrupt();
                iv[1] = Rec.now();
            }, "e");
        }
        t1.start();
        if (e != null) e.start();
        t1.join();
        if (e != null) e.join();
        if (intr != null && intr[0] >= 0) {
            // an interrupt after call() ended is outside the model (base.tla Interrupt needs cpc # "Done")
            long lastEnd = 0;
            synchronized (Rec.events) {
                for (Rec.Ev ev : Rec.events) {
                    Object en = ev.f.get("end");
                    if (en instanceof Long) lastEnd = Math.max(lastEnd, (Long) en);
                }
            }
            if (intr[0] <= lastEnd) Rec.ev("Interrupt", "e", intr[0], intr[1]).put("target", "c1");
        }
        Map<String, Object> m = new LinkedHashMap<>();
        // parse our own flat config JSON minimally: store raw via a marker
        boolean ok = Rec.writeRaw(out, config);
        System.out.println((ok ? "WROTE " : "DROPPED ") + out + " " + Rec.invalidWhy);
    }
}
