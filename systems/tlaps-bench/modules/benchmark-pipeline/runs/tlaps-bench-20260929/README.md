# TLAPS-Bench benchmark pipeline check

The September 29, 2026 check examined TLAPS-Bench at `ef53d032e3d263a7e425c13bbc20e5eba5e3eabf`. This record summarizes 7 distinct findings from the original report. The report lists nine reproduced entries; two of them repeat defects covered by other entries. One false positive, one environment-limited entry, and two dropped duplicates are excluded.

| Finding | Status | Reference |
|---|---|---|
| A crash during task regeneration leaves a mixed suite that the loader accepts | Confirmed |  |
| Module resume reports full progress while a submission still awaits grading | Confirmed |  |
| Renaming a bound variable also renames a record field and turns a valid theorem false | Fixed | [PR #178](https://github.com/specular-org/TLAPS-Bench/pull/178) |
| Proof-completion resume reuses a PASS recorded under a different backend, model, or source | Confirmed |  |
| Resume ignores a saved task result missing from results.json and repeats the paid attempt | Confirmed |  |
| A partial stdout line from a Docker agent blocks the runner past its deadline | Fixed | [PR #180](https://github.com/specular-org/TLAPS-Bench/pull/180) |
| Standalone scoring reports a partial selection as complete | Confirmed |  |

The two linked fixes have merged. The remaining findings are recorded as Confirmed by the project. Status was checked on 2026-11-23.

This is a findings summary. The original run reports and reproduction artifacts remain in the source archive; their hashes are recorded in [provenance.json](provenance.json).
