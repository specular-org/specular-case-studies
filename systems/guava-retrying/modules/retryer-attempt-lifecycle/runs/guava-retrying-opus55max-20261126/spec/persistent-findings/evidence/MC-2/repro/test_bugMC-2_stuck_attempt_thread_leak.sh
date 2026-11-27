#!/usr/bin/env bash
# MC-2 reproduction — a timed-out attempt that ignores interruption pins a pool thread of the
# private cached pool created by AttemptTimeLimiters.fixedTimeLimit(d, unit); every further
# timed-out attempt takes another thread; the threads outlive Retryer.call() and keep the JVM alive.
#
# Escalation level: 0 (pure black box). The library is compiled unmodified from the target
# checkout; the driver uses only public API (RetryerBuilder, AttemptTimeLimiters, StopStrategies,
# WaitStrategies, Retryer.call). The "stuck" callable is ordinary user code: a java.net.Socket read
# with no SO_TIMEOUT against a peer that accepts but never answers (Thread.interrupt() does not
# unblock it), or entering a monitor held by a hung thread. No sleeps are added to library code.
#
# Checks (each maps to the MC counterexample or the finding's stated consequence):
#   A  d3b  StuckBodiesPerCallAtMostOne — one call(), 2 timed-out attempts -> 2 pool threads pinned
#           (socket body and monitor body; JDK 21 and JDK 11)
#   B  d3a  StuckBodiesEndWithCall      — call() returns 42 while attempt 1 still pins a pool thread
#   C  JVM exit: main() returns normally; JVM with stuck bodies is still alive >= 95 s later
#           (beyond the 60 s cached-pool keep-alive that explains known issue #92), with controls:
#           C1 interruptible body (Thread.sleep) -> JVM exits ~60 s after main() (the #92 delay)
#           C2 stuck body but user-supplied daemon pool (3-arg overload) -> JVM exits at once
#   D  growth under the default neverStop: pinned threads grow ~linearly with attempts
#   E  same as D inside a cgroup with pids.max=200 (container-style task limit): thread creation
#           fails and call() fails with OutOfMemoryError "unable to create native thread"
#
# Exit status 0 = every bug check observed (bug reproduced); 1 = some check not observed.
set -u

SRC="${MC2_SRC:-/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-2/worktree}"
GUAVA="${GUAVA_JAR:-$HOME/.m2/repository/com/google/guava/guava/22.0/guava-22.0.jar}"
JSR305="${JSR305_JAR:-$HOME/.m2/repository/com/google/code/findbugs/jsr305/2.0.2/jsr305-2.0.2.jar}"
JAVA21="${JAVA21:-/usr/lib/jvm/java-21-openjdk-amd64/bin/java}"
JAVAC21="${JAVAC21:-/usr/lib/jvm/java-21-openjdk-amd64/bin/javac}"
JAVA11="${JAVA11:-/usr/lib/jvm/java-11-openjdk-amd64/bin/java}"
EXIT_WAIT="${MC2_EXIT_WAIT:-95}"          # seconds to watch a child JVM after its main() returned
BUILD="${MC2_BUILD_DIR:-$(mktemp -d /tmp/mc2-repro.XXXXXX)}"
mkdir -p "$BUILD/lib" "$BUILD/drv"

echo "== MC-2 repro  $(date -u +%FT%TZ)"
echo "source: $SRC  (git HEAD: $(git -C "$SRC" rev-parse --short HEAD 2>/dev/null || echo n/a), dirty files: $(git -C "$SRC" status --porcelain 2>/dev/null | wc -l))"
echo "guava:  $GUAVA ($(sha1sum "$GUAVA" | cut -c1-12))"
"$JAVA21" -version 2>&1 | head -1 | sed 's/^/java21: /'
[ -x "$JAVA11" ] && "$JAVA11" -version 2>&1 | head -1 | sed 's/^/java11: /'

# ---------------------------------------------------------------- build (unmodified library)
timeout 300 "$JAVAC21" --release 8 -Xlint:-options -nowarn -d "$BUILD/lib" -cp "$GUAVA:$JSR305" \
  $(find "$SRC/src/main/java" -name '*.java') || { echo "BUILD FAILED (library)"; exit 2; }

cat > "$BUILD/drv/MC2Driver.java" <<'JAVA'
import com.github.rholder.retry.*;
import java.io.InputStream;
import java.lang.management.ManagementFactory;
import java.net.*;
import java.util.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicInteger;

