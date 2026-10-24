# shellcheck shell=bash disable=SC1090,SC1091
source ~/.assets/shell/common.sh

# Non-interactive shells (ssh host cmd, scp) only need the environment above
[[ $- == *i* ]] || return 0

function exitstatus {
    local exit_code="$?"

    local RCol='\e[0m'
    local Bold='\e[1m'
    local Yel='\e[0;33m'
    local IBla='\e[0;90m'
    local On_IBla='\e[0;100m'
    local BGre='\e[1;32m'
    local BRed='\e[1;31m'

    local prompt="${RCol}${On_IBla}[\d \t]${RCol} ${IBla}\u@\h${RCol}:${Yel}\w${RCol}${RCol}"

    if [ "${exit_code}" -eq 0 ]; then
        PS1="${prompt} ${BGre}:)${RCol}\n\$ "
    else
        PS1="${prompt} ${BRed}:(${RCol}\n\$ "
    fi

    PS2="${Bold}>${RCol} "
}

function common_bash_setting() {
    # don't put duplicate lines or lines starting with space in the history
    HISTCONTROL=ignoreboth
    HISTSIZE=10000
    HISTFILESIZE=20000
    shopt -s histappend checkwinsize

    # starship (assets/starship/starship.toml) matches the zsh prompt; exitstatus is the fallback
    if command -v starship > /dev/null 2>&1; then
        eval "$(starship init bash)"
    else
        PROMPT_COMMAND=exitstatus
    fi

    if command -v aws_completer > /dev/null 2>&1; then
        complete -C "$(command -v aws_completer)" aws
    fi

    if command -v zoxide > /dev/null 2>&1; then
        eval "$(zoxide init bash)"
    fi

    # needs fzf >= 0.48; older versions fail silently
    if command -v fzf > /dev/null 2>&1; then
        eval "$(fzf --bash 2> /dev/null)"
    fi
}

function darwin_bash_setting() {
    local prefix="${HOMEBREW_PREFIX:-}"
    [ -z "${prefix}" ] && return 0

    if [ -f "${prefix}/etc/bash_completion" ]; then
        source "${prefix}/etc/bash_completion"
    fi
}

function linux_bash_setting() {
    if [ -r /usr/share/bash-completion/bash_completion ]; then
        source /usr/share/bash-completion/bash_completion
    fi
}

common_bash_setting
if [ "${OS}" = "Darwin" ]; then
    darwin_bash_setting
else
    linux_bash_setting
fi
