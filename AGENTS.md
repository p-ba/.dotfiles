# Dotfiles repository guidance

This repository mirrors `$HOME` where practical. Tracked configuration lives at the repository root (for example
`.config/`, `.codex/`, `.emacs.d/`, `.tmux/`, shell and Git dotfiles); `scripts/setup.sh` links those paths into the
home directory. Codex is the exception: `~/.codex` stays a real local runtime directory while only durable guidance and
custom agents are linked from this repository. Treat ignored runtime, auth, cache, and session data as local state
rather than source material.

## Safe scope

Make only the files needed for the assigned change. Preserve unrelated dirty worktree changes and do not reset, clean,
or overwrite them. Inspect existing setup behavior before changing links, backup logic, or platform-specific paths. Do
not run `scripts/setup.sh` without `--dry-run` unless the user explicitly authorizes filesystem changes outside the
repository.

## Validation and completion

For changes affecting setup, run these non-mutating checks when applicable:

```bash
bash -n scripts/setup.sh
scripts/setup.sh --dry-run
git diff --check
```

Before reporting done, inspect the relevant diff, run focused checks for changed files, and state any checks not run and
why. A change is done only when it is within scope, preserves unrelated work, passes applicable validation, and has no
unresolved blockers.
