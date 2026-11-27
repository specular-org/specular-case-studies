# Confirmation Report — guava-retrying

## Final Result

Reproduced bugs: 19 = 15 NEW + 4 KNOWN-unfixed + 0 KNOWN-fixed + 0 UNKNOWN
Masked live findings: 1
Env-limited findings: 0
False positives: 3
Dropped: 2
Needs more info: 0
Pending repair: 0
Incomplete: 0
Deferred: 0
Total disposition entries: 25
Dispositions: 25 total = 19 reproduced + 0 env-limited + 1 masked + 3 false-positive + 0 needs-more-info + 2 dropped + 0 pending-repair + 0 incomplete + 0 deferred

| Entry | Finding | Status | Counts as final bug? |
|---|---|---|---|
| 1 | MC-1 | REPRODUCED | yes |
| 2 | MC-2 | REPRODUCED | yes |
| 3 | MC-3 | FALSE POSITIVE | no |
| 4 | MC-4 | REPRODUCED | yes |
| 5 | MC-5 | REPRODUCED | yes |
| 6 | MC-6 | REPRODUCED | yes |
| 7 | MC-7 | REPRODUCED | yes |
| 8 | MC-8 | FALSE POSITIVE | no |
| 9 | MC-9 | REPRODUCED | yes |
| 10 | MC-10 | REPRODUCED | yes |
| 11 | MC-11 | REPRODUCED | yes |
| 12 | MC-12 | REPRODUCED | yes |
| 13 | CR-D-11 | REPRODUCED | yes |
| 14 | CR-D-12 | REPRODUCED | yes |
| 15 | CR-D-13 | REPRODUCED | yes |
| 16 | CR-D-15 | DROPPED | no |
| 17 | CR-D-16 | REPRODUCED | yes |
| 18 | CR-D-17 | REPRODUCED | yes |
| 19 | CR-D-18 | REPRODUCED | yes |
| 20 | CR-D-19 | REPRODUCED | yes |
| 21 | CR-D-20 | REPRODUCED | yes |
| 22 | CR-D-21 | MASKED | no |
| 23 | CR-D-22 | REPRODUCED | yes |
| 24 | CR-D-23 | DROPPED | no |
| 25 | CR-5 | FALSE POSITIVE | no |

## Entry 1: A timed-out attempt keeps running alongside later attempts and after `call()` has returned or thrown

- **Finding ID**: MC-1
- **Status**: REPRODUCED
- **Debate**: not run
- **Transcript**: /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-1/debate.md

running ls -la /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-1/ ; ls -la /home...
running ls -la ~/.claude/skills/ 2>/dev/null; ls -la /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation /home/ubuntu/guava-retrying-20261126/Specu...
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation && cat SKILL.md && echo ===== && cat guide.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation && cat phases/01-investigation.md && echo ===== && cat phases/02-reproduction.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation && cat references/persistent-findings.md && echo ===== && cat references/repair-requ...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output && cat persistent-findings-context.js...
running ls /home/ubuntu/guava-retrying-20261126/Specular/; ls /home/ubuntu/guava-retrying-20261126/Specular/bin 2>/dev/null; find /home/ubuntu/guava-retrying-2026112...
正在按 bug-confirmation skill 执行 MC-1：已读完 guide 和两个 phase 文档，接下来先查 persistent-findings 注册表，然后做 Phase 1 代码审计。
running cd /home/ubuntu/guava-retrying-20261126/Specular && file specular && head -30 specular; W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-o...
running cd /home/ubuntu/guava-retrying-20261126/Specular && W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.sp...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-1/worktree && git sta...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-1/worktree && cat -n...
running ls /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/ ; ls /home/ubuntu/scratch/guava-retrying-src/guava-re...
running find / -name "SimpleTimeLimiter.java" -path "*22*" 2>/dev/null | head; ls /home/ubuntu/scratch/ ; ls /home/ubuntu/scratch/guava22-sources-dl/
running cat -n /home/ubuntu/scratch/guava22-sources-dl/extracted/com/google/common/util/concurrent/SimpleTimeLimiter.java | sed -n 1,260p; cat /home/ubuntu/scratch/g...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec && ls output/ | grep -E "hunt_s1...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec && sed -n 1,60p output/hunt_s1_o...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec && sed -n 318,366p output/hunt_s...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec && grep -n -E "^State [0-9]+:|Er...
running which gh && gh auth status 2>&1 | head -5; timeout 60 gh api repos/rholder/guava-retrying --jq '{full_name, open_issues_count, pushed_at, updated_at}' 2>&1 |...
running cd /tmp && timeout 120 gh api --paginate "repos/rholder/guava-retrying/issues?state=all&per_page=100" --jq '.[] | [.number, (if .pull_request then "PR" else...
running cd /tmp && for n in 1 18 29 92 94 96; do echo "=================== #$n"; timeout 60 gh api repos/rholder/guava-retrying/issues/$n --jq '"TITLE: \(.title)\nST...
running cd /tmp && for n in 100 107 103 95 81 65 69 35; do echo "=================== #$n"; timeout 60 gh api repos/rholder/guava-retrying/issues/$n --jq '"TITLE: \(....
running cd /tmp && for q in "cancel" "still running" "interrupt" "keeps running" "concurrently" "parallel" "callWithTimeout" "SimpleTimeLimiter" "thread leak" "timeo...
running cd /tmp && for n in 12 63; do echo "=================== #$n"; timeout 60 gh api repos/rholder/guava-retrying/issues/$n --jq '"TITLE: \(.title)\nBODY:\n\(.bod...
running sed -n 30,104p /home/ubuntu/scratch/guava22-sources-dl/extracted/com/google/common/util/concurrent/TimeLimiter.java
running cd /tmp && for repo in rhuffman/re-retrying itning/guava-retrying3; do echo "######## $repo"; timeout 60 gh api "repos/$repo" --jq '{full_name, open_issues_c...
running cd /tmp && timeout 90 gh api --paginate "repos/itning/guava-retrying3/issues?state=all&per_page=100" --jq '.[] | select(.number < 36) | [.number, (if .pull_r...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-1/worktree && git log...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-1/worktree && git sho...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-1/worktree && sed -n...
running ls -la /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/; ls /home/ubuntu/scratch/g...
running cat /home/ubuntu/scratch/guava-retrying-build/pom.xml | head -80; sha1sum /home/ubuntu/.m2/repository/com/google/guava/guava/22.0/guava-22.0.jar /home/ubuntu...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-1/worktree && diff -r...
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-1/investigation.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-1/worktree && sed -n...
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/test_bugMC-1_timed_out_attempt_overlap.sh
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output && chmod +x repro/test_bugMC-1_timed_...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output && tail -20 confirmation/MC-1/repro-o...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro && python3 - <<'EOF' import re...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output && timeout 5m ./repro/test_bugMC-1_ti...
JDK 21 上 3/3 轮全部复现，`noTimeLimit` 对照组 0/3 无异常。再在 JDK 11 上跑一遍（JDK 11 用的是旧的 socket 实现），排除 JDK 版本相关性。
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output && JAVA_BIN=/usr/lib/jvm/java-11-open...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output && sed -n 1,75p confirmation/MC-1/rep...
running cd /home/ubuntu/guava-retrying-20261126/Specular/src/specular && grep -rn -l "def.*validate\|\"root\"" --include=*.py . | head; grep -rn "root" --include=*.p...
running cd /home/ubuntu/guava-retrying-20261126/Specular/src/specular && sed -n 1,140p persistent_findings.py
running cd /home/ubuntu/guava-retrying-20261126/Specular/src/specular && sed -n 140,420p persistent_findings.py
running cd /home/ubuntu/scratch/guava-retrying-src/guava-retrying/src/main/java/com/github/rholder/retry && for pat in ' public V call(Callable<V> callable) throws E...
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-1/issue.json
running cd /home/ubuntu/guava-retrying-20261126/Specular && W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.sp...
`issue.json` 校验通过（title 139 字符）。最后确认一下没有残留进程，再核对产物。
running pgrep -af MC1Repro || echo "no leftover MC1Repro processes"; ls /tmp | grep -c mc1-repro || true; ls -la /home/ubuntu/guava-retrying-20261126/Specular/runs/g...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-1 && sha1sum repro-ou...
MC-1 已确认为真实 bug，我在未修改的库上用 Level 0（只走公开 API）复现了它。JDK 21 和 JDK 11 下五个 bug 场景各 3/3 轮触发，`noTimeLimit` 对照组 0/3。

- **Source**: MC
- **Novelty**: NEW
- **Severity**: High
- **Location**: src/main/java/com/github/rholder/retry/AttemptTimeLimiters.java:107
- **Reproduction test**: `.specular-output/repro/test_bugMC-1_timed_out_attempt_overlap.sh`（Level 0）
- **Persistent record**: `confirmation/MC-1/issue.json`（`specular findings validate` 返回 `valid: true`）；Phase 1 证据见 `confirmation/MC-1/investigation.md`

## Description
`FixedAttemptTimeLimit.call`（`AttemptTimeLimiters.java:107`）调用的是 Guava 22.0 的 `SimpleTimeLimiter.callWithTimeout(callable, d, u, true)`。超时或调用线程被 interrupt 时，Guava 只做 `future.cancel(true)` 就立即抛出（`SimpleTimeLimiter.java:155-157`、`:164-166`），不等 worker 线程结束。`Retryer.call` 把这当成一次普通的失败 attempt，随即在另一个 pool 线程上用同一个 `Callable` 实例开始下一次 attempt（`Retryer.java:157-160`），或者直接返回/抛出（`:171`、`:174`）。被取消的那次 attempt 从此没人跟踪。

如果 callable 不响应 interrupt（例如平台线程上阻塞的 `java.net.Socket` 读），会出现三种后果：
- 同一次 `call()` 的几个 attempt 同时在跑；
- `call()` 已经返回或抛出，旧 attempt 还在运行；
- 旧 attempt 的结果或异常被静默丢弃，但它的副作用要到 `call()` 结束之后才发生。

## Trigger scenario
**S1：超时触发**（对应 `hunt_s1_overlap_bfs1.out` / `bfs2.out`）
1. 用 `fixedTimeLimit(300 ms)`、`retryIfRuntimeException()`、`stopAfterAttempt(3)` 构建 Retryer，调用 `call(task)`。`task` 通过阻塞 socket 读取一个值，再写进应用缓存。
2. attempt 1 在 `pool-1-thread-1` 上阻塞在 socket 读，服务端 1500 ms 后才响应。
3. 300 ms 时 `future.get` 超时。`cancel(true)` 确实 interrupt 了 worker，但 socket 读不理会，`UncheckedTimeoutException` 被立即抛出。
4. listener 收到 attempt #1 失败后，attempt 2 马上在 `pool-1-thread-2` 进入同一个 callable，此时 attempt 1 还在运行。这违反了 `SequentialAttempts`。
5. attempt 2 拿到 `VALUE-2`，`call()` 返回 `VALUE-2`，attempt 1 仍在执行。约 1.16 s 后 attempt 1 返回 `VALUE-1`：这个返回值被丢弃，但它写缓存的副作用把缓存改回了 `VALUE-1`。这违反了 `NoActivityAfterOutcome`。
6. 如果 stop strategy 先触发：`call()` 抛 `RetryException` 时，3 个 attempt 都还在运行（场景 B）。

**S2：调用方 interrupt 触发**（对应 `hunt_s2_interrupt_narrow_bfs3.out`）
- attempt 1 运行期间 interrupt 调用线程。Guava 在 `:155-157` 执行 cancel 并重抛 `InterruptedException`，`Retryer.java:162-163` 把它包装成失败 attempt。
- `retryIfRuntimeException` 不拒绝这个 attempt，于是 `Retryer.java:171` 抛出 `ExecutionException(InterruptedException)`，而 attempt 1 还在运行（场景 C）。
- 如果改用 `retryIfException`，下一次 attempt 会和 attempt 1 重叠（场景 C2）。

## Developer intent
**文档怎么说**
- `Retryer` 类 Javadoc（`Retryer.java:31-35`）和 `call()` Javadoc（`:141-144`）描述的都是一个顺序循环："retries it until it succeeds, or a stop strategy decides to stop retrying"，以及 "Then the wait strategy is used … and a new attempt is made"。
- `RetryerBuilder.java:113` 写的是 "limit the duration of any particular attempt"。构造器参数说明是 "to prevent from any single attempt from spinning infinitely"。
- 唯一的保留说法是 `AttemptTimeLimiter.java:22` 的 "will possibly be interrupted"，以及 Guava `TimeLimiter` 文档里的 "aborting the target method call is of secondary concern"。这只承认 interrupt 可能没效果，并没有说 Retryer 会在旧 attempt 还在跑时开始新 attempt，也没有说 `call()` 返回后 attempt 还可能继续运行、结果被丢弃。

**代码历史和测试**
- 引入时间限制的是 commit `7e474be`（PR #1，"limit any one single attempt from clobbering a Retryer"）。
- 代码附近没有 TODO 或 "known limitation" 之类的注释。
- `AttemptTimeLimiterTest` 只用了可中断的 `Thread.sleep`，没有覆盖不响应 interrupt 的 callable。
- 本次目标说明把"callable 可能忽略 interrupt"列为前提，并把重叠 attempt 和丢失结果列为关注点。

**是否已有人报告**
- `rholder/guava-retrying` 的全部 106 个 issue/PR（包括最近关闭的 #107，2026-09-05）都看过了，另外跑了关键词搜索。上游 master HEAD 是 `177b6c9`，与被测源码相同，说明没有修复。
- 两个维护中的 fork 也查过：`rhuffman/re-retrying` 和 `itning/guava-retrying3`。
- 最接近的是 #92，但机制不同：它的 demo 没有任何超时，进程不退出是因为内部 cached pool 的空闲非 daemon 线程。#29 讲的是超时后直接中止重试，也是不同问题。
- 结论：没有找到报告这个机制的记录，所以 Novelty 记为 NEW。

## Reproduction result
**Level 0。** 只用了公开 API。库源码来自 worktree `177b6c9`，0 个改动文件，以 `--release 8` 编译。Guava 22.0 jar 的 sha1 是 `3564ef38…`，与 Maven Central 一致。没有 failpoint，也没有向库或 Guava 注入任何延迟；唯一的时间因素是本地 TCP 服务响应慢，这本身就是触发条件。

运行命令（两次 exit 均为 0）：
```
cd .specular-output && timeout 5m ./repro/test_bugMC-1_timed_out_attempt_overlap.sh > confirmation/MC-1/repro-output.jdk21.log 2>&1
JAVA_BIN=/usr/lib/jvm/java-11-openjdk-amd64/bin/java timeout 5m ./repro/test_bugMC-1_timed_out_attempt_overlap.sh > confirmation/MC-1/repro-output.jdk11.log 2>&1
```

JDK 21 第 1 轮的原始输出（节选）：
```
=== Scenario A: timeout trigger, call() RETURNS. fixedTimeLimit(300 ms), retryIfRuntimeException, stopAfterAttempt(3); service answers request 1 after 1500 ms, later requests after 50 ms
  [t=    2 ms] pool-1-thread-1   attempt 1 ENTER callable body (bodies of this call() in flight = 1)
  [t=  302 ms] main              listener: attempt #1 failed with UncheckedTimeoutException
  [t=  303 ms] pool-1-thread-2   attempt 2 ENTER callable body (bodies of this call() in flight = 2)
  [t=  356 ms] pool-1-thread-2   attempt 2 EXIT  callable body: returned VALUE-2 (worker interrupt flag = false; bodies still in flight = 1)
  [t=  357 ms] main              listener: attempt #2 produced VALUE-2
  [t=  357 ms] main              call() RETURNED VALUE-2; bodies of this call() still executing = 1; application cache = VALUE-2
  [t= 1519 ms] pool-1-thread-1   attempt 1 EXIT  callable body: returned VALUE-1 (worker interrupt flag = true; bodies still in flight = 0)
  [t= 1526 ms] main              later: application cache = VALUE-1, although call() returned VALUE-2
  CHECK SequentialAttempts (max bodies at once > 1)    VIOLATED  (max bodies of ONE call() executing at the same time = 2)
  CHECK NoActivityAfterOutcome                         VIOLATED  (1 body(ies) still executing when call() ended; attempt 1 exited 1162 ms after call() ended and returned VALUE-1; )
  FACT  late outcome silently dropped                  YES  (call() delivered: returned VALUE-2; the late outcomes above reached nobody)
  FACT  consumer-visible stale cache                   YES  (cache = VALUE-1 after call() returned VALUE-2)
  FACT  service saw 2+ concurrent requests of one call YES  (max concurrent requests at the service = 2)
  FACT  cancel(true) interrupt reached attempt 1       YES  (worker interrupt flag when attempt 1's blocking read finally returned = true)

=== Scenario B: timeout trigger, call() THROWS RetryException. fixedTimeLimit(200 ms), stopAfterAttempt(3); every request is answered with an error after 1000 ms
  [t=  603 ms] main              call() ended: RetryException(failedAttempts=3, last cause=UncheckedTimeoutException); bodies of this call() still executing = 3
  [t= 1002 ms] pool-2-thread-1   attempt 1 EXIT  callable body: threw IOException: service answered ERR-1 (worker interrupt flag = true; bodies still in flight = 2)
  CHECK SequentialAttempts (max bodies at once > 1)    VIOLATED  (max bodies of ONE call() executing at the same time = 3)

=== Scenario C: caller-interrupt trigger. fixedTimeLimit(5 s, never expires here), retryIfRuntimeException, ...
  [t=  200 ms] main              interrupting the caller thread
  [t=  200 ms] caller            listener: attempt #1 failed with InterruptedException
  [t=  201 ms] caller            call() ended: ExecutionException(cause=InterruptedException); bodies of this call() still executing = 1; application cache = <empty>
  [t= 1003 ms] pool-3-thread-1   attempt 1 EXIT  callable body: returned VALUE-1 (worker interrupt flag = true; bodies still in flight = 0)
  CHECK NoActivityAfterOutcome                         VIOLATED  (1 body(ies) still executing when call() ended; attempt 1 exited 802 ms after call() ended and returned VALUE-1; )

=== Scenario D (control): same callable and service timing as A, AttemptTimeLimiters.noTimeLimit()
  CHECK SequentialAttempts (max bodies at once > 1)    holds  (max bodies of ONE call() executing at the same time = 1)
  CHECK NoActivityAfterOutcome                         holds  (0 body(ies) still executing when call() ended; )
```

JDK 21 汇总（JDK 11 的汇总完全相同）：
```
  A timeout -> return (S1)                             anomaly in 3/3 runs
  B timeout -> RetryException (S1)                     anomaly in 3/3 runs
  C  caller interrupt -> ExecutionException (S2)       anomaly in 3/3 runs
  C2 caller interrupt -> next attempt overlaps (S2)    anomaly in 3/3 runs
  F wrap() + user executor (S1)                        anomaly in 3/3 runs
  D control: noTimeLimit (expect clean)                anomaly in 0/3 runs
  E info: interrupt-responsive body                    anomaly in 0/3 runs
RESULT: BUG REPRODUCED - ...
exit code: 0
```

**哪几行证明了 bug**
- 场景 A 的 `t=303`（同一次调用里有 2 个 body 同时在跑）。
- `t=357`：`call()` 已返回，但仍有 1 个 body 在执行。
- `t=1519/1526`：`VALUE-1` 被丢弃，缓存却被改回 `VALUE-1`。

**和反例轨迹的对应关系**
- bfs1 的 `GetTimeout → Cancel* → Listeners → BlockZero → SubmitNewWorker(t2,w2) → BodyStart(w2)` 对应 A 中 `t=302/303` 两行。
- bfs2 的 `GetReturn → PredicateAccepts` 且 t1 仍 `Running`，对应 A 中 `t=357` 那行；B 演示了迟到的是异常时同样被丢弃，即反例里的 `"Exc"` 模式。
- bfs3 的 `Interrupt → GetInterrupted → Cancel* → PredicateAccepts` 结果为 `ExecExc`，对应场景 C。

**正确行为应该是**：每次 `call()` 同一时刻最多只有 1 个 body 在运行，`call()` 返回或抛出时不能还有 body 在执行。对照组 D 就是这样。

**另外观察到的问题（不属于 MC-1）**：C 和 C2 中 `call()` 结束后，调用线程的 interrupt status 为 `false`。

## Recommendation
1. **修复**：在 `FixedAttemptTimeLimit` 里给 callable 包一层，用一个原子状态机：NEW→RUNNING→DONE 或 NEW→ABANDONED。
   - 超时或被 interrupt 后，先尝试 CAS NEW→ABANDONED。成功说明 body 永远不会开始，这也覆盖了 bfs1 中 `GetTimeout` 先于 `BodyStart` 的交错。
   - CAS 失败说明 body 已在运行，就等它到 DONE，期间可设一个宽限期。超过宽限期时，抛一个让 Retryer 停止重试的明确异常，而不是开始一个重叠的 attempt。
   - 这样 `Retryer.call` 在一次 attempt 真正结束之前，既不会开始下一次，也不会返回。
2. **如果保留"只 interrupt、不等待"的语义**：至少在 `AttemptTimeLimiter`、`fixedTimeLimit` 和 `Retryer.call` 的 Javadoc 里写明：被超时的 attempt 可能和后续 attempt 并发执行，可能在 `call()` 返回后继续运行，其结果会被丢弃；callable 必须响应 interrupt，并且能安全地并发执行。
3. **用户侧缓解**：给阻塞 I/O 设一个不超过 attempt 时限的超时（例如 `Socket.setSoTimeout`），或者在 callable 内部自己实现超时、不用 `fixedTimeLimit`；同时让 callable 幂等、线程安全。

## Checklist
1. **Level 0 或 Level 1 单独就能触发吗？yes**，只用了 Level 0：真实公开 API、未修改的库，没有 failpoint，也没有注入延迟。
2. **用了 Level 2/3 吗？** 没有，不适用。
3. **哪个真实调用方看到了错误结果？**
   - `Retryer.call` 的调用方：在 `Retryer.java:171` 拿到 `VALUE-2`（场景 A），在 `:174` 拿到 `RetryException`（场景 B），在 `:171` 拿到 `ExecutionException`（场景 C）。这三种情况下，之前的 attempt 都还在运行。
   - 用户的 `Callable` 实例在 `Retryer.java:160` 被重入，而它的上一次调用还没结束。
   - `Retryer.RetryerCallable.call`（`Retryer.java:318`，场景 F）返回的 `Future` 在 attempt 1 还在运行时就以 `VALUE-2` 完成了。
   - 在复现中，应用代码在 `call()` 返回 `VALUE-2` 之后读到缓存是 `VALUE-1`，对端服务也看到了同一次 `call()` 发来的 2 个并发请求。
4. **坏状态是永久的吗？是。**
   - 迟到的结果被 `FutureTask` 丢弃（它的状态已经是 cancelled），没有任何回调。
   - 重叠执行和 `call()` 结束后的副作用都已经发生，Retryer 和 Guava 里都没有事后纠正的机制；场景结束时缓存仍是 `VALUE-1`。
   - 唯一的保护是 `cancel(true)` 发出的 interrupt。输出显示它确实送达了 worker（`worker interrupt flag = true`），但没能停止 socket 读。只有响应 interrupt 的 body 不受影响（场景 E）。
   - 因此不是 MASKED。

## Repair round 1 evidence
<!-- specular-repair-token: 3eefa76b5b37ed587e41b6cbdb823026 -->
- **Current violation analysis**: With fixedTimeLimit, when an attempt times out (or the caller is interrupted) Guava's SimpleTimeLimiter.callWithTimeout calls future.cancel(true) and returns immediately without waiting for the worker (SimpleTimeLimiter.java:155-157, 164-166). A callable that ignores interrupts (e.g. a blocking socket read) keeps running on its pool thread while Retryer.call (Retryer.java:157-184) immediately starts the next attempt on another thread or returns/throws. TLC shows two bodies of the same call() — the same Callable instance — running at once (hunt_s1_overlap_bfs1.out, 20 states) and call() return…
- **Counterexample**: `spec/output/hunt_s1_overlap_bfs1.out`

## Phase 4 confirmation after repair round 1

running pwd; ls -la; echo ---; ls -la /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmati...
running cd /home/ubuntu/guava-retrying-20261126/Specular; ls -la; echo ---; ls -la skills 2>/dev/null | head; echo ---; find /home/ubuntu/guava-retrying-20261126 -ma...
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; find . -type f | sort; echo ---; wc -l $(find . -type f -name "*.md")
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; for f in SKILL.md guide.md phases/01-investigation.md phases/02-reproduction.md; do...
reading /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation/guide.md
reading /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation/phases/01-investigation.md
reading /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation/phases/02-reproduction.md
Skill 已读完。接下来读取 references 和该 finding 已有的证据（verdict.json、investigation.md、issue.json、repro 日志）。
reading /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation/references/persistent-findings.md
reading /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation/references/repair-request-format.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-1/; python3 -I -c " i...
已有结论是 `REPRODUCED`（Level 0，JDK 21/11 各 3/3）。现在读取已有的 investigation.md、issue.json、debate.md 和 repro 测试，再核对 repair round 1 的新反例。
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-1/; cat investigation...
running S=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec; ls -la $S/output/hunt_s1_overlap...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec/output; for f in repair-r1/repai...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec/output; sed -n 1176,1232p repair...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-1/worktree && git log...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro && sha256sum test_bugMC-1_timed...
reading /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/test_bugMC-1_timed_out_attempt_overlap.sh
running G=/home/ubuntu/scratch/guava22-sources-dl/extracted/com/google/common/util/concurrent; sha1sum /home/ubuntu/.m2/repository/com/google/guava/guava/22.0/guava-...
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; cd /home/ubuntu/guava-retrying-202611...
running cd /tmp && timeout 60 gh api "repos/rholder/guava-retrying/issues?state=all&sort=updated&direction=desc&per_page=6" --jq '.[] | [.number, (if .pull_request t...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec/output; final() { awk -v n="$2"...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec/output; grep -E "^State [0-9]+:"...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-1/worktree/src/main/j...
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/test_bugMC-1_timed_out_attempt_overlap.sh
Run the extended repro on JDK 21 first, writing output to a temp file; it replaces the canonical log only if the run succeeds.
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output && mkdir -p /tmp/mc1-r1 && (time time...
JDK 21: 3/3 in every scenario, including the new G/G0; control D is 0/3. Let me check the detailed G/G0 output from round 1.
running head -4 /tmp/mc1-r1/jdk21.log; awk '/round 1 #/{p=1} /round 2 #/{exit} p' /tmp/mc1-r1/jdk21.log | awk '/=== Scenario G:/{p=1} /=== Scenario D/{p=0} p'
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output && (time JAVA_BIN=/usr/lib/jvm/java-1...
JDK 11 also gives 3/3 everywhere with a clean control (the final `holds` line is control D). Write both runs to the canonical logs and check for leftover processes.
running C=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-1; cp /tmp/mc1-r1/jdk2...
Only the `pgrep` command matched itself; no Java processes are left over. Pull the round-1 scenario A/B/C excerpts from the new JDK 21 log for the report.
running L=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-1/repro-output.jdk21.l...
Evidence is complete. Before updating the records, confirm the registry has no MC-1 record (which decides whether issue.json needs `revises`).
running cd /home/ubuntu/guava-retrying-20261126/Specular && W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.sp...
running tail -c 600 /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-1/investigat...
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-1/investigation.md
Next, update issue.json: add S4 to the consequence and premises, add the new actions, cfg dependencies, and repair-r1 counterexample evidence.
reading /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-1/issue.json
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-1/issue.json
reading /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-1/issue.json
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-1/issue.json
running cd /home/ubuntu/guava-retrying-20261126/Specular && W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.sp...
issue.json validates (`valid: true`, title 139 chars). Finally, pull the round-1 control D output verbatim for the report.
running L=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-1/repro-output.jdk21.l...
MC-1 依然是 **REPRODUCED**。repair round 1 之后它仍然成立：源码没有变，上游也没有修复。新增的 S4 反例（有界执行器被占满）我也在未修改的库上用 Level 0 复现了。

- **Source**: MC
- **Novelty**: NEW
- **Severity**: High
- **Location**: src/main/java/com/github/rholder/retry/AttemptTimeLimiters.java:107
- **Reproduction test**: `.specular-output/repro/test_bugMC-1_timed_out_attempt_overlap.sh`（Level 0）。本轮在原脚本里新增了场景 G 和 G0，原有场景 A–F 和对照 D/E 没有改动。
- **Persistent record**: `confirmation/MC-1/issue.json` 已更新，`specular findings validate` 返回 `valid: true`。证据记录追加在 `confirmation/MC-1/investigation.md` 的 "Repair round 1 continuation" 一节。

## Description
`FixedAttemptTimeLimit.call`（`AttemptTimeLimiters.java:107`）调用 Guava 22.0 的 `SimpleTimeLimiter.callWithTimeout(callable, d, u, true)`。超时或调用线程被 interrupt 时，Guava 执行 `future.cancel(true)` 后立即抛出（`SimpleTimeLimiter.java:155-157`、`:164-166`），不等 worker 结束。

`Retryer.call`（`Retryer.java:157-184`）把这当成一次普通失败。它马上用同一个 `Callable` 实例开始下一次 attempt，或者直接返回、抛出，之后再也不跟踪被取消的那次 attempt。callable 只要不响应 interrupt（例如平台线程上阻塞的 socket 读），就会出现以下后果：
- 同一次 `call()` 里有多个 body 同时在跑；
- `call()` 已经结束，旧 body 还在执行，它的结果或异常被静默丢弃，副作用却在 `call()` 结束后才发生。

如果限时执行器只有一个线程或已被占满（S4），被放弃的 body 会一直占着这个唯一线程。后续 attempt 要么在队列里超时，要么被拒绝。`call()` 抛出 `RetryException` 时，这个 body 仍在运行。

## Trigger scenario
- **S1，超时触发**（`hunt_s1_overlap_bfs1/bfs2`、`repair1_s1_timelimit_bfs1/bfs2`）：
  1. 配置 `fixedTimeLimit(300 ms)` + `retryIfRuntimeException` + `stopAfterAttempt(3)`。
  2. attempt 1 阻塞在 socket 读上，到 300 ms 超时；`cancel(true)` 送达了 interrupt，但没能停下这次读。
  3. attempt 2 在另一个线程上进入同一个 callable，违反 SequentialAttempts。
  4. `call()` 返回 `VALUE-2` 时，attempt 1 仍在运行，违反 NoActivityAfterOutcome。之后 attempt 1 把缓存写回了 `VALUE-1`。
  5. 如果 stop strategy 先触发，`call()` 抛出 `RetryException` 时三个 body 都还在运行。
- **S2，调用方被 interrupt**（`hunt_s2_interrupt_narrow_bfs3`）：
  - 执行 `:155-157` 的 cancel，然后重抛 `InterruptedException`，再由 `Retryer.java:171` 抛出 `ExecutionException(InterruptedException)`，此时 attempt 1 仍在运行。
  - 换成 `retryIfException` 时，后一次 attempt 会和 attempt 1 重叠。
- **S4，有界执行器被占满**（`repair1_s4_executor_bfs1`，本轮新增）：
  1. 两个线程共用一个 Retryer，配置为 `fixedTimeLimit(300 ms, ThreadPoolExecutor(1 线程, ArrayBlockingQueue(1)))`。
  2. caller-1 的 attempt 1 超时后仍占着唯一线程；caller-2 的 attempt 把队列占满。
  3. caller-1 的 attempt 2 在 `SimpleTimeLimiter.java:149` 提交。这次 `submit` 在 try 之外，抛出的 `RejectedExecutionException` 被 `Retryer.java:162-163` 记为一次失败 attempt。
  4. `stopAfterAttempt(2)` 使 `Retryer.java:174` 抛出 `RetryException`，而 t1 的 body 仍在运行。
- **反例与复现的对应**：repair-r1 的三条 trace 与原 trace 的最终状态完全相同，例如 bfs2 的终态都是 `outcome="Returned"`，同时 `tbody[t1]="Running"`。差别只在调用线程的 `GetTimeout(c1)` 和 worker 线程的 `BodyStart(w1)` 谁先谁后。这两步属于不同线程，可以交换顺序，所以之前的 trace 描述都还成立。
- **对旧记录的修正**：investigation.md 原来写的是"单线程执行器不会重叠，但卡住的 attempt 仍会活过 `call()`"。G0 验证了这一点。S4 在此基础上补充了两点：队列有界时，后续 attempt 会被直接拒绝；共用同一执行器的其他调用方会被饿死。

## Developer intent
沿用上一轮的证据，没有变化：
- `Retryer` 的 Javadoc（`:31-35`、`:141-144`）把 attempt 描述为一个顺序循环。
- `RetryerBuilder.java:113` 的说法是 "limit the duration of any particular attempt"。
- `AttemptTimeLimiter.java:22` 只说 "will possibly be interrupted"。
- 代码里没有 TODO 或已知限制的注释，测试只覆盖了可中断的 `Thread.sleep`。

本轮补充 Guava 的 `SimpleTimeLimiter.java:56-58`："using a bounded executor may be counterproductive! … the call may even time out before the target method is ever invoked"。这段只承认排队时间会计入时限（对应 G0，以及 G 里 caller-2 的情况）。被取消的 attempt 在 `call()` 结束后还在执行、还占着线程，这一点没有任何文档说明。

已知状态在 2026-11-26 重新查过：
- 上游 master 仍是 `177b6c9`（2016 年）。最近有动静的是 #84 和 #107，都是关闭且未合并的 PR，内容无关。
- 新加的关键词（`RejectedExecutionException`、`bounded executor` 等）都没有搜到结果。
- 本地 persistent registry 的 `lookup` 和 `show` 都为空。
- #92（空闲的 cached pool 线程）和 #29（超时导致中止）是不同的机制。

## Reproduction result
**Level 0。** 只用了公开 API。库源码是 worktree `177b6c9`，没有任何改动文件，用 `--release 8` 编译；Guava 22.0 jar 的 sha1 是 `3564ef38…`，与 Maven Central 一致。没有 failpoint，也没有向库注入延迟。

```
cd .specular-output && timeout 5m ./repro/test_bugMC-1_timed_out_attempt_overlap.sh                  # JDK 21.0.13.1, exit 0
JAVA_BIN=/usr/lib/jvm/java-11-openjdk-amd64/bin/java timeout 5m ./repro/test_bugMC-1_timed_out_attempt_overlap.sh   # JDK 11.0.33.1, exit 0
```

JDK 21 第 1 轮（`confirmation/MC-1/repro-output.jdk21.log`）：
```
=== Scenario A: timeout trigger, call() RETURNS. fixedTimeLimit(300 ms), retryIfRuntimeException, stopAfterAttempt(3); service answers request 1 after 1500 ms, later requests after 50 ms
  [t=    1 ms] pool-1-thread-1   attempt 1 ENTER callable body (bodies of this call() in flight = 1)
  [t=  301 ms] main              listener: attempt #1 failed with UncheckedTimeoutException
  [t=  302 ms] pool-1-thread-2   attempt 2 ENTER callable body (bodies of this call() in flight = 2)
  [t=  356 ms] main              call() RETURNED VALUE-2; bodies of this call() still executing = 1; application cache = VALUE-2
  [t= 1515 ms] pool-1-thread-1   attempt 1 EXIT  callable body: returned VALUE-1 (worker interrupt flag = true; bodies still in flight = 0)
  [t= 1516 ms] main              later: application cache = VALUE-1, although call() returned VALUE-2
  CHECK SequentialAttempts (max bodies at once > 1)    VIOLATED  (max bodies of ONE call() executing at the same time = 2)
  CHECK NoActivityAfterOutcome                         VIOLATED  (1 body(ies) still executing when call() ended; attempt 1 exited 1159 ms after call() ended and returned VALUE-1; )
=== Scenario C: caller-interrupt trigger. ...
  [t=  201 ms] caller            call() ended: ExecutionException(cause=InterruptedException); bodies of this call() still executing = 1; application cache = <empty>
  CHECK NoActivityAfterOutcome                         VIOLATED  (1 body(ies) still executing when call() ended; attempt 1 exited 800 ms after call() ended and returned VALUE-1; )
=== Scenario G: S4 saturated bounded limiter executor shared by two call()s. fixedTimeLimit(300 ms, ThreadPoolExecutor(1 thread, ArrayBlockingQueue(1))), retryIfRuntimeException, stopAfterAttempt(2); caller-1's service answers after 1500 ms, caller-2's after 50 ms; caller-2 starts at ~100 ms
  [t=    0 ms] pool-7-thread-1   attempt 1 ENTER callable body (bodies of this call() in flight = 1)
  [t=  100 ms] main              starting caller-2 on the same Retryer
  [t=  300 ms] caller-1          listener: attempt #1 failed with UncheckedTimeoutException
  [t=  301 ms] caller-1          listener: attempt #2 failed with RejectedExecutionException
  [t=  301 ms] caller-1          call() ended: RetryException(failedAttempts=2, last cause=RejectedExecutionException); bodies of this call() still executing = 1; bodies of this call() ever started = 1; limiter pool: active threads = 1, queued tasks = 1
  [t=  401 ms] caller-2          call() ended: RetryException(failedAttempts=2, last cause=RejectedExecutionException); bodies of this call() still executing = 0; bodies of this call() ever started = 0; limiter pool: active threads = 1, queued tasks = 1
  [t= 1501 ms] pool-7-thread-1   attempt 1 EXIT  callable body: returned VALUE-1 (worker interrupt flag = true; bodies still in flight = 0)
  CHECK NoActivityAfterOutcome                         VIOLATED  (1 body(ies) still executing when call() ended; attempt 1 exited 1200 ms after call() ended and returned VALUE-1; )
  FACT  late side effect after call() threw            YES  (caller-1 cache = VALUE-1)
  FACT  caller-2's callable never ran, its call() failed YES  (caller-2 call() ended with RetryException(failedAttempts=2, last cause=RejectedExecutionException); caller-2 bodies ever started = 0)
=== Scenario G0: S4 single-thread limiter executor (unbounded queue). ...
  [t=  901 ms] main              call() ended: RetryException(failedAttempts=3, last cause=UncheckedTimeoutException); bodies of this call() still executing = 1; bodies ever started = 1
  CHECK NoActivityAfterOutcome                         VIOLATED  (1 body(ies) still executing when call() ended; attempt 1 exited 600 ms after call() ended and returned VALUE-1; )
=== Scenario D (control): same callable and service timing as A, AttemptTimeLimiters.noTimeLimit()
  [t= 1501 ms] main              call() RETURNED VALUE-1; bodies still executing = 0; cache = VALUE-1
  CHECK SequentialAttempts (max bodies at once > 1)    holds  (max bodies of ONE call() executing at the same time = 1)
  CHECK NoActivityAfterOutcome                         holds  (0 body(ies) still executing when call() ended; )
```

汇总（JDK 21 与 JDK 11 完全相同）：
```
  A timeout -> return (S1)                             anomaly in 3/3 runs
  B timeout -> RetryException (S1)                     anomaly in 3/3 runs
  C  caller interrupt -> ExecutionException (S2)       anomaly in 3/3 runs
  C2 caller interrupt -> next attempt overlaps (S2)    anomaly in 3/3 runs
  F wrap() + user executor (S1)                        anomaly in 3/3 runs
  G  shared bounded executor -> rejection (S4)         anomaly in 3/3 runs
  G0 single-thread limiter executor (S4)               anomaly in 3/3 runs
  D control: noTimeLimit (expect clean)                anomaly in 0/3 runs
  E info: interrupt-responsive body                    anomaly in 0/3 runs
exit code: 0
```

**证明 bug 的输出行：**
- **场景 A**：`t=302` 时同一次调用里有 2 个 body 在跑。`t=356` 时 `call()` 已返回，但还有 1 个 body 在执行。`t=1515/1516` 时，结果 `VALUE-1` 被丢弃，缓存却被改回了 `VALUE-1`。
- **场景 G**：`t=300/301` 依次出现超时、`RejectedExecutionException`、`RetryException`，同时 "still executing = 1, active threads = 1, queued tasks = 1"。这对应反例 `repair1_s4_executor_bfs1` 的步骤 `GetTimeout → Cancel* → SubmitRejected → StopStrategyStops`，以及它的终态 `tbody[t1]="Running"`、`queue=<<t2>>`。

**正确行为**应当和对照组 D 一样：每次 `call()` 同一时刻最多只有 1 个 body 在跑，`call()` 结束时没有任何 body 还在执行。

**另外观察到的问题（不属于 MC-1）**：C 和 C2 中，`call()` 结束后调用线程的 interrupt status 为 `false`。

## Recommendation
1. **修复**：在 `FixedAttemptTimeLimit` 里给 callable 包一层原子状态机，状态为 NEW→RUNNING→DONE 或 NEW→ABANDONED。
   - 超时或被 interrupt 后，先尝试 CAS NEW→ABANDONED；成功说明 body 永远不会开始。
   - CAS 失败说明 body 已在运行，就等它到 DONE，可以设一个宽限期。超过宽限期时，抛一个能让 Retryer 停止重试的明确异常，而不是开始一次重叠的 attempt 或直接返回。
   - 提交被拒绝时，也不应把它当成一次可以重试的普通 attempt。
2. **如果保留现有语义**：至少在 `AttemptTimeLimiter`、`fixedTimeLimit` 和 `Retryer.call` 的 Javadoc 里写明以下几点：
   - 被超时的 attempt 可能和后续 attempt 并发执行，也可能在 `call()` 之后继续执行，它的结果会被丢弃；
   - 它会一直占用限时执行器的线程；
   - callable 必须响应 interrupt，并且能安全地并发执行。
3. **用户侧缓解**：给阻塞 I/O 设置不超过 attempt 时限的超时（例如 `Socket.setSoTimeout`），或者在 callable 内部自行实现超时；callable 要做到幂等、线程安全；限时执行器不要用有界的。

## Checklist
1. **只靠 Level 0 或 Level 1 能触发吗？yes**，只用了 Level 0：真实公开 API，库未修改，没有 failpoint，也没有注入延迟。唯一的时间因素是本地 TCP 服务响应慢，这正是触发条件本身。
2. **用了 Level 2/3 吗？** 没有，不适用。
3. **哪个真实调用方看到了错误结果？**
   - `Retryer.call` 的调用方：在 `Retryer.java:171` 拿到 `VALUE-2`（A）或 `ExecutionException`（C）；在 `Retryer.java:174` 拿到 `RetryException`（B、G、G0）。每种情况下，之前的 attempt 都还在运行。
   - 用户的 `Callable` 在 `Retryer.java:160` 被重入。
   - `Retryer.RetryerCallable.call`（`Retryer.java:318`，场景 F）返回的 Future 提前完成。
   - 场景 G 里，共用同一个 Retryer 的 caller-2，自己的 callable 一次都没执行，就收到了 `RetryException`。
   - 应用层面：`call()` 返回 `VALUE-2` 之后读到的缓存是 `VALUE-1`；服务端看到了同一次 `call()` 发来的 2 个并发请求。
4. **坏状态是永久的吗？是，不是 MASKED。**
   - 迟到的结果被 `FutureTask` 丢弃（它的状态已经是 INTERRUPTED），没有任何回调。
   - 重叠执行和 `call()` 结束后的副作用都已经发生，Retryer 和 Guava 里都没有事后纠正的机制，缓存最终仍是 `VALUE-1`。
   - 唯一的保护是 `cancel(true)` 发出的 interrupt。输出显示它确实送达了（`worker interrupt flag = true`），但没能停止阻塞的 socket 读；只有响应 interrupt 的 body 不受影响（场景 E 为 0/3）。

---

## Entry 2: A never-returning timed-out attempt pins a pool thread forever, and each further attempt takes another thread

- **Finding ID**: MC-2
- **Status**: REPRODUCED
- **Debate**: not run
- **Transcript**: /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-2/debate.md

running ls -la /home/ubuntu/.claude/projects/-home-ubuntu-guava-retrying-20261126-Specular-runs-guava-retrying-opus55max-20261126-guava-retrying--specular-output-con...
running find / -type d -name "bug-confirmation" 2>/dev/null | head -20
running ls -la /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation/* ; ls -la...
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation && cat SKILL.md && echo ---------- && cat guide.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation && cat phases/01-investigation.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation && cat phases/02-reproduction.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation && cat references/persistent-findings.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation && cat references/repair-request-format.md
已读完 bug-confirmation skill（guide + Phase 1/2 + references）。接下来先做 persistent-findings 轻量查询，然后开始 Phase 1 代码审计。
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; ls -la $OUT; ls -la $OUT/confirmati...
running ls /home/ubuntu/guava-retrying-20261126/Specular/; ls /home/ubuntu/guava-retrying-20261126/Specular/bin 2>/dev/null; find /home/ubuntu/guava-retrying-2026112...
running cd /tmp && SP=/home/ubuntu/guava-retrying-20261126/Specular/specular; head -30 $SP; OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opu...
Persistent-findings 查询结果为空（无历史记录），按正常流程分析。现在看 worktree 源码和反例。
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-2/worktree; ls -la $W;...
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-2/worktree; cd $W && c...
running find /home/ubuntu/guava-retrying-20261126 -path "*guava-22.0*" -name "SimpleTimeLimiter.java" 2>/dev/null | head; find / -name "guava-22.0*.jar" 2>/dev/null...
running mkdir -p /tmp/mc2-guava-src && cd /tmp/mc2-guava-src && unzip -o -q /home/ubuntu/scratch/guava22-sources-dl/guava-22.0-sources.jar 'com/google/common/util/co...
running cd /tmp/mc2-guava-src && cat -n com/google/common/util/concurrent/SimpleTimeLimiter.java | sed -n 160,200p
running S=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec; ls $S/output | grep -i -E "s1_ov...
running S=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec; sed -n 1,80p $S/output/hunt_s1_o...
running S=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec; grep -n -E "^State [0-9]+:|^Erro...
running S=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec; sed -n 945,998p $S/output/hunt_s...
running S=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec; grep -n -E "^State [0-9]+:|^Erro...
running which gh && timeout 60 gh auth status 2>&1 | head -5; timeout 60 gh api repos/rholder/guava-retrying --jq '{full_name, open_issues_count, pushed_at, default_...
running cd /tmp && timeout 90 gh api --paginate 'repos/rholder/guava-retrying/issues?state=all&per_page=100' --jq '.[] | [.number, .state, (if .pull_request then "PR...
running cd /tmp && for n in 92 18 69 94 96; do echo "=================== #$n"; timeout 60 gh api repos/rholder/guava-retrying/issues/$n --jq '"TITLE: " + .title + "\...
running cd /tmp && for n in 107 84 1 29 100; do echo "=================== #$n"; timeout 60 gh api repos/rholder/guava-retrying/issues/$n --jq '"TITLE: " + .title + "...
running cd /tmp && for q in "thread leak" "daemon" "interrupt" "SimpleTimeLimiter" "fixedTimeLimit" "newCachedThreadPool" "exit" "hang" "threads"; do echo "=== searc...
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-2/worktree; cd $W && g...
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-2/worktree; cd $W && l...
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-2/worktree; cd $W && s...
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; ls -la $OUT/analysis-evidence $OUT/...
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; cat $OUT/analysis-evidence/build/po...
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; cat $OUT/analysis-evidence/probes/t...
running ls /home/ubuntu/guava-retrying-20261126/Specular/case-studies | head -80; grep -r -l -i "guava-retrying\|rholder" /home/ubuntu/guava-retrying-20261126/Specul...
running ls -la /home/ubuntu/guava-retrying-20261126/Specular/case-studies; id; ulimit -u; cat /proc/sys/kernel/threads-max; which prlimit systemd-run docker 2>/dev/n...
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-2/worktree; cd $W && g...
Phase 1 证据已齐。先把调查记录写入 `investigation.md`（仅记录证据，不下结论）。
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-2/investigation.md
开始 Phase 2。先探测一下能否用 cgroup（`systemd-run --user --scope -p TasksMax`）模拟容器的 pids 上限，用于演示无界线程增长导致的崩溃。
running cd /tmp && timeout 30 systemd-run --user --scope -p TasksMax=50 --quiet bash -c 'cat /proc/self/cgroup; P=$(cat /proc/self/cgroup | sed "s/^0:://"); cat /sys...
cgroup 方式可用（`pids.max=50` 生效）。现在编写复现脚本：从 worktree 源码原样编译（Level 0，不改库代码），驱动只用公开 API。
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/test_bugMC-2_stuck_attempt_thread_leak.sh
脚本已写好。执行（外层 `timeout`，输出存到 `repro/MC-2.log`；C 段需观察子 JVM ~95s，总计约 3 分钟）。
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro && chmod +x test_bugMC-2_stuck_...
running cat /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/MC-2.log
running cd /home/ubuntu/guava-retrying-20261126/Specular && ls src/specular/ | head -50; grep -rn "def .*validate\|\"root\"\|'root'\|ROOTS\|roots" src/specular/findi...
running cd /home/ubuntu/guava-retrying-20261126/Specular && grep -n "root\b\|\"root\"\|'root'\|ROOT\|def _resolve\|def validate\|def _validate\|title\|160\|status\|e...
running cd /home/ubuntu/guava-retrying-20261126/Specular && sed -n 240,280p src/specular/persistent_findings.py; sed -n 330,470p src/specular/persistent_findings.py
running SRCROOT=/home/ubuntu/scratch/guava-retrying-src/guava-retrying; W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro && MC2_BUILD_DIR=/tmp/mc2-build...
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-2/issue.json
第二次运行结果完全一致（全部 OBSERVED）。把第二次日志加入 evidence，然后校验 `issue.json`。
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-2/issue.json
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; python3 -I -c "import json,sys; d=j...
MC-2 已复现，结论为 `REPRODUCED`。只用公开 API、未修改的库代码就能稳定触发（Level 0），完整跑了两次，两次结果相同。

- **Source**: MC
- **Novelty**: NEW
- **Location**: `src/main/java/com/github/rholder/retry/AttemptTimeLimiters.java:90`（相关位置：`AttemptTimeLimiters.java:57`、`:107`，`Retryer.java:160`，Guava 22.0 `SimpleTimeLimiter.java:83`、`:165`）
- **Severity**: High
- **Reproduction test**: `repro/test_bugMC-2_stuck_attempt_thread_leak.sh`，Escalation level 0

## Description
两参数的 `fixedTimeLimit(d, unit)` 会执行 `new SimpleTimeLimiter()`（`AttemptTimeLimiters.java:57-60, 89-91`），也就是在内部私有地建一个 `Executors.newCachedThreadPool()`（Guava `SimpleTimeLimiter.java:81-84`）。这个线程池没有上限，线程都是 non-daemon，库里没有任何 shutdown 路径，API 也拿不到它。

attempt 超时后，Guava 只会调用 `future.cancel(true)`（`:165`），也就是只给 worker 打上中断标志。如果 callable 不响应中断，它会一直占着这个线程。`Retryer.call` 随即提交下一个 attempt，旧线程还忙着，cached pool 只能再开一个新线程。

后果有四个：
- 每个超时的 attempt 永久占住一个线程；
- 同一次调用里的多个 attempt 同时在跑，而且 `call()` 结束后它们仍在跑；
- 在默认的 `neverStop` 下线程数无上限地增长，直到创建线程时报 OOM；
- `main()` 返回后 JVM 无法退出。

## Trigger scenario
1. 用 `fixedTimeLimit(d, unit)` 加 `retryIfRuntimeException()`（或 `retryIfException()`）构建 `Retryer`，去调用一个远程服务。
2. callable 阻塞在不响应 `Thread.interrupt()` 的操作上。复现里用了两种：
   - 不设 `SO_TIMEOUT` 的 `java.net.Socket` 读，对端接受连接但永远不回数据；
   - 进入一个被卡死线程一直持有的 monitor。
3. attempt 1 超时。`cancel(true)` 中断了 `pool-1-thread-1`，但这个线程仍然阻塞。
4. attempt 2 被提交到新线程 `pool-1-thread-2`，同样卡住。之后每次重试都这样。
5. `call()` 抛出 `RetryException`（或者某个后续 attempt 成功后正常返回），但所有卡住的线程都留在原地。

这和反例一一对应：
- **d3b**：`MCCancelDoInterrupt` 之后 `intr[w1]=TRUE`，body 仍是 `Running`；接着 `MCSubmitNewWorker(c1,t2,w2)`，两个 body 都是 `Stuck`。
- **d3a**：`outcome=Returned` 时 `wpc[w1]=Body`，也就是调用已返回而 w1 还在跑。

## Developer intent
- 文档承诺的是"限制每个 attempt 的时长"：
  - `Retryer.java:73/90/109`："to prevent from any single attempt from spinning infinitely"
  - `RetryerBuilder.java:113`："limit the duration of any particular attempt"
  - PR #1："limit any one single attempt from clobbering a Retryer"
- 文档里的保留说法：
  - `AttemptTimeLimiter.java:22`：attempt "will possibly be interrupted"
  - `AttemptTimeLimiters.java:48-50`：建议改用传 executor 的重载 "for control over thread management"；它引用的 Guava 说明只提醒"有界 executor 可能适得其反"。
- 没有任何文档说过：超时的 attempt 会永久占住线程、每次重试再多占一个、或 JVM 可能退不出。
- 维护者在 #18 承认 SimpleTimeLimiter 的实现"fairly wasteful with respect to resources"，但那是一个 feature request，不是对这个缺陷的报告。
- 现有测试（`AttemptTimeLimiterTest.java:36-51`）只覆盖会响应中断的 `Thread.sleep`。

上游检索：
- 检索了上游全部 106 个 issue/PR，以及多组关键词搜索。
- 最近关闭的 PR #107（2026-09-05 关闭、未合并，作者说是误提到了上游）和 #84（README 改动）都与此无关。
- 上游的 `AttemptTimeLimiters.java` 自 2015-01-20 以来没有改动。
- #92 是相关问题，但机制不同：它讲的是正常运行后有约 60s 的空闲退出延迟。下面的对照 C1 正好复现了 #92 的这个延迟；而本缺陷是永远不退出。

## Reproduction result
命令（exit=0；第二次运行输出到 `repro/MC-2.run2.log`，同样全部 OBSERVED）：

```
cd .specular-output/repro && MC2_BUILD_DIR=/tmp/mc2-build-run1 timeout 600 ./test_bugMC-2_stuck_attempt_thread_leak.sh > MC-2.log 2>&1
```

以下是 `repro/MC-2.log` 的原样摘录：
```
source: .../confirmation/MC-2/worktree  (git HEAD: 177b6c9, dirty files: 0)
== A  d3b (StuckBodiesPerCallAtMostOne)  JDK 21  body=socket  [fixedTimeLimit(500ms), stopAfterAttempt(2), noWait, retryIfRuntimeException]
  call() threw RetryException after 2 attempts, last cause = com.google.common.util.concurrent.UncheckedTimeoutException: java.util.concurrent.TimeoutException
    attempt 1 on pool-1-thread-1  alive=true  daemon=false interrupted=true  state=RUNNABLE bodyFinished=false earlierAttemptsStillRunningAtStart=0 stack: sun.nio.ch.SocketDispatcher.read0 <- sun.nio.ch.SocketDispatcher.read ... MC2Driver.body:51
    attempt 2 on pool-1-thread-2  alive=true  daemon=false interrupted=true  state=RUNNABLE bodyFinished=false earlierAttemptsStillRunningAtStart=1 stack: sun.nio.ch.SocketDispatcher.read0 <- sun.nio.ch.SocketDispatcher.read ... MC2Driver.body:51
  after call(): stuck attempt bodies holding pool threads = 2, live pool-* threads = 2
  BUG[d3b/socket]: one call() left 2 stuck attempt bodies pinning 2 distinct pool threads (StuckBodiesPerCallAtMostOne requires <= 1)
  => OBSERVED: A d3b JDK21 socket
  => OBSERVED: A d3b JDK21 monitor
  => OBSERVED: A d3b JDK11 socket
  => OBSERVED: A d3b JDK11 monitor
== B  d3a (StuckBodiesEndWithCall)  JDK 21  body=socket  [attempt 1 hangs, attempt 2 returns 42]
  call() returned 42
    attempt 1 on pool-1-thread-1  alive=true  daemon=false interrupted=true  state=RUNNABLE bodyFinished=false earlierAttemptsStillRunningAtStart=0 stack: sun.nio.ch.SocketDispatcher.read0 <- sun.nio.ch.SocketDispatcher.read ... MC2Driver.body:51
    attempt 2 on pool-1-thread-2  alive=true  daemon=false interrupted=false state=TIMED_WAITING bodyFinished=true  earlierAttemptsStillRunningAtStart=1 (returned 42)
  BUG[d3a/socket]: call() returned 42 while 1 stuck body still holds pool thread pool-1-thread-1 (StuckBodiesEndWithCall)
-- C/stuck-private  (the finding: 2-arg fixedTimeLimit, body ignores interrupts)
  MAIN_RETURNING (main() returns normally, no System.exit)
  [+60s after main() returned] stuck bodies=3, live pool-* threads=3, non-daemon threads=[pool-1-thread-1/RUNNABLE, pool-1-thread-3/RUNNABLE, pool-1-thread-2/RUNNABLE]
  [+90s after main() returned] stuck bodies=3, live pool-* threads=3, non-daemon threads=[pool-1-thread-1/RUNNABLE, pool-1-thread-3/RUNNABLE, pool-1-thread-2/RUNNABLE]
  JVM STILL ALIVE 95s after main() returned -> killed by harness
-- C/sleep-private  (control C1: 2-arg fixedTimeLimit, interruptible body (known #92 delay))
  JVM EXITED 60s after main() returned
-- C/stuck-daemonpool  (control C2: 3-arg fixedTimeLimit with user daemon pool, body ignores interrupts)
  JVM EXITED 1s after main() returned
== D  growth under default neverStop  [fixedTimeLimit(50ms), noWait, retryIfRuntimeException]  JDK 21
  t= 1.0s attempts=  20 stuck bodies=  20 live pool-* threads=  20 JVM threads=  28
  t= 5.0s attempts= 100 stuck bodies= 100 live pool-* threads= 100 JVM threads= 108
== E  same workload in a cgroup with pids.max=200 (container-style task limit)  JDK 21
[9.505s][warning][os,thread] Failed to start the native thread for java.lang.Thread "pool-1-thread-187"
  t= 9.5s attempts= 186 stuck bodies= 186 live pool-* threads= 186 JVM threads= 193  <- caller finished
  caller: call() threw ExecutionException, cause = java.lang.OutOfMemoryError: unable to create native thread: possibly out of memory or process/resource limits reached
MC-2 RESULT: BUG REPRODUCED (all checks observed)
```

证明缺陷的行：
- A：`BUG[d3b/...]` 这几行，在 socket 和 monitor 两种 body、JDK 21 和 11 上都成立。
- B：`BUG[d3a/socket]`。
- C：`JVM STILL ALIVE 95s`，加上 +90s 时的线程统计。
- D：线程数随时间线性增长的那组数据。
- E：`call() threw ExecutionException ... OutOfMemoryError`。

按文档，预期行为是：每次调用同时最多只有一个 attempt 在跑，`call()` 结束后没有 attempt 还在跑，用完后也不应有线程拖住 JVM。两个对照组说明了差异来自哪里：
- C1（会响应中断的 body）在 #92 那个 60s 延迟后正常退出；
- C2（用户自带 daemon 线程池）1s 内退出，但每个 attempt 仍各占一个线程。

## Recommendation
- 默认 executor 改用 daemon 线程，例如 `newCachedThreadPool(new ThreadFactoryBuilder().setDaemon(true).build())`。这能修好 JVM 退不出的问题（顺带修掉 #92）。
- 在同一次调用里，上一个超时的 attempt 还没真正结束时不再启动新 attempt；或者限制每个 limiter 允许遗留的在途 attempt 数（超过就让该 attempt 直接失败或停止）。这能挡住线程无界增长。
- 让 limiter 可以关闭（例如 `Closeable`），并在文档里写明：超时只会中断 attempt，它的线程要等 callable 返回才会释放。
- 用户现在能做的缓解：改用三参数重载并传入 daemon 线程池，同时在 callable 里设置 I/O 超时。

## Checklist
1. 是否仅靠 Level 0 / Level 1 触发？**yes**。只用了公开 API、未修改的库，callable 是普通用户代码，也没有用任何时序辅助。
2. 是否用了 Level 2/3？不适用，没有使用。
3. 哪个真实调用方观察到错误结果？是调用 `Retryer.call`（`Retryer.java:155`）的应用，具体有三种表现：
   - `main()` 返回后进程不退出，由父进程观察到（C）；
   - `call()` 自身在 `Retryer.java:171`（`attempt.get()`）抛出 `ExecutionException(OutOfMemoryError: unable to create native thread)`（E）；
   - `call()` 已经返回 42，而 attempt 1 仍在运行（B）。
4. 坏状态是**永久的**吗？是：
   - 超过 cached pool 的 60s keep-alive 之后，卡住的线程依然存活（+90s 时仍在）；
   - `cancel(true)` 已经执行过（`interrupted=true`），并没有让线程释放；
   - 私有线程池无法从外部关闭（`AttemptTimeLimiters.java:85` 是 private 字段，接口上没有生命周期方法）。

   没有任何下游机制能消除或掩盖这个问题。只有当 callable 自己返回时，线程才会释放。

另外写了 `confirmation/MC-2/investigation.md` 和 `confirmation/MC-2/issue.json`，后者已通过 `specular findings validate`（`"valid": true`）。

## Repair round 1 evidence
<!-- specular-repair-token: 3eefa76b5b37ed587e41b6cbdb823026 -->
- **Current violation analysis**: The two-argument fixedTimeLimit(d, unit) creates new SimpleTimeLimiter() (AttemptTimeLimiters.java:57-60, 89-91), i.e. a private Executors.newCachedThreadPool() (SimpleTimeLimiter.java:82-83) with non-daemon threads, no shutdown path and no API access. Because cancellation only interrupts the runner (MC-1), an attempt whose callable blocks uninterruptibly keeps its thread forever, and the cached pool starts a new thread for the next attempt. TLC (MCHunt.tla filtered checks on the s1_overlap model) shows one call() pinning two pool threads with stuck bodies (hunt_s1_overlap_d3b.out, 20 states)…
- **Counterexample**: `spec/output/hunt_s1_overlap_d3b.out`

## Phase 4 confirmation after repair round 1

running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-2 && ls -la && echo -...
running find / -type d -name "bug-confirmation" 2>/dev/null | head -20; find /home/ubuntu -path "*bug-confirmation*" -name "*.md" 2>/dev/null | head -30
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation && ls -laR && echo ========== SKILL.md && cat SKILL.md && echo ========== guide.md &...
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation && echo ========== 01 && cat phases/01-investigation.md && echo ========== 02 && cat...
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation && echo ========== persistent && cat references/persistent-findings.md && echo =====...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-2 && echo ===== inves...
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; W=$OUT/confirmation/MC-2/worktree;...
running S=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec/output; for f in repair-r1/repair...
running S=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec/output; for p in d3b d3a; do echo...
running S=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec/output; awk '/^State 28:/{f=1} f{...
running cat /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/test_bugMC-2_stuck_attempt_thr...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro && rm -rf /tmp/mc2-build-r1 &&...
running mkdir -p /tmp/mc2-r1-gh && cd /tmp/mc2-r1-gh && timeout 90 gh api --paginate 'repos/rholder/guava-retrying/issues?state=all&per_page=100' > all.json 2>err.tx...
running cat /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/MC-2.r1.log
running cd /tmp/mc2-r1-gh && timeout 90 gh api --paginate 'repos/rholder/guava-retrying/issues/comments?per_page=100' > comments.json 2>cerr.txt; echo "rc=$? err=$(h...
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-2/worktree/src/main/ja...
running J=$(ls /home/ubuntu/scratch/guava22-sources-dl/guava-22.0-sources.jar 2>/dev/null); echo "jar: $J"; mkdir -p /tmp/mc2-r1-guava && cd /tmp/mc2-r1-guava && unz...
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-2/worktree; cd $W && g...
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; SP=/home/ubuntu/guava-retrying-2026...
Lookup returned `[]` (nothing registered), so no `revises` is needed, and both cfg files exist. Next I'll append this round's evidence to `investigation.md`, keeping all existing content.
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-2 && cat >> investiga...
Now I'll update `issue.json`: add the current cfg as a dependency, add the repair-round-1 counterexamples and the new log as evidence, then run validation.
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-2 && cp issue.json /t...
`issue.json` validated (`"valid": true`). Last step before the conclusion: make sure the repro left no `MC2Driver` child JVMs running, and remove my scratch files under `/tmp`.
running pgrep -af MC2Driver || echo "no MC2Driver processes left"; rm -rf /tmp/mc2-r1-gh /tmp/mc2-r1-guava /tmp/mc2-issue.before.json /tmp/mc2-build-r1; ls -d /tmp/m...
## MC-2 结论：维持 `REPRODUCED`（repair round 1 后复核）

修复后的 spec 上，两个反例和原反例逐步相同。源码没有变化。同一个 Level 0 复现脚本又跑了一次，9 项检查全部触发；加上前两次，共三次运行，每次都是 9/9。

- **Source**: MC
- **Novelty**: NEW
- **Location**: src/main/java/com/github/rholder/retry/AttemptTimeLimiters.java:90
- **Severity**: High
- **Reproduction test**: `repro/test_bugMC-2_stuck_attempt_thread_leak.sh`（Escalation level 0）

## Description
两参数的 `fixedTimeLimit(d, unit)`（`AttemptTimeLimiters.java:57-60`）在 `:90` 执行 `new SimpleTimeLimiter()`，也就是建一个私有的 `Executors.newCachedThreadPool()`（Guava 22.0 `SimpleTimeLimiter.java:81-84`）。这个线程池：
- 线程数没有上限，线程都是 non-daemon；
- 没有 shutdown 路径；
- 外部拿不到它（`AttemptTimeLimiters.java:85` 是 private 字段）。

attempt 超时后，Guava 只执行 `future.cancel(true)`（`:165`），也就是只中断 worker 线程。callable 如果不响应中断，就会一直占着这个线程。`Retryer.call` 的下一轮循环（`Retryer.java:157-160`）把下一个 attempt 交给同一个线程池，而旧线程还忙着，线程池只能再开一个新线程。

后果有四个：
- 同一次 `call()` 的多个 attempt 同时在跑；
- `call()` 返回或抛出后，这些 attempt 仍在跑；
- 在默认的 `neverStop` 下，线程数随 attempt 数线性增长，直到创建线程失败；
- `main()` 返回后 JVM 无法退出。

## Trigger scenario
1. 用 `fixedTimeLimit(d, unit)` 加 `retryIfRuntimeException()`（或 `retryIfException()`）构建 `Retryer`，callable 去调用一个远程服务。
2. callable 阻塞在不响应 `Thread.interrupt()` 的操作上。复现里用了两种：
   - 不设 `SO_TIMEOUT` 的 `java.net.Socket` 读，对端接受连接但永远不回数据；
   - 进入一个被卡死线程一直持有的 monitor。
3. attempt 1 超时。`cancel(true)` 中断了 `pool-1-thread-1`，但这个线程仍然阻塞。
4. attempt 2 在新线程 `pool-1-thread-2` 上运行，同样卡住。之后每次重试都再多占一个线程。
5. `call()` 抛出 `RetryException`（或者某个后续 attempt 成功后正常返回），所有卡住的线程都留在原地。

这和当前 spec 上的反例（`MC_hunt_s1_timelimit.cfg`）一一对应：
- **d3b**（`repair1_s1_timelimit_d3b.out`，20 个状态）：`MCCancelDoInterrupt(c1)` 之后 `intr[w1]=TRUE`；接着 `MCSubmitNewWorker(c1,t2,w2)`、`MCBodyStart(w2,"Stuck")`。终态 `wpc = w1:Body, w2:Body`，`tmode = t1:Stuck, t2:Stuck`。
- **d3a**（`repair1_s1_timelimit_d3a.out`，28 个状态）：attempt 2 走 `MCBodyStart(w2,"Ret")` … `MCPredicateAccepts(c1)`。终态 `outcome = Returned`、`cpc = Done`，而 `wpc[w1] = Body`、`tbody[t1] = Running`，即调用已结束而 attempt 1 还在跑。

## Developer intent
- **文档的承诺**是限制单个 attempt 的时长：
  - `Retryer.java:73/90/109`："to prevent from any single attempt from spinning infinitely"
  - `RetryerBuilder.java:113`："limit the duration of any particular attempt"
  - PR #1："limit any one single attempt from clobbering a Retryer"
- **文档里的保留说法**只有两处：
  - `AttemptTimeLimiter.java:22`：attempt "will possibly be interrupted"；
  - `AttemptTimeLimiters.java:48-50`：建议改用传 executor 的重载 "for control over thread management"，它引用的 Guava 说明只提醒"有界 executor 可能适得其反"。
- 没有任何文档说过：超时的 attempt 会永久占住线程、每次重试再多占一个、或 JVM 可能退不出。
- 维护者在 #18 承认 SimpleTimeLimiter 的实现 "fairly wasteful with respect to resources"，但那是一个 feature request，不是对这个缺陷的报告。
- 现有测试（`AttemptTimeLimiterTest.java:36-51`）只覆盖会响应中断的 `Thread.sleep`。
- **上游检索**：
  - 查了上游全部 106 个 issue/PR。最新动态仍是 2026-09-20 关闭的 PR #84；最近关闭的 PR #107 未合并，且与此无关。
  - 本轮又对所有标题、正文、185 条 issue 评论和 5 条 review 评论做了全文关键词扫描，补上了上一轮 `threads` 关键词搜索被限流留下的空缺。
  - 结果：没有任何报告描述这个机制。
- **#92 相关但机制不同**：它讲的是正常运行结束后有约 60 s 的空闲退出延迟，是暂时性的。下面的对照 C1 正好复现了 #92 的这个延迟；而本缺陷是永远不退出。

## Reproduction result
命令（exit=0，耗时 123 s）：
```
cd .specular-output/repro && MC2_BUILD_DIR=/tmp/mc2-build-r1 timeout 590 ./test_bugMC-2_stuck_attempt_thread_leak.sh > MC-2.r1.log 2>&1
```
以下是 `repro/MC-2.r1.log` 的原样摘录，省略的部分用 `[...]` 标出。前两次的 `MC-2.log`、`MC-2.run2.log` 结果相同。
```
== MC-2 repro  2026-11-26T16:43:42Z
source: /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-2/worktree  (git HEAD: 177b6c9, dirty files: 0)
[...]
== A  d3b (StuckBodiesPerCallAtMostOne)  JDK 21  body=socket  [fixedTimeLimit(500ms), stopAfterAttempt(2), noWait, retryIfRuntimeException]
  call() threw RetryException after 2 attempts, last cause = com.google.common.util.concurrent.UncheckedTimeoutException: java.util.concurrent.TimeoutException
    attempt 1 on pool-1-thread-1  alive=true  daemon=false interrupted=true  state=RUNNABLE bodyFinished=false earlierAttemptsStillRunningAtStart=0 stack: sun.nio.ch.SocketDispatcher.read0 <- sun.nio.ch.SocketDispatcher.read ... MC2Driver.body:51
    attempt 2 on pool-1-thread-2  alive=true  daemon=false interrupted=true  state=RUNNABLE bodyFinished=false earlierAttemptsStillRunningAtStart=1 stack: sun.nio.ch.SocketDispatcher.read0 <- sun.nio.ch.SocketDispatcher.read ... MC2Driver.body:51
  after call(): stuck attempt bodies holding pool threads = 2, live pool-* threads = 2
  BUG[d3b/socket]: one call() left 2 stuck attempt bodies pinning 2 distinct pool threads (StuckBodiesPerCallAtMostOne requires <= 1)
  => OBSERVED: A d3b JDK21 socket
[...]
  => OBSERVED: A d3b JDK21 monitor
[...]
  => OBSERVED: A d3b JDK11 socket
[...]
  => OBSERVED: A d3b JDK11 monitor

== B  d3a (StuckBodiesEndWithCall)  JDK 21  body=socket  [attempt 1 hangs, attempt 2 returns 42]
  call() returned 42
    attempt 1 on pool-1-thread-1  alive=true  daemon=false interrupted=true  state=RUNNABLE bodyFinished=false earlierAttemptsStillRunningAtStart=0 stack: sun.nio.ch.SocketDispatcher.read0 <- sun.nio.ch.SocketDispatcher.read ... MC2Driver.body:51
    attempt 2 on pool-1-thread-2  alive=true  daemon=false interrupted=false state=TIMED_WAITING bodyFinished=true  earlierAttemptsStillRunningAtStart=1 (returned 42)
  immediately after call() returned: stuck attempt bodies holding pool threads = 1, live pool-* threads = 2
  BUG[d3a/socket]: call() returned 42 while 1 stuck body still holds pool thread pool-1-thread-1 (StuckBodiesEndWithCall)
  => OBSERVED: B d3a JDK21
[...]
  => OBSERVED: B d3a JDK11
[...]
-- C/stuck-private  (the finding: 2-arg fixedTimeLimit, body ignores interrupts)
[...]
  after call(): stuck attempt bodies holding pool threads = 3, live pool-* threads = 3
  MAIN_RETURNING (main() returns normally, no System.exit)
[...]
  [+60s after main() returned] stuck bodies=3, live pool-* threads=3, non-daemon threads=[pool-1-thread-1/RUNNABLE, pool-1-thread-3/RUNNABLE, pool-1-thread-2/RUNNABLE]
  [+75s after main() returned] stuck bodies=3, live pool-* threads=3, non-daemon threads=[pool-1-thread-1/RUNNABLE, pool-1-thread-3/RUNNABLE, pool-1-thread-2/RUNNABLE]
  [+90s after main() returned] stuck bodies=3, live pool-* threads=3, non-daemon threads=[pool-1-thread-1/RUNNABLE, pool-1-thread-3/RUNNABLE, pool-1-thread-2/RUNNABLE]
  JVM STILL ALIVE 95s after main() returned -> killed by harness

-- C/sleep-private  (control C1: 2-arg fixedTimeLimit, interruptible body (known #92 delay))
[...]
  JVM EXITED 60s after main() returned

-- C/stuck-daemonpool  (control C2: 3-arg fixedTimeLimit with user daemon pool, body ignores interrupts)
[...]
  JVM EXITED 1s after main() returned
  => OBSERVED: C JVM with stuck bodies never exits (>= 95s after main returned)
[...]
== D  growth under default neverStop  [fixedTimeLimit(50ms), noWait, retryIfRuntimeException]  JDK 21
  t= 1.0s attempts=  20 stuck bodies=  20 live pool-* threads=  20 JVM threads=  28
  t= 2.0s attempts=  40 stuck bodies=  40 live pool-* threads=  40 JVM threads=  48
  t= 3.0s attempts=  60 stuck bodies=  60 live pool-* threads=  60 JVM threads=  68
  t= 4.0s attempts=  80 stuck bodies=  80 live pool-* threads=  80 JVM threads=  88
  t= 5.0s attempts= 100 stuck bodies= 100 live pool-* threads= 100 JVM threads= 108
  caller: still retrying (neverStop)
  => OBSERVED: D stuck bodies grow with attempts (100 pinned threads after 5 s)

== E  same workload in a cgroup with pids.max=200 (container-style task limit)  JDK 21
[...]
[9.437s][warning][os,thread] Failed to start the native thread for java.lang.Thread "pool-1-thread-187"
  t= 9.5s attempts= 186 stuck bodies= 186 live pool-* threads= 186 JVM threads= 193  <- caller finished
  caller: call() threw ExecutionException, cause = java.lang.OutOfMemoryError: unable to create native thread: possibly out of memory or process/resource limits reached
  => OBSERVED: E call() fails with OutOfMemoryError: unable to create native thread

MC-2 RESULT: BUG REPRODUCED (all checks observed)
```
证明缺陷的行：
- **A**（d3b，`StuckBodiesPerCallAtMostOne`）：`BUG[d3b/...]` 加上 4 行 `=> OBSERVED: A d3b ...`。一次 `call()` 留下 2 个卡住的 body，各占一个不同的线程；socket 和 monitor 两种 body、JDK 21 和 11 上都成立。
- **B**（d3a，`StuckBodiesEndWithCall`）：`call() returned 42` 时 `pool-1-thread-1` 仍卡住；JDK 21 和 11 都成立。
- **C**：`JVM STILL ALIVE 95s after main() returned`，+90s 时 3 个 non-daemon 线程仍是 RUNNABLE。
- **D**：卡住的线程数与 attempt 数同步增长，1 s 时 20 个，5 s 时 100 个。
- **E**：`pids.max=200` 下第 187 个线程创建失败，`call()` 抛出 `ExecutionException(OutOfMemoryError ...)`。

按文档，预期行为是：同一次调用里同时最多只有一个 attempt 在跑；`call()` 结束后没有 attempt 还在跑；用完后也不应有线程拖住 JVM。两个对照组说明了差异来自哪里：
- C1（会响应中断的 body）在 #92 那个 60 s 延迟后正常退出；
- C2（三参数重载 + 用户自带的 daemon 线程池）1 s 内退出，但每个 attempt 仍各占一个线程。

## Recommendation
- 默认 executor 改用 daemon 线程，例如 `Executors.newCachedThreadPool(new ThreadFactoryBuilder().setDaemon(true).build())`。这能修好 JVM 退不出的问题，顺带修掉 #92。
- 在同一次调用里，上一个超时的 attempt 还没真正结束时不再启动新 attempt；或者限制每个 limiter 允许遗留的在途 attempt 数，超过就让该 attempt 直接失败或停止重试。这能挡住线程无界增长。
- 让 limiter 可以关闭（例如实现 `Closeable`），并在 Javadoc 里写明：超时只会中断 attempt，它的线程要等 callable 返回才会释放。
- 用户现在能做的缓解：改用三参数重载并传入 daemon 线程池，同时在 callable 里设置 I/O 超时。

## 本轮（repair round 1）更新与更正
- 当前反例 `repair1_s1_timelimit_d3a/d3b.out` 与原来的 `hunt_s1_overlap_d3a/d3b.out` 动作序列完全相同，`diff` 为空。终态只差在 `exitInfo` 记录里字段的打印顺序，语义一样。
- worktree 仍是 `177b6c9`，0 个 dirty 文件；复现脚本的 sha256 与上一轮一致（`c1d30916…`）；所有 `file:line` 引用都重新核对过。
- 上一轮的结论没有被推翻，只补充两点：
  - finding 摘要说"JVM 退不出"是 "by code inspection" 得出的；检查 C 已经直接演示了它，三次运行都在 `main()` 返回 95 s 后仍然存活。
  - 检查 E 中 OOM 被包成 `ExecutionException`，是因为 `Retryer.java:162-163` 捕获了所有 `Throwable`，再由 `:171` 抛出（这是已知的 #67）。它只决定调用方看到的异常类型，线程照样创建失败，不构成掩盖。
- 更新了 `confirmation/MC-2/investigation.md`（追加了本轮小节）。
- 更新了 `issue.json`：加入 `spec/MC_hunt_s1_timelimit.cfg` 依赖、两个 repair-r1 反例和 `repro/MC-2.r1.log`。`specular findings validate` 返回 `"valid": true`。

## Checklist
1. **是否仅靠 Level 0 / Level 1 触发？yes**：
   - 只用了公开 API：`RetryerBuilder`、`AttemptTimeLimiters.fixedTimeLimit`、`StopStrategies`、`WaitStrategies.noWait`、`Retryer.call`；
   - 库从 worktree `177b6c9` 原样编译；
   - callable 是普通用户代码；
   - 没有用任何时序辅助。
2. **是否用了 Level 2/3？** 不适用，没有使用。
3. **哪个真实调用方看到错误结果？** 是调用 `Retryer.call`（`Retryer.java:155`）的应用，具体有三种表现：
   - B：`call()` 已经返回 42，而 attempt 1 仍在运行；
   - E：`call()` 在 `Retryer.java:171` 抛出 `ExecutionException(OutOfMemoryError: unable to create native thread)`；
   - C：`main()` 正常返回后进程不退出，由父进程观察到。
4. **坏状态是永久的吗？是**：
   - 卡住的线程超过 cached pool 的 60 s keep-alive 后依然存活，+90 s 时仍在；
   - `cancel(true)` 已经执行过（`interrupted=true`），并没有让线程释放；
   - 私有线程池无法从外部关闭：`AttemptTimeLimiters.java:85` 是 private 字段，`AttemptTimeLimiter` 和 `Retryer` 都没有生命周期方法。

   没有任何下游机制能消除或掩盖这个问题。只有 callable 自己返回时，线程才会释放。

---

## Entry 3: A completed attempt is reported as a timeout; its result is discarded and the work is executed again

- **Finding ID**: MC-3
- **Status**: FALSE POSITIVE
- **Debate**: not run
- **Transcript**: /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-3/debate.md

running pwd; ls -la; echo ---; ls -la /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmati...
running ls -la ~/.claude/skills 2>&1 | head -50; echo ---; ls -la /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying...
running cat /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-3/turn01_A.log; echo...
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; cat SKILL.md; echo; echo =====GUIDE=====; cat guide.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; cat phases/01-investigation.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; cat phases/02-reproduction.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; cat references/persistent-findings.md; echo ====RR====; cat references/repair-reque...
running which specular gh java javac mvn 2>&1; echo ---; ls -la /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/....
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; cat persistent-findings-context.json...
running cd /home/ubuntu/guava-retrying-20261126/Specular; file specular; head -30 specular; echo ---; timeout 60 ./specular findings --help 2>&1 | head -40
running cd /home/ubuntu/guava-retrying-20261126/Specular; W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.spec...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-3/worktree; ls -la; g...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; ls -la harness harness/* | head -60;...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; cat analysis-evidence/build/pom.xml;...
running cd /tmp; unzip -l /home/ubuntu/scratch/guava22-sources-dl/guava-22.0-sources.jar | grep -E "SimpleTimeLimiter|TimeLimiter.java|UncheckedTimeoutException|Unin...
running cat /home/ubuntu/.m2/repository/com/google/guava/guava/22.0/guava-22.0.jar.sha1; echo; sha1sum /home/ubuntu/.m2/repository/com/google/guava/guava/22.0/guava-...
running unzip -p /home/ubuntu/scratch/guava22-sources-dl/guava-22.0-sources.jar com/google/common/util/concurrent/TimeLimiter.java | cat -n | sed -n '20,220p'
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-3/worktree/src/main/j...
running ls /usr/lib/jvm/; for j in /usr/lib/jvm/java-11-openjdk-amd64 /usr/lib/jvm/java-21-openjdk-amd64; do echo "== $j"; ls $j/lib/src.zip 2>&1; $j/bin/java -versi...
running unzip -p /usr/lib/jvm/java-11-openjdk-amd64/lib/src.zip java.base/java/util/concurrent/FutureTask.java | cat -n | sed -n '160,240p;255,290p;395,470p'
running unzip -l /usr/lib/jvm/java-11-openjdk-amd64/lib/src.zip | grep -i "FutureTask" ; ls -la /usr/lib/jvm/java-11-openjdk-amd64/lib/src.zip; readlink -f /usr/lib/...
running readlink -f /usr/lib/jvm/java-21-openjdk-amd64/lib/src.zip; ls -la /usr/lib/jvm/openjdk-21/ 2>&1 | head; find / -name "FutureTask.java" -not -path "/proc/*"...
running cd /home/ubuntu/scratch; ls -la jdk11u-src jdk-src jdk-src/11 2>&1 | head -30; md5sum jdk11u-src/FutureTask.java jdk-src/11/java/util/concurrent/FutureTask.j...
running cd /home/ubuntu/scratch/jdk-src/11/java/util/concurrent; grep -n "public boolean cancel\|public V get(long\|protected void set(V v)\|public void run()\|priva...
running cd /home/ubuntu/scratch/jdk-src/11/java/util/concurrent; sed -n '226,300p' FutureTask.java; echo ......; sed -n '380,460p' FutureTask.java
running cd /home/ubuntu/scratch/jdk-src/21/java/util/concurrent; grep -n "public boolean cancel\|public V get(long\|protected void set(V v)\|public void run()\|priva...
JDK 11 与 JDK 21 的 `FutureTask.cancel/awaitDone/get(timeout)` 实现一致，机制在两个运行时都成立。现在读 TLC 反例。
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec/output; ls -la hunt_s1_timelimit...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec/output; grep -n "^State \|Error\...
running timeout 30 gh auth status 2>&1 | head -10; echo ---; timeout 60 gh api repos/rholder/guava-retrying --jq '.full_name, .open_issues_count, .pushed_at, .archiv...
running cd /tmp; timeout 120 gh issue list -R rholder/guava-retrying --state all --limit 200 --json number,title,state,createdAt,closedAt --jq '.[] | "\(.number)\t\(...
running cd /tmp; timeout 120 gh pr list -R rholder/guava-retrying --state all --limit 200 --json number,title,state,createdAt,mergedAt --jq '.[] | "\(.number)\t\(.st...
running cd /tmp; for n in 29 18 94 96; do echo "=================== ISSUE #$n"; timeout 60 gh issue view $n -R rholder/guava-retrying --comments 2>&1 | head -80; done
running cd /tmp; for n in 29 18 94 96 65 69 100; do echo "=================== #$n"; timeout 60 gh api repos/rholder/guava-retrying/issues/$n --jq '"TITLE: " + .title...
running cd /tmp; for n in 1 95 107; do echo "=================== PR #$n"; timeout 60 gh api repos/rholder/guava-retrying/pulls/$n --jq '"TITLE: " + .title + "\nSTATE...
running cd /tmp; for q in "cancel" "timeout result" "SimpleTimeLimiter" "UncheckedTimeoutException" "executed twice" "runs twice" "time limit completed" "callWithTim...
running cd /tmp; for q in "SimpleTimeLimiter cancel" "SimpleTimeLimiter race" "TimeLimiter cancel result" "callWithTimeout completed timeout" "SimpleTimeLimiter Time...
running cd /tmp; for q in "SimpleTimeLimiter" "TimeLimiter"; do echo "=== search guava: $q"; timeout 60 gh search issues "$q" --repo google/guava --include-prs --lim...
running cd /tmp; for n in 6599 3550; do echo "=================== guava #$n"; timeout 60 gh api repos/google/guava/issues/$n --jq '"TITLE: " + .title + "\nSTATE: " +...
running cd /tmp; timeout 60 gh api "repos/google/guava/contents/guava/src/com/google/common/util/concurrent/SimpleTimeLimiter.java?ref=master" --jq '.content' 2>/dev...
running cd /tmp; timeout 60 gh api "repos/google/guava/contents/guava/src/com/google/common/util/concurrent/TimeLimiter.java?ref=master" --jq '.content' 2>/dev/null...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-3/worktree; git log -...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-3/worktree; sed -n '1...
running cd /home/ubuntu/scratch/jdk-src/11/java/util/concurrent; awk 'NR>=164 && NR<=183 {printf "%d: %s\n", NR, $0}' FutureTask.java | sed -n '1,3p;17,20p'; echo .....
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-3/investigation.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-3/worktree; sed -n '1...
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/test_bugMC-3_timeout_discards_completion.sh
running chmod +x /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/test_bugMC-3_timeout_disc...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec/output; awk '/^State 8:/,/^State...
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/test_bugMC-3_timeout_discards_completion.sh
running cd /tmp; R=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro; ( echo "\$ timeout 120...
running cat /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/MC-3.log | cut -c1-420
running cd /home/ubuntu/guava-retrying-20261126/Specular/src/specular; grep -rn "repair-request.body.md\|repair_request_body\|def _validate_repair_draft\|def validat...
running cd /home/ubuntu/guava-retrying-20261126/Specular/src/specular; sed -n '2622,2660p;2700,2830p' confirmlib.py
running cd /home/ubuntu/guava-retrying-20261126/Specular/src/specular; grep -n "def _scope_list\|def _scope_block_item\|def _repair_frontmatter\|_RR_LIFECYCLE_KEYS =...
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-3/repair-request.body.md
running cd /home/ubuntu/guava-retrying-20261126/Specular; timeout 60 python3 - <<'PY' import sys sys.path.insert(0, "src") sys.path.insert(0, "src/specular") try: fr...
running ls -la /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec/MC_hunt_s1_timelimit.cfg 2>&1
Now append the Phase 2 record to `investigation.md` so that later repair or confirmation rounds can reuse this evidence directly.
running cat >> /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-3/investigation.m...
running git -C /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-3/worktree status...
running L=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/MC-3.log; sed -n '1,4p' $L | cut...
MC-3 的结论是 PENDING REPAIR，target 为 `INVARIANT`：反例路径能用纯公共 API 稳定复现，但 `NoDiscardedCompletion` 标记的状态正是 Guava 和 guava-retrying 文档规定的超时结果，不是代码缺陷，问题在 invariant 本身过严。

- **Source**: MC
- **Novelty**: NEW
- **Location**: guava-22.0/com/google/common/util/concurrent/SimpleTimeLimiter.java:165

## Description
Guava 22.0 的 `SimpleTimeLimiter.callWithTimeout` 在 `TimeoutException` 分支先调用 `future.cancel(true)`，忽略其返回值，然后无条件抛 `UncheckedTimeoutException`（`SimpleTimeLimiter.java:164-166`）。

如果 callable 恰好在两个时刻之间完成，`cancel` 会返回 `false`：一是 `FutureTask.get(timeout)` 判定超时（`FutureTask.java:436-438`、`:202-204`），二是 `cancel` 的 CAS。此时 Future 最终是 NORMAL 并持有结果，而 `Retryer` 在 `Retryer.java:162-163` 记录的却是超时。

- 用 `retryIfException()` 时，callable 会再执行一次。
- 用默认谓词时，`call()` 抛 `ExecutionException(UncheckedTimeoutException)`。

这条路径真实可达，但只在 attempt 已经超过时限之后才会发生。调用方看到的结果与文档规定的超时结果完全相同，所以 invariant 要求的"Future 已 NORMAL 就不能记为超时"不是实现承诺过的性质。

## Trigger scenario
对应反例 `spec/output/hunt_s1_timelimit_bfs1.out`（10 个状态）：
1. `Retryer.call` → `FixedAttemptTimeLimit.call`（`AttemptTimeLimiters.java:107`）→ `executor.submit`（`SimpleTimeLimiter.java:149`）→ 调用线程进入 `get(limit)`（:154）。
2. 截止时刻已过，调用线程醒来，在循环顶部读到 `NEW`（`FutureTask.java:406`），判定 `elapsed >= nanos`（:436）。
3. worker 上的 callable 此时返回，`set` 的 CAS 把状态改为 `COMPLETING`（CE state 8 `MCSetCASWon`）。
4. `return state`（:438）读到 `COMPLETING`，于是抛 `TimeoutException`（:204，对应 CE state 9 `MCGetTimeout`）。实际运行中更常见的是另一种交错：读到 `NEW`，在构造 `TimeoutException` 的几微秒里 worker 的 CAS 落地。
5. worker 发布 `NORMAL`（CE state 10 `MCSetFinish`）。调用线程的 `cancel(true)` 返回 `false` 被忽略，抛出 `UncheckedTimeoutException`，`Retryer.java:162-163` 记录 `ExceptionAttempt`，随后按谓词重试，或 `call()` 抛 `ExecutionException`。

## Developer intent
- **Guava 22.0 `TimeLimiter.java:79-83`、`:94`**：这是 `AttemptTimeLimiters.java:107` 调用的 4 参数 `callWithTimeout` 的契约。原文："If the target method call finished before the limit is reached, the return value … is propagated … If, on the other hand, the time limit is reached, we attempt to abort the call to the target, and throw an UncheckedTimeoutException"。也就是说，一到时限就抛超时，中止调用只是"尝试"。
- **Guava 22.0 `TimeLimiter.java:47-51`**："the primary purpose … is to return control to the caller when the timeout elapses; aborting the target method call is of secondary concern"。
- **Guava 当前 master**（最近一次改动该文件的 commit 是 `3b1c73103d`，2026-07-28）：所有超时路径仍然忽略 `cancel` 的返回值，Javadoc 也没变。
- **guava-retrying**：
  - `AttemptTimeLimiter.java:22`："will possibly be interrupted if the limit is exceeded"。
  - `AttemptTimeLimiters.java:52`/`:63`："duration that an attempt may persist before being circumvented"（`7e474be`，dirkraft）。
  - issue #29 中维护者认为超时应当 "behave like any other exception thrown by an attempt, and be subject to the exception-related retryer configuration"。
  - `AttemptTimeLimiterTest.java:44-50` 断言超限的 attempt 得到 `ExecutionException(UncheckedTimeoutException)`。
- **既有报告检索**，均未找到针对此机制的报告，因此判为 NEW：
  - guava-retrying 全部 issue（#2–#106）和全部 PR（#1–#107，含 2026-09-05 关闭的 #107），外加 `cancel` / `SimpleTimeLimiter` / `UncheckedTimeoutException` 等关键词检索；#29 是另一个机制（超时默认不重试）。
  - google/guava 的 TimeLimiter / SimpleTimeLimiter 相关 issue。
  - persistent-findings `lookup` 返回 `[]`。

## Reproduction result
Level 0：只用公共 API，guava-retrying `177b6c9` 与 Guava 22.0（sha1 `3564ef38…`）均未修改，也没有注入任何状态。测试给公共工厂 `fixedTimeLimit(1, MILLISECONDS, executor)` 传入一个透传 executor，它只记录 `submit` 返回的 Future，不改变行为。

运行命令 `timeout 1200 repro/test_bugMC-3_timeout_discards_completion.sh 4000`，exit 0，完整日志在 `repro/MC-3.log`。以下是 JDK 21 的原始输出：

```
[TIMEOUT_DISCARDED_COMPLETION] trial 36: attempt#1 recorded as exception(UncheckedTimeoutException) | Future#1 = NORMAL value="result-of-execution-1" isCancelled()=false | callable returned +91.6us after (submit + limit), worker interrupted=false | callable executions=2 (bodies completed=2) | attempts seen by listener=2 | Retryer.call() returned "result-of-execution-2"
[control TIMEOUT_CANCELLED] trial 2004: attempt#1 recorded as exception(UncheckedTimeoutException) | Future#1 = CANCELLED isCancelled()=true | callable returned +91.4us after (submit + limit), worker interrupted=true | callable executions=2 (bodies completed=2) | Retryer.call() returned "result-of-execution-2"
summary A: retryIfException() + stopAfterAttempt(2):
  SUCCESS                          2020   callable return time vs (submit + limit): min -1010.8us, median +48.6us, max +1486.7us
  TIMEOUT_CANCELLED                1715   callable return time vs (submit + limit): min +44.4us, median +92.4us, max +1883.6us
  TIMEOUT_DISCARDED_COMPLETION      261   callable return time vs (submit + limit): min +44.5us, median +73.7us, max +115.0us
  TIMEOUT_CANCELLED               x1714  attempt#1=exception(UncheckedTimeoutException), callable executions=2, call() returned "result-of-execution-2"
  TIMEOUT_DISCARDED_COMPLETION    x261  attempt#1=exception(UncheckedTimeoutException), callable executions=2, call() returned "result-of-execution-2"
[TIMEOUT_DISCARDED_COMPLETION] trial 5: attempt#1 recorded as exception(UncheckedTimeoutException) | Future#1 = NORMAL value="result-of-execution-1" isCancelled()=false | callable returned +69.9us after (submit + limit), worker interrupted=false | callable executions=1 (bodies completed=1) | attempts seen by listener=1 | Retryer.call() threw ExecutionException(UncheckedTimeoutException)
  TIMEOUT_CANCELLED               x1730  attempt#1=exception(UncheckedTimeoutException), callable executions=1, call() threw ExecutionException(UncheckedTimeoutException)
  TIMEOUT_DISCARDED_COMPLETION    x247  attempt#1=exception(UncheckedTimeoutException), callable executions=1, call() threw ExecutionException(UncheckedTimeoutException)
RESULT: TIMEOUT_DISCARDED_COMPLETION hits: config A=261, config B=247      (JDK 21.0.13.1)
RESULT: TIMEOUT_DISCARDED_COMPLETION hits: config A=319, config B=252      (JDK 11.0.33.1)
```

- **路径可达**：16000 次 trial 中有 1079 次进入反例状态，即 attempt 被记为超时，而它的 Future 是 NORMAL 且持有结果，`cancel` 失败，worker 未被中断。
- **每次命中都已超时**：callable 在（`submit()` 返回 + 1 ms）之后 +42.3 到 +117.1 µs 才返回，晚于最早可能的截止时刻。成功与超时的分界取决于调用线程什么时候醒来：成功的 trial 最晚有 +1486.7 µs 才完成的。
- **调用方看不出区别**：在 Retryer 调用方和 listener 看到的结果里（attempt 记录、执行次数、`call()` 的返回或异常），MC-3 状态与普通的 cancel 成功型超时对照组完全一致。只有私有 Future 的状态（NORMAL 与 CANCELLED）和 worker 是否被中断不同。

为什么不是 REPRODUCED：仅 Level 0 就能走到反例状态，但没有任何真实调用方看到错误结果。`Retryer.call`（`Retryer.java:162-171`）和 listener 拿到的是文档规定的超时结果，那次额外执行也是用户的重试谓词对任何超时 attempt 都会要求的。也不是 MASKED：没有任何防护机制在掩盖问题，代码的行为就是它的契约。

## Recommendation
- **Spec**：已写语义草稿 `confirmation/MC-3/repair-request.body.md`（target `INVARIANT`，scope 为 `NoDiscardedCompletion` / `MC_hunt_s1_timelimit.cfg`），已用 dispatcher 的 `_parse_repair_draft` 校验通过。建议修订 `NoDiscardedCompletion`：
  - 只禁止"超时判定时任务已是 NORMAL 却仍记为超时"，这一点代码由 `FutureTask.java:406-410`、`:202-204` 保证。
  - 不再标记在超时判定之后、`cancel(true)` 之前才落地的完成。
  - 如果无法非空洞地表达，就把它从该 cfg 中移除并标为不适用。
  - 中断变体（`SimpleTimeLimiter.java:156`）归 MC-4，不在本次改动范围内。
- **代码**（可选的语义改进，不属于缺陷修复）：如果希望"完成优先"，`FixedAttemptTimeLimit.call` 可以自己做 submit/get，并在 `cancel(true)` 返回 `false` 且 `isDone() && !isCancelled()` 时返回 Future 的结果。
- 没有写 `issue.json`：PENDING REPAIR 不进入 persistent-findings 注册表。worktree 未改动。

## Repair round 1 evidence
<!-- specular-repair-token: 3eefa76b5b37ed587e41b6cbdb823026 -->
- **Repair request**: `/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec/repair-requests/RR-001.md`
- **Phase 3 result**: r1 (phase3-repair): NoDiscardedCompletion now checks only the caller-interrupt path (CallerIE, MC-4); the timeout path is the documented outcome and its supported part is GetTimeout's guard. Off (vacuous) in s1_timelimit, s4_executor, s4_shutdown, s4_wrap_samepool. 380/380 traces; MC.cfg exhaustive; s1_timelimit re-run: only MC-1/MC-2, then exhaustive; acceptance control exhaustive; still violated by the interrupt path in s2_interrupt_fixed, s2_wrap_cancel, sharing. MC-3 is not a current violation. Evidence: spec/output/repair-r1/.

---

## Entry 4: A caller interrupt during a time-limited attempt is swallowed: retrying continues, `call()` returns normally or throws `ExecutionException`, and the interrupt status is lost

- **Finding ID**: MC-4
- **Status**: REPRODUCED
- **Debate**: not run
- **Transcript**: /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-4/debate.md

running pwd && ls -la && git status 2>&1 | head -5; ls -la /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specu...
running ls -la /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation/* ; ls -la...
running ls -la /home/ubuntu/guava-retrying-20261126/Specular/.claude/skills/ ; ls -la /home/ubuntu/guava-retrying-20261126/Specular/.claude/skills/bug-confirmation 2...
Reading the skill in full.
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation && cat SKILL.md && echo ===== && cat guide.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation && cat phases/01-investigation.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation && cat phases/02-reproduction.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation && cat references/persistent-findings.md && echo ====== && cat references/repair-req...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-4 && cat .resume-leas...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-4/worktree && find sr...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-4/worktree && cat -n...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying && ls -la; ls -la .specular-output | head -50; find /h...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output && cat persistent-findings-context.js...
Skill 已读完。下面进入 Phase 1：先看构建配方和 Guava 22.0 的 `SimpleTimeLimiter` 源码。
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output && cat analysis-evidence/build/pom.xm...
running find / -path /proc -prune -o \( -name "SimpleTimeLimiter.java" -o -name "guava-22.0-sources.jar" \) -print 2>/dev/null | head -20; ls /home/ubuntu/scratch/ 2...
running cd /home/ubuntu/scratch/guava22-sources-dl && sha1sum guava-22.0-sources.jar; cat -n extracted/com/google/common/util/concurrent/SimpleTimeLimiter.java | sed...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec/output && ls -la hunt_s2_interru...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec/output && head -c 6000 hunt_s2_i...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec/output && awk '/^State [0-9]+:/{...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec/output && for f in hunt_s2_inter...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec/output && awk '/^State [0-9]+:/{...
Phase 1 Step 1（代码审计）已有足够事实。现在做 Step 2/3：查 git 历史与上游 issue/PR，确认是否已有人报告过这个机制。
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-4/worktree && git log...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-4/worktree && git sho...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-4/worktree && cat -n...
running which gh && gh auth status 2>&1 | head -5; timeout 60 gh api -X GET search/issues -f q='repo:rholder/guava-retrying interrupt' -f per_page=50 --jq '.total_co...
running for q in 'repo:rholder/guava-retrying InterruptedException' 'repo:rholder/guava-retrying interrupted' 'repo:rholder/guava-retrying interruption' 'repo:rholde...
Search API 触发了速率限制（并行 worker 共用账号）。改用普通 REST API 拉取上游全部 issue/PR（含已关闭/已合并）到本地再 grep。
running WD=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-4; mkdir -p $WD/notes...
running WD=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-4; python3 -I -c " im...
running WD=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-4; timeout 120 gh api...
running which specular; OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; timeout 60 specular...
running ls /home/ubuntu/guava-retrying-20261126/Specular/ | head -40; ls /home/ubuntu/guava-retrying-20261126/Specular/bin 2>/dev/null; find /home/ubuntu/guava-retry...
running cd /home/ubuntu/guava-retrying-20261126/Specular && head -20 specular; OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-202611...
running cd /home/ubuntu/guava-retrying-20261126/Specular && ls case-studies | head -80; grep -ril "guava-retrying\|rholder" case-studies 2>/dev/null | head
running F11=$(find /home/ubuntu/scratch/jdk11u-src -name FutureTask.java -path "*java/util/concurrent*" 2>/dev/null | head -1); F21=$(find /home/ubuntu/scratch/jdk-s...
running ls /home/ubuntu/scratch/jdk11u-src /home/ubuntu/scratch/jdk-src | head; find /home/ubuntu/scratch/jdk11u-src /home/ubuntu/scratch/jdk-src -name FutureTask.ja...
running for v in 11 21; do F=/home/ubuntu/scratch/jdk-src/$v/java/util/concurrent/FutureTask.java; echo "=== JDK $v: $F"; grep -n "private int awaitDone" $F; awk '/p...
running for v in 11 21; do echo "=== installed JDK $v src.zip"; unzip -p /usr/lib/jvm/java-$v-openjdk-amd64/lib/src.zip java.base/java/util/concurrent/FutureTask.jav...
running unzip -l /usr/lib/jvm/java-11-openjdk-amd64/lib/src.zip 2>&1 | grep -i "concurrent/FutureTask" | head; ls -la /usr/lib/jvm/java-11-openjdk-amd64/lib/src.zip;...
running ls ~/.m2/repository/com/google/code/findbugs/jsr305/ 2>/dev/null; find ~/.m2 -name "jsr305-2.0.2.jar" -o -name "junit-4.11.jar" -o -name "hamcrest-core-1.3.j...
running WD=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-4; python3 -I -c " im...
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-4/investigation.md
Phase 1 记录完成。进入 Phase 2：先确认 builder 默认值和 block 策略实现，再写复现程序。
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-4/worktree/src/main/j...
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/test_bugMC-4_interrupt_swallowed.sh
Fix one hack in the script (use `Thread.yield()` directly, drop the `sed`) and tighten F's classification (r1 = benign regardless of when the interrupt lands).
running F=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/test_bugMC-4_interrupt_swallowed...
Now run it (bounded by an outer `timeout`), capturing the full output.
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output && timeout 900 bash repro/test_bugMC-...
running cd /home/ubuntu/guava-retrying-20261126/Specular && grep -rln "def.*validate\|\"dependencies\"\|'dependencies'" src/specular | head; F=$(grep -rln "inherited...
running cd /home/ubuntu/guava-retrying-20261126/Specular && grep -n "REQUIRED\|required\|ALLOWED\|allowed\|\"root\"\|'root'\|roots\|title\|160\|status\|def validate\...
running cd /home/ubuntu/guava-retrying-20261126/Specular && sed -n '245,278p;340,460p' src/specular/persistent_findings.py
running SRC=/home/ubuntu/scratch/guava-retrying-src/guava-retrying; WT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-ret...
源码根目录与 worktree 一致。再跑一次复现，确认结果稳定（确定性场景应每次都触发）。
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output && /usr/bin/time -f "wall=%es" timeou...
结果稳定：A/B/B2/C/D 两次都确定性触发，F 的计数也一致。现在写 `issue.json`，先核对依赖边界行在源码根中是否唯一。
running SRC=/home/ubuntu/scratch/guava-retrying-src/guava-retrying/src/main/java/com/github/rholder/retry; python3 -I - "$SRC" <<'PY' import sys src=sys.argv[1] chec...
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-4/issue.json
running cd /home/ubuntu/guava-retrying-20261126/Specular && OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/....
`issue.json` 校验通过（`valid: true`）。最后确认 worktree 未被改动，并列出本 finding 产物。
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; git -C $OUT/confirmation/MC-4/workt...
## MC-4 确认结果：REPRODUCED（Level 0，JDK 21 和 JDK 11 都复现）

- **Source**: MC
- **Novelty**: NEW
- **Location**: `src/main/java/com/github/rholder/retry/Retryer.java:162`
- **Severity**: High
- **Reproduction test**: `repro/test_bugMC-4_interrupt_swallowed.sh`
- **Persistent record**: `confirmation/MC-4/issue.json`，已通过 `specular findings validate`（`"valid": true`）

## Description
用 `AttemptTimeLimiters.fixedTimeLimit` 时，调用 `Retryer.call()` 的线程在整个尝试期间都停在 Guava `SimpleTimeLimiter.callWithTimeout` 的 `future.get` 里（`AttemptTimeLimiters.java:107`，`amInterruptible=true`）。这时中断它，会依次发生：

1. JDK 的 `FutureTask.awaitDone` 先**清除中断位**，再抛 `InterruptedException`（JDK 11 `FutureTask.java:416-418`，JDK 21 `:469-471`）。
2. Guava 执行 `future.cancel(true)`，然后把这个异常原样抛出（`SimpleTimeLimiter.java:155-157`）。它不检查 `cancel` 是否成功，所以一个已经完成的尝试结果也会被丢掉。
3. `Retryer.call` 的 `catch (Throwable t)`（`:162-163`）把它当成一次普通的失败尝试，交给拒绝谓词和停止策略处理。
4. 中断位只在 `blockStrategy.block` 抛异常时恢复（`:179-181`）。但中断位此时已经被清掉，`Thread.sleep` 不会抛，所以这条恢复路径走不到。

结果是中断被吞掉，重试继续。按配置不同，`call()` 会正常返回、抛 `ExecutionException(InterruptedException)` 或抛 `RetryException`，三种情况中断位都是清除的。这违反了 `Retryer.java:151-153`（"if the thread is interrupted, this exception is thrown and the thread's interrupt status is set"）和 `:59-61`（"retry ... unless ... the thread is interrupted"）。

## Trigger scenario
只用公开 API：`RetryerBuilder` + `fixedTimeLimit(10, SECONDS)` + `Retryer.call` / `Retryer.wrap`，用 `Thread.interrupt` 或 `ExecutorService.shutdownNow` 发中断。

| 场景 | 配置与操作 | 结果 | 对应 trace / invariant |
|---|---|---|---|
| A | `retryIfException()`；attempt 1 进行中时中断调用线程 | 中断被吞，发起 attempt 2，正常返回 | bfs5 `InterruptPreserved` + bfs3 `NoRetryAfterObservedInterrupt` |
| B | `retryIfExceptionOfType(IOException)`；线程进入 `call()` 时已带中断位 | `ExecutionException(InterruptedException)`；callable 多数情况一次都没运行，却计了 attempt #1 | narrow_bfs1 `ExecutionExceptionMeansCallableThrew` + bfs1 `CountedImpliesInvoked` |
| B2 | 同 B 的谓词，中断发生在尝试中途 | `ExecutionException(InterruptedException)` | — |
| C | `retryIfException()` + `stopAfterAttempt(1)` | 抛 `RetryException`，但中断位清除 | ledger D-5 的这个出口 |
| D | 把 `retryer.wrap(svc)` 提交给 `ExecutorService`，然后 `shutdownNow()` + `awaitTermination(2s)` | 停不下来 | 真实调用方 |
| F | 让 attempt 1 完成的时刻和中断时刻相互竞争（随机时序，统计） | 已完成的结果被丢弃，callable 又跑一次 | bfs2 `NoDiscardedCompletion` |

每个场景都配了对照组：同样的 callable 和配置，只去掉 `fixedTimeLimit`。callable 是"配合中断、不吞中断位"的写法（检测到中断就抛 `InterruptedIOException`，中断位保持置位，和 NIO `ClosedByInterruptException` 的约定一样）。这样对照组走的是 `:179-181` 的正常路径，把 MC-4 和 MC-5/MC-6（callable 自己吞掉中断）分开了。

## Developer intent
- **契约**：`Retryer.java:151-153` 和 `:59-61`。
- **已有测试**：`RetryerBuilderTest.java:384-414` `testInterruption` 断言抛 `RetryException` 且 `Thread.currentThread().isInterrupted()`。它只覆盖不带时间限制的路径。`AttemptTimeLimiterTest` 只测超时，没有中断相关测试。
- **历史**：`7e474be`（2013，上游 PR #1）把 `callable.call()` 换成 `attemptTimeLimiter.call(callable)`，在调用线程上引入了库自己的可中断等待，但 catch-all 和中断处理都没改。附近没有 TODO/FIXME。
- **上游检索**：拉取了全部 106 个 issue/PR（含已关闭/已合并，最新到 2026-09 关闭的 #107）和全部 185 条评论，另外跑了 search API 查询（之后触发了速率限制）。没有任何条目报告这个机制。#67 也在 `Retryer.java:162`，但讲的是 catch-all 捕获 `Error`/OOME，机制不同。#29、#63、#92、#94 都无关。上游 master 最新提交仍是 `177b6c9`，没有修复。
- `specular findings lookup` 返回 `[]`。

## Reproduction result
- **级别**：Level 0。库源码未改动（`177b6c9`，worktree clean）；Guava 22.0 的 sha1 与随 jar 发布的 `.sha1` 一致。测试线程只负责排定中断的时机：等 attempt 1 已开始、调用线程已 park 之后再中断。
- **命令**（在 `.specular-output/` 下执行）：`timeout 900 bash repro/test_bugMC-4_interrupt_swallowed.sh`
- **退出码**：0（两个 JDK 都是 `RESULT: BUG REPRODUCED`）。完整输出在 `confirmation/MC-4/repro-run1.log`，第二次运行 `repro-run2.log` 结果一致。

JDK 21 的关键输出（log 第 10、35、65、90、98、110 行）：
```
=== A: retryIfException() (stop=never, wait=none); caller interrupted while attempt 1 runs   [bfs5, bfs3]
  [fixedTimeLimit] returned normally {value=result-of-invocation-2}, interruptStatusAfterCall=false, callableInvocations=2, attemptsSeenByListener=[#1 InterruptedException, #2 result(result-of-invocation-2)], elapsed=7ms
      caller stack when interrupted:
        at java.base/java.util.concurrent.FutureTask.awaitDone(FutureTask.java:497)
        at java.base/java.util.concurrent.FutureTask.get(FutureTask.java:203)
        at com.google.common.util.concurrent.SimpleTimeLimiter.callWithTimeout(SimpleTimeLimiter.java:154)
        at com.github.rholder.retry.AttemptTimeLimiters$FixedAttemptTimeLimit.call(AttemptTimeLimiters.java:107)
        at com.github.rholder.retry.Retryer.call(Retryer.java:160)
  [control       ] RetryException {failedAttempts=1, last=#1 InterruptedIOException}, interruptStatusAfterCall=true, callableInvocations=1, attemptsSeenByListener=[#1 InterruptedIOException [interrupt pending]], elapsed=6ms
=== B: retryIfExceptionOfType(IOException); thread already interrupted when call() starts   [narrow_bfs1, bfs1]
  [fixedTimeLimit] ExecutionException {cause=java.lang.InterruptedException}, interruptStatusAfterCall=false, callableInvocations=0, attemptsSeenByListener=[#1 InterruptedException], elapsed=0ms
  [fixedTimeLimit] 200 runs: {ExecutionException / status=clear / invocations=0=190, ExecutionException / status=clear / invocations=1=10}
  [control       ] RetryException {failedAttempts=1, last=#1 InterruptedIOException}, interruptStatusAfterCall=true, callableInvocations=1, ...
=== C: retryIfException() + stopAfterAttempt(1); caller interrupted while attempt 1 runs   [ledger D-5 RetryException exit]
  [fixedTimeLimit] RetryException {failedAttempts=1, last=#1 InterruptedException}, interruptStatusAfterCall=false, callableInvocations=1, attemptsSeenByListener=[#1 InterruptedException], elapsed=4ms
  [control       ] RetryException {failedAttempts=1, last=#1 InterruptedIOException}, interruptStatusAfterCall=true, ...
=== D: real consumer -- ExecutorService.submit(retryer.wrap(svc)); shutdownNow(); awaitTermination(2 s)
  [fixedTimeLimit] invocations at shutdownNow=2, awaitTermination(2s)=false after 2000ms, invocations started after shutdownNow=18, terminated after service recovered=true, task outcome: returned ok (invocation 21)
  [control       ] invocations at shutdownNow=2, awaitTermination(2s)=true after 0ms, invocations started after shutdownNow=0, terminated after service recovered=true, task outcome: ExecutionException(com.github.rholder.retry.RetryException: Retrying failed to complete successfully after 2 attempts.)
=== F: retryIfException() + stopAfterAttempt(3); attempt 1 returns at t0+offset, caller interrupted at t0   [bfs2]
  [fixedTimeLimit] 3000 trials: attempt 1 result returned (benign)=921, attempt cancelled+retried with status cleared=1973, COMPLETED attempt discarded+retried with status cleared=106, other=0
      example: attempt-1 FutureTask state: done, NOT cancelled, value=r1; attempt-1 body: returned r1; listener: [#1 InterruptedException, #2 result(r2)]; call() returned r2; interrupt status after call: false; callable invocations: 2
  controls (no time limiter) violating the contract: 0
RESULT: BUG REPRODUCED
```

JDK 11.0.33.1 结果相同：

| 场景 | JDK 11 结果 |
|---|---|
| A | 正常返回，`interruptStatusAfterCall=false` |
| B | 200/200 次抛 `ExecutionException`、中断位清除，其中 186 次 callable 调用数为 0 |
| C | `RetryException`，中断位清除 |
| D | `awaitTermination(2s)=false`，之后又调用 18 次 |
| F | 134/3000 次已完成的尝试被丢弃 |

对照组 0 违例。

**和反例的对照**：
- A 的动作序列和 bfs5 一致：Submit → 在 `Wait` 处被中断 → `GetInterrupted`（清除中断位）→ 取消 → 零等待 → `BlockZero` 不抛 → 提交第 2 次尝试 → 正常返回，`intr=FALSE`。
- 差别：bfs5 中被中断时 t1 还没开始运行（NotStarted），A 中 attempt 1 已经开始。NotStarted 这个变体由 B 覆盖（190/200 次调用数为 0）。
- bfs2 trace 里 callable 是抛异常完成的（EXCEPTIONAL），F 里是正常返回（NORMAL）。违反的是同一个 invariant。

## Recommendation
1. **`Retryer.call` 处理中断**：`attemptTimeLimiter.call(callable)` 抛出 `InterruptedException` 时，按中断处理，与 `:179-181` 一致：`Thread.currentThread().interrupt(); throw new RetryException(attemptNumber, attempt);`。不要交给拒绝谓词或停止策略。
2. **区分两种中断来源**：在 `FixedAttemptTimeLimit` 中区分"调用线程被中断"和"callable 自己抛的异常"。可以改用 Guava 22 的三参数 `callWithTimeout(callable, d, unit)`：它只在调用线程被中断时抛 `InterruptedException`，callable 的异常走 `ExecutionException`。或者自己包装 callable。
3. **已完成的结果不丢弃**：中断时如果 future 已经完成，就用它的结果（至少不要再重试），同时恢复中断位。
4. **回归测试**：在 `fixedTimeLimit` 尝试进行中中断调用线程，断言抛 `RetryException` 且 `isInterrupted()` 为 true。可直接改编本脚本的 A、C 两个场景。

## REPRODUCED 前的核对清单
1. **只用 Level 0 / Level 1 就触发了吗？** **yes**。A/B/B2/C/D 只用公开 API 和正常操作，库、Guava、JDK 都没有注入或修改。F 只是在用户 callable 里用自旋控制完成时刻（Level 1），只用于 bfs2 子结论。
2. **用了 Level 2/3 吗？** 没有。
3. **哪个真实调用方看到了错误结果？**
   - `Retryer.call` 的直接调用方：复现中是 `MC4Repro.java:99`，即任何依赖 `Retryer.java:151-153` 契约的用户代码。中断后它拿到正常返回值或 `ExecutionException`，且中断位为 false。
   - JDK `ThreadPoolExecutor` 执行的 `Retryer.RetryerCallable.call()`（`Retryer.java:317-319`，由 `Retryer.wrap` 在 `Retryer.java:195-197` 创建）：`shutdownNow()` 后 `awaitTermination(2s)` 返回 false，服务又被调用 18 次，任务最后正常返回。
4. **坏状态是永久的吗？** 是。`call()` 返回或抛出之后中断位一直是清除的，没有任何机制补回。D 场景中重试循环一直跑到服务恢复才结束（测试主动把 `svc.down` 置为 false），和中断无关。没有可称为 MASKED 的掩盖机制。

## Repair round 1 evidence
<!-- specular-repair-token: 3eefa76b5b37ed587e41b6cbdb823026 -->
- **Current violation analysis**: With fixedTimeLimit (amInterruptible=true, AttemptTimeLimiters.java:107), an interrupt of the thread running call() is consumed by Future.get (status cleared, JDK11 FutureTask.java:416-419); Guava cancels the attempt and rethrows InterruptedException (SimpleTimeLimiter.java:155-157). Retryer.call catches it like any Throwable (Retryer.java:162-163) and lets the rejection predicate decide; the status is restored only around blockStrategy.block (:179-181). TLC: with retryIfException() the next attempt runs and call() returns normally with the status clear (hunt_s2_interrupt_fixed_bfs5.out, 25 s…
- **Counterexample**: `spec/output/hunt_s2_interrupt_fixed_bfs5.out`

## Phase 4 confirmation after repair round 1

running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-4 && ls -la && echo -...
running ls -la ~/.claude/skills 2>/dev/null; echo ---; ls -la /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation /home/ubuntu/guava-retrying-20261...
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation && cat SKILL.md && echo ======= && cat guide.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation && cat phases/01-investigation.md && echo ======= && cat phases/02-reproduction.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation && cat references/persistent-findings.md && echo ======= && cat references/repair-re...
Skill 已读完。现在读取该 finding 的已有证据（`verdict.json` body、`investigation.md`、`issue.json` 等），在此基础上继续，而不是重做。
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-4 && python3 -I -c "...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-4 && cat investigatio...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output && cat confirmation/MC-4/issue.json &...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output && sha256sum repro/test_bugMC-4_inter...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output && cat -n repro/test_bugMC-4_interrup...
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; WT=$OUT/confirmation/MC-4/worktree;...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec/output/repair-r1 && head -c 5000...
running mkdir -p /tmp/mc4-tools && cat > /tmp/mc4-tools/tracediff.py <<'PY' import re, sys def parse(path): txt = open(path).read() hdr = re.findall(r'^Error: .*$',...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec/output/repair-r1 && python3 -I /...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec/output && for f in hunt_s2_inter...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-4 && grep -n -E 'wall...
running N=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-4/notes; timeout 60 gh...
running N=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-4/notes; python3 -I -...
#63、#65 都不涉及这个机制，Novelty 保持 NEW。再按 persistent-findings 流程跑一次 `lookup`。
running cd /home/ubuntu/guava-retrying-20261126/Specular && OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/....
已确认没有新报告。接下来扩展复现，覆盖 repair-r1 新增的路径。先核对 `fixedTimeLimit(d, unit, executor)` 和 `RetryerCallable` 的公开签名。
running WT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-4/worktree/src/main/j...
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/test_bugMC-4_wrap_cancel_sharing.sh
脚本已写好。用外层 `timeout` 执行，输出保存到 `confirmation/MC-4/repro-r1-run1.log`。
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output && chmod +x repro/test_bugMC-4_wrap_c...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output && /usr/bin/time -f "wall=%es" timeou...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec/output && for f in hunt_s2_inter...
reading /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-4/investigation.md
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-4/investigation.md
接下来更新 `issue.json`：补充新的触发方式、反例、invariant 名称和证据文件，然后用 `specular findings validate` 校验。
reading /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-4/issue.json
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-4/issue.json
running cd /home/ubuntu/guava-retrying-20261126/Specular && OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/....
`issue.json` 校验通过（`"valid": true`，标题 152 字符）。最后确认 worktree 未被改动，并列出本轮产物。
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; git -C $OUT/confirmation/MC-4/workt...
所有产物都已就位。写最终结论前，再核对一个推荐修复依赖的事实：Guava 22.0 是否已有三参数 `callWithTimeout`。
running S=/home/ubuntu/scratch/guava22-sources-dl/extracted/com/google/common/util/concurrent; grep -n -E 'public <T> T callWithTimeout|@since|throws (TimeoutExcepti...
## MC-4 续跑结论（repair round 1 之后）：REPRODUCED

- **Source**: MC
- **Novelty**: NEW
- **Location**: `src/main/java/com/github/rholder/retry/Retryer.java:162`
- **Severity**: High
- **Reproduction test**:
  - 原有脚本：`repro/test_bugMC-4_interrupt_swallowed.sh`（场景 A/B/B2/C/D/F），本轮回归运行一次。
  - 本轮新增：`repro/test_bugMC-4_wrap_cancel_sharing.sh`（场景 W1/W2/S1/S2，覆盖 repair-r1 的三条反例）。
- **Persistent record**: `confirmation/MC-4/issue.json` 已更新，`specular findings validate` 返回 `"valid": true`。`investigation.md` 新增了 repair round 1 一节。

### 本轮对已有证据的更正与补充
- **前提未变**：源码、Guava 22.0 jar（sha1 `3564ef38…`）、JDK 21.0.13.1 / 11.0.33.1 都没有变化。worktree 在 `177b6c9`，没有改动，4 个相关源文件与 source root 字节一致。上一轮的 A/B/B2/C/D/F 结论全部保留，本轮回归运行 `repro-run3.log` 再次全部复现。
- **RR-001 不影响本 finding**：RR-001 把 `NoDiscardedCompletion` 收窄为只看中断路径（超时路径即原 MC-3，已撤回）。本 finding 引用的 bfs1/2/3/5 和 narrow_bfs1 都是中断路径，trace 中 `mc.timeout = 0`。场景 F 也是：限时 10 s，attempt 在约 300 µs 内完成，不会发生超时。所以这些证据在收窄后的 invariant 下仍然有效。
- **三条新反例逐一说明**：
  - `repair1_ctl_s2_wrap_cancel_ndc.out`：新的只是中断来源。外层 Future 的 `cancel(true)`（`MCCancelOuter`）中断了正在跑 `retryer.wrap(...)` 的线程；库内走的路径不变。
  - `repair1_ctl_sharing_ndc.out` 和 `repair1_ctl_sharing_cir.out`：c2 全程处于 `Idle`。**更正**："with two callers"不是一个新的跨 caller 机制，只是双 caller 配置里的单 caller 交错。CIR 在 repair 后的名称是 `CountedImpliesInvokedNoStartRace`。
- **精化（上一轮描述 bfs2 时没有提到）**：bfs2 和 wrap_cancel_ndc 里，`MCGetInterrupted` 发生在 t1 已经离开 NEW 之后。
  - JDK 的 `awaitDone` 一旦读到 `state >= COMPLETING`，就不会再抛 IE。
  - 所以这个顺序要成立，调用线程必须先读到 NEW，然后被抢占，直到中断之后才执行 `Thread.interrupted()`。这是可达的，只是窗口窄；模型把"读 state"和"检查中断"合成了一个动作。
  - 现实中更宽的窗口是 sharing_ndc 的顺序：IE 在 t1 还是 NEW 时抛出，随后 t1 在 Guava 执行 `cancel(true)` 之前完成，`cancel` 返回的 false 被忽略。
  - 两种顺序走的是同一段代码，违反同一个 invariant。F/W2/S2 测到的是后一种。
- **更正**：上一轮写"上游最新到 2026-09 关闭的 #107"不准确。最近关闭的是 #84（PR，2026-09-20 未合并即关闭）。两者都与中断无关。

## Description
使用 `AttemptTimeLimiters.fixedTimeLimit` 时，调用 `Retryer.call()` 的线程在整个 attempt 期间都停在 Guava `SimpleTimeLimiter.callWithTimeout` 的 `future.get` 中（`AttemptTimeLimiters.java:107`，`amInterruptible=true`）。这时中断该线程，会依次发生：

1. JDK `FutureTask.awaitDone` 清除中断位，抛出 `InterruptedException`。
2. Guava 执行 `future.cancel(true)` 后把异常原样抛出（`SimpleTimeLimiter.java:155-157`），不检查 `cancel` 是否成功。
3. `Retryer.call` 的 `catch (Throwable)`（`:162-163`）把它当作普通的失败 attempt，交给拒绝谓词和停止策略处理。
4. 中断位只在 `blockStrategy.block` 抛异常时才恢复（`:179-181`）。由于中断位已经被清除，这条路径走不到。

结果是重试继续进行。`call()` 可能正常返回，也可能抛 `ExecutionException(InterruptedException)` 或 `RetryException`，但三种情况下中断位都是清除的。此外：
- 某个 attempt 被计数了，但它的 callable 从未运行。
- 已经完成的 attempt 结果会被丢弃，callable 被再执行一次。
- `Future.cancel(true)` 和 `shutdownNow()` 都停不下 `wrap()` 出来的任务。

这违反了 `Retryer.java:151-153`（"if the thread is interrupted, this exception is thrown and the thread's interrupt status is set"）和 `:59-61`（中断后不再重试）。

## Trigger scenario
所有场景只用公开 API：`RetryerBuilder`、`fixedTimeLimit(10, SECONDS[, executor])`，以及 `Retryer.call` / `Retryer.wrap`。中断来源是 `Thread.interrupt`、`Future.cancel(true)` 或 `ExecutorService.shutdownNow`。

| 场景 | 配置 / 操作 | 结果（`fixedTimeLimit`） | 对应反例 |
|---|---|---|---|
| A | `retryIfException()`，attempt 1 进行中时中断 | 发起 attempt 2，正常返回，中断位清除 | bfs5 `InterruptPreserved`，bfs3 |
| B | `retryIfExceptionOfType(IOException)`，进入 `call()` 前已带中断位 | `ExecutionException(IE)`，多数运行中 callable 0 次调用，却计了 #1 | narrow_bfs1，bfs1 |
| B2 / C | 同上谓词但在中途中断 / `stopAfterAttempt(1)` | `ExecutionException(IE)` / `RetryException`，中断位都清除 | ledger D-5 |
| D | `ExecutorService` 上跑 `wrap()` 任务，调用 `shutdownNow()` | `awaitTermination(2s)=false`，之后又调用 18 次 | — |
| F | attempt 1 的完成与中断赛跑 | 已完成的 r1 被丢弃并重跑 | bfs2 `NoDiscardedCompletion` |
| **W1** | `wrap()` 任务 attempt 1 进行中时，外层 `outer.cancel(true)` | `cancel` 返回 true，之后又调用 18 次，线程被占 2 s，最后正常返回，中断位清除 | wrap_cancel_ndc（`MCCancelOuter`） |
| **W2** | 同 W1，attempt 1 在 cancel 前后完成（NORMAL 或 EXCEPTIONAL） | 已完成的结果（r1 或 IOException）被丢弃并重跑 | wrap_cancel_ndc（NDC） |
| **S1** | 两个线程共享一个 Retryer 和 executor；c1 进入前已带中断位，c2 持续调用 | 计了 #1 但 callable 从未进入；之后重试并正常返回，中断位清除 | sharing_cir |
| **S2** | 同 S1 的共享配置，c1 的 attempt 1 与中断赛跑 | 已完成的 r1 被丢弃并重跑；c2 无异常 | sharing_ndc |

每个场景都有对照组，用同样的 callable 但不加时间限制。callable 配合中断：抛 `InterruptedIOException` 并保留中断位。对照组都按契约抛 `RetryException`，且中断位保持置位，从而把 MC-4 和 callable 自己吞掉中断的情况（MC-5/MC-6）区分开。

## Developer intent
- **契约**：`Retryer.java:151-153`、`:59-61`（构造器文档 `:76-78`、`:94-96`、`:113-115` 有同样的表述）。
- **现有测试**：`RetryerBuilderTest.java:384-414` 中的 `testInterruption` 断言抛 `RetryException` 且 `isInterrupted()` 为 true，但只覆盖不限时的路径。没有任何测试覆盖 `fixedTimeLimit` 下的中断。
- **代码历史**：`7e474be`（上游 PR #1）在调用线程上引入了可中断的 `future.get`，但没有同步修改 catch-all 和中断处理逻辑。代码附近没有 TODO 或 FIXME。
- **上游检索**：保存了全部 106 个 issue/PR 和 185 条评论，本轮又查了一遍最新动态（#84 和 #107 都未合并即关闭，master 仍是 `177b6c9`）。关键词 `interrupt` 只命中 #63（BlockStrategy 不 sleep 的问题）；`cancel`、`shutdownNow`、`RetryerCallable` 没有命中；`wrap` 的命中都与这个问题无关。没有任何条目报告过这个机制。#67 虽然也在 `:162`，但讲的是 `Error` 被捕获，机制不同。
- `specular findings lookup` 返回 `[]`。

## Reproduction result
- **级别**：Level 0（A/B/B2/C/D、W1、S1）和 Level 1（F、W2、S2：用户 callable 自旋到指定时刻）。库、Guava、JDK 都没有修改。W2/S 中传给 `fixedTimeLimit(d, unit, executor)` 的 executor 等价于 `newCachedThreadPool()`，只额外记录每个 attempt 的 FutureTask 以及 callable 是否被进入。
- **命令**（在 `.specular-output/` 下执行）：
  - `timeout 900 bash repro/test_bugMC-4_wrap_cancel_sharing.sh` → exit 0，wall 12.09 s，输出在 `confirmation/MC-4/repro-r1-run1.log`。
  - `timeout 900 bash repro/test_bugMC-4_interrupt_swallowed.sh` → exit 0，wall 9.66 s，输出在 `confirmation/MC-4/repro-run3.log`（回归运行）。

`repro-r1-run1.log` 在 JDK 21 上的输出：
```
=== W1: outer.cancel(true) of ExecutorService.submit(<task running retryer.wrap(svc)>) while attempt 1 is in flight   [repair1_ctl_s2_wrap_cancel_ndc: MCCancelOuter]
  [fixedTimeLimit] outer.cancel(true)=true, outer.get(): CancellationException; invocations at cancel=1, invocations started in the 2 s after cancel=18, next task on the pool started 2006 ms after cancel
      RetryerCallable.call(): returned ok (invocation 19), interrupt status after call()=false, ended 2006 ms after cancel
      listener (pool thread): [#1 InterruptedException, #2 IOException, #3 IOException, ... (19 attempts in total) ..., #18 IOException, #19 result(ok (invocation 19))]
        at java.base/java.util.concurrent.FutureTask.awaitDone(FutureTask.java:497)
        at com.google.common.util.concurrent.SimpleTimeLimiter.callWithTimeout(SimpleTimeLimiter.java:154)
        at com.github.rholder.retry.AttemptTimeLimiters$FixedAttemptTimeLimit.call(AttemptTimeLimiters.java:107)
  [control       ] outer.cancel(true)=true, ... invocations started in the 2 s after cancel=0, next task on the pool started 0 ms after cancel
      RetryerCallable.call(): RetryException: Retrying failed to complete successfully after 1 attempts., interrupt status after call()=true, ended 0 ms after cancel
  [fixedTimeLimit, attempt 1 NORMAL] 2000 trials: attempt-1 outcome observed (benign)=578, ..., attempt cancelled+retried after cancel(true)=1403, COMPLETED attempt discarded+retried=19, other=0
      example: outer.cancel(true)=true; attempt-1 FutureTask: done NOT cancelled, value=r1; listener: [#1 InterruptedException, #2 result(r2)]; RetryerCallable.call(): returned r2; interrupt status after: false; callable invocations: 2
  [fixedTimeLimit, attempt 1 EXCEPTIONAL] 2000 trials: ... COMPLETED attempt discarded+retried=26, other=0
      example: outer.cancel(true)=true; attempt-1 FutureTask: done NOT cancelled, threw java.io.IOException: attempt-1 failed; listener: [#1 InterruptedException, #2 result(r2)]; ...
  [S1 c1 pre-interrupted] 200 runs: {returned c1-ok / status=clear / #1 InterruptedException (attempt-1 callable NEVER entered)=196, returned c1-ok / status=clear / #1 InterruptedException (attempt-1 callable entered)=4}
  [S2 c1 interrupted at t0] 3000 trials: attempt-1 result returned (benign)=823, attempt cancelled+retried with status cleared=2105, COMPLETED attempt discarded+retried=72, other=0
  [c2, sharing the Retryer, never interrupted] 64753 calls during S, anomalies=0
  controls violating the contract + anomalies on the non-interrupted sharer: 0
RESULT: BUG REPRODUCED
```

JDK 11.0.33.1 上的结果一致：

| 场景 | JDK 11 结果 |
|---|---|
| W1 | `cancel` 之后又调用 18 次，下一个任务延迟 2007 ms，最后正常返回，中断位 false；对照组 0 次调用、0 ms、`RetryException` 且中断位 true |
| W2 | 已完成的结果被丢弃 47/4000（NORMAL 24，EXCEPTIONAL 23） |
| S1 | 179/200 次 callable 从未进入 |
| S2 | 已完成的结果被丢弃 70/3000 |
| c2 | 71019 次调用，0 异常 |

回归运行 `repro-run3.log` 的结果：

| 场景 | JDK 21 | JDK 11 |
|---|---|---|
| A | `returned normally {value=result-of-invocation-2}, interruptStatusAfterCall=false` | 相同 |
| B | 200/200 抛 `ExecutionException(IE)` 且中断位清除，其中 185 次 0 调用 | 200/200，其中 192 次 0 调用 |
| C | `RetryException`，中断位清除 | 相同 |
| D | `awaitTermination(2s)=false`，之后又调用 18 次 | 相同 |
| F | 已完成的结果被丢弃 101/3000 | 87/3000 |

对照组在两个 JDK 上都是 0 违例。

**与反例的对照**：
- **W1**：与 wrap_cancel_ndc 的中断来源一致，都是对外层 Future 调 `cancel(true)` 去中断运行 `RetryerCallable` 的线程。
- **W2**：EXCEPTIONAL 分支与 trace 中 body 抛异常、attempt 已完成却被丢弃的情形对应。执行顺序有差别，原因见上文的"精化"一条。
- **S1**：与 sharing_cir 对应，attempt 在 NEW 状态被 cancel，计数了但 callable 0 次调用。
- **S2**：与 sharing_ndc 对应，调用线程拿到 IE 之后、cancel 之前，t1 完成为 NORMAL。
- **c2**：trace 中 c2 不动作；这里 c2 持续调用共享的 Retryer，作为更强的配置，结果 0 异常。

## Recommendation
1. **`Retryer.call` 正确处理中断**：调用线程自己等待时收到 `InterruptedException`，应按中断处理，与 `:179-181` 一致——执行 `Thread.currentThread().interrupt(); throw new RetryException(attemptNumber, attempt);`，而不是交给拒绝谓词或停止策略。
2. **区分两种 `InterruptedException` 的来源**：`FixedAttemptTimeLimit` 应区分"调用线程被中断"和"callable 自己抛出的异常"。Guava 22.0 已经提供三参数的 `callWithTimeout(callable, d, unit)`（`SimpleTimeLimiter.java:171-188`），它只在调用线程被中断时抛 IE，callable 的异常则包装为 `ExecutionException`。
3. **不丢弃已完成的结果**：Guava 在收到 IE 后仍会无条件 `cancel(true); throw e;`，所以要做到这一点，需要在 `FixedAttemptTimeLimit` 里自己用 executor 实现 submit/get。`cancel` 返回 false 时，采用 future 已有的结果，同时恢复中断位。
4. **回归测试**：覆盖三种情形——`fixedTimeLimit` attempt 进行中被中断（A/C）、`wrap()` 任务被 `Future.cancel(true)`（W1）、共享 Retryer 时 c1 被中断（S1）。断言：抛 `RetryException`，`isInterrupted()` 为 true，cancel 之后没有新的调用。

## REPRODUCED 前的核对清单
1. **只用 Level 0 或 Level 1 就触发了吗？** **yes**。W1、S1 以及 A/B/B2/C/D 只用公开 API 和正常操作，测试线程只负责安排事件顺序。W2、S2、F 只是让用户 callable 自旋到指定时刻（Level 1）。库、Guava、JDK 都没有修改，也没有注入状态。
2. 没有使用 Level 2 或 Level 3。
3. **看到错误结果的真实调用方**：
   - `Retryer.call` 的直接调用方（场景 A/B/C 和 S 中的 c1 线程）：中断之后拿到的是正常返回值或 `ExecutionException`，中断位为 false。
   - JDK `ThreadPoolExecutor` 执行的 `Retryer.RetryerCallable.call()`（`Retryer.java:317-318`，由 `wrap` 在 `:195-196` 创建），它的提交方受到影响：`outer.cancel(true)` 返回 true，但服务又被调用 18 次，pool 线程被占用 2006 ms，`RetryerCallable.call()` 最终正常返回且中断位清除；用 `shutdownNow()` 时 `awaitTermination(2s)=false`。
   - 在 W2、S2、F 中，已完成的结果（r1 或 IOException）被丢弃，callable 被重新执行，产生重复的副作用。
4. **坏状态是永久的吗？** 是。被清除的中断位不会被任何机制重新投递，重试循环会一直跑到成功或停止策略结束为止；W1 中循环之所以结束，是因为测试主动让服务恢复。外层 Future 丢弃 `RetryerCallable` 的结果并不构成掩盖，因为危害在那之前已经发生：取消之后的额外调用、线程被占用、中断丢失。共享 Retryer 的 c2 没有受影响，但这也不会掩盖 c1 受到的危害。因此不存在 MASKED 意义上的掩盖机制。

---

## Entry 5: Without a time limit, an `InterruptedException` thrown by the callable on the caller thread is retried and the interrupt status is lost

- **Finding ID**: MC-5
- **Status**: REPRODUCED
- **Debate**: not run
- **Transcript**: /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-5/debate.md

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

---

## Entry 6: A `wrap()` task cancelled with `cancel(true)` / `shutdownNow()` keeps retrying forever (or returns normally), and its worker thread is never released

- **Finding ID**: MC-6
- **Status**: REPRODUCED
- **Debate**: not run
- **Transcript**: /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-6/debate.md

running ls -la /home/ubuntu/.claude/skills/ 2>/dev/null; ls -la ~/.claude/plugins 2>/dev/null | head; find / -type d -name "bug-confirmation" 2>/dev/null | head -20
running cat /home/ubuntu/.claude/projects/-home-ubuntu-guava-retrying-20261126-Specular-runs-guava-retrying-opus55max-20261126-guava-retrying--specular-output-confir...
running pwd; ls -la; ls -la .claude 2>/dev/null; find . -maxdepth 4 -name "*.md" | head -50
running ls -la /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; ls -la /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation/*;...
running cat /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation/SKILL.md; echo ------; cat /home/ubuntu/guava-retrying-20261126/Specular/skills/bug...
running cat /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation/phases/01-investigation.md
running cat /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation/phases/02-reproduction.md
Skill 已读完（guide + phase 1/2）。接下来读参考格式文件，然后开始 Phase 1 代码审计。
running cat /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation/references/persistent-findings.md; echo; echo ===========; cat /home/ubuntu/guava-r...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-6/worktree && git log...
running which specular; specular --help 2>&1 | head -30; ls /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.spec...
running ls /home/ubuntu/guava-retrying-20261126/Specular/; ls /home/ubuntu/guava-retrying-20261126/Specular/bin 2>/dev/null; find /home/ubuntu/guava-retrying-2026112...
running ls -la /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/ /home/ubuntu/guava-retryin...
running file /home/ubuntu/guava-retrying-20261126/Specular/specular; head -30 /home/ubuntu/guava-retrying-20261126/Specular/specular 2>/dev/null; ls /home/ubuntu/gua...
running cd /tmp && timeout 60 /home/ubuntu/guava-retrying-20261126/Specular/specular findings --work /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retryin...
Persistent-findings lookup 无命中。开始 Phase 1：通读 `Retryer.java`。
running cat -n /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-6/worktree/src/ma...
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-6/worktree/src/main/ja...
running S=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec; ls -la $S/output/ | grep -E "hun...
running S=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec; head -60 $S/output/hunt_s2_live_...
running S=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec; grep -nE "^State [0-9]+|Back to...
running which gh curl; gh auth status 2>&1 | head -5; timeout 30 curl -sS -o /dev/null -w "%{http_code}\n" https://api.github.com/repos/rholder/guava-retrying
running cd /tmp; for q in "interrupt" "interrupted" "InterruptedException" "cancel" "wrap" "RetryerCallable" "shutdownNow" "executor" "Future"; do echo "=== $q ===";...
running mkdir -p /tmp/mc6-upstream && cd /tmp/mc6-upstream && timeout 120 gh api --paginate "repos/rholder/guava-retrying/issues?state=all&per_page=100" > issues.jso...
running cd /tmp/mc6-upstream && python3 -I -c ' import json,re raw=open("issues.json").read() dec=json.JSONDecoder(); i=0; items=[] while i < len(raw): raw2=raw[i:]....
running cd /tmp/mc6-upstream && timeout 120 gh api --paginate "repos/rholder/guava-retrying/issues/comments?per_page=100" > comments.json 2>err2.txt; timeout 120 gh...
running cd /tmp/mc6-upstream && python3 -I -c ' import json raw=open("issues.json").read(); dec=json.JSONDecoder(); i=0; items=[] while i < len(raw): raw2=raw[i:].ls...
running cd /tmp/mc6-upstream && for pr in 107 84 101; do echo "=== PR $pr ==="; timeout 60 gh api "repos/rholder/guava-retrying/pulls/$pr" --jq '{state:.state,merged...
running cd /tmp; for repo in rhuffman/re-retrying itning/guava-retrying3; do echo "##### $repo"; timeout 60 gh api "repos/$repo" --jq '.full_name + " pushed " + .pus...
running cd /tmp; for n in 24 32 36; do echo "######## re-retrying #$n"; timeout 60 gh api "repos/rhuffman/re-retrying/issues/$n" --jq '"title: " + .title + "\nstate:...
running cd /tmp; for c in e2d01c3b f1ff0bfa; do echo "######## $c"; timeout 60 gh api "repos/rhuffman/re-retrying/commits/$c" --jq '.sha + "\n" + .commit.message + "...
running ls /home/ubuntu/guava-retrying-20261126/Specular/case-studies | head -80; grep -rli "guava-retrying\|rholder" /home/ubuntu/guava-retrying-20261126/Specular/c...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-6/worktree && git bla...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-6/worktree && grep -n...
running find / -name "guava-22.0*.jar" 2>/dev/null | head; find / -name "jsr305-2.0.2*.jar" 2>/dev/null | head -3; find / -name "junit-4.11*.jar" 2>/dev/null | head...
running mkdir -p /tmp/mc6-guava-src && cd /tmp/mc6-guava-src && unzip -o -q /home/ubuntu/scratch/guava22-sources-dl/guava-22.0-sources.jar com/google/common/util/con...
running S=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec/output; sed -n 60,82p $S/hunt_s2_...
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-6/worktree; diff -r $W...
Phase 1 证据已基本齐全。先把它写入 `investigation.md`，然后进入 Phase 2 复现。先确认 `RetryListener` 的签名：
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-6/worktree/src/main/ja...
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-6/investigation.md
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/test_bugMC-6_wrap_cancel_endless_retry.sh
复现脚本已写好（场景 A–F，含对照组）。现在实际执行，外层套 `timeout`，输出存到 `repro/MC-6.log`。
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro && chmod +x test_bugMC-6_wrap_c...
running cat /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/MC-6.log | sed -n 1,140p
running cat /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/MC-6.log | sed -n 140,320p | g...
running cd /home/ubuntu/guava-retrying-20261126/Specular && grep -rn "def .*validate\|\"cause\"\|'cause'\|required\|REQUIRED" src/specular/findings*.py src/specular/...
running cd /home/ubuntu/guava-retrying-20261126/Specular && grep -n "REQUIRED\|required_fields\|_FIELDS\|def _validate_proposal\|def validate\|status.*in\b\|ALLOWED\...
running cd /home/ubuntu/guava-retrying-20261126/Specular && sed -n 240,280p src/specular/persistent_findings.py; sed -n 340,475p src/specular/persistent_findings.py;...
running ls -la /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec/ | grep -E "MC_hunt_s2|^.*MC...
running S=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec/output; for f in hunt_s2_wrap_can...
running S=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec/output; grep -E "^State [0-9]+:"...
running S=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec/output; grep -l "" $S/hunt_s2_wra...
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-6/issue.json
running cd /tmp && timeout 120 /home/ubuntu/guava-retrying-20261126/Specular/specular findings --work /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retryi...
`issue.json` 校验通过（`valid: true`，title 143 字符）。确认 worktree 未被改动、也没有残留的 Java 进程：
running git -C /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-6/worktree status...
editing /home/ubuntu/.claude/projects/-home-ubuntu-guava-retrying-20261126-Specular-runs-guava-retrying-opus55max-20261126-guava-retrying--specular-output-confirmation-MC-6--agent-cwd-t...
# MC-6 确认结果：在 Level 0 复现

结论：用 `Retryer.wrap()` 交给 executor 的任务，被 `Future.cancel(true)` 或 `shutdownNow()` 取消后会一直重试。如果后面某次 attempt 成功，它会在取消之后正常返回，副作用已经提交，中断位也是清掉的。这个任务占用的 worker 永远不会被释放。只用了公开 API，没有改库源码，也没有注入状态。5 次独立试验 5 次都触发了。

- **Source**: MC
- **Novelty**: KNOWN (cite: https://github.com/rhuffman/re-retrying/issues/32; fix-status: unfixed)
- **Location**: src/main/java/com/github/rholder/retry/Retryer.java:162
- **Severity**: High
- **Reproduction test**: `repro/test_bugMC-6_wrap_cancel_endless_retry.sh`（Level 0），输出在 `repro/MC-6.log`
- **Persistent record**: `confirmation/MC-6/issue.json`（`specular findings validate` 返回 `"valid": true`）

Novelty 判成 KNOWN 是我的取舍，会影响这条 finding 的计数方式：
- upstream `rholder/guava-retrying` 的 issue、PR、全部评论里都没有这个机制的报告；最近关闭的 PR #107 和 #84 都和它无关；master 仍停在 `177b6c9b`。
- fork `rhuffman/re-retrying` 的 #32 和 #36 针对的是同一个 `Retryer.call`（同包、同一个 catch-all），报告的就是"attempt 执行中被中断仍然会重试"。fork 在 `f1ff0bfa` 修了，没有合回 upstream。
- 两边都没有提到 `wrap()` 加 cancel 这条路径。如果你只把 upstream tracker 里有记录的算作 KNOWN，这条就应该改成 NEW。

## Description

`RetryerCallable.call()`（`Retryer.java:317-319`）只是在 executor worker 上直接调用 `retryer.call(callable)`，自己没有任何取消处理。所以 `cancel(true)` 和 `shutdownNow()` 只能以"线程中断"的形式传进来。

这个中断会在 attempt 执行期间被消耗掉，有两种情况：
- 用了 `fixedTimeLimit` 时，被 Guava 22 `SimpleTimeLimiter.callWithTimeout(..., true)` 里的 `future.get` 消耗：抛出 `InterruptedException`，同时中断位被清除。
- 没有 time limiter 时，被 callable 自己的可中断等待消耗。

接下来：
- `Retryer.java:162` 的 `catch (Throwable t)` 把这个 `InterruptedException` 当成一次普通的失败 attempt。
- `retryIfException()` 会匹配它，于是继续重试。
- 中断位已经被清掉，所以 `Retryer.java:179` 那个唯一的中断检查永远不会触发。

结果，在 `neverStop`（builder 默认）下，调用会无限重试，worker 永不释放，`awaitTermination` 永远不会成功。

## Trigger scenario

1. 用 `RetryerBuilder.<String>newBuilder().retryIfException().withAttemptTimeLimiter(fixedTimeLimit(1000ms, pool)).build()` 构造 retryer，其余用默认值 `neverStop`、`noWait`。
2. 把 `retryer.wrap(callRemote)` 提交到 `ExecutorService`。`callRemote` 模拟一次 20 ms 的远程调用，并持续抛 `IOException`。
3. 应用决定放弃，调用 `task.cancel(true)` 或 `executor.shutdownNow()`。

和 TLC 反例逐步对应如下：

| 反例 state | 动作 | 复现中的观测 |
|---|---|---|
| 3 | `MCCancelOuter` | `task.cancel(true) returned true` |
| 5 | `MCGetInterrupted`（`curTag="CallerIE"`，`intr[c1]` 由 TRUE 变 FALSE） | `attempt #4 (AFTER cancellation): exception java.lang.InterruptedException \| ... interrupt status=false` |
| 15–43，回到 30 | 后续 attempt 抛 `Exc`，无限重试 | 后续 `IOException` attempt 持续不断，线程栈停在 `SimpleTimeLimiter.callWithTimeout:154` ← `Retryer.call:160` ← `RetryerCallable.call:318` |

另外三份反例输出也都对上了：
- 场景 D 与 `hunt_s2_wrap_cancel_bfs6.out` 逐步一致：取消后提交了 attempt 2，`MCPredicateAccepts`，`outcome="Returned"`，中断位为 FALSE。
- 场景 D 同时也印证了 `hunt_s2_wrap_cancel_bfs3.out`（取消之后又启动了新 attempt）。
- 对照组与 `hunt_s2_live_control.out` 一致：换成 `retryIfExceptionOfType(IOException)` 后调用正常退出。

## Developer intent

开发者的文档和测试都表明"中断就应该结束重试"：
- 构造器 Javadoc（`Retryer.java:59-61` 等处）："the retryer will retry the call, unless the stop strategy indicates otherwise or the thread is interrupted."
- `call()` 的 Javadoc（`:151-153`）："if the thread is interrupted, this exception [RetryException] is thrown and the thread's interrupt status is set."
- 类 Javadoc（`:37`）和 `wrap()` 的 Javadoc（`:188-193`）明确说 `RetryerCallable` 就是用来提交给 executor 的。
- `RetryerBuilderTest.testInterruption`（`:385-414`）断言"中断后抛 `RetryException` 且中断位被置上"，但它只覆盖了 sleep 阶段被中断的情况，没有测 attempt 执行中被中断，也没有测取消 `wrap()` 任务。
- `catch (Throwable t)` 来自 `fbe31777`（2013 年），`wrap()` 来自 `6d2d838b`（2012 年），附近没有任何注释表明这是有意为之。

## Reproduction result

命令（退出码 0）：

```
timeout 10m bash repro/test_bugMC-6_wrap_cancel_endless_retry.sh > repro/MC-6.log 2>&1
```

构建来源：未改动的源码 `177b6c9b`（dirty files: 0），Guava 22.0，JDK 21 `--release 8`。

下面是 `repro/MC-6.log` 的原文摘录：

```
### source: .../confirmation/MC-6/worktree @ 177b6c9b9f3e7957f404f0bdb8e23374cb1de43f (dirty files: 0)
================ scenario A-cancel: java MC6WrapCancelRepro cancel 10000 (timeout 60s) ================
[t=  0.104s] APP: task.cancel(true) returned true; isCancelled()=true isDone()=true (attempts before cancellation: 3)
[t=  0.104s]   onRetry: attempt #4 (AFTER cancellation): exception java.lang.InterruptedException | thread 'app-worker-1' interrupt status=false
[t=  0.105s] APP: task.get() threw CancellationException -> the application considers the task finished
[t=  0.125s]   onRetry: attempt #5 (AFTER cancellation): exception java.io.IOException: service unavailable | thread 'app-worker-1' interrupt status=false
[t= 10.107s] OBSERVE: task.isCancelled()=true app.isShutdown()=false | attempts since cancellation=494 (callable bodies run=498) | worker 'app-worker-1' alive=true state=TIMED_WAITING interruptStatus=false | last attempt 4 ms ago: exception java.io.IOException: service unavailable | task released by worker=NO
        at com.google.common.util.concurrent.SimpleTimeLimiter.callWithTimeout(SimpleTimeLimiter.java:154)
        at com.github.rholder.retry.AttemptTimeLimiters$FixedAttemptTimeLimit.call(AttemptTimeLimiters.java:107)
        at com.github.rholder.retry.Retryer.call(Retryer.java:160)
        at com.github.rholder.retry.Retryer$RetryerCallable.call(Retryer.java:318)
[t= 10.108s] RESULT cancel: BUG TRIGGERED — 494 attempts after cancel(true) (first one: exception java.lang.InterruptedException, interrupt status at that point=false); RetryerCallable.call() has neither returned nor thrown after 10.0 s; worker never released
================ scenario B-shutdownnow ...
[t= 10.116s] APP: awaitTermination(2000 ms) returned false; isTerminated()=false
[t= 10.117s] RESULT shutdownnow: BUG TRIGGERED — after 3 shutdownNow() calls and 10.0 s of awaitTermination, isTerminated()=false; 494 attempts after the first shutdownNow(), 3 of them InterruptedException attempts that were retried
================ scenario C-control-cancel ...
[t=  2.114s] RESULT control-cancel: CONTROL OK (call exits after the cancellation) — attempts after cancel(true)=1 (exception java.lang.InterruptedException); worker released at t=0.113s; shutdown()+awaitTermination(2 s)=true
================ scenario D-late-return ...
[t=  0.150s] APP: task.cancel(true) returned true; isCancelled()=true; invoices delivered so far=0
[t=  0.151s]   callable body #2 starts on 'timelimiter-pool-1' (remote call takes 300 ms)
[t=  0.452s]   callable body #2: invoice DELIVERED (side effect committed)
[t=  0.654s] RESULT late-return: RetryerCallable.call() RETURNED NORMALLY with value 'receipt-2'; Thread.currentThread().isInterrupted()=false
================ scenario F-jvm-exit ...
[t=  3.108s] APP: shutdownNow(); awaitTermination(3 s) returned false; worker 'pool-1-thread-1' daemon=false alive=true
[t= 10.612s] MONITOR (main() has returned): worker 'pool-1-thread-1' (non-daemon) alive=true state=TIMED_WAITING | attempts since shutdownNow()=517, last 19 ms ago: exception java.io.IOException: service unavailable
================ scenario F-jvm-exit exit code: 124
################ SUMMARY ################
A' cancel(true) trials                  : 5/5 triggered
C  control (IOException predicate)      : cancel exit 0, shutdownNow exit 0 (0 = exits/terminates)
E  cancel(true), no time limiter        : exit 0 (0 = endless retry after cancellation)
F  control JVM exit                     : exit 0 (0 = JVM exited by itself)
MC-6 REPRODUCED (Level 0): cancelled/shut-down wrap() tasks keep retrying (or return normally) and never release their worker; the control exits.
```

按 liveness 证据的三项要求逐一对照：
- **触发条件为真且一直为真**：每次采样 `isCancelled()=true`（B 场景是 `isShutdown()=true`）。
- **fairness 假设要求持续运行的线程确实在运行**：调用方线程和 time limiter 的 worker 都在跑，attempt 计数持续增长，最近一次 attempt 都在几毫秒之前。
- **等得足够久仍无进展**：观测了 10 s，是 1 s attempt 时限的 10 倍、20 ms 调用耗时的 500 倍，调用依然没有退出。

## Recommendation

1. 在 `Retryer.java:162` 的 catch-all 之前单独捕获 `InterruptedException`：调用 `Thread.currentThread().interrupt()` 恢复中断位，然后抛 `RetryException`。这样行为就和 `:179-181` 一致，也和 fork 的修复 `f1ff0bfa` 相同。
2. 每次开始新 attempt 之前检查 `Thread.currentThread().isInterrupted()`，并在 cause 链里识别 `InterruptedException`、`InterruptedIOException` 这类异常。
3. 补一个测试：取消 `wrap()` 任务后，调用应以 `RetryException` 退出且中断位被置上；`shutdownNow()` 之后 `awaitTermination` 应返回 true。
4. 用户在修复前的绕过办法：
   - 用 `retryIfException(t -> !(t instanceof InterruptedException))` 代替 `retryIfException()`；
   - 并且使用有界的 stop strategy。

   这样 worker 能被释放，但退出时中断位仍然是清掉的。

## Checklist

1. **只用 Level 0 是否触发？** yes。只用了公开 API（`RetryerBuilder`、`fixedTimeLimit`、`wrap`、`RetryListener`）加标准 JDK executor，库源码未改动。20 ms 的 callable 延迟属于工作负载本身，不是时序干预。
2. 不适用（没有用到 Level 2/3）。
3. **谁观察到错误结果？** 持有 executor 的应用代码：`cancel(true)` 返回 true，`get()` 抛 `CancellationException`，但任务一直在跑；`awaitTermination` 一直返回 false；使用默认非守护线程 executor 的 JVM 无法退出（exit 124）。错误结果出自 `Retryer.java:162` 和 `Retryer.java:317-319`，而这个 callable 正是库文档（`Retryer.java:37`、`:187-194`）建议提交给 executor 的东西。
4. **状态是永久的吗？** 是。`neverStop` 加上持续失败的 callable 时，没有任何东西能结束循环：每次额外的中断（`shutdownNow` 调了 3 次）都会被同样消耗然后继续重试；被取消的 `FutureTask` 状态拦不住正在运行的线程；没有下游机制能掩盖。唯一的出口是某次 attempt 成功，而那恰好是场景 D 的错误结果：取消之后提交副作用并正常返回。

## Repair round 1 evidence
<!-- specular-repair-token: 3eefa76b5b37ed587e41b6cbdb823026 -->
- **Current violation analysis**: RetryerCallable.call just runs retryer.call on the executor thread (Retryer.java:195-197, 317-319), so an outer Future.cancel(true) or shutdownNow() reaches call() only as a thread interrupt, which MC-4/MC-5's catch-all turns into an ordinary failed attempt. TLC (LiveSpec with weak fairness on caller and pool-worker steps only) finds a lasso in which, after the cancellation interrupt is consumed by Future.get, the always-failing callable is retried forever under retryIfException() and neverStop (hunt_s2_live_bfs.out, 43 states, back to state 30); the violation persists with the attempt-counte…
- **Counterexample**: `spec/output/hunt_s2_live_bfs.out`

## Phase 4 confirmation after repair round 1

running cat /home/ubuntu/.claude/projects/-home-ubuntu-guava-retrying-20261126-Specular-runs-guava-retrying-opus55max-20261126-guava-retrying--specular-output-confir...
running ls -la ~/.claude/skills 2>/dev/null; ls -la ~/.claude/plugins 2>/dev/null | head; echo ----; ls -la /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-...
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation && cat SKILL.md && echo ======== && cat guide.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation && cat phases/01-investigation.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation && cat phases/02-reproduction.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation && cat references/persistent-findings.md && echo ======== && cat references/repair-r...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-6 && python3 -I -c "...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-6 && cat .resume-leas...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-6 && cat investigatio...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output && cat confirmation/MC-6/issue.json;...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output && sha256sum repro/test_bugMC-6_wrap_...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output && ls -la --time-style=full-iso spec/...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec/output && for f in repair-r1/rep...
reading /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/test_bugMC-6_wrap_cancel_endless_retry.sh
running ls -la $HOME/.m2/repository/com/google/guava/guava/22.0/guava-22.0.jar $HOME/.m2/repository/com/google/code/findbugs/jsr305/2.0.2/jsr305-2.0.2.jar && sha256s...
running mkdir -p /tmp/mc6-r1 && cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output && START=$(da...
重跑结果：退出码 0，用时 59 s。全部场景再次触发：A' 5/5，B、D、E 触发，F 退出码 124；两个对照组都正常退出。下面看关键输出行。
running sed -n 1,80p /tmp/mc6-r1/MC-6.log
running sed -n 80,320p /tmp/mc6-r1/MC-6.log | grep -E "^=+ scenario|CONFIG|APP:|RESULT|OBSERVE|onRetry: attempt #[0-9]+ \(AFTER|STACK|at com\.(github|google)|MONITOR...
running grep -nE "scenario (E|F)|RESULT cancel-notimelimit|F-jvm-exit|CONFIG: Executors|APP: shutdownNow\(\); awaitTermination|MONITOR|main\(\) returns" /tmp/mc6-r1/...
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-6/worktree/src/main/ja...
running cd /tmp && echo "## upstream most-recently-updated issues/PRs"; timeout 60 gh api "repos/rholder/guava-retrying/issues?state=all&sort=updated&direction=desc&...
running cd /tmp && SP=/home/ubuntu/guava-retrying-20261126/Specular/specular; OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-2026112...
Registry 里没有可复用的记录，因为流水线要到 finalization 才登记。现在用新跑的日志替换 `repro/MC-6.log`，并在 `investigation.md` 里追加本轮续作的记录。
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; cp /tmp/mc6-r1/MC-6.log $OUT/repro/...
reading /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-6/investigation.md
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-6/investigation.md
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-6/issue.json
running cd /tmp && OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; python3 -I -c "import js...
running CE=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec/output/hunt_s2_live_bfs.out; for...
running ps -eo pid,etimes,args | grep '[j]ava .*MC6WrapCancel' || echo "no java repro processes"
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-6/worktree; awk 'NR==3...
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-6/worktree; T=$(find $...
# MC-6 repair round 1：结论维持 REPRODUCED（Level 0）

结论不变。用 `Retryer.wrap()` 提交到 executor 的任务，被 `cancel(true)` 或 `shutdownNow()` 取消后会一直重试。如果后面某次 attempt 成功，它会在取消之后正常返回：副作用已经提交，中断位是清掉的。worker 一直不会被释放。本轮在当前源码上重跑了 repro，所有场景都再次触发，对照组也都正常退出。现有证据没有推翻上轮任何陈述，不需要更正。

- **Source**: MC
- **Novelty**: KNOWN (cite: https://github.com/rhuffman/re-retrying/issues/32; fix-status: unfixed)
- **Location**: src/main/java/com/github/rholder/retry/Retryer.java:162
- **Severity**: High
- **Reproduction test**: `repro/test_bugMC-6_wrap_cancel_endless_retry.sh`（Level 0，脚本未改动），本轮输出在 `repro/MC-6.log`
- **Persistent record**: `confirmation/MC-6/issue.json`，`specular findings validate` 返回 `"valid": true`

关于 Novelty：
- upstream `rholder/guava-retrying` 没有这个机制的报告。本轮又增量查了一次：master 仍是 `177b6c9b`；最近关闭的 #84、#107 都没合并，内容也无关；搜 `interrupt` 只命中 #63，那是另一种机制。
- fork `rhuffman/re-retrying` 的 #32、#36 报告的正是同一个 `Retryer.call` catch-all 吞掉 attempt 期间中断的问题。fork 在 `f1ff0bfa` 修了，没有合回 upstream，所以对目标库来说是 unfixed。
- 两边都没提到 `wrap()` 加 cancel 这条路径。如果只把 upstream tracker 里的报告算作 KNOWN，这条应改记为 NEW。

## Description

`RetryerCallable.call()`（`Retryer.java:317-319`）只是在 executor worker 上直接调用 `retryer.call(callable)`，自己没有任何取消处理。所以 `Future.cancel(true)` 和 `shutdownNow()` 只能以线程中断的形式到达 `Retryer.call`。

这个中断会在 attempt 进行中被消耗掉：
- 用了 `fixedTimeLimit` 时，消耗在 Guava 22 `SimpleTimeLimiter.callWithTimeout(..., true)` 的 `future.get` 里（`AttemptTimeLimiters.java:107`）。它抛出 `InterruptedException`，同时清掉中断位。
- 没有 time limiter 时，消耗在 callable 自己的可中断等待里。

接下来：
- `Retryer.java:162` 的 `catch (Throwable t)` 把这个异常当成一次普通的失败 attempt。
- `retryIfException()` 匹配它，于是继续重试。
- 中断位已经清掉，唯一的中断检查（`:177-182`，在 `block()` 处）永远不会触发。

结果，在 `neverStop`（builder 默认）下调用永不结束：worker 不释放，`awaitTermination` 永远返回 false，使用非守护线程 executor 的 JVM 退不出去。

## Trigger scenario

1. 用 `RetryerBuilder.<String>newBuilder().retryIfException().withAttemptTimeLimiter(fixedTimeLimit(1000 ms, pool)).build()` 构造 retryer，其余用默认值 `neverStop`、`noWait`。
2. 把 `retryer.wrap(callRemote)` 提交到 `ExecutorService`。`callRemote` 模拟一次 20 ms 的远程调用，持续抛 `IOException`。
3. 应用放弃这个任务，调用 `task.cancel(true)` 或 `executor.shutdownNow()`。

和 lasso `hunt_s2_live_bfs.out` 的对应关系（本轮直接读了反例的状态变量）：

| CE state | 动作 / 状态 | 复现中的观测 |
|---|---|---|
| 3（state 4 时 `intr[c1]=TRUE`） | `MCCancelOuter` | `task.cancel(true) returned true` |
| 5 | `MCGetInterrupted`：`curTag` 由 `"none"` 变为 `"CallerIE"`，`intr[c1]` 由 TRUE 变为 FALSE | `attempt #4 (AFTER cancellation): exception java.lang.InterruptedException \| ... interrupt status=false` |
| 6–14 | 内层 future 被取消 → listeners → `MCWaitStrategyComputes("Zero")` → `MCBlockZero` | `Thread.sleep(0)` 正常返回，attempt #5 紧接着开始 |
| 30–43，回到 30 | `curTag="CallableExc"`，`intr` 全为 FALSE，`outcome="None"`，一直循环 | 取消后 10 s 内 496 次 attempt；线程栈停在 `SimpleTimeLimiter.callWithTimeout:154` ← `Retryer.call:160` ← `RetryerCallable.call:318` |

其他反例也对得上：
- 场景 D 对应 `hunt_s2_wrap_cancel_bfs6.out`：取消后 attempt 2 返回，`MCPredicateAccepts`，中断位为清。它也印证了 `bfs3`：取消之后又启动了新 attempt。
- 对照组对应 `hunt_s2_live_control.out`：换成 `retryIfExceptionOfType(IOException)` 后调用正常退出。

## Developer intent

- 构造器 Javadoc（`Retryer.java:59-61` 等处）："the retryer will retry the call, unless the stop strategy indicates otherwise or the thread is interrupted."
- `call()` 的 Javadoc（`:151-153`）：线程被中断时 "this exception [RetryException] is thrown and the thread's interrupt status is set."
- 类 Javadoc（`:37`）和 `wrap()` 的 Javadoc（`:187-194`）把 `RetryerCallable` 定位成可以提交给 executor 的对象。
- `RetryerBuilderTest.testInterruption`（`:385`）断言中断后抛 `RetryException` 且中断位被置上，但只覆盖了 sleep 阶段的中断。没有任何测试覆盖 attempt 执行期间被中断，或者取消 `wrap()` 任务。
- catch-all 来自 `fbe31777`（2013 年），附近没有注释说明这是有意为之。

## Reproduction result

本轮先确认上轮证据仍然有效：
- **源码未变**：worktree 在 `177b6c9b`，0 个 dirty 文件，`src/` 和冻结源码 `diff` 为空。
- **测试脚本未变**：sha256 为 `e57bd0c7…`。
- **反例是同一份文件**：`hunt_s2_live_bfs.out` 的 sha256 为 `3e4be17e…`，08:16 生成，早于 repair round 1 在 12:28 对 `spec/base.tla` 的修改。修复轮没有重跑 `MC_hunt_s2_live.cfg`。不过修复后的 S2 对照跑（`spec/output/repair-r1/repair1_ctl_s2_wrap_cancel_ndc.out`）仍然能走到 `MCCancelOuter`（state 9）→ `MCGetInterrupted`（state 11）。也就是说，反例起点的取消路径在修复后的模型里依旧可达。
- 无论模型怎样，结论依据的是在未改动源码上的 Level 0 实跑。

命令如下，退出码 0，用时 59 s：

```
timeout 10m bash repro/test_bugMC-6_wrap_cancel_endless_retry.sh > repro/MC-6.log 2>&1
```

`repro/MC-6.log` 原文摘录（`...` 表示省略的行）：

```
### source: /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-6/worktree @ 177b6c9b9f3e7957f404f0bdb8e23374cb1de43f (dirty files: 0)
### guava: /home/ubuntu/.m2/repository/com/google/guava/guava/22.0/guava-22.0.jar sha256=1158e94c7de4da48...
### java: openjdk version "21.0.13.1" 2026-11-17

================ scenario A-cancel: java MC6WrapCancelRepro cancel 10000 (timeout 60s) ================
[t=  0.095s]   onRetry: attempt #4 (AFTER cancellation): exception java.lang.InterruptedException | thread 'app-worker-1' interrupt status=false
[t=  0.095s] APP: task.cancel(true) returned true; isCancelled()=true isDone()=true (attempts before cancellation: 3)
[t=  0.095s] APP: task.get() threw CancellationException -> the application considers the task finished
[t=  0.115s]   onRetry: attempt #5 (AFTER cancellation): exception java.io.IOException: service unavailable | thread 'app-worker-1' interrupt status=false
...
[t= 10.097s] OBSERVE: task.isCancelled()=true app.isShutdown()=false | attempts since cancellation=496 (callable bodies run=500) | worker 'app-worker-1' alive=true state=TIMED_WAITING interruptStatus=false | last attempt 6 ms ago: exception java.io.IOException: service unavailable | task released by worker=NO
...
        at com.google.common.util.concurrent.SimpleTimeLimiter.callWithTimeout(SimpleTimeLimiter.java:154)
        at com.github.rholder.retry.AttemptTimeLimiters$FixedAttemptTimeLimit.call(AttemptTimeLimiters.java:107)
        at com.github.rholder.retry.Retryer.call(Retryer.java:160)
        at com.github.rholder.retry.Retryer$RetryerCallable.call(Retryer.java:318)
...
[t= 10.098s] RESULT cancel: BUG TRIGGERED — 496 attempts after cancel(true) (first one: exception java.lang.InterruptedException, interrupt status at that point=false); RetryerCallable.call() has neither returned nor thrown after 10.0 s; worker never released
...
[t= 10.098s] APP: awaitTermination(2000 ms) returned false; isTerminated()=false
...
[t= 10.099s] RESULT shutdownnow: BUG TRIGGERED — after 3 shutdownNow() calls and 10.0 s of awaitTermination, isTerminated()=false; 496 attempts after the first shutdownNow(), 3 of them InterruptedException attempts that were retried
...
[t=  2.096s] RESULT control-cancel: CONTROL OK (call exits after the cancellation) — attempts after cancel(true)=1 (exception java.lang.InterruptedException); worker released at t=0.094s; shutdown()+awaitTermination(2 s)=true
...
[t=  0.133s] APP: task.cancel(true) returned true; isCancelled()=true; invoices delivered so far=0
[t=  0.134s] APP: task.get() threw CancellationException -> the application considers the invoice NOT sent
[t=  0.134s]   onRetry: attempt #1 (AFTER cancellation): exception java.lang.InterruptedException | thread 'app-worker-1' interrupt status=false
[t=  0.135s]   callable body #2 starts on 'timelimiter-pool-1' (remote call takes 300 ms)
[t=  0.435s]   callable body #2: invoice DELIVERED (side effect committed)
[t=  0.637s] RESULT late-return: RetryerCallable.call() RETURNED NORMALLY with value 'receipt-2'; Thread.currentThread().isInterrupted()=false
...
[t=  6.095s] RESULT cancel-notimelimit: BUG TRIGGERED — 299 attempts after cancel(true) (first one: exception java.lang.InterruptedException: sleep interrupted, interrupt status at that point=false); RetryerCallable.call() has neither returned nor thrown after 6.0 s; worker never released
...
[t=  3.095s] APP: shutdownNow(); awaitTermination(3 s) returned false; worker 'pool-1-thread-1' daemon=false alive=true
[t= 10.598s] MONITOR (main() has returned): worker 'pool-1-thread-1' (non-daemon) alive=true state=TIMED_WAITING | attempts since shutdownNow()=520, last 6 ms ago: exception java.io.IOException: service unavailable
================ scenario F-jvm-exit exit code: 124
...
################ SUMMARY ################
A  cancel(true), CE config, 10 s window : exit 0 (0 = endless retry after cancellation)
A' cancel(true) trials                  : 5/5 triggered
B  shutdownNow + awaitTermination       : exit 0 (0 = pool never terminates)
C  control (IOException predicate)      : cancel exit 0, shutdownNow exit 0 (0 = exits/terminates)
D  late normal return after cancel      : exit 0 (0 = call() returned normally, side effect after cancel)
E  cancel(true), no time limiter        : exit 0 (0 = endless retry after cancellation)
F  JVM exit after shutdownNow           : exit 124 (124 = JVM never exited, killed by timeout)
F  control JVM exit                     : exit 0 (0 = JVM exited by itself)
MC-6 REPRODUCED (Level 0): cancelled/shut-down wrap() tasks keep retrying (or return normally) and never release their worker; the control exits.
```

关键输出行：
- A 场景：`attempts since cancellation=496`、`task released by worker=NO`，以及 `RESULT cancel: BUG TRIGGERED`。
- B 场景：`isTerminated()=false`。
- D 场景：`RETURNED NORMALLY ... isInterrupted()=false`，副作用在 `cancel(true)` 之后 0.302 s 才提交。
- F 场景：`exit code: 124`。

liveness 证据的三项要求都满足：
- **触发条件为真且一直为真**：每次采样都是 `isCancelled()=true`；B 场景是 `isShutdown()=true`。
- **fairness 假设要求运行的线程确实在跑**：attempt 计数持续增长，每次采样时最近一次 attempt 都在 20 ms 以内。
- **等得足够久仍无进展**：观测了 10 s，是 1 s attempt 时限的 10 倍、20 ms 调用耗时的 500 倍，调用依然没有退出。

正确行为应是：取消后抛 `RetryException`、中断位被置上、worker 被释放。对照组 C 用 `retryIfExceptionOfType(IOException)`，取消后只跑了 1 次 attempt 就退出，worker 在 t=0.094 s 被释放。不过 C 退出时抛的是 `ExecutionException`，中断位仍是清的；那是另一个中断位问题，不属于本 finding。

## Recommendation

1. 在 `Retryer.java:162` 的 catch-all 之前单独捕获 `InterruptedException`：先调用 `Thread.currentThread().interrupt()` 恢复中断位，再抛 `RetryException`。这和 `:179-181` 的处理一致，也和 fork 的修复 `f1ff0bfa` 思路相同。
2. 每次开始新 attempt 之前检查 `Thread.currentThread().isInterrupted()`。
3. 补回归测试：取消 `wrap()` 任务后，调用应以 `RetryException` 退出且中断位被置上；`shutdownNow()` 之后 `awaitTermination` 应返回 true。
4. 修复之前，用户可以这样绕过：用一个排除 `InterruptedException` 的谓词代替 `retryIfException()`，同时配合有界的 stop strategy。这样 worker 能被释放，但退出时中断位仍是清的。

## Checklist

1. **只用 Level 0/1 是否触发？** yes。只用了公开 API（`RetryerBuilder`、`AttemptTimeLimiters.fixedTimeLimit`、`Retryer.wrap`、`RetryListener`）和标准 JDK executor，库源码没有改动。callable 的 20 ms / 300 ms 耗时是工作负载本身的一部分，不是对时序的干预。
2. 不适用，没有用到 Level 2/3。
3. **谁观察到错误结果？** 持有 executor 的应用代码：
   - `Future.cancel(true)` 返回 true，`get()` 抛 `CancellationException`，但任务一直在跑；
   - `ExecutorService.awaitTermination` 一直返回 false；
   - 使用默认非守护线程 executor 的 JVM 无法退出（exit 124）；
   - 场景 D 里，取消之后副作用照样提交了。

   错误出自 `Retryer.java:162` 和 `Retryer.java:317-319`。被提交的正是库文档（`Retryer.java:37`、`:187-194`）建议交给 executor 的 `RetryerCallable`。
4. **坏状态是永久的吗？** 是。在 `neverStop` 加持续失败的 callable 下，没有任何东西能结束循环：
   - 每次额外的中断（`shutdownNow` 调了 3 次）都被同样消耗，然后继续重试；
   - 已取消的 `FutureTask` 状态拦不住正在运行的线程；
   - 没有下游机制能掩盖这个后果。

   唯一的出口是某次 attempt 成功，而那恰好就是场景 D 的错误结果：在取消之后提交副作用并正常返回。

---

## Entry 7: Adding a listener to the builder while a built `Retryer` runs makes `call()` throw `ConcurrentModificationException` after the attempt executed; its outcome is lost

- **Finding ID**: MC-7
- **Status**: REPRODUCED
- **Debate**: not run
- **Transcript**: /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-7/debate.md

running pwd; ls -la; ls -la /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-7/;...
running ls -la ~/.claude/skills/ 2>/dev/null; ls -la ~/.claude/skills/bug-confirmation 2>/dev/null; ls -la /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-c...
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; cat SKILL.md; echo ======; cat guide.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; cat phases/01-investigation.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; cat phases/02-reproduction.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; cat references/persistent-findings.md; echo =====; cat references/repair-request-fo...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-7/; cat .resume-lease...
先读源码和本 finding 的反例。
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-7/worktree; cat -n sr...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec; ls -la output/hunt_s3_listeners...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec; cat output/hunt_s3_listeners_bf...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec; grep -n "^State\|^Error\|states...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec; sed -n 1,27p output/hunt_sharin...
running which java javac mvn gradle gh specular 2>&1; java -version 2>&1; ls ~/.m2/repository/com/google/guava/guava/ 2>/dev/null; ls ~/.m2/repository/com/google/cod...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/; cat persistent-findings-context.jso...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/; cat harness/pom.xml; ls -la /home/u...
running cd /tmp; timeout 60 gh auth status 2>&1 | head -5; timeout 60 gh issue view 48 -R rholder/guava-retrying --json number,title,state,body,comments,createdAt,au...
running cd /tmp; for q in "ConcurrentModificationException" "concurrent modification" "listener" "listeners" "thread-safe" "thread safe" "withRetryListener" "Immutab...
running cd /tmp; timeout 90 gh pr list -R rholder/guava-retrying --state all --limit 200 --json number,title,state,mergedAt,closedAt,updatedAt 2>&1 | python3 -c 'imp...
running cd /tmp; timeout 60 gh pr view 107 -R rholder/guava-retrying --json title,state,body,closedAt,mergedAt,files 2>&1 | python3 -c 'import json,sys; d=json.load(...
running cd /tmp; timeout 60 gh issue view 35 -R rholder/guava-retrying --json title,state,body,comments 2>&1 | python3 -c 'import json,sys; d=json.load(sys.stdin); p...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-7/worktree; cat -n sr...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-7/worktree; grep -rn...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-7/worktree; grep -n -...
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-7/investigation.md
running ls -la ~/.m2/repository/com/google/guava/guava/22.0/ ~/.m2/repository/com/google/code/findbugs/jsr305/2.0.2/ 2>&1 | grep -E "\.jar$|total|cannot"; ls /usr/li...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-7/worktree/src/main/j...
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/test_bugMC-7_builder_listener_cme.sh
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/; chmod +x repro/test_bugMC-7_builder...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/; JAVA_HOME=/usr/lib/jvm/java-11-open...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/; ls -la spec/MC_hunt_s3_listeners.cf...
running S=/home/ubuntu/scratch/guava-retrying-src/guava-retrying; W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retryi...
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-7/issue.json
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/; python3 -I -c 'import json; d=json....
`issue.json` 校验通过（`valid: true`）。最后确认 worktree 未被改动、临时构建目录已清理。
running git -C /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-7/worktree status...
MC-7 已复现：在 builder 上调用 `withRetryListener` 时，如果同一 builder 构建出的 `Retryer` 正在别的线程执行 `call()`，`call()` 会在 attempt 已执行后抛出 `ConcurrentModificationException`，这次 attempt 的结果丢失。只用公开 API、不加任何 sleep 的纯黑盒（Level 0）就能触发。

- **Source**: MC
- **Novelty**: NEW
- **Severity**: Medium
- **Location**: src/main/java/com/github/rholder/retry/RetryerBuilder.java:196
- **Reproduction test**: `.specular-output/repro/test_bugMC-7_builder_listener_cme.sh`，Level 0 纯黑盒触发；Level 1 只用来做确定性复现
- **Persistent record**: `confirmation/MC-7/issue.json`，`specular findings validate` 返回 `"valid": true`

## Description
`RetryerBuilder` 的 listener 列表是一个可变的 `ArrayList`（`RetryerBuilder.java:40`）。`build()` 把这个列表原样传给 `Retryer`（`RetryerBuilder.java:196`），`Retryer` 也不复制，直接保存（`Retryer.java:137`）。`call()` 在 attempt 的 try/catch 之外，用 fail-fast 迭代器遍历这个列表（`Retryer.java:166-168`）。

所以，只要另一个线程在这时调用 `builder.withRetryListener()`（`ArrayList.add` 会 `modCount++`），正在遍历的 `next()` 就抛 CME，并直接穿出 `call()`。这时 callable 已经执行过，副作用已经发生，但它的返回值、它抛出的异常，以及本该接着发生的重试决策全部丢失，rejection predicate 和 stop strategy 都没有运行。

CME 不在 `call()` Javadoc（`Retryer.java:146-153`）列出的三种结局之内，也违反了“A retryer is thread-safe”（`Retryer.java:39-40`）。

## Trigger scenario
反例 `spec/output/hunt_s3_listeners_bfs1.out` 共 7 个状态，步骤依次是：
1. `MCCallStart(c1)`：c1 进入 `call()`。
2. `MCCallerBodyStart(c1,"Ret")` 和 `MCCallerBodyReturns(c1)`：callable 执行完并返回了值。
3. `MCListenersBegin(c1)`：创建迭代器，`itExpMod=1`，`itCursor=0`。
4. `MCAddListenerBegin(2)`：另一线程执行 `withRetryListener`，`bmod=2`。
5. `MCListenerCME(c1)`：`outcome="CME"`，`DocumentedOutcomesOnly` 被违反。

第二个反例 `hunt_sharing_bfs1.out` 机制相同，只是第一次 attempt 是 `fixedTimeLimit` 超时，超时后本该发生的重试被 CME 吞掉。

真实用法：一个 builder 已经 `build()` 出 retryer，并在工作线程或 `wrap()` + executor 中使用；与此同时，另一个线程继续用这个 builder `withRetryListener(...)`，比如再 build 一个变体（#48 里的报告者就是这样用的）。

## Developer intent
- **#35（已关闭）**：维护者回答 Retryer “should all be thread-safe”，并给出了一个跨线程共享的 `static final` retryer 示例。
- **Javadoc**：`Retryer.java:39-40` 写着“thread-safe, provided the arguments passed to its constructor are thread-safe”。但这里的 `ArrayList` 是 `build()` 自己传进去的，用户无法控制。
- **`RetryListener.onRetry`**：Javadoc 没有限制 listener 的执行耗时；builder 的 Javadoc 也没有禁止 `build()` 之后继续使用 builder。
- **测试**：`RetryerBuilderTest:463-550` 全是单线程用例，listener 都在 `build()` 之前加好，没有覆盖这个场景。
- **blame**：相关代码来自 1edb757（PR #37，2015-04-21）和 54a2a4d，提交信息里没有讨论复制列表或并发。
- **#48（OPEN，未修）**：报告了同一根因（builder 和 retryer 共享列表），但只写了顺序场景下的后果（多通知一个 listener），提议在 build 时 `ImmutableList.copyOf`。
- **判为 NEW 的依据**：搜了上游 issue/PR 的 ConcurrentModificationException、concurrent modification、listener(s)、thread-safe、withRetryListener、ImmutableList、copyOf，并逐个看了全部 45 个 PR（包括 2026-09 最近关闭但未合并的 #107 和 #84，都与此无关）。没有任何报告提到这个并发下抛 CME、丢结果的机制。
- **persistent-findings**：`previous: null`，没有历史记录可复用。

## Reproduction result
复现脚本只编译未修改的 2.0.0 源码（HEAD `177b6c9`，`dirty-files=0`），依赖 Guava 22.0，用 `--release 8` 编译。在 `.specular-output/` 下执行：
- JDK 21：`timeout 15m bash repro/test_bugMC-7_builder_listener_cme.sh`，日志在 `confirmation/MC-7/repro-output.log`
- JDK 11：`JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64 TRIALS=1000 timeout 10m bash repro/test_bugMC-7_builder_listener_cme.sh`，日志在 `repro-output-jdk11.log`

两次运行退出码都是 0。以下是 JDK 21 输出的原文摘录：
```
---- Level 0: pure black box (public API only, no sleeps, no hooks)
[L0-a] pure black box, 1 caller thread looping retryer.call() + 1 uncoordinated builder.withRetryListener() per trial
    trials=2000 (683 ms): call() threw ConcurrentModificationException in 876 trials (8 before the first listener ran = exact TLC interleaving, 868 after it ran); other failures=0
    of the CME trials, attempt executed (callable ran once) with predicate never consulted: 876
        java.util.ConcurrentModificationException
          at java.base/java.util.ArrayList$Itr.checkForComodification(ArrayList.java:1095)
          at java.base/java.util.ArrayList$Itr.next(ArrayList.java:1049)
          at com.github.rholder.retry.Retryer.call(Retryer.java:166)
    => BUG TRIGGERED at Level 0
[L0-b] pure black box, one Retryer shared by 2 pool threads via wrap(); main adds 1 listener per trial
    trials=200: trials with a CME-failed Future=161; futures ok=79755, failed with ExecutionException(cause=CME)=245, other=0
[...]
[L1-a] retryer.call(c) | attempt 1 returns 42
    concurrent step    : main thread calls builder.withRetryListener(late) while the caller is inside its listener loop
    documented outcome : call() returns 42 after 1 attempt
    observed           : threw java.util.ConcurrentModificationException; value delivered to caller = none
    probes             : callable executions=1, rejection-predicate invocations=0, stop-strategy invocations=0, late listener notified=0
[...]
[L1-c] retryer.call(c) | attempt 1 exceeds fixedTimeLimit(200ms) (retryable), attempt 2 returns 42
    concurrent step    : main thread calls builder.withRetryListener(late) while the caller is inside its listener loop
    documented outcome : call() retries and returns 42 after 2 attempts
    observed           : threw java.util.ConcurrentModificationException; value delivered to caller = none
    probes             : callable executions=1, rejection-predicate invocations=0, stop-strategy invocations=0, late listener notified=0
[...]
[L1-d] executor.submit(retryer.wrap(c)).get() | attempt 1 returns 42
    observed           : threw java.util.concurrent.ExecutionException (cause: java.util.ConcurrentModificationException); value delivered to caller = none
[...]
[C-a] control, same as above but NO concurrent withRetryListener | attempt 1 returns 42
    observed           : returned 42 | callable executions=1, rejection-predicate invocations=1, stop-strategy invocations=0, late listener notified=0  => documented outcome
[C-b] control, same as above but NO concurrent withRetryListener | attempt 1 throws IOException (retryable), attempt 2 returns 42
    observed           : returned 42 | callable executions=2, rejection-predicate invocations=2, stop-strategy invocations=1, late listener notified=0  => documented outcome
SUMMARY(unmodified 2.0.0): Level0 single-caller CME trials=876/2000, Level0 shared-wrap trials with CME=161, Level1 reproduced=true, controls documented=true
[...]
SUMMARY(negative control): documented outcomes=true, Level0 CME trials=0
RESULT: BUG REPRODUCED on unmodified guava-retrying 2.0.0; symptom absent when build() copies the listener list
```

JDK 11 的汇总行：`Level0 single-caller CME trials=813/1000, Level0 shared-wrap trials with CME=96, Level1 reproduced=true, controls documented=true`；负对照为 0 次 CME。

**哪些输出证明了 bug：**
- **L0-a** 的 876 次 CME，栈顶都是 `Retryer.call(Retryer.java:166)`。
- **与反例的对应**：
  - L0-a 中有 8 次是“第一个 listener 还没运行就抛 CME”，和 TLC 反例的交错（`itCursor=0`）完全一致。
  - L1-c 对应超时反例。
  - 违反的不变式与反例相同：CME 不在文档列出的结局内（`DocumentedOutcomesOnly`）；callable 执行了，结果却丢了（`NoLostAttemptOutcome`）。
- **L1-a、L1-b、L1-c、L1-d 的 probe**：callable 都执行了 1 次，predicate 和 stop strategy 都是 0 次。

**与正确行为的对比：**
- 对照组 C-a/C-b/C-c 不做并发 add，都返回 42，predicate 和 stop strategy 按文档被调用。
- 负对照只在临时副本里把 `build()` 改成复制列表，F-a 到 F-d 全部返回 42，Level 0 的 CME 次数为 0。

## Recommendation
- 在 `RetryerBuilder.build()`（`:196`）传入快照 `ImmutableList.copyOf(listeners)`。这正是 #48 提议的修法，负对照已经验证它消除了 CME 和丢结果，同时也修掉了 #48 的顺序后果。
- 建议在 `Retryer` 的 `@Beta` 构造器（`:137`）也做一次防御性复制：`this.listeners = ImmutableList.copyOf(listeners)`。这样直接调构造器的用户也得到快照语义。
- 不建议在 listener 循环外 catch 异常，那只是掩盖问题，attempt 的结局仍然会被打乱。

## REPRODUCED 检查清单
1. **Level 0 或 Level 1 单独能否触发？是。** Level 0 只用公开 API，没有 sleep 也没有 hook：JDK 21 下 876/2000 次，JDK 11 下 813/1000 次。Level 1 只在用户自己提供的 `RetryListener` 里用 latch 控制时序，四个场景 4/4 确定复现。
2. **是否用到 Level 2/3？不适用。** 没有做状态注入，也没有修改源码来制造症状。唯一的源码改动是负对照，而且是用来消除症状的。
3. **谁观察到错误结果？** 一是 `Retryer.call()` 的直接调用方：本应拿到 42（或重试后的 42），实际收到 CME。二是库自己的 `RetryerCallable.call()`（`Retryer.java:317-319`），它把 CME 原样交给 executor，所以 `Future.get()` 抛 `ExecutionException(cause=CME)`（L1-d，以及 L0-b 里的 245 个 future）。
4. **坏状态是永久的还是会被修复？对受影响的那次调用是永久的。** `Retryer` 里唯一的 try/catch 只包住 attempt 本身（`:159-164`），`RetryerCallable` 直接委托，没有任何机制恢复丢失的结果或补做重试。之后的调用虽然正常，但不会找回这次丢掉的结局，callable 的副作用也已经发生。没有任何东西掩盖这个后果，所以不是 MASKED。

## Repair round 1 evidence
<!-- specular-repair-token: 3eefa76b5b37ed587e41b6cbdb823026 -->
- **Current violation analysis**: RetryerBuilder.build() hands the builder's own ArrayList of listeners to the Retryer (RetryerBuilder.java:40, 196), which stores it without copying (Retryer.java:137) and iterates it with a fail-fast iterator outside the attempt's try/catch (Retryer.java:166-168). If another thread calls builder.withRetryListener (ArrayList.add: modCount++) while a call is inside its listener loop, next() throws ConcurrentModificationException out of call() after the callable already ran. TLC: hunt_s3_listeners_bfs1.out (7 states) — the attempt returns a value, the iterator is created, the builder adds a list…
- **Counterexample**: `spec/output/hunt_s3_listeners_bfs1.out`

## Phase 4 confirmation after repair round 1

running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-7 && ls -la && echo -...
running find / -type d -name "bug-confirmation" 2>/dev/null | head -20; find /home/ubuntu -path "*bug-confirmation*" -name "*.md" 2>/dev/null | head -40
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation && ls -laR && echo ====SKILL && cat SKILL.md && echo ====GUIDE && cat guide.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation && cat phases/01-investigation.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation && cat phases/02-reproduction.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation && cat references/persistent-findings.md && echo ====RR && cat references/repair-req...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-7 && cat investigatio...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec && ls -la --time-style=full-iso...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec && cat output/hunt_s3_listeners_...
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-7/worktree; git -C $W...
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-7/worktree/src/main/ja...
所有引用的行号都与源码吻合。接下来读复现脚本。
reading /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/test_bugMC-7_builder_listener_cme.sh
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output && ls -la ~/.m2/repository/com/google...
running cat /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-7/repro-output-repai...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec && grep -n -E "^Error|^State [0-...
running cd /tmp && timeout 60 gh issue view 48 -R rholder/guava-retrying --json number,title,state,updatedAt,comments 2>&1 | python3 -I -c 'import json,sys; d=json.l...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-7 && cat >> investiga...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-7 && grep -c 'Negativ...
现在更新 `issue.json`：修正触发率，补充超时情形的说明，并把本轮日志加入 evidence。
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-7 && python3 -I - <<'...
running O=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; which specular; timeout 120 specular...
`specular` 不在 PATH 上。上一轮校验通过过，先找一下它当时是怎么调用的。
running ls /home/ubuntu/guava-retrying-20261126/Specular/ | head -50; ls -la /home/ubuntu/guava-retrying-20261126/Specular/bin 2>/dev/null; find /home/ubuntu/guava-r...
running O=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; SP=/home/ubuntu/guava-retrying-202611...
`issue.json` 校验通过（`valid: true`）。最后确认临时构建目录已清理、worktree 仍然干净。
running ls -d /home/ubuntu/tmp/mc7-repro.* /tmp/mc7-repro.* 2>/dev/null | wc -l; git -C /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-2...
MC-7 在修复第 1 轮之后依然成立，判定维持 `REPRODUCED`。反例、源码和复现脚本都没有变化。本轮在未修改的 2.0.0 上重新执行，只用公开 API 的 Level 0 测试再次触发了这个 bug。上次材料里有两处不准确，本轮已更正，详见 Reproduction result 末尾。

- **Source**: MC
- **Novelty**: NEW
- **Severity**: Medium
- **Location**: src/main/java/com/github/rholder/retry/RetryerBuilder.java:196
- **Reproduction test**: `.specular-output/repro/test_bugMC-7_builder_listener_cme.sh`（sha256 `75d5a3b6…`，与上一轮相同）。Level 0 纯黑盒就能触发；Level 1 只用于确定性复现
- **Persistent record**: `confirmation/MC-7/issue.json` 已更新，`specular findings validate` 返回 `"valid": true`

## Description
`RetryerBuilder` 内部的 listener 列表是一个可变 `ArrayList`（`RetryerBuilder.java:40`）。`build()` 把这个列表原样传给 `Retryer`（`RetryerBuilder.java:196`），`Retryer` 也不复制，直接保存（`Retryer.java:137`）。`call()` 在 attempt 的 try/catch（`:159-164`）之外，用 fail-fast 迭代器遍历这个列表（`Retryer.java:166-168`）。

如果另一个线程这时调用 `builder.withRetryListener()`（`RetryerBuilder.java:63`，`ArrayList.add` 会 `modCount++`），`next()` 会抛出 `ConcurrentModificationException`，异常直接穿出 `call()`。此时 attempt 已经结束，它的返回值、它抛出的异常，以及本该接着发生的重试都会丢失，rejection predicate 和 stop strategy 一次都不会运行。CME 不在 `call()` Javadoc（`Retryer.java:146-153`）列出的结局里，也违反了 “A retryer is thread-safe”（`Retryer.java:39-40`）。

## Trigger scenario
反例 `spec/output/hunt_s3_listeners_bfs1.out`（sha256 `8a1b40f2…`，写于 08:05Z，本轮未变）共 7 个状态，步骤依次是：
1. `MCCallStart(c1)`：c1 进入 `call()`。
2. `MCCallerBodyStart(c1,"Ret")` 和 `MCCallerBodyReturns(c1)`：callable 返回了值，`curInvoked=TRUE`。
3. `MCListenersBegin(c1)`：创建迭代器，`itExpMod=1`，`itCursor=0`。
4. `MCAddListenerBegin(2)`：另一线程执行 `ArrayList.add` 中的 `modCount++`，`bmod=2`。
5. `MCListenerCME(c1)`：`outcome="CME"`，`exitInfo=[count 1, tag "Result", invoked TRUE]`。

TLC 输出只点名了 `DocumentedOutcomesOnly`，因为 TLC 在第一个被违反的不变式处就停止。

第二个反例 `hunt_sharing_bfs1.out` 共 10 个状态，机制相同，只是这次是 `fixedTimeLimit` 超时之后的 CME 吞掉了本该发生的重试。

对应的真实用法：一个 builder `build()` 出 retryer 后，retryer 在工作线程里或通过 `wrap()` 交给 executor 使用；与此同时，另一个线程继续在这个 builder 上 `withRetryListener(...)`，比如要再 build 一个变体（#48 的报告者就是这样用 builder 的）。

## Developer intent
- **#35（CLOSED）**：维护者回答 retryer “should all be thread-safe”，并给出了一个跨线程共享的 `static final` retryer 示例。
- **类 Javadoc**：`Retryer.java:39-40` 写着线程安全，前提是 “the arguments passed to its constructor are thread-safe”。但这个 `ArrayList` 是 `build()` 自己传进去的，用户无法控制。
- **listener 与 builder 的约束**：`RetryListener.onRetry`（`:28-35`）没有限制执行耗时，builder 也没有禁止在 `build()` 之后继续使用。
- **测试**：`RetryerBuilderTest:463-550` 全部是单线程用例，listener 都在 `build()` 之前加好。
- **blame**：相关代码来自 1edb757（PR #37）和 54a2a4d，提交信息里没有讨论复制列表或并发。
- **#48（OPEN，未修，0 条评论）**：与本 finding 同根因（builder 和 retryer 共享列表），但只写了顺序场景下的后果（多通知一个 listener），提议在 build 时 `ImmutableList.copyOf`。它没有提到并发、CME 或结果丢失。所以本 finding 是新后果、新机制，不是重述 #48。
- **本轮 tracker 复查**：
  - 2026-11-01 之后没有任何 issue 或 PR 有更新。
  - 搜索 “ConcurrentModificationException” 和 “concurrent modification” 都是 0 条结果。
  - “withRetryListener” 和 “listeners” 的命中集合与上轮相同。
  - `Retryer.java` 和 `RetryerBuilder.java` 在上游的最后一次提交都在 2015 年。
  - 上轮已经逐个看过全部 45 个 PR，包括 2026-09 关闭但未合并的 #107 和 #84。

## Reproduction result
在 `.specular-output/` 下执行（JDK 21.0.13.1）：
`timeout 15m bash repro/test_bugMC-7_builder_listener_cme.sh`

输出写到 `confirmation/MC-7/repro-output-repair1.log`，退出码 0。脚本编译的是未修改的 `177b6c9` 源码（`dirty-files=0`），用 Guava 22.0、`--release 8`。原文摘录：
```
source HEAD : 177b6c9b9f3e7957f404f0bdb8e23374cb1de43f  dirty-files=0
== run 1: UNMODIFIED guava-retrying 2.0.0
---- Level 0: pure black box (public API only, no sleeps, no hooks)
[L0-a] pure black box, 1 caller thread looping retryer.call() + 1 uncoordinated builder.withRetryListener() per trial
    trials=2000 (496 ms): call() threw ConcurrentModificationException in 673 trials (3 before the first listener ran = exact TLC interleaving, 670 after it ran); other failures=0
    of the CME trials, attempt executed (callable ran once) with predicate never consulted: 673
        java.util.ConcurrentModificationException
          at java.base/java.util.ArrayList$Itr.checkForComodification(ArrayList.java:1095)
          at java.base/java.util.ArrayList$Itr.next(ArrayList.java:1049)
          at com.github.rholder.retry.Retryer.call(Retryer.java:166)
    => BUG TRIGGERED at Level 0
[L0-b] pure black box, one Retryer shared by 2 pool threads via wrap(); main adds 1 listener per trial
    trials=200: trials with a CME-failed Future=138; futures ok=79780, failed with ExecutionException(cause=CME)=220, other=0
---- Level 1: timing help only (a user-supplied listener blocks on a latch during attempt 1)
[L1-a] retryer.call(c) | attempt 1 returns 42
    documented outcome : call() returns 42 after 1 attempt
    observed           : threw java.util.ConcurrentModificationException; value delivered to caller = none
    probes             : callable executions=1, rejection-predicate invocations=0, stop-strategy invocations=0, late listener notified=0
[...]
[L1-c] retryer.call(c) | attempt 1 exceeds fixedTimeLimit(200ms) (retryable), attempt 2 returns 42
    documented outcome : call() retries and returns 42 after 2 attempts
    observed           : threw java.util.ConcurrentModificationException; value delivered to caller = none
    probes             : callable executions=1, rejection-predicate invocations=0, stop-strategy invocations=0, late listener notified=0
[L1-d] executor.submit(retryer.wrap(c)).get() | attempt 1 returns 42
    observed           : threw java.util.concurrent.ExecutionException (cause: java.util.ConcurrentModificationException); value delivered to caller = none
    => BUG TRIGGERED: attempt executed, call() ended with ConcurrentModificationException, outcome lost, predicate/stop strategy never consulted
---- controls on the same unmodified build (no concurrent builder modification)
[C-a] control, same as above but NO concurrent withRetryListener | attempt 1 returns 42
    observed           : returned 42 | callable executions=1, rejection-predicate invocations=1, stop-strategy invocations=0, late listener notified=0  => documented outcome
[C-c] control, same as above but NO concurrent withRetryListener | attempt 1 exceeds fixedTimeLimit(200ms) (retryable), attempt 2 returns 42
    observed           : returned 42 | callable executions=2, rejection-predicate invocations=2, stop-strategy invocations=1, late listener notified=0  => documented outcome
SUMMARY(unmodified 2.0.0): Level0 single-caller CME trials=673/2000, Level0 shared-wrap trials with CME=138, Level1 reproduced=true, controls documented=true
== run 2: negative control (temp copy; build() copies the listener list)
[...]
    trials=2000 (468 ms): call() threw ConcurrentModificationException in 0 trials (0 before the first listener ran = exact TLC interleaving, 0 after it ran); other failures=0
SUMMARY(negative control): documented outcomes=true, Level0 CME trials=0
exit codes: unmodified=0 (0 = bug reproduced)  negative-control=0 (0 = symptom absent)
RESULT: BUG REPRODUCED on unmodified guava-retrying 2.0.0; symptom absent when build() copies the listener list
```

**哪些输出证明了 bug：**
- **Level 0**：L0-a 有 673 次 CME，栈顶都是 `Retryer.call(Retryer.java:166)`，每一次都是 callable 执行了 1 次、predicate 0 次。
- **与反例的对应**：
  - 其中 3 次发生在第一个 listener 运行之前，和 TLC 的交错（`itCursor=0`）完全一致。
  - 违反的性质与反例相同：结局不在文档列出的范围内，callable 执行了，结果却丢了。
- **Level 1**：L1-a 到 L1-d 4/4 确定复现，probe 都是 callable 1 次、predicate 0 次、stop strategy 0 次。L1-c 对应超时反例。

**与正确行为的对比：**
- 对照组 C-a/C-b/C-c 不做并发 add，都返回 42，predicate 和 stop strategy 的调用次数符合文档。
- 负对照只在临时副本里让 `build()` 复制列表，F-a 到 F-d 都返回 42，Level 0 出现 0 次 CME。

**本轮更正：**
- `issue.json` 里写的 “roughly 40-80% of trials” 不准确。本轮只有 673/2000（33.7%），所以实际观察到的范围是 34–81%：JDK 21 下 673/2000 和 876/2000，JDK 11 下 813/1000。已更正。
- `hunt_sharing_bfs1.out` 中，取消在 worker 启动 callable 之前就生效了（`MCCancelCASWon`），所以 `exitInfo.invoked=FALSE`，callable 没有执行，丢失的是超时 attempt 本该引发的重试。finding 摘要中 “two callers” 指的是配置里有两个 caller，实际只有 c1 在动。L1-c 覆盖的是同一个超时后 CME 的机制，区别在于它的 callable 已经开始执行，然后被打断。

上一轮的 JDK 21 日志和 JDK 11 日志都原样保留；本轮核对的细节追加在 `investigation.md` 末尾。

## Recommendation
- 在 `RetryerBuilder.build()`（`:196`）传入快照 `ImmutableList.copyOf(listeners)`。这正是 #48 提议的修法，负对照已经验证它能消除 CME 和丢结果，同时也修掉了 #48 的顺序后果。
- 在 `Retryer` 的 `@Beta` 构造器（`:137`）也做一次防御性复制，这样直接调构造器的用户也得到快照语义。
- 不要只在 listener 循环外 catch 异常，那会掩盖问题，attempt 的结局仍然会被打乱。

## REPRODUCED 检查清单
1. **Level 0 或 Level 1 单独能否触发？是。** L0-a 只用公开 API（`newBuilder`/`retryIfResult`/`withStopStrategy`/`withRetryListener`/`build`/`call`），没有 sleep 也没有 hook，2000 次里触发 673 次；L0-b 通过 `wrap()` 共享 retryer，有 220 个 future 失败。Level 1 只在用户自己的 `RetryListener` 里用 latch 控制时序，4/4 确定复现。
2. **是否用到 Level 2/3？不适用。** 没有做状态注入，也没有修改源码来制造症状。唯一的源码改动是临时副本里的负对照，而且是用来消除症状的。
3. **谁观察到错误结果？** 一是 `Retryer.call()`（`Retryer.java:155`）的直接调用方：本应拿到 42，实际收到 CME。二是库自己的 `RetryerCallable.call()`（`Retryer.java:317-319`），它把 CME 交给 executor，所以 `Future.get()` 抛 `ExecutionException(cause=CME)`（L1-d、L0-b）。
4. **坏状态是永久的还是会被修复？对受影响的那次调用是永久的。** `call()` 里唯一的 try/catch 只包住 attempt（`:159-164`），`RetryerCallable` 直接委托，没有任何机制恢复丢失的结局或补做重试，callable 的副作用也已经发生。没有任何东西掩盖这个后果，所以不是 MASKED。

---

## Entry 8: With a bounded limiter executor, attempts that time out in the queue or are rejected are counted as failed attempts although the callable never ran; `wrap()` on the limiter's own pool times out every attempt

- **Finding ID**: MC-8
- **Status**: FALSE POSITIVE
- **Debate**: not run
- **Transcript**: /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-8/debate.md

running pwd; ls -la; ls -la /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-8/;...
running ls -la /home/ubuntu/guava-retrying-20261126/Specular/ 2>/dev/null; ls -la /home/ubuntu/guava-retrying-20261126/ 2>/dev/null; find /home/ubuntu/guava-retrying...
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation && find . -type f | sort && wc -l $(find . -type f -name "*.md")
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation && for f in SKILL.md guide.md phases/01-investigation.md phases/02-reproduction.md;...
reading /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation/guide.md
reading /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation/phases/01-investigation.md
reading /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation/phases/02-reproduction.md
Skill 已读完（guide + Phase 1 + Phase 2）。接下来读 references，然后开始 Phase 1 代码审计。
reading /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation/references/persistent-findings.md
reading /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation/references/repair-request-format.md
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; ls -la $OUT; ls -la $OUT/repro 2>/d...
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; cat $OUT/persistent-findings-contex...
无历史 persistent 记录。开始 Phase 1：读源码。
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-8/worktree; cd $W && g...
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-8/worktree; cat -n $W/...
running find / -name "guava-22.0*" 2>/dev/null | grep -v proc | head -20; find / -type d -name "guava-22.0" 2>/dev/null | head
running mkdir -p /tmp/mc8-guava-src && cd /tmp/mc8-guava-src && unzip -o -q /home/ubuntu/scratch/guava22-sources-dl/guava-22.0-sources.jar com/google/common/util/con...
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec/output; wc -l $OUT/hunt_s4_exec...
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec/output; for f in hunt_s4_wrap_s...
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec/output; grep -nE "^State [0-9]+...
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-8/worktree/src/main/ja...
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-8/worktree; grep -n -i...
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-8/worktree; cd $W && g...
running find / \( -name "guava-1[0-9]*.jar" -o -name "guava-1[0-9]*-sources.jar" -o -name "guava-2[0-1]*.jar" \) 2>/dev/null | grep -v proc | head -20; W=/home/ubunt...
running mkdir -p /tmp/mc8-guava10 && cd /tmp/mc8-guava10 && timeout 60 curl -sSfL -o guava-10.0-sources.jar https://repo1.maven.org/maven2/com/google/guava/guava/10....
running gh auth status 2>&1 | head -5; for q in "bounded" "RejectedExecutionException" "executor" "thread pool" "fixedTimeLimit" "SimpleTimeLimiter" "queue" "starvat...
running for n in 69 18 29 65; do echo "################ #$n"; timeout 60 gh issue view $n --repo rholder/guava-retrying --comments 2>&1 | head -80; done
running for n in 29 18 69 94 96; do echo "################ #$n"; timeout 60 gh issue view $n --repo rholder/guava-retrying --json title,body,state,createdAt --jq '"\...
running timeout 90 gh pr list --repo rholder/guava-retrying --state all --limit 200 --json number,title,state,mergedAt,closedAt,updatedAt --jq '.[] | "\(.number)\t\(...
running for n in 107 1 84; do echo "################ PR #$n"; timeout 60 gh pr view $n --repo rholder/guava-retrying --json title,state,mergedAt,closedAt,body,files...
running ls /home/ubuntu/guava-retrying-20261126/Specular/case-studies | head -50; grep -ril "guava-retrying\|rholder" /home/ubuntu/guava-retrying-20261126/Specular/c...
running timeout 60 gh search repos "specula-case-studies" --json fullName --jq '.[].fullName' 2>&1 | head; timeout 60 gh api "search/code?q=guava-retrying+repo:specu...
running timeout 60 gh api repos/specular-org/specula-case-studies/contents/systems --jq '.[].name' 2>&1 | tr '\n' ' '; echo; timeout 60 gh api repos/specular-org/spe...
Specular 数据集中无 guava-retrying 记录；上游 tracker 无同机制报告。再补读 `RetryerBuilder`/`RetryListener` 的文档契约，然后写 `investigation.md`。
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-8/worktree/src/main/ja...
Phase 1 证据齐全，写入 `investigation.md`。
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-8/investigation.md
进入 Phase 2。先准备编译环境（JDK 21 `--release 8` + Guava 22.0 + jsr305）。
running find /home/ubuntu/.m2 -name "jsr305*.jar" 2>/dev/null | head; sha1sum /home/ubuntu/.m2/repository/com/google/guava/guava/22.0/guava-22.0.jar; cat /home/ubunt...
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/test_bugMC-8_bounded_executor_attempt_accounting.sh
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro && chmod +x test_bugMC-8_bounde...
running cd /home/ubuntu/guava-retrying-20261126/Specular && grep -rn "repair-request.body\|repair_request_body\|def .*validate.*draft\|counterexample" --include=*.py...
running cd /home/ubuntu/guava-retrying-20261126/Specular && sed -n 2615,2700p src/specular/confirmlib.py; echo ......; sed -n 2700,2880p src/specular/confirmlib.py
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-8/repair-request.body.md
用 dispatcher 自己的解析器校验草稿格式：
running cd /home/ubuntu/guava-retrying-20261126/Specular && cat specular | head -30; ls -d .venv 2>/dev/null; ls .venv/bin/python 2>/dev/null
running cd /tmp && cat > /tmp/mc8_validate_rr.py <<'EOF' import sys sys.path.insert(0, "/home/ubuntu/guava-retrying-20261126/Specular/src") sys.path.insert(0, "/home...
草稿通过 dispatcher 解析器校验。按 skill 的 persistent-findings 规则，invariant-repair 类结论不写 `issue.json`。清理我创建的临时文件：
running rm -rf /tmp/mc8-guava-src /tmp/mc8-guava10 /tmp/mc8_validate_rr.py; ls -d /tmp/mc8-repro.* 2>/dev/null | head; ls -la /home/ubuntu/guava-retrying-20261126/Sp...
# MC-8 确认结论：`PENDING REPAIR`（target `INVARIANT`）

反例路径在真实库里完整复现（Level 0，3/3 次运行）。但复现出来的结果正是库自己指向的 Guava 文档里写明的行为，没有任何调用方拿到违背文档承诺的结果。所以问题在 invariant `CountedImpliesInvokedNoStartRace` 要求过强，不是代码缺陷。

- **Source**: MC
- **Novelty**: NEW
- **Location**: `src/main/java/com/github/rholder/retry/Retryer.java:162`
- **Severity**: Medium（沿用 finding 的评级）
- **Reproduction test**: `repro/test_bugMC-8_bounded_executor_attempt_accounting.sh`（Level 0），日志在 `repro/MC-8.log`

Novelty 的依据：检索了 `rholder/guava-retrying` 的 issues 和全部 PR，含最近关闭的 #84（2026-09-20）和 #107（2026-09-05），也查了 Specular case-studies 数据集，都没有报告过这个机制。按 skill 规则，文档里的警告不算已有报告。

## Description
`fixedTimeLimit(d, unit, executor)` 直接把用户传入的 executor 交给 `SimpleTimeLimiter`（`AttemptTimeLimiters.java:69-72,93-95,105-108`）。Guava 22.0 的实现是先 `submit`，再从 submit 之后开始 `future.get(d)` 计时（`SimpleTimeLimiter.java:149-154`），所以在有界 executor 里排队的时间也算进时限。超时后 `cancel(true)`，但被取消的任务仍留在队列里（`:164-166`）。`Retryer.call` 把 limiter 抛出的任何异常都包成一个失败的 attempt（`Retryer.java:162-163`），包括排队超时的 `UncheckedTimeoutException` 和提交被拒的 `RejectedExecutionException`。这个 attempt 会通知 listener、消耗 stop 预算，并计入 `RetryException`。

这些都真实发生，但都是文档写明的行为：
- **文档出处**：`AttemptTimeLimiters.java:47-50` 让用户去看 `SimpleTimeLimiter(ExecutorService)` 的 note。那条 note 的原话是：使用有界 executor 时，"the call may even time out before the target method is ever invoked"。
- **设计意图**：limiter 的超时就按一次失败的 attempt 处理，见 issue #29 和 `AttemptTimeLimiterTest`。

## Trigger scenario
三个场景都只用公共 API，库源码未修改（`177b6c9`），时序只由用户自己的 callable 控制：

- **S1（对应 bfs1 和 bfs3）**：两个线程共用一个 `Retryer`，limiter 用 `TPE(1,1,ArrayBlockingQueue(1))`，配置为 `fixedTimeLimit(300ms)`、`retryIfRuntimeException`、`stopAfterAttempt(2)`。
  - caller-1 的 callable 忽略中断、运行 1500ms，超时后仍占着唯一的 worker。
  - caller-2 的 attempt#1 在队列里超时并被计数，attempt#2 因为队列里还留着它自己已取消的任务而被拒绝。
  - caller-1 的 attempt#2 同样被拒绝并计数。
- **S2（对应 wrap_samepool_bfs1）**：`pool.submit(retryer.wrap(c))`，而 limiter 用的正是这个单线程 `pool`。`RetryerCallable` 占住唯一线程，每个 attempt 都排在它后面直到超时，callable 一次都没被调用。
- **S2b**：同 S2，但用 `neverStop`。attempt 持续增加，callable 始终没被调用，已取消的任务在无界队列里持续堆积。
- **对照组**：limiter 换成 `newCachedThreadPool()`（库默认就是这类池），或者把 `wrap()` 提交到另一个池。此时 counted == invoked。

bfs3 里还能看到 attempt 1 的 callable 在 `call()` 结束后继续运行，那是另一个 invariant `NoActivityAfterOutcome`，这里不做判定。

## Developer intent
- **`AttemptTimeLimiters.java:47-50`**：随功能在 commit `7e474be`（dirkraft，2013-01-16）一起加入，指向 `SimpleTimeLimiter#SimpleTimeLimiter(ExecutorService)` 的 note。
- **Guava 22.0 `SimpleTimeLimiter.java:56-58`**："Warning: using a bounded executor may be counterproductive! If the thread pool fills up, any time callers spend waiting for a thread may count toward their time limit, and in this case the call may even time out before the target method is ever invoked." 我从 Maven Central 下载了 Guava 10.0 源码核对，这段话逐字相同（56-60 行）。10.0 正是 `7e474be` 编译时依赖的版本。
- **`AttemptTimeLimiter.java:22,31`**：time limit 包住的是整个 attempt；`@throws Exception any exception from this invocation`。
- **Issue #29**：time limiter 作者 dirkraft 说 "the attempt timeout should at a minimum behave like any other exception thrown by an attempt, and be subject to the exception-related retryer configuration"，owner 表示同意。
- **`AttemptTimeLimiterTest.java:44-50`**：断言超时会表现为该 attempt 的异常（`ExecutionException` 的 cause 是 `UncheckedTimeoutException`）。
- **反方证据**：`Attempt.java:6-7` 说 attempt 的异常是 "thrown by the call"。但任何一次超时都已经不符合这句话，测试里也是这样断言的，所以这句文档本身就不严格。PR #1 里说可以 "ensure some minimum number of attempts were made"，那是讲时间预算，不涉及有界 executor。
- 上游 tracker 中没有任何 issue 或 PR 把这个行为当作 bug 报告过。

## Reproduction result
命令：在 `.specular-output/repro/` 下执行 `timeout 600 ./test_bugMC-8_bounded_executor_attempt_accounting.sh > MC-8.log 2>&1`，退出码 0，3/3 次运行结果一致。以下摘自 run 1：

```
--- S1 | limiter pool = ThreadPoolExecutor(1,1,ArrayBlockingQueue(1))  [bounded, as in MC_hunt_s4_executor] | fixedTimeLimit(300 ms), retryIfRuntimeException(), stopAfterAttempt(2), fixedWait 0
      18 ms  caller-1  Retryer.call() begins
      33 ms  pool-1-thread-1 caller-1 callable INVOKED (#1), ignores interrupts, runs 1500 ms
      34 ms  caller-2  Retryer.call() begins
     335 ms  caller-1  [listener] attempt#1 exception=UncheckedTimeoutException | limiter queue=1 busy workers=1
     335 ms  caller-2  [listener] attempt#1 exception=UncheckedTimeoutException | limiter queue=1 busy workers=1
     335 ms  caller-1  [listener] attempt#2 exception=RejectedExecutionException | limiter queue=1 busy workers=1
     335 ms  caller-2  [listener] attempt#2 exception=RejectedExecutionException | limiter queue=1 busy workers=1
     336 ms  caller-1  Retryer.call() ends: RetryException(numberOfFailedAttempts=2, last cause=RejectedExecutionException)
     336 ms  caller-2  Retryer.call() ends: RetryException(numberOfFailedAttempts=2, last cause=RejectedExecutionException)
    1534 ms  pool-1-thread-1 caller-1 callable finished (#1)
  summary: caller-1 -> RetryException(numberOfFailedAttempts=2, last cause=RejectedExecutionException), callable invocations=1; caller-2 -> RetryException(numberOfFailedAttempts=2, last cause=RejectedExecutionException), callable invocations=0 (after the pool drained and terminated)
  [S1 control, newCachedThreadPool] summary: caller-1 -> RetryException(numberOfFailedAttempts=2, last cause=UncheckedTimeoutException), callable invocations=2; caller-2 -> returned c2-done, callable invocations=1 (after the pool drained and terminated)
--- S2 | limiter pool = 1-thread pool; RetryerCallable submitted to THE SAME pool  [as in MC_hunt_s4_wrap_samepool] | fixedTimeLimit(300 ms), retryIfExceptionOfType(UncheckedTimeoutException), stopAfterAttempt(3)
    4845 ms  pool-3-thread-1 [listener] attempt#1 exception=UncheckedTimeoutException | limiter queue=1 busy workers=1
    5145 ms  pool-3-thread-1 [listener] attempt#2 exception=UncheckedTimeoutException | limiter queue=2 busy workers=1
    5446 ms  pool-3-thread-1 [listener] attempt#3 exception=UncheckedTimeoutException | limiter queue=3 busy workers=1
  summary: RetryerCallable -> RetryException(numberOfFailedAttempts=3, last cause=UncheckedTimeoutException), callable invocations=0 (after both pools terminated); cancelled attempt tasks left in the limiter queue when call() ended=0
  [S2 control, separate pool] summary: RetryerCallable -> returned ok, callable invocations=1 (after both pools terminated); cancelled attempt tasks left in the limiter queue when call() ended=0
--- S2b (neverStop, 100 ms limit)
    6449 ms  main      after 1000 ms: attempts counted=9, callable invocations=0, limiter queue=10, outer done=false
    7450 ms  main      after 2000 ms: attempts counted=19, callable invocations=0, limiter queue=20, outer done=false
    8450 ms  main      after 3000 ms: attempts counted=29, callable invocations=0, limiter queue=30, outer done=false
    8451 ms  main      after cancelling the outer task: pool terminated=true, callable invocations=0
RESULT: MC-8 counterexample path realised in the real library (all scenarios + controls as predicted)
MC-8 REPRO: counterexample path realised in 3/3 runs
```
（两行带 `[S1 control …]`、`[S2 control …]` 前缀的是对照组 summary，前缀是我加的，便于阅读；其余行逐字摘自日志。完整输出见 `repro/MC-8.log`。）

与反例逐步对应：

| 反例 | 反例中的状态 | 实测 |
|---|---|---|
| bfs1 | states 5→9：`MCSubmitQueued` → `MCGetTimeout` → `MCCancel*`，c2 进入 `Classified`，`curQueued=TRUE`、`curInvoked=FALSE` | caller-2 的 attempt#1：`UncheckedTimeoutException`，`limiter queue=1`，0 次调用 |
| wrap_samepool | `wOuter=w1:>c1` 时出现同样的分类 | S2：attempt 1–3 全部排队超时，0 次调用 |
| bfs3 | `MCSubmitRejected` → `MCStopStrategyStops`，count=2 | caller-1：`RetryException(2)`，1 次调用，最后一个 attempt 是 `RejectedExecutionException` |

对照组里 counted == invoked，说明这个效应只在文档警告过的那类配置下出现。

## Recommendation
**对 spec（即本 RR）**：修改 `CountedImpliesInvokedNoStartRace`，二选一：
- **方案 A**：只在 limiter 用不会排队、也不会拒绝任务的 executor 的配置里要求 counted ⇒ invoked。
- **方案 B**：在 `MC_hunt_s4_executor.cfg` 和 `MC_hunt_s4_wrap_samepool.cfg` 里改为：一个被计数但 callable 从未运行的 attempt，必须带 limiter 产生的失败（Timeout 或 Rejected），不能是 result，也不能是 callable 抛出的异常。这样改后仍能抓到真正的误报。

**对库**（可选，属于改进而不是修 bug）：
- 在三参数的 `fixedTimeLimit` 和 `wrap()` 上直接写明有界 executor 的风险，并说明不要把 `RetryerCallable` 提交到它自己的 limiter 池。
- 可考虑从任务真正开始运行时才计时，或者为"尚未开始就失败"单独定义一种异常。

**对用户**：limiter 用无界的 cached pool，或者把池的大小按"最大并发 attempt 数 + 超时后仍在运行的任务"来配；不要和 `wrap()` 共用同一个池。

## Checklist
1. **Level 0 或 Level 1 是否单独触发？** 是。只用公共 API，库源码未修改，时序只来自用户 callable 里的 sleep 和 latch。
2. **是否用了 Level 2/3？** 没有，本项不适用。
3. **哪个真实调用方看到了错误结果？** 没有。`Retryer.call` 的调用方（通过 `RetryException.getNumberOfFailedAttempts()`）、`RetryListener.onRetry`、`StopStrategy` 确实会看到"计了数但 callable 没运行"的 attempt，但这正是 `AttemptTimeLimiters.java:47-50`（指向 `SimpleTimeLimiter.java:56-58`）、#29 和 `AttemptTimeLimiterTest.java:44-50` 写明的结果。没有违背任何承诺，所以不判 `REPRODUCED`。
4. **状态是永久的，还是会被下游机制纠正或掩盖？** 计数对那次调用是最终结果，没有被下游机制纠正。但这里没有被安全机制掩盖的缺陷，`MASKED` 不适用。这是 invariant 把文档写明的状态当成了坏状态，按规则走 `PENDING REPAIR`（`INVARIANT`）。

按 skill 规则，invariant-repair 类结论不写 `issue.json`。worktree 保持干净。

## Repair round 1 evidence
<!-- specular-repair-token: 3eefa76b5b37ed587e41b6cbdb823026 -->
- **Repair request**: `/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec/repair-requests/RR-002.md`
- **Phase 3 result**: r1 (phase3-repair): CountedImpliesInvokedNoStartRace now accepts timeouts and capacity rejections of a running executor (ghost curQueued = ~exShutdown at SubmitRejected); still flags CallerIE and post-shutdown rejections (MC-4, MC-9). Off (vacuous) in s4_executor, s4_wrap_samepool. 380/380 traces; MC.cfg exhaustive; s4_executor: only MC-1, then exhaustive; s4_wrap_samepool exhaustive; acceptance controls exhaustive; violated in s4_shutdown and sharing. MC-8 is not a current violation. Evidence: spec/output/repair-r1/.

---

## Entry 9: After the limiter's executor is shut down, `RejectedExecutionException` is recorded as the callable's failure: `call()` throws `ExecutionException` though the callable never ran, or spins through attempts that never run

- **Finding ID**: MC-9
- **Status**: REPRODUCED
- **Debate**: not run
- **Transcript**: /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-9/debate.md

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

---

## Entry 10: A negative computed sleep makes `call()` throw `IllegalArgumentException` — an undocumented outcome that also pre-empts the `RetryException` owed to an interrupted thread

- **Finding ID**: MC-10
- **Status**: REPRODUCED
- **Debate**: not run
- **Transcript**: /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-10/debate.md

running pwd; ls -la; find / -type d -name "bug-confirmation" 2>/dev/null | head -20
running ls -la ~/.claude/skills 2>/dev/null; ls -la /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.claude 2>/de...
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; cat SKILL.md; echo ======; cat guide.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; cat phases/01-investigation.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; cat phases/02-reproduction.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; ls -la references; for f in references/*; do echo "===== $f"; cat "$f"; done
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; ls -la; echo ----; ls -la confirmati...
MC-10 确认任务开始：已读完 bug-confirmation skill（guide + Phase 1/2 + references），接下来查看 worktree 源码和本 finding 的反例。
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-10/worktree; ls -la;...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-10/worktree; cat -n s...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec; ls output | grep -i "hunt_s5_de...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec; sed -n '1,200p' output/hunt_s5_...
running mkdir -p /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-10/scratch && c...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec; python3 -I /home/ubuntu/guava-r...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; cat persistent-findings-context.json...
running ls /home/ubuntu/guava-retrying-20261126/Specular/ ; ls /home/ubuntu/guava-retrying-20261126/Specular/bin 2>/dev/null; find /home/ubuntu/guava-retrying-202611...
running cd /home/ubuntu/guava-retrying-20261126/Specular; file specular; head -30 specular; ls .venv 2>/dev/null | head
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; SP=/home/ubuntu/guava-retrying-20261...
running which gh && gh auth status 2>&1 | head -5; timeout 60 gh api repos/rholder/guava-retrying --jq '.full_name + " open_issues=" + (.open_issues_count|tostring)...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-10/scratch; timeout 1...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-10/scratch; python3 -...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-10/scratch; cat > gre...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-10/scratch; python3 -...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-10/scratch; for n in...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-10/scratch; timeout 1...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-10/scratch; timeout 6...
running timeout 60 gh api "repos/rholder/guava-retrying/compare/master...13-return-original-builder" --jq '"ahead=" + (.ahead_by|tostring) + " behind=" + (.behind_by...
running timeout 60 gh api "repos/rholder/guava-retrying/compare/master...13-return-original-builder" --jq '("ahead=" + (.ahead_by|tostring) + " behind=" + (.behind_b...
running timeout 60 gh api "repos/rholder/guava-retrying/compare/master...13-return-original-builder" --jq '.commits[] | .sha[0:7] + " " + .commit.author.date[0:10] +...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-10/worktree; git log...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-10/worktree; for c in...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-10/worktree; ls src/t...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-10/worktree; sed -n '...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-10/worktree; grep -n...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-10/worktree; sed -n '...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; ls -la harness; find harness -maxdep...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/harness; cat pom.xml; echo ----; cat...
running SRC=/home/ubuntu/scratch/guava-retrying-src/guava-retrying; WT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-ret...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-10/worktree; sed -n '...
running for j in /usr/lib/jvm/java-21-openjdk-amd64 /usr/lib/jvm/java-11-openjdk-amd64; do ls -la $j/lib/src.zip 2>/dev/null || echo "no src.zip in $j"; done; unzip...
running ls -la /usr/lib/jvm/openjdk-21/ /usr/lib/jvm/openjdk-11/ 2>&1 | head; find / -name "src.zip" -path "*jvm*" 2>/dev/null | head
下面写 Phase 1 的 `investigation.md`（只记录证据，不下结论）。
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-10/investigation.md
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/test_bugMC-10_negative_sleep_iae.sh
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro; chmod +x test_bugMC-10_negativ...
两个 JDK（21 和 11）上全部场景一次复现，对照组都按文档行为通过。再连跑 3 次确认是确定性的：
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro; for i in 1 2 3; do timeout 10m...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-10/worktree/src/main/...
running cd /home/ubuntu/guava-retrying-20261126/Specular; timeout 60 ./specular findings --help 2>&1 | head -40; grep -rn -l "def.*validate" src/specular/*.py src/sp...
running cd /home/ubuntu/guava-retrying-20261126/Specular; grep -n -E "REQUIRED|required|ALLOWED|STATUSES|status|\"title\"|160|premises|actions|invariants|sites|cause...
running cd /home/ubuntu/guava-retrying-20261126/Specular; sed -n '20,42p;340,425p' src/specular/persistent_findings.py
running cd /home/ubuntu/guava-retrying-20261126/Specular; sed -n '236,278p' src/specular/persistent_findings.py
running cat > /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-10/issue.json <<'E...
`issue.json` 已通过 `specular findings validate`（`valid: true`）。最后确认一下产物：
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; ls -la repro/test_bugMC-10_negative_...
# MC-10：负的计算 sleep 让 `Retryer.call()` 抛出 `IllegalArgumentException`，中断线程拿不到应得的 `RetryException`

**结论**：MC-10 已复现。只用公共 API、内置策略、未修改的 2.0.0 源码，在 JDK 21 和 JDK 11 上都稳定触发；3 轮重跑结果完全一致，三个对照组都表现为文档规定的行为。

- **Source**: MC
- **Novelty**: NEW
- **Location**: `src/main/java/com/github/rholder/retry/Retryer.java:178`
- **Severity**: Medium
- **Reproduction test**: `repro/test_bugMC-10_negative_sleep_iae.sh`（Level 0），日志在 `repro/MC-10.log`
- **Persistent record**: `confirmation/MC-10/issue.json`（`specular findings validate` 结果为 `valid: true`）

## Description
`Retryer.call` 把 `waitStrategy.computeSleepTime(attempt)` 的返回值直接传给 `blockStrategy.block(sleepTime)`，不做校验也不 clamp（`Retryer.java:176-178`），外面只 catch 了 `InterruptedException`（`Retryer.java:179`）。默认的 `ThreadSleepStrategy` 直接调用 `Thread.sleep(sleepTime)`（`BlockStrategies.java:46`）。JDK 对负值会先抛 `IllegalArgumentException("timeout value is negative")`，之后才检查中断位。后果有两个：

- **不在文档里的结束方式**：异常从 `call()` 逃出，既不是返回值，也不是 `ExecutionException` 或 `RetryException`。重试在第 1 次 attempt 后就终止了，即使下一次 attempt 本来会成功。
- **中断合约被破坏**：线程已被中断时，调用方拿到的是 IAE（中断位仍为 true），而不是 Javadoc 承诺的 `RetryException`。IAE 的 `getCause()==null`，attempt 次数和最后一次失败都丢了。

本 finding 只覆盖 block 这一步。负值的来源用了两个可达的内置途径，只当作触发条件：`join` 的 long 溢出（`WaitStrategies.java:365-371`），以及 `exceptionWait` 原样透传用户函数的返回值（`:386-394`）。这两个来源各自的缺陷按去重说明另由 CR-D-16 / CR-D-17 跟踪。

## Trigger scenario
构造 Retryer：

```java
RetryerBuilder.<String>newBuilder()
    .retryIfExceptionOfType(IOException.class)
    .withStopStrategy(StopStrategies.stopAfterAttempt(3))
    .withWaitStrategy(WaitStrategies.join(
        fixedWait(Long.MAX_VALUE, MILLISECONDS),
        fixedWait(1, MILLISECONDS)))
    .build()
```

两个 `fixedWait` 都能通过各自 `sleepTime >= 0` 的检查（`WaitStrategies.java:237`）。

**与 bfs1 对应（`DocumentedOutcomesOnly`）**：
1. attempt 1 抛出 `IOException`（CE 步骤 3-4）。
2. listener 执行（步骤 5-7）。
3. 拒绝谓词决定重试，stop 策略不停止。
4. `computeSleepTime` 返回 `-9223372036854775808`（步骤 8）。
5. `Thread.sleep` 抛 IAE，IAE 逃出 `call()`（步骤 9）。

更贴近真实使用的来源：`exceptionWait(503.class, e -> retryAt - now)`，服务器给的 Retry-After 时刻因时钟偏差已经过去，算出的值约为 -2000。

**与 bfs3 对应（`InterruptedCallThrowsRetryException`）**：前面相同，但在 `RetryListener` 循环执行期间，另一个线程调用 `Thread.interrupt()`（CE 步骤 7）。结果是 IAE 且中断位为 true，而不是 `RetryException`。补充变体：调用 `call()` 前中断就已挂起，callable 忽略中断后失败（S3）。

## Developer intent
- **`Retryer.call` 的 Javadoc**（`Retryer.java:140-154`）只列了三种结局：
  - 返回结果；
  - `ExecutionException`；
  - `RetryException`，并写明 "if the thread is interrupted, this exception is thrown and the thread's interrupt status is set"。
- README Quickstart 示例里的调用方只 catch 这两种异常。
- **开发者有意避免负 sleep**：
  - `fixedWait` 拒绝负值（`:56`、`:237`）。
  - Incrementing、Exponential、Fibonacci 三个策略都用 `result >= 0L ? result : 0L` 把结果截到 0（`:283`、`:308`、`:334`）。这个写法在原始 JB 代码 c531b61、fd8b13b、ce0bc7d 里就有。
  - `join`（2b5bfec）和 `exceptionWait`（9c6bd63，PR #26）都没有做这种处理。
- **已有测试**：`RetryerBuilderTest.testInterruption` 断言中断后得到 `RetryException` 且中断位已设置。没有任何测试覆盖负 sleep。
- **上游检索**：查了全部 106 个 issue/PR（含已关闭和已合并）、185 条 issue 评论和 5 条 review 评论，并用 `gh search` 搜了 "negative" 和 "IllegalArgumentException"。没有找到同一机制的报告。
  - 最接近的 #101 是未合并的 PR，只处理 `sleepTime == 0`；#63 和 #40 是不同问题。
  - 指南列出的已知问题 #48、#92、#29、#67、#94 也都是不同机制。
  - 上游 master 自 177b6c9（2016-05-10）以来没有新提交。

## Reproduction result
从 `.specular-output/repro` 运行 `timeout 10m ./test_bugMC-10_negative_sleep_iae.sh 2>&1 | tee MC-10.log`。构建用的是未修改的 worktree `177b6c9`（0 local modifications），编译参数为 `javac 21.0.13.1 --release 8`，依赖 Guava 22.0 + jsr305 2.0.2。下面是 JDK 21 输出的原文节选，完整日志见 `repro/MC-10.log`：

```
[S1a] bfs1 / DocumentedOutcomesOnly: attempt 1 throws IOException, retryable, stopAfterAttempt(3),
      wait = join(fixedWait(Long.MAX_VALUE ms), fixedWait(1 ms)), default ThreadSleepStrategy, 1 listener
      wait strategy value for the failed attempt: computeSleepTime = -9223372036854775808
      still blocked in the wait after 3 s (documented behaviour): false
      call() ended with      : UNDOCUMENTED IllegalArgumentException  [java.lang.IllegalArgumentException: timeout value is negative]
      documented outcome?   : false
      interrupt status @exit: false
      callable invocations  : 1; listener saw attempts [1]; elapsed 1 ms
      thrown.getCause()     : null  (attempt count / last failure reachable from the thrown exception: false)
      origin of the escaping exception (top frames):
        at java.base/java.lang.Thread.sleep(Thread.java:500)
        at com.github.rholder.retry.BlockStrategies$ThreadSleepStrategy.block(BlockStrategies.java:46)
        at com.github.rholder.retry.Retryer.call(Retryer.java:178)
  => S1a: BUG TRIGGERED - IllegalArgumentException escaped Retryer.call() after attempt 1 (not result/ExecutionException/RetryException)
  => S1b: BUG TRIGGERED - retrying aborted with IllegalArgumentException; attempt 2 (which would return "ok") never ran
  => S1b-ctl: control OK - call() retried and returned "ok" from attempt 2

[S2] bfs3 / InterruptedCallThrowsRetryException: attempt 1 throws IOException; another thread interrupts
     the caller while the RetryListener loop runs (CE step 7); wait = overflowing join (CE step 9: Negative)
     interrupt observed inside the listener loop: true
     call() ended with      : UNDOCUMENTED IllegalArgumentException  [java.lang.IllegalArgumentException: timeout value is negative]
     documented outcome?   : false
     interrupt status @exit: true
     callable invocations  : 1; listener saw attempts [1]; elapsed 0 ms
     thrown.getCause()     : null  (attempt count / last failure reachable from the thrown exception: false)
     documented (Retryer.call Javadoc): RetryException(numberOfFailedAttempts=1, cause=IOException), interrupt status set
  => S2: BUG TRIGGERED - interrupted call ended with IllegalArgumentException instead of RetryException; attempt count and last failure lost

[S2-ctl] identical, but a non-negative wait (join(fixedWait(10 ms), fixedWait(1 ms)))
     call() ended with      : RetryException  [com.github.rholder.retry.RetryException: Retrying failed to complete successfully after 1 attempts.]
     interrupt status @exit: true
     RetryException        : numberOfFailedAttempts=1, cause=java.io.IOException: transient failure on attempt 1
  => S2-ctl: control OK - RetryException(1 attempt, cause IOException) with interrupt status set - the documented outcome
  => S3: BUG TRIGGERED - interrupted call ended with IllegalArgumentException instead of RetryException
  => S3-ctl: control OK - RetryException(1 attempt, cause IOException) with interrupt status set
     Future.get() -> ExecutionException, cause=java.lang.IllegalArgumentException: timeout value is negative; callable invocations=1
  => S4: BUG TRIGGERED - RetryerCallable.call() (Retryer.java:317-319) propagated the IAE into the Future instead of retrying
RESULT: MC-10 REPRODUCED on java 21.0.13.1 - negative computed sleep -> Thread.sleep IAE escapes Retryer.call(); on an interrupted thread it replaces the RetryException
...
RESULT: MC-10 REPRODUCED on java 11.0.33.1 - negative computed sleep -> Thread.sleep IAE escapes Retryer.call(); on an interrupted thread it replaces the RetryException
OVERALL: MC-10 REPRODUCED on every JDK run
```

**确定性**：又连跑 3 轮，每轮都是 exit=0，10 行 `BUG TRIGGERED`、6 行 `control OK`。

**与反例逐步对照**：
- 动作顺序一致：CallableExc → ListenerNotify → [Interrupt] → Negative → IAE。
- 退出状态一致，都是 `exitInfo=[flag TRUE, count 1, tag CallableExc]`。
- 违反的不变式一致，都是 `DocumentedOutcomesOnly` / `InterruptedCallThrowsRetryException`。
- 栈帧落在 finding 指出的 `Retryer.java:178` → `BlockStrategies.java:46`。

**对照组**：配置完全相同、只把 sleep 改成非负时，得到的就是文档规定的 `RetryException`，且中断位已设置。这说明异常差异完全来自负 sleep。

## Recommendation
1. **在唯一的 block 入口截断负值**：在 `Retryer.call` 里写 `long sleepTime = Math.max(0L, waitStrategy.computeSleepTime(attempt));`，做法和内置策略的 `>= 0 ? : 0` 一致。同时在 `WaitStrategy`/`BlockStrategy` 的 Javadoc 里写明负值按 0 处理。截断到 0 后 `Thread.sleep(0)` 仍会检查中断，`RetryException` 路径能保住。
   - 注意：如果将来合并 #101 那种 "sleepTime==0 就不 sleep" 的改法，要在 block 之前显式检查一次 `Thread.interrupted()`（检查后恢复中断位并抛 `RetryException`），否则中断合约会以另一种方式失效。
2. **另行修复两个负值来源**：`CompositeWaitStrategy` 改成饱和加法（CR-D-16）；`exceptionWait` 截断到 0 或抛出有文档说明的异常（CR-D-17）。
3. **补回归测试**：用 `join(fixedWait(Long.MAX_VALUE ms), fixedWait(1 ms))` 加一个已中断的线程，断言得到 `RetryException`、`getNumberOfFailedAttempts()==1`，且中断位已设置。

## 判定检查表
1. **仅靠 Level 0 或 Level 1 是否触发？是。**
   - S1a、S1b、S3、S4 是纯 Level 0：只用公共 API，没有任何时序辅助。
   - S2 为贴合 bfs3 第 7 步，在测试自己写的 `RetryListener` 里用 latch 等待，把外部线程的 `Thread.interrupt()` 安排到 listener 循环内。这只是用户代码里的时序控制，最多算 Level 1，没有改动库代码。
2. **是否用了 Level 2/3？没有**，因此不需要额外论证注入状态的可达性。
3. **哪个真实调用方看到了错误结果？**
   - 公共 `Retryer.call(Callable)` 的调用方（`Retryer.java:155`）：按 README 写的 `catch (RetryException)` / `catch (ExecutionException)` 被绕过（S1a/S1b/S2/S3）。
   - `Retryer.RetryerCallable.call()`（`Retryer.java:317-319`）：把 IAE 传进 `ExecutorService` 的 `Future`。S4 中 `Future.get()` 得到 `ExecutionException(cause=IllegalArgumentException)`，callable 只执行了 1 次，而第 2 次 attempt 本会返回 "ok"。
4. **错误状态是否永久？是，没有被掩盖（不是 MASKED）。**
   - IAE 已经终止了 `call()`，下游没有任何机制会重试、转换或重建 `RetryException`。
   - IAE 的 cause 为 null，这次调用的 attempt 次数和最后一次失败都无法再取回。
   - 退出时中断位仍为 true（S2/S3）。

## Repair round 1 evidence
<!-- specular-repair-token: 3eefa76b5b37ed587e41b6cbdb823026 -->
- **Current violation analysis**: Retryer.call passes waitStrategy.computeSleepTime(attempt) to the block strategy unvalidated and catches only InterruptedException (Retryer.java:176-182); ThreadSleepStrategy calls Thread.sleep directly (BlockStrategies.java:46), which throws IllegalArgumentException for a negative value before it checks the interrupt status. Negative sleeps come from the unchecked join sum (WaitStrategies.java:225-230, 365-371) and exceptionWait's unclamped user value (:386-394) (code-review ledger D-16/D-17). TLC: the IAE escapes call() after a failed attempt (hunt_s5_decision_bfs1.out, 9 states, Documented…
- **Counterexample**: `spec/output/hunt_s5_decision_bfs3.out`

## Phase 4 confirmation after repair round 1

running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-10 && ls -la && echo...
running find / -type d -name 'bug-confirmation' 2>/dev/null | head -20
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation && ls -la . phases references 2>/dev/null; echo ======; cat SKILL.md; echo ======; c...
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation && cat phases/01-investigation.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation && cat phases/02-reproduction.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation && for f in references/*; do echo "===== $f"; cat "$f"; done
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-10 && python3 -I -c "...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-10 && cat investigati...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec && ls -la --time-style=full-iso...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-10/worktree && git lo...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/spec && cat output/hunt_s5_decision_b...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro && ls -la --time-style=full-iso...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-10/worktree/src/main/...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro && date -u +"run start %Y-%m-%d...
running cd /tmp && timeout 60 gh api repos/rholder/guava-retrying --jq '"repo=" + .full_name + " pushed_at=" + .pushed_at + " updated_at=" + .updated_at + " open_iss...
running cd /tmp && for q in "negative sleep" "IllegalArgumentException sleep" "timeout value is negative" "computeSleepTime negative" "join overflow" "exceptionWait...
running cd /tmp && for n in 107 101; do echo "===== PR #$n files"; timeout 60 gh api "repos/rholder/guava-retrying/pulls/$n/files?per_page=100" --jq '.[] | .filename...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-10 && cat issue.json;...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output && stat -c '%y %n' spec/MC_hunt_s5_de...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-10 && tail -c 400 inv...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-10 && cat >> investig...
追加完成。下面用 diff 核实刚才"每一行 BUG/control 都和第一轮一致"这句话。
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro && for f in MC-10.log MC-10.r1....
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-10 && python3 -I - <<...
running cd /home/ubuntu/guava-retrying-20261126/Specular && timeout 120 ./specular findings --work /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-...
`issue.json` 校验通过（`valid: true`）。最后清理我在 `/tmp` 里留下的两个临时比对文件。
running rm -f /tmp/mc10_MC-10.lines /tmp/mc10_MC-10.r1.lines; cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/...
# MC-10：wait 策略算出负的 sleep 时，`Retryer.call()` 抛出 `IllegalArgumentException`；线程已被中断时，这个异常顶替了应得的 `RetryException`（repair round 1 续作）

**结论**：MC-10 仍然复现。这一轮在当前 worktree（`177b6c9`，0 处本地修改）上，用未修改的复现脚本在 JDK 21.0.13.1 和 JDK 11.0.33.1 上重跑：脚本退出码为 0，共 10 行 `BUG TRIGGERED` 和 6 行 `control OK`，判定行与第一轮日志逐行相同。

- **Source**: MC
- **Novelty**: NEW
- **Location**: `src/main/java/com/github/rholder/retry/Retryer.java:178`
- **Severity**: Medium
- **Reproduction test**: `repro/test_bugMC-10_negative_sleep_iae.sh`。Level 0；S2 只在测试自己的 listener 里用 latch 控制时序，最多算 Level 1。
- **日志**：第一轮 `repro/MC-10.log`，本轮 `repro/MC-10.r1.log`
- **Persistent record**: `confirmation/MC-10/issue.json`，本轮把 `repro/MC-10.r1.log` 加进了 evidence，`specular findings validate` 返回 `valid: true`

## 本轮核对与更正
- **反例**：`spec/output/hunt_s5_decision_bfs3.out` 自第一轮确认以来没有变（mtime 08:15，sha256 `9b4aeab6…13da`）。路径依次为：State 6 `MCListenerNotify`，State 7 `MCInterrupt(c1)`，State 8 `MCListenersEnd`，State 9 `MCWaitStrategyComputes(c1,"Negative")`，State 10 `MCBlockNegative(c1)`，结果 `outcome="IAE"`。违反的不变式是 `InterruptedCallThrowsRetryException`。
- **一处补充**：State 10 的 `exitInfo` 完整内容是 `[flag TRUE, count 1, tag CallableExc, invoked TRUE]`。第一轮记录漏了 `invoked` 字段。它和复现结果一致（callable 调用 1 次），不影响结论。没有发现被推翻的旧结论。
- **模型改动**：`spec/base.tla` 的 mtime 是 12:28，晚于反例和第一轮确认，应该是 repair round 1 改的。按规定我没有读 spec 内容。判定依据是真实代码上的复现，它与反例的动作序列逐步对应。
- **源码**：worktree 与配置的源码树逐字节相同，引用的行号全部仍然对得上。
- **上游**：重新检索过。master 仍是 177b6c9；2026-11-01 之后没有 issue 或 PR 更新过；8 组关键词的 `gh search`（open 和 closed，含 PR）都是 0 命中。最近关闭的 PR 都没有合并，#107 "Modernize" 是把 Java 源码换成了 PHP 移植，与此无关。#101 仍然只处理 `sleepTime == 0L`。
- **记录**：`investigation.md` 末尾追加了 "Repair round 1 continuation" 一节。

## Description
`Retryer.call` 把 `waitStrategy.computeSleepTime(attempt)` 的结果原样传给 `blockStrategy.block(sleepTime)`，既不校验也不截断（`Retryer.java:176-178`），外面只 catch 了 `InterruptedException`（`Retryer.java:179`）。默认的 `ThreadSleepStrategy` 直接调用 `Thread.sleep(sleepTime)`（`BlockStrategies.java:46`）。JDK 遇到负值会先抛 `IllegalArgumentException("timeout value is negative")`，然后才检查中断位。这带来两个后果：

- **出现文档之外的结束方式**：`call()` 抛出的既不是结果，也不是 `ExecutionException` 或 `RetryException`。重试在第 1 次 attempt 后就终止了，哪怕下一次本来会成功。
- **中断合约被破坏**：线程已被中断时，调用方拿到的是 IAE（中断位仍为 true），而不是 Javadoc 承诺的 `RetryException`。IAE 没有 cause，attempt 次数和最后一次失败都无从取得。

本 finding 只覆盖 block 这一步。负值的来源（`join` 的 long 溢出，`WaitStrategies.java:365-371`；`exceptionWait` 原样透传用户函数的返回值，`:386-394`）只用作触发条件，它们本身的缺陷另由 CR-D-16 / CR-D-17 跟踪。

## Trigger scenario
```java
RetryerBuilder.<String>newBuilder()
    .retryIfExceptionOfType(IOException.class)
    .withStopStrategy(StopStrategies.stopAfterAttempt(3))
    .withWaitStrategy(WaitStrategies.join(
        fixedWait(Long.MAX_VALUE, MILLISECONDS),
        fixedWait(1, MILLISECONDS)))   // 两个参数各自都能通过 :237 的 sleepTime >= 0 检查
    .build()
```

**对应 bfs1（`DocumentedOutcomesOnly`）**：
1. attempt 1 抛出 `IOException`。
2. listener 执行。
3. 拒绝谓词判定为重试，stop 策略不停止。
4. `computeSleepTime` 返回 `-9223372036854775808`。
5. `Thread.sleep` 抛出 IAE，IAE 逃出 `call()`。

**对应 bfs3（`InterruptedCallThrowsRetryException`）**：前面步骤相同，只是在 `RetryListener` 循环执行期间，另一个线程调用了 `Thread.interrupt()`（对应反例第 7 步）。最终得到 IAE，且中断位为 true。

**补充场景**：
- S3：调用 `call()` 前中断就已挂起。
- S1b/S4：更贴近实际使用的来源 `exceptionWait(503, e -> retryAt - now)`。服务器给的 Retry-After 时刻因为时钟偏差已经过去，算出约 -2000。S4 走的是 `wrap()` 交给 `ExecutorService` 的路径。

## Developer intent
- **`Retryer.call` 的 Javadoc**（`Retryer.java:140-154`）只列了三种结局：返回结果、`ExecutionException`、`RetryException`，并写明 "if the thread is interrupted, this exception is thrown and the thread's interrupt status is set"。README 示例里也只 catch 这两种异常。
- **开发者有意不让负值进入 block 这一步**：
  - `fixedWait` 拒绝负值（`:56`、`:237`）。
  - Incrementing、Exponential、Fibonacci 三个策略都用 `result >= 0L ? result : 0L` 截断（c531b61、fd8b13b、ce0bc7d）。
  - `join`（2b5bfec）和 `exceptionWait`（9c6bd63，PR #26）没有做这种截断。
- **现有测试**：`RetryerBuilderTest.testInterruption` 断言中断后得到 `RetryException`，且中断位已设置。没有任何测试覆盖负 sleep。
- **上游**：第一轮查过全部 issue/PR 和评论，本轮又补了一次检索，都没有找到同一机制的报告。指南列出的已知问题 #48、#92、#29、#67、#94 都是不同机制。

## Reproduction result
命令：`cd .specular-output/repro && timeout 10m ./test_bugMC-10_negative_sleep_iae.sh 2>&1 | tee MC-10.r1.log`，结果 `SCRIPT EXIT=0`。下面是原样节选：

```
== source: /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/../confirmation/MC-10/worktree (177b6c9b9f3e7957f404f0bdb8e23374cb1de43f; 0 local modifications)
== compiling unmodified library sources with javac 21.0.13.1 --release 8
================================================================ run on /usr/lib/jvm/java-21-openjdk-amd64
[S1a] bfs1 / DocumentedOutcomesOnly: attempt 1 throws IOException, retryable, stopAfterAttempt(3),
      wait = join(fixedWait(Long.MAX_VALUE ms), fixedWait(1 ms)), default ThreadSleepStrategy, 1 listener
      wait strategy value for the failed attempt: computeSleepTime = -9223372036854775808
      still blocked in the wait after 3 s (documented behaviour): false
      call() ended with      : UNDOCUMENTED IllegalArgumentException  [java.lang.IllegalArgumentException: timeout value is negative]
      documented outcome?   : false
      interrupt status @exit: false
      callable invocations  : 1; listener saw attempts [1]; elapsed 0 ms
      thrown.getCause()     : null  (attempt count / last failure reachable from the thrown exception: false)
      origin of the escaping exception (top frames):
        at java.base/java.lang.Thread.sleep(Thread.java:500)
        at com.github.rholder.retry.BlockStrategies$ThreadSleepStrategy.block(BlockStrategies.java:46)
        at com.github.rholder.retry.Retryer.call(Retryer.java:178)
  => S1a: BUG TRIGGERED - IllegalArgumentException escaped Retryer.call() after attempt 1 (not result/ExecutionException/RetryException)
  => S1b: BUG TRIGGERED - retrying aborted with IllegalArgumentException; attempt 2 (which would return "ok") never ran
  => S1b-ctl: control OK - call() retried and returned "ok" from attempt 2

[S2] bfs3 / InterruptedCallThrowsRetryException: attempt 1 throws IOException; another thread interrupts
     the caller while the RetryListener loop runs (CE step 7); wait = overflowing join (CE step 9: Negative)
     interrupt observed inside the listener loop: true
     call() ended with      : UNDOCUMENTED IllegalArgumentException  [java.lang.IllegalArgumentException: timeout value is negative]
     documented outcome?   : false
     interrupt status @exit: true
     callable invocations  : 1; listener saw attempts [1]; elapsed 0 ms
     thrown.getCause()     : null  (attempt count / last failure reachable from the thrown exception: false)
     documented (Retryer.call Javadoc): RetryException(numberOfFailedAttempts=1, cause=IOException), interrupt status set
  => S2: BUG TRIGGERED - interrupted call ended with IllegalArgumentException instead of RetryException; attempt count and last failure lost

[S2-ctl] identical, but a non-negative wait (join(fixedWait(10 ms), fixedWait(1 ms)))
     call() ended with      : RetryException  [com.github.rholder.retry.RetryException: Retrying failed to complete successfully after 1 attempts.]
     interrupt status @exit: true
     RetryException        : numberOfFailedAttempts=1, cause=java.io.IOException: transient failure on attempt 1
  => S2-ctl: control OK - RetryException(1 attempt, cause IOException) with interrupt status set - the documented outcome
  => S3: BUG TRIGGERED - interrupted call ended with IllegalArgumentException instead of RetryException
  => S3-ctl: control OK - RetryException(1 attempt, cause IOException) with interrupt status set
     Future.get() -> ExecutionException, cause=java.lang.IllegalArgumentException: timeout value is negative; callable invocations=1
  => S4: BUG TRIGGERED - RetryerCallable.call() (Retryer.java:317-319) propagated the IAE into the Future instead of retrying
RESULT: MC-10 REPRODUCED on java 21.0.13.1 - negative computed sleep -> Thread.sleep IAE escapes Retryer.call(); on an interrupted thread it replaces the RetryException
...
        at java.base/java.lang.Thread.sleep(Native Method)
        at com.github.rholder.retry.BlockStrategies$ThreadSleepStrategy.block(BlockStrategies.java:46)
        at com.github.rholder.retry.Retryer.call(Retryer.java:178)
...
RESULT: MC-10 REPRODUCED on java 11.0.33.1 - negative computed sleep -> Thread.sleep IAE escapes Retryer.call(); on an interrupted thread it replaces the RetryException
== exit code on /usr/lib/jvm/java-11-openjdk-amd64: 0
OVERALL: MC-10 REPRODUCED on every JDK run
```

- **与反例的对应**：
  - 动作顺序相同：CallableExc → ListenerNotify → Interrupt → Negative → IAE。
  - 退出状态相同：中断位 true，attempt 计数 1，callable 调用 1 次。
  - 违反的不变式相同：`DocumentedOutcomesOnly` / `InterruptedCallThrowsRetryException`。
  - 栈帧正是 finding 指出的 `Retryer.java:178` → `BlockStrategies.java:46`。
- **对照组**：配置完全相同、只把 sleep 换成非负值时，得到的就是文档规定的 `RetryException(1, IOException)`，中断位也已设置。所以差异完全来自负 sleep。

## Recommendation
1. **在唯一的 block 入口截断**：`Retryer.call` 里改成 `long sleepTime = Math.max(0L, waitStrategy.computeSleepTime(attempt));`，做法和内置策略的截断写法一致，并在 `WaitStrategy`/`BlockStrategy` 的 Javadoc 里写明负值按 0 处理。截断后 `Thread.sleep(0)` 仍会检查中断，`RetryException` 这条路径保持不变。
   - 如果将来合并 #101 那种 "sleepTime==0 就不调用 sleep" 的改法，需要在 block 之前先显式检查一次 `Thread.interrupted()`，然后恢复中断位并抛 `RetryException`。
2. **另外修复两个负值来源**：`CompositeWaitStrategy` 改用饱和加法（CR-D-16）；`exceptionWait` 截断到 0，或者抛出有文档说明的异常（CR-D-17）。
3. **加回归测试**：用 `join(fixedWait(Long.MAX_VALUE ms), fixedWait(1 ms))` 加一个已中断的线程，断言得到 `RetryException`、`getNumberOfFailedAttempts()==1`，且中断位已设置。

## 判定检查表
1. **仅靠 Level 0 或 Level 1 是否触发？是。**
   - S1a、S1b、S3、S4 是纯 Level 0：只用公共 API 和内置策略，库代码没改动。
   - S2 为了对应反例第 7 步，在测试自己的 `RetryListener` 里用 latch 安排外部线程调用 `Thread.interrupt()`。这只是用户代码里的时序控制，最多算 Level 1。
2. **是否用了 Level 2/3？没有**，所以不需要论证注入状态是否可达。
3. **哪个真实调用方看到了错误结果？**
   - 公共 `Retryer.call(Callable)`（`Retryer.java:155`）的调用方：按 README 写法 `catch (RetryException)` / `catch (ExecutionException)` 接不住这个异常（S1a/S1b/S2/S3）。
   - `Retryer.RetryerCallable.call()`（`Retryer.java:317-319`）背后的 `Future`：`Future.get()` 得到 `ExecutionException(cause=IllegalArgumentException)`，而本会成功的第 2 次 attempt 从未执行（S4）。
4. **错误状态是否永久？是，不是 MASKED。** IAE 已经终止了 `call()`，下游没有任何机制会重试、转换或重新构造 `RetryException`。IAE 没有 cause，attempt 次数和最后一次失败都取不回来，退出时中断位仍为 true。

---

## Entry 11: (Known #48) A listener added to the builder after `build()` is notified by an already-built Retryer, including by a call already in flight

- **Finding ID**: MC-11
- **Status**: REPRODUCED
- **Debate**: not run
- **Transcript**: /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-11/debate.md

running pwd; ls -la; echo ---; ls -la /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmati...
running ls -la /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation/*; echo --...
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; cat SKILL.md; echo; echo =====GUIDE=====; cat guide.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; cat phases/01-investigation.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; cat phases/02-reproduction.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; cat references/persistent-findings.md; echo; echo =====RR=====; cat references/repa...
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; ls -la $OUT; echo ---; ls -la $OUT/...
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; cat $OUT/persistent-findings-contex...
running cd /home/ubuntu/guava-retrying-20261126/Specular; head -30 specular; echo ---; OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55ma...
Persistent-findings lookup returned nothing (no prior history), so I'll proceed with a full Phase 1 investigation. Starting with the source code.
running WT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-11/worktree; cd $WT;...
running WT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-11/worktree; cat -n $...
running WT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-11/worktree; cd $WT;...
Code audit confirms the aliasing path. Now reading the cited counterexample traces.
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; wc -l $OUT/spec/output/hunt_s3_list...
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; F=$OUT/spec/output/hunt_sharing_bfs...
Both traces match the code path. Now the developer-knowledge / known-status search: checking upstream issue #48 and recent PRs.
running which gh && timeout 60 gh auth status 2>&1 | head -5; echo ---; timeout 60 gh issue view 48 -R rholder/guava-retrying --json number,title,state,createdAt,aut...
running timeout 90 gh pr list -R rholder/guava-retrying --state all --limit 200 --json number,title,state,mergedAt,closedAt,createdAt,url 2>&1 | python3 -c ' import...
running timeout 90 gh pr view 107 -R rholder/guava-retrying --json number,title,state,closedAt,mergedAt,body,files 2>&1 | python3 -c ' import json,sys d=json.load(sy...
running timeout 60 gh api repos/rholder/guava-retrying --jq '.default_branch + " pushed_at=" + .pushed_at + " archived=" + (.archived|tostring)'; timeout 60 gh api r...
running timeout 90 gh issue list -R rholder/guava-retrying --state all --limit 200 --json number,title,state,createdAt 2>&1 | python3 -c ' import json,sys d=json.loa...
running java -version 2>&1 | head -2; javac -version 2>&1; which mvn gradle 2>&1; ls /usr/lib/jvm/; echo ---; find ~/.m2/repository -path "*com/google/guava/guava/22...
running cd ~/.m2/repository; for j in com/google/guava/guava/22.0/guava-22.0.jar com/google/code/findbugs/jsr305/2.0.2/jsr305-2.0.2.jar; do printf "%s computed=%s re...
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-11/investigation.md
Phase 1 recorded in `investigation.md`. Moving to Phase 2: checking test dependencies for a fix-control run, then writing the repro.
running find ~/.m2/repository -path "*mockito*" -name "*.jar" 2>/dev/null | head; find ~/.m2/repository -path "*objenesis*" -name "*.jar" 2>/dev/null | head -3; WT=/...
`mockito-all-1.9.5` is cached, so the script can also run the 36 upstream tests against the original code and against a one-line fix. Writing the reproduction script now.
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/test_bugMC-11_listener_added_after_build.sh
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro && chmod +x test_bugMC-11_liste...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro && for i in 1 2 3 4 5 6 7 8 9 1...
running S=/home/ubuntu/guava-retrying-20261126/jpf-smoke; ls -la $S; echo ---; cat $S/run.sh; echo ---; ls $S/* | head -30; cat ~/.jpf/site.properties
running S=/home/ubuntu/guava-retrying-20261126/jpf-smoke; cat $S/src/RetryCallListener.java; echo ---; cat $S/src/SmokeSingle.java; echo ---; tail -30 $S/build/timel...
running J=/home/ubuntu/tools/jpf-core-mku-spurious; ls $J; ls $J/build | head; grep -n -E "^vm\.(por|shared)|never_break|exclude|include" $J/src/main/gov/nasa/jpf/*....
running J=/home/ubuntu/tools/jpf-core-mku-spurious; F=$(grep -l "vm.shared.never_break_methods" -r $J/src/main 2>/dev/null | head -1); echo "$F"; sed -n 160,240p "$F"
running J=/home/ubuntu/tools/jpf-core-mku-spurious; sed -n 170,240p $J/jpf.properties
JPF's `PathSharednessPolicy` doesn't exclude `java.util.ArrayList` fields, so it can interleave inside `ArrayList.add`. Checking a few JPF API signatures before writing the tracing listener.
running J=/home/ubuntu/tools/jpf-core-mku-spurious/src/main/gov/nasa/jpf; grep -n -E "public (int|ElementInfo) (getLastThis|getLastElementInfo)\(" $J/jvm/bytecode/*....
running J=/home/ubuntu/tools/jpf-core-mku-spurious/src/main/gov/nasa/jpf; grep -n -E "getLastThis|getLastElementInfo|getFieldInfo\(\)" $J/vm/bytecode/*.java $J/jvm/b...
running J=/home/ubuntu/tools/jpf-core-mku-spurious/src/main/gov/nasa/jpf; sed -n 70,100p $J/vm/bytecode/InstanceFieldInstruction.java; grep -n "class PUTFIELD\|class...
API confirmed. Writing the JPF workload (public API only), a path-local tracing listener, and a runner in the finding work dir.
running mkdir -p /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-11/jpf/src && e...
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-11/jpf/src/MC11Straddle.java
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-11/jpf/src/MC11StraddleListener.java
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-11/jpf/run_jpf_straddle.sh
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-11/jpf && chmod +x ru...
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-11/jpf/src/MC11StraddleListener.java
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-11/jpf && (timeout 15...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-11/jpf && wc -l jpf_s...
running cd /home/ubuntu/guava-retrying-20261126/Specular; timeout 60 ./specular findings --help 2>&1 | head -40; echo ---; timeout 60 ./specular findings validate --...
running cd /home/ubuntu/guava-retrying-20261126/Specular/src/specular; F=$(grep -rl "def.*validate" --include=*.py . | xargs grep -l "dependencies" | head -3); echo...
running cd /home/ubuntu/guava-retrying-20261126/Specular/src/specular; sed -n 240,278p persistent_findings.py; echo ....; sed -n 345,440p persistent_findings.py; gre...
running SRC=/home/ubuntu/scratch/guava-retrying-src/guava-retrying/src/main/java/com/github/rholder/retry; for pat in ' private List<RetryListener> listeners = new A...
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-11/issue.json
running cd /home/ubuntu/guava-retrying-20261126/Specular; OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.sp...
`issue.json` validates (`"valid": true`, title 134 chars). Pulling the exact log text to paste into the verdict.
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro; wc -l MC-11.log; sed -n '1,13p...
MC-11 已复现：结论 REPRODUCED，Novelty 为 KNOWN（上游 #48，OPEN、未修复）。只用公开 API、不改库代码就能确定性触发：单线程是 Level 0，并发是 Level 1。同一程序打上 #48 提议的一行修复后，3 个场景都不再出现异常，上游 36 个测试在修复前后都通过。

- **Source**: MC
- **Novelty**: KNOWN (cite: https://github.com/rholder/guava-retrying/issues/48; fix-status: unfixed)
- **Severity**: Medium
- **Location**: src/main/java/com/github/rholder/retry/RetryerBuilder.java:196
- **Reproduction test**: `repro/test_bugMC-11_listener_added_after_build.sh`（Scenario 1 为 Level 0，Scenario 2/3 为 Level 1）

## Description
每个 `RetryerBuilder` 只有一个可变的 `ArrayList`（`RetryerBuilder.java:40`）。`build()` 把这个对象本身交给 `Retryer`，没有拷贝（`RetryerBuilder.java:196` → `Retryer.java:137`）。`withRetryListener` 一直往同一个 list 里 `add`（`RetryerBuilder.java:63`），`Retryer.call` 则在每个 attempt 之后遍历这个仍在变化的 list（`Retryer.java:166-168`）。

所以 `build()` 之后再调用 `withRetryListener`，会改变所有已构建 `Retryer` 的 listener 集合，正在执行的 `call()` 也会受影响：同一次 `call()` 的不同 attempt 会通知不同的 listener 集合。builder 的其它配置（stop/wait/block/predicate/time limiter）都在 `build()` 时按值固定，只有 listener 会泄漏到已构建的 `Retryer`。这一问题与 MC-7 同根因，MC-7 是同一 aliasing 引发 CME 的那一半。

## Trigger scenario
1. **单线程（#48 的序列）**：先 `retryerA = template.withRetryListener(metricsA).build()`，再 `retryerB = template.withRetryListener(metricsB).build()`，然后 `retryerA.call(...)`。结果 `metricsB` 收到 `retryerA` 的每个 attempt，而 `retryerB` 从未运行。
2. **MC 反例 `hunt_s3_listeners_bfs2.out`（9 个 state）**：
   - `retryer = builder.withRetryListener(L1).build()`；
   - 线程 c1 进入 `retryer.call`，attempt 1 的 callable 正在执行；
   - 另一个线程完成 `builder.withRetryListener(L2)`；
   - callable 返回后，`Retryer.java:166` 才创建 iterator，此时 `expectedModCount` 已包含这次 add，所以没有 CME；
   - 依次通知 L1、L2，`notified = <<1,2>>`，违反 `ListenersFixedAtBuild`。
3. **`hunt_sharing_bfs4.out` 的 straddle 变体**：`ArrayList.add` 先执行 `modCount++`，再写 `size`。如果 iterator 恰好在这两步之间创建，`expectedModCount` 能对上，新元素随后变得可见，于是 L2 被通知，同样没有 CME。

## Developer intent
- **#48（2015-08-24，OPEN，无任何回复）**：原文写道 "`firstRetryer.call(...);` will call both listeners since they are based on the same mutable list."，并提议的修复是 "Create an `ImmutableList` using `#copyOf`"。
- **没有修复**：
  - 上游 45 个 PR（各种状态）中，没有一个会拷贝 listener 列表。
  - 最近的 #107 "Modernize" 于 2026-09-05 关闭且未合并，内容是 PHP 重写。
  - 上游 `master` HEAD 仍是 `177b6c9`（与本 worktree 相同），三处代码都没变。
- **文档与维护者表态**：
  - `Retryer.java:39-40` 写明 "A retryer is thread-safe, provided the arguments passed to its constructor are thread-safe."，但 builder 传进去的是自己那个非线程安全的 `ArrayList`。
  - #35 中维护者确认 `Retryer` 可以跨线程共享。
  - `RetryListener` 标注为 `@Beta`。
- **提交历史与测试**：
  - 这段代码来自 `1edb757e`（PR #37 "Add RetryListener implementation"）；`54a2a4d5` 只把类型改成了 `List`。
  - 没有任何提交或注释说明这是预期行为。
  - 现有测试（`RetryerBuilderTest.java:463-551`）都只在 `build()` 之前注册 listener。
- 本次复现的 control 也表明：`build()` 之后追加的 `retryIfResult` 不会影响已构建的 `Retryer`，只有 listener 会。

## Reproduction result
- **级别**：Scenario 1 为 Level 0（单线程纯公开 API）。Scenario 2/3 为 Level 1：用 `CountDownLatch` 控制先后顺序，latch 只放在用户 callable 里，库代码不改（`git HEAD 177b6c9`，src 干净）。
- **运行**：
  - 完整运行 `timeout 10m bash repro/test_bugMC-11_listener_added_after_build.sh` 得到 `EXIT=0`。
  - 另跑 10 次（`RUN_UPSTREAM_TESTS=0`），每次都是原版库 3/3 场景出现异常、fix control 0/3，每次 exit 0。
  - 结束后 worktree 仍然干净。
- **与 MC trace 的对照**：
  - Scenario 2 的 `[01]–[08]` 与 State 1–9 一一对应，`[08]` 就是 State 9。
  - 唯一没有直接打印的是 `MCListenersBegin`，即 `Retryer.java:166` 内部创建 iterator，它发生在 `[06]` 和 `[07]` 之间。
  - 违反的不变式是同一个，代码路径也是同一条。
- **证明 bug 的行**：
  - Scenario 1 的 `[04]` 和 `[06]`；
  - Scenario 2 的 `[08]`；
  - Scenario 3 的 `[06]` 和 `[08]`。

`repro/MC-11.log` 原文摘录：
```
git HEAD : 177b6c9b9f3e7957f404f0bdb8e23374cb1de43f
src dirty: <clean -- library sources unmodified>
--- Scenario 1 (Level 0, one thread): builder used as a template for two Retryers (issue #48 sequence)
    [01] main      retryerA = template.withRetryListener(metricsA).build()          -> retryerA: retry on "busy", listeners [metricsA]
    [02] main      retryerB = template.retryIfResult("slow").withRetryListener(metricsB).build()  (retryerB is never called)
    [03] main      metricsA.onRetry(attempt #1, result="busy")
    [04] main      metricsB.onRetry(attempt #1, result="busy")
    [05] main      metricsA.onRetry(attempt #2, result="slow")
    [06] main      metricsB.onRetry(attempt #2, result="slow")
    [07] main      retryerA.call(...) returned "slow" after 2 attempt(s)
    control: retryIfResult("slow") added after retryerA was built did NOT affect retryerA (it accepted "slow") -> predicates are fixed at build()
    expected (listener set fixed at build()): metricsA=[1, 2]  metricsB=[]   (retryerB never ran)
    observed                                : metricsA=[1, 2]  metricsB=[1, 2]   <-- retryerB's listener counted retryerA's attempts
--- Scenario 2 (Level 1, two threads): MC counterexample hunt_s3_listeners_bfs2.out -- add completes while attempt 1 runs
    [01] main      retryer = builder.withRetryListener(L1).build()                 [State 1: listeners at build = [L1]]
    [02] caller-c1 retryer.call(callable) entered                              [State 2: MCCallStart(c1)]
    [03] caller-c1 attempt 1: callable body running                            [State 3: MCCallerBodyStart(c1,"Ret")]
    [04] main      builder.withRetryListener(L2) begins                        [State 4: MCAddListenerBegin(2)]
    [05] main      builder.withRetryListener(L2) returned                      [State 5: MCAddListenerEnd]
    [06] caller-c1 attempt 1: callable returns "Ret"                            [State 6: MCCallerBodyReturns(c1)]
    [07] caller-c1 L1.onRetry(attempt #1, result="Ret")
    [08] caller-c1 L2.onRetry(attempt #1, result="Ret")
    [09] caller-c1 retryer.call(callable) returned "Ret"
    expected (listener set fixed at build()): in-flight call notifies [L1] only            outcome="Ret"
    observed                                : L1=[1]  L2=[1]  outcome="Ret"   <-- notified=<<1,2>> as in State 9 (no ConcurrentModificationException)
--- Scenario 3 (Level 1, two threads): listener set of one in-flight call() changes between attempts
    [05] caller-c1 L1.onRetry(attempt #2, result="retry")
    [06] caller-c1 L2.onRetry(attempt #2, result="retry")
    [07] caller-c1 L1.onRetry(attempt #3, result="ok")
    [08] caller-c1 L2.onRetry(attempt #3, result="ok")
    observed                                : L1=[1, 2, 3]  L2=[2, 3]   <-- same call() notified [L1] for attempt 1 but [L1, L2] for later attempts
================ RESULT ================
unmodified library : SUMMARY build=original anomalies=3/3
fix control        : SUMMARY build=fixed anomalies=0/3
upstream tests (unmodified library): OK (36 tests)
upstream tests (fixed copy)        : OK (36 tests)
EXIT=0
```

**Fix control**：在源码副本里把 `RetryerBuilder.java:196` 改为传 `ImmutableList.copyOf(listeners)`，再跑同一个程序，结果是 0/3。这说明根因就是这一行的 aliasing。

**JPF 补充（straddle 变体）**：
- 程序、listener 和脚本在 `confirmation/MC-11/jpf/`。程序只用公开 API；JPF listener 只观察，不改任何状态。
- JPF 穷尽搜索了全部 410 个状态，没有触发任何搜索约束。
- 它在真实 JDK `ArrayList` 字节码中找到了这条路径（`jpf_straddle.log` 原文）：
```
[MC11]   main      ArrayList.add(L2): modCount := 2   (element not yet published, size=1)
[MC11]   caller-c1 Retryer.java:166 new ArrayList$Itr: expectedModCount=2 (list.modCount=2 list.size=1) -- INSIDE the add (modCount bumped, size not yet stored)
[MC11]   main      ArrayList.add(L2): size := 2   (L2 now visible)
[MC11]   caller-c1 L1.onRetry(attempt #2)   [list.modCount=2 list.size=2]
[MC11]   caller-c1 L2.onRetry(attempt #2)   [list.modCount=2 list.size=2]
```

## Recommendation
- **最小修复**：在 `RetryerBuilder.java:196` 改为传 `ImmutableList.copyOf(listeners)`。这正是 #48 的提议，已用 fix control 验证，上游 36 个测试仍然全部通过。
- **更好的做法**：同时在公开的 `@Beta` 构造器 `Retryer.java:137` 里拷贝，即 `this.listeners = ImmutableList.copyOf(listeners);`。这样直接调用构造器的用户也会拿到固定快照，`Retryer.java:166` 的遍历也不再与外部修改竞争，MC-7 的 CME 那一半随之消除。
- **回归测试**：`build()` 之后再 `withRetryListener(L2)`，然后调用 `call()`，断言 L2 不被通知；并发版本可以照搬 Scenario 2。

## 复现前检查清单
1. **是否单靠 Level 0 或 Level 1 触发：是**。Scenario 1 为 Level 0；Scenario 2/3 为 Level 1，只用公开 API，latch 只在用户 callable 中。
2. **不适用**。没有用到 Level 2 或 Level 3：没有状态注入，也没有改源码。JPF listener 只读。
3. **哪个真实使用方看到错误结果**：是应用自己的 `RetryListener.onRetry`，由 `Retryer.java:167` 调用（循环在 `Retryer.java:166`），调用它的是一个该 listener 从未注册过的 `Retryer`。
   - 复现中，`retryerB` 的 `metricsB` 统计到了 `retryerA` 的 attempt `[1, 2]`，而 `retryerB` 从未运行。
   - 正在执行的 `retryer.call` 把 attempt #1 发给了 L2。
   - 这是实际演示出来的错误结果，不是推论。
4. **坏状态是永久的**：
   - list 在 `Retryer` 的整个生命周期内都保持共享，而且没有移除 listener 的 API。
   - 后续每个 attempt 和每次 `call()` 都会继续通知 L2（Scenario 3 的 attempt 2、3）。
   - 没有任何下游机制会修正或掩盖它，已经发出的回调也无法撤回。

产物文件：
- `confirmation/MC-11/investigation.md`（Phase 1 记录）
- `confirmation/MC-11/issue.json`（已通过 `specular findings ... validate`，结果 `"valid": true`）
- `repro/test_bugMC-11_listener_added_after_build.sh`
- `repro/MC-11.log`
- `confirmation/MC-11/jpf/`

## Repair round 1 evidence
<!-- specular-repair-token: 3eefa76b5b37ed587e41b6cbdb823026 -->
- **Current violation analysis**: KNOWN: upstream issue #48 (open). Because build() shares the builder's ArrayList with every Retryer it built (RetryerBuilder.java:40, 196; Retryer.java:137), a withRetryListener call after build() changes the listener set of existing Retryers. TLC reproduces it in flight: the builder completes an add while attempt 1's callable runs, and the running call notifies both the configured listener and the new one (hunt_s3_listeners_bfs2.out, 9 states); with two callers the add can straddle the iterator creation so no CME occurs and the new listener is still notified (hunt_sharing_bfs4.out). Same roo…
- **Counterexample**: `spec/output/hunt_s3_listeners_bfs2.out`

## Phase 4 confirmation after repair round 1

running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-11/ && ls -la && echo...
running find / -type d -name "bug-confirmation" 2>/dev/null | head -20; find /home/ubuntu -path "*skills*" -name "guide.md" 2>/dev/null | head -20
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-11/ && python3 -I -c...
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation && ls -laR && echo ===SKILL=== && cat SKILL.md && echo && echo =====GUIDE===== && ca...
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation && cat phases/01-investigation.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation && cat phases/02-reproduction.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation && cat references/persistent-findings.md && echo && echo =====RR===== && cat referen...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-11/ && cat investigat...
running WT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-11/worktree; cd $WT &...
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; ls -la --time-style=full-iso $OUT/s...
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; F=$OUT/spec/output/hunt_s3_listener...
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; for F in $OUT/spec/output/hunt_s3_l...
running cat /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/test_bugMC-11_listener_added_a...
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; cp -p $OUT/repro/MC-11.log $OUT/con...
running grep -v -E "^Note:" /tmp/mc11-round1.log
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-11/jpf && cat run_jpf...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro && for i in $(seq 1 10); do RUN...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-11/jpf && free -g | h...
running diff <(grep "^\[MC11\]" /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-...
running timeout 90 gh pr list -R rholder/guava-retrying --state all --limit 300 --json number,title,state,mergedAt,closedAt,updatedAt --jq 'sort_by(.updatedAt) | rev...
running timeout 90 gh issue list -R rholder/guava-retrying --state all --limit 300 --json number,title,state,updatedAt --jq '(length|tostring) + " issues total", (so...
running cd /home/ubuntu/guava-retrying-20261126/Specular && OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/....
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; head -5 $OUT/confirmation/MC-11/MC-...
running WT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-11/worktree; cd $WT;...
running sed -n 60,200p /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-11/jpf/sr...
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; cp /tmp/mc11-round1.log $OUT/repro/...
running cat >> /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-11/investigation....
`investigation.md` 已更新。`issue.json` 的内容仍然准确，不需要修改。但 spec 依赖（`MC.tla`/`base.tla`）在修复轮中改过，需要重新跑一次 validate。
running cd /home/ubuntu/guava-retrying-20261126/Specular && OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/....
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; git -C $OUT/confirmation/MC-11/work...
## MC-11 结论

MC-11 在修复轮后重新确认，结论仍为 **REPRODUCED**，Novelty 为 KNOWN（上游 #48，仍 OPEN、未修复）。本轮在重建的 worktree 上重跑了复现：一次完整运行加 10 次重复，每次都是原版库 3/3 场景出现异常、fix control 0/3。JPF 重跑的结果与上一轮完全一致。当前源码和反例中没有任何内容推翻上一轮的结论，只需更正 finding 摘要里的一处措辞（见 Trigger scenario 第 3 条）。

- **Source**: MC
- **Novelty**: KNOWN (cite: https://github.com/rholder/guava-retrying/issues/48; fix-status: unfixed)
- **Severity**: Medium
- **Location**: src/main/java/com/github/rholder/retry/RetryerBuilder.java:196
- **Reproduction test**: `repro/test_bugMC-11_listener_added_after_build.sh`（Scenario 1 为 Level 0，Scenario 2/3 为 Level 1）

## Description
- 每个 `RetryerBuilder` 只有一个可变的 `ArrayList`（`RetryerBuilder.java:40`）。
- `build()` 把这个对象本身交给 `Retryer`，没有拷贝（`RetryerBuilder.java:196` → `Retryer.java:137`）。
- `withRetryListener` 之后继续往同一个 list 里 `add`（`RetryerBuilder.java:63`）。
- `Retryer.call` 在每个 attempt 之后都遍历这个仍在变化的 list（`Retryer.java:166-168`）。

所以在 `build()` 之后调用 `withRetryListener`，会改变所有已构建 `Retryer` 的 listener 集合，正在执行的 `call()` 也会受影响。builder 的其它配置不会这样泄漏：后续修改只替换 builder 自己的字段，或被 `checkState` 拒绝。Scenario 1 的 control 证实了这一点。这个问题与 MC-7 同根因（MC-7 是 CME 那一半），列出它是为了标记已知问题 #48 已复现，不是新缺陷。

## Trigger scenario
1. **单线程（#48 的序列）**：
   - `retryerA = template.withRetryListener(metricsA).build()`
   - `retryerB = template.withRetryListener(metricsB).build()`
   - 调用 `retryerA.call(...)`，`metricsB` 收到了 `retryerA` 的每个 attempt。
2. **MC 反例 `hunt_s3_listeners_bfs2.out`（9 个 state）**：
   - attempt 1 的 callable 正在运行时，builder 线程完成 add（S4–S5，`blist=<<1,2>>`）。
   - iterator 在 add 之后才于 `Retryer.java:166` 创建（S7，`itExpMod=2`），所以没有 CME。
   - 随后依次通知 L1、L2（S9，`notified=<<1,2>>`），违反 `ListenersFixedAtBuild`。
   - 该文件 mtime 为 08:11，早于上一轮确认和修复轮，修复轮没有重新生成它。本轮重读的状态序列与上一轮一致。
3. **straddle 变体 `hunt_sharing_bfs4.out`（对 finding 摘要的更正）**：
   - 摘要写的是 "with two callers"。实际上 cfg 确实有两个 caller 槽位，但 trace 中 `c2` 始终是 `Idle`，交错只发生在 `c1` 与 builder 线程之间。
   - 此外，`c1` 的 attempt 1 走的是 `fixedTimeLimit` 超时取消路径（S3–S7）。
   - 之后 iterator 在 `bmod=2`、`blist=<<1>>` 时创建，即落在 `ArrayList.add` 的 `modCount++` 与写 `size` 之间（S8–S12）。
   - 这个变体不依赖 time limiter：JPF 在默认的 `noTimeLimit` 配置下就能走到它。

## Developer intent
- **#48（2015-08-24 提交，OPEN，0 条评论）**：原文写道 "`firstRetryer.call(...);` will call both listeners since they are based on the same mutable list"，并提议的修复是 "Create an `ImmutableList` using `#copyOf`"。
- **本轮复查（2026-11-26）**：
  - 上游 `master` 仍是 `177b6c9`，从未合并过相关 PR。
  - 最近更新的两个 PR 都已关闭且未合并：#84（README）和 #107（"Modernize"）。
  - 在仓库内搜索 `listeners`，只命中 #48。
- **文档**：`Retryer.java:39-40` 写明 "A retryer is thread-safe, provided the arguments passed to its constructor are thread-safe"，但 builder 传入的是它自己那个非线程安全的 `ArrayList`。
- **维护者表态**：#35 中维护者确认 `Retryer` 可以跨线程共享。`RetryListener` 标注为 `@Beta`。
- **提交历史**：这段代码来自 `1edb757e`（PR #37），`54a2a4d5` 只改了类型，`e90fe648` 只改了 `onRetry` 的签名。没有任何提交或注释说明这是预期行为。
- **测试**：现有测试（`RetryerBuilderTest.java:463-551`）都只在 `build()` 之前注册 listener。

## Reproduction result
- **级别**：Scenario 1 为 Level 0（单线程，纯公开 API）。Scenario 2/3 为 Level 1：latch 只放在用户 callable 里，库代码未修改（`177b6c9`，src 干净）。
- **命令**：`timeout 10m bash repro/test_bugMC-11_listener_added_after_build.sh`，结果 `EXIT=0`。
- **重复运行**：另跑 10 次（`RUN_UPSTREAM_TESTS=0`），每次都是 `anomalies=3/3` 对 `0/3`，exit 0。

`repro/MC-11.log` 已刷新为本轮的运行结果，以下是原文摘录，`[...]` 表示省略：
```
git HEAD : 177b6c9b9f3e7957f404f0bdb8e23374cb1de43f
src dirty: <clean -- library sources unmodified>
--- Scenario 1 (Level 0, one thread): builder used as a template for two Retryers (issue #48 sequence)
    [01] main      retryerA = template.withRetryListener(metricsA).build()          -> retryerA: retry on "busy", listeners [metricsA]
    [02] main      retryerB = template.retryIfResult("slow").withRetryListener(metricsB).build()  (retryerB is never called)
    [03] main      metricsA.onRetry(attempt #1, result="busy")
    [04] main      metricsB.onRetry(attempt #1, result="busy")
    [05] main      metricsA.onRetry(attempt #2, result="slow")
    [06] main      metricsB.onRetry(attempt #2, result="slow")
    [07] main      retryerA.call(...) returned "slow" after 2 attempt(s)
    control: retryIfResult("slow") added after retryerA was built did NOT affect retryerA (it accepted "slow") -> predicates are fixed at build()
    expected (listener set fixed at build()): metricsA=[1, 2]  metricsB=[]   (retryerB never ran)
    observed                                : metricsA=[1, 2]  metricsB=[1, 2]   <-- retryerB's listener counted retryerA's attempts
--- Scenario 2 (Level 1, two threads): MC counterexample hunt_s3_listeners_bfs2.out -- add completes while attempt 1 runs
    [01] main      retryer = builder.withRetryListener(L1).build()                 [State 1: listeners at build = [L1]]
    [02] caller-c1 retryer.call(callable) entered                              [State 2: MCCallStart(c1)]
    [03] caller-c1 attempt 1: callable body running                            [State 3: MCCallerBodyStart(c1,"Ret")]
    [04] main      builder.withRetryListener(L2) begins                        [State 4: MCAddListenerBegin(2)]
    [05] main      builder.withRetryListener(L2) returned                      [State 5: MCAddListenerEnd]
    [06] caller-c1 attempt 1: callable returns "Ret"                            [State 6: MCCallerBodyReturns(c1)]
    [07] caller-c1 L1.onRetry(attempt #1, result="Ret")
    [08] caller-c1 L2.onRetry(attempt #1, result="Ret")
    [09] caller-c1 retryer.call(callable) returned "Ret"
    expected (listener set fixed at build()): in-flight call notifies [L1] only            outcome="Ret"
    observed                                : L1=[1]  L2=[1]  outcome="Ret"   <-- notified=<<1,2>> as in State 9 (no ConcurrentModificationException)
--- Scenario 3 (Level 1, two threads): listener set of one in-flight call() changes between attempts
[...]
    [05] caller-c1 L1.onRetry(attempt #2, result="retry")
    [06] caller-c1 L2.onRetry(attempt #2, result="retry")
    [07] caller-c1 L1.onRetry(attempt #3, result="ok")
    [08] caller-c1 L2.onRetry(attempt #3, result="ok")
    observed                                : L1=[1, 2, 3]  L2=[2, 3]   <-- same call() notified [L1] for attempt 1 but [L1, L2] for later attempts
[...]
================ RESULT ================
unmodified library : SUMMARY build=original anomalies=3/3
fix control        : SUMMARY build=fixed anomalies=0/3
upstream tests (unmodified library): OK (36 tests)
upstream tests (fixed copy)        : OK (36 tests)
EXIT=0
```

- **证明 bug 的行**：Scenario 1 的 `[04]` 和 `[06]`，Scenario 2 的 `[08]`，Scenario 3 的 `[06]` 和 `[08]`。
- **与 MC trace 的对照**：
  - Scenario 2 的 `[01]–[06]` 对应 State 1–6，`[07]`/`[08]` 对应 State 8/9。
  - State 7（在 `Retryer.java:166` 创建 iterator）发生在 `[06]` 与 `[07]` 之间，没有单独打印。
  - 违反的不变式和代码路径都与反例相同。
- **fix control**：在源码副本中把 `RetryerBuilder.java:196` 改为 `ImmutableList.copyOf(listeners)` 后，结果为 0/3。这说明根因就是这一行的 aliasing。

**JPF 重跑（straddle 变体）**：`jpf/run_jpf_straddle.sh` 的输出与上一轮 `jpf_straddle.log` 中的 `[MC11]` 行完全一致：410 个新状态，`constraints=0`，"no errors detected"。关键路径如下：
```
[MC11]   main      ArrayList.add(L2): modCount := 2   (element not yet published, size=1)
[MC11]   caller-c1 Retryer.java:166 new ArrayList$Itr: expectedModCount=2 (list.modCount=2 list.size=1) -- INSIDE the add (modCount bumped, size not yet stored)
[MC11]   main      ArrayList.add(L2): size := 2   (L2 now visible)
[MC11]   caller-c1 L2.onRetry(attempt #2)   [list.modCount=2 list.size=2]
```

## Recommendation
- **最小修复**：在 `RetryerBuilder.java:196` 改为传 `ImmutableList.copyOf(listeners)`，即 #48 提议的修复。fix control 已验证有效，上游 36 个测试仍然全部通过。
- **更稳妥的做法**：同时在 `@Beta` 构造器里拷贝（`Retryer.java:137`：`this.listeners = ImmutableList.copyOf(listeners);`）。这样直接调用构造器的用户也会拿到固定快照，MC-7 的 CME 也随之消除。
- **回归测试**：在 `build()` 之后调用 `withRetryListener(L2)`，再调用 `call()`，断言 L2 不被通知。并发版本可以照搬 Scenario 2。

## 复现前检查清单
1. **是否单靠 Level 0 或 Level 1 触发：是。** Scenario 1 为 Level 0；Scenario 2/3 为 Level 1，只用公开 API，latch 只在用户 callable 中。
2. **不适用。** 没有用到 Level 2 或 Level 3：没有状态注入，也没有改库源码。fix control 只是对照组，JPF listener 只读。
3. **哪个真实使用方看到错误结果**：是应用自己的 `RetryListener.onRetry`，在 `Retryer.java:167` 被调用（循环位于 `Retryer.java:166`），调用它的是一个该 listener 从未注册过的 `Retryer`。
   - `metricsB` 统计到了 `retryerA` 的 attempt `[1, 2]`，而 `retryerB` 从未运行。
   - 正在执行的 `call()` 把 attempt #1 发给了 L2。
   - 这是实际演示出来的结果，不是推论。
4. **坏状态是永久的。** 在 `Retryer` 的整个生命周期内，list 一直是共享的，而且没有移除 listener 的 API；之后的每个 attempt 和每次 `call()` 都会继续通知 L2（Scenario 3 的 attempt 2、3）。没有任何下游机制会修正或掩盖它，已经发出的回调也无法撤回。

本轮产物：
- `confirmation/MC-11/investigation.md`：追加了 "Repair round 1 continuation" 一节，记录本轮复查内容和对 "two callers" 措辞的更正。
- `repro/MC-11.log`：已刷新为本轮的运行输出。
- `confirmation/MC-11/issue.json`：内容未改，重新运行 `specular findings ... validate` 后结果为 `valid: True`（title 134 字符）。
- 复现脚本的 sha256 未变（`cc5ec745…`），worktree 仍然干净。

---

## Entry 12: (Known #29) The first attempt timeout ends retrying with `ExecutionException(UncheckedTimeoutException)` unless the predicate matches Guava's exception

- **Finding ID**: MC-12
- **Status**: REPRODUCED
- **Debate**: not run
- **Transcript**: /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-12/debate.md

running pwd; ls -la; ls -la /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-12/...
running find / -type d -name "bug-confirmation" 2>/dev/null | head -20
running ls -la ~/.claude/skills 2>&1 | head; ls -la /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; find /home/ubuntu/guava-retrying-20261126/...
running git status 2>&1 | head; git log --oneline 2>&1 | head; ls -la .claude 2>/dev/null; find . -maxdepth 3 -path ./.git -prune -o -type f -print | head
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; cat SKILL.md; echo ======; cat guide.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; cat phases/01-investigation.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; cat phases/02-reproduction.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; cat references/repair-request-format.md; echo =====; cat references/persistent-find...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-12/; cat .resume-leas...
running ls -la /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/; ls -la /home/ubuntu/guava-retry...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/; cat persistent-findings-context.jso...
running ls /home/ubuntu/guava-retrying-20261126/Specular/; ls /home/ubuntu/guava-retrying-20261126/Specular/bin 2>/dev/null; find /home/ubuntu/guava-retrying-2026112...
running cd /home/ubuntu/guava-retrying-20261126/Specular; head -30 specular; ls -la .venv 2>/dev/null | head -3;
running SP=/home/ubuntu/guava-retrying-20261126/Specular/specular; OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-ret...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-12/worktree; find src...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-12/worktree; cat -n s...
running find / -path /proc -prune -o \( -name "guava-22.0*.jar" -o -type d -name "guava-22.0" \) -print 2>/dev/null | head -20
running mkdir -p /tmp/mc12-guava-src && cd /tmp/mc12-guava-src && unzip -o -q /home/ubuntu/scratch/guava22-sources-dl/guava-22.0-sources.jar 'com/google/common/util/...
running which gh && gh --version | head -1; timeout 60 gh api repos/rholder/guava-retrying/issues/29 2>&1 | python3 -c 'import sys,json; d=json.load(sys.stdin); prin...
running timeout 60 gh api repos/rholder/guava-retrying/issues/29/comments 2>&1 | python3 -c 'import sys,json; d=json.load(sys.stdin); [print("=== ", c["user"]["login...
running timeout 90 gh search issues --repo rholder/guava-retrying --include-prs "timeout" --limit 40 --json number,title,state,isPullRequest,url,closedAt,createdAt 2...
running timeout 90 gh pr list --repo rholder/guava-retrying --state all --limit 200 --json number,title,state,createdAt,closedAt,mergedAt,url 2>&1 | python3 -c 'impo...
running for q in "UncheckedTimeoutException" "AttemptTimeLimiter" "time limit" "timed out" "TimeLimiter"; do echo "### $q"; timeout 60 gh search issues --repo rholde...
running timeout 60 gh api "repos/rholder/guava-retrying/commits?per_page=10" 2>&1 | python3 -c 'import sys,json; d=json.load(sys.stdin); [print(c["sha"][:7], c["comm...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-12/worktree; git tag...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-12/worktree; git show...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-12/worktree; grep -n...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-12/worktree; sed -n '...
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; ls -la $OUT/spec/output/hunt_s4_shu...
running ls /home/ubuntu/scratch/guava-jars/ 2>&1 | head; find /home/ubuntu/.m2/repository -name "jsr305*.jar" 2>/dev/null; find /home/ubuntu/.m2/repository -path "*j...
running cd /home/ubuntu/scratch/guava-retrying-src/guava-retrying 2>&1 && git log --oneline -1 && git status --short | head -10; cd /home/ubuntu/guava-retrying-20261...
running ls /home/ubuntu/.m2/repository/com/google/guava/guava/22.0/; cat /home/ubuntu/.m2/repository/com/google/guava/guava/22.0/guava-22.0.jar.sha1 2>/dev/null; ech...
running cd /tmp/mc12-guava-src && sed -n '17,60p' com/google/common/util/concurrent/UncheckedTimeoutException.java | grep -v '^ \*\|^/\*\|^$' ; grep -n 'Retryer\|ret...
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-12/investigation.md
Phase 1 记录完成。进入 Phase 2：先核对 strategy/listener 接口签名，再写复现脚本。
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-12/worktree/src/main/...
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/test_bugMC-12_timeout_ends_call_execution_exception.sh
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro && chmod +x test_bugMC-12_timeo...
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; ls -la $OUT/spec/MC_hunt_s4_shutdow...
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-12/worktree/src/main/j...
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-12/issue.json
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; python3 -c "import json,sys; d=json...
`issue.json` 校验通过（`valid: true`，title 153 字符）。清理临时解压目录，并取出复现脚本中调用方所在的行号，供清单引用。
running rm -rf /tmp/mc12-guava-src; ls /tmp | grep -c mc12 ; grep -n -F 'o.value = retryer.call(callable);' /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-...
## MC-12 确认结论：已复现（Level 0/1），属于上游已知且未修复的问题 #29

- **Source**: MC
- **Novelty**: KNOWN (cite: https://github.com/rholder/guava-retrying/issues/29; fix-status: unfixed)
- **Severity**: Medium
- **Location**: src/main/java/com/github/rholder/retry/Retryer.java:162
- **Reproduction test**: `repro/test_bugMC-12_timeout_ends_call_execution_exception.sh`。S2/S3 为 Level 0，S1 为 Level 1；日志在 `repro/MC-12.log`
- **Persistent record**: `confirmation/MC-12/issue.json`，已通过 `specular findings … validate`（`"valid": true`）。Phase 1 证据记录在 `confirmation/MC-12/investigation.md`

## Description
`Retryer.call` 把 `attemptTimeLimiter.call(callable)` 抛出的任何 `Throwable` 都当作普通的 `ExceptionAttempt` 处理（`Retryer.java:162-163`）。这包括 Guava 22.0 `SimpleTimeLimiter` 超时后先执行 `future.cancel(true)`、再抛出的 `UncheckedTimeoutException`（`SimpleTimeLimiter.java:164-166`）。这个 attempt 随后交给用户的 rejection predicate 判断。

只要谓词不匹配 Guava 的这个实现类，`Retryer.java:170-171` 就会直接 `return attempt.get()`，抛出 `ExecutionException(UncheckedTimeoutException)`。谓词不匹配的例子有 `retryIfExceptionOfType(IOException.class)`，或者根本没配 `retryIf`。

结果是第一次超时就结束了整个 `call()`，`stopStrategy` 和 `waitStrategy` 一次都没被调用。这与两处文档冲突：
- 时限按单次 attempt 生效（`RetryerBuilder.java:113`）。
- `@throws ExecutionException` 的约定是"callable 抛出异常时包装其原始异常"（`Retryer.java:148-150`）。在 CE 的交错里，callable 根本没有运行过。

该行为在 2.0.0 和 upstream master `177b6c9` 上依然存在。v1.0.6 与 v2.0.0 的 `call()` 中 try/catch 加谓词判断的结构完全相同，所以和 #29 报告的是同一机制、同一位置。

## Trigger scenario
CE `spec/output/hunt_s4_shutdown_k29.out` 共 11 个状态，与真实 API 的对应关系如下：

| CE 步骤 | 真实 API 中发生的事 |
|---|---|
| `MCCallStart` | 用户调用 `call()`，开始 attempt 1 |
| `MCSubmitNewWorker` | 新 worker 已拿到任务，但还没开始执行 |
| `MCGetTimeout` | `future.get` 超时 |
| `MCCancelCASWon` / `MCCancelReadRunner` / `MCCancelFinish` | `cancel(true)`；因为任务未启动，找不到 runner |
| `MCListenersBegin` / `MCListenerNotify` / `MCListenersEnd` | 监听器收到 #1 attempt，异常为 `UncheckedTimeoutException` |
| `MCPredicateAccepts` | 谓词不匹配，`outcome = ExecExc` |

复现覆盖三种配置：
- **S1**：精确复刻上述 CE。限时 300 ms，用户自定义的 `ThreadFactory` 把 worker 启动推迟 1500 ms。
- **S2**：典型场景。`fixedTimeLimit(500 ms)` + `retryIfExceptionOfType(IOException)` + `stopAfterAttempt(5)` + `fixedWait(50 ms)`。第 1 次 attempt 卡住超过时限，第 2 次本应成功。
- **S3**：#29 报告者的原始配置（缩小了时长）。不配 `retryIf`，只配 `fixedWait` + `stopAfterDelay`。

## Developer intent
**支持"这是 bug"的证据：**
- 上游 #29 处于 open 状态，label 为 `bug`。维护者 rholder 在 2015-05-02 的回复（https://github.com/rholder/guava-retrying/issues/29#issuecomment-98264665）原文：
  > "I agree with your assessment and would also consider it a bug, too … the `Retryer` effectively stops retrying instead of giving up on the attempt and trying again. Catchall `retryIfException()` or `retryIfRuntimeException()` retrying appears to mask this behavior as well."
- Javadoc 的表述都是"按单次 attempt"：
  - `RetryerBuilder.java:113`："limit the duration of any particular attempt"
  - `AttemptTimeLimiter.java:22`："wrap any single attempt"

**反向证据：**
- `AttemptTimeLimiter` 的作者 dirkraft 在 #29 中说，超时"at a minimum"应当像其他异常一样，受谓词配置约束。
- 现有测试 `AttemptTimeLimiterTest.java:44-50`（2013 年）在**不配任何 `retryIf`** 时断言的结果就是 `ExecutionException(UncheckedTimeoutException)`。

**如何权衡：** 判定主要依据 S1/S2。这两个场景中用户明确配置了重试谓词和 stop 策略。S1 里 callable 从未运行，抛出的 `ExecutionException` 却不对应 Javadoc 里任何一种文档化的结果。

**查重：** 搜索了 issue 和 PR（`--state all`，共 45 个 PR，最新的 #107 于 2026-09-05 关闭且未合并，内容无关），没有找到修复。

## Reproduction result
运行命令：`timeout 10m ./test_bugMC-12_timeout_ends_call_execution_exception.sh 2>&1 | tee MC-12.log`

库源码未做任何修改，从源码编译。以下是第 1 次运行的原始输出：
```
source HEAD: 177b6c9b9f3e7957f404f0bdb8e23374cb1de43f  dirty-files: 0
guava jar  : /home/ubuntu/.m2/repository/com/google/guava/guava/22.0/guava-22.0.jar sha1=3564ef3803de51fb0530a8377ec6100b33b0d073
[    35 ms]     worker mc12-w1 created with the attempt task assigned; its start is delayed 1500 ms
[   336 ms]     listener.onRetry: attempt #1 exception UncheckedTimeoutException (delaySinceFirstAttempt=302 ms)
[   336 ms]     call() THREW ExecutionException with cause com.google.common.util.concurrent.UncheckedTimeoutException after 302 ms
[  1535 ms]     worker mc12-w1 now runs the attempt's FutureTask: isCancelled()=true
S1 OBSERVED: ExecutionException(UncheckedTimeoutException) after 302 ms | attempts seen by listener=[#1 exception UncheckedTimeoutException] | stop.shouldStop calls=0 | wait.computeSleepTime calls=0 | callable invocations=0 => BUG
[  1538 ms]     callable invocation #1 on pool-1-thread-1: stalls 10000 ms (transient stall)
[  2037 ms]     callable invocation #1 interrupted by the limiter's future.cancel(true)
[  2038 ms]     call() THREW ExecutionException with cause com.google.common.util.concurrent.UncheckedTimeoutException after 500 ms
S2 OBSERVED: ExecutionException(UncheckedTimeoutException) after 500 ms | attempts seen by listener=[#1 exception UncheckedTimeoutException] | stop.shouldStop calls=0 | wait.computeSleepTime calls=0 | callable invocations=1 => BUG
S3 OBSERVED: ExecutionException(UncheckedTimeoutException) after 500 ms | attempts seen by listener=[#1 exception UncheckedTimeoutException] | stop.shouldStop calls=0 | wait.computeSleepTime calls=0 | callable invocations=1 => BUG
[  2542 ms]     stopAfterAttempt(5).shouldStop(attempt #1) -> false
[  2542 ms]     fixedWait(50 ms).computeSleepTime(attempt #1) -> 50 ms
C1 OBSERVED: returned "ok" after 53 ms | attempts seen by listener=[#1 exception IOException, #2 result ok] | stop.shouldStop calls=1 | wait.computeSleepTime calls=1 | callable invocations=2 => control OK
[  3094 ms]     stopAfterAttempt(5).shouldStop(attempt #1) -> false
[  3145 ms]     callable invocation #2 returns "ok"
C2 OBSERVED: returned "ok" after 551 ms | attempts seen by listener=[#1 exception UncheckedTimeoutException, #2 result ok] | stop.shouldStop calls=1 | wait.computeSleepTime calls=1 | callable invocations=2 => control OK
RESULT: PASS (bug triggered: the first attempt timeout ended call() with ExecutionException(UncheckedTimeoutException); stop/wait strategies never consulted)
OVERALL: PASS (bug triggered in 5/5 runs)
script exit status: 0
```

**证明 bug 的输出行：** `S1/S2/S3 OBSERVED` 三行。三个场景都在一次 attempt 之后抛出 `ExecutionException(UncheckedTimeoutException)`，且 `stop.shouldStop calls=0`、`wait.computeSleepTime calls=0`。

**正确行为应该是什么：** C2 加上了 #29 的 workaround 谓词，展示的正是正确行为：`stopAfterAttempt(5)` 对 #1 返回 `false`，等待 50 ms 后第 2 次 attempt 返回 `"ok"`。

**另一个对照：** C1 说明，同一套策略下普通的 `IOException` 失败会被正常重试。

**与 CE 一致：** 操作顺序、违反的不变式 `TimeoutDoesNotEndCallWithExecutionException`、根因代码路径（`:162-163` 到 `:170-171`）都与 CE 相同。

## Recommendation
- **修复方向：**
  1. 在 `AttemptTimeLimiter` 的契约中区分"超时"和"callable 抛出的异常"。例如 `FixedAttemptTimeLimit.call` 把 `UncheckedTimeoutException` 转换成库自己的超时异常类型。
  2. `Retryer.call` 把超时的 attempt 视为被拒绝的 attempt，一律交给 `stopStrategy`/`waitStrategy` 处理；stop 策略最终停止时抛出 `RetryException`，其中 last failed attempt 携带超时信息。
  3. 同时更新 `withAttemptTimeLimiter` 和 `call()` 的 Javadoc。
- **修复时注意：** `cancel(true)` 只是发出中断。如果 callable 忽略中断，超时后再次重试可能与仍在运行的旧 attempt 并行，需要在设计时考虑。
- **用户侧临时规避：** 加上 `.retryIfExceptionOfType(UncheckedTimeoutException.class)`，或 `retryIfRuntimeException()`（见 C2）。

## Pre-REPRODUCED checklist
1. **仅凭 Level 0 或 Level 1 是否就能触发：是。** S2/S3 只用公共 API，执行器是库的默认执行器（Level 0）。S1 只借助用户提供的 `ThreadFactory` 推迟线程启动来控制时序（Level 1），库和 Guava 都未修改。
2. 不适用，没有用到 Level 2 或 Level 3。
3. **观察到错误结果的真实调用方：** 调用 `Retryer.call` 的应用代码。异常在 `src/main/java/com/github/rholder/retry/Retryer.java:171` 离开库；如果走 `wrap()`，则经 `Retryer.java:318` 传出。在复现中，对应的调用方是 `repro/test_bugMC-12_timeout_ends_call_execution_exception.sh:245` 的 `o.value = retryer.call(callable);`：它收到了 `ExecutionException`，而同一策略本应重试到第 2 次并拿到 `"ok"`（C2 可证）。
4. **坏状态是永久的。** `call()` 抛出后，库内没有任何机制会再次尝试或纠正结果，stop 策略剩下的 4 次 attempt 不会被用到。唯一能避开的情况是用户谓词恰好覆盖了 `UncheckedTimeoutException`（C2），但那属于触发条件之外的配置，并不是事后掩盖问题的机制，所以不属于 MASKED。

## Repair round 1 evidence
<!-- specular-repair-token: 3eefa76b5b37ed587e41b6cbdb823026 -->
- **Current violation analysis**: KNOWN: upstream issue #29 (open, acknowledged by the maintainer, reported against 1.0.6); the guidance asks whether 2.0.0 still has it — it does. A per-attempt timeout becomes an ordinary attempt failure (Retryer.java:162-163) judged by the user's predicate, so with a predicate that does not match Guava's UncheckedTimeoutException (e.g. retryIfExceptionOfType(IOException), or no retryIf at all) the first timeout ends call() with ExecutionException(UncheckedTimeoutException) (Retryer.java:170-171) without consulting the stop or wait strategy, although the limit is documented as per attempt (Re…
- **Counterexample**: `spec/output/hunt_s4_shutdown_k29.out`

## Phase 4 confirmation after repair round 1

running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-12 && ls -la && echo...
running find / -type d -name "bug-confirmation" 2>/dev/null | head -20; find /home/ubuntu -path "*bug-confirmation*" -name "*.md" 2>/dev/null | head -40
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation && ls -R && echo ====== && cat SKILL.md && echo ====== && cat guide.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation && cat phases/01-investigation.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation && cat phases/02-reproduction.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation && cat references/repair-request-format.md; echo; echo =====; cat references/persist...
Skill 已读完。这是对 MC-12 的续作确认（既有结论 `REPRODUCED`）。接下来读已有的 investigation、issue.json 和 debate 记录，再核对当前源码和 CE 是否仍一致。
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-12 && cat investigati...
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output ls -la --time-style=full-iso $OUT/sp...
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-12/worktree cd $W && g...
源码未变（HEAD `177b6c9`，0 个 dirty 文件，`Retryer.java:155-185` 与首轮引用一致）。快速核对 CE 的动作序列和违反的不变式，然后复看复现脚本。
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output grep -n -E '^(Error|State [0-9]+|[0-...
running sed -n '1,140p' /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/test_bugMC-12_time...
running sed -n '140,420p' /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/test_bugMC-12_ti...
running sed -n '420,520p' /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/test_bugMC-12_ti...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro && date -u '+run started %Y-%m-...
running R=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro mv -f $R/MC-12.log.new $R/MC-12....
running timeout 60 gh api repos/rholder/guava-retrying/issues/29 --jq '"#\(.number) state=\(.state) labels=\([.labels[].name]|join(",")) comments=\(.comments) update...
running timeout 60 gh api repos/rholder/guava-retrying/pulls/107 --jq '"#\(.number) state=\(.state) merged=\(.merged) created=\(.created_at) closed=\(.closed_at) cha...
running J=/home/ubuntu/scratch/guava22-sources-dl/guava-22.0-sources.jar sha256sum $J | cut -c1-16 unzip -p $J com/google/common/util/concurrent/SimpleTimeLimiter.ja...
所有引用行均与源码一致。现在把本轮续作的核对结果和两处更正追加到 `investigation.md`。
running tail -5 /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-12/investigation...
running cat >> /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-12/investigation....
running F=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-12/investigation.md; w...
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output SP=$(command -v specular || echo /ho...
running L=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/MC-12.log wc -l $L; n=$(grep -n...
## MC-12 续作确认结论：仍为 REPRODUCED（上游已知问题 #29，未修复）

- **Source**: MC
- **Novelty**: KNOWN (cite: https://github.com/rholder/guava-retrying/issues/29; fix-status: unfixed)
- **Severity**: Medium
- **Location**: src/main/java/com/github/rholder/retry/Retryer.java:162
- **Reproduction test**: `repro/test_bugMC-12_timeout_ends_call_execution_exception.sh`。S2 和 S3 是 Level 0，S1 是 Level 1。日志在 `repro/MC-12.log`
- **Persistent record**: `confirmation/MC-12/issue.json`。本轮重新跑了 `specular findings … validate`，结果为 `"valid": true`，title 153 字符

## Repair round 1 续作：本轮核对了什么
- **源码没变**：worktree HEAD 仍是 `177b6c9`，没有未提交的改动。报告里引用的行逐一重读过，都没变：`Retryer.java:155-185/248-262/317-318`、`RetryerBuilder.java:39/113-122/153-157/207-213`、`AttemptTimeLimiters.java:83-109`、`AttemptTimeLimiterTest.java:32-50`，以及 Guava 22.0 的 `SimpleTimeLimiter.java:56-58/142-168`。
- **模型产物**：以下三个文件的修改时间都是 08:22，早于首轮确认（10:14），所以和首轮映射过的是同一份文件：
  - CE `spec/output/hunt_s4_shutdown_k29.out`
  - `MCHunt.tla`
  - 生成该 CE 的派生 cfg `hunt/s4_shutdown-k29.cfg`

  repair round 1 期间只有基础 cfg `MC_hunt_s4_shutdown.cfg` 在 12:28 被改过，它不是生成这个 CE 的 cfg。CE 内容仍是 11 个状态，末态为 `outcome = "ExecExc"`、`exitInfo.tag = "Timeout"`、`invoked = FALSE`、`tbody[t1] = "NotStarted"`。
- **上游状态**（约 17:00 用 `gh` 复查）：#29 仍为 `open`，label `bug`；upstream master 仍是 `177b6c9`。最新的 PR #107 已关闭且未合并，它把 Java 源码删掉换成了 PHP，与本问题无关。
- **复现脚本未改动，重新执行**（sha256 `6d7fd74e…`）：5/5 次触发，详见下文。新日志替换了 `repro/MC-12.log`；首轮日志里各场景的结果与本轮完全相同。
- `investigation.md` 末尾新增了 "Repair round 1 continuation" 一节。

**对上一轮陈述的更正：**
1. 首轮 verdict 正文把贴出的输出称为"第 1 次运行的原始输出"，实际是手工挑选的片段。它省掉了 provenance 头、各场景的标题行和 `config:` 行、S1 的 `the delayed worker has processed…` 行，以及若干 `listener.onRetry` 行。贴出的结果本身是真实的，只是标注错了。本轮在下方贴出 run 1 的完整输出，省略部分会明确标出。
2. Guava `SimpleTimeLimiter.java:56-58` 说"超时可能发生在目标方法被调用之前"，但它说的是有界线程池被占满的情况。CE 的 `MCSubmitNewWorker` 对应的是另一种情形：无界 cached pool 的新线程还没启动。真正演示出 CE 这种形态的是 S1，不是那句 Javadoc。

## Description
`Retryer.call` 把 `attemptTimeLimiter.call(callable)` 抛出的任何 `Throwable` 都当成普通的 `ExceptionAttempt`（`Retryer.java:162-163`）。这也包括 Guava 22.0 `SimpleTimeLimiter` 超时后的行为：先 `future.cancel(true)`，再抛 `UncheckedTimeoutException`（`SimpleTimeLimiter.java:164-166`）。

用户的谓词如果不匹配这个 Guava 类，`Retryer.java:170-171` 就会直接 `return attempt.get()`，抛出 `ExecutionException(UncheckedTimeoutException)`。不匹配的例子有 `retryIfExceptionOfType(IOException.class)`，或者根本没配 `retryIf`。这样第一次超时就结束了整个 `call()`，`stopStrategy` 和 `waitStrategy` 一次都没被调用。

这和文档有两处冲突：
- `RetryerBuilder.java:113` 说时限作用于"any particular attempt"。
- `Retryer.java:148-150` 说 `@throws ExecutionException` 表示"callable 抛出了异常"。而在 CE 的交错里，callable 根本没有运行过。

## Trigger scenario
CE `hunt_s4_shutdown_k29.out` 共 11 个状态，与实际代码的对应关系：

| CE 步骤 | 实际代码中发生的事 |
|---|---|
| `MCCallStart` | `call()` 开始第 1 次 attempt（`Retryer.java:155-160`） |
| `MCSubmitNewWorker` | 新 worker 拿到了任务，但还没开始执行（`SimpleTimeLimiter.java:149`） |
| `MCGetTimeout` | `future.get` 超时（`:154`） |
| `MCCancelCASWon` / `MCCancelReadRunner` / `MCCancelFinish` | `cancel(true)` 时任务还没开始执行，没有可中断的线程（`:165`） |
| `MCListenersBegin` / `MCListenerNotify` / `MCListenersEnd` | 监听器收到第 1 次 attempt，异常为 `UncheckedTimeoutException`（`Retryer.java:166-168`） |
| `MCPredicateAccepts` | 谓词不匹配，`outcome = ExecExc`（`Retryer.java:170-171`） |

复现覆盖了三种配置：
- **S1**：精确复现上面的 CE 交错。限时 300 ms，用户自己的 `ThreadFactory` 把 worker 的启动推迟 1500 ms。
- **S2**：典型配置：`fixedTimeLimit(500 ms)` + `retryIfExceptionOfType(IOException)` + `stopAfterAttempt(5)` + `fixedWait(50 ms)`。第 1 次 attempt 卡住超时，第 2 次本应成功。
- **S3**：#29 报告者的原始配置（时长按比例缩小）：不配 `retryIf`，只配 `fixedWait` + `stopAfterDelay`。

## Developer intent
**支持"这是 bug"的证据：**
- 上游 #29 为 open，label `bug`。维护者 rholder 在 2015-05-02 回复（https://github.com/rholder/guava-retrying/issues/29#issuecomment-98264665）：
  > "I agree with your assessment and would also consider it a bug, too … the `Retryer` effectively stops retrying instead of giving up on the attempt and trying again. Catchall `retryIfException()` or `retryIfRuntimeException()` retrying appears to mask this behavior as well."
- Javadoc 都写的是"作用于单次 attempt"：`RetryerBuilder.java:113` 是 "limit the duration of any particular attempt"，`AttemptTimeLimiter.java:22` 是 "wrap any single attempt"。

**反向证据：**
- `AttemptTimeLimiter` 的作者 dirkraft 在 #29 中说，超时"at a minimum"应当和其他异常一样，按谓词配置处理。
- 现有测试 `AttemptTimeLimiterTest.java:44-50`（2013 年）在不配 `retryIf` 时，断言的就是 `ExecutionException(UncheckedTimeoutException)`。

**如何权衡：** 判定主要依据 S1 和 S2。这两个场景里用户明确配置了重试谓词和 stop 策略。S1 中 callable 从未运行，抛出的异常却不对应任何一种文档化的结果。

## Reproduction result
命令：`cd .specular-output/repro && timeout 10m ./test_bugMC-12_timeout_ends_call_execution_exception.sh 2>&1 | tee MC-12.log.new`，检查后替换为 `MC-12.log`。开始时间 2026-11-26T16:58:42Z。库和 Guava 都没有修改，直接从源码编译。

日志第 1–51 行原样贴出（provenance 头 + run 1 的完整输出）：
```
== MC-12 provenance
source dir : /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/MC-12/worktree
source HEAD: 177b6c9b9f3e7957f404f0bdb8e23374cb1de43f  dirty-files: 0
guava jar  : /home/ubuntu/.m2/repository/com/google/guava/guava/22.0/guava-22.0.jar sha1=3564ef3803de51fb0530a8377ec6100b33b0d073
jsr305 jar : /home/ubuntu/.m2/repository/com/google/code/findbugs/jsr305/2.0.2/jsr305-2.0.2.jar
java       : openjdk version "21.0.13.1" 2026-11-17
built      : 13 unmodified library sources with javac --release 8

== run 1/5 (verbose): timeout 120 java -cp <lib+test+guava-22.0+jsr305> MC12Repro
[     0 ms] S1  exact CE: the limit expires before the new worker starts the callable (Level 1: user ThreadFactory delays thread start)
[    15 ms]     config: fixedTimeLimit(300 ms, cachedPool(delayed-start 1500 ms)), retryIfExceptionOfType(IOException), stopAfterAttempt(5), fixedWait(50 ms)
[    32 ms]     worker mc12-w1 created with the attempt task assigned; its start is delayed 1500 ms
[   333 ms]     listener.onRetry: attempt #1 exception UncheckedTimeoutException (delaySinceFirstAttempt=301 ms)
[   333 ms]     call() THREW ExecutionException with cause com.google.common.util.concurrent.UncheckedTimeoutException after 302 ms
[  1532 ms]     worker mc12-w1 now runs the attempt's FutureTask: isCancelled()=true
[  1533 ms]     the delayed worker has processed the attempt's FutureTask: true (isCancelled()=true isDone()=true)
S1 OBSERVED: ExecutionException(UncheckedTimeoutException) after 302 ms | attempts seen by listener=[#1 exception UncheckedTimeoutException] | stop.shouldStop calls=0 | wait.computeSleepTime calls=0 | callable invocations=0 => BUG
[  1533 ms] S2  canonical: attempt 1 stalls past the limit, attempt 2 would succeed (Level 0: public API only)
[  1533 ms]     config: fixedTimeLimit(500 ms) [library-default executor], retryIfExceptionOfType(IOException), stopAfterAttempt(5), fixedWait(50 ms)
[  1535 ms]     callable invocation #1 on pool-1-thread-1: stalls 10000 ms (transient stall)
[  2035 ms]     listener.onRetry: attempt #1 exception UncheckedTimeoutException (delaySinceFirstAttempt=500 ms)
[  2035 ms]     callable invocation #1 interrupted by the limiter's future.cancel(true)
[  2035 ms]     call() THREW ExecutionException with cause com.google.common.util.concurrent.UncheckedTimeoutException after 500 ms
S2 OBSERVED: ExecutionException(UncheckedTimeoutException) after 500 ms | attempts seen by listener=[#1 exception UncheckedTimeoutException] | stop.shouldStop calls=0 | wait.computeSleepTime calls=0 | callable invocations=1 => BUG
[  2035 ms] S3  upstream #29 configuration: no retryIf; fixedWait + stopAfterDelay (Level 0)
[  2035 ms]     config: fixedTimeLimit(500 ms), fixedWait(100 ms), stopAfterDelay(3000 ms)
[  2036 ms]     callable invocation #1 on pool-2-thread-1: stalls 10000 ms (transient stall)
[  2536 ms]     listener.onRetry: attempt #1 exception UncheckedTimeoutException (delaySinceFirstAttempt=500 ms)
[  2536 ms]     callable invocation #1 interrupted by the limiter's future.cancel(true)
[  2536 ms]     call() THREW ExecutionException with cause com.google.common.util.concurrent.UncheckedTimeoutException after 500 ms
S3 OBSERVED: ExecutionException(UncheckedTimeoutException) after 500 ms | attempts seen by listener=[#1 exception UncheckedTimeoutException] | stop.shouldStop calls=0 | wait.computeSleepTime calls=0 | callable invocations=1 => BUG
[  2536 ms] C1  control: S2 config, attempt 1 throws IOException (an ordinary transient failure)
[  2537 ms]     callable invocation #1 throws IOException("transient")
[  2538 ms]     listener.onRetry: attempt #1 exception IOException (delaySinceFirstAttempt=1 ms)
[  2539 ms]     stopAfterAttempt(5).shouldStop(attempt #1) -> false
[  2539 ms]     fixedWait(50 ms).computeSleepTime(attempt #1) -> 50 ms
[  2589 ms]     callable invocation #2 returns "ok"
[  2590 ms]     listener.onRetry: attempt #2 result ok (delaySinceFirstAttempt=52 ms)
[  2590 ms]     call() RETURNED "ok" after 52 ms
C1 OBSERVED: returned "ok" after 52 ms | attempts seen by listener=[#1 exception IOException, #2 result ok] | stop.shouldStop calls=1 | wait.computeSleepTime calls=1 | callable invocations=2 => control OK
[  2590 ms] C2  control: S2 config + retryIfExceptionOfType(UncheckedTimeoutException) (the #29 workaround)
[  2590 ms]     callable invocation #1 on pool-4-thread-1: stalls 10000 ms (transient stall)
[  3090 ms]     listener.onRetry: attempt #1 exception UncheckedTimeoutException (delaySinceFirstAttempt=500 ms)
[  3090 ms]     callable invocation #1 interrupted by the limiter's future.cancel(true)
[  3091 ms]     stopAfterAttempt(5).shouldStop(attempt #1) -> false
[  3091 ms]     fixedWait(50 ms).computeSleepTime(attempt #1) -> 50 ms
[  3141 ms]     callable invocation #2 returns "ok"
[  3141 ms]     listener.onRetry: attempt #2 result ok (delaySinceFirstAttempt=551 ms)
[  3141 ms]     call() RETURNED "ok" after 551 ms
C2 OBSERVED: returned "ok" after 551 ms | attempts seen by listener=[#1 exception UncheckedTimeoutException, #2 result ok] | stop.shouldStop calls=1 | wait.computeSleepTime calls=1 | callable invocations=2 => control OK
RESULT: PASS (bug triggered: the first attempt timeout ended call() with ExecutionException(UncheckedTimeoutException); stop/wait strategies never consulted)
```
run 2–5 在日志第 53–83 行，此处省略。整份日志的统计：`=> BUG` 15 行（3 个场景 × 5 次），`=> control OK` 10 行，`RESULT: PASS` 5 行，`no bug`/`control FAILED`/`FAIL`/`INCONCLUSIVE` 0 行。日志结尾两行原文：
```
OVERALL: PASS (bug triggered in 5/5 runs)
script exit status: 0
```

**证明 bug 的行：** `S1/S2/S3 OBSERVED` 三行。三个场景都只经过 1 次 attempt 就抛出 `ExecutionException(UncheckedTimeoutException)`，`stop.shouldStop calls=0`、`wait.computeSleepTime calls=0`。S1 中还有 `callable invocations=0`，并且 worker 运行时看到的任务已是 `isCancelled()=true`。

**正确行为应该是什么样：** C2 在同一套策略上加了 #29 的 workaround 谓词：`stopAfterAttempt(5)` 对第 1 次 attempt 返回 `false`，等待 50 ms 后第 2 次返回 `"ok"`。C1 说明，同一套策略下普通的 `IOException` 失败会被正常重试。

**与 CE 一致：** 操作顺序、违反的不变式 `TimeoutDoesNotEndCallWithExecutionException`、根因代码路径（`:162-163` → `:170-171`）都与 CE 相同。

## Recommendation
- **修复方向：**
  1. 在 `AttemptTimeLimiter` 的契约里把"超时"和"callable 抛出的异常"分开。例如让 `FixedAttemptTimeLimit.call` 把 `UncheckedTimeoutException` 转换成库自己的超时类型。
  2. `Retryer.call` 把超时的 attempt 一律当作被拒绝的 attempt，交给 `stopStrategy`/`waitStrategy` 处理。stop 策略最终停止时抛 `RetryException`，让 last failed attempt 带上超时信息。
  3. 同步更新 `withAttemptTimeLimiter` 和 `call()` 的 Javadoc。
- **修复时注意：** `cancel(true)` 只是发出中断。如果 callable 忽略中断，超时后的重试可能和仍在运行的旧 attempt 并行。
- **用户侧临时规避：** 加 `.retryIfExceptionOfType(UncheckedTimeoutException.class)` 或 `retryIfRuntimeException()`（见 C2）。

## Pre-REPRODUCED checklist
1. **只用 Level 0 或 Level 1 就能触发吗：是。** S2 和 S3 只用公共 API 和库的默认执行器（Level 0）。S1 只借助用户提供的 `ThreadFactory` 推迟线程启动来控制时序（Level 1），库和 Guava 都未修改。
2. 不适用。没有用到 Level 2 或 Level 3。
3. **观察到错误结果的真实调用方：** 调用 `Retryer.call` 的应用代码。异常在 `src/main/java/com/github/rholder/retry/Retryer.java:171` 离开库；如果通过 `wrap()`，则经 `Retryer.java:318` 传出。复现中对应 `repro/test_bugMC-12_timeout_ends_call_execution_exception.sh:245` 的 `o.value = retryer.call(callable);`：它收到了 `ExecutionException`，而同一策略本应重试并拿到 `"ok"`（C2 可证）。
4. **坏状态是永久的。** `call()` 抛出之后，库里没有任何机制会重试或纠正，`stopAfterAttempt(5)` 剩下的 4 次 attempt 永远用不上。唯一能避开的情况是谓词恰好覆盖了 `UncheckedTimeoutException`（C2），但那是触发条件以外的配置，不是事后掩盖问题的下游机制，所以不属于 MASKED。

---

## Entry 13: `fixedTimeLimit` accepts a zero or negative duration; every attempt then fails with `IllegalArgumentException` before the callable runs and is treated as a callable failure

- **Finding ID**: CR-D-11
- **Status**: REPRODUCED
- **Debate**: not run
- **Transcript**: /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-11/debate.md

running pwd; ls -la; find / -type d -name "bug-confirmation" 2>/dev/null | head -20
running ls -la /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation/* ; ls -la...
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation && cat SKILL.md && echo ---------- && cat guide.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation && cat phases/01-investigation.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation && cat phases/02-reproduction.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation && cat references/persistent-findings.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation && cat references/repair-request-format.md
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; ls -la $OUT; echo ----; ls -la $OUT...
running ls /home/ubuntu/guava-retrying-20261126/Specular/; ls /home/ubuntu/guava-retrying-20261126/Specular/bin 2>/dev/null; find /home/ubuntu/guava-retrying-2026112...
running cd /tmp && SP=/home/ubuntu/guava-retrying-20261126/Specular/specular; head -30 $SP; OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opu...
Persistent-findings 查询为空（无历史记录）。接下来读源码。
running WT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-11/worktree; cd $WT...
running find / -path /proc -prune -o \( -name "guava-22.0*.jar" -o -type d -name "guava-22.0" \) -print 2>/dev/null | head -20; ls ~/.m2/repository/com/google/guava/...
running mkdir -p /tmp/crd11-guava-src && cd /tmp/crd11-guava-src && unzip -o -q /home/ubuntu/scratch/guava22-sources-dl/guava-22.0-sources.jar com/google/common/util...
Guava 22.0 源码确认：`callWithTimeout` 在 `:147` 先 `checkPositiveTimeout`，然后才在 `:149` `executor.submit`。继续看构建配置、README 和 git 历史。
running WT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-11/worktree; cd $WT...
本地 git 历史未见相关提交。接下来查上游 issue tracker 和 PR（含已合并/已关闭）。
running cd /tmp && which gh && timeout 30 gh auth status 2>&1 | head -5; timeout 60 gh api repos/rholder/guava-retrying --jq '{full_name, pushed_at, open_issues_coun...
running cd /tmp && mkdir -p /tmp/crd11-gh && timeout 120 gh api --paginate "repos/rholder/guava-retrying/issues?state=all&per_page=100" --jq '.[] | [.number, .state,...
上游共 106 个 issue/PR。逐个读与 time limiter 相关的条目（#94、#96、#29、#92、#18、#1，以及近期关闭的 PR #107/#103/#95 等）。
running cd /tmp && for n in 94 96 29 92 1 18; do echo "=================== #$n"; timeout 60 gh api repos/rholder/guava-retrying/issues/$n --jq '"TITLE: " + .title +...
running cd /tmp && for n in 107 103 95 101 99 98 97 83 82 89 100 81; do echo "=================== #$n"; timeout 60 gh api repos/rholder/guava-retrying/issues/$n --jq...
PR #103、#95、#83 改动了 `AttemptTimeLimiters.java`，看一下它们的 diff 是否加了 duration 校验。
running cd /tmp && for n in 103 95 83; do echo "=================== PR #$n"; timeout 60 gh api --paginate repos/rholder/guava-retrying/pulls/$n/files --jq '.[] | sel...
上游 tracker 中没有关于零/负 duration 的报告，相关 PR 也都没加校验。再做一次全局 GitHub 搜索，并查本地 Specular case-studies 数据集。
running cd /tmp && for q in 'repo:rholder/guava-retrying "timeout must be positive"' 'repo:rholder/guava-retrying fixedTimeLimit negative' 'repo:rholder/guava-retryi...
spring-retry #69 同时提到了 `fixedTimeLimit` 和 "timeout must be positive"，读一下内容。
running cd /tmp && timeout 60 gh api repos/spring-attic/spring-retry/issues/69 --jq '"TITLE: " + .title + "\nSTATE: " + .state + "\nBODY:\n" + (.body // "")' 2>&1 |...
running cd /home/ubuntu/guava-retrying-20261126/Specular/case-studies 2>/dev/null && ls | head -80; grep -rli "guava-retrying\|rholder\|fixedTimeLimit\|AttemptTimeLi...
running ls -la /home/ubuntu/guava-retrying-20261126/Specular/case-studies/ | head; find /home/ubuntu/guava-retrying-20261126/Specular/case-studies -maxdepth 2 | head...
running cd /tmp && timeout 60 gh api -X GET search/code -f q='guava-retrying repo:specular-org/specular-case-studies' --jq '"total=\(.total_count)", (.items[] | " "...
running cd /tmp && timeout 60 gh api repos/specular-org/specular-case-studies/contents/systems --jq '.[].name' 2>&1 | tr '\n' ' '; echo; timeout 60 gh api repos/spec...
Specular 数据集中没有 guava-retrying 条目。再快速查两个主要 fork（rhuffman/re-retrying、itning/guava-retrying3）是否报告或修复过该问题。
running cd /tmp && for r in rhuffman/re-retrying itning/guava-retrying3; do echo "=== $r"; timeout 60 gh api "repos/$r" --jq '.full_name + " pushed=" + .pushed_at' 2...
running cd /tmp && timeout 60 gh api repos/rhuffman/re-retrying/commits/067f329 --jq '.commit.message + "\n" + ([.files[] | .filename] | join(", "))' 2>&1 | head; ec...
running java -version 2>&1; javac -version 2>&1; which mvn && mvn -v 2>&1 | head -3; ls ~/.m2/repository/com/google/code/findbugs/jsr305/ 2>/dev/null; ls ~/.m2/repos...
JDK 21 + Maven 3.8.7 + Guava 10.0.1/14.0.1/16.0.1/22.0 jar 都在本地。再读 `Attempt` / `RetryException` / `RetryListener` 的契约文档，补全 Phase 1 证据。
running WT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-11/worktree; cd $WT...
running cd /tmp/crd11-guava-src && grep -n -B2 -A40 "callWithTimeout(" com/google/common/util/concurrent/TimeLimiter.java | sed -n 1,80p
running cd /tmp/crd11-guava-src && sed -n 70,100p com/google/common/util/concurrent/TimeLimiter.java
running WT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-11/worktree; cd $WT...
Worktree 的 `src/` 与 v2.0.0 发布版一致（HEAD 只改了 `.travis.yml`）。Phase 1 证据齐全，写入 `investigation.md`。
running WT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-11/worktree; cd $WT...
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-11/investigation.md
Phase 1 记录完成，结论：路径完全经由公开 API 可达，上游无报告（`NEW`），进入 Phase 2。先确认几个对照用工厂方法的签名，再写 Level 0 复现。
running WT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-11/worktree; grep -...
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/test_bugCR-D-11_nonpositive_time_limit.sh
脚本已写好。按技能要求加外层 `timeout` 执行，并把输出保存为日志。
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro && chmod +x test_bugCR-D-11_non...
Level 0 一次命中：主运行（Guava 22.0）19/19 个 bug 观察点成立、8/8 对照正常；Guava 10.0.1/14.0.1/16.0.1 上结果相同。再跑一遍主运行确认可重复。
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro && CROSS_GUAVA=0 timeout 5m ./t...
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/test_bugCR-D-11_nonpositive_time_limit.sh
running set -e; WT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-11/worktree...
running FIX=$(cat /tmp/crd11-fixcheck.path); cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro && timeout 10m ./test_bugCR-D-1...
三次运行结论一致。接下来写持久化记录 `issue.json`。先确认 `specular findings validate` 的 schema 与 source 根目录（只读检查）。
running cd /home/ubuntu/guava-retrying-20261126/Specular && ls src/specular | head -50; grep -rln "def .*validate\|\"validate\"" src/specular | head;
running cd /home/ubuntu/guava-retrying-20261126/Specular/src/specular && grep -n "ROOTS\|\"root\"\|'root'\|allowed_roots\|def _validate_proposal\|def validate\|requi...
running cd /home/ubuntu/guava-retrying-20261126/Specular/src/specular && sed -n 1,60p persistent_findings.py | grep -n "LIVE\|ROOT\|source\|work" ; sed -n 240,300p p...
校验时 `source` 根取自 context：`/home/ubuntu/scratch/guava-retrying-src/guava-retrying`。只读核对该目录的相关文件与 worktree 是否一致。
running S=/home/ubuntu/scratch/guava-retrying-src/guava-retrying; WT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retry...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro && sed -n '/PRIMARY RUN/,/prima...
证据齐全。写结论记录 `confirmation.md`，随后写 `issue.json` 并跑 `specular findings validate`。
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-11/confirmation.md
running python3 - <<'PY' t = "fixedTimeLimit accepts a zero or negative duration; every attempt then fails with IllegalArgumentException before the callable runs and...
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-11/issue.json
running cd /tmp && OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; python3 -c "import json,...
`issue.json` 校验通过（`valid: true`，标题 156 字符）。最后确认 worktree 未被改动，并清理我在 `/tmp` 下的临时文件。
running WT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-11/worktree; git -C...
CR-D-11 已在 Level 0 复现：只用公开 API，没有时序辅助、没有状态注入、没有改源码。`fixedTimeLimit(0 或负数, …)` 在构造和 `build()` 时都被接受；之后每次 attempt 都在 Guava 提交任务之前抛出 `IllegalArgumentException`，callable 一次都没执行，`Retryer` 却把它当成 callable 自己的失败来处理。配合 `retryIfException()` 和 builder 默认的 `neverStop()`/`noWait()`，`call()` 永不返回：3 秒约 83 万次 attempt，调用线程 CPU 占用 98%。

两次完整运行结果一致；在 Guava 10.0.1/14.0.1/16.0.1 上重新编译后结果相同。加一行 `checkArgument(duration > 0)` 后测试变为"未复现"，说明这个测试能区分有 bug 和已修复两种情况。

- **Source**: Code Review
- **Novelty**: NEW
- **Severity**: Medium
- **Location**: src/main/java/com/github/rholder/retry/AttemptTimeLimiters.java:57
- **Reproduction test**: `.specular-output/repro/test_bugCR-D-11_nonpositive_time_limit.sh`（Level 0）

## Description
`fixedTimeLimit(duration, unit)`（`AttemptTimeLimiters.java:57-60`）、带 executor 的重载（`:69-72`）和 `FixedAttemptTimeLimit` 构造函数（`:97-103`）都不检查 `duration > 0`。同一库里其他带数值参数的内置工厂都会在构造时校验（`WaitStrategies.java:237`、`StopStrategies.java:103`、`:118`）。

Guava 22.0 的 `SimpleTimeLimiter.callWithTimeout` 在 `:147` 调用 `checkPositiveTimeout`（`:317-319`），在 `executor.submit`（`:149`）之前就抛出 `IllegalArgumentException("timeout must be positive: d")`。`Retryer.call` 的 `catch (Throwable)`（`Retryer.java:162-163`）把它记为该 attempt 的"callable 抛出的异常"。结果是 callable 从未运行，却被当作失败上报、重试并计入次数；如果谓词会重试异常且用的是 `neverStop()`，这个过程永不停止。

## Trigger scenario
1. 构造 `RetryerBuilder.<T>newBuilder().retryIfException().withAttemptTimeLimiter(AttemptTimeLimiters.<T>fixedTimeLimit(0, TimeUnit.MILLISECONDS)).build()`，工厂、`withAttemptTimeLimiter`、`build()` 都不报错。`d <= 0` 的自然来源：
   - 配置里写 `0` 表示"不限时"（与 JDK 的 `Socket.setSoTimeout`、`URLConnection.setConnectTimeout`、`Statement.setQueryTimeout`、`Thread.join` 约定一致）；
   - 未设置的数值属性默认为 0；
   - 由 `deadline - now` 算出的剩余预算已经 ≤ 0。

   真实代码就是把配置值直接传进这个工厂，例如 spring-retry issue 69 里的 `fixedTimeLimit(config.getRetryTimeout(), MILLISECONDS)` 配合 `retryIfException()`。
2. 调用 `retryer.call(callable)`，或 `executor.submit(retryer.wrap(callable))`。
3. 每个 attempt 依次经过 `Retryer.java:160` → `AttemptTimeLimiters.java:107` → `SimpleTimeLimiter.java:147/318`，在提交任务前抛出 IAE。然后 `Retryer.java:163` 生成 `ExceptionAttempt(IAE)`，通知 listener，再由谓词决定结果：
   - **默认谓词**：`call()` 在 `:171` 抛出 `ExecutionException(IAE)`。
   - **`retryIfException()`/`retryIfRuntimeException()` 加 `stopAfterAttempt(N)`**：在 `:174` 抛出 `RetryException("… after N attempts")`，且 `getNumberOfFailedAttempts()==N`。
   - **同样的谓词加默认 `neverStop()`/`noWait()`，或 README 里"永远重试"的示例**：`:157-184` 的循环永不结束。

## Developer intent
- **已知状态检索：**
  - rholder/guava-retrying 全部 106 个 issue/PR 都看过，包括 2026-09-05 关闭的 #107，以及改过 `AttemptTimeLimiters` 的 #103、#95、#83，都没有涉及非正 duration。
  - GitHub 定向搜索（`"timeout must be positive"`、`fixedTimeLimit negative/zero` 等）结果为 0。
  - Specular case-studies 数据集里没有 guava-retrying。
  - 两个主要 fork（`rhuffman/re-retrying`、`itning/guava-retrying3`）既没有这项校验，也没有相关报告。
- **代码历史：** `fixedTimeLimit` 来自 `7e474be`（dirkraft，2013），只有 `checkNotNull(timeUnit)`；Javadoc 没写取值范围；`AttemptTimeLimiterTest` 只测了 1 秒。
- **被违反的文档契约：**
  - `Retryer.call`："@throws ExecutionException if the given callable throws an exception"（`Retryer.java:148-150`）；
  - `Attempt`："a Throwable thrown by the call"；
  - `RetryException.numberOfFailedAttempts`："times we've tried and failed"。
- **设计意图：** 其余数值型工厂都在构造时校验；Guava 也把非正超时当作非法参数，而不是"立即超时"。
- **唯一的缓解不构成 mask：** 默认谓词下第一次 `call()` 就会失败并给出可读消息，但仍被包装成 callable 的 `ExecutionException`；对会重试异常的配置则完全不起作用。上游 #29 是另一种机制（真正超时后不重试）。

## Reproduction result
Level 0。命令：`timeout 10m .specular-output/repro/test_bugCR-D-11_nonpositive_time_limit.sh`，退出码 0。脚本用 `javac --release 8` 编译未修改的 2.0.0 源码（`177b6c9`，`src/` 与 `v2.0.0` 相同），依赖 Guava 22.0 + jsr305 2.0.2，在 JDK 21.0.13 上运行。以下是 `repro/CR-D-11.log` 主运行的原文摘录：

```
== B1: fixedTimeLimit with a zero / negative duration is accepted at construction and build()
  [BUG    ] fixedTimeLimit(0, SECONDS) + RetryerBuilder.build(): accepted, no exception
  [BUG    ] fixedTimeLimit(-1, SECONDS, userExecutor) + RetryerBuilder.build(): accepted, no exception
== B2: default rejection predicate -> call() throws ExecutionException(IAE) although the callable never ran
  [BUG    ] fixedTimeLimit(0, SECONDS) round 1: ExecutionException(cause=java.lang.IllegalArgumentException: timeout must be positive: 0), callable invocations=0, tasks submitted to user executor=n/a; cause thrown at:
        at com.google.common.base.Preconditions.checkArgument(Preconditions.java:191)
        at com.google.common.util.concurrent.SimpleTimeLimiter.checkPositiveTimeout(SimpleTimeLimiter.java:318)
        at com.google.common.util.concurrent.SimpleTimeLimiter.callWithTimeout(SimpleTimeLimiter.java:147)
        at com.github.rholder.retry.AttemptTimeLimiters$FixedAttemptTimeLimit.call(AttemptTimeLimiters.java:107)
        at com.github.rholder.retry.Retryer.call(Retryer.java:160)
        at CrD11Repro.main(CrD11Repro.java:175)
  [BUG    ] fixedTimeLimit(0, SECONDS) round 2: ExecutionException(cause=java.lang.IllegalArgumentException: timeout must be positive: 0), callable invocations=0, tasks submitted to user executor=n/a
  [BUG    ] fixedTimeLimit(-1, SECONDS, userExecutor) round 1: ExecutionException(cause=java.lang.IllegalArgumentException: timeout must be positive: -1), callable invocations=0, tasks submitted to user executor=0
== B3: retry predicate + stopAfterAttempt(5) + fixedWait(20ms) -> RetryException('after 5 attempts') with 0 runs
  [BUG    ] fixedTimeLimit(0, SECONDS) + retryIfException: RetryException("Retrying failed to complete successfully after 5 attempts."), getNumberOfFailedAttempts()=5, lastFailedAttempt.getExceptionCause()=java.lang.IllegalArgumentException: timeout must be positive: 0, listener saw 5 failed attempts, waited ~80 ms between them, callable invocations=0, tasks submitted to user executor=n/a
== C4 control: retryIfException + builder defaults (neverStop, noWait), positive limit, callable fails twice then succeeds
  [CTRL ok] fixedTimeLimit(1, SECONDS): call() returned 'ok' after 3 attempts, callable invocations=3
== B4: same configuration with fixedTimeLimit(0, MILLISECONDS) -> call() never returns, busy-loops, callable never runs
  [BUG    ] fixedTimeLimit(0, MILLISECONDS) + retryIfException() + defaults neverStop()/noWait(): after 3000 ms call() has not returned (caller alive=true), attempts so far=828422, last attempt cause=java.lang.IllegalArgumentException: timeout must be positive: 0, callable invocations=0, tasks submitted to user executor=n/a, caller CPU time=2956 ms (98% of wall)
        (cleanup) after interrupting the caller: alive=false, call() ended with com.github.rholder.retry.RetryException: Retrying failed to complete successfully after 828621 attempts.
== B5: Retryer.wrap() submitted to an executor (retryIfRuntimeException, neverStop, noWait, fixedTimeLimit(-1, SECONDS))
  [BUG    ] fixedTimeLimit(-1, SECONDS): Future of wrap(callable) not done after 2000 ms; pool thread made 523402 attempts; callable invocations=0
== C5 contrast: a positive but far-too-small limit is a real timeout AFTER submission (not an argument error)
  [CTRL ok] fixedTimeLimit(1, NANOSECONDS, userExecutor): ExecutionException(cause=com.google.common.util.concurrent.UncheckedTimeoutException), tasks submitted to user executor=1

SUMMARY: bug observations 19/19, controls ok 8/8
RESULT: BUG REPRODUCED
```

各段说明了什么：
- **B1**：工厂、`withAttemptTimeLimiter` 和 `build()` 都接受了非正的 duration。
- **B2**：IAE 在 `SimpleTimeLimiter.java:147` 抛出，由 `Retryer.java:160` 调用，栈上没有 callable 的帧；invocations=0，提交到 executor 的任务数为 0；同一个 `Retryer` 第二次调用照样失败。
- **B3**：`RetryException` 报告了 5 次 attempt，listener 也收到 5 次失败，但 callable 一次都没运行。
- **B4/B5**：`call()` 永不返回，只有应用自己 interrupt 才能结束；`wrap()` 时 executor 线程 2 秒内做了约 52 万次 attempt。

对照组：
- **C4**：同样的配置换成正数限时后，callable 正常执行，第 3 次成功返回。
- **C5**：极小的正数限时会在任务提交之后产生真正的 `UncheckedTimeoutException`，与非正值的行为不同。

重复与修复验证：
- `repro/CR-D-11.run2.log` 的第二次完整运行结果相同。
- Guava 10.0.1/14.0.1/16.0.1 上各自重新编译后都是 19/19。
- `repro/CR-D-11.fixcheck.log`：在临时副本里加一行 `checkArgument(duration > 0L, …)` 后，脚本退出码为 1（0/4，非正 duration 在调用工厂时就被拒绝），对照组 6/6。

## Recommendation
在两个 `fixedTimeLimit` 重载里、构造 `SimpleTimeLimiter` 之前先校验：

```java
Preconditions.checkArgument(duration > 0L, "duration must be > 0 but is %s", duration);
```

这样 2 参数版本不会为一个注定被拒绝的限时器白建 cached pool。私有构造函数里再加一道作兜底，并在 Javadoc 写明取值范围。需要"不限时"的用户应使用 `AttemptTimeLimiters.noTimeLimit()`；如果想支持"0 = 不限时"，也可以在工厂里显式把 0 映射到它。

更彻底的修法是不再把限时器在提交前抛出的异常当作 callable 的结果，也就是 dedup note 里提到的共享 catch-all `Retryer.java:162-163`。但只加校验就足以消除这个触发条件。

## REPRODUCED 前检查清单
1. **yes**：仅用 Level 0 触发（公开 API、正常调用，没有任何时序辅助）。
2. 不适用：没有使用 Level 2 或 Level 3。
3. 观察到错误结果的真实调用方是调用 `Retryer.call` 的应用代码：
   - `Retryer.java:171` 抛出的 `ExecutionException`，其 cause 并非 callable 抛出；
   - `Retryer.java:174` 的 `RetryException` 报告 N 次失败，实际执行次数为 0；
   - `Retryer.java:157-184` 的循环永不返回；
   - `wrap()` 路径下是 executor 线程上的 `RetryerCallable.call`（`Retryer.java:317-319`）；
   - 用户的 `RetryListener.onRetry`（`Retryer.java:166-168`）收到的是从未执行过的失败 attempt。
4. **永久**：`FixedAttemptTimeLimit` 的字段都是 final，同一个 `Retryer` 每次调用都同样失败（B2 round 2）。库内没有任何机制会修复或结束这个状态，只有应用自己 interrupt 才能停下（B4 cleanup、B5 `shutdownNow()`）。没有 mask。

产物都在 `.specular-output/` 下，worktree 没有改动：
- `confirmation/CR-D-11/investigation.md`
- `confirmation/CR-D-11/confirmation.md`
- `confirmation/CR-D-11/issue.json`（`specular findings … validate` 结果为 `valid: true`）
- `repro/test_bugCR-D-11_nonpositive_time_limit.sh`
- `repro/CR-D-11.log`、`repro/CR-D-11.run2.log`、`repro/CR-D-11.fixcheck.log`

---

## Entry 14: Under `fixedTimeLimit`, Guava's `throwCause(e, true)` appends the caller's stack to the callable's exception on every attempt, so a reused exception's stack trace grows without bound

- **Finding ID**: CR-D-12
- **Status**: REPRODUCED
- **Debate**: not run
- **Transcript**: /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-12/debate.md

running ls -la /home/ubuntu/.claude/projects/-home-ubuntu-guava-retrying-20261126-Specular-runs-guava-retrying-opus55max-20261126-guava-retrying--specular-output-con...
running find / -type d -name "bug-confirmation" 2>/dev/null | head -20
running ls -la ~/.claude/skills/ 2>/dev/null; ls -la /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; find /home/ubuntu/guava-retrying-20261126...
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation && cat SKILL.md && echo ===== && cat guide.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation && cat phases/01-investigation.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation && cat phases/02-reproduction.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation && cat references/persistent-findings.md && echo ====== && cat references/repair-req...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/ && ls -la && echo ==== && ls -la con...
已读完 bug-confirmation skill（guide + Phase 1/2 + references）。下面开始 Phase 1：先做 persistent-findings lookup，再审计代码。
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/ && cat persistent-findings-context.j...
running ls /home/ubuntu/guava-retrying-20261126/Specular/ ; ls /home/ubuntu/guava-retrying-20261126/Specular/bin 2>/dev/null; find /home/ubuntu/guava-retrying-202611...
running cd /home/ubuntu/guava-retrying-20261126/Specular && head -30 specular; echo ====; timeout 60 ./specular findings --help 2>&1 | head -40
running cd /home/ubuntu/guava-retrying-20261126/Specular && W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.sp...
Persistent-findings lookup 无命中（`[]`），按正常流程继续。现在看 worktree 源码与 Guava 22.0 的 `SimpleTimeLimiter`。
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-12/worktree && ls -...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-12/worktree && cat...
running find / -path /proc -prune -o \( -name "guava-22.0*.jar" -o -type d -name "guava-22.0" \) -print 2>/dev/null | head -20
running ls -la /home/ubuntu/.m2/repository/com/google/guava/guava/22.0/ /home/ubuntu/scratch/guava22-sources-dl/ /home/ubuntu/scratch/guava-jars/; sha256sum /home/ub...
running sha1sum /home/ubuntu/.m2/repository/com/google/guava/guava/22.0/guava-22.0.jar /home/ubuntu/scratch/guava22-sources-dl/guava-22.0-sources.jar; cat /home/ubun...
running cat -n /home/ubuntu/scratch/guava22-sources-dl/extracted/com/google/common/util/concurrent/SimpleTimeLimiter.java | sed -n '1,280p'
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-12/worktree && git...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-12/worktree && cat...
running sed -n '1,200p' /home/ubuntu/scratch/guava22-sources-dl/extracted/com/google/common/util/concurrent/TimeLimiter.java | grep -n -B3 -A40 "boolean amInterrupti...
running grep -n "callWithTimeout\|amInterruptible\|@deprecated\|@throws\|stack" /home/ubuntu/scratch/guava22-sources-dl/extracted/com/google/common/util/concurrent/T...
running sed -n '78,105p' /home/ubuntu/scratch/guava22-sources-dl/extracted/com/google/common/util/concurrent/TimeLimiter.java
running which gh && timeout 30 gh auth status 2>&1 | head -10
running for q in "stack trace" "stacktrace" "setStackTrace" "throwCause" "combineStackTraces" "memory leak" "OutOfMemory" "SimpleTimeLimiter" "fixedTimeLimit" "callW...
running timeout 60 gh api --paginate "repos/rholder/guava-retrying/issues?state=all&per_page=100" --jq '.[] | "\(.number)\t\(.state)\t\(if .pull_request then "PR" el...
running for n in 3 94 96; do echo "########## #$n"; timeout 30 gh issue view $n --repo rholder/guava-retrying --comments 2>&1 | head -80; done
running for n in 3 94 96; do echo "########## #$n"; timeout 30 gh api "repos/rholder/guava-retrying/issues/$n" --jq '"TITLE: \(.title)\nSTATE: \(.state)\nBODY:\n\(.b...
running for n in 1 82 95 103 107; do echo "########## PR #$n"; timeout 30 gh api "repos/rholder/guava-retrying/pulls/$n" --jq '"TITLE: \(.title)\nSTATE: \(.state) me...
running for n in 95 103; do echo "########## PR #$n AttemptTimeLimiters diff"; timeout 30 gh api "repos/rholder/guava-retrying/pulls/$n/files" --jq '.[] | select(.fi...
running for q in "SimpleTimeLimiter stack trace" "combineStackTraces" "throwCause stack" "callWithTimeout stack trace" "SimpleTimeLimiter setStackTrace" "TimeLimiter...
running timeout 30 gh api "repos/google/guava/issues/6599" --jq '"TITLE: \(.title)\nSTATE: \(.state) closed_at=\(.closed_at) state_reason=\(.state_reason)\nBODY:\n\(...
running for q in "TimeLimiter stack trace" "SimpleTimeLimiter exception" "callWithTimeout" ; do echo "### google/guava: $q"; timeout 30 gh search issues --repo googl...
running for n in 3550 3725; do echo "########## google/guava #$n"; timeout 30 gh api "repos/google/guava/issues/$n" --jq '"TITLE: \(.title)\nSTATE: \(.state)\nBODY:\...
using ToolSearch
searching for SimpleTimeLimiter callWithTimeout combineStackTraces stack trace grows reused exception
searching for guava-retrying fixedTimeLimit exception stack trace growing memory
running cd /home/ubuntu/guava-retrying-20261126/Specular && ls case-studies | head -80; grep -rIl -i "guava-retrying\|combineStackTraces\|SimpleTimeLimiter" case-stu...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/ && ls -la analysis-evidence/ analysi...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/ && cat analysis-evidence/build/pom.x...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-12/worktree/src/mai...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-12/worktree && sed...
running java -version 2>&1; javac -version 2>&1; ls ~/.m2/repository/com/google/code/findbugs/jsr305/ 2>/dev/null; ls ~/.m2/repository/com/google/code/findbugs/jsr30...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-12/worktree && git...
Worktree 为 `177b6c9`（v2.0.0+1，未修改），与 persistent-findings 的 source 一致。现在写 Phase 1 记录 `investigation.md`。
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-12/investigation.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-12/worktree/src/mai...
开始写复现脚本（自包含：从 worktree 用 `javac --release 8` 编译库，Guava 22.0 + jsr305 2.0.2 取自 `~/.m2`，然后跑各场景，全部带外层 `timeout`）。
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/test_bugCR-D-12_reused_exception_stack_growth.sh
先做一次标定：手动编译并单独试跑 OOM 场景，确认耗时和触发点，再跑完整脚本。
running set -e; S=/tmp/crd12-calib; rm -rf $S; mkdir -p $S/lib $S/cls $S/src WT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/...
running S=/tmp/crd12-calib; ls -R $S/cls | head; ls $S/lib/com/github/rholder/retry | head -40
running S=/tmp/crd12-calib; wc -l $S/src/ReproCRD12.java; R=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.spec...
running S=/tmp/crd12-calib; R=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/test_bugCR-D...
running S=/tmp/crd12-calib; CP=$HOME/.m2/repository/com/google/guava/guava/22.0/guava-22.0.jar:$HOME/.m2/repository/com/google/code/findbugs/jsr305/2.0.2/jsr305-2.0....
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/test_bugCR-D-12_reused_exception_stack_growth.sh
Now rewrite the driver/evaluation section so each scenario is checked from its own output file.
running R=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/test_bugCR-D-12_reused_exception...
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/test_bugCR-D-12_reused_exception_stack_growth.sh
脚本已就绪。后台运行完整复现（输出 tee 到 `repro/CR-D-12.log`），并用基于 PID 的等待阻塞到结束。
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro && bash -n test_bugCR-D-12_reus...
running PID=$(cat /tmp/crd12-run.pid); end=$((SECONDS+570)); while kill -0 $PID 2>/dev/null && [ $SECONDS -lt $end ]; do sleep 5; done; if kill -0 $PID 2>/dev/null;...
完整运行结束：25 项检查全部 `ok`，`RESULT: BUG TRIGGERED (PASS)`，脚本退出码 0。查看日志关键段落以便摘录。
running L=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/CR-D-12.log; sed -n '1,12p' $L;...
running L=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/CR-D-12.log; grep -n -A5 'ReproC...
running J19=/home/ubuntu/scratch/guava-jars/guava-19.0.jar; ls ~/.m2/repository/com/google/guava/guava/ 2>/dev/null; sha1sum $J19; for j in $J19 $HOME/.m2/repository...
running for v in 10.0.1 14.0.1 16.0.1; do j=$HOME/.m2/repository/com/google/guava/guava/$v/guava-$v.jar; [ -f $j ] || continue; echo "== guava $v sha1=$(sha1sum $j |...
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/test_bugCR-D-12_reused_exception_stack_growth.sh
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro && bash -n test_bugCR-D-12_reus...
running L=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/CR-D-12.log; grep -n -A2 'growth...
running cd /home/ubuntu/guava-retrying-20261126/Specular && grep -rn "def .*validate\|required\|\"status\"\|ALLOWED\|allowed_status\|STATUSES\|title" src/specular/fi...
running cd /home/ubuntu/guava-retrying-20261126/Specular/src/specular && grep -n "def _validate_proposal\|def validate\|REQUIRED\|required =\|_STATUS\|STATUS\|'sourc...
running cd /home/ubuntu/guava-retrying-20261126/Specular/src/specular && sed -n '240,278p;355,470p' persistent_findings.py
running cd /home/ubuntu/scratch/guava-retrying-src/guava-retrying/src/main/java/com/github/rholder/retry && c(){ printf '%s\t%s\n' "$(grep -cxF -- "$2" "$1")" "$1: $...
边界行均唯一。先在 `investigation.md` 中补入 Guava 多版本字节码核查（属于 Phase 1 代码审计事实）。
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-12/investigation.md
现在提取最终日志中的原文行（用于 verdict 正文的逐字粘贴）。
running L=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/CR-D-12.log; sed -n '1,6p' $L; e...
写入本 finding 的确认记录 `confirmation.md`（即 verdict 正文），随后写 `issue.json` 并校验。
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-12/confirmation.md
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; python3 - "$W/confirmation/CR-D-12/is...
`issue.json` 校验通过（`"valid": true`）。最后清理自己创建的临时文件，并确认 worktree 未被改动。
running rm -rf /tmp/crd12-calib /tmp/crd12-run.pid; ls -d /tmp/crd12-build.* 2>/dev/null || echo "no leftover build dirs"; git -C /home/ubuntu/guava-retrying-2026112...
CR-D-12 已用纯公共 API（Level 0）复现。同一个异常对象被重复抛出时，`fixedTimeLimit` 每次失败都会把调用方的整段栈追加到它上面，而且永远不会清掉：栈帧、日志、CPU 和占用的堆都持续增长，最终 OOM。两个对照（`noTimeLimit`、每次新建异常）都没有变化。未找到任何已有报告，所以是 NEW。完整记录在 `confirmation/CR-D-12/confirmation.md`。

- **Source**: Code Review
- **Novelty**: NEW
- **Severity**: Medium
- **Location**: src/main/java/com/github/rholder/retry/AttemptTimeLimiters.java:107
- **Reproduction test**: `repro/test_bugCR-D-12_reused_exception_stack_growth.sh` (Level 0); output in `repro/CR-D-12.log`

## Description
`FixedAttemptTimeLimit.call` (`AttemptTimeLimiters.java:107`) runs every attempt through Guava's deprecated four-argument `SimpleTimeLimiter.callWithTimeout(..., true)`. When the callable fails, that method runs `throw throwCause(e, true /* combineStackTraces */)` (`SimpleTimeLimiter.java:162-163`). `throwCause` then calls `cause.setStackTrace(concat(cause.getStackTrace(), e.getStackTrace()))` (`:256-259`). `cause` is the exact object the user's callable threw, and `e`'s stack is the caller thread's whole stack. guava-retrying stores and rethrows that same object (`Retryer.java:162-163`, `:171`, `:174`; `RetryException.java:57`).

If the callable throws the same exception object again, each failed attempt adds one more caller stack, and nothing ever removes it. Common sources of a reused object:
- a preallocated sentinel exception;
- a "cheap" exception that only overrides `fillInStackTrace()`;
- the JDK's `CompletableFuture.join()`, which rethrows the same `CompletionException` object every time.

Retained heap, CPU per attempt and log volume therefore grow without bound until `OutOfMemoryError`. `noTimeLimit()` leaves the same exception untouched. Guava's own Javadoc says the exception is "propagated to the caller exactly as-is". Every Guava version 2.0.0 can link against has this path (checked with `javap` for 10.0.1, 14.0.1, 16.0.1, 19.0 and 22.0).

## Trigger scenario
1. Build a retryer through the public API with `.withAttemptTimeLimiter(AttemptTimeLimiters.fixedTimeLimit(5, SECONDS[, executor]))` and exception-retrying predicates. The test uses the README quickstart: `retryIfExceptionOfType(IOException.class)`, `retryIfRuntimeException()`, `stopAfterAttempt(3)`.
2. The callable fails with the same object each time, for example `static final IOException NOT_READY` or `memoisedFuture.join()`.
3. Each failed attempt goes `Retryer.call:160` → `AttemptTimeLimiters.java:107` → `SimpleTimeLimiter.callWithTimeout:154/162-163` → `throwCause:259`, which calls `setStackTrace(old + caller stack)`.
4. Each failure adds about (caller depth + 5) frames: 7 frames when called from `main`, about 109 at an application depth of 100.
   - With the builder default `neverStop`, this builds up inside a single `call()`.
   - A static exception keeps accumulating for the whole life of the process.

## Developer intent
- **guava-retrying:** there is no developer commentary on this behavior.
  - `AttemptTimeLimiters.java:105-108` has not changed since 7e474be7 (2013, PR #1).
  - The `AttemptTimeLimiter` Javadoc only says "@throws Exception any exception from this invocation".
  - `AttemptTimeLimiterTest` never makes the callable throw.
- **Guava:** the contract for the method being called (`TimeLimiter.java:78-97`, 22.0) says the exception is "propagated to the caller exactly as-is", and the method is `@Deprecated`. Guava's stack concatenation is deliberate, but it was not designed with reused exception objects in mind.
- **Known-status:** nobody has reported this mechanism. I checked:
  - every issue and PR in rholder/guava-retrying (#1–#107, including #84 and #107, both closed in 2026-09);
  - google/guava (#6599 is only about nested-try style);
  - the forks rhuffman/re-retrying and itning/guava-retrying3;
  - a web search.

  PRs #95 (open) and #103 (unmerged) change line 107 to the three-argument API only for Guava 23 compatibility, and neither mentions this behavior.

## Reproduction result
PASS at Level 0. The test used the unmodified worktree `177b6c9b9f3e7957f404f0bdb8e23374cb1de43f`, Guava 22.0 (SHA-1 `3564ef3803de51fb0530a8377ec6100b33b0d073`) and JDK 21, plus a cross-check on JDK 11. There are no sleeps, failpoints or source changes.

Command: `bash repro/test_bugCR-D-12_reused_exception_stack_growth.sh`. Exit status was 0 and 26/26 checks passed.

```
[growth] limiter=noTimeLimit (control) exception=sentinel (IOException) initial stackTrace.length=1
  after 300 call()s / 900 failed attempts: stackTrace.length=     1 (SimpleTimeLimiter.callWithTimeout frames:   0)  listener log entry=      129 chars  caller's RetryException.printStackTrace=      362 chars  log total=      224,700 chars
[growth] limiter=fixedTimeLimit(5s, executor) exception=sentinel (IOException) initial stackTrace.length=1
  after   1 call()s /   3 failed attempts: stackTrace.length=    22 (SimpleTimeLimiter.callWithTimeout frames:   3)  listener log entry=     1614 chars  caller's RetryException.printStackTrace=     1775 chars  log total=        5,132 chars
  after 300 call()s / 900 failed attempts: stackTrace.length=  6301 (SimpleTimeLimiter.callWithTimeout frames: 900)  listener log entry=   445629 chars  caller's RetryException.printStackTrace=   445790 chars  log total=  267,948,600 chars
    [1] java.base/java.util.concurrent.FutureTask.report(FutureTask.java:122)
    [3] com.google.common.util.concurrent.SimpleTimeLimiter.callWithTimeout(SimpleTimeLimiter.java:154)
    [4] com.github.rholder.retry.AttemptTimeLimiters$FixedAttemptTimeLimit.call(AttemptTimeLimiters.java:107)
    [5] com.github.rholder.retry.Retryer.call(Retryer.java:160)
[attribution] limiter=fixedTimeLimit(5s, executor)  1 call() x 3 failed attempts: setStackTrace() called 3 time(s) on the callable's exception, by {com.google.common.util.concurrent.SimpleTimeLimiter.throwCause(SimpleTimeLimiter.java:259)=3}; stackTrace.length 2 -> 23
[cf] limiter=fixedTimeLimit(5s, executor)  CompletableFuture.join() rethrows the same object on every call: true  initial stackTrace.length=6
  after 100 call()s / 300 failed attempts: CompletionException stackTrace.length= 2106 (SimpleTimeLimiter.callWithTimeout frames: 300)
[paths] limiter=fixedTimeLimit(5s, executor) (b) predicate accepts the exception -> ExecutionException: stackTrace.length 2 -> 702 after 100 call()s x 1 attempt
[paths] limiter=fixedTimeLimit(5s, executor) (d) Retryer.wrap() run on an executor: stackTrace.length 2 -> 3002 after 100 call()s x 3 attempts
[paths] limiter=fixedTimeLimit(5s, executor) (e) default neverStop, one call() that succeeds on attempt 2000 (result=ok): stackTrace.length 2 -> 13995
[oom] fixedTimeLimit(5s, executor) / reused static sentinel, callerDepth=100, maxHeap=32MB, maxCalls=6000
    250 call()s /    750 failed attempts: heap used after GC=   5.7 MB  NOT_READY.stackTrace.length=   81,751     0.58 ms per call() since previous line
   1500 call()s /   4500 failed attempts: heap used after GC=  26.0 MB  NOT_READY.stackTrace.length=  490,501   125.27 ms per call() since previous line
  RESULT[fixedTimeLimit(5s, executor) / reused static sentinel]: call() #1604 ended with ExecutionException caused by java.lang.OutOfMemoryError: Java heap space  <-- not the configured outcome (83.9 s; 4809 failed attempts completed before)
  AFTER[fixedTimeLimit(5s, executor) / reused static sentinel]: a later call() succeeded (result=ok); after GC heap used=  27.6 MB of 32 MB, NOT_READY.stackTrace.length=524,182
  RESULT[noTimeLimit (control) / reused static sentinel]: all 6000 call()s ended with RetryException(IOException) as configured (0.2 s; 18000 failed attempts completed before)
  RESULT[fixedTimeLimit(5s, executor) / fresh object per attempt]: all 6000 call()s ended with RetryException(IOException) as configured (1.4 s; 18000 failed attempts completed before)
```

What the output shows, compared with the controls:
- **Growth:** the reused exception's stack goes from 1 to 6301 frames, with exactly one `SimpleTimeLimiter.callWithTimeout` frame per failed attempt (900/900). In the control it stays at 1 frame.
- **Logs:** one listener log entry grows from 129 to 445,629 chars.
- **Root cause:** the change is made by `SimpleTimeLimiter.throwCause(SimpleTimeLimiter.java:259)`, once per attempt.
- **Bounded heap (`-Xmx32m`):**
  - Retained heap grows linearly, about 5.7 kB per failed attempt at depth 100.
  - Time per call grows from 0.58 to 125 ms.
  - Call #1604 ends with `ExecutionException(OutOfMemoryError)` instead of the configured `RetryException(IOException)`.
  - The memory is still held after a later successful call.
- **Controls:** `noTimeLimit` with the same reused exception, and `fixedTimeLimit` with a fresh exception each attempt, both finish all 6000 calls as configured and stay at 1.6–1.7 MB.
- **Also reproduced the same way:** the two-argument `fixedTimeLimit(5s)` factory, the cheap `fillInStackTrace`-override exception, and JDK 11.
- **Mitigation check:** a reused exception built with `writableStackTrace=false` stays at 0 frames.

### Checklist
1. **Did Level 0 or Level 1 alone trigger it? Yes, Level 0 alone.** Only public APIs were used (`RetryerBuilder`, both `fixedTimeLimit` factories, `Retryer.call`, `Retryer.wrap`, `RetryListener`), with no timing help.
2. **Level 2/3 pre-condition:** not applicable, neither was used. The only pre-condition is a callable that throws the same object twice. Ordinary code does this, for example through a `static final` sentinel or the JDK's `CompletableFuture.join()`, which the run shows returns the same object (`true`).
3. **Which real caller observes a wrong outcome:**
   - The application calling `Retryer.call` (`Retryer.java:155`) gets `ExecutionException(OutOfMemoryError)` instead of the configured `RetryException(IOException)`. The OOM is caught at `Retryer.java:162-163` and rethrown by `attempt.get()` at `:171`. Its calls also slow from 0.58 to 125 ms each.
   - `RetryListener.onRetry` (`Retryer.java:166-168`) receives and logs ever-larger traces.
   - A caller that prints the `RetryException` (cause set at `RetryException.java:57`; the README does `e.printStackTrace()`) prints 445,790 chars instead of 362.
4. **Permanent? Yes.** Nothing resets the mutated stack, and a static exception lives as long as the process. After a later successful `call()` plus GC, the heap is still at 27.6 of 32 MB and the trace at 524,182 frames. Nothing later in the flow fixes or hides it.

## Recommendation
Fix `AttemptTimeLimiters.java:107` so it no longer calls Guava's four-argument `callWithTimeout`, which modifies the exception:
- Submit the callable to the executor directly.
- On `ExecutionException`, rethrow the cause exactly as received. Do not call `setStackTrace` or `addSuppressed` on it, because the object may be shared.
- On `TimeoutException`, cancel the future and throw `UncheckedTimeoutException`.
- On `InterruptedException`, cancel the future and rethrow.

This keeps today's visible behavior and also removes the dependency on the API that Guava 23 removed (#94). If the three-argument `TimeLimiter.callWithTimeout` is used instead, unwrap `ExecutionException`, `UncheckedExecutionException` and `ExecutionError`, and map `TimeoutException` to `UncheckedTimeoutException`. Example code is in `confirmation/CR-D-12/confirmation.md`.

Add a regression test: throw the same exception object on N attempts under `fixedTimeLimit`, then assert that it is still the same object and `getStackTrace().length` has not changed.

Until there is a fix, users can avoid the problem in any of these ways:
- build reused exceptions with `writableStackTrace=false` (verified above);
- throw a new exception for each failure;
- don't use `fixedTimeLimit`.

Other files written: `confirmation/CR-D-12/investigation.md` (Phase 1 evidence) and `confirmation/CR-D-12/issue.json`, which passed `specular findings validate` (`"valid": true`).

Web sources consulted for the novelty search (none reports this mechanism):
- [Guava SimpleTimeLimiter.java (master)](https://github.com/google/guava/blob/master/guava/src/com/google/common/util/concurrent/SimpleTimeLimiter.java)
- [SimpleTimeLimiter Javadoc, Guava 11.0.2](https://guava.dev/releases/11.0.2/api/docs/com/google/common/util/concurrent/SimpleTimeLimiter.html)
- [guava-retrying RetryException.java](https://github.com/rholder/guava-retrying/blob/master/src/main/java/com/github/rholder/retry/RetryException.java)

---

## Entry 15: Under `fixedTimeLimit`, a callable `Throwable` that is neither `Exception` nor `Error` reaches predicates still wrapped in `ExecutionException`, so `retryIfExceptionOfType` stops matching

- **Finding ID**: CR-D-13
- **Status**: REPRODUCED
- **Debate**: not run
- **Transcript**: /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-13/debate.md

running pwd; ls -la; find / -type d -name "bug-confirmation" 2>/dev/null | head -20
running ls -la ~/.claude/skills/ 2>/dev/null; ls -la /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; ls -la /home/ubuntu/guava-retrying-202611...
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; cat SKILL.md; echo ======; cat guide.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; cat phases/01-investigation.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; cat phases/02-reproduction.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; ls -la references; for f in references/*; do echo "===== $f"; cat "$f"; done
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; ls -la $W; echo ----; ls -la $W/confi...
先简要说明进展：已读完 bug-confirmation 技能（guide + Phase 1/2 + references），现在进入 Phase 1，查看 worktree 源码与构建方式。
running WT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-13/worktree; cd $WT...
running cd /home/ubuntu/guava-retrying-20261126; ls -la; find / -name "guava-22.0*.jar" 2>/dev/null | head; find / -type d -name "guava-22.0" 2>/dev/null | head
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; ls -la $W/harness $W/analysis-evidenc...
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; cat $W/analysis-evidence/build/pom.xm...
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; cat $W/analysis-evidence/probes/timel...
running WT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-13/worktree; cd $WT...
进展：已读完 `Retryer.call`、`RetryerBuilder.ExceptionClassPredicate`、`AttemptTimeLimiters`。下一步对照 Guava 22.0 `SimpleTimeLimiter` 源码确认 `throwCause` 的分支。
running FD=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-13; mkdir -p $FD/gu...
running WT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-13/worktree; cd $WT...
running which gh && gh auth status 2>&1 | head -5; timeout 30 gh api 'repos/rholder/guava-retrying' --jq '{full_name, open_issues_count, pushed_at, updated_at}' 2>&1...
running cd /tmp; FD=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-13; mkdir...
running cd /tmp; FD=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-13; timeou...
running FD=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-13; python3 -I - "$...
running cd /tmp; for n in 107 95 103 82 84; do echo "===== PR #$n"; timeout 60 gh api "repos/rholder/guava-retrying/pulls/$n" --jq '{state, merged: .merged, merged_a...
running cd /tmp; for n in 95 103; do echo "===== PR #$n AttemptTimeLimiters.java patch"; timeout 60 gh api "repos/rholder/guava-retrying/pulls/$n/files?per_page=100"...
running cd /tmp; timeout 60 gh api 'repos/rholder/guava-retrying/commits?sha=master&per_page=15' --jq '.[] | .sha[0:7] + " " + .commit.author.date[0:10] + " " + (.co...
running ls /home/ubuntu/guava-retrying-20261126/Specular/; ls /home/ubuntu/guava-retrying-20261126/Specular/bin 2>/dev/null; find /home/ubuntu/guava-retrying-2026112...
running cd /home/ubuntu/guava-retrying-20261126/Specular; head -30 specular; W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/g...
running cd /home/ubuntu/guava-retrying-20261126/Specular; ls case-studies | head -80; grep -r -l -i "guava-retrying\|rholder" case-studies 2>/dev/null | head
running cd /tmp; for q in 'guava-retrying fixedTimeLimit Throwable' 'guava-retrying ExecutionException retryIfExceptionOfType timeLimiter' 'AttemptTimeLimiter Execut...
running cd /tmp; for n in 28 22 23 14 8 7; do echo "===== re-retrying #$n"; timeout 60 gh api "repos/rhuffman/re-retrying/issues/$n" --jq '"[" + .state + "] " + .tit...
running which java javac kotlinc kotlin groovy groovyc scala scalac mvn 2>&1; java -version 2>&1 | head -2; /usr/lib/jvm/java-11-openjdk-amd64/bin/java -version 2>&1...
running FD=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-13; cd $FD/guava22-...
running for v in 10.0.1 14.0.1 16.0.1 22.0; do ls -la ~/.m2/repository/com/google/guava/guava/$v/*.jar 2>/dev/null; done; ls -la ~/.m2/repository/com/google/code/fin...
running ls -la ~/.m2/repository/org/apache/commons/commons-lang3/*/ 2>/dev/null; find / -name 'commons-lang3-*.jar' -not -path '*/proc/*' 2>/dev/null | head -5; find...
running J=~/.m2/repository/org/apache/commons/commons-lang3/3.8.1/commons-lang3-3.8.1.jar; sha1sum $J; cat $J.sha1; echo; javap -cp $J org.apache.commons.lang3.excep...
Phase 1 证据已齐（commons-lang3 3.8.1 的 `ExceptionUtils.rethrow` 可作为真实第三方触发源）。现在写入 `investigation.md`。
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-13/investigation.md
Phase 1 记录已写好。进入 Phase 2：先确认 `RetryListener` 签名，然后编写 Level 0（纯公共 API、无时序辅助）复现脚本。
running WT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-13/worktree; sed -n...
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/test_bugCR-D-13_weird_throwable_timelimit_misclassifie...
Fix a stale comment, then run the reproduction with an outer timeout and capture the log.
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/test_bugCR-D-13_weird_throwable_timelimit_misclassifie...
running R=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro; chmod +x $R/test_bugCR-D-13_wei...
The script exited 0 (bug reproduced). The log is large, so I'll read it in sections: first the full JDK 21 run.
running R=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro; wc -l -c $R/CR-D-13.log; awk '/...
running R=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro; grep -n -E '^=+ run:|^#+ supple...
The JDK 11 run and the supplementary Guava 16.0.1/14.0.1/10.0.1 runs all reproduced (8 divergences each, controls consistent). Now the A1/C1 detail lines from the JDK 11 run, for the report.
running R=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro; sed -n '64,75p;95,100p;104,106p...
Level 0 reproduction succeeded. Next: a second run to confirm determinism, a check that the persistent-findings source root matches the worktree, and a look at the `issue.json` validation rules.
running R=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro; cd /tmp; EXTRA_GUAVA_VERSIONS="...
running cd /home/ubuntu/guava-retrying-20261126/Specular/src/specular; grep -rn -l "def.*validate\|\"validate\"\|'validate'" . 2>/dev/null | head; ls
running cd /home/ubuntu/guava-retrying-20261126/Specular/src/specular; grep -n -E "REQUIRED|required|ALLOWED|_STATUSES|_SOURCES|def _validate_proposal|def validate|r...
running cd /home/ubuntu/guava-retrying-20261126/Specular/src/specular; sed -n 240,300p persistent_findings.py; echo ......; sed -n 330,505p persistent_findings.py
running cd /home/ubuntu/guava-retrying-20261126/Specular/src/specular; grep -n -E "^DIRECTORY|^RECEIPTS|^CONTEXT|^LIVE|def _strings|def _text|def _path" -A6 persiste...
running FD=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-13; cd $FD/guava22-...
running FD=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-13; python3 -I - "$...
The title is 2 characters over the limit; shortening it and re-running.
running python3 -I -c " for t in ['Under fixedTimeLimit, a callable Throwable that is neither Exception nor Error reaches retry predicates as ExecutionException, so...
running python3 -I -c " for t in ['fixedTimeLimit wraps a callable Throwable that is neither Exception nor Error in ExecutionException, so retryIfExceptionOfType sto...
running FD=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-13; python3 -I - "$...
running cat /tmp/crd13-validate.out | head -c 1500; echo; grep -n "\"validate\"\|command == \"validate\"\|validate_issue_proposal" /home/ubuntu/guava-retrying-202611...
`issue.json` validated (`"valid": true`). Before writing the conclusion, I'll check the exact line numbers of a few citations.
running WT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-13/worktree; FD=$WT...
Two citations in `investigation.md` are off (`RetryException.java:42` should be `:57`; `TimeLimiter.java:79-98` should be `:80-82`). Fixing them and re-validating.
running FD=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-13; cd $FD; grep -n...
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; git -C $W/confirmation/CR-D-13/worktr...
# CR-D-13 — Confirmation verdict

**Conclusion: REPRODUCED.** I triggered it with public APIs only (Level 0, no timing help), on Guava 22.0 under both JDK 21 and JDK 11. The run is deterministic.

- **Source**: Code Review
- **Novelty**: NEW
- **Location**: src/main/java/com/github/rholder/retry/AttemptTimeLimiters.java:107
- **Severity**: Medium. Once triggered, the configured retry policy flips: it either stops retrying or retries something it shouldn't. The trigger is limited to callables that throw a non-`Exception`, non-`Error` Throwable.
- **Reproduction test**: `.specular-output/repro/test_bugCR-D-13_weird_throwable_timelimit_misclassified.sh` (Level 0). Logs are `repro/CR-D-13.log` and `repro/CR-D-13.run2.log`.

## Description

How the bug happens:

1. `FixedAttemptTimeLimit.call` (`AttemptTimeLimiters.java:107`) delegates to Guava's deprecated `SimpleTimeLimiter.callWithTimeout(callable, d, u, true)`.
2. Guava's `throwCause` rethrows the cause only when it is an `Exception` or an `Error`. For any other Throwable it rethrows the outer `FutureTask` `ExecutionException` (Guava 22.0 `SimpleTimeLimiter.java:261-268`).
3. `Retryer.call` catches that wrapper with `catch (Throwable t)` (`Retryer.java:162-163`) and records it as the attempt's exception.
4. `ExceptionClassPredicate` (`RetryerBuilder.java:212`) and `ExceptionPredicate` (`:247`) test `getExceptionCause()` directly, without unwrapping.

Without a time limit, `NoAttemptTimeLimit` (`AttemptTimeLimiters.java:77-79`) passes the callable's Throwable through unchanged. So adding only `fixedTimeLimit` changes the retry decision:

- **`retryIfExceptionOfType(T)` / `retryIfException(Predicate)`** stop matching. The call ends after 1 attempt with `ExecutionException(ExecutionException(t))`.
- **`retryIfException()`** goes the other way: it starts retrying a Throwable that is not an `Exception`.

## Trigger scenario

1. The callable throws `TransientFailure extends Throwable`. I tested three ways to throw it:
   - commons-lang3 3.8.1 `ExceptionUtils.rethrow`
   - `Class.newInstance()`
   - a generic sneaky throw, which is what Lombok `@SneakyThrows` compiles to
2. Configure `retryIfExceptionOfType(TransientFailure.class)` + `stopAfterAttempt(3)`.
3. With `noTimeLimit()`: 3 invocations, then `RetryException(cause=TransientFailure)`.
4. Change only to `fixedTimeLimit(5, SECONDS[, pool])`; the callable still throws immediately and never times out. Result: 1 invocation, then `ExecutionException <- ExecutionException <- TransientFailure`. Listeners see `getExceptionCause()` as `ExecutionException`.

## Developer intent

The documentation consistently says predicates see the exception the callable threw, and that the time limiter only limits duration:

- **`Attempt.getExceptionCause()`**: "the exception thrown by the call" (`Attempt.java:65`).
- **`retryIfExceptionOfType`**: retries "if an exception of the given class … is thrown by the call", and its parameter type is `Class<? extends Throwable>`.
- **`Retryer.call`** Javadoc: "The original exception is wrapped into an ExecutionException" (`Retryer.java:148-150`).
- **`withAttemptTimeLimiter`**: only says it limits each attempt's duration.
- **`AttemptTimeLimiter.call`**: "@throws Exception any exception from this invocation".
- **Guava 22.0's own `TimeLimiter.callWithTimeout` Javadoc** promises the exception is propagated "exactly as-is" (`TimeLimiter.java:80-82`). Its implementation deviates via the `:267` "weird kind of Throwable" branch, and `:138` carries a TODO.

There is no test for "time limiter + non-`Exception`/`Error` Throwable". The existing tests only assert the unlimited case, where the cause is the original exception wrapped once. `git log` and blame show no discussion of this.

Prior-report search:

- **Upstream `rholder/guava-retrying`**: I read all 106 issues/PRs and their comments, including #107 (closed 2026-09-05) and #84 (closed 2026-09-20). #29 is about the timeout exception and #67 about catching `Error`s, so neither is this mechanism. PRs #95/#103 change the same file only for Guava 23 compatibility.
- **Fork `rhuffman/re-retrying` and a GitHub-wide search**: nothing for this mechanism.
- **`specular findings lookup`**: returned `[]`.

So this is **NEW**. Details are in `confirmation/CR-D-13/investigation.md`.

## Reproduction result

Command: `timeout 10m .specular-output/repro/test_bugCR-D-13_weird_throwable_timelimit_misclassified.sh`. Exit 0, 6.6 s.

The second run (`EXTRA_GUAVA_VERSIONS=""`) gave the same result on both JDKs: `divergences=8 controlFailures=0`.

Excerpt from the JDK 21 run (each line truncated after the `|` separator; full text in the log):

```
[A1] retryIfExceptionOfType(TransientFailure.class), stopAfterAttempt(3), T1 commons-lang3 ExceptionUtils.rethrow
   noTimeLimit()                  -> invocations=3 elapsed=1ms thrown=com.github.rholder.retry.RetryException <- TransientFailure (getNumberOfFailedAttempts=3) | ...
   fixedTimeLimit(5,SECONDS,pool) -> invocations=1 elapsed=1ms thrown=java.util.concurrent.ExecutionException <- java.util.concurrent.ExecutionException <- TransientFailure | thrown.getCause() instanceof TransientFailure=false | listener saw getExceptionCause(): [#1 java.util.concurrent.ExecutionException <- TransientFailure]
[C1] retryIfException(), stopAfterAttempt(3), T1 commons-lang3 ExceptionUtils.rethrow
   noTimeLimit()                  -> invocations=1 elapsed=0ms thrown=java.util.concurrent.ExecutionException <- TransientFailure | ...
   fixedTimeLimit(5,SECONDS,pool) -> invocations=3 elapsed=0ms thrown=com.github.rholder.retry.RetryException <- java.util.concurrent.ExecutionException <- TransientFailure (getNumberOfFailedAttempts=3) | ...
[D1] ... control: throw TransientIOException   => CONTROL OK: identical to noTimeLimit()
[E1] ... control: throw TransientError         => CONTROL OK: identical to noTimeLimit()
[ROOT-CAUSE] fixedTimeLimit outcome: outer=java.util.concurrent.ExecutionException (created by Retryer.ExceptionAttempt), inner=java.util.concurrent.ExecutionException, inner.getCause()=TransientFailure, inner.getCause() is Exception? false, is Error? false
     at java.base/java.util.concurrent.FutureTask.report(FutureTask.java:122)
     at com.google.common.util.concurrent.SimpleTimeLimiter.callWithTimeout(SimpleTimeLimiter.java:154)
     at com.github.rholder.retry.AttemptTimeLimiters$FixedAttemptTimeLimit.call(AttemptTimeLimiters.java:107)
     at com.github.rholder.retry.Retryer.call(Retryer.java:160)
SUMMARY java.version=21.0.13.1: divergences=8 controlFailures=0 baselineFailures=0
SUMMARY java.version=11.0.33.1: divergences=8 controlFailures=0 baselineFailures=0
FINAL: BUG REPRODUCED on every primary run (Guava 22.0; JDKs: /usr/lib/jvm/java-21-openjdk-amd64 /usr/lib/jvm/java-11-openjdk-amd64)
```

The A1 `fixedTimeLimit` row is the bug: 1 invocation with a doubly-wrapped exception, versus 3 retries without a limit.

- **Root-cause frames**: the extra `ExecutionException` comes from `FutureTask` and is passed through by `SimpleTimeLimiter`. Its cause is neither `Exception` nor `Error`, so only the `:268 throw e` branch can have thrown it.
- **Controls**: the `Exception` and `Error` controls behave identically with and without a time limit, which confirms the divergence is limited to that branch.
- **Other cases**: A2/A3 (the other two ways of throwing), B1 (the predicate form), and the no-executor `fixedTimeLimit(5,SECONDS)` all diverge the same way.
- **Older Guava**: as a supplementary check, the same source compiled against Guava 16.0.1, 14.0.1 and 10.0.1 gives the same 8 divergences.

**Checklist before REPRODUCED:**

1. **Level 0/1 alone?** Yes. Level 0 alone, with public APIs and normal operation, no timing help and no timeout involved.
2. **Level 2/3 used?** No.
3. **Real consumer:** `Retryer.call` at `Retryer.java:170-172` applies the rejection predicate to the misattributed attempt and returns `attempt.get()` instead of retrying. The application calling `Retryer.call()` gets `ExecutionException(ExecutionException(t))` after one invocation, and its `getCause()` is not the original exception. `RetryListener.onRetry` (`Retryer.java:166-168`) sees `ExecutionException`.
4. **Permanent?** Yes. This is the final outcome of `call()`: retries that were skipped never happen, and nothing downstream re-evaluates the decision. There is no masking mechanism, and it reproduces deterministically across 2 runs × 2 JDKs.

## Recommendation

- **Fix:** in `FixedAttemptTimeLimit.call`, stop using the deprecated 4-argument `callWithTimeout`. Submit to the executor directly and call `future.get(duration, unit)`:
  - On `ExecutionException`, rethrow `getCause()` as-is (sneaky rethrow is fine, since `Retryer.call` already catches `Throwable`).
  - On timeout, keep `future.cancel(true)` + `UncheckedTimeoutException`.
  - On interrupt, keep cancelling and rethrowing `InterruptedException`.

  This also drops the dependency on the API removed in Guava 23 (#94).
- **Don't just switch to the 3-argument overload** (as PRs #95/#103 do). Per `SimpleTimeLimiter.java:184-186,299-307`, it wraps every outcome in `ExecutionException` / `UncheckedExecutionException` / `ExecutionError`, which would extend this misclassification to all exception types.
- **Regression test:** with the same predicates, a non-`Exception`/`Error` Throwable must produce the same attempt count and the same `getExceptionCause()` under `noTimeLimit` and `fixedTimeLimit`.

The persistent record `confirmation/CR-D-13/issue.json` passes `specular findings validate` (`"valid": true`). The worktree was not modified.

---

## Entry 16: (Known #67) `Retryer.call` catches an `Error` thrown by the callable as an ordinary attempt outcome, wraps it in `ExecutionException` and may retry it

- **Finding ID**: CR-D-15
- **Status**: DROPPED
- **Debate**: not run
- **Transcript**: /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-15/debate.md

running find / -type d -name "bug-confirmation" 2>/dev/null | head -20; echo ---; ls -la /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-...
running ls -la ~/.claude/skills 2>/dev/null; echo ---; ls -la /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.cl...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-15/; cat turn01_A.l...
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; cat SKILL.md; echo; echo =====GUIDE=====; cat guide.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; cat phases/01-investigation.md; echo; echo =====REPRO=====; cat phases/02-reproduct...
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; cat references/persistent-findings.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; cat references/repair-request-format.md
Skill 已读完。现在按 Persistent Findings 规则先做轻量 lookup，然后进入 Phase 1 代码审计。
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; which specular; ls -la $OUT | head...
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; cat $OUT/persistent-findings-contex...
running head -30 /home/ubuntu/guava-retrying-20261126/Specular/specular; file /home/ubuntu/guava-retrying-20261126/Specular/specular
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; S=/home/ubuntu/guava-retrying-20261...
Persistent registry 无匹配记录。进入 Phase 1 代码审计。
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-15/worktree; cd $W;...
reading /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-15/worktree/src/main/java/com/github/rhold...
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-15/worktree; cd $W/s...
running find / -type d -name "guava-22.0" 2>/dev/null | head; find ~/.m2 -name "guava-22.0*.jar" 2>/dev/null; find ~/.m2 -path "*jsr305*" -name "*.jar" 2>/dev/null |...
running ls -la ~/.m2/repository/com/google/guava/guava/22.0/; find / -name "guava-22.0-sources.jar" 2>/dev/null | head -3; find / -path "*guava-22.0*" -name "SimpleT...
running ls -la /home/ubuntu/scratch/guava22-sources-dl/; mkdir -p /tmp/crd15-guava-src && cd /tmp/crd15-guava-src && unzip -o -q /home/ubuntu/scratch/guava22-sources...
running cd /tmp/crd15-guava-src; grep -n "" com/google/common/util/concurrent/SimpleTimeLimiter.java | sed -n '120,175p;255,270p'
running which gh && timeout 60 gh auth status 2>&1 | head -5; timeout 60 gh issue view 67 --repo rholder/guava-retrying --json number,title,state,body,author,created...
running cd /tmp; timeout 60 gh api repos/rholder/guava-retrying --jq '{default_branch, pushed_at, archived, open_issues_count}' 2>&1; timeout 60 gh api "repos/rholde...
running cd /tmp; for q in "Throwable" "Error" "OOME" "OutOfMemoryError" "67"; do echo "=== PR search: $q"; timeout 60 gh search prs --repo rholder/guava-retrying "$q...
running cd /tmp; echo "=== #67 timeline"; timeout 60 gh api -H "Accept: application/vnd.github+json" "repos/rholder/guava-retrying/issues/67/timeline?per_page=100" -...
running cd /tmp; timeout 60 gh api -H "Accept: application/vnd.github+json" "repos/rholder/guava-retrying/issues/67/timeline?per_page=100" --jq '.[] | select(.event=...
running cd /home/ubuntu/guava-retrying-20261126/Specular; grep -rn "DROPPED" --include=*.py src/specular | grep -v "^.*test" | head -40
running cd /home/ubuntu/guava-retrying-20261126/Specular; sed -n '1400,1560p' src/specular/confirmlib.py
running cd /home/ubuntu/guava-retrying-20261126/Specular; sed -n '60,110p' src/specular/confirmlib.py; grep -n "Novelty\|\*\*Source\*\*\|\*\*Location\*\*\|def _parse...
running cd /home/ubuntu/guava-retrying-20261126/Specular; sed -n '4180,4240p' src/specular/confirmlib.py; sed -n '150,175p' src/specular/confirmlib.py
running cd /home/ubuntu/guava-retrying-20261126/Specular; grep -n "_REPORT_STATUS_FIELD_RE\s*=" -A3 src/specular/confirmlib.py; grep -n "investigation.md" src/specul...
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-15/worktree; cd $W;...
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-15/worktree; cd /tmp...
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-15/investigation.md
running rm -rf /tmp/crd15-guava-src; ls /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro |...
CR-D-15 判定为 **DROPPED**：这是来自 code review 的 finding，而上游 issue #67 已经报告过同一处、同一机制的缺陷，属于 skill 规定的唯一 Phase-1 预过滤情形。因此我没有进入 Phase 2，也没有写 `repro/test_bugCR-D-15_*`。你的输出说明里要求写并执行这个测试，但 skill 对 `DROPPED` 的规定是“write no `repro/` test”，我按 skill 执行。dispatcher 代码（`confirmlib.py` 的 `_validate_final_artifacts`）也只对 `REPRODUCED` 要求 repro 文件。证据记录在 `confirmation/CR-D-15/investigation.md`。

- **Source**: Code Review
- **Novelty**: KNOWN (cite: https://github.com/rholder/guava-retrying/issues/67; fix-status: unfixed)
- **Location**: src/main/java/com/github/rholder/retry/Retryer.java:162
- **Severity**: —（已 DROPPED；输入时标为 Medium）
- **Reproduction test**: 无

## Description
`Retryer.call` 在 `Retryer.java:162` 用 `catch (Throwable t)` 捕获 attempt 抛出的所有东西，包括 callable 抛出的 `Error`，并把它当成普通的 `ExceptionAttempt`。`Retryer.java:254` 再把它包进 checked 的 `ExecutionException`，所以：
- listener 会收到这个 attempt；
- predicate 拒绝该 attempt 时，`call()` 抛出 `ExecutionException(cause=Error)`；
- predicate 接受 `Throwable` 时，这个 `Error` 会被重试，直到抛出 `RetryException(cause=Error)`。

用 `fixedTimeLimit` 时结果相同：Guava 22.0 在 `SimpleTimeLimiter.java:264-265` 把 worker 里的 `Error` 原样抛回，最后进入的还是同一个 catch。

## Trigger scenario
用公开 API 即可触发：
- `RetryerBuilder.newBuilder().retryIfException().withStopStrategy(stopAfterAttempt(3)).build().call(() -> { throw new AssertionError(); })`：1 次 attempt 后抛出 `ExecutionException(cause=AssertionError)`，因为 `Error` 不匹配 `RetryerBuilder.java:130-133` 的 `Exception.class`。
- 改用 `retryIfExceptionOfType(Throwable.class)`：执行 3 次 attempt 后抛出 `RetryException(cause=AssertionError)`。
- 有没有 time limit 都可达，库内没有任何针对 `Error` 的处理。

## Developer intent
- **上游 issue**：#67 "Retryer.call should not catch Errors like OOME" 仍为 OPEN（2016-11-15 提出，0 条评论）。正文直接指向 master 的 `Retryer.java#L162`，要求 "not to catch and wrap Error potentially thrown by the called Callable"。
- **同一行**：上游 master HEAD 和 worktree HEAD 都是 `177b6c9b9f3e7957f404f0bdb8e23374cb1de43f`，两边第 162 行都是 `} catch (Throwable t) {`。
- **重试后果也已报告**：fork 的 `rhuffman/re-retrying#14` 自称是 #67 的重复，单独报告了“对 OutOfMemoryError 反复重试”。
- **没有已落地的修复**：PR 检索（含最近关闭/合并的）没有找到修复。#107 "Modernize" 改过 `Retryer.java`，但 2026-09-05 关闭、`mergedAt: null`。
- **代码历史和文档**：这个 catch 由 `6d2d838`（2012）引入，`fbe3177` 只调整了格式，没有任何说明意图的提交。文档只描述 `Exception`（`Retryer.java:148-150`、`README.md:55-56`），没有提到 `Error`。`Attempt.java:21-23` 把 attempt 定义为“a Throwable thrown by the call”。
- **测试**：现有测试都没有覆盖 callable 抛出 `Error` 的情况。
- **历史记录**：Persistent findings lookup 返回 `[]`。

这个 finding 额外列出的后果（listener、checked 包装、重试、time-limiter 路径）全部出自同一个 catch，#67 提出的修复能一并消除，所以它只是复述了 #67。

## Reproduction result
没有运行。Phase 1 的 code-review × known 预过滤已经成立，按 skill 不进入 Phase 2。下面是决定这个结论的命令的真实输出：
```
$ gh issue view 67 --repo rholder/guava-retrying --json number,title,state,createdAt,closedAt,comments,body
{"body":"Please consider catching \"Exception | RuntimeException e\" instead of Throwable at https://github.com/rholder/guava-retrying/blob/master/src/main/java/com/github/rholder/retry/Retryer.java#L162 not to catch and wrap Error potentially thrown by the called Callable.","closedAt":null,"comments":0,"createdAt":"2016-11-15T17:45:21Z","number":67,"state":"OPEN","title":"Retryer.call should not catch Errors like OOME"}

$ gh api repos/rholder/guava-retrying/commits/master --jq .sha
177b6c9b9f3e7957f404f0bdb8e23374cb1de43f
$ git -C worktree rev-parse HEAD
177b6c9b9f3e7957f404f0bdb8e23374cb1de43f

$ gh api .../contents/src/main/java/com/github/rholder/retry/Retryer.java?ref=master | base64 -d | sed -n 162p
            } catch (Throwable t) {
$ sed -n 162p worktree/src/main/java/com/github/rholder/retry/Retryer.java
            } catch (Throwable t) {

$ gh pr view 107 --repo rholder/guava-retrying --json state,mergedAt,closedAt,title
{"closedAt":"2026-09-05T04:39:19Z","mergedAt":null,"state":"CLOSED","title":"Modernize"}
```

## Recommendation
在上游 #67 下跟进，不要作为新缺陷提交。修复方式就是 #67 提出的：在 `Retryer.java:162` 改为 catch `Exception`，让 `Error` 直接抛出。`fixedTimeLimit` 路径不需要额外改动，因为 Guava 本来就把 `Error` 原样抛回到这一行。没有写 `issue.json`，因为 persistent 记录只用于 `REPRODUCED/ENV_LIMITED/MASKED`。

---

## Entry 17: `WaitStrategies.join` sums component sleeps without overflow protection; a total of 2^63 ms or more wraps negative and `call()` throws `IllegalArgumentException`

- **Finding ID**: CR-D-16
- **Status**: REPRODUCED
- **Debate**: not run
- **Transcript**: /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-16/debate.md

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

---

## Entry 18: `exceptionWait` returns the user function's negative value unclamped; `Thread.sleep` then throws `IllegalArgumentException` out of `call()`

- **Finding ID**: CR-D-17
- **Status**: REPRODUCED
- **Debate**: not run
- **Transcript**: /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-17/debate.md

running ls -la ~/.claude/ 2>/dev/null; ls -la ~/.claude/skills 2>/dev/null; find / -type d -name "bug-confirmation" 2>/dev/null | head -20
running pwd; ls -la; ls -la .claude 2>/dev/null; ls -la .claude/skills 2>/dev/null; git -C . log --oneline -3 2>/dev/null; git -C . status 2>/dev/null | head
running ls -la /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation/*; ls /hom...
running cat /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation/SKILL.md; echo "=================== GUIDE"; cat /home/ubuntu/guava-retrying-2026112...
running cat /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation/phases/01-investigation.md
running cat /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation/phases/02-reproduction.md
running cat /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation/references/persistent-findings.md
Skill 已读完（guide + 两个 phase + persistent-findings）。下面按流程走：先做 persistent-findings lookup，再做 Phase 1 代码审计。
running which specular; OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; ls -la $OUT; ls -la...
running ls /home/ubuntu/guava-retrying-20261126/Specular/ ; ls /home/ubuntu/guava-retrying-20261126/Specular/bin 2>/dev/null; find /home/ubuntu/guava-retrying-202611...
running head -40 /home/ubuntu/guava-retrying-20261126/Specular/specular; cat /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/gua...
running SP=/home/ubuntu/guava-retrying-20261126/Specular/specular; OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-ret...
Persistent-findings lookup 为空（`[]`），没有可复用记录。进入 Phase 1 代码审计。
running WT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-17/worktree; cd $WT...
reading /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-17/worktree/src/main/java/com/github/rhold...
running WT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-17/worktree; cd $WT...
running which gh && timeout 30 gh auth status 2>&1 | head -5; timeout 30 gh api repos/rholder/guava-retrying --jq '.full_name + " open_issues=" + (.open_issues_count...
running cd /tmp; for q in "exceptionWait" "negative" "IllegalArgumentException" "timeout value is negative" "exceptionalWait" "ExceptionWaitStrategy" "Retry-After" "...
running mkdir -p /tmp/crd17-upstream && cd /tmp/crd17-upstream && timeout 120 gh api --paginate "repos/rholder/guava-retrying/issues?state=all&per_page=100" > issues...
running python3 -I -c ' import json,re raw=open("/tmp/crd17-upstream/issues.json").read() dec=json.JSONDecoder(); i=0; items=[] while i < len(raw): while i < len(raw...
running cd /tmp/crd17-upstream; for n in 24 25 26 63 101 107 100; do echo "################ #$n"; timeout 40 gh api repos/rholder/guava-retrying/issues/$n --jq '"tit...
running cd /tmp/crd17-upstream; for n in 101 107 95; do echo "######## PR #$n"; timeout 40 gh api repos/rholder/guava-retrying/pulls/$n --jq '"merged=" + (.merged|to...
running cd /tmp/crd17-upstream; timeout 40 gh api repos/rholder/guava-retrying/pulls/95/files --jq '.[] | select(.filename|test("WaitStrategies.java")) | .patch' 2>&...
running cd /tmp/crd17-upstream; for r in rhuffman/re-retrying itning/guava-retrying3; do echo "=== $r"; timeout 40 gh api "repos/$r" --jq '.full_name+" pushed="+.pus...
running cd /tmp/crd17-upstream; for q in "exceptionWait negative" "exceptionWait IllegalArgumentException" "guava-retrying \"timeout value is negative\"" "WaitStrate...
running cd /tmp/crd17-upstream; for r in rhuffman/re-retrying itning/guava-retrying3; do echo "=== $r"; p=$(timeout 40 gh api "repos/$r/git/trees/HEAD?recursive=1" -...
running cd /tmp/crd17-upstream; sed -n 388,400p rhuffman_re-retrying_WaitStrategies.java; ls -la; r=itning/guava-retrying3; timeout 40 gh api "repos/$r/git/trees/HEA...
running cd /tmp/crd17-upstream; r=itning/guava-retrying3; for f in ExceptionWaitStrategy CompositeWaitStrategy; do timeout 40 gh api "repos/$r/contents/src/main/java...
running ls ~/.m2/repository/com/google/guava/guava/ 2>/dev/null; ls ~/.m2/repository/com/google/code/findbugs/jsr305/ 2>/dev/null; ls ~/.m2/repository/junit/junit 2>...
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; sed -n 1,200p $OUT/harness/pom.xml...
running WT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-17/worktree; cd $WT...
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-17/investigation.md
running WT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-17/worktree; cd $WT...
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/test_bugCR-D-17_exception_wait_negative_sleep.sh
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output && chmod +x repro/test_bugCR-D-17_exc...
Level 0 一次复现成功：7/7 触发，5 个对照全部正常。再跑一遍确认确定性，然后看 `specular findings validate` 的 schema，准备写 `issue.json`。
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output && timeout 5m bash repro/test_bugCR-D...
running cd /home/ubuntu/guava-retrying-20261126/Specular/src/specular; grep -rln "def.*validate\|\"validate\"" . | head; grep -rn "required\|REQUIRED_FIELDS\|\"cause...
running cd /home/ubuntu/guava-retrying-20261126/Specular/src/specular; grep -n "def _validate_proposal\|def validate\|def _proposal\|_REQUIRED\|required =\|\"title\"...
running cd /home/ubuntu/guava-retrying-20261126/Specular/src/specular; sed -n 340,480p persistent_findings.py; grep -n "^LIVE\|LIVE =" persistent_findings.py; sed -n...
running SRC=/home/ubuntu/scratch/guava-retrying-src/guava-retrying; WT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-ret...
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-17/issue.json
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; python3 -I -c 'import json,sys; d=j...
`issue.json` 校验通过（`"valid": true`）。最后清理临时目录，并核对产出文件。
running rm -rf /tmp/crd17-upstream; OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; ls -la...
CR-D-17 在 Level 0 复现成功：只用公开 API、默认配置、未修改的 v2.0.0 源码，两次运行都是 7/7 触发、5 个对照全部正常。上游 issue/PR（含最近关闭的）和两个主要 fork 里都没有这个机制的报告，判为 NEW。

- **Severity**: Medium
- **Source**: Code Review
- **Novelty**: NEW
- **Location**: src/main/java/com/github/rholder/retry/WaitStrategies.java:390
- **Reproduction test**: `repro/test_bugCR-D-17_exception_wait_negative_sleep.sh`（Level 0；日志 `repro/CR-D-17.log`、`repro/CR-D-17.run2.log`）

## Description
`WaitStrategies.exceptionWait`（`WaitStrategies.java:211-216`）构造的 `ExceptionWaitStrategy.computeSleepTime`（`:386-394`）在 `:390` 原样返回用户 function 的值，不钳到 `>= 0`。其他按次计算等待时间的内建策略都会钳位（`:283`、`:305-308`、`:330-334`）。

`Retryer.call` 不做校验，直接把这个值交给默认的 `ThreadSleepStrategy`（`Retryer.java:176-178` → `BlockStrategies.java:46`）。`Thread.sleep(负数)` 抛出 `IllegalArgumentException: timeout value is negative`，而 `Retryer.java:179` 只捕获 `InterruptedException`，所以这个异常直接逃出 `call()`。

`call()` 的 Javadoc（`Retryer.java:140-154`）只承认三种结局：返回结果、`ExecutionException`、`RetryException`。实际表现是：重试在第 1 次尝试后就放弃了，尽管 stop 策略还允许继续。

放进 `join`（`CompositeWaitStrategy`，`:364-371`）时，负值会直接计入总和：要么把其他策略配置的等待砍短，要么让总和变负，抛出同一个 IAE。

## Trigger scenario
只用公开 API，block 策略保持默认：
```java
Retryer<String> r = RetryerBuilder.<String>newBuilder()
    .retryIfExceptionOfType(RetryAfterException.class)
    .withWaitStrategy(WaitStrategies.exceptionWait(RetryAfterException.class,
        e -> e.retryAtMillis - System.currentTimeMillis()))   // 等到服务端给的重试时刻
    .withStopStrategy(StopStrategies.stopAfterAttempt(5))
    .build();
r.call(callable);   // 第 1 次抛出 RetryAfterException，retryAt 已经过去；第 2 次会返回 "ok"
```
服务端给的绝对重试时刻（HTTP `Retry-After: <HTTP-date>`、`X-RateLimit-Reset` 等）在客户端时钟上已经过去时，function 就会返回负值。常见原因有三个：
- 客户端与服务端的时钟偏差；
- 网络或处理延迟；
- HTTP-date 只有 1 秒精度。

以 1 秒精度为例：即使时钟完全同步，`Retry-After = now+1s` 截断到整秒后，算出的值是 `1000 - (s mod 1000) - latency`，约有 latency/1000 的概率为负。这一条是推算，本次没有单独测。

复现 [6] 用真实 HTTP 演示了这条路径：本地 `HttpServer` 返回 503 和 RFC 9110 格式的 `Retry-After` HTTP-date，客户端在 callable 里解析。服务端时钟慢 2 s 时，function 返回 −1010 ms，重试被放弃。

## Developer intent
- **文档**：`exceptionWait` 的 Javadoc（`:202-210`）只说 function "determines how the sleep time should be calculated"，没有符号约束，也没有 `@throws`。`WaitStrategy.computeSleepTime` 的契约是 "the time, in milliseconds, to sleep before retrying"。
- **内建策略的惯例**：
  - 常量参数在构造时校验：`fixedWait` `:237`、`randomWait` `:254-255`。
  - 按次计算的值钳到 0。`incrementingWait` 甚至不校验负的 `increment`，结果再钳到 0（`:283`，2012 年原始代码 `6d2d838` 就有）；Fibonacci 的溢出处理来自 `ce0bc7d`。
  - 复现 [2] 证明，在同一条 `Retryer` + 默认 block 路径上，内建的钳位确实生效。
- **历史**：引入该策略的提交是 `9c6bd63`（上游 PR #24/#26，issue #25），之后的 `dbe616d` 只是重命名。维护者的评论没有涉及值域。附近没有 TODO/FIXME/"by design" 注释。
- **测试**：`WaitStrategiesTest.testExceptionWait`（`:157-168`）只覆盖了 0、3 600 000、29 和异常类型不匹配的情况，没有负值，也没有端到端的 `call()` 测试。测试里自带的 `RetryAfterException` 说明，由服务端指导重试正是这个功能的目标用法。
- **Novelty 检索**（2026-11-26）：
  - 用 `gh search` 在 rholder/guava-retrying 里搜了 10 组关键词，没有相关结果。
  - 全量拉取上游 106 个 issue/PR，对标题和正文做 grep，没有报告这个机制的条目。
  - 最近关闭的 PR：#107 于 2026-09-05 关闭且 `merged=false`；#84 只改了 README。
  - 未合入的 PR：#101 只跳过 `sleepTime == 0`；#95 不涉及 `ExceptionWaitStrategy`。
  - GitHub 全站 issue 搜索没有结果。
  - fork `rhuffman/re-retrying` 和 `itning/guava-retrying3` 的 tracker 里也没有报告，两者至今仍原样透传。

## Reproduction result
Level 0：只用公开 API，不打 failpoint，不做时序辅助，不改源码。库从 worktree `177b6c9`（`v2.0.0-1-g177b6c9`，0 个 dirty 文件）编译，配方为 Guava 22.0、jsr305 2.0.2、`--release 8`，运行在 JDK 21 上。

运行命令：`cd .specular-output && timeout 5m bash repro/test_bugCR-D-17_exception_wait_negative_sleep.sh`，退出码 0。第二次运行（run2）结果相同：7/7 触发，0/5 对照失败。第一次运行的输出：
```
[1] exceptionWait(retryAt - now); server retry time already 250 ms in the past; stopAfterAttempt(5)
    expected (call() Javadoc + the clamp-to-0 convention of the other built-ins): retry at once, return "ok" on invocation 2
    callable invocations = 1 (stop strategy allows 5), call() took 15 ms
    user function returned -259 ms; ExceptionWaitStrategy.computeSleepTime(attempt#1) now returns -266 (passed through, no clamp)
    call() outcome: java.lang.IllegalArgumentException: timeout value is negative
        at java.base/java.lang.Thread.sleep(Thread.java:500)
        at com.github.rholder.retry.BlockStrategies$ThreadSleepStrategy.block(BlockStrategies.java:46)
        at com.github.rholder.retry.Retryer.call(Retryer.java:178)
        at ReproCRD17.outcome(ReproCRD17.java:103)
    >>> BUG TRIGGERED: undocumented IllegalArgumentException escaped Retryer.call after 1 of 5 permitted attempts
[1-determinism] same scenario, 50 fresh calls
    IllegalArgumentException(Thread.sleep) = 50/50, returned ok = 0, other = 0
    >>> BUG TRIGGERED: deterministic: 50/50 calls aborted with IllegalArgumentException
[1-control] identical configuration, server retry time 300 ms in the future
    control OK: returned "ok" on invocation 2 after waiting 300 ms (function returned 300)
[2] library convention on the SAME Retryer/default-block path: incrementingWait(0 ms, increment -250 ms) also computes negative sleeps
    control OK: negative computed sleeps clamped to 0 by the built-in; call() returned "ok" on invocation 4
[3] consumer written exactly like README.md:44-50 (catch RetryException / catch ExecutionException), on its own thread
    handled by: <nothing>; thread terminated by uncaught: java.lang.IllegalArgumentException: timeout value is negative
    >>> BUG TRIGGERED: neither documented handler ran; the consumer thread died with an uncaught IllegalArgumentException
[4] Retryer.wrap(callable) submitted to an ExecutorService (RetryerCallable.call -> Retryer.call)
    future outcome: ExecutionException caused by java.lang.IllegalArgumentException: timeout value is negative
        at java.base/java.lang.Thread.sleep(Thread.java:500)
        at com.github.rholder.retry.BlockStrategies$ThreadSleepStrategy.block(BlockStrategies.java:46)
        at com.github.rholder.retry.Retryer.call(Retryer.java:178)
        at com.github.rholder.retry.Retryer$RetryerCallable.call(Retryer.java:318); invocations = 1
    >>> BUG TRIGGERED: Future failed with IllegalArgumentException instead of "ok" / RetryException
[5] join(fixedWait(400 ms), exceptionWait(retryAt - now)) — Javadoc: wait is the total of all wait times
    retry time 250 ms in the past: exceptionWait part = -250 ms; outcome = ok; measured wait between attempts = 150 ms (fixedWait alone is 400 ms; Thread.sleep never undershoots)
    >>> BUG TRIGGERED: the negative component cut the configured 400 ms fixed wait to 150 ms
    retry time 600 ms in the past: exceptionWait part = -600 ms; total ~ -200 ms; invocations = 1; outcome = java.lang.IllegalArgumentException: timeout value is negative
        at java.base/java.lang.Thread.sleep(Thread.java:500)
        at com.github.rholder.retry.BlockStrategies$ThreadSleepStrategy.block(BlockStrategies.java:46)
        at com.github.rholder.retry.Retryer.call(Retryer.java:178)
        at ReproCRD17.outcome(ReproCRD17.java:103)
    >>> BUG TRIGGERED: negative total escaped Retryer.call as IllegalArgumentException
    control OK: retry time 100 ms ahead: waited 500 ms (~400 + 100), returned "ok"
[6] end-to-end over real HTTP: 503 + 'Retry-After: <HTTP-date>' (RFC 9110 10.2.3), client parses it in the callable
    server clock in sync, Retry-After = now+2s: header 'Thu, 26 Nov 2026 10:37:15 GMT', function returned 1314 ms, HTTP requests = 2, outcome = ok
    control OK: in-sync server: waited, retried, got "ok"
    server clock 2 s behind the client, Retry-After = server now+1s: header 'Thu, 26 Nov 2026 10:37:14 GMT', function returned -1010 ms, HTTP requests = 1, outcome = java.lang.IllegalArgumentException: timeout value is negative
        at java.base/java.lang.Thread.sleep(Thread.java:500)
        at com.github.rholder.retry.BlockStrategies$ThreadSleepStrategy.block(BlockStrategies.java:46)
        at com.github.rholder.retry.Retryer.call(Retryer.java:178)
        at ReproCRD17.outcome(ReproCRD17.java:103)
    >>> BUG TRIGGERED: skewed-clock server: retry abandoned after 1 request with IllegalArgumentException

SUMMARY: bug triggers = 7/7, failed controls = 0/5
RESULT: BUG REPRODUCED (Level 0)
```
- **关键行**：[1] 中 function 返回 −259，栈为 `Retryer.call(Retryer.java:178)` → `ThreadSleepStrategy.block(BlockStrategies.java:46)` → `Thread.sleep`，callable 只被调用 1 次（允许 5 次）。这和 finding 声称的路径一致：`exceptionWait` 透传负值 → 默认 block → IAE 逃出 `call()`。
- **正确行为应是**：retry 时刻已经过去时立即重试并返回 `"ok"`，这与 [1-control] 和 [2] 中内建策略的钳位惯例一致；`join` 的等待应 ≥ 400 ms。

## Recommendation
- **主修复**：在 `ExceptionWaitStrategy.computeSleepTime` 中写成 `long v = function.apply((T) cause); return v >= 0L ? v : 0L;`，与 incrementing、exponential、Fibonacci 的做法一致，并在 `exceptionWait` 的 Javadoc 中写明"负值视为不等待"。
- **防御性修复**：`CompositeWaitStrategy` 的结果钳到 0（同时处理 long 溢出），或在 `Retryer.call` 调用 `block` 前取 `Math.max(0L, sleepTime)`，这样即使 strategy 返回负值，也不会把 `IllegalArgumentException` 泄漏出 `call()`。
- **补测试**：
  - `exceptionWait` 在负值时 `computeSleepTime == 0`；
  - 端到端的 `call()` 遇到负值时会重试并返回结果；
  - `join(fixedWait(400), exceptionWait(-250))` 的等待 ≥ 400 ms。
- **用户侧临时规避**：在 function 内部写 `Math.max(0L, retryAt - now)`。

### REPRODUCED checklist
1. **Level 0 或 Level 1 单独触发了吗？yes。** 是 Level 0：只用公开 API（`RetryerBuilder`、`WaitStrategies.exceptionWait/join/fixedWait`、`StopStrategies.stopAfterAttempt`、`Retryer.call/wrap`），默认 block 策略，没有时序辅助，也没有改源码。
2. 不适用：没有用 Level 2/3。
3. **哪些真实调用方看到了错误结果：**
   - 按 README.md:44-50 写法调用 `Retryer.call` 的代码：两个文档化的 catch 都没有执行，线程因未捕获的 IAE 退出（[3]）。
   - `Retryer$RetryerCallable.call`（`Retryer.java:316-319`）经 executor 执行：`Future.get()` 得到 `ExecutionException(cause=IllegalArgumentException)`（[4]）。
   - `Retryer.call` 自身的重试循环（`Retryer.java:173-182`）：5 次只用了 1 次；在 `join` 里，配置的 400 ms 退避实际只等了 150 ms（[5]）。
4. **错误状态是否永久：是永久的。** IAE 终结了这次 `call()`，库内没有任何机制去捕获、重试或补偿（`Retryer.java:179` 只捕获 `InterruptedException`），callable 也不会再被调用（invocations = 1）。默认配置下没有任何 mask。只有用户自定义一个容忍负值的 `BlockStrategy`、或在 function 里自己钳位，才能避开这个 IAE；但这两样都不是库提供的保护，也不是默认行为，而且 `join` 把等待砍短的问题在那种情况下依然存在。

`issue.json` 已写入 `confirmation/CR-D-17/`，`specular findings validate` 通过；Phase 1 证据在 `confirmation/CR-D-17/investigation.md`。

---

## Entry 19: `exceptionWait` with a function that returns `null` makes `call()` throw `NullPointerException` from auto-unboxing

- **Finding ID**: CR-D-18
- **Status**: REPRODUCED
- **Debate**: not run
- **Transcript**: /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-18/debate.md

running ls -la /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-18/ ; echo ---;...
running ls -la /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation/* ; echo -...
running find / -path /proc -prune -o -type d -name "bug-confirmation" -path "*claude*" -print 2>/dev/null | head; find ~/.claude -maxdepth 4 -iname "*bug-confirmatio...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-18/ && grep -n -i "...
Now reading the skill in full.
running S=/home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; cat $S/SKILL.md; echo; echo "=========== guide.md"; cat $S/guide.md
running S=/home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; cat $S/phases/01-investigation.md
running S=/home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; cat $S/phases/02-reproduction.md
running S=/home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; cat $S/references/persistent-findings.md
running S=/home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; cat $S/references/repair-request-format.md
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-18/worktree; cd $W &...
running which specular; specular --help 2>&1 | head -30; ls -la /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/....
running cat /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/persistent-findings-context.json; ec...
running cd /home/ubuntu/guava-retrying-20261126/Specular && file specular && head -20 specular; ls .venv 2>/dev/null | head; ls -la .venv/bin/specular 2>/dev/null
开始执行 CR-D-18 的确认流程：已读完 skill（guide + Phase 1/2 + references），现在先做 persistent-findings 轻量查重，再进入代码审计。
running cd /tmp && SP=/home/ubuntu/guava-retrying-20261126/Specular/specular; OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-2026112...
Persistent registry 无匹配记录。进入 Phase 1 代码审计。
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-18/worktree; cat -n...
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-18/worktree; grep -n...
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-18/worktree; cd $W;...
running ls ~/.m2/repository/com/google/guava/guava/ 2>/dev/null; ls ~/.m2/repository/com/google/guava/guava/22.0/ 2>/dev/null; ls ~/.m2/repository/com/google/code/fi...
running cd /tmp && mkdir -p /tmp/crd18-javap && cd /tmp/crd18-javap && javap -v -cp ~/.m2/repository/com/google/guava/guava/22.0/guava-22.0.jar com.google.common.bas...
running cd /tmp/crd18-javap && for v in 10.0.1 14.0.1 16.0.1; do J=$(ls ~/.m2/repository/com/google/guava/guava/$v/*.jar 2>/dev/null | grep -v sources | head -1); ec...
running cd /tmp/crd18-javap && javap -v -cp ~/.m2/repository/com/google/guava/guava/10.0.1/guava-10.0.1.jar com.google.common.base.Function 2>&1 | grep -A14 "apply(F)"
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-18/worktree; cd $W;...
running cd /tmp && timeout 30 gh auth status 2>&1 | head -5; timeout 60 gh api "repos/rholder/guava-retrying" --jq '{full_name, open_issues_count, pushed_at, archive...
running cd /tmp && for q in "exceptionWait" "ExceptionWaitStrategy" "NullPointerException" "unboxing" "computeSleepTime" "exceptionalWait" "wait strategy null" "Wait...
running mkdir -p /tmp/crd18-upstream && cd /tmp/crd18-upstream && timeout 120 gh api --paginate "repos/rholder/guava-retrying/issues?state=all&per_page=100" > issues...
running cd /tmp/crd18-upstream && python3 -I -c " import json,re raw=open('/tmp/crd18-upstream/issues_all.json').read().replace('][', ',') items=json.loads(raw) pat=...
running cd /tmp/crd18-upstream && for n in 24 25 26; do echo "===== #$n comments"; timeout 60 gh api --paginate "repos/rholder/guava-retrying/issues/$n/comments?per_...
running cd /tmp/crd18-upstream && timeout 60 gh api "repos/rholder/guava-retrying/commits?per_page=15" --jq '.[] | "\(.sha[0:7]) \(.commit.author.date[0:10]) \(.comm...
running cd /tmp/crd18-upstream && for n in 107 95; do echo "===== PR #$n WaitStrategies.java / Retryer.java patch (exception-wait related hunks)"; timeout 60 gh api...
running cd /tmp/crd18-upstream && grep -n -i -E "exception(al)?Wait|ExceptionWaitStrategy|function\.apply|apply\(" pr107.patch | head -20; echo; timeout 60 gh api "r...
running ls /home/ubuntu/guava-retrying-20261126/Specular/case-studies/ 2>/dev/null | head -80; grep -r -l -i "guava-retrying\|guava_retrying\|exceptionWait" /home/ub...
running cd /tmp/crd18-upstream && for q in "exceptionWait null" "exceptionWait NullPointerException" "ExceptionWaitStrategy NullPointerException"; do echo "=== globa...
running cd /tmp/crd18-upstream && timeout 60 gh api "repos/specular-org/specula-case-studies/contents" --jq '.[] | .name' 2>&1 | head -80 | tr '\n' ' '; echo; timeou...
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-18/worktree; cd $W;...
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-18/investigation.md
Phase 2：写 Level 0（纯公共 API）复现测试。
running R=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro; ls -d $R; ls $R | grep -c . ; l...
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-18/worktree; cd $W;...
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/test_bugCR-D-18_exceptionwait_null_npe.sh
running R=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro; chmod +x $R/test_bugCR-D-18_exc...
running R=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro; cd /tmp; LOG=$R/CR-D-18.log; {...
4/4 次运行全部确定性复现。接下来按 persistent-findings 格式写 `issue.json`，先看一下 validator 的 schema 要求。
running cd /home/ubuntu/guava-retrying-20261126/Specular && grep -rn "def validate\|\"validate\"\|'validate'" src/specular/ 2>/dev/null | head; ls src/specular/ | he...
running cd /home/ubuntu/guava-retrying-20261126/Specular && sed -n '300,560p' src/specular/persistent_findings.py
running cd /home/ubuntu/guava-retrying-20261126/Specular && grep -n "def _dependency_bytes\|def _id\|def _path\|def context\|def _strings\|def _text\|^LIVE\|^DIRECTO...
running SRC=/home/ubuntu/scratch/guava-retrying-src/guava-retrying; W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retr...
running SRC=/home/ubuntu/scratch/guava-retrying-src/guava-retrying/src/main/java/com/github/rholder/retry; python3 -I - "$SRC" <<'PY' import sys src=sys.argv[1] chec...
All boundaries are unique. Writing `issue.json` and running the validator.
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-18/issue.json
running cd /tmp && OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; timeout 120 /home/ubuntu...
Validator 通过（`valid: true`，title 143 字符）。最后确认 worktree 未被改动。
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-18/worktree; git -C...
running cat /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/CR-D-18.log
# CR-D-18 确认结果

- **Source**: Code Review
- **Novelty**: NEW
- **Location**: src/main/java/com/github/rholder/retry/WaitStrategies.java:390
- **Severity**: Medium
- **Reproduction test**: `.specular-output/repro/test_bugCR-D-18_exceptionwait_null_npe.sh`，在 Level 0 复现；运行日志在 `.specular-output/repro/CR-D-18.log`
- **Persistent record**: `confirmation/CR-D-18/issue.json`，`specular findings ... validate` 结果为 `"valid": true`。Phase 1 证据记录在 `confirmation/CR-D-18/investigation.md`

## Description
`ExceptionWaitStrategy.computeSleepTime` 直接把 `function.apply((T) cause)`（类型为 `Long`）当作 `long` 返回（`WaitStrategies.java:390`），编译器会在这里插入 `Long.longValue()`。Guava 22.0 的 `Function.apply` 返回值带 `@javax.annotation.Nullable`（已用 `javap -v` 确认），用户函数返回 `null` 是合法的。函数一旦返回 `null`，这里就会抛出 `NullPointerException`。

`Retryer.call` 在 `Retryer.java:176` 调用 `waitStrategy.computeSleepTime(attempt)`，这一行不在 attempt 的 try/catch 内。它外面唯一的 try 只包住 `blockStrategy.block`，而且只捕获 `InterruptedException`。所以这个 NPE 会在 attempt 执行之后直接抛出 `call()`。`call()` 的 Javadoc（`Retryer.java:140-154`）只写了三种结局：返回值、`ExecutionException`、`RetryException`，NPE 不在其中。

## Trigger scenario
1. 用以下配置构建 Retryer：`retryIfExceptionOfType(IOException.class)`、`stopAfterAttempt(3)`、`exceptionWait(HttpStatusException.class, e -> e.getRetryAfterMillis())`。HTTP 的 `Retry-After` header 是可选的，header 缺失时这个函数返回 `null`。
2. callable 第一次抛出 HTTP 503（没有 `Retry-After`），第二次会成功。
3. 按文档，第 2 次 attempt 应该返回 `"OK"`。同一个 Retryer 在 429 带 header 的情况下确实返回了 `"OK"`。
4. 实际结果：attempt #1 执行完、listener 也收到通知之后，`call()` 抛出 NPE。callable 只被调用了 1 次，NPE 的 `getCause()` 为 `null`，原始的 503 异常丢失。

另外两条路径同样会触发：
- `join(fixedWait, exceptionWait(map::get 未命中))` 配合 `neverStop()`。
- `wrap()` 后提交给 `ExecutorService`：`Future.get()` 抛出的 `ExecutionException` 的 cause 是 NPE，而不是 `RetryException`。

## Developer intent
- **代码历史**：该策略由 `9c6bd63`（2014，PR #24/#26，issue #25）引入，当时就直接拆箱。`dbe616d`（2015-06-21，"suppress warnings"）在这个方法上加了 `@SuppressWarnings({"ThrowableResultOfMethodCallIgnored", "ConstantConditions", "unchecked"})`。在这个方法里，`ConstantConditions` 唯一可能针对的就是对 `@Nullable` 返回值拆箱的告警。也就是说维护者见过静态告警，选择了压制，但没有加防护。这只说明他们知道有告警，并不是已提交的报告。
- **文档**：`exceptionWait` 的 Javadoc 没有禁止 `null`，也没有任何 `@throws`。
- **测试**：`WaitStrategiesTest.testExceptionWait` 只覆盖返回非 null 的函数。
- **查重**：
  - 已检查上游全部 106 条 issue/PR（open 和 closed），包括按 body 做正则搜索。最近关闭的 #107（2026-09-05 关闭，未合并）把 Java 代码整体删掉、改成 PHP 移植，没有报告或修复这个问题；#84 只改了 README。上游 master 仍是 `177b6c9`，没有修复落地。
  - GitHub 全站 issue 搜索、fork `rhuffman/re-retrying`、`specular findings lookup`、Specular case-studies 数据集都没有找到同一机制的报告。

## Reproduction result
运行命令：`timeout 5m bash .specular-output/repro/test_bugCR-D-18_exceptionwait_null_npe.sh`。这是 Level 0：只用公共 API，库源码 `177b6c9` 未修改，用 `--release 8` 和 Guava 22.0 编译。

```
source HEAD : 177b6c9b9f3e7957f404f0bdb8e23374cb1de43f
source dirty: 0 changed file(s) under src/
Retryer.java:176        |                long sleepTime = waitStrategy.computeSleepTime(attempt);
WaitStrategies.java:390 |                    return function.apply((T) cause);
== Scenario 1a (control): HTTP 429 WITH Retry-After: 20 ms, then success
  outcome=RETURNED value=OK | callable invocations=2 | listener saw [#1 threw CRD18Repro$HttpStatusException: HTTP 429, #2 returned OK]
  [CONTROL-OK] same Retryer returns OK on attempt 2 when the function yields a non-null wait
== Scenario 1b (bug): HTTP 503 WITHOUT Retry-After (function returns null), then success
  outcome=ESCAPED java.lang.NullPointerException: Cannot invoke "java.lang.Long.longValue()" because the return value of "com.google.common.base.Function.apply(Object)" is null | callable invocations=1 | listener saw [#1 threw CRD18Repro$HttpStatusException: HTTP 503]
    escaped type   : java.lang.NullPointerException
    message        : Cannot invoke "java.lang.Long.longValue()" because the return value of "com.google.common.base.Function.apply(Object)" is null
    getCause()     : null
    at com.github.rholder.retry.WaitStrategies$ExceptionWaitStrategy.computeSleepTime(WaitStrategies.java:390)
    at com.github.rholder.retry.Retryer.call(Retryer.java:176)
    at CRD18Repro.documentedContractCaller(CRD18Repro.java:84)
    at CRD18Repro.main(CRD18Repro.java:168)
  [BUG-CONFIRMED] call() let an exception escape the documented handlers (not a value / ExecutionException / RetryException)
  [BUG-CONFIRMED] escaped exception is the unboxing NPE raised in ExceptionWaitStrategy.computeSleepTime under Retryer.call
  [BUG-CONFIRMED] attempt #1 had already run and been reported to the listener before the NPE
  [BUG-CONFIRMED] retrying was abandoned after 1 attempt although stopAfterAttempt(3) allowed more and attempt #2 would succeed
  [BUG-CONFIRMED] the attempt's real failure (HttpStatusException: HTTP 503) is not attached to the escaped exception
== Scenario 2a (control): join(fixedWait, exceptionWait(map lookup hit)), neverStop
  outcome=RETURNED value=OK | callable invocations=2
  [CONTROL-OK] joined strategy returns OK on attempt 2 when the lookup hits
== Scenario 2b (bug): same Retryer, IOException("connection reset") -> lookup miss -> null
    at com.github.rholder.retry.WaitStrategies$ExceptionWaitStrategy.computeSleepTime(WaitStrategies.java:390)
    at com.github.rholder.retry.WaitStrategies$CompositeWaitStrategy.computeSleepTime(WaitStrategies.java:368)
    at com.github.rholder.retry.Retryer.call(Retryer.java:176)
  [BUG-CONFIRMED] NPE escapes call() through CompositeWaitStrategy; a neverStop() retryer gave up after 1 attempt
== Scenario 3 (bug): retryer1.wrap(callable) on an ExecutorService, HTTP 503 without Retry-After
  future value=null | future failure cause=java.lang.NullPointerException: Cannot invoke "java.lang.Long.longValue()" because the return value of "com.google.common.base.Function.apply(Object)" is null | callable invocations=1
  [BUG-CONFIRMED] Future fails with the unboxing NPE instead of a RetryException / the callable's exception
RESULT: BUG REPRODUCED -- exceptionWait function returning null makes Retryer.call() throw an undocumented NullPointerException after the attempt ran, abandoning the retry and dropping the failure cause
exit code: 0
```

完整输出见 `repro/CR-D-18.log`。另外连跑 3 次，都是 `BUG REPRODUCED`、exit 0，结果确定。

能证明 bug 的几行是：`outcome=ESCAPED java.lang.NullPointerException`、栈帧 `WaitStrategies.java:390` ← `Retryer.java:176`、`callable invocations=1`、`getCause() : null`。作为对照，同一个 Retryer 在函数返回非 null 时（1a、2a）都按文档在第 2 次 attempt 返回 `OK`。

## Recommendation
在 `ExceptionWaitStrategy.computeSleepTime` 里不要直接拆箱：

```java
Long sleep = function.apply((T) cause);
return sleep == null ? 0L : sleep;
```

这和 Javadoc 里已写明的"不匹配时返回 0"语义一致，也能让重试循环继续执行。同时在 `exceptionWait` 的 Javadoc 里写明 `null` 的含义，并在 `WaitStrategiesTest` 里加一个返回 `null` 的回归用例，覆盖 `Retryer.call` 路径。

如果维护者更想快速失败，至少应该抛出带说明的异常，并把 attempt 的原始异常设为 cause。但那样仍然是 `call()` 文档之外的结局，所以更推荐上面的写法。

## REPRODUCED checklist
1. **是否只靠 Level 0 或 Level 1 触发？是。** Level 0，只用了 `RetryerBuilder`、`WaitStrategies.exceptionWait/join/fixedWait`、`StopStrategies`、`RetryListener`、`Retryer.call`、`Retryer.wrap`。没有加 sleep，没有注入状态，没有改源码。
2. **Level 2/3**：没有用到，不适用。
3. **哪个真实调用方观察到错误结果**：
   - 调用 `Retryer.call` 的应用代码（`Retryer.java:155`）。测试里的 `documentedContractCaller` 按 Javadoc 只处理 `ExecutionException` 和 `RetryException`，NPE 直接越过了这两个 handler。
   - `Retryer.RetryerCallable.call`（`Retryer.java:316-319`）的使用方：通过 `ExecutorService` 拿到的 `Future.get()` 抛出 `ExecutionException(cause=NPE)`。
4. **是永久状态还是会被掩盖？永久，没有被掩盖。**
   - 这次 `call()` 异常终止，重试被放弃：callable 只跑了 1 次，而配置允许 3 次或无限次。
   - 库里没有任何下游机制会重试或转换这个异常：`Retryer.java:176` 周围没有 catch，`CompositeWaitStrategy` 和 `RetryerCallable` 只是往外传。
   - 原始异常无法从 NPE 恢复（`getCause()==null`）。同样输入每次都会触发。

---

## Entry 20: The `int` attempt counter in `Retryer.call` wraps after 2^31-1 attempts: attempt numbers become non-positive, `RetryException` reports the count modulo 2^32, and growing waits collapse to 0

- **Finding ID**: CR-D-19
- **Status**: REPRODUCED
- **Debate**: not run
- **Transcript**: /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-19/debate.md

running ls -la /home/ubuntu/.claude/projects/-home-ubuntu-guava-retrying-20261126-Specular-runs-guava-retrying-opus55max-20261126-guava-retrying--specular-output-con...
running ls -la /home/ubuntu/guava-retrying-20261126/Specular/ 2>/dev/null; echo "---"; ls -la /home/ubuntu/guava-retrying-20261126/Specular/skills/ 2>/dev/null; echo...
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation && find . -type f | sort && echo "---" && wc -l $(find . -type f | sort)
reading /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation/SKILL.md
reading /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation/guide.md
reading /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation/phases/01-investigation.md
reading /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation/phases/02-reproduction.md
reading /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation/references/persistent-findings.md
reading /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation/references/repair-request-format.md
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; ls -la $OUT; echo "---"; ls -la $OU...
Skill 已读完（guide + Phase 1/2 + 两个 reference）。先按 persistent-findings 规则做一次轻量 lookup，然后开始 Phase 1 代码审计。
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; cat $OUT/persistent-findings-contex...
Persistent-findings lookup 为空（无历史记录）。进入 Phase 1：审计源码。
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-19/worktree; cd $W &...
reading /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-19/worktree/src/main/java/com/github/rhold...
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-19/worktree/src/main...
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-19/worktree; cd $W;...
running timeout 60 gh auth status 2>&1 | head -5; echo "---"; timeout 60 gh api repos/rholder/guava-retrying --jq '.full_name, .open_issues_count, .pushed_at, .archi...
running mkdir -p /tmp/crd19 && cd /tmp/crd19 && timeout 120 gh api --paginate "repos/rholder/guava-retrying/issues?state=all&per_page=100" --jq '.[] | [.number, .sta...
running cd /tmp/crd19 && timeout 180 gh api --paginate "repos/rholder/guava-retrying/issues?state=all&per_page=100" --jq '.[] | "### #\(.number) [\(.state)] \(.title...
running cd /tmp/crd19 && awk 'NR>=660 && NR<=700' bodies.txt | grep -n "###" ; grep -n "^### #" bodies.txt | awk -F: '$1<=696' | tail -1; echo "--- PR 107/84/103/95/...
running cd /tmp/crd19 && timeout 90 gh api "repos/rholder/guava-retrying/pulls/107" --jq '"body:\n" + (.body // "") + "\ncommits=\(.commits) changed_files=\(.changed...
PR #107 是把整个库改写成 PHP 的无关 PR，不是对该缺陷的报告。再查一下 fork（re-retrying）和 Specular 自带 case-studies 里有没有同机制的先例。
running cd /tmp/crd19; for q in "overflow" "attemptNumber" "Integer.MAX_VALUE" "negative attempt"; do echo "== re-retrying issues: $q"; timeout 60 gh search issues "...
running cd /tmp/crd19; timeout 60 gh api repos/rhuffman/re-retrying/issues/27 --jq '"#\(.number) [\(.state)] \(.title)\ncreated=\(.created_at) closed=\(.closed_at) b...
running cd /tmp/crd19; timeout 60 gh api repos/rhuffman/re-retrying/commits/fef672fa5c3c579707c35c2afa130cc13290b60b --jq '"\(.sha[0:10]) \(.commit.author.date) \(.c...
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; ls -la $OUT/harness; echo "---"; ls...
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; grep -n -E "artifactId|version|rele...
Phase 1 证据齐了，先写 `investigation.md`（只记录事实，不下结论）。
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-19/investigation.md
running set -e; F=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-19; S=$F/scr...
running ls /home/ubuntu/guava-retrying-20261126/Specular/scripts/infra/ 2>/dev/null; echo "---"; sed -n 1,60p /home/ubuntu/guava-retrying-20261126/Specular/scripts/i...
`start_background.sh` 是 TLC 专用的；我会用 `nohup` 启动复现脚本并写 PID 文件，再用 `wait_for_pid.sh` 分段阻塞等待。现在写复现测试。
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/test_bugCR-D-19_attempt_counter_int_wrap.sh
先修一个小问题（B2 在 `e == null` 时拼字符串会 NPE），然后用快速场景（P0 对照 + C4）验证脚本本身能编译运行。
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/test_bugCR-D-19_attempt_counter_int_wrap.sh
running cd /tmp && SCENARIOS="P0 C4" timeout 300 bash /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-o...
running cd /tmp && SCENARIOS="C1" timeout 580 bash /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-outp...
running R=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro; cd /tmp && nohup setsid bash -c...
完整运行已在后台开始（PID 1794581）。等待期间先查 `specular findings` 的 issue.json 校验规则，以便写持久化记录。
running cd /home/ubuntu/guava-retrying-20261126/Specular && grep -rln "def.*validate\|persistent" src --include=*.py | head -20; echo "---"; grep -rn "\"title\"\|max...
running cd /home/ubuntu/guava-retrying-20261126/Specular && sed -n 330,470p src/specular/persistent_findings.py
running SRC=/home/ubuntu/scratch/guava-retrying-src/guava-retrying; W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retr...
注册表的 source root 与 worktree 同一提交、同一内容。B1 正在跑。先核对 issue.json 依赖区间的起止行在各文件中唯一且逐字匹配。
running SRC=/home/ubuntu/scratch/guava-retrying-src/guava-retrying/src/main/java/com/github/rholder/retry; chk() { local f="$1"; shift; for l in "$@"; do n=$(grep -c...
所有边界行都唯一。现在阻塞等待后台运行（每次最多 9 分钟）。
running R=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro; /home/ubuntu/guava-retrying-202...
running ls -d /tmp/crd19-repro.*/ 2>/dev/null; for d in /tmp/crd19-repro.*/; do [[ -f $d/A.out ]] && { echo "== $d"; cat $d/A.out; }; done; ps -eo pid,etime,pcpu,cmd...
场景 A 实测 6.05e5 次/秒，预计约 11:51 UTC 到达目标（还需约 50 分钟）。等待期间先写持久化记录 `issue.json` 并做一次预校验。
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-19/issue.json
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; python3 -c "import json,sys; d=json...
预校验通过（title 157 字符）。继续阻塞等待场景 A。
running R=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro; /home/ubuntu/guava-retrying-202...
场景 A 速率稳定在约 6.08e5 次/秒，已到 12.8 亿次，预计 11:51 UTC 前后越过回绕点。
running R=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro; /home/ubuntu/guava-retrying-202...
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; rm -f $OUT/repro/CR-D-19.log.pid; l...
## CR-D-19 确认结论：REPRODUCED

`Retryer.call` 用 `int` 记录尝试次数，超过 2^31-1 次后会回绕。我只用公开 API、不改源码（Level 0）把它跑了出来，其中一个场景用的是纯 builder 默认配置。不过 finding 里"增长型等待塌缩为 0"这条子论断，实际只有一半能到达，见下文的子论断表。

- **Source**: Code Review
- **Novelty**: NEW
- **Location**: `src/main/java/com/github/rholder/retry/Retryer.java:157`
- **Severity**: Medium。只看计数和 attempt number 出错是 Low；但同一个回绕会让内置的递减 `incrementingWait` 一次睡 248.6 天（场景 C1），所以定 Medium。
- **Reproduction test**: `repro/test_bugCR-D-19_attempt_counter_int_wrap.sh`，完整输出在 `repro/CR-D-19.log`（脚本 exit 0）。
- **Persistent record**: `confirmation/CR-D-19/issue.json`，`specular findings validate` 结果为 `valid: true`。

## Description
`Retryer.java:157` 的 `for (int attemptNumber = 1; ; attemptNumber++)` 没有任何溢出保护。这个值会写进 `ResultAttempt` / `ExceptionAttempt` 的 `long attemptNumber`（`:161`、`:163`），也会写进 `RetryException` 的 `int numberOfFailedAttempts`（`:174`、`:181`，以及 `RetryException.java:34,44-46`）。而 `Attempt.getAttemptNumber()` 的文档写的是 "The number, starting from 1"（`Attempt.java:73-78`）。

一次 `call()` 里失败超过 2^31-1 次后：
- 监听器和各个策略拿到的 attempt number 变成负数或 0，过了 2^32 次又从 1 开始；
- `getNumberOfFailedAttempts()` 和异常 message 报的是 `(int)` 截断后的值。

## Trigger scenario
1. 停止策略不按次数停：`neverStop`（builder 默认）、`stopAfterDelay` 或自定义策略都可以。`stopAfterAttempt(int)` 因为上限本身是 `int`，到不了回绕点。
2. rejection predicate 一直拒绝，比如轮询一个始终不满足的条件。
3. 用 builder 默认配置（`noWait` + `Thread.sleep(0)`），本机约 6.1e5 次/秒，58.7 分钟就到回绕点。
4. 调用结束有两种方式：`stopAfterDelay` 正常停止，或者其他线程中断（例如 `executor.shutdownNow()`）。两种都会抛出计数错误的 `RetryException`。

## Developer intent
- **代码历史**：`int` 计数器和 `RetryException` 的 `int` 都来自 2012 年的 `6d2d838b`。`long getAttemptNumber()` 是 2015 年 `1e7f2bdc` 加的，提交说明是 "allow us to build even more elaborate stop and wait strategies"。没有任何注释提到上限。
- **测试**：`WaitStrategiesTest` 只测到 `failedAttempt(Integer.MAX_VALUE, …)`。监听器测试用 `Map<Long, Attempt>` 按 attempt number 存值，说明期望编号唯一且从 1 开始。
- **上游**：rholder/guava-retrying 全部 106 个 issue/PR（含 2026 年关闭的 #84、#107）及其评论都没有报告过这个问题。#107 是把整个库改写成 PHP，与此无关。
- **Fork**：`rhuffman/re-retrying#27` 认为"重试超过 `Integer.MAX_VALUE` 次没有意义"，于是把 getter 改成了 `int`。这是设计判断，没有报告也没有修复回绕，所以不算 KNOWN。
- 完整记录在 `confirmation/CR-D-19/investigation.md`。

## Reproduction result
**怎么跑的：**
- 运行命令：`timeout 4h bash repro/test_bugCR-D-19_attempt_counter_int_wrap.sh > repro/CR-D-19.log`
- 构建：未修改的 `177b6c9` 源码（`git status` 干净），`javac --release 8` + Guava 22.0 + jsr305 2.0.2，与 harness `pom.xml` 的配方一致。
- 场景 A：纯 builder 默认配置。
- 场景 B1、B2、C1：额外接了一个用户 `BlockStrategy`，大于 0 ms 时调用 `Thread.sleep`，等于 0 时只检查中断，行为符合接口 Javadoc，只是省掉 `sched_yield`，用来提速。
- 对照组 P0：`[P0] CONTROL OK (expected count 3, listener numbers 1..3)`

**场景 A（纯默认配置）：**
```
[A] reached 2,152,529,920 attempts after 3522.1 s (6.112e+05 attempts/s)
[A] RetryException.getNumberOfFailedAttempts() = -2,142,427,672
[A] RetryException.getMessage() = "Retrying failed to complete successfully after -2142427672 attempts."
[A] actual failed attempts (listener long counter) = 2,152,539,624 ; (int) actual = -2,142,427,672 ; actual - reported = 4,294,967,296
[A] listener: getAttemptNumber() matched the real index for attempts 1..2,147,483,647; first mismatch at real attempt 2,147,483,648: getAttemptNumber() = -2,147,483,648
[A] listener: getAttemptNumber() == (long)(int) realIndex for every attempt: true
```

**场景 B1（`neverStop`，中断结束，计数被模 2^32）：**
```
[B1] RetryException.getNumberOfFailedAttempts() = 144,727,207
[B1] actual failed attempts (listener long counter) = 4,439,694,503 ; (int) actual = 144,727,207 ; actual - reported = 4,294,967,296
[B1] listener: real attempt 4,294,967,296 -> getAttemptNumber() = 0
[B1] listener: real attempt 4,294,967,297 -> getAttemptNumber() = 1
[B1] largest attempt number any listener/strategy ever saw: 2,147,483,647 although 4,439,694,503 attempts were made
```

**场景 B2（内置 `stopAfterDelay` 正常停止）：**
```
[B2] RetryException.getNumberOfFailedAttempts() = -916,908,789
[B2] actual failed attempts (listener long counter) = 3,378,058,507 ; (int) actual = -916,908,789 ; actual - reported = 4,294,967,296
```

**场景 C1（`incrementingWait(50 ms, -10 ms)`，递减等待）：**
```
[C1] 5 s later: attempts 2,147,483,648 -> 2,147,483,648; worker state TIMED_WAITING, top frame java.base/java.lang.Thread.sleep0(Native Method)
[C1] positive sleep requests: 6; last one: 21,474,836,540 ms (= 248.6 days) requested after real attempt 2,147,483,648
```

**场景 C2（Level 1，用只记录不睡眠的 `BlockStrategy` 做虚拟时钟）：**
```
[C2] before the wrap: 2,147,483,647 positive and 0 zero sleep requests, max 2 ms; virtual time slept = 4,294,967,294 ms (= 49.7 days)
[C2] requested sleep after real attempt 2,147,483,647: 2 ms; after 2,147,483,648: 0 ms; after 2,147,483,649: 0 ms
```

**场景 C4（Fibonacci 等待的计算成本）：**
```
[C4] fibonacciWait(10 ms).computeSleepTime(attempt 2,147,483,647) = 10 ms, took 0.587 s (0.27 ns per loop iteration)
[C4] reaching the wrap with fibonacciWait needs sum_{n=1}^{2^31-1} n = 2.306e+18 fib-loop iterations ~ 20 years of CPU in computeSleepTime alone
```

**总结行：**
```
OVERALL: BUG TRIGGERED (int attempt counter wrap observed through the public API)
script exit=0
```

**确认触发的是这个 bug：** 每一次尝试都满足 `getAttemptNumber() == (long)(int) realIndex`，上报值与真实值恰好差 2^32。这正是 `:157` 那个 `int` 截断的特征，然后经 `:161`、`:174`、`:181` 传出去。

**各子论断结果：**

| 子论断 | 结果 |
|---|---|
| attempt number 变成 ≤ 0 | 已复现，Level 0（场景 A、B1、B2、C1） |
| `RetryException` 计数错误 | 已复现，Level 0（A 和 B2 为负数；B1 为模 2^32 后的正数） |
| exponential 等待塌缩为 0 | 只在 Level 1 下看到；真实环境要先睡 ≥ 49.7 天才能到回绕点 |
| Fibonacci 等待塌缩为 0 | 实际不可达（约 20 年 CPU） |
| incrementing 等待（正增量）塌缩为 0 | 实际不可达（总睡眠时间按次数平方增长，仅分析，未运行） |
| 附加：incrementing 等待（负增量） | 已复现，Level 0，回绕时睡 248.6 天 |

## Recommendation
- 把 `Retryer.java:157` 的计数器改成 `long`。两个 `Attempt` 实现本来就存 `long`，改动很小。
- `RetryException` 内部改存 `long`，新增 `long` 构造器和 `long` getter，message 用 `long` 值；保留 `int getNumberOfFailedAttempts()` 以兼容旧代码，但改为饱和转换 `Ints.saturatedCast`。
- 顺带建议：`incrementingWait` 对负增量做校验，或者用饱和算术。
- 补一个回归测试：用空操作的 `BlockStrategy` 跑过 2^31 次，大约 80 秒。

**REPRODUCED 检查清单：**
1. 是否仅靠 Level 0/1 触发？**是**。场景 A 只用了 builder 默认配置、`wrap()` 和 `shutdownNow()`；B1、B2、C1 只用公开 API 加一个符合契约的 `BlockStrategy`。
2. 是否用了 Level 2/3？没有，不适用。C2 是 Level 1，只用来支撑 exponential 那条子论断，不计入结论。
3. 谁观察到错误结果？
   - 捕获 `RetryException` 的调用方：`getNumberOfFailedAttempts()` 和 message（`RetryException.java:44-46,67-69`）读到的值来自 `Retryer.java:174` / `:181`。
   - 用户的 `RetryListener.onRetry`（`Retryer.java:166-168`）收到 ≤ 0 的编号，违反 `Attempt.java:73-78` 的文档。
   - 内置的 `IncrementingWaitStrategy`（`WaitStrategies.java:281-284`）经 `Retryer.java:176-178` 发起 248.6 天的 `Thread.sleep`。
4. 错误状态是否永久？**是**，没有任何下游机制会修正，所以不是 MASKED。
   - `RetryException` 的计数是 `final` 字段；
   - attempt number 过了 2^32 次后虽然又变回正数，但仍然少 2^32；
   - C1 的睡眠除非被中断，会持续 248.6 天。

---

## Entry 21: `incrementingWait` overflows `initial + increment * (n - 1)` for increments near `Long.MAX_VALUE`, alternating sleeps with immediate retries

- **Finding ID**: CR-D-20
- **Status**: REPRODUCED
- **Debate**: not run
- **Transcript**: /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-20/debate.md

running ls -la ~/.claude/skills 2>/dev/null; find / -type d -name "bug-confirmation" 2>/dev/null | head -20
running pwd; ls -la; ls -la .claude 2>/dev/null; ls -la .claude/skills 2>/dev/null; ls -la /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; ls...
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; cat SKILL.md; echo "=====GUIDE====="; cat guide.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; cat phases/01-investigation.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; cat phases/02-reproduction.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; cat references/persistent-findings.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; sed -n 1,60p references/repair-request-format.md; echo ...; which specular; ls /hom...
我已读完 bug-confirmation 技能（guide + Phase 1/2 + persistent-findings）。接下来先做 persistent-findings 查重，然后进入 Phase 1 代码审计。
running ls /home/ubuntu/guava-retrying-20261126/Specular/; ls /home/ubuntu/guava-retrying-20261126/Specular/bin 2>/dev/null; find /home/ubuntu/guava-retrying-2026112...
running cd /home/ubuntu/guava-retrying-20261126/Specular; file specular; head -20 specular; ls .venv 2>/dev/null | head
running SP=/home/ubuntu/guava-retrying-20261126/Specular/specular; W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retry...
持久化记录中无匹配项，开始 Phase 1 代码审计。
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-20/worktree; ls -la...
reading /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-20/worktree/src/main/java/com/github/rhold...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-20/worktree; cat -n...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-20/worktree; cat .g...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-20/worktree; git sh...
进度：代码审计确认算术溢出路径存在（`WaitStrategies.java:282-283` 未检查乘法溢出，负值被钳到 0）。现在查开发者历史与上游 issue。
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-20/worktree; git lo...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-20/worktree; git sh...
running which gh && timeout 30 gh auth status 2>&1 | head -5; timeout 30 gh api 'repos/rholder/guava-retrying' --jq '.full_name, .open_issues_count, .pushed_at' 2>&1...
running for q in "incrementingWait" "IncrementingWaitStrategy" "overflow" "incrementing" "Long.MAX_VALUE" "negative sleep" "increment"; do echo "=== $q ==="; timeout...
running timeout 60 gh api --paginate 'repos/rholder/guava-retrying/issues?state=all&per_page=100' --jq '.[] | "\(.number)\t\(.state)\t\(if .pull_request then "PR" el...
上游 106 个 issue/PR 中没有关于 incrementingWait 溢出的标题。再核对 #100（fork 修复说明）及触及 `WaitStrategies.java` 的 PR diff，避免漏掉同机制的修复。
running timeout 30 gh api repos/rholder/guava-retrying/issues/100 --jq '.body' 2>&1 | head -40; echo ======; for pr in 50 95 101 40 58 59 98 24 26 17; do echo "--- P...
running for pr in 50 95 98 26 17; do echo "--- PR $pr ---"; timeout 30 gh api "repos/rholder/guava-retrying/pulls/$pr/files" --jq '.[] | select(.filename|test("WaitS...
running timeout 30 gh api "repos/rholder/guava-retrying/pulls/98/files" --jq '.[] | select(.filename|test("WaitStrategies.java$")) | .patch' 2>&1 | sed -n 15,40p
running for q in "IncrementingWaitStrategy overflow" "incrementingWait overflow" "incrementingWait Long.MAX_VALUE" "guava-retrying incrementing overflow" "guava-retr...
running for repo in rhuffman/re-retrying itning/guava-retrying3; do echo "=== $repo ==="; path=$(timeout 30 gh api -X GET search/code -f q="IncrementingWaitStrategy...
未发现上游或主要 fork（`rhuffman/re-retrying` 代码相同、未修复）报告过此机制。继续看 `RetryerBuilder` 是否有任何守卫，然后准备构建环境。
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-20/worktree; grep -...
确认无构建期守卫：任意 `increment` 都可通过 `RetryerBuilder.withWaitStrategy` 进入 `Retryer.call`。现在把 Phase 1 证据写入 `investigation.md`，然后准备构建依赖。
running ls ~/.m2/repository/com/google/guava/guava/ 2>/dev/null; ls ~/.m2/repository/com/google/guava/guava/22.0/ 2>/dev/null; ls ~/.m2/repository/com/google/code/fi...
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; ls $W/harness | head -30; ls $W/repro...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-20/worktree; git st...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-20/worktree; git di...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-20/worktree; grep -...
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-20/investigation.md
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/test_bugCR-D-20_incrementing_wait_overflow.sh
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro; chmod +x test_bugCR-D-20_incre...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro; timeout 5m bash test_bugCR-D-2...
running set -e FD=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-20 WT=$FD/wo...
running source /tmp/crd20-fixcheck-path.txt; cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/...
running M2=$HOME/.m2/repository; ls $M2/junit/junit/4.11/*.jar $M2/org/hamcrest/hamcrest-core/1.3/*.jar $M2/org/mockito/mockito-all/1.9.5/*.jar 2>&1 | head; ls $M2/o...
running set -e FD=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-20 WT=$FD/wo...
running cd /home/ubuntu/guava-retrying-20261126/Specular/src/specular; grep -rln "def.*validate\|\"validate\"" --include=*.py . | head; grep -rn "add_parser(\"valida...
running cd /home/ubuntu/guava-retrying-20261126/Specular/src/specular; grep -n "def \|REQUIRED\|required\|160\|\"root\"\|'root'\|evidence\|premises\|sites\|status" p...
running cd /home/ubuntu/guava-retrying-20261126/Specular/src/specular; sed -n 20,42p persistent_findings.py; sed -n 100,135p persistent_findings.py; sed -n 255,280p...
running S=/home/ubuntu/scratch/guava-retrying-src/guava-retrying; git -C $S rev-parse HEAD; git -C $S status --porcelain | head; for f in WaitStrategies Retryer Bloc...
running cd /home/ubuntu/scratch/guava-retrying-src/guava-retrying/src/main/java/com/github/rholder/retry; chk(){ f=$1; shift; for l in "$@"; do n=$(grep -cxF -- "$l"...
边界行全部唯一。写入 `issue.json` 并校验。
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-20/issue.json
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; python3 -c "import json,sys; d=json.l...
`issue.json` 校验通过（`"valid": true`，标题 141 字符）。取出完整运行日志用于报告。
running cat /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/CR-D-20.log
CR-D-20 已确认：只用公开 API、不打补丁、不注入状态（Level 0）即可稳定复现。前提是 `increment` 极大（接近 `Long.MAX_VALUE`），因此严重度我建议从 Medium 降为 Low。

- **Source**: Code Review
- **Novelty**: NEW
- **Location**: src/main/java/com/github/rholder/retry/WaitStrategies.java:282
- **Severity**: Low（原标 Medium）。只有极大的 `increment` 才会溢出：n 次尝试内溢出需要约 `Long.MAX_VALUE/(n-1)` ms，比如把 `Long.MAX_VALUE` 当"无限"哨兵值，或经 `TimeUnit` 饱和换算得到。普通取值在 `int` 尝试计数器（`Retryer.java:157`）达到约 2^31 之前不会溢出。触发后不抛异常，后果是退避变成立即重试。
- **Reproduction test**: `repro/test_bugCR-D-20_incrementing_wait_overflow.sh`，Level 0
- **Persistent record**: `confirmation/CR-D-20/issue.json`（`specular findings validate` 结果为 `"valid": true`）

## Description
`IncrementingWaitStrategy.computeSleepTime`（`WaitStrategies.java:282-283`）用 long 计算 `initialSleepTime + increment * (attemptNumber - 1)`，不做溢出检查，结果为负时直接钳成 `0`。工厂方法（`:108-116`）和构造函数（`:275`）都不限制 `increment`，`TimeUnit.toMillis` 遇到超大值还会饱和成 `Long.MAX_VALUE`。

当 `increment` 接近 `Long.MAX_VALUE` 时，乘法溢出：`increment*(n-1)` 在 n-1 为偶数时变成 `-(n-1)`，为奇数时加上初始值后变成负数。`Retryer.call` 实际收到的 sleep 序列是 `1000, 0, 998, 0, 996, …` ms，逐次递减，并且每隔一次就立即重试。Javadoc 承诺的是"incrementing amounts of time after each additional failed attempt"（等待时间逐次递增）。

## Trigger scenario
1. 用户构造 `RetryerBuilder.<Boolean>newBuilder().retryIfResult(equalTo(FALSE)).withWaitStrategy(WaitStrategies.incrementingWait(1000, MILLISECONDS, Long.MAX_VALUE, MILLISECONDS)).withStopStrategy(stopAfterAttempt(6)).build()`。
   - 另一种写法 `incrementingWait(1, SECONDS, Long.MAX_VALUE, DAYS)` 效果相同，因为 `DAYS.toMillis` 会饱和成 `Long.MAX_VALUE`。
   - 这些参数能通过 `RetryerBuilder.java:75-80, 190-197` 上的全部检查。
2. `Retryer.call` 第 1 次尝试被拒，`:176` 算出 sleep 1000，`:178` 执行 `Thread.sleep(1000)`。
3. 第 2 次尝试被拒，`1000 + Long.MAX_VALUE` 溢出成负数，被钳为 0。`Thread.sleep(0)` 立即返回（`BlockStrategies.java:45-47`），第 3 次尝试马上开始。
4. 之后同样交替：998 ms、0 ms、996 ms……
5. 对 initial=1000，到第 1002 次尝试时序列进一步异常，返回 `Long.MAX_VALUE`，之后又回到 0。

## Developer intent
- **Javadoc**（`WaitStrategies.java:97-107`）：工厂方法写的是 "in incrementing amounts of time after each additional failed attempt"，`@param increment` 写的是 "added to the previous sleep time after each failed attempt"。没有提到溢出，也没有给 `increment` 规定取值范围。
- **代码历史**：公式和 `>= 0 ? : 0` 钳位来自原始导入 `c531b61`（2012，`fr.free.jnizet.retry`），`1e7f2bd` 只改了参数名。没有任何提交讨论过这里的溢出。从代码看，这个钳位是给负 `increment`（递减等待、下限为 0）用的，不是溢出处理。
- **同文件的兄弟策略都对溢出做了向上饱和**：
  - `FibonacciWaitStrategy`（`:330`，`ce0bc7d`）：`if (result > maximumWait || result < 0L) result = maximumWait;`
  - `ExponentialWaitStrategy` 依赖 `Math.round` 饱和到 `Long.MAX_VALUE`，工厂 Javadoc 写的是 "up to Long.MAX_VALUE"。
- **测试**：
  - 指数和 Fibonacci 都有极值测试 `failedAttempt(Integer.MAX_VALUE, …)`（`WaitStrategiesTest.java:103,116,140,153`）。
  - `testIncrementingWait`（`:45-50`）只测了 `500/600/700`。
- **上游与 fork 检索**：
  - 搜索范围：`rholder/guava-retrying` 全部 106 个 issue/PR（open 和 closed，含已合并/关闭的 PR）、关键词搜索、所有改动 `WaitStrategies.java` 的 PR diff（#17/#26/#50/#95/#98），以及 GitHub 全站搜索。都没有找到报告这一机制的记录；#98 只改了消息格式。
  - fork `rhuffman/re-retrying` 里是同样的代码，同样没修。
  - persistent-findings 查询结果为 `[]`。

## Reproduction result
命令：`timeout 5m bash repro/test_bugCR-D-20_incrementing_wait_overflow.sh 2>&1 | tee repro/CR-D-20.log`。在 `.specular-output` 下执行，exit 0；第二次运行 `repro/CR-D-20.run2.log` 结果完全一致。环境：JDK 21，`--release 8`，Guava 22.0。测试类放在独立包里，只用公开 API。

```
== source HEAD: 177b6c9b9f3e7957f404f0bdb8e23374cb1de43f  dirty-files: 0
== javac 21.0.13.1  guava: guava-22.0.jar  jsr305: jsr305-2.0.2.jar
TimeUnit.DAYS.toMillis(Long.MAX_VALUE) = 9223372036854775807  (saturates)

[A] Retryer.call with DEFAULT block strategy (Thread.sleep), incrementingWait(1000, MILLISECONDS, Long.MAX_VALUE, MILLISECONDS), stopAfterAttempt(6)
    finished=true outcome=RetryException(numberOfFailedAttempts=6) attempts=6 wall=3016ms
    gap attempt 1 -> 2: observed 1000 ms   documented sleep: 1000 ms
    gap attempt 2 -> 3: observed 0 ms   documented sleep: 9223372036854776807 (> Long.MAX_VALUE; saturated: 9223372036854775807) ms
    gap attempt 3 -> 4: observed 998 ms   documented sleep: 18446744073709552614 (> Long.MAX_VALUE; saturated: 9223372036854775807) ms
    gap attempt 4 -> 5: observed 0 ms   documented sleep: 27670116110564328421 (> Long.MAX_VALUE; saturated: 9223372036854775807) ms
    gap attempt 5 -> 6: observed 996 ms   documented sleep: 36893488147419104228 (> Long.MAX_VALUE; saturated: 9223372036854775807) ms
    A: BUG -> attempt 3 ran 0 ms after attempt 2 (immediate retry) although the first wait was 1000 ms; waits are not incrementing

[B] Retryer.call, incrementingWait(1, SECONDS, Long.MAX_VALUE, DAYS), stopAfterAttempt(6), recording BlockStrategy delegating to BlockStrategies.threadSleepStrategy()
    finished=true outcome=RetryException(numberOfFailedAttempts=6) attempts=6
    sleeps requested by Retryer.call : [1000, 0, 998, 0, 996]
    observed gaps between attempts   : [1000, 0, 998, 0, 996] ms
    B: BUG -> requested sleeps decrease and include 0 ms (immediate retries)

[C] control: incrementingWait(100, MILLISECONDS, 100, MILLISECONDS), stopAfterAttempt(6)
    finished=true outcome=RetryException(numberOfFailedAttempts=6)
    sleeps requested by Retryer.call : [100, 200, 300, 400, 500]
    observed gaps between attempts   : [100, 200, 300, 400, 500] ms
    C: OK (incrementing as documented)

[D] public WaitStrategy.computeSleepTime(Attempt) for incrementingWait(1000 ms, +Long.MAX_VALUE ms)
    attempt 1: computeSleepTime=1000   documented=1000
    attempt 2: computeSleepTime=0   documented=9223372036854776807 (> Long.MAX_VALUE; saturated: 9223372036854775807)
    attempt 3: computeSleepTime=998   documented=18446744073709552614 (> Long.MAX_VALUE; saturated: 9223372036854775807)
    attempt 4: computeSleepTime=0   documented=27670116110564328421 (> Long.MAX_VALUE; saturated: 9223372036854775807)
    attempt 5: computeSleepTime=996   documented=36893488147419104228 (> Long.MAX_VALUE; saturated: 9223372036854775807)
    attempt 6: computeSleepTime=0   documented=46116860184273880035 (> Long.MAX_VALUE; saturated: 9223372036854775807)
    attempt 7: computeSleepTime=994   documented=55340232221128655842 (> Long.MAX_VALUE; saturated: 9223372036854775807)
    attempt 999: computeSleepTime=2   documented=9204925292781066256386 (> Long.MAX_VALUE; saturated: 9223372036854775807)
    attempt 1000: computeSleepTime=0   documented=9214148664817921032193 (> Long.MAX_VALUE; saturated: 9223372036854775807)
    attempt 1001: computeSleepTime=0   documented=9223372036854775808000 (> Long.MAX_VALUE; saturated: 9223372036854775807)
    attempt 1002: computeSleepTime=9223372036854775807   documented=9232595408891630583807 (> Long.MAX_VALUE; saturated: 9223372036854775807)
    attempt 1003: computeSleepTime=0   documented=9241818780928485359614 (> Long.MAX_VALUE; saturated: 9223372036854775807)

RESULT: BUG REPRODUCED (CR-D-20) - incrementingWait yields decreasing sleeps alternating with 0 ms immediate retries for an increment near Long.MAX_VALUE
== exit status: 0
```

**证明缺陷的输出行：**
- A 的 `gap attempt 2 -> 3: observed 0 ms`：默认 `Thread.sleep` 阻塞下，用户 callable 在第 2 次尝试后 0 ms 就被再次调用，而第一次等待是 1000 ms。
- B 的 `sleeps requested by Retryer.call : [1000, 0, 998, 0, 996]`。

**与预期行为对比：**
- 按文档，第 2 次之后的 sleep 应 ≥ `1000 + Long.MAX_VALUE` ms，饱和后实际上就是无限等待。
- 对照组 C（正常参数）严格递增，说明测量方法本身没问题，只有极端 `increment` 才出错。

**修复验证（梯级之外的反向对照，worktree 未改）：**
- 在临时副本上应用 `confirmation/CR-D-20/fixcheck.patch`，改用 `LongMath.checkedAdd/checkedMultiply` 并在溢出时饱和。
- 同一脚本的结果见 `repro/CR-D-20.fixcheck.log`：A/B 判为 `not triggered: retryer still sleeping after attempt 2`，B 请求的 sleep 为 `[1000, 9223372036854775807]`，C 不变，最终 `RESULT: NOT REPRODUCED`（exit 1）。说明这个测试能区分修复前后，症状确实来自 `:282-283`。
- 原始版本和修复版本都通过全部 36 个已有单测（`confirmation/CR-D-20/fixcheck-unit-tests.log`）。

## Recommendation
在 `IncrementingWaitStrategy.computeSleepTime` 里改用带溢出检查的算术，溢出时按 `increment` 的方向饱和：正向得 `Long.MAX_VALUE`，负向得 `0`。这和同文件 Fibonacci/Exponential 的饱和语义一致。

```java
long result;
try {
    result = LongMath.checkedAdd(initialSleepTime,
            LongMath.checkedMultiply(increment, failedAttempt.getAttemptNumber() - 1));
} catch (ArithmeticException overflow) {
    result = increment > 0L ? Long.MAX_VALUE : 0L;
}
return result >= 0L ? result : 0L;
```

`LongMath` 从 Guava 11 才有。如果要保留声明范围 `[10.+,)` 的下限，就改用手写的溢出检查。另外按已有的 `Integer.MAX_VALUE` 测试的写法，为 incrementing 补一个极值单测（例如 `incrementingWait(1000, ms, Long.MAX_VALUE, ms)` 在第 2、3 次尝试应返回 `Long.MAX_VALUE`）。如果维护者更想要一个上限参数，也可以像 `exponentialWait(maximumTime, …)` 那样增加 `maximumTime` 重载，并在 Javadoc 里写明溢出时如何饱和。

## REPRODUCED checklist
1. 只用 Level 0 / Level 1 就触发了吗？**yes**，Level 0：全部经由公开 API，默认阻塞策略，没有改源码，没有注入状态。
2. 不适用，没有用到 Level 2/3。
3. 哪个真实调用方观察到错误结果？`Retryer.call`（`Retryer.java:176-178`）把溢出后的 `0` 交给 `BlockStrategy.block`，再到 `BlockStrategies.java:46` 的 `Thread.sleep(0)`。用户 callable 按自己记录的时间戳，在第 2 次尝试后 0 ms 就被再次调用（场景 A）。
4. 坏状态是永久的吗？**是。** 每次算出的 sleep 都被直接用掉，立即重试那一次已经实际执行了 callable，无法撤回。之后每个偶数次尝试都会重现，没有任何下游机制纠正。唯一的"保护"是 `:283` 的钳位，而 0 正是它产生的，所以不存在遮蔽（mask）。

---

## Entry 22: `fibonacciWait` overflow wraps to a positive value that the guard misses, so the sleep drops below the cap instead of growing up to the maximum

- **Finding ID**: CR-D-21
- **Status**: MASKED
- **Debate**: not run
- **Transcript**: /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-21/debate.md

running pwd; ls -la; echo ---; ls -la /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmati...
running ls -la /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation/*; echo --...
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; cat SKILL.md; echo; echo "=================== guide.md"; cat guide.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; cat phases/01-investigation.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; cat phases/02-reproduction.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; cat references/persistent-findings.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; cat references/repair-request-format.md | head -80
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-21/worktree; ls -la...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-21/worktree; cat -n...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-21/worktree; grep -...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-21/worktree; ls src...
running which gh specular java javac mvn 2>&1; java -version 2>&1 | head -2; gh auth status 2>&1 | head -5; ls /home/ubuntu/guava-retrying-20261126/Specular/runs/gua...
running cd /home/ubuntu/guava-retrying-20261126/Specular; ls; ls bin scripts 2>/dev/null | head -30; find . -maxdepth 3 -name "specular*" -not -path "./runs/*" 2>/de...
running cd /tmp; timeout 60 gh search issues --repo rholder/guava-retrying "fibonacci" --limit 50 --json number,title,state,url,createdAt 2>&1 | head -50; echo ---PR...
running cd /tmp; for q in overflow "wait time negative" "sleep time" "Long.MAX_VALUE" "maximumWait" "computeSleepTime" "exponential overflow" "wait strategy"; do ech...
running cd /tmp; echo "=== ALL PRs (any state), newest update first"; timeout 60 gh pr list --repo rholder/guava-retrying --state all --limit 200 --json number,title...
running cd /tmp; timeout 60 gh pr view 107 --repo rholder/guava-retrying --json title,state,body,files,closedAt,mergedAt 2>&1 | python3 -c 'import sys,json; d=json.l...
running cd /tmp; echo "=== ALL issues"; timeout 60 gh issue list --repo rholder/guava-retrying --state all --limit 300 --json number,title,state,updatedAt 2>&1 | pyt...
running cd /tmp; for n in 87 100 81; do echo "=================== ISSUE #$n"; timeout 60 gh issue view $n --repo rholder/guava-retrying --comments 2>&1 | head -80; done
running cd /tmp; echo "=================== PR #9"; timeout 60 gh pr view 9 --repo rholder/guava-retrying --comments 2>&1 | head -80; echo; echo "=== PR #9 review com...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-21/worktree; grep -...
running cd /tmp; for n in 87 100; do echo "=================== ISSUE #$n"; timeout 60 gh api repos/rholder/guava-retrying/issues/$n --jq '"\(.title)\n\(.state)\n\(.b...
running cd /tmp; echo "=== global issue search"; for q in "FibonacciWaitStrategy overflow" "fibonacciWait overflow" "fibonacci wait overflow retry" "FibonacciWaitStr...
running cd /tmp; for repo in kiwiproject/retrying-again rhuffman/re-retrying itning/guava-retrying3; do echo "=========== $repo"; timeout 60 gh search issues --repo...
running cd /tmp; timeout 60 gh api "repos/kiwiproject/retrying-again/contents/src/main/java/org/kiwiproject/retry/WaitStrategies.java" --jq '.content' 2>/dev/null |...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-21/worktree; git bl...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-21/worktree; git sh...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-21/worktree; git lo...
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; ls -la $OUT/harness $OUT/repro 2>&1...
检索与审计完成，进入 Phase 2。先确认 JDK 21 中 `Thread.sleep` 的毫秒→纳秒换算（这关系到被包裹回来的值能否被真实的 sleep 观察到）。
running ls /usr/lib/jvm/; J21=$(dirname $(dirname $(readlink -f $(which java)))); echo $J21; ls $J21/lib/src.zip 2>&1; unzip -p $J21/lib/src.zip java.base/java/lang/...
running J21=/usr/lib/jvm/java-21-openjdk-amd64; ls -la $J21/lib/src.zip; readlink -f $J21/lib/src.zip; unzip -l $J21/lib/src.zip 2>&1 | grep -m3 "java/lang/Thread.ja...
running /usr/lib/jvm/java-11-openjdk-amd64/bin/javap -p java.lang.Thread 2>/dev/null | grep -n "sleep"; cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-r...
running python3 - <<'EOF' M=2**64 def s(x): x%=M return x-M if x>=2**63 else x LMAX=2**63-1 def comp(n,m,cap): a,b=0,1 if n==0: f=0 elif n==1: f=1 else: for i in ran...
数值核对与 finding 一致（n=93→`Long.MAX_VALUE`，n=94→1293530146158671551；×1000 时 n=79→上限，n=80→4969984274758133384）。现在写 Phase 1 的 `investigation.md`。
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-21/investigation.md
接下来写复现脚本。先确认 `RetryListener` 签名和上游 `WaitStrategiesTest` 的依赖（修复后的回归检查要用）。
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-21/worktree; sed -n...
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/test_bugCR-D-21_fibonacci_overflow_wrap.sh
修正脚本中 `set -e` 会吞掉退出码、以及 grep 无匹配时中断的问题。
running F=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/test_bugCR-D-21_fibonacci_overfl...
脚本就绪，开始实际执行（外层 `timeout 20m`，输出写入 `repro/CR-D-21.log`）。
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro; timeout 20m bash ./test_bugCR-...
reading /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/CR-D-21.log
running F=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/test_bugCR-D-21_fibonacci_overfl...
重跑通过，扫描结果与首次一致。确认日志其余部分（L0 和修复对照）也正常。
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro; sed -n '1,6p;13,16p;26,42p;49,...
running SRC=/home/ubuntu/scratch/guava-retrying-src/guava-retrying; cd $SRC; git rev-parse HEAD; git status --porcelain | wc -l chk(){ f="$1"; l="$2"; c=$(grep -cxF...
边界行均唯一。写入 `issue.json` 并校验。
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-21/issue.json
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; python3 -c "import json,sys; d=json...
`issue.json` 校验通过（`valid: true`，title 127 字符）。最后确认源码 checkout 未被改动。
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-21/worktree && git...
## CR-D-21 结论：MASKED

算术缺陷是真的，通过公共 API 也能走到；但没有任何真实的 sleep 会因此变短，实际危害被三层机制屏蔽，三层都在运行中证明生效。

- **Source**: Code Review（ledger D-21，scenario 5，未做模型检查，没有反例）
- **Novelty**: NEW
- **Severity**: Low（finding 原标 Medium。下调是因为在任何可接受的部署里，真实 sleep 都不会变短）
- **Location**: `src/main/java/com/github/rholder/retry/WaitStrategies.java:330`（guard），相关代码在 `:326-352`
- **Reproduction test**: `repro/test_bugCR-D-21_fibonacci_overflow_wrap.sh`，输出在 `repro/CR-D-21.log`；ladder 停在 Level 0
- **Persistent record**: `confirmation/CR-D-21/issue.json`，`specular findings validate` 返回 `valid: true`

## Description
`FibonacciWaitStrategy` 用不检查溢出的 `long` 运算计算 `fib(attemptNumber)` 和 `multiplier * fib`。guard（`:330`）只把负数或超过上限的结果当作溢出。如果溢出后绕回成一个低于 `maximumWait` 的正数，这个值会被直接返回当作 sleep，于是等待时间先到达上限、随后又下降，违反了 Javadoc（`:161-162`、`:171-172`）里"增长到 maximumTime 为止"的约定。

两个受影响的配置：
- `fibonacciWait()`：第 93 次得到 `Long.MAX_VALUE`，第 94 次降到 1293530146158671551。
- `fibonacciWait(1000, Long.MAX_VALUE, MILLISECONDS)`：第 79 次到上限，第 80 次降到 4969984274758133384。

另外，对任意 multiplier，第一次溢出一定绕回成负数并被 guard 映射为上限。所以低于上限的值只可能出现在已经睡过一次上限时长之后。

## Trigger scenario
用 `RetryerBuilder` 搭配 `fibonacciWait()` 或上面的 ×1000 配置，加上 `neverStop()` 或 `stopAfterAttempt(≥95)`，callable 一直失败。`Retryer.call` 在 `:176-178` 把绕回后的值交给 `BlockStrategy.block`。

要在现实时间内到达第 94 次（×1000 为第 80 次），只有两种方式：
- 用一个不按指定时长阻塞的 `BlockStrategy`。`BlockStrategy.java:27-31` 对这种实现明确提出了警告。
- 通过公共的 `WaitStrategy`/`Attempt` 接口直接求值。

用内置的 `ThreadSleepStrategy` 时，到达这一步之前要先完成至少 2^63−1 ms 的指定睡眠。

## Developer intent
- 原始提交 `ce0bc7d`（PR #9，Jochen Schalanda，2013）就带着 `result < 0L` 这个溢出 guard，说明作者想让溢出饱和到上限。
- 同一提交里的测试 `WaitStrategiesTest.java:140,153` 断言 `computeSleepTime(Integer.MAX_VALUE)` 等于上限（10 和 50000），即作者预期极端次数会被钳到上限。不封顶的 `fibonacciWait()` 没有对应测试。
- README 的示例配置是 `fibonacciWait(100, 2, MINUTES)`，并提到极端参数"very unlikely with useful parameters"。代码附近没有 TODO 或 FIXME。
- 已知状态检索：
  - rholder/guava-retrying 全部 61 个 issue、45 个 PR，包括最近关闭的 #107（2026-09-05，误投的 PHP 移植，未合并）和 #84，都没有这个机制。
  - fork re-retrying、guava-retrying3、kiwiproject/retrying-again 也没有报告；retrying-again 至今保留完全相同的代码。
  - GitHub 全局搜索无结果。`persistent-findings-context.json` 里也没有历史记录。

## Reproduction result
运行命令：`timeout 20m bash repro/test_bugCR-D-21_fibonacci_overflow_wrap.sh > repro/CR-D-21.log 2>&1`，exit 0。源码是未修改的 `177b6c9`，用 JDK 21 `--release 8` 和 Guava 22.0 编译，驱动程序只调用公共 API。

```
  attempt  93 -> block( 9,223,372,036,854,775,807 ms)  = 2.923e+08 years
  attempt  94 -> block( 1,293,530,146,158,671,551 ms)  = 4.099e+07 years   <-- DECREASE vs attempt 93, below the cap that attempt 93 already reached
  attempt  80 -> block( 4,969,984,274,758,133,384 ms)  = 1.575e+08 years   <-- DECREASE vs attempt 79, below the cap that attempt 79 already reached
    designated total          = 28963646256722998973 ms = 9.178e+08 years   (>= 2^63-1 ms: true)
    JDK 21 Thread.sleep total = 293868841283207 ms = 9312 years   (each sleep saturates at Long.MAX_VALUE ns = 292.3 years)
  WaitStrategies.fibonacciWait(): after 3.0 s wall clock the Retryer had made 17 attempts and was TIMED_WAITING in Thread.sleep(1597 ms = 1.60 s)
  toNanos(1293530146158671551 ms) = 9223372036854775807 ns;  toNanos(Long.MAX_VALUE ms) = 9223372036854775807 ns
# fibonacciWait(100, 2, MINUTES)  [README example]   multiplier=100  cap=120000 ms (120.00 s)
  guard escapes (value != cap at attempt >= 17): 0   decreases: 0
  smallest escape: attempt 818715960 -> 3196715680 ms (37.00 days)
  escapes < 292.3 y (shorter than a saturated JDK 21 sleep): 1098 (first at attempt 578550; JDK 21 Thread.sleep before it ~ 1.691e+08 years)
```

Escalation ladder：
- **L0-B**：真实 `Retryer.call` 加一个只记录、不真睡的用户 `BlockStrategy`，block 收到了下降的值。缺陷路径成立。
- **L0-C**：直接调用公共 `computeSleepTime`，第 1..100 次的结果与 L0-B 交给 block 的值完全一致。
- **L0-A**：内置 sleep，3 秒预算内只跑到第 17 次。
- **L1**：不适用，这不是竞态问题。
- **L2/L3**：没有用来制造症状。只在一个临时副本上套用了修复，作为对照。

三层屏蔽：
- **M1 时间屏障**：出现第一个低于上限的值之前，按指定时长要睡约 9.18e8 年；在 JDK 21 上实际要睡约 9,312 年。
- **M2 guard 覆盖**：对 10 s、2 min（README）、1 h、1 天 ×1000 这几个现实上限，扫描全部 1..`Integer.MAX_VALUE` 次，没有一次逃逸。365 天上限会逃逸，但最早在第 818,715,960 次。
- **M3 JDK 21 下游饱和**：JDK 21 的 `Thread.sleep` 先把毫秒换算成纳秒并饱和到 `Long.MAX_VALUE` ns，所以第 94 次（以及 ×1000 的第 80 次）实际睡的时长和上限完全相同。第一个真正会缩短 JDK 21 实际睡眠的值出现在第 578,550 次，之前要先睡约 1.7e8 年。

修复对照：同样的公共 API 运行下序列单调，并从第 93 次（×1000 为第 79 次）起固定在上限。上游 `WaitStrategiesTest` 在原始版和修复版上都是 `OK (12 tests)`。

为什么不是 REPRODUCED（逐条回答检查清单）：
1. **只靠 Level 0/1 能触发吗？** 缺陷路径能（L0，公共 API）；实际危害不能。要在现实时间内到达第 94 次，必须用一个不按指定时长阻塞的 `BlockStrategy`，这违反了目标"用户策略遵守接口 Javadoc"的假设。
2. **用了 L2/L3 吗？** 没有用 L2 或 L3 制造症状。经真实 API 到达第 94 次，需要先完成上面 M1 那一大段睡眠。
3. **哪个真实调用方看到错误结果？** `Retryer.java:178` 的 `BlockStrategy.block` 确实收到了下降的值，但内置 `ThreadSleepStrategy`（`BlockStrategies.java:46`）在任何现实时间里都观察不到差异。所以后果只停留在论证层面。
4. **坏状态是永久的还是被屏蔽？** 被屏蔽，屏蔽机制就是上面的 M1、M2、M3。

## Recommendation
建议换成有界计算。这段代码已在复现脚本的修复对照中验证；另外它会提前退出，单次调用的开销从 O(n) 降到最多约 93 步：

```java
long n = failedAttempt.getAttemptNumber();
if (n <= 0L) return 0L;
long limit = maximumWait / multiplier;
long prevPrev = 0L, prev = 1L;
for (long i = 2L; i <= n; i++) {
    if (prevPrev > limit - prev) return maximumWait;   // 超过上限，且没有发生任何溢出
    long next = prev + prevPrev; prevPrev = prev; prev = next;
}
return prev * multiplier;                              // prev <= limit，不会溢出
```

同时补一个测试：`fibonacciWait()` 从第 93 次到第 200 次以及 `Integer.MAX_VALUE` 都应等于 `Long.MAX_VALUE`，并且整段序列单调不减。

---

## Entry 23: `stopAfterDelay(d, unit)` truncates the delay to whole milliseconds, so a sub-millisecond limit becomes 0 ms and retrying stops after the first failed attempt

- **Finding ID**: CR-D-22
- **Status**: REPRODUCED
- **Debate**: not run
- **Transcript**: /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-22/debate.md

running find / -type d -name "bug-confirmation" 2>/dev/null | head -20; echo ---; ls -la /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-...
running ls -la ~/.claude/skills/ 2>&1 | head -50; echo ---; ls -la /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation/ /home/ubuntu/guava-retrying...
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation/ && cat SKILL.md && echo "=====GUIDE=====" && cat guide.md
running cat /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation/phases/01-investigation.md
running cat /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation/phases/02-reproduction.md
running cat /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation/references/persistent-findings.md
running cat /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation/references/repair-request-format.md | head -120
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-22/ && cat turn01_A...
正在处理 CR-D-22：已读完 skill（guide + Phase 1/2 + 参考文档），接下来先做 persistent-findings lookup，然后审计 `StopStrategies.java`。
running which specular; ls /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/ 2>&1; echo ---; ls /...
running cd /home/ubuntu/guava-retrying-20261126/Specular && ls; echo ---; ls bin scripts 2>/dev/null | head -40; echo ---; find . -maxdepth 3 -name "specular*" -not...
running cd /home/ubuntu/guava-retrying-20261126/Specular && file ./specular && head -30 ./specular; echo ---; timeout 60 ./specular findings --help 2>&1 | head -40
running cd /home/ubuntu/guava-retrying-20261126/Specular && W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.sp...
Persistent-findings lookup 无匹配（`[]`），进入 Phase 1 代码审计。
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-22/worktree && cat...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-22/worktree && grep...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-22/worktree && git...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-22/worktree && cat...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-22/worktree && grep...
running for q in "stopAfterDelay" "toMillis" "microseconds" "nanoseconds" "truncat" "TimeUnit" "millisecond" "precision" "resolution"; do echo "=== search: $q (issue...
running for q in "stopAfterDelay" "toMillis" "microseconds" "nanoseconds" "truncat" "TimeUnit" "millisecond" "precision" "resolution" "StopAfterDelayStrategy" "delay...
running for n in 93 30; do echo "=================== ISSUE #$n"; timeout 60 gh issue view $n --repo rholder/guava-retrying --comments 2>&1 | head -80; done
running for n in 39 58; do echo "=================== PR #$n"; timeout 60 gh pr view $n --repo rholder/guava-retrying --comments 2>&1 | head -60; echo "--- files"; ti...
running for n in 93 30 29 86; do echo "=================== #$n"; timeout 60 gh api repos/rholder/guava-retrying/issues/$n --jq '"title: \(.title)\nstate: \(.state)\n...
running echo "=== all PRs (any state), newest first"; timeout 60 gh pr list --repo rholder/guava-retrying --state all --limit 200 --json number,title,state,updatedAt...
running for n in 107 95 98 53 101 99; do echo "=================== PR #$n"; timeout 60 gh pr view $n --repo rholder/guava-retrying --json title,state,mergedAt,closed...
running cd /home/ubuntu/guava-retrying-20261126/Specular && ls case-studies | head -80; echo ---; grep -ril "guava-retrying\|rholder" case-studies 2>/dev/null | head...
running timeout 60 gh search code "guava-retrying" --owner specular-org --limit 20 --json repository,path --jq '.[] | "\(.repository.fullName) \(.path)"' 2>&1 | head...
running timeout 60 gh api "repos/specular-org/specular-case-studies/contents" --jq '.[].name' 2>&1 | head -100 | tr '\n' ' '; echo; echo ---; timeout 60 gh api "repo...
running for d in systems wip catalog; do echo "== $d"; timeout 60 gh api "repos/specular-org/specular-case-studies/contents/$d" --jq '.[].name' 2>&1 | tr '\n' ' '; e...
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; ls -la $W/harness | head -40; echo --...
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; cat $W/harness/pom.xml; echo ----; ca...
running java -version 2>&1; javac -version 2>&1; ls ~/.m2/repository/com/google/guava/guava/22.0/ ~/.m2/repository/com/google/code/findbugs/jsr305/2.0.2/ ~/.m2/repos...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-22/worktree/src/mai...
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-22/investigation.md
Phase 1 记录已写入 `investigation.md`，不触发 pre-filter（未被报告过）。进入 Phase 2：编写 Level 0 纯黑盒复现脚本（仅用公开 API，带对照组）。
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/test_bugCR-D-22_subms_stop_after_delay.sh
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output && chmod +x repro/test_bugCR-D-22_sub...
running cd /home/ubuntu/guava-retrying-20261126/Specular && grep -n "def \|status\|source\|title\|160\|start\|end\b" src/specular/*findings*.py 2>/dev/null | head -8...
running cd /home/ubuntu/guava-retrying-20261126/Specular && sed -n '20,42p;345,420p' src/specular/persistent_findings.py
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/test_bugCR-D-22_subms_stop_after_delay.sh
Now refactor the scenario-A runner to take any counting callable and add the result-rejection (D) and `wrap()`/executor (E) paths.
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/test_bugCR-D-22_subms_stop_after_delay.sh
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output && timeout 10m bash repro/test_bugCR-...
所有 5 条路径（A 子毫秒、B 一般性缩短、C 恒失败、D 按结果拒绝、E `wrap()`+executor）均触发，对照组全部正常。再跑一次独立运行确认确定性。
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output && timeout 10m bash repro/test_bugCR-...
running cd /home/ubuntu/scratch/guava-retrying-src/guava-retrying && git rev-parse HEAD && git status --porcelain | head -3; D=src/main/java/com/github/rholder/retry...
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-22/issue.json
running cd /home/ubuntu/guava-retrying-20261126/Specular && W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.sp...
`issue.json` 校验通过（`valid: true`，标题 151 字符）。最后确认未改动库源码。
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output && git -C confirmation/CR-D-22/worktr...
## CR-D-22 确认结论：REPRODUCED（Level 0，纯公开 API）

- **Source**: Code Review
- **Novelty**: NEW（上游 issue 和 PR 全状态都搜过，包括最近关闭的 #107（2026-09-05 关闭未合并，是 PHP 移植）和 #84，也查了 Specular case-studies 数据集，没有人报告过这个机制。最接近的 #93 讲的是 `WaitStrategies` 文档没写清 ms 单位，站点和机制都不同）
- **Location**: `src/main/java/com/github/rholder/retry/StopStrategies.java:87`（另见 `:124`，触发点在 `Retryer.java:173-174`）
- **Severity**: Low。finding 原标 Medium，我下调了：只有带亚毫秒部分的上限会受影响，提前量不到 1 ms；但上限小于 1 ms 时重试会被完全取消
- **Reproduction test**: `.specular-output/repro/test_bugCR-D-22_subms_stop_after_delay.sh`（Level 0），日志在 `repro/CR-D-22.log` 和 `repro/CR-D-22.run2.log`
- **Persistent record**: `confirmation/CR-D-22/issue.json`，已通过 `specular findings validate`（`"valid": true`）

## Description
`stopAfterDelay(long duration, TimeUnit timeUnit)` 用 `timeUnit.toMillis(duration)` 换算上限（`StopStrategies.java:87`），这个换算会向零截断。`StopAfterDelayStrategy.shouldStop` 的判断是 `getDelaySinceFirstAttempt() >= maxDelay`（`:124`），所以实际生效的条件是"已过时间 ≥ floor(上限的毫秒数)"。

结果有两种：
- 上限小于 1 ms 时（例如 500 µs、999 999 ns），上限变成 0，第一次失败后就立刻停止，相当于 `stopAfterAttempt(1)`。
- 上限带亚毫秒余数时，会提前最多 0.999 ms 停止。

Javadoc（`:75-79`）写的是只有当已过时间 "has exceeded the given delay amount" 才停止，上面两种情况都违反了它。

## Trigger scenario
1. 构造 retryer：`RetryerBuilder.<String>newBuilder().retryIfException().withStopStrategy(StopStrategies.stopAfterDelay(500, TimeUnit.MICROSECONDS)).build()`。
2. 调用 `call(c)`，其中 `c` 第一次立即抛出 `IOException`（瞬时故障），第二次返回 `"ok"`。
3. 第 1 次尝试大约 2 µs 后失败，此时 `getDelaySinceFirstAttempt()=0`，判断 `0 >= 0` 为真。
4. `call()` 抛出 `RetryException(numberOfFailedAttempts=1)`，本来会成功的第 2 次尝试从未执行。

另外几条路径同样触发：
- 按结果拒绝的路径（`retryIfResult(isNull())`）。
- `Retryer.wrap()` 提交到 executor 的路径。
- 带余数的上限：`stopAfterDelay(1900, MICROSECONDS)` 被换算成 1 ms，第一次尝试约 1.2 ms 后失败，此时就停止了。

## Developer intent
- 这个 overload 由 24aa7ef（PR #39 / issue #30）引入，提交说明是："For consistency with the AttemptTimeLimiters and WaitStrategies classes, StopStrategies now also accepts (long, TimeUnit) pairs"。其中 `AttemptTimeLimiters.fixedTimeLimit` 会把单位原样传给 Guava，保留全部精度。提交和讨论里都没有涉及亚毫秒精度。
- Javadoc 没有说明会截断。`@return ... {@code delayInMillis}` 是从被弃用的那个 overload 照抄过来的，引用的参数名在本方法里根本不存在。
- 现有 `StopStrategiesTest` 只测了 1000 ms 和 1 SECONDS 两种上限，没有测试把"亚毫秒上限只尝试一次"断言为预期行为。
- `Attempt.java:81-83` 声明延迟以毫秒为单位，这只能解释精度是毫秒级，不能解释取整方向。对照组证明，用同样的毫秒级 `Attempt` 改成向上取整，就能满足文档契约。
- 目标说明的 Q5 也明确把 `stopAfterDelay` 的预期定义为"达到上限才停止"。

## Reproduction result
运行方式：

```
cd .specular-output && timeout 10m bash repro/test_bugCR-D-22_subms_stop_after_delay.sh 2>&1 | tee repro/CR-D-22.log
```

脚本用未修改的源码（HEAD `177b6c9b9f3e7957f404f0bdb8e23374cb1de43f`，`git status --porcelain` 为空）加 Guava 22.0 编译。上游 `StopStrategiesTest` 结果为 `OK (4 tests)`。一共独立跑了两次，结果一致（rc=0）。下面摘录日志关键行：

```
JDK TimeUnit.toMillis (used by StopStrategies.java:87): MICROSECONDS.toMillis(500)=0  NANOSECONDS.toMillis(999_999)=0  NANOSECONDS.toMillis(1_000_000)=1  MICROSECONDS.toMillis(1900)=1

[A] transient failure: attempt 1 fails immediately, attempt 2 would return "ok" (default noWait)
  built-in stopAfterDelay(500, MICROSECONDS)                 trials=1000  returned "ok"=0  RetryException after 1 attempt=1000  other RetryException=0  other=0
                                                               gave up after 1 attempt with WHOLE call() < limit (500.0 us): 1000/1000;  call() duration us min/p50/max=2.2/2.3/114.5;  lastFailedAttempt.getDelaySinceFirstAttempt()=0 ms
  built-in stopAfterDelay(999_999, NANOSECONDS)              trials=1000  returned "ok"=0  RetryException after 1 attempt=1000  other RetryException=0  other=0
                                                               gave up after 1 attempt with WHOLE call() < limit (1000.0 us): 1000/1000;  call() duration us min/p50/max=1.9/2.0/122.2;  lastFailedAttempt.getDelaySinceFirstAttempt()=0 ms
  CONTROL built-in stopAfterDelay(1_000_000, NANOSECONDS)    trials=1000  returned "ok"=1000  RetryException after 1 attempt=0  other RetryException=0  other=0
  CONTROL oracle (ceil) for 500 MICROSECONDS                 trials=1000  returned "ok"=1000  RetryException after 1 attempt=0  other RetryException=0  other=0

[B] general shortening: attempt 1 works ~1200 us then fails, attempt 2 would return "ok"
  built-in stopAfterDelay(1900, MICROSECONDS)                trials=300  returned "ok"=0  RetryException after 1 attempt=300  other RetryException=0  other=0
                                                               gave up after 1 attempt with WHOLE call() < limit (1900.0 us): 300/300;  call() duration us min/p50/max=1202.5/1204.1/1630.1;  lastFailedAttempt.getDelaySinceFirstAttempt()=1 ms
  CONTROL oracle (ceil) for 1900 MICROSECONDS                trials=300  returned "ok"=300  RetryException after 1 attempt=0  other RetryException=0  other=0

[C] every attempt fails immediately: how long is retrying actually kept up?
  built-in stopAfterDelay(500, MICROSECONDS)                 trials=200  gave up after 1 attempt=200 (with WHOLE call() < limit: 200)  after >1 attempts=0;  attempts min/p50/max=1/1/1;  call() duration us min/p50/max=2.4/3.0/33.2
  CONTROL oracle (ceil) for 500 MICROSECONDS                 trials=200  gave up after 1 attempt=0 (with WHOLE call() < limit: 0)  after >1 attempts=200;  attempts min/p50/max=147/211/368;  call() duration us min/p50/max=1001.3/1004.6/9887.8

RESULT A (sub-ms limit -> 0 ms): BUG TRIGGERED -- stopAfterDelay(500, MICROSECONDS): 1000/1000 calls threw RetryException after the 1st failed attempt although the whole call() took < 500 us; stopAfterDelay(999_999, NANOSECONDS): 1000/1000; 1 ns more (1_000_000 NANOSECONDS) returns "ok" in 1000/1000.
RESULT B (limit shortened by up to 0.999 ms): BUG TRIGGERED -- stopAfterDelay(1900, MICROSECONDS) gave up after 1 attempt with the whole call() < 1900 us in 300/300 calls (oracle returns "ok" in 300/300).
RESULT C (always failing): BUG TRIGGERED -- stopAfterDelay(500, MICROSECONDS) stopped after 1 attempt, before 500 us elapsed, in 200/200 calls; oracle kept retrying until >= 1 ms in 200/200.
RESULT D (rejected-result path): BUG TRIGGERED -- 1000/1000 calls gave up after 1 attempt before 500 us; control returns "ok" in 1000/1000.
RESULT E (wrap()/executor path): BUG TRIGGERED -- Future.get() threw ExecutionException(RetryException after 1 attempt) before 500 us in 499/500 submissions; control returns "ok" in 500/500.
CONTROLS OK
```

怎么读这些输出：
- **判定依据**：整个 `call()` 的耗时（从调用前到捕获异常）是停止决策时刻已过时间的上界。所以"1 次尝试后放弃，且整个 `call()` 小于上限"就证明了决策发生在上限到达之前。
- **截断是根因**：同为 `NANOSECONDS` 单位，999 999 ns 下 1000/1000 次只尝试一次，多 1 ns（1 000 000 ns）就 1000/1000 次返回 `"ok"`。
- **预期行为**：向上取整的对照 oracle 在同样的工作负载下全部返回 `"ok"`；在 C 场景中它一直重试到已过时间 ≥ 1 ms 才停（即超过了 500 µs）。
- **E 路径的个别未计入**：E 有 1 次（第二次运行是 2 次）因为 executor 交接耗时，上界测量超过了 500 µs，被如实计为"不可证明"。这几次同样是 1 次尝试后就放弃了。

**REPRODUCED 检查清单**
1. 只靠 Level 0 或 Level 1 就触发了吗？**yes**。只用了公开 API（`RetryerBuilder`、`StopStrategies`、`Retryer.call`/`wrap`、`RetryException`、`Attempt`），库代码里没有加 sleep，没有注入状态，也没有改源码。B 场景里 1.2 ms 的自旋是用户 callable 自己的工作量。
2. 没有用到 Level 2 或 Level 3，不适用。
3. 谁看到了错误结果？`Retryer.call`（`Retryer.java:173-174`）根据 `shouldStop` 的结果把 `RetryException` 抛给调用方，调用方拿到的是 `RetryException(1 attempt)`，而不是 `"ok"`，callable 只被调用了 1 次。走 `RetryerCallable.call`（`Retryer.java:317-318`）这条路时，`Future.get()` 的调用方拿到的是 `ExecutionException(RetryException)`。
4. 是永久的吗？是。`RetryException` 就是这次 `call()` 的最终结果，库里没有任何下游机制会重新尝试或恢复，所以不属于 MASKED。

## Recommendation
- **修复方式**：在 `StopStrategies.stopAfterDelay(long, TimeUnit)` 中把截断改为向上取整，这样永远不会在上限之前停止：
  ```java
  long ms = timeUnit.toMillis(duration);
  if (ms < Long.MAX_VALUE && timeUnit.toNanos(duration) > TimeUnit.MILLISECONDS.toNanos(ms)) ms++;
  return new StopAfterDelayStrategy(ms);
  ```
  整毫秒单位的现有行为不变，超大值的饱和处理也不变。如果不改行为，至少要在 Javadoc 里写明毫秒精度和取整规则，或者拒绝亚毫秒输入。
- **文档**：同时修正 `@return` 里过时的 `{@code delayInMillis}`。
- **回归测试**：建议加以下断言：
  - `stopAfterDelay(500, MICROSECONDS)` 对 delay 0 ms 应判为 false；
  - `stopAfterDelay(1900, MICROSECONDS)` 对 1 ms 应判为 false，对 2 ms 应判为 true。
- **范围之外**：`WaitStrategies` 的各个工厂方法（`WaitStrategies.java:60` 等）也用 `toMillis` 截断，形状相同但站点和后果不同，不在本 verdict 范围内。

---

## Entry 24: `RetryException` is `Serializable` but holds a non-transient `Attempt` whose implementations are not serializable, so serializing it fails

- **Finding ID**: CR-D-23
- **Status**: DROPPED
- **Debate**: not run
- **Transcript**: /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-23/debate.md

running pwd; ls -la; echo ---; ls -la /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmati...
running ls -la ~/.claude/skills 2>/dev/null; echo ---; ls -la /home/ubuntu/guava-retrying-20261126/Specular/ 2>/dev/null; echo ---; ls -la /home/ubuntu/guava-retryin...
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; find . -type f | sort; echo ---; wc -l $(find . -type f)
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; for f in SKILL.md guide.md phases/01-investigation.md phases/02-reproduction.md; do...
reading /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation/guide.md
reading /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation/phases/01-investigation.md
reading /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation/phases/02-reproduction.md
reading /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation/references/persistent-findings.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-23; cat turn01_A.lo...
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; ls -la $OUT; echo ---; ls -la $OUT/...
running which specular; ls -la /home/ubuntu/guava-retrying-20261126/Specular/specular; cat /home/ubuntu/guava-retrying-20261126/Specular/specular
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; cd /tmp && timeout 2m /home/ubuntu/...
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-23/worktree; cd $W;...
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; python3 -I -c " import json,sys d=j...
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; find $OUT/analysis-evidence -maxdep...
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; ls -la $OUT/analysis-evidence/probe...
running which gh && gh auth status 2>&1 | head -5; echo ---; timeout 30 gh api repos/rholder/guava-retrying --jq '.full_name, .open_issues_count, .pushed_at' 2>&1 |...
running cd /tmp; for q in "serializ" "Serializable" "NotSerializableException" "ExceptionAttempt" "ResultAttempt" "lastFailedAttempt" "transient" "RMI"; do echo "===...
running mkdir -p /tmp/crd23 && cd /tmp/crd23; timeout 120 gh api --paginate "repos/rholder/guava-retrying/issues?state=all&per_page=100" > upstream_issues.json 2>ups...
running cd /tmp/crd23; python3 -I -c " import json raw=open('upstream_issues.json').read().replace('][',',') d=json.loads(raw) for i in d: if i['number'] in (78,65):...
running cd /tmp/crd23; timeout 30 gh api repos/rholder/guava-retrying/pulls/78 --jq '.merged, .merged_at, .state' ; echo ---; timeout 30 gh api "repos/rholder/guava-...
running cd /tmp/crd23; timeout 30 gh api repos/rhuffman/re-retrying/issues/40 --jq '{number, title, state, created_at, closed_at, user: .user.login, html_url, pull_r...
running cd /tmp/crd23; timeout 30 gh api "repos/rhuffman/re-retrying/contents/src/main/java/com/github/rholder/retry/RetryException.java?ref=5c75a68acd87989fe93c605d...
running cd /tmp/crd23; timeout 30 gh api "repos/rhuffman/re-retrying/commits/6d2d838b" --jq '.sha + " " + .commit.author.name + " " + .commit.author.date + " " + (.c...
running mkdir -p /tmp/crd23/forkclone && cd /tmp/crd23/forkclone && timeout 120 git clone --quiet https://github.com/rhuffman/re-retrying.git re-retrying 2>&1 | tail...
running D=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-23; cat $D/.stop-gat...
running cd /home/ubuntu/guava-retrying-20261126/Specular/src/specular; wc -l stop_gate.py; grep -n -i "drop\|repro\|verdict\|investigation\|confirm" stop_gate.py | h...
running cd /home/ubuntu/guava-retrying-20261126/Specular/src/specular; grep -rn "DROPPED" --include=*.py . | head -40
running cd /home/ubuntu/guava-retrying-20261126/Specular/src/specular; sed -n 1440,1500p confirmlib.py; echo ----; grep -n "def _parse_verdict\|def parse_verdict\|re...
running OUT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; ls -la $OUT/analysis-evidence/probe...
running cd /tmp/crd23; for q in '"Retryer$ExceptionAttempt"' '"Retryer$ResultAttempt"' 'NotSerializableException RetryException rholder' '"RetryException" serializab...
running cd /tmp/crd23; for u in Graylog2/graylog2-server/13997 redisson/redisson/6637 Graylog2/graylog2-server/4326 typedb/typedb/3902 typedb/typedb/3666 typedb/type...
running cd /home/ubuntu/guava-retrying-20261126/Specular/src/specular; sed -n 150,200p confirmlib.py; echo ----; sed -n 4180,4240p confirmlib.py
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-23/worktree; cd $W;...
running set -u; W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-23/worktree;...
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-23/investigation.md
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-23/worktree; git -C...
## CR-D-23 结论：DROPPED

这个缺陷在代码层面确实存在，但已经有公开报告了：`rhuffman/re-retrying#40`（2019 年提出，至今 open），报告的就是从 guava-retrying 原样继承下来的同一行代码。按 skill 的唯一预过滤规则（code-review × already-reported），我跳过了 Phase 2，没有写 `repro/` 测试。

- **Source**: Code Review
- **Novelty**: KNOWN (cite: https://github.com/rhuffman/re-retrying/issues/40; fix-status: unfixed)
- **Location**: src/main/java/com/github/rholder/retry/RetryException.java:35
- **Severity**: —（DROPPED 不分级；输入标注为 Medium）
- **Reproduction test**: 无（skill 对 DROPPED 的要求是 "write no `repro/` test"）
- **Investigation record**: `.specular-output/confirmation/CR-D-23/investigation.md`

## Description
`RetryException`（`RetryException.java:32`）继承 `Exception`，所以是 `Serializable`。它把最后一次 attempt 存在非 transient 字段 `Attempt<?> lastFailedAttempt`（`:35`）里。`Attempt` 接口没有继承 `Serializable`，库里仅有的两个实现 `Retryer$ResultAttempt`（`Retryer.java:199-200`）和 `Retryer$ExceptionAttempt`（`:247-248`）也都没有实现它，源码里也没有 `serialVersionUID`、`transient` 或 `writeReplace`。结果是：`call()` 抛出的任何 `RetryException`，在 Java 序列化时都会失败。

## Trigger scenario
1. `Retryer.call()` 抛出 `RetryException`，有两种情况：stop strategy 决定停止（`Retryer.java:174`），或在等待期间被中断（`:181`）。
2. 这个异常带着的 attempt 一定是 `ResultAttempt` 或 `ExceptionAttempt`。
3. 调用方让这个异常经过 Java 序列化，例如：
   - RMI；
   - 跨 JVM 传递任务失败的框架；
   - session replication；
   - 直接调用 `ObjectOutputStream.writeObject(e)`；
   - 经 `wrap()` 提交给 executor 后，`Future.get()` 抛出的 `ExecutionException`（它的 cause 链里含这个异常）。
4. 默认序列化会走到 `lastFailedAttempt`，抛出 `java.io.NotSerializableException: com.github.rholder.retry.Retryer$ExceptionAttempt`。如果最后一次 attempt 是被拒绝的结果，则是 `$ResultAttempt`。

库里没有任何代码兜住这个失败。

## Developer intent
- **上游 tracker**（`rholder/guava-retrying`，用 `gh api --paginate` 全量抓取）：106 个 issue/PR（所有状态，编号到 #107）、185 条 issue 评论、5 条 PR review 评论，没有一处提到序列化。
  - 相关关键词只命中两条，都与序列化无关：#78（把 `ExceptionAttempt`/`ResultAttempt` 改成 public，已关闭且未合并）和 #65（一个功能提案）。
  - 上游 HEAD 仍是 `177b6c9`（2016-05-10），之后没有任何修复。
- **代码历史与文档**：`RetryException.java:31-35` 的 blame 是 `6d2d838b`（2012）；提交历史里没有任何关于 serialization 的信息。`README.md:55` 写明 `RetryException` "contains information about the last failed attempt"，说明携带 attempt 是有意设计，但没有任何地方提到它不能序列化。测试只检查 `getLastFailedAttempt()` 的内容，没有序列化测试。
- **已知报告**：`rhuffman/re-retrying#40`，标题 "RetryException is not serializable bc Attempt is not"，eschultink 于 2019-05-31 提出，至今 open；2021-04-05 jgiardin 留言说也遇到了。它和本 finding 是同一机制、同一位置：
  - re-retrying 自称是 guava-retrying 的 fork，它的历史包含上游 HEAD `177b6c9` 和 tag `v2.0.0`。
  - #40 链接的 `RetryException.java#L32-L34`（@`5c75a68`）做 blame，和 2.0.0 的 `:31-35` 都来自同一个上游提交 `6d2d838b`，是同一行代码。
  - 只有次要位置不同：fork 后来把两个实现合并成了一个具体类 `Attempt`，而 2.0.0 是 `ResultAttempt`/`ExceptionAttempt`。两者都没有实现 `Serializable`，所以 #40 说的原因原样适用于 2.0.0。
  - fork 的 HEAD 仍是 `5c75a68`，源码里也没有 `Serializable`/`transient`，所以两边都还没修（unfixed）。
- 在 GitHub 全站搜 `"Retryer$ExceptionAttempt"` / `"Retryer$ResultAttempt"`，命中的都是其他项目里的报错调用栈，正文和评论都没有提到序列化。Specular 的已有发现库查询（`specular findings lookup`）返回 `[]`。

## Reproduction result
没有运行 Phase 2，原因是 code-review × known 预过滤。下面是支撑这个判定的命令真实输出：
```
## [2] blame guava-retrying RetryException.java:31-35
6d2d838b (Ray Holder 2012-11-17 21:28:26 -0600 32) public final class RetryException extends Exception {
6d2d838b (Ray Holder 2012-11-17 21:28:26 -0600 35)     private final Attempt<?> lastFailedAttempt;
## [4] blame fork RetryException.java:31-34 @5c75a68 (the lines issue #40 links)
6d2d838b (Ray Holder 2012-11-17 21:28:26 -0600 32) public final class RetryException extends Exception {
6d2d838b (Ray Holder 2012-11-17 21:28:26 -0600 34)     private final Attempt<?> lastFailedAttempt;
## [5] ancestry
177b6c9 (guava-retrying HEAD) IS an ancestor of fork 5c75a68
## [6] fork issue #40
#40 [open] RetryException is not serializable bc Attempt is not | opened 2019-05-31T16:44:41Z by eschultink | comments=1 | https://github.com/rhuffman/re-retrying/issues/40
## [7] upstream rholder/guava-retrying default-branch HEAD
177b6c9b9f 2016-05-10T02:23:41Z
## [8] Serializable/transient anywhere in guava-retrying main sources
(none)
```
分析阶段已有的 probe `analysis-evidence/probes/main/SerProbe_.jdk21.log` 也表明 2.0.0 上的机制和报告一致。它不是 Phase 2 复现：
```
NotSerializableException: com.github.rholder.retry.Retryer$ExceptionAttempt
exit=0
```
REPRODUCED 前的检查清单不适用，因为结论不是 REPRODUCED。按 persistent-findings 规则，DROPPED 不需要写 `issue.json`。

## Recommendation
- 不要把它当作新缺陷再报一次；如果向上游报告，引用 `rhuffman/re-retrying#40`。
- 修复方向（两个仓库都适用）：
  - 把 `lastFailedAttempt` 标成 `transient`，再加上 `serialVersionUID`。跨 JVM 需要的信息（`numberOfFailedAttempts`、message、cause）本来就能序列化。代价是反序列化后 `getLastFailedAttempt()` 会返回 `null`，要么在 Javadoc 里写明，要么在 `readObject` 里重建一个只含 attempt number、delay 和 hasException 的快照。
  - 不建议直接让 `Attempt` 继承 `Serializable`：`ResultAttempt.result` 是任意用户类型 `R`，照样可能序列化失败。
- 调用方现在就能用的规避：在序列化边界 catch `RetryException`，换成一个只带 `getNumberOfFailedAttempts()` 和 `getCause()` 的可序列化异常。

---

## Entry 25: Code-review Scenario 5: post-attempt decision steps run outside the attempt's try/catch and built-in wait/stop arithmetic is unchecked

- **Finding ID**: CR-5
- **Status**: FALSE POSITIVE
- **Debate**: not run
- **Transcript**: /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-5/debate.md

running pwd; ls -la; find / -type d -name "bug-confirmation" 2>/dev/null | head -20
running ls -la ~/.claude/skills 2>/dev/null; ls -la ~/.claude/ 2>/dev/null; ls -la /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation /home/ubuntu...
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; cat SKILL.md; echo ======; cat guide.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; cat phases/01-investigation.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; cat phases/02-reproduction.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; cat references/persistent-findings.md
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-5/worktree; cd $W && g...
running O=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; cat $O/persistent-findings-context.js...
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-5/worktree; cd $W; fin...
reading /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-5/worktree/src/main/java/com/github/rholder/...
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-5/worktree/src/main/ja...
running O=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; python3 -I -c " import json,sys d=jso...
running O=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; wc -l $O/analysis-report.md $O/modeli...
running O=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; sed -n '1,27p;44,56p;213,221p;287,340...
running which gh && gh auth status 2>&1 | head -5; ls /home/ubuntu/scratch/guava-retrying-archaeology/ 2>/dev/null | head -30
running cd /tmp; timeout 60 gh api -X GET repos/rholder/guava-retrying --jq '{full_name, pushed_at, updated_at, open_issues_count, archived}' 2>&1; timeout 60 gh iss...
running cd /tmp; timeout 60 gh pr list -R rholder/guava-retrying --state all --limit 200 --json number,title,state,updatedAt,closedAt,mergedAt 2>&1 | python3 -I -c "...
running cd /tmp; timeout 60 gh pr view 107 -R rholder/guava-retrying --json title,body,state,closedAt,mergedAt,author,files,commits --jq '{title,state,closedAt,merge...
running cd /tmp; for q in "negative" "overflow" "IllegalArgumentException" "timeout value is negative" "NullPointerException" "Integer.MAX_VALUE" "attempt number" "e...
running cd /tmp; for n in 59 99 101 63; do echo "=================== #$n"; timeout 60 gh pr view $n -R rholder/guava-retrying --json title,body,comments --jq '"TITLE...
running cd /tmp; for n in 93 86 87 97 25 12 52 28 23; do echo "=================== #$n"; timeout 60 gh issue view $n -R rholder/guava-retrying --json title,body,comm...
running cd /home/ubuntu/guava-retrying-20261126/Specular; ls case-studies | head -80; grep -rli "guava-retrying\|rholder" case-studies 2>/dev/null | head; cd /tmp; t...
running cd /home/ubuntu/guava-retrying-20261126/Specular; ls -a | head -40; ls .venv/bin 2>/dev/null | grep -i specul; find / -maxdepth 6 -name specular -type f -per...
running S=/home/ubuntu/guava-retrying-20261126/Specular; O=$S/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; head -20 $S/specular; timeout 1...
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-5/worktree; cd $W; git...
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-5/worktree; cd $W; sed...
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-5/worktree; cd $W; gre...
running ls ~/.m2/repository/com/google/guava/guava/ 2>/dev/null; ls ~/.m2/repository/com/google/code/findbugs/jsr305/ 2>/dev/null; which mvn java javac; java -versio...
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-5/worktree; cd $W; sed...
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-5/worktree/src/main/ja...
Phase 1 证据已收齐。现在写入 `investigation.md`（代码审计、调用链、可达性、安全措施、开发者意图、known-status）。
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-5/investigation.md
running ls /home/ubuntu/scratch/jdk-src/ 2>/dev/null; for v in 8 11 21; do f=$(find /home/ubuntu/scratch/jdk-src/$v -name jvm.cpp -path "*prims*" 2>/dev/null | head...
running for v in 8 11 21; do echo "== $v"; grep -rln "JVM_Sleep" /home/ubuntu/scratch/jdk-src/$v 2>/dev/null | head -5; done; ls /home/ubuntu/scratch/jdk-src/21 | head
running for v in 8 11 21; do echo "======== JDK $v"; awk '/JVM_ENTRY\(void, JVM_Sleep/{p=1} p{print NR": "$0} /^JVM_END/{if(p){exit}}' /home/ubuntu/scratch/jdk-src/$...
running mkdir -p /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-5/build && ls /...
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/test_bugCR-5_decision_step_sweep.sh
running R=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro; chmod +x $R/test_bugCR-5_decisi...
running R=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro; cut -c1-330 $R/CR-5.log
running R=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro; F=$R/test_bugCR-5_decision_step...
JDK 21 和 JDK 11 结果一致：`UNATTRIBUTED=0`，`RESULT: NO_OTHER_DEFECT_FOUND`。取出最终日志中要引用的确切行。
running R=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro; sed -n '1,4p' $R/CR-5.log | sed...
running R=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro; grep -nE "^\[SEPARATE \[D-(21|2...
结论：CR-5 在这个机制中没有发现 D-16..D-22、MC-10、MC-7 之外的缺陷。机制本身是真实的，但其中每一个缺陷都已由这些独立候选覆盖。因此对 CR-5 作为独立候选的判定是 FALSE POSITIVE。下面是供 dispatcher 解析的结构化结果。

- **Source**: Code Review
- **Novelty**: NEW
- **Location**: src/main/java/com/github/rholder/retry/Retryer.java:166
- **Reproduction test**: `.specular-output/repro/test_bugCR-5_decision_step_sweep.sh`（Level 0 + Level 2）；日志在 `repro/CR-5.log`（JDK 21）和 `repro/CR-5.jdk11.log`（JDK 11）

## Description
CR-5 要求在 Scenario 5 机制中，找出 D-16..D-22、MC-10、MC-7 以外的缺陷。这里说的机制是：决策步骤在 `Retryer.java:166-182` 中运行，位于 attempt 的 try/catch 之外；内置的 wait/stop 算术没有任何检查。结果是一个都没有找到。

- **未文档化的退出。** 我用每一种内置的 listener、predicate、stop、wait 和 block 路径驱动了每个决策步骤。`call()` 出现的未文档化退出只有两种：
  - 负数 sleep 时 `Thread.sleep` 抛出 IAE，对应 D-16、D-17 和 MC-10。
  - `exceptionWait` 返回 null 拆箱时抛出 NPE，对应 D-18。
  - 修改 builder 引发的 listener CME 属于 MC-7，没有重跑。
- **其余部分符合契约。** 其他所有退出都在文档列出的集合内（`Retryer.java:146-153`）：
  - `RetryException` 的计数、最后一次 attempt 和 cause 都正确。
  - 在 listener、wait 计算、sleep、stop 各个步骤到达的中断，都以 `RetryException` 结束，并保留了中断标志。
- **算术清单。** 我检查了 `src/main` 中每一处 `toMillis`、`+`、`*`、`%`、`Math.*` 和计数器，偏离的位置只有以下几处：
  - D-16：join 求和
  - D-17 和 D-18：exceptionWait
  - D-19：int 计数器回绕
  - D-20：incrementing
  - D-21：Fibonacci 回绕
  - D-22：stopAfterDelay 的向下取整

  Exponential（含超过 2^53 的 multiplier）、random、fixed、`stopAfterAttempt`（包括 `Integer.MAX_VALUE`）、`neverStop` 以及延迟测量都正确。`RandomWait` 的 `Math.abs(Long.MIN_VALUE)` 路径不可达。
- **两个后果变体，都归属已有条目，不是新缺陷：**
  - D-20 的负增量情形，与 D-20 是同一个表达式（`WaitStrategies.java:282`）：`incrementingWait(500ms, Long.MIN_VALUE/2 ms)` 依次给出 `500, 0, 0, 4611686018427388404, 500`。
  - D-19 的后果比 “wait 归零” 更严重：计数器回绕后，`incrementingWait(5s, -1s)` 收到的 attempt 编号是 `Integer.MIN_VALUE`，返回 `2147483654000` ms（约 68 年）。也就是说，循环本应立即重试，实际却会一直 sleep 下去。
- **不计为缺陷：`fib()` 每次 attempt 的成本是 O(n)。**
  - 计算出的 sleep 值仍然正确。
  - 实测为 0.273 ns/iteration（JDK 21），0.364 ns/iteration（JDK 11）。
  - 每次计算耗费的 CPU 只有在以下条件下才会达到上限：上限为 2 ms 时，单个 `call()` 连续失败约 4 小时；上限为 10 ms 时约 4.2 天。上限 ≥1 s 时，在 int 计数器范围内永远达不到。
  - 这是性能问题，不属于本机制的缺陷类别（没有错误的值、退出或计数）。

## Trigger scenario
所有检查都通过公开 API 构建，库源码未修改（`177b6c9`，Guava 22.0，使用默认的 `ThreadSleepStrategy`）。

- **Part A（Level 0）：54 次真实的 `Retryer.call()` 运行。**
  - 覆盖所有内置 wait 和 stop 工厂的边界参数，包括 `Long.MAX_VALUE`、`DAYS` 饱和、亚毫秒值和负增量。
  - 还覆盖了 builder 的各个 `retryIf*` predicate，以及在调用前、listener 中、wait 计算中、sleep 中到达的中断。
  - 每次运行都用文档契约作 oracle 判定：退出类型、`RetryException` 的计数/最后 attempt/cause、中断标志、listener 的编号和延迟单调性、计算出的 sleep 序列。
  - 另有 7 个阳性对照，复现独立候选的特征签名。
- **Part B（Level 2）：对公开 strategy API 做全扫。**
  - 输入是用户实现的 `Attempt`，attempt 编号取 1..`Integer.MAX_VALUE`（真实 int 循环可达），延迟 ≥0。共 1.33 亿次评估。
  - 对 Random 的 LCG 做了穷举检查：65536 个状态 × 0..2000 个插入抽样。
- **Part C：** 测量 `fib(n)` 的成本。

## Developer intent
- `Retryer.call` 的 Javadoc 只列出三种结果：返回值、`ExecutionException`、`RetryException`（中断时会设置标志）。
- 各工厂的 Javadoc 写明：exponential 和 Fibonacci 增长到 “up to the maximumTime”；join 为 “total of all wait times”；`stopAfterAttempt` 为 “stops after N failed attempts”。
- `WaitStrategiesTest:103,116,140,153` 断言在 attempt `Integer.MAX_VALUE` 时上限依然成立；`StopStrategiesTest:41-51` 断言 `>=` 边界。
- 源码中没有 TODO/FIXME。用于钳位的代码来自 `fd8b13b` 和 `ce0bc7d`，提交信息中没有讨论溢出。
- 上游检索结果：61 个 issue 和 45 个 PR，包括 2026-09 关闭的 #107 和 #84，再加上关键词检索和 GitHub 全站检索，都没有报告这个机制。
  - 相关但不同的条目有：#63（不 sleep 的用户 `BlockStrategy`）、#93（文档单位）、#97/#99（`%d` 格式化）、#101（跳过 `sleep(0)`）、#86。
- `specular findings lookup` 返回 `[]`，没有更早的 Specular 数据集条目。

## Reproduction result
- **执行的命令：**
  - `timeout 15m bash repro/test_bugCR-5_decision_step_sweep.sh`（JDK 21）
  - `JAVA_HOME_RUN=/usr/lib/jvm/java-11-openjdk-amd64 timeout 15m bash repro/test_bugCR-5_decision_step_sweep.sh <worktree> <build-jdk11>`
  - 两次都以 exit 0 结束。
- **逐级尝试：**
  - **Level 0（Part A）：** 没有找到无法归因的异常。
  - **Level 1：** 只用中断作为时序手段（看门狗中断、listener 或 wait 中自我中断），同样没有异常。
  - **Level 2（Part B）：** 没有异常。
  - **Level 3：** 没有可施加的对象。这些决策步骤是调用线程上的顺序代码，没有可以拉宽的时间窗口。

JDK 21 日志摘录（`repro/CR-5.log`）：
```
source:  <out>/repro/../confirmation/CR-5/worktree  (git 177b6c9, status: 0 changed files)
guava:   /home/ubuntu/.m2/repository/com/google/guava/guava/22.0/guava-22.0.jar sha1=3564ef3803de51fb0530a8377ec6100b33b0d073
[OK]            W24  fixedWait(Long.MAX_VALUE DAYS) [saturates], neverStop, interrupt after 300ms -> RETRY(count=1,last#=1,cause=IOException:fail#1) calls=1 flag=true sleeps=[9223372036854775807] elapsed=300.223ms watchdog-interrupt@300ms
[OK]            S06  stopAfterDelay(30ms) + noWait, always failing -> RETRY(count=6334,last#=6334,cause=IOException:fail#6334) calls=6334 flag=false sleeps=[0,0,0,0,0,0,...(+6327)] elapsed=30.023ms
[OK]            I04  interrupt while listeners run (attempt 2) + noWait -> RETRY(count=2,last#=2,cause=IOException:fail#2) calls=2 flag=true sleeps=[0,0] elapsed=0.117ms
[OK]            I05  interrupt while the wait is computed (attempt 2) + fixedWait(1ms) -> RETRY(count=2,last#=2,cause=IOException:fail#2) calls=2 flag=true sleeps=[1,1] elapsed=1.119ms
[SEPARATE D-16]   K16a  join(fixedWait(Long.MAX_VALUE ms), fixedWait(1s)) -> OTHER(java.lang.IllegalArgumentException: timeout value is negative) calls=1 flag=false sleeps=[-9223372036854774809] elapsed=0.055ms
[SEPARATE D-18]   K18  exceptionWait(IOException, ->null) -> OTHER(java.lang.NullPointerException: Cannot invoke "java.lang.Long.longValue()" because the return value of "com.google.common.base.Function.apply(Object)" is null) calls=1 flag=false sleeps=[] elap[…]
[SEPARATE D-20]   K20  incrementingWait(20ms, +Long.MAX_VALUE ms) + stopAfterAttempt(4) -> RETRY(count=4,last#=4,cause=IOException:fail#4) calls=4 flag=false sleeps=[20,0,18] elapsed=38.186ms
[SEPARATE MC-10/D-17]   K10  pre-interrupted + exceptionWait(->-5) -> OTHER(java.lang.IllegalArgumentException: timeout value is negative) calls=1 flag=true sleeps=[-5] elapsed=0.020ms
[OK]            B1  ExponentialWait: >=0, <=cap, non-decreasing, = min(cap, m*2^n) (double rel.err <= 1e-12): 54 configs, 7182 evaluations, unattributed=0
[OK]            B4-LCG  of the 65536 LCG states that yield hi=0x80000000, none yields lo=0 after 0..2000 intervening next() calls -> Math.abs(Long.MIN_VALUE) unreachable without >2000 concurrent draws inside one nextLong()
[OK]            B8  stopAfterAttempt(N): stops exactly when attempt >= N, for N up to Integer.MAX_VALUE: 6 configs, 28 evaluations, unattributed=0
[SEPARATE [D-22]]  B9  stopAfterDelay: never stops before the requested duration except via sub-ms truncation (D-22); 4 configs saturate beyond 2^63 ms (unreachable): 63 configs, 3021 evaluations, unattributed=0, known {D-22=15} [...]
[VARIANT D-20]  incrementingWait(500ms, Long.MIN_VALUE/2 ms) sleeps for attempts 1..5: 500, 0, 0, 4611686018427388404, 500  (documented: 500 then clamped 0s)
[VARIANT D-19]  incrementingWait(5s, -1s) by attempt number, incl. the numbers Retryer passes after its int counter wraps (Integer.MIN_VALUE...): #1->5000 #2->4000 #6->0 #7->0 #2147483647->0 #-2147483648->2147483654000 #-2147483647->2147483653000
[MEASURE]       fib(n) for n=100,000,000: 27.290 ms per computeSleepTime (0.273 ns/iteration)
[PROJECTION]    cap=2 ms: fib cost reaches the cap at attempt ~7.33e+06, i.e. after ~4.1 h (0.2 days) of uninterrupted retrying in one call()
==== SUMMARY ====
Part A runs / Part B families: OK=61 SEPARATE-CANDIDATE signatures=12 NOTE=0 UNATTRIBUTED=0
Part B strategy evaluations: 133014354
Separate-candidate signatures observed (D-16..D-22, MC-10; not CR-5 defects): {D-16=17, D-17=5, D-18=2, D-20=13272, D-21=459, D-22=16, MC-10/D-17=1}
UNATTRIBUTED anomalies (candidate other defects): 0
RESULT: NO_OTHER_DEFECT_FOUND
exit code: 0
```
JDK 11（`repro/CR-5.jdk11.log`，`java.version=11.0.33.1`）的汇总与 JDK 21 完全相同：`OK=61 SEPARATE-CANDIDATE signatures=12 NOTE=0 UNATTRIBUTED=0`，`RESULT: NO_OTHER_DEFECT_FOUND`，`exit code: 0`。

## Recommendation
CR-5 不需要单独修复。这个机制的修复都归属各个独立候选：

- 在 `block` 之前校验或钳位计算出的 sleep：MC-10、D-16、D-17。
- 在 join、incrementing、Fibonacci 中使用饱和算术：D-16、D-20、D-21。D-20 的修复要覆盖负增量情形（`WaitStrategies.java:282`）。
- 在 `exceptionWait` 中检查 null：D-18。
- 把 attempt 计数器改为 `long`，或在溢出时饱和：D-19。这样也会消除计数器回绕后负增量导致的约 68 年 sleep。
- 让 `stopAfterDelay` 按 `toNanos` 比较：D-22。

建议把上面两个变体转告 D-19 和 D-20 的负责人。`fib()` 的 O(n) 成本属于可选的性能改进（例如在结果达到上限后停止迭代）。

---
