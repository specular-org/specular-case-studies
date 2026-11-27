# MC-10 — Phase 1 investigation (evidence only)

Finding: a negative computed sleep makes `Retryer.call()` throw `IllegalArgumentException`; when the caller thread is interrupted it pre-empts the `RetryException` the Javadoc promises.

Target source: `confirmation/MC-10/worktree` at `177b6c9b9f3e7957f404f0bdb8e23374cb1de43f`. `diff -r` against the configured source `/home/ubuntu/scratch/guava-retrying-src/guava-retrying/src` shows the trees are identical. This is also the live upstream `master` head (`gh api repos/rholder/guava-retrying/commits`: newest commit 177b6c9, 2016-05-10).

Persistent-findings lookup (`specular findings --work .specular-output lookup --query IllegalArgumentException --query "negative sleep" --query BlockStrategies.java --query Thread.sleep --query DocumentedOutcomesOnly --query InterruptedCallThrowsRetryException`) returned `[]`. The context file has `previous: null`, so there is no historical record to reuse.

## Counterexamples (this finding's only)

`spec/output/hunt_s5_decision_bfs1.out` (9 states, `DocumentedOutcomesOnly`):
1. Init → 2. `MCCallStart(c1)` (attemptNo=1) → 3. `MCCallerBodyStart(c1,"Exc")` → 4. `MCCallerBodyThrows(c1)` (curTag=CallableExc) → 5. `MCListenersBegin` → 6. `MCListenerNotify` (notified=<<1>>) → 7. `MCListenersEnd` (cpc=Decide) → 8. `MCWaitStrategyComputes(c1,"Negative")` (cpc=Block) → 9. `MCBlockNegative(c1)`: outcome=`"IAE"`, exitInfo=[flag FALSE, count 1, tag CallableExc].

`spec/output/hunt_s5_decision_bfs3.out` (10 states, `InterruptedCallThrowsRetryException`): same prefix, plus 7. `MCInterrupt(c1)` between `MCListenerNotify` and `MCListenersEnd` (intr[c1]=TRUE). Then 9. `MCWaitStrategyComputes(c1,"Negative")` → 10. `MCBlockNegative(c1)`: outcome=`"IAE"`, exitInfo=[flag **TRUE**, count 1, tag CallableExc]. Result: the thread is interrupted but the call ended with an IAE, not a `RetryException`.

The model picks the abstract sleep class `"Negative"` non-deterministically. It does not model the arithmetic that produces it.

## Step 1 — Code audit

Cited sites (read in full):
- `Retryer.java:155-185` (`call`). Lines 176-182:
  ```java
  long sleepTime = waitStrategy.computeSleepTime(attempt);   // :176
  try {
      blockStrategy.block(sleepTime);                         // :178
  } catch (InterruptedException e) {                          // :179
      Thread.currentThread().interrupt();
      throw new RetryException(attemptNumber, attempt);
  }
  ```
  `sleepTime` is neither validated nor clamped. Only `InterruptedException` is caught.
- `BlockStrategies.java:44-47`: `ThreadSleepStrategy.block(long sleepTime) { Thread.sleep(sleepTime); }`. This is the default block strategy (`RetryerBuilder.java:194`, and the 3- and 4-argument `Retryer` constructors at `Retryer.java:67,84`).
- JDK `Thread.sleep(long)` throws `IllegalArgumentException("timeout value is negative")` when `millis < 0`, **before** it checks the interrupt status. In JDK 21 the Java method's first statement is the `millis < 0` check. In JDK 8/11 the native `JVM_Sleep` checks `millis < 0` before `is_interrupted`. The interrupt flag is therefore neither consumed nor turned into `InterruptedException`. Phase 2 tests this empirically on JDK 11 and JDK 21.