/** Public-API driver for MC-2. Only RetryerBuilder / AttemptTimeLimiters / Retryer.call are used. */
public class MC2Driver {
    // ---- a remote service that accepts connections and never answers (hung dependency)
    static final List<Socket> accepted = Collections.synchronizedList(new ArrayList<Socket>()); // keep peers open
    static ServerSocket server;
    static final Object HELD_LOCK = new Object();

    static void startHungServer() throws Exception {
        server = new ServerSocket(0, 2000, InetAddress.getLoopbackAddress());
        Thread acc = new Thread(() -> {
            try { while (true) accepted.add(server.accept()); } catch (Exception ignored) { }
        }, "hung-server-acceptor");
        acc.setDaemon(true);
        acc.start();
    }

    static void startLockHolder() throws Exception {      // e.g. a peer thread hung while holding a lock
        final CountDownLatch held = new CountDownLatch(1);
        Thread h = new Thread(() -> {
            synchronized (HELD_LOCK) {
                held.countDown();
                while (true) { try { Thread.sleep(Long.MAX_VALUE); } catch (InterruptedException ignored) { } }
            }
        }, "lock-holder");
        h.setDaemon(true);
        h.start();
        held.await();
    }

    // ---- per-attempt bookkeeping, filled in by the callable itself
    static final class Rec {
        final int no; final Thread thread; final int earlierStillRunning;
        volatile boolean ended; volatile String how = "";
        Rec(int no, Thread thread, int earlier) { this.no = no; this.thread = thread; this.earlierStillRunning = earlier; }
    }
    static final List<Rec> recs = new CopyOnWriteArrayList<Rec>();

    /** User code that blocks and does not respond to Thread.interrupt(). */
    static int body(String kind) throws Exception {
        if (kind.equals("socket")) {
            Socket s = new Socket(InetAddress.getLoopbackAddress(), server.getLocalPort()); // no SO_TIMEOUT
            InputStream in = s.getInputStream();
            return in.read();                    // blocks; an interrupt does not unblock a java.net.Socket read
        } else if (kind.equals("monitor")) {
            synchronized (HELD_LOCK) { return 1; } // monitor entry is not interruptible
        } else if (kind.equals("sleep")) {         // CONTROL: interruptible body
            Thread.sleep(3_600_000L);
            return 1;
        }
        throw new IllegalArgumentException(kind);
    }

    static Callable<Integer> callable(final String kind, final int succeedFrom) {
        final AtomicInteger n = new AtomicInteger();
        return () -> {
            int no = n.incrementAndGet();
            int running = 0;
            for (Rec r : recs) if (!r.ended) running++;
            Rec rec = new Rec(no, Thread.currentThread(), running);
            recs.add(rec);
            try {
                if (succeedFrom > 0 && no >= succeedFrom) { rec.how = "returned 42"; return 42; }
                int v = body(kind);
                rec.how = "returned " + v;
                return v;
            } catch (Exception e) {
                rec.how = "threw " + e; throw e;
            } catch (Error e) {
                rec.how = "threw " + e; throw e;
            } finally {
                rec.ended = true;
            }
        };
    }

