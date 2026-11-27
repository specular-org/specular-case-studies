# MC-4 — Phase 1 investigation (evidence only)

Finding: a caller interrupt during a `fixedTimeLimit` attempt is consumed by `Future.get`, turned into an ordinary failed attempt by the catch-all in `Retryer.call`, and the interrupt status is never restored. Source: model checking (invariant `InterruptPreserved`, cfg `MC_hunt_s2_interrupt_fixed.cfg`).

Source under test: worktree `confirmation/MC-4/worktree`, HEAD `177b6c9` (upstream `rholder/guava-retrying` master; 2.0.0 + a Travis workaround). Guava 22.0 binary `~/.m2/.../guava-22.0.jar` (sha1 `3564ef3803de51fb0530a8377ec6100b33b0d073`, matches the `.sha1` published alongside it); Guava sources from `/home/ubuntu/scratch/guava22-sources-dl/guava-22.0-sources.jar` (extracted). JDK sources: `/home/ubuntu/scratch/jdk-src/{11,21}/java/util/concurrent/FutureTask.java`.

## Step 1 — Code audit

### Cited code, read in context

- `Retryer.java:155-185` `call()`:
  - `:160` `V result = attemptTimeLimiter.call(callable);`
  - `:162-163` `catch (Throwable t) { attempt = new ExceptionAttempt<V>(t, ...) }` — every `Throwable`, including `InterruptedException`, becomes an ordinary failed attempt. No `Thread.currentThread().interrupt()` here.
  - `:166-168` listeners; `:170-172` `if (!rejectionPredicate.apply(attempt)) return attempt.get();` — `attempt.get()` throws `ExecutionException(cause)` for an `ExceptionAttempt` (`:260-262`).
  - `:173-174` `if (stopStrategy.shouldStop(attempt)) throw new RetryException(attemptNumber, attempt);` — no interrupt restore.
  - `:176-182` the only interrupt handling: `blockStrategy.block(sleepTime)`; `catch (InterruptedException e) { Thread.currentThread().interrupt(); throw new RetryException(...) }`.
- `AttemptTimeLimiters.java:105-108` `FixedAttemptTimeLimit.call` → `timeLimiter.callWithTimeout(callable, duration, timeUnit, true)` (`amInterruptible = true`). Both `fixedTimeLimit` factories (`:57-60`, `:69-72`) build this class around a Guava `SimpleTimeLimiter` (default: `Executors.newCachedThreadPool()`, `SimpleTimeLimiter.java:82-84`).
- Guava 22.0 `SimpleTimeLimiter.java:142-168` `callWithTimeout(callable, d, unit, amInterruptible)`:
  - `:149` `Future<T> future = executor.submit(callable);` — the callable runs on a pool worker, not on the caller thread.
  - `:152-158` `if (amInterruptible) { try { return future.get(timeoutDuration, timeoutUnit); } catch (InterruptedException e) { future.cancel(true); throw e; } }` — on a caller interrupt the attempt is cancelled and the `InterruptedException` rethrown. The return value of `cancel` is not checked, so an attempt that completed between the interrupt check and `cancel` is still discarded.
- JDK `FutureTask.awaitDone` (`get` with timeout): JDK 11 `FutureTask.java:416-418`, JDK 21 `FutureTask.java:469-471`: `else if (Thread.interrupted()) { removeWaiter(q); throw new InterruptedException(); }` — `Thread.interrupted()` **clears** the caller's interrupt status before throwing. (`s == COMPLETING` → `Thread.yield()` at 11:`:412-415` / 21:`:465-468`; only a task already done is returned despite an interrupt.)
- Contract text: `Retryer.java:151-153` "@throws RetryException if all the attempts failed before the stop strategy decided to abort, or the thread was interrupted. Note that if the thread is interrupted, this exception is thrown and the thread's interrupt status is set." and the constructor docs `:59-61` (also `:76-78`, `:94-96`, `:113-115`): "If an attempt is rejected, the retryer will retry the call, unless the stop strategy indicates otherwise or the thread is interrupted." `AttemptTimeLimiter.java:22`: a timed-out attempt "will possibly be interrupted if the limit is exceeded" (about the worker, not the caller).

