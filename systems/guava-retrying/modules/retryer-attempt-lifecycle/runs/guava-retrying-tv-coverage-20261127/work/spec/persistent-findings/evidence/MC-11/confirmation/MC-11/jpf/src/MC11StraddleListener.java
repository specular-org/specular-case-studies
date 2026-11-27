import gov.nasa.jpf.ListenerAdapter;
import gov.nasa.jpf.search.Search;
import gov.nasa.jpf.vm.ElementInfo;
import gov.nasa.jpf.vm.Instruction;
import gov.nasa.jpf.vm.MethodInfo;
import gov.nasa.jpf.vm.ThreadInfo;
import gov.nasa.jpf.vm.VM;
import gov.nasa.jpf.vm.bytecode.InstanceFieldInstruction;
import gov.nasa.jpf.vm.bytecode.WriteInstruction;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * Observes (never alters) the JPF run of MC11Straddle and keeps a path-local event log that is
 * restored on backtrack. It classifies the moment Retryer.java:166 creates the ArrayList$Itr over the
 * builder's listener list relative to the concurrent ArrayList.add(L2):
 *   phase 0 = before add bumped modCount, 1 = after modCount++ but before size was stored (STRADDLE),
 *   2 = after the add published the element.
 * It reports the first path on which L2.onRetry runs from an iterator created in phase 1
 * (i.e. no ConcurrentModificationException and the new listener is still notified), plus
 * outcome counts over all end states reached.
 */
public class MC11StraddleListener extends ListenerAdapter {
    static final class PathState {
        final List<String> events; final boolean l2Entered; final int addPhase; final int lastItrPhase;
        final boolean cme; final boolean l2Notified;
        PathState(List<String> events, boolean l2Entered, int addPhase, int lastItrPhase, boolean cme, boolean l2Notified) {
            this.events = events; this.l2Entered = l2Entered; this.addPhase = addPhase; this.lastItrPhase = lastItrPhase;
            this.cme = cme; this.l2Notified = l2Notified;
        }
        PathState log(String e, boolean l2Entered, int addPhase, int lastItrPhase, boolean cme, boolean l2Notified) {
            List<String> n = new ArrayList<String>(events);
            n.add(e);
            return new PathState(Collections.unmodifiableList(n), l2Entered, addPhase, lastItrPhase, cme, l2Notified);
        }
    }

    private PathState cur = new PathState(Collections.<String>emptyList(), false, 0, -1, false, false);
    private final ArrayList<PathState> atDepth = new ArrayList<PathState>();
    private int listRef = -1;
    private boolean reported;
    private int endStates, endCme, endL2NotifiedNoCme, endL2NotifiedViaStraddle, endL2NotNotified;

    private static String who(ThreadInfo ti) { return String.format("%-9s", ti.getName()); }

    @Override public void searchStarted(Search search) { atDepth.clear(); atDepth.add(cur); }

    @Override public void stateAdvanced(Search search) {
        int d = search.getDepth();
        while (atDepth.size() <= d) atDepth.add(null);
        atDepth.set(d, cur);
        if (search.isEndState()) {
            endStates++;
            if (cur.cme) endCme++;
            else if (cur.l2Notified && cur.lastItrPhase == 1) endL2NotifiedViaStraddle++;
            else if (cur.l2Notified) endL2NotifiedNoCme++;
            else endL2NotNotified++;
        }
    }

    @Override public void stateBacktracked(Search search) { cur = atDepth.get(search.getDepth()); }

    @Override public void stateRestored(Search search) { cur = atDepth.get(search.getDepth()); }

