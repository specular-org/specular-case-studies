# CR-D-12 — Phase 1 investigation (evidence only)

Finding: under `AttemptTimeLimiters.fixedTimeLimit`, Guava's `throwCause(e, true)` appends the caller's stack to the callable's exception on every attempt, so a reused exception's stack trace grows without bound.

Source: code review (analysis ledger row D-12, scenario 4; not model-checked, no counterexample).

Source under test: worktree `177b6c9b9f3e7957f404f0bdb8e23374cb1de43f` (`v2.0.0-1-g177b6c9`, clean); `src/main` is byte-identical to the persistent-findings source `/home/ubuntu/scratch/guava-retrying-src/guava-retrying`. Guava: `~/.m2/repository/com/google/guava/guava/22.0/guava-22.0.jar` (SHA-1 `3564ef3803de51fb0530a8377ec6100b33b0d073`, matches the Maven `.sha1`); sources read from `/home/ubuntu/scratch/guava22-sources-dl/guava-22.0-sources.jar` (SHA-1 `55edc69e…`, matches its `.sha1`).

Persistent-findings lookup (`specular findings lookup --query throwCause --query setStackTrace --query combineStackTraces --query FixedAttemptTimeLimit --query "stack trace"`): `[]` — no prior record.

## Step 1 — Code audit

### Cited code

- `src/main/java/com/github/rholder/retry/AttemptTimeLimiters.java:105-108`
  ```java
  @Override
  public V call(Callable<V> callable) throws Exception {
      return timeLimiter.callWithTimeout(callable, duration, timeUnit, true);
  }
  ```
  `timeLimiter` is a `SimpleTimeLimiter` built at `:89-95` (`new SimpleTimeLimiter()` or `new SimpleTimeLimiter(executorService)`). Both public factories `fixedTimeLimit(long, TimeUnit)` (`:57-60`) and `fixedTimeLimit(long, TimeUnit, ExecutorService)` (`:69-72`) produce this class.
- Guava 22.0 `SimpleTimeLimiter.callWithTimeout(Callable, long, TimeUnit, boolean)` (`SimpleTimeLimiter.java:139-168`, `@Deprecated`): submits the callable, `future.get(timeout)`, and on failure
  ```java
  } catch (ExecutionException e) {
    throw throwCause(e, true /* combineStackTraces */);      // :162-163
  ```
- Guava 22.0 `SimpleTimeLimiter.throwCause` (`:251-269`):
  ```java
  Throwable cause = e.getCause();
  ...
  if (combineStackTraces) {
    StackTraceElement[] combined =
        ObjectArrays.concat(cause.getStackTrace(), e.getStackTrace(), StackTraceElement.class);
    cause.setStackTrace(combined);                             // :256-259
  }
  if (cause instanceof Exception) { throw (Exception) cause; } // :261-263
  ```
  `cause` is the very object the user callable threw (FutureTask stores it and wraps it in a fresh `ExecutionException` in `FutureTask.report`, on the caller thread). `e.getStackTrace()` is therefore the caller thread's stack at `future.get` (`FutureTask.report`, `FutureTask.get`, `SimpleTimeLimiter.callWithTimeout`, `FixedAttemptTimeLimit.call`, `Retryer.call`, then every frame of the application above `Retryer.call`). The mutated, original exception object is rethrown.
