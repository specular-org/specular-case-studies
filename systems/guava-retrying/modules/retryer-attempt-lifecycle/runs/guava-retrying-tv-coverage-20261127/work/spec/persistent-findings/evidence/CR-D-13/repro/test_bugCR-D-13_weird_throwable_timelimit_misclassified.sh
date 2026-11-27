#!/usr/bin/env bash
# CR-D-13 — Under AttemptTimeLimiters.fixedTimeLimit, a callable Throwable that is neither an
# Exception nor an Error reaches the retry predicates still wrapped in ExecutionException, so
# retryIfExceptionOfType(T) / retryIfException(Predicate) stop matching (and retryIfException()
# starts matching). Same configuration without a time limit behaves as documented.
#
# Escalation level: 0 (pure black-box). Only the public guava-retrying API is used
# (RetryerBuilder, AttemptTimeLimiters, StopStrategies, RetryListener, Retryer.call); the library
# source is compiled unmodified from the worktree; no sleeps, hooks, state injection or patches.
# The callable throws immediately, so no timeout is involved at all (the 5 s limit never fires).
#
# How the callable throws a non-Exception, non-Error Throwable (all three are ordinary user code;
# the target guidance says the callable "may ... throw any Throwable"):
#   T1 commons-lang3 ExceptionUtils.rethrow(Throwable)   (real third-party API, 3.8.1)
#   T2 Class.newInstance() on a constructor declaring the throwable (JDK-documented pass-through)
#   T3 generic sneaky throw (what Lombok @SneakyThrows compiles to; Kotlin/Groovy/Scala just `throw`)
#
# Exit status: 0 = bug reproduced (divergence observed, controls consistent),
#              1 = not reproduced, 2 = setup/build failure.
#
# Usage: timeout 10m ./test_bugCR-D-13_weird_throwable_timelimit_misclassified.sh
# Env overrides: SRC (guava-retrying checkout), GUAVA_JAR, JSR305_JAR, LANG3_JAR, JAVA_HOMES,
#                EXTRA_GUAVA_VERSIONS (supplementary runs against older Guava; "" to skip).
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="$(cd "$HERE/.." && pwd)"   # .specular-output
SRC="${SRC:-$OUT_DIR/confirmation/CR-D-13/worktree}"
M2="${M2:-$HOME/.m2/repository}"
GUAVA_JAR="${GUAVA_JAR:-$M2/com/google/guava/guava/22.0/guava-22.0.jar}"
JSR305_JAR="${JSR305_JAR:-$M2/com/google/code/findbugs/jsr305/2.0.2/jsr305-2.0.2.jar}"
LANG3_JAR="${LANG3_JAR:-$M2/org/apache/commons/commons-lang3/3.8.1/commons-lang3-3.8.1.jar}"
JAVA_HOMES="${JAVA_HOMES:-/usr/lib/jvm/java-21-openjdk-amd64 /usr/lib/jvm/java-11-openjdk-amd64}"
EXTRA_GUAVA_VERSIONS="${EXTRA_GUAVA_VERSIONS-16.0.1 14.0.1 10.0.1}"

fetch() { # groupId artifactId version -> path (download via Maven if absent)
  local g="$1" a="$2" v="$3" p
  p="$M2/$(echo "$g" | tr . /)/$a/$v/$a-$v.jar"
  if [ ! -f "$p" ] && command -v mvn >/dev/null 2>&1; then
    timeout 300 mvn -q dependency:get -Dartifact="$g:$a:$v" >/dev/null 2>&1 || true
  fi
  echo "$p"
}
[ -f "$GUAVA_JAR" ]  || GUAVA_JAR="$(fetch com.google.guava guava 22.0)"
[ -f "$JSR305_JAR" ] || JSR305_JAR="$(fetch com.google.code.findbugs jsr305 2.0.2)"
[ -f "$LANG3_JAR" ]  || LANG3_JAR="$(fetch org.apache.commons commons-lang3 3.8.1)"
for f in "$GUAVA_JAR" "$JSR305_JAR" "$LANG3_JAR"; do
  [ -f "$f" ] || { echo "SETUP FAILURE: missing jar $f"; exit 2; }
done
[ -d "$SRC/src/main/java/com/github/rholder/retry" ] || { echo "SETUP FAILURE: no guava-retrying source at $SRC"; exit 2; }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/crd13.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

