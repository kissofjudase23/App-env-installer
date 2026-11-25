import os
import shutil
import subprocess
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parent.parent
PROFILE = ROOT / "assets/shell/profile.ps1"
INSTALL_PS1 = ROOT / "install.ps1"
PROXY = "http://proxy.example.com:8080"

# One xdist worker (--dist loadgroup): pwsh processes started at the same time crash on macOS
pytestmark = pytest.mark.xdist_group(name="pwsh")
# Even one at a time, pwsh on macOS runners now and then dies from SIGSEGV with no output; such a
# crash says nothing about the script under test, so run_pwsh starts it again
PWSH_ATTEMPTS = 3


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
    proxy_vars = ("USE_CORP_PROXY", "CORP_PROXY_URL", "CORP_NO_PROXY")
    for name in (*proxy_vars, "HTTP_PROXY", "HTTPS_PROXY", "NO_PROXY"):
        env.pop(name, None)
        env.pop(name.lower(), None)
    for _ in range(PWSH_ATTEMPTS):
        result = subprocess.run(
            [pwsh, "-NoProfile", "-NonInteractive", "-Command", script],
            env=env,
            capture_output=True,
            text=True,
            timeout=60,
            check=False,
        )
        # negative: killed by a signal (POSIX only; Windows reports crashes as positive codes)
        if result.returncode >= 0:
            break
    return result


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


def test_profile_appends_corp_no_proxy(home):
    (home / ".shell_local.ps1").write_text(
        f"$env:USE_CORP_PROXY = '1'\n$env:CORP_PROXY_URL = '{PROXY}'\n"
        "$env:CORP_NO_PROXY = '.corp.example.com'\n"
    )
    result = run_pwsh(f". '{PROFILE}'; $env:NO_PROXY", home)
    assert result.stdout.strip() == "127.0.0.1,localhost,.corp.example.com", result.stderr


@pytest.mark.parametrize("on_path", [False, True], ids=["missing", "later-on-path"])
def test_profile_puts_local_bin_first(home, on_path):
    local_bin = home / ".local" / "bin"
    local_bin.mkdir(parents=True)
    path = os.pathsep.join([os.environ["PATH"], str(local_bin)]) if on_path else None
    script = (
        f". '{PROFILE}'; $e = $env:PATH -split [IO.Path]::PathSeparator; "
        f"$e[0]; @($e | Where-Object {{ $_ -eq '{local_bin}' }}).Count"
    )
    result = run_pwsh(script, home, path=path)
    # first, and moved rather than duplicated
    assert result.stdout.splitlines() == [str(local_bin), "1"], result.stderr


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


# Completers report what they received, so the test sees the COMP_LINE / COMP_POINT protocol
CLOUD_FAKES = {
    "nt": {
        "aws_completer.cmd": "@echo [%COMP_POINT%:%COMP_LINE%]\n",
        "terraform.cmd": "@echo [%COMP_POINT%:%COMP_LINE%]\n",
        "az.cmd": '@echo account>"%_ARGCOMPLETE_STDOUT_FILENAME%"\n',
    },
    "posix": {
        "aws_completer": '#!/bin/sh\necho "[$COMP_POINT:$COMP_LINE]"\n',
        "terraform": '#!/bin/sh\necho "[$COMP_POINT:$COMP_LINE]"\n',
        "az": '#!/bin/sh\necho account > "$_ARGCOMPLETE_STDOUT_FILENAME"\n',
    },
}


def test_profile_completes_cloud_clis(tmp_path, home):
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()
    for name, text in CLOUD_FAKES["nt" if os.name == "nt" else "posix"].items():
        (bin_dir / name).write_text(text)
        (bin_dir / name).chmod(0o755)
    pwsh_dir = str(Path(shutil.which("pwsh") or "pwsh").parent)
    script = (
        f". '{PROFILE}'; "
        "(TabExpansion2 'aws s3 ' 7).CompletionMatches.CompletionText; "
        "(TabExpansion2 'terraform ' 10).CompletionMatches.CompletionText; "
        "(TabExpansion2 'az ' 3).CompletionMatches.CompletionText; "
        "[bool](Get-ChildItem Env:COMP_LINE, Env:COMP_POINT, Env:_ARGCOMPLETE -ErrorAction Ignore)"
    )
    result = run_pwsh(script, home, path=os.pathsep.join([str(bin_dir), pwsh_dir]))
    assert result.stdout.splitlines() == [
        "[7:aws s3 ]",
        "[10:terraform ]",
        "account",
        "False",
    ], result.stderr


