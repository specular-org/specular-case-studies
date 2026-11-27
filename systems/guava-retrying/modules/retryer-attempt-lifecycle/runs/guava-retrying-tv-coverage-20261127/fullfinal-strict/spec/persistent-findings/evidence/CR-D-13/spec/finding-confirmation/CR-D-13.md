# CR-D-13

Status: REPRODUCED
Run: guava-retrying-opus55max-20261126

running pwd; ls -la; find / -type d -name "bug-confirmation" 2>/dev/null | head -20
running ls -la ~/.claude/skills/ 2>/dev/null; ls -la /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; ls -la /home/ubuntu/guava-retrying-202611...
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; cat SKILL.md; echo ======; cat guide.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; cat phases/01-investigation.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; cat phases/02-reproduction.md
running cd /home/ubuntu/guava-retrying-20261126/Specular/skills/bug-confirmation; ls -la references; for f in references/*; do echo "===== $f"; cat "$f"; done
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; ls -la $W; echo ----; ls -la $W/confi...
先简要说明进展：已读完 bug-confirmation 技能（guide + Phase 1/2 + references），现在进入 Phase 1，查看 worktree 源码与构建方式。
running WT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-13/worktree; cd $WT...
running cd /home/ubuntu/guava-retrying-20261126; ls -la; find / -name "guava-22.0*.jar" 2>/dev/null | head; find / -type d -name "guava-22.0" 2>/dev/null | head
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; ls -la $W/harness $W/analysis-evidenc...
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; cat $W/analysis-evidence/build/pom.xm...
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; cat $W/analysis-evidence/probes/timel...
running WT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-13/worktree; cd $WT...
进展：已读完 `Retryer.call`、`RetryerBuilder.ExceptionClassPredicate`、`AttemptTimeLimiters`。下一步对照 Guava 22.0 `SimpleTimeLimiter` 源码确认 `throwCause` 的分支。
running FD=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-13; mkdir -p $FD/gu...
running WT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-13/worktree; cd $WT...
running which gh && gh auth status 2>&1 | head -5; timeout 30 gh api 'repos/rholder/guava-retrying' --jq '{full_name, open_issues_count, pushed_at, updated_at}' 2>&1...
running cd /tmp; FD=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-13; mkdir...
running cd /tmp; FD=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-13; timeou...
running FD=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-13; python3 -I - "$...
running cd /tmp; for n in 107 95 103 82 84; do echo "===== PR #$n"; timeout 60 gh api "repos/rholder/guava-retrying/pulls/$n" --jq '{state, merged: .merged, merged_a...
running cd /tmp; for n in 95 103; do echo "===== PR #$n AttemptTimeLimiters.java patch"; timeout 60 gh api "repos/rholder/guava-retrying/pulls/$n/files?per_page=100"...
running cd /tmp; timeout 60 gh api 'repos/rholder/guava-retrying/commits?sha=master&per_page=15' --jq '.[] | .sha[0:7] + " " + .commit.author.date[0:10] + " " + (.co...
running ls /home/ubuntu/guava-retrying-20261126/Specular/; ls /home/ubuntu/guava-retrying-20261126/Specular/bin 2>/dev/null; find /home/ubuntu/guava-retrying-2026112...
running cd /home/ubuntu/guava-retrying-20261126/Specular; head -30 specular; W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/g...
running cd /home/ubuntu/guava-retrying-20261126/Specular; ls case-studies | head -80; grep -r -l -i "guava-retrying\|rholder" case-studies 2>/dev/null | head
running cd /tmp; for q in 'guava-retrying fixedTimeLimit Throwable' 'guava-retrying ExecutionException retryIfExceptionOfType timeLimiter' 'AttemptTimeLimiter Execut...
running cd /tmp; for n in 28 22 23 14 8 7; do echo "===== re-retrying #$n"; timeout 60 gh api "repos/rhuffman/re-retrying/issues/$n" --jq '"[" + .state + "] " + .tit...
running which java javac kotlinc kotlin groovy groovyc scala scalac mvn 2>&1; java -version 2>&1 | head -2; /usr/lib/jvm/java-11-openjdk-amd64/bin/java -version 2>&1...
running FD=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-13; cd $FD/guava22-...
running for v in 10.0.1 14.0.1 16.0.1 22.0; do ls -la ~/.m2/repository/com/google/guava/guava/$v/*.jar 2>/dev/null; done; ls -la ~/.m2/repository/com/google/code/fin...
running ls -la ~/.m2/repository/org/apache/commons/commons-lang3/*/ 2>/dev/null; find / -name 'commons-lang3-*.jar' -not -path '*/proc/*' 2>/dev/null | head -5; find...
running J=~/.m2/repository/org/apache/commons/commons-lang3/3.8.1/commons-lang3-3.8.1.jar; sha1sum $J; cat $J.sha1; echo; javap -cp $J org.apache.commons.lang3.excep...
Phase 1 证据已齐（commons-lang3 3.8.1 的 `ExceptionUtils.rethrow` 可作为真实第三方触发源）。现在写入 `investigation.md`。
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-13/investigation.md
Phase 1 记录已写好。进入 Phase 2：先确认 `RetryListener` 签名，然后编写 Level 0（纯公共 API、无时序辅助）复现脚本。
running WT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-13/worktree; sed -n...
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/test_bugCR-D-13_weird_throwable_timelimit_misclassifie...
Fix a stale comment, then run the reproduction with an outer timeout and capture the log.
editing /home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro/test_bugCR-D-13_weird_throwable_timelimit_misclassifie...
running R=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro; chmod +x $R/test_bugCR-D-13_wei...
The script exited 0 (bug reproduced). The log is large, so I'll read it in sections: first the full JDK 21 run.
running R=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro; wc -l -c $R/CR-D-13.log; awk '/...
running R=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro; grep -n -E '^=+ run:|^#+ supple...
The JDK 11 run and the supplementary Guava 16.0.1/14.0.1/10.0.1 runs all reproduced (8 divergences each, controls consistent). Now the A1/C1 detail lines from the JDK 11 run, for the report.
running R=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro; sed -n '64,75p;95,100p;104,106p...
Level 0 reproduction succeeded. Next: a second run to confirm determinism, a check that the persistent-findings source root matches the worktree, and a look at the `issue.json` validation rules.
running R=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/repro; cd /tmp; EXTRA_GUAVA_VERSIONS="...
running cd /home/ubuntu/guava-retrying-20261126/Specular/src/specular; grep -rn -l "def.*validate\|\"validate\"\|'validate'" . 2>/dev/null | head; ls
running cd /home/ubuntu/guava-retrying-20261126/Specular/src/specular; grep -n -E "REQUIRED|required|ALLOWED|_STATUSES|_SOURCES|def _validate_proposal|def validate|r...
running cd /home/ubuntu/guava-retrying-20261126/Specular/src/specular; sed -n 240,300p persistent_findings.py; echo ......; sed -n 330,505p persistent_findings.py
running cd /home/ubuntu/guava-retrying-20261126/Specular/src/specular; grep -n -E "^DIRECTORY|^RECEIPTS|^CONTEXT|^LIVE|def _strings|def _text|def _path" -A6 persiste...
running FD=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-13; cd $FD/guava22-...
running FD=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-13; python3 -I - "$...
The title is 2 characters over the limit; shortening it and re-running.
running python3 -I -c " for t in ['Under fixedTimeLimit, a callable Throwable that is neither Exception nor Error reaches retry predicates as ExecutionException, so...
running python3 -I -c " for t in ['fixedTimeLimit wraps a callable Throwable that is neither Exception nor Error in ExecutionException, so retryIfExceptionOfType sto...
running FD=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-13; python3 -I - "$...
running cat /tmp/crd13-validate.out | head -c 1500; echo; grep -n "\"validate\"\|command == \"validate\"\|validate_issue_proposal" /home/ubuntu/guava-retrying-202611...
`issue.json` validated (`"valid": true`). Before writing the conclusion, I'll check the exact line numbers of a few citations.
running WT=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-13/worktree; FD=$WT...
Two citations in `investigation.md` are off (`RetryException.java:42` should be `:57`; `TimeLimiter.java:79-98` should be `:80-82`). Fixing them and re-validating.
running FD=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output/confirmation/CR-D-13; cd $FD; grep -n...
running W=/home/ubuntu/guava-retrying-20261126/Specular/runs/guava-retrying-opus55max-20261126/guava-retrying/.specular-output; git -C $W/confirmation/CR-D-13/worktr...
# CR-D-13 — Confirmation verdict

