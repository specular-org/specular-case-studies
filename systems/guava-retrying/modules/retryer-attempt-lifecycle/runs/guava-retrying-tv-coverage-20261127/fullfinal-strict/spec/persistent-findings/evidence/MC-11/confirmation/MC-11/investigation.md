# MC-11 — Phase 1 investigation (evidence only)

Finding: a listener added to a `RetryerBuilder` after `build()` is notified by an already-built `Retryer`, including by a call already in flight. Invariant `ListenersFixedAtBuild`, cfg `MC_hunt_s3_listeners.cfg`, counterexample `spec/output/hunt_s3_listeners_bfs2.out` (9 states). Secondary trace cited by the finding: `spec/output/hunt_sharing_bfs4.out` (12 states).

Source under test: worktree at upstream `177b6c9` (= upstream `master` HEAD, release 2.0.0 + one Travis commit), clean.

Persistent-findings lookup (`specular findings ... lookup --query RetryerBuilder --query withRetryListener --query ListenersFixedAtBuild --query listeners`) returned `[]` (no prior record; `previous: null`).

## Step 1 — Code audit

### Cited sites (read in full)

- `src/main/java/com/github/rholder/retry/RetryerBuilder.java:40` — `private List<RetryListener> listeners = new ArrayList<RetryListener>();` (one mutable list per builder).
- `RetryerBuilder.java:61-65` — `withRetryListener(listener)` does `listeners.add(listener)` (line 63) on that same list, with no "already built" check (unlike `withWaitStrategy`/`withStopStrategy`/`withBlockStrategy`, which use `checkState(... == null)` but also do not care about `build()`).
- `RetryerBuilder.java:190-197` — `build()` passes the builder's `listeners` field by reference: `return new Retryer<V>(..., rejectionPredicate, listeners);` (line 196). No copy.
- `Retryer.java:119-138` — the `@Beta` 6-arg constructor stores the collection by reference: `this.listeners = listeners;` (line 137); field `private final Collection<RetryListener> listeners;` (line 52) — `final` reference, mutable contents.
- `Retryer.java:166-168` — inside `call()`, after each attempt is classified, `for (RetryListener listener : listeners) { listener.onRetry(attempt); }` iterates the live (shared) list every attempt.

### Call chain (public API only)

1. `RetryerBuilder.newBuilder()` → `.withRetryListener(L1)` → `.build()` ⇒ `Retryer r` whose `listeners` field *is* the builder's `ArrayList`.
2. Later `builder.withRetryListener(L2)` ⇒ `ArrayList.add(L2)` on the same object ⇒ `r`'s listener set now contains L2.
3. `r.call(callable)` (directly, or via `r.wrap(callable).call()`) ⇒ `Retryer.call` line 160 runs the attempt, then line 166 iterates the shared list ⇒ `L2.onRetry(attempt)`.

All steps are public API in normal use. Reachability: unconditional — no configuration, timing or fault is needed for the sequential form (build → add → call). The in-flight form (the MC counterexample) needs only a second thread calling `withRetryListener` while `call()` is running attempt 1's callable.

### Trigger scenarios

