[ -f ~/.fzf.bash ] && source ~/.fzf.bash

case $- in
    *i*) [ -t 0 ] && stty -ixon 2>/dev/null || true ;;
esac

alias vim='nvim'

. "$HOME/.cargo/env"
