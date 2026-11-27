# MC-9

Status: REPRODUCED
Run: guava-retrying-opus55max-20261126

running ls -la ~/.claude/skills/ 2>/dev/null; ls -la ~/.claude/ 2>/dev/null; find / -type d -name "bug-confirmation" 2>/dev/null | head -20
running pwd; ls -la; ls -la .claude 2>/dev/null; find . -maxdepth 4 -name "*.md" | head -50; ls -la /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirma...
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; cat SKILL.md; echo ======; cat guide.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; cat phases/01-investigation.md; echo ======; cat phases/02-reproduction.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; cat references/persistent-findings.md; echo ======; cat references/repair-request-f...
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; ls -la $OUT; ls -la $OUT/confirmati...
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; cat $OUT/persistent-findings-contex...
已读完 bug-confirmation skill（guide + phase 1/2 + references）。接下来先做 persistent-findings lookup，然后进入 Phase 1 代码审计。
running cd /home/ubuntu/guava-retrying-20261126/Specular; ls -la specular; file specular; OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus5...
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-9/worktree; cd $W; ls...
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-9/worktree; cat -n $W/...
running find / -type d -name "guava-22.0" 2>/dev/null | head; find / -name "SimpleTimeLimiter.java" -path "*guava-22*" 2>/dev/null | head
running find / \( -name "guava-22.0*.jar" -o -name "guava-22.0-sources.jar" \) 2>/dev/null | head; OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retry...
running mkdir -p /tmp/mc9-guava-src && cd /tmp/mc9-guava-src && unzip -o -q /home/ubuntu/scratch/guava22-sources-dl/guava-22.0-sources.jar 'com/google/common/util/co...
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-9/worktree; cat -n $W/...
running S=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec; ls -la $S/output/ | grep -i shut...
running S=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec; cat $S/output/hunt_s4_shutdown_b...
running S=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec; grep -nE "^(Error|State [0-9]+:)...
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-9/worktree; cd $W; git...
running which gh && gh auth status 2>&1 | head -5; timeout 60 gh api -X GET search/issues -f q='repo:rholder/guava-retrying RejectedExecutionException' --jq '.total_...
running for q in 'shutdown' 'rejected' 'executor' 'ExecutorService' 'SimpleTimeLimiter' 'fixedTimeLimit' 'AttemptTimeLimiter' 'time limiter' 'busy loop' 'callable ne...
running timeout 90 gh api --paginate "repos/rholder/guava-retrying/issues?state=all&per_page=100&sort=updated&direction=desc" --jq '.[] | "#\(.number) [\(.state)] pr...
running timeout 60 gh api repos/rholder/guava-retrying/pulls/107 --jq '"merged=\(.merged) merged_at=\(.merged_at) closed_at=\(.closed_at) state=\(.state)\ntitle=\(.t...
running for n in 69 65 94 18 67 29 100 92 35 96; do body=$(timeout 60 gh api repos/rholder/guava-retrying/issues/$n --jq '.title + "\n" + (.body // "")' 2>&1); comme...
running for repo in rhuffman/re-retrying; do for q in RejectedExecutionException shutdown rejected; do echo "=== $repo $q"; timeout 60 gh api -X GET search/issues -f...
running ls ~/.m2/repository/com/google/code/findbugs/jsr305/ 2>/dev/null; ls ~/.m2/repository/com/google/guava/guava/ 2>/dev/null; ls ~/.m2/repository/junit/junit 2>...
running timeout 60 gh api repos/rholder/guava-retrying/issues/29 --jq '"#\(.number) [\(.state)] created=\(.created_at) \(.title)\n\(.body)"'; echo "--- comments"; ti...
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-9/worktree; cd $W/src/...
running cd ~/.m2/repository/com/google/guava/guava/22.0/ && ls && sha1sum guava-22.0.jar && cat guava-22.0.jar.sha1 2>/dev/null; echo; cd ~/.m2/repository/com/google...
依赖 jar 的 SHA1 与 Maven Central 校验文件一致（guava 22.0、jsr305 2.0.2）。现在把 Phase 1 证据写入 `investigation.md`。
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-9/investigation.md
Phase 1 已落盘。进入 Phase 2：先确认原始源码目录与 worktree 是同一提交，然后写 Level 0（纯 public API、源码不改）复现脚本。
running S0=/home/ubuntu/scratch/guava-retrying-src/guava-retrying; W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retry...
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/test_bugMC-9_rejected_submit_misattributed.sh
running R=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro; chmod +x $R/test_bugMC-9_reject...
running R=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro; cd $R && timeout 10m ./test_bug...
第二次运行同样 6/6 触发，结果确定、可重复。接着核对 README 推荐的配置，看这个缺陷在常见用法下的实际后果。
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-9/worktree; grep -n -B...
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/test_bugMC-9_rejected_submit_misattributed.sh
running R=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro; rm -f $R/MC-9.run2.log; cd $R &...
running R=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro; cd $R && timeout 10m ./test_bug...
结果确定：最终版本两次运行都是 7/7 触发，退出码 0。接下来写持久化记录 `issue.json`。先确认要用作 span 边界的源码行在各自文件中唯一。
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-9/worktree/src/main/ja...
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-9/issue.json
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; python3 -I -c "import json,sys; d=j...
`issue.json` 通过校验（`valid: true`，标题 141 字符）。下面是最终确认结论。

