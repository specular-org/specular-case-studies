# CR-D-20 — Phase 1 investigation (evidence only)

Finding: `incrementingWait` overflows `initial + increment * (n - 1)` for increments near `Long.MAX_VALUE`, alternating sleeps with immediate retries. Source: code review (ledger row D-20; not model-checked, no counterexample).

Source under test: `confirmation/CR-D-20/worktree`, HEAD `177b6c9b9f3e7957f404f0bdb8e23374cb1de43f` (= upstream `rholder/guava-retrying` master; `git diff v2.0.0 HEAD` touches only `.travis.yml`), working tree clean.

Persistent-findings lookup (`specular findings lookup --query IncrementingWaitStrategy --query incrementingWait --query computeSleepTime --query overflow`): `[]` — no prior record.

## Step 1 — Code audit

### Cited code

`src/main/java/com/github/rholder/retry/WaitStrategies.java:108-116` (factory):

```java
public static WaitStrategy incrementingWait(long initialSleepTime,
                                            @Nonnull TimeUnit initialSleepTimeUnit,
                                            long increment,
                                            @Nonnull TimeUnit incrementTimeUnit) {
    Preconditions.checkNotNull(initialSleepTimeUnit, ...);
    Preconditions.checkNotNull(incrementTimeUnit, ...);
    return new IncrementingWaitStrategy(initialSleepTimeUnit.toMillis(initialSleepTime),
            incrementTimeUnit.toMillis(increment));
}
```

`TimeUnit.toMillis` saturates to `Long.MAX_VALUE` / `Long.MIN_VALUE` on overflow, so e.g. `incrementTimeUnit = DAYS, increment = Long.MAX_VALUE` yields `increment == Long.MAX_VALUE` ms.

`WaitStrategies.java:273-284` (strategy):

```java
public IncrementingWaitStrategy(long initialSleepTime, long increment) {
    Preconditions.checkArgument(initialSleepTime >= 0L, ...);   // :275 — increment is NOT validated
    this.initialSleepTime = initialSleepTime;
    this.increment = increment;
}
public long computeSleepTime(Attempt failedAttempt) {
    long result = initialSleepTime + (increment * (failedAttempt.getAttemptNumber() - 1)); // :282 unchecked long mul+add
    return result >= 0L ? result : 0L;                                                     // :283 negative -> 0
}
```

