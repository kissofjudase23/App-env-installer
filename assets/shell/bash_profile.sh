# shellcheck shell=bash disable=SC1090
# Docker Desktop CLI tools
if [ -d "$HOME/.docker/bin" ]; then
    export PATH="$PATH:$HOME/.docker/bin"
fi

if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi
