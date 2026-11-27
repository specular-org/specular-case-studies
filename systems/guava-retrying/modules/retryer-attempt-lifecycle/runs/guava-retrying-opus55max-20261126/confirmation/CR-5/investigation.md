# CR-5 — Phase 1 investigation (evidence only)

Finding: Code-review Scenario 5 — post-attempt decision steps run outside the attempt's try/catch and built-in wait/stop arithmetic is unchecked. Source: code review (no MC counterexample for the arithmetic; MC-10 models only the block-step composition, MC-7 the listener-loop CME).

Assignment from the dispatcher: ledger rows D-16..D-22 are confirmed as **separate** candidates; this candidate must look for **other** defects in the same mechanism and report plainly if there are none. Excluded from CR-5's own scope (already separate candidates): D-16 (join sum overflow → negative sleep → IAE), D-17 (exceptionWait negative pass-through → IAE), D-18 (exceptionWait null → NPE), D-19 (int attempt counter wrap), D-20 (incrementingWait overflow), D-21 (Fibonacci positive wrap below the cap), D-22 (sub-ms truncation in stopAfterDelay), MC-10 (unvalidated negative sleep escapes as IAE, pre-empting RetryException), MC-7 / D-8 (listener-loop CME under builder mutation).

Source under test: worktree at `177b6c9` (src/main identical to tag `v2.0.0`), unmodified, `git status` clean.

## Step 1 — Code audit

### Cited sites (read in full)

- `Retryer.java:155-185` (`call`). The try/catch covers only the attempt (`:159-164`, `catch (Throwable t)` at `:162`). Outside it, in order: listener loop `:166-168`, rejection predicate `:170-172` (`return attempt.get()` at `:171`), stop check `:173-174` (`throw new RetryException(attemptNumber, attempt)`), wait computation `:176`, block `:177-182` (only `InterruptedException` is caught, `:179-181`, which restores the flag and throws `RetryException`). Any other `Throwable` from `:166-182` escapes `call()` unchanged.
- `Retryer.java:157` `for (int attemptNumber = 1; ; attemptNumber++)` — int counter; attempts store it as `long` (`:202`, `:250`), `RetryException` stores `int` (`RetryException.java:34`, `:44`).
- `Retryer.java:156,161,163` — `delaySinceFirstAttempt = NANOSECONDS.toMillis(System.nanoTime() - startTime)` (floor to ms; monotonic clock; difference cannot overflow for < 292 years).
- `BlockStrategies.java:44-47` — `Thread.sleep(sleepTime)` with no validation; `Thread.sleep` throws `IllegalArgumentException` for negative values before it checks the interrupt flag (JDK 11/21 `Thread.sleep` / `JVM_Sleep`).
- `WaitStrategies.java` arithmetic inventory (complete, by grep over src/main):
  - `:60,73,93-94,114-115,139,157,181,199` `TimeUnit.toMillis` at construction (floors sub-ms, saturates at ±Long.MAX_VALUE).
  - `:263-264` RandomWait `Math.abs(RANDOM.nextLong()) % (maximum - minimum) + minimum` (range is in (0, Long.MAX_VALUE] by the constructor checks at `:254-255`).
  - `:282-283` IncrementingWait `initialSleepTime + increment * (n - 1)`, clamped to `>= 0` (increment unchecked) — D-20.
  - `:303-308` ExponentialWait `Math.round(multiplier * Math.pow(2, n))`, capped and clamped.
  - `:327-334`, `:337-352` FibonacciWait `multiplier * fib(n)`, guard `result > maximumWait || result < 0L` — D-21 for positive wraps; `fib` is O(n).
  - `:366-370` join sum (unchecked) — D-16.
  - `:386-394` exceptionWait pass-through of a user `Long` (unboxing at `:390`) — D-17, D-18.
- `StopStrategies.java:85-88` `toMillis` floor (D-22); `:107-110` `n >= maxAttemptNumber` (int bound, checked `>= 1` at `:103`); `:122-125` `delay >= maxDelay` (checked `>= 0` at `:118`).
- Built-in rejection predicates `RetryerBuilder.java:199-249` (`ExceptionClassPredicate`, `ResultPredicate`, `ExceptionPredicate`, plus Guava `Predicates.alwaysFalse/or`): guarded by `hasException()`/`hasResult()`; the exception cause is never null (`ExceptionAttempt` wraps the caught non-null `Throwable` in a fresh `ExecutionException`, `Retryer.java:253-254`, `:280-282`).
- `RetryException.java:56-59` — `checkNotNull(lastFailedAttempt)`; the loop always passes a non-null attempt.

### Call chain and reachability

Public entry: `RetryerBuilder.newBuilder()…build()` (`RetryerBuilder.java:190-197`) or the `Retryer` constructors → `Retryer.call(callable)` (also via `wrap(callable).call()`, `Retryer.java:195-197`, `:317-319`). Every attempt whose rejection predicate returns true runs listeners → predicate → stop → wait → block on the caller thread. All built-in strategies are selected through public factories (`WaitStrategies.*`, `StopStrategies.*`, `BlockStrategies.threadSleepStrategy()`, the builder's `retryIf*`). The path is reached in normal usage on every retried attempt; the arithmetic extremes need extreme factory parameters, extreme attempt counts, or sub-ms units.

### Safeguards encountered (recorded, not judged)

- Construction checks: `FixedWait >= 0` (`:237`), `RandomWait min >= 0, max > min` (`:254-255`), `Incrementing initial >= 0` (`:275`), `Exponential/Fibonacci multiplier > 0, max >= 0, multiplier < max` (`:294-296`, `:318-320`), `stopAfterAttempt >= 1` (`StopStrategies.java:103`), `stopAfterDelay >= 0` (`:118`), `join` non-empty / non-null (`:226-228`).
- Result clamps `>= 0` at `:283`, `:308`, `:334`; Fibonacci negative-wrap guard at `:330`; `Math.round` saturation in ExponentialWait.
- `Thread.sleep(0)` still checks the interrupt flag (JDK 8/11/21 `JVM_Sleep`), so `noWait` keeps the documented interrupt exit.
- `stopAfterAttempt(int)` fires before the int counter can wrap.
- No safeguard validates the value passed from `computeSleepTime` to `block` (that gap is MC-10 / D-16 / D-17).

### Trigger hypotheses for "other" defects (to test in Phase 2)

H-a Built-in predicates or stop strategies throwing for some reachable attempt. H-b ExponentialWait negative, decreasing, or above the cap for any multiplier/cap/attempt number ≤ 2^31-1 (including `double` precision loss for multipliers > 2^53). H-c RandomWait outside `[min, max)` (including the `Math.abs(Long.MIN_VALUE)` path). H-d FixedWait/RandomWait/Exponential/Fibonacci factory `toMillis` saturation producing a negative or wrapped value outside `join`. H-e IncrementingWait with a negative increment (decreasing, or wrapping upward). H-f stopAfterAttempt off-by-one at 1 / N / Integer.MAX_VALUE. H-g stopAfterDelay stopping early with an integral-ms limit, or never stopping because of saturation. H-h `RetryException` count / last attempt / cause wrong on the stop exit or the sleep-interrupt exit (below the D-19 wrap). H-i Interrupt delivered before or during the decision steps not producing `RetryException` + flag with built-in strategies (except the D-16/D-17/MC-10 pre-emption). H-j Listener notification order/count or attempt-number/delay monotonicity broken. H-k `fib(n)` O(n) cost making the effective delay exceed the configured maximum in reachable ranges. H-l `fib(long n)` with `n == Long.MAX_VALUE` loops forever (`i <= n` never false) — reachability: the real loop only produces int attempt numbers.

## Step 2 — Developer knowledge

- Issue tracker (live `gh`, 2026-11-26): all 61 issues and 45 PRs listed (latest activity: PR #107 "Modernize", closed unmerged 2026-09-05, a PHP port; PR #84 README, closed 2026-09-20). Keyword searches (`negative`, `overflow`, `IllegalArgumentException`, `timeout value is negative`, `NullPointerException`, `Integer.MAX_VALUE`, `attempt number`, `exceptionWait`, `join`, `composite`, `microseconds`, `truncate`, `sleepTime`, `fibonacci`, `incrementing`, `Long.MAX_VALUE`, `getNumberOfFailedAttempts`) plus two GitHub-wide searches found no report of an exception escaping a decision step, a negative/overflowing computed sleep, a wrong failure count, or a stop-boundary error. Related but different: #63 (a user `BlockStrategy` that does not sleep), #93 (docs should mention milliseconds), #97/#99 (`%d` message formatting), #101 (skip `sleep(0)`), #86 (first exponential wait is 2×multiplier), #12/PR #17 (join introduced), #25/PR #26 (exceptionWait introduced), PR #9 (Fibonacci introduced), #28 (random-exponential proposal reusing the same clamp pattern).
- Commits/blame: clamps `result >= 0L ? result : 0L` date from `fd8b13b` ("Adding exponential wait strategy and unit tests", 2012) and `ce0bc7d` (Fibonacci, 2013); the Fibonacci negative guard `result < 0L` at `:330` from `5cc1018`; join from `2b5bfec` (#12); exceptionWait from `9c6bd63`/`dbe616d` (#25); the decision-step order from `6d2d838`/`fbe3177`/`a96183d`/`1edb757`/`1e7f2bd`. No commit message describes overflow handling or a decision that exceptions from strategies should escape.
- Comments/docs: no TODO/FIXME/known-issue in src/main. Contract text: `Retryer.call` Javadoc `:146-153` (return / `ExecutionException` / `RetryException`, interrupt → `RetryException` + flag); `WaitStrategy.computeSleepTime` "Returns the time, in milliseconds, to sleep" (sign not stated); factory Javadoc: exponential/Fibonacci grow "up to the maximumTime", join waits "total of all wait times", incrementing "increment added to the previous sleep time", `stopAfterAttempt` "stops after N failed attempts", `stopAfterDelay` "has exceeded the given delay".
- Tests: `WaitStrategiesTest` asserts the caps hold at attempt `Integer.MAX_VALUE` (`:103`, `:116`, `:140`, `:153`) — developers expect extreme attempt counts to stay capped; `StopStrategiesTest:41-51` asserts `>=` boundaries (1000 ms stops at delay 1000); `RetryerBuilderTest:55-83` joins with a `Long.MAX_VALUE`-capped Fibonacci; no test covers a negative increment, a sub-ms stop limit, an overflowing join, or exceptions from decision steps.

## Step 3 — Known-status / precedent

- Persistent findings: `specular findings --work <output> lookup --query Retryer.call --query CompositeWaitStrategy --query ThreadSleepStrategy --query WaitStrategies --query StopStrategies --query "IllegalArgumentException negative sleep"` → `[]`; `persistent-findings-context.json` has `previous: null`, no inherited records. No prior Specular dataset entry for guava-retrying (`case-studies/` has no guava-retrying entry).
- Upstream: no issue/PR/CVE reports this mechanism (see Step 2), including recently closed PRs.
- Pre-filter: not code-review × known → proceed to Phase 2. Novelty, if a new defect is found: NEW.
