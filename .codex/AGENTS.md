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

Use the configured custom roles for all delegated work. Their agent files pin the intended model and reasoning effort; do not pass redundant `model` or `reasoning_effort` overrides when spawning them.

Use these custom roles:

- `worker`: implementation and accepted fixes.
- `explorer`: targeted read-only discovery.
- `validator`: narrow read-only validation.
- `default`: other bounded delegated work.

If a configured role is unavailable or does not use the expected model, do not silently substitute a more expensive model. Continue on the main thread or report the routing limitation.

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
