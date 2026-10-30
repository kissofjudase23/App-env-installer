import os
import shutil
import subprocess
import sys
from pathlib import Path

import pytest

# Git Bash on Windows is not a target: these dotfiles are linked on macOS and Linux only
pytestmark = pytest.mark.skipif(sys.platform == "win32", reason="bash/zsh dotfiles are Unix-only")

ROOT = Path(__file__).resolve().parent.parent
SHELL_DIR = ROOT / "assets/shell"
COMMON = SHELL_DIR / "common.sh"
INSTALL_SH = ROOT / "install.sh"
PROXY = "http://proxy.example.com:8080"

# Clean shells: no system or user rc files, only what the test sources
SHELLS = {"bash": ["bash", "--noprofile", "--norc", "-c"], "zsh": ["zsh", "-f", "-c"]}


@pytest.fixture
def home(tmp_path: Path) -> Path:
    path = tmp_path / "home"
    path.mkdir()
    (path / ".assets").symlink_to(ROOT / "assets")
    for name, src in {".bashrc": "bashrc.sh", ".bash_profile": "bash_profile.sh"}.items():
        (path / name).symlink_to(SHELL_DIR / src)
    return path


def run_shell(
    shell: str, script: str, home: Path, *args: str, env: dict[str, str] | None = None
) -> subprocess.CompletedProcess:
    if shutil.which(shell) is None:
        pytest.skip(f"{shell} is not installed")
    env = {"HOME": str(home), "PATH": os.environ["PATH"], "TERM": "xterm-256color", **(env or {})}
    return subprocess.run(
        [*SHELLS[shell], script, shell, *args],
        env=env,
        capture_output=True,
        text=True,
        timeout=60,
        check=False,
    )


@pytest.mark.parametrize(
    ("shell", "path"),
    [
        ("bash", INSTALL_SH),
        ("bash", COMMON),
        ("bash", SHELL_DIR / "bashrc.sh"),
        ("bash", SHELL_DIR / "bash_profile.sh"),
        ("zsh", COMMON),
        ("zsh", SHELL_DIR / "zshrc.zsh"),
    ],
    ids=lambda v: v if isinstance(v, str) else v.name,
)
def test_syntax(shell, path, home):
    result = run_shell(shell, f'{shell} -n "$1"', home, str(path))
    assert result.returncode == 0, result.stderr


@pytest.mark.parametrize("shell", ["bash", "zsh"])
@pytest.mark.parametrize("proxy", [False, True], ids=["plain", "proxy"])
def test_common_sh_prints_nothing(shell, proxy, home):
    # Output from common.sh breaks scp and the prompt
    if proxy:
        (home / ".shell_local").write_text(f"USE_CORP_PROXY=1\nCORP_PROXY_URL={PROXY}\n")
    result = run_shell(shell, 'source "$1"', home, str(COMMON))
    assert (result.returncode, result.stdout, result.stderr) == (0, "", "")


@pytest.mark.parametrize("shell", ["bash", "zsh"])
def test_common_sh_sets_proxy_from_shell_local(shell, home):
    (home / ".shell_local").write_text(f"USE_CORP_PROXY=1\nCORP_PROXY_URL={PROXY}\n")
    script = 'source "$1"; printf "%s\\n" "$http_proxy" "$HTTPS_PROXY" "$no_proxy"'
    result = run_shell(shell, script, home, str(COMMON))
    assert result.stdout.splitlines() == [PROXY, PROXY, "127.0.0.1,localhost"]


@pytest.mark.parametrize("shell", ["bash", "zsh"])
@pytest.mark.parametrize(
    ("term", "expected"),
    [
        ("xterm", "xterm-256color"),
        ("xterm-256color", "xterm-256color"),
        ("nosuchterm", "nosuchterm"),
    ],
)
def test_common_sh_upgrades_term_to_256color(shell, term, expected, home):
    if shutil.which("infocmp") is None:
        pytest.skip("infocmp is not installed")
    script = 'source "$1"; printf "%s" "$TERM"'
    result = run_shell(shell, script, home, str(COMMON), env={"TERM": term})
    assert result.stdout == expected


def test_common_sh_keeps_only_alias_setting(home):
    result = run_shell("bash", 'source "$1"; declare -F', home, str(COMMON))
    assert result.stdout.split() == ["declare", "-f", "alias_setting"]


def test_non_interactive_bash_login_prints_nothing(home):
    # ssh host cmd / scp: bash_profile -> bashrc -> common.sh must stay silent
    result = run_shell("bash", "source ~/.bash_profile; declare -F", home)
    assert (result.returncode, result.stdout, result.stderr) == (0, "", "")