    @Override public void methodEntered(VM vm, ThreadInfo ti, MethodInfo mi) {
        String cn = mi.getClassName(), mn = mi.getName();
        if (cn.equals("com.github.rholder.retry.RetryerBuilder") && mn.equals("build") && listRef < 0) {
            // the builder's listener ArrayList; allocated before caller-c1 exists, so the same ref on every path
            listRef = ti.getElementInfo(ti.getTopFrame().getThis()).getReferenceField("listeners");
            cur = cur.log(who(ti) + " RetryerBuilder.build(): Retryer receives the builder's own listener list (size "
                    + ti.getElementInfo(listRef).getIntField("size") + ")", cur.l2Entered, cur.addPhase, cur.lastItrPhase, cur.cme, cur.l2Notified);
        } else if (cn.equals("com.github.rholder.retry.RetryerBuilder") && mn.equals("withRetryListener")) {
            int arg = ti.getTopFrame().getSlot(1);
            if (arg > 0 && ti.getElementInfo(arg).getClassInfo().getName().endsWith("$L2")) {
                cur = cur.log(who(ti) + " builder.withRetryListener(L2) entered (after build())", true, cur.addPhase, cur.lastItrPhase, cur.cme, cur.l2Notified);
            }
        } else if (mn.equals("onRetry") && (cn.equals("MC11Straddle$L1") || cn.equals("MC11Straddle$L2"))) {
            boolean isL2 = cn.endsWith("$L2");
            long no = ti.getElementInfo(ti.getTopFrame().getSlot(1)).getLongField("attemptNumber");
            ElementInfo list = ti.getElementInfo(listRef);
            cur = cur.log(who(ti) + " " + (isL2 ? "L2" : "L1") + ".onRetry(attempt #" + no + ")   [list.modCount=" + list.getIntField("modCount")
                    + " list.size=" + list.getIntField("size") + "]", cur.l2Entered, cur.addPhase, cur.lastItrPhase, cur.cme, cur.l2Notified || isL2);
            if (isL2 && cur.lastItrPhase == 1 && !reported) {
                reported = true;
                System.out.println();
                System.out.println("[MC11] STRADDLE PATH FOUND (search depth " + vm.getSearch().getDepth() + "): the iterator Retryer.java:166 is using was created");
                System.out.println("[MC11] after ArrayList.add(L2) bumped modCount but before it stored size -> no CME, and L2 is notified:");
                for (String e : cur.events) System.out.println("[MC11]   " + e);
                System.out.println();
            }
        }
    }

    @Override public void instructionExecuted(VM vm, ThreadInfo ti, Instruction next, Instruction exec) {
        if (listRef < 0 || !(exec instanceof InstanceFieldInstruction) || !(exec instanceof WriteInstruction)) return;
        // A shared-field PUTFIELD first runs only to create a scheduling choice point (next == exec, no
        // write yet) and is re-executed when the thread is scheduled again; log only the effective write.
        if (next == exec) return;
        InstanceFieldInstruction fins = (InstanceFieldInstruction) exec;
        String name = fins.getFieldInfo().getName();
        int obj = fins.getLastThis();
        if (obj == listRef && name.equals("modCount") && cur.l2Entered && cur.addPhase == 0) {
            ElementInfo list = ti.getElementInfo(listRef);
            cur = cur.log(who(ti) + " ArrayList.add(L2): modCount := " + list.getIntField("modCount") + "   (element not yet published, size="
                    + list.getIntField("size") + ")", cur.l2Entered, 1, cur.lastItrPhase, cur.cme, cur.l2Notified);
        } else if (obj == listRef && name.equals("size") && cur.addPhase == 1) {
            cur = cur.log(who(ti) + " ArrayList.add(L2): size := " + ti.getElementInfo(listRef).getIntField("size") + "   (L2 now visible)",
                    cur.l2Entered, 2, cur.lastItrPhase, cur.cme, cur.l2Notified);
        } else if (name.equals("expectedModCount") && fins.getFieldInfo().getClassInfo().getName().equals("java.util.ArrayList$Itr")) {
            ElementInfo itr = ti.getElementInfo(obj);
            if (itr.getReferenceField("this$0") == listRef) {
                ElementInfo list = ti.getElementInfo(listRef);
                String phase = cur.addPhase == 0 ? "before the add" : cur.addPhase == 1 ? "INSIDE the add (modCount bumped, size not yet stored)" : "after the add";
                cur = cur.log(who(ti) + " Retryer.java:166 new ArrayList$Itr: expectedModCount=" + itr.getIntField("expectedModCount")
                        + " (list.modCount=" + list.getIntField("modCount") + " list.size=" + list.getIntField("size") + ") -- " + phase,
                        cur.l2Entered, cur.addPhase, cur.addPhase, cur.cme, cur.l2Notified);
            }
        }
    }

    @Override public void exceptionThrown(VM vm, ThreadInfo ti, ElementInfo ex) {
        if (ex.getClassInfo().getName().equals("java.util.ConcurrentModificationException")) {
            cur = cur.log(who(ti) + " ConcurrentModificationException thrown", cur.l2Entered, cur.addPhase, cur.lastItrPhase, true, cur.l2Notified);
        }
    }

    @Override public void searchFinished(Search search) {
        System.out.println("[MC11] distinct end states (state matching on; merged paths are not re-counted): " + endStates
                + " | CME: " + endCme
                + " | L2 notified via straddling iterator: " + endL2NotifiedViaStraddle
                + " | L2 notified, iterator created after the add: " + endL2NotifiedNoCme
                + " | L2 not notified: " + endL2NotNotified);
        System.out.println("[MC11] straddle path reported: " + reported);
    }
}
