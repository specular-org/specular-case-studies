# CR-D-19 — Phase 1 investigation (evidence only)

Finding: the `int` attempt counter in `Retryer.call` wraps after 2^31-1 attempts; attempt numbers become non-positive, `RetryException` reports the count modulo 2^32, and growing waits collapse to 0.
Source: code review (ledger D-19, scenario 5; not model-checked, no counterexample).
Source tree audited: `confirmation/CR-D-19/worktree` @ `177b6c9` (guava-retrying 2.0.0 + travis workaround), unmodified.

## Step 0: persistent-findings lookup

`specular findings --work .specular-output lookup --query "attemptNumber overflow" --query "RetryException numberOfFailedAttempts" --query "Retryer.call int counter wrap"` returned `[]` (no inherited records; `persistent-findings-context.json` has `previous: null`).

## Step 1: code audit

### Cited code (verbatim)

- `Retryer.java:157` — `for (int attemptNumber = 1; ; attemptNumber++) {` — the only attempt counter; `int`, unbounded loop, no overflow check.
- `Retryer.java:161` — `attempt = new ResultAttempt<V>(result, attemptNumber, ...)`; `Retryer.java:163` — `attempt = new ExceptionAttempt<V>(t, attemptNumber, ...)`. The `int` is widened to the `long attemptNumber` field (`Retryer.java:202`, `:250`), so after the wrap the stored `long` is negative (sign-extended), never > 2^31-1.
- `Retryer.java:166-168` — every attempt is passed to every `RetryListener.onRetry(attempt)`.
- `Retryer.java:173-174` — `if (stopStrategy.shouldStop(attempt)) { throw new RetryException(attemptNumber, attempt); }`
- `Retryer.java:176` — `long sleepTime = waitStrategy.computeSleepTime(attempt);`
- `Retryer.java:178-181` — `blockStrategy.block(sleepTime)`; on `InterruptedException`: re-interrupt and `throw new RetryException(attemptNumber, attempt);`
- `RetryException.java:34` — `private final int numberOfFailedAttempts;`
- `RetryException.java:44-46` — `public RetryException(int numberOfFailedAttempts, ...)` builds the message `"Retrying failed to complete successfully after " + numberOfFailedAttempts + " attempts."`
- `RetryException.java:62-69` — `public int getNumberOfFailedAttempts()`, Javadoc "Returns the number of failed attempts".
- `Attempt.java:73-78` — `/** The number, starting from 1, of this attempt. */ public long getAttemptNumber();`

### Consumers of the attempt number

- User `RetryListener`s (`Retryer.java:166-168`) — receive `attempt.getAttemptNumber()`.
- `StopStrategies.StopAfterAttemptStrategy.shouldStop` (`StopStrategies.java:108-110`): `failedAttempt.getAttemptNumber() >= maxAttemptNumber` with `int maxAttemptNumber >= 1` (`StopStrategies.java:54`, `:103`). Because the limit is an `int` <= `Integer.MAX_VALUE`, this strategy always stops at or before attempt 2^31-1, i.e. before the wrap. It cannot reach the wrapped state.
- `StopAfterDelayStrategy` (`StopStrategies.java:122-125`) and `NeverStopStrategy` (`:91-95`) do not read the attempt number; with them the loop can run past 2^31-1 attempts.
- Built-in wait strategies that read the attempt number:
  - `IncrementingWaitStrategy` (`WaitStrategies.java:281-284`): `initialSleepTime + increment * (n - 1)`, clamped at 0. For `n = Integer.MIN_VALUE` and a positive increment the result is negative → 0. For a negative increment (accepted: only `initialSleepTime >= 0` is checked, `:275`) the result flips to a large positive value (e.g. `increment = -1 ms` → 2,147,483,649 ms).
  - `ExponentialWaitStrategy` (`WaitStrategies.java:302-309`): `Math.round(multiplier * Math.pow(2, n))`; for `n <= -1075` `Math.pow` gives `0.0` → 0.
  - `FibonacciWaitStrategy` (`WaitStrategies.java:326-352`): `fib(n)` returns 0 for `n < 0` (loop body never runs) → 0. `fib(n)` is O(n) per call.