# MC-9 确认结果

- **Source**: MC
- **Novelty**: NEW
- **Status**: REPRODUCED
- **Severity**: Medium
- **Location**: src/main/java/com/github/rholder/retry/Retryer.java:162
- **Reproduction test**: `repro/test_bugMC-9_rejected_submit_misattributed.sh`，Level 0；日志 `repro/MC-9.log` 和 `repro/MC-9.run2.log`，两次运行都是 7/7 触发
- **Persistent record**: `confirmation/MC-9/issue.json`（已通过 `specular findings validate`）；Phase 1 证据在 `confirmation/MC-9/investigation.md`

## Description
`AttemptTimeLimiters.fixedTimeLimit(d, unit, executor)` 收到的 executor 被 shutdown 之后，再走到 Guava 22.0 `SimpleTimeLimiter.callWithTimeout` 第 149 行的 `executor.submit(callable)` 会抛 `RejectedExecutionException`。这次 submit 在 `try` 块之外，异常原样穿过 `FixedAttemptTimeLimit.call`（`AttemptTimeLimiters.java:107`），被 `Retryer.call` 的 `catch (Throwable t)`（`Retryer.java:162-163`）记成 callable 抛出的异常，并编号为第 N 次 attempt。callable 实际一次都没运行。后果分三种：

- **predicate 不匹配**：`call()` 抛 `ExecutionException(RejectedExecutionException)`。Javadoc 只在「the given callable throws an exception」时才承诺抛这个异常。
- **retry-all predicate**：每次被拒绝的 submit 都按 callable 失败重试，listener 和 `RetryException` 统计的都是从未运行过的 attempt。
  - `stopAfterAttempt(3)`：`call()` 抛出的 `RetryException` 报告 3 次失败，callable 调用 0 次。
  - `neverStop` + `noWait`（builder 默认值）：CPU 约 100% 空转，每秒 13–24 万次假 attempt。
  - README 的指数退避配置：`call()` 永不返回。

## Trigger scenario
与 `hunt_s4_shutdown_bfs2.out` 逐步对应：

1. **State 2 `MCExecutorShutdown`**：`executor.shutdown()`。
2. **State 3 `MCCallStart`**：用 `fixedTimeLimit(1s, executor)` + `retryIfExceptionOfType(IOException.class)` + 一个 listener 构建 Retryer，然后调用 `retryer.call(callable)`。
3. **State 4 `MCSubmitRejected`**：`SimpleTimeLimiter.java:149` 的 submit 被拒绝，计为 attempt 1，callable 未被调用（`made=1`, `curInvoked=FALSE`）。bfs1 就停在这一步，违反 `CountedImpliesInvokedNoStartRace`。
4. **States 5–7（listener 通知）**：`onRetry` 收到 attempt#1，`hasException=true`。
5. **State 8 `MCPredicateAccepts`**：predicate 不匹配，`Retryer.java:171` 的 `attempt.get()` 抛 `ExecutionException(RejectedExecutionException)`，违反 `ExecutionExceptionMeansCallableThrewExcept29`。

生产环境里更常见的触发方式（S4）：attempt 1 抛 `IOException`，Retryer 在 `fixedWait` 期间等待，此时应用停机关掉了 executor；attempt 2 被拒绝，也被归到 callable 头上。

