# guava-retrying trace-validation coverage follow-up

Record `guava-retrying-tv-coverage-20261127` measures and extends the trace-validation coverage of [guava-retrying-opus55max-20261126](../guava-retrying-opus55max-20261126/README.md). It works on copies of that record's spec, harness, and traces. An action counts as covered only when a trace observes its effect in real code. The detailed record is [LOG.txt](LOG.txt).

## Results

| | Before | After |
| --- | --- | --- |
| Covered actions | 42/52 | 53/53 |
| Accepted traces | 379 (JPF) | 1,343 (577 JPF, 766 HotSpot on JDK 11 and 21) |
| Spec errors found | — | 1 (F1) |
| Change in model-checking results | — | None |
| New bugs | — | None |

**F1.** After finishing a task, a worker still holds its `Worker` lock until `runWorker` unlocks it (JDK 11 `ThreadPoolExecutor.java:1137`), so `shutdown()` does not interrupt it. The model interrupted such a worker as idle.
- The core record's final spec rejects 13 of the 577 new JPF traces, all at `ExecutorShutdown`.
- The [fix](fix/F1-base.diff) adds a `Release` worker state and a `WorkerUnlock` action.
- `MC.cfg` and 13 hunting configurations produce identical violation chains on the spec with and without the fix ([mc/summary.txt](mc/summary.txt)).

## Contents

| Path | Contents |
| --- | --- |
| [LOG.txt](LOG.txt) | Detailed record: coverage rule, changes, results |
| [work/](work/) | Edited harness (JPF recorder with state read-backs, 5 additional workloads), the spec with the F1 fix and the stricter `Trace.tla`, and 577 JPF traces |
| [rt/](rt/) | Real-HotSpot harness sources, 766 traces, and 3 mutated negative-control traces (`neg/`) |
| [fullfinal-strict/](fullfinal-strict/) | The core record's final spec with the stricter `Trace.tla`, and its validation outputs |
| [mc/](mc/) | Model-checking summary and TLC outputs for both specs |
| [phase2/](phase2/) | Phase 2 spec reconstructed from the Phase 3 session |
| [fix/](fix/) | F1 spec diff |
| [packages/P1-F1-shutdown-lock/](packages/P1-F1-shutdown-lock/) | F1 example: spec diff, a rejected trace, validation logs before and after the fix, model-checking output |
| [logs/](logs/), [tools/](tools/) | Run logs; coverage, validation, and hunting-chain scripts |
| [.record/files.tsv](.record/files.tsv) | File inventory with source paths and checksums |

Not included:
- the pristine copy of the core record;
- the library source, the jpf-core copy, and the TLA+ jars;
- two spec copies under `mc/` that are byte-identical to the core record's `spec/` and to `work/spec/`;
- TLC state directories, replay binaries, and build outputs.

Scripts and logs keep their original workspace paths.
