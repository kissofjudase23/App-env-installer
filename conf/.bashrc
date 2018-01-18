source ~/.utility/git-prompt.sh
source ~/.utility/git-completion.bash

function exitstatus {
    EXITSTATUS="$?"

    # Colors
    RCol='\e[0m'    # Text Reset

    # Regular           Bold                Underline           High Intensity      BoldHigh Intens     Background          High Intensity Backgrounds
    Bla='\e[0;30m';     BBla='\e[1;30m';    UBla='\e[4;30m';    IBla='\e[0;90m';    BIBla='\e[1;90m';   On_Bla='\e[40m';    On_IBla='\e[0;100m';
    Red='\e[0;31m';     BRed='\e[1;31m';    URed='\e[4;31m';    IRed='\e[0;91m';    BIRed='\e[1;91m';   On_Red='\e[41m';    On_IRed='\e[0;101m';
    Gre='\e[0;32m';     BGre='\e[1;32m';    UGre='\e[4;32m';    IGre='\e[0;92m';    BIGre='\e[1;92m';   On_Gre='\e[42m';    On_IGre='\e[0;102m';
    Yel='\e[0;33m';     BYel='\e[1;33m';    UYel='\e[4;33m';    IYel='\e[0;93m';    BIYel='\e[1;93m';   On_Yel='\e[43m';    On_IYel='\e[0;103m';
    Blu='\e[0;34m';     BBlu='\e[1;34m';    UBlu='\e[4;34m';    IBlu='\e[0;94m';    BIBlu='\e[1;94m';   On_Blu='\e[44m';    On_IBlu='\e[0;104m';
    Pur='\e[0;35m';     BPur='\e[1;35m';    UPur='\e[4;35m';    IPur='\e[0;95m';    BIPur='\e[1;95m';   On_Pur='\e[45m';    On_IPur='\e[0;105m';
    Cya='\e[0;36m';     BCya='\e[1;36m';    UCya='\e[4;36m';    ICya='\e[0;96m';    BICya='\e[1;96m';   On_Cya='\e[46m';    On_ICya='\e[0;106m';
    Whi='\e[0;37m';     BWhi='\e[1;37m';    UWhi='\e[4;37m';    IWhi='\e[0;97m';    BIWhi='\e[1;97m';   On_Whi='\e[47m';    On_IWhi='\e[0;107m';

    PROMPT="${RCol}${On_IBla}[\d \t]${RCol} ${IBla}\u@\h${RCol}:${Yel}\w${RCol}${Pur}\$(__git_ps1)${RCol}"

    if [ "${EXITSTATUS}" -eq 0 ]; then
        PS1="${PROMPT} ${BGre}:)${RCol}\n\$ "
    else
        PS1="${PROMPT} ${BRed}:(${RCol}\n\$ "
    fi

    PS2="${BOLD}>${RCol} "
}

function common_env_setting() {
    # don't put duplicate lines or lines starting with space in the history.
    # See bash(1) for more options
    HISTCONTROL=ignoreboth
    PROMPT_COMMAND=exitstatus

    if command -v nvim > /dev/null 2>&1 ; then
        export VISUAL=nvim       # set nvim as default editor
        export EDITOR="$VISUAL"
    else
        export VISUAL=vim       # set vim as default editor
        export EDITOR="$VISUAL"
    fi

    if command -v nvim > /dev/null 2>&1 ; then
        local aws_completer_path=$(command -v aws_completer)
        complete -C ${aws_completer_path} aws
    fi
}


function linux_env_setting() {
    echo "do nothing for linux here"
}

function darwin_env_setting() {
    export CLICOLOR='true'
    export LSCOLORS="gxfxcxdxcxegedabagacad"

    # Setting PATH for Python 2.7
    # The original version is saved in .bash_profile.pysave
    PATH="/Library/Frameworks/Python.framework/Versions/2.7/bin:${PATH}"
    export PATH

    # Setting PATH for Python 3.6
    # The original version is saved in .bash_profile.pysave
    PATH="/Library/Frameworks/Python.framework/Versions/3.6/bin:${PATH}"
    export PATH
}

function envir_var_setting() {
    common_env_setting

    OS=$(uname)
    case ${OS} in
        "Linux")
            linux_env_setting
            ;;
        "Darwin")
            darwin_env_setting
            ;;
        *)
        echo "Do not support ${OS} now"
    esac

}

function go_env_setting(){
    go_src=/usr/local
    export PATH=$PATH:${go_src}/go/bin
    # your go project.
    #export GOPATH=${HOME}/e23-Git-Dev/Go_Practice
    #export PATH=$PATH:$GOPATH/bin
}

function common_alias(){
    alias tree='tree -C'

    if command -v nvim > /dev/null 2>&1 ; then
        alias vi='nvim'
        alias vim='nvim'
        alias vimdiff='nvim -d'
    else
        alias vi='vim'
    fi
}

function linux_alias() {
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
    alias ls='ls --colo=auto'
    alias ll='ls -alF --color=auto'
    alias la='ls -A --color=auto'
    alias l='ls -CF --color=auto'
}

function darwin_alias() {
    alias grep='grep'
    alias fgrep='fgrep'
    alias egrep='egrep'
    alias ls='ls'
    alias ll='ls -alF'
    alias la='ls -A'
    alias l='ls -CF'
}

function color_tuning() {
    case "$TERM" in
    *-256color)
        alias ssh='TERM=${TERM%-256color} ssh'
        ;;
    *)
        POTENTIAL_TERM=${TERM}-256color
        POTENTIAL_TERMINFO=${TERM:0:1}/$POTENTIAL_TERM

        # better to check $(toe -a | awk '{print $1}') maybe?
        BOX_TERMINFO_DIR=/usr/share/terminfo
        [[ -f $BOX_TERMINFO_DIR/$POTENTIAL_TERMINFO ]] && \
            export TERM=$POTENTIAL_TERM

        HOME_TERMINFO_DIR=$HOME/.terminfo
        [[ -f $HOME_TERMINFO_DIR/$POTENTIAL_TERMINFO ]] && \
            export TERM=$POTENTIAL_TERM
        ;;
    esac
}

function alias_setting() {
    common_alias
    OS=$(uname)
    case ${OS} in
        "Linux")
            linux_alias
            ;;
        "Darwin")
            darwin_alias
            ;;
        *)
        echo "Do not support ${OS} now"
    esac 
}

function main() {
    envir_var_setting
    color_tuning
    alias_setting
}

main


