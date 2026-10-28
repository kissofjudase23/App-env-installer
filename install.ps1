# Bootstrap packages, Python, dotfiles and Go tools on Windows.
# Runs on Windows PowerShell 5.1 (a fresh machine has no pwsh yet):
#   powershell -ExecutionPolicy Bypass -File .\install.ps1 [-Upgrade]
[CmdletBinding()]
param(
    # Also upgrade packages that are already installed
    [switch] $Upgrade,
    [switch] $Help
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$PackagesFile = Join-Path $PSScriptRoot 'winget-packages.json'

function Show-Usage {
    @'
Usage: powershell -ExecutionPolicy Bypass -File .\install.ps1 [-Upgrade]

Bootstrap winget packages, Python, dotfiles and Go tools on Windows.

Options:
  -Upgrade  Upgrade the packages in winget-packages.json even when installed
  -Help     Show this help and exit
'@
}

# Run a native command and fail on a non-zero exit code, like bash's set -e
function Invoke-Native {
    param([Parameter(Mandatory)] [string] $Command, [string[]] $Arguments = @())
    Write-Host "> $Command $($Arguments -join ' ')"
    & $Command @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "'$Command $($Arguments -join ' ')' failed with exit code $LASTEXITCODE"
    }
}

function Assert-Windows {
    # $IsWindows only exists on PowerShell 6+; 5.1 runs on Windows only
    if ((Test-Path Variable:IsWindows) -and -not $IsWindows) {
        throw 'install.ps1 supports Windows only; use install.sh on macOS and Ubuntu'
    }
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw 'winget not found; install "App Installer" from the Microsoft Store'
    }
}

function Install-WingetPackage {
    param([switch] $Upgrade)
    $arguments = @(
        'import', '--import-file', $PackagesFile,
        '--accept-package-agreements', '--accept-source-agreements', '--disable-interactivity'
    )
    # import upgrades installed packages unless told not to; non-zero exit if any package fails
    if (-not $Upgrade) { $arguments += '--no-upgrade' }
    Invoke-Native winget $arguments
}

# winget installers update the registry PATH, not this session's
function Sync-SessionPath {
    $machine = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = "$machine;$user;$env:Path"
}

# PSScriptAnalyzer backs `make pslint`; PSFzf adds fzf key bindings in profile.ps1.
# Runs in pwsh, whose bundled PSResourceGet (7.4+) needs no NuGet provider prompt.
function Install-PwshModule {
    $script = "foreach (`$m in 'PSScriptAnalyzer', 'PSFzf') { " +
        "if (-not (Get-Module -ListAvailable `$m)) { " +
        "Install-PSResource `$m -Scope CurrentUser -TrustRepository -Quiet } }"
    Invoke-Native pwsh @('-NoProfile', '-NonInteractive', '-Command', $script)
}

function Install-Python {
    # No argument: uv reads the version from .python-version
    Invoke-Native uv @('python', 'install')
    Invoke-Native uv @('sync')
    Invoke-Native uv @('run', 'install.py', '-a', '-y')
}

function Main {
    param([switch] $Upgrade, [switch] $Help)
    if ($Help) {
        Show-Usage
        return
    }
    Assert-Windows
    Push-Location $PSScriptRoot
    try {
        Install-WingetPackage -Upgrade:$Upgrade
        Sync-SessionPath
        Install-PwshModule
        Install-Python
    } finally {
        Pop-Location
    }
    Write-Host @'

Done. Open Windows Terminal and set:
  Settings > Startup > Default profile: PowerShell (7)
  Settings > Profiles > Defaults > Appearance > Font face: MesloLGS Nerd Font
'@
}

# Dot-sourcing only defines the functions (tests/test_powershell.py)
if ($MyInvocation.InvocationName -ne '.') {
    Main -Upgrade:$Upgrade -Help:$Help
}
