# MC-2 — Phase 1 investigation (evidence only)

Finding: a timed-out attempt whose callable never returns and ignores interruption pins a pool thread of the private cached pool created by the two-argument `AttemptTimeLimiters.fixedTimeLimit(d, unit)`; each further timed-out attempt takes another thread; the threads outlive `call()`.

Source checkout: `confirmation/MC-2/worktree` (guava-retrying 2.0.0, HEAD `177b6c9`), built against Guava 22.0.
Counterexamples: `spec/output/hunt_s1_overlap_d3b.out` (`StuckBodiesPerCallAtMostOne`, 20 states), `spec/output/hunt_s1_overlap_d3a.out` (`StuckBodiesEndWithCall`, 28 states), cfg `MC_hunt_s1_overlap.cfg`.
Persistent-findings lookup (`specular findings lookup --query SimpleTimeLimiter --query fixedTimeLimit --query StuckBodiesPerCallAtMostOne --query newCachedThreadPool`): `[]` (no prior record).

## Step 1 — Code audit

### Cited sites

- `src/main/java/com/github/rholder/retry/AttemptTimeLimiters.java:57-60` — `fixedTimeLimit(long duration, TimeUnit timeUnit)` returns `new FixedAttemptTimeLimit<V>(duration, timeUnit)`.
- `AttemptTimeLimiters.java:89-91` — `FixedAttemptTimeLimit(long, TimeUnit)` calls `this(new SimpleTimeLimiter(), duration, timeUnit)`.
- `AttemptTimeLimiters.java:85` — `private final TimeLimiter timeLimiter;` inside `private static final class FixedAttemptTimeLimit` (`:83`). No getter, no `close`/`shutdown`.
- `AttemptTimeLimiters.java:106-108` — `call()` = `timeLimiter.callWithTimeout(callable, duration, timeUnit, true)`.
- `AttemptTimeLimiter.java:27-34` — interface has only `V call(Callable<V>)`; no lifecycle method. `Retryer` has none either.
- Guava 22.0 `SimpleTimeLimiter.java:81-84` — `public SimpleTimeLimiter() { this(Executors.newCachedThreadPool()); }`; `:50` `private final ExecutorService executor;`.
- JDK `Executors.newCachedThreadPool()` = `new ThreadPoolExecutor(0, Integer.MAX_VALUE, 60L, SECONDS, new SynchronousQueue<>())` with `Executors.defaultThreadFactory()` (non-daemon threads named `pool-N-thread-M`). Unbounded; idle threads are reaped after 60 s; busy threads are never reaped.
- Guava `SimpleTimeLimiter.java:142-168` `callWithTimeout(callable, d, unit, amInterruptible=true)`: `:149` `executor.submit(callable)`; `:154` `future.get(d, unit)`; on `TimeoutException` `:165` `future.cancel(true)` then `:166` `throw new UncheckedTimeoutException(e)`. `cancel(true)` only sets the worker's interrupt flag; it cannot stop a body that does not respond to interrupts.
- `src/main/java/com/github/rholder/retry/Retryer.java:155-185` — `call()` loop: `:160` `attemptTimeLimiter.call(callable)`; `:162-164` `catch (Throwable t)` → `ExceptionAttempt`; `:170` predicate; `:173` stop; `:176-178` wait/block; next iteration submits again. Nothing tracks or waits for the abandoned previous attempt.

### Call chain (public API → cited code)

