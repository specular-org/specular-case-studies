# CR-D-21 — Phase 1 investigation (evidence only)

Finding: `fibonacciWait` overflow wraps to a positive value that the guard misses, so the sleep drops below the cap instead of growing up to the maximum. Source: code review (ledger D-21, scenario 5), not model-checked, no counterexample.

Source under test: worktree `177b6c9b9f3e7957f404f0bdb8e23374cb1de43f` (upstream 2.0.0 tip), clean; `WaitStrategies.java` sha256 `75e567e7…6086`, identical to the run source `/home/ubuntu/scratch/guava-retrying-src/guava-retrying`.

## Step 1 — Code audit

### Cited code

- `src/main/java/com/github/rholder/retry/WaitStrategies.java:166-168` — `fibonacciWait()` = `new FibonacciWaitStrategy(1, Long.MAX_VALUE)`; Javadoc (:161-162): "sleeps for an increasing amount of time after the first failed attempt, and in Fibonacci increments after each failed attempt up to `Long#MAX_VALUE`".
- `:178-182`, `:195-200` — capped variants; Javadoc (:171-172, :185-186): "... up to the `maximumTime`". `maximumTime` goes through `TimeUnit.toMillis` (saturating), so `fibonacciWait(1000, Long.MAX_VALUE, MILLISECONDS)` has cap `Long.MAX_VALUE`.
- `:317-323` — constructor: `multiplier > 0`, `maximumWait >= 0`, `multiplier < maximumWait`.
- `:326-335` — `computeSleepTime`: `fib = fib(attemptNumber)`; `result = multiplier * fib` (unchecked); `if (result > maximumWait || result < 0L) result = maximumWait;` (:330); `return result >= 0L ? result : 0L`.
- `:337-352` — `fib(n)`: iterative, unchecked `long` additions (`result = prev + prevPrev`), O(n) per call.

### Arithmetic facts (exact, computed with Python big integers, mirroring Java `long` wrap)

- F(92) = 7540113804746346429 is the largest Fibonacci number that fits in a signed `long`. F(93) wraps negative → the guard maps it to the cap, so attempt 93 yields `Long.MAX_VALUE`.
- `fibonacciWait()`: attempt 94 → `F(93)+F(92)` wraps to **1293530146158671551** (positive, `< Long.MAX_VALUE`) → the guard does not fire → value returned; 95-97 → `Long.MAX_VALUE`; 98 → 6174643828739884737; ... The sequence is non-monotone from attempt 94 on.
- `fibonacciWait(1000, Long.MAX_VALUE, MILLISECONDS)`: attempt 78 → 8944394323791464000; 79 → product wraps negative → cap; **80 → 4969984274758133384**; 81 → 995574225724802768; ...
- Structural fact: for any multiplier `m`, the first overflowing product `m·F(n0)` lies in `[2^63, 1.618·2^63)` (because `m·F(n0-1) < 2^63` and `F(n0)/F(n0-1) < 1.62`), i.e. it always wraps *negative* and is mapped to the cap. A positive below-cap wrap can therefore only appear *after* at least one attempt whose wait equals `maximumWait`.

### Call chain from the public API

