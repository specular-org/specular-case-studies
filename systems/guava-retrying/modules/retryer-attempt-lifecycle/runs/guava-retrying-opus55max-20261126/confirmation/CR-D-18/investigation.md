# CR-D-18 — Investigation (Phase 1, evidence only)

Finding: `exceptionWait` with a function that returns `null` makes `call()` throw `NullPointerException` from auto-unboxing.
Source: code review (ledger D-18, scenario 5); no model-checking counterexample exists for it.
Target SHA: worktree at `177b6c9` (= upstream `rholder/guava-retrying` master, 2.0.0 + a Travis workaround).

## Step 1 — Code audit

### Cited code

`src/main/java/com/github/rholder/retry/WaitStrategies.java:374-395`

```java
    @Immutable
    private static final class ExceptionWaitStrategy<T extends Throwable> implements WaitStrategy {
        private final Class<T> exceptionClass;
        private final Function<T, Long> function;
        ...
        @SuppressWarnings({"ThrowableResultOfMethodCallIgnored", "ConstantConditions", "unchecked"})
        @Override
        public long computeSleepTime(Attempt lastAttempt) {
            if (lastAttempt.hasException()) {
                Throwable cause = lastAttempt.getExceptionCause();
                if (exceptionClass.isAssignableFrom(cause.getClass())) {
                    return function.apply((T) cause);      // line 390: Long -> long auto-unboxing
                }
            }
            return 0L;
        }
    }
```

Line 390 returns a `Long` from `Function<T, Long>.apply` as the primitive `long` return type, so javac inserts `Long.longValue()`; a `null` from `apply` throws `NullPointerException` there.

Factory `WaitStrategies.java:202-216` (`exceptionWait`) only null-checks `exceptionClass` and the `function` object; nothing checks what the function returns. Javadoc: "The {@code function} determines how the sleep time should be calculated for the given {@code exceptionClass}. If the exception does not match, a wait time of 0 is returned." No statement that `null` is forbidden, no `@throws`.

`WaitStrategy.computeSleepTime` Javadoc (`WaitStrategy.java:26-32`): "Returns the time, in milliseconds, to sleep before retrying." No exceptions documented.

`CompositeWaitStrategy.computeSleepTime` (`WaitStrategies.java:364-371`, i.e. `join(...)`) calls each member's `computeSleepTime` directly, so a nested `exceptionWait` propagates the NPE the same way.

### Guava contract for the user function

Build target is Guava 22.0 (target guidance). `javap -v` on `~/.m2/.../guava-22.0.jar`:

```
  public abstract T apply(F);
    RuntimeVisibleAnnotations:
      0: #9()
        javax.annotation.Nullable
```

i.e. `@Nullable T apply(@Nullable F input)` — a null return is part of Guava's declared `Function` contract (same on 14.0.1 and 16.0.1; Guava 10.0.1 has only the `@Nullable` parameter). Guava 22's `Function` is a `@FunctionalInterface` extending `java.util.function.Function`, so lambdas such as `e -> hints.get(key)` (a `Map.get` that yields `null` on a miss) are natural arguments.

### Call chain (public API → defect)

1. User: `RetryerBuilder.newBuilder().withWaitStrategy(WaitStrategies.exceptionWait(E.class, fn))...build()` (`RetryerBuilder.java:75-80`, `:190-197`).
2. `Retryer.call(callable)` (`Retryer.java:155`).
3. Attempt runs inside `try { ... } catch (Throwable t)` (`Retryer.java:159-164`) → `ExceptionAttempt` holding the callable's exception.
4. Listeners notified (`Retryer.java:166-168`).
5. `rejectionPredicate.apply(attempt)` true (e.g. `retryIfExceptionOfType(E.class)`) (`Retryer.java:170`).
6. `stopStrategy.shouldStop(attempt)` false (`Retryer.java:173`).
7. `long sleepTime = waitStrategy.computeSleepTime(attempt);` (`Retryer.java:176`) — **outside** any try/catch; the only try (`:177-182`) wraps `blockStrategy.block` and catches only `InterruptedException`.
8. `ExceptionWaitStrategy.computeSleepTime` → `function.apply(cause)` returns `null` → unboxing NPE (`WaitStrategies.java:390`).
9. NPE propagates out of `Retryer.call` to the caller. `RetryerCallable.call()` (`Retryer.java:316-319`) simply delegates, so `wrap()` users get the same.

Documented outcomes of `call()` (`Retryer.java:140-154`): return the result; `ExecutionException` "if the given callable throws an exception, and the rejection predicate considers the attempt as successful"; `RetryException` "if all the attempts failed before the stop strategy decided to abort, or the thread was interrupted". An unchecked `NullPointerException` is not among them.

### Reachability

