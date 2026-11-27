# CR-D-17

Status: REPRODUCED
Run: guava-retrying-opus55max-20261126

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

- **Status**: REPRODUCED
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
