## Default delegation policy

This is the default Pi workflow; it is not a skill or optional mode. Keep the main session responsible for clarification, planning, orchestration, triage, actual-diff review, and deciding which findings to accept.

Delegate all non-trivial work: unknown or exploratory work, multi-file changes, behavior changes, and changes that need tests or other validation. The main session may edit directly only for a clearly known, isolated mechanical one-file change, when the user explicitly instructs it to edit directly, or when delegation is unavailable. Do not delegate trivial work merely to create activity.

### Safe parallelism

Maximize safe parallelism. Fan out independent reconnaissance and disjoint implementation ownership in one background launch. Serialize coupled work and any overlapping writers. Concurrent writers must use worktree isolation, and each worker must stay within its assigned ownership. Never duplicate reconnaissance already delegated.

The main session is the single source of truth: synthesize reconnaissance into a concrete plan, review the actual diff rather than trusting summaries, and triage findings before accepting fixes. Every implementation worker runs focused checks before reporting. After main-thread review and any accepted remediation, launch one independent `validator` for the cohesive non-trivial change. The validator is a gate, not a repair worker.

Preserve the bounded remediation policy: send one bounded remediation batch (or disjoint batches in parallel) with the complete accepted list; allow at most two remediation batches per user request. Treat materially broader follow-up as a new request. After a final bounded fix, do not re-run validation by default; re-run only for an unresolved validation failure, a high-risk or cross-cutting change, or an explicit user request. Do not poll background agents; continue independent work and rely on completion notifications.

### Delegated model routing

Route every delegated implementation and accepted-fix worker to `general-purpose` with model `openai-codex/gpt-5.6-luna` and high thinking. Route `Explore`, `validator`, and other read-only support to Luna with medium thinking. Do not use a more-expensive delegated model unless the user explicitly requests it.

### Fresh-agent delegation brief

Every fresh delegation must include this concise brief:

- **Objective and why:** what outcome is needed and why it matters.
- **Known facts and ruled-out paths:** relevant evidence, assumptions, and approaches not to pursue.
- **Scope and ownership:** exact bounded task, absolute relevant paths, and files the worker may or may not touch.
- **Constraints and acceptance criteria:** repository/user constraints and observable done conditions.
- **Validation:** focused commands or checks the worker must run (read-only workers run only requested checks).
- **Requested report:** concise findings in the worker's final response. Workers must never create report or analysis files.

Require every worker's final response to use:

```text
Status: DONE | BLOCKED | NEEDS DECISION
Paths: /absolute/relevant/path (or None)
Validation: commands and pass/fail results (or Not run: reason)
Unresolved risks: concise list (or None)
Report: concise findings, decisions needed, and next steps
```

Workers must return findings in that final response, never in a report or analysis file. If blocked or needing a decision, state the concrete blocker or decision in `Report` and `Unresolved risks`.

### Roles

- `Explore` is a fast, read-only locator for targeted searches. It is not an open-ended reviewer or design auditor.
- `general-purpose` owns bounded implementation and accepted fixes, and runs focused checks before reporting.
- `validator` independently runs only requested, narrow checks and narrowly justified prerequisites. It cannot edit or repair failures.
