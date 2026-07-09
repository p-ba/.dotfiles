PROFILE_LOADED=1
export HOMEBREW_PREFIX="/opt/homebrew"
export HOMEBREW_CELLAR="$HOMEBREW_PREFIX/Cellar"
export HOMEBREW_REPOSITORY="$HOMEBREW_PREFIX"
export PATH="$HOMEBREW_PREFIX/bin:$HOMEBREW_PREFIX/sbin:$PATH"
export INFOPATH="$HOMEBREW_PREFIX/share/info:${INFOPATH:-}"
export EDITOR=vim
export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"

export PATH="$PATH:$HOME/.local/bin"
export PATH="$PATH:$HOME/.composer/vendor/bin"
export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"
export PATH="$HOME/.local/nvim/bin:$PATH"
export PATH="$HOME/.local/vim/bin:$PATH"

if [ -r "$HOME/.phpbrew/bashrc" ]; then
    . "$HOME/.phpbrew/bashrc"
fi

# Added by Toolbox App
export PATH="$PATH:$HOME/Library/Application Support/JetBrains/Toolbox/scripts"

# NVM: load on first use (sourcing nvm.sh adds ~1s+ to every shell)
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
if [ -d "$NVM_DIR/versions/node" ]; then
    NVM_DEFAULT_VERSION=$(ls -1 "$NVM_DIR/versions/node" | sort -V | tail -n 1)
    if [ -n "$NVM_DEFAULT_VERSION" ]; then
        export PATH="$NVM_DIR/versions/node/$NVM_DEFAULT_VERSION/bin:$PATH"
    fi
    unset NVM_DEFAULT_VERSION
fi

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
# bun end

export PATH="/Applications/Sublime Text.app/Contents/SharedSupport/bin:$PATH"

export PATH="$HOME/go/bin:$PATH"

export PYENV_ROOT="$HOME/.pyenv"
if [ -d "$PYENV_ROOT/bin" ]; then
    export PATH="$PYENV_ROOT/bin:$PATH"
fi
if [ -d "$PYENV_ROOT/shims" ]; then
    export PATH="$PYENV_ROOT/shims:$PATH"
fi

if [ -r "$HOME/.cargo/env" ]; then
    . "$HOME/.cargo/env"
fi
