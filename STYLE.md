# Repository style guide

This repository stores configuration that is read by many different tools. Prefer small, unsurprising changes and
preserve the behavior of the program that owns each file.

## General rules

- Use UTF-8, Unix line endings, and a final newline.
- Keep lines at or below 120 characters in every human-maintained source and configuration file.
- Wrap prose at word boundaries. Do not reflow generated files or change a literal value merely to meet the limit.
- Long URLs, unbreakable identifiers or regular expressions, Markdown code blocks, and Markdown table rows may exceed
  120 characters when wrapping would harm behavior. Mark a non-Markdown exception immediately above the line with
  `line-length-exception: next-line`; generated dependency lockfiles are checked for syntax but not line length.
- Indent with spaces unless the language or file format requires tabs.
- Keep secrets, machine-local state, caches, dependencies, and generated output out of version control.
- Comments should explain intent or a constraint, not restate the code.

## Language and format conventions

### Shell and Zsh

Use Bash only when Bash features are needed; otherwise prefer portable shell syntax. Quote expansions, use
`set -euo pipefail` in non-interactive Bash scripts, and make the interpreter explicit with a shebang. Interactive Zsh
configuration may use native Zsh features. Shell files must pass their interpreter's syntax check; Bash and POSIX shell
files must also pass ShellCheck.

### Lua

Follow StyLua's default layout with a 120-column limit. Prefer local variables and small modules. Neovim-specific
globals are acceptable where the API requires them.

### Emacs Lisp

Use two-space indentation, conventional `kebab-case` names, and balanced readable forms. Keep package side effects
explicit. All tracked forms must be readable by Emacs without loading the user's configuration.

### TypeScript

Use ES modules, two-space indentation, semicolons, and trailing commas where supported. Avoid `any`; validate values
received from external APIs.

### Python

Follow Ruff's lint rules with a 120-column limit. Prefer type hints for public helpers and avoid import-time side
effects in editor integrations.

### JSON

Use two-space indentation and valid JSON without comments or trailing commas. Preserve the ordering of human-maintained
configuration when it aids scanning. Generated lock files are syntax-checked but are not manually reformatted.

### TOML

Use two-space indentation for arrays and inline structures, one key per line, and a 120-column limit. Wrap prose in
multiline strings; use TOML's line-ending backslash when a newline must not become part of the value. Do not split
identifiers or other literal values when that would change their meaning.

### Markdown

Use ATX headings, fenced code blocks with a language tag when known, and blank lines around block elements. Wrap prose
to 120 columns. Long URLs, code blocks, and tables are the documented line-length exceptions. Markdown fragments used as
agent prompts do not require a top-level heading.

### YAML

Use two-space indentation, explicit booleans, and a 120-column limit. Break long collections and mappings across lines.
Unbreakable URLs and scalar values may exceed the limit when folding would change the value.

### Editor and native configuration

Sublime JSONC formats (including settings, keymaps, commands, menus, macros, projects, themes, and color schemes) must
parse as JSON with comments; snippets must be valid XML. Git configuration is parsed by Git, ripgrep configuration is
exercised by ripgrep, and tmux configuration is loaded by a short-lived isolated tmux server. NeoVintageous
configuration receives the common line-length and whitespace checks, but has no standalone side-effect-free syntax mode,
so the lint command does not claim deeper validation for it.

## Running checks

Run `scripts/lint` from anywhere in the checkout. It checks tracked files and nonignored untracked files, so new source
is covered before staging while ignored runtime state and installed dependencies remain excluded. Package-manager lint
tool versions used in automation are pinned in `.github/workflows/lint.yml`; local installation commands are documented
in `README.md`.
