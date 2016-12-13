#!/bin/bash

function my_realpath(){
    [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

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

#dot files list
DOT_FILE_LIST=( ".bashrc"\
            ".vimrc"\
            ".gitconfig"\
            ".git-prompt.sh"\
            ".screenrc"\
            ".gdbinit"\
            ".bash_profile")

print_var() {
    echo "OS=${OS}"
    echo "ARCH=${VER}"
    echo "VER=${VER}"
    echo "Script_Name=${0}"
    echo "Script_Dir=${SCRIPT_DIR}"
    echo "Working_Dir=${WORK_DIR}"
    echo "Backup_Dir=${BK_DIR}"
    echo "Source_Dir=${SRC_DIR}"
}



function Check_File_and_Create(){
    checkFile=$1
    echo $checkFile
    if [[ ! -f "$checkFile" ]];then
        touch "$checkFile"
    fi
    chmod +x "$checkFile"
}

function Check_Link_and_Create(){
    checkFile=$1
    echo $checkFile
    if [[ ! -L "$checkFile" ]];then
        touch "$checkFile"
    fi
    chmod +x "$checkFile"
}

function Check_File_and_Delete(){
    checkFile=$1
    echo $checkFile
    if [[ -f "$checkFile" ]];then
        rm -rf  "$checkFile"
    fi
}

function Check_Link_and_Delete(){
    checkFile=$1
    echo $checkFile
    if [[ -L "$checkFile" ]];then
        rm -rf  "$checkFile"
    fi
}

main() {
    print_var
}

main
