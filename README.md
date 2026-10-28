# App-env-installer

[![CI](https://github.com/kissofjudase23/App-env-installer/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/kissofjudase23/App-env-installer/actions/workflows/ci.yml)
[![Install (Ubuntu)](https://github.com/kissofjudase23/App-env-installer/actions/workflows/install-ubuntu.yml/badge.svg?branch=master)](https://github.com/kissofjudase23/App-env-installer/actions/workflows/install-ubuntu.yml)
[![Install (Windows)](https://github.com/kissofjudase23/App-env-installer/actions/workflows/install-windows.yml/badge.svg?branch=master)](https://github.com/kissofjudase23/App-env-installer/actions/workflows/install-windows.yml)

Automated development environment setup for **macOS**, **Ubuntu** and **Windows** (native PowerShell, or Ubuntu on WSL2). Installs CLI tools, links dotfiles, clones supporting git repos (oh-my-zsh), and configures shell/editor/terminal.

## Table of Contents
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration (`config.yaml`)](#configuration-configyaml)
- [What Gets Installed](#what-gets-installed)
- [Dotfiles Linked](#dotfiles-linked)
- [Shell Setup](#shell-setup)
- [Go](#go)
- [Terminal Setup](#terminal-setup)
- [Editor](#editor)
- [Development](#development)

## Overview

The installer is split into two stages:

1. **`install.sh`** – Detects the OS, installs system packages ([Brewfile](./Brewfile) on macOS, [apt-packages.txt](./apt-packages.txt) on Ubuntu), installs Python (version from [.python-version](./.python-version)) and dependencies with [`uv`](https://github.com/astral-sh/uv), bootstraps Go, runs `install.py`, and changes the default shell to `zsh`.
   On Windows, **`install.ps1`** does the same with [winget](./winget-packages.json) instead (no `chsh`).
2. **`install.py`** – Reads [config.yaml](./config.yaml) to link dotfiles into `$HOME` (symlinks on macOS/Linux, stub files on Windows), clone git repositories, install fonts, and install Go tools.

Both scripts are idempotent and can be re-run safely.

## Prerequisites

- macOS / Ubuntu: `git`, `curl`, `bash` / `sudo` (for Ubuntu apt installs and `/etc/shells`)
- Windows 10/11: `winget` ("App Installer", preinstalled on Windows 11) and `git` to clone this repo (`winget install Git.Git`). No admin rights or Developer Mode are required, though some winget installers ask for UAC consent.

Python (the version pinned in [.python-version](./.python-version)) is installed by `uv`; no system Python is required.

## Installation

```bash
git clone https://github.com/kissofjudase23/App-env-installer.git
cd App-env-installer
bash install.sh   # or: make install
bash install.sh --help
```

GitHub's API allows 60 anonymous requests per hour per IP, which a shared office NAT can exhaust. If `GITHUB_TOKEN` or `GH_TOKEN` is set, `install.sh` and `install.py` send it to `api.github.com` only (never to download hosts), e.g. `GH_TOKEN=$(gh auth token) bash install.sh`.

`install.sh` will:
1. Detect OS (macOS / Ubuntu).
2. macOS: install Homebrew (if missing) and run `brew bundle` with the [Brewfile](./Brewfile) (includes Nerd Fonts).
   Ubuntu: add the gh apt repo, install [apt-packages.txt](./apt-packages.txt) and the GitHub-release tools (fzf, neovim, eza, delta, starship), install `uv`, and install the latest stable Go from [go.dev](https://go.dev/dl/) into `/usr/local/go` if `go` is missing or older than 1.21.
3. Run `uv python install` (version read from [.python-version](./.python-version)) and `uv sync`.
4. Run `uv run install.py -a -y`, which:
   - Symlinks dotfiles from [assets/](./assets) into `$HOME` (existing files are backed up as `<file>.bak.<timestamp>`).
   - Creates `~/.gitconfig.local` if missing.
   - On Linux, installs the Meslo and Mononoki Nerd Fonts from the official [Nerd Fonts](https://github.com/ryanoasis/nerd-fonts) release (sha256-verified) into `~/.local/share/fonts/NerdFonts/`.
   - Clones git repos (oh-my-zsh).
   - Installs Go tools with `go install`.
5. Add `zsh` to `/etc/shells` if needed and switch your default shell to it.

### Windows

```powershell
git clone https://github.com/kissofjudase23/App-env-installer.git
cd App-env-installer
powershell -ExecutionPolicy Bypass -File .\install.ps1            # first run; later: make install
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Upgrade   # also upgrade installed packages (make upgrade)
```

`-Upgrade` skips PowerShell 7 itself while any `pwsh` window is open, because its installer cannot replace a running `pwsh`; close them and run `winget upgrade Microsoft.PowerShell` from `cmd` or Windows PowerShell.

`install.ps1` runs on the built-in Windows PowerShell 5.1 and will:
1. Run `winget import` with [winget-packages.json](./winget-packages.json): Git, PowerShell 7, GNU make, uv, Go, starship, fzf, fd, bat, delta, eza, zoxide, ripgrep, gh, jq, shfmt, shellcheck. Neovim/Vim are not installed or configured on Windows.
2. Install the PSScriptAnalyzer (for `make pslint`) and PSFzf PowerShell modules for the current user.
3. Run `uv python install`, `uv sync` and `uv run install.py -a -y`, which writes the `~/.gitconfig` and PowerShell `$PROFILE` stubs (see [Dotfiles Linked](#dotfiles-linked)), creates `~/.gitconfig.local`, installs the Meslo and Mononoki Nerd Fonts for the current user (`%LOCALAPPDATA%\Microsoft\Windows\Fonts`) and runs `go install` for the Go tools.

An existing `~/.gitconfig` is backed up as `~/.gitconfig.bak.<timestamp>`; move your `[user]` section from it into `~/.gitconfig.local`. Afterwards, set Windows Terminal's default profile to PowerShell 7 and its font to *MesloLGS Nerd Font*.

### WSL2

Ubuntu on WSL2 is a regular Ubuntu install, so the Linux steps apply unchanged:

```powershell
wsl --install -d Ubuntu-24.04
```

Then, inside Ubuntu, clone the repo into the Linux file system (e.g. `~/App-env-installer`, not under `/mnt/c`, which is slow and has no Unix permissions) and run `bash install.sh`. `install.py` detects WSL and skips the Linux font install, because Windows Terminal renders with fonts installed on the Windows side (run the native Windows install, or `uv run install.py -f` on Windows, to get them).

### Manual `install.py` usage

```bash
uv run install.py --help
uv run install.py                 # link dotfiles (default)
uv run install.py -g              # only clone git repositories
uv run install.py -f              # only install fonts (Linux, Windows)
uv run install.py -t              # only install Go tools (go install)
uv run install.py -a              # all actions
uv run install.py -a --dry-run    # print what would happen
uv run install.py -a -y           # skip confirmation prompts
```

`install.py` can be run from any directory.

## Configuration (`config.yaml`)

| Key          | Description                                                  |
| ------------ | ------------------------------------------------------------ |
| `git_repos`  | Repositories to clone (oh-my-zsh)                            |
| `dotfiles`   | Files in `assets/` to link into `$HOME`                      |
| `nerd_fonts` | Nerd Fonts release archives installed on Linux and Windows (Meslo, Mononoki) |
| `go_tools`   | Packages installed with `go install` (gopls, goimports, dlv) |

`dotfiles` and `git_repos` entries take `src` and `dst` plus optional keys:

| Key    | Description                                                                                  |
| ------ | -------------------------------------------------------------------------------------------- |
| `os`   | Subset of `[darwin, linux, windows]` the entry applies to; all when omitted                  |
| `base` | `home` (default) or `documents` (the Windows Documents folder); `dst` is relative to it      |
| `stub` | Dotfiles only: `gitconfig` or `powershell` writes a file that includes `src` instead of a symlink |

## What Gets Installed

- **macOS**: see [Brewfile](./Brewfile) (formulae, `claude` (Claude Desktop), `claude-code`, `copilot-cli`, Meslo/Mononoki Nerd Fonts).
- **Windows**: see [winget-packages.json](./winget-packages.json).
- **Ubuntu** (22.04, 24.04): see [apt-packages.txt](./apt-packages.txt). `gh` comes from the official cli.github.com apt repo and `uv` from its install script. `fzf`, `neovim` (≥ 0.11, in `/opt/nvim`), `eza`, `delta` and `starship` come from their GitHub releases, verified by sha256, because apt lacks them or ships versions that are too old. `fdfind`/`batcat` are linked as `fd`/`bat`.

Usage of eza, fd, bat and gh, and how the shell wires them together: [docs/cli-tools.md](./docs/cli-tools.md).

To add a package, edit the corresponding file and re-run `bash install.sh`.

Re-running `install.sh` skips GitHub-release tools that are already installed (and recent enough). To update them on Ubuntu, run `bash install.sh --upgrade` (or `make upgrade`), which reinstalls the latest fzf, eza, delta, starship and Neovim releases. On macOS, `brew bundle` already upgrades outdated packages, so `--upgrade` changes nothing there.

## Dotfiles Linked

On macOS and Linux, symlinks are created from this repo into `$HOME`. On Windows, `install.py` writes small **stub files** instead, which include the repo file (gitconfig `[include]`, PowerShell dot-source), so no Developer Mode or admin rights are needed and edits in the repo still apply immediately. `Documents/` is the Windows Documents folder (follows OneDrive redirection).

| Source                          | Target                                                   | OS            |
| ------------------------------- | -------------------------------------------------------- | ------------- |
| `assets/editor/vimrc.vim`       | `~/.vimrc`                                               | darwin, linux |
| `assets/editor/vimrc.vim`       | `~/.config/nvim/init.vim`                                | darwin, linux |
| `assets/shell/bash_profile.sh`  | `~/.bash_profile`                                        | darwin, linux |
| `assets/shell/bashrc.sh`        | `~/.bashrc`                                              | darwin, linux |
| `assets/shell/zshrc.zsh`        | `~/.zshrc`                                               | darwin, linux |
| `assets/starship/starship.toml` | `~/.config/starship.toml`                                | darwin, linux |
| `assets/git/gitconfig`          | `~/.gitconfig`                                           | darwin, linux |
| `assets/git/gitconfig`          | `~/.gitconfig`                                           | windows       |
| `assets/shell/profile.ps1`      | `Documents/PowerShell/Microsoft.PowerShell_profile.ps1` | windows       |
| `assets/tmux/tmux.conf`         | `~/.tmux.conf`                                           | darwin, linux |
| `assets/tig/tigrc`              | `~/.tigrc`                                               | darwin, linux |
| `assets/`                       | `~/.assets`                                              | darwin, linux |

On Windows, starship reads `assets/starship/starship.toml` through `STARSHIP_CONFIG`, set by `profile.ps1`.

## Shell Setup

- **zsh** + [oh-my-zsh](https://ohmyz.sh/), with the [starship](https://starship.rs/) prompt (also used by bash).
- oh-my-zsh plugins: `sudo`, `zsh-autosuggestions`, `zsh-syntax-highlighting`, plus `docker`, `docker-compose`, `golang`, `uv`, `gh`, `zoxide`, `tig`, `tmux`, `fzf` when their tool is installed (see [zshrc.zsh](./assets/shell/zshrc.zsh)).
- Bash and zsh share environment settings via [common.sh](./assets/shell/common.sh).
- Windows: PowerShell 7 loads [profile.ps1](./assets/shell/profile.ps1) through its `$PROFILE` stub. It mirrors `common.sh`: the same eza/bat aliases (as functions), fzf with fd/bat, `GIT_PAGER=delta`, zoxide (`z`, `j`), starship, PSReadLine history prediction, and PSFzf's `Ctrl-T` / `Ctrl-R` when installed.
- Directory jumping uses [zoxide](https://github.com/ajeetdsouza/zoxide): `z <dir>`, or `j <dir>` (alias kept for autojump habits); `zi` / `ji` pick interactively with fzf.
- The installer auto-runs `chsh -s $(which zsh)`. Restart your terminal afterwards.
- The prompt is configured in [starship.toml](./assets/starship/starship.toml) (linked to `~/.config/starship.toml`): the [starship-p10k-rainbow](https://github.com/carlosplanchon/starship-p10k-rainbow) preset with a silver OS icon (Powerlevel10k Rainbow style: one line, ANSI-256 palette; left OS · directory · git, right exit status, duration, jobs, direnv, language versions and user@host on SSH/root). To update it, copy the upstream `starship.toml` over this file, re-apply the local change noted in its header and bump the commit. bash has no right prompt unless [ble.sh](https://github.com/akinomyoga/ble.sh) is installed. Without starship, zsh falls back to the `robbyrussell` theme and bash to a plain prompt. See the [starship config docs](https://starship.rs/config/).
- Recommended font: **MesloLGS Nerd Font** (installed on both macOS and Linux); the prompt icons need a Nerd Font.

### Machine-specific settings

`assets/shell/common.sh` sources `~/.shell_local` (untracked) if it exists. Use it for per-machine settings, e.g. a corporate proxy:

```bash
# ~/.shell_local
export USE_CORP_PROXY=1
export CORP_PROXY_URL="http://proxy.example.com:8080"
```

The proxy variables (`HTTP_PROXY`, `HTTPS_PROXY`, `NO_PROXY`, in both upper and lower case) are only set when `USE_CORP_PROXY=1` and `CORP_PROXY_URL` is non-empty.

On Windows, `profile.ps1` dot-sources `~/.shell_local.ps1` instead:

```powershell
# ~/.shell_local.ps1
$env:USE_CORP_PROXY = '1'
$env:CORP_PROXY_URL = 'http://proxy.example.com:8080'
```

### Git identity

`gitconfig` does not contain a user. Set it in `~/.gitconfig.local` (created by the installer, included by `~/.gitconfig`):

```ini
[user]
    name = Your Name
    email = you@example.com
```

## Go

Go versions are managed by Go's official [toolchain mechanism](https://go.dev/doc/toolchain) (Go ≥ 1.21); no version manager (gvm/goenv) is used.

- A single bootstrap `go` is installed: `brew "go"` on macOS, the official tarball in `/usr/local/go` on Ubuntu.
- `GOTOOLCHAIN` is left at its default `auto`: inside a module, the `go` / `toolchain` lines of `go.mod` select the version, and newer toolchains are downloaded on demand into the module cache.
- Pin a project: `go get go@1.23.0` (minimum version) or `go get toolchain@go1.23.4` (preferred toolchain).
- Global override: `go env -w GOTOOLCHAIN=go1.23.4+auto` (undo with `go env -u GOTOOLCHAIN`).
- Run a one-off version: `GOTOOLCHAIN=go1.22.0 go version`.
- `${GOBIN:-${GOPATH:-~/go}/bin}` is added to `PATH` by [common.sh](./assets/shell/common.sh); the starship prompt shows the Go version inside Go projects.
- Migrating from gvm: gvm is no longer loaded; remove it with `rm -rf ~/.gvm`.

## Terminal Setup

### iTerm2 (macOS)

- **Font**: Preferences → Profiles → Text → Font → *MesloLGS Nerd Font*
- **Transparency**: if Profiles → Window → Transparency is above 0, also tick *Keep background colors opaque*, otherwise the starship blocks look darker than their arrow edges.
- **Color schemes** (bundled in [assets/iterm2_themes/](./assets/iterm2_themes)):
  - Tomorrow Night, Tomorrow Night Blue, Tomorrow Night Bright, Tomorrow Night Burns, Tomorrow Night Eighties
  - Import via: Preferences → Profiles → Colors → Color Presets → Import
- More themes: [iTerm2-Color-Schemes](https://github.com/mbadolato/iTerm2-Color-Schemes)

> Note: Homebrew has no formula for `.itermcolors` files — they must be imported through iTerm2.

### Windows Terminal

- **Font**: the native Windows install puts the Nerd Fonts in place; Settings → Profiles → Defaults → Appearance → Font face → *MesloLGS Nerd Font*
- **Default profile**: Settings → Startup → Default profile → PowerShell (7, not Windows PowerShell)
- [Color schemes for Windows Terminal](https://github.com/mbadolato/iTerm2-Color-Schemes/tree/master/windowsterminal)

## Editor

Neovim and Vim share the same config (`assets/editor/vimrc.vim`), linked to `~/.vimrc` and `~/.config/nvim/init.vim` on macOS and Linux. Windows does not install or configure them.

Vim plugins are managed by [vim-plug](https://github.com/junegunn/vim-plug), which bootstraps itself and installs plugins on first launch. Included plugins: molokai, NERDTree, ALE, vim-easy-align, ack.vim, vim-go.

Go: on Neovim ≥ 0.11, `gopls` runs through the native LSP client (with staticcheck); on Vim and older Neovim, vim-go uses `gopls` as its metalinter. ack.vim searches with `ripgrep`.

Keys: `Ctrl-h/j/k/l` move between splits, `[e` / `]e` jump between ALE problems, `F5` toggles NERDTree, `Ctrl-f` starts `:Ack`. Undo history persists across sessions (Vim: `~/.vim/undo`, Neovim: its state dir). Search is case-insensitive unless the pattern has capitals.

To manage plugins later (`:PlugClean` removes plugins dropped from the vimrc, e.g. vim-yaml):

```vim
:PlugInstall
:PlugUpdate
:PlugClean
```

## Development

This project uses `uv` for Python dependency management.

Run `make` (or `make help`) to list all targets with descriptions. On Windows, `make` (installed by `install.ps1`) runs its recipes in PowerShell 7, and `install`/`upgrade`/`check` use the Windows variants.

| Target            | Description                                                                                                  |
| ----------------- | ------------------------------------------------------------------------------------------------------------ |
| `make help`       | Default target. Lists all targets and their descriptions.                                                    |
| `make install`    | Full bootstrap via `install.sh` (Windows: `install.ps1`): OS packages, Python (from `.python-version`), `install.py -a -y`, `chsh` to zsh. Uses `sudo` and modifies `$HOME`. |
| `make sync`       | Creates/updates `.venv` with the Python deps pinned in `uv.lock` (`uv sync`).                                |
| `make lint`       | `ruff check` + `ruff format --check`; reports issues without modifying files (same as CI).                   |
| `make test`       | Runs `pytest` against a temporary `$HOME`: `install.py` unit tests, plus shell smoke tests (syntax, and `common.sh` / non-interactive bash must print nothing; skipped on Windows) and PowerShell smoke tests (`profile.ps1` must print nothing; skipped without `pwsh`). |
| `make format`     | `ruff check --fix` + `ruff format`; fixes lint issues and reformats Python code in place.                    |
| `make shfmt`      | Checks shell formatting with `shfmt` (style in `.editorconfig`); `make format-shell` rewrites in place.        |
| `make shellcheck` | Runs `shellcheck` on `install.sh`, `common.sh`, `bashrc.sh`, `bash_profile.sh` (`shellcheck` is installed by `install.sh`). |
| `make pslint`     | Runs PSScriptAnalyzer on `install.ps1` and `profile.ps1` (settings in `PSScriptAnalyzerSettings.psd1`).      |
| `make check`      | Pre-commit gate: `lint` + `test` + `shellcheck` + `shfmt` + `install.py -a -y --dry-run` (Windows: plus `pslint`). Makes no changes. |

> Running `make` with no arguments only shows help; use `make install` explicitly to bootstrap.

AI coding agents (Claude Code, GitHub Copilot): project instructions live in [AGENTS.md](AGENTS.md).

Without a local `shellcheck`, run it via `uvx --from shellcheck-py shellcheck <files>`.

To test `install.py` without touching your real home directory:

```bash
T=$(mktemp -d) && HOME=$T uv run install.py -d -y && ls -la $T; rm -rf $T
```

Python deps and tool config live in [pyproject.toml](./pyproject.toml); `uv.lock` pins versions. CI ([.github/workflows/ci.yml](./.github/workflows/ci.yml)) runs ruff, pytest and an `install.py` dry run on Ubuntu, macOS and Windows, plus shellcheck and shfmt on Ubuntu and PSScriptAnalyzer on Windows. [install-windows.yml](./.github/workflows/install-windows.yml) runs the real `install.ps1` and `install.ps1 -Upgrade` on a fresh Windows runner, followed by `make check`, on the same schedule and triggers as the Ubuntu one. [install-ubuntu.yml](./.github/workflows/install-ubuntu.yml) runs the real `install.sh` and `install.sh --upgrade` in fresh Ubuntu 22.04 and 24.04 containers weekly, on pushes to `master` and PRs that touch the install path, or on demand (Actions → Install (Ubuntu) → Run workflow). Dependabot ([.github/dependabot.yml](./.github/dependabot.yml)) keeps the actions and `uv.lock` current.