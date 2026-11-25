# Bootstrap packages, Python, dotfiles and Go tools on Windows.
# Runs on Windows PowerShell 5.1 (a fresh machine has no pwsh yet):
#   powershell -ExecutionPolicy Bypass -File .\install.ps1 [-Upgrade] [-Cloud]
[CmdletBinding()]
param(
    # Also upgrade installed packages, Go tools and Nerd Fonts
    [switch] $Upgrade,
    # Also install the cloud CLIs (packages\winget-cloud-packages.json)
    [switch] $Cloud,
    [switch] $Help
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$PackagesFile = Join-Path $PSScriptRoot 'packages\winget-packages.json'
$CloudPackagesFile = Join-Path $PSScriptRoot 'packages\winget-cloud-packages.json'

function Show-Usage {
    @'
Usage: powershell -ExecutionPolicy Bypass -File .\install.ps1 [-Upgrade] [-Cloud]

Bootstrap winget packages, Python, dotfiles and Go tools on Windows.

Options:
  -Upgrade  Upgrade the packages in packages\winget-packages.json, the Go tools
            and the Nerd Fonts even when installed
  -Cloud    Also install the cloud CLIs aws, az, gcloud and terraform
            (packages\winget-cloud-packages.json); with -Upgrade, upgrade them too
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

function Write-Heading {
    param([Parameter(Mandatory)] [string] $Text)
    # Plain text in CI logs and when NO_COLOR is set
    if ($env:NO_COLOR -or [Console]::IsOutputRedirected) {
        Write-Host $Text
    } else {
        Write-Host $Text -ForegroundColor Cyan
    }
}

# Print the plan, then run each @{ Title; Action } under a "==> [i/N] Title" heading
function Invoke-Step {
    param([Parameter(Mandatory)] [hashtable[]] $Steps)
    Write-Host '    Steps:'
    for ($i = 0; $i -lt $Steps.Count; $i++) {
        Write-Host "      $($i + 1). $($Steps[$i].Title)"
    }
    for ($i = 0; $i -lt $Steps.Count; $i++) {
        $current = "[$($i + 1)/$($Steps.Count)] $($Steps[$i].Title)"
        Write-Host ''
        Write-Heading "==> $current"
        try {
            & $Steps[$i].Action
        } catch {
            Write-Host "Error: step $current failed" -ForegroundColor Red
            throw
        }
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
    param([string] $File = $PackagesFile, [switch] $Upgrade)
    $common = @('--accept-package-agreements', '--accept-source-agreements', '--disable-interactivity')
    # Install what is missing; import exits non-zero if any package fails
    Invoke-Native winget (@('import', '--import-file', $File, '--no-upgrade') + $common)
    if (-not $Upgrade) { return }

    # Copilot CLI updates its portable exe in place, so winget refuses to remove the "modified" package
    $skip = @('GitHub.Copilot')
    # The PowerShell MSI cannot replace pwsh while it runs (Windows Terminal, make, CI steps)
    if (Get-Process pwsh -ErrorAction SilentlyContinue) {
        $skip += 'Microsoft.PowerShell'
        Write-Host 'Skip upgrading PowerShell 7 while pwsh is running; close it, then from cmd run: winget upgrade Microsoft.PowerShell'
    }
    $config = Get-Content $File -Raw | ConvertFrom-Json
    foreach ($source in $config.Sources) {
        $source.Packages = @($source.Packages | Where-Object { $skip -notcontains $_.PackageIdentifier })
    }
    $upgradeFile = Join-Path ([IO.Path]::GetTempPath()) "app-env-installer-$(Split-Path $File -Leaf)"
    # WriteAllText: UTF-8 without the BOM that 5.1's Set-Content -Encoding UTF8 adds
    [IO.File]::WriteAllText($upgradeFile, ($config | ConvertTo-Json -Depth 5))
    try {
        Invoke-Native winget (@('import', '--import-file', $upgradeFile) + $common)
    } finally {
        Remove-Item $upgradeFile -ErrorAction SilentlyContinue
    }
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
    param([switch] $Upgrade)
    # No version argument: uv reads it from .python-version; --default adds python to ~/.local/bin
    Invoke-Native uv @('python', 'install', '--default')
    Invoke-Native uv @('sync', '--locked')
    $installArgs = @('run', 'install.py', '-a', '-y')
    if ($Upgrade) { $installArgs += '--upgrade' }
    Invoke-Native uv $installArgs
}

# Every step goes in this list, so the plan printed up front matches what runs.
# Actions read $Upgrade from Main, whose scope Invoke-Step runs them in.
function Get-InstallStep {
    param([switch] $Upgrade, [switch] $Cloud)
    $verb = 'Install missing'
    if ($Upgrade) { $verb = 'Install and upgrade' }
    $steps = @(
        @{
            Title = "$verb winget packages (packages\winget-packages.json)"
            Action = { Install-WingetPackage -Upgrade:$Upgrade }
        }
    )
    if ($Cloud) {
        $steps += @{
            Title = "$verb cloud CLIs (packages\winget-cloud-packages.json)"
            Action = { Install-WingetPackage -File $CloudPackagesFile -Upgrade:$Upgrade }
        }
    }
    $steps += @(
        @{ Title = 'Reload PATH from the registry'; Action = { Sync-SessionPath } },
        @{ Title = 'Install PowerShell modules (PSScriptAnalyzer, PSFzf)'; Action = { Install-PwshModule } },
        @{
            Title = 'Set up Python, then run install.py (dotfiles, fonts, git repos, Go tools)'
            Action = { Install-Python -Upgrade:$Upgrade }
        }
    )
    $steps
}

function Main {
    param([switch] $Upgrade, [switch] $Cloud, [switch] $Help)
    if ($Help) {
        Show-Usage
        return
    }
    Assert-Windows
    $timer = [Diagnostics.Stopwatch]::StartNew()
    $mode = 'install'
    if ($Upgrade) { $mode = 'upgrade' }
    $steps = Get-InstallStep -Upgrade:$Upgrade -Cloud:$Cloud
    Write-Heading "==> App-env-installer: $mode on Windows"
    Push-Location $PSScriptRoot
    try {
        Invoke-Step $steps
    } finally {
        Pop-Location
    }
    $elapsed = $timer.Elapsed
    Write-Host ''
    Write-Heading ("==> Done in {0}m{1}s ({2})." -f [int][Math]::Floor($elapsed.TotalMinutes), $elapsed.Seconds, $mode)
    if (-not $Upgrade) {
        Write-Host "    Installed packages were kept as they are; 'make upgrade' also updates them."
    }
    Write-Host @'
    Open Windows Terminal and set:
      Settings > Startup > Default profile: PowerShell (7)
      Settings > Profiles > Defaults > Appearance > Font face: MesloLGS Nerd Font
'@
}

# Dot-sourcing only defines the functions (tests/test_powershell.py)
if ($MyInvocation.InvocationName -ne '.') {
    Main -Upgrade:$Upgrade -Cloud:$Cloud -Help:$Help
}