## Developer intent
- `Retryer.java:148-150` 写明 `@throws ExecutionException if the given callable throws an exception ... The original exception is wrapped into an ExecutionException.`
- `Attempt.java` 定义 attempt 为「An attempt of a call, which resulted either in a result returned by the call, or in a Throwable thrown by the call」。`RetryException` 把 `numberOfFailedAttempts` 解释为「times we've tried and failed」。
- `AttemptTimeLimiter.call` 只写了 `@throws Exception any exception from this invocation`，没有说 limiter 自己的异常算作 callable 的异常。
- 现有测试 `AttemptTimeLimiterTest` 只覆盖 timeout 包成 `ExecutionException(UncheckedTimeoutException)`。没有任何测试覆盖被拒绝或已 shutdown 的 executor。
- `catch (Throwable)` 从 2012 年（`6d2d838b`）起就在，相关提交信息里没有任何讨论。
- 上游 #29（https://github.com/rholder/guava-retrying/issues/29 ，open）：维护者 rholder 表示「would also consider it a bug ... its failure is tied to any `Exception` that might pop out」。不过整个讨论只涉及 timeout，即 callable 已提交之后 `future.get` 超时。#29 提议的修法（让 limiter 区分 `TimeoutException` 和 `ExecutionException`）仍会让 submit 抛出的原始 `RejectedExecutionException` 落进同一个 catch，所以是同一位置的不同缺陷。invariant 本身也排除了 #29 的情形。
- 去重检索（判定 NEW 的依据）：
  - 上游关键词 `RejectedExecutionException`、`shutdown`、`rejected`、`busy loop`、`never executed` 全部 0 命中。
  - 逐条看过全部 107 个 issue/PR。最近关闭的 #107（2026-09-05）未合并，是 PHP 移植；#84 只改 README。
  - fork `rhuffman/re-retrying` 无相关报告，Specular registry 无记录。
  - #67（catch Error）讨论的是另一个问题。

## Reproduction result
运行命令：`cd .specular-output/repro && timeout 10m ./test_bugMC-9_rejected_submit_misattributed.sh`，退出码 0。

```text
source HEAD  : 177b6c9b9f3e7957f404f0bdb8e23374cb1de43f
source dirty : 0 modified file(s) under src/ (0 = unmodified library)
guava jar    : /home/ubuntu/.m2/repository/com/google/guava/guava/22.0/guava-22.0.jar (sha1 3564ef3803de51fb0530a8377ec6100b33b0d073)
[     0.0 ms] === S1: exact MC counterexample hunt_s4_shutdown_bfs2 (retryIfExceptionOfType(IOException), fixedTimeLimit(1s, executor))
[    20.9 ms] [CE state 2 MCExecutorShutdown] executor.shutdown() -> isShutdown=true
[    36.9 ms] [CE state 3 MCCallStart] retryer.call(callable)
[    37.8 ms] [CE states 4-7 MCSubmitRejected + MCListener*] listener.onRetry: attempt#1 hasException=true getExceptionCause()=java.util.concurrent.RejectedExecutionException | callable invocations so far=0
[    37.9 ms] [CE state 8 MCPredicateAccepts -> outcome ExecExc] call() threw java.util.concurrent.ExecutionException: java.util.concurrent.RejectedExecutionException: Task java.util.concurrent.FutureTask@4f3f5b24[Not completed, task = MC9Repro$1@27d6c5e0] rejected from java.util.concurrent.ThreadPoolExecutor@4617c264[Terminated, pool size = 0, active threads = 0, queued tasks = 0, completed tasks = 0]
[    38.3 ms]         at com.github.rholder.retry.Retryer$ExceptionAttempt.<init>(Retryer.java:254)
[    38.5 ms]         at com.github.rholder.retry.Retryer.call(Retryer.java:163)
[    39.4 ms]         at java.base/java.util.concurrent.AbstractExecutorService.submit(AbstractExecutorService.java:145)
[    39.5 ms]         at com.google.common.util.concurrent.SimpleTimeLimiter.callWithTimeout(SimpleTimeLimiter.java:149)
[    39.6 ms]         at com.github.rholder.retry.AttemptTimeLimiters$FixedAttemptTimeLimit.call(AttemptTimeLimiters.java:107)
[    39.7 ms]         at com.github.rholder.retry.Retryer.call(Retryer.java:160)
[    39.9 ms]     callable invocations=0  listener notifications=1
[    42.1 ms] control C1 (callable throws IllegalStateException): call() threw ExecutionException(cause=IllegalStateException); callable invocations=1  <- documented case
[    43.1 ms] control C2 (callable returns): call() returned "callable-ran"; callable invocations=1
[    47.1 ms]     matrix: 8/8 configurations misattribute the rejected submit as the callable's exception
[    48.1 ms] call() threw RetryException: "Retrying failed to complete successfully after 3 attempts."
[    48.3 ms]     getNumberOfFailedAttempts()=3  getLastFailedAttempt().getAttemptNumber()=3  getLastFailedAttempt().getExceptionCause()=java.util.concurrent.RejectedExecutionException
[    48.3 ms]     callable invocations=0  listener notifications=3
[  3061.7 ms]     t=3s: caller alive=true state=RUNNABLE | attempts reported to listener=480,361 | callable invocations=0 | caller CPU 2972 ms of 3002 ms wall
[  8068.4 ms]     t=4s: caller alive=true state=TIMED_WAITING | attempts reported to listener=5 | callable invocations=0 | caller CPU 0 ms of 4001 ms wall
[  8571.6 ms]     listener.onRetry: attempt#2 hasException=true getExceptionCause()=java.util.concurrent.RejectedExecutionException | callable invocations so far=1
[  8571.7 ms]     call() threw ExecutionException(cause=java.util.concurrent.RejectedExecutionException); callable invocations=1; attempts reported=2
[  9073.2 ms]     call() returned "ok-on-invocation-2"; callable invocations=2
[  9074.1 ms] RESULT: BUG REPRODUCED (MC-9; 7 scenario checks triggered)
```

