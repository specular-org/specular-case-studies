# CR-D-16

Status: REPRODUCED
Run: guava-retrying-opus55max-20261126

running pwd; ls -la; find / -type d -name "bug-confirmation" 2>/dev/null | head -20
running ls -la /home/ubuntu/guava-retrying-20261126/Specular/ 2>/dev/null; ls -la /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation 2>/dev/null;...
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; cat SKILL.md; echo ----; ls -la phases references; echo ----; cat guide.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; cat phases/01-investigation.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; cat phases/02-reproduction.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; cat references/persistent-findings.md; echo; echo =========; cat references/repair-...
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; ls -la $OUT; echo ---; ls -la $OUT/...
开始处理 CR-D-16：已读完 bug-confirmation skill（guide + 两个 phase + references）。下一步：Phase 1 代码审计 + 已知性检索，然后写 repro 测试并实际运行。
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; cat $OUT/persistent-findings-contex...
running which specular; ls -la /home/ubuntu/guava-retrying-20261126/Specular/specular; OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55ma...
Persistent-findings lookup 返回 `[]`（无历史记录可复用）。进入 Phase 1 代码审计。
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-16/worktree; cat -n...
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-16/worktree; ls $W/s...
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-16/worktree; sed -n...
running which gh && gh auth status 2>&1 | head -5; timeout 60 gh repo view rholder/guava-retrying --json name,isArchived,pushedAt,updatedAt 2>&1 | head -20
running cd /tmp; timeout 90 gh issue list --repo rholder/guava-retrying --state all --limit 300 --json number,title,state,createdAt,closedAt 2>&1 > /tmp/crd16_issues...
running cd /tmp; timeout 90 gh pr list --repo rholder/guava-retrying --state all --limit 300 --json number,title,state,createdAt,mergedAt,closedAt > /tmp/crd16_prs.j...
running cd /tmp; for q in overflow negative "timeout value is negative" IllegalArgumentException composite join "Long.MAX_VALUE" saturat "MAX_VALUE" "computeSleepTim...
running cd /tmp; for n in 12 17 59; do echo "######## #$n"; timeout 60 gh issue view $n --repo rholder/guava-retrying --comments 2>/dev/null | head -80 || timeout 60...
running cd /tmp; for n in 107 101 95; do echo "######## PR #$n"; timeout 60 gh pr view $n --repo rholder/guava-retrying --json title,state,body,files,closedAt,merged...
running cd /tmp; for n in 107 95; do echo "######## PR #$n diff (WaitStrategies.java / BlockStrategies.java / Retryer.java hunks touching sum/sleep)"; timeout 90 gh...
running cd /tmp; timeout 60 gh issue view 100 --repo rholder/guava-retrying 2>/dev/null | head -30; echo ====; timeout 60 gh issue view 81 --repo rholder/guava-retry...
running cd /tmp; for repo in rhuffman/re-retrying itning/guava-retrying3; do echo "######## $repo"; timeout 60 gh repo view $repo --json name,pushedAt,hasIssuesEnabl...
running cd /tmp; for repo in rhuffman/re-retrying itning/guava-retrying3; do echo "######## $repo"; timeout 60 gh api "search/code?q=CompositeWaitStrategy+repo:$repo...
running cd /tmp; timeout 60 gh api repos/rhuffman/re-retrying/contents/src/main/java/com/github/rholder/retry/WaitStrategies.java --jq .content 2>/dev/null | base64...
running cd /tmp; timeout 60 gh api repos/itning/guava-retrying3/contents/src/main/java/io/github/itning/retry/strategy/wait/CompositeWaitStrategy.java --jq .content...
running ls /home/ubuntu/guava-retrying-20261126/Specular/case-studies | head -50; grep -ril "guava-retrying\|CompositeWaitStrategy\|rholder" /home/ubuntu/guava-retry...
running ls -la /home/ubuntu/guava-retrying-20261126/Specular/case-studies; ls /home/ubuntu/guava-retrying-20261126/; ls /home/ubuntu/guava-retrying-20261126/Specular...
running ls -R ~/.claude/skills/codex-memory-archive | head -30; grep -ril "guava-retrying\|guava_retrying\|CompositeWaitStrategy" ~/.claude/skills/codex-memory-archi...
Phase 1 已知性结论：未找到任何报告（上游 issues/PRs、近期关闭的 PR #107、两个 fork、本地 Specular 数据集均无）。现在准备构建环境（Guava 22.0 + jsr305）。
running ls ~/.m2/repository/com/google/guava/guava/ 2>/dev/null; ls ~/.m2/repository/com/google/code/findbugs/jsr305/ 2>/dev/null; find ~/.m2/repository -name "guava...
构建依赖齐全（`~/.m2` 中有 guava-22.0、jsr305-2.0.2；JDK 21 与 JDK 11 均可用）。先核对 jar 来源，然后写 `investigation.md`。
running cd ~/.m2/repository; for f in com/google/guava/guava/22.0/guava-22.0.jar com/google/code/findbugs/jsr305/2.0.2/jsr305-2.0.2.jar; do echo "$f"; sha1sum $f | c...
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-16/worktree; cd $W;...
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-16/worktree; sed -n...
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-16/worktree; grep -n...
Phase 1 证据齐全，写入 `investigation.md`（只记录证据，不下结论）。
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-16/investigation.md
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-16/worktree; grep -n...
补一处行号引用（`RetryerCallable.call` 在 `Retryer.java:317-319`），然后写复现脚本。
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-16/investigation.md
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/test_bugCR-D-16_join_sum_overflow.sh
复现脚本已写好（Level 0：只用未修改库的公共 API，默认 `ThreadSleepStrategy`；含 6 个 bug case + 6 个 control）。现在实际运行，JDK 21 与 JDK 11 各跑一遍。
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; chmod +x $OUT/repro/test_bugCR-D-16...
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; sed -n 1,175p $OUT/repro/CR-D-16.log
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; sed -n 175,341p $OUT/repro/CR-D-16....
running S=/home/ubuntu/scratch/guava-retrying-src/guava-retrying; ls $S >/dev/null && git -C $S rev-parse HEAD && git -C $S status --porcelain | head -5; cd $S/src/m...
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-16/issue.json
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; python3 -I -c "import json,sys; d=j...
`issue.json` 校验通过（`"valid": true`，title 153 字符）。以下是 CR-D-16 的结论。