echo "== CR-D-13 reproduction (Level 0, public API only)"
echo "source:  $SRC ($(git -C "$SRC" rev-parse --short HEAD 2>/dev/null || echo unknown-rev); dirty files: $(git -C "$SRC" status --porcelain 2>/dev/null | wc -l))"
echo "guava:   $GUAVA_JAR (sha256 $(sha256sum "$GUAVA_JAR" | cut -c1-16)...)"
echo "lang3:   $LANG3_JAR"

mkdir -p "$WORK/drv-src"
cat > "$WORK/drv-src/CRD13Repro.java" <<'JAVA'
import com.github.rholder.retry.Attempt;
import com.github.rholder.retry.AttemptTimeLimiter;
import com.github.rholder.retry.AttemptTimeLimiters;
import com.github.rholder.retry.RetryException;
import com.github.rholder.retry.RetryListener;
import com.github.rholder.retry.Retryer;
import com.github.rholder.retry.RetryerBuilder;
import com.github.rholder.retry.StopStrategies;
import com.google.common.base.Predicate;
import org.apache.commons.lang3.exception.ExceptionUtils;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.ThreadFactory;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

public class CRD13Repro {

    /** A Throwable that is neither an Exception nor an Error. */
    public static final class TransientFailure extends Throwable {
        public TransientFailure(String message) { super(message); }
    }
    /** Control: an Exception subclass. */
    public static final class TransientIOException extends IOException {
        public TransientIOException(String message) { super(message); }
    }
    /** Control: an Error subclass. */
    public static final class TransientError extends Error {
        public TransientError(String message) { super(message); }
    }
    /** Its constructor declares the checked throwable; Class.newInstance() propagates it unchanged. */
    public static final class FlakyResource {
        public FlakyResource() throws TransientFailure { throw new TransientFailure("thrown by FlakyResource()"); }
    }

    @SuppressWarnings("unchecked")
    static <T extends Throwable> void sneakyThrow(Throwable t) throws T { throw (T) t; }

    static final ExecutorService POOL = Executors.newCachedThreadPool(new ThreadFactory() {
        final AtomicInteger n = new AtomicInteger();
        @Override public Thread newThread(Runnable r) {
            Thread t = new Thread(r, "attempt-pool-" + n.incrementAndGet());
            t.setDaemon(true);
            return t;
        }
    });

    enum Limit {
        NONE("noTimeLimit()"),
        FIXED_POOL("fixedTimeLimit(5,SECONDS,pool)"),
        FIXED_DEFAULT("fixedTimeLimit(5,SECONDS)");
        final String label;
        Limit(String label) { this.label = label; }
        AttemptTimeLimiter<Object> create() {
            switch (this) {
                case NONE: return AttemptTimeLimiters.<Object>noTimeLimit();
                case FIXED_POOL: return AttemptTimeLimiters.<Object>fixedTimeLimit(5, TimeUnit.SECONDS, POOL);
                default: return AttemptTimeLimiters.<Object>fixedTimeLimit(5, TimeUnit.SECONDS);
            }
        }
    }

    interface Rule { String label(); void apply(RetryerBuilder<Object> b); }
    interface Trigger { String label(); Object fire(int invocation) throws Exception; }

    static Rule ofType(final Class<? extends Throwable> c) {
        return new Rule() {
            public String label() { return "retryIfExceptionOfType(" + c.getSimpleName() + ".class)"; }
            public void apply(RetryerBuilder<Object> b) { b.retryIfExceptionOfType(c); }
        };
    }
    static final Rule PREDICATE = new Rule() {
        public String label() { return "retryIfException(t -> t instanceof TransientFailure)"; }
        public void apply(RetryerBuilder<Object> b) {
            b.retryIfException(new Predicate<Throwable>() {
                public boolean apply(Throwable t) { return t instanceof TransientFailure; }
            });
        }
    };
    static final Rule ANY_EXCEPTION = new Rule() {
        public String label() { return "retryIfException()"; }
        public void apply(RetryerBuilder<Object> b) { b.retryIfException(); }
    };