- `Retryer.call` (`Retryer.java:155-185`): `:160` calls `attemptTimeLimiter.call(callable)`; `:162-163` catches the rethrown object and stores it as-is in `ExceptionAttempt` (`:253-254`, `new ExecutionException(cause)`, `getExceptionCause()` returns it at `:280-281`); `:166-168` passes the attempt to every `RetryListener.onRetry`; `:171` `attempt.get()` throws `ExecutionException(cause)` when the predicate accepts; `:174` throws `RetryException(attemptNumber, attempt)`.
- `RetryException` (`RetryException.java:56-57`): the last attempt's exception cause becomes the `RetryException`'s cause ("ensure it is available in the stack trace").
- `NoAttemptTimeLimit.call` (`AttemptTimeLimiters.java:75-79`) just calls `callable.call()` — the exception passes through unmodified. This is the natural control.
- Not specific to Guava 22.0: `javap -c -p` of `SimpleTimeLimiter` in Guava 10.0.1, 14.0.1, 16.0.1 (`~/.m2`, SHA-1s match their `.sha1` files), 19.0 (`/home/ubuntu/scratch/guava-jars/guava-19.0.jar`, SHA-1 `6ce200f6…`) and 22.0 all show `iconst_1; invokestatic throwCause:(Ljava/lang/Exception;Z)` in the four-argument `callWithTimeout` and a `setStackTrace` call in `throwCause`. Guava 23+ removed the constructors/method guava-retrying 2.0.0 links against (#94), so every Guava version 2.0.0 can run with has this path.

### Call chain (public API → cited code)

`RetryerBuilder.newBuilder()` → `.retryIfException()` / `.retryIfExceptionOfType(..)` / `.retryIfRuntimeException()` → `.withAttemptTimeLimiter(AttemptTimeLimiters.fixedTimeLimit(d, unit[, executor]))` (`RetryerBuilder.java:118-121`) → `.build()` (`:190-196`) → `Retryer.call(callable)` (`Retryer.java:155`) or `Retryer.wrap(callable).call()` (`:195-197`, `:317-318`) → `Retryer.java:160` → `AttemptTimeLimiters.java:107` → `SimpleTimeLimiter.java:149-163` → `throwCause` `:256-259` (`setStackTrace` on the user's exception) → rethrown into `Retryer.java:162-163`.

Reachable during normal use: yes — every attempt whose callable throws, under any `fixedTimeLimit` retryer. No configuration beyond the documented public builder API is needed; the defaults (`RetryerBuilder.java:192-193`) are `neverStop` and `noWait`.

### Trigger scenario

1. Application builds a retryer with `fixedTimeLimit(...)` and an exception-retrying predicate (README quickstart shape: `retryIfExceptionOfType(IOException.class)`, `retryIfRuntimeException()`, `stopAfterAttempt(3)`).
2. The callable fails by throwing an exception object that is the same instance on every failure. Realistic producers: (a) a preallocated/static "sentinel" exception (`static final IOException NOT_READY = ...`, a common control-flow/performance pattern, including the `fillInStackTrace()`-overriding "stackless" variant, which still has a writable stack trace); (b) a JDK `CompletableFuture` that failed asynchronously, rethrown with `join()` — `join()` rethrows the stored `CompletionException` object itself (to be verified in Phase 2).
3. Each failed attempt: `throwCause` replaces the shared exception's stack trace with `old + caller stack` (≈ caller depth + 5 frames).
4. Attempts repeat (within one `call()` up to the stop strategy — unbounded with the default `neverStop` — and across every later `call()` for the process lifetime when the instance is static/cached). The stack trace grows linearly with the total number of failed attempts; each attempt also copies the whole array three times (`getStackTrace` clone, `concat`, `setStackTrace` defensive copy), so CPU per attempt grows too.
5. Consumers: `RetryListener.onRetry` (`Retryer.java:166-168`) receives `attempt.getExceptionCause()` = the grown object; `RetryException` (`Retryer.java:174`, cause per `RetryException.java:57`) and `ExecutionException` from `attempt.get()` (`Retryer.java:171`) carry it to the caller, which typically logs it (README quickstart: `e.printStackTrace()`); the retained `StackTraceElement[]` is heap held by the shared exception forever.

### Safeguards / masks recorded (not dismissed; Phase 2 checks)

- JVM `-XX:MaxJavaStackTraceDepth` caps only `fillInStackTrace` capture, not arrays installed by `setStackTrace` — expected not to cap growth (Phase 2 measures).
- Exceptions built with `writableStackTrace=false` (`Throwable(String, Throwable, boolean, boolean)`) ignore `setStackTrace` — immune. Fresh-per-attempt exceptions get only a one-time, bounded concatenation. These narrow the trigger (reused + writable), they do not mask it.
- Nothing in `Retryer`, `RetryException`, or `AttemptTimeLimiters` copies, truncates, or resets the exception.

## Step 2 — Developer-knowledge evidence (verbatim, unclassified)

- Commit / blame: `AttemptTimeLimiters.java:105-108` unchanged since `7e474be7` (dirkraft, 2013-01-16, "add time limit per attempt in a retryer", PR #1 "added a per attempt time limit": "This provides a mechanism to limit any one single attempt from clobbering a Retryer."). No message mentions stack traces or exception mutation. Later commits on the file (`4da9dda`, `5cc1018`, `8515e4a`, `a5a069f`) are Javadoc/license only.
- Library docs: `AttemptTimeLimiter.java:21-33` — "A rule to wrap any single attempt in a time limit, where it will possibly be interrupted if the limit is exceeded." / "@throws Exception any exception from this invocation". `AttemptTimeLimiters.java:47-55` Javadoc: no statement about exceptions or stack traces.
- Guava's own contract for the method used (Guava 22.0 `TimeLimiter.java:78-97`): "If the target method call finished before the limit is reached, the return value or exception is propagated to the caller exactly as-is." … "@deprecated Use one of the other {@code call[Uninterruptibly]WithTimeout()} or {@code run[Uninterruptibly]WithTimeout()} methods. This method is scheduled to be removed in Guava 23.0." The implementation comment `/* combineStackTraces */` (`SimpleTimeLimiter.java:163`) shows the concatenation itself is deliberate in Guava; nothing addresses reused instances.
- Tests: `AttemptTimeLimiterTest.java:30-67` only checks success and that a timeout surfaces as `UncheckedTimeoutException`; no test covers a callable that throws, or the identity/stack of a thrown exception.
- README quickstart (`README.md:31-50`): exception-retrying predicates plus `e.printStackTrace()` on `RetryException`/`ExecutionException` — the canonical consumer logs the cause's stack.

## Step 3 — Known-status / precedent

Searches run on 2026-11-26 (tracker / git history only):

- `rholder/guava-retrying`, full list of all issues and PRs (`gh api repos/rholder/guava-retrying/issues?state=all`, #1-#107, includes recently closed PR #107 "Modernize" 2026-09-05 and #84 2026-09-20) plus `gh search` for "stack trace", "stacktrace", "setStackTrace", "throwCause", "combineStackTraces", "memory leak", "OutOfMemory", "SimpleTimeLimiter", "fixedTimeLimit", "callWithTimeout", "static exception", "stack grows". Hits read: #3 (2013, closed: make the last attempt's exception the `RetryException` cause — different mechanism), #94 / #96 (Guava 22+/23 constructor visibility — different), #29 / #92 (timeout retry, thread lifecycle — different). PRs #95 (open) and #103 (closed, unmerged) change line 107 to the three-argument `callWithTimeout` only for Guava 23 compatibility; neither mentions stack traces or exception mutation.
- `google/guava`: "SimpleTimeLimiter stack trace", "combineStackTraces", "throwCause stack", "callWithTimeout stack trace", "SimpleTimeLimiter setStackTrace", "TimeLimiter stacktrace grows", "SimpleTimeLimiter memory leak", "callWithTimeout exception modified", "TimeLimiter stack trace", "SimpleTimeLimiter exception", "callWithTimeout". Hits: #6599 "Sloppy code in SimpleTimeLimiter" (nested try style, closed 2023-06-27 — not this mechanism), #3550 (thread not interrupted), #3725 (re-expose constructors), #3907, #490 — none about stack-trace mutation or growth.
- Forks `rhuffman/re-retrying` ("stack trace", "stacktrace", "TimeLimiter", "memory": #17 thread pool per call, #8/#7 Guava 23 — different) and `itning/guava-retrying3` (no relevant hits).
- Web search ("SimpleTimeLimiter callWithTimeout combineStackTraces stack trace grows reused exception"; "guava-retrying fixedTimeLimit exception stack trace growing memory"): no report of this mechanism.
- Local Specular dataset: persistent-findings lookup empty; `Specular/case-studies` has no guava-retrying entry.

Known-status: no existing issue / PR / CVE / advisory / dataset entry reports this mechanism at this site. Pre-filter (code-review × already-reported) does **not** apply → proceed to Phase 2.