- (A, sequential — issue #48's example) `r1 = b.build(); b.withRetryListener(L2); r2 = b.build(); r1.call(c)` ⇒ `L2.onRetry` fires for `r1`'s attempts. `r1` and `r2` also share one list object.
- (B, in flight — MC counterexample `hunt_s3_listeners_bfs2.out`) Thread T1 is inside `r.call(c)`, attempt 1's callable is executing (no time limiter → runs on T1). Thread T2 completes `b.withRetryListener(L2)`. The callable returns; T1 creates the iterator at line 166 *after* the add, so `expectedModCount` already includes the add (no CME), and T1 notifies L1 then L2.
- (C, straddle — `hunt_sharing_bfs4.out`) `ArrayList.add` bumps `modCount` before it publishes the element/size. If T1's iterator is created between those two writes, `expectedModCount` matches, and the element becomes visible before the iterator's second `hasNext()`, so L2 is notified without a CME. This is a narrower interleaving inside JDK `ArrayList`; (B) already shows the same consequence.

### Safeguards encountered

- None in the library: no defensive copy (`ImmutableList.copyOf`/`new ArrayList<>(...)`) at `build()` or in the `Retryer` constructor, no "built" flag in the builder, no synchronization of `listeners`.
- The only incidental "guard" is `ArrayList`'s fail-fast iterator: if the add happens *while* the for-each loop is between notifications, `next()` throws `ConcurrentModificationException` (different symptom, that is the CME half — covered by another finding, not this one). It does not prevent scenarios A/B/C above, where the add completes before (or straddles) iterator creation.
- Without a happens-before edge between T2's add and T1's iteration, T1 may also see a stale list (Java memory model); the deterministic repro uses user-side latches, which create that edge, so it shows the plain logical aliasing rather than a visibility artifact.

## Step 2 — Developer-knowledge search

### Issue tracker (gh, `rholder/guava-retrying`, all states)

- **#48 (OPEN, 2015-08-24, JensRantil)** "Multiple builders constructed from the same builder always use the same listeners" — https://github.com/rholder/guava-retrying/issues/48. Verbatim: "`RetryerBuilder<Object> myBuilder = RetryerBuilder.<Object> newBuilder().withRetryListener(myFirstListener); Retryer<Object> firstRetryer = myBuilder.build(); myBuilder.withRetryListener(mySecondListener); Retryer<Object> secondRetryer = myBuilder.build();` … `firstRetryer.call(...);` will call both listeners since they are based on the same mutable list. **Proposed fix:** Create an `ImmutableList` using `#copyOf` (from Guava) when creating a builder." No comments, no maintainer response.
- **#35 (CLOSED)** "Reuse Retryer across threads" — maintainer rholder: "Yes, they should all be thread-safe. Here's an example of one that could be shared: `private static final Retryer<APIResponse> API_RETRYER = RetryerBuilder...build();`".
- **#13 (OPEN)** "Make it possible to get a builder from a Retryer instance for further customisation" and PR **#43 (OPEN)** "Return builder from a Retryer instance" — related builder-reuse requests, not fixes for #48.
- Other listener issues (#47, #56, #60, #62, #36) concern listener semantics/typing, not aliasing.
- PRs (45 total, all states): none touches listener copying. Most recent: #107 "Modernize" (CLOSED 2026-09-05, **not merged**; rewrites the repo into PHP — not a fix); #105/#103/#101/#99/#98/#95/#91 unrelated. #37 (MERGED 2015-05-04) introduced `RetryListener` (the aliasing originates here).
- Upstream `master` HEAD = `177b6c9` (2016-05-10), identical to this worktree; `RetryerBuilder.java` on master still has line 40 `new ArrayList<RetryListener>()`, line 63 `listeners.add(listener)`, line 196 `new Retryer<V>(..., listeners)`.

### Commits / blame

- `RetryerBuilder.java:61-65`, `:196`, `Retryer.java:52`, `:119-137`, `:166,168` — `1edb757e` (Kevin Conaway, 2015-04-21) "Add RetryListener implementation" (PR #37).
- `RetryerBuilder.java:40` — `54a2a4d5` (Ray Holder, 2015-05-03) "listeners should probably be a List since the order is significant for their behavior" (changed type only; still shared).
- `Retryer.java:118` — `b188a69f` "mark the RetryListener interface and usage with the @Beta annotation so we can continue iterating here without freezing the public API #36".
- No commit message states that post-build listener addition is intended or accepted.

### Comments / docs

- `Retryer.java:39-40` class Javadoc: "A retryer is thread-safe, provided the arguments passed to its constructor are thread-safe." (The builder passes its own non-thread-safe `ArrayList`.)
- `RetryerBuilder.java:28` "A builder used to configure and create a Retryer"; `:186-188` `build()` "Builds the retryer." — no statement that the Retryer remains linked to the builder.
- `RetryerBuilder.java:56` `withRetryListener`: "Adds a listener that will be notified of each attempt that is made" — no statement that it affects already-built Retryers.
- `RetryListener` is `@Beta`. README never mentions listeners.

### Tests

- `RetryerBuilderTest.java:463-551` (`testRetryListener_SuccessfulAttempt`, `testRetryListener_WithException`, `testMultipleRetryListeners`) only register listeners before `build()`. No test adds a listener after `build()` or asserts either behavior.

## Step 3 — Known-status / precedent

- Same mechanism, same sites: #48 reports exactly this — the builder's mutable listener list shared with built Retryers (`RetryerBuilder.java:40/63/196`, `Retryer.java:137/166`). Its example is scenario A; the MC trace (scenario B) is the same aliasing observed by a call already in flight.
- Status: **KNOWN (cite: https://github.com/rholder/guava-retrying/issues/48; fix-status: unfixed)** — issue OPEN, no fixing PR merged or open, upstream master unchanged.
- Pre-filter: the finding is MC-sourced with an actual counterexample (`hunt_s3_listeners_bfs2.out`, invariant `ListenersFixedAtBuild` violated at State 9), so the code-review × known drop does **not** apply. Proceed to Phase 2.

## Repair round 1 continuation (2026-11-26, after the Phase-3 repair pass)

The dispatcher still lists MC-11 as a current violation with the same analysis and counterexample (`spec/output/hunt_s3_listeners_bfs2.out`). Round-0 evidence was re-checked against the current source and trace rather than redone from scratch.

- Source: the worktree was recreated at `177b6c9` and is clean. The cited lines are unchanged: `RetryerBuilder.java:40`, `:63`, `:196`, `Retryer.java:52`, `:137`, `:166-168`, and the class Javadoc at `Retryer.java:39-40`. Blame is unchanged (`54a2a4d5` for line 40, `1edb757e` for the rest). The one exception is `Retryer.java:167`, last touched by `e90fe648`, "continue refactoring to simplify listener, related to #25 #36", which only changed `onRetry(attempt, attemptNumber)` to `onRetry(attempt)` and says nothing about intent.
- Counterexample: `hunt_s3_listeners_bfs2.out` was not regenerated. Its mtime is 08:11, which is before the round-0 confirmation (10:22) and before the Phase-3 spec edits (about 12:28-12:41). The re-read state sequence matches round 0. The add completes in S4-S5 (`bmod=2`, `blist=<<1,2>>`) while `cbody="Ret"` is running. The iterator is created after it in S7 (`itExpMod=2`). S9 ends with `notified=<<1,2>>`, and `ListenersFixedAtBuild` is violated.
- Correction to the finding summary (not to round-0 evidence): the summary says "with two callers the add can straddle the iterator creation" for `hunt_sharing_bfs4.out`. That cfg does have two caller slots, but in the trace `c2` stays `Idle` in every state. The straddle is between `c1` and the builder thread only. Also, `c1`'s attempt 1 in that trace is a `fixedTimeLimit` timeout (S3 `MCSubmitNewWorker`, S4 `MCGetTimeout`, then S5-S7 `MCCancelCASWon`/`MCCancelReadRunner`/`MCCancelFinish`), followed by the straddle in S8-S12: `MCAddListenerBegin` (`bmod=2`), `MCListenersBegin` (`itExpMod=2` while `blist=<<1>>`), notify L1, `MCAddListenerEnd`, notify L2. The straddle does not depend on the time limiter: the round-0 JPF workload reaches it with the default `noTimeLimit`.
- JPF statistics note: in the JPF log, "L2 notified via straddling iterator: 0" in the end-state counts does not contradict "STRADDLE PATH FOUND". The counts cover distinct end states only, and with state matching on, the straddle path merges into an already-visited state and is not re-counted, as the listener output itself states.
- Known-status re-check (gh, 2026-11-26): #48 is still OPEN with 0 comments (last update 2015-11-05). Upstream `master` is still `177b6c9`. No PR was ever merged that touches this. The most recently updated PRs are #84 (README, closed unmerged 2026-09-20) and #107 ("Modernize", closed unmerged 2026-09-05). GitHub search for `listeners` in the repo returns only #48. Status unchanged: KNOWN (#48, unfixed).
- Persistent-findings lookup (`ListenersFixedAtBuild`, `withRetryListener`, `RetryerBuilder`) still returns `[]`.
- Reproduction re-run on the recreated worktree: `timeout 10m bash repro/test_bugMC-11_listener_added_after_build.sh` gave `EXIT=0`. The unmodified library shows 3/3 anomalies, the fix control 0/3, and the 36 upstream tests pass on both builds. 10 more runs with `RUN_UPSTREAM_TESTS=0` all gave 3/3 vs 0/3 with exit 0. The output matches the round-0 log line for line (only javac `Note:` temp paths and diff-header timestamps differ), and `repro/MC-11.log` now holds the round-1 run. The JPF re-run (`jpf/run_jpf_straddle.sh`) printed `[MC11]` lines identical to `jpf/jpf_straddle.log` (410 new states, `constraints=0`, "no errors detected").
- Nothing in the current source or traces contradicts a round-0 statement. The only correction is the "two callers" wording in the finding summary noted above.
