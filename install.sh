#!/bin/bash

set -Eeuo pipefail

function on_error() {
    echo "Error: '${BASH_COMMAND}' failed with exit code $1 (install.sh line $2)" >&2
}
trap 'on_error $? ${LINENO}' ERR

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

function add_gh_apt_repo() {
    # Ubuntu's own gh lags far behind; the official repo keeps it current through apt
    local keyring="/etc/apt/keyrings/githubcli-archive-keyring.gpg"
    if [ ! -f "${keyring}" ]; then
        sudo mkdir -p -m 755 /etc/apt/keyrings
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg |
            sudo tee "${keyring}" > /dev/null
        sudo chmod go+r "${keyring}"
    fi
    echo "deb [arch=$(dpkg --print-architecture) signed-by=${keyring}] https://cli.github.com/packages stable main" |
        sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
}

function link_debian_renamed_tools() {
    # Debian renames fd and bat to avoid clashes; expose the upstream names
    local pair src dst
    for pair in fdfind:fd batcat:bat; do
        src="${pair%%:*}"
        dst="${pair##*:}"
        if command -v "${src}" &> /dev/null && ! command -v "${dst}" &> /dev/null; then
            sudo ln -sf "$(command -v "${src}")" "/usr/local/bin/${dst}"
        fi
    done
}

function install_pkgs_for_ubuntu() {
    echo "Installing apt packages for Ubuntu..."

    add_gh_apt_repo
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
FZF_MIN_VERSION="0.48"
NVIM_MIN_VERSION="0.11"
NVIM_ROOT="/opt/nvim"

# Succeeds when version $2 >= $1
function version_at_least() {
    [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -n1)" = "$1" ]
}

# $1: arch naming used by the release assets: go (amd64), rust (x86_64/aarch64), nvim (x86_64/arm64)
function ubuntu_arch() {
    case "$1:$(uname -m)" in
        go:x86_64) echo "amd64" ;;
        go:aarch64 | go:arm64 | nvim:aarch64 | nvim:arm64) echo "arm64" ;;
        rust:x86_64 | nvim:x86_64) echo "x86_64" ;;
        rust:aarch64 | rust:arm64) echo "aarch64" ;;
        *)
            echo "Error: Unsupported architecture for $1: $(uname -m)" >&2
            exit 1
            ;;
    esac
}

# Download the latest release asset of GitHub repo $1 whose name matches regex $2 to file $3,
# verified against the sha256 digest GitHub publishes; sets RELEASE_TAG.
# Call it directly, not in $(...), so RELEASE_TAG reaches the caller.
function github_release_asset() {
    local repo="$1" pattern="$2" out="$3" release asset digest
    release="$(curl -fsSL "https://api.github.com/repos/${repo}/releases/latest")" || return 1
    asset="$(jq -c --arg p "${pattern}" '[.assets[] | select(.name | test($p))] | first // empty' <<< "${release}")"
    if [ -z "${asset}" ]; then
        echo "Error: No ${repo} release asset matches ${pattern}" >&2
        return 1
    fi

    digest="$(jq -r '.digest // empty' <<< "${asset}")"
    if [[ "${digest}" != sha256:* ]]; then
        echo "Error: No sha256 digest for $(jq -r '.name' <<< "${asset}")" >&2
        return 1
    fi

    curl -fsSL -o "${out}" "$(jq -r '.browser_download_url' <<< "${asset}")" || return 1
    echo "${digest#sha256:}  ${out}" | sha256sum -c --quiet - || return 1
    RELEASE_TAG="$(jq -r '.tag_name' <<< "${release}")"
}

# Install executable $3 from the tar.gz release asset of GitHub repo $1 matching regex $2
function install_github_binary() {
    local repo="$1" pattern="$2" binary="$3" tmp_dir
    tmp_dir="$(mktemp -d "${WORK_DIR}/XXXXXX")"
    github_release_asset "${repo}" "${pattern}" "${tmp_dir}/asset.tar.gz"
    echo "Installing ${binary} ${RELEASE_TAG} to /usr/local/bin..."
    tar -C "${tmp_dir}" -xzf "${tmp_dir}/asset.tar.gz"
    sudo install -m 0755 "$(find "${tmp_dir}" -type f -name "${binary}" | head -n1)" "/usr/local/bin/${binary}"
}

function go_is_recent_enough() {
    local current
    command -v go &> /dev/null || return 1
    current="$(go env GOVERSION)"
    version_at_least "${GO_MIN_VERSION}" "${current#go}"
}

