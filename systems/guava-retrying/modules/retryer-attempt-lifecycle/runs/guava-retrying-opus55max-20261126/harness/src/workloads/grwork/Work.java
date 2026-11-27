package grwork;

import gov.nasa.jpf.vm.Verify;

import java.util.concurrent.Callable;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * The user callable. The k-th body that starts (counting bodies of this
 * callable, in start order) runs plan[min(k, plan.length-1)]. A plan entry may
 * list alternatives separated by '|'; JPF then chooses one (Verify.getInt), so
 * the random search explores the alternatives.
 */
public final class Work implements Callable<Object> {
    private final String[] plan;
    private final AtomicInteger bodies = new AtomicInteger();

    public Work(String... plan) {
        this.plan = plan;
    }

    @Override
    public Object call() throws Exception {
        int k = bodies.getAndIncrement();
        String entry = plan[Math.min(k, plan.length - 1)];
        String mode;
        if (entry.indexOf('|') < 0) {
            mode = entry;
        } else {
            String[] alts = entry.split("\\|");
            mode = alts[Verify.getInt(0, alts.length - 1)];
        }
        return Modes.run(mode);
    }
}
