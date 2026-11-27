# CR-D-11 — `fixedTimeLimit` accepts a zero or negative duration; attempts never run and are retried as callable failures

- **Source**: Code Review
- **Novelty**: NEW
- **Status**: REPRODUCED
- **Severity**: Medium
- **Location**: src/main/java/com/github/rholder/retry/AttemptTimeLimiters.java:57
- **Reproduction test**: `repro/test_bugCR-D-11_nonpositive_time_limit.sh` — escalation Level 0 (public API only)
- **Evidence**: `confirmation/CR-D-11/investigation.md`, `repro/CR-D-11.log`, `repro/CR-D-11.run2.log`, `repro/CR-D-11.fixcheck.log`

## Description

`AttemptTimeLimiters.fixedTimeLimit(duration, unit)` (`AttemptTimeLimiters.java:57-60`), its executor overload (`:69-72`) and the `FixedAttemptTimeLimit` constructor (`:97-103`) never check `duration > 0`, while every other parameterized built-in factory validates its numbers when it is called (`WaitStrategies.java:237`, `StopStrategies.java:103`, `:118`). Guava's `SimpleTimeLimiter.callWithTimeout` rejects a non-positive timeout with `IllegalArgumentException("timeout must be positive: d")` at `SimpleTimeLimiter.java:147` (`checkPositiveTimeout`, `:317-319`) before it submits the task (`:149`). `Retryer.call`'s `catch (Throwable)` (`Retryer.java:162-163`) then records that limiter error as the attempt's "exception thrown by the call". The callable never runs, but the retryer reports, retries and counts each attempt as a callable failure. With an exception-retry predicate and `neverStop()`, this repeats forever.

## Trigger scenario

1. Build `RetryerBuilder.<T>newBuilder().retryIfException().withAttemptTimeLimiter(AttemptTimeLimiters.<T>fixedTimeLimit(0, TimeUnit.MILLISECONDS)).build()`. The factory, `withAttemptTimeLimiter` and `build()` all accept it. A value `d <= 0` can come from a config value of `0` meant as "no timeout" (the JDK convention for `Socket.setSoTimeout`, `URLConnection.setConnectTimeout`, `Statement.setQueryTimeout` and `Thread.join`), from an unset numeric property, or from a computed remaining budget (`deadline - now`) that has reached 0. Real code passes config values straight into this factory; spring-retry issue 69 shows `fixedTimeLimit(config.getRetryTimeout(), TimeUnit.MILLISECONDS)` together with `retryIfException()`.
2. Call `retryer.call(callable)` or `executor.submit(retryer.wrap(callable))`.
3. Each attempt runs `Retryer.java:160` → `AttemptTimeLimiters.java:107` → `SimpleTimeLimiter.java:147`/`:318`, which throws the IAE before `executor.submit`. `Retryer.java:163` wraps it in `ExceptionAttempt(IAE)`, the listeners are notified, and the rejection predicate decides what happens next:
   - With the default predicate, `call()` throws `ExecutionException(IAE)` at `Retryer.java:171`.
   - With `retryIfException()` or `retryIfRuntimeException()` plus `stopAfterAttempt(N)`, it throws `RetryException("Retrying failed to complete successfully after N attempts.")` with `getNumberOfFailedAttempts()==N` (`:174`).
   - With the same predicates plus the builder defaults `neverStop()`/`noWait()`, or the README's "retry forever" examples (`neverStop()` with exponential or Fibonacci backoff), the loop at `:157-184` never ends.

## Developer intent

- Nothing in the project's history addresses non-positive durations. I reviewed all 106 rholder/guava-retrying issues and PRs, including PR #107 (closed 2026-09-05) and the PRs that touch `AttemptTimeLimiters` (#103, #95, #83). Targeted GitHub searches returned nothing, and the Specular case-study dataset has no guava-retrying entry. `fixedTimeLimit` was added in `7e474be` (dirkraft, 2013-01-16) with only `checkNotNull(timeUnit)`. Its Javadoc gives no valid range ("@param duration that an attempt may persist before being circumvented"), and no comment or test covers `0` or negative values.
- The observed outcomes contradict these documented contracts:
  - `Retryer.call`: "@throws ExecutionException if the given callable throws an exception…" (`Retryer.java:148-150`).
  - `Attempt`: "An attempt of a call, which resulted … in a Throwable thrown by the call"; `getExceptionCause()`: "Gets the exception thrown by the call".
  - `RetryException.numberOfFailedAttempts`: "times we've tried and failed".