function install_go_for_ubuntu() {
    # Bootstrap go only; later versions are fetched by the go command via GOTOOLCHAIN
    export PATH="${GO_ROOT}/bin:${PATH}"
    if go_is_recent_enough; then
        echo "Go $(go env GOVERSION) found, skip bootstrap"
        return
    fi

    local arch version tarball sha256 tmp_dir
    arch="$(ubuntu_arch go)"
    version="$(curl -fsSL 'https://go.dev/VERSION?m=text' | head -n1)"
    tarball="${version}.linux-${arch}.tar.gz"
    sha256="$(curl -fsSL 'https://go.dev/dl/?mode=json' |
        jq -r --arg f "${tarball}" '.[].files[] | select(.filename == $f) | .sha256')"
    if [ -z "${sha256}" ]; then
        echo "Error: Cannot find checksum for ${tarball}" >&2
        exit 1
    fi

    echo "Installing ${version} to ${GO_ROOT}..."
    tmp_dir="$(mktemp -d "${WORK_DIR}/XXXXXX")"
    curl -fsSL -o "${tmp_dir}/${tarball}" "https://go.dev/dl/${tarball}"
    echo "${sha256}  ${tmp_dir}/${tarball}" | sha256sum -c -
    sudo rm -rf "${GO_ROOT}"
    sudo tar -C "$(dirname "${GO_ROOT}")" -xzf "${tmp_dir}/${tarball}"
}

function install_release_tools_for_ubuntu() {
    local arch rust_arch current
    arch="$(ubuntu_arch go)"
    rust_arch="$(ubuntu_arch rust)"

    # apt's fzf is too old for `fzf --bash` / `fzf --zsh`
    current="$(command -v fzf &> /dev/null && fzf --version | cut -d' ' -f1 || echo 0)"
    if version_at_least "${FZF_MIN_VERSION}" "${current}"; then
        echo "fzf ${current} found, skip install"
    else
        install_github_binary junegunn/fzf "^fzf-.*-linux_${arch}\\.tar\\.gz$" fzf
    fi

    # eza and delta are not packaged on Ubuntu 22.04
    if command -v eza &> /dev/null; then
        echo "eza found, skip install"
    else
        install_github_binary eza-community/eza "^eza_${rust_arch}-unknown-linux-gnu\\.tar\\.gz$" eza
    fi

    if command -v delta &> /dev/null; then
        echo "delta found, skip install"
    else
        install_github_binary dandavison/delta "^delta-.*-${rust_arch}-unknown-linux-gnu\\.tar\\.gz$" delta
    fi

    # starship publishes aarch64 builds for musl only; the static binary runs on any Ubuntu
    if command -v starship &> /dev/null; then
        echo "starship found, skip install"
    else
        install_github_binary starship/starship "^starship-${rust_arch}-unknown-linux-musl\\.tar\\.gz$" starship
    fi
}

function install_neovim_for_ubuntu() {
    # apt has 0.6 (22.04) / 0.9 (24.04); the vimrc's native LSP setup needs 0.11
    local current tmp_dir arch
    current="$(command -v nvim &> /dev/null && nvim --version | head -n1 || echo 0)"
    current="${current#NVIM v}"
    if version_at_least "${NVIM_MIN_VERSION}" "${current}"; then
        echo "Neovim ${current} found, skip install"
        return
    fi

    arch="$(ubuntu_arch nvim)"
    tmp_dir="$(mktemp -d "${WORK_DIR}/XXXXXX")"
    github_release_asset neovim/neovim "^nvim-linux-${arch}\\.tar\\.gz$" "${tmp_dir}/nvim.tar.gz"
    echo "Installing Neovim ${RELEASE_TAG} to ${NVIM_ROOT}..."
    sudo rm -rf "${NVIM_ROOT}"
    sudo mkdir -p "${NVIM_ROOT}"
    sudo tar -C "${NVIM_ROOT}" --strip-components=1 -xzf "${tmp_dir}/nvim.tar.gz"
    sudo ln -sf "${NVIM_ROOT}/bin/nvim" /usr/local/bin/nvim
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
    # brew may be installed but not on PATH yet (e.g. /opt/homebrew on a fresh shell)
    load_brew_env
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
    WORK_DIR="$(mktemp -d)"
    trap 'rm -rf "${WORK_DIR}"' EXIT

    detect_os

    case "${DETECTED_OS}" in
        Darwin) install_pkgs_for_darwin ;;
        Linux)
            install_pkgs_for_ubuntu
            link_debian_renamed_tools
            install_go_for_ubuntu
            install_release_tools_for_ubuntu
            install_neovim_for_ubuntu
            ;;
    esac

    setup_python
    change_default_shell_to_zsh
}

main "$@"
