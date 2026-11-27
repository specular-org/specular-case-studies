# CR-D-16 — Phase 1 investigation (evidence only)

Finding: `WaitStrategies.join` sums component sleeps without overflow protection; a total of 2^63 ms or more wraps negative and `Retryer.call()` throws `IllegalArgumentException`.

Source: code review (ledger row D-16, scenario 5; not model-checked, no counterexample).

Checkout: `confirmation/CR-D-16/worktree` at `177b6c9b9f3e7957f404f0bdb8e23374cb1de43f` (guava-retrying 2.0.0 + travis workaround), `git status --porcelain` empty (unmodified).

Persistent-findings lookup (`specular findings ... lookup --query CompositeWaitStrategy --query WaitStrategies.join --query computeSleepTime --query "timeout value is negative" --query "negative sleep"`): `[]`. `persistent-findings-context.json` has `previous: null`, no inherited records.

## Step 1 — Code audit

### Cited code

`src/main/java/com/github/rholder/retry/WaitStrategies.java:218-230` — `join` (Javadoc: "The new joined strategy will have a wait time which is total of all wait times computed one after another in order."). It validates only `length > 0` and no `null` element.

`src/main/java/com/github/rholder/retry/WaitStrategies.java:364-371` — `CompositeWaitStrategy.computeSleepTime`:

```java
long waitTime = 0L;
for (WaitStrategy waitStrategy : waitStrategies) {
    waitTime += waitStrategy.computeSleepTime(failedAttempt);
}
return waitTime;
```

Plain two's-complement `long` addition: no `LongMath.saturatedAdd`, no `Math.addExact`, no `< 0` clamp.

`src/main/java/com/github/rholder/retry/Retryer.java:173-183` — after `stopStrategy.shouldStop(attempt)` is false, `long sleepTime = waitStrategy.computeSleepTime(attempt);` then `blockStrategy.block(sleepTime);` inside `try { ... } catch (InterruptedException e) { Thread.currentThread().interrupt(); throw new RetryException(attemptNumber, attempt); }`. No validation of `sleepTime`; only `InterruptedException` is caught.

`src/main/java/com/github/rholder/retry/BlockStrategies.java:44-47` — default `ThreadSleepStrategy.block(long sleepTime)` is `Thread.sleep(sleepTime);`. `Thread.sleep` throws `IllegalArgumentException("timeout value is negative")` for a negative argument, and it checks the sign before it checks/clears the interrupt status (JDK 21 `Thread.sleep(long)`: `if (millis < 0) throw new IllegalArgumentException("timeout value is negative");` is the first statement; JDK 8/11 `JVM_Sleep` throws the IAE before testing `is_interrupted`).

`Retryer.call` Javadoc (`Retryer.java:140-154`): returns the result, `@throws ExecutionException` (callable exception accepted by the rejection predicate), `@throws RetryException` ("if all the attempts failed before the stop strategy decided to abort, or the thread was interrupted. Note that if the thread is interrupted, this exception is thrown and the thread's interrupt status is set."). `IllegalArgumentException` is not a documented outcome.

### Component values that can reach the sum

- `fixedWait(long sleepTime, TimeUnit)` (`WaitStrategies.java:58-61`, ctor `:236-239`) accepts any `sleepTime >= 0`, including `Long.MAX_VALUE` ms; `TimeUnit.toMillis` saturates to `Long.MAX_VALUE` for large values in coarser units (e.g. `fixedWait(Long.MAX_VALUE, DAYS)`), and the factory accepts the saturated value.
- `exceptionWait(Class, Function<T, Long>)` (`:211-216`, impl `:374-395`) returns whatever the function returns for a matching exception (e.g. a server back-off hint converted with the saturating `TimeUnit.SECONDS.toMillis`). No bound.
- `randomWait(...)` returns values in `[min, max)`; with `randomWait(1, SECONDS)` the value is in `[0, 999]` ms (0 with probability 1/1000).
- `exponentialWait()` / `fibonacciWait()` cap at `Long.MAX_VALUE` by design (`:118-126`, `:160-168`); they reach that cap only after ~57-93 attempts, i.e. after sleeping astronomically long under the default block strategy, so they are not a practical first-attempt trigger.

