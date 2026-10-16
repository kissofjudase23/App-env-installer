#!/bin/bash

set -Eeuo pipefail

cd "$(dirname "$0")"

function detect_os() {
    local os_type
    os_type="$(uname -s)"

    case "${os_type}" in
        Darwin)
            echo "Detected OS: macOS (Darwin)"
            DETECTED_OS="Darwin"
            ;;
        Linux)
            if [ ! -f /etc/os-release ]; then
                echo "Error: Cannot determine Linux distribution" >&2
                exit 1
            fi
            # shellcheck disable=SC1091
            . /etc/os-release
            if [ "${ID:-}" != "ubuntu" ]; then
                echo "Error: Unsupported Linux distribution: ${ID:-unknown}" >&2
                exit 1
            fi
            echo "Detected OS: Linux (Ubuntu ${VERSION_ID:-})"
            DETECTED_OS="Linux"
            ;;
        *)
            echo "Error: Unsupported OS: ${os_type}" >&2
            exit 1
            ;;
    esac
}

function change_default_shell_to_zsh() {
    local zsh_path
    zsh_path="$(command -v zsh)"

    if ! grep -qxF "${zsh_path}" /etc/shells; then
        echo "Adding ${zsh_path} to /etc/shells..."
        echo "${zsh_path}" | sudo tee -a /etc/shells > /dev/null
    fi

    if [ "${SHELL:-}" != "${zsh_path}" ]; then
        echo "Changing default shell to ${zsh_path}..."
        chsh -s "${zsh_path}"
    fi
}

function install_pkgs_for_ubuntu() {
    echo "Installing apt packages for Ubuntu..."

    sudo apt-get update -y
    sudo apt-get install -y software-properties-common
    sudo add-apt-repository -y ppa:neovim-ppa/stable
    sudo apt-get update -y

    sed -e 's/#.*//' apt-packages.txt | xargs sudo apt-get install -y

    if ! command -v uv &> /dev/null; then
        curl -LsSf https://astral.sh/uv/install.sh | sh
    fi
    if [ -f "${HOME}/.local/bin/env" ]; then
        # shellcheck disable=SC1091
        . "${HOME}/.local/bin/env"
    fi
}

function load_brew_env() {
    local brew_bin
    for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew; do
        if [ -x "${brew_bin}" ]; then
            eval "$("${brew_bin}" shellenv)"
            return
        fi
    done
}

function install_pkgs_for_darwin() {
    if ! command -v brew &> /dev/null; then
        echo "Homebrew not found, installing..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        load_brew_env
    fi

    brew bundle --file=Brewfile
}

function setup_python() {
    # No argument: uv reads the version from .python-version
    uv python install
    uv sync
    uv run install.py -a -y
}

function main() {
    detect_os

    case "${DETECTED_OS}" in
        Darwin) install_pkgs_for_darwin ;;
        Linux) install_pkgs_for_ubuntu ;;
    esac

    setup_python
    change_default_shell_to_zsh
}

main "$@"
