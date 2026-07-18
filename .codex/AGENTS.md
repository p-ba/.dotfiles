# Default delegation policy

Use subagents aggressively for concrete, bounded work that can proceed independently while the main thread continues useful work. This is the default workflow, not an optional mode.

Keep the main thread responsible for clarification, planning, orchestration, critical-path decisions, reviewing the actual worktree, and synthesizing the final result. Delegate repository exploration, independent implementation slices, test or log analysis, focused reviews, and targeted validation whenever they are substantial enough to justify a separate worker.

Keep work on the main thread when it is a tiny mechanical change, an immediate blocker for the next action, tightly coupled to current reasoning, or likely to overlap another writer. Do not delegate merely to create activity, and do not duplicate work already assigned to a subagent.

## Safe parallelism

Maximize useful parallelism within the available thread limit:

- Launch independent reconnaissance or disjoint implementation tasks together.
- Give concurrent writers disjoint file ownership. Never let agents edit overlapping files concurrently.
- Serialize coupled work and overlapping changes.
- Continue non-overlapping main-thread work while subagents run. Wait only when their result is required for the next critical-path action.
- Review the actual diff and run the final critical checks on the main thread; do not trust summaries as proof.
- Use the `validator` agent for an independent, read-only check when it can run alongside remaining review or integration work.

## Delegated model routing

The user explicitly requires every delegated agent to run on `gpt-5.6-luna`. For every `spawn_agent` call, request the `gpt-5.6-luna` model override unconditionally. Do not let a child inherit the main session's Sol model, even when the task name or custom role suggests the intended routing.

Use these custom roles where the runtime supports role selection:

- `worker`: implementation and accepted fixes, with high reasoning.
- `explorer`: targeted read-only discovery, with medium reasoning.
- `validator`: narrow read-only validation, with medium reasoning.
- `default`: other bounded delegated work, with high reasoning.

Do not use a more expensive model for a subagent unless the user explicitly requests it or Luna has produced concrete evidence that it cannot complete the assigned task. Prefer high reasoning for implementation and medium reasoning for read-only support when the runtime exposes a per-child reasoning override.

## Delegation brief

Every fresh delegation should include:

- Objective and why the result matters.
- Known facts, assumptions, and paths already ruled out.
- Exact scope, ownership, and files the agent may or may not edit.
- Constraints and observable acceptance criteria.
- Focused validation to run.
- The requested final report.

Require the final report to use this shape:

```text
Status: DONE | BLOCKED | NEEDS DECISION
Paths: /absolute/relevant/path (or None)
Validation: commands and pass/fail results (or Not run: reason)
Unresolved risks: concise list (or None)
Report: concise findings, decisions, and next steps
```

Subagents return findings in their final response and must not create report or analysis files.