### Call chain (public API → cited code)

`RetryerBuilder.newBuilder()` → `.withWaitStrategy(WaitStrategies.join(a, b, ...))` (`RetryerBuilder.java:75-79`) → `.build()` (`:190-197`, default block strategy `BlockStrategies.threadSleepStrategy()` at `:194`) → `Retryer.call(callable)` → attempt fails and is rejected (e.g. `retryIfException()`), stop strategy says continue → `CompositeWaitStrategy.computeSleepTime` (`WaitStrategies.java:365-371`) → `ThreadSleepStrategy.block` (`BlockStrategies.java:46`) → `Thread.sleep(negative)` → `IllegalArgumentException` propagates out of `Retryer.call` (no catch for it at `Retryer.java:177-182`). Same path through `Retryer.wrap(callable)` (`Retryer.java:195-197`) → `RetryerCallable.call()` (`Retryer.java:317-319`, `return retryer.call(callable);`, no catch).

Reachability: every step is public API with arguments that pass the factories' own preconditions. The overflow happens at the first failed attempt when a component returns a huge value at attempt 1 (`fixedWait(huge)`, `exceptionWait(...)` with a huge hint).

### Trigger scenarios

1. `join(fixedWait(Long.MAX_VALUE, MILLISECONDS), fixedWait(1, SECONDS))`, `retryIfException()`, `stopAfterAttempt(3)`, callable fails once → sum = `Long.MAX_VALUE + 1000` = `-9223372036854774809` → `Thread.sleep` IAE escapes `call()` after one attempt.
2. Saturating unit: `join(fixedWait(Long.MAX_VALUE, DAYS), fixedWait(1, MILLISECONDS))` (or any positive component).
3. Data-driven: `join(exceptionWait(RetryAfterException.class, e -> TimeUnit.SECONDS.toMillis(e.retryAfterSeconds)), randomWait(1, SECONDS))` with a huge/sentinel back-off hint → `Long.MAX_VALUE + jitter` wraps negative (unless the jitter happens to be 0).
4. Interrupted caller: the callable fails because the caller thread is interrupted with the interrupt status left set (e.g. NIO `ClosedByInterruptException`, which sets the status); with a non-overflowing wait, `Thread.sleep` throws `InterruptedException` → documented `RetryException` + interrupt status; with the overflowing join, `Thread.sleep` throws IAE first.

### Safeguards encountered (recorded, not dismissed)

- `join` precondition checks: only non-empty / non-null. No range check.
- Factory preconditions on components: `sleepTime >= 0` etc. — all pass for `Long.MAX_VALUE`.
- No sign/range check of `sleepTime` in `Retryer.call` (`:176-178`).
- `ThreadSleepStrategy.block` delegates directly to `Thread.sleep`.
- A user-supplied `BlockStrategy` could clamp negatives, but the default (and the only built-in) does not.
- No catch of `RuntimeException` around the block step; `RetryerCallable` does not catch either.

## Step 2 — Developer-knowledge evidence (verbatim, unclassified)

