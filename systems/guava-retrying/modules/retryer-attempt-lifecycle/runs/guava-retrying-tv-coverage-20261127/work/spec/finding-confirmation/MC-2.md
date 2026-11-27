# MC-2

Status: REPRODUCED
Run: guava-retrying-opus55max-20261126

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
- **Status**: REPRODUCED
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
- **Status**: REPRODUCED
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
