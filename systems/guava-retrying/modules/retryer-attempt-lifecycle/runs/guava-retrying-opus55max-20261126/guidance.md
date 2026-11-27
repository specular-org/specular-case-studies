# guava-retrying Modeling Guidance

## Required

### Goal

- Find real, reproducible defects in guava-retrying 2.0.0 that users of the published library can hit, with emphasis on the attempt lifecycle under per-attempt time limits, thread interruption, and sharing across threads. Separate new defects from the known upstream issues listed below.

### Scope

- In scope: all of `src/main/java/com/github/rholder/retry/` — `Retryer` (including `wrap`/`RetryerCallable`), `RetryerBuilder`, the built-in stop, wait, block and time-limit strategies, `Attempt`, and `RetryException` — plus Guava's `SimpleTimeLimiter` behavior insofar as `AttemptTimeLimiters` depends on it.
- Boundaries/exclusions: Guava is environment, not a target. Exclude build, packaging and dependency-resolution problems, and message-formatting, naming or API-ergonomics requests.

### Priority Questions

1. When a per-attempt time limit (`AttemptTimeLimiters.fixedTimeLimit`) expires — including when the callable ignores interruption or finishes at about the moment the limit fires — can a timed-out attempt keep running alongside later attempts or after `call()` has returned or thrown, can a finished attempt's result be discarded and its work repeated, or can worker threads outlive the retryer's use?
   Expected behavior: `Retryer` describes attempts as a sequence that ends when one succeeds or the stop strategy stops; `AttemptTimeLimiter` says a timed-out attempt "will possibly be interrupted". Determine which of these outcomes are reachable and whether the documentation admits them.
2. When the calling thread is interrupted — before or during an attempt (with and without a time limit), while listeners run, or while waiting between attempts — or when the callable itself throws `InterruptedException`, can `call()` keep retrying, return normally, or throw without the interrupt status set?
   Expected behavior: per the `Retryer.call` Javadoc, an interrupted thread gets a `RetryException` and its interrupt status is set.
