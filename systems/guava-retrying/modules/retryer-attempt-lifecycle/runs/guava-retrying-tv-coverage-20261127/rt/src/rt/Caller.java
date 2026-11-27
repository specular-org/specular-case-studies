package rt;

import com.github.rholder.retry.*;
import com.google.common.base.Predicate;

import java.io.IOException;
import java.util.*;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeUnit;

/** One caller thread (c1) and its recording callable, listener and strategy wrappers. */
public final class Caller {
    final String id = "c1";
    final Random rnd;
    final String[] plan;
    final long stopDelayMs;          // -1 unless stopAfterDelay
    long spinMicros = 2000;
    volatile boolean done;
    int k = 0;                       // attempt number (bodies started)
    long lastExit = -1;              // end of the latest observed caller step
    Rec.Ev pendingExpired, pendingCount;
    Retryer<Object> retryer;
    volatile boolean inSleep;        // set by the block wrapper around the real sleep
    volatile boolean inBody;

    Caller(long seed, String[] plan, long stopDelayMs) {
        this.rnd = new Random(seed);
        this.plan = plan;
        this.stopDelayMs = stopDelayMs;
    }

    boolean intr() { return Thread.currentThread().isInterrupted(); }

    static final long NOW = -2;

    /** Reads the interrupt flag BEFORE stamping the end of the interval (end = NOW). */
    Rec.Ev cev(String name, long start, long end, int attemptNo) {
        boolean i = intr();
        long en = end == NOW ? Rec.now() : end;
        long st = start == NOW ? en : start;
        Rec.Ev e = Rec.ev(name, id, st, en);
        e.put("attemptNo", attemptNo);
        e.put("intr", i);
        return e;
    }

    // ---------------- user callable ----------------
    final Callable<Object> work = new Callable<Object>() {
        @Override
        public Object call() throws Exception {
            k++;
            String entry = plan[Math.min(k - 1, plan.length - 1)];
            String[] alts = entry.split("\\|");
            String mode = alts[rnd.nextInt(alts.length)];
            Rec.Ev bs = cev("CallerBodyStart", NOW, NOW, k).put("mode", mode);
            if (k == 1) callStart.end((Long) bs.f.get("start"));
            inBody = true;
            try {
                Object r = Modes.run(mode, spinMicros);
                inBody = false;
                Rec.Ev e = cev("CallerBodyReturns", NOW, NOW, k);
                long u = (Long) e.f.get("end");
                e.put("attemptKind", Modes.BAD.equals(r) ? "BadResult" : "Result").open("expired");
                pendingExpired = e;
                lastExit = u;
                return r;
            } catch (Throwable th) {
                inBody = false;
                Rec.Ev e = cev("CallerBodyThrows", NOW, NOW, k);
                long u = (Long) e.f.get("end");
                String kind = th instanceof InterruptedException ? "CallableIE" : th instanceof Error ? "CallableErr" : "CallableExc";
                e.put("attemptKind", kind).open("expired");
                pendingExpired = e;
                lastExit = u;
                throw th;
            }
        }
    };
    Rec.Ev callStart, pendingNext, pendingListenersEnd;
    int listenerCount;

    // ---------------- listeners ----------------
    final class L implements RetryListener {
        final int lid;
        L(int lid) { this.lid = lid; }
        @Override
        public <V> void onRetry(Attempt<V> attempt) {
            if (pendingExpired != null) {
                boolean exp = stopDelayMs >= 0 && attempt.getDelaySinceFirstAttempt() >= stopDelayMs;
                pendingExpired.put("expired", exp);
                pendingExpired = null;
                // ListenersBegin: Itr.<init> read modCount between the Attempt and the first notify
                Object list = Rec.field(retryer, Retryer.class, "listeners");
                int mod = (Integer) Rec.field(list, AbstractList.class, "modCount");
                int size = (Integer) Rec.field(list, ArrayList.class, "size");
                cev("ListenersBegin", lastExit, NOW, (int) attempt.getAttemptNumber()).put("modCount", mod).put("size", size);
            }
            cev("ListenerNotify", NOW, NOW, (int) attempt.getAttemptNumber()).put("listener", lid).put("cursor", lid);
            lastExit = Rec.now();
            if (lid == listenerCount) {
                pendingListenersEnd = Rec.ev("ListenersEnd", id, lastExit, -1).put("attemptNo", (int) attempt.getAttemptNumber()).put("intr", intr())
                        .put("cursor", lid).put("size", listenerCount);
            }
        }
    }