以上是摘录，完整输出在 `repro/MC-9.log`。

- **S1 的关键行**：`callable invocations=0` 和 `ExecutionException ... RejectedExecutionException` 同时出现，栈帧正好经过 `SimpleTimeLimiter.java:149` → `AttemptTimeLimiters.java:107` → `Retryer.java:160/163`。
- **S1 对照组**：配置不变、executor 未 shutdown 时，只有 callable 真的抛异常（C1）才会得到 `ExecutionException`。
- **S2（bfs1）**：`RetryException` 报告 3 次失败，实际调用 0 次。
- **S3**：持续空转，CPU 时间约等于墙钟时间。
- **S3b**：README 指数退避配置下，4 秒后 `call()` 仍未返回。
- **S4**：中途 shutdown 导致误归因；不 shutdown 的对照组正常返回 `"ok-on-invocation-2"`。

## Recommendation
1. **主修复**：在 `Retryer.call` 或 `FixedAttemptTimeLimit.call` 里区分「attempt 没能启动」和「attempt 失败」。
   - 用内部 wrapper 包住用户 callable，进入时记录 `invoked=true`。
   - 如果 limiter 抛出 `RejectedExecutionException` 时 `invoked` 仍为 false，就直接从 `call()` 抛出（它是 `RuntimeException`，签名不用改）。
   - 这种情况下不构造 `ExceptionAttempt`、不通知 listener、不走 rejection predicate 和 stop strategy。
   - 这样 `ExecutionException` 只表示 callable 自己抛了异常，attempt 计数也等于真实调用次数。
2. **相关情形**：任务排队后在启动前就超时，`invoked` 同样为 false。修复时需要把这种情况一起定下统一语义。
3. **文档**：在 `fixedTimeLimit(long, TimeUnit, ExecutorService)` 的 Javadoc 里写明 executor 必须在 Retryer 的整个生命周期内保持运行，并说明 submit 被拒绝时如何报告。
4. **回归测试**：
   - executor 已 shutdown + `retryIfExceptionOfType(IOException)`：`call()` 不应抛 `ExecutionException`。
   - executor 已 shutdown + `retryIfException()`：callable 一次没跑时不应计数，也不应重试。
5. **2.0.0 的临时规避**：Retryer 仍在使用时不要 shutdown 它的 limiter executor；在 predicate 里排除这个异常，例如 `retryIfException(t -> !(t instanceof RejectedExecutionException))`。注意 callable 自己也可能抛 `RejectedExecutionException`，这时两种情况无法区分。

## REPRODUCED 前置检查
1. **是否仅靠 Level 0/1 触发**：是，Level 0。
   - 只用了 public API（`RetryerBuilder`、`fixedTimeLimit(d, unit, executor)`、`RetryListener`、`Retryer.call`）和 JDK 的 `ExecutorService.shutdown()/shutdownNow()`。
   - 库源码未改动（`177b6c9`，`src/` 下 0 处修改）。
   - S4 只是通过 public listener 的 latch 安排测试自己的操作顺序，没有往库里注入任何时序。
2. **Level 2/3 注入**：不适用，没有使用。复现顺序与反例 bfs2 的 State 2→8 逐步对应，bfs1 对应其中的 State 2→4。
3. **谁观察到错误结果**：`Retryer.call()` 的调用方。
   - `Retryer.java:171` 把 `ExecutionException(RejectedExecutionException)` 交给调用方。
   - `Retryer.java:174` 抛出的 `RetryException` 报告了 3 次从未运行的 attempt。
   - `Retryer.java:166-168` 把伪造的 attempt 交给 `RetryListener.onRetry`。
   - `Retryer.java:317-318` 的 `RetryerCallable.call()` 原样传播同样的结果。
   - 复现中的调用方和 listener 都直接观察到了这些结果，不只是推论。
4. **状态是永久的还是会被修复或掩盖**：永久。
   - `call()` 已经以误归因的异常结束，之后没有任何机制重新分类。
   - executor shutdown 不可逆，retry-all 配置永远不会调用到 callable，只能靠中断退出（中断退出是文档写明的路径，并不修复问题）。
   - 没有下游机制掩盖这个结果，所以不属于 MASKED。

