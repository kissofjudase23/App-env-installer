#!/bin/bash
# author: Tom_Lin
# date:   2015/12/2

#include common functions
source ./script_funcs.sh


# For. bashrc
# create a symbolic link to config script.
chmod +x "e23_config.sh"
ln -s $(pwd)/e23_config.sh ~/e23_config_symbolic

LINE='source ~/e23_config_symbolic'
FILE=.bashrc
cd ~

# check .bashrc and create if necessary.
Check_File_and_Create $FILE

# add a entry porint to user-defined script in .bashrc.
# add LINE to FILE only if this LINE dose not exists.
grep -q "$LINE" "$FILE" || echo "$LINE" >> "$FILE"

# For .vimrc
# check .bashrc and delete if necessary.
FILE=.vimrc
Check_File_and_Delete $FILE

cd - 
# create a symbolic for user-defined .vimrc
ln -s $(pwd)/$FILE ~/$FILE

