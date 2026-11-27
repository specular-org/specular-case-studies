# MC-7 — Phase 1 investigation (evidence only)

Finding: adding a listener to a `RetryerBuilder` while a `Retryer` built from it is inside `call()` makes `call()` throw `ConcurrentModificationException` after the attempt ran; the attempt outcome is lost.

Source checkout: `.specular-output/confirmation/MC-7/worktree` at `177b6c9` (guava-retrying 2.0.0 + travis workaround), clean. Upstream `master` has no later commit touching `Retryer.java` or `RetryerBuilder.java` (checked with `gh api repos/rholder/guava-retrying/commits?path=...`; last changes are 2015-05/2015-06).

Persistent-findings lookup: `.specular-output/persistent-findings-context.json` has `"previous": null` and `"inherited_records": {}`, so this run has no historical record to reuse. I did not run a lookup against this run's own records, because the task forbids reading other findings.

## Step 1 — Code audit

### Cited sites (verified against the worktree)

- `RetryerBuilder.java:40`: `private List<RetryListener> listeners = new ArrayList<RetryListener>();` creates one mutable `ArrayList` per builder.
- `RetryerBuilder.java:61-65`: `withRetryListener` calls `listeners.add(listener)` on that list. It has no copy-on-write and no synchronization, so `ArrayList.add` does `modCount++` and appends.
- `RetryerBuilder.java:190-197`: `build()` passes the same `listeners` reference to `new Retryer<V>(..., rejectionPredicate, listeners)` at line 196. It does not copy the list.
- `Retryer.java:52`: `private final Collection<RetryListener> listeners;`
- `Retryer.java:137`: `this.listeners = listeners;` stores the reference without copying it.
- `Retryer.java:155-185`: `call()`.
  - Lines 159-164: the attempt runs inside `try { ... } catch (Throwable t)`, and any outcome becomes an `Attempt`.
  - Lines 166-168: `for (RetryListener listener : listeners) { listener.onRetry(attempt); }` uses `ArrayList.Itr`, a fail-fast iterator. This loop is outside any try/catch.
  - Lines 170-183: after the loop come the rejection predicate, then `attempt.get()` or the stop strategy, then wait/block.
- `Retryer.java:39-40` (class Javadoc): "A retryer is thread-safe, provided the arguments passed to its constructor are thread-safe." When the builder is used, the caller never passes the list. `build()` passes the builder's private `ArrayList`.
- `Retryer.java:146-153` (`call` Javadoc): the documented outcomes are (1) return the callable's result, (2) `ExecutionException` when the callable threw and the predicate accepts the attempt, and (3) `RetryException` when the stop strategy aborts or the thread is interrupted. `ConcurrentModificationException` is not among them.
- `RetryListener.java:28-35`: `onRetry` "will fire no matter what the result is and before the rejection predicate and stop strategies are applied". Doing slow work inside it (logging, metrics) is allowed. The interface puts no timing limit on listeners.

### JDK mechanism (JDK 21 runtime; `--release 8` only restricts the API)

`ArrayList.add(e)` runs `modCount++` and then appends, which changes `size`. `ArrayList.Itr` records `expectedModCount = modCount` when the iterator is created. `hasNext()` is `cursor != size`. `next()` starts with `checkForComodification()`, which throws `ConcurrentModificationException` when `modCount != expectedModCount`. The for-each loop at `Retryer.java:166` is therefore a fail-fast iteration over a list that another thread can change through the builder's public API.

### Call chain from the public API

1. User thread T1: `Retryer r = RetryerBuilder.newBuilder()...withRetryListener(L1)...build();` (RetryerBuilder.java:51, 61, 190-197). `r.listeners` is the builder's `ArrayList`.
2. Worker thread T2: `r.call(callable)` or `r.wrap(callable).call()` on an executor (Retryer.java:155, 195-197, 317-319). The attempt runs and becomes an `Attempt` (lines 159-164). Then the for-each at line 166 creates `ArrayList.Itr` and calls `L1.onRetry(attempt)`.
3. Thread T1, meanwhile: `builder.withRetryListener(L2)` (RetryerBuilder.java:63), for example to build a second retryer "for use some other time" as in upstream #48. `ArrayList.add` does `modCount++` and `size++`.
4. T2: the next `hasNext()` sees `cursor(1) != size(2)`, so `next()` throws CME from `checkForComodification()`. If the add lands between `iterator()` and the first `next()`, the throw happens at `cursor == 0`; that is the exact TLC interleaving. The CME propagates out of `call()`. Lines 170-183 never run: no predicate, no `attempt.get()`, no stop strategy, no retry. The callable's return value, or its exception (wrapped `ExecutionException` / `RetryException`), is discarded.

Reachability: every step uses public API (`newBuilder`, `withRetryListener`, `build`, `call`/`wrap`). The only precondition is that the builder is still used after `build()` while a built retryer runs on another thread. The builder Javadoc does not forbid reusing a builder after `build()`, and #48 shows a user doing exactly that.

### Safeguards encountered (recorded, not dismissed)

