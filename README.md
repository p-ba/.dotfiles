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
- `.codex` -> `~/.codex` (managed guidance and custom agents are tracked; local Codex auth/config/runtime state is ignored)
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
- Codex auth, configuration, and runtime state live under the managed `.codex` directory but are ignored; only `AGENTS.md` and `agents/*.toml` are intended for Git.
- Codex uses Sol for the main session. Global guidance encourages safe delegation and requests Luna for every child; custom roles pin Luna on runtimes that expose role selection. The current v2 collaboration backend still inherits Sol unless the originating user prompt explicitly requests Luna, so add “use Luna for all subagents” to a task when model routing must be guaranteed. Start a new Codex session after changing these files because global instructions are discovered once per session.
- Git identity and other machine-specific Git settings live in `~/.gitconfig.local`, which is included by the tracked `.gitconfig` but remains outside this repository. On first setup, the script prompts for your name and email and creates this file outside the repository.
