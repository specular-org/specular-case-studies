# TLAPS-Bench

## Scope

Specular analyzed TLAPS-Bench task generation, proof-checking evaluation, resume and checkpoint recovery, scoring, and container execution.

## Findings

The [September 2026 check](modules/benchmark-pipeline/runs/tlaps-bench-20260929/README.md) records 7 findings: two Fixed and five Confirmed.

- [PR #178](https://github.com/specular-org/TLAPS-Bench/pull/178) preserves theorem semantics when the task generator renames bound variables.
- [PR #180](https://github.com/specular-org/TLAPS-Bench/pull/180) keeps container stdout reads within the agent deadline.

The run summary lists the remaining findings individually.
