#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=0
SKIP_PI=0

usage() {
  cat <<'USAGE'
Usage: setup.sh [--dry-run] [--skip-pi]

Symlink dotfiles from this repository into $HOME.
Existing files/directories are moved to ~/.dotfiles-backup/<timestamp>/.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --skip-pi) SKIP_PI=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 2 ;;
  esac
  shift
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

case "$(uname -s)" in
  Darwin) SUBLIME_USER_DIR="$HOME/Library/Application Support/Sublime Text/Packages/User" ;;
  Linux) SUBLIME_USER_DIR="$HOME/.config/sublime-text/Packages/User" ;;
  *) SUBLIME_USER_DIR="" ;;
esac

run() {
  if [[ "$DRY_RUN" == 1 ]]; then
    printf '[dry-run] %q ' "$@"
    printf '\n'
  else
    "$@"
  fi
}

link_one() {
  local rel="$1"
  local target="$2"
  local source="$DOTFILES_DIR/$rel"

  if [[ ! -e "$source" && ! -L "$source" ]]; then
    echo "skip missing source: $source"
    return 0
  fi

  if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then
    echo "ok: $target -> $source"
    return 0
  fi

  run mkdir -p "$(dirname "$target")"

  if [[ -e "$target" || -L "$target" ]]; then
    local backup_target="$BACKUP_DIR/${target#$HOME/}"
    echo "backup: $target -> $backup_target"
    run mkdir -p "$(dirname "$backup_target")"
    run mv "$target" "$backup_target"
  fi

  echo "link: $target -> $source"
  run ln -s "$source" "$target"
}

bootstrap_git_identity() {
  local local_gitconfig="$HOME/.gitconfig.local"
  local git_name git_email

  if [[ -e "$local_gitconfig" || -L "$local_gitconfig" ]]; then
    return 0
  fi

  if [[ "$DRY_RUN" == 1 ]]; then
    echo "[dry-run] would prompt for Git name and email, then create: $local_gitconfig"
    return 0
  fi

  echo "Git identity is not configured."
  read -r -p "Git user name: " git_name
  read -r -p "Git user email: " git_email

  git config --file "$local_gitconfig" user.name "$git_name"
  git config --file "$local_gitconfig" user.email "$git_email"
  echo "created: $local_gitconfig"
}

LINKS=(
  ".config/nvim:$HOME/.config/nvim"
  ".config/opencode:$HOME/.config/opencode"
  ".emacs.d:$HOME/.emacs.d"
  ".tmux.conf:$HOME/.tmux.conf"
  ".tmux:$HOME/.tmux"
  ".zshrc:$HOME/.zshrc"
  ".zshenv:$HOME/.zshenv"
  ".bashrc:$HOME/.bashrc"
  ".profile:$HOME/.profile"
  ".gitconfig:$HOME/.gitconfig"
  ".agents/skills/architect:$HOME/.agents/skills/architect"
)

if [[ -n "$SUBLIME_USER_DIR" ]]; then
  LINKS+=(".config/sublime-text/Packages/User:$SUBLIME_USER_DIR")
else
  echo "skip Sublime Text config: unsupported platform $(uname -s)"
fi

if [[ "$SKIP_PI" != 1 ]]; then
  LINKS+=(".pi:$HOME/.pi")
fi

for mapping in "${LINKS[@]}"; do
  link_one "${mapping%%:*}" "${mapping#*:}"
done

bootstrap_git_identity

echo "Done. Dotfiles root: $DOTFILES_DIR"
