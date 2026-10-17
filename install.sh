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

GO_MIN_VERSION="1.21"
GO_ROOT="/usr/local/go"

function go_is_recent_enough() {
    local current
    command -v go &> /dev/null || return 1
    current="$(go env GOVERSION)"
    current="${current#go}"
    [ "$(printf '%s\n%s\n' "${GO_MIN_VERSION}" "${current}" | sort -V | head -n1)" = "${GO_MIN_VERSION}" ]
}

function install_go_for_ubuntu() {
    # Bootstrap go only; later versions are fetched by the go command via GOTOOLCHAIN
    export PATH="${GO_ROOT}/bin:${PATH}"
    if go_is_recent_enough; then
        echo "Go $(go env GOVERSION) found, skip bootstrap"
        return
    fi

    local arch version tarball sha256 tmp_dir
    case "$(uname -m)" in
        x86_64) arch="amd64" ;;
        aarch64 | arm64) arch="arm64" ;;
        *)
            echo "Error: Unsupported architecture for Go: $(uname -m)" >&2
            exit 1
            ;;
    esac

    version="$(curl -fsSL 'https://go.dev/VERSION?m=text' | head -n1)"
    tarball="${version}.linux-${arch}.tar.gz"
    sha256="$(curl -fsSL 'https://go.dev/dl/?mode=json' |
        jq -r --arg f "${tarball}" '.[].files[] | select(.filename == $f) | .sha256')"
    if [ -z "${sha256}" ]; then
        echo "Error: Cannot find checksum for ${tarball}" >&2
        exit 1
    fi

    echo "Installing ${version} to ${GO_ROOT}..."
    tmp_dir="$(mktemp -d)"
    curl -fsSL -o "${tmp_dir}/${tarball}" "https://go.dev/dl/${tarball}"
    echo "${sha256}  ${tmp_dir}/${tarball}" | sha256sum -c -
    sudo rm -rf "${GO_ROOT}"
    sudo tar -C "$(dirname "${GO_ROOT}")" -xzf "${tmp_dir}/${tarball}"
    rm -rf "${tmp_dir}"
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
        Linux)
            install_pkgs_for_ubuntu
            install_go_for_ubuntu
            ;;
    esac

    setup_python
    change_default_shell_to_zsh
}

main "$@"
