# CR-D-22 — Phase 1 investigation (evidence only)

Finding: `stopAfterDelay(d, unit)` truncates the delay to whole milliseconds, so a sub-millisecond limit becomes 0 ms and retrying stops after the first failed attempt.

Source checkout: `worktree/` at `177b6c9b9f3e7957f404f0bdb8e23374cb1de43f` (guava-retrying 2.0.0 release head; same SHA as `/home/ubuntu/scratch/guava-retrying-src/guava-retrying`), clean.

Persistent-findings lookup (`specular findings --work <out> lookup --query stopAfterDelay --query StopAfterDelayStrategy --query toMillis --query sub-millisecond`): `[]` — no prior record.

## Step 1: Code audit

### Cited code

- `src/main/java/com/github/rholder/retry/StopStrategies.java:74-88` — public, non-deprecated factory:
  - Javadoc (:75-79): "If an unsuccessful attempt is made, this StopStrategy will check if the amount of time that's passed from the first attempt has exceeded the given delay amount. If it has exceeded this delay, then using this strategy causes the retrying to stop."
  - `@param duration the delay, starting from first attempt` / `@param timeUnit the unit of the duration` (:81-82). `@return ... stops after {@code delayInMillis} time in milliseconds` (:83) names a parameter (`delayInMillis`) that this overload does not have — copied verbatim from the deprecated overload (:66) by commit 24aa7ef.
  - Body (:87): `return new StopAfterDelayStrategy(timeUnit.toMillis(duration));` — `TimeUnit.toMillis` truncates toward zero for `NANOSECONDS`/`MICROSECONDS` (JDK contract), so 500 µs → 0, 999 999 ns → 0, 1 900 µs → 1, etc. No precondition rejects or rounds sub-ms input.
- `StopStrategies.java:113-126` — `StopAfterDelayStrategy`: constructor only checks `maxDelay >= 0` (:118); `shouldStop` returns `failedAttempt.getDelaySinceFirstAttempt() >= maxDelay` (:124).
- `Retryer.java:156-174` — `call()`: `startTime = System.nanoTime()` (:156); each attempt's delay is `TimeUnit.NANOSECONDS.toMillis(System.nanoTime() - startTime)` (:161/:163, floor to ms); listeners (:166-168); rejection predicate (:170); `if (stopStrategy.shouldStop(attempt)) throw new RetryException(attemptNumber, attempt);` (:173-174).
- `Attempt.java:80-85` — `getDelaySinceFirstAttempt()`: "The delay since the start of the first attempt, in milliseconds." `WaitStrategy.java:27`: "Returns the time, in milliseconds, to sleep before retrying." `StopStrategy.java:26-32`: no resolution statement.

### Arithmetic consequence

With `t` = true elapsed time (ms, real) and `d` = requested limit (ms, real):

- stop condition actually evaluated: `floor(t) >= floor(d)` ⇔ `t >= floor(d)` (since `floor(d)` is an integer).
- documented condition: stop iff `t` has exceeded `d` (target guidance Q5 phrases it as "stop once ... elapsed time since the first attempt reaches the limit").
- For integer-ms `d` (MILLISECONDS, SECONDS, ...) the two agree (up to `>=` vs `>`).
- For `d` with a sub-ms part the strategy stops whenever `floor(d) <= t < d`: up to 0.999… ms early. For `d < 1 ms` (e.g. `stopAfterDelay(500, MICROSECONDS)`, `stopAfterDelay(999_999, NANOSECONDS)`) `floor(d) = 0`, so `shouldStop` is `true` for every attempt: the strategy degenerates to `stopAfterAttempt(1)` regardless of elapsed time.

### Call chain / reachability

User code → `StopStrategies.stopAfterDelay(long, TimeUnit)` (public, the recommended non-deprecated overload) → `RetryerBuilder.withStopStrategy(StopStrategy)` (public, `RetryerBuilder.java:89-94`) → `RetryerBuilder.build()` (`:190-197`) → `Retryer.call(Callable)` (public) → `StopAfterDelayStrategy.shouldStop` at `Retryer.java:173`. Also reachable via `new Retryer(...)` constructors and `Retryer.wrap(...).call()`. Every step is public API in normal usage; no special configuration needed. Any `TimeUnit` is accepted (`@Nonnull TimeUnit timeUnit`).

### Trigger scenario

1. `Retryer<String> r = RetryerBuilder.<String>newBuilder().retryIfException().withStopStrategy(StopStrategies.stopAfterDelay(500, TimeUnit.MICROSECONDS)).build();`
2. `r.call(c)` where `c` throws `IOException` on its first invocation (transient failure, returns immediately) and returns `"ok"` on the second.
3. Attempt 1 fails a few µs after `startTime`; `getDelaySinceFirstAttempt()` = 0; `shouldStop` evaluates `0 >= 0` → true.
4. `call()` throws `RetryException(numberOfFailedAttempts=1)` although far less than 500 µs has passed; the attempt that would have succeeded never runs.