    static int stuck() { int s = 0; for (Rec r : recs) if (r.thread.isAlive() && !r.ended) s++; return s; }
    static int poolThreads() {
        int n = 0;
        for (Thread t : Thread.getAllStackTraces().keySet()) if (t.isAlive() && t.getName().startsWith("pool-")) n++;
        return n;
    }
    static String frames(Thread t) {
        StackTraceElement[] st = t.getStackTrace();
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < st.length && i < 2; i++) sb.append(i == 0 ? "" : " <- ").append(st[i].getClassName()).append('.').append(st[i].getMethodName());
        for (StackTraceElement e : st) if (e.getClassName().startsWith("MC2Driver")) { sb.append(" ... ").append(e.getClassName()).append('.').append(e.getMethodName()).append(':').append(e.getLineNumber()); break; }
        return sb.toString();
    }
    static void census(String label) {
        for (Rec r : recs) {
            Thread t = r.thread;
            System.out.printf("    attempt %d on %-16s alive=%-5s daemon=%-5s interrupted=%-5s state=%-8s bodyFinished=%-5s earlierAttemptsStillRunningAtStart=%d %s%n",
                r.no, t.getName(), t.isAlive(), t.isDaemon(), t.isInterrupted(), t.getState(), r.ended, r.earlierStillRunning,
                r.ended ? "(" + r.how + ")" : "stack: " + frames(t));
        }
        System.out.printf("  %s: stuck attempt bodies holding pool threads = %d, live pool-* threads = %d%n", label, stuck(), poolThreads());
    }

    static Retryer<Integer> retryer(long limitMs, StopStrategy stop, ExecutorService userPool) {
        AttemptTimeLimiter<Integer> lim = userPool == null
            ? AttemptTimeLimiters.<Integer>fixedTimeLimit(limitMs, TimeUnit.MILLISECONDS)          // 2-arg overload (the finding)
            : AttemptTimeLimiters.<Integer>fixedTimeLimit(limitMs, TimeUnit.MILLISECONDS, userPool); // 3-arg overload (control)
        return RetryerBuilder.<Integer>newBuilder()
            .retryIfRuntimeException()                      // timeouts surface as UncheckedTimeoutException
            .withAttemptTimeLimiter(lim)
            .withStopStrategy(stop)
            .withWaitStrategy(WaitStrategies.noWait())      // the CE's "Zero" wait
            .build();
    }

    static String outcome(Retryer<Integer> r, Callable<Integer> c) {
        try {
            return "call() returned " + r.call(c);
        } catch (RetryException e) {
            return "call() threw RetryException after " + e.getNumberOfFailedAttempts() + " attempts, last cause = " + e.getLastFailedAttempt().getExceptionCause();
        } catch (ExecutionException e) {
            return "call() threw ExecutionException, cause = " + e.getCause();
        } catch (Throwable t) {
            return "call() threw " + t;
        }
    }

    public static void main(String[] a) throws Exception {
        String mode = a[0];
        String kind = a.length > 1 ? a[1] : "socket";
        if (kind.equals("monitor")) startLockHolder(); else startHungServer();

        if (mode.equals("d3b")) {                // CE hunt_s1_overlap_d3b: StuckBodiesPerCallAtMostOne
            Retryer<Integer> r = retryer(500, StopStrategies.stopAfterAttempt(2), null);
            System.out.println("  " + outcome(r, callable(kind, 0)));
            Thread.sleep(500);
            census("after call()");
            int s = stuck();
            System.out.println(s >= 2
                ? "  BUG[d3b/" + kind + "]: one call() left " + s + " stuck attempt bodies pinning " + s + " distinct pool threads (StuckBodiesPerCallAtMostOne requires <= 1)"
                : "  no-bug[d3b/" + kind + "]: stuck=" + s);
            System.exit(s >= 2 ? 0 : 1);

        } else if (mode.equals("d3a")) {         // CE hunt_s1_overlap_d3a: StuckBodiesEndWithCall
            Retryer<Integer> r = retryer(500, StopStrategies.stopAfterAttempt(3), null);
            String out = outcome(r, callable(kind, 2));
            System.out.println("  " + out);
            census("immediately after call() returned");
            int s = stuck();
            boolean bug = out.equals("call() returned 42") && s >= 1;
            System.out.println(bug
                ? "  BUG[d3a/" + kind + "]: call() returned 42 while " + s + " stuck body still holds pool thread " + recs.get(0).thread.getName() + " (StuckBodiesEndWithCall)"
                : "  no-bug[d3a/" + kind + "]: " + out + " stuck=" + s);
            System.exit(bug ? 0 : 1);

        } else if (mode.equals("exit")) {        // JVM exit after main() returns normally
            String pool = a[2];                     // "private" (2-arg overload) or "daemonpool" (3-arg, control)
            ExecutorService userPool = null;
            if (pool.equals("daemonpool")) {
                userPool = Executors.newCachedThreadPool(rr -> { Thread t = new Thread(rr, "pool-user-daemon"); t.setDaemon(true); return t; });
            }
            Retryer<Integer> r = retryer(500, StopStrategies.stopAfterAttempt(3), userPool);
            System.out.println("  " + outcome(r, callable(kind, 0)));
            Thread.sleep(300);
            census("after call()");
            final long t0 = System.nanoTime();
            Thread rep = new Thread(() -> {        // daemon reporter: does not keep the JVM alive
                while (true) {
                    try { Thread.sleep(15_000); } catch (InterruptedException e) { return; }
                    List<String> nd = new ArrayList<String>();
                    for (Thread t : Thread.getAllStackTraces().keySet())
                        if (t.isAlive() && !t.isDaemon() && !t.getName().equals("DestroyJavaVM")) nd.add(t.getName() + "/" + t.getState());
                    System.out.printf("  [+%ds after main() returned] stuck bodies=%d, live pool-* threads=%d, non-daemon threads=%s%n",
                        TimeUnit.NANOSECONDS.toSeconds(System.nanoTime() - t0), stuck(), poolThreads(), nd);
                    System.out.flush();
                }
            }, "reporter");
            rep.setDaemon(true);
            rep.start();
            System.out.println("  MAIN_RETURNING (main() returns normally, no System.exit)");
            System.out.flush();
            return;

        } else if (mode.equals("grow")) {        // default neverStop; sample pinned threads over time
            int seconds = Integer.parseInt(a[2]);
            final Retryer<Integer> r = retryer(50, StopStrategies.neverStop(), null);
            final Callable<Integer> c = callable(kind, 0);
            final String[] result = { null };
            Thread caller = new Thread(() -> { result[0] = outcome(r, c); }, "retry-caller");
            caller.setDaemon(true);
            caller.start();
            for (int i = 1; i <= seconds * 2; i++) {
                Thread.sleep(500);
                if (i % 2 == 0 || result[0] != null)
                    System.out.printf("  t=%4.1fs attempts=%4d stuck bodies=%4d live pool-* threads=%4d JVM threads=%4d%s%n",
                        i / 2.0, recs.size(), stuck(), poolThreads(), ManagementFactory.getThreadMXBean().getThreadCount(),
                        result[0] != null ? "  <- caller finished" : "");
                if (result[0] != null) break;
            }
            System.out.println("  caller: " + (result[0] == null ? "still retrying (neverStop)" : result[0]));
            System.out.flush();
            System.exit(0);
        }
        throw new IllegalArgumentException(mode);
    }
}
JAVA
timeout 300 "$JAVAC21" --release 8 -Xlint:-options -nowarn -cp "$BUILD/lib:$GUAVA:$JSR305" -d "$BUILD/drv" "$BUILD/drv/MC2Driver.java" \
  || { echo "BUILD FAILED (driver)"; exit 2; }
