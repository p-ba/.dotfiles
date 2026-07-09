---
name: architect
description: "Plan and deliver complex software features through an architect-led workflow. Use when the user invokes /skill:architect, $architect, asks for architect mode, or requests a complex feature that benefits from planned delegation, main-thread review, and iterative remediation."
---

# Architect

Run complex feature work as an architect-led workflow. The main agent owns the plan, delegates bounded work, reviews every change, and remains the single source of truth.

## Model policy

- Prefer `openai-codex/gpt-5.6-sol` with high thinking for the main architect session when model controls are available.
- Use `openai-codex/gpt-5.6-luna` with medium thinking for delegated exploration, implementation, testing, and fixes.
- Do not add persistent role-specific agents solely for this workflow; provide the role and boundaries in each delegation prompt.

## Delegation

Use the generic Agent types:

- `Explore` for read-only reconnaissance and locating relevant code.
- `general-purpose` for bounded implementation, testing, or accepted review fixes.
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
2. Inspect enough of the repository to identify architecture, conventions, tests, commands, and change boundaries.
3. Write a concrete plan with slices, ownership, validation, review criteria, and safe parallelism.
4. Delegate only when it reduces latency or protects main-thread context. Handle small or tightly coupled work directly.
5. Verify actual worker changes; do not rely only on summaries.
6. Run focused validation, then broader checks when justified.
7. Review correctness, tests, architecture, regressions, security, performance, and maintainability in the main thread.
8. Triage each review remark: accept and fix it, or reject it with a brief reason.
9. Repeat bounded fixes, validation, and review while accepted remarks remain, up to 10 review/fix iterations.
10. Stop when no accepted unresolved remarks remain or after iteration 10. Report anything still unresolved.

Count an iteration only when reviewing concrete implementation or fix work. Planning, exploration, validation-only, and completion-only work do not count.

## Prompt shapes

Implementation:

```text
You are an implementation worker. Work only on this bounded slice:
<slice, files, behavior, constraints>

Follow repository instructions and avoid unrelated edits. Run focused validation. Return changed files, validation results, and unresolved risks.
```

Fix:

```text
You are a fix worker. Resolve only these accepted review remarks:
<remarks and owned files>

Avoid unrelated edits. Run focused validation. Return changed files, validation results, and anything unresolved.
```

Validation:

```text
Validate only this behavior with read-only checks:
<commands or scope>

Do not edit files. Report pass/fail, actionable failures, and relevant paths.
```

## Final response

Keep it concise and include:

- what changed;
- validation and outcome;
- review/fix iteration count;
- remaining accepted remarks or risks.
