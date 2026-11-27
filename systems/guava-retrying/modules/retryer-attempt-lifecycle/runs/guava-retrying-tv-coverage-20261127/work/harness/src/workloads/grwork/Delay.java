package grwork;

import gov.nasa.jpf.vm.Verify;

/** Lets JPF choose how long an environment thread lets others run before acting. */
public final class Delay {
    private Delay() {}

    /** Yields between 0 and max times (JPF chooses the count). */
    public static void some(int max) {
        int k = Verify.getInt(0, max);
        for (int i = 0; i < k; i++) {
            Thread.yield();
        }
    }
}