    static final Trigger T1_LANG3 = new Trigger() {
        public String label() { return "T1 commons-lang3 ExceptionUtils.rethrow"; }
        public Object fire(int n) { return ExceptionUtils.<Object>rethrow(new TransientFailure("attempt " + n)); }
    };
    static final Trigger T2_NEW_INSTANCE = new Trigger() {
        public String label() { return "T2 Class.newInstance()"; }
        @SuppressWarnings("deprecation")
        public Object fire(int n) throws Exception { return FlakyResource.class.newInstance(); }
    };
    static final Trigger T3_SNEAKY = new Trigger() {
        public String label() { return "T3 generic sneaky throw"; }
        public Object fire(int n) { CRD13Repro.<RuntimeException>sneakyThrow(new TransientFailure("attempt " + n)); return null; }
    };
    static final Trigger IO_EXCEPTION = new Trigger() {
        public String label() { return "control: throw TransientIOException"; }
        public Object fire(int n) throws Exception { throw new TransientIOException("attempt " + n); }
    };
    static final Trigger ERROR = new Trigger() {
        public String label() { return "control: throw TransientError"; }
        public Object fire(int n) { throw new TransientError("attempt " + n); }
    };

    static final class Outcome {
        int invocations;
        long elapsedMs;
        Object returned;
        Throwable thrown;
        final List<String> listenerCauses = Collections.synchronizedList(new ArrayList<String>());
        /** Shape used to compare limiters: invocations + exception class chain. */
        String signature() { return "invocations=" + invocations + " thrown=" + classChain(thrown); }
    }

    static Outcome run(Limit limit, Rule rule, final Trigger trigger) {
        RetryerBuilder<Object> b = RetryerBuilder.<Object>newBuilder()
                .withStopStrategy(StopStrategies.stopAfterAttempt(3))
                .withAttemptTimeLimiter(limit.create());
        rule.apply(b);
        final Outcome o = new Outcome();
        b.withRetryListener(new RetryListener() {
            @Override public <V> void onRetry(Attempt<V> attempt) {
                o.listenerCauses.add("#" + attempt.getAttemptNumber() + " "
                        + (attempt.hasException() ? classChain(attempt.getExceptionCause()) : "result"));
            }
        });
        Retryer<Object> retryer = b.build();
        final AtomicInteger invocations = new AtomicInteger();
        long t0 = System.nanoTime();
        try {
            o.returned = retryer.call(new Callable<Object>() {
                @Override public Object call() throws Exception { return trigger.fire(invocations.incrementAndGet()); }
            });
        } catch (ExecutionException e) {
            o.thrown = e;
        } catch (RetryException e) {
            o.thrown = e;
        }
        o.elapsedMs = TimeUnit.NANOSECONDS.toMillis(System.nanoTime() - t0);
        o.invocations = invocations.get();
        return o;
    }

    static String name(Class<?> c) {
        return c.getEnclosingClass() == CRD13Repro.class ? c.getSimpleName() : c.getName();
    }
    static String classChain(Throwable t) {
        if (t == null) return "<none>";
        StringBuilder sb = new StringBuilder();
        for (Throwable x = t; x != null; x = x.getCause()) {
            if (sb.length() > 0) sb.append(" <- ");
            sb.append(name(x.getClass()));
        }
        return sb.toString();
    }
    static String describe(Outcome o) {
        String extra = "";
        if (o.thrown instanceof RetryException) {
            extra = " (getNumberOfFailedAttempts=" + ((RetryException) o.thrown).getNumberOfFailedAttempts() + ")";
        }
        return "invocations=" + o.invocations + " elapsed=" + o.elapsedMs + "ms thrown=" + classChain(o.thrown) + extra
                + " | thrown.getCause() instanceof TransientFailure=" + (o.thrown != null && o.thrown.getCause() instanceof TransientFailure)
                + " | listener saw getExceptionCause(): " + o.listenerCauses;
    }

    static int bugs = 0, controlFailures = 0, sanityFailures = 0;