CP="$BUILD/lib:$BUILD/drv:$GUAVA:$JSR305"

FAIL=0
expect() {  # expect <label> <exit-code> : 0 means the bug condition was observed
  if [ "$2" -eq 0 ]; then echo "  => OBSERVED: $1"; else echo "  => NOT OBSERVED: $1 (rc=$2)"; FAIL=1; fi
}

# ---------------------------------------------------------------- A: d3b
for JV in 21 11; do
  JBIN=$JAVA21; [ "$JV" = 11 ] && JBIN=$JAVA11
  [ -x "$JBIN" ] || { echo "skip JDK $JV"; continue; }
  for KIND in socket monitor; do
    echo; echo "== A  d3b (StuckBodiesPerCallAtMostOne)  JDK $JV  body=$KIND  [fixedTimeLimit(500ms), stopAfterAttempt(2), noWait, retryIfRuntimeException]"
    timeout 60 "$JBIN" -cp "$CP" MC2Driver d3b "$KIND"; expect "A d3b JDK$JV $KIND" $?
  done
done

# ---------------------------------------------------------------- B: d3a
for JV in 21 11; do
  JBIN=$JAVA21; [ "$JV" = 11 ] && JBIN=$JAVA11
  [ -x "$JBIN" ] || continue
  echo; echo "== B  d3a (StuckBodiesEndWithCall)  JDK $JV  body=socket  [attempt 1 hangs, attempt 2 returns 42]"
  timeout 60 "$JBIN" -cp "$CP" MC2Driver d3a socket; expect "B d3a JDK$JV" $?
done