Variant (general shortening): `stopAfterDelay(1900, MICROSECONDS)` → `maxDelay = 1`; a first attempt that fails after ~1.2 ms gives delay 1 → `1 >= 1` → stop at 1.2 ms < 1.9 ms.

Variant (deadline propagation): `stopAfterDelay(deadlineNanos - System.nanoTime(), NANOSECONDS)` with < 1 ms remaining → exactly one attempt.

### Safeguards encountered (recorded, not judged)

- `StopAfterDelayStrategy` constructor check `maxDelay >= 0` (:118) — passes for 0, does not reject it.
- No rounding/ceil anywhere; `Retryer.call` has no minimum-attempt guard; the `RetryException` propagates straight to the `call()` caller (`Retryer.java:174`). No downstream mechanism re-runs the call.
- Composite use (a user's own `StopStrategy` wrapping it) is outside the built-in path.

## Step 2: Developer-knowledge search

- **Commit 24aa7ef** (Stephan Schroevers, 2015-05-03, PR #39 "Fix for issue #30"): "Introduce StopStrategies#stopAfterDelay(long, TimeUnit). For consistency with the AttemptTimeLimiters and WaitStrategies classes, StopStrategies now also accepts (long, TimeUnit) pairs. The original method has been deprecated in favor of its new overload." No mention of sub-ms precision/rounding. The new Javadoc was copied from the ms overload, including the stale `{@code delayInMillis}` @return text.
- **Issue #30** (closed, "Be consistent about "duration" method parameters"): API-consistency request only; owner rholder: "I like consistency, too ... Feel free to open a PR". No discussion of precision.
- **Commit 1e7f2bd** (rholder, 2015-05-10): moved delay into `Attempt` (`TimeUnit.NANOSECONDS.toMillis(System.nanoTime() - startTime)`) and changed `shouldStop` to `failedAttempt.getDelaySinceFirstAttempt() >= maxDelay`. No precision commentary.
- **Commit/PR #16** (2014): "switch time measurement over to System.nanoTime() #15" — elapsed-time measurement precision, a different aspect.
- **Comments/docs near the code**: no TODO/FIXME/"known issue"; README has no `stopAfterDelay` example; HISTORY.md no mention.
- **Existing tests** (`src/test/java/com/github/rholder/retry/StopStrategiesTest.java:40-52`): `testStopAfterDelayWithMilliseconds` (1000 ms) and `testStopAfterDelayWithTimeUnit` (1 SECONDS) assert 999 → false, 1000 → true, 1001 → true. No test uses MICROSECONDS/NANOSECONDS or a sub-ms limit; no test asserts that a sub-ms limit means "stop after one attempt".
- **Related developer evidence**: `AttemptTimeLimiters.fixedTimeLimit(duration, timeUnit)` (`AttemptTimeLimiters.java:57-109`) passes `duration` + `timeUnit` to Guava unchanged (full precision); `WaitStrategies` factories (`WaitStrategies.java:58-199`) truncate with `toMillis` like `stopAfterDelay`.

## Step 3: Known-status / precedent

Searched upstream `rholder/guava-retrying` with `gh search issues --include-prs` (all states) for `stopAfterDelay`, `toMillis`, `microseconds`, `nanoseconds`, `truncat`, `TimeUnit`, `millisecond`, `precision`, `resolution`, `StopAfterDelayStrategy`, `delay`; listed all 45 PRs and all issues (`gh pr list/issue list --state all`), including the most recently closed PRs #107 "Modernize" (closed unmerged 2026-09-05; a PHP port that deletes the Java sources) and #84 (README formatting, closed; last updated 2026-09-20). Checked diffs of #107, #95, #98, #99, #101, #53, #58, #39 for changes to `stopAfterDelay`/`toMillis`/`StopAfterDelayStrategy`.

- #93 (open) "WaitStrategies documentation should mention milliseconds": implicit-ms multipliers in `fibonacciWait`/`exponentialWait` — a different site (WaitStrategies) and a different mechanism (undocumented ms unit of the multiplier), not sub-ms truncation of the stop limit.
- #30 / #39: introduced the overload; no report of truncation.
- #98 / PR #98: `%d` vs `%s` message formatting in `StopAfterDelayStrategy` precondition — different aspect.
- #58: test-only change replacing deprecated calls.
- #52 / PR #53: clock abstraction for `nanoTime` — different aspect.
- Specular case-studies dataset (`specular-org/specular-case-studies`, tree scanned): no guava-retrying entries.

Result: no existing issue/PR/CVE/dataset entry reports THIS mechanism (sub-ms `TimeUnit` limit truncated by `toMillis` in `stopAfterDelay(long, TimeUnit)`). Code-review-sourced but not already reported → no pre-filter drop; proceed to Phase 2.
