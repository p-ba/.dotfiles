setopt inc_append_history
[ -t 0 ] && [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

if [ ${TERM:-} = 'xterm-256color' ]; then
    #exec tmux new -A -s home
fi

bindkey -e

[[ -o interactive ]] && [[ -t 0 ]] && stty -ixon 2>/dev/null || true

reset_connection() {
    sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder
    sudo ifconfig en0 down; sudo ifconfig en0 up
}

_nvm_lazy_load() {
    unset -f nvm node npm npx 2>/dev/null || true
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
}

nvm() {
    _nvm_lazy_load
    nvm "$@"
}

node() {
    _nvm_lazy_load
    command node "$@"
}

npm() {
    _nvm_lazy_load
    command npm "$@"
}

npx() {
    _nvm_lazy_load
    command npx "$@"
}

_pyenv_lazy_load() {
    unset -f pyenv 2>/dev/null || true
    eval "$(command pyenv init - --no-rehash zsh)"
}

pyenv() {
    _pyenv_lazy_load
    pyenv "$@"
}

fzf_tmux() {
    source ~/.local/bin/fzf_tmux
}
zle -N fzf_tmux
bindkey '^F' fzf_tmux

alias oc="opencode2 --yolo"
alias copilot="copilot --yolo"
# Use ChatGPT's bundled CLI so app updates also update terminal Codex.
if [[ -x /Applications/ChatGPT.app/Contents/Resources/codex ]]; then
    alias codex='/Applications/ChatGPT.app/Contents/Resources/codex --yolo'
else
    alias codex='codex --yolo'
fi
alias dc="docker compose"
alias de="docker exec -it"
alias tree="tree --dirsfirst"
etags() {
    ctags -R -e --exclude="*/node_modules/*" --exclude="*.min.js" --exclude="*.min.css" --exclude="*.map" "$@"
}
alias bash='/opt/homebrew/bin/bash'
alias /bin/bash='/opt/homebrew/bin/bash'
alias vim=nvim
export EDITOR=nvim
export VISUAL=nvim
alias c=codex

__docker_exec() {
    CONTAINER_ID=$(docker ps | fzf | awk '{print $1}')
    if [[ $CONTAINER_ID = '' ]]; then
        return
    fi
    docker exec -it $CONTAINER_ID /bin/bash || docker exec -it $CONTAINER_ID /bin/sh
}
alias dce="__docker_exec"

__docker_logs() {
    CONTAINER_ID=$(docker ps | fzf | awk '{print $1}')
    if [[ $CONTAINER_ID = '' ]]; then
        return
    fi
    docker logs -f $CONTAINER_ID
}
alias dcl="__docker_logs"

__docker_stop_rm() {
    CONTAINER_ID=$(docker ps | fzf | awk '{print $1}')
    if [[ $CONTAINER_ID = '' ]]; then
        return
    fi
    docker stop $CONTAINER_ID && docker rm $CONTAINER_ID
}
alias dcsr="__docker_stop_rm"

# Stop all SSH dynamic-forwarding tunnels.
sshKillAllTunnel() {
    ps -ax | grep 'ssh -D' | grep -v 'grep ' | awk -F " " '{print $1}' | xargs -t --no-run-if-empty kill
}
alias ssh_kill_all_tunnel='sshKillAllTunnel'

# bun completion: autoload on first use instead of parsing the generated file at startup
if [ -s "$HOME/.bun/_bun" ]; then
    fpath=("$HOME/.bun" $fpath)
    autoload -Uz _bun 2>/dev/null
    (( $+functions[compdef] )) && compdef _bun bun
fi
