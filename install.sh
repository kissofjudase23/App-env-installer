#!/bin/bash

set -e

function main() {
    pip3 install -r requirements
    python3 install.py
    # sudo sh -c "echo $(which zsh) >> /etc/shells"
    # chsh -s $(which zsh)

}

main


