# MC-5

Status: REPRODUCED
Run: guava-retrying-opus55max-20261126

running pwd && ls -la && git status 2>&1 | head -20; ls -la ..; ls -la ../..; find / -type d -name "bug-confirmation" 2>/dev/null | head -20
running ls -la /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation/*; ls -la...
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation && cat SKILL.md && echo ---------- && cat guide.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation && cat phases/01-investigation.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation && cat phases/02-reproduction.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation && cat references/persistent-findings.md && echo ------------ && cat references/repa...
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; ls -la $OUT; ls -la $OUT/confirmati...
running WT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-5/worktree; cd $WT &&...
running WT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-5/worktree; cat -n $W...
running SPEC=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec; ls -la $SPEC/output | grep -i...
running SPEC=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec; sed -n 1,60p $SPEC/output/hun...
running SPEC=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec; grep -n "^State\|^Error\|Inva...
running SPEC=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec; F=$SPEC/output/hunt_s2_interr...
running which gh && gh auth status 2>&1 | head -5; WT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-o...
running WT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-5/worktree; cd $WT &&...
running WT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-5/worktree; sed -n 37...
running cd /tmp && timeout 60 gh search issues --repo rholder/guava-retrying "interrupt" --limit 50 --json number,title,state,updatedAt,isPullRequest 2>&1 | head -80...
running cd /tmp && timeout 60 gh issue view 63 --repo rholder/guava-retrying --comments 2>&1 | head -60; echo =====; timeout 60 gh search prs --repo rholder/guava-re...
running cd /tmp && timeout 60 gh api repos/rholder/guava-retrying/issues/63 --jq '.title, .state, .body' 2>&1 | head -40; timeout 60 gh api repos/rholder/guava-retry...
running cd /tmp && timeout 120 gh api --paginate "repos/rholder/guava-retrying/issues?state=all&per_page=100" --jq '.[] | "\(.number)\t\(.state)\t\(if .pull_request...
running cd /tmp && for n in 67 107 100 101; do echo "########## #$n"; timeout 60 gh api repos/rholder/guava-retrying/issues/$n --jq '"\(.title) | state=\(.state) | c...
running cd /tmp && timeout 60 gh api repos/rholder/guava-retrying/commits?per_page=5 --jq '.[] | "\(.sha[0:7]) \(.commit.author.date[0:10]) \(.commit.message | split...
running cd /tmp && timeout 60 gh search issues "guava-retrying InterruptedException" --limit 20 --json repository,number,title,state,url 2>&1 | head -40; echo ====;...
running cd /tmp && for n in 36 32; do echo "########## re-retrying #$n"; timeout 60 gh api repos/rhuffman/re-retrying/issues/$n --jq '"\(.title) | state=\(.state) |...
running cd /tmp && echo "########## re-retrying #24"; timeout 60 gh api repos/rhuffman/re-retrying/issues/24 --jq '"\(.title) | state=\(.state) | created=\(.created_...
running cd /tmp && timeout 60 gh api repos/rhuffman/re-retrying/commits/f1ff0bfacb1c5b8bf370b32ce3dc366229db31dd --jq '.files[] | select(.filename|endswith("main/jav...
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; S=/home/ubuntu/guava-retrying-20261...
running ls ~/.m2/repository/com/google/guava/guava/ 2>/dev/null; find ~/.m2/repository -name "guava-22.0.jar" -o -name "jsr305-2.0.2.jar" -o -name "junit-4.11.jar" -...
Phase 1 证据已齐全（persistent-findings lookup 为空）。在写 `investigation.md` 之前，先核对 bfs1 反例（NoRetryAfterObservedInterrupt，11 states）以便准确引用。
running SPEC=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec; F=$SPEC/output/hunt_s2_interr...
反例与代码路径完全对应。现在写 `investigation.md`（Phase 1 证据记录）。
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-5/investigation.md
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/test_bugMC-5_callable_interrupt_retried.sh
running R=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro; chmod +x $R/test_bugMC-5_callab...
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/test_bugMC-5_callable_interrupt_retried.sh
running R=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro; cd $R && timeout 10m ./test_bug...
干净重跑通过（exit 0）。顺带用修复版的临时副本跑一遍上游现有的 36 个测试，确认推荐修复不破坏现有行为（只在 /tmp 中操作，不碰 worktree）。
running find ~/.m2/repository/org/mockito ~/.m2/repository/org/objenesis -name "*.jar" 2>/dev/null | head;
running set -e; WT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-5/worktree; M...
running S=/home/ubuntu/scratch/guava-retrying-src/guava-retrying; WT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retry...
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-5/issue.json
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; python3 -I -c "import json,sys; d=j...
`issue.json` 校验通过（`"valid": true`，所有边界行在 source 根中唯一精确匹配）。最后取一下干净日志的头部，用于引用。
running R=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro; sed -n 1,5p $R/MC-5.log; grep -...
## MC-5 确认结果：REPRODUCED（Level 0）

- **Source**: MC
- **Novelty**: KNOWN (cite: https://github.com/rhuffman/re-retrying/issues/32; fix-status: unfixed)
- **Location**: src/main/java/com/github/rholder/retry/Retryer.java:162
- **Severity**: High
- **Status**: REPRODUCED
- **Reproduction test**: `.specular-output/repro/test_bugMC-5_callable_interrupt_retried.sh`（Level 0），输出在 `.specular-output/repro/MC-5.log`

## Description
不配置时间限制时（`RetryerBuilder.build()` 的默认行为，`RetryerBuilder.java:191`），callable 直接在调用线程上执行（`AttemptTimeLimiters.java:78`）。调用线程在 callable 阻塞期间被中断时，JDK 会清掉中断位，并让 callable 抛出 `InterruptedException`。`Retryer.call` 的 `catch (Throwable t)`（`Retryer.java:162-163`）把这个异常当成一次普通的失败尝试，没有恢复中断位。只要谓词匹配这个异常（例如 `retryIfException()`），就会进入下一次尝试。代码里唯一的中断保护在 `Retryer.java:179-181`，只处理等待期间抛出的 `InterruptedException`；这里中断位已经被清掉，`Thread.sleep` 不会抛异常，所以这道保护不会触发。最终 `call()` 会正常返回，或者在新一次尝试里继续阻塞，中断信号就此丢失。

## Trigger scenario
对应反例 `hunt_s2_interrupt_nolimit_bfs2.out` 的 16 个状态（bfs1 是前 11 个状态）：
1. `MCCallStart`：线程 T 调用 `retryer.call(callable)`。retryer 配置为 `retryIfException()` 加 `stopAfterAttempt(5)`，其余用默认的 `noTimeLimit`、`noWait`、`Thread.sleep`。
2. `MCCallerBodyStart("IntrBlock")`：第 1 次尝试阻塞在 `queue.take()`。
3. `MCInterrupt`：T 被中断。实际场景可以是 `Thread.interrupt`、`Future.cancel(true)` 或 `shutdownNow()`。
4. `MCCallerBodyThrows`：callable 抛出 `InterruptedException`，中断位被清掉。
5. `MCWaitStrategyComputes("Zero")` → `MCBlockZero`：`Thread.sleep(0)` 不抛异常，开始第 2 次尝试。这一步违反 `NoRetryAfterObservedInterrupt`。
6. `MCCallerBodyReturns` → `MCPredicateAccepts`：`call()` 正常返回，中断位仍是清空状态。这一步违反 `InterruptPreserved`。

## Developer intent
- `Retryer.java:151-153` 写明：线程被中断时会抛 `RetryException`，并且线程的中断位会被设置（"if the thread is interrupted, this exception is thrown and the thread's interrupt status is set"）。
- `Retryer.java:59-61` 写明：被拒绝的尝试会重试，除非 stop 策略要求停止或线程已被中断（"will retry the call, unless the stop strategy indicates otherwise or the thread is interrupted"）。
- 现有测试 `RetryerBuilderTest.java:384-414` `testInterruption` 只覆盖了在等待期间被中断的情况，断言 `RetryException` 加 `isInterrupted()`。没有测试覆盖 callable 执行期间被中断。
- 上游 `rholder/guava-retrying` 的全部 106 个 issue/PR（包括最近关闭的 #84、#107）都没有报告这个机制。#67 是同一处 catch，但讲的是 `Error`，不是同一个问题。
- 上游 #81 指认的硬 fork `rhuffman/re-retrying`（同一个文件 `com/github/rholder/retry/Retryer.java`）在 #32 和 #36 报告过这个机制，fork 维护者回复 "I agree"。该 fork 用 PR #37（commit `f1ff0bf`，在 `catch (Throwable)` 前加 `catch (InterruptedException e) { throw e; }`）修复了，但从未合回上游。上游 HEAD `177b6c9` 仍然是原来的代码。

## Reproduction result
运行命令：`cd .specular-output/repro && timeout 10m ./test_bugMC-5_callable_interrupt_retried.sh 50 > MC-5.log 2>&1`，退出码为 0。

- 测试只用公开 API。库源码取自 worktree `177b6c9`，未作改动（dirty files: 0），用 `javac --release 8` 加 Guava 22.0 编译。
- 测试会等调用线程确实停在 `LinkedBlockingQueue.take()` 之后再发出中断。这只是测试侧的编排，库代码里没有加任何 sleep 或 hook。

下面是 JDK 21 上原版库的输出（JDK 11 结果相同）：
```
java.version=21.0.13.1; Retryer from file:/tmp/mc5-repro.wYRVn2/lib-pristine/
  A: listener log = [attempt#1=exception:java.lang.InterruptedException (interrupt status seen by listener=false), attempt#2=result:value-for-attempt-2 (interrupt status seen by listener=false)]
  A: attempt 2 started after the interrupt = true
  A: outcome = call() returned normally: "value-for-attempt-2"
  A: Thread.currentThread().isInterrupted() right after call() = false
  A: total attempts = 2 -> BUG_TRIGGERED
SCENARIO A (MC trace bfs1/bfs2): BUG_TRIGGERED in 50/50 runs; CONTRACT_HELD in 0/50; OTHER 0
  B: shutdownNow() -> 0 never-run tasks; isShutdown=true; awaitTermination(2s)=false
  B: attempts after shutdownNow = 2; worker state=WAITING; worker parked in take() again=true
  B: after offering a value: Future.get() returned normally: "late-value"; awaitTermination(5s)=true; total attempts=2
SCENARIO B (ExecutorService.shutdownNow consumer): BUG_TRIGGERED
  C: outcome=ExecutionException(cause=java.lang.InterruptedException); interrupt status after call()=false; attempts=1
SCENARIO C (no retry, status still lost): BUG_TRIGGERED
  D: outcome=RetryException(numberOfFailedAttempts=1, cause=java.io.IOException: transient failure #1); interrupt status after call()=true; attempts=1
CONTROL D (interrupt during wait, Retryer.java:179-181): CONTRACT_HELD
...
RESULT: MC-5 REPRODUCED (Level 0) on the unmodified library; fix control restores the documented contract
```

**哪几行证明了 bug：**
- **场景 A：** 第 2 次尝试在中断之后才开始；`call()` 正常返回 `"value-for-attempt-2"`；返回后 `isInterrupted()` 为 `false`。50 次运行全部如此，与 bfs1/bfs2 的动作序列和两个被违反的 invariant 一致。按文档，正确行为应是抛 `RetryException` 且中断位被设置。
- **场景 B：** 这是一个真实的使用方：`retryer.wrap(callable)` 提交到 JDK 线程池。`shutdownNow()` 之后 `awaitTermination(2s)=false`，worker 又阻塞在第 2 次尝试里。等数据到达后，这个已经被 `shutdownNow` 的任务反而正常完成，返回了 `"late-value"`。
- **场景 C（补充）：** 同一个 catch-all，谓词不匹配时不会重试，但中断位同样丢失，抛出的是 `ExecutionException` 而不是 `RetryException`。
- **对照 D：** 在等待期间中断时，库自带的保护正确生效。这说明测试能区分正确与错误行为。

**修复对照组：** 只在临时副本中改动 `Retryer.java`，加 4 行（见下）。改后 A 为 `BUG_TRIGGERED in 0/50 runs; CONTRACT_HELD in 50/50`，B、C、D 都是 `CONTRACT_HELD`。上游现有的 36 个测试在原版和修复版上都是 `OK (36 tests)`。

## Recommendation
在 `Retryer.call` 里，通知完 listener 之后、执行 rejection predicate 之前，加入以下检查：
```java
if (attempt.hasException() && attempt.getExceptionCause() instanceof InterruptedException) {
    Thread.currentThread().interrupt();
    throw new RetryException(attemptNumber, attempt);
}
```
- 这样能兑现 Javadoc 的约定：抛 `RetryException`，并恢复中断位。
- 不需要改 `call()` 的签名。fork 的做法是直接重新抛出 `InterruptedException`，那需要改 API。
- 改动放在 `Retryer.call` 这一层，所以任何经由 `attemptTimeLimiter.call` 到达这个 catch 的 `InterruptedException` 都会被覆盖，与使用哪种 time limiter 无关。
- 另外建议补一个回归测试：callable 执行期间中断调用线程。

## Checklist
1. **只用 Level 0 或 Level 1 就触发了吗？** 是。纯 Level 0：真实公开 API，库代码未改动，也没有任何时序辅助。
2. 不适用。没有用到 Level 2 或 Level 3。
3. **哪个真实使用方看到了错误结果？**
   - `Retryer.call` 的调用方（`Retryer.java:155`）：得到正常返回值，中断位却已清空。
   - 库自己的线程池入口 `Retryer.RetryerCallable.call()`（`Retryer.java:317-318`），配合 JDK 的 `ThreadPoolExecutor.shutdownNow()`/`awaitTermination`：`awaitTermination(2s)=false`，任务最后正常完成。
4. **坏状态是永久的吗？** 是。中断位被 JDK 清掉后，没有任何机制把它恢复。唯一的保护 `Retryer.java:179-181` 只作用于等待阶段（对照 D 已证明），这条路径上不会触发。不存在掩盖后果的机制。

产出文件：`confirmation/MC-5/investigation.md`、`confirmation/MC-5/issue.json`（`specular findings validate` 结果为 `"valid": true`）、`repro/test_bugMC-5_callable_interrupt_retried.sh`、`repro/MC-5.log`。

## Repair round 1 evidence
<!-- specular-repair-token: 3eefa76b5b37ed587e41b6cbdb823026 -->
- **Current violation analysis**: With noTimeLimit the callable runs on the caller thread (AttemptTimeLimiters.java:77-78). If that thread is interrupted while the callable is in an interruptible blocking call, the callable throws InterruptedException and the status is cleared; Retryer.call records it as an ordinary failed attempt (Retryer.java:162-163) and, with a predicate that matches it, retries. TLC: attempt 2 starts after the interrupt was observed (hunt_s2_interrupt_nolimit_bfs1.out, 11 states) and call() returns normally with the status clear (hunt_s2_interrupt_nolimit_bfs2.out, 16 states), contradicting Retryer.java:…
- **Counterexample**: `spec/output/hunt_s2_interrupt_nolimit_bfs2.out`

## Phase 4 confirmation after repair round 1

running pwd; ls -la; find / -type d -name "bug-confirmation" 2>/dev/null | head -20
running ls -la ~/.claude/skills 2>/dev/null; ls -la /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; find /home/ubuntu/guava-retrying-20261126/...
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; cat SKILL.md; echo ======; cat guide.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; cat phases/01-investigation.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; cat phases/02-reproduction.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; cat references/repair-request-format.md; echo =====; cat references/persistent-find...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-5; ls -la; echo ====;...
正在读取 MC-5 现有的证据（verdict.json、investigation.md、debate.md、issue.json），然后在此基础上继续，不从头重做。
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-5; python3 -I -c " im...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-5; cat investigation....
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; cat confirmation/MC-5/issue.json; ec...
先核对当前状态：worktree 源码是否仍是 `177b6c9` 且未改动、反例文件是否在上一轮确认之后被重新生成、上一轮的复现脚本内容。
running WT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-5/worktree; cd $WT &&...
running WT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-5/worktree/src/main/j...
源码与上一轮引用的行号完全一致（`177b6c9`，无改动）。接下来核对当前反例 `bfs2.out` 的违反 invariant 与动作序列是否仍与上一轮记录一致。
running SPEC=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec; for f in bfs1 bfs2; do F=$SPE...
running SPEC=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec; F=$SPEC/output/hunt_s2_interr...
reading /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/test_bugMC-5_callable_interrupt_retried.sh
复现脚本是纯 Level 0、自包含，且只读取 worktree。先确认脚本哈希与上一轮 verdict 记录一致，然后在外层 `timeout` 下重新执行。
running R=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro; sha256sum $R/test_bugMC-5_calla...
running R=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro; W=/home/ubuntu/guava-retrying-2...
running WT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-5/worktree; B=$WT/src...
running cd /tmp && timeout 60 gh api repos/rholder/guava-retrying/commits?per_page=3 --jq '.[] | "\(.sha[0:7]) \(.commit.committer.date) \(.commit.message | split("\...
running SPEC=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec; F=$SPEC/output/hunt_s2_interr...
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-5; diff $W/.MC-5.round...
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-5; R=/home/ubuntu/guav...
reading /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-5/investigation.md
running ls ~/.m2/repository/com/google/guava/guava/22.0/; cd /tmp && J=~/.m2/repository/com/google/guava/guava/22.0/guava-22.0.jar; javap -c -p -cp $J com.google.com...
running WT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-5/worktree; grep -n "...
Now append this round's check record to `investigation.md` (existing content kept as-is):
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-5/investigation.md
Re-validating `issue.json` (dependency boundary lines and evidence files):
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; which specular; python3 -I -c "impo...
`specular` isn't on PATH; looking for the CLI entry point the previous round used:
running ls /home/ubuntu/guava-retrying-20261126/Specular/ | head -40; ls /home/ubuntu/guava-retrying-20261126/Specular/.venv/bin 2>/dev/null | grep -i specul; find /...
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; SP=/home/ubuntu/guava-retrying-2026...
## MC-5 确认结果（修复循环第 1 轮续查）：REPRODUCED（Level 0）

- **Source**: MC
- **Novelty**: KNOWN (cite: https://github.com/rhuffman/re-retrying/issues/32; fix-status: unfixed)
- **Location**: src/main/java/com/github/rholder/retry/Retryer.java:162
- **Severity**: High
- **Status**: REPRODUCED
- **Reproduction test**: `.specular-output/repro/test_bugMC-5_callable_interrupt_retried.sh`（Level 0），输出在 `.specular-output/repro/MC-5.log`

**本轮结论：** 上一轮的 REPRODUCED 结论成立，复现结果与上一轮一致。具体核查了以下几点：
- worktree 仍是 `177b6c9`，没有改动，所有引用的行号都没变。
- Phase 3 本轮给出的反例还是 `hunt_s2_interrupt_nolimit_bfs2.out`，内容与上一轮相同。
- 复现脚本没改（sha256 `931e9f43…`），重新执行的结果与上一轮相同。
- 上游 HEAD 仍是 `177b6c9`，没有新的修复或报告。

**需要更正的一处：** 上一轮正文把 bfs1 的 `NoRetryAfterObservedInterrupt` 违反写在了 `MCBlockZero` 这一步。实际违反发生在 bfs1 的 state 11 `MCCallerBodyStart(c1,"Ret")`：从 state 10 到 11，变量 `made` 由 1 变 2，也就是第 2 次 callable 真正开始执行。`MCBlockZero`（state 10）只是把 `attemptNo` 加到 2。`investigation.md` 原本写的就是对的，本轮追加了一节记录这次核查和更正。

## Description
不配置时间限制是 `RetryerBuilder.build()` 的默认行为（`RetryerBuilder.java:191`）。这时 callable 直接在调用线程上运行（`AttemptTimeLimiters.java:78`）。

如果调用线程在 callable 阻塞期间被中断，JDK 会清掉中断位并抛出 `InterruptedException`。`Retryer.call` 的 `catch (Throwable t)`（`Retryer.java:162-163`）把它当作一次普通的失败尝试，不恢复中断位。只要谓词匹配这个异常（例如 `retryIfException()`），就会继续重试。

唯一的中断保护在 `Retryer.java:179-181`，但它只处理等待阶段抛出的异常。此时中断位已经被清掉，`Thread.sleep` 不会抛异常，这道保护不会触发。结果是 `call()` 正常返回下一次尝试的值，中断信号就此丢失。

## Trigger scenario
下面按反例 `hunt_s2_interrupt_nolimit_bfs2.out`（16 个状态，违反 `InterruptPreserved`）的顺序列出。复现中的场景 A 逐步对应这些状态。

1. **state 2 `MCCallStart`：** 线程 T 调用 `retryer.call(callable)`。retryer 配置为 `retryIfException()` 加 `stopAfterAttempt(5)`，其余用默认的 `noTimeLimit`/`noWait`/`Thread.sleep`。
2. **state 3 `MCCallerBodyStart("IntrBlock")`：** 第 1 次尝试在调用线程上阻塞于 `queue.take()`。
3. **state 4 `MCInterrupt`：** T 被中断（`intr[c1]=TRUE`，`intrDelivered=TRUE`）。现实中可以来自 `Thread.interrupt`、`Future.cancel(true)` 或 `shutdownNow()`。
4. **state 5 `MCCallerBodyThrows`：** callable 抛出 `InterruptedException`（`curTag="CallableIE"`），JDK 清掉中断位（`intr[c1]=FALSE`）。`Retryer.java:162-163` 把它记成 `ExceptionAttempt`。
5. **state 6–10（listener → `MCWaitStrategyComputes("Zero")` → `MCBlockZero`）：** `Thread.sleep(0)` 不抛异常，`attemptNo` 变为 2。
6. **state 11 `MCCallerBodyStart("Ret")`：** 第 2 次 callable 开始执行，bfs1 在这一步违反 `NoRetryAfterObservedInterrupt`。
7. **state 12–16（返回 → listener → `MCPredicateAccepts`）：** `outcome="Returned"` 且 `intr[c1]=FALSE`，违反 `InterruptPreserved`。

## Developer intent
**文档约定：**
- `Retryer.java:151-153`："if the thread is interrupted, this exception [RetryException] is thrown and the thread's interrupt status is set"。
- `Retryer.java:59-61`："the retryer will retry the call, unless the stop strategy indicates otherwise or the thread is interrupted"。

**现有测试：** `RetryerBuilderTest.java:384-414` `testInterruption` 只覆盖在等待阶段被中断的情况，断言抛出 `RetryException` 且 `isInterrupted()` 为 true。没有测试覆盖 callable 执行期间被中断。

**上游 `rholder/guava-retrying`：** 没有任何 issue/PR 报告过这个机制。本轮重新查过：HEAD 仍是 `177b6c9`，最近更新的 #84、#107 都无关，搜索 "interrupt" 只命中无关的 #63。

**硬 fork `rhuffman/re-retrying`：** 这是上游 #81 里宣布的 fork，代码与上游是同一个文件。fork 的 #32 和 #36 报告了同一个机制，fork 维护者回复 "I agree"。fork 用 PR #37（commit `f1ff0bf`）修掉了，但从未合回上游，所以目标仓库里 fix-status 是 unfixed。

## Reproduction result
运行命令：`cd .specular-output/repro && timeout 10m ./test_bugMC-5_callable_interrupt_retried.sh 50`，退出码为 0，输出保存在 `repro/MC-5.log`。测试只用公开 API，库源码未改动，也没有加任何时序辅助。

```
== MC-5 repro: 2026-11-26T16:43:54Z
== library source: /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/../confirmation/MC-5/worktree (git HEAD: 177b6c9; dirty files: 0)
== Retryer.java sha256: 62e792c48a5fc9d5
==================== pristine-jdk-default
java.version=21.0.13.1; Retryer from file:/tmp/mc5-repro.HpabYp/lib-pristine/
  A: listener log = [attempt#1=exception:java.lang.InterruptedException (interrupt status seen by listener=false), attempt#2=result:value-for-attempt-2 (interrupt status seen by listener=false)]
  A: attempt 2 started after the interrupt = true
  A: outcome = call() returned normally: "value-for-attempt-2"
  A: Thread.currentThread().isInterrupted() right after call() = false
  A: total attempts = 2 -> BUG_TRIGGERED
SCENARIO A (MC trace bfs1/bfs2): BUG_TRIGGERED in 50/50 runs; CONTRACT_HELD in 0/50; OTHER 0
  B: shutdownNow() -> 0 never-run tasks; isShutdown=true; awaitTermination(2s)=false
  B: attempts after shutdownNow = 2; worker state=WAITING; worker parked in take() again=true
  B: after offering a value: Future.get() returned normally: "late-value"; awaitTermination(5s)=true; total attempts=2
SCENARIO B (ExecutorService.shutdownNow consumer): BUG_TRIGGERED
  C: outcome=ExecutionException(cause=java.lang.InterruptedException); interrupt status after call()=false; attempts=1
SCENARIO C (no retry, status still lost): BUG_TRIGGERED
  D: outcome=RetryException(numberOfFailedAttempts=1, cause=java.io.IOException: transient failure #1); interrupt status after call()=true; attempts=1
CONTROL D (interrupt during wait, Retryer.java:179-181): CONTRACT_HELD
==================== summary
 pristine library (pristine-jdk11):
  [ok]   A: interrupted attempt retried, call() returned normally, status clear (50/50)
  [ok]   B: shutdownNow() could not stop the task; it was retried and completed normally
 fix control (temp copy with the 4-line fix):
  [ok]   A: RetryException + status set (50/50)
  [ok]   B: shutdownNow() terminates the task
  [ok]   C: RetryException + status set
  [ok]   D: unchanged

RESULT: MC-5 REPRODUCED (Level 0) on the unmodified library; fix control restores the documented contract
```

**各场景的含义：**
- **场景 A** 对应反例 bfs1/bfs2：中断之后开始了第 2 次尝试，`call()` 正常返回，中断位为 `false`。JDK 21 和 JDK 11 下都是 50/50。按文档，应当抛出 `RetryException` 并设置中断位。
- **场景 B** 是一个真实使用方：`retryer.wrap(callable)` 提交到 JDK 线程池后调用 `shutdownNow()`，任务没有停下来，最后反而正常完成。
- **场景 C：** 谓词不匹配 `InterruptedException` 时不会重试，但中断位同样丢失。
- **对照 D：** 在等待阶段中断时，库自带的保护正确生效，说明测试能区分正确和错误行为。
- **修复对照组：** 4 行修复让 A、B、C 全部回到文档约定的行为。

## Recommendation
在 `Retryer.call` 中，通知完 listener 之后、执行 rejection predicate 之前加入：
```java
if (attempt.hasException() && attempt.getExceptionCause() instanceof InterruptedException) {
    Thread.currentThread().interrupt();
    throw new RetryException(attemptNumber, attempt);
}
```
- 这样能兑现 Javadoc 的约定，而且不用改 `call()` 的签名。
- 同时补一个回归测试：callable 执行期间中断调用线程。
- 有时间限制时，这个检查会把 worker 线程上的中断也当成调用线程被中断。原因是 Guava 22 的 `callWithTimeout` 会通过 `throwCause(e, true)` 把 worker 的 `InterruptedException` 原样抛回来（`AttemptTimeLimiters.java:107`）。fork 的修复也是同样的行为。如果要严格区分这两种中断，可以把这个检查限定在 `NoAttemptTimeLimit` 路径上。

## Checklist
1. **只用 Level 0 或 Level 1 就触发了吗？** 是。纯 Level 0：真实公开 API，库代码未改动，没有任何时序辅助。
2. 不适用，没有用到 Level 2 或 Level 3。
3. **哪个真实使用方看到了错误结果？**
   - `Retryer.call` 的调用方（`Retryer.java:155`）：得到正常返回值，中断位却已清空。
   - `Retryer.wrap` 产生的 `RetryerCallable.call()`（`Retryer.java:317-318`）提交给 JDK `ThreadPoolExecutor` 的使用方：`shutdownNow()` 之后 `awaitTermination(2s)=false`，任务最后正常完成并返回 `"late-value"`。
4. **坏状态是永久的吗？** 是。中断位被 JDK 清掉后，没有任何机制把它恢复。唯一的保护 `Retryer.java:179-181` 只作用于等待阶段，对照 D 已经证明了这一点，它在这条路径上不会触发。不存在掩盖后果的机制。

本轮写入的文件：
- `confirmation/MC-5/investigation.md`：追加了 Repair round 1 一节。
- `repro/MC-5.log`：替换为本轮的运行输出。
- `confirmation/MC-5/issue.json`：内容未改，`specular findings validate` 返回 `"valid": true`。
