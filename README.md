# App-env-installer

Automated development environment setup for **macOS** and **Ubuntu**. Installs CLI tools, links dotfiles, clones supporting git repos (oh-my-zsh), and configures shell/editor/terminal.

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
2. **`install.py`** – Reads [config.yaml](./config.yaml) to symlink dotfiles into `$HOME`, clone git repositories, install fonts, and install Go tools.

Both scripts are idempotent and can be re-run safely.

## Prerequisites

- `git`, `curl`
- `bash` / `sudo` (for Ubuntu apt installs and `/etc/shells`)

Python (the version pinned in [.python-version](./.python-version)) is installed by `uv`; no system Python is required.

## Installation

```bash
git clone <this-repo> App-env-installer
cd App-env-installer
bash install.sh   # or: make install
```

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

### Manual `install.py` usage

```bash
uv run install.py --help
uv run install.py                 # link dotfiles (default)
uv run install.py -g              # only clone git repositories
uv run install.py -f              # only install fonts (Linux)
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
| `dotfiles`   | Files in `assets/` to symlink into `$HOME`                   |
| `nerd_fonts` | Nerd Fonts release archives installed on Linux (Meslo, Mononoki) |
| `go_tools`   | Packages installed with `go install` (gopls, goimports, dlv) |

## What Gets Installed

- **macOS**: see [Brewfile](./Brewfile) (formulae, `claude` (Claude Desktop), `claude-code`, `copilot-cli`, Meslo/Mononoki Nerd Fonts).
- **Ubuntu** (22.04, 24.04): see [apt-packages.txt](./apt-packages.txt). `gh` comes from the official cli.github.com apt repo and `uv` from its install script. `fzf`, `neovim` (≥ 0.11, in `/opt/nvim`), `eza`, `delta` and `starship` come from their GitHub releases, verified by sha256, because apt lacks them or ships versions that are too old. `fdfind`/`batcat` are linked as `fd`/`bat`.

Usage of eza, fd, bat and gh, and how the shell wires them together: [docs/cli-tools.md](./docs/cli-tools.md).

To add a package, edit the corresponding file and re-run `bash install.sh`.

## Dotfiles Linked

Symlinks created from this repo into `$HOME`:

| Source                          | Target                    |
| ------------------------------- | ------------------------- |
| `assets/editor/vimrc.vim`       | `~/.vimrc`                |
| `assets/editor/vimrc.vim`       | `~/.config/nvim/init.vim` |
| `assets/shell/bash_profile.sh`  | `~/.bash_profile`         |
| `assets/shell/bashrc.sh`        | `~/.bashrc`               |
| `assets/shell/zshrc.zsh`        | `~/.zshrc`                |
| `assets/starship/starship.toml` | `~/.config/starship.toml` |
| `assets/git/gitconfig`          | `~/.gitconfig`            |
| `assets/tmux/tmux.conf`         | `~/.tmux.conf`            |
| `assets/tig/tigrc`              | `~/.tigrc`                |
| `assets/screen/screenrc`        | `~/.screenrc`             |
| `assets/`                       | `~/.assets`               |

## Shell Setup

- **zsh** + [oh-my-zsh](https://ohmyz.sh/), with the [starship](https://starship.rs/) prompt (also used by bash).
- oh-my-zsh plugins: `sudo`, `zsh-autosuggestions`, `zsh-syntax-highlighting`, plus `docker`, `docker-compose`, `golang`, `uv`, `gh`, `zoxide`, `tig`, `tmux`, `fzf` when their tool is installed (see [zshrc.zsh](./assets/shell/zshrc.zsh)).
- Bash and zsh share environment settings via [common.sh](./assets/shell/common.sh).
- Directory jumping uses [zoxide](https://github.com/ajeetdsouza/zoxide): `z <dir>`, or `j <dir>` (alias kept for autojump habits); `zi` / `ji` pick interactively with fzf.
- The installer auto-runs `chsh -s $(which zsh)`. Restart your terminal afterwards.
- The prompt is configured in [starship.toml](./assets/starship/starship.toml) (linked to `~/.config/starship.toml`): a two-line powerline layout with OS, directory and git on the left, and command duration, jobs, virtualenv, Go version and user@host (root/SSH only) on the right. Without starship, zsh falls back to the `robbyrussell` theme and bash to a plain prompt. See the [starship config docs](https://starship.rs/config/).
- Recommended font: **MesloLGS Nerd Font** (installed on both macOS and Linux); the prompt icons need a Nerd Font.

### Machine-specific settings

`assets/shell/common.sh` sources `~/.shell_local` (untracked) if it exists. Use it for per-machine settings, e.g. a corporate proxy:

```bash
# ~/.shell_local
export USE_CORP_PROXY=1
export CORP_PROXY_URL="http://proxy.example.com:8080"
```

The proxy variables (`HTTP_PROXY`, `HTTPS_PROXY`, `no_proxy`) are only set when `USE_CORP_PROXY=1` and `CORP_PROXY_URL` is non-empty.

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
- **Color schemes** (bundled in [assets/iterm2_themes/](./assets/iterm2_themes)):
  - Tomorrow Night, Tomorrow Night Blue, Tomorrow Night Bright, Tomorrow Night Burns, Tomorrow Night Eighties
  - Import via: Preferences → Profiles → Colors → Color Presets → Import
- More themes: [iTerm2-Color-Schemes](https://github.com/mbadolato/iTerm2-Color-Schemes)

> Note: Homebrew has no formula for `.itermcolors` files — they must be imported through iTerm2.

### Windows Terminal

- Install Nerd Fonts via [chocolatey](https://github.com/ryanoasis/nerd-fonts?tab=readme-ov-file#option-3-unofficial-chocolatey-or-scoop-repositories) or [manual](https://medium.com/@vedantkadam541/beautify-your-windows-terminal-using-nerd-fonts-and-oh-my-posh-4f4393f097)
- Settings → Profile → Appearance → Font Face
- [Color schemes for Windows Terminal](https://github.com/mbadolato/iTerm2-Color-Schemes/tree/master/windowsterminal)

## Editor

Neovim and Vim share the same config (`assets/editor/vimrc.vim`), linked to `~/.vimrc` and `~/.config/nvim/init.vim`.

Vim plugins are managed by [vim-plug](https://github.com/junegunn/vim-plug), which bootstraps itself and installs plugins on first launch. Included plugins: molokai, NERDTree, ALE, vim-easy-align, ack.vim, vim-go, vim-yaml.

Go: on Neovim ≥ 0.11, `gopls` runs through the native LSP client (with staticcheck); on Vim and older Neovim, vim-go uses `gopls` as its metalinter. ack.vim searches with `ripgrep`.

To manage plugins later:

```vim
:PlugInstall
:PlugUpdate
:PlugClean
```

## Development

This project uses `uv` for Python dependency management.

Run `make` (or `make help`) to list all targets with descriptions.

| Target            | Description                                                                                                  |
| ----------------- | ------------------------------------------------------------------------------------------------------------ |
| `make help`       | Default target. Lists all targets and their descriptions.                                                    |
| `make install`    | Full bootstrap via `install.sh`: OS packages, Python (from `.python-version`), `install.py -a -y`, `chsh` to zsh. Uses `sudo` and modifies `$HOME`. |
| `make sync`       | Creates/updates `.venv` with the Python deps pinned in `uv.lock` (`uv sync`).                                |
| `make lint`       | `ruff check` + `ruff format --check`; reports issues without modifying files (same as CI).                   |
| `make test`       | Runs `install.py` unit tests with `pytest` against a temporary `$HOME`.                                     |
| `make format`     | `ruff check --fix` + `ruff format`; fixes lint issues and reformats Python code in place.                    |
| `make shfmt`      | Checks shell formatting with `shfmt` (style in `.editorconfig`); `make format-shell` rewrites in place.        |
| `make shellcheck` | Runs `shellcheck` on `install.sh`, `common.sh`, `bashrc.sh`, `bash_profile.sh` (`shellcheck` is installed by `install.sh`). |
| `make check`      | Pre-commit gate: `lint` + `test` + `shellcheck` + `shfmt` + `install.py -a -y --dry-run`. Makes no changes.  |

> Running `make` with no arguments only shows help; use `make install` explicitly to bootstrap.

AI coding agents (Claude Code, GitHub Copilot): project instructions live in [AGENTS.md](AGENTS.md).

Without a local `shellcheck`, run it via `uvx --from shellcheck-py shellcheck <files>`.

To test `install.py` without touching your real home directory:

```bash
T=$(mktemp -d) && HOME=$T uv run install.py -d -y && ls -la $T; rm -rf $T
```

Python deps and tool config live in [pyproject.toml](./pyproject.toml); `uv.lock` pins versions. CI ([.github/workflows/ci.yml](./.github/workflows/ci.yml)) runs ruff and an `install.py` dry run on Ubuntu and macOS, plus shellcheck on Ubuntu.