- None in the library. Neither `build()` nor the constructor copies the list, and neither the loop nor `call()` catches `RuntimeException`.
- `RetryerCallable.call()` (Retryer.java:317-319) is a straight delegation, so the CME reaches the executor's `Future` as `ExecutionException(cause=CME)`. A caller that only expects `RetryException`, or a wrapped callable exception, sees an undocumented failure.
- Timing: the race window is the duration of the listener loop (iterator creation up to the last `next()`). It widens with the time listeners spend in `onRetry`. A no-op listener gives a window of a few instructions.
- JMM: the list is shared with no happens-before edge. The CME needs T2 to observe T1's `modCount`/`size` writes. On HotSpot/x86 these plain-field writes become visible promptly in practice, but the JMM does not guarantee it. The TLC model is sequentially consistent.

### Trigger scenario (from the CE `spec/output/hunt_s3_listeners_bfs1.out`, 7 states)

1. Init: the builder list has one listener (`blist = <<1>>`, `bmod = 1`).
2. `MCCallStart(c1)`: c1 enters `call()`.
3. `MCCallerBodyStart(c1,"Ret")` → 4. `MCCallerBodyReturns(c1)`: the callable ran and returned a value (`curTag = "Result"`, `curInvoked = TRUE`).
5. `MCListenersBegin(c1)`: the iterator is created (`itExpMod = 1`, `itCursor = 0`).
6. `MCAddListenerBegin(2)`: another thread runs `withRetryListener` and `ArrayList.add` does `modCount++` (`bmod = 2`).
7. `MCListenerCME(c1)`: `next()` sees `modCount != expectedModCount`, so `outcome = "CME"` and `cpc = "Done"`. `exitInfo.invoked = TRUE` with tag `Result`: the attempt ran, but its outcome was never delivered. `DocumentedOutcomesOnly` is violated.

Second CE `spec/output/hunt_sharing_bfs1.out` (10 states, two-caller config, only c1 active): with a `fixedTimeLimit`, the attempt times out (`MCGetTimeout`, cancel), then `MCListenersBegin` → `MCAddListenerBegin(2)` → `MCListenerCME`. The same CME also discards a timed-out attempt and the retry decision that should follow it.

## Step 2 — Developer-knowledge search

