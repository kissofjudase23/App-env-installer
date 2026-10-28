import os
import shutil
import subprocess
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parent.parent
PROFILE = ROOT / "assets/shell/profile.ps1"
PROXY = "http://proxy.example.com:8080"


@pytest.fixture
def home(tmp_path: Path) -> Path:
    path = tmp_path / "home"
    path.mkdir()
    return path


def run_pwsh(script: str, home: Path, *, path: str | None = None) -> subprocess.CompletedProcess:
    pwsh = shutil.which("pwsh")
    if pwsh is None:
        pytest.skip("pwsh is not installed")
    env = {
        **os.environ,
        "HOME": str(home),
        "USERPROFILE": str(home),
        "PATH": path if path is not None else os.environ["PATH"],
    }
    for name in ("USE_CORP_PROXY", "CORP_PROXY_URL", "HTTP_PROXY", "HTTPS_PROXY", "NO_PROXY"):
        env.pop(name, None)
        env.pop(name.lower(), None)
    return subprocess.run(
        [pwsh, "-NoProfile", "-NonInteractive", "-Command", script],
        env=env,
        capture_output=True,
        text=True,
        timeout=60,
        check=False,
    )


@pytest.mark.parametrize("proxy", [False, True], ids=["plain", "proxy"])
def test_profile_prints_nothing(home, proxy):
    if proxy:
        (home / ".shell_local.ps1").write_text(
            f"$env:USE_CORP_PROXY = '1'\n$env:CORP_PROXY_URL = '{PROXY}'\n"
        )
    result = run_pwsh(f". '{PROFILE}'", home)
    assert (result.returncode, result.stdout, result.stderr) == (0, "", "")


def test_profile_without_optional_tools_prints_nothing(home):
    # Only pwsh's own directory: starship, zoxide, eza, bat, fd, delta are all missing
    pwsh_dir = str(Path(shutil.which("pwsh") or "pwsh").parent)
    result = run_pwsh(f". '{PROFILE}'", home, path=pwsh_dir)
    assert (result.returncode, result.stdout, result.stderr) == (0, "", "")


def test_profile_sets_proxy_and_starship_config(home):
    (home / ".shell_local.ps1").write_text(
        f"$env:USE_CORP_PROXY = '1'\n$env:CORP_PROXY_URL = '{PROXY}'\n"
    )
    script = f". '{PROFILE}'; $env:HTTPS_PROXY; $env:NO_PROXY; $env:STARSHIP_CONFIG"
    result = run_pwsh(script, home)
    assert result.stdout.splitlines() == [
        PROXY,
        "127.0.0.1,localhost",
        str(ROOT / "assets" / "starship" / "starship.toml"),
    ], result.stderr


def test_profile_removes_its_helpers(home):
    script = f". '{PROFILE}'; [bool](Get-Command Test-Command, Add-PathEntry -ErrorAction Ignore)"
    result = run_pwsh(script, home)
    assert result.stdout.strip() == "False", result.stderr

