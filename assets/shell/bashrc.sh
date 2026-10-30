# shellcheck shell=bash disable=SC1090,SC1091
source ~/.assets/shell/common.sh
unset -f alias_setting

# Non-interactive shells (ssh host cmd, scp) only need the environment above
[[ $- == *i* ]] || return 0

# Fallback prompt when starship is missing; \[ \] keeps line wrapping correct
function exitstatus {
    local code=$?
    local reset='\[\e[0m\]' grey='\[\e[0;90m\]' yellow='\[\e[0;33m\]'
    local mark='\[\e[1;32m\]:)'
    [ "${code}" -eq 0 ] || mark='\[\e[1;31m\]:('
    PS1="${grey}\u@\h${reset}:${yellow}\w${reset} ${mark}${reset}\n\$ "
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

    # after starship, which also sets PROMPT_COMMAND
    if command -v direnv > /dev/null 2>&1; then
        eval "$(direnv hook bash)"
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
case "${OSTYPE}" in
    darwin*) darwin_bash_setting ;;
    *) linux_bash_setting ;;
esac
unset -f common_bash_setting darwin_bash_setting linux_bash_setting
