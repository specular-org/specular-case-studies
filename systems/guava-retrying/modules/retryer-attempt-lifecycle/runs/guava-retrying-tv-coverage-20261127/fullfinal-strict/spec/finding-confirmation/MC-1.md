# MC-1

Status: REPRODUCED
Run: guava-retrying-opus55max-20261126

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
- **Status**: REPRODUCED
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
