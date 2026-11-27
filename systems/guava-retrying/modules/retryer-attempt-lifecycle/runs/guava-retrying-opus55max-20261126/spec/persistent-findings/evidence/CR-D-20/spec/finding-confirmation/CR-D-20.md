# CR-D-20

Status: REPRODUCED
Run: guava-retrying-opus55max-20261126

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
- **Status**: REPRODUCED
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
