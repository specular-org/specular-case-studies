# MC-6 — Phase 1 investigation (evidence only)

Finding: a `wrap()` task cancelled with `Future.cancel(true)` / `shutdownNow()` keeps retrying forever (or returns normally), and its worker thread is never released. Source: model checking, actual counterexample `spec/output/hunt_s2_live_bfs.out` (property `InterruptedCallEventuallyExits`, cfg `MC_hunt_s2_live.cfg`), safety views `hunt_s2_wrap_cancel_bfs3.out` / `hunt_s2_wrap_cancel_bfs6.out`.

Source under test: worktree `.../confirmation/MC-6/worktree`, HEAD `177b6c9b9f3e7957f404f0bdb8e23374cb1de43f` (= upstream `rholder/guava-retrying` master, 2.0.0 + a Travis tweak). `diff -r` of `src/` against the frozen run source `/home/ubuntu/scratch/guava-retrying-src/guava-retrying` is empty (no instrumentation). Guava 22.0 jar sha256 `1158e94c7de4da480873f0b4ab4a1da14c0d23d4b1902cc94a58a6f0f9ab579e`.

Persistent-findings lookup (`specular findings ... lookup --query RetryerCallable --query InterruptedCallEventuallyExits --query "cancel(true)" --query wrap`) returned `[]`.

## Step 1 — Code audit

### Cited code

- `Retryer.java:155-185` `call()`: the only interrupt handling in the loop is `Retryer.java:177-182` (`blockStrategy.block(sleepTime)`; on `InterruptedException` re-set the flag and throw `RetryException`).
- `Retryer.java:159-164`: `attemptTimeLimiter.call(callable)` inside `try { ... } catch (Throwable t) { attempt = new ExceptionAttempt<V>(t, ...) }` — every throwable from the attempt, including `InterruptedException`, becomes an ordinary failed attempt.
- `Retryer.java:170-172` rejection predicate; `Retryer.java:173-174` stop strategy; `Retryer.java:176-178` wait + block.
- `Retryer.java:195-197` `wrap()` and `Retryer.java:301-320` `RetryerCallable`; `call()` at `Retryer.java:317-319` is just `return retryer.call(callable);` — no cancellation hook, no interrupt check.
- `AttemptTimeLimiters.java:105-108` `FixedAttemptTimeLimit.call` → `timeLimiter.callWithTimeout(callable, duration, timeUnit, true)` (amInterruptible = true).
- Guava 22.0 `SimpleTimeLimiter.java:142-168` (from `guava-22.0-sources.jar`): `future = executor.submit(callable); ... return future.get(timeoutDuration, timeoutUnit); } catch (InterruptedException e) { future.cancel(true); throw e; }`. `FutureTask.awaitDone` clears the flag via `Thread.interrupted()` before throwing, so the `InterruptedException` reaches `Retryer.java:162` with the interrupt status clear.
- `BlockStrategies.java:45-47` `Thread.sleep(sleepTime)`. HotSpot `JVM_Sleep` checks (and clears) the interrupt flag first even for 0 ms, so a *still-pending* interrupt is caught at `Retryer.java:179`; an already-consumed one is not.
- `RetryerBuilder.java:130-133` `retryIfException()` = `ExceptionClassPredicate(Exception.class)`, which matches `InterruptedException`. `RetryerBuilder.java:190-197` defaults: `noTimeLimit`, `neverStop`, `noWait`, `threadSleepStrategy`.

### Call chain (public entry → cited code)

`ExecutorService.submit(retryer.wrap(callable))` → `FutureTask.run` on pool worker W → `RetryerCallable.call` (`Retryer.java:317-319`) → `Retryer.call` (`:155`) → `attemptTimeLimiter.call` (`:160`) → `FixedAttemptTimeLimit.call` (`AttemptTimeLimiters.java:106-107`) → `SimpleTimeLimiter.callWithTimeout` → `future.get(timeout)`.

