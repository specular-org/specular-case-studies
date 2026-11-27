# MC-7

Status: REPRODUCED
Run: guava-retrying-opus55max-20261126

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
- **Status**: REPRODUCED
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
- **Status**: REPRODUCED
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
