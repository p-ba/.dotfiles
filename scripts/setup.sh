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

link_codex() {
  local source="$DOTFILES_DIR/.codex"
  local target="$HOME/.codex"

  if [[ ! -d "$source" ]]; then
    echo "skip missing source: $source"
    return 0
  fi

  if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then
    echo "ok: $target -> $source"
    return 0
  fi

  run mkdir -p "$(dirname "$target")"

  if [[ "$DRY_RUN" == 1 ]]; then
    if [[ -d "$target" && ! -L "$target" ]]; then
      echo "[dry-run] would merge local Codex data from: $target"
    elif [[ -e "$target" || -L "$target" ]]; then
      echo "[dry-run] would backup: $target -> $BACKUP_DIR/${target#$HOME/}"
    fi
    echo "[dry-run] ln -s $source $target"
    return 0
  fi

  if [[ -d "$target" && ! -L "$target" ]]; then
    local backup_target="$BACKUP_DIR/${target#$HOME/}"
    local entry name link

    echo "backup: $target -> $backup_target"
    mkdir -p "$(dirname "$backup_target")"
    mv "$target" "$backup_target"

    while IFS= read -r -d '' entry; do
      name="${entry##*/}"
      if [[ -L "$entry" ]]; then
        link="$(readlink "$entry")"
        if [[ "$name" == "AGENTS.md" && "$link" == "$source/AGENTS.md" ]] ||
           [[ "$name" == "agents" && "$link" == "$source/agents" ]]; then
          continue
        fi
      fi
      if [[ -e "$source/$name" || -L "$source/$name" ]]; then
        echo "Codex source conflict: $source/$name" >&2
        mv "$backup_target" "$target"
        return 1
      fi
    done < <(find -P "$backup_target" -mindepth 1 -maxdepth 1 -print0)

    while IFS= read -r -d '' entry; do
      name="${entry##*/}"
      if [[ -L "$entry" ]]; then
        link="$(readlink "$entry")"
        if [[ "$name" == "AGENTS.md" && "$link" == "$source/AGENTS.md" ]] ||
           [[ "$name" == "agents" && "$link" == "$source/agents" ]]; then
          rm "$entry"
          continue
        fi
      fi
      mv "$entry" "$source/$name"
    done < <(find -P "$backup_target" -mindepth 1 -maxdepth 1 -print0)
    rmdir "$backup_target" "$BACKUP_DIR" 2>/dev/null || true
  elif [[ -e "$target" || -L "$target" ]]; then
    local backup_target="$BACKUP_DIR/${target#$HOME/}"
    echo "backup: $target -> $backup_target"
    mkdir -p "$(dirname "$backup_target")"
    mv "$target" "$backup_target"
  fi

  echo "link: $target -> $source"
  ln -s "$source" "$target"
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
  ".ripgreprc:$HOME/.ripgreprc"
  ".gitconfig:$HOME/.gitconfig"
)

if [[ -n "$SUBLIME_USER_DIR" ]]; then
  LINKS+=(".config/sublime-text/Packages/User:$SUBLIME_USER_DIR")
else
  echo "skip Sublime Text config: unsupported platform $(uname -s)"
fi

if [[ "$SKIP_PI" != 1 ]]; then
  LINKS+=(".pi:$HOME/.pi")
fi

link_codex

for mapping in "${LINKS[@]}"; do
  link_one "${mapping%%:*}" "${mapping#*:}"
done

bootstrap_git_identity

echo "Done. Dotfiles root: $DOTFILES_DIR"
