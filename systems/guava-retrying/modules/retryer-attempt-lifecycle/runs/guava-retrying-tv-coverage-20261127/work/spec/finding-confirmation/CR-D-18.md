# CR-D-18

Status: REPRODUCED
Run: guava-retrying-opus55max-20261126

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
- **Status**: REPRODUCED
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
