# shellcheck shell=bash disable=SC1090,SC1091
source ~/.assets/shell/common.sh
source ~/.assets/git/git-prompt.sh
source ~/.assets/git/git-completion.bash

function exitstatus {
    local exit_code="$?"

    local RCol='\e[0m'
    local Bold='\e[1m'
    local Yel='\e[0;33m'
    local Pur='\e[0;35m'
    local IBla='\e[0;90m'
    local On_IBla='\e[0;100m'
    local BGre='\e[1;32m'
    local BRed='\e[1;31m'

    local prompt="${RCol}${On_IBla}[\d \t]${RCol} ${IBla}\u@\h${RCol}:${Yel}\w${RCol}${Pur}\$(__git_ps1)${RCol}"

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
    PROMPT_COMMAND=exitstatus

    if command -v aws_completer > /dev/null 2>&1; then
        complete -C "$(command -v aws_completer)" aws
    fi
}

function linux_bash_setting() {
    local f
    for f in /etc/profile.d/autojump.bash /usr/share/autojump/autojump.bash; do
        if [ -f "${f}" ]; then
            source "${f}"
            break
        fi
    done
}

function darwin_bash_setting() {
    local prefix="${HOMEBREW_PREFIX:-}"
    [ -z "${prefix}" ] && return 0

    if [ -f "${prefix}/etc/bash_completion" ]; then
        source "${prefix}/etc/bash_completion"
    fi

    if [ -f "${prefix}/etc/profile.d/autojump.sh" ]; then
        source "${prefix}/etc/profile.d/autojump.sh"
    fi
}

common_bash_setting
case ${OS} in
    "Linux") linux_bash_setting ;;
    "Darwin") darwin_bash_setting ;;
esac

if [ -f ~/.fzf.bash ]; then
    source ~/.fzf.bash
fi
