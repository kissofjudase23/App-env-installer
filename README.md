# App-env-installer

Automated development environment setup for **macOS** and **Ubuntu**. Installs CLI tools, links dotfiles, clones supporting git repos (oh-my-zsh, Powerlevel10k), and configures shell/editor/terminal.

## Table of Contents
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration (`config.yaml`)](#configuration-configyaml)
- [What Gets Installed](#what-gets-installed)
- [Dotfiles Linked](#dotfiles-linked)
- [Shell Setup](#shell-setup)
- [Terminal Setup](#terminal-setup)
- [Editor](#editor)
- [Development](#development)

## Overview

The installer is split into two stages:

1. **`install.sh`** – Detects the OS, installs system packages ([Brewfile](./Brewfile) on macOS, [apt-packages.txt](./apt-packages.txt) on Ubuntu), installs Python 3.15 and dependencies with [`uv`](https://github.com/astral-sh/uv), runs `install.py`, and changes the default shell to `zsh`.
2. **`install.py`** – Reads [config.yaml](./config.yaml) to symlink dotfiles into `$HOME`, clone git repositories, and install fonts.

Both scripts are idempotent and can be re-run safely.

## Prerequisites

- `git`, `curl`
- `bash` / `sudo` (for Ubuntu apt installs and `/etc/shells`)

Python (>= 3.15) is installed by `uv`; no system Python is required.

## Installation

```bash
git clone <this-repo> App-env-installer
cd App-env-installer
bash install.sh
```

`install.sh` will:
1. Detect OS (macOS / Ubuntu).
2. macOS: install Homebrew (if missing) and run `brew bundle` with the [Brewfile](./Brewfile) (includes Nerd Fonts).
   Ubuntu: add the neovim PPA, install [apt-packages.txt](./apt-packages.txt), and install `uv`.
3. Run `uv python install 3.15` and `uv sync`.
4. Run `uv run install.py -a -y`, which:
   - Symlinks dotfiles from [assets/](./assets) into `$HOME` (existing files are backed up as `<file>.bak.<timestamp>`).
   - Creates `~/.gitconfig.local` if missing.
   - On Linux, installs MesloLGS NF fonts.
   - Clones git repos (oh-my-zsh, Powerlevel10k).
5. Add `zsh` to `/etc/shells` if needed and switch your default shell to it.

### Manual `install.py` usage

```bash
uv run install.py --help
uv run install.py                 # link dotfiles (default)
uv run install.py -g              # only clone git repositories
uv run install.py -f              # only install fonts (Linux)
uv run install.py -a              # all actions
uv run install.py -a --dry-run    # print what would happen
uv run install.py -a -y           # skip confirmation prompts
```

`install.py` can be run from any directory.

## Configuration (`config.yaml`)

| Key         | Description                                              |
| ----------- | -------------------------------------------------------- |
| `git_repos` | Repositories to clone (oh-my-zsh, Powerlevel10k)         |
| `dotfiles`  | Files in `assets/` to symlink into `$HOME`               |

## What Gets Installed

- **macOS**: see [Brewfile](./Brewfile) (formulae, `copilot-cli`, Meslo/Mononoki Nerd Fonts).
- **Ubuntu**: see [apt-packages.txt](./apt-packages.txt); `neovim` comes from `ppa:neovim-ppa/stable`, `uv` from the official install script.

To add a package, edit the corresponding file and re-run `bash install.sh`.

## Dotfiles Linked

Symlinks created from this repo into `$HOME`:

| Source                         | Target                    |
| ------------------------------ | ------------------------- |
| `assets/editor/vimrc.vim`      | `~/.vimrc`                |
| `assets/editor/vimrc.vim`      | `~/.config/nvim/init.vim` |
| `assets/shell/bash_profile.sh` | `~/.bash_profile`         |
| `assets/shell/bashrc.sh`       | `~/.bashrc`               |
| `assets/shell/zshrc.zsh`       | `~/.zshrc`                |
| `assets/shell/p10k.zsh`        | `~/.p10k.zsh`             |
| `assets/git/gitconfig`         | `~/.gitconfig`            |
| `assets/tmux/tmux.conf`        | `~/.tmux.conf`            |
| `assets/tig/tigrc`             | `~/.tigrc`                |
| `assets/screen/screenrc`       | `~/.screenrc`             |
| `assets/`                      | `~/.assets`               |

## Shell Setup

- **zsh** + [oh-my-zsh](https://ohmyz.sh/) + [Powerlevel10k](https://github.com/romkatv/powerlevel10k) theme.
- The installer auto-runs `chsh -s $(which zsh)`.
- After install, restart your terminal. P10k will start a configuration wizard on first launch (or run `p10k configure`).
- Recommended font: **Meslo Nerd Font** (installed by the installer on both macOS and Linux). See [Powerlevel10k fonts](https://github.com/romkatv/powerlevel10k?tab=readme-ov-file#fonts).

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

Vim plugins are managed by [vim-plug](https://github.com/junegunn/vim-plug), which bootstraps itself and installs plugins on first launch. To manage plugins later:

```vim
:PlugInstall
:PlugUpdate
:PlugClean
```

## Development

This project uses `uv` for Python dependency management.

```bash
make sync        # uv sync
make lint        # ruff check + ruff format --check
make format      # ruff check --fix + ruff format
make shellcheck  # shellcheck install.sh and shell dotfiles
make check       # lint + shellcheck + install.py dry run
```

Python deps and tool config live in [pyproject.toml](./pyproject.toml); `uv.lock` pins versions. CI runs the same checks on Ubuntu and macOS ([.github/workflows/ci.yml](./.github/workflows/ci.yml)).