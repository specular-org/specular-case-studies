package grwork;

import java.util.concurrent.Callable;

/**
 * Markers the JPF recorder (grtrace.GrTraceRecorder) observes. They have no
 * behavior of their own: the recorder reacts to their invocation.
 *
 * Recording starts at begin() (after RetryerBuilder.build(), before the first
 * Retryer.call / submit(wrap(..))) and the workload is finished at end();
 * the recorder keeps recording other threads for a bounded number of further
 * scheduling steps (or until all threads have terminated).
 */
public final class Harness {
    private Harness() {}

    /**
     * @param configJson the workload's static configuration (the
     *                   {"tag":"config"} fields that do not depend on the run)
     * @param retryer    the Retryer under test (the recorder reads its listener
     *                   list and time limiter from its fields)
     * @param limiterExecutor the executor passed to fixedTimeLimit, or null
     *                   (noTimeLimit, or the 2-argument factory: the recorder
     *                   then takes SimpleTimeLimiter's own executor)
     */
    public static void begin(String configJson, Object retryer, Object limiterExecutor) {}

    /** Declares that {@code retryerCallable} (a Retryer.wrap() result) is caller {@code id}. */
    public static void wrapCaller(String id, Object retryerCallable) {}

    /** The workload's main thread is done (all callers have finished). */
    public static void end() {}

    /** Joins a thread, ignoring interrupts of the joining thread. */
    public static void join(Thread t) {
        for (;;) {
            try {
                t.join();
                return;
            } catch (InterruptedException e) {
                // keep waiting
            }
        }
    }

    /** Starts a named thread. */
    public static Thread start(String name, Runnable r) {
        Thread t = new Thread(r, name);
        t.start();
        return t;
    }

    /** Runs retryer.call on the current thread and swallows every outcome. */
    public static Object callQuietly(com.github.rholder.retry.Retryer<Object> retryer, Callable<Object> work) {
        try {
            return retryer.call(work);
        } catch (Throwable t) {
            // RetryException, ExecutionException, and the undocumented escapes
            // (ConcurrentModificationException, IllegalArgumentException) all end the call
            return t;
        }
    }
}
