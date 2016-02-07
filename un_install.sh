#!/bin/bash
# Author:Tom
# Create Date: 2015/12/02
# Last Update: 2015/12/02

function Check_File_and_Create(){
    checkFile=$1
    echo $checkFile
    if [[ ! -f "$checkFile" ]];then
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

cd ~
file_list=("e23_config_symbolic" ".vimrc");
for filename in "${file_list[@]}"
do
    Check_File_and_Delete $filename
done

LINE='source ~/e23_config_symbolic'
FILE=.bashrc

sed -i "/$LINE/d" $FILE