`RetryerBuilder.withWaitStrategy(WaitStrategies.fibonacciWait…)` → `build()` → `Retryer.call` (`Retryer.java:155-185`): `int attemptNumber` loop (:157) → attempt → listeners → rejection predicate → `stopStrategy.shouldStop` (:173) → `waitStrategy.computeSleepTime(attempt)` (:176) → `blockStrategy.block(sleepTime)` (:178). The only in-library consumers of `computeSleepTime` are `Retryer.call` (:176) and `CompositeWaitStrategy` (`WaitStrategies.java:365-371`, itself only consumed by `Retryer.call`). The value is otherwise visible to user code through the public `WaitStrategy`/`Attempt` interfaces (direct evaluation, as the project's own `WaitStrategiesTest` does).

Default block strategy: `BlockStrategies.ThreadSleepStrategy.block` = `Thread.sleep(sleepTime)` (`BlockStrategies.java:45-46`). On JDK 21, `Thread.sleep(long millis)` first does `TimeUnit.MILLISECONDS.toNanos(millis)` (verified by `javap -c java.lang.Thread`: `getstatic MILLISECONDS; invokevirtual toNanos`), which saturates at `Long.MAX_VALUE` ns (≈292.47 years) for any `millis ≥ 9223372036855`. On JDK 11 `Thread.sleep(long)` is `native` (no ns conversion in Java code).

### Reachability

- Attempt 94 (or 80 for ×1000) is reached by `Retryer.call` only after `block()` has returned for every earlier attempt, including `block(Long.MAX_VALUE)` at attempt 93 (79) and `block(F(92))` at attempt 92. With any block strategy that actually blocks for the designated time (the built-in `ThreadSleepStrategy`, or a user strategy honoring `BlockStrategy.block`'s Javadoc "Attempt to block for the designated amount of time", `BlockStrategy.java:27-31`), that is ≥ 2^63 ms ≈ 292 million years of designated sleep; even with JDK 21's ns saturation (each sleep ≤ 292.47 years), it is ~30 saturated sleeps ≈ 9,000+ years.
- Reachable quickly through the public API only (a) with a user `BlockStrategy` that does not block for the designated time (the `BlockStrategy` Javadoc explicitly cautions that such implementations "can significantly modify the behavior of any configured WaitStrategy"), or (b) by calling `computeSleepTime` directly with a user-implemented `Attempt` (public interface).
- The Retryer's attempt domain is `1..Integer.MAX_VALUE` (`int attemptNumber`, `Retryer.java:157`); beyond that the counter wraps negative, which is a different mechanism and out of scope here.
- Realistic finite caps (README: `fibonacciWait(100, 2, MINUTES)`): a wrapped value escapes the guard only if it lands in `[0, cap)`, probability ≈ cap/2^64 per attempt; the ledger probe saw no escape for n ≤ 1e8. Phase 2 extends this to the full `int` domain.

### Safeguards / masks noted (Phase 2 must prove whether they fire)

1. The existing guard `result > maximumWait || result < 0L` (:330) — catches negative wraps and wraps above a finite cap.
2. The preceding astronomically long designated sleeps (time barrier) before any below-cap wrap can be produced inside a Retryer.
3. JDK 21 `Thread.sleep` ms→ns saturation: `block(1293530146158671551)` and `block(Long.MAX_VALUE)` become the same `sleep0(Long.MAX_VALUE ns)`.

### Trigger scenario

`RetryerBuilder.<Integer>newBuilder().retryIfResult(alwaysTrue).withWaitStrategy(WaitStrategies.fibonacciWait()).withStopStrategy(StopStrategies.neverStop() or stopAfterAttempt(≥95)).build().call(alwaysFailing)` — after 93 failed attempts the 94th wait is 1293530146158671551 ms although the 93rd was `Long.MAX_VALUE`. Same with `fibonacciWait(1000, Long.MAX_VALUE, MILLISECONDS)` at attempt 80. Requires either a non-sleeping block strategy or ≥ 292M years (≥ ~9,000 years on JDK 21) of real sleeping.

## Step 2 — Developer-knowledge search

- **Original commit** `ce0bc7d` (Jochen Schalanda, 2013-12-03, PR #9 "Implement FibonacciWaitStrategy", merged): introduced the code including the guard `if(result > maximumWait || result < 0L)` — the `< 0L` clause is an overflow guard, i.e. the author intended overflow to saturate to the cap. Commit message: "Similar to the ExponentialWaitStrategy the FibonacciWaitStrategy follows a pattern of waiting an increasing amount of time after each failed attempt." PR #9 discussion: only the owner's "+1 ... I'll add these notes to the README.md as well." No review comments.
- **Tests (developer-intended behavior)**, added in the same commit, `src/test/java/com/github/rholder/retry/WaitStrategiesTest.java:140,153`: `fibonacciWait(10L, MILLISECONDS).computeSleepTime(failedAttempt(Integer.MAX_VALUE, 0L)) == 10L` and `fibonacciWait(1000L, 50000L, MILLISECONDS)... (Integer.MAX_VALUE) == 50000L` — the developers expect extreme attempt numbers to yield exactly the cap, and they evaluate the strategy directly with huge attempt numbers. There is no extreme-attempt test for the uncapped `fibonacciWait()` (`testFibonacci`, :120-128, only checks attempts 1-6).
- **Later edits**: `5cc1018` (2014-03-15) whitespace only on the guard; `1e7f2bd` (2015-05-10) switched the input to `failedAttempt.getAttemptNumber()`.
- **README** (`README.md:74-100`): Fibonacci example `fibonacciWait(100, 2, TimeUnit.MINUTES)` with `neverStop()` — "waiting after every failed retry in increasing Fibonacci backoff intervals until at most 2 minutes. After 2 minutes, retry from then on in 2 minute intervals." Also: the iterative version avoids a StackOverflowError "at a certain point (although very unlikely with useful parameters for retrying)" — the developers consider extreme parameters but judged them unlikely; no statement about integer overflow.
- **Comments near the code**: none (no TODO/FIXME).
- **`BlockStrategy` Javadoc** (`BlockStrategy.java:27-31`): "Attempt to block for the designated amount of time. Implementations that don't block ... for the given sleep duration can significantly modify the behavior of any configured WaitStrategy. Caution is advised..."

## Step 3 — Known-status / precedent

Searches run 2026-11-26 with `gh`:

- `rholder/guava-retrying` issues and PRs: keyword searches `fibonacci`, `overflow`, `wait time negative`, `sleep time`, `Long.MAX_VALUE`, `maximumWait`, `computeSleepTime`, `exponential overflow`, `wait strategy`; plus a full listing of all 61 issues and all 45 PRs (any state) sorted by last update. Fibonacci-related hits: #87 (open question "When i should use Fibonacci WaitStrategy", no overflow content), #12 (closed, "New strategy"), PR #9 (the original implementation). Most recently closed PRs: #84 (2026-09-20, README formatting) and #107 (2026-09-05, "Modernize" — a PHP port that deletes the Java sources, closed unmerged). None reports or fixes this mechanism.
- Forks: `rhuffman/re-retrying` (#81), `itning/guava-retrying3` (#100), `kiwiproject/retrying-again` — no issues/PRs mentioning fibonacci or overflow; `retrying-again`'s current `FibonacciWaitStrategy` still has the identical unchecked arithmetic and guard.
- Global GitHub issue/PR search (`FibonacciWaitStrategy overflow`, `fibonacciWait overflow`, `fibonacci wait overflow retry`, `FibonacciWaitStrategy`): only blog-style articles and dependency bumps; no report of this defect.
- Prior Specular dataset: `persistent-findings-context.json` has `previous: null`, `inherited_records: {}` — no historical records to match.

Result: no existing report of THIS mechanism at THIS site → **not known**, the code-review × known pre-filter does not apply → proceed to Phase 2. Novelty: NEW.
