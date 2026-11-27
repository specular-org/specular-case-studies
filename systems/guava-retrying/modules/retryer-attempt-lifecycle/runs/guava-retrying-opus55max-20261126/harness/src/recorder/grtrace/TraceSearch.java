package grtrace;

import gov.nasa.jpf.Config;
import gov.nasa.jpf.search.Search;
import gov.nasa.jpf.vm.RestorableVMState;
import gov.nasa.jpf.vm.VM;

/**
 * Random-walk search with restarts: each path runs the workload from the
 * initial state to the end of the execution, taking the first choice of every
 * choice generator (cg.randomize_choices shuffles them), so each path is one
 * complete execution of the real code under one thread schedule. A path ends
 * when all threads have terminated, when the recorder reports the workload
 * finished (plus a quiescence window, for workloads with threads that never
 * terminate, e.g. a Stuck callable or an idle cached pool), at the depth
 * limit, or when no thread can run. The recorder then writes the path's trace
 * and the search restarts from the initial state.
 *
 * Properties: grtrace.max_paths, grtrace.budget_ms (wall clock), plus the
 * recorder's grtrace.max_traces (stop once that many traces are kept).
 */
public class TraceSearch extends Search {
    private final int maxPaths;
    private final long budgetMs;

    public TraceSearch(Config config, VM vm) {
        super(config, vm);
        maxPaths = config.getInt("grtrace.max_paths", 2000);
        budgetMs = config.getLong("grtrace.budget_ms", 120000L);
    }

    @Override
    public boolean requestBacktrack() {
        return false;
    }

    @Override
    public boolean supportsBacktrack() {
        return false;
    }

    @Override
    public void search() {
        GrTraceRecorder rec = vm.getJPF().getListenerOfType(GrTraceRecorder.class);
        if (rec == null) throw new IllegalStateException("grtrace.GrTraceRecorder must be a listener");
        RestorableVMState init = vm.getRestorableState();
        notifySearchStarted();
        long t0 = System.currentTimeMillis();
        int paths = 0;
        while (!done && paths < maxPaths && System.currentTimeMillis() - t0 < budgetMs && !rec.enough()) {
            rec.pathStarted(paths);
            depth = 0;
            String why;
            for (;;) {
                if (isEndState()) { why = "end"; break; }
                if (rec.pathComplete()) { why = "quiescent"; break; }
                if (depth >= depthLimit) { why = "depth"; break; }
                if (!forward()) { why = "blocked"; break; }
                depth++;
                notifyStateAdvanced();
                if (currentError != null) {
                    System.out.println("[grtrace] path " + paths + ": property violated: " + currentError.getDescription());
                    why = "error";
                    currentError = null;
                    break;
                }
            }
            rec.pathEnded(why);
            paths++;
            vm.restoreState(init);
            vm.resetNextCG();
        }
        rec.writeSummary(paths);
        notifySearchFinished();
    }
}
