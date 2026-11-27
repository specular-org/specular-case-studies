# Analysis Report: guava-retrying 2.0.0 — Code Analysis Audit Trail

Companion to `modeling-brief.md` (primary handoff) and `defect-ledger.json`. This report records how the analysis was done, the archaeology coverage, every hypothesis examined with its verdict, the exclusions, and where the evidence lives.

## 0. Run context and method

- **Target**: rholder/guava-retrying, checkout `/home/ubuntu/scratch/guava-retrying-src/guava-retrying` at `177b6c9` (2016-05-09). `git diff c3e1c37 HEAD -- src` is empty: src/main equals the `v2.0.0` tag; the only later commit edits `.travis.yml`. The checkout was never modified (all subagents used read-only commands; `git status` clean).
- **Scope** (target guidance): everything under `src/main/java/com/github/rholder/retry/` plus Guava `SimpleTimeLimiter` behavior as used by `AttemptTimeLimiters`; emphasis on the attempt lifecycle under time limits, interruption, and sharing across threads; exclusions: build/packaging/dependency problems, message formatting, naming, API ergonomics.
- **Environment**:
  - Guava 22.0 sources: `guava-22.0-sources.jar` from Maven Central, SHA-1 verified, extracted to `/home/ubuntu/scratch/guava22-sources-dl/extracted/`.
  - JDK sources (FutureTask, ThreadPoolExecutor, Thread, ArrayList, Random, Throwable, ForkJoinTask, Executors, hotspot `jvm.cpp`) for JDK 8u, 11u and 21u from the openjdk GitHub repositories, in `/home/ubuntu/scratch/jdk-src/{8,11,21}/` (the local JDK `src.zip` links are dangling). JDK 8 is not installed: JDK 8 behavior is stated from source only.
  - Out-of-tree Maven build `analysis-evidence/build/pom.xml` (source and test directories point into the untouched checkout; Guava 22.0, jsr305 2.0.2, JUnit 4.11, mockito-all 1.9.5; JDK 21 `--release 8`): compiles and passes all 36 existing tests (4 + 19 + 12 + 1).
- **Method**: the Specular `code-analysis` skill (Step 0 classification, Phases 1–4), Category B references (`deep-analysis.md`, `concurrent-analysis.md`).
  - Phase 1 and the first full read of all 13 main files and `SimpleTimeLimiter.java` in the main context.
  - Phase 2 in parallel subagents: (A) all 61 issues, (B) all 45 PRs, their diffs, and forks, (C) all 103 commits.
  - Phase 3 in parallel forks by mechanism: (D1) time-limiter lifecycle, (D2) interrupt handling, (D3) builder handoff and sharing, (D4) strategies and `call()` outcomes. Each fork read its files fully, applied the analysis patterns, and wrote bounded probes against the unmodified library.
  - Cross-reference and verification in the main context: re-read of every cited line; re-ran the key probes myself on JDK 21 (and saved JDK 11/21 logs): `IntProbe`, `IntProbe2`, `IntProbe3`, `IntProbe4`, `SharedListenerCME` (both modes), `ListenerSetDrift`, `SharedLimiterStarvation`, `WrapSameExecutor`, `WrapCancelZombie2`, `EscapeProbe`, `IncProbe`, `OutcomeProbe`, `RandomMinValue`, `StrategyMath`; wrote and ran `SerProbe` (D-23).
- **Persistent findings**: the pipeline context (`persistent-findings-context.json`) has `previous: null` and no inherited records. `specular findings --work <output> lookup --query Retryer.call --query AttemptTimeLimiters --query InterruptedException --query RetryerBuilder.build --query CompositeWaitStrategy` returned `[]`; nothing to reuse.
- **Evidence levels used below** (kept separate, never merged in counts):
  - **Probe (CA)** — reproduced by a code-analysis probe on the unmodified 2.0.0 classes with Guava 22.0 (JDK 11 and/or 21). This is reachability evidence for the ledger, not Bug Confirmation's `REPRODUCED` verdict.
  - **Code** — established by source reading only.
  - **Refuted** — shown not to be a defect (or unreachable).

## 1. Category

**Category B (Concurrent / Runtime).** No network, persistence or message passing exists. The behavior under study is (a) the caller → executor-worker handoff inside `SimpleTimeLimiter` and `FutureTask` (CAS-driven state machine, park/unpark with timeout, cancellation by interrupt), (b) interrupt-status flow on the calling thread, and (c) a mutable `ArrayList` shared between the builder's thread and threads running `Retryer.call`. Concurrent-analysis patterns that applied: split operation windows (§ 2.1 of the reference: timeout decision → cancel; body end → set CAS), ownership transfer and completion ordering (§ 2.5: cancel without join), fast/slow path divergence (§ 2.6: noTimeLimit vs fixedTimeLimit classification; sleep path vs attempt path for interrupts), bookkeeping boundary violations (§ 2.7: attempts counted without running), cancellation (§ 5.2) and caller misuse/adversarial client (§ 5.7: builder reuse).

## 2. Phase 1 — Reconnaissance

### 2.1 File map (non-comment code lines)

| File | Lines | Role |
|---|---:|---|
| `WaitStrategies.java` | 220 | Fixed, random, incrementing, exponential, Fibonacci, exception and composite (`join`) waits |
| `Retryer.java` | 180 | The loop (`call`), `wrap`/`RetryerCallable`, `ResultAttempt`/`ExceptionAttempt` |
| `RetryerBuilder.java` | 118 | Builder state, `retryIf*` predicate composition, `build()` |
| `StopStrategies.java` | 55 | `neverStop`, `stopAfterAttempt`, `stopAfterDelay` |
| `AttemptTimeLimiters.java` | 54 | `noTimeLimit`, `fixedTimeLimit` (2- and 3-argument) over Guava `SimpleTimeLimiter` |
| `RetryException.java` | 23 | Checked exception with `int` count and last `Attempt` |
| `BlockStrategies.java` | 17 | `ThreadSleepStrategy` (`Thread.sleep`) |
| `Attempt.java`, `RetryListener.java`, `AttemptTimeLimiter.java`, `WaitStrategy.java`, `StopStrategy.java`, `BlockStrategy.java` | 34 | Interfaces |
| **Total** | **701** | (1,457 physical lines with license and Javadoc) |

### 2.2 Threads and atomicity boundaries