## CR-D-16：`WaitStrategies.join` 求和溢出 → 负 sleep → `Retryer.call()` 抛出 `IllegalArgumentException`

- **Source**: Code Review
- **Novelty**: NEW
- **Status**: REPRODUCED（Level 0，纯公共 API，库未修改）
- **Severity**: Medium
- **Location**: src/main/java/com/github/rholder/retry/WaitStrategies.java:368
- **Reproduction test**: `.specular-output/repro/test_bugCR-D-16_join_sum_overflow.sh`，输出在 `.specular-output/repro/CR-D-16.log`
- **Persistent record**: `confirmation/CR-D-16/issue.json`（已用 `specular findings validate` 校验）；Phase 1 证据记录在 `confirmation/CR-D-16/investigation.md`

## Description

`join` 生成 `CompositeWaitStrategy`，它的 `computeSleepTime`（`WaitStrategies.java:365-371`）对各分量直接做 `long` 加法（`waitTime += ...`）。这里没有饱和处理，也不检查符号。

只要分量之和达到 2^63 ms 或更多，结果就会回绕成负数。`Retryer.call` 不做校验，直接把这个值交给默认的 `ThreadSleepStrategy`（`Retryer.java:176-178`）。`Thread.sleep(负数)` 在 `BlockStrategies.java:46` 抛出 `IllegalArgumentException("timeout value is negative")`，而 `call()` 只捕获 `InterruptedException`，所以异常直接抛出 `call()`。

这不在文档列出的三种结果之内（返回值、`ExecutionException`、`RetryException`）。后果有三点：
- 尝试次数丢失；
- 最后一次失败的异常丢失（IAE 没有 cause，也没有 suppressed）；
- 调用线程被中断时，文档规定的 `RetryException` 被 IAE 抢先。

## Trigger scenario

触发需要以下条件：
1. 用 `RetryerBuilder` 加 `retryIfException()`、`stopAfterAttempt(5)` 构建 retryer，wait strategy 是 `join(...)`，block strategy 用默认值。
2. 某个分量在第一次失败时就返回很大的值。例如：
   - `fixedWait(Long.MAX_VALUE, MILLISECONDS)`；
   - `fixedWait(Long.MAX_VALUE, DAYS)`（`toMillis` 饱和为 `Long.MAX_VALUE`）；
   - `exceptionWait(X.class, e -> SECONDS.toMillis(retryAfterHint))`，服务端退避提示过大时同样饱和为 `Long.MAX_VALUE`。
3. 与任意正数分量相加，比如 `fixedWait(1, SECONDS)` 或 `randomWait(1, SECONDS)` 抖动。
4. callable 失败一次后，`call()` 立刻抛出 IAE，`stopAfterAttempt(5)` 允许的后续 4 次尝试都不会发生。