- Design evidence: every other numeric built-in factory rejects bad values when constructed (`WaitStrategies.java:237, 254-255, 275, 294-296, 318-320`; `StopStrategies.java:103, 118`). Guava itself treats a non-positive timeout as an illegal argument, not as "time out immediately". Upstream #29 is a different mechanism: a real timeout that is not retried.
- Partial mitigation: with the default predicate, the error appears on the first `call()` with a readable message. It is still reported as the callable's `ExecutionException`, and it does not help configurations that retry on exceptions.

## Reproduction result

Escalation level 0: public API only, with no timing help, state injection or source change. The unmodified 2.0.0 source (`177b6c9`; `src/` identical to tag `v2.0.0`) was compiled with `javac --release 8` against Guava 22.0 and jsr305 2.0.2 and run on JDK 21.0.13. **PASS: the bug triggered every time.** Two full runs gave the same result (19/19 bug observations, 8/8 controls), and rebuilding the library against Guava 10.0.1, 14.0.1 and 16.0.1 also gave 19/19 on each version.

Command: `timeout 10m .specular-output/repro/test_bugCR-D-11_nonpositive_time_limit.sh` (exit 0; log `repro/CR-D-11.log`; repeat run `repro/CR-D-11.run2.log`).

```
== B1: fixedTimeLimit with a zero / negative duration is accepted at construction and build()
  [BUG    ] fixedTimeLimit(0, SECONDS) + RetryerBuilder.build(): accepted, no exception
  [BUG    ] fixedTimeLimit(0, SECONDS, userExecutor) + RetryerBuilder.build(): accepted, no exception
  [BUG    ] fixedTimeLimit(-1, SECONDS) + RetryerBuilder.build(): accepted, no exception
  [BUG    ] fixedTimeLimit(-1, SECONDS, userExecutor) + RetryerBuilder.build(): accepted, no exception
== B2: default rejection predicate -> call() throws ExecutionException(IAE) although the callable never ran
  [BUG    ] fixedTimeLimit(0, SECONDS) round 1: ExecutionException(cause=java.lang.IllegalArgumentException: timeout must be positive: 0), callable invocations=0, tasks submitted to user executor=n/a; cause thrown at:
        at com.google.common.base.Preconditions.checkArgument(Preconditions.java:191)
        at com.google.common.util.concurrent.SimpleTimeLimiter.checkPositiveTimeout(SimpleTimeLimiter.java:318)
        at com.google.common.util.concurrent.SimpleTimeLimiter.callWithTimeout(SimpleTimeLimiter.java:147)
        at com.github.rholder.retry.AttemptTimeLimiters$FixedAttemptTimeLimit.call(AttemptTimeLimiters.java:107)
        at com.github.rholder.retry.Retryer.call(Retryer.java:160)
        at CrD11Repro.main(CrD11Repro.java:175)
  [BUG    ] fixedTimeLimit(0, SECONDS) round 2: ExecutionException(cause=java.lang.IllegalArgumentException: timeout must be positive: 0), callable invocations=0, tasks submitted to user executor=n/a
  [BUG    ] fixedTimeLimit(-1, SECONDS, userExecutor) round 1: ExecutionException(cause=java.lang.IllegalArgumentException: timeout must be positive: -1), callable invocations=0, tasks submitted to user executor=0
== B3: retry predicate + stopAfterAttempt(5) + fixedWait(20ms) -> RetryException('after 5 attempts') with 0 runs
  [BUG    ] fixedTimeLimit(0, SECONDS) + retryIfException: RetryException("Retrying failed to complete successfully after 5 attempts."), getNumberOfFailedAttempts()=5, lastFailedAttempt.getExceptionCause()=java.lang.IllegalArgumentException: timeout must be positive: 0, listener saw 5 failed attempts, waited ~80 ms between them, callable invocations=0, tasks submitted to user executor=n/a
  [BUG    ] fixedTimeLimit(0, SECONDS, userExecutor) + retryIfRuntimeException: RetryException("Retrying failed to complete successfully after 5 attempts."), getNumberOfFailedAttempts()=5, lastFailedAttempt.getExceptionCause()=java.lang.IllegalArgumentException: timeout must be positive: 0, listener saw 5 failed attempts, waited ~80 ms between them, callable invocations=0, tasks submitted to user executor=0
== C4 control: retryIfException + builder defaults (neverStop, noWait), positive limit, callable fails twice then succeeds
  [CTRL ok] fixedTimeLimit(1, SECONDS): call() returned 'ok' after 3 attempts, callable invocations=3
== B4: same configuration with fixedTimeLimit(0, MILLISECONDS) -> call() never returns, busy-loops, callable never runs
  [BUG    ] fixedTimeLimit(0, MILLISECONDS) + retryIfException() + defaults neverStop()/noWait(): after 3000 ms call() has not returned (caller alive=true), attempts so far=828422, last attempt cause=java.lang.IllegalArgumentException: timeout must be positive: 0, callable invocations=0, tasks submitted to user executor=n/a, caller CPU time=2956 ms (98% of wall)
        (cleanup) after interrupting the caller: alive=false, call() ended with com.github.rholder.retry.RetryException: Retrying failed to complete successfully after 828621 attempts.
== B4b: README 'retry forever with exponential backoff' config + fixedTimeLimit(0, MILLISECONDS, userExecutor)
  [BUG    ] fixedTimeLimit(0, MILLISECONDS, userExecutor) + README: retryIfExceptionOfType(IOException).retryIfRuntimeException().exponentialWait(100, 5, MINUTES).neverStop(): after 3000 ms call() has not returned (caller alive=true), attempts so far=4, last attempt cause=java.lang.IllegalArgumentException: timeout must be positive: 0, callable invocations=0, tasks submitted to user executor=0, caller CPU time=0 ms (0% of wall)
== B5: Retryer.wrap() submitted to an executor (retryIfRuntimeException, neverStop, noWait, fixedTimeLimit(-1, SECONDS))
  [BUG    ] fixedTimeLimit(-1, SECONDS): Future of wrap(callable) not done after 2000 ms; pool thread made 523402 attempts; callable invocations=0
== C5 contrast: a positive but far-too-small limit is a real timeout AFTER submission (not an argument error)
  [CTRL ok] fixedTimeLimit(1, NANOSECONDS, userExecutor): ExecutionException(cause=com.google.common.util.concurrent.UncheckedTimeoutException), tasks submitted to user executor=1

SUMMARY: bug observations 19/19, controls ok 8/8
RESULT: BUG REPRODUCED
```

