import os
import shutil
import subprocess
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parent.parent
PROFILE = ROOT / "assets/shell/profile.ps1"
INSTALL_PS1 = ROOT / "install.ps1"
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


def test_profile_uses_nvim_as_editor(tmp_path, home):
    # Get-Command -CommandType Application needs a .cmd on Windows, an executable bit elsewhere
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()
    fake = bin_dir / ("nvim.cmd" if os.name == "nt" else "nvim")
    fake.write_text("@echo off\n" if os.name == "nt" else "#!/bin/sh\n")
    fake.chmod(0o755)
    pwsh_dir = str(Path(shutil.which("pwsh") or "pwsh").parent)
    script = (
        f". '{PROFILE}'; $env:VISUAL; $env:EDITOR; $env:GIT_EDITOR; "
        "(Get-Alias vi).Definition; (Get-Alias vim).Definition; "
        "[bool](Get-Command vimdiff -CommandType Function -ErrorAction Ignore)"
    )
    result = run_pwsh(script, home, path=os.pathsep.join([str(bin_dir), pwsh_dir]))
    assert result.stdout.splitlines() == ["nvim"] * 5 + ["True"], result.stderr


def test_profile_removes_its_helpers(home):
    script = f". '{PROFILE}'; [bool](Get-Command Test-Command, Add-PathEntry -ErrorAction Ignore)"
    result = run_pwsh(script, home)
    assert result.stdout.strip() == "False", result.stderr


def test_install_ps1_dot_source_does_not_run_main(home):
    # Main would call winget; dot-sourcing must only define functions
    script = f". '{INSTALL_PS1}'; [bool](Get-Command Install-WingetPackage -ErrorAction Ignore)"
    result = run_pwsh(script, home, path="")
    assert (result.returncode, result.stdout.strip()) == (0, "True"), result.stderr


# Invoke-Native is replaced by a recorder that prints each winget import and its package IDs
WINGET_SCRIPT = """
. '{install}'
function Invoke-Native($Command, $Arguments) {{
    $file = $Arguments[[array]::IndexOf($Arguments, '--import-file') + 1]
    $ids = (Get-Content $file -Raw | ConvertFrom-Json).Sources.Packages.PackageIdentifier
    $pwsh = $ids -contains 'Microsoft.PowerShell'
    Write-Output "$($Arguments -contains '--no-upgrade') $pwsh $($ids.Count)"
}}
Install-WingetPackage {flag} 6> $null
"""


@pytest.mark.parametrize(
    ("flag", "expected"),
    [("", ["True True"]), ("-Upgrade", ["True True", "False False"])],
    ids=["install", "upgrade"],
)
def test_install_ps1_never_upgrades_running_pwsh(home, flag, expected):
    # The test itself runs in pwsh, whose MSI cannot be replaced while it runs
    packages = INSTALL_PS1.parent / "packages" / "winget-packages.json"
    total = packages.read_text().count("PackageIdentifier")
    result = run_pwsh(WINGET_SCRIPT.format(install=INSTALL_PS1, flag=flag), home)
    counts = [str(total)] + [str(total - 1)] * (len(expected) - 1)
    assert result.stdout.splitlines() == [
        f"{line} {count}" for line, count in zip(expected, counts, strict=True)
    ], result.stderr