- `RetryException` constructor / getter (above) — the count is stored and returned as the same `int`.
- No other reader; nothing re-derives or corrects the count.

### Call chain (public entry points)

`RetryerBuilder.newBuilder()...build()` (`RetryerBuilder.java:190-197`, defaults: `noTimeLimit`, `neverStop`, `noWait`, `threadSleepStrategy`) or one of the public `Retryer` constructors → `Retryer.call(callable)` (`Retryer.java:155`) or `Retryer.wrap(callable).call()` (`Retryer.java:195-197`, `:317-319`) → loop at `:157`. Reachable through normal use; no internal API needed.

### Reachability

- Needs > 2^31-1 = 2,147,483,647 rejected attempts inside one `call()`. This requires a stop strategy that does not stop by attempt count (`neverStop` — the builder default — `stopAfterDelay`, or a custom one) and a rejection predicate that keeps rejecting (e.g. `retryIfResult(...)` polling a condition, `retryIfException()` with a persistently failing callable).
- Speed: with the builder defaults the per-attempt cost is the callable + `Thread.sleep(0)` (a `sched_yield`); the finding's analysis measured ~6.1e5 attempts/s → ~59 min to the first wrap. To be measured in Phase 2 on this host.
- With built-in growing waits the wrap is only reachable at very different costs:
  - `exponentialWait`: `multiplier >= 1` and `maximumWait > multiplier` force every sleep to be >= 2 ms → >= 2^31 x 2 ms ≈ 50 days of continuous retrying (any realistic cap, e.g. 1 s, → ~68 years).
  - `fibonacciWait`: O(n) `fib` per attempt → ~n²/2 ≈ 2.3e18 loop iterations before attempt 2^31 (decades of CPU), independent of sleeping; practically unreachable.
  - `incrementingWait` with positive increment >= 1 ms: total sleep ≈ increment x n²/2 → unreachable. With increment 0 nothing changes after the wrap. With a negative increment the sleeps clamp to 0 after a few attempts, so the wrap is reached at the same speed as `noWait`, and then the computed sleep becomes huge (see above).
- `stopAfterAttempt(int)` is a de-facto guard only for that one strategy (see above).

### Safeguards encountered (recorded, not judged)

- None on the counter itself (no `Math.addExact`, no `long`, no cap).
- `stopAfterAttempt` cannot reach the wrap (int limit).
- `ExponentialWaitStrategy`/`FibonacciWaitStrategy`/`IncrementingWaitStrategy` clamp negative results to 0 (`result >= 0L ? result : 0L`); this turns the wrapped attempt number into a 0 sleep rather than an exception.
- Nothing downstream rewrites `RetryException.numberOfFailedAttempts` (final field).

### Trigger scenario

1. Build a retryer with the builder defaults (`neverStop`, `noWait`, `Thread.sleep` block) or `stopAfterDelay(D)` with no wait, plus a rejection predicate that keeps rejecting (e.g. polling a condition that stays false), optionally a `RetryListener` that logs or keys by `getAttemptNumber()`.
2. `retryer.call(callable)` keeps retrying for more than 2^31-1 attempts (≈ 1 h at the defaults).
3. Attempt 2,147,483,648 is delivered to listeners/strategies with `getAttemptNumber() == -2147483648`; numbers then run up through 0 and restart at 1 after 2^32 attempts.
4. The call ends with `RetryException` either because `stopAfterDelay` stops, or because another thread interrupts the caller (`Thread.sleep(0)` throws `InterruptedException` → `Retryer.java:179-181`). `getNumberOfFailedAttempts()` and the message report `(int) actualCount`.

## Step 2: developer-knowledge search