Arithmetic (two's complement, `I = initialSleepTime`, `M = Long.MAX_VALUE`, attempt `n`):
- `n-1 = 2k` (even): `M*2k ≡ -2k (mod 2^64)`, so `result = I - 2k` (positive while `2k < I`).
- `n-1 = 2k+1` (odd): `M*(2k+1) ≡ M - 2k`, so `I + M - 2k` overflows to a negative value while `2k < I` → clamped to `0`.
- For `I = 1000`: requested sleeps are `1000, 0, 998, 0, 996, 0, ...` (decreasing, alternating with 0). For `n >= 1002` odd branch stops overflowing and returns `≈ Long.MAX_VALUE - (2k - I)` (huge), even branch is negative → 0.

### Call chain (public API → cited code → consumer)

1. User: `RetryerBuilder.newBuilder().withWaitStrategy(WaitStrategies.incrementingWait(...))` — `RetryerBuilder.java:75-80` only null-checks / single-assignment checks; `build()` (`:190-197`) passes the strategy unchanged into `Retryer`.
2. `Retryer.call` (`Retryer.java:155-185`): after a rejected attempt and `stopStrategy.shouldStop == false`, `:176 long sleepTime = waitStrategy.computeSleepTime(attempt);` then `:178 blockStrategy.block(sleepTime);`.
3. Default block strategy `BlockStrategies.ThreadSleepStrategy.block` (`BlockStrategies.java:45-47`) → `Thread.sleep(sleepTime)`; `Thread.sleep(0)` returns immediately, so the next attempt starts at once.

Reachability: normal usage — all values pass every precondition in the factory, constructor, builder and `Retryer` constructor. No caller-side guard exists between `computeSleepTime` and `block`. `Attempt.getAttemptNumber()` is `long` (`Attempt.java:78`), so the multiply is done in `long`.

### Trigger scenario

`incrementingWait(1000, MILLISECONDS, Long.MAX_VALUE, MILLISECONDS)` (or the saturating `incrementingWait(1, SECONDS, Long.MAX_VALUE, DAYS)`), `retryIfException()`/`retryIfResult(...)`, any stop strategy that permits ≥3 attempts (e.g. `stopAfterAttempt(6)`), a callable that keeps failing. Expected per the factory Javadoc: second sleep = `1000 + increment` (not representable; saturation ⇒ effectively unbounded). Actual: sleep after attempt 2 is `0` → attempt 3 starts immediately; then 998 ms, then 0 again, etc.

Realism note (recorded, not judged): overflow within a realistic number of attempts needs an astronomically large increment (≥ ~`Long.MAX_VALUE/(n-1)` ms) — in practice a `Long.MAX_VALUE`-style "infinite" sentinel, a config value, or a saturating `TimeUnit` conversion. For moderate increments the `int` attempt counter in `Retryer.call` (`Retryer.java:157`) cannot reach the overflow point before ~2^31 attempts. The target guidance (Priority Question 5) explicitly puts "extreme attempt counts, durations or parameters" yielding "a negative, decreasing or above-maximum sleep" in scope.

### Safeguards encountered

- `:283` clamp `result >= 0L ? result : 0L` — prevents a negative `Thread.sleep` (`IllegalArgumentException`) but turns the overflowed product into `0` (immediate retry). It does not detect overflow.
- No validation of `increment` (sign or magnitude) anywhere.
- No downstream correction: `Retryer.call` consumes the value directly.

## Step 2 — Developer-knowledge search

- **Javadoc** (`WaitStrategies.java:97-107`): "Returns a strategy that sleeps a fixed amount of time after the first failed attempt and in incrementing amounts of time after each additional failed attempt." `@param increment the increment added to the previous sleep time after each failed attempt`; `@return a wait strategy that incrementally sleeps an additional fixed time after each failed attempt`. No statement about overflow or limits. `WaitStrategy.computeSleepTime` Javadoc (`WaitStrategy.java:26-32`): "Returns the time, in milliseconds, to sleep before retrying."
- **History / blame**: formula and clamp come unchanged from the original import "Adding original source code from JB" (`c531b61`, 2012-08-26, `fr.free.jnizet.retry`); only the parameter was renamed in `1e7f2bd` (2015-05-10, Attempt refactor, #25/#36). No commit message discusses overflow for this strategy. The clamp predates any overflow discussion and coincides with `increment` being allowed negative (decrementing waits floor at 0).
- **Sibling strategies in the same file (developer intent for overflow)**: `FibonacciWaitStrategy.computeSleepTime` (`WaitStrategies.java:326-335`, added in `ce0bc7d` "Implement FibonacciWaitStrategy"): `if (result > maximumWait || result < 0L) { result = maximumWait; }` — overflow saturates *up* to the maximum. `ExponentialWaitStrategy` uses `Math.round(double)` which saturates at `Long.MAX_VALUE`, then caps at `maximumWait` (`:302-309`); factory Javadoc `exponentialWait()` says "up to Long.MAX_VALUE".
- **Tests**: `WaitStrategiesTest.testIncrementingWait` (`WaitStrategiesTest.java:45-50`) only checks `500, 600, 700` for increment 100. In contrast the exponential and Fibonacci tests deliberately probe `failedAttempt(Integer.MAX_VALUE, ...)` and assert the capped maximum (`WaitStrategiesTest.java:103, 116, 140, 153`) — the developers test overflow-safety for those strategies, but there is no extreme-value test for incrementing. `RetryerBuilderTest.testWithMoreThanOneWaitStrategyOneBeingIncremental` (`:71-83`) uses small values only.
- **README/HISTORY**: no mention of incrementing limits/overflow.
- **Upstream tracker** (`gh api repos/rholder/guava-retrying/issues?state=all`, 106 issues+PRs, open and closed, incl. merged/closed PRs): title filter for wait/sleep/increment/overflow/negative/backoff/strategy/max/long; searches `repo:rholder/guava-retrying` for `incrementingWait`, `IncrementingWaitStrategy`, `overflow`, `incrementing`, `Long.MAX_VALUE`, `negative sleep`, `increment` → no report of this mechanism (hits: #59 unrelated, #93 docs-milliseconds, #65 futures). PR diffs touching `WaitStrategies.java` (#17, #26, #50, #95, #98) inspected: none changes the incrementing arithmetic (#98 only changes `%d`→`%s` in the constructor message). Upstream repo last push 2023-03-28; HEAD `177b6c9` = worktree HEAD.
- **GitHub-wide**: searches `IncrementingWaitStrategy overflow`, `incrementingWait overflow`, `incrementingWait Long.MAX_VALUE`, `guava-retrying incrementing overflow` → nothing relevant (only an unrelated apache/accumulo Retry overflow). Fork `rhuffman/re-retrying` still has the identical code (`WaitStrategies.java:284-286`), i.e. not fixed there either; issue #100's fork `itning/guava-retrying3` has no indexed `IncrementingWaitStrategy` hit.

## Step 3 — Known-status / precedent

No issue / PR / CVE / advisory / prior Specular dataset entry reports this mechanism (unchecked `increment * (n-1)` overflow clamped to 0 in `IncrementingWaitStrategy.computeSleepTime`). Upstream known incidents listed by the target (#48, #92, #29, #67, #94) concern listeners, thread lifetime, timeouts, `Error` wrapping and Guava compatibility — different mechanisms. Not a code-review × known duplicate → **no pre-filter drop; proceed to Phase 2.** Novelty to record: `NEW`.
