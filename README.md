# App-env-installer

Automated development environment setup for **macOS** and **Ubuntu**. Installs CLI tools, links dotfiles, clones supporting git repos (oh-my-zsh, Powerlevel10k, Vundle), and configures shell/editor/terminal.

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

1. **`install.sh`** – Detects the OS, installs system packages (`brew` on macOS, `apt` on Ubuntu), bootstraps a Python virtualenv with [`uv`](https://github.com/astral-sh/uv), and changes the default shell to `zsh`.
2. **`install.py`** – Reads [config.yaml](./config.yaml) to clone git repositories and symlink dotfiles into `$HOME`.

## Prerequisites

- `git`
- `python3` (>= 3.14, see [pyproject.toml](./pyproject.toml))
- `bash` / `sudo` (for Ubuntu apt installs)

## Installation

```bash
git clone <this-repo> App-env-installer
cd App-env-installer
bash install.sh
```

`install.sh` will:
1. Detect OS (macOS / Ubuntu).
2. Install Homebrew (if missing) and brew packages, or apt packages.
3. Install [Nerd Fonts](https://www.nerdfonts.com/) on macOS (`font-meslo-lg-nerd-font`, `font-mononoki-nerd-font`).
4. Install [`uv`](https://github.com/astral-sh/uv) and create a `.venv`.
5. Run `uv run python install.py -a`, which:
   - Symlinks dotfiles from [assets/](./assets) into `$HOME`.
   - Clones git repos (oh-my-zsh, Powerlevel10k, Vundle).
   - On Linux, installs Powerline fonts.
6. Switch your default shell to `zsh`.

### Manual `install.py` usage

```bash
uv run python install.py --help
uv run python install.py -a       # install all (dotfiles + repos + fonts)
uv run python install.py -g       # only clone git repositories
```

## Configuration (`config.yaml`)

| Key         | Description                                              |
| ----------- | -------------------------------------------------------- |
| `git_repos` | Repositories to clone (Vundle, oh-my-zsh, Powerlevel10k) |
| `dotfiles`  | Files in `assets/` to symlink into `$HOME`               |

## What Gets Installed

### macOS (Homebrew)
`the_silver_searcher` (ag), `autojump`, `bash-completion`, `ctop`, `fzf`, `git`, `jq`, `tmux`, `make`, `pyenv`, `pyenv-virtualenv`, `neovim`, `tree`, `tig`, `zsh`, `gron`, `uv`, `copilot-cli`

**Casks (fonts):** `font-meslo-lg-nerd-font`, `font-mononoki-nerd-font`

### Ubuntu (apt)
`silversearcher-ag`, `autojump`, `curl`, `fontconfig`, `fzf`, `git`, `jq`, `tmux`, `tree`, `tig`, `language-pack-en`, `neovim` (via `ppa:neovim-ppa/stable`), `zsh`

`uv` is installed via the official install script.

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
| `assets/`                      | `~/.assets`               |

## Shell Setup

- **zsh** + [oh-my-zsh](https://ohmyz.sh/) + [Powerlevel10k](https://github.com/romkatv/powerlevel10k) theme.
- The installer auto-runs `chsh -s $(which zsh)`.
- After install, restart your terminal. P10k will start a configuration wizard on first launch (or run `p10k configure`).
- Recommended font: **Meslo Nerd Font** (already installed on macOS via brew cask). See [Powerlevel10k fonts](https://github.com/romkatv/powerlevel10k?tab=readme-ov-file#fonts).

## Terminal Setup

### iTerm2 (macOS)

- **Font**: Preferences → Profiles → Text → Font → *MesloLGS Nerd Font*
- **Color schemes** (bundled in [assets/item2_themes/](./assets/item2_themes)):
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

Vim plugins are managed by [Vundle](https://github.com/VundleVim/Vundle.vim) (cloned automatically). To install plugins:

```vim
:PluginInstall
```

## Development

This project uses `uv` for Python dependency management.

```bash
make lint     # flake8 install.py
make format   # black install.py
```

Python deps are listed in [requirements](./requirements); project metadata in [pyproject.toml](./pyproject.toml).