# CR-D-11 — Phase 1 investigation (evidence only)

Finding: `fixedTimeLimit` accepts a zero or negative duration; every attempt then fails with `IllegalArgumentException` before the callable runs and is treated as a callable failure.

Source: code review (ledger row D-11, scenario 4; not model-checked, no counterexample).

Source under test: worktree `HEAD` = `177b6c9` (only `.travis.yml` differs from tag `v2.0.0` = `c3e1c37`; `git diff --stat v2.0.0 HEAD -- src` is empty), i.e. the guava-retrying 2.0.0 release source. Guava: 22.0 (`~/.m2/repository/com/google/guava/guava/22.0/guava-22.0.jar`, sha256 `1158e94c…579e`; sources jar `~/scratch/guava22-sources-dl/guava-22.0-sources.jar`).

Persistent-findings lookup (`specular findings … lookup --query fixedTimeLimit --query FixedAttemptTimeLimit --query "timeout must be positive" --query checkPositiveTimeout --query AttemptTimeLimiters`): `[]` (no prior record).

## Step 1 — Code audit

### Cited code (read in full, in context)

- `src/main/java/com/github/rholder/retry/AttemptTimeLimiters.java:57-60` — `fixedTimeLimit(long duration, TimeUnit timeUnit)`: only `Preconditions.checkNotNull(timeUnit)`, then `new FixedAttemptTimeLimit<V>(duration, timeUnit)`.
- `AttemptTimeLimiters.java:69-72` — `fixedTimeLimit(long duration, TimeUnit timeUnit, ExecutorService executorService)`: only `checkNotNull(timeUnit)` (executor not even null-checked here; `SimpleTimeLimiter(ExecutorService)` does that).
- `AttemptTimeLimiters.java:89-103` — `FixedAttemptTimeLimit` constructors: `checkNotNull(timeLimiter)`, `checkNotNull(timeUnit)`, store `duration` unchecked.
- `AttemptTimeLimiters.java:105-108` — `call(callable)` = `timeLimiter.callWithTimeout(callable, duration, timeUnit, true)`.
- Guava 22.0 `SimpleTimeLimiter.java:142-149` — deprecated 4-arg `callWithTimeout`: `checkNotNull(callable)`, `checkNotNull(timeoutUnit)`, **`checkPositiveTimeout(timeoutDuration)` (:147)**, and only then `Future<T> future = executor.submit(callable)` (:149).
- Guava 22.0 `SimpleTimeLimiter.java:317-319` — `checkPositiveTimeout`: `checkArgument(timeoutDuration > 0, "timeout must be positive: %s", timeoutDuration)` → `IllegalArgumentException`. The check is on the raw `long`, not on the unit-converted value.
- `Retryer.java:160` — `V result = attemptTimeLimiter.call(callable);`
- `Retryer.java:162-163` — `catch (Throwable t) { attempt = new ExceptionAttempt<V>(t, attemptNumber, …); }` — every throwable out of the limiter becomes the attempt's "exception thrown by the call".
- `Retryer.java:166-168` — every listener's `onRetry(attempt)` is called with that attempt.
- `Retryer.java:170-171` — if the rejection predicate does not match: `return attempt.get()` → throws `ExecutionException(IAE)`.
- `Retryer.java:173-174` — if it matches and the stop strategy stops: `throw new RetryException(attemptNumber, attempt)` (message "Retrying failed to complete successfully after N attempts.", cause = IAE).
- `Retryer.java:176-182` — else compute sleep, `blockStrategy.block(sleepTime)`, loop to the next attempt.
- `RetryerBuilder.java:118-122` — `withAttemptTimeLimiter`: only `checkNotNull`. `RetryerBuilder.java:190-197` — `build()`: defaults `StopStrategies.neverStop()`, `WaitStrategies.noWait()`, `BlockStrategies.threadSleepStrategy()`; no limiter validation. `Retryer.java:125-130` — constructor: null checks only.

### Call chain (public API → defect site)

