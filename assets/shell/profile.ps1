# PowerShell 7 profile (Windows), loaded through the $PROFILE stub written by install.py.
# Mirrors common.sh; must not print anything. Optional tools are guarded by Test-Command.

function Test-Command([string] $Name) {
    [bool](Get-Command $Name -CommandType Application -ErrorAction SilentlyContinue)
}

function Add-PathEntry([string] $Dir, [switch] $Prepend) {
    $sep = [IO.Path]::PathSeparator
    $entries = $env:PATH -split $sep
    if ($Prepend) {
        # Moves an entry already on PATH to the front, so it wins (e.g. over the Store's python)
        $env:PATH = (@($Dir) + @($entries | Where-Object { $_ -ne $Dir })) -join $sep
    } elseif ($entries -notcontains $Dir) {
        $env:PATH = "$env:PATH$sep$Dir"
    }
}

# Untracked machine-specific overrides, e.g. $env:USE_CORP_PROXY = '1' and $env:CORP_PROXY_URL
$shellLocal = Join-Path $HOME '.shell_local.ps1'
if (Test-Path $shellLocal) { . $shellLocal }

Add-PathEntry (Join-Path $HOME 'bin') -Prepend
# uv python install --default (install.ps1) puts python there
$localBin = Join-Path -Path $HOME -ChildPath '.local' -AdditionalChildPath 'bin'
if (Test-Path $localBin) { Add-PathEntry $localBin -Prepend }
$goBin = if ($env:GOBIN) { $env:GOBIN } elseif ($env:GOPATH) {
    Join-Path ($env:GOPATH -split ';')[0] 'bin'
} else { Join-Path $HOME 'go\bin' }
Add-PathEntry $goBin
# The OpenSSL Light MSI may leave its bin off PATH
if ($env:ProgramFiles -and -not (Test-Command openssl)) {
    $openSslBin = Join-Path $env:ProgramFiles 'OpenSSL-Win64\bin'
    if (Test-Path $openSslBin) { Add-PathEntry $openSslBin }
}

if ($env:USE_CORP_PROXY -eq '1' -and $env:CORP_PROXY_URL) {
    # Windows env vars are case-insensitive, so one assignment covers both spellings
    $env:HTTP_PROXY = $env:CORP_PROXY_URL
    $env:HTTPS_PROXY = $env:CORP_PROXY_URL
    $env:NO_PROXY = '127.0.0.1,localhost'
    if ($env:CORP_NO_PROXY) { $env:NO_PROXY += ",$env:CORP_NO_PROXY" }
}

if (Test-Command fd) {
    $env:FZF_DEFAULT_COMMAND = 'fd --type f --hidden --exclude .git'
    $env:FZF_CTRL_T_COMMAND = $env:FZF_DEFAULT_COMMAND
}

if (Test-Command nvim) {
    $env:VISUAL = 'nvim'
    $env:EDITOR = 'nvim'
    $env:GIT_EDITOR = 'nvim'
    Set-Alias -Name vi -Value nvim
    Set-Alias -Name vim -Value nvim
    function vimdiff { nvim -d @args }
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
    # Same as common.sh: green in place of eza's bold yellow
    $env:EZA_COLORS = 'ur=1;32:gr=32:tr=32:uu=1;32:gu=1;32:sc=1;32:bu=1;4;32'
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

# Tab completion for the optional cloud CLIs (install.ps1 -Cloud). aws_completer and terraform use
# bash's `complete -C` protocol: the command line in COMP_LINE, one candidate per output line.
foreach ($completer in @{ aws = 'aws_completer'; terraform = 'terraform' }.GetEnumerator()) {
    if (-not (Test-Command $completer.Value)) { continue }
    $completerExe = $completer.Value
    Register-ArgumentCompleter -Native -CommandName $completer.Key -ScriptBlock {
        # Native completers get the word to complete, the command AST and the cursor position
        $env:COMP_LINE = "$($args[1])".PadRight($args[2])
        $env:COMP_POINT = $args[2]
        try {
            & $completerExe | ForEach-Object {
                [Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
            }
        } finally {
            Remove-Item Env:COMP_LINE, Env:COMP_POINT -ErrorAction SilentlyContinue
        }
    }.GetNewClosure()
}

# az uses Python's argcomplete, which writes the candidates to _ARGCOMPLETE_STDOUT_FILENAME
if (Test-Command az) {
    Register-ArgumentCompleter -Native -CommandName az -ScriptBlock {
        $out = New-TemporaryFile
        $vars = @{
            _ARGCOMPLETE = '1'; _ARGCOMPLETE_SHELL = 'powershell'; _ARGCOMPLETE_IFS = "`n"
            _ARGCOMPLETE_SUPPRESS_SPACE = '0'; ARGCOMPLETE_USE_TEMPFILES = '1'
            _ARGCOMPLETE_STDOUT_FILENAME = "$out"
            COMP_LINE = "$($args[1])".PadRight($args[2]); COMP_POINT = "$($args[2])"
        }
        foreach ($name in $vars.Keys) { Set-Item "Env:$name" $vars[$name] }
        try {
            az 2>&1 | Out-Null
            Get-Content $out | Sort-Object | ForEach-Object {
                [Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
            }
        } finally {
            foreach ($name in $vars.Keys) { Remove-Item "Env:$name" -ErrorAction SilentlyContinue }
            Remove-Item $out -ErrorAction SilentlyContinue
        }
    }
}

Remove-Item Function:Add-PathEntry, Function:Test-Command
Remove-Variable shellLocal, localBin, goBin, openSslBin, completer, completerExe -ErrorAction SilentlyContinue
