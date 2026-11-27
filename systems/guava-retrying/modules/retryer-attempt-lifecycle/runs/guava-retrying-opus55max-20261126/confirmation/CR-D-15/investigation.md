# CR-D-15 — Phase 1 investigation

Finding: `Retryer.call` 把 callable 抛出的 `Error` 当作普通 attempt 结果捕获，包进 `ExecutionException`，并可能重试（ledger D-15，code review only，未做 model check）。

- **Source**: Code Review（`counterexample: null`；dedup_note 说明模型里没有针对 Error 策略的 property，因此不存在 MC candidate）
- **Status**: DROPPED (code-review × known, cite: https://github.com/rholder/guava-retrying/issues/67)
- **Novelty**: KNOWN (cite: https://github.com/rholder/guava-retrying/issues/67; fix-status: unfixed)
- 审计版本：worktree HEAD `177b6c9b9f3e7957f404f0bdb8e23374cb1de43f`，与上游 `rholder/guava-retrying` master HEAD 相同（`gh api repos/rholder/guava-retrying/commits/master`，2026-11-26）。
- Persistent findings lookup（`specular findings ... lookup --query Retryer.call --query Error --query ExecutionException ...`）：`[]`，没有可复用的历史记录。

## Step 1: Code audit

引用位置（逐行核对 worktree）：

- `src/main/java/com/github/rholder/retry/Retryer.java:159-164`：`try { V result = attemptTimeLimiter.call(callable); attempt = new ResultAttempt<V>(...); } catch (Throwable t) { attempt = new ExceptionAttempt<V>(t, ...); }`。任何 `Throwable`（包括 `Error`）都会变成一个 `ExceptionAttempt`。
- `Retryer.java:253-257`：`ExceptionAttempt(Throwable cause, ...)` 执行 `this.e = new ExecutionException(cause)`；`get()` 抛出它（`Retryer.java:260-262`），`getExceptionCause()` 返回原始 `Error`（`Retryer.java:280-282`）。
- `Retryer.java:166-168`：listener 收到这个 attempt；`Retryer.java:170-171`：predicate 拒绝该 attempt 时，`return attempt.get()` 抛出 `ExecutionException(cause=Error)`；`Retryer.java:173-174`：stop strategy 停止时抛出 `RetryException(attemptNumber, attempt)`，其 cause 就是该 `Error`（`RetryException.java:57`）。
- `AttemptTimeLimiters.java:76-79`（`NoAttemptTimeLimit`）直接调用 `callable.call()`；`AttemptTimeLimiters.java:105-108`（`FixedAttemptTimeLimit`）调用 `timeLimiter.callWithTimeout(callable, duration, timeUnit, true)`。
- Guava 22.0 `com/google/common/util/concurrent/SimpleTimeLimiter.java:162-163` 捕获 worker 的 `ExecutionException` 后调用 `throwCause(e, true)`；`SimpleTimeLimiter.java:264-265` 判断 `if (cause instanceof Error) throw (Error) cause;`。因此在 `fixedTimeLimit` 下，`Error` 不被包装（只是 stack trace 被拼接），原样到达 `Retryer.java:162` 这同一个 catch。

各 predicate 的行为（`RetryerBuilder.java`）：

- `retryIfException()` → `ExceptionClassPredicate(Exception.class)`（`RetryerBuilder.java:130-133`、`207-213`）：`Error` 不是 `Exception`，predicate 为 false → `call()` 在 1 次 attempt 后抛出 `ExecutionException(cause=Error)`。
- `retryIfExceptionOfType(Throwable.class / Error.class / AssertionError.class)`（`RetryerBuilder.java:153-157`）或 `retryIfException(Predicate<Throwable>)`（`RetryerBuilder.java:166-170`）→ predicate 为 true → 重试该 `Error`，直到 stop strategy 停止 → `RetryException(cause=Error)`。

调用链：`RetryerBuilder.newBuilder()...build()`（`RetryerBuilder.java:190-197`）→ `Retryer.call(callable)`（`Retryer.java:155`），或经 `Retryer.wrap(callable).call()`（`Retryer.java:195-197`、`317-319`）→ `attemptTimeLimiter.call(callable)`（`Retryer.java:160`）→ 用户 callable 抛出 `Error` → 在 `Retryer.java:162` 被捕获。

可达性：属于正常的公开 API 用法。任何抛出 `Error` 的 callable 都会走到这里（如 `-ea` 下的 `AssertionError`、`StackOverflowError`、`OutOfMemoryError`、`NoClassDefFoundError`、`ExceptionInInitializerError`）。有没有 time limit 都可达。

Safeguards：库内没有任何对 `Error` 的特殊处理。`Error` 不会丢失，它保留在 `ExecutionException.getCause()` / `RetryException.getCause()` 里，但调用方观察到的抛出类型从 unchecked `Error` 变成了 checked 包装异常；若 predicate 接受 `Throwable`，还会对它重试。

触发场景：`RetryerBuilder.<Integer>newBuilder().retryIfException().withStopStrategy(StopStrategies.stopAfterAttempt(3)).withRetryListener(l).build().call(() -> { throw new AssertionError("boom"); })` → listener 收到一次 `hasException()==true` 的 attempt；`call()` 抛出 `ExecutionException`，其 cause 为该 `AssertionError`。改用 `.retryIfExceptionOfType(Throwable.class)` → 进行 3 次 attempt，然后抛出 `RetryException(cause=AssertionError)`。加上 `.withAttemptTimeLimiter(AttemptTimeLimiters.fixedTimeLimit(...))` 结果相同，因为 Guava 会原样重新抛出该 `Error`。

## Step 2: Developer-knowledge search

- **上游 issue #67**（https://github.com/rholder/guava-retrying/issues/67，OPEN，2016-11-15 由 sslavic 创建，0 条评论）。标题："Retryer.call should not catch Errors like OOME"。正文原文："Please consider catching \"Exception | RuntimeException e\" instead of Throwable at https://github.com/rholder/guava-retrying/blob/master/src/main/java/com/github/rholder/retry/Retryer.java#L162 not to catch and wrap Error potentially thrown by the called Callable."
- **#67 的 timeline**：唯一的交叉引用来自 fork 的 https://github.com/rhuffman/re-retrying/issues/14（已关闭，2017-09-29），标题 "Retryer.call should probably not retry if the Callable throws an Error"，正文原文："The Retryer.call method catches Throwable. This is probably not advisable because it will keep retrying, most likely uselessly, on problems like OutOfMemoryError. This is a duplicate of Issue #67 in the original guava-retrying project."
- **PR / 近期合并检查**：在 rholder/guava-retrying 中用 `Throwable`、`Error`、`OOME`、`OutOfMemoryError`、`67` 搜索 `gh search prs`，没有任何 PR 处理该 catch（命中的只有 #78 "Make ExceptionAttempt and ResultAttempt public"（closed）、#99、#42、#68，均无关）。按 updatedAt 排序的最近 PR：#84 closed 2026-09-20 未合并；#107 "Modernize" 修改了 `Retryer.java`，但于 2026-09-05 关闭且 `mergedAt: null`。上游 master HEAD 仍为 `177b6c9`（2016-05-10）。没有已落地的修复。
- **#67 指向的正是该行**：master 的 `Retryer.java` 第 162 行（`gh api .../contents/...?ref=master`）是 `            } catch (Throwable t) {`，与 worktree 的第 162 行完全相同（同一 commit）。
- **Commits / blame**：`catch (Throwable t)` 由 `6d2d838`（2012-11-17，"update package, clean up some Javadoc"）引入，`fbe3177`（2013-06-06，"minor formatting changes"）只调整了格式。没有任何提交说明处理 `Error` 的意图。
- **注释 / 文档**：`Attempt.java:21-23` 写的是 "An attempt of a call, which resulted either in a result returned by the call, or in a Throwable thrown by the call."；`Retryer.java:148-150` 写的是 "@throws ExecutionException if the given callable throws an exception, and the rejection predicate considers the attempt as successful. The original exception is wrapped into an ExecutionException."；`RetryerBuilder.java:124-129` 中 `retryIfException()` = "any `Exception` or subclass of `Exception`"；`RetryerBuilder.java:146-153` 中 `retryIfExceptionOfType(Class<? extends Throwable>)` 接受 `Error` 类型；`README.md:55-56` 写的是 "If any other `Exception` pops out of the `call()` method it's wrapped and rethrown in an `ExecutionException`."，没有提到 `Error`。没有 TODO/FIXME。
- **Tests**：现有测试都没有从 callable 抛出 `Error`（在 `src/test` 中 grep `Error|Throwable|OutOfMemory|StackOverflow|AssertionError`，只命中 `RetryerBuilderTest.java:274-296` 中的 `Predicate<Throwable>` 用法）。

## Step 3: Known-status / precedent

- **机制相同**：`Retryer.call` 用 `catch (Throwable t)` 把 callable 抛出的 `Error` 当作普通 attempt 结果，并把它包装起来（`ExceptionAttempt` → `ExecutionException`）。#67 原话就是 "not to catch and wrap Error potentially thrown by the called Callable"。
- **位置相同**：#67 链接的 `Retryer.java#L162`（master，commit `177b6c9`）正是本 finding 引用的 `Retryer.java:162`。
- 本 finding 列出的其他后果（listener 收到 `Error` attempt、抛出 checked `ExecutionException`、在接受 `Throwable` 的 predicate 下被重试、`fixedTimeLimit` 路径经 `SimpleTimeLimiter.java:264-265`）都来自这一个 catch，#67 提出的修复（catch `Exception` 而非 `Throwable`）能一并消除。重试这一后果已由 re-retrying#14 作为 #67 的重复单独报告过。time-limiter 路径不是另一个位置：Guava 把 `Error` 原样重新抛出，由同一个 catch 处理。目标说明也把 "#67: `Retryer.call` catches and wraps `Error`s" 列为已知上游问题。
- 来源为 code review（没有 counterexample）。

→ 唯一的 Phase-1 预过滤条件成立：code-review × already-reported。**Status: DROPPED (code-review × known, cite: https://github.com/rholder/guava-retrying/issues/67)**。按 `guide.md` / `phases/01-investigation.md` Step 3，不进入 Phase 2，不写 `repro/` 测试；DROPPED 也不写 persistent `issue.json`（只有 REPRODUCED / ENV_LIMITED / MASKED 才写）。
