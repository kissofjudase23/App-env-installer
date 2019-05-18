#!/bin/bash

function my_realpath(){
    [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

function get_os_info(){
    # get basic system info
    OS=$(uname -s)
    ARCH=$(uname -m)
    VER=$(uname -r)
    DISTRIBUTION=$(grep DISTRIB_ID /etc/*-release | awk -F '=' '{print $2}')
}

function print_os_info() {
    echo "========================="
    echo "OS Info:"
    echo "OS=${OS}"
    echo "ARCH=${VER}"
    echo "VER=${VER}"
    echo "========================="
}

function set_install_info() {
    SCRIPT_NAME=${0}
    SCRIPT_DIR=$(my_realpath ${0})
    WORK_DIR=$(dirname $SCRIPT_DIR)
    BK_DIR=${WORK_DIR}/conf_bk
    SRC_DIR=${WORK_DIR}/conf
    UTILITY_DIR=${SRC_DIR}/.utility

    DOT_FILE_LIST=( ".bashrc"\
                    ".vimrc"\
                    ".gitconfig"\
                    ".screenrc"\
                    ".tmux.conf"\
                    ".gdbinit"\
                    ".bash_profile"\
                    ".utility"
                    ".zshrc"
                  )

}

function print_install_info() {
    echo "========================="
    echo "Install info"
    echo "Script_Name=${0}"
    echo "Script_Dir=${SCRIPT_DIR}"
    echo "Working_Dir=${WORK_DIR}"
    echo "Backup_Dir=${BK_DIR}"
    echo "Source_Dir=${SRC_DIR}"
    echo "========================"
}

function check_file_and_create(){
    checkFile=$1
    echo $checkFile
    if [[ ! -f "$checkFile" ]];then
        touch "$checkFile"
    fi
    chmod +x "$checkFile"
}

function check_link_and_create(){
    checkFile=$1
    echo $checkFile
    if [[ ! -L "$checkFile" ]];then
        touch "$checkFile"
    fi
    chmod +x "$checkFile"
}

function check_file_and_remove(){
    checkFile=$1
    echo $checkFile
    if [[ -f "$checkFile" ]];then
        rm -rf  "$checkFile"
    fi
}

function check_Link_and_remove(){
    checkFile=$1
    echo $checkFile
    if [[ -L "$checkFile" ]];then
        rm -rf  "$checkFile"
    fi
}

function check_and_yum_install(){
    local cmd=${1}
    local package_name=${2}
    if ! command -v ${cmd} > /dev/null 2>&1 ; then
        echo "install ${package_name} for ${cmd}"
        sudo yum install ${package_name}
    else
        echo "${package_name} for ${cmd} has been installed"
    fi
}

function check_and_apt_install(){
    local cmd=${1}
    local package_name=${2}
    if ! command -v ${cmd} > /dev/null 2>&1 ; then
        echo "install ${package_name} for ${cmd}"
        sudo apt-get install ${package_name}
    else
        echo "${package_name} for ${cmd} has been installed"
    fi

}

function check_and_brew_install(){
    local cmd=${1}
    local package_name=${2}
    if ! command -v ${cmd} > /dev/null 2>&1 ; then
        echo "install ${package_name} for ${cmd}"
        brew install ${package_name}
    else
        echo "${package_name} for ${cmd} has been installed"
    fi
}
