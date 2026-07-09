# dotfiles

Single home for personal configuration.

## Install

```bash
git clone <repo-url> ~/.dotfiles
~/.dotfiles/scripts/setup.sh
```

For the current machine/session, use this if you do not want to replace the live Pi runtime directory yet:

```bash
~/.dotfiles/scripts/setup.sh --skip-pi
```

## Layout

This repo mirrors `$HOME` where practical:

- `.config/nvim` -> `~/.config/nvim`
- `.config/opencode` -> `~/.config/opencode`
- `.emacs.d` -> `~/.emacs.d`
- `.pi` -> `~/.pi`
- `.agents/skills/architect` -> `~/.agents/skills/architect`
- shell/git/tmux files -> their normal home paths

Vim config is intentionally not included.

## Notes

- Existing targets are backed up under `~/.dotfiles-backup/<timestamp>/` before symlinking.
- Emacs' nested `.git` directory was removed from `.emacs.d` during migration.
- Pi auth/session/runtime directories are ignored; audit before force-adding any Pi files.
- Git identity and other machine-specific Git settings live in `~/.gitconfig.local`, which is included by the tracked `.gitconfig` but remains outside this repository. Bootstrap it once with `cp ~/.dotfiles/.gitconfig.local.example ~/.gitconfig.local` and fill in its placeholders.
- The architect workflow is maintained as a portable skill; invoke it in Pi with `/skill:architect <task>`.
