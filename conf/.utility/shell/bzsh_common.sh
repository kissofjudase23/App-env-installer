
function common_env_setting() {

    if command -v nvim > /dev/null 2>&1 ; then
        export VISUAL=nvim       # set nvim as default editor
        export EDITOR="$VISUAL"
    else
        export VISUAL=vim       # set vim as default editor
        export EDITOR="$VISUAL"
    fi

    # create the work space
    work_dir="${HOME}/WorkSpace"
    if [ ! -d "${work_dir}" ]; then
        mkdir ${work_dir}
    fi

    # go path for mod
    go_path="${work_dir}/go"
    if [ ! -d "${go_path}" ]; then
        mkdir ${go_path}
    fi

    export GOPATH=${go_path}
    export GO111MODULE=auto

}


function linux_env_setting() {
    echo "do nothing for linux here"
}

function darwin_env_setting() {
    export CLICOLOR='true'
    export LSCOLORS="gxfxcxdxcxegedabagacad"

    # golang path
    export PATH="${PATH}:/usr/local/go/bin"

    export PATH="/Library/Frameworks/Python.framework/Versions/2.7/bin:${PATH}"

    export PATH="/Library/Frameworks/Python.framework/Versions/3.6/bin:${PATH}"

    export PATH="/Library/Frameworks/Python.framework/Versions/3.7/bin:${PATH}"
}

function envir_setting() {

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

function common_alias(){
    alias tree='tree -C'

    local vpy27_path="${HOME}/WorkSpace/virtualenv/python2.7/bin"
    local vpy36_path="${HOME}/WorkSpace/venv/python3.6/bin"
    local vpy37_path="${HOME}/WorkSpace/venv/python3.7/bin"

    alias vpy27="source ${vpy27_path}/activate"
    alias vpy36="source ${vpy36_path}/activate"
    alias vpy37="source ${vpy37_path}/activate"

    export VPY27="${vpy27_path}/python"
    export VPY36="${vpy36_path}/python"
    export VPY37="${vpy37_path}/python"

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

function screen_color_setting() {
    case "$TERM" in
    *-256color)
        alias ssh='TERM=${TERM%-256color} ssh'
        ;;
    *)
        POTENTIAL_TERM=${TERM}-256color
        gOTENTIAL_TERMINFO=${TERM:0:1}/$POTENTIAL_TERM

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
    envir_setting
    screen_color_setting
    alias_setting
}

main

