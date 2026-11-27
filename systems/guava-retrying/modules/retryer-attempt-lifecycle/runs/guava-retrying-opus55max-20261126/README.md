# guava-retrying attempt lifecycle, interrupts, and sharing

Run `guava-retrying-opus55max-20261126` is a full Specular pipeline run on guava-retrying 2.0.0 at revision `177b6c9b9f3e7957f404f0bdb8e23374cb1de43f`, built against Guava 22.0. Agent: Claude Code with `claude-opus-5-5`, effort `max` ([run metadata](run.json)).

## Results

The [confirmation report](confirmed-bugs.md) has 25 entries:

| Disposition | Count |
| --- | --- |
| Reproduced, new | 15 |
| Reproduced, known | 4 |
| False positive | 3 |
| Masked | 1 |
| Dropped | 2 |

| Finding | Status | Finding | Status |
| --- | --- | --- | --- |
| MC-1 | REPRODUCED | CR-D-11 | REPRODUCED |
| MC-2 | REPRODUCED | CR-D-12 | REPRODUCED |
| MC-3 | FALSE POSITIVE | CR-D-13 | REPRODUCED |
| MC-4 | REPRODUCED | CR-D-15 | DROPPED |
| MC-5 | REPRODUCED (known) | CR-D-16 | REPRODUCED |
| MC-6 | REPRODUCED (known) | CR-D-17 | REPRODUCED |
| MC-7 | REPRODUCED | CR-D-18 | REPRODUCED |
| MC-8 | FALSE POSITIVE | CR-D-19 | REPRODUCED |
| MC-9 | REPRODUCED | CR-D-20 | REPRODUCED |
| MC-10 | REPRODUCED | CR-D-21 | MASKED |
| MC-11 | REPRODUCED (known) | CR-D-22 | REPRODUCED |
| MC-12 | REPRODUCED (known) | CR-D-23 | DROPPED |
| | | CR-5 | FALSE POSITIVE |

Summaries of the reproduced bugs are in the [system overview](../../../../overview.md); severity tiers are in [bug-severity.md](bug-severity.md).

## Contents

| Path | Contents |
| --- | --- |
| [guidance.md](guidance.md) | Target guidance given to the pipeline |
| [analysis-report.md](analysis-report.md), [modeling-brief.md](modeling-brief.md), [defect-ledger.json](defect-ledger.json) | Phase 1 code analysis, modeling brief, and defect ledger (23 entries) |
| [analysis-evidence/probes/](analysis-evidence/probes/) | Phase 1 probe programs |
| [spec/](spec/) | TLA+ model ([base.tla](spec/base.tla)), wrappers ([MC.tla](spec/MC.tla), [MCHunt.tla](spec/MCHunt.tla), [Trace.tla](spec/Trace.tla)), configurations, [instrumentation mapping](spec/instrumentation-spec.md), [validation changelog](spec/changelog.md), [bug-hunting report](spec/bug-report.md), TLC outputs (`spec/output/`), and counterexample traces (`*_TTrace_*.tla`) |
| [harness/](harness/) | Java PathFinder trace harness ([instrumentation guide](harness/INSTRUMENTATION.md)): JPF listener recorder and 13 workloads in `src/`, Maven build of the unmodified library (`pom.xml`), and validation scripts |
| [harness/patches/jpf-core/](harness/patches/jpf-core/) | Five jpf-core patches for JDK 11, against lemmy/jpf-core `mku-spurious` `1432471` |
| [traces/](traces/) | 380 NDJSON traces recorded under JPF |
| [.tlc-tasks/](.tlc-tasks/) | TLC job requests, results, and logs |
| [confirmed-bugs.md](confirmed-bugs.md), [confirmation/](confirmation/) | Confirmation report and per-finding records (investigation, verdict, reproduction output) |
| [repro/](repro/) | Reproduction scripts and their output logs |
| [bug-severity.md](bug-severity.md) | Severity classification |
| [summary.md](summary.md), [pipeline-summary.md](pipeline-summary.md), [pipeline.log](pipeline.log), [run.json](run.json), [repair-loop.json](repair-loop.json) | Run summaries, log, and metadata |
| [environment/](environment/) | JPF smoke example and Maven build check used to prepare the run |
| [.record/files.tsv](.record/files.tsv) | File inventory with source paths and checksums |

## Validation

- **Trace validation:** all 380 traces replay against the final `Trace.tla` ([changelog](spec/changelog.md)).
- **Model checking:** `MC.cfg` is exhaustive without a violation (5,867,867 distinct states), and 13 hunting configurations were run ([bug-hunting report](spec/bug-report.md)). These are bounded checks.

Agent transcripts and prompts, per-finding library worktrees, TLC state directories, replay binaries, and build outputs are not included. Scripts and logs keep their original workspace paths.