### Call chain (public API → cited code)

User code → `RetryerBuilder.newBuilder()...withAttemptTimeLimiter(AttemptTimeLimiters.fixedTimeLimit(d, unit[, executor])).build()` → `Retryer.call(callable)` (or `Retryer.wrap(callable)` → `RetryerCallable.call()` `Retryer.java:317-319`, which is designed to be submitted to an `ExecutorService`) → `Retryer.java:160` → `AttemptTimeLimiters.java:107` → `SimpleTimeLimiter.java:149,154` → `FutureTask.get(timeout)` → `awaitDone` clears the interrupt, throws `InterruptedException` → `SimpleTimeLimiter.java:155-157` cancels and rethrows → `Retryer.java:162-163` records an `ExceptionAttempt(InterruptedException)` → predicate / stop / wait / block as for any failure.

Reachable in normal use: `fixedTimeLimit` is a documented public factory; interrupting a thread that runs `call()` is the standard Java cancellation mechanism (`Thread.interrupt`, `Future.cancel(true)`, `ExecutorService.shutdownNow()`), and the Javadoc explicitly specifies the interrupted-thread behaviour. While a time-limited attempt is in flight the caller thread spends essentially all its time parked inside `future.get`, so an interrupt that arrives during an attempt lands exactly there.

### Trigger scenarios (one per exit the finding claims)

1. **Normal return, status clear** (bfs5; retry itself = bfs3): `retryIfException()` (stop: default never, wait: default none). Thread T is in attempt 1 (callable running on the pool); another thread interrupts T. `Future.get` clears the status and throws IE → attempt 1 = `ExceptionAttempt(IE)` → rejected → `Thread.sleep(0)` does not throw (status already clear) → attempt 2 runs and succeeds → `call()` returns normally; `Thread.currentThread().isInterrupted()` is false.
2. **`ExecutionException(InterruptedException)`, status clear, callable never ran** (narrow_bfs1; attempt counted with 0 invocations = bfs1): `retryIfExceptionOfType(IOException.class)`. T already has its interrupt status set when it enters `call()` (or is interrupted during attempt 1). `submit` succeeds, `get` throws IE immediately; `cancel(true)` wins against the not-yet-started task, so the callable is never invoked; the predicate does not reject IE → `attempt.get()` throws `ExecutionException(IE)`; status clear. A listener sees attempt #1 although the callable ran 0 times.
3. **`RetryException`, status clear** (ledger D-5 exit, same path, not a cited trace): `retryIfException()` + `stopAfterAttempt(1)`: interrupted attempt is rejected, the stop strategy fires at `:173-174`, `RetryException` is thrown without restoring the status.
4. **Discarded finished attempt** (bfs2): the attempt's task completes (FutureTask CAS to COMPLETING/NORMAL) after the caller read state NEW but before `cancel(true)`; `cancel` returns false, Guava still rethrows IE, and the completed outcome is discarded; with `retryIfException()` the work is repeated.

### Safeguards encountered (recorded, not judged)

- `Retryer.java:179-181` restores the status and throws `RetryException` — but only if the interrupt is still pending when `blockStrategy.block` runs; the consumed interrupt is already cleared, so `Thread.sleep` does not throw. Not a guard on this path.
- `FutureTask.awaitDone` returns a value when the task is already done (`s > COMPLETING`) even if interrupted; in that case the interrupt status is left set. Only protects interrupts that arrive after the attempt's completion is published.
- A second, later interrupt that happens to land during `blockStrategy.block` would be honoured (`:179-181`). Callers interrupt once (`shutdownNow`, `cancel(true)`), so this does not restore the lost interrupt.
- No other code in `Retryer`, the builder, or the strategies inspects or restores the interrupt status.

