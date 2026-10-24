# shellcheck shell=bash disable=SC1090
# Login bash does not read ~/.bashrc; everything lives there and in common.sh.
if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi
