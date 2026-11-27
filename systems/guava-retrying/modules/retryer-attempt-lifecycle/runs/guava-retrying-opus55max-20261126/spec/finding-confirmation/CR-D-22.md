# CR-D-22

Status: REPRODUCED
Run: guava-retrying-opus55max-20261126

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
- **Status**: REPRODUCED
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
