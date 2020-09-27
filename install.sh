#!/bin/bash

set -e

function main() {
    pip3 install -r requirements
    python3 install.py
}

main