## Step 2 — Developer-knowledge search

- **Contract**: `Retryer.java:151-153` and `:59-61` quoted above — the developers explicitly promise that an interrupted thread gets a `RetryException` with its interrupt status set, and that retrying stops when the thread is interrupted.
- **Tests**: `RetryerBuilderTest.java:384-414` `testInterruption`: interrupts the thread running `call()` (noTimeLimit, `fixedWait(1000ms)`, `retryIfResult(isNull)`) and asserts `RetryException` plus `assertTrue(Thread.currentThread().isInterrupted())` (`:401`). No test covers an interrupt with `fixedTimeLimit`; `AttemptTimeLimiterTest.java` only checks timeout → `ExecutionException(UncheckedTimeoutException)`.
- **History / blame**: the catch-all dates from `6d2d838` (2012) / `fbe3177` (2013); the interrupt restore at `:179-181` from `6d2d838`. `7e474be` (2013-01-16, upstream PR #1 "added a per attempt time limit") replaced `callable.call()` with `attemptTimeLimiter.call(callable)`, introducing the library's own interruptible `Future.get` on the caller thread without changing the catch-all or the interrupt handling. No commit message mentions interrupts. No TODO/FIXME near the site. Guava's own `// TODO: should this actually throw only ExecutionException?` above `callWithTimeout` (`SimpleTimeLimiter.java:138`) is about Guava's exception types, not this behaviour.
- **Issue tracker** (fetched all 106 upstream issues/PRs, state=all, incl. closed/merged PRs up to #107 closed 2026-09, and all 185 issue comments; saved in `notes/upstream-issues-all.jsonl`, `notes/upstream-comments-all.jsonl`; GitHub search for `interrupt`, `InterruptedException`, `interrupted`, `interruption`, `timelimit`, "time limit", `fixedTimeLimit`, `cancel`, `SimpleTimeLimiter`, `timeout` before the search API rate-limited): no issue, PR, or comment reports a consumed/lost caller interrupt or retrying after an interrupt. Related but different: #63 (custom `BlockStrategy` that does not sleep), #29 (timeout aborted retrying in 1.0.6), #92 (process exit delay with `fixedTimeLimit`), #67 (catch-all at `Retryer.java:162` catches `Error`s such as OOME — same line, different exception class and consequence), #94 (Guava ≥ 23 incompatibility). Upstream master's newest commit is `177b6c9` (2016-05-10) = worktree HEAD, so nothing was fixed upstream.
- **Specular persistent findings**: `specular findings --work .specular-output lookup --query InterruptPreserved --query Retryer.call --query fixedTimeLimit --query SimpleTimeLimiter --query InterruptedException` → `[]` (context `previous: null`, no inherited records). `Specular/case-studies` contains no guava-retrying entry.

## Step 3 — Known-status

No existing issue / PR / advisory / dataset entry reports this mechanism at this site. Source is MC with actual counterexamples (`spec/output/hunt_s2_interrupt_fixed_bfs5.out` — `InterruptPreserved`, 25 states; `hunt_s2_interrupt_fixed_bfs3.out` — `NoRetryAfterObservedInterrupt`; `hunt_s2_interrupt_narrow_bfs1.out` — `ExecutionExceptionMeansCallableThrew`; `hunt_s2_interrupt_fixed_bfs1.out` — `CountedImpliesInvoked`; `hunt_s2_interrupt_fixed_bfs2.out` — `NoDiscardedCompletion`). Not eligible for the code-review × known drop → proceed to Phase 2.

### Counterexample summary (bfs5, the cited trace)

`MCCallStart(c1)` → `MCSubmitNewWorker(c1,t1,w1)` → `MCInterrupt(c1)` (cpc=Wait, intr[c1]=TRUE) → `MCGetInterrupted(c1)` (intr[c1]=FALSE, tag CallerIE) → `MCCancelCASWon/ReadRunner/Finish` (t1 NEW→INTERRUPTING→INTERRUPTED, body NotStarted) → listeners → `MCWaitStrategyComputes(c1,"Zero")` → `MCBlockZero(c1)` (no throw) → `MCSubmitNewWorker(c1,t2,w2)` → t2 body returns → `MCGetReturn(c1)` → listeners → `MCPredicateAccepts(c1)`: outcome Returned, intr[c1]=FALSE, intrDelivered=TRUE.
narrow_bfs1: `MCInterrupt(c1)` before `MCCallStart(c1)` → submit → `MCGetInterrupted` → cancel wins (t1 NotStarted) → listeners → `MCPredicateAccepts` → outcome ExecExc, invoked FALSE, intr FALSE.
bfs2: t1 body throws, `MCSetCASWon(w1)` (t1 COMPLETING), then `MCInterrupt(c1)` → `MCGetInterrupted(c1)` → `MCSetFinish(w1)` (t1 EXCEPTIONAL) while the caller holds CallerIE.

## Repair round 1 continuation (2026-11-26, after RR-001)

Inputs: the finding summary as updated by repair round 1. RR-001 narrowed `NoDiscardedCompletion` to the interrupt path; the timeout-path counterpart (former MC-3) was withdrawn as the documented timeout outcome. New current-violation traces: `spec/output/repair-r1/repair1_ctl_s2_wrap_cancel_ndc.out`, `repair1_ctl_sharing_ndc.out`, `repair1_ctl_sharing_cir.out` (TLC 12:32). Everything above is preserved; corrections and precisions are listed below.

### Premises re-checked

- Source unchanged: worktree HEAD `177b6c9`, 0 dirty files. `Retryer.java`, `AttemptTimeLimiters.java`, `RetryerBuilder.java`, `BlockStrategies.java` are byte-identical to the source root `/home/ubuntu/scratch/guava-retrying-src/guava-retrying` (sha256 prefixes `62e792c4`, `b98b9da0`, `a6de5ad2`, `e230771f`). Guava 22.0 sha1 `3564ef38…` and JDKs 21.0.13.1 / 11.0.33.1 unchanged. Line cites re-verified: `Retryer.java:59-61,151-153,160,162,178,180,195-196,317-318`, `AttemptTimeLimiters.java:69-72,107`.
- The pre-repair traces (`hunt_s2_interrupt_*`, written 08:05–08:15) were not regenerated. Every one this finding cites is an interrupt-path trace: bfs1 (`CountedImpliesInvoked`, `MCInterrupt` before `MCCallStart`, `mc.timeout = 0` throughout), bfs2 (`NoDiscardedCompletion`, `MCInterrupt` at state 9, `mc.timeout = 0`), bfs3, bfs5 and narrow_bfs1. RR-001's narrowing therefore withdraws none of them. Scenario F of the base repro is interrupt-path too: the limit is 10 s and attempt 1 completes about 300 µs after it starts, so no timeout fires. Its discards stay valid evidence under the narrowed invariant.

### Repair-r1 traces

- `repair1_ctl_s2_wrap_cancel_ndc.out` (`NoDiscardedCompletion`, 11 states):
  - Steps: `MCCallStart(c1)` → `MCSubmitNewWorker(c1,t1,w1)` → w1 runs t1 and the body throws (`MCBodyStart(w1,"Exc")`, `MCBodyThrows`) → `MCSetCASWon(w1)` (t1 COMPLETING) → `MCCancelOuter(c1)` → `MCSetFinish(w1)` (t1 EXCEPTIONAL) → `MCGetInterrupted(c1)` (CallerIE, intr[c1] FALSE).
  - `MCCancelOuter(c1)` sets `outerState` to CANCELLED and intr[c1] to TRUE. In the real code this is `Future.cancel(true)` on the Future of an executor task that runs `retryer.wrap(callable)` (`Retryer.java:195-196`, `:317-318`); JDK `FutureTask.cancel(true)` interrupts the task's runner thread.
  - New element vs. bfs2: the interrupt comes from the outer Future's `cancel(true)` instead of `Thread.interrupt`. The library path is the same.
- `repair1_ctl_sharing_ndc.out` (`NoDiscardedCompletion`, 11 states, callers c1 and c2):
  - c2 stays `Idle` in every state.
  - c1: submit t1 → `MCInterrupt(c1)` → `MCGetInterrupted(c1)` while t1 is still NEW (CallerIE, status cleared) → w1 then starts t1 and runs it to NORMAL (`MCBodyReturns`, `MCSetCASWon`, `MCSetFinish`) before c1's `cancel(true)`.
  - This is the interleaving that F (base repro) and W2/S2 (this round) measure.
- `repair1_ctl_sharing_cir.out` (8 states, c2 stays `Idle`):
  - It violates `CountedImpliesInvokedNoStartRace`, the post-repair form of `CountedImpliesInvoked`.
  - c1: submit t1 → `MCInterrupt(c1)` → `MCGetInterrupted(c1)` → `MCCancelCASWon` / `MCCancelReadRunner` / `MCCancelFinish` (t1 NEW→INTERRUPTING→INTERRUPTED, body NotStarted) → `Classified`. The attempt is counted with 0 invocations.
  - Same as bfs1, except the interrupt lands after submit instead of before `call()`.
- **Precision on "with two callers"**: this adds no cross-caller mechanism. The second caller takes no step in either sharing trace, so both are single-caller interleavings inside a two-caller configuration. Phase 2 still exercises the shared configuration with c2 actively calling.
- **Admissibility note (not covered in the earlier bfs2 summary)**: in bfs2 and `wrap_cancel_ndc`, `MCGetInterrupted` fires after t1 has left NEW (COMPLETING or EXCEPTIONAL).
  - JDK `FutureTask.awaitDone` never throws `InterruptedException` once it has read `state >= COMPLETING` (JDK 21 source comment: "never return empty-handed or throw InterruptedException").
  - So these exact orders happen only when the caller read `state == NEW` before the worker's completion CAS, and then ran `Thread.interrupted()` after the interrupt — that is, the caller was preempted between those two statements. That is an admissible interleaving of the real code; the model's atomic `MCGetInterrupted` merges the read and the check into one step.
  - The wider real window is the sharing_ndc order: IE is thrown while t1 is NEW, and t1 completes before Guava's `future.cancel(true)`, whose `false` result is ignored (`SimpleTimeLimiter.java:155-157`).
  - Both orders violate the same invariant through the same code.

### Developer knowledge / known-status re-check

- Upstream re-check (2026-11-26): the most recently updated items are #84 (PR, closed unmerged 2026-09-20) and #107 (PR "Modernize", closed unmerged 2026-09-05). No PR has been merged since 2016; master is still `177b6c9`. **Correction:** the earlier note "up to #107 closed 2026-09" was imprecise, because #84 was closed later. Neither touches interrupts.
- Keyword grep over all 106 saved issues/PRs and 185 comments:
  - `interrupt`: only #63 (a custom BlockStrategy that does not sleep).
  - `cancel`, `shutdownNow`, `RetryerCallable`: no hits.
  - `wrap`: only incidental uses (#3, #7, #23, #29, #65 — a ListenableFuture retryer proposal, #67, #70, and two comments).
  - No item reports a swallowed caller interrupt, or a cancelled `wrap()` task that keeps retrying.
- `specular findings lookup --query InterruptPreserved --query NoDiscardedCompletion --query CountedImpliesInvokedNoStartRace --query RetryerCallable --query fixedTimeLimit` → `[]`.
- Known-status is unchanged: no prior report of this mechanism. The finding is MC-sourced with actual counterexamples, so it proceeds to Phase 2.
- Phase 2 this round:
  - New test `repro/test_bugMC-4_wrap_cancel_sharing.sh`, output in `confirmation/MC-4/repro-r1-run1.log`.
  - Regression run of the unchanged base repro, output in `confirmation/MC-4/repro-run3.log`.