Built-in producers of a negative `computeSleepTime` (out of MC-10's dedup scope as defects, used here only as reachable triggers):
- `WaitStrategies.join(...)` → `CompositeWaitStrategy.computeSleepTime` (`WaitStrategies.java:365-371`) is an unchecked `long` sum (`waitTime += ...`). For example, `join(fixedWait(Long.MAX_VALUE, MILLISECONDS), fixedWait(1, MILLISECONDS))` gives `Long.MIN_VALUE` on the first failed attempt. Each component passes its own `sleepTime >= 0` check (`WaitStrategies.java:237`), and `join` (`:225-230`) checks only non-empty and non-null.
- `WaitStrategies.exceptionWait(cls, fn)` → `ExceptionWaitStrategy.computeSleepTime` (`WaitStrategies.java:386-394`) returns `function.apply(cause)` unchanged. A negative user value (for example a "retry at" timestamp minus now that has already passed) goes straight through. It can also make a `join` total negative.
- Built-ins that cannot produce a negative value: `FixedWaitStrategy` (ctor check `:237`), `IncrementingWaitStrategy` (`:283` clamp), `ExponentialWaitStrategy` (`:308` clamp), `FibonacciWaitStrategy` (`:330-334` clamp), `RandomWaitStrategy` (min ≥ 0, max > min; `Math.abs(Long.MIN_VALUE)` corner not pursued).

Call chain (normal usage, public API only):
`RetryerBuilder.newBuilder()...withWaitStrategy(WaitStrategies.join(...) | exceptionWait(...)).build()` → `Retryer.call(callable)` (or `Retryer.wrap(callable)` → `RetryerCallable.call()` `Retryer.java:317-319`, e.g. submitted to an `ExecutorService`) → attempt fails (`:160-164`) → listeners (`:166-168`) → `rejectionPredicate.apply` = true (`:170`) → `stopStrategy.shouldStop` = false (`:173`) → `computeSleepTime` < 0 (`:176`) → `ThreadSleepStrategy.block` → `Thread.sleep(<0)` → `IllegalArgumentException` → not caught at `:179` → propagates out of `call()` (and out of `RetryerCallable.call()` into the `Future`).

Reachability: the path is reachable in normal use. It is a built-in strategy combination with valid parameters and the default block strategy.

Trigger scenarios:
- T1 (bfs1): the callable throws a retryable exception, the stop strategy does not stop, and the wait strategy yields a negative value. `call()` throws IAE after attempt 1, which is neither a result, an `ExecutionException`, nor a `RetryException`.
- T2 (bfs3): as T1, but the caller thread gets interrupted (by another thread) while the `RetryListener` loop runs. The interrupt might instead arrive during the attempt with a callable that ignores interrupts, or be pending before `call()`. Documented outcome: `RetryException` with interrupt status set. Code outcome: IAE with the interrupt status still set, and the `RetryException`'s attempt count and last failed attempt are never produced.

Safeguards checked: none on this path. `Retryer.call` does not validate or clamp `sleepTime`. `ThreadSleepStrategy` does not clamp. `RetryerBuilder.withWaitStrategy`/`build` cannot validate per-attempt outputs. No catch for `RuntimeException` around the block step, and no outer handler in `RetryerCallable.call`.

## Step 2 — Developer-knowledge search

Javadoc (contract):
- `Retryer.call` (`Retryer.java:140-154`): "@throws ExecutionException if the given callable throws an exception, and the rejection predicate considers the attempt as successful ... @throws RetryException if all the attempts failed before the stop strategy decided to abort, or the thread was interrupted. Note that if the thread is interrupted, this exception is thrown and the thread's interrupt status is set."
- `Retryer` constructors (`:59-61` etc.): "If an attempt is rejected, the retryer will retry the call, unless the stop strategy indicates otherwise or the thread is interrupted."
- `WaitStrategies.join` (`:218-224`): "The new joined strategy will have a wait time which is total of all wait times computed one after another in order."
- `WaitStrategies.fixedWait` (`:56`): "@throws IllegalStateException if the sleep time is < 0". Negative sleeps are treated as invalid configuration and rejected up front.
- `exceptionWait` (`:202-210`): "function to calculate sleep time". No sign constraint is documented.
- `WaitStrategy.computeSleepTime` (`WaitStrategy.java:26-32`): "Returns the time, in milliseconds, to sleep before retrying." `BlockStrategy.block` (`BlockStrategy.java:26-36`): "@param sleepTime the computed sleep duration in milliseconds @throws InterruptedException". No sign constraint, and no IAE is documented.
- README Quickstart (`README.md:38-56`) shows callers catching exactly `RetryException` and `ExecutionException`.

Commits / blame:
- `Retryer.java:176-182` was introduced in 6d2d838 (2012), 1e7f2bd (2015, Attempt refactor) and a96183d (2014-04-02, "Adding block strategies to the retryer to decide how to block", PR #20). None mentions negative sleeps.
- Clamp-to-zero idiom `result >= 0L ? result : 0L` (pickaxe): c531b61 (2012-08-26, original JB source), fd8b13b (2012-08-29, exponential), ce0bc7d (2013-12-03, Fibonacci). The built-ins deliberately avoid handing negative values to the block step.
- `join`/`CompositeWaitStrategy`: 2b5bfec (2014-03-27, "Issue #12 - New composite wait strategy"). No overflow handling.
- `exceptionWait`: 9c6bd63 (2014-11-04, PR #26: "user-defined function to calculate sleep time from exception occurred"). No sign validation.

Tests:
- `RetryerBuilderTest.testInterruption` (`RetryerBuilderTest.java:384-414`) asserts the documented interrupt contract: `RetryException` is thrown and `Thread.currentThread().isInterrupted()` is true.
- `RetryerBuilderTest.java:55-82` uses `join(fixedWait(50ms) | incrementingWait(..), fibonacciWait(10, Long.MAX_VALUE, MILLISECONDS))`. `Long.MAX_VALUE` caps inside `join` are a pattern the project's own tests use.
- `WaitStrategiesTest.testExceptionWait` (`:156-169`) uses a `RetryAfterException.getRetryAfter()` function. The intended use is a server Retry-After hint.
- No test covers a negative sleep or an exception other than `RetryException`/`ExecutionException` escaping `call()`.

Issue tracker (`gh api --paginate repos/rholder/guava-retrying/issues?state=all`: 106 items = 61 issues + 45 PRs, open and closed, newest update 2026-09-20; plus all 185 issue comments and 5 PR review comments; plus `gh search issues --include-prs` for "negative" and "IllegalArgumentException"):
- None reports an IAE or negative sleep escaping `Retryer.call`, join overflow, or exceptionWait negatives.
- Near misses, each a different mechanism:
  - #101 (open, unmerged PR, 2021-09): `ThreadSleepStrategy.block` returns early when `sleepTime == 0L`. Zero only; nothing for negatives.
  - #63 (open issue): a custom `BlockStrategy` that does not sleep.
  - #40 (open PR): adds a `BlockStrategiesTest` for interrupt during a positive sleep.
  - #20 (merged PR): introduced block strategies.
  - #9 (merged PR): Fibonacci wait.
  - #86 comment (2018-06-19) mentions combining exponential and fixed waits through `CompositeWaitStrategy` (join used in practice).
  - #97/#99: unformatted `IllegalArgumentException` messages in strategy factories.
- Guidance-listed known issues #48 (listener aliasing), #92 (time-limiter exit), #29 (timeout aborts retrying), #67 (`call` catches/wraps `Error`s at the attempt step), #94 (Guava 23) are different mechanisms.
- Upstream `master` has had no commits since 177b6c9 (2016-05-10). The only side branch, `13-return-original-builder` (2ddc1fd), touches builder exposure only.

## Step 3 — Known-status

- Source: MC. Actual violation traces exist (`hunt_s5_decision_bfs1.out`, `hunt_s5_decision_bfs3.out`).
- Novelty: NEW. No issue, PR, comment, or prior Specular record reports this mechanism (unvalidated negative sleep reaching `Thread.sleep` via `Retryer.java:176-182`/`BlockStrategies.java:46`, with only `InterruptedException` caught). The search covered open and closed issues, merged, closed and open PRs, and all comments.
- Pre-filter: not applicable (MC-sourced). Proceed to Phase 2.

## Repair round 1 continuation (2026-11-26, evidence re-check)

The prior record above still holds. Nothing in the current source or trace contradicts it. This section records only what was re-checked and one completion.

- Counterexample: `spec/output/hunt_s5_decision_bfs3.out` is unchanged since the first confirmation (mtime 08:15:57 UTC, sha256 `9b4aeab6…13da`, 10 states). Its steps still match the summary above: State 7 `MCInterrupt(c1)` between `MCListenerNotify` (6) and `MCListenersEnd` (8); State 9 `MCWaitStrategyComputes(c1,"Negative")`; State 10 `MCBlockNegative(c1)` with `outcome="IAE"`. Invariant violated: `InterruptedCallThrowsRetryException`.
- Completion of the State 10 description: `exitInfo` also carries `invoked |-> TRUE`, i.e. `[flag TRUE, count 1, tag CallableExc, invoked TRUE]`. The summary above omitted that field. It is consistent with the repro (callable invocations = 1).
- Model change since the first confirmation: `spec/base.tla` mtime is 12:28 UTC. That is after the counterexample (08:15) and after the first confirmation (10:13), so it presumably reflects the Phase 3 repair round. The spec contents were not read (out of scope for this worker). The verdict rests on the real-code reproduction, which follows the CE action sequence step for step.
- Source: worktree HEAD is still `177b6c9`, `git status` is clean, and `diff -r src` against the configured source is identical. The cited lines are unchanged: `Retryer.java:176` (computeSleepTime), `:178` (block), `:179` (catch InterruptedException only), `:317-319` (RetryerCallable.call), `BlockStrategies.java:46` (Thread.sleep), `WaitStrategies.java:225-230` (join), `:237` (fixedWait >= 0 check), `:365-371` (unchecked sum), `:386-394` (exceptionWait passthrough).
- Upstream re-search on 2026-11-26 (after the first search):
  - The repo was last pushed 2023-03-28. `master` is still 177b6c9 (2016-05-10).
  - `issues?state=all&since=2026-11-01` returns nothing.
  - `gh search issues --include-prs` (open and closed) for "negative sleep", "IllegalArgumentException sleep", "timeout value is negative", "computeSleepTime negative", "join overflow", "exceptionWait negative", "negative wait" and "Thread.sleep negative" all return 0 hits.
  - Most recently updated closed PRs, all unmerged:
    - #84: README formatting.
    - #107 "Modernize": deletes the Java sources and replaces them with a PHP port. No fix to this mechanism.
    - #78, #103, #53: unrelated.
  - Open PR #101 still only short-circuits `sleepTime == 0L`.
  - Novelty is unchanged: NEW.
- Reproduction re-run on the current worktree: `repro/MC-10.r1.log`, exit 0 on JDK 21.0.13.1 and JDK 11.0.33.1. Every BUG and control line matches the first run (`repro/MC-10.log`).
