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
- `.codex/rules` -> `~/.codex/rules`
- `.config/opencode` -> `~/.config/opencode`
- `.config/sublime-text/Packages/User` -> `~/Library/Application Support/Sublime Text/Packages/User` (macOS) or
  `~/.config/sublime-text/Packages/User` (Linux)
- `.emacs.d` -> `~/.emacs.d`
- shell/git/tmux/ripgrep files -> their normal home paths

Vim config is intentionally not included.

## Notes

- Existing targets are backed up under `~/.dotfiles-backup/<timestamp>/` before symlinking.
- Emacs' nested `.git` directory was removed from `.emacs.d` during migration.
- `~/.codex` is always a real, local Codex runtime directory. It holds auth, sessions, caches, plugins, and the
  user-owned `config.toml`; none of that runtime state is linked into or tracked by this repository.
- Setup links only durable Codex guidance (`AGENTS.md`), custom roles (`agents/`), and command rules (`rules/`) from
  Git. It does not seed, compare, or overwrite the local `~/.codex/config.toml`.
- A legacy whole-directory `~/.codex` symlink is backed up without following it and replaced with a real directory.
  Migrate runtime state from the old referent before running setup on a legacy installation; the 2026-08-14 upgrade of
  this repository performed that move in place. Existing local `AGENTS.md`, `agents/`, or `rules/` entries are backed up
  individually before the managed links are installed.
- The local Codex config uses Sol for the primary session. The lead role inherits its parent session's model and
  reasoning effort; the reviewer uses Sol/high, default and implementation work use Terra, and focused read-only
  exploration and validation use Luna/medium. Shell aliases keep `codex` on its normal approval safeguards, `c` is the
  same command, and `ca` opts into automatic approval review. Start a new Codex session after changing guidance or
  roles.
- Git identity and other machine-specific Git settings live in `~/.gitconfig.local`, which is included by the tracked
  `.gitconfig` but remains outside this repository. On first setup, the script prompts for your name and email and
  creates this file outside the repository.

## Development

The repository conventions are documented in [STYLE.md](STYLE.md). Run all checks with:

```bash
scripts/lint
```

On macOS, install the syntax-validator runtimes with Homebrew. Homebrew packages follow the current macOS bottle; the
dedicated lint tools below are installed at the exact versions used by CI:

```bash
brew install emacs git libxml2 ripgrep tmux zsh
export PATH="$(brew --prefix libxml2)/bin:$PATH"
rustup toolchain install 1.89.0 --profile minimal --no-self-update
cargo +1.89.0 install stylua --version 2.5.2 --locked
npm install --global @taplo/cli@0.7.0 deno@2.5.0 markdownlint-cli2@0.18.1 prettier@3.8.1
uv tool install ruff==0.12.10
uv tool install yamllint==1.37.1
```

Install the exact ShellCheck release separately; the checksum selection covers both macOS architectures:

```bash
shellcheck_version=v0.11.0
case "$(uname -m)" in
  arm64) shellcheck_arch=aarch64; shellcheck_sha256=56affdd8de5527894dca6dc3d7e0a99a873b0f004d7aabc30ae407d3f48b0a79 ;;
  x86_64) shellcheck_arch=x86_64; shellcheck_sha256=3c89db4edcab7cf1c27bff178882e0f6f27f7afdf54e859fa041fca10febe4c6 ;;
  *) echo "unsupported architecture" >&2; exit 1 ;;
esac
shellcheck_tmp="$(mktemp -d)"
shellcheck_archive="shellcheck-${shellcheck_version}.darwin.${shellcheck_arch}.tar.xz"
curl --fail --location --output "$shellcheck_tmp/$shellcheck_archive" \
  "https://github.com/koalaman/shellcheck/releases/download/$shellcheck_version/$shellcheck_archive"
echo "$shellcheck_sha256  $shellcheck_tmp/$shellcheck_archive" | shasum -a 256 --check
tar --extract --xz --file "$shellcheck_tmp/$shellcheck_archive" --directory "$shellcheck_tmp"
install -m 0755 "$shellcheck_tmp/shellcheck-$shellcheck_version/shellcheck" "$HOME/.local/bin/shellcheck"
```

The lint command fails with a list of missing tools instead of silently skipping a language. CI pins the runner, action
commits, language runtimes, and dedicated lint-tool versions before running the complete command.