def test_profile_removes_its_helpers(home):
    script = (
        f". '{PROFILE}'; [bool](Get-Command Test-Command, Add-PathEntry -ErrorAction Ignore); "
        "[bool](Get-Variable shellLocal, localBin, goBin, openSslBin, completer, completerExe "
        "-ErrorAction Ignore)"
    )
    result = run_pwsh(script, home)
    assert result.stdout.splitlines() == ["False", "False"], result.stderr


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
    $copilot = $ids -contains 'GitHub.Copilot'
    Write-Output "$($Arguments -contains '--no-upgrade') $pwsh $copilot $($ids.Count)"
}}
Install-WingetPackage {flag} 6> $null
"""


@pytest.mark.parametrize(
    ("flag", "expected"),
    [("", ["True True True"]), ("-Upgrade", ["True True True", "False False False"])],
    ids=["install", "upgrade"],
)
def test_install_ps1_skips_upgrading_pwsh_and_copilot(home, flag, expected):
    # The test runs in pwsh, whose MSI cannot replace it; Copilot CLI updates itself
    packages = INSTALL_PS1.parent / "packages" / "winget-packages.json"
    total = packages.read_text().count("PackageIdentifier")
    result = run_pwsh(WINGET_SCRIPT.format(install=INSTALL_PS1, flag=flag), home)
    counts = [str(total)] + [str(total - 2)] * (len(expected) - 1)
    assert result.stdout.splitlines() == [
        f"{line} {count}" for line, count in zip(expected, counts, strict=True)
    ], result.stderr


def test_install_ps1_imports_cloud_packages_from_their_own_file(home):
    # Nothing in the cloud list is skipped on upgrade
    packages = INSTALL_PS1.parent / "packages" / "winget-cloud-packages.json"
    total = packages.read_text().count("PackageIdentifier")
    script = WINGET_SCRIPT.format(install=INSTALL_PS1, flag="-File $CloudPackagesFile -Upgrade")
    result = run_pwsh(script, home)
    assert result.stdout.splitlines() == [
        f"True False False {total}",
        f"False False False {total}",
    ], result.stderr


# Actions read $Upgrade from the caller's scope (Main), like Invoke-Step runs them
INSTALL_STEP_SCRIPT = """
. '{install}'
function Install-WingetPackage([string] $File = $PackagesFile, [switch] $Upgrade) {{
    Write-Output "import $(Split-Path $File -Leaf) $Upgrade"
}}
$Upgrade = {upgrade}
$steps = Get-InstallStep {flags}
$steps.Title
foreach ($step in $steps | Where-Object Title -Like '*winget*') {{ & $step.Action }}
"""


@pytest.mark.parametrize(
    ("flags", "upgrade", "cloud"),
    [("", False, False), ("-Cloud", False, True), ("-Upgrade -Cloud", True, True)],
    ids=["install", "cloud", "upgrade-cloud"],
)
def test_install_ps1_adds_cloud_step_only_with_flag(home, flags, upgrade, cloud):
    script = INSTALL_STEP_SCRIPT.format(
        install=INSTALL_PS1, flags=flags, upgrade="$true" if upgrade else "$false"
    )
    result = run_pwsh(script, home)
    verb = "Install and upgrade" if upgrade else "Install missing"
    titles = [f"{verb} winget packages (packages\\winget-packages.json)"]
    imports = [f"import winget-packages.json {upgrade}"]
    if cloud:
        titles.append(f"{verb} cloud CLIs (packages\\winget-cloud-packages.json)")
        imports.append(f"import winget-cloud-packages.json {upgrade}")
    assert result.stdout.splitlines() == [
        *titles,
        "Reload PATH from the registry",
        "Install PowerShell modules (PSScriptAnalyzer, PSFzf)",
        "Set up Python, then run install.py (dotfiles, fonts, git repos, Go tools)",
        *imports,
    ], result.stderr


@pytest.mark.parametrize(("flag", "suffix"), [("", ""), ("-Upgrade", " --upgrade")])
def test_install_ps1_passes_upgrade_to_install_py(home, flag, suffix):
    script = (
        f". '{INSTALL_PS1}'\n"
        'function Invoke-Native($Command, $Arguments) { Write-Output "$Command $Arguments" }\n'
        f"Install-Python {flag}"
    )
    result = run_pwsh(script, home)
    assert result.stdout.splitlines() == [
        "uv python install --default",
        "uv sync --locked",
        f"uv run install.py -a -y{suffix}",
    ], result.stderr


STEPS_SCRIPT = """
. '{install}'
$steps = @(
    @{{ Title = 'First step'; Action = {{ Write-Host 'first ran' }} }},
    @{{ Title = '{second}'; Action = {{ {action} }} }}
)
Invoke-Step $steps 6>&1
"""


def test_install_ps1_invoke_step_prints_plan_then_numbered_steps(home):
    script = STEPS_SCRIPT.format(
        install=INSTALL_PS1, second="Second step", action="Write-Host 'second ran'"
    )
    result = run_pwsh(script, home)
    assert result.stdout.splitlines() == [
        "    Steps:",
        "      1. First step",
        "      2. Second step",
        "",
        "==> [1/2] First step",
        "first ran",
        "",
        "==> [2/2] Second step",
        "second ran",
    ], result.stderr


def test_install_ps1_invoke_step_names_the_failed_step(home):
    script = STEPS_SCRIPT.format(install=INSTALL_PS1, second="Broken step", action="throw 'boom'")
    result = run_pwsh(script, home)
    assert result.returncode != 0
    assert "Error: step [2/2] Broken step failed" in result.stdout
    assert "boom" in result.stderr
