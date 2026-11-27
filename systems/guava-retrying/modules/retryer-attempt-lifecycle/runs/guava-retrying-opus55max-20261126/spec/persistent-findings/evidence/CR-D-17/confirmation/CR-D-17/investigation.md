# CR-D-17 — Phase 1 investigation (evidence only)

Source under test: worktree `177b6c9` (`v2.0.0-1-g177b6c9`; differs from tag `v2.0.0` only in `.travis.yml`). Finding source: code review (ledger D-17, not model-checked; no counterexample).

Persistent-findings lookup (`specular findings ... lookup --query ExceptionWaitStrategy --query exceptionWait --query computeSleepTime --query "negative sleep" --query IllegalArgumentException`) returned `[]` — no reusable record.

## Step 1 — Code audit

### Cited code

- `WaitStrategies.java:211-216` — `exceptionWait(Class<T>, Function<T, Long>)` only null-checks its arguments; Javadoc (`:202-210`) says "The {@code function} determines how the sleep time should be calculated ... If the exception does not match, a wait time of 0 is returned." No statement that the function must return a non-negative value, no `@throws`.
- `WaitStrategies.java:386-394` — `ExceptionWaitStrategy.computeSleepTime` returns `function.apply((T) cause)` (`:390`) unmodified (auto-unboxed `Long` → `long`). No clamp, no check.
- Contrast, the other built-ins whose value is computed per attempt clamp to `>= 0`:
  - `IncrementingWaitStrategy` `:282-283` — `increment` is NOT validated (may be negative), and the result is clamped: `return result >= 0L ? result : 0L;` (present since the original 2012 code, `6d2d838`).
  - `ExponentialWaitStrategy` `:305-308` — clamp to `maximumWait`, then `>= 0`.
  - `FibonacciWaitStrategy` `:330-334` — overflow (`result < 0L`) mapped to `maximumWait`, then `>= 0` (added in `ce0bc7d`).
  - Constant-valued built-ins validate at construction: `FixedWaitStrategy` `:237` (`sleepTime >= 0`), `RandomWaitStrategy` `:254-255`.
- `WaitStrategies.java:364-371` — `CompositeWaitStrategy` (`join`) sums component values with no clamp, so a negative component lowers the sum, and a large enough negative makes the sum negative.
- `WaitStrategy.java:26-32` — `computeSleepTime` "Returns the time, in milliseconds, to sleep before retrying."
- `Retryer.java:176-182` — `long sleepTime = waitStrategy.computeSleepTime(attempt); try { blockStrategy.block(sleepTime); } catch (InterruptedException e) {...}` — no validation of `sleepTime`; only `InterruptedException` is caught.
- `BlockStrategies.java:44-47` — `ThreadSleepStrategy.block` = `Thread.sleep(sleepTime)`. JDK `Thread.sleep(long)` throws `IllegalArgumentException("timeout value is negative")` for a negative argument.
- `RetryerBuilder.java:194` — `threadSleepStrategy()` is the default block strategy.
- `Retryer.java:140-154` — `call()` Javadoc documents exactly two failure outcomes: `ExecutionException` (callable threw and the rejection predicate accepted the attempt) and `RetryException` (stop strategy aborted, or interrupted).

### Call chain (all public API)

`RetryerBuilder.newBuilder().retryIfExceptionOfType(E.class).withWaitStrategy(WaitStrategies.exceptionWait(E.class, fn)).withStopStrategy(...).build()` → `Retryer.call(callable)` → attempt 1 throws `E` → `ExceptionAttempt` (`Retryer.java:163`) → rejection predicate accepts retry (`:170`) → stop strategy says continue (`:173`) → `ExceptionWaitStrategy.computeSleepTime` returns `fn.apply(e)` (`WaitStrategies.java:390`) → `ThreadSleepStrategy.block(negative)` (`BlockStrategies.java:46`) → `Thread.sleep` throws IAE → not caught at `Retryer.java:179` → escapes `call()`.

Also reachable via `Retryer.wrap(callable)` → `RetryerCallable.call()` (`Retryer.java:316-319`) submitted to an executor; and via `join(..., exceptionWait(...), ...)` (`WaitStrategies.java:225-230`, `:364-371`).

Reachability: normal usage. `exceptionWait` is a public factory intended for server-guided back-off; the project's own test uses a `RetryAfterException` (`WaitStrategiesTest.java:164-168, 205-211`).

### Trigger scenario