**Conclusion: REPRODUCED.** I triggered it with public APIs only (Level 0, no timing help), on Guava 22.0 under both JDK 21 and JDK 11. The run is deterministic.

- **Source**: Code Review
- **Novelty**: NEW
- **Location**: src/main/java/com/github/rholder/retry/AttemptTimeLimiters.java:107
- **Status**: REPRODUCED
- **Severity**: Medium. Once triggered, the configured retry policy flips: it either stops retrying or retries something it shouldn't. The trigger is limited to callables that throw a non-`Exception`, non-`Error` Throwable.
- **Reproduction test**: `.specular-output/repro/test_bugCR-D-13_weird_throwable_timelimit_misclassified.sh` (Level 0). Logs are `repro/CR-D-13.log` and `repro/CR-D-13.run2.log`.

## Description

How the bug happens:

1. `FixedAttemptTimeLimit.call` (`AttemptTimeLimiters.java:107`) delegates to Guava's deprecated `SimpleTimeLimiter.callWithTimeout(callable, d, u, true)`.
2. Guava's `throwCause` rethrows the cause only when it is an `Exception` or an `Error`. For any other Throwable it rethrows the outer `FutureTask` `ExecutionException` (Guava 22.0 `SimpleTimeLimiter.java:261-268`).
3. `Retryer.call` catches that wrapper with `catch (Throwable t)` (`Retryer.java:162-163`) and records it as the attempt's exception.
4. `ExceptionClassPredicate` (`RetryerBuilder.java:212`) and `ExceptionPredicate` (`:247`) test `getExceptionCause()` directly, without unwrapping.

