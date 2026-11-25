#!/bin/bash

set -Eeuo pipefail

function on_error() {
    echo "Error: '${BASH_COMMAND}' failed with exit code $1 (install.sh line $2)" >&2
    if [[ -n "${CURRENT_STEP}" ]]; then
        echo "Error: step ${CURRENT_STEP} failed" >&2
    fi
}
trap 'on_error $? ${LINENO}' ERR

UPGRADE=0
CLOUD=0
# "function|Title" steps plan_steps picks for main
STEPS=()
# "[i/N] Title" of the step run_steps is in, for on_error
CURRENT_STEP=""

# Bold cyan on a terminal; plain when piped (CI logs) or NO_COLOR is set
function heading() {
    if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
        printf '\033[1;36m%s\033[0m\n' "$1"
    else
        printf '%s\n' "$1"
    fi
}

# Print the plan, then run each "function|Title" argument under a "==> [i/N] Title" heading
function run_steps() {
    local step i=0 total=$#
    echo "    Steps:"
    for step in "$@"; do
        i=$((i + 1))
        echo "      ${i}. ${step#*|}"
    done

    i=0
    for step in "$@"; do
        i=$((i + 1))
        CURRENT_STEP="[${i}/${total}] ${step#*|}"
        echo
        heading "==> ${CURRENT_STEP}"
        "${step%%|*}"
    done
    CURRENT_STEP=""
}

function usage() {
    cat << 'USAGE'
Usage: bash install.sh [--upgrade] [--cloud]

Bootstrap packages, Python, dotfiles and Go tools on macOS or Ubuntu.

Options:
  --upgrade   Also upgrade what is already installed (packages, release
              tools, Go tools, Nerd Fonts); without it, only what is
              missing gets installed. Details: docs/configuration.md#updating
  --cloud     Also install the cloud CLIs aws, az, gcloud and terraform;
              pass it together with --upgrade to upgrade them too
  -h, --help  Show this help and exit
USAGE
}

function parse_args() {
    while (($# > 0)); do
        case "$1" in
            --upgrade) UPGRADE=1 ;;
            --cloud) CLOUD=1 ;;
            -h | --help)
                usage
                exit 0
                ;;
            *)
                echo "Error: Unknown argument: $1" >&2
                usage >&2
                exit 2
                ;;
        esac
        shift
    done
}

# Succeeds (and says so) when installed tool $1 should be kept, i.e. without --upgrade
function keep_installed() {
    if ((UPGRADE == 1)); then
        return 1
    fi
    echo "$1 found, skip install (--upgrade to update)"
}

function detect_os() {
    local os_type
    os_type="$(uname -s)"

    case "${os_type}" in
        Darwin)
            DETECTED_OS="Darwin"
            OS_LABEL="macOS"
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
            if ! version_at_least "${UBUNTU_MIN_VERSION}" "${VERSION_ID:-0}"; then
                echo "Error: Unsupported Ubuntu ${VERSION_ID:-}: ${UBUNTU_MIN_VERSION} or newer is required" >&2
                exit 1
            fi
            DETECTED_OS="Linux"
            OS_LABEL="Ubuntu ${VERSION_ID:-}"
            ;;
        *)
            echo "Error: Unsupported OS: ${os_type}" >&2
            exit 1
            ;;
    esac
}

# The user's login shell from the account database; $SHELL stays stale until the next login
function login_shell() {
    local user
    user="$(id -un)"
    case "$(uname -s)" in
        Darwin) dscl . -read "/Users/${user}" UserShell | sed 's/^UserShell: //' ;;
        *) getent passwd "${user}" | cut -d: -f7 ;;
    esac
}

function change_default_shell_to_zsh() {
    local zsh_path
    zsh_path="$(command -v zsh)"

    if ! grep -qxF "${zsh_path}" /etc/shells; then
        echo "Adding ${zsh_path} to /etc/shells..."
        echo "${zsh_path}" | sudo tee -a /etc/shells > /dev/null
    fi

    if [ "$(login_shell)" != "${zsh_path}" ]; then
        echo "Changing default shell to ${zsh_path}..."
        # sudo reuses the credentials cached by earlier steps; plain chsh asks for a password
        sudo chsh -s "${zsh_path}" "$(id -un)"
    else
        echo "Default shell is already ${zsh_path}, skip chsh"
    fi
}

