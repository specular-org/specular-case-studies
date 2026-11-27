package grwork;

/**
 * The callable behaviors of instrumentation-spec.md section 1 ("mode"). One
 * method per mode; the recorder identifies the mode by which method the
 * attempt's body enters, and each method's end is the mode's end commit point:
 *
 *   Ret / RetBad  the areturn
 *   Exc / Err     the athrow
 *   IntrRet       the Thread.interrupted() call (true: throws, status cleared)
 *   IntrBlock     the InterruptedException raised by Object.wait()
 *   Stuck         none (never returns, never reads the interrupt status)
 */
public final class Modes {
    private Modes() {}

    public static final String OK = "ok";
    /** The value retryIfResult(BAD::equals) rejects. */
    public static final String BAD = "bad";

    public static Object ret() {
        return OK;
    }

    public static Object retBad() {
        return BAD;
    }

    public static Object exc() throws Exception {
        throw new java.io.IOException("Exc");
    }

    public static Object err() {
        throw new AssertionError("Err");
    }

    public static Object intrRet() throws InterruptedException {
        if (Thread.interrupted()) {
            throw new InterruptedException("IntrRet");
        }
        return OK;
    }

    public static Object intrBlock() throws InterruptedException {
        Object lock = new Object();
        synchronized (lock) {
            for (;;) {
                lock.wait(); // no notifier: ends only by InterruptedException
            }
        }
    }

    public static Object stuck() {
        for (;;) {
            Thread.yield(); // never returns, never touches the interrupt status
        }
    }

    static Object run(String mode) throws Exception {
        switch (mode) {
            case "Ret": return ret();
            case "RetBad": return retBad();
            case "Exc": return exc();
            case "Err": return err();
            case "IntrRet": return intrRet();
            case "IntrBlock": return intrBlock();
            case "Stuck": return stuck();
            default: throw new IllegalStateException("unknown mode " + mode);
        }
    }
}
