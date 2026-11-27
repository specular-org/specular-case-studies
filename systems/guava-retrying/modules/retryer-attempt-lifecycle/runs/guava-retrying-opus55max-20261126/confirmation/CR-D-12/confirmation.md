# CR-D-12 — fixedTimeLimit rewrites the callable's exception on every attempt; a reused exception's stack trace grows without bound

- **Source**: Code Review
- **Novelty**: NEW
- **Status**: REPRODUCED
- **Severity**: Medium
- **Location**: src/main/java/com/github/rholder/retry/AttemptTimeLimiters.java:107
- **Reproduction test**: `repro/test_bugCR-D-12_reused_exception_stack_growth.sh` — escalation Level 0 (public API only); output `repro/CR-D-12.log`
- **Investigation record**: `confirmation/CR-D-12/investigation.md`

## Description

`FixedAttemptTimeLimit.call` (`AttemptTimeLimiters.java:107`) runs every attempt through Guava's deprecated four-argument `SimpleTimeLimiter.callWithTimeout(callable, duration, unit, true)`. On failure that method executes `throw throwCause(e, true /* combineStackTraces */)` (`SimpleTimeLimiter.java:162-163`), and `throwCause` calls `cause.setStackTrace(concat(cause.getStackTrace(), e.getStackTrace()))` (`:256-259`). `cause` is the very object the user's callable threw, and `e.getStackTrace()` is the whole caller-thread stack at `future.get`. guava-retrying stores and rethrows that same object (`Retryer.java:162-163`, `:171`, `:174`; `RetryException.java:57`).

When the callable throws a reused exception object, each failed attempt appends one more caller stack to it, and nothing ever removes the frames. Reused objects include a preallocated sentinel, a "cheap" exception that only overrides `fillInStackTrace()`, and the `CompletionException` that a failed `CompletableFuture` rethrows from every `join()`. Retained heap, per-attempt CPU (the array is copied three times per attempt) and log volume therefore grow without bound until the JVM runs out of memory. With `noTimeLimit()` the same exception is not touched, and Guava's own Javadoc promises the exception is "propagated to the caller exactly as-is". Every Guava version that 2.0.0 links against (10.x–22.0) has this path.

## Trigger scenario

1. The application builds a retryer through the public API with `.withAttemptTimeLimiter(AttemptTimeLimiters.fixedTimeLimit(5, SECONDS[, executor]))` and an exception-retrying predicate. The repro uses the README quickstart predicates: `retryIfExceptionOfType(IOException.class)`, `retryIfRuntimeException()` and `stopAfterAttempt(3)`.
2. The callable fails with the same exception object on each failure, for example `static final IOException NOT_READY` or `memoisedFuture.join()`.
3. Each failed attempt runs this chain: `Retryer.call:160` → `AttemptTimeLimiters.java:107` → `SimpleTimeLimiter.callWithTimeout:154/162-163` → `throwCause:259`, which calls `setStackTrace(old + caller stack)` on the shared object. The callable's original frames stay first, followed by one `FutureTask.report … SimpleTimeLimiter.callWithTimeout … Retryer.call … <caller frames>` block per attempt.
4. The application keeps calling. Each failure adds about (caller depth + 5) frames: 7 frames from `main`, and about 109 frames at an application depth of 100. With the builder default `neverStop`, the growth also builds up inside a single `call()`. Because the exception is static or cached, it lives for the whole process.

## Developer intent

