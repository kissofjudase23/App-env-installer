#!/bin/bash
# Author:Tom
# Create Date: 2015/12/02
# Last Update: 2015/12/02

#include common functions:
source ./script_funcs.sh

cd ~
file_list=("e23_config_symbolic" ".vimrc");
for filename in "${file_list[@]}"
do
    Check_Link_and_Delete $filename
done

LINE='source ~/e23_config_symbolic'
FILE=.bashrc
sed -i "/$LINE/d" $FILE