- **Blame.** `Retryer.java:157` (`int attemptNumber`) and `RetryException.java:34/44/67` (`int`) date from the initial import `6d2d838b` (Ray Holder, 2012-11-17). `Attempt.getAttemptNumber()` returning `long` (`Attempt.java:73-78`) and passing the `int` counter into the `long` attempt fields came with `1e7f2bdc` (Ray Holder, 2015-05-10): "refactoring Attempt interface to simplify state handling for attempt number and delay since first attempt, this should allow us to build even more elaborate stop and wait strategies moving forward, related to #25 #36". Before that commit the strategies took `int previousAttemptNumber` ("the number of the previous attempt (starting from 1)").
- **Comments / docs.** No comment near the counter about overflow or a maximum. `Attempt` Javadoc promises "The number, starting from 1, of this attempt". `RetryException.getNumberOfFailedAttempts` Javadoc: "Returns the number of failed attempts". `StopStrategies.neverStop` Javadoc warns only about abusing services with small wait intervals. README mentions overflow only for a recursive Fibonacci (`StackOverflowError`), not for the counter.
- **Tests.** `WaitStrategiesTest` probes wait strategies with `failedAttempt(Integer.MAX_VALUE, 0)` (`WaitStrategiesTest.java:103,116,140,153`) — the largest attempt number the developers test is `Integer.MAX_VALUE`, positive; no test covers > 2^31-1 attempts or non-positive numbers. `RetryerBuilderTest.testRetryListener_*` (`RetryerBuilderTest.java:463-500`) keys a `Map<Long, Attempt>` by `attempt.getAttemptNumber()` and expects keys 1..6 — listeners are expected to see unique, 1-based numbers. `RetryerBuilderTest` asserts `getNumberOfFailedAttempts() == 3` after 3 attempts (lines 111, 154, ...).
- **Upstream tracker** (`gh api repos/rholder/guava-retrying/issues?state=all` — 106 issues+PRs incl. closed/merged and the PRs closed in 2026: #84 2026-09-20, #107 2026-09-05; plus all issue comments and PR review comments): no issue/PR mentions overflow, wrap-around, negative attempt numbers, or a wrong `getNumberOfFailedAttempts`. Keyword grep (`overflow|integer.max|max_value|wrap|negative attempt|attempt ?number|attemptNumber|numberOfFailedAttempts|2147483647|long attempt`) hits only unrelated code snippets (custom stop strategy, `RetryException` usage, a JVM "buffer overflow" crash log, #23 "Getting attempt number on success"). #107 "Modernize" (closed, not merged) deletes the Java sources and replaces them with a PHP port — unrelated.
- **Fork** `rhuffman/re-retrying` issue #27 (closed 2018-02-24, by the fork maintainer): "Attempt.getAttemptNumber can return int instead of long — It makes little sense to have the Retryer retry more than Integer.MAX_VALUE times, and, in fact, the Retryer uses an int variable to iterate. Therefore, the attempt number can be an int." Resolved by fork commit `fef672fa` narrowing `getAttemptNumber()` to `int`; the loop counter stays `int` and still wraps. This is a design note in a different project that dismisses the > Integer.MAX_VALUE case; it does not report the wrap or its consequences and does not fix it.
- GitHub-wide issue search (`guava-retrying attempt number overflow`, `RetryException getNumberOfFailedAttempts int overflow`): no results. re-retrying issue search for `overflow`, `attemptNumber`, `negative attempt`: none other than #27.

## Step 3: known-status

- No upstream issue / PR / CVE / advisory reports this defect (int counter wrap → non-positive attempt numbers / wrong `RetryException` count / wait collapse). Recently closed PRs checked (#84, #107, #103, #78): unrelated.
- No prior Specular dataset entry (persistent-findings lookup empty; Specular `case-studies/` has no guava-retrying entry).
- The fork's #27 is developer awareness of the `int` counter in another project, framed as "retrying more than Integer.MAX_VALUE times makes little sense"; per the skill this is not a filed report of this defect.
- → Novelty: NEW. Not dropped; proceed to Phase 2.