# Write /etc/apt/sources.list.d/$1.list for repo "$4" (URL, suite, components), signed by the
# key at URL $3, kept as /etc/apt/keyrings/$2 (.asc for armored keys, which apt reads as they are)
function add_apt_repo() {
    local name="$1" keyring="/etc/apt/keyrings/$2" key_url="$3" repo="$4" tmp
    if [ ! -f "${keyring}" ]; then
        sudo mkdir -p -m 755 /etc/apt/keyrings
        # download fully first; a failed curl must not leave a partial keyring behind
        tmp="$(mktemp "${WORK_DIR}/XXXXXX")"
        curl "${CURL_RETRY[@]}" -fsSL -o "${tmp}" "${key_url}"
        sudo install -m 0644 "${tmp}" "${keyring}"
    fi
    echo "deb [arch=$(dpkg --print-architecture) signed-by=${keyring}] ${repo}" |
        sudo tee "/etc/apt/sources.list.d/${name}.list" > /dev/null
}

function add_gh_apt_repo() {
    # Ubuntu's own gh lags far behind; the official repo keeps it current through apt
    add_apt_repo github-cli githubcli-archive-keyring.gpg \
        https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        "https://cli.github.com/packages stable main"
}

# Suite to use from the apt repo at URL $1: this Ubuntu's codename, or APT_SUITE_FALLBACK while
# the vendor has not published that codename yet (new releases lag behind)
function apt_suite() {
    if curl "${CURL_RETRY[@]}" -fsSIL -o /dev/null "$1/dists/${VERSION_CODENAME}/Release"; then
        echo "${VERSION_CODENAME}"
    else
        echo "No ${VERSION_CODENAME} suite at $1 yet, using ${APT_SUITE_FALLBACK}" >&2
        echo "${APT_SUITE_FALLBACK}"
    fi
}

# apt-get install the packages listed in file $1 (# comments allowed)
function apt_install() {
    local -a pkgs flags=(-y)
    read -r -d '' -a pkgs < <(sed -e 's/#.*//' "$1") || true
    # Without --upgrade only install what is missing, like winget import --no-upgrade
    if ((UPGRADE == 0)); then
        flags+=(--no-upgrade)
    fi
    # sudo drops exported variables, so pass DEBIAN_FRONTEND through env
    sudo env DEBIAN_FRONTEND=noninteractive apt-get install "${flags[@]}" "${pkgs[@]}"
}

function link_debian_renamed_tools() {
    # Debian renames fd and bat to avoid clashes; expose the upstream names
    local pair src dst
    for pair in fdfind:fd batcat:bat; do
        src="${pair%%:*}"
        dst="${pair##*:}"
        if command -v "${dst}" &> /dev/null; then
            echo "${dst} found, skip link"
        elif command -v "${src}" &> /dev/null; then
            echo "Linking /usr/local/bin/${dst} to ${src}..."
            sudo ln -sf "$(command -v "${src}")" "/usr/local/bin/${dst}"
        else
            echo "${src} not found, skip link"
        fi
    done
}

function install_pkgs_for_ubuntu() {
    echo "Installing apt packages for Ubuntu..."

    add_gh_apt_repo
    sudo apt-get update -y
    apt_install packages/apt-packages.txt

    # Never let the uv installer edit rc files (they may be symlinks into this repo);
    # common.sh already puts ~/.local/bin on PATH
    export PATH="${HOME}/.local/bin:${PATH}"
    if ! command -v uv &> /dev/null; then
        echo "Installing uv to ${HOME}/.local/bin..."
        curl -LsSf https://astral.sh/uv/install.sh |
            env UV_NO_MODIFY_PATH=1 UV_INSTALL_DIR="${HOME}/.local/bin" sh
    elif ((UPGRADE == 1)) && [[ "$(command -v uv)" == "${HOME}/.local/bin/uv" ]]; then
        # uv reads a GitHub token (rate limit) only from UV_GITHUB_TOKEN
        local token="${GITHUB_TOKEN:-${GH_TOKEN:-}}"
        echo "Updating uv..."
        if [[ -n "${token}" ]]; then
            UV_GITHUB_TOKEN="${token}" uv self update
        else
            uv self update
        fi
    else
        echo "uv found, skip install"
    fi
}

