# guava-retrying attempt lifecycle, interrupts, and sharing

Run `guava-retrying-opus55max-20261126` is a full Specular pipeline run on guava-retrying 2.0.0 at revision `177b6c9b9f3e7957f404f0bdb8e23374cb1de43f`, built against Guava 22.0. It used Specular `7590b155` with Claude Opus 5.5 at max effort and [target guidance](guidance.md). The trace harness runs the unmodified library under Java PathFinder.

## Results

| Finding | Status | Finding | Status |
| --- | --- | --- | --- |
| MC-1 | REPRODUCED | CR-D-11 | REPRODUCED |
| MC-2 | REPRODUCED | CR-D-12 | REPRODUCED |
| MC-3 | FALSE POSITIVE | CR-D-13 | REPRODUCED |
| MC-4 | REPRODUCED | CR-D-15 | DROPPED (known #67) |
| MC-5 | REPRODUCED (known) | CR-D-16 | REPRODUCED |
| MC-6 | REPRODUCED (known) | CR-D-17 | REPRODUCED |
| MC-7 | REPRODUCED | CR-D-18 | REPRODUCED |
| MC-8 | FALSE POSITIVE | CR-D-19 | REPRODUCED |
| MC-9 | REPRODUCED | CR-D-20 | REPRODUCED |
| MC-10 | REPRODUCED | CR-D-21 | MASKED |
| MC-11 | REPRODUCED (known #48) | CR-D-22 | REPRODUCED |
| MC-12 | REPRODUCED (known #29) | CR-D-23 | DROPPED (known) |
| | | CR-5 | FALSE POSITIVE |

19 bugs were reproduced: 15 new and 4 known. MC-4, MC-5, and MC-6 share one root cause, the catch of `Throwable` at `Retryer.java:162`. See the [confirmation report](confirmed-bugs.md), the [severity classification](bug-severity.md), and the [system overview](../../../../overview.md).

## Artifacts

- **Inputs and analysis:** [guidance](guidance.md), [analysis](analysis-report.md), [modeling brief](modeling-brief.md), and [defect ledger](defect-ledger.json). The Phase 1 probes in [analysis-evidence/probes](analysis-evidence/probes/) reproduced the concurrency defects (ledger D-1 to D-10) before modeling began.
- **Model:** [reference model](spec/base.tla), [MC wrapper](spec/MC.tla), [hunting wrapper](spec/MCHunt.tla), [Trace wrapper](spec/Trace.tla), [instrumentation mapping](spec/instrumentation-spec.md), [validation changelog](spec/changelog.md), and [bug-hunting report](spec/bug-report.md). TLC outputs are in `spec/output/` and `.tlc-tasks/`.
- **Harness:** the [instrumentation guide](harness/INSTRUMENTATION.md) and [JPF recorder and workloads](harness/src/). The [jpf-core patches](harness/patches/jpf-core/) apply to `mku-spurious` `1432471`. The [traces](traces/) hold 380 NDJSON files.
- **Confirmation:** [reproduction scripts](repro/), [per-finding records](confirmation/), and the [classification](bug-severity.md).
- **Environment and run metadata:** the [environment](environment/) used to prepare the run (a JPF smoke example and the Maven build check), the [pipeline log](pipeline.log), the [pipeline summary](pipeline-summary.md), [run metadata](run.json), and the [file inventory](.record/files.tsv).

## Validation and model checking

- **Trace validation:** all 380 JPF traces replay against the final `Trace.tla`.
- **Model checking:** `MC.cfg` ran to exhaustion without a violation (5,867,867 distinct states after repair round 1). Thirteen hunting configurations ran safety and liveness checks: each run disabled a property once it was violated and continued, with a 30-minute budget per configuration. All are bounded checks.

## Run history

- **Failure.** After Phase 4, repair round 1 withdrew MC-3 and MC-8 as over-strict invariants. Those states are documented timeout and bounded-executor behavior. The pipeline then stopped on a Specular report-parser bug, [specular-org/Specular#232](https://github.com/specular-org/Specular/pull/232): a numeric table row in MC-6's evidence was counted as a disposition row.
- **Resume.** With the parser fixed locally, the run resumed with `--fresh-context --skip-analysis --skip-specgen --skip-harness --skip-validate`. The resumed run re-confirmed the 10 current model-checking findings, all reproduced, and then ran classification.
- **Duration and cost.** The run took about 9 hours of wall-clock time and about $263 in API-equivalent cost.

## Limitations

- **Reproductions:** several reproductions control timing with latches and short time limits. MC-2's thread exhaustion was shown under a 200-task process limit.
- **Excluded:** agent transcripts and prompts, per-finding library worktrees, TLC state directories, replay binaries, and build outputs.
- **Provenance:** scripts and receipts keep their original workspace paths. This archive is not an additional reproduction run.