Without a time limit, `NoAttemptTimeLimit` (`AttemptTimeLimiters.java:77-79`) passes the callable's Throwable through unchanged. So adding only `fixedTimeLimit` changes the retry decision:

- **`retryIfExceptionOfType(T)` / `retryIfException(Predicate)`** stop matching. The call ends after 1 attempt with `ExecutionException(ExecutionException(t))`.
- **`retryIfException()`** goes the other way: it starts retrying a Throwable that is not an `Exception`.

## Trigger scenario

1. The callable throws `TransientFailure extends Throwable`. I tested three ways to throw it:
   - commons-lang3 3.8.1 `ExceptionUtils.rethrow`
   - `Class.newInstance()`
   - a generic sneaky throw, which is what Lombok `@SneakyThrows` compiles to
2. Configure `retryIfExceptionOfType(TransientFailure.class)` + `stopAfterAttempt(3)`.
3. With `noTimeLimit()`: 3 invocations, then `RetryException(cause=TransientFailure)`.
4. Change only to `fixedTimeLimit(5, SECONDS[, pool])`; the callable still throws immediately and never times out. Result: 1 invocation, then `ExecutionException <- ExecutionException <- TransientFailure`. Listeners see `getExceptionCause()` as `ExecutionException`.

## Developer intent

The documentation consistently says predicates see the exception the callable threw, and that the time limiter only limits duration:

- **`Attempt.getExceptionCause()`**: "the exception thrown by the call" (`Attempt.java:65`).
- **`retryIfExceptionOfType`**: retries "if an exception of the given class … is thrown by the call", and its parameter type is `Class<? extends Throwable>`.
- **`Retryer.call`** Javadoc: "The original exception is wrapped into an ExecutionException" (`Retryer.java:148-150`).
- **`withAttemptTimeLimiter`**: only says it limits each attempt's duration.
- **`AttemptTimeLimiter.call`**: "@throws Exception any exception from this invocation".
- **Guava 22.0's own `TimeLimiter.callWithTimeout` Javadoc** promises the exception is propagated "exactly as-is" (`TimeLimiter.java:80-82`). Its implementation deviates via the `:267` "weird kind of Throwable" branch, and `:138` carries a TODO.

There is no test for "time limiter + non-`Exception`/`Error` Throwable". The existing tests only assert the unlimited case, where the cause is the original exception wrapped once. `git log` and blame show no discussion of this.

Prior-report search:

- **Upstream `rholder/guava-retrying`**: I read all 106 issues/PRs and their comments, including #107 (closed 2026-09-05) and #84 (closed 2026-09-20). #29 is about the timeout exception and #67 about catching `Error`s, so neither is this mechanism. PRs #95/#103 change the same file only for Guava 23 compatibility.
- **Fork `rhuffman/re-retrying` and a GitHub-wide search**: nothing for this mechanism.
- **`specular findings lookup`**: returned `[]`.

So this is **NEW**. Details are in `confirmation/CR-D-13/investigation.md`.

## Reproduction result

Command: `timeout 10m .specular-output/repro/test_bugCR-D-13_weird_throwable_timelimit_misclassified.sh`. Exit 0, 6.6 s.

The second run (`EXTRA_GUAVA_VERSIONS=""`) gave the same result on both JDKs: `divergences=8 controlFailures=0`.

Excerpt from the JDK 21 run (each line truncated after the `|` separator; full text in the log):