- **Caller thread**: runs all of `Retryer.call`. With `noTimeLimit` it also runs the callable. Steps and the points where the interrupt status is tested, cleared or restored are tabulated in brief § 1.1.
- **Limiter worker threads** (fixedTimeLimit only): run `FutureTask.run` → callable. Default executor: one private `Executors.newCachedThreadPool()` per `FixedAttemptTimeLimit` (non-daemon, SynchronousQueue, 60 s keep-alive, never shut down).
- **Builder thread** (any thread holding the builder): may call `withRetryListener` after `build()`.
- **Outer executor threads** (for `wrap()`): run `RetryerCallable.call` → `Retryer.call`; their cancellation reaches the loop only as an interrupt.
- **Atomic units that matter**: `FutureTask` state CASes (`cancel`: NEW→INTERRUPTING/CANCELLED; `set`/`setException`: NEW→COMPLETING; `run`: runner CAS), the `awaitDone` decision (state read vs deadline vs interrupt), `Thread.sleep`'s order of checks (negative, then interrupt, then sleep/yield), and the `ArrayList.Itr` fail-fast check (`modCount` vs `expectedModCount`). Everything in `Retryer.call` between these is plain sequential code on the caller thread.

### 2.3 Developer signals

`grep -n "TODO|FIXME|HACK|XXX"` over src/main finds nothing in 2.0.0 (TODOs added in `975cb89` and `1e7f2bd` were removed by `dbe616d`/`b188a69`). Guava's `SimpleTimeLimiter.java:138` carries "TODO: should this actually throw only ExecutionException?" on the very method this library calls.

## 3. Phase 2 — Bug Archaeology

### 3.1 Coverage statistics