Excerpt from the primary run; `repro/CR-D-11.log` has every line.

How the output shows the bug:

- **B1** — the factory, `withAttemptTimeLimiter` and `build()` all accept the invalid duration.
- **B2** — `call()` throws `ExecutionException`. Its cause is thrown at `SimpleTimeLimiter.java:147` (reached from `Retryer.java:160`), with no frame from the callable, 0 invocations and 0 executor tasks. The same `Retryer` fails identically on a second call.
- **B3** — `RetryException` reports "5 attempts" and listeners see 5 failed attempts, but the callable ran 0 times.
- **B4/B5** — `call()` never returns: about 828k attempts in 3 s at 98% CPU on the caller, or about 523k attempts on a pool thread for `wrap()`, still with 0 invocations. Only the application's own interrupt ends the loop.

Expected behavior, shown by the controls:

- **C1/C4** — the same configurations with a positive limit run the callable and return. In C4, `neverStop` + `noWait` + `retryIfException` returns `'ok'` after 3 attempts.
- **C0** — the other factories reject bad values immediately.
- **C5** — a positive but tiny limit gives a real `UncheckedTimeoutException` after the task is submitted.

Fix check (`repro/CR-D-11.fixcheck.log`): I ran the script against a temporary copy of the source with one added line, `Preconditions.checkArgument(duration > 0L, …)`, in `FixedAttemptTimeLimit`. It exits 1 ("bug observations 0/4", every non-positive duration rejected at the factory call), and controls pass 6/6.

## Recommendation

Validate the duration up front in both `fixedTimeLimit` overloads, before the `SimpleTimeLimiter` is constructed (so the 2-arg form does not create a cached pool for a limiter it is about to reject):

```java
Preconditions.checkArgument(duration > 0L, "duration must be > 0 but is %s", duration);
```

Add the same check to the private `FixedAttemptTimeLimit` constructor as a second line of defense, and state the valid range in the Javadoc. Callers who want no limit should use `AttemptTimeLimiters.noTimeLimit()`; alternatively, the factory could map `0` to it if the "0 = no limit" convention is preferred. More generally, `Retryer.call` should not treat an exception that the time limiter throws before submitting the callable as the callable's outcome. That is the shared catch-all at `Retryer.java:162-163` mentioned in the dedup note, but the validation alone removes this trigger.