## Repair round 1 evidence
<!-- specular-repair-token: 3eefa76b5b37ed587e41b6cbdb823026 -->
- **Current violation analysis**: When the ExecutorService passed to fixedTimeLimit(d, unit, executor) has been shut down, executor.submit throws RejectedExecutionException (SimpleTimeLimiter.java:149) and Retryer.call records it as the attempt's Throwable (Retryer.java:162-163) as if the callable had thrown it. TLC: shutdown, call(), the submit is rejected and counted as attempt 1 (CountedImpliesInvokedNoStartRace, which after RR-002 still rejects a rejection by a shut-down executor: spec/output/repair-r1/repair1_ctl_s4_shutdown_cir.out, 4 states; originally hunt_s4_shutdown_bfs1.out); with retryIfExceptionOfType(IOException…
- **Counterexample**: `spec/output/repair-r1/repair1_s4_shutdown_bfs2.out`

## Phase 4 confirmation after repair round 1

running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-9 && ls -la && echo -...
running find / -type d -name "bug-confirmation" 2>/dev/null | head -20; find / -path /proc -prune -o -type f -name "guide.md" -path "*bug-confirmation*" -print 2>/de...
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation && ls -laR && echo ====== && cat SKILL.md && echo ====== && cat guide.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation && cat phases/01-investigation.md && echo ====== && cat phases/02-reproduction.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation && cat references/persistent-findings.md && echo ====== && cat references/repair-req...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-9 && cat investigatio...
running S=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec; ls -la $S/output/repair-r1/ | gr...
running S=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec/output; cat $S/repair-r1/repair1_...
running S=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec/output; diff $S/hunt_s4_shutdown_...
running S=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec/output; for f in repair-r1/repair...
running R=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro; ls -la $R | grep -E "MC-9|bugMC...
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-9/worktree; cd $W && g...
running G=/tmp/mc9-guava-src/com/google/common/util/concurrent/SimpleTimeLimiter.java; if [ -f $G ]; then sed -n '138,170p' $G | awk '{printf "%d\t%s\n", NR+137, $0}...
running cd /home/ubuntu/guava-retrying-20261126/Specular; which specular; ls -la specular 2>/dev/null | head -2; OUT=/home/ubuntu/guava-retrying-20261126/Specular/ru...
running which gh >/dev/null && echo "gh ok"; timeout 90 gh api "repos/rholder/guava-retrying/issues?state=all&per_page=15&sort=updated&direction=desc" --jq '.[] | "#...
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/test_bugMC-9_rejected_submit_misattributed.sh
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-9 && python3 -I -c "...
只追踪了测试脚本。我会把上一轮的两份日志保留为 `MC-9.r0*.log`，本轮输出写到原名 `MC-9.log` / `MC-9.run2.log`，确保脚本与日志一致。现在执行复现。
running R=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro; cd $R && cp -p MC-9.log MC-9.r0...
running R=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro; cd $R && (timeout 10m ./test_bu...
两次运行均为 7/7、exit 0，结果确定。S3 的空转速率与上一轮不同，下面核对两轮日志的速率，以便如实更新报告中的数字。
running R=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro; cd $R && for f in MC-9.r0.log M...
running R=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro; cd $R && grep -hE "sha256|sourc...
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-9/investigation.md
running F=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-9/investigation.md; ca...
`investigation.md` 的磁盘变更就是我刚才追加的内容。接下来更新 `issue.json`：改用新反例路径、新日志，修正空转速率范围，并补充 repaired trace 的前提。
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-9 && cp -p issue.json...
内容改动符合预期（其余差异只是 JSON 缩进格式）。现在运行 `specular findings validate`。
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; cd /home/ubuntu/guava-retrying-2026...
`issue.json` 校验通过（`valid: true`，标题 141 字符）。写结论前，最后复核报告要引用的几处行号。
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-9/worktree/src/main/ja...
所有引用行号均已核实，结论如下。

# MC-9 确认结果（repair round 1 续审）

- **Source**: MC
- **Novelty**: NEW
- **Status**: REPRODUCED
- **Severity**: Medium
- **Location**: src/main/java/com/github/rholder/retry/Retryer.java:162
- **Reproduction test**: `repro/test_bugMC-9_rejected_submit_misattributed.sh`，Level 0。
  - 本轮日志 `repro/MC-9.log` 和 `repro/MC-9.run2.log`：两次都是 7/7 触发，退出码 0。
  - 上一轮日志另存为 `repro/MC-9.r0.log` 和 `repro/MC-9.r0.run2.log`。
- **Persistent record**: `confirmation/MC-9/issue.json` 已更新，`specular findings validate` 返回 `valid: true`。`confirmation/MC-9/investigation.md` 末尾新增了 "Repair round 1 continuation" 一节。

## 本轮核对结论
- **反例对比**：
  - `spec/output/repair-r1/repair1_s4_shutdown_bfs2.out` 与原来的 `hunt_s4_shutdown_bfs2.out` 相比，State 2→8 的动作序列相同，违反的 invariant 也都是 `ExecutionExceptionMeansCallableThrewExcept29`。
  - `repair1_ctl_s4_shutdown_cir.out` 与原来的 `hunt_s4_shutdown_bfs1.out` 相比，同样只有 4 个 state，违反的都是 `CountedImpliesInvokedNoStartRace`。也就是说，按 RR-002 修订后，这个 invariant 仍然把"被已 shutdown 的 executor 拒绝"判为违反。
- **唯一的语义差异**：`MCSubmitRejected` 之后，`curQueued` 从 `TRUE` 变成了 `FALSE`。
  - 新值与实现一致：对已 shutdown 的 pool，`ThreadPoolExecutor.execute`（`ThreadPoolExecutor.java:1376`）直接调用 `reject`，任务不会入队。
  - 复现脚本为此新增了一条断言：listener 在 State 4 到 8 之间看到 `taskCount=0 queue.size=0 largestPoolSize=0`。
- **修正**：原反例里 `curQueued = TRUE` 是模型误差。上一轮的结论没有用到这个变量，所以不受影响。需要改的只有反例路径引用，已在 `investigation.md`、`issue.json` 和脚本里更新。
- **源码一致性**：源码仍是 `177b6c9`，`src/` 下没有任何修改。`Retryer.java` 和 `AttemptTimeLimiters.java` 的哈希、Guava 22.0 jar 的 sha1 都与上一轮相同。
- **空转速率**：上一轮写的"每秒 13–24 万次"是按每秒增量统计的，数据本身没错。本轮跑得更快，四次运行合计的范围更新为每秒约 13–28 万次。

## Description
`fixedTimeLimit(d, unit, executor)` 收到的 executor 被 shutdown 后，Guava 22.0 的 `SimpleTimeLimiter.java:149` 调用 `executor.submit(callable)` 时会抛出 `RejectedExecutionException`。这行在 `try` 块之外，异常原样穿过 `AttemptTimeLimiters.java:107`，然后被 `Retryer.java:162-163` 的 `catch (Throwable t)` 当作 callable 抛出的异常，记为第 N 次 attempt。实际上 callable 一次都没有运行，任务也从未进入 executor。

后果取决于 rejection predicate：
- **predicate 不匹配**（例如 `retryIfExceptionOfType(IOException)`）：`call()` 抛出 `ExecutionException(RejectedExecutionException)`。
- **retry-all predicate**（`retryIfException()` 或 `retryIfRuntimeException()`）：每次被拒绝都当作 callable 失败来重试。
  - 配 `stopAfterAttempt(3)`：`RetryException` 报告 3 次失败，callable 实际调用 0 次。
  - 用 builder 默认的 `neverStop` + `noWait`：CPU 约 100% 空转。
  - 用 README 里的指数退避配置：`call()` 永不返回。

## Trigger scenario
与 `repair1_s4_shutdown_bfs2.out` 逐步对应：
1. **State 2 `MCExecutorShutdown`**：调用 `executor.shutdown()`。
2. **State 3 `MCCallStart`**：用 `fixedTimeLimit(1s, executor)`、`retryIfExceptionOfType(IOException.class)` 和一个 listener 构建 Retryer，然后调用 `retryer.call(callable)`。
3. **State 4 `MCSubmitRejected`**：submit 被拒绝，计为 attempt 1。对应模型状态 `made=1`、`curInvoked=FALSE`、`curQueued=FALSE`。cir/bfs1 反例到这一步为止。
4. **States 5–7**：`onRetry` 收到 attempt#1，`hasException=true`。
5. **State 8 `MCPredicateAccepts`**：`Retryer.java:171` 的 `attempt.get()` 抛出 `ExecutionException(RejectedExecutionException)`，模型状态为 `exitInfo.invoked=FALSE`。

生产中更常见的触发方式（S4）：attempt 1 抛出 `IOException`，Retryer 在等待重试期间，应用停机关掉了 executor，于是 attempt 2 被拒绝，并被算作 callable 的失败。

## Developer intent
- **Javadoc 契约**：
  - `Retryer.java:148-150`：`ExecutionException` 只在 "the given callable throws an exception" 时抛出。
  - `Attempt.java:21-23`：attempt 的结果是 "a Throwable thrown by the call"。
  - `RetryException.java:41`：失败次数的含义是 "times we've tried and failed"。
- **测试**：没有任何测试覆盖被拒绝或已 shutdown 的 executor。
- **维护者态度**：上游 #29（https://github.com/rholder/guava-retrying/issues/29 ，open）中，维护者 rholder 表示，把 limiter 自身的异常算到 attempt 头上 "would also consider it a bug"。
- **与 #29 的区别**：#29 只讨论超时，即 `future.get` 发生在任务已提交之后。它提议的修法仍会让 submit 阶段的 `RejectedExecutionException` 落进同一个 catch，所以 MC-9 是同一位置的另一个缺陷。
- **查重（今天重新查过）**：
  - 上游搜索 `RejectedExecutionException`、`shutdown`、`rejected`、`executor shut`：全部 0 命中。
  - 最近关闭的 PR #84 和 #107 都没有合并，master 仍是 `177b6c9`。
  - `specular findings lookup` 返回 `[]`。

## Reproduction result
运行命令：`cd .specular-output/repro && timeout 10m ./test_bugMC-9_rejected_submit_misattributed.sh`，两次运行的退出码都是 0。以下是 `MC-9.log` 的原文摘录：

```text
source HEAD  : 177b6c9b9f3e7957f404f0bdb8e23374cb1de43f
source dirty : 0 modified file(s) under src/ (0 = unmodified library)
[     0.0 ms] === S1: exact MC counterexample repair-r1/repair1_s4_shutdown_bfs2 (originally hunt_s4_shutdown_bfs2) (retryIfExceptionOfType(IOException), fixedTimeLimit(1s, executor))
[    18.4 ms] [CE state 2 MCExecutorShutdown] executor.shutdown() -> isShutdown=true
[    32.5 ms] [CE state 3 MCCallStart] retryer.call(callable)
[    33.4 ms] [CE states 4-7 MCSubmitRejected + MCListener*] listener.onRetry: attempt#1 hasException=true getExceptionCause()=java.util.concurrent.RejectedExecutionException | callable invocations so far=0 | executor taskCount=0 queue.size=0 largestPoolSize=0
[    33.5 ms] [CE state 8 MCPredicateAccepts -> outcome ExecExc] call() threw java.util.concurrent.ExecutionException: java.util.concurrent.RejectedExecutionException: Task java.util.concurrent.FutureTask@4f3f5b24[Not completed, task = MC9Repro$1@27d6c5e0] rejected from java.util.concurrent.ThreadPoolExecutor@4617c264[Terminated, pool size = 0, active threads = 0, queued tasks = 0, completed tasks = 0]
[    33.9 ms]         at com.github.rholder.retry.Retryer$ExceptionAttempt.<init>(Retryer.java:254)
[    34.1 ms]         at com.github.rholder.retry.Retryer.call(Retryer.java:163)
[    34.9 ms]         at java.base/java.util.concurrent.ThreadPoolExecutor.execute(ThreadPoolExecutor.java:1376)
[    35.0 ms]         at java.base/java.util.concurrent.AbstractExecutorService.submit(AbstractExecutorService.java:145)
[    35.1 ms]         at com.google.common.util.concurrent.SimpleTimeLimiter.callWithTimeout(SimpleTimeLimiter.java:149)
[    35.1 ms]         at com.github.rholder.retry.AttemptTimeLimiters$FixedAttemptTimeLimit.call(AttemptTimeLimiters.java:107)
[    35.2 ms]         at com.github.rholder.retry.Retryer.call(Retryer.java:160)
[    35.3 ms]     callable invocations=0  listener notifications=1
[    35.4 ms] [repaired CE state 4: made=1, curInvoked=FALSE, curQueued=FALSE] executor after call(): taskCount=0 queue.size=0 largestPoolSize=0 completedTaskCount=0 isTerminated=true -> task ever queued or started: false
[    37.1 ms] control C1 (callable throws IllegalStateException): call() threw ExecutionException(cause=IllegalStateException); callable invocations=1  <- documented case
[    37.9 ms] control C2 (callable returns): call() returned "callable-ran"; callable invocations=1
[    41.8 ms]     matrix: 8/8 configurations misattribute the rejected submit as the callable's exception
[    42.8 ms] call() threw RetryException: "Retrying failed to complete successfully after 3 attempts."
[    42.9 ms]     getNumberOfFailedAttempts()=3  getLastFailedAttempt().getAttemptNumber()=3  getLastFailedAttempt().getExceptionCause()=java.util.concurrent.RejectedExecutionException
[    43.0 ms]     callable invocations=0  listener notifications=3  executor taskCount=0 (task ever queued or started: false)
[  3055.4 ms]     t=3s: caller alive=true state=RUNNABLE | attempts reported to listener=795,095 | callable invocations=0 | caller CPU 2982 ms of 3001 ms wall
[  8059.9 ms]     t=4s: caller alive=true state=TIMED_WAITING | attempts reported to listener=5 | callable invocations=0 | caller CPU 0 ms of 4001 ms wall
[  8562.5 ms]     listener.onRetry: attempt#2 hasException=true getExceptionCause()=java.util.concurrent.RejectedExecutionException | callable invocations so far=1
[  8562.6 ms]     call() threw ExecutionException(cause=java.util.concurrent.RejectedExecutionException); callable invocations=1; attempts reported=2
[  9063.7 ms]     call() returned "ok-on-invocation-2"; callable invocations=2
[  9064.4 ms] RESULT: BUG REPRODUCED (MC-9; 7 scenario checks triggered)
exit=0
```

各场景的关键证据：
- **S1（对应 bfs2）**：同时出现 `callable invocations=0`、`ExecutionException(RejectedExecutionException)` 和 `taskCount=0`，调用栈依次经过 `SimpleTimeLimiter.java:149` → `AttemptTimeLimiters.java:107` → `Retryer.java:160/163`。
- **S1 对照组**：executor 未 shutdown 时，只有 callable 真的抛异常（C1）才会得到 `ExecutionException`；正常返回时（C2）拿到结果。
- **S1 矩阵**：4 种 executor × `shutdown()`/`shutdownNow()`，8/8 都出现误归因。
- **S2（对应 cir/bfs1）**：报告 3 次失败，callable 实际调用 0 次。
- **S3**：持续空转，线程 CPU 时间约等于墙钟时间。
- **S3b**：README 的指数退避配置，4 秒后 `call()` 仍未返回。
- **S4**：中途 shutdown 后 attempt 2 被误归因；不 shutdown 的对照组正常返回。

## Recommendation
1. **主修复**：区分"attempt 没能启动"和"attempt 失败"。
   - 用内部 wrapper 包住 callable，进入时记录 `invoked=true`。
   - limiter 抛出 `RejectedExecutionException` 时如果 `invoked` 仍为 false，就从 `call()` 直接抛出。
   - 这种情况下不构造 `ExceptionAttempt`，不通知 listener，也不经过 predicate 和 stop strategy。
2. **统一语义**：任务已入队、但在启动前超时的情况也要一并定下语义（与 RR-002 涉及的 start race 相关）。
3. **文档**：在 `fixedTimeLimit(long, TimeUnit, ExecutorService)` 的 Javadoc 里写明，executor 必须在 Retryer 使用期间保持运行。
4. **回归测试**：
   - shutdown + `retryIfExceptionOfType(IOException)`：`call()` 不应抛出 `ExecutionException`。
   - shutdown + `retryIfException()`：被拒绝的提交不应计数，也不应重试。
5. **2.0.0 的临时规避**：Retryer 仍在使用时不要 shutdown 它的 executor，或者在 predicate 里排除 `RejectedExecutionException`。注意 callable 自己也可能抛这个异常，此时两种情况无法区分。

## REPRODUCED 前置检查
1. **是否仅靠 Level 0/1 触发**：是，Level 0。只用了 public API 和 JDK 的 `ExecutorService.shutdown()/shutdownNow()`，库源码未改动（`177b6c9`，`src/` 下 0 处修改）。S4 只是借 public listener 的 latch 安排测试自己的操作顺序。
2. **Level 2/3 注入**：不适用，没有使用。复现与 `repair1_s4_shutdown_bfs2.out` 的 State 2→8 逐步对应，S2 对应 `repair1_ctl_s4_shutdown_cir.out` 的 State 2→4。
3. **谁观察到错误结果**：`Retryer.call()` 的调用方和 listener，均在复现中直接观察到。
   - `Retryer.java:171` 把 `ExecutionException(RejectedExecutionException)` 交给调用方，该异常构造于 `Retryer.java:254`。
   - `Retryer.java:174` 抛出的 `RetryException` 计入了从未运行的 attempt。
   - `Retryer.java:166-168` 把伪造的 attempt 交给 `onRetry`。
   - `RetryerCallable.call()`（`Retryer.java:317-318`）原样传播上述结果。
4. **状态是永久的还是会被修复或掩盖**：永久。
   - `call()` 已经以误归因的异常结束，之后没有任何机制会重新分类。
   - executor shutdown 不可逆，retry-all 配置永远调用不到 callable，只能靠中断退出。中断是文档写明的退出路径，并不修复问题。
   - 没有下游机制掩盖这个结果，所以不属于 MASKED。
