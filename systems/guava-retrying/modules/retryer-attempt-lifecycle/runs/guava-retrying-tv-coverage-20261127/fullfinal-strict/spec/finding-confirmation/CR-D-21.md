# CR-D-21

Status: MASKED
Run: guava-retrying-opus55max-20261126

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
- **Status**: MASKED
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