    /** Runs one rule/trigger under noTimeLimit() and each given fixed limiter and compares the outcome shapes. */
    static void compare(String id, Rule rule, Trigger trigger, Limit[] limits, boolean control,
                        String expectNone) {
        System.out.println();
        System.out.println("[" + id + "] " + rule.label() + ", stopAfterAttempt(3), " + trigger.label());
        Outcome none = run(Limit.NONE, rule, trigger);
        System.out.println("   " + pad(Limit.NONE.label) + " -> " + describe(none));
        if (!none.signature().equals(expectNone)) {
            sanityFailures++;
            System.out.println("   !! unexpected baseline; expected " + expectNone);
        }
        for (Limit l : limits) {
            Outcome fixed = run(l, rule, trigger);
            boolean same = fixed.signature().equals(none.signature());
            System.out.println("   " + pad(l.label) + " -> " + describe(fixed));
            if (control) {
                System.out.println("   => " + (same ? "CONTROL OK: identical to noTimeLimit()" : "CONTROL FAILED: differs from noTimeLimit()"));
                if (!same) controlFailures++;
            } else {
                System.out.println("   => " + (same ? "no divergence" : "DIVERGES from noTimeLimit(): " + none.signature() + "  vs  " + fixed.signature()));
                if (!same) bugs++;
            }
        }
    }

    static String pad(String s) { StringBuilder b = new StringBuilder(s); while (b.length() < 30) b.append(' '); return b.toString(); }

    public static void main(String[] args) throws Exception {
        System.out.println("java.version=" + System.getProperty("java.version")
                + "  guava=" + com.google.common.util.concurrent.SimpleTimeLimiter.class.getProtectionDomain().getCodeSource().getLocation().getPath().replaceAll(".*/", "")
                + "  retrying=" + Retryer.class.getProtectionDomain().getCodeSource().getLocation().getPath());
        Limit[] fixedBoth = { Limit.FIXED_POOL, Limit.FIXED_DEFAULT };
        Limit[] fixedPool = { Limit.FIXED_POOL };
        String TF = "TransientFailure";
        String EE = "java.util.concurrent.ExecutionException";

        // Main defect: the configured retry predicate stops matching once a time limit is added.
        compare("A1", ofType(TransientFailure.class), T1_LANG3, fixedBoth, false,
                "invocations=3 thrown=com.github.rholder.retry.RetryException <- " + TF);
        compare("A2", ofType(TransientFailure.class), T2_NEW_INSTANCE, fixedPool, false,
                "invocations=3 thrown=com.github.rholder.retry.RetryException <- " + TF);
        compare("A3", ofType(TransientFailure.class), T3_SNEAKY, fixedPool, false,
                "invocations=3 thrown=com.github.rholder.retry.RetryException <- " + TF);
        // Same input reaches user Predicate<Throwable>.
        compare("B1", PREDICATE, T1_LANG3, fixedBoth, false,
                "invocations=3 thrown=com.github.rholder.retry.RetryException <- " + TF);
        // Inverse: retryIfException() (Exception.class) starts matching a non-Exception throwable.
        compare("C1", ANY_EXCEPTION, T1_LANG3, fixedBoth, false,
                "invocations=1 thrown=" + EE + " <- " + TF);
        // Controls: Exception and Error causes take throwCause's unwrap branches and are unaffected.
        compare("D1", ofType(TransientIOException.class), IO_EXCEPTION, fixedBoth, true,
                "invocations=3 thrown=com.github.rholder.retry.RetryException <- TransientIOException");
        compare("E1", ofType(TransientError.class), ERROR, fixedBoth, true,
                "invocations=3 thrown=com.github.rholder.retry.RetryException <- TransientError");

        // Root-cause path: the extra ExecutionException is the FutureTask one rethrown by SimpleTimeLimiter
        // (throwCause's "weird kind of Throwable" fallthrough), not one created by guava-retrying.
        Outcome a = run(Limit.FIXED_POOL, ofType(TransientFailure.class), T1_LANG3);
        Throwable inner = a.thrown == null ? null : a.thrown.getCause();
        System.out.println();
        System.out.println("[ROOT-CAUSE] fixedTimeLimit outcome: outer=" + (a.thrown == null ? "<none>" : a.thrown.getClass().getName())
                + " (created by Retryer.ExceptionAttempt), inner=" + (inner == null ? "<none>" : inner.getClass().getName())
                + ", inner.getCause()=" + (inner == null || inner.getCause() == null ? "<none>" : name(inner.getCause().getClass()))
                + ", inner.getCause() is Exception? " + (inner != null && inner.getCause() instanceof Exception)
                + ", is Error? " + (inner != null && inner.getCause() instanceof Error));
        boolean viaLimiter = false;
        if (inner != null) {
            System.out.println("   inner ExecutionException creation frames:");
            for (StackTraceElement f : inner.getStackTrace()) {
                String s = f.toString();
                if (s.contains("FutureTask") || s.contains("SimpleTimeLimiter") || s.contains("AttemptTimeLimiters") || s.contains("Retryer.call")) {
                    System.out.println("     at " + s);
                    if (s.contains("SimpleTimeLimiter.callWithTimeout")) viaLimiter = true;
                }
            }
        }
        if (!(inner instanceof ExecutionException) || !(inner.getCause() instanceof TransientFailure) || !viaLimiter) {
            sanityFailures++;
            System.out.println("   !! root-cause path not as expected");
        }

        System.out.println();
        System.out.println("SUMMARY java.version=" + System.getProperty("java.version") + ": divergences=" + bugs
                + " controlFailures=" + controlFailures + " baselineFailures=" + sanityFailures);
        if (bugs > 0 && controlFailures == 0 && sanityFailures == 0) {
            System.out.println("RESULT: BUG REPRODUCED - with fixedTimeLimit the callable's non-Exception/non-Error Throwable reaches the"
                    + " predicates as java.util.concurrent.ExecutionException; retryIfExceptionOfType/retryIfException(Predicate) stop"
                    + " retrying (1 invocation, ExecutionException(ExecutionException(t))) and retryIfException() starts retrying.");
            System.exit(0);
        }
        System.out.println("RESULT: NOT REPRODUCED (or inconsistent controls)");
        System.exit(1);
    }
}
JAVA

