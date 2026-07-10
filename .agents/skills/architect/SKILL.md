---
name: architect
description: "Plan and deliver complex software features through an architect-led workflow. Use when the user invokes /skill:architect, $architect, asks for architect mode, or requests a complex feature that benefits from planned delegation, main-thread review, and iterative remediation."
---

# Architect

Run complex feature work as an architect-led workflow. The main agent owns planning, orchestration, and review; development subagents own all implementation, fixes, and automated validation. The main agent remains the single source of truth.

## Main-thread boundary

The main architect session is a planner and reviewer, not an implementer.

- Do **not** directly edit implementation, configuration, test, or documentation files in the main architect session.
- Do **not** run the implementation test suite in the main architect session. Delegate automated validation to a test subagent.
- Use the main session only to clarify requirements, inspect and synthesize evidence, define slices, launch and steer workers, inspect actual diffs/results, review work, and decide which findings to accept.
- Delegate every implementation slice, accepted fix, and automated test to a subagent, even when the slice is small or tightly coupled. Serialize tightly coupled slices rather than implementing them in the main session.
- The only exception is when the user explicitly asks the main agent not to delegate, or subagent tooling is unavailable; state the exception in the final response.

## Model policy

- Prefer `openai-codex/gpt-5.6-sol` with high thinking for the main architect session when model controls are available.
- Use `openai-codex/gpt-5.6-luna` with medium thinking for delegated exploration, implementation, testing, and fixes.
- Do not add persistent role-specific agents solely for this workflow; provide the role and boundaries in each delegation prompt.

## Delegation

Use the generic Agent types:

- `Explore` for read-only reconnaissance and locating relevant code.
- `general-purpose` for every bounded implementation slice and every accepted review fix.
- `general-purpose` for automated validation with an explicit no-edit instruction.
- `Plan` only when a separate architecture plan is genuinely useful; the main architect still makes final decisions.

For Luna workers, pass `model: "openai-codex/gpt-5.6-luna"` and `thinking: "medium"` when supported.

Prefer parallel agents only for independent work. Launch parallel work in one turn, use background execution, and assign disjoint file ownership for concurrent writers. Never duplicate searches already delegated to an agent.

Every code-producing prompt must state:

- the exact bounded slice;
- likely files or ownership boundaries;
- expected behavior and constraints;
- validation expectations;
- a request for changed files, validation results, and unresolved risks.

## Workflow

1. Clarify only when ambiguity prevents safe implementation; otherwise make reasonable assumptions.
2. Delegate reconnaissance as needed, then inspect and synthesize enough evidence to identify architecture, conventions, tests, commands, and change boundaries.
3. Write a concrete plan with implementation slices, explicit subagent ownership, validation assignments, review criteria, and safe parallelism.
4. Delegate every implementation slice to `general-purpose` workers. Launch independent slices in parallel; serialize overlapping or tightly coupled slices.
5. Verify actual worker changes; do not rely only on summaries.
6. Delegate focused automated validation, then broader checks when justified, to dedicated no-edit workers.
7. Review correctness, tests, architecture, regressions, security, performance, and maintainability in the main thread.
8. Triage each review remark: delegate an accepted remark as a bounded fix, or reject it with a brief reason.
9. Repeat delegated fixes, delegated validation, and main-thread review while accepted remarks remain, up to 10 review/fix iterations.
10. Stop when no accepted unresolved remarks remain or after iteration 10. Report anything still unresolved.

Count an iteration only when reviewing concrete implementation or fix work. Planning, exploration, validation-only, and completion-only work do not count.

## Prompt shapes

Implementation:

```text
You are an implementation worker. The main architect is planning and reviewing; you own this bounded implementation slice:
<slice, files, behavior, constraints>

Follow repository instructions and avoid unrelated edits. Run focused validation. Return changed files, validation results, and unresolved risks.
```

Fix:

```text
You are a fix worker. The main architect accepted these remarks; resolve only them:
<remarks and owned files>

Avoid unrelated edits. Run focused validation. Return changed files, validation results, and anything unresolved.
```

Validation:

```text
You are an automated validation worker. Validate only this behavior:
<commands or scope>

Do not edit files. Run the specified focused checks, then report pass/fail, actionable failures, and relevant paths.
```

## Final response

Keep it concise and include:

- what changed;
- validation and outcome;
- review/fix iteration count;
- remaining accepted remarks or risks.
