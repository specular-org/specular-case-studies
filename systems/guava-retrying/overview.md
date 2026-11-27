# guava-retrying

## Scope

Specular studied [guava-retrying](https://github.com/rholder/guava-retrying) 2.0.0 (`177b6c9`), built against Guava 22.0. The study covers the `Retryer.call` attempt loop; per-attempt time limits (`AttemptTimeLimiters.fixedTimeLimit`, which runs each attempt through Guava's `SimpleTimeLimiter` on a JDK `ThreadPoolExecutor`); interrupts and cancellation, including `Retryer.wrap()` tasks on an executor; the `RetryerBuilder`-to-`Retryer` handoff; and the built-in stop, wait, and block strategies.

There are two records:

| Record | Contents |
| --- | --- |
| [guava-retrying-opus55max-20261126](modules/retryer-attempt-lifecycle/runs/guava-retrying-opus55max-20261126/README.md) | Full pipeline run (Claude Opus 5.5, max effort): analysis, TLA+ model, JPF trace harness, model checking, confirmation, classification |
| [guava-retrying-tv-coverage-20261127](modules/retryer-attempt-lifecycle/runs/guava-retrying-tv-coverage-20261127/README.md) | Trace-validation follow-up: strict coverage measurement, recorder read-backs, new JPF workloads, real-HotSpot traces, one spec fix |

## Trace validation with Java PathFinder

This is the first Specular study whose trace harness drives the implementation with Java PathFinder instead of instrumenting the source. It follows the approach of [lemmy/BlockingQueue](https://github.com/lemmy/BlockingQueue) (v40–v44) and [tlaplus/tlaplus#1405](https://github.com/tlaplus/tlaplus/pull/1405).

- **Harness.** JPF executes the unmodified library classes, Guava 22.0, and the JDK 11 `java.util.concurrent` classes. A JPF listener records commit points in the library, Guava, and the JDK as NDJSON events, and a random-walk search writes one trace per explored path. The 13 workloads correspond to the model-checking configurations. All 380 recorded traces replay against the final `Trace.tla`. See the [instrumentation guide](modules/retryer-attempt-lifecycle/runs/guava-retrying-opus55max-20261126/harness/INSTRUMENTATION.md).
- **jpf-core.** The harness uses [lemmy/jpf-core `mku-spurious`](https://github.com/lemmy/jpf-core/tree/mku-spurious) (`1432471`) with five JDK 11 model fixes. They are available as [patches](modules/retryer-attempt-lifecycle/runs/guava-retrying-opus55max-20261126/harness/patches/jpf-core/):
  1. A no-op native peer for `Reference.reachabilityFence`, which `Executors` wrappers call.
  2. `weakCompareAndSet` and `setRelease` on `JPFFieldVarHandle`, which `FutureTask` uses.
  3. The argument and interrupt checks of JDK 11 `Thread.sleep`.
  4. `interrupt()` of a sleeping thread now sets the interrupt flag; it was previously dropped.
  5. `wait()` with a pending interrupt now throws `InterruptedException`; it previously hung.
- **Spurious wakeups.** The `mku-spurious` policy did not apply here. It covers monitor `Object.wait()`, while the library, `SimpleTimeLimiter`, and the executor block in `LockSupport.park`.
- **Coverage.** The original harness reported 51/51 traced actions. Under a stricter rule, it covered 42/52 actions (80.8%). The rule counts an action only when a trace observes its effect in real code; an observation through a harness-written model or an inference in `Trace.tla` does not count. The follow-up added state read-backs, five workloads, and a real-HotSpot harness (JDK 11 and 21, library unmodified). That reached 53/53 actions over 1,343 accepted traces: 577 from JPF and 766 from HotSpot. Three deliberately mutated traces were rejected.
- **Spec error found by trace validation (F1).** After finishing a task, a `ThreadPoolExecutor` worker holds its `Worker` lock until `runWorker` releases it (JDK 11 `ThreadPoolExecutor.java:1137`). `shutdown()` therefore skips it when interrupting idle workers, but the model interrupted it. The final pipeline spec rejected 13 of 577 new JPF traces at `ExecutorShutdown`. The fix adds a release step. Re-running `MC.cfg` and the 13 hunting configurations on both specs produced identical violation chains.
- **JPF versus HotSpot.** All 766 HotSpot traces pass the same spec as the JPF traces. The harness's own JPF `Thread.sleep` model (patch 3) therefore agrees with real sleeps on JDK 11 and 21.

## Bugs

19 bugs reproduced: 15 new and 4 already known. Nothing has been reported upstream; the project has been inactive since 2016. The bugs fall into five groups.

**Interrupts are consumed as ordinary failures.** The cause is that `Retryer.java:162` catches `Throwable`.
- MC-4 (new): with `fixedTimeLimit`, an interrupt of the calling thread is swallowed. Retrying continues, `call()` can return normally or throw `ExecutionException`, and the interrupt status is lost.
- MC-5 (known, [re-retrying#32](https://github.com/rhuffman/re-retrying/issues/32)): without a time limit, an `InterruptedException` thrown by the callable is retried and the interrupt status is lost.
- MC-6 (known, same issue): a `wrap()` task cancelled with `cancel(true)` or `shutdownNow()` keeps retrying and never releases its worker.

**Time-limited attempts outlive their timeout.** Guava cancels a timed-out attempt but does not wait for it.
- MC-1: a timed-out attempt keeps running alongside later attempts and after `call()` has returned or thrown.
- MC-2: a timed-out attempt that ignores interrupts permanently holds a non-daemon thread of the two-argument `fixedTimeLimit`'s private pool. Threads accumulate with each attempt, and the JVM cannot exit. [#92](https://github.com/rholder/guava-retrying/issues/92) reports only the 60-second idle exit delay.

**The builder and its Retryers share one listener list.**
- MC-11 (known, [#48](https://github.com/rholder/guava-retrying/issues/48)): a listener added to the builder after `build()` is notified by already-built Retryers.
- MC-7 (new consequence of #48): adding a listener while a built `Retryer` runs makes `call()` throw `ConcurrentModificationException` after the attempt ran, and the attempt's outcome is lost.

**Outcomes are misattributed at the time limiter.**
- MC-12 (known, [#29](https://github.com/rholder/guava-retrying/issues/29)): the first timeout ends retrying unless the predicate matches Guava's `UncheckedTimeoutException`.
- MC-9: after the limiter's executor is shut down, `RejectedExecutionException` is recorded as the callable's failure.
- CR-D-11: `fixedTimeLimit` accepts a zero or negative duration, after which every attempt fails before the callable runs.
- CR-D-12: Guava's `throwCause(e, true)` appends the caller's stack trace to a reused exception on every attempt, so the stack trace grows without bound.
- CR-D-13: a `Throwable` that is neither an `Exception` nor an `Error` reaches predicates still wrapped in `ExecutionException`.

**Wait and stop arithmetic, and undocumented exits.**
- MC-10: a negative computed sleep makes `call()` throw `IllegalArgumentException`, which also pre-empts the `RetryException` owed to an interrupted caller.
- CR-D-16: `join` sums sleeps without overflow protection.
- CR-D-17: `exceptionWait` passes negative values to `Thread.sleep` unclamped.
- CR-D-18: an `exceptionWait` function returning `null` causes a `NullPointerException`.
- CR-D-19: the `int` attempt counter wraps after 2^31−1 attempts.
- CR-D-20: `incrementingWait` overflows for very large increments.
- CR-D-22: `stopAfterDelay` truncates its limit to whole milliseconds.

**Not counted.**
- MC-3 and MC-8 were false positives: the reached states are documented timeout and bounded-executor behavior. A repair round withdrew both.
- CR-5 was a false positive.
- CR-D-21 is masked.
- CR-D-15 (#67) and CR-D-23 ([re-retrying#40](https://github.com/rhuffman/re-retrying/issues/40)) were dropped as already reported.

## What model checking added

Model checking found no bug that code analysis had not already demonstrated. Phase 1 had hypothesized every model-checking finding and reproduced the concurrency defects with JVM probes before any spec existed; see [analysis-evidence/probes](modules/retryer-attempt-lifecycle/runs/guava-retrying-opus55max-20261126/analysis-evidence/probes/).

What model checking did add here:

- **Bounded negative results.**
  - A cancellation interrupt never reaches another task's body.
  - `RetryException` counts stay correct.
  - Interrupts that arrive during listeners, predicates, stop or wait computation, or the sleep are handled as documented.
  
  Together these narrow the interrupt bugs to the catch at `Retryer.java:162`.
- **A liveness counterexample** for MC-6, with a control configuration in which the property holds.

Two factors limited what model checking could contribute on this target. The concurrency is shallow: one caller, one or two workers, and first counterexamples within about 13–17 states. In addition, the guidance's priority questions named the suspected failure modes.
