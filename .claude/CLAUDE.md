# Delegation

Subagents default to Sonnet: `CLAUDE_CODE_SUBAGENT_MODEL` in `~/.claude/settings.json` and the overrides in
`~/.claude/agents/`. `Plan` stays built-in and inherits the main model. Delegation is therefore cheap; use it to keep
the main context on decisions and integration.

## Roles

- `worker` (Sonnet) makes every file edit. A PreToolUse hook denies `Edit` and `Write` from every other caller,
  including the main thread, so the main thread writes briefs instead. Do not work around the hook with `Bash`.
- `reviewer` (inherits the session model, read-only) reviews every worker result before it is accepted.
- `Explore` (Sonnet, read-only) answers any lookup that would take more than two searches or reading more than two
  files.
- `general-purpose` (Opus, read-only) runs noisy commands: test suites, builds, log scans, repeated diagnostics.

The main session's unbounded reads of regular text files over 350 lines by default route to `Explore`; ask it a focused
question and request concise path:line evidence. Follow up with positive bounded `Read` limits at most the configured
threshold for direct reasoning. This is context routing rather than a security control, and must never be bypassed
through `Bash`.

## Workflow for changes

1. Understand the request, inspect enough code to decompose it, and decide what to change. Ask the user only when an
   answer blocks safe implementation.
2. Brief `worker` with: objective, files it owns and must not touch, acceptance criteria, validation to run, and the
   output wanted back. Run independent lanes in parallel only when their files do not overlap.
3. Brief `reviewer` with the original brief, the base commit, and the changed paths. Do not forward the worker's summary
   as the thing to review.
4. On FIX or REJECT, send the findings back to the same worker with SendMessage; do not spawn a fresh one. Allow at most
   two correction cycles, then report the blocker to the user.
5. Inspect the final diff yourself before reporting. Treat subagent reports as compressed evidence, not proof.

Keep the main session on substantive debugging, architecture, security decisions, and targeted verification.

Exceptions: the main thread may edit directly only for a one-line fix the user asked for by name, or to unblock a worker
that cannot proceed. Prefer a fresh Sonnet agent over a fork; forks inherit the main model and its full context.