| Source | Collected | Deeply read | Result |
|---|---:|---:|---|
| Git commits (HEAD) | 103 (89 non-merge + 14 merge) | all 32 non-merge commits touching src/main, plus the 10 PR merges carrying src/main changes (no conflict resolution in any) | 3 bug fixes (`434bb51` Medium, `d0d1e86` Low, `129627d` Low), all complete in 2.0.0; 9 features, 7 refactors, 12 docs, 1 build-release; **0 commits about interrupts, thread safety, overflow** (keyword hits for interrupt/thread/race/concurrent/safe/overflow/negative/timeout/leak: 0 genuine) |
| GitHub issues | 61 (all states) | 61 (body + every comment; comment counts cross-checked against the raw JSON) | 5 confirmed bugs (#3, #15 fixed; #29, #48, #97 present), 2 design defects (#67, #92), 1 user error (#106), 0 disputed, 0 uncertain, 25 feature requests, 15 questions, 12 build/packaging/dependency, 1 docs |
| Pull requests | 45 (15 merged, 19 open, 11 closed unmerged) | 45 threads and diffs | 11 with bug-fix intent (#16, #42, #64, #68, #75, #82, #95, #98, #99, #101, #103); in-scope bug-fix intent: #16 (merged, fixed) and #101 (open; the claimed defect is not one and merging it would remove the only interrupt checkpoint under `noWait`) |
| Forks / derivatives | 267 GitHub forks compared with upstream (250 without own commits, 15 with); 3 non-fork derivatives (rhuffman/re-retrying, itning/guava-retrying3, lowzj/java-retrying) | commits and issues of the 15 + 3 | Fixes in scope exist only for attempt-path interrupt handling (re-retrying) and default-pool lifecycle (re-retrying partly; guava-retrying3 and PR #103 by deleting the no-executor factory); nobody reported or fixed overlapping attempts, discarded completions, listener-list copying, or the wait-strategy overflows |

Issues excluded as false positive or not-a-defect: #106 (user error: jar missing from the runtime classpath, not a library or Java 21 problem). No issue was disputed or left uncertain. Feature requests, questions and build/packaging issues are classified, not counted as defects.

### 3.2 Git history

**Bug-fix commits (all complete in 2.0.0)**:

| SHA | Date | Fix | Root cause | Component | Severity | 2.0.0 status |
|---|---|---|---|---|---|---|
| `d0d1e86` | 2013-06-07 | #3: last attempt's exception becomes `RetryException`'s cause | constructor called `super()` without cause | RetryException | Low | complete (`RetryException.java:44-60`) |
| `434bb51` (PR #16) | 2014-03-26 | #15: elapsed time from `System.nanoTime()` | wall clock `currentTimeMillis` not monotonic: `stopAfterDelay` misfires on clock jumps | Retryer timing | Medium | complete (`Retryer.java:156,161,163`) |
| `129627d` (PR #42) | 2015-05-25 | wrong `checkNotNull` message for `rejectionPredicate` | copy-paste | Retryer constructor | Low | complete (`Retryer.java:129`); siblings `:125`, `:130` still have typos (message formatting, excluded) |

**Origins of the scrutinized mechanisms** (none was ever fixed; no commit message or comment discusses interrupts, thread safety or overflow):

| Mechanism | Introduced | Notes |
|---|---|---|
| `catch (Throwable t)` around the attempt; interrupt restore only around the sleep; `int attemptNumber`; IncrementingWait clamp; RandomWait `Math.abs(nextLong())`; "thread-safe" class Javadoc | `c531b61` (original import, 2012) | `fbe3177` reformatted only; `a96183d` (PR #20) moved `Thread.sleep` behind `BlockStrategy`, keeping the same catch |
| Per-attempt time limiter (`callWithTimeout(..., true)`, `new SimpleTimeLimiter()` per instance) | `7e474be` (PR #1, v1.0.3) | logic unchanged since; `AttemptTimeLimiters`/`AttemptTimeLimiter` byte-identical to 1.0.6 apart from copyright |
| Exponential wait (`Math.round(multiplier * 2^n)`, cap) | `fd8b13b` | first wait is 2×multiplier (#86, design) |
| Fibonacci wait with guard `result > maximumWait` or `result < 0L` | `ce0bc7d` (PR #9) | guard misses positive wraps (D-21) |
| `join` / `CompositeWaitStrategy` (plain sum) | `2b5bfec` (PR #17, #12) | no overflow or negativity guard (D-16) |
| `exceptionWait` | `9c6bd63` (PR #26, #25), renamed in `dbe616d` | no validation of the function result (D-17, D-18) |
| Listener list handed from builder to Retryer | `1edb757` (PR #37), `54a2a4d` (Collection→List, same reference) | #48 aliasing; D-8 |
| `Attempt` carries `long` number and delay | `1e7f2bd` | loop counter, `RetryException` count and `maxAttemptNumber` stay `int` (D-19) |
| Guava range `[10.+,)` | `d2d9701` (#32) | root of #57, #66, #70, #94, #104 (excluded) |

**Hotspots** (bug-fix commits per file): `Retryer.java` 2, `RetryException.java` 1, all others 0. Overall churn: Retryer 17 commits (9 logic), WaitStrategies 15 (7), RetryerBuilder 14 (5). The scrutinized mechanisms are "cold but untested": no fixes, and no tests for interrupts during an attempt (the only interrupt test, `RetryerBuilderTest.java:384-414`, exercises the sleep path), timeouts racing completion, builder reuse, or extreme strategy parameters.

### 3.3 Issues (all 61)

| # | State | Class | Scope Q | Present in 2.0.0 | Note |
|---|---|---|---|---|---|
| 2 | open | Feature | (API) | n/a | Make `RetryException` unchecked; maintainer open, never done |
| 3 | closed | Confirmed bug | Q4 | no | Cause propagation, fixed `d0d1e86` |
| 5 | open | Feature | — | n/a | Phi accrual detector |
| 12 | closed | Feature | Q5 | implemented | Became `join` (PR #17); its sum overflows (D-16) |
| 13 | open | Feature | Q3 adj. | n/a | Builder from Retryer; maintainer: "might have some thread safety implications"; PR #43 open |
| 14 | closed | Question | Q3/Q4 adj. | n/a | Custom StopStrategy; maintainer warns exceptions "can escape from the normal retry `call()` flow" |
| 15 | closed | Confirmed bug | Q5 | no | nanoTime, fixed `434bb51` |
| 18 | open | Feature | Q1 | yes | Timing wheel; maintainer: SimpleTimeLimiter "fairly wasteful" |
| 19 | closed | Feature | — | partly | Failure-only hook; PR #21 closed |
| 22 | closed | Question | — | n/a | Inverted predicate |
| 23 | open | Feature | Q3/Q4 adj. | yes | Attempt number on success |
| 25 | closed | Feature | Q5 adj. | implemented | `exceptionWait` (PR #26); output unvalidated (D-17, D-18) |
| 27 | open | Feature | (API) | n/a | retryIfCause |
| 28 | open | Feature | Q5 adj. | n/a | randomExponentialWait; PR #50 open |
| 29 | open | Confirmed bug (maintainer) | Q1/Q4 | **yes** | Timeout aborts retrying unless a predicate matches `UncheckedTimeoutException` (D-14) |
| 30 | closed | Feature | (API) | implemented | `stopAfterDelay(long, TimeUnit)` (PR #39) |
| 31 | closed | Build | out | n/a | Release request |
| 32 | closed | Build | out | n/a | Open Guava range (root of #94 etc.) |
| 33 | closed | Build | out | n/a | jsr305 vs annotations (wontfix) |
| 34 | open | Feature | (API) | n/a | Non-generic Retryer |
| 35 | closed | Question | Q3 | answer holds with caveats | Maintainer: "Yes, they should all be thread-safe." Breaks with builder mutation (D-8) |
| 36 | closed | Feature | Q3 | implemented | RetryListener (PR #37), introduced the shared list |
| 38 | closed | Build | out | n/a | Gradle 2.x |
| 41 | open | Feature | (API) | n/a | retryIf(BooleanSupplier) |
| 44 | closed | Build | out | n/a | Dup of #32 |
| 45 | open | Feature | (API) | n/a | Public Attempt implementations; PR #78 closed |
| 46 | open | Feature | (API) | n/a | Non-generic AttemptTimeLimiter |
| 47 | open | Feature (rename) | (naming) | behaves as documented | `onRetry` fires for every attempt |
| 48 | open | Confirmed bug (no reply) | Q3 | **yes** | Shared mutable listener list (D-9; root of D-8) |
| 49 | open | Feature | — | yes | Listener cannot tell whether a retry follows |
| 51 | open | Question | — | n/a | Arbitrary predicate (answered) |
| 52 | open | Feature | Q5 adj. | yes | Clock abstraction; PR #53 closed |
| 54 | open | Question | Q3 adj. | n/a | Per-call tracking needs per-call listener/ThreadLocal |
| 55 | open | Question | — | n/a | Unrelated |
| 56 | open | Question | Q4 adj. | n/a | Order: callable → listeners → predicate → stop → wait |
| 57 | open | Build | out | yes | Range resolved to a SNAPSHOT |
| 60 | open | Question | Q1/Q3 adj. | n/a | Swapping state in a listener races with a zombie attempt (D-1) |
| 61 | open | Feature | (API) | n/a | Spec string |
| 62 | open | Feature | (API) | yes | Generic RetryListener; PRs #77, #89 |
| 63 | open | Question | Q2 adj. | as designed | Quotes the sleep catch; non-blocking BlockStrategy + neverStop = busy loop |
| 65 | open | Feature | — | n/a | Future retryer proposal |
| 66 | open | Build | out | yes | Range resolved to Guava 20.0-rc1 |
| 67 | open | Design defect (no reply) | Q4 | **yes** | `catch (Throwable)` wraps Errors (D-15) |
| 69 | open | Question | Q1 | n/a | Custom executor exists (3-arg `fixedTimeLimit`) |
| 70 | open | Build | out | yes | Compile error with Guava 21 |
| 71 | closed | Question | — | n/a | Logging via RetryListener |
| 72 | open | Question | Q1 adj. | n/a | "Runs in the caller thread" is false with fixedTimeLimit (excluded: API semantics) |
| 74 | open | Build | out | yes | jsr305 compile dependency; PR #75 |
| 76 | open | Feature | (API) | yes | Protected builder constructor |
| 81 | open | Meta | — | n/a | Fork notice: rhuffman/re-retrying |
| 86 | open | Feature | Q5 adj. | n/a | First exponential wait is 2×multiplier (design) |
| 87 | open | Question | — | n/a | When to use Fibonacci |
| 92 | open | Design defect (no reply) | Q1 | **yes** | Non-daemon private pool delays exit ~60 s (related to D-3) |
| 93 | open | Docs | Q5 adj. | yes | Milliseconds undocumented |
| 94 | open | Build/dependency | out | yes | Guava ≥ 23: `NoSuchMethodError` / `IllegalAccessError` in `fixedTimeLimit` (excluded) |
| 96 | closed | Build/dependency | out | yes | Dup of #94 |
| 97 | open | Confirmed bug | out (message format) | yes | `%d` not formatted by Guava `Preconditions`; PRs #98, #99 |
| 100 | open | Meta | — | n/a | Fork notice: itning/guava-retrying3 |
| 102 | open | Feature | (API) | yes | Remove `final` from Retryer |
| 104 | open | Build | out | yes | Range resolved to a vendor build |
| 106 | open | User error | out | n/a | Jar missing from runtime classpath |

**Notes on the issues referenced by the brief** (full discussions read):

- **#29** (2015-01-17, against 1.0.6): "any exception thrown by the `AttemptTimeLimiter` will cause `Retryer` to abort. This is includes `TimeoutException`." rholder: "I agree with your assessment and would also consider it a bug, too … Without explicit handling of `com.google.common.util.concurrent.UncheckedTimeoutException` (or maybe more loosely any `RuntimeException`) the `Retryer` effectively stops retrying instead of giving up on the attempt and trying again. Catchall `retryIfException()` or `retryIfRuntimeException()` retrying appears to mask this behavior as well." dirkraft (author of the limiter): "the attempt timeout should at a minimum behave like any other exception thrown by an attempt". No PR followed. 2.0.0 behaves the same (Probe (CA) `P8Issue29`; `AttemptTimeLimiterTest.java:44-50` encodes it).
- **#35**: "Yes, they should all be thread-safe. Here's an example of one that could be shared" (a static Retryer).
- **#48** (JensRantil, 0 comments): two Retryers built from one builder "will call both listeners since they are based on the same mutable list"; proposes `ImmutableList.copyOf`. No mention of concurrent use or `ConcurrentModificationException`.
- **#67**: request to catch `Exception`, not `Throwable`; unanswered.
- **#92** (2019): demo with `fixedTimeLimit(5 s)`; "process can not exit immediately"; unanswered. Reproduced by the issue subagent: JVM exits 60.0 s after `main()` returns (Demo92).
- **#13 / PR #43**: rholder: "Swapping out the old `Retryer` instance and updating the builder might have some thread safety implications".
- **#18**: rholder: "The current implementation of an `AttemptTimeLimiter` using `SimpleTimeLimiter` can be fairly wasteful with respect to resources."
- **#63**: quotes `Retryer.java:176-182`; nobody discusses interrupts during attempts.
- No issue, PR or commit in the upstream repository mentions interrupt handling during an attempt, overlapping attempts, discarded completions, or exceptions escaping from wait strategies.

### 3.4 Pull requests (all 45)

| # | State | Class | Bug-fix intent | In scope | Note |
|---|---|---|---|---|---|
| 1 | merged | feature | — | mechanism | Per-attempt time limit (Scenario 1 origin) |
| 4, 6, 7, 8, 10, 11 | merged | docs/build | — | out | Dependency bumps, CI, Javadoc, test imports |
| 9 | merged | feature | — | mechanism | Fibonacci wait (D-21 guard) |
| 16 | merged | bug fix | yes | in | nanoTime (#15), complete |
| 17 | merged | feature | — | mechanism | `join` (D-16) |
| 20 | merged | feature | — | mechanism | BlockStrategy; the sleep catch is the only interrupt restore |
| 21 | closed | superseded | — | out | Failed-attempt event (replaced by #37) |
| 24 | closed | superseded | — | out | Re-submitted as #26 |
| 26 | merged | feature | — | mechanism | `exceptionWait` (D-17, D-18) |
| 37 | merged | feature | — | mechanism | RetryListener; shared list (#48, D-8) |
| 39 | merged | feature | — | out | `stopAfterDelay(long, TimeUnit)` |
| 40 | open | test | — | in (test only) | BlockStrategiesTest |
| 42 | merged | bug fix | yes | out | Message text |
| 43 | open | feature | — | adj. Q3 | Return builder from Retryer; would amplify #48 |
| 50 | open | feature | — | out | Random exponential wait |
| 53 | closed | feature | — | out | Clock abstraction |
| 58 | open | test | — | out | Deprecated API cleanup |
| 59 | open | feature | — | out | Convenience constructor |
| 64, 68, 75 | open/closed | build | yes | out | Guava range, jsr305 scope |
| 73 | open | feature | — | out | Retry a Runnable (its own code bypasses the limiter) |
| 77, 89 | open | feature | — | out | Generic RetryListener |
| 78 | closed | feature | — | out | Public Attempt implementations |
| 79, 84, 88, 90, 91, 105 | open/closed | docs | — | out | README |
| 80, 83, 103, 107 | closed | mis-filed | (103: yes) | out | Intended for forks; #107 is a PHP port; #103 deletes the no-executor `fixedTimeLimit` |
| 82 | closed | build | yes | out | Guava fix, withdrawn for re-retrying |
| 95 | open | build + feature | yes | out (side effects in scope) | Guava ≥ 23 via 3-arg `callWithTimeout`: timeouts become checked `TimeoutException`, callable failures get wrapped; keeps the per-limiter non-daemon pool |
| 98, 99 | open | bug fix | yes | out | `%d` formatting (#97) |
| 101 | open | "bug fix" (perf) | yes (claimed) | in | Skips `Thread.sleep(0)`: removes the only interrupt checkpoint under `noWait` (archaeology probe T4: 1000 attempts instead of 1 after a pending interrupt; never ends with `neverStop`). Not a defect fix; harmful |

### 3.5 Forks and derivatives

- **rhuffman/re-retrying** (3.0.0): attempt-path interrupts — issue #32 ("Thread interruption when executing the callback is not propagated", citing the same Javadoc sentence; owner: "Thanks, and I agree. But this is a duplicate of #24."), commits `e2d01c3` (block path rethrows `InterruptedException`) and `f1ff0bf` (`catch (InterruptedException e) { throw e; }` before the catch-all) — the same mechanism as D-5/D-6, fixed there by an API change. Pool lifecycle — `5234118` (one static cached pool instead of one per limiter; threads still non-daemon). Issue #14 (= upstream #67) closed won't-fix. Issue #27 (attempt count type) did not address the wrap. Issue #40 (open): `RetryException` not serializable (D-23). Not fixed: listener sharing (later even predicates became shared), wait arithmetic. Regression: `2a07e7b` switched back to `currentTimeMillis`.
- **itning/guava-retrying3** (announced in #100): ported #98/#99; time-limiter path moved to the 3-arg call; the no-executor factory first used a non-terminating fixed pool, finally was deleted (`affae9e`). Not fixed: catch-all and interrupt handling, listener sharing, arithmetic.
- **lowzj/java-retrying**: same catch-all, same sleep-only interrupt handling, same shared listener list; its limiter requires an explicit executor.
- Other forks with own commits (storecast, IAT, qct, HubSpot, dima11051994, www1350, tagadvance, Breggor, haifeng9414, donalds2010, thefabulous, izerui, laohuyuhai): Guava compatibility, metrics, packaging; two switched to bounded pools (`newSingleThreadExecutor`, static `newFixedThreadPool(3)`), which turns D-1 zombies into D-4 starvation.

### 3.6 Documented semantics

README (`README.md:53-56`): "If any other `Exception` pops out of the `call()` method it's wrapped and rethrown in an `ExecutionException`." README examples `exponentialWait(100, 5, MINUTES)` and `fibonacciWait(100, 2, MINUTES)` promise "after 5 minutes, retry from then on in 5 minute intervals" (`:60-61`, `:76-77`) — verified to hold in reachable ranges. The README says nothing about time limiters, thread safety, interrupts, listeners or units. HISTORY.md records the features above. Javadoc contracts are collected in brief § 1.6.

### 3.7 Scenario grouping from the archaeology

Grouped by mechanism, not file: (1) the limiter's cancel-without-join handoff (#92, #18, #29, PR #1, fork pool changes) → Scenario 1; (2) interrupt handling only on the sleep path (fork re-retrying #32/`f1ff0bf`, PR #101 risk) → Scenario 2; (3) builder-to-Retryer aliasing (#48, #35, #13/PR #43, PR #37) → Scenario 3; (4) attribution of non-callable failures (#29, #67, PR #95/#103 shape changes) → Scenario 4; (5) unvalidated decision-step values (#12/PR #17, #25/PR #26, PR #9, #93) → Scenario 5. Historical fixes (#3, #15) are reference context only; nothing in the brief recreates a fixed defect.

## 4. Phase 3 — Deep Analysis

### 4.1 Time-limiter lifecycle (D1)

| Hypothesis | Verdict | Evidence | Ledger |
|---|---|---|---|
| H1.1 Timed-out attempt keeps running alongside later attempts and after `call()` | Probe (CA) | `P1Overlap`: `allTimeout` → `RetryException attempts=4 … stillRunning=4 maxConcurrentAttempts=4`, 1 s later `finishedAfterCallEnded=4`; `lastSucceeds` → returned 4 with 3 still running (JDK 11 same). `IntProbe4`: a caller interrupt also leaves attempt 1 running (finished at 1526 ms after `call()` returned at 322 ms). No join anywhere (`SimpleTimeLimiter.java:155-157,164-166`); late `set` loses CAS (`FutureTask.java:281-305`) | D-1 |
| H1.2 Timeout races completion; completed result discarded and work repeated | Probe (CA) | `P2Race` 83/20,000 (JDK 21), 60/20,000 (JDK 11) with the first Future NORMAL and a second invocation; the only path to a second invocation with a NORMAL first future is the timeout branch with `cancel` returning false | D-2 |
| H1.3 Threads outlive the call; unbounded growth with uninterruptible callables; JVM never exits | Probe (CA) | `P3ThreadGrowth`: 20 attempts → 20 threads blocked in `read` at +0/+2/+4 s; JVM not exiting (killed at 20 s). #92 covers only the idle 60 s delay (reproduced separately: `issue-repro/Demo92`) | D-3 |
| H1.4a Bounded executor saturated by own zombies / other callers / `wrap()` on the same pool | Probe (CA) | `P4Executors`, `SharedLimiterStarvation`, `WrapSameExecutor`; Guava warns about bounded executors (`SimpleTimeLimiter.java:56-58`), guava-retrying's factory does not | D-4 |
| H1.4b Shut-down/rejecting executor → REE treated as callable failure | Probe (CA) | `P4Executors` (37,453 attempts / 200 ms, 0 invocations), `OutcomeProbe` 7 | D-10 |
| H1.4c Direct executor / CallerRunsPolicy → no limit; H1.4d ForkJoinPool → no interrupt (JDK 11 `commonPool` may run the task inside `get`) | Probe (CA), environment | `P4Executors`, `P4bForkJoin` | excluded (JDK executor semantics) |
| H1.5 `fixedTimeLimit(≤0)` accepted, every attempt fails before running | Probe (CA) | `P5Duration`, `OutcomeProbe` 5-6 | D-11 |
| H1.6 Stack trace of a reused exception grows per attempt | Probe (CA) | `P6StackGrowth` 1 → 66,667 frames after 10,000 attempts | D-12 |
| H1.7 Non-Exception/non-Error Throwable classified differently by limiter | Probe (CA) | `P7Weird`, `OutcomeProbe` 3-4 | D-13 |
| H1.8 #29 still present | Probe (CA) | `P8Issue29`, `OutcomeProbe` 8 | D-14 |
| H1.9 Cancellation interrupt leaks into another attempt / the caller | Refuted for ThreadPoolExecutor and the caller (`runWorker` clears, `ThreadPoolExecutor.java:1136-1140`; `P9InterruptLeak` single-thread executor: no leak); a custom executor that never clears interrupts does leak (`P9`: attempt 2 started interrupted) — environment | `P9InterruptLeak` | excluded; InterruptContainment kept as a regression invariant |

### 4.2 Interrupt handling (D2)

Contract: C3/C4 (brief § 1.6). Guava's interruptible mode is documented to abort and throw `InterruptedException` (`TimeLimiter.java:88-93`), so restoring the status is `Retryer`'s job.

| Hypothesis | Verdict | Evidence | Ledger |
|---|---|---|---|
| H2.1 Caller interrupted while parked in `get` (fixed) | Probe (CA) | `IntProbe` H2.1a (`retryIfException`, neverStop → RETURNED ok, flag false, 2 invocations), b (stop fires → RetryException, flag false), c/d/e (non-matching predicates → ExecutionException(IE), flag false), f (fixedWait → RETURNED ok, flag false); JDK 11 = JDK 21 | D-5 |
| H2.2 Interrupt pending when an attempt starts (fixed) | Probe (CA) | `IntProbe2` (300 trials): JDK 21 290× returned ok/flag false/attempt 1 cancelled before start, 10× work repeated; `retryIfRuntimeException` 298× ExecutionException(IE) with 0 invocations. JDK 11: 298/2 and 296/4. JDK 8 checks the interrupt before completion (`FutureTask.java:402`), so it discards even already-finished tasks more often (source only) | D-5 |
| H2.3 noTimeLimit, interruptible callable throws IE | Probe (CA) | `IntProbe` H2.3a-d; `IntProbe2` H2.2n2 | D-6 |
| H2.4 Interrupt during listeners / predicate / stop / wait computation | Refuted (correct) | `IntProbe2` H2.4a-d: RetryException with flag true; `sleep(0)` throws when flagged (JDK 8/11/21 `JVM_Sleep`) | — |
| H2.5 Interrupt during sleep | Refuted (correct) | `IntProbe` H2.5/H2.5b | — |
| H2.6 Negative sleep with a pending interrupt | Probe (CA) | `IntProbe2` H2.6b: IAE escapes, flag stays true (sign check precedes interrupt check) | part of D-16 |
| H2.7 `wrap()` task cancelled / `shutdownNow` keeps retrying | Probe (CA) | `IntProbe3` (4 → 11 invocations within 2 s; executor not terminated; control terminates), `WrapCancelZombie2` (2 → 12 attempts, with and without limiter) | D-7 |
| H2.8 Caller interrupt while the attempt ignores interrupts | Probe (CA) | `IntProbe4`: overlap via interrupt (second trigger of D-1) | D-1 |
| H2.9 Worker-side IE while the caller is not interrupted | Not a defect (callable failure); modeling note: keep it distinct from caller-side IE | Code: `SimpleTimeLimiter.java:162-163,251-268` | — |
| Successful attempt returns with the flag still set | Not a defect (flag preserved; Javadoc wording only) | `IntProbe2` H2.4c | — |

**Interrupt matrix** (arrival point × limiter × predicate matches IE × stop → outcome | flag at exit | extra attempts):

| # | Arrival | Limiter | Matches IE | Stop | Outcome | Flag | Extra attempts |
|---|---|---|---|---|---|---|---|
| 1 | during attempt (caller parked in `get`) | fixed | yes | no | keeps retrying, may return a result | **false** | ≥ 1 (unbounded with neverStop) |
| 2 | during attempt | fixed | yes | fires | `RetryException(cause IE)` | **false** | 0 |
| 3 | during attempt | fixed | no | — | `ExecutionException(IE)`; callable did not throw | **false** | 0 |
| 4 | during attempt, interruptible callable | none | yes / no | — | as rows 1–3 | **false** | as rows 1–3 |
| 5 | during attempt, callable ignores interrupts | none | any | any | accepted → result; rejected → `RetryException` | true | 0 (correct) |
| 6 | pending at attempt start | fixed | yes / no | — | almost always rows 1–3, often with 0 invocations; rarely a correct return | **false** | as rows 1–3; work sometimes repeated |
| 7 | pending at attempt start | none | — | — | interruptible callable → row 4; otherwise row 5 | — | — |
| 8 | listeners / predicate / stop / wait computation | any | — | no | `sleep(≥0)` throws → `RetryException` | true | 0 (correct) |
| 9 | same | any | — | fires | `RetryException` | true | 0 (correct) |
| 10 | same, attempt accepted | any | — | — | returns result (or `ExecutionException`) | true | 0 (acceptable) |
| 11 | during sleep | any | — | — | `RetryException` | true | 0 (correct) |
| 12 | before sleep, sleep < 0 | any | — | — | `IllegalArgumentException` escapes | true | 0 (D-16) |
| 13 | `wrap()` + `cancel(true)` / `shutdownNow` during an attempt | any | yes | no | cancelled task retries forever; executor never terminates | **false** | unbounded (D-7) |
| 14 | during attempt, callable ignores interrupts | fixed | yes | — | as row 1, and the cancelled attempt keeps running (D-1) | **false** | ≥ 1 |

### 4.3 Builder handoff and sharing (D3)

| Hypothesis | Verdict | Evidence | Ledger |
|---|---|---|---|
| H3.1 Builder modified after `build()` while a built Retryer iterates → CME after the attempt executed | Probe (CA) | `SharedListenerCME` (latch-ordered, legal SC schedule): CME at `Retryer.java:166`, side effects 1, predicate 0, stop 0 (JDK 11 and 21; `failing` mode: the IOException is not retried). `RacyListenerStressLogging`: 9,369/9,406 modifications caused CME; with a trivially inlinable listener only 2–26 per run (JIT keeps stale size/modCount). NPE/stale slot permitted by the JMM, not observed in ~620k racing calls | D-8 |
| H3.2 Known vs new | #48 reports only single-threaded aliasing; the concurrent CME / lost outcome is not reported anywhere | `threads/issue-48.txt`, #36, #47, #13, PR #43 | D-8 known field |
| #48 in flight | Probe (CA), known | `ListenerSetDrift` (a listener added during the sleep notified twice by the running call) | D-9 |
| H3.3 Builder violates the Retryer's own thread-safety precondition; the `@Beta` constructor stores the caller's collection | Code | `RetryerBuilder.java:196` → `Retryer.java:137`; for direct constructor users the Javadoc puts this on the caller | second site of D-8 |
| H3.4 Other shared mutable state after `build()` | Refuted | `Predicates.or` builds a new `OrPredicate` over a fresh `Arrays.asList` each time (Guava `Predicates.java:153-155,415-420`); strategies set-once and immutable; `join` copies varargs (`WaitStrategies.java:227`); Retryer fields final | — |
| H3.5 Shared mutable state in built-ins when one Retryer is shared | Refuted except the limiter's executor | static `Random` is thread-safe; singletons stateless; `RetryerCallable` non-final fields safely published by executor submission | executor part → D-4 |
| H3.6 Duplicate listener notified twice; listener exceptions escape; builder used concurrently | By design / user code / builder misuse | — | — |

### 4.4 Strategies and `call()` outcomes (D4)

| Hypothesis | Verdict | Evidence | Ledger |
|---|---|---|---|
| H4.1 `join` overflow → negative sleep → IAE escapes | Probe (CA) | `EscapeProbe` (a), (d), (e); attempt 1 overflow with `fixedWait(Long.MAX_VALUE, …)` or a saturating `toMillis`; growth-only overflow (`join(exponentialWait(), fixedWait(1ms))` at n=63) unreachable in real time | D-16 |
| H4.2 `exceptionWait` passes negative and null through | Probe (CA) | `EscapeProbe` (b), (c); Guava 22 `Function.apply` is `@Nullable` (`Function.java:47-49`), and the `exceptionWait` Javadoc forbids neither, so a well-behaved user function can trigger both | D-17, D-18 |
| H4.3 `RandomWaitStrategy` `Math.abs(Long.MIN_VALUE)` | Refuted (unreachable) | `RandomMinValue`: only hi=0x80000000, lo=0 gives MIN_VALUE; 0 of 65,536 candidate LCG states is followed by `next(32)=0`; with interleaved draws on the shared Random the first qualifying gap is 201,243 calls (`RandomMinValueInterleaved`) | — |
| H4.4 IncrementingWait overflow | Probe (CA), extreme parameters | `IncProbe`: 1000, 0, 998, 0, 996, 0 for an increment of `Long.MAX_VALUE` ms; realistic increments overflow only after ~2.1e9 attempts | D-20 |
| H4.5 Fibonacci positive wrap below the cap | Probe (CA), unreachable through real sleeping | `FibScan`: `fibonacciWait()` n=94 → 1,293,530,146,158,671,551; all realistic capped settings clean to n=1e8 (cap reached at n=5–25) | D-21 |
| H4.6 Exponential arithmetic | Refuted (correct) | monotone and capped (n ≤ 5000 uncapped; README example to 1e8) | — |
| H4.7 `int` attempt counter wraps | Probe (CA) | `WrapProbe`: 4,439,235,284 runs → `getNumberOfFailedAttempts()` 144,267,988; listener saw −2147483648 after 2147483647; `RateProbe`: 6.1e5 attempts/s with defaults (~59 min), 3.4e7/s if 0-ms sleeps are skipped (~63 s); `stopAfterAttempt(int)` always fires before the wrap | D-19 |
| H4.8 Sub-millisecond truncation | Probe (CA), weak | `StrategyMath`: `stopAfterDelay(500 µs)` stops after attempt 1; `fixedWait(999 µs)` = 0; `randomWait(500 µs)` and `exponentialWait(1 ms)` fail at construction (IAE) | D-22 (stop only; the waits are documented ms resolution) |
| H4.9 All `call()` exits | — | brief § 1.1/§ 1.3; documented: return, `ExecutionException`, `RetryException` (stop or sleep interrupt); undocumented from built-ins: IAE (D-16, D-17), NPE (D-18), CME/NPE (D-8); documented type but non-callable cause: D-5, D-10, D-11, D-13, D-14, D-15 | — |
| H4.10 `RetryException` count/cause; stop boundaries; delay measurement | Refuted (correct) except the wrap | count = attempt number on both exits (`:174`, `:181`); cause = attempt throwable or null; `stopAfterAttempt(3)` stops at 3; `stopAfterDelay` uses `>=` vs "exceeded" (trivial); overshoot by one sleep + one attempt is the documented mechanism | — |

### 4.5 Cross-reference

- **D-1 has two triggers**: timeouts (`P1`) and caller interrupts (`IntProbe4`); both go through `cancel` without join. **D-4 is amplified by D-1**: zombies are what fill bounded pools. **D-7 is the executor-level consequence of D-5/D-6**: the same catch-all, observed through `wrap()`.
- **Interrupt × arithmetic**: when a negative sleep (D-16/D-17) meets a pending interrupt, the IAE wins and the documented `RetryException` + flag is not produced (`IntProbe2` H2.6b).
- **PR #101 × Scenario 2**: skipping `sleep(0)` would remove the only interrupt check under `noWait`; any fix for D-5/D-6 should not rely on the sleep.
- **Guava ≥ 23 patches × Scenario 4**: moving to the three-argument `callWithTimeout` (PR #95, PR #103, several forks) changes the attempt shapes: timeouts become checked `TimeoutException` (no longer matched by `retryIfRuntimeException()`), callable failures arrive wrapped (no longer matched by `retryIfExceptionOfType(IOException)`). The model should treat the classification step as a parameter, not hard-code today's types beyond what 2.0.0 does.
- **D-8 × D-1**: listeners run on the caller while zombie bodies may still run on workers; a listener that "swaps the connection" (issue #60's pattern) races with a zombie attempt.

### 4.6 Verification record per ledger row

Every row was checked against the deep-analysis checklist: (1) re-read of the cited lines in the 2.0.0 checkout and in Guava 22.0 / JDK sources; (2) compensating mechanisms — none found: no join or tracking of cancelled tasks, no interrupt restore outside `:180`, no defensive copy of listeners, no validation of computed sleeps, no `long` counter; TPE's interrupt clearing was found and is why the leak hypothesis H1.9 was refuted; Guava's own documentation was checked for D-4 (bounded-executor caveat noted in the row); (3) full execution path — traced from `call()` entry through the limiter, worker and decision steps, and confirmed by probes on the unmodified library; (4) design intent — Javadoc C1–C9, README, maintainer comments (#29, #35, #13, #18) and commit messages; none describes the observed behavior as intended; (5) real-world impact — triggers use public API with ordinary configurations (`retryIfException()`, `fixedTimeLimit`, `wrap()` on an executor, builder reuse), except D-20/D-21/D-22, which are flagged as extreme-parameter or weak.

## 5. Exclusions and refuted candidates

| Candidate | Decision | Reason |
|---|---|---|
| RandomWait negative sleep via `Math.abs(Long.MIN_VALUE)` | Refuted | Unreachable (exhaustive LCG check, § 4.4) |
| Exponential wait overflow/decrease | Refuted | `Math.round` saturates; monotone and capped |
| `stopAfterAttempt` early/late stop | Refuted | Stops exactly at N; fires before the counter could wrap |
| `stopAfterDelay` overshoot | By design | Documented check-after-attempt mechanism |
| `RetryException` cause/count on the two exits | Refuted | Correct until the wrap (D-19) |
| Cancellation interrupt leaking into the next attempt | Refuted (TPE) / environment (custom executors) | `runWorker` clears stale interrupts |
| ForkJoinPool, direct executor, CallerRunsPolicy | Environment | JDK executor semantics chosen by the user |
| JMM-level NPE in the listener loop | Note only | Permitted, not observed; TLA+/JPF are SC |
| `RetryerCallable` non-final fields | Refuted | Safe publication through executor submission |
| Interrupt during listeners/predicate/stop/wait or during sleep | Refuted (correct) | Flag preserved or restored; `RetryException` thrown |
| Returning a result with the flag set | Not a defect | Status preserved; only Javadoc wording |
| Worker-side `InterruptedException` with the caller not interrupted | Not a defect | Genuine callable failure |
| User listeners/predicates/strategies throwing; swallowing `BlockStrategy` | Out of scope | Guidance assumption: user code honors its interface |
| Null callable | Out of scope | Caller misuse |
| Guava ≥ 23 incompatibility (#94, #96) and all build/packaging issues | Out of scope | Guidance exclusion |
| `%d` formatting (#97), Javadoc exception types, ms documentation (#93), 2×multiplier first wait (#86), naming (#47), checked exception (#2), `withAttemptTimeLimiter` not set-once | Out of scope | Message formatting / docs / API ergonomics |
| ThreadLocal context lost under a limiter (#72) | Out of scope | API semantics |
| O(n) `fib()`; two threads per timed attempt (#18) | Not recorded | Performance only in reachable ranges |
| `RetryException` thrown for a sleep interrupt carries the previous attempt's cause and a "failed after N attempts" message | Not recorded | Documented behavior; the interrupt is signaled by the flag |

## 6. Evidence index

All probe sources and logs are under `analysis-evidence/probes/` (copied from the scratch probe directories; class files omitted). Build: `analysis-evidence/build/pom.xml`; classpath for probes = `target/classes` + `guava-22.0.jar` + `jsr305-2.0.2.jar`.

| Ledger row | Probe(s) | Log(s) |
|---|---|---|
| D-1 | `timelimit/P1Overlap.java`, `interrupt/IntProbe4.java` | `timelimit/p1.jdk21.log`, `p1.jdk11.log`; `interrupt/IntProbe4_.jdk{11,21}.log` |
| D-2 | `timelimit/P2Race.java` (args: 20000 1000 300) | `timelimit/p2.jdk21.log`, `p2.jdk11.log` |
| D-3 | `timelimit/P3ThreadGrowth.java`; `issue-repro/Demo92.java` (#92) | `timelimit/p3.noexit.log`, `p3.exit.log`; `issue-repro/demo92-g19.out` |
| D-4 | `timelimit/P4Executors.java`, `sharing/SharedLimiterStarvation.java`, `sharing/WrapSameExecutor.java` | `timelimit/p4.jdk{21,11}.log`; `sharing/SharedLimiterStarvation_.jdk21.log`, `WrapSameExecutor_.jdk21.log` |
| D-5 | `interrupt/IntProbe.java` (H2.1), `interrupt/IntProbe2.java` (H2.2) | `interrupt/IntProbe_.jdk{11,21}.log`, `IntProbe2_.jdk{11,21}.log` |
| D-6 | `interrupt/IntProbe.java` (H2.3), `IntProbe2.java` (H2.2n2) | same |
| D-7 | `interrupt/IntProbe3.java`, `sharing/WrapCancelZombie2.java` (args: none/limiter cancel/shutdownNow) | `interrupt/IntProbe3_.jdk{11,21}.log`, `sharing/WrapCancelZombie2.jdk21.log` |
| D-8 | `sharing/SharedListenerCME.java` (optional arg `failing`), `sharing/RacyListenerStress*.java` | `sharing/SharedListenerCME_.jdk{11,21}.log`, `SharedListenerCME_failing.jdk21.log` |
| D-9 | `sharing/ListenerSetDrift.java` | `sharing/ListenerSetDrift_.jdk21.log` |
| D-10 | `timelimit/P4Executors.java`, `strategies/OutcomeProbe.java` (case 7) | `timelimit/p4.jdk21.log`, `strategies/OutcomeProbe_.jdk21.log` |
| D-11 | `timelimit/P5Duration.java`, `OutcomeProbe` (5-6) | `timelimit/p5-9.log`, `OutcomeProbe_.jdk21.log` |
| D-12 | `timelimit/P6StackGrowth.java` | `timelimit/p5-9.log` |
| D-13 | `timelimit/P7Weird.java`, `OutcomeProbe` (3-4) | `timelimit/p5-9.log`, `OutcomeProbe_.jdk21.log` |
| D-14 | `timelimit/P8Issue29.java`, `OutcomeProbe` (8) | `timelimit/p5-9.log`, `OutcomeProbe_.jdk21.log` |
| D-15 | `OutcomeProbe` (1-2), `issue-repro/IssueRepro.java` (i67) | `OutcomeProbe_.jdk21.log` |
| D-16 | `strategies/EscapeProbe.java` (a, d, e), `interrupt/IntProbe2.java` (H2.6) | `strategies/EscapeProbe_.jdk21.log`, `interrupt/IntProbe2_.jdk{11,21}.log` |
| D-17, D-18 | `strategies/EscapeProbe.java` (b, c) | `strategies/EscapeProbe_.jdk21.log` |
| D-19 | `strategies/WrapProbe.java` (arg: seconds), `strategies/RateProbe.java`, `archaeology-repro/AttemptOverflow.java` | figures quoted from the D4 subagent run (150 s); not re-run here |
| D-20 | `strategies/IncProbe.java` | `strategies/IncProbe_.jdk21.log` |
| D-21 | `strategies/FibScan.java` | figures quoted from the D4 subagent run |
| D-22 | `strategies/StrategyMath.java` | `strategies/StrategyMath_.jdk21.log` |
| D-23 | `main/SerProbe.java` | `main/SerProbe_.jdk21.log` |
| Refuted H4.3 | `strategies/RandomMinValue.java`, `RandomMinValueInterleaved.java` | `strategies/RandomMinValue_.jdk21.log` |
| Refuted H1.9 | `timelimit/P9InterruptLeak.java` | `timelimit/p9.log` |
| #101 regression | `archaeology-repro/ArchRepro.java` (T4) | figures quoted from the PR subagent run |

## 7. Limitations and notes for later phases

- **D-2 is statistical in tests** (~0.4 % with a deliberately tight 1 ms limit and completions clustered at the deadline); TLA+ interleavings or JPF's nondeterministic `parkNanos` timeouts are the systematic way to reach it.
- **JDK 8** behavior (interrupt checked before completion in `FutureTask.awaitDone`) is from source only; the probes ran on JDK 11 and 21, where completion is checked first. The model can carry this as a constant.
- **D-19 timings** are machine-specific (6.1e5 attempts/s with the builder defaults here).
- **JPF**: needs JDK 11; the local jpf-core branch carries `FutureTask` VarHandle and `reachabilityFence` fixes; its spurious-wakeup policy does not cover `LockSupport.park`. Recording `FutureTask.state` via field reads in `methodExited` hooks captures CAS outcomes without touching library code.
- **Raw archaeology data** (issue/PR JSON and text dumps, fork comparison `cmp.tsv`) remains in `/home/ubuntu/scratch/guava-retrying-archaeology/` and `/home/ubuntu/scratch/guava-retrying-archaeology-forkscan/`.