`AttemptTimeLimiters.fixedTimeLimit(d <= 0, unit[, executor])` (accepted, no range check) → `RetryerBuilder.withAttemptTimeLimiter(…)` (null check only) → `RetryerBuilder.build()` / `new Retryer(…)` (null checks only) → `Retryer.call(callable)` or `retryer.wrap(callable).call()` → `Retryer.java:160` `attemptTimeLimiter.call(callable)` → `AttemptTimeLimiters.java:107` `SimpleTimeLimiter.callWithTimeout(callable, d, unit, true)` → `SimpleTimeLimiter.java:147` → `:317-319` throws `IllegalArgumentException("timeout must be positive: d")` **before** `executor.submit(callable)` at `:149` → `Retryer.java:162-163` wraps it as the attempt's exception → listeners (`:166-168`) → rejection predicate (`:170`) → stop (`:173`) / wait+block (`:176-178`) → next attempt, which fails identically.

### Reachability

Fully reachable through the public API in normal usage, deterministically, on every `call()` of such a `Retryer` (the limiter's fields are final; nothing can repair the duration afterward). No concurrency or timing is needed.

### Trigger scenarios (natural)

1. Config-driven limit where `0` is meant as "no timeout" — the dominant Java convention (`Socket.setSoTimeout(0)`, `URLConnection.setConnectTimeout(0)`, `Statement.setQueryTimeout(0)`, `Thread.join(0)`, `Object.wait(0)` all mean "no limit"), or an unset numeric property defaulting to `0`. Real user code passes config values straight into this factory, e.g. spring-retry issue 69 (https://github.com/spring-attic/spring-retry/issues/69) shows `RetryerBuilder…retryIfException()…withAttemptTimeLimiter(AttemptTimeLimiters.fixedTimeLimit(config.getRetryTimeout(), TimeUnit.MILLISECONDS))`.
2. A per-attempt limit computed from a remaining deadline budget (`deadline - now`) that has reached `<= 0` when the retryer is built.
3. Any explicit `0`/negative literal.

Combined with the very common `retryIfException()` / `retryIfRuntimeException()` (both match `IllegalArgumentException`; upstream issue #92 and spring-retry 69 show both in real code) and the builder defaults `neverStop()` + `noWait()`, `call()` spins forever without ever invoking the callable. With `stopAfterAttempt(N)` it ends in `RetryException("… after N attempts")` with 0 invocations. With the default predicate it ends in `ExecutionException(IllegalArgumentException)` on the first call.

### Safeguards encountered (recorded, not yet proven in either direction)

- No eager check anywhere in guava-retrying (factory, `FixedAttemptTimeLimit`, builder, `Retryer` constructor).
- Guava's `checkPositiveTimeout` is the only check; it fires at use time, inside the attempt, and so is subject to `Retryer`'s catch-all and retry policy.
- With the default rejection predicate (`alwaysFalse`) the misconfiguration surfaces on the first `call()` as `ExecutionException` whose cause is the IAE with a readable message — "fail at first use" rather than "fail fast". This is a partial mitigation only when no exception-retry predicate is configured; it is not a mask for configurations using `retryIfException()`/`retryIfRuntimeException()`/`retryIfExceptionOfType(IllegalArgumentException|RuntimeException|Exception)`/an exception predicate that accepts IAE.
- Interrupting the calling thread ends the spin (`Thread.sleep(0)` in `threadSleepStrategy` throws `InterruptedException` if interrupted → `RetryException`), but only if something interrupts it; nothing in the library does. To be verified in Phase 2.

## Step 2 — Developer-knowledge search (verbatim evidence)

### Issue tracker (rholder/guava-retrying; all 106 issues and PRs listed with `gh api …/issues?state=all`, incl. merged/closed PRs)

- No issue or PR reports a zero/negative `fixedTimeLimit` duration, "timeout must be positive", or missing duration validation. GitHub search `repo:rholder/guava-retrying` for `"timeout must be positive"`, `fixedTimeLimit negative`, `fixedTimeLimit zero`, `duration validation`, `IllegalArgumentException timeout`: 0 results each.
- PRs touching `AttemptTimeLimiters.java`: #103 "Upgradejdk8" (closed 2022-07-30, not merged) — removes the 2-arg factory, switches to `SimpleTimeLimiter.create` + 3-arg `callWithTimeout`; no duration check. #95 "Include Full Jitter BackOff support, fixing new Guava compatibility issues" (open) — Guava 23+ compat; no duration check. #83 "first attempt" (closed 2017) — duplicates `checkNotNull(timeUnit)`; no duration check. #107 "Modernize" (closed 2026-09-05, not merged) — deletes the Java sources (PHP port).
- Related-but-different issues: #29 "Retry following timeout" (open; a real `UncheckedTimeoutException` aborts retrying unless an exception predicate is set — rholder: "Without explicit handling of `UncheckedTimeoutException` … the `Retryer` effectively stops retrying"; dirkraft: "the attempt timeout should at a minimum behave like any other exception thrown by an attempt"). #94 / #96 (Guava 22+/23 `SimpleTimeLimiter` constructor compatibility). #92 (process does not exit promptly after `call()` with `fixedTimeLimit`). #18 (resource use of `SimpleTimeLimiter`). #1 (original feature PR, dirkraft: "This provides a mechanism to limit any one single attempt from clobbering a Retryer"). #97/#98/#99 (unformatted `%d` messages of the *eager* `checkArgument` validation in `StopStrategies`/`WaitStrategies` — shows users hit those eager checks with `stopAfterAttempt(0)`).
- spring-retry issue 69 quotes Guava's `checkArgument(timeoutDuration > 0, "timeout must be positive: %s", …)` while comparing libraries; it is not a report of this defect, but shows config-driven `fixedTimeLimit(config.getRetryTimeout(), MILLISECONDS)` + `retryIfException()` usage.

### Commits / blame

- `git blame` on `AttemptTimeLimiters.java:57-72,89-108`: all from `7e474be` (dirkraft, 2013-01-16, "add time limit per attempt in a retryer"); Javadoc touched by `5cc1018` (Ray Holder, 2014-03-15). No commit message mentions duration range, validation, or zero/negative values. `git log --all` messages: none mention timeout validation.

### Comments / docs

- `fixedTimeLimit` Javadoc (`AttemptTimeLimiters.java:47-56, 62-68`): "@param duration that an attempt may persist before being circumvented" — no valid range stated, no statement about zero/negative.
- `AttemptTimeLimiter` (`AttemptTimeLimiter.java:21-22`): "A rule to wrap any single attempt in a time limit, where it will possibly be interrupted if the limit is exceeded."
- `Retryer.call` Javadoc (`Retryer.java:140-154`): "@throws ExecutionException if the given callable throws an exception, and the rejection predicate considers the attempt as successful. … @throws RetryException if all the attempts failed before the stop strategy decided to abort".
- `Attempt` Javadoc (`Attempt.java`): "An attempt of a call, which resulted either in a result returned by the call, or in a Throwable thrown by the call." `getExceptionCause()`: "Gets the exception thrown by the call".
- `RetryException` (`RetryException.java`): "An exception indicating that none of the attempts of the Retryer succeeded." `numberOfFailedAttempts`: "times we've tried and failed".
- Guava 22.0 `TimeLimiter` 4-arg `callWithTimeout` Javadoc: documents `InterruptedException` and `UncheckedTimeoutException`; does not document the IAE. `SimpleTimeLimiter` enforces `timeoutDuration > 0` in every `callWithTimeout`/`runWithTimeout`/`newProxy` variant — Guava treats a non-positive limit as an illegal argument, not as "time out immediately".
- No TODO/FIXME near the site.

### Tests

- `AttemptTimeLimiterTest` uses only `fixedTimeLimit(1, TimeUnit.SECONDS)`; nothing exercises 0/negative durations or asserts the current behavior.

### Library-wide design evidence (eager validation everywhere else)

Every other parameterized built-in strategy validates its numeric arguments in its constructor, at factory-call time: `WaitStrategies.java:237` (`sleepTime >= 0`), `:254-255` (random min/max), `:275` (incrementing), `:294-296` (exponential), `:318-320` (fibonacci); `StopStrategies.java:103` (`maxAttemptNumber >= 1`), `:118` (`maxDelay >= 0`). `fixedTimeLimit` is the only parameterized factory whose numeric argument is unchecked.

## Step 3 — Known-status / precedent

- Upstream tracker (issues + all PRs incl. recently closed #107 on 2026-09-05): no report of this mechanism at this site.
- Prior Specular dataset (`specular-org/specular-case-studies`, systems list and code search for `guava-retrying`/`fixedTimeLimit`): no guava-retrying entry.
- Main forks checked for awareness: `rhuffman/re-retrying` (issues: only "Update to Guava 23"; its `AttemptTimeLimiters.java` has no duration check) and `itning/guava-retrying3` (only dependabot PRs). Neither reports this.
- The known incidents listed in the target guidance (#48, #92, #29, #67, #94) are different mechanisms.

Known-status: not previously reported → `Novelty: NEW`. Code-review × known pre-filter does not apply → proceed to Phase 2.
