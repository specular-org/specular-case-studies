# CR-D-19

Status: REPRODUCED
Run: guava-retrying-opus55max-20261126

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
- **Status**: REPRODUCED
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