- `join` Javadoc (`WaitStrategies.java:219-220`): "Joins one or more wait strategies to derive a composite wait strategy. The new joined strategy will have a wait time which is total of all wait times computed one after another in order."
- `exponentialWait()` Javadoc (`:119-120`): "... in exponentially incrementing amounts after each failed attempt up to Long.MAX_VALUE." `fibonacciWait()` (`:161-162`): "... up to {@link Long#MAX_VALUE}." The library itself uses `Long.MAX_VALUE` as a legitimate sleep value.
- Sibling built-ins guard against overflow/negative results: `IncrementingWaitStrategy` `return result >= 0L ? result : 0L;` (`:282-283`); `ExponentialWaitStrategy` clamps to `maximumWait` and `return result >= 0L ? result : 0L;` (`:305-308`); `FibonacciWaitStrategy` `if (result > maximumWait || result < 0L) { result = maximumWait; }` (`:330-334`, introduced in `ce0bc7d` "Implement FibonacciWaitStrategy", 2013-12-03). `CompositeWaitStrategy` (added `2b5bfec` "Issue #12 - New composite wait strategy. Allows mixing more than one wait strategy.", 2014-03-27) has no such guard.
- Existing tests exercise extreme attempt numbers and expect saturation, never a negative value: `WaitStrategiesTest.testExponentialWithMaximumWait` asserts `computeSleepTime(failedAttempt(Integer.MAX_VALUE, 0)) == 40`; `testFibonacciWithMaximumWait` `== 10L`; `testFibonacciWithMultiplierAndMaximumWait` `== 50000L`.
- Existing tests combine `join` with a `Long.MAX_VALUE` maximum: `RetryerBuilderTest.testWithMoreThanOneWaitStrategyOneBeingFixed` uses `WaitStrategies.join(WaitStrategies.fixedWait(50L, TimeUnit.MILLISECONDS), WaitStrategies.fibonacciWait(10, Long.MAX_VALUE, TimeUnit.MILLISECONDS))`; `testWithMoreThanOneWaitStrategyOneBeingIncremental` joins `incrementingWait(...)` with the same Fibonacci. No test covers a component at or near `Long.MAX_VALUE` inside `join`.
- `WaitStrategy.computeSleepTime` Javadoc: "Returns the time, in milliseconds, to sleep before retrying." No bound stated. `BlockStrategy.block` Javadoc: "@param sleepTime the computed sleep duration in milliseconds". Nothing about negative values.
- Upstream issue #12 (owner rholder, proposing `join`): "each strategy is combined together in such a way that they each add to the computed sleep value that is returned". PR #17 (merged) discussion: no mention of overflow.
- No TODO/FIXME near the site. README/HISTORY: only "New composite wait strategy #12 (shasts)".

## Step 3 — Known-status / precedent

Searches run on 2026-11-26 with `gh`:

- `rholder/guava-retrying`: full list of all 61 issues and all 45 PRs (open, closed, merged; newest: PR #107 "Modernize", closed 2026-09-05). `gh search issues --include-prs` for `overflow`, `negative`, `"timeout value is negative"`, `IllegalArgumentException`, `composite`, `join`, `Long.MAX_VALUE`, `saturat`, `MAX_VALUE`, `computeSleepTime`, `"sleep time"`, `wrap`. Hits: #59 (Travis "buffer overflow" in CI — unrelated), #99/#97 (StopStrategies message formatting — unrelated), #17/#12 (introduce `join`; no overflow discussion), others unrelated. PR #107 rewrites the project to PHP and was closed unmerged; PR #95 (open) adds a jitter strategy and does not touch the composite sum.
- Forks named upstream (#81 `rhuffman/re-retrying`, #100 `itning/guava-retrying3`): keyword searches return nothing relevant (only dependabot bumps); both forks still contain the identical unguarded `waitTime += waitStrategy.computeSleepTime(failedAttempt);` loop.
- Local Specular dataset: `Specular/case-studies` is empty; Codex memory archive has no guava-retrying entry; persistent-findings registry empty.

Result: no existing issue/PR/CVE/advisory or prior dataset entry reports this mechanism (unguarded sum in `CompositeWaitStrategy`) — not known. Code-review × known pre-filter does not apply → proceed to Phase 2.

Note (from the finding's dedup note, not re-read): MC-10 in this run covers the downstream half (negative sleep escaping `call()`); it is a sibling finding in the same run, not an upstream report.
