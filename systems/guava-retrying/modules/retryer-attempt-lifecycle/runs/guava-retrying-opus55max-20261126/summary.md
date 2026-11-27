# Specular Summary

## Result

- Run status: **Complete**

Final confirmation recorded 19 reproduced bugs (15 new and 4 previously reported but still unfixed), 1 masked live finding, 0 environment-limited findings, 3 false positives and 2 dropped findings across 25 entries. The practical conclusion is that guava-retrying 2.0.0 does not reliably stop work it gives up on: time-limited attempts that ignore interrupts keep running and holding threads, interrupts and cancellation are often swallowed so retrying continues, and several reachable configurations end `call()` with undocumented exceptions, misattributed failures or wrong attempt accounting.

## Findings

- **MC-1 — A timed-out attempt keeps running alongside later attempts and after `call()` has returned or thrown** — Status: `REPRODUCED`. Impact: With a time limit, a callable that ignores interrupts can run at the same time as later attempts and keep running after `call()` has finished, so its result is discarded while its side effects still land, as when an application cache was reverted to an older value. Evidence: Exercised through the public API on the unmodified library against a deliberately slow local service on JDK 21 and JDK 11, while the same workload without a time limit stayed sequential.
- **MC-2 — A never-returning timed-out attempt pins a pool thread forever, and each further attempt takes another thread** — Status: `REPRODUCED`. Impact: Each timed-out attempt that ignores interrupts keeps a thread of the time limiter's private pool forever, so threads pile up with every retry until thread creation fails, and the JVM does not exit after `main()` returns. Evidence: Exercised through the public API with blocking-socket and lock-waiting callables on JDK 21 and JDK 11; thread exhaustion was shown under a container-style process limit.
- **MC-4 — A caller interrupt during a time-limited attempt is swallowed: retrying continues, `call()` returns normally or throws `ExecutionException`, and the interrupt status is lost** — Status: `REPRODUCED`. Impact: Interrupting a time-limited call does not stop it: retrying continues with the interrupt status lost, a completed attempt can be discarded and run again, and executor tasks keep calling the service after `Future.cancel(true)` or `shutdownNow()`. Evidence: Exercised through the public API with ordinary interrupts, Future cancellation and executor shutdown on JDK 21 and JDK 11; the discarded-completion cases used controlled timing inside the user callable, and the same callables without a time limit behaved as documented.
- **MC-5 — Without a time limit, an `InterruptedException` thrown by the callable on the caller thread is retried and the interrupt status is lost** — Status: `REPRODUCED`. Impact: Interrupting a call that has no time limit while the callable is blocked makes the retryer try again instead of stopping, loses the interrupt status, and leaves `shutdownNow()` unable to stop a wrapped task. Evidence: Exercised through the public API in 50 of 50 runs on JDK 21 and JDK 11, while an interrupt during the wait between attempts was handled as documented.
- **MC-6 — A `wrap()` task cancelled with `cancel(true)` / `shutdownNow()` keeps retrying forever (or returns normally), and its worker thread is never released** — Status: `REPRODUCED`. Impact: A cancelled or shut-down `wrap()` task with a retry-everything predicate keeps retrying under the default stop strategy, never frees its worker thread, blocks executor termination and JVM exit, or commits its side effect after the cancellation. Evidence: Exercised through the public API with a standard executor in 5 of 5 cancellation trials; the same setup with a predicate that does not retry the interruption exited normally.
- **MC-7 — Adding a listener to the builder while a built `Retryer` runs makes `call()` throw `ConcurrentModificationException` after the attempt executed; its outcome is lost** — Status: `REPRODUCED`. Impact: Registering a listener on the builder from another thread while a built retryer is running can make `call()` fail after the attempt already ran, losing its result and the retry decision. Evidence: Triggered through the public API without timing aids in 34–81% of uncoordinated trials; controlled timing inside a user listener made it deterministic.
- **MC-9 — After the limiter's executor is shut down, `RejectedExecutionException` is recorded as the callable's failure: `call()` throws `ExecutionException` though the callable never ran, or spins through attempts that never run** — Status: `REPRODUCED`. Impact: Once the executor given to the time limiter is shut down, `call()` reports the rejection as the callable's own failure and counts attempts that never ran, and with predicates that retry every exception it spins or waits without end. Evidence: Exercised through the public API with ordinary executor shutdown; the same calls with a running executor behaved as documented.
- **MC-10 — A negative computed sleep makes `call()` throw `IllegalArgumentException` — an undocumented outcome that also pre-empts the `RetryException` owed to an interrupted thread** — Status: `REPRODUCED`. Impact: A negative computed wait ends `call()` with `IllegalArgumentException` after the first failed attempt, abandoning a retry that would have succeeded and, on an interrupted thread, replacing the documented `RetryException`. Evidence: Exercised through the public API with built-in wait strategies on JDK 21 and JDK 11; one interrupt case used controlled timing inside a user listener, and non-negative waits gave the documented result.
- **MC-11 — (Known #48) A listener added to the builder after `build()` is notified by an already-built Retryer, including by a call already in flight** — Status: `REPRODUCED`. Impact: Reusing a builder as a template leaks later listeners into retryers already built from it, so one retryer's listener also counts another retryer's attempts for as long as that retryer lives. Evidence: The template-reuse case was exercised through the public API in a single thread; the in-flight cases used controlled timing inside the user callable.
- **MC-12 — (Known #29) The first attempt timeout ends retrying with `ExecutionException(UncheckedTimeoutException)` unless the predicate matches Guava's exception** — Status: `REPRODUCED`. Impact: Unless the retry predicate happens to match Guava's timeout exception, the first timed-out attempt ends `call()` with an `ExecutionException` instead of retrying under the configured stop and wait strategies. Evidence: Exercised through the public API with the library's default executor; the exact interleaving was reproduced by delaying worker start through a user thread factory.
- **CR-D-11 — `fixedTimeLimit` accepts a zero or negative duration; every attempt then fails with `IllegalArgumentException` before the callable runs and is treated as a callable failure** — Status: `REPRODUCED`. Impact: A zero or negative time limit is accepted, after which every call fails without running the callable or, with a retry-everything predicate and default settings, loops forever at nearly full CPU without ever running it. Evidence: Exercised through the public API on the unmodified library; the endless loop ended only when the test interrupted the caller.
- **CR-D-12 — Under `fixedTimeLimit`, Guava's `throwCause(e, true)` appends the caller's stack to the callable's exception on every attempt, so a reused exception's stack trace grows without bound** — Status: `REPRODUCED`. Impact: When a callable throws the same exception object again and again under a time limit, that exception keeps growing, steadily raising memory use, per-call time and log size until `call()` fails with an `OutOfMemoryError`. Evidence: Exercised through the public API on JDK 21 and JDK 11; out-of-memory was reached with a 32 MB heap, while controls without a time limit or with a fresh exception per attempt stayed flat.
- **CR-D-13 — Under `fixedTimeLimit`, a callable `Throwable` that is neither `Exception` nor `Error` reaches predicates still wrapped in `ExecutionException`, so `retryIfExceptionOfType` stops matching** — Status: `REPRODUCED`. Impact: For callables that throw such a `Throwable`, adding a time limit flips the retry decision: type-based rules stop retrying it and catch-all rules start retrying it. Evidence: Exercised through the public API with three ordinary ways of throwing such a `Throwable` on JDK 21 and JDK 11; `Exception` and `Error` controls behaved the same with and without a time limit.
- **CR-D-16 — `WaitStrategies.join` sums component sleeps without overflow protection; a total of 2^63 ms or more wraps negative and `call()` throws `IllegalArgumentException`** — Status: `REPRODUCED`. Impact: Joining a wait at or near `Long.MAX_VALUE` with any positive wait makes `call()` fail with `IllegalArgumentException` after the first failed attempt instead of waiting. Evidence: Exercised through the public API with the default block strategy on JDK 21 and JDK 11; the same large wait alone, or a saturating sum, waited as documented.
- **CR-D-17 — `exceptionWait` returns the user function's negative value unclamped; `Thread.sleep` then throws `IllegalArgumentException` out of `call()`** — Status: `REPRODUCED`. Impact: A negative value from an `exceptionWait` function, such as a server retry time that is already in the past because of clock skew, makes `call()` fail with `IllegalArgumentException` and abandon the remaining retries. Evidence: Exercised through the public API, including an end-to-end HTTP case with a server clock two seconds behind the client; a retry time in the future waited and succeeded.
- **CR-D-18 — `exceptionWait` with a function that returns `null` makes `call()` throw `NullPointerException` from auto-unboxing** — Status: `REPRODUCED`. Impact: An `exceptionWait` function that returns `null`, for example when an optional retry hint is absent, makes `call()` fail with `NullPointerException` and abandon retries that would have succeeded. Evidence: Exercised through the public API; the same retryer returned normally when the function produced a value.
- **CR-D-19 — The `int` attempt counter in `Retryer.call` wraps after 2^31-1 attempts: attempt numbers become non-positive, `RetryException` reports the count modulo 2^32, and growing waits collapse to 0** — Status: `REPRODUCED`. Impact: After more than 2^31−1 failed attempts in one call, listeners and strategies see zero or negative attempt numbers, `RetryException` reports a wrong count, and a decreasing wait strategy can sleep for 248.6 days instead of retrying. Evidence: The count and numbering errors were exercised through the public API with default settings after about an hour of continuous retrying; the long-sleep case used a contract-respecting user block strategy to speed up the run.
- **CR-D-20 — `incrementingWait` overflows `initial + increment * (n - 1)` for increments near `Long.MAX_VALUE`, alternating sleeps with immediate retries** — Status: `REPRODUCED`. Impact: With an increment close to `Long.MAX_VALUE`, waits shrink and every other retry happens immediately instead of backing off further. Evidence: Exercised through the public API with the default sleep strategy; ordinary increments grew as documented.
- **CR-D-21 — `fibonacciWait` overflow wraps to a positive value that the guard misses, so the sleep drops below the cap instead of growing up to the maximum** — Status: `MASKED`. Impact: After the wait reaches its maximum, an arithmetic overflow can make the computed wait drop under the cap again. Evidence: The drop was observed through the public API only with a block strategy that does not really sleep; with the built-in sleep strategy it lies behind at least 2^63−1 ms of designated sleep, realistic caps never produce it, and JDK 21's saturating sleep hides it.
- **CR-D-22 — `stopAfterDelay(d, unit)` truncates the delay to whole milliseconds, so a sub-millisecond limit becomes 0 ms and retrying stops after the first failed attempt** — Status: `REPRODUCED`. Impact: A stop limit under one millisecond gives no retries at all, and other limits stop up to one millisecond early. Evidence: Exercised through the public API in 1000 of 1000 calls, while a limit of exactly one millisecond retried and succeeded.
- Other dispositions: 5.

## Validation limits

- MC-1 and MC-2 depend on callables that ignore interrupts, such as blocking socket reads; interrupt-responsive callables did not show the overlap or the permanent thread pinning.
- The thread-exhaustion failure in MC-2 was shown under a container-style limit of 200 tasks, and the out-of-memory failure in CR-D-12 with a 32 MB heap.
- The endless or non-exiting outcomes in MC-2, MC-6, MC-9 and CR-D-11 were judged from bounded observation windows of 2 to 95 seconds.
- Some cases relied on controlled timing in user code rather than in the library: the discarded-completion cases of MC-4, the deterministic runs of MC-7, one interrupt case of MC-10, the in-flight cases of MC-11 and the exact interleaving of MC-12.
- CR-D-19 needs more than 2^31−1 failed attempts in one call; its long-sleep case used a user block strategy to speed up the run, the exponential-wait collapse was seen only with a simulated clock, and the Fibonacci and positive-increment collapses are practically unreachable.
- CR-D-16 and CR-D-20 need waits or increments near `Long.MAX_VALUE`, and CR-D-22 affects only limits with a sub-millisecond part.
- CR-D-21 remains masked: with the built-in sleep strategy the shorter wait lies behind at least 2^63−1 ms of designated sleep, realistic caps never produce it, and JDK 21's saturating sleep hides the difference.
- For CR-D-17, the estimate that one-second date precision alone can produce negative waits was not tested separately; the tested trigger was a skewed server clock.


## Run coverage

- Source analysis was skipped.
- Formal model generation was skipped.
- Execution trace collection was skipped.
- Trace validation and model checking were skipped.
- Independent reviews were not run.

## Run details

| Item | Value |
|---|---|
| Target | guava-retrying |
| Original source commit | 177b6c9b9f3e7957f404f0bdb8e23374cb1de43f |
| Current attempt source commit | 177b6c9b9f3e7957f404f0bdb8e23374cb1de43f |
| Agent / model | claude-code / claude-opus-5-5 |
| Reasoning effort | max |

## Detailed reports

- [Confirmation report](confirmed-bugs.md)
- [Severity report](bug-severity.md)

## Resource usage

| Phase | Runtime | Tokens | Estimated cost |
|---|---:|---:|---:|
| Phase 1 | 53m 31s | 60.8M total (58.4M cached) | $36.47 |
| Phase 2 | 1h 32m | 56.1M total (54.9M cached) | $25.92 |
| Phase 2.5 | 1h 3m | 59.1M total (58.2M cached) | $23.49 |
| Phase 3 | 1h 29m | 67.1M total (66.2M cached) | $22.92 |
| Phase 4a | 3h 20m | 202.3M total (192.7M cached) | $150.60 |
| Phase 4b | 22m 27s | 11.5M total (11.0M cached) | $7.93 |
| **Total** | 8h 41m | 456.9M total (441.3M cached) | $267.33 |

- Configured maximum parallelism: phase defaults (ordinary phases 1 at a time; per-finding confirmation 4 at a time)
- Configured TLC limits: auto memory; unbounded (report only) workers