# ---------------------------------------------------------------- C: JVM exit (PID-based waits, hard deadlines)
echo; echo "== C  JVM exit after main() returns normally (watch each child JVM for up to ${EXIT_WAIT}s after main() returned)"
declare -A CPID CLOG
for V in stuck-private sleep-private stuck-daemonpool; do
  KIND=${V%%-*}; [ "$KIND" = stuck ] && KIND=socket
  POOL=${V#*-}
  CLOG[$V]="$BUILD/exit-$V.log"
  "$JAVA21" -cp "$CP" MC2Driver exit "$KIND" "$POOL" > "${CLOG[$V]}" 2>&1 &
  CPID[$V]=$!
done
declare -A T0 TEXIT
START=$(date +%s)
DEADLINE=$((START + EXIT_WAIT + 30))
while :; do
  NOW=$(date +%s); ALIVE=0
  for V in "${!CPID[@]}"; do
    if [ -z "${T0[$V]:-}" ] && grep -q MAIN_RETURNING "${CLOG[$V]}" 2>/dev/null; then T0[$V]=$NOW; fi
    if [ -z "${TEXIT[$V]:-}" ]; then
      if kill -0 "${CPID[$V]}" 2>/dev/null; then
        ALIVE=1
      else
        TEXIT[$V]=$NOW
      fi
    fi
  done
  [ "$ALIVE" -eq 0 ] && break
  DONE=1
  for V in "${!CPID[@]}"; do
    if [ -z "${TEXIT[$V]:-}" ]; then
      if [ -z "${T0[$V]:-}" ] || [ $((NOW - ${T0[$V]})) -lt "$EXIT_WAIT" ]; then DONE=0; fi
    fi
  done
  [ "$DONE" -eq 1 ] && break
  [ "$NOW" -ge "$DEADLINE" ] && break
  sleep 1
done
for V in stuck-private sleep-private stuck-daemonpool; do
  echo; echo "-- C/$V  ($( [ "$V" = stuck-private ] && echo 'the finding: 2-arg fixedTimeLimit, body ignores interrupts' ; [ "$V" = sleep-private ] && echo 'control C1: 2-arg fixedTimeLimit, interruptible body (known #92 delay)'; [ "$V" = stuck-daemonpool ] && echo 'control C2: 3-arg fixedTimeLimit with user daemon pool, body ignores interrupts'))"
  cat "${CLOG[$V]}"
  if [ -n "${TEXIT[$V]:-}" ]; then
    echo "  JVM EXITED $(( ${TEXIT[$V]} - ${T0[$V]:-${TEXIT[$V]}} ))s after main() returned"
  else
    echo "  JVM STILL ALIVE $(( $(date +%s) - ${T0[$V]:-$START} ))s after main() returned -> killed by harness"
    kill -9 "${CPID[$V]}" 2>/dev/null; wait "${CPID[$V]}" 2>/dev/null
  fi
done
[ -z "${TEXIT[stuck-private]:-}" ]; expect "C JVM with stuck bodies never exits (>= ${EXIT_WAIT}s after main returned)" $?
[ -n "${TEXIT[sleep-private]:-}" ]; echo "  control C1 exited: $([ -n "${TEXIT[sleep-private]:-}" ] && echo yes || echo no)"
[ -n "${TEXIT[stuck-daemonpool]:-}" ]; echo "  control C2 exited: $([ -n "${TEXIT[stuck-daemonpool]:-}" ] && echo yes || echo no)"

# ---------------------------------------------------------------- D: growth under neverStop
echo; echo "== D  growth under default neverStop  [fixedTimeLimit(50ms), noWait, retryIfRuntimeException]  JDK 21"
timeout 60 "$JAVA21" -cp "$CP" MC2Driver grow socket 5 | tee "$BUILD/grow.log"
GROWN=$(grep -E '^ +t= *5\.0s' "$BUILD/grow.log" | sed -E 's/.*stuck bodies= *([0-9]+).*/\1/')
[ "${GROWN:-0}" -ge 20 ]; expect "D stuck bodies grow with attempts (${GROWN:-0} pinned threads after 5 s)" $?

# ---------------------------------------------------------------- E: growth under a container-style task limit
echo; echo "== E  same workload in a cgroup with pids.max=200 (container-style task limit)  JDK 21"
if timeout 20 systemd-run --user --scope -p TasksMax=200 --quiet true 2>/dev/null; then
  timeout 90 systemd-run --user --scope -p TasksMax=200 --quiet \
    "$JAVA21" -XX:+UseSerialGC -XX:-TieredCompilation -XX:CICompilerCount=1 -XX:-UsePerfData \
    -cp "$CP" MC2Driver grow socket 30 2>&1 | tee "$BUILD/grow-capped.log"
  grep -q 'unable to create native thread' "$BUILD/grow-capped.log"; expect "E call() fails with OutOfMemoryError: unable to create native thread" $?
else
  echo "  systemd-run --user scope unavailable; E skipped"
fi

echo
if [ "$FAIL" -eq 0 ]; then echo "MC-2 RESULT: BUG REPRODUCED (all checks observed)"; else echo "MC-2 RESULT: some checks NOT observed"; fi
exit $FAIL
