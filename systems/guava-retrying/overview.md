# guava-retrying

## Scope

[guava-retrying](https://github.com/rholder/guava-retrying) 2.0.0 (`177b6c9`), built against Guava 22.0. The studied module covers:

- the `Retryer.call` attempt loop;
- per-attempt time limits (`AttemptTimeLimiters.fixedTimeLimit` over Guava `SimpleTimeLimiter` and the JDK `ThreadPoolExecutor`);
- interrupts and cancellation, including `Retryer.wrap()`;
- the `RetryerBuilder`-to-`Retryer` handoff;
- the built-in stop, wait, and block strategies.

## Records

| Record | Contents | Findings |
| --- | --- | --- |
| [guava-retrying-opus55max-20261126](modules/retryer-attempt-lifecycle/runs/guava-retrying-opus55max-20261126/README.md) | Full pipeline run: analysis, TLA+ model, Java PathFinder trace harness and traces, model checking, confirmation, classification | 25 entries; 19 reproduced (15 new, 4 known) |
| [guava-retrying-tv-coverage-20261127](modules/retryer-attempt-lifecycle/runs/guava-retrying-tv-coverage-20261127/README.md) | Trace-validation coverage follow-up on copies of the first record's spec, harness, and traces | 1 spec error (F1); no new bugs |

## Reproduced bugs

| Finding | Summary | Status |
| --- | --- | --- |
| MC-1 | With `fixedTimeLimit`, a timed-out attempt keeps running alongside later attempts and after `call()` returns or throws | New |
| MC-2 | Timed-out attempts that ignore interrupts each pin a non-daemon thread of the two-argument `fixedTimeLimit`'s private pool; the JVM cannot exit | New |
| MC-4 | With `fixedTimeLimit`, an interrupt of the calling thread is swallowed: retrying continues and the interrupt status is lost | New |
| MC-5 | Without a time limit, an `InterruptedException` thrown by the callable is retried and the interrupt status is lost | Known ([re-retrying#32](https://github.com/rhuffman/re-retrying/issues/32)) |
| MC-6 | A `wrap()` task cancelled with `cancel(true)` or `shutdownNow()` keeps retrying and never releases its worker | Known ([re-retrying#32](https://github.com/rhuffman/re-retrying/issues/32)) |
| MC-7 | Adding a listener to the builder while a built `Retryer` runs makes `call()` throw `ConcurrentModificationException`; the attempt's outcome is lost | New |
| MC-9 | After the limiter's executor is shut down, `RejectedExecutionException` is recorded as the callable's failure | New |
| MC-10 | A negative computed sleep makes `call()` throw `IllegalArgumentException`, pre-empting the `RetryException` owed to an interrupted caller | New |
| MC-11 | A listener added to the builder after `build()` is notified by already-built Retryers | Known ([#48](https://github.com/rholder/guava-retrying/issues/48)) |
| MC-12 | The first attempt timeout ends retrying with `ExecutionException(UncheckedTimeoutException)` | Known ([#29](https://github.com/rholder/guava-retrying/issues/29)) |
| CR-D-11 | `fixedTimeLimit` accepts a zero or negative duration; every attempt then fails before the callable runs | New |
| CR-D-12 | Under `fixedTimeLimit`, the caller's stack is appended to a reused exception on every attempt, so the stack trace grows without bound | New |
| CR-D-13 | Under `fixedTimeLimit`, a `Throwable` that is neither `Exception` nor `Error` reaches predicates wrapped in `ExecutionException` | New |
| CR-D-16 | `WaitStrategies.join` overflows to a negative sleep | New |
| CR-D-17 | `exceptionWait` passes a negative value to `Thread.sleep` | New |
| CR-D-18 | An `exceptionWait` function returning `null` makes `call()` throw `NullPointerException` | New |
| CR-D-19 | The `int` attempt counter wraps after 2^31−1 attempts | New |
| CR-D-20 | `incrementingWait` overflows for increments near `Long.MAX_VALUE` | New |
| CR-D-22 | `stopAfterDelay` truncates its limit to whole milliseconds | New |

Other dispositions in the first record:

| Finding | Disposition |
| --- | --- |
| MC-3, MC-8, CR-5 | False positive |
| CR-D-21 | Masked |
| CR-D-15 ([#67](https://github.com/rholder/guava-retrying/issues/67)), CR-D-23 ([re-retrying#40](https://github.com/rhuffman/re-retrying/issues/40)) | Dropped as already reported |