`RetryerBuilder.newBuilder().withAttemptTimeLimiter(AttemptTimeLimiters.fixedTimeLimit(d, unit))` (`RetryerBuilder.java:118-122`, `AttemptTimeLimiters.java:57-60`) → `new FixedAttemptTimeLimit` (`:89-91`) → `new SimpleTimeLimiter()` → private `newCachedThreadPool()` (Guava `:81-84`). `build()` (`RetryerBuilder.java:190-197`, default stop = `neverStop`, wait = `noWait`) → `Retryer.call` (`Retryer.java:155`) → `:160` → `AttemptTimeLimiters.java:107` → Guava `:149` submit (new pool thread if none idle) → `:154` timeout → `:165` `cancel(true)` (interrupt only) → `:166` `UncheckedTimeoutException` → `Retryer.java:163` `ExceptionAttempt` → predicate (`retryIfException()`/`retryIfRuntimeException()` reject it; default `alwaysFalse` does not, see #29) → stop/wait → `:160` again → Guava `:149` submit: the only pool thread is still busy in the old body, so `SynchronousQueue` hand-off fails and the cached pool starts a new thread.

Reachability: normal public-API usage. The 2-arg overload is the one the existing test uses (`src/test/java/com/github/rholder/retry/AttemptTimeLimiterTest.java:32-34`).

### Trigger scenario

1. A user wraps a remote call (the project's own description, `build.gradle:12`: "such as something that talks to a remote service with flaky uptime") in a `Retryer` built with `fixedTimeLimit(d, unit)` and `retryIfException()` / `retryIfRuntimeException()`.
2. The callable blocks in an operation that ignores `Thread.interrupt()` — e.g. a classic `java.net.Socket` read with no `SO_TIMEOUT` (the `HttpURLConnection` default read timeout is 0), a monitor (`synchronized`) wait, or code that swallows `InterruptedException`. The callable is arbitrary user code that may ignore interrupts and block indefinitely (target guidance, Assumptions).
3. The remote side accepts but never answers. Attempt 1 times out; `cancel(true)` interrupts `pool-1-thread-1`, which stays blocked.
4. Attempt 2 is submitted; the cached pool has no idle thread, so it creates `pool-1-thread-2`, which also blocks. This repeats once per attempt (unbounded under the default `neverStop`).
5. `call()` throws `RetryException` (or returns if a later attempt succeeds), leaving every stuck thread blocked. They are non-daemon and their pool is private, so nothing can shut them down; the JVM cannot exit while they are blocked.

Maps 1:1 to the CE: d3b states 2-11 (attempt 1 submit on new worker w1, `GetTimeout`, body `Stuck`, `CancelDoInterrupt` sets `intr[w1]`), 12-16 (listeners, `Zero` wait), 17-20 (`MCSubmitNewWorker(c1,t2,w2)`, second body `Stuck`) → `wpc = w1:Body, w2:Body`, `tmode = t1:Stuck, t2:Stuck`. d3a: same prefix, then attempt 2 returns (`MCBodyStart(w2,"Ret")` … `MCPredicateAccepts`) → `outcome = Returned`, `cpc = Done` while `wpc[w1] = Body`, `tbody[t1] = Running`.

### Safeguards recorded (Phase 2 must test whether they fire)

- `future.cancel(true)` interrupt (Guava `:165`): helps only interruptible bodies.
- Cached-pool keep-alive 60 s: reaps idle threads only.
- 3-arg overload `fixedTimeLimit(d, unit, executorService)` (`AttemptTimeLimiters.java:69-72`): lets a user supply a daemon/bounded executor; not available to 2-arg users, and a bounded executor starves later attempts (Guava note `:56-58`).
- Default rejection predicate `alwaysFalse`: without `retryIf*`, a timed-out call is not retried, so each `call()` leaks at most one thread — but repeated calls still accumulate.

## Step 2 — Developer-knowledge evidence (verbatim)

- `AttemptTimeLimiter.java:22`: "A rule to wrap any single attempt in a time limit, where it will possibly be interrupted if the limit is exceeded."
- `AttemptTimeLimiters.java:48-50`: "For control over thread management, it is preferable to offer an {@link ExecutorService} through the other factory method, {@link #fixedTimeLimit(long, TimeUnit, ExecutorService)}. See the note on {@link SimpleTimeLimiter#SimpleTimeLimiter(ExecutorService)}, which this AttemptTimeLimiter uses." (blame: `7e474be7` dirkraft 2013-01-16). The referenced Guava note (`SimpleTimeLimiter.java:56-58`) warns only that a *bounded* executor may make callers time out before the target runs.
- `AttemptTimeLimiters.java:52`: "@param duration that an attempt may persist before being circumvented".
- `Retryer.java:73,90,109`: "@param attemptTimeLimiter to prevent from any single attempt from spinning infinitely".
- `RetryerBuilder.java:113`: "Configures the retryer to limit the duration of any particular attempt by the given duration."
- `Retryer.java:32-35`: "A retryer, which executes a call, and retries it until it succeeds, or a stop strategy decides to stop retrying."
- Guava `SimpleTimeLimiter.java:38-40`: "If the time limit expires for a given method call, the thread running the call will be interrupted."
- PR #1 (dirkraft, merged 2013-01-16, https://github.com/rholder/guava-retrying/pull/1): "This provides a mechanism to limit any one single attempt from clobbering a Retryer."
- Issue #18 (open, https://github.com/rholder/guava-retrying/issues/18, feature request "Suggest to use HashedWheelTimer for timeout management"), maintainer rholder 2014-03-28: "The current implementation of an `AttemptTimeLimiter` using `SimpleTimeLimiter` can be fairly wasteful with respect to resources. This would make a great pull request."
- Issue #92 (open, no comments, https://github.com/rholder/guava-retrying/issues/92): demo with `fixedTimeLimit(5, SECONDS)` whose callable returns normally; "my process can not exit immediately" (the 60 s idle keep-alive of the private non-daemon pool).
- Issue #69 (open): "The default executor is **CachedThreadPool**, but it's not fit." — asks for other executors; no defect report.
- Git history: `AttemptTimeLimiters.java` unchanged since `a5a069f` (2015-01-20, copyright header) upstream; the 2-arg path is the original 2013 implementation (`7e474be`).
- Tests: `AttemptTimeLimiterTest.java:36-51` covers only an interruptible body (`Thread.sleep`) and asserts `ExecutionException(UncheckedTimeoutException)`. No test covers a body that ignores interrupts, thread counts, or JVM exit.

## Step 3 — Known-status / precedent

Searched (2026-11-26, read-only `gh api`): all 106 upstream issues/PRs (`state=all`); keyword searches "thread leak", "daemon", "interrupt", "SimpleTimeLimiter", "fixedTimeLimit", "newCachedThreadPool", "exit", "hang" (the "threads" query hit the search rate limit); recently closed PRs #107 "Modernize" (closed unmerged 2026-09-05; author: "This was supposed to go under my fork") and #84 (README, closed 2026-09-20); upstream commit history of `AttemptTimeLimiters.java`. Specular case-studies directory: empty. Persistent-findings registry: empty.

Result: no issue/PR reports a timed-out attempt that ignores interrupts pinning a pool thread permanently, one more thread per timed-out attempt, or a JVM that never exits because of it. Related but different: #92 (60 s exit delay after a normal run; same private non-daemon pool site, different trigger and a transient consequence), #18 (resource wastefulness as a feature request), #29 (timeouts not retried by default).

Pre-filter: MC-sourced with actual counterexamples (d3b, d3a) → not droppable; proceed to Phase 2.

## Repair round 1 — continuation (2026-11-26)

Prior disposition `REPRODUCED` (turn 1). This section only adds what changed; the Step 1–3 evidence above stands.

- Current counterexamples (current spec, `MC_hunt_s1_timelimit.cfg`): `spec/output/repair-r1/repair1_s1_timelimit_d3b.out` (`StuckBodiesPerCallAtMostOne`, 20 states) and `spec/output/repair-r1/repair1_s1_timelimit_d3a.out` (`StuckBodiesEndWithCall`, 28 states). Their `State N: <Action>` sequences are identical to `hunt_s1_overlap_d3b.out` / `hunt_s1_overlap_d3a.out` (`diff` empty), and their final states differ only in the printed field order of the `exitInfo` record. d3b final state: `wpc = w1:Body, w2:Body`, `tmode = t1:Stuck, t2:Stuck`, `tbody = t1:Running, t2:Running`, `intr[w1] = TRUE`, `tstate[t1] = INTERRUPTED`, `cpc[c1] = Wait`. d3a final state: `outcome[c1] = Returned`, `cpc[c1] = Done`, `wpc[w1] = Body`, `tbody[t1] = Running`, `tmode[t1] = Stuck`, `intr[w1] = TRUE`.
- Source: worktree HEAD `177b6c9`, 0 dirty files (unchanged). Re-checked cites: `AttemptTimeLimiters.java:57-60, 85, 89-91, 107`; `Retryer.java:155-185` (`:157` loop, `:160` submit via limiter, `:162-163` catch-all, `:171` `attempt.get()`, `:173-174` stop); Guava 22.0 `SimpleTimeLimiter.java:81-84` (`:83` `this(Executors.newCachedThreadPool())`), `:149`, `:154`, `:164-166`. Doc cites `Retryer.java:73/90/109`, `RetryerBuilder.java:113`, `AttemptTimeLimiter.java:22`, `AttemptTimeLimiterTest.java:36-51` unchanged.
- Upstream re-check: all 106 issues/PRs (newest activity still PR #84, 2026-09-20; nothing after the turn-1 search); full-text keyword scan (thread/daemon/leak/exit/hang/interrupt/cancel/TimeLimiter/pool/stuck) over every title and body and over all 185 issue comments and 5 review comments. No report of this mechanism. This closes the turn-1 gap where the `threads` search query hit the rate limit. Related items unchanged: #92, #18, #69, #29.
- Reproduction re-run on the unchanged script (sha256 `c1d30916…`): `repro/MC-2.r1.log`, exit 0, 9/9 checks `OBSERVED` (same as `MC-2.log` and `MC-2.run2.log`).
- Corrections to earlier statements: none disproved. Two clarifications: (1) the finding summary says the JVM-exit consequence is "by code inspection"; check C demonstrates it directly (JVM still alive 95 s after `main()` returned, three runs). (2) In check E the `OutOfMemoryError` reaches the caller wrapped in `ExecutionException` because `Retryer.java:162-163` catches every `Throwable` and `:171` rethrows it (known issue #67); that only fixes the exception type the caller sees — thread creation fails either way, so it does not mask MC-2.