UBUNTU_MIN_VERSION="24.04"
# Suite for vendor apt repos that have not published this Ubuntu's codename yet
APT_SUITE_FALLBACK="noble"
AWS_CLI_ROOT="/usr/local/aws-cli"
GO_MIN_VERSION="1.21"
GO_ROOT="/usr/local/go"
FZF_MIN_VERSION="0.48"
NVIM_MIN_VERSION="0.11"
NVIM_ROOT="/opt/nvim"
# GitHub-release binaries; ahead of /usr/bin on PATH, so they win over apt's older copies
RELEASE_BIN_DIR="/usr/local/bin"
# Transient errors (timeouts, 429, 5xx) only; not for `curl | sh`, where a retry could
# append a second copy to what the shell already read
CURL_RETRY=(--retry 3 --connect-timeout 10)

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

# GET api.github.com/$1; GITHUB_TOKEN/GH_TOKEN lifts the 60 requests/hour anonymous limit.
# The header goes through stdin so the token never shows up in ps.
function github_api() {
    local token="${GITHUB_TOKEN:-${GH_TOKEN:-}}"
    if [[ -n "${token}" ]]; then
        curl "${CURL_RETRY[@]}" -fsSL -H @- "https://api.github.com/$1" <<< "Authorization: Bearer ${token}"
    else
        curl "${CURL_RETRY[@]}" -fsSL "https://api.github.com/$1"
    fi
}

# Download the latest release asset of GitHub repo $1 whose name matches regex $2 to file $3,
# verified against the sha256 digest GitHub publishes; sets RELEASE_TAG.
# Call it directly, not in $(...), so RELEASE_TAG reaches the caller.
function github_release_asset() {
    local repo="$1" pattern="$2" out="$3" release asset digest
    release="$(github_api "repos/${repo}/releases/latest")" || return 1
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

    curl "${CURL_RETRY[@]}" -fsSL -o "${out}" "$(jq -r '.browser_download_url' <<< "${asset}")" || return 1
    echo "${digest#sha256:}  ${out}" | sha256sum -c --quiet - || return 1
    RELEASE_TAG="$(jq -r '.tag_name' <<< "${release}")"
}

# Install executable $3 from the tar.gz release asset of GitHub repo $1 matching regex $2
function install_github_binary() {
    local repo="$1" pattern="$2" binary="$3" tmp_dir
    tmp_dir="$(mktemp -d "${WORK_DIR}/XXXXXX")"
    github_release_asset "${repo}" "${pattern}" "${tmp_dir}/asset.tar.gz"
    echo "Installing ${binary} ${RELEASE_TAG} to ${RELEASE_BIN_DIR}..."
    tar -C "${tmp_dir}" -xzf "${tmp_dir}/asset.tar.gz"
    sudo install -m 0755 "$(find "${tmp_dir}" -type f -name "${binary}" | head -n1)" "${RELEASE_BIN_DIR}/${binary}"
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
    version="$(curl "${CURL_RETRY[@]}" -fsSL 'https://go.dev/VERSION?m=text' | head -n1)"
    tarball="${version}.linux-${arch}.tar.gz"
    sha256="$(curl "${CURL_RETRY[@]}" -fsSL 'https://go.dev/dl/?mode=json' |
        jq -r --arg f "${tarball}" '.[].files[] | select(.filename == $f) | .sha256')"
    if [ -z "${sha256}" ]; then
        echo "Error: Cannot find checksum for ${tarball}" >&2
        exit 1
    fi

    echo "Installing ${version} to ${GO_ROOT}..."
    tmp_dir="$(mktemp -d "${WORK_DIR}/XXXXXX")"
    curl "${CURL_RETRY[@]}" -fsSL -o "${tmp_dir}/${tarball}" "https://go.dev/dl/${tarball}"
    echo "${sha256}  ${tmp_dir}/${tarball}" | sha256sum -c -
    sudo rm -rf "${GO_ROOT}"
    sudo tar -C "$(dirname "${GO_ROOT}")" -xzf "${tmp_dir}/${tarball}"
}

