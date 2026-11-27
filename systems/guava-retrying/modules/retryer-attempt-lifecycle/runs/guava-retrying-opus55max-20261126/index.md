# guava-retrying Results

## Final Reports

- [Summary](summary.md) — Results, validation limits, run details, and resource usage
- [Confirmation report](confirmed-bugs.md) — Confirmation results and supporting evidence
- [Severity report](bug-severity.md) — Impact assessment

> Availability means that a document exists. It does not imply review approval
> or confirmation of every finding.

## Supporting Analysis

| Step | Document | What it contains |
|---:|---|---|
| 1 | [Modeling brief](modeling-brief.md) | System model, Scenarios, and proposed invariants |
| 2 | [Analysis report](analysis-report.md) | Detailed source-code investigation |
| 3 | [Spec coverage](spec/brief-coverage.md) · [Instrumentation map](spec/instrumentation-spec.md) | How the analysis was translated into the model |
| 4 | [Validation changelog](spec/changelog.md) | Model corrections and validation history |
| 5 | [Model-checking report](spec/bug-report.md) | Candidate findings from model checking |

## Confirmation Details

| Finding | Investigation | Discussion | Reproduction |
|---|---|---|---|
| CR-5 | [Read](confirmation/CR-5/investigation.md) | [Read](confirmation/CR-5/debate.md) | [test_bugCR-5_decision_step_sweep.sh](repro/test_bugCR-5_decision_step_sweep.sh) |
| CR-D-11 | [Read](confirmation/CR-D-11/investigation.md) | [Read](confirmation/CR-D-11/debate.md) | [test_bugCR-D-11_nonpositive_time_limit.sh](repro/test_bugCR-D-11_nonpositive_time_limit.sh) |
| CR-D-12 | [Read](confirmation/CR-D-12/investigation.md) | [Read](confirmation/CR-D-12/debate.md) | [test_bugCR-D-12_reused_exception_stack_growth.sh](repro/test_bugCR-D-12_reused_exception_stack_growth.sh) |
| CR-D-13 | [Read](confirmation/CR-D-13/investigation.md) | [Read](confirmation/CR-D-13/debate.md) | [test_bugCR-D-13_weird_throwable_timelimit_misclassified.sh](repro/test_bugCR-D-13_weird_throwable_timelimit_misclassified.sh) |
| CR-D-15 | [Read](confirmation/CR-D-15/investigation.md) | [Read](confirmation/CR-D-15/debate.md) | Not available |
| CR-D-16 | [Read](confirmation/CR-D-16/investigation.md) | [Read](confirmation/CR-D-16/debate.md) | [test_bugCR-D-16_join_sum_overflow.sh](repro/test_bugCR-D-16_join_sum_overflow.sh) |
| CR-D-17 | [Read](confirmation/CR-D-17/investigation.md) | [Read](confirmation/CR-D-17/debate.md) | [test_bugCR-D-17_exception_wait_negative_sleep.sh](repro/test_bugCR-D-17_exception_wait_negative_sleep.sh) |
| CR-D-18 | [Read](confirmation/CR-D-18/investigation.md) | [Read](confirmation/CR-D-18/debate.md) | [test_bugCR-D-18_exceptionwait_null_npe.sh](repro/test_bugCR-D-18_exceptionwait_null_npe.sh) |
| CR-D-19 | [Read](confirmation/CR-D-19/investigation.md) | [Read](confirmation/CR-D-19/debate.md) | [test_bugCR-D-19_attempt_counter_int_wrap.sh](repro/test_bugCR-D-19_attempt_counter_int_wrap.sh) |
| CR-D-20 | [Read](confirmation/CR-D-20/investigation.md) | [Read](confirmation/CR-D-20/debate.md) | [test_bugCR-D-20_incrementing_wait_overflow.sh](repro/test_bugCR-D-20_incrementing_wait_overflow.sh) |
| CR-D-21 | [Read](confirmation/CR-D-21/investigation.md) | [Read](confirmation/CR-D-21/debate.md) | [test_bugCR-D-21_fibonacci_overflow_wrap.sh](repro/test_bugCR-D-21_fibonacci_overflow_wrap.sh) |
| CR-D-22 | [Read](confirmation/CR-D-22/investigation.md) | [Read](confirmation/CR-D-22/debate.md) | [test_bugCR-D-22_subms_stop_after_delay.sh](repro/test_bugCR-D-22_subms_stop_after_delay.sh) |
| CR-D-23 | [Read](confirmation/CR-D-23/investigation.md) | [Read](confirmation/CR-D-23/debate.md) | Not available |
| MC-1 | [Read](confirmation/MC-1/investigation.md) | [Read](confirmation/MC-1/debate.md) | [test_bugMC-1_timed_out_attempt_overlap.sh](repro/test_bugMC-1_timed_out_attempt_overlap.sh) |
| MC-10 | [Read](confirmation/MC-10/investigation.md) | [Read](confirmation/MC-10/debate.md) | [test_bugMC-10_negative_sleep_iae.sh](repro/test_bugMC-10_negative_sleep_iae.sh) |
| MC-11 | [Read](confirmation/MC-11/investigation.md) | [Read](confirmation/MC-11/debate.md) | [test_bugMC-11_listener_added_after_build.sh](repro/test_bugMC-11_listener_added_after_build.sh) |
| MC-12 | [Read](confirmation/MC-12/investigation.md) | [Read](confirmation/MC-12/debate.md) | [test_bugMC-12_timeout_ends_call_execution_exception.sh](repro/test_bugMC-12_timeout_ends_call_execution_exception.sh) |
| MC-2 | [Read](confirmation/MC-2/investigation.md) | [Read](confirmation/MC-2/debate.md) | [test_bugMC-2_stuck_attempt_thread_leak.sh](repro/test_bugMC-2_stuck_attempt_thread_leak.sh) |
| MC-3 | [Read](confirmation/MC-3/investigation.md) | [Read](confirmation/MC-3/debate.md) | [test_bugMC-3_timeout_discards_completion.sh](repro/test_bugMC-3_timeout_discards_completion.sh) |
| MC-4 | [Read](confirmation/MC-4/investigation.md) | [Read](confirmation/MC-4/debate.md) | [test_bugMC-4_interrupt_swallowed.sh](repro/test_bugMC-4_interrupt_swallowed.sh) · [test_bugMC-4_wrap_cancel_sharing.sh](repro/test_bugMC-4_wrap_cancel_sharing.sh) |
| MC-5 | [Read](confirmation/MC-5/investigation.md) | [Read](confirmation/MC-5/debate.md) | [test_bugMC-5_callable_interrupt_retried.sh](repro/test_bugMC-5_callable_interrupt_retried.sh) |
| MC-6 | [Read](confirmation/MC-6/investigation.md) | [Read](confirmation/MC-6/debate.md) | [test_bugMC-6_wrap_cancel_endless_retry.sh](repro/test_bugMC-6_wrap_cancel_endless_retry.sh) |
| MC-7 | [Read](confirmation/MC-7/investigation.md) | [Read](confirmation/MC-7/debate.md) | [test_bugMC-7_builder_listener_cme.sh](repro/test_bugMC-7_builder_listener_cme.sh) |
| MC-8 | [Read](confirmation/MC-8/investigation.md) | [Read](confirmation/MC-8/debate.md) | [test_bugMC-8_bounded_executor_attempt_accounting.sh](repro/test_bugMC-8_bounded_executor_attempt_accounting.sh) |
| MC-9 | [Read](confirmation/MC-9/investigation.md) | [Read](confirmation/MC-9/debate.md) | [test_bugMC-9_rejected_submit_misattributed.sh](repro/test_bugMC-9_rejected_submit_misattributed.sh) |

## Technical Details

- TLA+ models: [base.tla](spec/base.tla) · [MC.tla](spec/MC.tla) · [Trace.tla](spec/Trace.tla)
- Harness guide: [INSTRUMENTATION.md](harness/INSTRUMENTATION.md)
- Repair history: [repair-ledger.md](spec/repair-ledger.md)

## Troubleshooting

- Full pipeline log: [pipeline.log](../../pipeline.log)
