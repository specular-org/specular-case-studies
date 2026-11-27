package grtrace;

import gov.nasa.jpf.Config;
import gov.nasa.jpf.ListenerAdapter;
import gov.nasa.jpf.jvm.bytecode.ARETURN;
import gov.nasa.jpf.jvm.bytecode.ATHROW;
import gov.nasa.jpf.jvm.bytecode.GETFIELD;
import gov.nasa.jpf.jvm.bytecode.IINC;
import gov.nasa.jpf.jvm.bytecode.IRETURN;
import gov.nasa.jpf.jvm.bytecode.ISTORE;
import gov.nasa.jpf.jvm.bytecode.PUTFIELD;
import gov.nasa.jpf.search.Search;
import gov.nasa.jpf.vm.ElementInfo;
import gov.nasa.jpf.vm.Instruction;
import gov.nasa.jpf.vm.MethodInfo;
import gov.nasa.jpf.vm.NativeStackFrame;
import gov.nasa.jpf.vm.StackFrame;
import gov.nasa.jpf.vm.ThreadInfo;
import gov.nasa.jpf.vm.VM;

import java.io.IOException;
import java.io.Writer;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.security.MessageDigest;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.IdentityHashMap;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;

/**
 * JPF listener that records guava-retrying executions as NDJSON traces for
 * Trace.tla (instrumentation-spec.md). JPF executes the unmodified library,
 * Guava 22.0 and the JDK 11 java.util.concurrent bytecode; this listener
 * observes the instruction (or native call) that is each base.tla action's
 * commit point and emits one event per action with start = end = a global
 * logical clock value taken at that point.
 *
 * Each path explored by {@link TraceSearch} is one execution: the recorder
 * resets at path start and, at path end, writes the path's events (sorted by
 * clock) as one trace file if the trace is new and adds coverage.
 *
 * Fields that the code only determines after the commit point (the attempt's
 * classification, the RetryException count, the body's mode, the incremented
 * attempt number, the listener next() returns, the dequeued task) are filled
 * in later on the same thread; the event keeps the commit point's clock. A
 * path that ends while such a field is still open is cut before the earliest
 * open event (a prefix of the execution).
 */
public class GrTraceRecorder extends ListenerAdapter {

    // ------------------------------------------------------------------
    // Configuration
    // ------------------------------------------------------------------

    private final Path outDir;
    private final Path summaryDir;
    private final String workload;
    private final int maxTraces;
    private final int minTraces;
    private final int quiesceSteps;
    private final int maxEvents;
    private final boolean debug;