function install_release_tools_for_ubuntu() {
    local arch rust_arch current
    arch="$(ubuntu_arch go)"
    rust_arch="$(ubuntu_arch rust)"

    # 24.04's apt fzf (0.44) is too old for `fzf --bash` / `fzf --zsh`
    current="$(command -v fzf &> /dev/null && fzf --version | cut -d' ' -f1 || echo 0)"
    if ! version_at_least "${FZF_MIN_VERSION}" "${current}" || ! keep_installed "fzf ${current}"; then
        install_github_binary junegunn/fzf "^fzf-.*-linux_${arch}\\.tar\\.gz$" fzf
    fi

    # 24.04's apt eza (0.18) and delta (0.16) are far behind upstream; the GitHub releases
    # keep every supported Ubuntu on the same version, so only our own copy counts as installed
    if [[ ! -x "${RELEASE_BIN_DIR}/eza" ]] || ! keep_installed eza; then
        install_github_binary eza-community/eza "^eza_${rust_arch}-unknown-linux-gnu\\.tar\\.gz$" eza
    fi

    if [[ ! -x "${RELEASE_BIN_DIR}/delta" ]] || ! keep_installed delta; then
        install_github_binary dandavison/delta "^delta-.*-${rust_arch}-unknown-linux-gnu\\.tar\\.gz$" delta
    fi

    # starship publishes aarch64 builds for musl only; the static binary runs on any Ubuntu
    if [[ ! -x "${RELEASE_BIN_DIR}/starship" ]] || ! keep_installed starship; then
        install_github_binary starship/starship "^starship-${rust_arch}-unknown-linux-musl\\.tar\\.gz$" starship
    fi
}

function install_neovim_for_ubuntu() {
    # 24.04's apt has 0.9 (26.04: 0.11); the vimrc's native LSP setup needs 0.11
    local current tmp_dir arch
    current="$(command -v nvim &> /dev/null && nvim --version | head -n1 || echo 0)"
    current="${current#NVIM v}"
    if version_at_least "${NVIM_MIN_VERSION}" "${current}" && keep_installed "Neovim ${current}"; then
        return
    fi

    arch="$(ubuntu_arch nvim)"
    tmp_dir="$(mktemp -d "${WORK_DIR}/XXXXXX")"
    github_release_asset neovim/neovim "^nvim-linux-${arch}\\.tar\\.gz$" "${tmp_dir}/nvim.tar.gz"
    echo "Installing Neovim ${RELEASE_TAG} to ${NVIM_ROOT}..."
    sudo rm -rf "${NVIM_ROOT}"
    sudo mkdir -p "${NVIM_ROOT}"
    sudo tar -C "${NVIM_ROOT}" --strip-components=1 -xzf "${tmp_dir}/nvim.tar.gz"
    sudo ln -sf "${NVIM_ROOT}/bin/nvim" "${RELEASE_BIN_DIR}/nvim"
}

function install_cloud_pkgs_for_ubuntu() {
    echo "Adding the Azure CLI, Google Cloud CLI and HashiCorp apt repos..."
    local azure="https://packages.microsoft.com/repos/azure-cli"
    local hashicorp="https://apt.releases.hashicorp.com"
    local azure_suite hashicorp_suite
    azure_suite="$(apt_suite "${azure}")"
    hashicorp_suite="$(apt_suite "${hashicorp}")"
    add_apt_repo azure-cli microsoft.asc https://packages.microsoft.com/keys/microsoft.asc \
        "${azure} ${azure_suite} main"
    add_apt_repo google-cloud-sdk cloud.google.asc https://packages.cloud.google.com/apt/doc/apt-key.gpg \
        "https://packages.cloud.google.com/apt cloud-sdk main"
    add_apt_repo hashicorp hashicorp.asc "${hashicorp}/gpg" "${hashicorp} ${hashicorp_suite} main"
    sudo apt-get update -y
    apt_install packages/apt-cloud-packages.txt
}

