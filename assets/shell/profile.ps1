# PowerShell 7 profile (Windows), loaded through the $PROFILE stub written by install.py.
# Mirrors common.sh; must not print anything. Optional tools are guarded by Test-Command.

function Test-Command([string] $Name) {
    [bool](Get-Command $Name -CommandType Application -ErrorAction SilentlyContinue)
}

function Add-PathEntry([string] $Dir, [switch] $Prepend) {
    $entries = $env:PATH -split [IO.Path]::PathSeparator
    if ($entries -contains $Dir) { return }
    $env:PATH = if ($Prepend) { "$Dir;$env:PATH" } else { "$env:PATH;$Dir" }
}

# Untracked machine-specific overrides, e.g. $env:USE_CORP_PROXY = '1' and $env:CORP_PROXY_URL
$shellLocal = Join-Path $HOME '.shell_local.ps1'
if (Test-Path $shellLocal) { . $shellLocal }

Add-PathEntry (Join-Path $HOME 'bin') -Prepend
$goBin = if ($env:GOBIN) { $env:GOBIN } elseif ($env:GOPATH) {
    Join-Path ($env:GOPATH -split ';')[0] 'bin'
} else { Join-Path $HOME 'go\bin' }
Add-PathEntry $goBin

if ($env:USE_CORP_PROXY -eq '1' -and $env:CORP_PROXY_URL) {
    # Windows env vars are case-insensitive, so one assignment covers both spellings
    $env:HTTP_PROXY = $env:CORP_PROXY_URL
    $env:HTTPS_PROXY = $env:CORP_PROXY_URL
    $env:NO_PROXY = '127.0.0.1,localhost'
}

if (Test-Command fd) {
    $env:FZF_DEFAULT_COMMAND = 'fd --type f --hidden --exclude .git'
    $env:FZF_CTRL_T_COMMAND = $env:FZF_DEFAULT_COMMAND
    $env:FZF_ALT_C_COMMAND = 'fd --type d --hidden --exclude .git'
}

# Set here rather than core.pager so git still works where delta is missing
if (Test-Command delta) { $env:GIT_PAGER = 'delta' }

# Built-in ls/cat aliases win over functions, so drop them first; Get-ChildItem stays available
if (Test-Command eza) {
    Remove-Item Alias:ls -Force -ErrorAction SilentlyContinue
    function ls { eza --group-directories-first @args }
    function l { eza -F --group-directories-first @args }
    function la { eza -a --group-directories-first @args }
    function ll { eza -al --git --group-directories-first @args }
    function lt { eza --tree --level=2 --group-directories-first @args }
    function lta { eza -a --tree --level=2 --ignore-glob=.git --group-directories-first @args }
    function lm { eza -al --git --sort=modified @args }
    function lS { eza -al --sort=size @args }
    function ld { eza -lD @args }
}

if (Test-Command bat) {
    Remove-Item Alias:cat -Force -ErrorAction SilentlyContinue
    function cat { bat --paging=never @args }
    $env:FZF_CTRL_T_OPTS = "--preview 'bat --color=always --style=numbers --line-range=:300 {}'"
}

if (Get-Module -ListAvailable PSReadLine) {
    Set-PSReadLineOption -EditMode Emacs -HistorySearchCursorMovesToEnd
    # Prediction needs a VT-capable console; skip it when output is redirected
    if (-not [Console]::IsOutputRedirected) {
        Set-PSReadLineOption -PredictionSource History
    }
}

if ((Test-Command fzf) -and (Get-Module -ListAvailable PSFzf)) {
    Import-Module PSFzf
    Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
}

# The repo file directly; Windows has no ~/.config/starship.toml link
$env:STARSHIP_CONFIG = Join-Path $PSScriptRoot '..\starship\starship.toml' -Resolve -ErrorAction SilentlyContinue
if (Test-Command starship) {
    Invoke-Expression (& starship init powershell)
}

if (Test-Command zoxide) {
    Invoke-Expression (& zoxide init powershell | Out-String)
    Set-Alias -Name j -Value z
    Set-Alias -Name ji -Value zi
}

Remove-Item Function:Add-PathEntry, Function:Test-Command
Remove-Variable shellLocal, goBin
