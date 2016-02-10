#!/bin/bash
# Author:Tom
# Create Date:  2015/12/2
# Last Updated: 2015/1227
# This script is used to add some common setting e.g. alias, git bracnh...

# <1>. alias command
alias ll='ls -al --color'
alias grep='grep --color'

# <2>.display current git branch name in command prompt
function parse_git_branch () {
   git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}
 
RED="\[\033[0;31m\]"
YELLOW="\[\033[0;33m\]"
GREEN="\[\033[0;32m\]"
NO_COLOR="\[\033[0m\]"
PS1="$GREEN\u@\h$NO_COLOR:\w$YELLOW\$(parse_git_branch)$NO_COLOR\$ "

# <3>. go language environment
# go bin position.
go_src=/usr/local
export PATH=$PATH:${go_src}/go/bin

# <4>. set vim as default editor
export VISUAL=vim
export EDITOR="$VISUAL"

# your go project.
export GOPATH=${HOME}/e23-Git-Dev/Go_Practice
export PATH=$PATH:$GOPATH/bin




