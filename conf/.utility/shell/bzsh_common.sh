

WORK_DIR="${HOME}/WorkSpace" 
OS=$(uname)


function linux_env {
    echo "do nothing for linux here"
}


function darwin_env {
    export CLICOLOR='true'
    export LSCOLORS="gxfxcxdxcxegedabagacad"
}


function go_env() {
    # go path for mod
    go_path="${WORK_DIR}/go"
    if [ ! -d "${go_path}" ]; then
        mkdir ${go_path}
    fi
    export GOPATH=${go_path}
    export GO111MODULE=auto

    case ${OS} in
        "Linux")
            echo "Set go path here if necessary"
            ;;
        "Darwin")
            export PATH="${PATH}:/usr/local/go/bin"
            ;;
        *)
        echo "Do not support ${OS} now"
    esac
}

function python_env() {

    local py_venv="${WORK_DIR}/pyvenv"
    local vpy27_path="${py_venv}/python2.7/bin"
    local vpy36_path="${py_venv}/python3.6/bin"
    local vpy37_path="${py_venv}/python3.7/bin"

    alias vpy27="source ${vpy27_path}/activate"
    alias vpy36="source ${vpy36_path}/activate"
    alias vpy37="source ${vpy37_path}/activate"

    export VPY27="${vpy27_path}/python"
    export VPY36="${vpy36_path}/python"
    export VPY37="${vpy37_path}/python"

    case ${OS} in
        "Linux")
            echo "Set python path here if necessary"
            ;;
        "Darwin")
            local python_framework_path="/Library/Frameworks/Python.framework/Versions" 
            export PATH="${python_framework_path}/2.7/bin:${PATH}"
            export PATH="${python_framework_path}/Versions/3.6/bin:${PATH}"
            export PATH="${python_framework_path}/Versions/3.7/bin:${PATH}"
            ;;
        *)
        echo "Do not support ${OS} now"
    esac

}

function editor_env() {
    if command -v nvim > /dev/null 2>&1 ; then
        # set nvim as default editor
        export VISUAL=nvim      
        export EDITOR="$VISUAL"
        alias vi='nvim'
        alias vim='nvim'
        alias vimdiff='nvim -d'
    else
        # set vim as default editor
        export VISUAL=vim       
        export EDITOR="$VISUAL"
        alias vi='vim'
    fi
}

function common_env() {
    # If you come from bash you might have to change your $PATH.
    export PATH=$HOME/bin:/usr/local/bin:$PATH
    export PATH
    
    # create the work space
    if [ ! -d "${WORK_DIR}" ]; then
        mkdir ${WORK_DIR}
    fi

    editor_env

    python_env

    go_env
}


function env_setting() {
    common_env
    case ${OS} in
        "Linux")
            linux_env
            ;;
        "Darwin")
            darwin_env
            ;;
        *)
        echo "Do not support ${OS} now"
    esac
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

function common_alias(){
    
    alias tree='tree -C'
}

function alias_setting() {

    common_alias

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

function screen_color_setting() 
{
    export TERM="xterm-256color"

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

function main() {
    env_setting
    alias_setting
    screen_color_setting
}


main

