

WORK_DIR="${HOME}/WorkSpace"
OS=$(uname -s)
ARCH=$(uname -m)
VER=$(uname -r)
# DISTRIBUTION=$(grep DISTRIB_ID /etc/*-release | awk -F '=' '{print $2}')


function check_folder_and_create(){
    local check_folder=$1
    # echo ${check_folder}
    if [[ ! -d "${check_folder}" ]];then
        mkdir -p ${check_folder}
    fi
}


function print_os_info() {
    get_os_info
    echo "========================="
    echo "OS Info:"
    echo "OS=${OS}"
    echo "ARCH=${VER}"
    echo "VER=${VER}"
    echo "DISTRIBUTION=${DISTRIBUTION}"
    echo "========================="
}


function linux_env {
    export LANG=C.UTF-8
    export LC_ALL=C.UTF-8
}


function darwin_env {
    export LANG=en_US.UTF-8
    export LC_ALL=en_US.UTF-8
    export CLICOLOR='true'
    export LSCOLORS="gxfxcxdxcxegedabagacad"

    # stop ruuing brew update every time
    export HOMEBREW_NO_AUTO_UPDATE=1

}


function go_env() {
    # note:
    # gvm will redeine the go env
    # https://github.com/moovweb/gvm
    if [[ -s ~/.gvm/scripts/gvm ]]; then
        source ~/.gvm/scripts/gvm
        gvm use go1.19.10
        alias vgo19="gvm use go1.19.10"
        alias vgo20="gvm use go1.20.5"
    fi

    export PATH="${PATH}:${HOME}/go/bin"
}

function python_env() {

    # pyenv
    export PYENV_ROOT="${HOME}/.pyenv"

    if [ -d "${PYENV_ROOT}" ]; then
        export PATH="${PYENV_ROOT}/bin:${PATH}"
        eval "$(pyenv init --path)"
        eval "$(pyenv init -)"
        eval "$(pyenv virtualenv-init -)"
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
        *)
        echo "Do not support ${OS} now"
    esac

    # pipenv
    export PIPENV_VENV_IN_PROJECT='true'


}

function editor_env() {
    if command -v nvim > /dev/null 2>&1 ; then
        # set nvim as default editor
        export VISUAL='nvim'
        export EDITOR="$VISUAL"
        export GIT_EDITOR='nvim'
        alias vi='nvim'
        alias vim='nvim'
        alias vimdiff='nvim -d'
    else
        # set vim as default editor
        export VISUAL='vim'
        export EDITOR="$VISUAL"
        export GIT_EDITOR='vim'
        alias vi='vim'
    fi
}

function mysql_env() {
    case ${OS} in
        "Linux")
            ;;
        "Darwin")
            local mysql_path='/usr/local/opt/mysql-client/bin/'
            export PATH=${mysql_path}:${PATH}
            ;;
        *)
        echo "Do not support ${OS} now"
    esac
}

function k8s_env() {
    export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
}


function common_env() {
    # If you come from bash you might have to change your $PATH.
    export PATH=$HOME/bin:/usr/local/bin:/usr/local/opt/:${PATH}

    # create the work space
    check_folder_and_create ${WORK_DIR}

    editor_env

    python_env

    go_env

    mysql_env

    k8s_env

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