Cancellation delivery: `FutureTask.cancel(true)` interrupts the runner thread W; `ThreadPoolExecutor.shutdownNow()` interrupts all started workers. Nothing in `RetryerCallable` observes the outer future's cancellation; the only signal reaching `Retryer.call` is W's interrupt flag.

With the interrupt pending/arriving while W waits in `future.get` (W spends nearly all of each attempt there): `InterruptedException` (flag cleared) → inner future cancelled → rethrown → caught at `Retryer.java:162` → `ExceptionAttempt(InterruptedException)` → listeners → `retryIfException()` rejects it → `neverStop` → `noWait` (0) → `Thread.sleep(0)` returns normally (flag clear) → next attempt, indefinitely. The same catch-all applies when the user callable itself consumes the interrupt (any interruptible blocking call that throws `InterruptedException`), with or without a time limiter.

Reachability: entirely through public API with standard JDK executors and the builder defaults; `wrap()` is advertised for exactly this use (`Retryer.java:37`, `Retryer.java:187-194`). `cancel(true)` / `shutdownNow()` are the standard ways to stop executor tasks.

### Safeguards encountered (recorded, not judged)

1. `Retryer.java:179-181` — fires only if the interrupt flag is still set when `block()` runs (interrupt landed in listeners/predicate/sleep, or the attempt ignored it). It does not fire once `future.get` / the callable consumed the interrupt.
2. Stop strategy — a bounded strategy (`stopAfterAttempt`, `stopAfterDelay`) ends the loop eventually; "forever" needs `neverStop` (the builder default). With a bounded strategy attempts still continue after the cancellation until the stop fires.
3. Rejection predicate — only predicates that accept `InterruptedException` keep retrying (`retryIfException()`, `retryIfExceptionOfType(Exception.class)`, a `Predicate<Throwable>` returning true). With e.g. `retryIfExceptionOfType(IOException.class)` the interrupted attempt is not rejected and `call()` exits with `ExecutionException(InterruptedException)` (flag clear — separate interrupt-status issue).
4. Outer `FutureTask` — once cancelled, discards whatever `call()` later returns (the canceller cannot see a late normal return, but side effects of post-cancel attempts happen).

### Trigger scenario

1. Build `RetryerBuilder.<String>newBuilder().retryIfException().withAttemptTimeLimiter(AttemptTimeLimiters.fixedTimeLimit(1, SECONDS, innerPool)).build()` (defaults `neverStop`, `noWait`).
2. Submit `retryer.wrap(callRemote)` to an `ExecutorService`; `callRemote` simulates a remote call (~20 ms) that currently fails with `IOException`.
3. The application gives up: `future.cancel(true)` (or `executor.shutdownNow()` at shutdown).
4. W is waiting in `future.get` inside `SimpleTimeLimiter`; the interrupt is consumed there (CE state 5 `MCGetInterrupted`, `curTag = "CallerIE"`, `intr[c1]` TRUE→FALSE).
5. The interrupted attempt is retried; the following attempts fail with `IOException` and are retried forever (CE states 15-43, lasso back to state 30). `cancel(true)` returned true and `isCancelled()` is true, but W never returns to the pool; after `shutdownNow()` `awaitTermination` never returns true.
6. If a post-cancel attempt succeeds, `RetryerCallable.call()` returns normally with the interrupt status clear (CE view `hunt_s2_wrap_cancel_bfs6.out`).

## Step 2 — Developer-knowledge search

### Comments / docs (verbatim)