# install.sh only runs main when executed, so sourcing it exposes its functions
@pytest.mark.parametrize(
    ("minimum", "current", "ok"),
    [
        ("0.48", "0.48", True),
        ("0.48", "0.56.3", True),
        ("0.48", "0.9", False),
        ("0.11", "0", False),
    ],
)
def test_version_at_least(home, minimum, current, ok):
    script = 'source "$1"; if version_at_least "$2" "$3"; then echo yes; else echo no; fi'
    result = run_shell("bash", script, home, str(INSTALL_SH), minimum, current)
    assert result.stdout == ("yes\n" if ok else "no\n"), result.stderr


# A function shadows curl and echoes its args plus any header read from stdin
GITHUB_API_SCRIPT = """
source "$1"
curl() {
    printf 'args: %s\\n' "$*"
    case " $* " in *" @- "*) printf 'stdin: %s\\n' "$(cat)" ;; esac
}
github_api repos/o/r/releases/latest
"""


@pytest.mark.parametrize("token_var", ["GITHUB_TOKEN", "GH_TOKEN"])
def test_github_api_sends_token_via_stdin(home, token_var):
    env = {token_var: "s3cret"}
    result = run_shell("bash", GITHUB_API_SCRIPT, home, str(INSTALL_SH), env=env)

    assert result.stdout.splitlines() == [
        "args: -fsSL -H @- https://api.github.com/repos/o/r/releases/latest",
        "stdin: Authorization: Bearer s3cret",
    ], result.stderr


def test_github_api_without_token(home):
    result = run_shell("bash", GITHUB_API_SCRIPT, home, str(INSTALL_SH))

    assert result.stdout.splitlines() == [
        "args: -fsSL https://api.github.com/repos/o/r/releases/latest"
    ], result.stderr


@pytest.mark.parametrize(("args", "upgrade"), [([], "0"), (["--upgrade"], "1")])
def test_parse_args(home, args, upgrade):
    script = 'source "$1"; shift; parse_args "$@"; echo "UPGRADE=${UPGRADE}"'
    result = run_shell("bash", script, home, str(INSTALL_SH), *args)
    assert (result.returncode, result.stdout) == (0, f"UPGRADE={upgrade}\n"), result.stderr


@pytest.mark.parametrize("flag", ["-h", "--help"])
def test_parse_args_help(home, flag):
    result = run_shell("bash", 'source "$1"; parse_args "$2"', home, str(INSTALL_SH), flag)
    assert result.returncode == 0
    assert result.stdout.startswith("Usage: bash install.sh [--upgrade]")
    assert result.stderr == ""


def test_parse_args_rejects_unknown_argument(home):
    result = run_shell("bash", 'source "$1"; parse_args --bogus', home, str(INSTALL_SH))
    assert result.returncode == 2
    assert result.stdout == ""
    assert result.stderr.startswith("Error: Unknown argument: --bogus\nUsage:")


# Stubs replace downloads and sudo; PATH holds only the coreutils the checks need,
# so fzf, delta and nvim exist (as stub functions) while eza and starship are missing.
RELEASE_TOOLS_SCRIPT = """
source "$1"
PATH="$2"
FZF_VERSION="$3"
shift 3
WORK_DIR=/nonexistent
ubuntu_arch() { echo x; }
mktemp() { echo "${WORK_DIR}"; }
sudo() { :; }
install_github_binary() { echo "install $3"; }
github_release_asset() { RELEASE_TAG=v9.9.9; }
fzf() { echo "${FZF_VERSION} (stub)"; }
delta() { :; }
nvim() { echo "NVIM v0.12.1"; }
parse_args "$@"
install_release_tools_for_ubuntu
install_neovim_for_ubuntu
"""
KEEP = "found, skip install (--upgrade to update)"


@pytest.fixture
def coreutils_path(tmp_path: Path) -> str:
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()
    for tool in ("sort", "head", "cut"):
        (bin_dir / tool).symlink_to(shutil.which(tool))
    return str(bin_dir)


@pytest.mark.parametrize(
    ("fzf_version", "args", "expected"),
    [
        (
            "0.56.3",
            [],
            [
                f"fzf 0.56.3 {KEEP}",
                "install eza",
                f"delta {KEEP}",
                "install starship",
                f"Neovim 0.12.1 {KEEP}",
            ],
        ),
        (
            "0.29.0",
            [],
            [
                "install fzf",
                "install eza",
                f"delta {KEEP}",
                "install starship",
                f"Neovim 0.12.1 {KEEP}",
            ],
        ),
        (
            "0.56.3",
            ["--upgrade"],
            [
                "install fzf",
                "install eza",
                "install delta",
                "install starship",
                "Installing Neovim v9.9.9 to /opt/nvim...",
            ],
        ),
    ],
    ids=["keep", "fzf-too-old", "upgrade"],
)
def test_release_tools_upgrade(home, coreutils_path, fzf_version, args, expected):
    result = run_shell(
        "bash", RELEASE_TOOLS_SCRIPT, home, str(INSTALL_SH), coreutils_path, fzf_version, *args
    )
    assert result.stdout.splitlines() == expected, result.stderr
