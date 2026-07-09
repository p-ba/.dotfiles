---
name: project-setup
description: Use when setting up build/test/lint automation for a local project. Triggers when the user asks to create a Makefile, set up pre-commit hooks, add build/run/test/lint targets, or bootstrap project automation regardless of tech stack.
---

# Project Setup

Generate a `Makefile` at the project root that provides standard automation
targets for *any* tech stack, plus a pre-commit hook that runs linters against
changed files and the test suite.

## Workflow

1. Detect the tech stack by inspecting the repo (look for `package.json`,
   `Cargo.toml`, `go.mod`, `pyproject.toml`/`requirements.txt`/`setup.py`,
   `pom.xml`/`build.gradle`, `*.csproj`/`*.sln`, `Mix.exs`, `Gemfile`,
   `Package.swift`, `*.xcodeproj`, etc.). Read only what you need to identify
   the language, package manager, build tool, linter, and test runner.
2. Derive the concrete commands for each target from what you found. Do not
   invent commands; if you cannot find a linter/test runner, ask the user
   instead of guessing.
3. Write a `Makefile` (at the repo root) with the targets below. Use `.PHONY`
   for every target. Keep target names stable across stacks so the user
   muscle-memory transfers; only the bodies change.
4. Create the pre-commit hook at `.git/hooks/pre-commit` that:
   - Stages nothing itself.
   - Operates only on changed (staged) files.
   - Runs the project's linter(s) against those changed files (scoped when the
     linter supports it; otherwise full lint).
   - Runs the project's test suite.
   - Exits non-zero if either step fails, blocking the commit.
   - Is made executable (`chmod +x`).
5. Implement the hook install as the **default** (first) Makefile target
   (`install-hooks`), and make every other target depend on it so that the
   hook is (re)installed/refreshed whenever any `make <target>` runs.
6. Print a short summary of each target and the detected stack so the user can
   verify the choices. If anything was guessed, call it out.

## Required Makefile targets

- `install-hooks` (default, first target): writes/refreshes
  `.git/hooks/pre-commit` from the canonical script below and `chmod +x` it.
  All other targets depend on this one.
- `build`: compile/build the project artifact.
- `run`: build (if needed) and run the app/CLI/server locally.
- `test`: run the full test suite.
- `lint`: run the project linter(s) across the whole project.
- `check`: run `lint` then `test` (the "everything green" target).
- `clean`: remove build artifacts.
- `help`: list available targets (print target name + one-line description).

## Canonical pre-commit hook

Always write this shape into `.git/hooks/pre-commit` (replace the placeholder
lines with the stack-specific lint/test commands you derived):

```sh
#!/usr/bin/env sh
set -e

# Files changed in this commit.
CHANGED=$(git diff --cached --name-only --diff-filter=ACMR)

# --- Lint changed files -----------------------------------------------------
# Replace the line below with the stack-specific command that lints $CHANGED
# (or the whole project if the linter cannot scope to a file list).
<lint-command-here>

# --- Tests ------------------------------------------------------------------
# Replace the line below with the stack-specific test command.
<test-command-here>

echo "pre-commit: lint + tests passed"
```

Notes:
- Keep `set -e` so any failure aborts the commit.
- If the linter formats files, leave formatting fixes unstaged and let the
  user re-`git add` — the hook must not auto-stage.
- If the project has no test runner yet, fail loudly with a clear message
  instead of silently passing.

## Conventions

- Use tabs for Makefile indentation (required by `make`).
- Prefer portable shell (`/bin/sh`) in recipes; use `bash` only if needed.
- Do not add comments to the `Makefile` or hook unless the user asks.
- Do not commit anything unless the user explicitly asks.
- After writing, remind the user to restart opencode is not needed here —
  these are project files, not opencode config.