如果调用线程在 attempt 期间被中断（例如 NIO 读被中断抛 `ClosedByInterruptException`，中断标志保持置位），或者进入 `call()` 前已被中断，结果仍是 IAE，而不是 `RetryException`。

## Developer intent

- `join` 的 Javadoc（`WaitStrategies.java:220`）："wait time which is total of all wait times"。
- 库本身把 `Long.MAX_VALUE` 当作合法的 sleep 上限：`exponentialWait()` 和 `fibonacciWait()` 的文档写的是 "up to Long.MAX_VALUE"。现有测试 `RetryerBuilderTest.testWithMoreThanOneWaitStrategyOneBeingFixed` 也把 `fibonacciWait(10, Long.MAX_VALUE, MILLISECONDS)` 放进 `join`。
- 同文件其他做算术的策略都有溢出或负值保护：Incrementing 和 Exponential 有 `result >= 0L ? result : 0L`，Fibonacci 有 `result < 0L → maximumWait`（`ce0bc7d`）。`WaitStrategiesTest` 在 `Integer.MAX_VALUE` 次尝试下断言结果饱和到上限。只有 `CompositeWaitStrategy`（`2b5bfec`，#12）没有这类保护。
- 站点附近没有 TODO 或 FIXME。
- 已知性检索（2026-11-26，`gh`）均无匹配：
  - `rholder/guava-retrying` 全部 61 个 issue 和 45 个 PR（含 2026-09-05 关闭的 PR #107），关键字包括 overflow、negative、"timeout value is negative"、IllegalArgumentException、composite、join、MAX_VALUE 等。#12 和 #17 引入了 `join`，但没有讨论溢出。
  - 两个 fork `rhuffman/re-retrying` 和 `itning/guava-retrying3` 也无匹配，而且两者仍是同样的裸加法。
  - persistent-findings lookup 返回 `[]`。

因此 Novelty 为 NEW。

## Reproduction result

- 命令：`timeout 10m bash .specular-output/repro/test_bugCR-D-16_join_sum_overflow.sh > .specular-output/repro/CR-D-16.log 2>&1`，退出码 0。
- 被测库：未修改的 `177b6c9b9f3e7957f404f0bdb8e23374cb1de43f`（dirty files 为 0），用 `javac --release 8` 编译，依赖 guava-22.0 和 jsr305-2.0.2（sha1 与 Maven Central 一致）。
- 同一个 driver 分别在 JDK 21.0.13.1 和 JDK 11.0.33.1 上运行。

JDK 21 的关键输出（原样摘录）：

```
Long.MAX_VALUE = 9223372036854775807;  Long.MAX_VALUE + 1000 (plain long add) = -9223372036854774809

--- C1 control: fixedWait(Long.MAX_VALUE, MILLISECONDS) alone (no join), default block strategy ---
  [C1] after watchdog: caller still inside call(), state=TIMED_WAITING, blocked in Thread.sleep=true
  [C1] call() threw: com.github.rholder.retry.RetryException: Retrying failed to complete successfully after 1 attempts.
  [C1]   RetryException.getLastFailedAttempt().getExceptionCause() = java.io.IOException: backend unavailable (invocation 1)
  [C1] caller interrupt status after call() = true, elapsed 1501 ms
  => [CONTROL OK] C1: caller sleeps; on interrupt -> documented RetryException(1 attempt, last failure kept), interrupt status set

--- B1 bug: join(fixedWait(Long.MAX_VALUE, MILLISECONDS), fixedWait(1, SECONDS)), default block strategy ---
  [B1] callable invocations = 1 (stop strategy allows 5)
  [B1] call() threw: java.lang.IllegalArgumentException: timeout value is negative
  [B1]     at java.base/java.lang.Thread.sleep(Thread.java:500)
  [B1]     at com.github.rholder.retry.BlockStrategies$ThreadSleepStrategy.block(BlockStrategies.java:46)
  [B1]     at com.github.rholder.retry.Retryer.call(Retryer.java:178)
  [B1]   thrown.getCause() = null
  [B1]   last callable failure reachable from the thrown exception: false
  [B1] caller interrupt status after call() = false, elapsed 0 ms
  => [BUG TRIGGERED] B1: call() escaped with IllegalArgumentException after 1 attempt instead of waiting (documented: total wait)

--- B1-diag: same join, recording wrapper around the built-in threadSleepStrategy ---
  [B1-diag] values passed to block(): [-9223372036854774809]  (expected total 9223372036854775807 + 1000, not representable)
  [B3] 20 runs: IllegalArgumentException=20, slept (jitter happened to be 0 ms)=0, other=0

--- C3 control: caller interrupted during attempt, fixedWait(Long.MAX_VALUE, MILLISECONDS) alone ---
  [C3] call() threw: com.github.rholder.retry.RetryException: Retrying failed to complete successfully after 1 attempts.
  [C3] caller interrupt status after call() = true, elapsed 301 ms
--- B4 bug: caller interrupted during attempt, join(fixedWait(Long.MAX_VALUE, MILLISECONDS), fixedWait(1, SECONDS)) ---
  [B4] call() threw: java.lang.IllegalArgumentException: timeout value is negative
  [B4] caller interrupt status after call() = true, elapsed 300 ms
  => [BUG TRIGGERED] B4: interrupted caller gets IllegalArgumentException, not the documented RetryException

  [B6] Future.get() -> ExecutionException cause = java.lang.IllegalArgumentException: timeout value is negative, callable invocations = 1

--- F1 expected behaviour: same components with a saturating sum (user-side WaitStrategy) ---
  [F1] after watchdog: caller still inside call(), state=TIMED_WAITING, blocked in Thread.sleep=true
  [F1] call() threw: com.github.rholder.retry.RetryException: Retrying failed to complete successfully after 1 attempts.
  => [CONTROL OK] F1: caller waits (Long.MAX_VALUE ms); interrupt -> RetryException(1 attempt, last failure kept), interrupt status set

SUMMARY (java 21.0.13.1): bug cases triggered 7/7; controls as documented 6/6
SUMMARY (java 11.0.33.1): bug cases triggered 7/7; controls as documented 6/6
FINAL: BUG REPRODUCED on all JDKs run
```