- Upstream issue #48 (OPEN, 2015-08-24, JensRantil): "Multiple builders constructed from the same builder always use the same listeners", https://github.com/rholder/guava-retrying/issues/48. Quote: "`firstRetryer.call(...);` will call both listeners since they are based on the same mutable list. **Proposed fix:** Create an `ImmutableList` using `#copyOf` (from Guava) when creating a builder." It has no comments. It reports the aliasing and its sequential consequence (extra listener notified). It says nothing about threads, ConcurrentModificationException, or lost outcomes.
- Upstream issue #35 (CLOSED, "Reuse Retryer across threads"). Maintainer rholder: "Yes, they should all be thread-safe. Here's an example of one that could be shared: `private static final Retryer<APIResponse> API_RETRYER = RetryerBuilder...build();`". The developers intend built retryers to be shared across threads.
- Tracker searches (`gh search issues --include-prs --repo rholder/guava-retrying`): "ConcurrentModificationException" (0 hits), "concurrent modification" (0), "listener" (#48, #56, #60, #23, #54, #47, #71, #36, all unrelated except #48), "listeners" (#48, #36), "thread-safe" (#13, #35), "thread safe" (#35), "withRetryListener" (#48, #62, #47, #92, #60, #54), "ImmutableList" (#48), "copyOf" (#48). No hit reports a CME or a concurrent consequence.
- All 45 upstream PRs (`gh pr list --state all`): none copies or guards the listener list. The most recently closed PRs, #107 "Modernize" (closed 2026-09-05, unmerged; a PHP port that deletes the Java sources) and #84 (README, closed 2026-09-20), are unrelated. The last merged PR is #42 (2015-06-22).
- Blame: `RetryerBuilder.java:40` comes from 54a2a4d (2015-05-03, "listeners should probably be a List since the order is significant"). Lines 61-65 and 196 and `Retryer.java:137,166,168` come from 1edb757 (2015-04-21, "Add RetryListener implementation", PR #37). `Retryer.java:167` comes from e90fe64 (2015-05-12). `Retryer.java:39-40` (the thread-safety Javadoc) comes from 6d2d838 (2012-11-17), which predates listeners. No commit message discusses copying the list or concurrency.
- `RetryListener` and its usage are `@Beta` (b188a69, "so we can continue iterating here without freezing the public API #36"). That concerns API stability, not thread-safety.
- Tests: `RetryerBuilderTest.testRetryListener_SuccessfulAttempt`, `testRetryListener_WithException` and `testMultipleRetryListeners` (lines 463-550) are all single-threaded and add every listener before `build()`. No test covers changing the builder after `build()`, or concurrency.

## Step 3 — Known-status / precedent

- Source: MC, with real counterexamples (`hunt_s3_listeners_bfs1.out`, `hunt_sharing_bfs1.out`). The code-review × known pre-filter does not apply, so the finding proceeds to Phase 2.
- Known-status evidence: #48 reports the shared root cause (aliasing at `RetryerBuilder.java:196`) with a different, sequential consequence. No issue or PR, including recently closed PRs, reports the mechanism of this finding: a concurrent `withRetryListener` that makes the fail-fast iteration at `Retryer.java:166-168` throw CME out of `call()` and discard the attempt outcome. The fix #48 proposes (`ImmutableList.copyOf` in the builder) would also remove this consequence.

## Repair round 1 continuation (2026-11-26, re-dispatch after Phase 3 round 1)

The dispatcher re-sent MC-7 with the same current violation analysis and the same counterexample path. The prior disposition was `REPRODUCED`. Each prior fact was re-checked against the current files, not re-derived.

- **Counterexample.** `spec/output/hunt_s3_listeners_bfs1.out` has sha256 `8a1b40f2…` and mtime 2026-11-26 08:05:54Z, so it was written before the round-0 verdict. It still has 7 states with the same action sequence: `MCCallStart(c1)` → `MCCallerBodyStart(c1,"Ret")` → `MCCallerBodyReturns(c1)` → `MCListenersBegin(c1)` (`itExpMod=1`, `itCursor=0`) → `MCAddListenerBegin(2)` (`bmod=2`, `bAdding=2`, `blist` still `<<1>>`) → `MCListenerCME(c1)`. The final state has `outcome="CME"`, `cpc="Done"` and `exitInfo=[flag FALSE, count 1, tag "Result", invoked TRUE]`. The TLC output names only `DocumentedOutcomesOnly`, because TLC stops at the first violated invariant. The `NoLostAttemptOutcome` violation is the finding's own additional claim and matches the reproduced consequence: the callable ran once and its outcome was never delivered. The `MC_hunt_s3_listeners.cfg` sha256 is `6634aac2…`, with mtime 06:48Z.
- **Precision on the second CE (`hunt_sharing_bfs1.out`).** This trace has 10 states. The cfg defines two callers, but only c1 moves; c2 stays `Idle`. Steps 3-7 are `MCSubmitNewWorker` → `MCGetTimeout` → `MCCancelCASWon` → `MCCancelReadRunner` → `MCCancelFinish`, so the cancel wins before the worker starts the body. As a result, `exitInfo.invoked = FALSE` and `curTag = "Timeout"`. In this trace the callable never ran. What is lost is the timed-out attempt and the retry that should follow it. The finding summary's phrase "also with two callers" refers to the cfg, not to two active callers. The round-0 statement "two-caller config, only c1 active" stands. Repro case L1-c exercises the same CME in the listener loop after a timeout, with one difference: the body had started and was interrupted, not cancelled before it started.
- **Source.** The worktree HEAD is `177b6c9` with 0 dirty files. `Retryer.java`, `RetryerBuilder.java` and `RetryListener.java` are byte-identical to `/home/ubuntu/scratch/guava-retrying-src/guava-retrying`. Every cited line was re-read and is unchanged: `RetryerBuilder.java:40,61-65,190-197`, `Retryer.java:39-40,52,137,146-153,155-185,195-197,317-319`, `RetryListener.java:28-35`.
- **Tracker re-check (around 16:52Z).**
  - #48 is still OPEN with 0 comments; it was last updated 2015-11-05.
  - `gh search issues --include-prs --updated ">=2026-11-01"` returns 0 results, so nothing has been filed, merged or closed since the round-0 search.
  - "ConcurrentModificationException" and "concurrent modification" each return 0 hits.
  - "withRetryListener" returns #47, #48, #54, #60, #62 and #92; "listeners" returns #36 and #48. These are the same sets as before.
  - The newest upstream commits touching `RetryerBuilder.java` and `Retryer.java` date from 2015 (54a2a4d and 3744989).
- **Repro re-run.**
  - Command: `timeout 15m bash repro/test_bugMC-7_builder_listener_cme.sh`, run from `.specular-output/` on OpenJDK 21.0.13.1. The script's sha256 is unchanged (`75d5a3b6…`). The log is `confirmation/MC-7/repro-output-repair1.log` and the exit code was 0.
  - Level 0: L0-a hit a CME in 673/2000 trials, 3 of them at `itCursor=0` (the exact TLC interleaving), with 0 other failures. In L0-b, 138/200 trials had a CME-failed `Future`, for 220 futures in total.
  - Level 1: cases a-d reproduced 4/4.
  - Controls: C-a/b/c all behaved as documented.
  - Negative control: F-a/b/c/d returned 42 and L0 saw 0 CMEs.
  - The round-0 logs (`repro-output.log` for JDK 21, `repro-output-jdk11.log`) are kept unchanged.
- **Correction.** The round-0 `issue.json` said the pure black-box stress triggers in "roughly 40-80% of trials". This run hit 673/2000 (33.7%). The observed range is therefore about 34-81% across runs: 673/2000 and 876/2000 on JDK 21, and 813/1000 on JDK 11. `issue.json` is updated to match.