- `Retryer.java:59-61` (and `:76-78`, `:94-96`, `:113-115`): "If an attempt is rejected, the retryer will retry the call, unless the stop strategy indicates otherwise or the thread is interrupted."
- `Retryer.java:151-153` (`call()`): "@throws RetryException if all the attempts failed before the stop strategy decided to abort, or the thread was interrupted. Note that if the thread is interrupted, this exception is thrown and the thread's interrupt status is set."
- `Retryer.java:37`: "A retryer can also wrap the callable into a RetryerCallable, which can be submitted to an executor."
- `Retryer.java:188-193` (`wrap()`): "Wraps the given Callable in a RetryerCallable, which can be submitted to an executor ... behaves like the given Callable with retry behavior defined by this Retryer".
- `AttemptTimeLimiter.java:22`: "A rule to wrap any single attempt in a time limit, where it will possibly be interrupted if the limit is exceeded."
- No TODO/FIXME/"by design" comment near the catch-all or `RetryerCallable`.

### Tests

- `RetryerBuilderTest.testInterruption` (`RetryerBuilderTest.java:385-414`): interrupts a thread sleeping in `fixedWait(1000ms)` and asserts `RetryException` and `Thread.currentThread().isInterrupted()` — developers expect interruption to end `call()` with the flag set. Only the block step is covered.
- `RetryerBuilderTest.testWrap` (`:417-424`): happy path only. No test covers an interrupt during an attempt or cancellation/shutdown of a `wrap()` task.

### Commits / blame

- `catch (Throwable t)` at `Retryer.java:162`: `fbe31777` (2013-06-06). Block-step interrupt handling and `wrap()`/`RetryerCallable`: `6d2d838b` (2012-11-17). Time limiter call at `:160`: `7e474be7` (2013-01-16, "add time limit per attempt in a retryer"). No commit message discusses interrupts during an attempt or cancellation of wrapped tasks.

### Issue trackers (searched 2026-11-26)

- Upstream `rholder/guava-retrying`: all 106 issues/PRs (all states) listed via `gh api --paginate repos/rholder/guava-retrying/issues?state=all`, bodies grepped for `interrupt|cancel|shutdown|RetryerCallable|wrap(|InterruptedException|awaitTermination|executor`; all 185 issue comments and 5 PR review comments grepped for the same. Hits: #63 (open) — a user `BlockStrategy` that does not sleep "will runs forever" (user strategy, different mechanism); #65/#69 (unrelated executor/feature questions). PR #101 (open, unmerged) "Not calling Thread.sleep() if sleepTime is Zero" touches `BlockStrategies` only. Recently closed: PR #107 (closed 2026-09-05, unmerged, PHP rewrite) and PR #84 (closed 2026-09-20, unmerged, README). Upstream master HEAD is still `177b6c9b` (2016-05-10). No upstream report of this mechanism; not fixed upstream.
- Fork `rhuffman/re-retrying` (same package `com.github.rholder.retry`, same `Retryer.java` at the time):
  - #32 (closed 2018-02-11) "Thread interruption when executing the callback is not propagated": quotes the same Javadoc ("unless the stop strategy indicates otherwise or the thread is interrupted") and reports "this is not the case" — an interrupt during the callback is retried. Closed as a duplicate of #24. https://github.com/rhuffman/re-retrying/issues/32
  - #24 (closed 2018-02-24) "Add better handling of InterruptedException in Retryer.call" (API change to propagate `InterruptedException`), fixed by `e2d01c3b`.
  - #36 (closed 2018-07-11) "InterruptedException thrown by a Callable is not handled correctly", fixed by `f1ff0bfa` which adds `catch (InterruptedException e) { throw e; }` before the `catch (Throwable t)` in `Retryer.call` — the same site as `Retryer.java:159-164` here. https://github.com/rhuffman/re-retrying/issues/36
  - None of these mention `wrap()`, `Future.cancel`, `shutdownNow`, endless retry or worker release; the fix was never upstreamed.
- Specular case-studies dataset: empty directory; persistent registry: no match.

## Step 3 — Known-status / precedent

