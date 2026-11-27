package rt;

/** The callable behaviors of base.tla AllModes, on a real JVM. */
public final class Modes {
    public static final String OK = "ok";
    public static final String BAD = "bad";
    static final Object waitLock = new Object();

    /** Busy work that never reads the interrupt status. */
    static void spin(long micros) {
        long end = System.nanoTime() + micros * 1000;
        while (System.nanoTime() < end) { Thread.onSpinWait(); }
    }

    static Object run(String mode, long spinMicros) throws Exception {
        switch (mode) {
            case "Ret": spin(spinMicros); return OK;
            case "RetBad": spin(spinMicros); return BAD;
            case "Exc": spin(spinMicros); throw new java.io.IOException("Exc");
            case "Err": spin(spinMicros); throw new AssertionError("Err");
            case "IntrRet":
                spin(spinMicros);
                if (Thread.interrupted()) throw new InterruptedException("IntrRet");
                return OK;
            case "IntrBlock":
                synchronized (waitLock) {
                    while (true) waitLock.wait();   // ends only by InterruptedException
                }
            default: throw new IllegalStateException(mode);
        }
    }
}
