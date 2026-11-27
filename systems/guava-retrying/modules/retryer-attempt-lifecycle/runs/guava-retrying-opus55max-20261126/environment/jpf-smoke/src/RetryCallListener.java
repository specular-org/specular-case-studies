import gov.nasa.jpf.ListenerAdapter;
import gov.nasa.jpf.vm.*;

/** Prints entry/exit of Retryer.call and attempt time-limiter calls, with search depth, without touching app code. */
public class RetryCallListener extends ListenerAdapter {
  private static boolean watched(MethodInfo mi) {
    String c = mi.getClassName();
    return (c.equals("com.github.rholder.retry.Retryer") && mi.getName().equals("call"))
        || (c.startsWith("com.github.rholder.retry.AttemptTimeLimiters$") && mi.getName().equals("call"));
  }
  @Override public void methodEntered(VM vm, ThreadInfo ti, MethodInfo mi) {
    if (watched(mi)) System.out.println("[trace] depth=" + vm.getSearch().getDepth() + " t=" + ti.getId() + " enter " + mi.getFullName());
  }
  @Override public void methodExited(VM vm, ThreadInfo ti, MethodInfo mi) {
    if (watched(mi)) System.out.println("[trace] depth=" + vm.getSearch().getDepth() + " t=" + ti.getId() + " exit  " + mi.getFullName());
  }
}
