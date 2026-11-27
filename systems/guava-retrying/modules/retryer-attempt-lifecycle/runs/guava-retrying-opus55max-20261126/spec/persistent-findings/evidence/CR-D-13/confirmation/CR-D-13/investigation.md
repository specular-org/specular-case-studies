# CR-D-13 — Phase 1 investigation (evidence only)

Finding: under `AttemptTimeLimiters.fixedTimeLimit`, a callable `Throwable` that is neither `Exception` nor `Error` reaches the retry predicates wrapped in `ExecutionException`, so `retryIfExceptionOfType(T)` stops matching. Source: code review (ledger D-13, scenario 4, not model-checked; no counterexample).

Source under test: worktree `confirmation/CR-D-13/worktree`, detached at upstream `177b6c9` (= current upstream `master` head, `gh api repos/rholder/guava-retrying/commits?sha=master`). Guava: 22.0 (`~/.m2/repository/com/google/guava/guava/22.0/guava-22.0.jar`, sources from `/home/ubuntu/scratch/guava22-sources-dl/guava-22.0-sources.jar`, extracted to `guava22-src/`).

## Step 1 — Code audit

### Cited code

- `src/main/java/com/github/rholder/retry/AttemptTimeLimiters.java:75-80` — `NoAttemptTimeLimit.call` is `return callable.call();` — the callable's `Throwable` propagates unchanged.
- `src/main/java/com/github/rholder/retry/AttemptTimeLimiters.java:105-108` — `FixedAttemptTimeLimit.call` is `return timeLimiter.callWithTimeout(callable, duration, timeUnit, true);` (Guava `SimpleTimeLimiter`, deprecated 4-arg overload). Both factories (`fixedTimeLimit(d,u)` at :57-60 → `new SimpleTimeLimiter()`; `fixedTimeLimit(d,u,executor)` at :69-72 → `new SimpleTimeLimiter(executor)`) reach it.
- `guava-22.0 com/google/common/util/concurrent/SimpleTimeLimiter.java:149-167` — `callWithTimeout(...)`: `executor.submit(callable)`, `future.get(timeout)`; `catch (ExecutionException e) { throw throwCause(e, true); }`.
- `guava-22.0 .../SimpleTimeLimiter.java:251-269` — `throwCause`:
  ```java
  if (cause instanceof Exception) { throw (Exception) cause; }   // :261-263
  if (cause instanceof Error) { throw (Error) cause; }           // :264-266
  // The cause is a weird kind of Throwable, so throw the outer exception.   // :267
  throw e;                                                        // :268
  ```
  So for a cause that is neither `Exception` nor `Error`, the attempt fails with the `java.util.concurrent.ExecutionException` created by `FutureTask.report` (cause = the callable's throwable), not with the throwable itself.
- `src/main/java/com/github/rholder/retry/Retryer.java:159-164` — `catch (Throwable t) { attempt = new ExceptionAttempt<V>(t, ...); }`; `:253-256` `ExceptionAttempt` stores `new ExecutionException(cause)`; `:280-282` `getExceptionCause()` returns `e.getCause()` — i.e. `t` as thrown by the limiter. Under `fixedTimeLimit` + weird throwable that is `ExecutionException(t)`.
- `src/main/java/com/github/rholder/retry/RetryerBuilder.java:207-213` — `ExceptionClassPredicate.apply`: `exceptionClass.isAssignableFrom(attempt.getExceptionCause().getClass())` — exact class test on the (possibly wrapped) cause, no unwrapping. `:242-248` `ExceptionPredicate.apply` passes `attempt.getExceptionCause()` to the user `Predicate<Throwable>` — same input.
- `src/main/java/com/github/rholder/retry/Retryer.java:166-174` — consumer of the classification: listeners get the attempt (:166-168); `if (!rejectionPredicate.apply(attempt)) return attempt.get();` (:170-172) ends the call, otherwise stop strategy/RetryException (:173-174) whose cause is `getExceptionCause()` (`RetryException.java:57`).

### Call chain (public entry → cited code)

`RetryerBuilder.newBuilder().retryIfExceptionOfType(T.class).withAttemptTimeLimiter(AttemptTimeLimiters.fixedTimeLimit(...)).build().call(callable)` → `Retryer.call` (`Retryer.java:160`) → `FixedAttemptTimeLimit.call` (`AttemptTimeLimiters.java:107`) → `SimpleTimeLimiter.callWithTimeout` (Guava :149-163) → `FutureTask.get` → `ExecutionException(t)` → `throwCause` falls through to `throw e` (:268) → `Retryer.call` `catch (Throwable t)` with `t = ExecutionException(t0)` (:162-163) → `rejectionPredicate.apply` → `ExceptionClassPredicate` tests `ExecutionException.class` (:212) → no match → `attempt.get()` throws `ExecutionException(ExecutionException(t0))` (:171).

Reachability: every step is the normal public path; `retryIfExceptionOfType` explicitly accepts `Class<? extends Throwable>` (`RetryerBuilder.java:153`), `retryIfException(Predicate<Throwable>)` (:166), and `Retryer.call` catches `Throwable` (:162). The only precondition is a callable that throws a `Throwable` that is neither `Exception` nor `Error`. Java code reaches that through standard sneaky-throw helpers (commons-lang3 `ExceptionUtils.rethrow(Throwable)` — verified in 3.8.1 bytecode as `aload_0; athrow`; Lombok `@SneakyThrows`), `Class.newInstance()` on a constructor that declares such a throwable, or JVM languages without checked exceptions (Kotlin/Groovy/Scala `throw` of a `Throwable` subclass). The target guidance states the callable "may … throw any `Throwable`".

### Trigger scenario

1. User defines `class TransientFailure extends Throwable` (or receives one from a library) and configures `retryIfExceptionOfType(TransientFailure.class)` + `stopAfterAttempt(3)`.
2. Without a time limit, a callable throwing `TransientFailure` is retried 3 times → `RetryException(cause=TransientFailure)`.
3. The user adds `withAttemptTimeLimiter(fixedTimeLimit(5, SECONDS[, executor]))` — nothing else changes; the callable still throws immediately (no timeout involved).
4. Now attempt 1's cause is `ExecutionException(TransientFailure)`; the predicate does not match; `call()` returns after 1 invocation by throwing `ExecutionException(ExecutionException(TransientFailure))`.
Variants to check in Phase 2: `retryIfException(Predicate<Throwable>)` (same input), and `retryIfException()` (`Exception.class`) where the wrapping makes a non-`Exception` throwable match (inverse divergence).

### Safeguards encountered (to be tested in Phase 2, not dismissed)

- None in guava-retrying unwraps the limiter's `ExecutionException` before the predicates (`RetryerBuilder.java:207-213`, `:242-248`). Callers could unwrap the final exception with `Throwables.getRootCause`, but that cannot restore the retries the predicate already declined at `Retryer.java:170`.
- `Exception` and `Error` causes take `throwCause` branches :261-266 and are rethrown unwrapped, so they are not affected (controls for Phase 2).

## Step 2 — Developer knowledge (verbatim)

- `Attempt.getExceptionCause()` Javadoc: "Gets the exception thrown by the call … @return the exception thrown by the call" (`Attempt.java`).
- `Attempt.get()` Javadoc: "@throws ExecutionException if an exception was thrown by the attempt. The thrown exception is set as the cause of the ExecutionException".
- `RetryerBuilder.retryIfExceptionOfType` Javadoc (`RetryerBuilder.java:146-152`): "Configures the retryer to retry if an exception of the given class (or subclass of the given class) is thrown by the call."
- `RetryerBuilder.withAttemptTimeLimiter` Javadoc (`:112-117`): "Configures the retryer to limit the duration of any particular attempt by the given duration." — no mention of changing exception classification.
- `AttemptTimeLimiter` Javadoc: "A rule to wrap any single attempt in a time limit, where it will possibly be interrupted if the limit is exceeded. … @return the return of the given callable @throws Exception any exception from this invocation".
- `Retryer.call` Javadoc (`Retryer.java:148-150`): "@throws ExecutionException if the given callable throws an exception, and the rejection predicate considers the attempt as successful. The original exception is wrapped into an ExecutionException."
- Guava 22.0 `TimeLimiter.callWithTimeout(Callable, long, TimeUnit, boolean)` Javadoc (`TimeLimiter.java:80-82`): "If the target method call finished before the limit is reached, the return value or exception is propagated to the caller exactly as-is." `SimpleTimeLimiter.java:138` carries "// TODO: should this actually throw only ExecutionException?"; `:267` "// The cause is a weird kind of Throwable, so throw the outer exception." (Guava's own implementation deviates from its interface Javadoc for this case because the method is declared `throws Exception`.)
- Tests: `AttemptTimeLimiterTest.testAttemptTimeLimit` asserts only the timeout case (`e.getCause().getClass() == UncheckedTimeoutException.class`). `RetryerBuilderTest.testRetryIfExceptionOfType` / `testRetryIfExceptionWithPredicate` (`:239-310`) assert `e.getCause() instanceof IllegalStateException` and `getLastFailedAttempt().getExceptionCause() instanceof IOException` — the callable's exception, once-wrapped — without a time limiter. No test combines a time limiter with a non-`Exception`/non-`Error` throwable.
- Git: `AttemptTimeLimiters` added in `7e474be` (dirkraft, 2013-01-16, "add time limit per attempt in a retryer"), unchanged since except boilerplate/Javadoc (`a5a069f`, `5cc1018`, `4da9dda`, `8515e4a`). `ExceptionClassPredicate` unchanged since `6d2d838` (2012-11-17). No commit message discusses exception wrapping by the limiter.

## Step 3 — Known-status / precedent

Searched (2026-11-26), raw dumps in `tracker/`:
- `rholder/guava-retrying`: all 106 issues + PRs (state=all, incl. PR #107 closed 2026-09-05 and #84 closed 2026-09-20), 185 issue comments, 5 review comments; keyword grep for Throwable/throwCause/sneaky/ExecutionException/unwrap/wrapped/getExceptionCause/retryIfExceptionOfType/isAssignableFrom/callWithTimeout/Kotlin/Scala. Hits read: #29 (timeout `UncheckedTimeoutException` not retried — different mechanism, the limiter's own timeout exception), #27 (feature: cause-chain predicates), #67 (catching `Error`s), #65/#60/#41/#102/#78/#23 (unrelated). PRs #95 and #103 modify `AttemptTimeLimiters.call` only for Guava 23+ compatibility (switch to 3-arg `callWithTimeout`); neither reports this defect; both unmerged. Upstream `master` = `177b6c9` (same as worktree); `AttemptTimeLimiters.java` last touched 2015-01-21.
- Fork `rhuffman/re-retrying` (issues 1–41): #22 (stop wrapping in `ExecutionException` — API-style request), #23, #14 (Errors), #7/#8 (Guava 23) — none reports this mechanism.
- GitHub-wide `gh search issues` for "guava-retrying fixedTimeLimit Throwable", "AttemptTimeLimiter ExecutionException wrapped Throwable", "SimpleTimeLimiter throwCause Throwable ExecutionException", etc.: no results.
- Specular persistent findings: `specular findings --work .specular-output lookup --query 'SimpleTimeLimiter throwCause' --query ExceptionClassPredicate --query 'retryIfExceptionOfType fixedTimeLimit Throwable'` → `[]`; `persistent-findings-context.json` has no previous/inherited records.

Result: no existing report of THIS mechanism at THIS site → Novelty NEW; the code-review × known pre-filter does not apply → proceed to Phase 2.
