# CR-D-12

Status: REPRODUCED
Run: guava-retrying-opus55max-20261126

running ls -la /home/ubuntu/.claude/projects/-home-ubuntu-guava-retrying-20261126-Specular-runs-guava-retrying-opus55max-20261126-guava-retrying--specular-output-con...
running find / -type d -name "bug-confirmation" 2>/dev/null | head -20
running ls -la ~/.claude/skills/ 2>/dev/null; ls -la /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; find /home/ubuntu/guava-retrying-20261126...
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation && cat SKILL.md && echo ===== && cat guide.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation && cat phases/01-investigation.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation && cat phases/02-reproduction.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation && cat references/persistent-findings.md && echo ====== && cat references/repair-req...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/ && ls -la && echo ==== && ls -la con...
已读完 bug-confirmation skill（guide + Phase 1/2 + references）。下面开始 Phase 1：先做 persistent-findings lookup，再审计代码。
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/ && cat persistent-findings-context.j...
running ls /home/ubuntu/guava-retrying-20261126/Specular/ ; ls /home/ubuntu/guava-retrying-20261126/Specular/bin 2>/dev/null; find /home/ubuntu/guava-retrying-202611...
running cd /home/ubuntu/guava-retrying-20261126/Specular && head -30 specular; echo ====; timeout 60 ./specular findings --help 2>&1 | head -40
running cd /home/ubuntu/guava-retrying-20261126/Specular && W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.sp...
Persistent-findings lookup 无命中（`[]`），按正常流程继续。现在看 worktree 源码与 Guava 22.0 的 `SimpleTimeLimiter`。
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-12/worktree && ls -...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-12/worktree && cat...
running find / -path /proc -prune -o \( -name "guava-22.0*.jar" -o -type d -name "guava-22.0" \) -print 2>/dev/null | head -20
running ls -la /home/ubuntu/.m2/repository/com/google/guava/guava/22.0/ /home/ubuntu/scratch/guava22-sources-dl/ /home/ubuntu/scratch/guava-jars/; sha256sum /home/ub...
running sha1sum /home/ubuntu/.m2/repository/com/google/guava/guava/22.0/guava-22.0.jar /home/ubuntu/scratch/guava22-sources-dl/guava-22.0-sources.jar; cat /home/ubun...
running cat -n /home/ubuntu/scratch/guava22-sources-dl/extracted/com/google/common/util/concurrent/SimpleTimeLimiter.java | sed -n '1,280p'
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-12/worktree && git...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-12/worktree && cat...
running sed -n '1,200p' /home/ubuntu/scratch/guava22-sources-dl/extracted/com/google/common/util/concurrent/TimeLimiter.java | grep -n -B3 -A40 "boolean amInterrupti...
running grep -n "callWithTimeout\|amInterruptible\|@deprecated\|@throws\|stack" /home/ubuntu/scratch/guava22-sources-dl/extracted/com/google/common/util/concurrent/T...
running sed -n '78,105p' /home/ubuntu/scratch/guava22-sources-dl/extracted/com/google/common/util/concurrent/TimeLimiter.java
running which gh && timeout 30 gh auth status 2>&1 | head -10
running for q in "stack trace" "stacktrace" "setStackTrace" "throwCause" "combineStackTraces" "memory leak" "OutOfMemory" "SimpleTimeLimiter" "fixedTimeLimit" "callW...
running timeout 60 gh api --paginate "repos/rholder/guava-retrying/issues?state=all&per_page=100" --jq '.[] | "\(.number)\t\(.state)\t\(if .pull_request then "PR" el...
running for n in 3 94 96; do echo "########## #$n"; timeout 30 gh issue view $n --repo rholder/guava-retrying --comments 2>&1 | head -80; done
running for n in 3 94 96; do echo "########## #$n"; timeout 30 gh api "repos/rholder/guava-retrying/issues/$n" --jq '"TITLE: \(.title)\nSTATE: \(.state)\nBODY:\n\(.b...
running for n in 1 82 95 103 107; do echo "########## PR #$n"; timeout 30 gh api "repos/rholder/guava-retrying/pulls/$n" --jq '"TITLE: \(.title)\nSTATE: \(.state) me...
running for n in 95 103; do echo "########## PR #$n AttemptTimeLimiters diff"; timeout 30 gh api "repos/rholder/guava-retrying/pulls/$n/files" --jq '.[] | select(.fi...
running for q in "SimpleTimeLimiter stack trace" "combineStackTraces" "throwCause stack" "callWithTimeout stack trace" "SimpleTimeLimiter setStackTrace" "TimeLimiter...
running timeout 30 gh api "repos/google/guava/issues/6599" --jq '"TITLE: \(.title)\nSTATE: \(.state) closed_at=\(.closed_at) state_reason=\(.state_reason)\nBODY:\n\(...
running for q in "TimeLimiter stack trace" "SimpleTimeLimiter exception" "callWithTimeout" ; do echo "### google/guava: $q"; timeout 30 gh search issues --repo googl...
running for n in 3550 3725; do echo "########## google/guava #$n"; timeout 30 gh api "repos/google/guava/issues/$n" --jq '"TITLE: \(.title)\nSTATE: \(.state)\nBODY:\...
using ToolSearch
searching for SimpleTimeLimiter callWithTimeout combineStackTraces stack trace grows reused exception
searching for guava-retrying fixedTimeLimit exception stack trace growing memory
running cd /home/ubuntu/guava-retrying-20261126/Specular && ls case-studies | head -80; grep -rIl -i "guava-retrying\|combineStackTraces\|SimpleTimeLimiter" case-stu...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/ && ls -la analysis-evidence/ analysi...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/ && cat analysis-evidence/build/pom.x...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-12/worktree/src/mai...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-12/worktree && sed...
running java -version 2>&1; javac -version 2>&1; ls ~/.m2/repository/com/google/code/findbugs/jsr305/ 2>/dev/null; ls ~/.m2/repository/com/google/code/findbugs/jsr30...
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-12/worktree && git...
Worktree 为 `177b6c9`（v2.0.0+1，未修改），与 persistent-findings 的 source 一致。现在写 Phase 1 记录 `investigation.md`。
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-12/investigation.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-12/worktree/src/mai...
开始写复现脚本（自包含：从 worktree 用 `javac --release 8` 编译库，Guava 22.0 + jsr305 2.0.2 取自 `~/.m2`，然后跑各场景，全部带外层 `timeout`）。
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/test_bugCR-D-12_reused_exception_stack_growth.sh
先做一次标定：手动编译并单独试跑 OOM 场景，确认耗时和触发点，再跑完整脚本。
running set -e; S=/tmp/crd12-calib; rm -rf $S; mkdir -p $S/lib $S/cls $S/src WT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/...
running S=/tmp/crd12-calib; ls -R $S/cls | head; ls $S/lib/com/github/rholder/retry | head -40
running S=/tmp/crd12-calib; wc -l $S/src/ReproCRD12.java; R=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.spec...
running S=/tmp/crd12-calib; R=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/test_bugCR-D...
running S=/tmp/crd12-calib; CP=$HOME/.m2/repository/com/google/guava/guava/22.0/guava-22.0.jar:$HOME/.m2/repository/com/google/code/findbugs/jsr305/2.0.2/jsr305-2.0....
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/test_bugCR-D-12_reused_exception_stack_growth.sh
Now rewrite the driver/evaluation section so each scenario is checked from its own output file.
running R=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/test_bugCR-D-12_reused_exception...
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/test_bugCR-D-12_reused_exception_stack_growth.sh
脚本已就绪。后台运行完整复现（输出 tee 到 `repro/CR-D-12.log`），并用基于 PID 的等待阻塞到结束。
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro && bash -n test_bugCR-D-12_reus...
running PID=$(cat /tmp/crd12-run.pid); end=$((SECONDS+570)); while kill -0 $PID 2>/dev/null && [ $SECONDS -lt $end ]; do sleep 5; done; if kill -0 $PID 2>/dev/null;...
完整运行结束：25 项检查全部 `ok`，`RESULT: BUG TRIGGERED (PASS)`，脚本退出码 0。查看日志关键段落以便摘录。
running L=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/CR-D-12.log; sed -n '1,12p' $L;...
running L=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/CR-D-12.log; grep -n -A5 'ReproC...
running J19=/home/ubuntu/scratch/guava-jars/guava-19.0.jar; ls ~/.m2/repository/com/google/guava/guava/ 2>/dev/null; sha1sum $J19; for j in $J19 $HOME/.m2/repository...
running for v in 10.0.1 14.0.1 16.0.1; do j=$HOME/.m2/repository/com/google/guava/guava/$v/guava-$v.jar; [ -f $j ] || continue; echo "== guava $v sha1=$(sha1sum $j |...
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/test_bugCR-D-12_reused_exception_stack_growth.sh
running cd /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro && bash -n test_bugCR-D-12_reus...
running L=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/CR-D-12.log; grep -n -A2 'growth...
running cd /home/ubuntu/guava-retrying-20261126/Specular && grep -rn "def .*validate\|required\|\"status\"\|ALLOWED\|allowed_status\|STATUSES\|title" src/specular/fi...
running cd /home/ubuntu/guava-retrying-20261126/Specular/src/specular && grep -n "def _validate_proposal\|def validate\|REQUIRED\|required =\|_STATUS\|STATUS\|'sourc...
running cd /home/ubuntu/guava-retrying-20261126/Specular/src/specular && sed -n '240,278p;355,470p' persistent_findings.py
running cd /home/ubuntu/scratch/guava-retrying-src/guava-retrying/src/main/java/com/github/rholder/retry && c(){ printf '%s\t%s\n' "$(grep -cxF -- "$2" "$1")" "$1: $...
边界行均唯一。先在 `investigation.md` 中补入 Guava 多版本字节码核查（属于 Phase 1 代码审计事实）。
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-12/investigation.md
现在提取最终日志中的原文行（用于 verdict 正文的逐字粘贴）。
running L=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/CR-D-12.log; sed -n '1,6p' $L; e...
写入本 finding 的确认记录 `confirmation.md`（即 verdict 正文），随后写 `issue.json` 并校验。
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-12/confirmation.md
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; python3 - "$W/confirmation/CR-D-12/is...
`issue.json` 校验通过（`"valid": true`）。最后清理自己创建的临时文件，并确认 worktree 未被改动。
running rm -rf /tmp/crd12-calib /tmp/crd12-run.pid; ls -d /tmp/crd12-build.* 2>/dev/null || echo "no leftover build dirs"; git -C /home/ubuntu/guava-retrying-2026112...
CR-D-12 已用纯公共 API（Level 0）复现。同一个异常对象被重复抛出时，`fixedTimeLimit` 每次失败都会把调用方的整段栈追加到它上面，而且永远不会清掉：栈帧、日志、CPU 和占用的堆都持续增长，最终 OOM。两个对照（`noTimeLimit`、每次新建异常）都没有变化。未找到任何已有报告，所以是 NEW。完整记录在 `confirmation/CR-D-12/confirmation.md`。

- **Source**: Code Review
- **Novelty**: NEW
- **Status**: REPRODUCED
- **Severity**: Medium
- **Location**: src/main/java/com/github/rholder/retry/AttemptTimeLimiters.java:107
- **Reproduction test**: `repro/test_bugCR-D-12_reused_exception_stack_growth.sh` (Level 0); output in `repro/CR-D-12.log`

## Description
`FixedAttemptTimeLimit.call` (`AttemptTimeLimiters.java:107`) runs every attempt through Guava's deprecated four-argument `SimpleTimeLimiter.callWithTimeout(..., true)`. When the callable fails, that method runs `throw throwCause(e, true /* combineStackTraces */)` (`SimpleTimeLimiter.java:162-163`). `throwCause` then calls `cause.setStackTrace(concat(cause.getStackTrace(), e.getStackTrace()))` (`:256-259`). `cause` is the exact object the user's callable threw, and `e`'s stack is the caller thread's whole stack. guava-retrying stores and rethrows that same object (`Retryer.java:162-163`, `:171`, `:174`; `RetryException.java:57`).

If the callable throws the same exception object again, each failed attempt adds one more caller stack, and nothing ever removes it. Common sources of a reused object:
- a preallocated sentinel exception;
- a "cheap" exception that only overrides `fillInStackTrace()`;
- the JDK's `CompletableFuture.join()`, which rethrows the same `CompletionException` object every time.

Retained heap, CPU per attempt and log volume therefore grow without bound until `OutOfMemoryError`. `noTimeLimit()` leaves the same exception untouched. Guava's own Javadoc says the exception is "propagated to the caller exactly as-is". Every Guava version 2.0.0 can link against has this path (checked with `javap` for 10.0.1, 14.0.1, 16.0.1, 19.0 and 22.0).

## Trigger scenario
1. Build a retryer through the public API with `.withAttemptTimeLimiter(AttemptTimeLimiters.fixedTimeLimit(5, SECONDS[, executor]))` and exception-retrying predicates. The test uses the README quickstart: `retryIfExceptionOfType(IOException.class)`, `retryIfRuntimeException()`, `stopAfterAttempt(3)`.
2. The callable fails with the same object each time, for example `static final IOException NOT_READY` or `memoisedFuture.join()`.
3. Each failed attempt goes `Retryer.call:160` → `AttemptTimeLimiters.java:107` → `SimpleTimeLimiter.callWithTimeout:154/162-163` → `throwCause:259`, which calls `setStackTrace(old + caller stack)`.
4. Each failure adds about (caller depth + 5) frames: 7 frames when called from `main`, about 109 at an application depth of 100.
   - With the builder default `neverStop`, this builds up inside a single `call()`.
   - A static exception keeps accumulating for the whole life of the process.

## Developer intent
- **guava-retrying:** there is no developer commentary on this behavior.
  - `AttemptTimeLimiters.java:105-108` has not changed since 7e474be7 (2013, PR #1).
  - The `AttemptTimeLimiter` Javadoc only says "@throws Exception any exception from this invocation".
  - `AttemptTimeLimiterTest` never makes the callable throw.
- **Guava:** the contract for the method being called (`TimeLimiter.java:78-97`, 22.0) says the exception is "propagated to the caller exactly as-is", and the method is `@Deprecated`. Guava's stack concatenation is deliberate, but it was not designed with reused exception objects in mind.
- **Known-status:** nobody has reported this mechanism. I checked:
  - every issue and PR in rholder/guava-retrying (#1–#107, including #84 and #107, both closed in 2026-09);
  - google/guava (#6599 is only about nested-try style);
  - the forks rhuffman/re-retrying and itning/guava-retrying3;
  - a web search.

  PRs #95 (open) and #103 (unmerged) change line 107 to the three-argument API only for Guava 23 compatibility, and neither mentions this behavior.

## Reproduction result
PASS at Level 0. The test used the unmodified worktree `177b6c9b9f3e7957f404f0bdb8e23374cb1de43f`, Guava 22.0 (SHA-1 `3564ef3803de51fb0530a8377ec6100b33b0d073`) and JDK 21, plus a cross-check on JDK 11. There are no sleeps, failpoints or source changes.

Command: `bash repro/test_bugCR-D-12_reused_exception_stack_growth.sh`. Exit status was 0 and 26/26 checks passed.

```
[growth] limiter=noTimeLimit (control) exception=sentinel (IOException) initial stackTrace.length=1
  after 300 call()s / 900 failed attempts: stackTrace.length=     1 (SimpleTimeLimiter.callWithTimeout frames:   0)  listener log entry=      129 chars  caller's RetryException.printStackTrace=      362 chars  log total=      224,700 chars
[growth] limiter=fixedTimeLimit(5s, executor) exception=sentinel (IOException) initial stackTrace.length=1
  after   1 call()s /   3 failed attempts: stackTrace.length=    22 (SimpleTimeLimiter.callWithTimeout frames:   3)  listener log entry=     1614 chars  caller's RetryException.printStackTrace=     1775 chars  log total=        5,132 chars
  after 300 call()s / 900 failed attempts: stackTrace.length=  6301 (SimpleTimeLimiter.callWithTimeout frames: 900)  listener log entry=   445629 chars  caller's RetryException.printStackTrace=   445790 chars  log total=  267,948,600 chars
    [1] java.base/java.util.concurrent.FutureTask.report(FutureTask.java:122)
    [3] com.google.common.util.concurrent.SimpleTimeLimiter.callWithTimeout(SimpleTimeLimiter.java:154)
    [4] com.github.rholder.retry.AttemptTimeLimiters$FixedAttemptTimeLimit.call(AttemptTimeLimiters.java:107)
    [5] com.github.rholder.retry.Retryer.call(Retryer.java:160)
[attribution] limiter=fixedTimeLimit(5s, executor)  1 call() x 3 failed attempts: setStackTrace() called 3 time(s) on the callable's exception, by {com.google.common.util.concurrent.SimpleTimeLimiter.throwCause(SimpleTimeLimiter.java:259)=3}; stackTrace.length 2 -> 23
[cf] limiter=fixedTimeLimit(5s, executor)  CompletableFuture.join() rethrows the same object on every call: true  initial stackTrace.length=6
  after 100 call()s / 300 failed attempts: CompletionException stackTrace.length= 2106 (SimpleTimeLimiter.callWithTimeout frames: 300)
[paths] limiter=fixedTimeLimit(5s, executor) (b) predicate accepts the exception -> ExecutionException: stackTrace.length 2 -> 702 after 100 call()s x 1 attempt
[paths] limiter=fixedTimeLimit(5s, executor) (d) Retryer.wrap() run on an executor: stackTrace.length 2 -> 3002 after 100 call()s x 3 attempts
[paths] limiter=fixedTimeLimit(5s, executor) (e) default neverStop, one call() that succeeds on attempt 2000 (result=ok): stackTrace.length 2 -> 13995
[oom] fixedTimeLimit(5s, executor) / reused static sentinel, callerDepth=100, maxHeap=32MB, maxCalls=6000
    250 call()s /    750 failed attempts: heap used after GC=   5.7 MB  NOT_READY.stackTrace.length=   81,751     0.58 ms per call() since previous line
   1500 call()s /   4500 failed attempts: heap used after GC=  26.0 MB  NOT_READY.stackTrace.length=  490,501   125.27 ms per call() since previous line
  RESULT[fixedTimeLimit(5s, executor) / reused static sentinel]: call() #1604 ended with ExecutionException caused by java.lang.OutOfMemoryError: Java heap space  <-- not the configured outcome (83.9 s; 4809 failed attempts completed before)
  AFTER[fixedTimeLimit(5s, executor) / reused static sentinel]: a later call() succeeded (result=ok); after GC heap used=  27.6 MB of 32 MB, NOT_READY.stackTrace.length=524,182
  RESULT[noTimeLimit (control) / reused static sentinel]: all 6000 call()s ended with RetryException(IOException) as configured (0.2 s; 18000 failed attempts completed before)
  RESULT[fixedTimeLimit(5s, executor) / fresh object per attempt]: all 6000 call()s ended with RetryException(IOException) as configured (1.4 s; 18000 failed attempts completed before)
```

What the output shows, compared with the controls:
- **Growth:** the reused exception's stack goes from 1 to 6301 frames, with exactly one `SimpleTimeLimiter.callWithTimeout` frame per failed attempt (900/900). In the control it stays at 1 frame.
- **Logs:** one listener log entry grows from 129 to 445,629 chars.
- **Root cause:** the change is made by `SimpleTimeLimiter.throwCause(SimpleTimeLimiter.java:259)`, once per attempt.
- **Bounded heap (`-Xmx32m`):**
  - Retained heap grows linearly, about 5.7 kB per failed attempt at depth 100.
  - Time per call grows from 0.58 to 125 ms.
  - Call #1604 ends with `ExecutionException(OutOfMemoryError)` instead of the configured `RetryException(IOException)`.
  - The memory is still held after a later successful call.
- **Controls:** `noTimeLimit` with the same reused exception, and `fixedTimeLimit` with a fresh exception each attempt, both finish all 6000 calls as configured and stay at 1.6–1.7 MB.
- **Also reproduced the same way:** the two-argument `fixedTimeLimit(5s)` factory, the cheap `fillInStackTrace`-override exception, and JDK 11.
- **Mitigation check:** a reused exception built with `writableStackTrace=false` stays at 0 frames.

### Checklist
1. **Did Level 0 or Level 1 alone trigger it? Yes, Level 0 alone.** Only public APIs were used (`RetryerBuilder`, both `fixedTimeLimit` factories, `Retryer.call`, `Retryer.wrap`, `RetryListener`), with no timing help.
2. **Level 2/3 pre-condition:** not applicable, neither was used. The only pre-condition is a callable that throws the same object twice. Ordinary code does this, for example through a `static final` sentinel or the JDK's `CompletableFuture.join()`, which the run shows returns the same object (`true`).
3. **Which real caller observes a wrong outcome:**
   - The application calling `Retryer.call` (`Retryer.java:155`) gets `ExecutionException(OutOfMemoryError)` instead of the configured `RetryException(IOException)`. The OOM is caught at `Retryer.java:162-163` and rethrown by `attempt.get()` at `:171`. Its calls also slow from 0.58 to 125 ms each.
   - `RetryListener.onRetry` (`Retryer.java:166-168`) receives and logs ever-larger traces.
   - A caller that prints the `RetryException` (cause set at `RetryException.java:57`; the README does `e.printStackTrace()`) prints 445,790 chars instead of 362.
4. **Permanent? Yes.** Nothing resets the mutated stack, and a static exception lives as long as the process. After a later successful `call()` plus GC, the heap is still at 27.6 of 32 MB and the trace at 524,182 frames. Nothing later in the flow fixes or hides it.

## Recommendation
Fix `AttemptTimeLimiters.java:107` so it no longer calls Guava's four-argument `callWithTimeout`, which modifies the exception:
- Submit the callable to the executor directly.
- On `ExecutionException`, rethrow the cause exactly as received. Do not call `setStackTrace` or `addSuppressed` on it, because the object may be shared.
- On `TimeoutException`, cancel the future and throw `UncheckedTimeoutException`.
- On `InterruptedException`, cancel the future and rethrow.

This keeps today's visible behavior and also removes the dependency on the API that Guava 23 removed (#94). If the three-argument `TimeLimiter.callWithTimeout` is used instead, unwrap `ExecutionException`, `UncheckedExecutionException` and `ExecutionError`, and map `TimeoutException` to `UncheckedTimeoutException`. Example code is in `confirmation/CR-D-12/confirmation.md`.

Add a regression test: throw the same exception object on N attempts under `fixedTimeLimit`, then assert that it is still the same object and `getStackTrace().length` has not changed.

Until there is a fix, users can avoid the problem in any of these ways:
- build reused exceptions with `writableStackTrace=false` (verified above);
- throw a new exception for each failure;
- don't use `fixedTimeLimit`.

Other files written: `confirmation/CR-D-12/investigation.md` (Phase 1 evidence) and `confirmation/CR-D-12/issue.json`, which passed `specular findings validate` (`"valid": true`).

Web sources consulted for the novelty search (none reports this mechanism):
- [Guava SimpleTimeLimiter.java (master)](https://github.com/google/guava/blob/master/guava/src/com/google/common/util/concurrent/SimpleTimeLimiter.java)
- [SimpleTimeLimiter Javadoc, Guava 11.0.2](https://guava.dev/releases/11.0.2/api/docs/com/google/common/util/concurrent/SimpleTimeLimiter.html)
- [guava-retrying RetryException.java](https://github.com/rholder/guava-retrying/blob/master/src/main/java/com/github/rholder/retry/RetryException.java)
