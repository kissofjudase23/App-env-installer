#!/bin/bash
source ./common_utility.sh

function get_os_var(){
    #get basic system info
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