Reachable during normal usage through public API only: a user-supplied `Function<E, Long>` that returns `null` for some exception instances (e.g. a "Retry-After" hint absent from the exception, a map lookup miss). No special state, timing or concurrency is needed. Deterministic.

### Safeguards encountered

- `exceptionWait` factory: `checkNotNull(function)` — guards the function object, not its result.
- `Retryer.call`: no catch around `computeSleepTime` (line 176). No try/finally. No later mechanism re-attempts or converts the exception.
- `CompositeWaitStrategy`: no guard.
- None found that would mask the NPE; Phase 2 checks this empirically.

### Trigger scenario

1. Configure `retryIfExceptionOfType(IOException.class)`, `stopAfterAttempt(3)`, `exceptionWait(IOException.class, e -> retryAfterHints.get(e.getMessage()))` where the hint map has no entry for the message the server returned.
2. The callable fails once with `IOException("503 Service Unavailable")` (transient) and would succeed on the next attempt.
3. Expected per docs: second attempt runs and `call()` returns the value (or, if all fail, `RetryException` after 3 attempts).
4. Predicted actual: `call()` throws `NullPointerException` after attempt 1; attempt 2 never runs; the NPE carries no reference to the `IOException`; a caller handling only the documented `ExecutionException`/`RetryException` does not catch it.

## Step 2 — Developer knowledge

- **History**: strategy added by Yaroslav Matveychuk in `9c6bd63` (2014-11-04, PR #24 closed / #26 merged, issue #25 "Calculate sleep time from failed attempt"); already `return function.apply((T) lastAttempt.getExceptionCause());`. Renamed `exceptionalWait`→`exceptionWait` and `AttemptWaitStrategy`→`ExceptionWaitStrategy` by Ray Holder in `dbe616d` (2015-06-21, "some minor refactoring and renaming for #25, suppress warnings"), which also added `@SuppressWarnings({"ThrowableResultOfMethodCallIgnored", "ConstantConditions", "unchecked"})` on `computeSleepTime`. `ConstantConditions` is IntelliJ's nullability/constant-condition inspection; the only candidate in this method is the unboxing of the `@Nullable` `Function.apply` result (`getExceptionCause()` is not annotated). This is evidence a static warning at this site was seen and suppressed without adding a guard — awareness, not a filed report.
- **Discussion**: #25 comments (rholder 2015-07-01: "should now be live in the 2.0.0 release"), #26 comments (rholder 2015-05-02, about exposing the `Attempt`) — no discussion of null returns or failure semantics. #24/#26 have no review comments.
- **Comments/docs**: no TODO/FIXME at the site; the old `// TODO generalize this to accept a Function<Attempt, Long>` (removed in `dbe616d`) concerns the input type, not null results. README does not mention `exceptionWait`.
- **Tests**: `WaitStrategiesTest.testExceptionWait` (`src/test/java/.../WaitStrategiesTest.java:156-169`) uses only functions returning non-null `0L`, `3600*1000L`, `29L`; no test covers a null return or the NPE behavior, and no test asserts it is intended.

## Step 3 — Known-status / precedent

Searches performed on 2026-11-26:

- `gh search issues --repo rholder/guava-retrying --include-prs` for `exceptionWait`, `ExceptionWaitStrategy`, `NullPointerException`, `unboxing`, `computeSleepTime`, `exceptionalWait`, `wait strategy null`, `WaitStrategy exception` → only unrelated hits (#92 thread-exit, #86/#45/#63/#28/#65 feature questions).
- Full dump of all 106 upstream issues + PRs (open and closed, `gh api repos/rholder/guava-retrying/issues?state=all`), body/title regex for `exceptionWait|exceptionalWait|ExceptionWait|AttemptWaitStrategy|NullPointer|NPE|unbox|Function<` → only #24/#26 (the PRs that introduced the strategy) and #92 (stack trace mentioning NPE in an unrelated thread-exit report), #65 (unrelated Future retryer).
- Recently closed PRs: #107 "Modernize" (closed unmerged 2026-09-05) deletes the Java sources in favor of a PHP port — does not report or fix this; #84 (closed 2026-09-20) README only. #95 (open) adds a jitter strategy; untouched `ExceptionWaitStrategy`. Upstream `master` HEAD is still `177b6c9` (2016-05-10) — no fix landed.
- GitHub-wide issue search `exceptionWait null`, `exceptionWait NullPointerException`, `ExceptionWaitStrategy NullPointerException` → no results; fork `rhuffman/re-retrying` (#81) issue search `exceptionWait` → no results.
- Prior Specular dataset: `specular findings lookup` (exceptionWait / ExceptionWaitStrategy / computeSleepTime / NullPointerException) → `[]`; `specular-org/specula-case-studies` tree has no guava-retrying system.

Known-status: no existing issue/PR/CVE/dataset entry reports this mechanism at this site → not a code-review × known drop. Proceed to Phase 2.