- guava-retrying has no developer comments on this behavior. `AttemptTimeLimiters.java:105-108` has not changed since 7e474be7 (dirkraft, 2013-01-16, PR #1 "added a per attempt time limit"). The `AttemptTimeLimiter` Javadoc says only "@throws Exception any exception from this invocation". `AttemptTimeLimiterTest` never makes the callable throw.
- Guava's contract for the method that is called (`TimeLimiter.java:78-97`, 22.0) reads: "If the target method call finished before the limit is reached, the return value or exception is propagated to the caller exactly as-is". The method is `@Deprecated` ("scheduled to be removed in Guava 23.0"). The `combineStackTraces` concatenation is deliberate in Guava, but it never accounts for reused instances.
- Engineering principle: a per-attempt time-limit wrapper should not change the callable's outcome, and it must not pile up per-attempt state on objects the user owns.
- Known-status search (2026-11-26): nothing reports this mechanism.
  - rholder/guava-retrying: all issues and PRs #1–#107, including #84 and #107, both closed in 2026-09.
  - google/guava: #6599 is only about nested-try style.
  - Forks rhuffman/re-retrying and itning/guava-retrying3.
  - A web search.
  - PRs #95 (open) and #103 (closed, unmerged) switch line 107 to the three-argument API for Guava 23 compatibility only. Neither mentions this behavior.

## Reproduction result

PASS — Level 0: public API only, unmodified worktree `177b6c9b9f3e7957f404f0bdb8e23374cb1de43f`, Guava 22.0 (SHA-1 `3564ef3803de51fb0530a8377ec6100b33b0d073`), JDK 21, with a cross-check on JDK 11. No sleeps, failpoints, state injection or source changes. The only user-side instrumentation is in the `[attribution]` scenario: an exception subclass that records who calls its `setStackTrace()`.

Command: `bash repro/test_bugCR-D-12_reused_exception_stack_growth.sh`. The script exits with status 0 and passes 26/26 checks. The full output is in `repro/CR-D-12.log`.

Growth (README retryer; the listener and the caller log every failure):
```
[growth] limiter=noTimeLimit (control) exception=sentinel (IOException) initial stackTrace.length=1
  after 300 call()s / 900 failed attempts: stackTrace.length=     1 (SimpleTimeLimiter.callWithTimeout frames:   0)  listener log entry=      129 chars  caller's RetryException.printStackTrace=      362 chars  log total=      224,700 chars
[growth] limiter=fixedTimeLimit(5s, executor) exception=sentinel (IOException) initial stackTrace.length=1
  after   1 call()s /   3 failed attempts: stackTrace.length=    22 (SimpleTimeLimiter.callWithTimeout frames:   3)  listener log entry=     1614 chars  caller's RetryException.printStackTrace=     1775 chars  log total=        5,132 chars
  after  10 call()s /  30 failed attempts: stackTrace.length=   211 (SimpleTimeLimiter.callWithTimeout frames:  30)  listener log entry=    14979 chars  caller's RetryException.printStackTrace=    15140 chars  log total=      318,620 chars
  after 100 call()s / 300 failed attempts: stackTrace.length=  2101 (SimpleTimeLimiter.callWithTimeout frames: 300)  listener log entry=   148629 chars  caller's RetryException.printStackTrace=   148790 chars  log total=   29,916,200 chars
  after 300 call()s / 900 failed attempts: stackTrace.length=  6301 (SimpleTimeLimiter.callWithTimeout frames: 900)  listener log entry=   445629 chars  caller's RetryException.printStackTrace=   445790 chars  log total=  267,948,600 chars
  first frames of the reused exception's stack trace:
    [0] ReproCRD12.<clinit>(ReproCRD12.java:30)
    [1] java.base/java.util.concurrent.FutureTask.report(FutureTask.java:122)
    [2] java.base/java.util.concurrent.FutureTask.get(FutureTask.java:205)
    [3] com.google.common.util.concurrent.SimpleTimeLimiter.callWithTimeout(SimpleTimeLimiter.java:154)
    [4] com.github.rholder.retry.AttemptTimeLimiters$FixedAttemptTimeLimit.call(AttemptTimeLimiters.java:107)
    [5] com.github.rholder.retry.Retryer.call(Retryer.java:160)
```
Root-cause attribution, the realistic `CompletableFuture` source, and the other `Retryer.call` paths:
```
[attribution] limiter=noTimeLimit (control)  1 call() x 3 failed attempts: setStackTrace() called 0 time(s) on the callable's exception, by {}; stackTrace.length 2 -> 2
[attribution] limiter=fixedTimeLimit(5s, executor)  1 call() x 3 failed attempts: setStackTrace() called 3 time(s) on the callable's exception, by {com.google.common.util.concurrent.SimpleTimeLimiter.throwCause(SimpleTimeLimiter.java:259)=3}; stackTrace.length 2 -> 23
[cf] limiter=fixedTimeLimit(5s, executor)  CompletableFuture.join() rethrows the same object on every call: true  initial stackTrace.length=6
  after 100 call()s / 300 failed attempts: CompletionException stackTrace.length= 2106 (SimpleTimeLimiter.callWithTimeout frames: 300)
[paths] limiter=fixedTimeLimit(5s, executor) (b) predicate accepts the exception -> ExecutionException: stackTrace.length 2 -> 702 after 100 call()s x 1 attempt
[paths] limiter=fixedTimeLimit(5s, executor) (d) Retryer.wrap() run on an executor: stackTrace.length 2 -> 3002 after 100 call()s x 3 attempts
[paths] limiter=fixedTimeLimit(5s, executor) (e) default neverStop, one call() that succeeds on attempt 2000 (result=ok): stackTrace.length 2 -> 13995
```
Bounded heap (`-Xmx32m`, caller at an application depth of 100 frames, README retryer called repeatedly):
```
[oom] fixedTimeLimit(5s, executor) / reused static sentinel, callerDepth=100, maxHeap=32MB, maxCalls=6000
    250 call()s /    750 failed attempts: heap used after GC=   5.7 MB  NOT_READY.stackTrace.length=   81,751     0.58 ms per call() since previous line
    500 call()s /   1500 failed attempts: heap used after GC=  10.1 MB  NOT_READY.stackTrace.length=  163,501     4.59 ms per call() since previous line
    750 call()s /   2250 failed attempts: heap used after GC=  13.8 MB  NOT_READY.stackTrace.length=  245,251    13.49 ms per call() since previous line
   1000 call()s /   3000 failed attempts: heap used after GC=  18.6 MB  NOT_READY.stackTrace.length=  327,001    31.55 ms per call() since previous line
   1250 call()s /   3750 failed attempts: heap used after GC=  22.3 MB  NOT_READY.stackTrace.length=  408,751    60.81 ms per call() since previous line
   1500 call()s /   4500 failed attempts: heap used after GC=  26.0 MB  NOT_READY.stackTrace.length=  490,501   125.27 ms per call() since previous line
  RESULT[fixedTimeLimit(5s, executor) / reused static sentinel]: call() #1604 ended with ExecutionException caused by java.lang.OutOfMemoryError: Java heap space  <-- not the configured outcome (83.9 s; 4809 failed attempts completed before)
  AFTER[fixedTimeLimit(5s, executor) / reused static sentinel]: a later call() succeeded (result=ok); after GC heap used=  27.6 MB of 32 MB, NOT_READY.stackTrace.length=524,182
  RESULT[noTimeLimit (control) / reused static sentinel]: all 6000 call()s ended with RetryException(IOException) as configured (0.2 s; 18000 failed attempts completed before)
  RESULT[fixedTimeLimit(5s, executor) / fresh object per attempt]: all 6000 call()s ended with RetryException(IOException) as configured (1.4 s; 18000 failed attempts completed before)
```

How the lines above show the bug:
- In the `[growth]` block, the trace grows 1 → 6301 frames, with exactly one `SimpleTimeLimiter.callWithTimeout` frame per failed attempt (900/900). In the control it stays at 1 frame.
- A single listener log entry grows from 129 to 445,629 chars, and the caller's `RetryException.printStackTrace` grows from 362 to 445,790 chars. Cumulative log is 268 MB, compared with 225 KB for the control.
- The `[attribution]` line shows `SimpleTimeLimiter.throwCause(SimpleTimeLimiter.java:259)` doing the mutation 3× per call.
- The `RESULT`/`AFTER` lines of the bounded-heap run show the outcome:
  - Retained heap grows linearly (≈5.7 kB per failed attempt at depth 100: (26.0−5.7) MiB over 3,750 attempts), and per-call cost grows from 0.58 to 125 ms.
  - `call()` #1604 ends with `ExecutionException(OutOfMemoryError)` instead of the configured `RetryException(IOException)`.
  - The memory stays held after a later successful call.

Expected behavior is what both controls show. The `noTimeLimit` control and the `fixedTimeLimit` control with a fresh exception per attempt complete all 6000 calls with the configured outcome and stay at 1.6–1.7 MB.

Other checks in the run:
- The two-argument factory `fixedTimeLimit(5s)` and the "cheap" `fillInStackTrace`-overriding exception reproduce identically.
- JDK 11 reproduces identically.
- A reused exception built with `writableStackTrace=false` stays at 0 frames.
- `javap` shows the same `throwCause(e, true)`/`setStackTrace` path in Guava 10.0.1, 14.0.1, 16.0.1 and 19.0.

### Confirmation checklist

1. Did Level 0 or Level 1 alone trigger it? **Yes.** Level 0 only: `RetryerBuilder`, `AttemptTimeLimiters.fixedTimeLimit` (both factories), `Retryer.call`, `Retryer.wrap`, `RetryListener`, against unmodified sources. No timing help was needed.
2. Was Level 2 or Level 3 used? Not applicable — neither was used. The only precondition is a callable that throws the same object twice, which ordinary Java code does: `static final` sentinels, or the JDK's `CompletableFuture.join()`, shown above as returning the same object (`true`).
3. Which real consumer observes a wrong outcome?
   - The application calling `Retryer.call` (`Retryer.java:155`):
     - Its configured `RetryException(IOException)` turns into `ExecutionException(OutOfMemoryError)`. The OOM is raised in the time-limiter path, caught at `Retryer.java:162-163`, and rethrown by `attempt.get()` at `Retryer.java:171`.
     - Its calls slow from 0.58 to 125 ms each.
   - `RetryListener.onRetry` (`Retryer.java:166-168`) receives and logs ever-larger traces.
   - The caller printing `RetryException`, whose cause is set at `RetryException.java:57` (README quickstart `e.printStackTrace()`), prints ever-larger traces.
4. Is the bad state permanent? **Yes.** Nothing resets the mutated trace, and the static or cached exception lives for the whole process. After a later successful `call()` and a GC, the heap still holds 27.6 of 32 MB and the trace is still 524,182 frames. No downstream mechanism resolves or masks it.

## Recommendation

Fix it in guava-retrying at `AttemptTimeLimiters.java:107`: stop calling Guava's mutating four-argument `callWithTimeout`. Instead, submit to the executor and unwrap the failure without touching the user's exception, keeping today's outward contract (the callable's own exception is rethrown, `UncheckedTimeoutException` on timeout, the future is cancelled on timeout or interrupt):