build_and_run() { # guava_jar label java_homes...
  local gjar="$1" label="$2"; shift 2
  local lib="$WORK/lib-$label" drv="$WORK/drv-$label" rc=0 jh
  mkdir -p "$lib" "$drv"
  if ! javac --release 8 -nowarn -g -encoding UTF-8 -cp "$gjar:$JSR305_JAR" -d "$lib" \
        $(find "$SRC/src/main/java" -name '*.java') 2> "$WORK/javac-lib-$label.log"; then
    echo "BUILD FAILURE (library vs $label):"; cat "$WORK/javac-lib-$label.log"; return 2
  fi
  if ! javac --release 8 -nowarn -g -encoding UTF-8 -cp "$lib:$gjar:$JSR305_JAR:$LANG3_JAR" -d "$drv" \
        "$WORK/drv-src/CRD13Repro.java" 2> "$WORK/javac-drv-$label.log"; then
    echo "BUILD FAILURE (driver vs $label):"; cat "$WORK/javac-drv-$label.log"; return 2
  fi
  for jh in "$@"; do
    [ -x "$jh/bin/java" ] || { echo "(skip: no JDK at $jh)"; continue; }
    echo
    echo "=================== run: $label on $("$jh/bin/java" -version 2>&1 | head -1)"
    echo "\$ timeout 120 $jh/bin/java -cp <lib>:<guava>:<jsr305>:<lang3>:<driver> CRD13Repro"
    timeout 120 "$jh/bin/java" -cp "$drv:$lib:$gjar:$JSR305_JAR:$LANG3_JAR" CRD13Repro
    local r=$?
    echo "(exit $r)"
    if [ $r -ne 0 ]; then rc=1; fi
  done
  return $rc
}

overall=0
build_and_run "$GUAVA_JAR" "guava-22.0" $JAVA_HOMES || overall=$?

# Supplementary (not required for the verdict): same unmodified source compiled against older Guava
# releases inside the declared range [10.+,), on the first JDK only.
first_jdk="${JAVA_HOMES%% *}"
for v in $EXTRA_GUAVA_VERSIONS; do
  gj="$M2/com/google/guava/guava/$v/guava-$v.jar"
  if [ -f "$gj" ]; then
    echo; echo "################ supplementary: Guava $v"
    build_and_run "$gj" "guava-$v" "$first_jdk" || echo "(supplementary Guava $v: non-zero result, see above)"
  else
    echo; echo "(supplementary Guava $v skipped: $gj not present)"
  fi
done

echo
if [ "$overall" -eq 0 ]; then
  echo "FINAL: BUG REPRODUCED on every primary run (Guava 22.0; JDKs: $JAVA_HOMES)"
else
  echo "FINAL: primary runs did not all reproduce (status $overall)"
fi
exit "$overall"
