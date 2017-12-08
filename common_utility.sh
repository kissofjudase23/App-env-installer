#!/bin/bash

function my_realpath(){
    [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
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

function get_os_var(){
    # get basic system info
    OS=$(uname -s)
    ARCH=$(uname -m)
    VER=$(uname -r)
    DISTRIBUTION=$(grep DISTRIB_ID /etc/*-release | awk -F '=' '{print $2}')
}

function print_os_var() {
    echo "========================="
    echo "OS Info:"
    echo "OS=${OS}"
    echo "ARCH=${VER}"
    echo "VER=${VER}"
    echo "========================="
}



