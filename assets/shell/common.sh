# shellcheck shell=bash disable=SC1090,SC1091
# Shared environment for bash and zsh; must not print anything (p10k instant prompt).

OS=$(uname -s)

# Untracked machine-specific overrides, e.g. USE_CORP_PROXY=1 and CORP_PROXY_URL
if [[ -f "$HOME/.shell_local" ]]; then
    source "$HOME/.shell_local"
fi

function linux_env() {
    export LANG=C.UTF-8
    export LC_ALL=C.UTF-8
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
        export PATH="/usr/local/go/bin:${PATH}"
    fi

    export PATH="${PATH}:${GOBIN:-${GOPATH:-${HOME}/go}/bin}"
}

function python_env() {
    export PYENV_ROOT="${HOME}/.pyenv"
    if [[ -d "${PYENV_ROOT}/bin" ]]; then
        export PATH="${PYENV_ROOT}/bin:${PATH}"
    fi

    if command -v pyenv > /dev/null 2>&1; then
        eval "$(pyenv init -)"
        if command -v pyenv-virtualenv-init > /dev/null 2>&1; then
            eval "$(pyenv virtualenv-init -)"
        fi
        export PYENV_VIRTUALENV_DISABLE_PROMPT=1
    fi

    case ${OS} in
        "Linux")
            export PYTHON_CONFIGURE_OPTS="--enable-shared"
            export REQUESTS_CA_BUNDLE="/etc/ssl/certs/ca-certificates.crt"
            ;;
        "Darwin")
            export PYTHON_CONFIGURE_OPTS="--enable-framework"
            ;;
    esac

    export PIPENV_VENV_IN_PROJECT='true'
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

function mysql_env() {
    local mysql_bin="${HOMEBREW_PREFIX:-}/opt/mysql-client/bin"
    if [[ -n "${HOMEBREW_PREFIX:-}" && -d "${mysql_bin}" ]]; then
        export PATH="${mysql_bin}:${PATH}"
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
    export PATH="$HOME/bin:${PATH}"

    brew_env
    editor_env
    python_env
    go_env
    mysql_env
    uv_env

    case ${OS} in
        "Linux") linux_env ;;
        "Darwin") darwin_env ;;
    esac
}

function alias_setting() {
    alias tree='tree -C'

    case ${OS} in
        "Linux")
            alias grep='grep --color=auto'
            alias fgrep='fgrep --color=auto'
            alias egrep='egrep --color=auto'
            alias ls='ls --color=auto'
            alias ll='ls -alF --color=auto'
            alias la='ls -A --color=auto'
            alias l='ls -CF --color=auto'
            ;;
        "Darwin")
            alias ll='ls -alF'
            alias la='ls -A'
            alias l='ls -CF'
            ;;
    esac
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