```
[A1] retryIfExceptionOfType(TransientFailure.class), stopAfterAttempt(3), T1 commons-lang3 ExceptionUtils.rethrow
   noTimeLimit()                  -> invocations=3 elapsed=1ms thrown=com.github.rholder.retry.RetryException <- TransientFailure (getNumberOfFailedAttempts=3) | ...
   fixedTimeLimit(5,SECONDS,pool) -> invocations=1 elapsed=1ms thrown=java.util.concurrent.ExecutionException <- java.util.concurrent.ExecutionException <- TransientFailure | thrown.getCause() instanceof TransientFailure=false | listener saw getExceptionCause(): [#1 java.util.concurrent.ExecutionException <- TransientFailure]
[C1] retryIfException(), stopAfterAttempt(3), T1 commons-lang3 ExceptionUtils.rethrow
   noTimeLimit()                  -> invocations=1 elapsed=0ms thrown=java.util.concurrent.ExecutionException <- TransientFailure | ...
   fixedTimeLimit(5,SECONDS,pool) -> invocations=3 elapsed=0ms thrown=com.github.rholder.retry.RetryException <- java.util.concurrent.ExecutionException <- TransientFailure (getNumberOfFailedAttempts=3) | ...
[D1] ... control: throw TransientIOException   => CONTROL OK: identical to noTimeLimit()
[E1] ... control: throw TransientError         => CONTROL OK: identical to noTimeLimit()
[ROOT-CAUSE] fixedTimeLimit outcome: outer=java.util.concurrent.ExecutionException (created by Retryer.ExceptionAttempt), inner=java.util.concurrent.ExecutionException, inner.getCause()=TransientFailure, inner.getCause() is Exception? false, is Error? false
     at java.base/java.util.concurrent.FutureTask.report(FutureTask.java:122)
     at com.google.common.util.concurrent.SimpleTimeLimiter.callWithTimeout(SimpleTimeLimiter.java:154)
     at com.github.rholder.retry.AttemptTimeLimiters$FixedAttemptTimeLimit.call(AttemptTimeLimiters.java:107)
     at com.github.rholder.retry.Retryer.call(Retryer.java:160)
SUMMARY java.version=21.0.13.1: divergences=8 controlFailures=0 baselineFailures=0
SUMMARY java.version=11.0.33.1: divergences=8 controlFailures=0 baselineFailures=0
FINAL: BUG REPRODUCED on every primary run (Guava 22.0; JDKs: /usr/lib/jvm/java-21-openjdk-amd64 /usr/lib/jvm/java-11-openjdk-amd64)
```

The A1 `fixedTimeLimit` row is the bug: 1 invocation with a doubly-wrapped exception, versus 3 retries without a limit.

- **Root-cause frames**: the extra `ExecutionException` comes from `FutureTask` and is passed through by `SimpleTimeLimiter`. Its cause is neither `Exception` nor `Error`, so only the `:268 throw e` branch can have thrown it.
- **Controls**: the `Exception` and `Error` controls behave identically with and without a time limit, which confirms the divergence is limited to that branch.
- **Other cases**: A2/A3 (the other two ways of throwing), B1 (the predicate form), and the no-executor `fixedTimeLimit(5,SECONDS)` all diverge the same way.
- **Older Guava**: as a supplementary check, the same source compiled against Guava 16.0.1, 14.0.1 and 10.0.1 gives the same 8 divergences.

**Checklist before REPRODUCED:**

1. **Level 0/1 alone?** Yes. Level 0 alone, with public APIs and normal operation, no timing help and no timeout involved.
2. **Level 2/3 used?** No.
3. **Real consumer:** `Retryer.call` at `Retryer.java:170-172` applies the rejection predicate to the misattributed attempt and returns `attempt.get()` instead of retrying. The application calling `Retryer.call()` gets `ExecutionException(ExecutionException(t))` after one invocation, and its `getCause()` is not the original exception. `RetryListener.onRetry` (`Retryer.java:166-168`) sees `ExecutionException`.
4. **Permanent?** Yes. This is the final outcome of `call()`: retries that were skipped never happen, and nothing downstream re-evaluates the decision. There is no masking mechanism, and it reproduces deterministically across 2 runs × 2 JDKs.

## Recommendation

- **Fix:** in `FixedAttemptTimeLimit.call`, stop using the deprecated 4-argument `callWithTimeout`. Submit to the executor directly and call `future.get(duration, unit)`:
  - On `ExecutionException`, rethrow `getCause()` as-is (sneaky rethrow is fine, since `Retryer.call` already catches `Throwable`).
  - On timeout, keep `future.cancel(true)` + `UncheckedTimeoutException`.
  - On interrupt, keep cancelling and rethrowing `InterruptedException`.

  This also drops the dependency on the API removed in Guava 23 (#94).
- **Don't just switch to the 3-argument overload** (as PRs #95/#103 do). Per `SimpleTimeLimiter.java:184-186,299-307`, it wraps every outcome in `ExecutionException` / `UncheckedExecutionException` / `ExecutionError`, which would extend this misclassification to all exception types.
- **Regression test:** with the same predicates, a non-`Exception`/`Error` Throwable must produce the same attempt count and the same `getExceptionCause()` under `noTimeLimit` and `fixedTimeLimit`.

The persistent record `confirmation/CR-D-13/issue.json` passes `specular findings validate` (`"valid": true`). The worktree was not modified.