function install_aws_cli_for_ubuntu() {
    # No apt repo; AWS's installer keeps the CLI in AWS_CLI_ROOT and links it into RELEASE_BIN_DIR.
    # AWS publishes a PGP signature but no checksum, so like the uv installer this relies on HTTPS.
    if [[ -x "${RELEASE_BIN_DIR}/aws" ]] && keep_installed "AWS CLI"; then
        return
    fi

    local arch tmp_dir
    arch="$(ubuntu_arch rust)"
    tmp_dir="$(mktemp -d "${WORK_DIR}/XXXXXX")"
    echo "Installing the latest AWS CLI v2 to ${AWS_CLI_ROOT}..."
    curl "${CURL_RETRY[@]}" -fsSL -o "${tmp_dir}/awscliv2.zip" \
        "https://awscli.amazonaws.com/awscli-exe-linux-${arch}.zip"
    unzip -q "${tmp_dir}/awscliv2.zip" -d "${tmp_dir}"
    # --update replaces an existing install instead of failing on it
    sudo "${tmp_dir}/aws/install" --bin-dir "${RELEASE_BIN_DIR}" --install-dir "${AWS_CLI_ROOT}" --update
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

    if ((UPGRADE == 1)); then
        brew update
    fi
    brew_bundle packages/Brewfile
}

function install_cloud_pkgs_for_darwin() {
    load_brew_env
    brew_bundle packages/Brewfile.cloud
}

# brew bundle Brewfile $1. Without --upgrade only install what is missing, like winget import
# --no-upgrade; an explicit --upgrade also wins over HOMEBREW_BUNDLE_NO_UPGRADE
function brew_bundle() {
    if ((UPGRADE == 1)); then
        brew bundle install --upgrade --file="$1"
    else
        brew bundle install --no-upgrade --file="$1"
    fi
}

function setup_python() {
    # No argument: uv reads the version from .python-version
    uv python install --default
    uv sync --locked
    if ((UPGRADE == 1)); then
        uv run install.py -a -y --upgrade
    else
        uv run install.py -a -y
    fi
}

# Every step goes in STEPS, so the plan printed up front matches what runs
function plan_steps() {
    local missing="Install missing" latest="Install"
    if ((UPGRADE == 1)); then
        missing="Install and upgrade" latest="Install the latest"
    fi
    case "${DETECTED_OS}" in
        Darwin)
            STEPS=("install_pkgs_for_darwin|${missing} Homebrew packages (packages/Brewfile)")
            if ((CLOUD == 1)); then
                STEPS+=("install_cloud_pkgs_for_darwin|${missing} cloud CLIs (packages/Brewfile.cloud)")
            fi
            ;;
        Linux)
            STEPS=(
                "install_pkgs_for_ubuntu|${missing} apt packages and uv"
                "link_debian_renamed_tools|Link fdfind / batcat as fd / bat"
                "install_go_for_ubuntu|Bootstrap Go"
                "install_release_tools_for_ubuntu|${latest} fzf, eza, delta, starship (GitHub releases)"
                "install_neovim_for_ubuntu|${latest} Neovim (GitHub release)"
            )
            if ((CLOUD == 1)); then
                STEPS+=(
                    "install_cloud_pkgs_for_ubuntu|${missing} az, gcloud, terraform (vendor apt repos)"
                    "install_aws_cli_for_ubuntu|${latest} AWS CLI (official installer)"
                )
            fi
            ;;
    esac
    STEPS+=(
        "setup_python|Set up Python, then run install.py (dotfiles, fonts, git repos, Go tools)"
        "change_default_shell_to_zsh|Make zsh the default shell"
    )
}

function main() {
    parse_args "$@"
    cd "$(dirname "${BASH_SOURCE[0]}")"
    WORK_DIR="$(mktemp -d)"
    trap 'rm -rf "${WORK_DIR}"' EXIT

    detect_os
    plan_steps

    local mode="install"
    if ((UPGRADE == 1)); then
        mode="upgrade"
    fi
    heading "==> App-env-installer: ${mode} on ${OS_LABEL}"
    run_steps "${STEPS[@]}"

    echo
    heading "==> Done in $((SECONDS / 60))m$((SECONDS % 60))s (${mode}). Open a new terminal to load the shell config."
    if ((UPGRADE == 0)); then
        echo "    Installed tools were kept as they are; 'make upgrade' also updates them."
    fi
}

# Sourcing only defines the functions (tests/test_shell.py)
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
