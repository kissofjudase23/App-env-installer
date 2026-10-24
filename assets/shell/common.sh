# shellcheck shell=bash disable=SC1090,SC1091
# Shared environment for bash and zsh; must not print anything (breaks scp and the prompt).

# Untracked machine-specific overrides, e.g. USE_CORP_PROXY=1 and CORP_PROXY_URL
if [[ -f "$HOME/.shell_local" ]]; then
    source "$HOME/.shell_local"
fi

function path_prepend() {
    case ":${PATH}:" in
        *":$1:"*) ;;
        *) export PATH="$1:${PATH}" ;;
    esac
}

function path_append() {
    case ":${PATH}:" in
        *":$1:"*) ;;
        *) export PATH="${PATH}:$1" ;;
    esac
}

function linux_env() {
    # C.UTF-8 is always available; en_US.UTF-8 needs a generated locale
    export LANG=C.UTF-8
    export LC_ALL=C.UTF-8
    export REQUESTS_CA_BUNDLE="/etc/ssl/certs/ca-certificates.crt"
}

function darwin_env() {
    export LANG=en_US.UTF-8
    export LC_ALL=en_US.UTF-8
    export CLICOLOR='true'
    export LSCOLORS="gxfxcxdxcxegedabagacad"

    # stop running brew update every time
    export HOMEBREW_NO_AUTO_UPDATE=1
}

function brew_env() {
    [[ -n "${HOMEBREW_PREFIX:-}" ]] && return 0

    local brew_bin
    for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
        if [[ -x "${brew_bin}" ]]; then
            eval "$("${brew_bin}" shellenv)"
            return 0
        fi
    done
}

function uv_env() {
    if [[ -f "$HOME/.local/bin/env" ]]; then
        source "$HOME/.local/bin/env"
    fi
}

function go_env() {
    # Bootstrap go only; GOTOOLCHAIN=auto (default) switches per go.mod go/toolchain lines
    if [[ -d /usr/local/go/bin ]]; then
        path_prepend /usr/local/go/bin
    fi

    path_append "${GOBIN:-${GOPATH:-${HOME}/go}/bin}"
}

function docker_env() {
    # Docker Desktop CLI tools
    if [[ -d "$HOME/.docker/bin" ]]; then
        path_append "$HOME/.docker/bin"
    fi
}

function editor_env() {
    if command -v nvim > /dev/null 2>&1; then
        export VISUAL='nvim'
        export EDITOR="$VISUAL"
        export GIT_EDITOR='nvim'
        alias vi='nvim'
        alias vim='nvim'
        alias vimdiff='nvim -d'
    else
        export VISUAL='vim'
        export EDITOR="$VISUAL"
        export GIT_EDITOR='vim'
        alias vi='vim'
    fi
}

function cli_tools_env() {
    if command -v fd > /dev/null 2>&1; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
        export FZF_CTRL_T_COMMAND="${FZF_DEFAULT_COMMAND}"
        export FZF_ALT_C_COMMAND='fd --type d --hidden --exclude .git'
    fi

    if command -v bat > /dev/null 2>&1; then
        export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:300 {}'"
        export MANPAGER="sh -c 'col -bx | bat -l man -p'"
        # groff on Linux emits SGR escapes that col cannot strip; -c restores overstrike
        export MANROFFOPT='-c'
    fi

    # Set here rather than core.pager so git still works where delta is missing
    if command -v delta > /dev/null 2>&1; then
        export GIT_PAGER='delta'
    fi
}

function network_setting() {
    if [[ "${USE_CORP_PROXY:-0}" != "1" || -z "${CORP_PROXY_URL:-}" ]]; then
        return 0
    fi

    export HTTPS_PROXY="${CORP_PROXY_URL}"
    export HTTP_PROXY="${CORP_PROXY_URL}"
    export no_proxy="127.0.0.1,localhost"
}

function env_setting() {
    path_prepend "$HOME/bin"

    brew_env
    editor_env
    go_env
    docker_env
    uv_env
    cli_tools_env

    case "${OSTYPE}" in
        linux*) linux_env ;;
        darwin*) darwin_env ;;
    esac
}

function alias_setting() {
    alias tree='tree -C'

    case "${OSTYPE}" in
        linux*)
            alias grep='grep --color=auto'
            alias fgrep='fgrep --color=auto'
            alias egrep='egrep --color=auto'
            alias ls='ls --color=auto'
            alias ll='ls -alF --color=auto'
            alias la='ls -A --color=auto'
            alias l='ls -CF --color=auto'
            ;;
        darwin*)
            alias ll='ls -alF'
            alias la='ls -A'
            alias l='ls -CF'
            ;;
    esac

    # eza flags differ from ls (e.g. -t needs a field); use `command ls` for the original
    if command -v eza > /dev/null 2>&1; then
        alias ls='eza --group-directories-first'
        alias l='eza -F --group-directories-first'
        alias la='eza -a --group-directories-first'
        alias ll='eza -al --git --group-directories-first'
        alias lt='eza --tree --level=2 --group-directories-first'
        alias lta='eza -a --tree --level=2 --ignore-glob=.git --group-directories-first'
        alias lm='eza -al --git --sort=modified'
        alias lS='eza -al --sort=size'
        alias ld='eza -lD'
    fi

    # interactive only; bat prints plain text when piped, `command cat` for the original
    if command -v bat > /dev/null 2>&1; then
        alias cat='bat --paging=never'
    fi

    # zoxide's z is defined later by zoxide init / the oh-my-zsh plugin
    if command -v zoxide > /dev/null 2>&1; then
        alias j='z'
        alias ji='zi'
    fi
}

function term_setting() {
    case "${TERM:-}" in
        *-256color) ;;
        *)
            local candidate="${TERM:-xterm}-256color"
            local terminfo="${candidate:0:1}/${candidate}"
            if [[ -f "/usr/share/terminfo/${terminfo}" || -f "$HOME/.terminfo/${terminfo}" ]]; then
                export TERM="${candidate}"
            fi
            ;;
    esac

    # remote hosts may lack tmux/screen terminfo entries
    alias ssh='TERM=xterm-256color ssh'
}

env_setting
alias_setting
term_setting
network_setting