```java
@Override
public V call(Callable<V> callable) throws Exception {
    Future<V> future = executorService.submit(callable);
    try {
        return future.get(duration, timeUnit);
    } catch (ExecutionException e) {
        Throwable cause = e.getCause();          // rethrow as-is: no setStackTrace / addSuppressed on a possibly shared object
        if (cause instanceof Exception) throw (Exception) cause;
        if (cause instanceof Error) throw (Error) cause;
        throw e;
    } catch (TimeoutException e) {
        future.cancel(true);
        throw new UncheckedTimeoutException(e);
    } catch (InterruptedException e) {
        future.cancel(true);
        throw e;
    }
}
```

Keep the `ExecutorService` in `FixedAttemptTimeLimit` for this. The fix also drops the dependency on the API that Guava 23 removed (#94). If the three-argument `TimeLimiter.callWithTimeout` is used instead, unwrap `ExecutionException`, `UncheckedExecutionException` and `ExecutionError`, and map `TimeoutException` to `UncheckedTimeoutException`. Do not re-add caller context by mutating the cause or calling `addSuppressed` on it, because that also grows on reused instances.

Add a regression test: throw the same exception object on N attempts under `fixedTimeLimit`, then assert that the identity and `getStackTrace().length` are unchanged.

Until a fix ships, users can avoid it in any of these ways:
- Create reused exceptions with `writableStackTrace=false` (verified above).
- Throw a fresh exception per failure.
- Avoid `fixedTimeLimit`.