    public GrTraceRecorder(Config conf) {
        outDir = Paths.get(conf.getString("grtrace.out_dir", "traces"));
        summaryDir = Paths.get(conf.getString("grtrace.summary_dir", outDir.toString()));
        workload = conf.getString("grtrace.workload", "workload");
        maxTraces = conf.getInt("grtrace.max_traces", 40);
        minTraces = conf.getInt("grtrace.min_traces", 5);
        quiesceSteps = conf.getInt("grtrace.quiesce_steps", 150);
        maxEvents = conf.getInt("grtrace.max_events", 400);
        debug = conf.getBoolean("grtrace.debug", false);
        try {
            Files.createDirectories(outDir);
            Files.createDirectories(summaryDir);
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }

    // ------------------------------------------------------------------
    // Method identification
    // ------------------------------------------------------------------

    private static final int NONE = 0;
    // workload markers and modes
    private static final int H_BEGIN = 1, H_END = 2, H_WRAP = 3, WORK_CALL = 4;
    private static final int M_RET = 10, M_RETBAD = 11, M_EXC = 12, M_ERR = 13, M_INTRRET = 14,
            M_INTRBLOCK = 15, M_STUCK = 16;
    // guava-retrying
    private static final int R_CALL = 20, RC_CALL = 21, RA_INIT = 22, EA_INIT = 23, RETRYEX_INIT3 = 24,
            NOLIMIT_CALL = 25, DEC_APPLY = 26, DEC_SHOULDSTOP = 27, DEC_SLEEPTIME = 28;
    // Guava
    private static final int STL_CALL = 30;
    // FutureTask
    private static final int FT_INIT = 40, FT_RUN = 41, FT_CANCEL = 42, FT_GET_T = 43, FT_AWAIT = 44,
            FT_REPORT = 45, FT_SET = 46, FT_SETEX = 47, FT_HPCI = 48;
    // JPF VarHandle model
    private static final int VH_CAS_INT = 50, VH_CAS_OBJ = 51, VH_SETREL_INT = 52;
    // SynchronousQueue
    private static final int SQ_OFFER = 60, TS_TRANSFER = 61, TS_CASHEAD = 62, SN_TRYMATCH = 63, SQ_POLL_T = 64;
    // LinkedBlockingQueue / ArrayBlockingQueue / AtomicInteger
    private static final int LBQ_OFFER = 70, LBQ_TAKE = 71, LBQ_POLL_T = 72, AI_GETINC = 73, AI_GETDEC = 74,
            ABQ_OFFER = 75, ABQ_ENQ = 76, ABQ_DEQ = 77;
    // ThreadPoolExecutor
    private static final int TPE_EXECUTE = 80, TPE_ADDWORKER = 81, TPE_CAIWC = 82, TPE_REJECT = 83,
            TPE_GETTASK = 84, TPE_ADVANCE = 85, TPE_SHUTDOWN = 86, WORKER_INIT = 87, TPE_INTR_IDLE = 88, W_UNLOCK = 89, TPE_RUNWORKER = 79;
    // ArrayList
    private static final int ITR_INIT = 90, ITR_HASNEXT = 91, ITR_NEXT = 92, ITR_CHECK = 93, AL_ADD = 94,
            AL_ADD3 = 95;
    // Thread (JPF model)
    private static final int TH_INTERRUPT = 100, TH_INTERRUPTED = 101, TH_SLEEP = 102, TH_SLEEP0 = 103;

    private static final Map<String, Integer> CODES = new HashMap<>();

    static {
        String R = "com.github.rholder.retry.";
        CODES.put("grwork.Harness.begin(Ljava/lang/String;Ljava/lang/Object;Ljava/lang/Object;)V", H_BEGIN);
        CODES.put("grwork.Harness.end()V", H_END);
        CODES.put("grwork.Harness.wrapCaller(Ljava/lang/String;Ljava/lang/Object;)V", H_WRAP);
        CODES.put("grwork.Work.call()Ljava/lang/Object;", WORK_CALL);
        CODES.put("grwork.Modes.ret()Ljava/lang/Object;", M_RET);
        CODES.put("grwork.Modes.retBad()Ljava/lang/Object;", M_RETBAD);
        CODES.put("grwork.Modes.exc()Ljava/lang/Object;", M_EXC);
        CODES.put("grwork.Modes.err()Ljava/lang/Object;", M_ERR);
        CODES.put("grwork.Modes.intrRet()Ljava/lang/Object;", M_INTRRET);
        CODES.put("grwork.Modes.intrBlock()Ljava/lang/Object;", M_INTRBLOCK);
        CODES.put("grwork.Modes.stuck()Ljava/lang/Object;", M_STUCK);
        CODES.put(R + "Retryer.call(Ljava/util/concurrent/Callable;)Ljava/lang/Object;", R_CALL);
        CODES.put(R + "Retryer$RetryerCallable.call()Ljava/lang/Object;", RC_CALL);
        CODES.put(R + "Retryer$ResultAttempt.<init>(Ljava/lang/Object;JJ)V", RA_INIT);
        CODES.put(R + "Retryer$ExceptionAttempt.<init>(Ljava/lang/Throwable;JJ)V", EA_INIT);
        CODES.put(R + "RetryException.<init>(Ljava/lang/String;ILcom/github/rholder/retry/Attempt;)V", RETRYEX_INIT3);
        CODES.put(R + "AttemptTimeLimiters$NoAttemptTimeLimit.call(Ljava/util/concurrent/Callable;)Ljava/lang/Object;", NOLIMIT_CALL);
        CODES.put("com.google.common.util.concurrent.SimpleTimeLimiter.callWithTimeout(Ljava/util/concurrent/Callable;JLjava/util/concurrent/TimeUnit;Z)Ljava/lang/Object;", STL_CALL);
        String F = "java.util.concurrent.FutureTask.";
        CODES.put(F + "<init>(Ljava/util/concurrent/Callable;)V", FT_INIT);
        CODES.put(F + "run()V", FT_RUN);
        CODES.put(F + "cancel(Z)Z", FT_CANCEL);
        CODES.put(F + "get(JLjava/util/concurrent/TimeUnit;)Ljava/lang/Object;", FT_GET_T);
        CODES.put(F + "awaitDone(ZJ)I", FT_AWAIT);
        CODES.put(F + "report(I)Ljava/lang/Object;", FT_REPORT);
        CODES.put(F + "set(Ljava/lang/Object;)V", FT_SET);
        CODES.put(F + "setException(Ljava/lang/Throwable;)V", FT_SETEX);
        CODES.put(F + "handlePossibleCancellationInterrupt(I)V", FT_HPCI);
        CODES.put("java.lang.invoke.JPFFieldVarHandle.compareAndSet(Ljava/lang/Object;II)Z", VH_CAS_INT);
        CODES.put("java.lang.invoke.JPFFieldVarHandle.compareAndSet(Ljava/lang/Object;Ljava/lang/Object;Ljava/lang/Object;)Z", VH_CAS_OBJ);
        CODES.put("java.lang.invoke.JPFFieldVarHandle.setRelease(Ljava/lang/Object;I)V", VH_SETREL_INT);
        String S = "java.util.concurrent.SynchronousQueue";
        CODES.put(S + ".offer(Ljava/lang/Object;)Z", SQ_OFFER);
        CODES.put(S + ".poll(JLjava/util/concurrent/TimeUnit;)Ljava/lang/Object;", SQ_POLL_T);
        CODES.put(S + "$TransferStack.transfer(Ljava/lang/Object;ZJ)Ljava/lang/Object;", TS_TRANSFER);
        CODES.put(S + "$TransferStack.casHead(Ljava/util/concurrent/SynchronousQueue$TransferStack$SNode;Ljava/util/concurrent/SynchronousQueue$TransferStack$SNode;)Z", TS_CASHEAD);
        CODES.put(S + "$TransferStack$SNode.tryMatch(Ljava/util/concurrent/SynchronousQueue$TransferStack$SNode;)Z", SN_TRYMATCH);
        String L = "java.util.concurrent.LinkedBlockingQueue.";
        CODES.put(L + "offer(Ljava/lang/Object;)Z", LBQ_OFFER);
        CODES.put(L + "take()Ljava/lang/Object;", LBQ_TAKE);
        CODES.put(L + "poll(JLjava/util/concurrent/TimeUnit;)Ljava/lang/Object;", LBQ_POLL_T);
        CODES.put("java.util.concurrent.atomic.AtomicInteger.getAndIncrement()I", AI_GETINC);
        CODES.put("java.util.concurrent.atomic.AtomicInteger.getAndDecrement()I", AI_GETDEC);
        String A = "java.util.concurrent.ArrayBlockingQueue.";
        CODES.put(A + "offer(Ljava/lang/Object;)Z", ABQ_OFFER);
        CODES.put(A + "enqueue(Ljava/lang/Object;)V", ABQ_ENQ);
        CODES.put(A + "dequeue()Ljava/lang/Object;", ABQ_DEQ);
        String T = "java.util.concurrent.ThreadPoolExecutor";
        CODES.put(T + ".execute(Ljava/lang/Runnable;)V", TPE_EXECUTE);
        CODES.put(T + ".addWorker(Ljava/lang/Runnable;Z)Z", TPE_ADDWORKER);
        CODES.put(T + ".compareAndIncrementWorkerCount(I)Z", TPE_CAIWC);
        CODES.put(T + ".reject(Ljava/lang/Runnable;)V", TPE_REJECT);
        CODES.put(T + ".getTask()Ljava/lang/Runnable;", TPE_GETTASK);
        CODES.put(T + ".advanceRunState(I)V", TPE_ADVANCE);
        CODES.put(T + ".shutdown()V", TPE_SHUTDOWN);
        CODES.put(T + ".interruptIdleWorkers(Z)V", TPE_INTR_IDLE);
        CODES.put(T + "$Worker.unlock()V", W_UNLOCK);
        CODES.put(T + ".runWorker(Ljava/util/concurrent/ThreadPoolExecutor$Worker;)V", TPE_RUNWORKER);
        CODES.put(T + "$Worker.<init>(Ljava/util/concurrent/ThreadPoolExecutor;Ljava/lang/Runnable;)V", WORKER_INIT);
        CODES.put("java.util.ArrayList$Itr.<init>(Ljava/util/ArrayList;)V", ITR_INIT);
        CODES.put("java.util.ArrayList$Itr.hasNext()Z", ITR_HASNEXT);
        CODES.put("java.util.ArrayList$Itr.next()Ljava/lang/Object;", ITR_NEXT);
        CODES.put("java.util.ArrayList$Itr.checkForComodification()V", ITR_CHECK);
        CODES.put("java.util.ArrayList.add(Ljava/lang/Object;)Z", AL_ADD);
        CODES.put("java.util.ArrayList.add(Ljava/lang/Object;[Ljava/lang/Object;I)V", AL_ADD3);
        CODES.put("java.lang.Thread.interrupt()V", TH_INTERRUPT);
        CODES.put("java.lang.Thread.interrupted()Z", TH_INTERRUPTED);
        CODES.put("java.lang.Thread.sleep(J)V", TH_SLEEP);
        CODES.put("java.lang.Thread.sleep0(JI)V", TH_SLEEP0);
    }

    private final IdentityHashMap<MethodInfo, Integer> codeCache = new IdentityHashMap<>();

    private int code(MethodInfo mi) {
        Integer c = codeCache.get(mi);
        if (c == null) {
            String key = mi.getClassName() + "." + mi.getUniqueName();
            c = CODES.get(key);
            if (c == null) {
                // decision steps of Retryer.call: identified by name, the caller frame is checked later
                String n = mi.getName();
                String sig = mi.getSignature();
                if (n.equals("apply") && sig.equals("(Ljava/lang/Object;)Z")) c = DEC_APPLY;
                else if (n.equals("shouldStop") && sig.equals("(Lcom/github/rholder/retry/Attempt;)Z")) c = DEC_SHOULDSTOP;
                else if (n.equals("computeSleepTime") && sig.equals("(Lcom/github/rholder/retry/Attempt;)J")) c = DEC_SLEEPTIME;
                else c = NONE;
            }
            codeCache.put(mi, c);
        }
        return c;
    }

    private static final String[] STATE_NAMES = {"NEW", "COMPLETING", "NORMAL", "EXCEPTIONAL", "CANCELLED",
            "INTERRUPTING", "INTERRUPTED"};

    private static String stateName(int s) {
        return (s >= 0 && s < STATE_NAMES.length) ? STATE_NAMES[s] : ("?" + s);
    }

    // ------------------------------------------------------------------
    // Per-path state
    // ------------------------------------------------------------------

    static final class Ev {
        final String name;
        final String tid;
        final int clock;
        final String ts;
        final LinkedHashMap<String, Object> f = new LinkedHashMap<>();
        final Set<String> pending = new LinkedHashSet<>();

        Ev(String name, String tid, int clock, String ts) {
            this.name = name;
            this.tid = tid;
            this.clock = clock;
            this.ts = ts;
        }

        Ev put(String k, Object v) {
            f.put(k, v);
            pending.remove(k);
            return this;
        }

        Ev open(String k) {
            pending.add(k);
            return this;
        }
    }

    static final class CallerSt {
        final String id;
        int threadRef;             // the thread running this caller's Retryer.call
        boolean started, done;
        Ev pendingClass, pendingCount, pendingMode, pendingNotify, pendingWrapStart;
        final List<Ev> pendingAttemptNo = new ArrayList<>();
        int curTask;               // limiter FutureTask of the current attempt
        String getKind;            // how get() ended in this attempt: RET | TO | IE
        int lastStateClock;
        String lastStateTs;
        int lastStateVal = -1;
        boolean lastStateIntr;
        int lastIntrClock;
        String lastIntrTs;
        int lastIntrState = -1;
        boolean lastIntrIntr;
        // submit decided earlier than its event (failed offer / worker-count CAS)
        int subClock;
        String subTs, subKind, subWorker;
        boolean subIntr;
        String lastAttemptClass;   // RA | EA
        boolean outerCancelled;

        CallerSt(String id) {
            this.id = id;
        }
    }

    static final class WorkerSt {
        final String id;
        int task;          // limiter FutureTask held
        String stage = "";
        Ev pendingMode, pendingTake;

        WorkerSt(String id) {
            this.id = id;
        }
    }

    static final class P {
        int clock;
        final List<Ev> events = new ArrayList<>();
        boolean recording, ended;
        int stepsAfterEnd;
        Map<String, Object> cfg = new LinkedHashMap<>();
        Set<String> cfgCallers = new HashSet<>(), cfgWrap = new HashSet<>(), cfgWrapOnPool = new HashSet<>();
        String stopKind = "";
        long delayLimitMs = -1;
        int limiterExec, listeners, retryer;
        final Map<Integer, String> taskId = new HashMap<>();
        final List<String> tasks = new ArrayList<>();
        final Map<Integer, String> outerTaskCaller = new HashMap<>();
        final Map<Integer, String> rcCaller = new HashMap<>();
        final Map<Integer, WorkerSt> workers = new HashMap<>(); // by thread object ref
        final List<String> workerIds = new ArrayList<>();
        final Map<String, String> outerWorkers = new TreeMap<>();
        final Map<Integer, String> snodeOwner = new HashMap<>();   // worker request node -> worker id
        final Map<Integer, String> fulfillOwner = new HashMap<>(); // caller fulfilling node -> caller id
        final Map<Integer, Integer> fulfillTask = new HashMap<>(); // caller fulfilling node -> FutureTask
        final Map<String, CallerSt> callers = new HashMap<>();
        final Map<Integer, Boolean> inSleep0 = new HashMap<>();
        // TV-exp: interrupter thread ref -> {event, target thread ref}; the target's flag is read
        // right after the first execution of the native Thread.interrupt()
        final Map<Integer, Object[]> pendingIntr = new HashMap<>();
        Ev openShutdown;
        final List<String> idleIntr = new ArrayList<>();
        String note = "";
    }

    private P p = new P();

    // ------------------------------------------------------------------
    // Search-facing API (TraceSearch)
    // ------------------------------------------------------------------

    private int pathNo;
    private int kept;
    private final Set<String> hashes = new HashSet<>();
    private final Set<String> features = new HashSet<>();
    private final Map<String, Integer> endReasons = new TreeMap<>();
    private final Map<String, Integer> eventCounts = new TreeMap<>();
    private int prefixes;
    private final long t0 = System.currentTimeMillis();

    void pathStarted(int n) {
        pathNo = n;
        p = new P();
    }

    /** True once the workload ended and the quiescence window has passed. */
    boolean pathComplete() {
        if (p.events.size() > maxEvents) {
            p.note = "max_events";
            return true;
        }
        if (!p.ended) return false;
        return ++p.stepsAfterEnd > quiesceSteps;
    }

    boolean enough() {
        return kept >= maxTraces;
    }

    void pathEnded(String why) {
        String reason = p.note.isEmpty() ? why : p.note;
        endReasons.merge(reason, 1, Integer::sum);
        if (!p.recording) return;
        List<Ev> evs = new ArrayList<>(p.events);
        evs.sort((a, b) -> Integer.compare(a.clock, b.clock));
        int cut = Integer.MAX_VALUE;
        for (Ev e : evs) {
            if (!e.pending.isEmpty()) {
                cut = Math.min(cut, e.clock);
            }
        }
        boolean prefix = cut != Integer.MAX_VALUE;
        List<Ev> out = new ArrayList<>();
        for (Ev e : evs) {
            if (e.clock < cut) out.add(e);
        }
        if (out.isEmpty()) return;
        // config line
        Map<String, Object> cfg = new LinkedHashMap<>();
        cfg.put("tag", "config");
        cfg.putAll(p.cfg);
        cfg.put("workers", new ArrayList<>(p.workerIds));
        cfg.put("tasks", new ArrayList<>(p.tasks));
        Map<String, Object> ow = new LinkedHashMap<>();
        for (Map.Entry<String, String> e : p.outerWorkers.entrySet()) {
            if (p.cfgWrapOnPool.contains(e.getKey())) ow.put(e.getKey(), e.getValue());
        }
        cfg.put("outerWorkers", ow);
        // event lines
        List<String> lines = new ArrayList<>();
        StringBuilder canon = new StringBuilder();
        for (Ev e : out) {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("tag", "trace");
            m.put("event", e.name);
            m.put("tid", e.tid);
            m.put("start", e.clock);
            m.put("end", e.clock);
            m.putAll(e.f);
            String noTs = Json.write(m);
            canon.append(noTs).append('\n');
            m.put("ts", e.ts);
            lines.add(Json.write(m));
        }
        canon.append(Json.write(cfg.get("workers"))).append(Json.write(cfg.get("tasks")));
        String h = sha1(canon.toString());
        if (!hashes.add(h)) return;
        Set<String> feats = features(out);
        boolean novel = false;
        for (String ft : feats) {
            if (!features.contains(ft)) {
                novel = true;
                break;
            }
        }
        if (kept >= maxTraces || (!novel && kept >= minTraces)) return;
        features.addAll(feats);
        kept++;
        if (prefix) prefixes++;
        for (Ev e : out) eventCounts.merge(e.name, 1, Integer::sum);
        cfg.put("workload", workload);
        cfg.put("path", pathNo);
        cfg.put("endReason", reason);
        cfg.put("prefix", prefix);
        Path f = outDir.resolve(String.format("%s-%03d.ndjson", workload, kept));
        try (Writer w = Files.newBufferedWriter(f, StandardCharsets.UTF_8)) {
            w.write(Json.write(cfg));
            w.write('\n');
            for (String l : lines) {
                w.write(l);
                w.write('\n');
            }
        } catch (IOException ex) {
            throw new RuntimeException(ex);
        }
        if (debug) System.out.println("[grtrace] wrote " + f + " (" + out.size() + " events, " + reason + (prefix ? ", prefix" : "") + ")");
    }

    private static Set<String> features(List<Ev> evs) {
        Set<String> s = new HashSet<>();
        Map<String, String> lastByTid = new HashMap<>();
        String prev = "^";
        for (Ev e : evs) {
            String kind = e.tid.startsWith("c") ? "C" : e.tid.startsWith("w") ? "W" : "E";
            StringBuilder d = new StringBuilder(e.name);
            for (String k : new String[]{"state", "attemptKind", "result", "mode", "sleep", "outcome", "expired",
                    "runner", "listener", "intr"}) {
                if (e.f.containsKey(k)) {
                    Object v = e.f.get(k);
                    if (k.equals("runner")) v = "none".equals(v) ? "none" : "w";
                    d.append(':').append(k).append('=').append(v);
                }
            }
            String detail = d.toString();
            s.add("E:" + detail);
            String lt = lastByTid.getOrDefault(e.tid, "^");
            s.add("T:" + kind + ":" + lt + ">" + e.name);
            lastByTid.put(e.tid, e.name);
            s.add("G:" + prev + ">" + e.name);
            prev = e.name;
        }
        return s;
    }

    private static String sha1(String s) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-1");
            byte[] d = md.digest(s.getBytes(StandardCharsets.UTF_8));
            StringBuilder sb = new StringBuilder();
            for (byte b : d) sb.append(String.format("%02x", b));
            return sb.toString();
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

    void writeSummary(int paths) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("workload", workload);
        m.put("paths", paths);
        m.put("distinctTraces", hashes.size());
        m.put("keptTraces", kept);
        m.put("keptPrefixes", prefixes);
        m.put("seconds", (int) ((System.currentTimeMillis() - t0) / 1000));
        m.put("endReasons", new LinkedHashMap<String, Object>(endReasons));
        m.put("eventCountsInKept", new LinkedHashMap<String, Object>(eventCounts));
        try {
            Files.write(summaryDir.resolve(workload + ".summary.json"),
                    (Json.write(m) + "\n").getBytes(StandardCharsets.UTF_8));
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
        System.out.println("[grtrace] " + Json.write(m));
    }

    // ------------------------------------------------------------------
    // Emission helpers
    // ------------------------------------------------------------------

    private int tick() {
        return ++p.clock;
    }

    private static String ts() {
        return Long.toString(System.nanoTime());
    }

    private Ev emit(String name, String tid) {
        return emitAt(name, tid, tick(), ts());
    }

    private Ev emitAt(String name, String tid, int clock, String ts) {
        Ev e = new Ev(name, tid, clock, ts);
        p.events.add(e);
        if (debug) System.out.println("[grtrace] path " + pathNo + " @" + clock + " " + tid + " " + name);
        return e;
    }

    private Ev callerEv(String name, CallerSt cs, ThreadInfo ti) {
        Ev e = emit(name, cs.id);
        e.put("attemptNo", attemptNo(ti));
        e.put("intr", ti.isInterrupted(false));
        return e;
    }

    private Ev workerEv(String name, WorkerSt ws, ThreadInfo ti) {
        Ev e = emit(name, ws.id);
        e.put("intr", ti.isInterrupted(false));
        return e;
    }

    // ------------------------------------------------------------------
    // Heap / stack helpers
    // ------------------------------------------------------------------

    private VM vm;

    private ElementInfo obj(int ref) {
        return ref <= 0 ? null : vm.getHeap().get(ref);
    }

    private int refField(int ref, String f) {
        ElementInfo ei = obj(ref);
        return ei == null ? 0 : ei.getReferenceField(f);
    }

    private int intField(int ref, String f) {
        return obj(ref).getIntField(f);
    }

    private String className(int ref) {
        ElementInfo ei = obj(ref);
        return ei == null ? "null" : ei.getClassInfo().getName();
    }

    private String threadName(ThreadInfo ti) {
        return ti.getName();
    }

    private String threadNameOfRef(int threadRef) {
        ThreadInfo t = vm.getThreadList().getThreadInfoForObjRef(threadRef);
        return t == null ? null : t.getName();
    }

    private StackFrame retryerFrame(ThreadInfo ti) {
        for (StackFrame f = ti.getTopFrame(); f != null; f = f.getPrevious()) {
            MethodInfo m = f.getMethodInfo();
            if (m != null && code(m) == R_CALL) return f;
        }
        return null;
    }

    private int attemptNo(ThreadInfo ti) {
        StackFrame f = retryerFrame(ti);
        return f == null ? -1 : f.getLocalVariable(4);
    }

    /** The caller whose Retryer.call runs on ti (null if none). */
    private CallerSt callerOf(ThreadInfo ti) {
        boolean inCall = false;
        int rc = 0;
        for (StackFrame f = ti.getTopFrame(); f != null; f = f.getPrevious()) {
            MethodInfo m = f.getMethodInfo();
            if (m == null) continue;
            int c = code(m);
            if (c == R_CALL) inCall = true;
            else if (c == RC_CALL) rc = f.getThis();
        }
        if (!inCall) return null;
        String id = null;
        if (rc != 0) id = p.rcCaller.get(rc);
        if (id == null && p.cfgCallers.contains(ti.getName()) && !p.cfgWrap.contains(ti.getName())) id = ti.getName();
        if (id == null) return null;
        CallerSt cs = caller(id);
        cs.threadRef = ti.getThreadObjectRef();
        return cs;
    }

    private CallerSt caller(String id) {
        return p.callers.computeIfAbsent(id, CallerSt::new);
    }

    private WorkerSt workerOf(ThreadInfo ti) {
        return p.workers.get(ti.getThreadObjectRef());
    }

    private boolean hasFrame(ThreadInfo ti, int code, int depth) {
        int i = 0;
        for (StackFrame f = ti.getTopFrame(); f != null && i < depth; f = f.getPrevious(), i++) {
            MethodInfo m = f.getMethodInfo();
            if (m != null && code(m) == code) return true;
        }
        return false;
    }

    private static int callerLine(StackFrame f) {
        Instruction pc = f == null ? null : f.getPC();
        return pc == null ? -1 : pc.getLineNumber();
    }

    private int frameCode(StackFrame f) {
        if (f == null || f.getMethodInfo() == null) return NONE;
        return code(f.getMethodInfo());
    }

    private boolean isLimiterQueue(int queueRef) {
        return p.limiterExec != 0 && refField(p.limiterExec, "workQueue") == queueRef;
    }

    // ------------------------------------------------------------------
    // Listener callbacks
    // ------------------------------------------------------------------

    @Override
    public void searchStarted(Search search) {
        vm = search.getVM();
    }

    @Override
    public void methodEntered(VM vm, ThreadInfo ti, MethodInfo mi) {
        int c = code(mi);
        if (c == NONE) return;
        this.vm = vm;
        switch (c) {
            case H_BEGIN: onBegin(ti); return;
            case H_WRAP: onWrapCaller(ti); return;
            case H_END: if (p.recording) p.ended = true; return;
            default: break;
        }
        if (!p.recording) return;
        switch (c) {
            case TH_SLEEP: p.inSleep0.put(ti.getThreadObjectRef(), false); break;
            case TH_SLEEP0: p.inSleep0.put(ti.getThreadObjectRef(), true); break;
            case TH_INTERRUPT: onInterruptCall(ti); break;
            case FT_INIT: onFutureTaskInit(ti); break;
            case FT_REPORT: onReport(ti); break;
            case TPE_REJECT: onReject(ti); break;
            case WORK_CALL: onWorkCall(ti); break;
            case M_RET: onModeEnter(ti, "Ret"); break;
            case M_RETBAD: onModeEnter(ti, "RetBad"); break;
            case M_EXC: onModeEnter(ti, "Exc"); break;
            case M_ERR: onModeEnter(ti, "Err"); break;
            case M_INTRRET: onModeEnter(ti, "IntrRet"); break;
            case M_INTRBLOCK: onModeEnter(ti, "IntrBlock"); break;
            case M_STUCK: onModeEnter(ti, "Stuck"); break;
            default: break;
        }
    }

    @Override
    public void methodExited(VM vm, ThreadInfo ti, MethodInfo mi) {
        if (!p.recording) return;
        int c = code(mi);
        if (c == NONE) return;
        this.vm = vm;
        switch (c) {
            case VH_CAS_INT: onCasInt(ti); break;
            case VH_CAS_OBJ: onCasObj(ti); break;
            case VH_SETREL_INT: onSetRelease(ti); break;
            case TH_INTERRUPTED: onInterrupted(ti); break;
            case TS_CASHEAD: onCasHead(ti); break;
            case SQ_OFFER: case ABQ_OFFER: onQueueOffer(ti); break;
            case AI_GETINC: onAtomicInc(ti); break;
            case AI_GETDEC: onAtomicDec(ti); break;
            case LBQ_TAKE: case LBQ_POLL_T: case ABQ_DEQ: onDequeued(ti); break;
            case TPE_CAIWC: onCaiwc(ti); break;
            case WORKER_INIT: onWorkerInit(ti); break;
            case TPE_ADDWORKER: onAddWorkerExit(ti); break;
            case TPE_GETTASK: onGetTaskExit(ti); break;
            case TPE_ADVANCE: onAdvanceRunState(ti); break;
            case TPE_SHUTDOWN: onShutdownExit(ti); break;
            case W_UNLOCK: onWorkerUnlock(ti); break;
            case ITR_NEXT: onItrNextExit(ti); break;
            case RA_INIT: case EA_INIT: onAttemptBuilt(ti, c); break;
            case RETRYEX_INIT3: onRetryExceptionBuilt(ti); break;
            case FT_RUN: onRunExit(ti); break;
            case DEC_APPLY: case DEC_SHOULDSTOP: case DEC_SLEEPTIME: onDecision(ti, c); break;
            default: break;
        }
    }

    @Override
    public void executeInstruction(VM vm, ThreadInfo ti, Instruction insn) {
        if (!p.recording || !(insn instanceof ATHROW)) return;
        MethodInfo mi = insn.getMethodInfo();
        if (mi == null) return;
        int c = code(mi);
        if (c == NONE) return;
        this.vm = vm;
        switch (c) {
            case M_EXC: onBodyEnd(ti, false, "CallableExc"); break;
            case M_ERR: onBodyEnd(ti, false, "CallableErr"); break;
            case TH_SLEEP: onSleepThrow(ti); break;
            default: break;
        }
    }

    @Override
    public void instructionExecuted(VM vm, ThreadInfo ti, Instruction next, Instruction insn) {
        if (!p.recording) return;
        MethodInfo mi = insn.getMethodInfo();
        if (mi == null) return;
        int c = code(mi);
        if (c == NONE) return;
        if (c == TH_INTERRUPT && insn.getClass().getSimpleName().equals("EXECUTENATIVE")) {
            this.vm = vm;
            onInterruptNativeDone(ti);
        }
        if (next == insn) return; // a choice point was set before this instruction; it re-executes next
        this.vm = vm;
        switch (c) {
            case R_CALL:
                if (insn instanceof ISTORE && ((ISTORE) insn).getLocalVariableIndex() == 4) onAttemptNoStore(ti);
                else if (insn instanceof IINC && ((IINC) insn).getIndex() == 4) onAttemptNoInc(ti);
                break;
            case FT_RUN:
                if (insn instanceof GETFIELD && ((GETFIELD) insn).getFieldName().equals("state")) onRunStateRead(ti, insn.getLineNumber());
                else if (insn instanceof PUTFIELD && ((PUTFIELD) insn).getFieldName().equals("runner")) onRunnerCleared(ti);
                break;
            case FT_HPCI:
                if (insn instanceof GETFIELD && ((GETFIELD) insn).getFieldName().equals("state")) onSpinRead(ti);
                break;
            case FT_CANCEL:
                if (insn instanceof GETFIELD) {
                    String fn = ((GETFIELD) insn).getFieldName();
                    if (fn.equals("state")) onCancelStateRead(ti);
                    else if (fn.equals("runner")) onCancelRunnerRead(ti);
                }
                break;
            case FT_GET_T:
            case FT_AWAIT:
                if (insn instanceof GETFIELD && ((GETFIELD) insn).getFieldName().equals("state")) {
                    int line = insn.getLineNumber();
                    if (c == FT_GET_T || line == 406 || line == 438) onGetStateRead(ti);
                } else if (insn instanceof IRETURN && c == FT_AWAIT && insn.getLineNumber() == 438) {
                    onAwaitDeadlineReturn(ti);
                }
                break;
            case ITR_INIT:
                if (insn instanceof GETFIELD && ((GETFIELD) insn).getFieldName().equals("modCount")) onItrInit(ti, (GETFIELD) insn);
                break;
            case ITR_CHECK:
                if (insn instanceof GETFIELD && ((GETFIELD) insn).getFieldName().equals("modCount")) onItrCheck(ti, (GETFIELD) insn);
                break;
            case ITR_HASNEXT:
                if (insn instanceof GETFIELD && ((GETFIELD) insn).getFieldName().equals("size")) onItrHasNext(ti, (GETFIELD) insn);
                break;
            case AL_ADD:
                if (insn instanceof PUTFIELD && ((PUTFIELD) insn).getFieldName().equals("modCount")) onAddModCount(ti, (PUTFIELD) insn);
                break;
            case AL_ADD3:
                if (insn instanceof PUTFIELD && ((PUTFIELD) insn).getFieldName().equals("size")) onAddSize(ti, (PUTFIELD) insn);
                break;
            case ABQ_ENQ:
                if (insn instanceof PUTFIELD && ((PUTFIELD) insn).getFieldName().equals("count")) onAbqCount(ti, (PUTFIELD) insn, true);
                break;
            case ABQ_DEQ:
                if (insn instanceof PUTFIELD && ((PUTFIELD) insn).getFieldName().equals("count")) onAbqCount(ti, (PUTFIELD) insn, false);
                break;
            case M_RET:
                if (insn instanceof ARETURN) onBodyEnd(ti, true, "Result");
                break;
            case M_RETBAD:
                if (insn instanceof ARETURN) onBodyEnd(ti, true, "BadResult");
                break;
            default:
                break;
        }
    }

    @Override
    public void exceptionThrown(VM vm, ThreadInfo ti, ElementInfo ex) {
        if (!p.recording) return;
        if (!ex.getClassInfo().getName().equals("java.lang.InterruptedException")) return;
        this.vm = vm;
        // IntrBlock: the InterruptedException raised by Object.wait() inside
        // Modes.intrBlock. JPF notifies a native's exception twice (with the
        // native frame on top, then with its caller on top): use the first.
        StackFrame top = ti.getTopFrame();
        MethodInfo tm = top == null ? null : top.getMethodInfo();
        if (tm == null || !tm.getClassName().equals("java.lang.Object") || !tm.getName().equals("wait")) return;
        if (frameCode(top.getPrevious()) == M_INTRBLOCK) onBodyEnd(ti, false, "CallableIE");
    }

    // ------------------------------------------------------------------
    // Markers
    // ------------------------------------------------------------------

    @SuppressWarnings("unchecked")
    private void onBegin(ThreadInfo ti) {
        StackFrame f = ti.getTopFrame();
        String json = obj(f.getLocalVariable(0)).asString();
        Map<String, Object> cfg = (Map<String, Object>) Json.parse(json);
        Object dl = cfg.remove("stopDelayMs");
        p.delayLimitMs = dl == null ? -1 : ((Number) dl).longValue();
        p.cfg = cfg;
        for (Object o : (List<Object>) cfg.get("callers")) p.cfgCallers.add((String) o);
        for (Object o : (List<Object>) cfg.get("wrapCallers")) p.cfgWrap.add((String) o);
        for (Object o : (List<Object>) cfg.get("wrapOnLimiterPool")) p.cfgWrapOnPool.add((String) o);
        p.stopKind = (String) cfg.get("stopKind");
        p.retryer = f.getLocalVariable(1);
        p.listeners = refField(p.retryer, "listeners");
        int limiter = refField(p.retryer, "attemptTimeLimiter");
        int exec = f.getLocalVariable(2);
        if (exec == 0 && limiter != 0 && className(limiter).endsWith("$FixedAttemptTimeLimit")) {
            exec = refField(refField(limiter, "timeLimiter"), "executor");
        }
        p.limiterExec = exec;
        p.recording = true;
        p.clock = 0;
    }

    private void onWrapCaller(ThreadInfo ti) {
        StackFrame f = ti.getTopFrame();
        String id = obj(f.getLocalVariable(0)).asString();
        p.rcCaller.put(f.getLocalVariable(1), id);
    }

    // ------------------------------------------------------------------
    // Retryer.call
    // ------------------------------------------------------------------

    /** Retryer.java:157 `attemptNumber = 1` (istore 4): CallStart of a direct caller. */
    private void onAttemptNoStore(ThreadInfo ti) {
        CallerSt cs = callerOf(ti);
        if (cs == null) return;
        if (p.cfgWrap.contains(cs.id)) {
            if (cs.pendingWrapStart != null) {
                cs.pendingWrapStart.put("attemptNo", attemptNo(ti));
                cs.pendingWrapStart = null;
            }
            return;
        }
        cs.started = true;
        callerEv("CallStart", cs, ti);
    }

    /** Retryer.java:157 `attemptNumber++`: the incremented value of BlockZero / SleepReturns. */
    private void onAttemptNoInc(ThreadInfo ti) {
        CallerSt cs = callerOf(ti);
        if (cs == null) return;
        int n = attemptNo(ti);
        for (Ev e : cs.pendingAttemptNo) e.put("attemptNo", n);
        cs.pendingAttemptNo.clear();
    }

    /** CallerBodyStart: entry of the workload callable on the caller (noTimeLimit). */
    private void onWorkCall(ThreadInfo ti) {
        StackFrame prev = ti.getTopFrame().getPrevious();
        if (frameCode(prev) != NOLIMIT_CALL) return;
        CallerSt cs = callerOf(ti);
        if (cs == null) return;
        cs.getKind = null;
        Ev e = callerEv("CallerBodyStart", cs, ti).open("mode");
        cs.pendingMode = e;
    }

    private void onModeEnter(ThreadInfo ti, String mode) {
        WorkerSt ws = workerOf(ti);
        if (ws != null && ws.pendingMode != null) {
            ws.pendingMode.put("mode", mode);
            ws.pendingMode = null;
            return;
        }
        CallerSt cs = callerOf(ti);
        if (cs != null && cs.pendingMode != null) {
            cs.pendingMode.put("mode", mode);
            cs.pendingMode = null;
        }
    }

    /** End commit point of a body: worker (FutureTask.run of a limiter task) or caller (noTimeLimit). */
    private void onBodyEnd(ThreadInfo ti, boolean returns, String result) {
        WorkerSt ws = workerOf(ti);
        if (ws != null && "BODY".equals(ws.stage) && hasFrame(ti, FT_RUN, 12)) {
            Ev e = emit(returns ? "BodyReturns" : "BodyThrows", ws.id);
            e.put("intr", ti.isInterrupted(false));
            e.put("task", p.taskId.get(ws.task));
            e.put("result", result);
            ws.stage = "BODYDONE";
            return;
        }
        CallerSt cs = callerOf(ti);
        if (cs != null && hasFrame(ti, NOLIMIT_CALL, 12)) {
            Ev e = callerEv(returns ? "CallerBodyReturns" : "CallerBodyThrows", cs, ti);
            e.open("attemptKind").open("expired");
            cs.pendingClass = e;
        }
    }

    private void onAttemptBuilt(ThreadInfo ti, int c) {
        CallerSt cs = callerOf(ti);
        if (cs == null) return;
        int att = ti.getTopFrame().getThis();
        String kind;
        if (c == RA_INIT) {
            cs.lastAttemptClass = "RA";
            int r = refField(att, "result");
            ElementInfo re = obj(r);
            kind = (re != null && re.getClassInfo().getName().equals("java.lang.String") && "bad".equals(re.asString()))
                    ? "BadResult" : "Result";
        } else {
            cs.lastAttemptClass = "EA";
            int ee = refField(att, "e");
            int cause = refField(ee, "cause");
            if (cause == ee) cause = 0;
            String cn = className(cause);
            if (cn.equals("com.google.common.util.concurrent.UncheckedTimeoutException")) kind = "Timeout";
            else if (cn.equals("java.util.concurrent.RejectedExecutionException")) kind = "Rejected";
            else if (cn.equals("java.lang.InterruptedException")) kind = "IE".equals(cs.getKind) ? "CallerIE" : "CallableIE";
            else if (isError(cause)) kind = "CallableErr";
            else kind = "CallableExc";
        }
        boolean expired = false;
        if ("AfterDelay".equals(p.stopKind) && p.delayLimitMs >= 0) {
            expired = obj(att).getLongField("delaySinceFirstAttempt") >= p.delayLimitMs;
        }
        if (cs.pendingClass != null) {
            cs.pendingClass.put("attemptKind", kind);
            cs.pendingClass.put("expired", expired);
            cs.pendingClass = null;
        }
    }

    private boolean isError(int ref) {
        ElementInfo ei = obj(ref);
        if (ei == null) return false;
        for (gov.nasa.jpf.vm.ClassInfo ci = ei.getClassInfo(); ci != null; ci = ci.getSuperClass()) {
            if (ci.getName().equals("java.lang.Error")) return true;
        }
        return false;
    }

    private void onRetryExceptionBuilt(ThreadInfo ti) {
        CallerSt cs = callerOf(ti);
        if (cs == null || cs.pendingCount == null) return;
        int re = ti.getTopFrame().getThis();
        cs.pendingCount.put("count", intField(re, "numberOfFailedAttempts"));
        if (cs.pendingCount.pending.contains("intr")) {
            // BlockInterrupted / SleepInterrupted: the status Retryer.java:180 restored
            cs.pendingCount.put("intr", ti.isInterrupted(false));
        }
        cs.pendingCount = null;
    }

    /** Return of the rejection predicate / stop strategy / wait strategy called by Retryer.call. */
    private void onDecision(ThreadInfo ti, int c) {
        StackFrame top = ti.getTopFrame();
        if (frameCode(top.getPrevious()) != R_CALL) return;
        CallerSt cs = callerOf(ti);
        if (cs == null) return;
        if (c == DEC_APPLY) {
            if (top.peek() == 0) {
                Ev e = callerEv("PredicateAccepts", cs, ti);
                e.put("outcome", "RA".equals(cs.lastAttemptClass) ? "Returned" : "ExecExc");
                cs.done = true;
            }
        } else if (c == DEC_SHOULDSTOP) {
            if (top.peek() != 0) {
                Ev e = callerEv("StopStrategyStops", cs, ti).open("count");
                cs.pendingCount = e;
                cs.done = true;
            }
        } else {
            long v = top.peekLong();
            Ev e = callerEv("WaitStrategyComputes", cs, ti);
            e.put("sleep", v < 0 ? "Negative" : v == 0 ? "Zero" : "Positive");
        }
    }

    // ------------------------------------------------------------------
    // Block step (JPF Thread.sleep model, JDK 11 JVM_Sleep semantics)
    // ------------------------------------------------------------------

    private void onSleepThrow(ThreadInfo ti) {
        StackFrame f = ti.getTopFrame();
        int ex = f.peek();
        if (!className(ex).equals("java.lang.IllegalArgumentException")) return;
        CallerSt cs = callerOf(ti);
        if (cs == null) return;
        callerEv("BlockNegative", cs, ti);
        cs.done = true;
    }

    private void onSleepCheck(ThreadInfo ti, StackFrame sleepFrame, boolean interrupted) {
        CallerSt cs = callerOf(ti);
        if (cs == null) return;
        boolean afterSleep = p.inSleep0.getOrDefault(ti.getThreadObjectRef(), false);
        if (!afterSleep) {
            if (interrupted) {
                Ev e = callerEv("BlockInterrupted", cs, ti).open("count").open("intr");
                cs.pendingCount = e;
                cs.done = true;
            } else {
                long millis = sleepFrame.getLongLocalVariable(0);
                if (millis == 0) {
                    Ev e = callerEv("BlockZero", cs, ti).open("attemptNo");
                    cs.pendingAttemptNo.add(e);
                } else {
                    callerEv("BlockSleepStart", cs, ti);
                }
            }
        } else {
            if (interrupted) {
                Ev e = callerEv("SleepInterrupted", cs, ti).open("count").open("intr");
                cs.pendingCount = e;
                cs.done = true;
            } else {
                Ev e = callerEv("SleepReturns", cs, ti).open("attemptNo");
                cs.pendingAttemptNo.add(e);
            }
        }
    }

    // ------------------------------------------------------------------
    // Thread.interrupt / Thread.interrupted
    // ------------------------------------------------------------------

    private void onInterruptCall(ThreadInfo ti) {
        StackFrame top = ti.getTopFrame();
        int target = top.getThis();
        if (target == 0 && top instanceof NativeStackFrame) {
            Object[] args = ((NativeStackFrame) top).getArguments();
            if (args != null && args.length > 1 && args[1] instanceof Integer) target = (Integer) args[1];
        }
        StackFrame prev = top.getPrevious();
        int pc = frameCode(prev);
        if (pc == FT_CANCEL) {
            int ft = prev.getThis();
            if (p.taskId.containsKey(ft)) {
                CallerSt cs = callerOf(ti);
                WorkerSt ws = p.workers.get(target);
                if (cs != null) {
                    Ev e = callerEv("CancelDoInterrupt", cs, ti);
                    e.put("task", p.taskId.get(ft));
                    e.put("target", ws == null ? "?" : ws.id);
                    e.open("targetIntr");
                    p.pendingIntr.put(ti.getThreadObjectRef(), new Object[]{e, target});
                }
                return;
            }
            String cid = p.outerTaskCaller.get(ft);
            if (cid != null) {
                CallerSt cs = caller(cid);
                // call() has started: the interrupt of the thread running it is
                // the commit point. A cancel after call() ended is outside the
                // model (ExitCall already completes the outer future).
                if (cs.started && !cs.done && !cs.outerCancelled) {
                    cs.outerCancelled = true;
                    Ev e = emit("CancelOuter", threadName(ti)).put("target", cid);
                    e.put("outerState", stateName(intField(ft, "state")));
                    e.open("targetIntr");
                    p.pendingIntr.put(ti.getThreadObjectRef(), new Object[]{e, target});
                }
                return;
            }
            return;
        }
        if (pc == TPE_INTR_IDLE && prev.getThis() == p.limiterExec && p.openShutdown != null) {
            WorkerSt ws = p.workers.get(target);
            p.idleIntr.add(ws == null ? "?" : ws.id);
            return;
        }
        if (target == ti.getThreadObjectRef()) return; // Retryer.java:180 re-sets its own status
        String name = threadNameOfRef(target);
        if (name != null && p.cfgCallers.contains(name) && !p.cfgWrap.contains(name)) {
            CallerSt cs = caller(name);
            if (!cs.done) {
                Ev e = emit("Interrupt", threadName(ti)).put("target", name);
                e.open("targetIntr");
                p.pendingIntr.put(ti.getThreadObjectRef(), new Object[]{e, target});
            }
        }
    }

    private void onInterrupted(ThreadInfo ti) {
        NativeStackFrame nf = (NativeStackFrame) ti.getTopFrame();
        boolean r = Boolean.TRUE.equals(nf.getReturnValue());
        StackFrame prev = nf.getPrevious();
        switch (frameCode(prev)) {
            case FT_AWAIT: {
                if (callerLine(prev) != 416) return;
                CallerSt cs = callerOf(ti);
                int ft = prev.getThis();
                if (cs == null || !p.taskId.containsKey(ft)) return;
                if (r) {
                    Ev e = callerEv("GetInterrupted", cs, ti);
                    e.put("task", p.taskId.get(ft));
                    e.put("state", stateName(intField(ft, "state")));
                    cs.getKind = "IE";
                } else {
                    cs.lastIntrClock = tick();
                    cs.lastIntrTs = ts();
                    cs.lastIntrState = intField(ft, "state");
                    cs.lastIntrIntr = ti.isInterrupted(false);
                }
                return;
            }
            case M_INTRRET:
                onBodyEnd(ti, !r, r ? "CallableIE" : "Result");
                return;
            case TH_SLEEP:
                onSleepCheck(ti, prev, r);
                return;
            case SQ_POLL_T: {
                // TV-exp: SynchronousQueue.poll found its node cancelled by the pending
                // interrupt and clears the status (SynchronousQueue.java:940) = WorkerPollCancel
                if (!r) return;
                WorkerSt ws = workerOf(ti);
                if (ws != null) workerEv("WorkerPollCancel", ws, ti);
                return;
            }
            default:
                return;
        }
    }

    // ------------------------------------------------------------------
    // FutureTask (limiter tasks, and the outer FutureTask of wrap() callers)
    // ------------------------------------------------------------------

    private void onFutureTaskInit(ThreadInfo ti) {
        StackFrame f = ti.getTopFrame();
        int ft = f.getThis();
        int callable = f.getLocalVariable(1);
        String cid = p.rcCaller.get(callable);
        if (cid != null) {
            p.outerTaskCaller.put(ft, cid);
            return;
        }
        if (!hasFrame(ti, STL_CALL, 6)) return;
        CallerSt cs = callerOf(ti);
        if (cs == null) return;
        String id = "t" + (p.tasks.size() + 1);
        p.tasks.add(id);
        p.taskId.put(ft, id);
        cs.curTask = ft;
        cs.getKind = null;
        cs.lastStateVal = -1;
        cs.lastIntrState = -1;
        cs.subKind = null;
        cs.subWorker = null;
    }

    private void onRunStateRead(ThreadInfo ti, int line) {
        StackFrame f = ti.getTopFrame();
        int ft = f.getThis();
        int s = f.peek();
        String task = p.taskId.get(ft);
        WorkerSt ws = workerOf(ti);
        if (task != null && ws != null) {
            if (line == 255) {
                ws.task = ft;
                Ev e = workerEv(s == 0 ? "WorkerRunTaskStart" : "WorkerRunTaskSkip", ws, ti);
                e.put("task", task);
                e.put("state", stateName(s));
                ws.stage = s == 0 ? "RUNCAS" : "";
            } else if (line == 260) {
                if (s == 0) {
                    Ev e = workerEv("BodyStart", ws, ti);
                    e.put("task", task);
                    e.open("mode");
                    ws.pendingMode = e;
                    ws.stage = "BODY";
                } else {
                    ws.stage = "SKIP";
                }
            } else if (line == 280) {
                if ("FINALLY".equals(ws.stage)) {
                    Ev e = workerEv(s == 5 ? "RunFinallySpin" : "RunFinallyExit", ws, ti);
                    e.put("task", task);
                    e.put("state", stateName(s));
                    ws.stage = s == 5 ? "SPIN" : "";
                }
            }
            return;
        }
        // wrap(): the outer FutureTask.run state check that lets RetryerCallable.call run
        String cid = p.outerTaskCaller.get(ft);
        if (cid != null && line == 260 && s == 0) {
            CallerSt cs = caller(cid);
            cs.started = true;
            Ev e = emit("CallStart", cid);
            e.open("attemptNo");
            e.put("intr", ti.isInterrupted(false));
            cs.pendingWrapStart = e;
            WorkerSt ws2 = workerOf(ti);
            if (ws2 != null) p.outerWorkers.put(cid, ws2.id);
        }
    }

    /** FutureTask.java:277 `runner = null`: BodySkip / SetCASLost commit points. */
    private void onRunnerCleared(ThreadInfo ti) {
        int ft = ti.getTopFrame().getThis();
        String task = p.taskId.get(ft);
        WorkerSt ws = workerOf(ti);
        if (task == null || ws == null) return;
        String ev;
        if ("SKIP".equals(ws.stage) || "INRUN".equals(ws.stage)) ev = "BodySkip";
        else if ("SETLOST".equals(ws.stage)) ev = "SetCASLost";
        else return;
        Ev e = workerEv(ev, ws, ti);
        e.put("task", task);
        e.put("state", stateName(intField(ft, "state")));
        ws.stage = "FINALLY";
    }

    private void onSpinRead(ThreadInfo ti) {
        StackFrame f = ti.getTopFrame();
        int ft = f.getThis();
        int s = f.peek();
        String task = p.taskId.get(ft);
        WorkerSt ws = workerOf(ti);
        if (task == null || ws == null || !"SPIN".equals(ws.stage) || s == 5) return;
        Ev e = workerEv("SpinExit", ws, ti);
        e.put("task", task);
        e.put("state", stateName(s));
        ws.stage = "";
    }

    private void onRunExit(ThreadInfo ti) {
        int ft = ti.getTopFrame().getThis();
        String cid = p.outerTaskCaller.get(ft);
        WorkerSt ws = workerOf(ti);
        if (cid == null || ws == null || !p.cfgWrapOnPool.contains(cid)) return;
        emit("OuterWorkerRelease", ws.id).put("caller", cid);
        p.outerWorkers.putIfAbsent(cid, ws.id);
    }

    private void onCancelStateRead(ThreadInfo ti) {
        StackFrame f = ti.getTopFrame();
        int ft = f.getThis();
        int s = f.peek();
        if (s == 0 || !p.taskId.containsKey(ft)) return;
        CallerSt cs = callerOf(ti);
        if (cs == null) return;
        Ev e = callerEv("CancelCASLost", cs, ti);
        e.put("task", p.taskId.get(ft));
        e.put("state", stateName(s));
        e.open("attemptKind").open("expired");
        cs.pendingClass = e;
    }

    private void onCancelRunnerRead(ThreadInfo ti) {
        StackFrame f = ti.getTopFrame();
        int ft = f.getThis();
        if (!p.taskId.containsKey(ft)) return;
        CallerSt cs = callerOf(ti);
        if (cs == null) return;
        int r = f.peek();
        WorkerSt ws = r == 0 ? null : p.workers.get(r);
        Ev e = callerEv("CancelReadRunner", cs, ti);
        e.put("task", p.taskId.get(ft));
        e.put("runner", r == 0 ? "none" : ws == null ? "?" : ws.id);
    }

    private void onCasInt(ThreadInfo ti) {
        NativeStackFrame nf = (NativeStackFrame) ti.getTopFrame();
        boolean r = Boolean.TRUE.equals(nf.getReturnValue());
        StackFrame prev = nf.getPrevious();
        int pc = frameCode(prev);
        if (pc == FT_CANCEL) {
            int ft = prev.getThis();
            if (p.taskId.containsKey(ft)) {
                CallerSt cs = callerOf(ti);
                if (cs == null) return;
                if (r) {
                    Ev e = callerEv("CancelCASWon", cs, ti);
                    e.put("task", p.taskId.get(ft));
                    e.put("state", stateName(intField(ft, "state")));
                } else {
                    Ev e = callerEv("CancelCASLost", cs, ti);
                    e.put("task", p.taskId.get(ft));
                    e.put("state", stateName(intField(ft, "state")));
                    e.open("attemptKind").open("expired");
                    cs.pendingClass = e;
                }
                return;
            }
            String cid = p.outerTaskCaller.get(ft);
            if (cid != null && r) {
                CallerSt cs = caller(cid);
                if (!cs.started && !cs.outerCancelled) {
                    cs.outerCancelled = true;
                    Ev e = emit("CancelOuter", threadName(ti)).put("target", cid);
                    e.put("outerState", stateName(intField(ft, "state")));
                }
            }
            return;
        }
        if (pc == FT_SET || pc == FT_SETEX) {
            int ft = prev.getThis();
            WorkerSt ws = workerOf(ti);
            if (ws == null || !p.taskId.containsKey(ft)) return;
            if (r) {
                Ev e = workerEv("SetCASWon", ws, ti);
                e.put("task", p.taskId.get(ft));
                e.put("state", stateName(intField(ft, "state")));
                ws.stage = "COMPLETING";
            } else {
                ws.stage = "SETLOST";
            }
        }
    }

    private void onCasObj(ThreadInfo ti) {
        NativeStackFrame nf = (NativeStackFrame) ti.getTopFrame();
        boolean r = Boolean.TRUE.equals(nf.getReturnValue());
        StackFrame prev = nf.getPrevious();
        int pc = frameCode(prev);
        if (pc == FT_RUN) {
            int ft = prev.getThis();
            WorkerSt ws = workerOf(ti);
            if (ws == null || !p.taskId.containsKey(ft) || !r) return;
            Ev e = workerEv("WorkerRunnerCAS", ws, ti);
            e.put("task", p.taskId.get(ft));
            ws.stage = "INRUN";
        } else if (pc == SN_TRYMATCH && r) {
            // SNode.tryMatch(s): the waiting request node m (this) is matched with
            // the fulfilling node s. The CAS is the hand-off's commit point; it is
            // executed by the offering caller, or by another thread that helps a
            // fulfiller (TransferStack.transfer, "help a fulfiller").
            int m = prev.getThis();
            int fs = prev.getLocalVariable(1);
            String cid = p.fulfillOwner.get(fs);
            if (cid == null) return;
            CallerSt cs = caller(cid);
            ThreadInfo cti = vm.getThreadList().getThreadInfoForObjRef(cs.threadRef);
            if (cti == null) return;
            String w = p.snodeOwner.get(m);
            Ev e = emit("SubmitHandoff", cs.id);
            e.put("attemptNo", attemptNo(cti));
            e.put("intr", cti.isInterrupted(false));
            e.put("task", p.taskId.get(p.fulfillTask.get(fs)));
            e.put("worker", w == null ? "unknown" : w);
            if (!ti.getName().equals(cti.getName()) && debug) {
                System.out.println("[grtrace] path " + pathNo + " hand-off of " + cid + " committed by " + ti.getName());
            }
        }
    }

    private void onSetRelease(ThreadInfo ti) {
        StackFrame top = ti.getTopFrame();
        StackFrame prev = top.getPrevious();
        int pc = frameCode(prev);
        if (pc == FT_CANCEL) {
            int ft = prev.getThis();
            if (!p.taskId.containsKey(ft)) return;
            CallerSt cs = callerOf(ti);
            if (cs == null) return;
            Ev e = callerEv("CancelFinish", cs, ti);
            e.put("task", p.taskId.get(ft));
            e.put("state", stateName(intField(ft, "state")));
            e.open("attemptKind").open("expired");
            cs.pendingClass = e;
        } else if (pc == FT_SET || pc == FT_SETEX) {
            int ft = prev.getThis();
            WorkerSt ws = workerOf(ti);
            if (ws == null || !p.taskId.containsKey(ft)) return;
            Ev e = workerEv("SetFinish", ws, ti);
            e.put("task", p.taskId.get(ft));
            e.put("state", stateName(intField(ft, "state")));
            ws.stage = "DONE";
        }
    }

    /** State reads of FutureTask.get(timeout) / awaitDone that may return a terminal state. */
    private void onGetStateRead(ThreadInfo ti) {
        StackFrame f = ti.getTopFrame();
        int ft = f.getThis();
        if (!p.taskId.containsKey(ft)) return;
        CallerSt cs = callerOf(ti);
        if (cs == null) return;
        cs.lastStateClock = tick();
        cs.lastStateTs = ts();
        cs.lastStateVal = f.peek();
        cs.lastStateIntr = ti.isInterrupted(false);
    }

    /** FutureTask.report entry from get(): the read that returned the terminal state was GetReturn. */
    private void onReport(ThreadInfo ti) {
        StackFrame top = ti.getTopFrame();
        if (frameCode(top.getPrevious()) != FT_GET_T) return;
        int ft = top.getThis();
        if (!p.taskId.containsKey(ft)) return;
        CallerSt cs = callerOf(ti);
        if (cs == null || cs.lastStateVal < 2) return;
        Ev e = emitAt("GetReturn", cs.id, cs.lastStateClock, cs.lastStateTs);
        e.put("attemptNo", attemptNo(ti));
        e.put("intr", cs.lastStateIntr);
        e.put("task", p.taskId.get(ft));
        e.put("state", stateName(cs.lastStateVal));
        e.open("attemptKind").open("expired");
        cs.pendingClass = e;
        cs.getKind = "RET";
    }

    /** awaitDone's deadline branch `return state` (FutureTask.java:438). */
    private void onAwaitDeadlineReturn(ThreadInfo ti) {
        StackFrame f = ti.getTopFrame(); // FutureTask.get, with the returned value pushed
        int s = f.peek();
        if (s > 1) return; // terminal: get() returns normally (GetReturn at the re-read)
        int ft = f.getThis();
        if (!p.taskId.containsKey(ft)) return;
        CallerSt cs = callerOf(ti);
        if (cs == null || cs.lastIntrState < 0) return;
        Ev e = emitAt("GetTimeout", cs.id, cs.lastIntrClock, cs.lastIntrTs);
        e.put("attemptNo", attemptNo(ti));
        e.put("intr", cs.lastIntrIntr);
        e.put("task", p.taskId.get(ft));
        e.put("state", stateName(cs.lastIntrState));
        cs.getKind = "TO";
    }

    // ------------------------------------------------------------------
    // Executor: submit decisions, workers, queues
    // ------------------------------------------------------------------

    private void onQueueOffer(ThreadInfo ti) {
        StackFrame top = ti.getTopFrame();
        if (top.peek() != 0) return; // accepted: handled at the hand-off / enqueue
        if (!isLimiterQueue(top.getThis()) || !hasFrame(ti, TPE_EXECUTE, 3)) return;
        CallerSt cs = callerOf(ti);
        if (cs == null) return;
        cs.subClock = tick();
        cs.subTs = ts();
        cs.subIntr = ti.isInterrupted(false);
        cs.subKind = "offerFailed";
        cs.subWorker = null;
    }

    private void onCaiwc(ThreadInfo ti) {
        StackFrame top = ti.getTopFrame();
        if (top.peek() == 0 || top.getThis() != p.limiterExec) return;
        if (!hasFrame(ti, TPE_EXECUTE, 4)) return;
        CallerSt cs = callerOf(ti);
        if (cs == null || cs.subKind != null) return;
        cs.subClock = tick();
        cs.subTs = ts();
        cs.subIntr = ti.isInterrupted(false);
        cs.subKind = "caiwc";
        cs.subWorker = null;
    }

    private void onWorkerInit(ThreadInfo ti) {
        int w = ti.getTopFrame().getThis();
        if (refField(w, "this$0") != p.limiterExec || p.limiterExec == 0) return;
        int thread = refField(w, "thread");
        if (thread == 0 || p.workers.containsKey(thread)) return;
        String id = "w" + (p.workerIds.size() + 1);
        p.workerIds.add(id);
        p.workers.put(thread, new WorkerSt(id));
        CallerSt cs = callerOf(ti);
        if (cs != null && cs.subKind != null) cs.subWorker = id;
    }

    private void onAddWorkerExit(ThreadInfo ti) {
        StackFrame top = ti.getTopFrame();
        if (top.getThis() != p.limiterExec) return;
        CallerSt cs = callerOf(ti);
        if (cs == null || cs.subKind == null || !hasFrame(ti, TPE_EXECUTE, 3)) return;
        if (top.peek() != 0 && cs.subWorker != null) {
            Ev e = emitAt("SubmitNewWorker", cs.id, cs.subClock, cs.subTs);
            e.put("attemptNo", attemptNo(ti));
            e.put("intr", cs.subIntr);
            e.put("task", p.taskId.get(cs.curTask));
            e.put("worker", cs.subWorker);
            cs.subKind = null;
            cs.subWorker = null;
        } else if ("caiwc".equals(cs.subKind)) {
            cs.subKind = null;
            cs.subWorker = null;
        }
    }

    private void onReject(ThreadInfo ti) {
        if (ti.getTopFrame().getThis() != p.limiterExec) return;
        CallerSt cs = callerOf(ti);
        if (cs == null) return;
        Ev e;
        // Saturated bounded pool: decided at the failed offer (the queue was
        // full; addWorker(command, false) then fails). Shut-down executor
        // (including an offer that failed before a concurrent shutdown, after
        // which addWorker fails on the run state): the reject call.
        boolean running = intField(refField(p.limiterExec, "ctl"), "value") < 0;
        if ("offerFailed".equals(cs.subKind) && running && "Bounded".equals(p.cfg.get("execKind"))) {
            e = emitAt("SubmitRejected", cs.id, cs.subClock, cs.subTs);
            e.put("attemptNo", attemptNo(ti));
            e.put("intr", cs.subIntr);
        } else {
            e = callerEv("SubmitRejected", cs, ti);
        }
        e.open("attemptKind").open("expired");
        cs.pendingClass = e;
        cs.subKind = null;
        cs.subWorker = null;
    }

    /** LinkedBlockingQueue count.getAndIncrement (offer) on a caller: SubmitQueued. */
    private void onAtomicInc(ThreadInfo ti) {
        StackFrame prev = ti.getTopFrame().getPrevious();
        if (frameCode(prev) != LBQ_OFFER) return;
        int q = prev.getThis();
        if (!isLimiterQueue(q)) return;
        CallerSt cs = callerOf(ti);
        if (cs == null || cs.curTask == 0) return;
        Ev e = callerEv("SubmitQueued", cs, ti);
        e.put("task", p.taskId.get(cs.curTask));
        e.put("queueLen", intField(refField(q, "count"), "value"));
    }

    /** LinkedBlockingQueue count.getAndDecrement (take / poll) on a worker: WorkerTake. */
    private void onAtomicDec(ThreadInfo ti) {
        StackFrame prev = ti.getTopFrame().getPrevious();
        int pc = frameCode(prev);
        if (pc != LBQ_TAKE && pc != LBQ_POLL_T) return;
        if (!isLimiterQueue(prev.getThis())) return;
        WorkerSt ws = workerOf(ti);
        if (ws == null) return;
        Ev e = workerEv("WorkerTake", ws, ti).open("task");
        ws.pendingTake = e;
    }

    /** ArrayBlockingQueue count++ (enqueue, caller) / count-- (dequeue, worker). */
    private void onAbqCount(ThreadInfo ti, PUTFIELD insn, boolean enq) {
        int q = insn.getLastThis();
        if (!isLimiterQueue(q)) return;
        if (enq) {
            CallerSt cs = callerOf(ti);
            if (cs == null || cs.curTask == 0 || !hasFrame(ti, TPE_EXECUTE, 4)) return;
            Ev e = callerEv("SubmitQueued", cs, ti);
            e.put("task", p.taskId.get(cs.curTask));
            e.put("queueLen", intField(q, "count"));
        } else {
            WorkerSt ws = workerOf(ti);
            if (ws == null) return;
            Ev e = workerEv("WorkerTake", ws, ti).open("task");
            ws.pendingTake = e;
        }
    }

    private void onDequeued(ThreadInfo ti) {
        WorkerSt ws = workerOf(ti);
        if (ws == null || ws.pendingTake == null) return;
        int r = ti.getTopFrame().peek();
        String task = p.taskId.get(r);
        if (r != 0 && task == null) {
            // not a limiter task (e.g. the outer wrap() task on the limiter pool): no event
            p.events.remove(ws.pendingTake);
            ws.pendingTake = null;
            return;
        }
        if (task == null) return;
        ws.pendingTake.put("task", task);
        ws.pendingTake = null;
    }

    /**
     * SynchronousQueue.TransferStack.casHead succeeded. Line 360: a node is
     * pushed to wait for a match; for a worker's poll (REQUEST mode) this is
     * WorkerPollBlock (matchable from here on). Line 373: an offering caller
     * pushes its fulfilling node; the hand-off itself is the later tryMatch.
     */
    private void onCasHead(ThreadInfo ti) {
        StackFrame top = ti.getTopFrame();
        if (top.peek() == 0) return;
        StackFrame prev = top.getPrevious();
        if (frameCode(prev) != TS_TRANSFER) return;
        int line = callerLine(prev);
        boolean request = prev.getLocalVariable(1) == 0; // transfer's e: null for poll/take
        if (line == 360 && request) {
            WorkerSt ws = workerOf(ti);
            if (ws == null || !hasFrame(ti, TPE_GETTASK, 6)) return;
            p.snodeOwner.put(top.getLocalVariable(2), ws.id);
            workerEv("WorkerPollBlock", ws, ti);
        } else if (line == 373 && !request) {
            CallerSt cs = callerOf(ti);
            if (cs == null || cs.curTask == 0 || !hasFrame(ti, TPE_EXECUTE, 6)) return;
            int node = top.getLocalVariable(2);
            p.fulfillOwner.put(node, cs.id);
            p.fulfillTask.put(node, cs.curTask);
        }
    }

    private void onGetTaskExit(ThreadInfo ti) {
        StackFrame top = ti.getTopFrame();
        if (top.getThis() != p.limiterExec || top.peek() != 0) return;
        WorkerSt ws = workerOf(ti);
        if (ws == null) return;
        emit("WorkerExit", ws.id);
    }

    private void onAdvanceRunState(ThreadInfo ti) {
        StackFrame top = ti.getTopFrame();
        if (top.getThis() != p.limiterExec || frameCode(top.getPrevious()) != TPE_SHUTDOWN) return;
        Ev e = emit("ExecutorShutdown", threadName(ti));
        int ctl = intField(refField(p.limiterExec, "ctl"), "value");
        int rs = ctl & ~((1 << 29) - 1);
        e.put("runState", rs == (-1 << 29) ? "RUNNING" : rs == 0 ? "SHUTDOWN" : "STOP+");
        e.open("idleIntr");
        p.openShutdown = e;
        p.idleIntr.clear();
    }

    private void onShutdownExit(ThreadInfo ti) {
        if (p.openShutdown == null || ti.getTopFrame().getThis() != p.limiterExec) return;
        p.openShutdown.put("idleIntr", new ArrayList<>(p.idleIntr));
        p.openShutdown = null;
    }

    /** TV-exp F1: runWorker's post-task w.unlock() (JDK11 TPE.java:1137) on a limiter worker. */
    private void onWorkerUnlock(ThreadInfo ti) {
        StackFrame prev = ti.getTopFrame().getPrevious();
        if (frameCode(prev) != TPE_RUNWORKER || callerLine(prev) != 1137) return;
        WorkerSt ws = workerOf(ti);
        if (ws != null) workerEv("WorkerUnlock", ws, ti);
    }

    /** TV-exp: read the target's interrupt flag right after Thread.interrupt() set it. */
    private void onInterruptNativeDone(ThreadInfo ti) {
        Object[] pe = p.pendingIntr.remove(ti.getThreadObjectRef());
        if (pe == null) return;
        Ev e = (Ev) pe[0];
        ThreadInfo t = vm.getThreadList().getThreadInfoForObjRef((Integer) pe[1]);
        e.put("targetIntr", t != null && t.isInterrupted(false));
    }

    // ------------------------------------------------------------------
    // Listener list (RetryerBuilder's ArrayList) and its iterator
    // ------------------------------------------------------------------

    private int listenerId(int ref) {
        ElementInfo ei = obj(ref);
        if (ei == null || !ei.getClassInfo().getName().equals("grwork.IdListener")) return -1;
        return ei.getIntField("id");
    }

    private void onItrInit(ThreadInfo ti, GETFIELD insn) {
        int list = insn.getLastThis();
        if (list != p.listeners) return;
        CallerSt cs = callerOf(ti);
        if (cs == null) return;
        Ev e = callerEv("ListenersBegin", cs, ti);
        e.put("modCount", ti.getTopFrame().peek());
        e.put("size", intField(list, "size"));
    }

    private void onItrCheck(ThreadInfo ti, GETFIELD insn) {
        int list = insn.getLastThis();
        if (list != p.listeners) return;
        if (frameCode(ti.getTopFrame().getPrevious()) != ITR_NEXT) return;
        CallerSt cs = callerOf(ti);
        if (cs == null) return;
        int itr = ti.getTopFrame().getThis();
        int mod = ti.getTopFrame().peek();
        int exp = intField(itr, "expectedModCount");
        if (mod == exp) {
            Ev e = callerEv("ListenerNotify", cs, ti).open("listener").open("cursor");
            cs.pendingNotify = e;
        } else {
            Ev e = callerEv("ListenerCME", cs, ti);
            e.put("modCount", mod);
            e.put("expectedModCount", exp);
            cs.done = true;
        }
    }

    private void onItrNextExit(ThreadInfo ti) {
        CallerSt cs = callerOf(ti);
        if (cs == null || cs.pendingNotify == null) return;
        StackFrame top = ti.getTopFrame();
        cs.pendingNotify.put("listener", listenerId(top.peek()));
        cs.pendingNotify.put("cursor", intField(top.getThis(), "cursor"));
        cs.pendingNotify = null;
    }

    private void onItrHasNext(ThreadInfo ti, GETFIELD insn) {
        int list = insn.getLastThis();
        if (list != p.listeners) return;
        CallerSt cs = callerOf(ti);
        if (cs == null) return;
        int size = ti.getTopFrame().peek();
        int cursor = intField(ti.getTopFrame().getThis(), "cursor");
        if (size != cursor) return; // hasNext true: part of ListenerNotify
        Ev e = callerEv("ListenersEnd", cs, ti);
        e.put("cursor", cursor);
        e.put("size", size);
    }

    private void onAddModCount(ThreadInfo ti, PUTFIELD insn) {
        int list = insn.getLastThis();
        if (list != p.listeners || callerOf(ti) != null) return;
        int elem = ti.getTopFrame().getLocalVariable(1);
        Ev e = emit("AddListenerBegin", threadName(ti));
        e.put("listener", listenerId(elem));
        e.put("modCount", intField(list, "modCount"));
    }

    private void onAddSize(ThreadInfo ti, PUTFIELD insn) {
        int list = insn.getLastThis();
        if (list != p.listeners || callerOf(ti) != null) return;
        int elem = ti.getTopFrame().getLocalVariable(1);
        Ev e = emit("AddListenerEnd", threadName(ti));
        e.put("listener", listenerId(elem));
        e.put("size", intField(list, "size"));
    }
}
