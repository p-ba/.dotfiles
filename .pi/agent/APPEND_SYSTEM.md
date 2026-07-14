## Default Development Delegation

Outside architect mode or another workflow that explicitly prohibits main-thread implementation, use direct tools for known, mechanical one-file changes. Do not delegate work merely to create activity.

For broad repository searches or two or more independent unknowns, launch one to three `Explore` agents in one turn with background execution. Divide their work by concern and do not duplicate their searches in the main thread.

After a cohesive non-trivial implementation—behavior changes, test changes, or changes spanning multiple files—the main session reviews the actual diff and worker results using its full task context. Do not delegate code review by default. Launch the `validator` once after the main-thread review and any resulting remediation are complete.

Treat main-thread review as a gate, not a ping-pong loop:

- Have the implementation worker run focused checks before the main review.
- The main session inspects the actual diff, requirements, and validation output, then sends one bounded remediation task (or disjoint remediation tasks in parallel) with the complete accepted list.
- The remediation worker runs focused validation. Then launch the independent `validator` against the resulting cohesive change set.
- The main session triages validator findings and directs a final bounded fix only when needed. Do not re-run validation by default after that fix; re-run it only for an unresolved validation failure, a high-risk/cross-cutting change, or an explicit user request.
- Use at most two remediation batches per user request. Treat materially broader follow-up work as a new request.

Use `general-purpose` agents for bounded implementation and batched fix slices. Launch independent slices in parallel only when concurrent writers have disjoint ownership and worktree isolation; otherwise serialize them. The main thread owns orchestration, final diff inspection, finding triage, and integration.

Do not poll background agents. Continue non-overlapping work until completion notifications arrive.

### Subagent model routing

Apply this routing to normal development and architect workflows:

- Code review: main session with its current model and full task context (normally Sol/high).
- Implementation and accepted fixes: `general-purpose` with `openai-codex/gpt-5.6-luna`, thinking `high`.
- Exploration, validation, and other read-only support: `Explore` or `validator` with `openai-codex/gpt-5.6-luna`, thinking `medium`.

Always pass the model and thinking level explicitly when the agent definition does not already pin them.