证明 bug 的行：
- B1、B2、B3、B5 的 `call() threw: java.lang.IllegalArgumentException: timeout value is negative`，栈为 `Thread.sleep ← BlockStrategies.java:46 ← Retryer.java:178`；
- B1-diag 显示组合策略返回 `-9223372036854774809`；
- B4 和 B5 在调用线程被中断时得到的是 IAE；
- B6 中通过 `wrap` 提交的任务以 IAE 失败。

与正确行为的对照：
- 同样的大分量单独使用（C1、C3），或同样的分量改用饱和求和（F1），调用线程都会正常进入等待；被中断后得到文档规定的 `RetryException`，带尝试次数和最后一次失败，中断标志置位。
- 非溢出的 `join`（C0、C2、C4）行为正确。

这说明缺陷确实在求和处。

## Recommendation

在 `CompositeWaitStrategy.computeSleepTime` 中改用饱和加法：

```java
long t = waitStrategy.computeSleepTime(failedAttempt);
waitTime = (t > 0 && waitTime > Long.MAX_VALUE - t) ? Long.MAX_VALUE : waitTime + t;
```

库声明支持 Guava `[10.+,)`，而 `LongMath.saturatedAdd` 只从 Guava 20 起才有，所以手写饱和加法更合适。同时补一个测试：`join(fixedWait(Long.MAX_VALUE, MILLISECONDS), fixedWait(1, SECONDS))` 应返回 `Long.MAX_VALUE`。

可以再加一层防御：在 `Retryer.call` 或 `ThreadSleepStrategy.block` 中把负的 `sleepTime` 截为 0。这对应下游的 MC-10，与本条的缺陷点不同。

用户侧的临时规避：用自定义的饱和 `WaitStrategy` 代替 `join`（即 F1 的做法）。

## Checklist

1. 是否仅靠 Level 0 或 Level 1 就触发了？**yes**。Level 0，只用公共 API：`WaitStrategies.join/fixedWait/exceptionWait/randomWait`、`RetryerBuilder`、`Retryer.call` 和 `Retryer.wrap`。bug case 用的是默认 block strategy，库未修改，没有时序辅助。
2. 没有用 Level 2 或 Level 3，不适用。
3. 看到错误结果的真实调用方：
   - 调用 `Retryer.call` 的应用代码（`Retryer.java:155`；IAE 从 `Retryer.java:178` 和 `BlockStrategies.java:46` 抛出）；
   - 经 `RetryerCallable.call`（`Retryer.java:317-319`）调用 `Future.get()` 的代码（B6）。
4. 结果是永久的，没有被掩盖。IAE 直接终止 `call()`，`Retryer.call` 和 `RetryerCallable` 中都没有任何捕获或兜底。同一配置每次都会复现（B1/B2/B4/B5/B6 每次都触发，B3 为 20/20）。
