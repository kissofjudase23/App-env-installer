#!/bin/bash

set -Eo pipefail

function detect_os() {
    local os_type
    os_type="$(uname -s)"

    case "${os_type}" in
        Darwin)
            echo "Detected OS: macOS (Darwin)"
            export DETECTED_OS="Darwin"
            ;;
        Linux)
            if [ -f /etc/os-release ]; then
                . /etc/os-release
                if [ "${ID}" = "ubuntu" ]; then
                    echo "Detected OS: Linux (Ubuntu ${VERSION_ID})"
                    export DETECTED_OS="Linux"
                    export DETECTED_DISTRO="Ubuntu"
                else
                    echo "Error: Unsupported Linux distribution: ${ID}" >&2
                    exit 1
                fi
            else
                echo "Error: Cannot determine Linux distribution" >&2
                exit 1
            fi
            ;;
        *)
            echo "Error: Unsupported OS: ${os_type}" >&2
            exit 1
            ;;
    esac
}

function change_default_shell_to_zsh() {
    if [ "$SHELL" != "$(which zsh)" ]; then
        echo "Changing default shell to zsh..."
        chsh -s "$(which zsh)"
    fi
}

function install_pkgs_for_ubuntu() {
    echo "Installing apt packages for Ubuntu..."

    # Add PPAs from config.yaml apt_pkgs (add-repo field)
    local ppas=(
        "ppa:neovim-ppa/stable"  # neovim
    )

    for ppa in "${ppas[@]}"; do
        echo "Adding PPA: ${ppa}"
        sudo add-apt-repository -y "${ppa}"
    done

    sudo apt-get update -y

    local pkgs=(
        "silversearcher-ag"  # ag
        "autojump"
        "curl"
        "fontconfig"
        "fzf"
        "git"
        "jq"
        "tmux"
        "tree"
        "tig"
        "language-pack-en"
        "neovim"
        "zsh"

    )

    echo "Installing packages: ${pkgs[*]}"
    sudo apt-get install -y "${pkgs[@]}"

    # install uv
    curl -LsSf https://astral.sh/uv/install.sh | sh

    change_default_shell_to_zsh
}

function install_pkgs_for_darwin() {
    echo "Installing brew packages for macOS..."

    # Install Homebrew if not present
    if ! command -v brew &> /dev/null; then
        echo "Homebrew not found, installing..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    # reload shell to get the path of homebrew
    exec zsh

    # Taps needed for cask fonts
    brew tap homebrew/cask-fonts 2>/dev/null || true

    # Regular packages from config.yaml brew_pkgs (cask: false)
    local pkgs=(
        "the_silver_searcher"  # ag
        "autojump"
        "bash-completion"
        "ctop"
        "fzf"
        "git"
        "jq"
        "tmux"
        "make"
        "pyenv"
        "pyenv-virtualenv"
        "neovim"
        "tree"
        "tig"
        "zsh"
        "gron"
        "uv"
    )

    echo "Installing brew packages: ${pkgs[*]}"
    for pkg in "${pkgs[@]}"; do
        if ! brew list "${pkg}" &> /dev/null; then
            echo "Installing ${pkg}..."
            brew install "${pkg}"
        else
            echo "${pkg} already installed, skipping."
        fi
    done

    # Cask packages from config.yaml brew_pkgs (cask: true)
    local casks=(
        "font-fira-code"  # nerd-font
    )

    echo "Installing cask packages: ${casks[*]}"
    for cask in "${casks[@]}"; do
        if ! brew list --cask "${cask}" &> /dev/null; then
            echo "Installing cask ${cask}..."
            brew install --cask "${cask}"
        else
            echo "${cask} already installed, skipping."
        fi
    done

    change_default_shell_to_zsh
}

function main() {
    detect_os
    if [ "${DETECTED_OS}" = "Darwin" ]; then
        install_pkgs_for_darwin
    elif [ "${DETECTED_OS}" = "Linux" ] && [ "${DETECTED_DISTRO}" = "Ubuntu" ]; then
        install_pkgs_for_ubuntu
    fi

    # Create venv and install python dependencies
    if [ ! -d ".venv" ]; then
        uv venv
    fi
    uv pip install -r requirements
    uv run python install.py -a
}

main
