# dotfiles

Single home for personal configuration.

## Install

```bash
git clone git@github.com:p-ba/.dotfiles.git ~/.dotfiles
~/.dotfiles/scripts/setup.sh
```

## Layout

This repo mirrors `$HOME` where practical:

- `.config/nvim` -> `~/.config/nvim`
- `.codex/AGENTS.md` -> `~/.codex/AGENTS.md`
- `.codex/agents` -> `~/.codex/agents`
- `.config/opencode` -> `~/.config/opencode`
- `.config/sublime-text/Packages/User` -> `~/Library/Application Support/Sublime Text/Packages/User` (macOS) or `~/.config/sublime-text/Packages/User` (Linux)
- `.emacs.d` -> `~/.emacs.d`
- `.pi` -> `~/.pi`
- shell/git/tmux/ripgrep files -> their normal home paths

Vim config is intentionally not included.

## Notes

- Existing targets are backed up under `~/.dotfiles-backup/<timestamp>/` before symlinking.
- Emacs' nested `.git` directory was removed from `.emacs.d` during migration.
- Pi auth/session/runtime directories are ignored; audit before force-adding any Pi files.
- `~/.codex` is always a real, local Codex runtime directory. It holds auth, sessions, caches, plugins, and the user-owned `config.toml`; none of that runtime state is linked into or tracked by this repository.
- Setup links only durable Codex guidance (`AGENTS.md`) and custom roles (`agents/`) from Git. It seeds `~/.codex/config.toml` from tracked `.codex/config.base.toml` only when no local config exists, so later setup runs never overwrite local configuration.
- A legacy whole-directory `~/.codex` symlink is backed up without following it and replaced with a real directory. Migrate runtime state from the old referent before running setup on a legacy installation; the 2026-08-14 upgrade of this repository performed that move in place. Existing local `AGENTS.md` or `agents/` entries are backed up individually before the managed links are installed.
- Codex uses Sol for the primary session; Terra powers the default, worker, validator, and independent reviewer roles; Luna powers focused read-only exploration. Shell aliases keep `codex` on its normal approval safeguards, `c` is the same command, and `ca` opts into automatic approval review. The portable baseline uses on-request approval and workspace-scoped permissions; start a new Codex session after changing guidance or roles.
- Git identity and other machine-specific Git settings live in `~/.gitconfig.local`, which is included by the tracked `.gitconfig` but remains outside this repository. On first setup, the script prompts for your name and email and creates this file outside the repository.