A user converts a server-supplied *absolute* retry time into a sleep: `fn = e -> e.retryAtMillis - System.currentTimeMillis()` (HTTP `Retry-After: <HTTP-date>` per RFC 9110 §10.2.3, `X-RateLimit-Reset` epoch seconds, etc.). When the retry time has already passed by the time the attempt fails or the function runs — clock skew between client and server, network/processing latency, or the 1-second resolution of HTTP-date — `fn` returns a negative number. With the default block strategy, `call()` throws `IllegalArgumentException: timeout value is negative` after one attempt, even though the stop strategy permits more attempts and the correct behavior would be "retry now".

In `join(fixedWait(base), exceptionWait(E.class, fn))`, the negative value is subtracted from `base` (wait shorter than the configured fixed minimum), and when `|fn| > base` the sum is negative → same IAE.

### Safeguards encountered (recorded, to be tested in Phase 2)

- None in the library: no clamp in `ExceptionWaitStrategy` or `CompositeWaitStrategy`, no validation in `Retryer.call`, `ThreadSleepStrategy` passes the value through.
- A custom `BlockStrategy` that ignores negatives (e.g. `LockSupport.parkNanos`) would hide the IAE, but it is not the default (`RetryerBuilder.java:194`).
- The user can clamp inside their own function — a workaround, not a library safeguard.

## Step 2 — Developer-knowledge search

- Commit `9c6bd63` (2014-11-04, Yaroslav Matveychuk; upstream PR #24 / #26, issue #25 "Calculate sleep time from failed attempt"): introduced `AttemptWaitStrategy` (later renamed `ExceptionWaitStrategy` in `dbe616d`) returning `function.apply(...)` unclamped. PR #26 maintainer comment (rholder, 2015-05-02): "I kind of like the idea of having the last `Attempt` available for inspection..." — nothing about the value range.
- Commit `dbe616d` (2015-06-21) "some minor refactoring and renaming for #25, suppress warnings" — rename only.
- Clamps in the other strategies: `IncrementingWaitStrategy` clamp since the original code (`6d2d838`, 2012); Fibonacci overflow handling `ce0bc7d` (2013). No commit message states a policy, but every built-in that computes a value per attempt clamps it to `>= 0`.
- Comments/docs: no TODO/FIXME/"by design" near `ExceptionWaitStrategy`. Javadoc of `exceptionWait` silent on sign. README never mentions `exceptionWait`.
- Tests: `WaitStrategiesTest.testExceptionWait` (`:157-168`) covers 0, 3 600 000 and 29 ms, and the non-matching-exception case; no negative-value test, no test of `exceptionWait` inside `Retryer.call`.
- Upstream issue #63 ("Why WaitStrategy use BlockStrategy#block to sleep?") and open PR #101 ("Not calling Thread.sleep() if sleepTime is Zero", only `== 0L`, unmerged) concern the block step, not negative values.

## Step 3 — Known-status / precedent

Searches run 2026-11-26:

- `gh search issues --repo rholder/guava-retrying --include-prs` for: `exceptionWait`, `negative`, `IllegalArgumentException`, `"timeout value is negative"`, `exceptionalWait`, `ExceptionWaitStrategy`, `Retry-After`, `retry after`, `sleep time negative`, `computeSleepTime` — no hit describing this mechanism (hits: #97/#99 unformatted `StopStrategies` message; #86, #28, #45, #63, #65 unrelated).
- Full dump of all 106 upstream issues/PRs (`repos/rholder/guava-retrying/issues?state=all`, max #107), title+body grep for `negative|exceptionWait|ExceptionWait|AttemptWaitStrategy|IllegalArgument|timeout value|retry.?after|clamp|Thread.sleep|sleepTime|computeSleepTime` — only #20, #24, #26, #28, #45, #63, #65, #86, #97, #99, #101; none reports this defect.
- Recently closed/merged PRs: #107 "Modernize" closed 2026-09-05, `merged=false` (author: "This was supposed to go under my fork"); #84 README only. Open PR #95 (full-jitter) does not touch `ExceptionWaitStrategy`; open PR #101 skips only `sleepTime == 0`.
- GitHub-wide issue search (`exceptionWait negative`, `exceptionWait IllegalArgumentException`, `guava-retrying "timeout value is negative"`, `WaitStrategies.exceptionWait negative sleep`, `guava-retrying negative sleep time`) — no results.
- Forks: `rhuffman/re-retrying` (41 issues/PRs) and `itning/guava-retrying3` issue lists — no report; both forks still return `function.apply(cause)` unclamped and still call `Thread.sleep(sleepTime)` directly.

Known-status: not previously reported → Novelty NEW. Code-review × known pre-filter does not apply → proceed to Phase 2.
