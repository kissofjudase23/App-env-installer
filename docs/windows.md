# Windows (native PowerShell 7)

[← README](../README.md)

For a Linux environment on Windows, use [WSL2](ubuntu.md#wsl2) instead; it follows the Ubuntu guide.

## Prerequisites

Windows 10/11 with `winget` ("App Installer", preinstalled on Windows 11) and `git` to clone this repo (`winget install Git.Git`). No admin rights or Developer Mode are required, though some winget installers ask for UAC consent. Python (the version pinned in [.python-version](../.python-version)) is installed by `uv`.

## Installation

```powershell
git clone https://github.com/kissofjudase23/App-env-installer.git
cd App-env-installer
powershell -ExecutionPolicy Bypass -File .\install.ps1            # first run; later: make install
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Upgrade   # also upgrade installed packages (make upgrade)
```

`-Upgrade` skips PowerShell 7 itself while any `pwsh` window is open, because its installer cannot replace a running `pwsh`; close them and run `winget upgrade Microsoft.PowerShell` from `cmd` or Windows PowerShell.

GitHub's API allows 60 anonymous requests per hour per IP; if `GITHUB_TOKEN` or `GH_TOKEN` is set, `install.py` sends it to `api.github.com` only.

`install.ps1` runs on the built-in Windows PowerShell 5.1 and will:
1. Run `winget import` with [packages/winget-packages.json](../packages/winget-packages.json).
2. Install the PSScriptAnalyzer (for `make pslint`) and PSFzf PowerShell modules for the current user.
3. Run `uv python install`, `uv sync` and `uv run install.py -a -y`, which writes the `~/.gitconfig`, PowerShell `$PROFILE` and Neovim `init.vim` stubs (see [Dotfiles Linked](configuration.md#dotfiles-linked)), creates `~/.gitconfig.local`, installs the Meslo and Mononoki Nerd Fonts for the current user (`%LOCALAPPDATA%\Microsoft\Windows\Fonts`) and runs `go install` for the Go tools.

An existing `~/.gitconfig` is backed up as `~/.gitconfig.bak.<timestamp>`; move your `[user]` section from it into `~/.gitconfig.local`.

Dotfiles are stub files pointing at absolute paths in this repo, so moving the repo means re-running `install.ps1` (or `uv run install.py`).

## What Gets Installed

[packages/winget-packages.json](../packages/winget-packages.json): Git, PowerShell 7, GNU make, uv, Go, Neovim, starship, fzf, fd, bat, delta, eza, zoxide, ripgrep, gh, jq, OpenSSL, shfmt, shellcheck, Claude Code (`claude`), GitHub Copilot CLI (`copilot`). Vim is not installed or configured on Windows.

Neovim reads the shared [vimrc.vim](../assets/editor/vimrc.vim) through `%LOCALAPPDATA%\nvim\init.vim`. The first launch installs vim-plug and the plugins, as on the other systems ([details](shell.md)). `t<Enter>` opens a `pwsh` terminal, and `:!` runs in `cmd.exe`, Neovim's default on Windows.

zoxide works in PowerShell 7: `profile.ps1` sets up `z` / `j` (and `zi` / `ji`) when it is installed.

Network tools: `curl.exe` ships with Windows 10+ (PowerShell 7 has no `curl` alias, so `curl` runs it). `openssl` comes from the OpenSSL Light package; `profile.ps1` adds `C:\Program Files\OpenSSL-Win64\bin` to `PATH` if the installer did not. There is no maintained winget package for `nc` or `dig`; use the built-in equivalents:

```powershell
Test-NetConnection example.com -Port 443   # nc -vz example.com 443
Resolve-DnsName example.com                # dig example.com
Resolve-DnsName example.com -Type MX -Server 1.1.1.1
```

To add a package, add its ID (check with `winget show --id <id> --exact`) to winget-packages.json and re-run `install.ps1`.

## Shell

PowerShell 7 loads [profile.ps1](../assets/shell/profile.ps1) through its `$PROFILE` stub. It mirrors `common.sh`: the same eza/bat aliases (as functions), `vi`/`vim`/`vimdiff` and `EDITOR` for Neovim, fzf with fd/bat, `GIT_PAGER=delta`, zoxide (`z`, `j`), starship, PSReadLine history prediction, and PSFzf's `Ctrl-T` / `Ctrl-R` when installed. starship reads [starship.toml](../assets/starship/starship.toml) through `STARSHIP_CONFIG`, set by `profile.ps1`.

Machine-specific settings go in `~/.shell_local.ps1` (untracked), which `profile.ps1` dot-sources:

```powershell
# ~/.shell_local.ps1
$env:USE_CORP_PROXY = '1'
$env:CORP_PROXY_URL = 'http://proxy.example.com:8080'
```

## Windows Terminal

- **Font**: the native Windows install puts the Nerd Fonts in place; Settings → Profiles → Defaults → Appearance → Font face → *MesloLGS Nerd Font*. Without a Nerd Font the prompt falls back to Cascadia, which has the powerline arrows but shows `�` for the OS logo and other icons. A font set on a single profile overrides Defaults.
- **Default profile**: Settings → Startup → Default profile → PowerShell (7, not Windows PowerShell)
- [Color schemes for Windows Terminal](https://github.com/mbadolato/iTerm2-Color-Schemes/tree/master/windowsterminal)

## Next steps

- Set your git identity in `~/.gitconfig.local` ([configuration.md](configuration.md#git-identity)).
- Open a new PowerShell 7 window so the profile loads.