- The root mechanism — an interrupt arriving during an attempt is swallowed by the catch-all at `Retryer.java:159-164` and the call keeps retrying despite the Javadoc — was publicly reported against the identical `Retryer.call` in the `rhuffman/re-retrying` fork (#32, #36) and fixed there (`f1ff0bfa`); it is unreported and unfixed in `rholder/guava-retrying` (2.0.0 and master `177b6c9b`).
- The `wrap()` consequence specific to this finding (cancelled/shut-down executor task retries forever, worker never released, `awaitTermination` never true, or a cancelled task's late normal return) is not described in either tracker.
- Pre-filter: the finding is MC-sourced with an actual counterexample, so it is not eligible for the code-review × known drop. Proceed to Phase 2.

## Repair round 1 continuation (2026-11-26)

Round 0 ended `REPRODUCED` (Level 0, `verdict.json`, consensus). Phase 3 repair round 1 reports the same violation as still current, citing the same counterexample. This round re-checks that evidence and keeps it.

- Source: the worktree HEAD is still `177b6c9b9f3e7957f404f0bdb8e23374cb1de43f` with 0 dirty files, and `diff -r src` against the frozen run source is empty. The cited lines still match: `Retryer.java:160` (attempt), `:162` (`catch (Throwable t)`), `:177-182` (the only interrupt check), `:195-197` (`wrap()`), `:317-319` (`RetryerCallable.call()`), and `AttemptTimeLimiters.java:107` (`callWithTimeout(..., true)`).
- Counterexample: `spec/output/hunt_s2_live_bfs.out` is byte-identical to the round-0 file (sha256 `3e4be17e3194ffd2…`). It was written at 08:16, before repair round 1 edited `spec/base.tla` at 12:28.
- The lasso is unchanged: state 3 `MCCancelOuter`, then state 5 `MCGetInterrupted`, then states 30-43 (`MCSubmitHandoff` → `MCBodyThrows` → `MCGetReturn` → listeners → `MCWaitStrategyComputes("Zero")` → `MCBlockZero`), back to state 30.
- Repair round 1 did not re-run `MC_hunt_s2_live.cfg`. Its post-repair S2 control run, `spec/output/repair-r1/repair1_ctl_s2_wrap_cancel_ndc.out`, still reaches `MCCancelOuter` (state 9) → `MCGetInterrupted` (state 11). So the cancellation path the counterexample starts from is still admissible in the repaired model. In any case the verdict rests on the Level 0 run against unmodified source, not on the model.
- Reproduction: the test script is unchanged (sha256 `e57bd0c7ea8d08fa…`). It was re-executed against the current source and `repro/MC-6.log` now holds that run (exit 0, 59 s):
  - A: 496 attempts in 10 s after `cancel(true)`; the first is an `InterruptedException` with the flag clear.
  - A': 5/5 trials triggered.
  - B: `awaitTermination` returns false for 10 s after 3× `shutdownNow()`; 496 attempts, 3 of them retried `InterruptedException` attempts.
  - C: both controls exit or terminate.
  - D: late normal return `'receipt-2'`; the side effect was committed 0.302 s after `cancel(true)`.
  - E: 299 attempts in 6 s without a time limiter.
  - F: the JVM never exits and is killed by `timeout` (124); the control exits 0.
- Known-status refresh: the most recent upstream activity is #84 and #107, both closed unmerged in Sept 2026 and unrelated. Searching `interrupt` finds only #63 (a user `BlockStrategy`); `cancel`, `shutdownNow` and `RetryerCallable` find nothing. Master is still `177b6c9b`. Fork `rhuffman/re-retrying` #32 and #36 are unchanged: closed, and fixed only in the fork (`f1ff0bfa`). Novelty stays KNOWN (re-retrying #32), unfixed in `rholder/guava-retrying`.
- The persistent-findings lookup returned `[]` again, so there is no registered record to reuse.
- Corrections to round-0 statements: none. Current source and trace evidence agree with every round-0 statement; only the observed counts changed in the re-run (A: 494 → 496 attempts in 10 s).