    void closeListenersEnd(long t) {
        if (pendingListenersEnd != null) { pendingListenersEnd.end(t); pendingListenersEnd = null; }
    }

    // ---------------- strategy wrappers around the built-in ones ----------------
    StopStrategy stop(StopStrategy real) {
        return attempt -> {
            long t = Rec.now();
            closeListenersEnd(t);
            boolean s = real.shouldStop(attempt);
            if (s) {
                pendingCount = cev("StopStrategyStops", t, NOW, k).open("count");
            }
            lastExit = Rec.now();
            return s;
        };
    }

    WaitStrategy waitS(WaitStrategy real) {
        return attempt -> {
            long t = Rec.now();
            long v = real.computeSleepTime(attempt);
            Rec.Ev we = cev("WaitStrategyComputes", t, NOW, k).put("sleep", v == 0 ? "Zero" : v > 0 ? "Positive" : "Negative");
            long u = (Long) we.f.get("end");
            lastSleep = v;
            lastExit = u;
            return v;
        };
    }
    long lastSleep;

    final BlockStrategy realBlock = BlockStrategies.threadSleepStrategy();

    BlockStrategy block() {
        return sleepTime -> {
            boolean pre = Thread.currentThread().isInterrupted();
            long t1 = Rec.now();
            inSleep = sleepTime > 0;
            try {
                realBlock.block(sleepTime);
            } catch (IllegalArgumentException iae) {
                inSleep = false;
                cev("BlockNegative", t1, NOW, k);
                throw iae;
            } catch (InterruptedException ie) {
                inSleep = false;
                long t2 = Rec.now();
                boolean flagNow = false; // Thread.sleep cleared it
                if (pre || sleepTime == 0) {
                    pendingCount = Rec.ev("BlockInterrupted", id, t1, t2).put("attemptNo", k).open("intr").open("count");
                } else if (t2 - t1 >= 20_000_000L) {
                    Rec.ev("BlockSleepStart", id, t1, t2).put("attemptNo", k).put("intr", false);
                    pendingCount = Rec.ev("SleepInterrupted", id, t1, t2).put("attemptNo", k).open("intr").open("count");
                } else {
                    Rec.invalidate("ambiguous interrupt of sleep(" + sleepTime + ") after " + (t2 - t1) + " ns");
                }
                throw ie;
            }
            inSleep = false;
            long t2;
            if (sleepTime == 0) {
                t2 = (Long) cev("BlockZero", t1, NOW, k + 1).f.get("end");
            } else {
                Rec.Ev bss = Rec.ev("BlockSleepStart", id, t1, -1).put("attemptNo", k).put("intr", false);
                t2 = (Long) cev("SleepReturns", t1, NOW, k + 1).f.get("end");
                bss.end(t2);
            }
            lastExit = t2;
        };
    }

    /** Runs Retryer.call and records how it ended. */
    void run() {
        long t0 = Rec.now();
        callStart = Rec.ev("CallStart", id, t0, -1).put("attemptNo", 1).put("intr", intr());
        try {
            retryer.call(work);
            Rec.Ev pa = cev("PredicateAccepts", lastExit, NOW, k).put("outcome", "Returned");
            closeListenersEnd((Long) pa.f.get("end"));
        } catch (ExecutionException ee) {
            Rec.Ev pa = cev("PredicateAccepts", lastExit, NOW, k).put("outcome", "ExecExc");
            closeListenersEnd((Long) pa.f.get("end"));
        } catch (RetryException re) {
            if (pendingCount != null) {
                pendingCount.put("count", re.getNumberOfFailedAttempts());
                if (pendingCount.pending.contains("intr")) pendingCount.put("intr", intr());
            } else {
                Rec.invalidate("RetryException without a recorded stop/interrupt step");
            }
        } catch (IllegalArgumentException iae) {
            // BlockNegative already recorded
        } catch (RuntimeException rx) {
            Rec.invalidate("unexpected " + rx);
        }
    }
}
