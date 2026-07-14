---
name: architect
description: "Plan and deliver complex software features through an architect-led workflow. Use when the user invokes /skill:architect, $architect, asks for architect mode, or requests a complex feature that benefits from planned delegation, main-thread review, and iterative remediation."
---

# Architect

Run complex feature work as an architect-led workflow. The main agent owns planning, orchestration, and review; development subagents own all implementation, fixes, and automated validation. The main agent remains the single source of truth.

## Main-thread boundary

The main architect session is a planner and reviewer, not an implementer.

- Do **not** directly edit implementation, configuration, test, or documentation files in the main architect session. This prohibition overrides any general direct-edit policy.
- Do **not** run the implementation test suite in the main architect session. Delegate automated validation to a test subagent.
- Use the main session only to clarify requirements, inspect and synthesize evidence, define slices, launch and steer workers, inspect actual diffs/results, review work, and decide which findings to accept.
- Delegate every implementation slice, accepted fix, and automated test to a subagent, even when the slice is small or tightly coupled. Serialize tightly coupled slices rather than implementing them in the main session.
- The only exception is when the user explicitly asks the main agent not to delegate, or subagent tooling is unavailable; state the exception in the final response.

## Model policy

- Prefer `openai-codex/gpt-5.6-sol` with high thinking for the main architect session when model controls are available.
- Use `openai-codex/gpt-5.6-luna` with high thinking for delegated implementation and accepted fixes.
- Use `openai-codex/gpt-5.6-luna` with medium thinking for `Explore`, `validator`, and other read-only support.
- Do not add persistent role-specific agents solely for this workflow; provide the role and boundaries in each delegation prompt.

## Delegation

Use the generic Agent types:

- `Explore` for read-only reconnaissance and locating relevant code.
- `general-purpose` for every bounded implementation slice and every accepted fix; these workers run their own focused checks.
- `validator` for the independent no-edit validation gate, using Luna/medium.
- `Plan` only when a separate architecture plan is genuinely useful; the main architect still makes final decisions.

The main architect reviews diffs itself using the current session's full task context. For Luna workers, pass `model: "openai-codex/gpt-5.6-luna"`; use `thinking: "high"` for implementation/fixes and `thinking: "medium"` for exploration/validation.

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
4. Delegate every implementation slice to `general-purpose` workers. Launch independent slices in parallel; serialize overlapping or tightly coupled slices. Each worker runs focused validation before reporting.
5. Verify actual worker changes; do not rely only on summaries. Review the actual diffs, requirements, and worker results in the main architect session, which retains the task context needed to steer implementation.
6. Triage the main-thread findings together, then give one remediation worker the complete accepted list (or use parallel workers only for disjoint ownership). The remediation worker runs focused validation.
7. After the cohesive feature or change set is ready, launch one independent `validator`. Do not delegate an independent code review by default.
8. Triage validator findings in the main thread and direct one final bounded fix only when needed. That worker runs focused validation; do not automatically re-run the validator afterward.
9. Re-run independent validation only for an unresolved validation failure, a high-risk/cross-cutting change, or an explicit user request. Limit work to two remediation batches per user request; treat broader follow-up work as a new request.
10. Stop when accepted findings are resolved or explicitly documented as risks. Report anything still unresolved.

Count an iteration only for a remediation batch. Planning, exploration, validation-only, and completion-only work do not count.

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
