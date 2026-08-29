# Delegation policy

Delegate bounded work when context isolation, independent judgment, or parallel speed justifies the overhead. Do not
delegate micro-tasks or duplicate assigned work.

The primary thread and any selected `lead` follow this delegation, routing, execution, and integration workflow. The
primary thread owns requirements, approvals, scope expansion, top-level and cross-lead decisions, final verification,
and the final response; a lead owns decisions within its assigned bounded outcome. Keep their direct work to
requirements and decomposition, low-output triage, integration, and small decisive checks. Delegate broad searches,
multi-file investigation, large reviews, noisy tests or logs, and repeated diagnostics.

The primary thread may spawn specialists as needed. A selected `lead` must spawn at least one specialist and may create
only one specialist layer; its children may not spawn. Selecting `lead` grants this nesting authority without requiring
a separate phrase in its brief. When subagent coordination is unnecessary, use direct specialist roles rather than a
lead.

## Routing

Use the configured roles without model or reasoning overrides:

- `lead`: bounded, cross-cutting coordination that requires subagents.
- `worker`: specified implementation and fixes.
- `explorer`: targeted read-only discovery.
- `reviewer`: independent correctness, security, and regression review.
- `validator`: focused, potentially noisy validation.
- `default`: other bounded work.

If a role is unavailable, substitute only when another configured role still meets the acceptance criteria; otherwise
reduce scope or report the limitation.

## Execution

- Give fresh agents a self-contained brief: objective and deliverable; scope, ownership, and exclusions; acceptance and
  validation; relevant constraints or snapshot; edit authority; and task-specific nesting constraints beyond role
  defaults.
- Normally pass no inherited turns. Pass limited recent context only when restating it would be less reliable; use full
  history only when continuity is essential.
- Parallelize only stable, independent lanes. Usually run one or two children; use three only when coordination cost is
  justified.
- Prefer one active writer per checkout. Use the shared checkout for short, non-overlapping work; use primary-managed
  worktrees for multiple long-running writers or overlapping build/generated state.
- Keep lane follow-up with the same agent and request deltas. Do not poll or narrate unchanged state.
- Do not paste full conversations, logs, or diffs into briefs. Agents return findings in their final response and do not
  create report files.

## Integration

Require decision-relevant evidence, not raw transcripts or full diffs. Verify with the agent verdict plus targeted
inspection of the highest-risk changed state; do not replay completed work. Route fixes and rechecks to the lane owner,
then report the integrated result.