3. When a `RetryerBuilder` is modified or reused after `build()` while a `Retryer` it built is executing on another thread, can that running call fail with an unexpected exception or notify a different set of listeners than was configured when it was built?
   Expected behavior: a `Retryer` may be shared across threads (class Javadoc; maintainer's answer in #35). #48 already reports the listener aliasing itself; this question asks whether it also breaks concurrent use.
4. Can `call()` end in any way other than its documented outcomes — for example, an exception escaping a built-in wait, stop or block step — and can `RetryException` report the wrong attempt count or last failure?
   Expected behavior: per the `Retryer.call` Javadoc, `call()` returns the result, throws `ExecutionException` wrapping the callable's exception when the rejection predicate accepts that attempt, or throws `RetryException` when the stop strategy aborts or the thread is interrupted.
5. At extreme attempt counts, durations or parameters, can a built-in wait strategy (alone or combined with `join`) yield a negative, decreasing or above-maximum sleep, or a built-in stop strategy stop too early or never?
   Expected behavior: each strategy behaves as its factory Javadoc states (for example, exponential and Fibonacci waits grow "up to the maximumTime"; `join` waits for the total of its strategies; `stopAfterAttempt` and `stopAfterDelay` stop once the attempt count or elapsed time since the first attempt reaches the limit).

### Must-cover Interactions

- `Retryer.call` ↔ `AttemptTimeLimiter` ↔ Guava `SimpleTimeLimiter` ↔ the user callable: submission to the executor, timeout, future cancellation and worker interruption, and how each outcome becomes an `Attempt`.
- `Retryer.call` ↔ rejection predicate, `StopStrategy`, `WaitStrategy`, `BlockStrategy`, `RetryListener`: the per-attempt decision order and the caller thread's interrupt status throughout.
- `RetryerBuilder` ↔ `Retryer`: what state is handed over at `build()` and what remains shared afterward.
- One `Retryer` (and one time limiter's executor) shared by several threads, directly or through `wrap()` on an executor.
- Consider: interrupts arriving at each step of the loop; timeout racing completion; callables that ignore interrupts, block forever, or throw `Error`s; user-supplied executors that are saturated or shut down.

### Assumptions

- The callable is arbitrary user code: it may ignore interrupts, block indefinitely, throw any `Throwable`, and have side effects. Re-running a failed attempt is intended; findings should concern overlapping attempts, lost or misattributed outcomes, interrupt handling, and thread/resource lifecycle, not the mere fact that a callable runs more than once.
- User-supplied strategies, predicates and listeners are assumed to honor their interface Javadoc; the built-in implementations are in scope.
- Build against Guava 22.0. The declared range `[10.+,)` resolves to Guava versions without the `SimpleTimeLimiter` constructors and four-argument `callWithTimeout` this library calls (both removed in Guava 23). The upstream Gradle 2.4 wrapper does not run on current JDKs; adapt the build setup, not the library source. A Maven build on JDK 21 with `--release 8`, Guava 22.0, jsr305 2.0.2, JUnit 4.11 and Mockito 1.9.5 compiles and passes all 36 existing tests.

## Optional

### Known Incidents and References

The project has been inactive since 2016; the issues below are open and unfixed. A finding that only restates one of them is known, not new.

- #48: builders share one mutable listener list with every `Retryer` they build.
- #92: a program using `fixedTimeLimit` does not exit promptly after `call()` returns.
- #29: an attempt timeout aborted retrying instead of being retried (reported against 1.0.6; check 2.0.0).
- #67: `Retryer.call` catches and wraps `Error`s.
- #94: incompatible with Guava 23 and later.

### Available Tools

- Java PathFinder (JPF) may be used in addition to ordinary tests to drive the implementation through bounded workloads. It systematically explores thread schedules and other nondeterministic choices, can inject runtime faults such as spurious wakeups, and its listeners can record traces at the JVM level without instrumenting the library source. Traces collected this way still go through Specula's trace validation.
- Prior work using this approach:
  - https://github.com/lemmy/BlockingQueue commits v40–v44: a JPF workload, listener-recorded public call/return and internal events, and TLA+ validation of every recorded execution prefix.
  - https://github.com/tlaplus/tlaplus/pull/1405: JPF verification of TLC's `DiskStateQueue`, including a spurious-wakeup scheduling policy.
  - https://github.com/lemmy/jpf-core/tree/mku-spurious: jpf-core branch that adds spurious wakeups for monitor waits.
- Environment (installed and smoke-tested on this machine):
  - JDK 11: `/usr/lib/jvm/java-11-openjdk-amd64` (the system default `java` remains JDK 21).
  - jpf-core: `/home/ubuntu/tools/jpf-core-mku-spurious`, jars in `build/`, registered in `~/.jpf/site.properties`. Branch `local/reachability-fence` is `mku-spurious` plus two local fixes needed by JDK 11 executors: a no-op native peer for `Reference.reachabilityFence`, and `weakCompareAndSet`/`setRelease` on `JPFFieldVarHandle` (used by `FutureTask`). If other JDK model gaps appear, fix them in that checkout and record the change.
  - The spurious-wakeup policy (`+vm.scheduler.sync.class=gov.nasa.jpf.vm.SpuriousWakeupSyncPolicy`) applies only to monitor `Object.wait()`; `LockSupport.park`, which `FutureTask` and `ThreadPoolExecutor` use, is excluded.
  - Working example: `/home/ubuntu/guava-retrying-20261126/jpf-smoke/` (runner `run.sh`, a single-threaded and a `fixedTimeLimit` workload, and a listener that records `Retryer.call` entry and exit). JPF explores `fixedTimeLimit` timeouts nondeterministically: the two-attempt time-limit workload reaches normal return, timeouts before the callable starts, and timeouts after it has run. A 60-second budget covered about 170,000 states without finishing.

### Suggested Starting Points

- `Retryer.java:155-185` (`call`), `RetryerBuilder.java:190-197` (`build`), `AttemptTimeLimiters.java:83-109` (`FixedAttemptTimeLimit`), `WaitStrategies.java`, `StopStrategies.java`.
