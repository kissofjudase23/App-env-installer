#!/bin/bash


function my_realpath(){
    [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

function get_install_var(){
    #get basic system info
    OS=$(uname -s)
    ARCH=$(uname -m)
    VER=$(uname -r)

    #get absolute working directory
    SCRIPT_NAME=${0}
    SCRIPT_DIR=$(my_realpath ${0})
    WORK_DIR=$(dirname $SCRIPT_DIR)
    BK_DIR=${WORK_DIR}/conf_bk
    SRC_DIR=${WORK_DIR}/conf
}

function print_var() {
    echo "========================="
    echo "Basic Info:"
    echo "OS=${OS}"
    echo "ARCH=${VER}"
    echo "VER=${VER}"
    echo "Script_Name=${0}"
    echo "Script_Dir=${SCRIPT_DIR}"
    echo "Working_Dir=${WORK_DIR}"
    echo "Backup_Dir=${BK_DIR}"
    echo "Source_Dir=${SRC_DIR}"
    echo "========================="
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

main() {
    get_install_var
    print_var
}

main
