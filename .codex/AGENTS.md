# Default delegation policy

Delegate concrete, bounded work when there is a clear benefit from context isolation, independent judgment, or parallel
speed. Context isolation does not require parallelism: sequential exploration, implementation, review, and validation
may use separate agents when their intermediate output does not belong in the primary thread. Do not delegate
micro-tasks or merely create activity.

The primary thread owns user requirements and clarification, approval boundaries, task decomposition, cross-lane
decisions, final verification, and the final response. Keep its direct work to low-output triage, integration decisions,
and small decisive checks. Delegate broad searches, multi-file investigation, large diff review, test or log output,
repeated diagnostics, and other context-heavy work. Keep only tiny mechanical changes, immediate blockers, and genuinely
indivisible work on the primary thread. Do not duplicate work assigned to an agent.

Only the primary thread spawns subagents by default. For a large context-heavy task, it may authorize one `lead` agent
to spawn one nested layer of specialists within an exact scope. Other children must not spawn agents unless their brief
explicitly authorizes it.

## Primary-thread context budget

- Before a direct tool call, consider whether its raw output is necessary for a primary-thread decision. Delegate calls
  likely to produce exploratory branches, long source excerpts, logs, stack traces, or broad test output.
- Give fresh agents a self-contained brief and normally use no inherited turns. Use a small recent-turn window only when
  reproducing the relevant requirements would be less reliable; use full history only when continuity itself is
  essential.
- Keep lane-local follow-up in the same agent with a follow-up task. Ask for deltas instead of restating the task or
  spawning a replacement agent.
- Require decision-relevant evidence packets. Do not request raw command transcripts, full diffs, or repeated background
  unless a specific unresolved decision needs them.
- Do not poll agents repeatedly or narrate unchanged state. Wait when their result is required for the next decision.

## Progressive delegation and safe parallelism

Scale delegation to context volume, uncertainty, independence, and risk instead of applying a fixed sequence:

1. Perform only minimal direct triage needed to classify the task, such as status, a diff stat, or an exact symbol
   lookup.
2. Use an `explorer` before broad source reading or open-ended discovery. Exploration may be sequential on the critical
   path; the agent returns locations, facts, and unresolved questions rather than its search transcript.
3. Delegate implementation after file ownership, constraints, and acceptance criteria are clear. Prefer one `worker` and
   one writer per checkout. Use concurrent writers only when their code, tests, generated state, and validation cannot
   overlap.
4. For large, ambiguous, or cross-cutting work, prefer one `lead` that owns the bounded outcome, coordinates an
   explicitly authorized nested layer, and returns one synthesized packet to the primary thread.
5. Use a `reviewer` when correctness, security, API, migration, concurrency, or regression risk warrants independent
   judgment.
6. Use a `validator` for non-trivial checks, output-heavy tests, repeated verification, or any validation whose output
   is not predictably small. The primary may run small focused checks needed for final confidence.
7. Verify through cited evidence, an independently reported verdict, and targeted inspection of the highest-risk changed
   state. Do not replay every agent command or reread the entire diff merely to duplicate completed work.
8. Route fixes and rechecks back to the agent that owns that lane, request only the delta, then report the integrated
   result.

Sequential delegation is appropriate for context isolation. Parallelize only stable, independent lanes. Ordinarily use
one or two active children per coordinator; use three only when the lanes are genuinely independent and the coordination
cost is justified.

Use the shared checkout for short, bounded changes with explicit ownership and at most one active writer. Use
primary-managed separate worktrees for multiple long-running writers, write-heavy work, overlapping build or generated
state, or likely integration conflicts. The primary owns cross-worktree integration and cleanup; a `lead` may integrate
only its explicitly assigned scope in a shared checkout.

## Delegated model routing

Use the configured custom roles for all delegated work. Their agent files pin the intended model and reasoning effort;
do not pass redundant `model` or `reasoning_effort` overrides when spawning them.

Use these custom roles:

- `lead`: demanding context-heavy coordination and cross-cutting delivery within a bounded scope.
- `worker`: fully specified implementation and accepted fixes.
- `explorer`: targeted read-only discovery.
- `reviewer`: independent read-only review for correctness, security, regressions, and missing tests.
- `validator`: focused validation of the integrated target.
- `default`: other bounded delegated work.

If a configured role is unavailable or does not use the expected model, do not silently substitute another model. Use
the nearest suitable configured role only when it still meets the task's acceptance criteria; otherwise continue with a
deliberately reduced scope or report the routing limitation.

## Delegation brief

Give each fresh delegation a concise, self-contained brief containing:

- Objective and expected deliverable.
- Exact scope, file ownership, and excluded paths.
- Observable acceptance criteria and focused validation.
- Relevant decisions, constraints, and the target diff or immutable snapshot when applicable.
- Whether edits or one nested delegation layer are authorized.

Do not paste the full conversation, raw logs, or a full diff into the brief when a compact statement or snapshot
reference is sufficient. The role definitions own the final evidence-packet format; do not repeat that schema in every
brief. Subagents return findings in their final response and must not create report or analysis files.
