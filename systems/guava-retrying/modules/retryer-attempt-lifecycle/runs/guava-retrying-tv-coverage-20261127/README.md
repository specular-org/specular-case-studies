# guava-retrying trace-validation coverage follow-up

Record `guava-retrying-tv-coverage-20261127` measures and extends the trace-validation coverage of [guava-retrying-opus55max-20261126](../guava-retrying-opus55max-20261126/README.md) under a strict counting rule. All work was done on copies of that run's spec, harness, and traces. The run directory and the jpf-core checkout were not modified. The [log](LOG.txt) is the detailed record.

## Results

| | Before | After |
| --- | --- | --- |
| Covered actions (strict) | 42/52 (80.8%) | 53/53 (100%) |
| Accepted traces | 379 (JPF) | 1,343 (577 JPF + 766 HotSpot on JDK 11 and 21) |
| Spec errors found by trace validation | — | 1 (F1) |
| Change in model-checking results | — | none |
| New bugs | — | none |

- **Strict rule.** An action counts only when a trace observes its effect in real code. Before this work, the actions not counted were:
  - six block and sleep actions, observed only inside the harness's own JPF `Thread.sleep` model (jpf-core patch 3);
  - `WorkerPollCancel`, which `Trace.tla` inferred instead of observing;
  - `Interrupt`, `CancelOuter`, and `ExecutorShutdown`, whose events did not read back the state they write.
- **Changes.**
  - The JPF recorder now reads back the target's interrupt flag, the outer `FutureTask` state, and the executor's run state and interrupted idle workers at shutdown. It also emits explicit `WorkerPollCancel` and `WorkerUnlock` events.
  - Five new JPF workloads cover configurations no earlier trace reached, including the `StopKind = Never` configuration behind MC-6.
  - A new harness records traces on real HotSpot (`rt/`). The library is unmodified; recording wrappers surround only the built-in stop, wait, and block strategies.
  - As negative controls, three mutated traces were all rejected.
- **F1.** After finishing a task, a worker holds its `Worker` lock until `runWorker` unlocks it (JDK 11 `ThreadPoolExecutor.java:1137`). `interruptIdleWorkers` uses `tryLock`, so `shutdown()` skips that worker. The model interrupted it as idle.
  - The pipeline's final spec rejected 13 of 577 new JPF traces, all at `ExecutorShutdown`.
  - The [fix](fix/F1-base.diff) adds a `Release` worker state and a `WorkerUnlock` action. With the fix, `MC.cfg` remains exhaustive without violation at 7,035,861 distinct states (5,867,867 before).
  - The [example package](packages/P1-F1-shutdown-lock/) contains the spec diff, a rejected trace, validation logs before and after the fix, and model-checking output.
- **Model checking.** `MC.cfg` and the 13 hunting configurations ran on both the final pipeline spec and the fixed spec. Each run disabled a property once it was violated and continued, with a 30-minute budget per configuration. All 14 configurations produced identical chains of violated properties; see [mc/summary.txt](mc/summary.txt).
- **Other observations.**
  - Real JPF executions of the `wrap_never` workload re-observe MC-6: after `cancel(true)`, 20 of 30 traces submit at least two more attempts.
  - All 766 HotSpot traces pass the same spec as the JPF traces, so the harness's JPF sleep model agrees with real sleeps on JDK 11 and 21.
  - The `mku-spurious` spurious-wakeup policy does not apply: the library and executor paths block in `LockSupport.park`, not `Object.wait()`.
- **Cost.** About 1.3 hours of wall-clock time, about 6 CPU-hours each for JPF and TLC, and about 1,000 lines of new code.

## Layout

- `work/`: the edited copy of the harness (recorder and workloads), the spec with the F1 fix and strict `Trace.tla`, and the 577 JPF traces.
- `rt/`: the real-HotSpot harness sources, its 766 traces, and the negative controls in `neg/`.
- `fullfinal-strict/`: the pipeline's final spec with the strict `Trace.tla`, used to measure what the unfixed spec rejects.
- `mc/`: the hunting-chain summary and TLC outputs for both specs.
- `phase2/`: the Phase 2 spec reconstructed from the Phase 3 session. On the original 379 traces it passes 321.
- `fix/`, `packages/`, `logs/`, `tools/`: the F1 diff, the F1 example package, run logs, and the coverage, validation, and hunting-chain scripts.

Excluded:
- the pristine copy of the core record (`orig/`), the library source, and the jpf-core copy and TLA+ jars;
- the two spec copies under `mc/` (byte-identical to the core record's `spec/` and to `work/spec/`);
- TLC state directories, replay binaries, and build outputs.

Paths in logs and scripts are the original workspace paths.
