# MC-6

Status: REPRODUCED
Run: guava-retrying-opus55max-20261126

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
- **Status**: REPRODUCED
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
- **Status**: REPRODUCED
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
