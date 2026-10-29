# App-env-installer

[![CI](https://github.com/kissofjudase23/App-env-installer/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/kissofjudase23/App-env-installer/actions/workflows/ci.yml)
[![Install (Ubuntu)](https://github.com/kissofjudase23/App-env-installer/actions/workflows/install-ubuntu.yml/badge.svg?branch=master)](https://github.com/kissofjudase23/App-env-installer/actions/workflows/install-ubuntu.yml)
[![Install (Windows)](https://github.com/kissofjudase23/App-env-installer/actions/workflows/install-windows.yml/badge.svg?branch=master)](https://github.com/kissofjudase23/App-env-installer/actions/workflows/install-windows.yml)

Automated development environment setup for **macOS**, **Ubuntu** and **Windows** (native PowerShell, or Ubuntu on WSL2). Installs CLI tools, links dotfiles, clones supporting git repos (oh-my-zsh), and configures shell/editor/terminal.

## Pick your OS

| OS | Guide | Installer | Packages |
| --- | --- | --- | --- |
| macOS | [docs/macos.md](docs/macos.md) | `bash install.sh` | [packages/Brewfile](packages/Brewfile) |
| Ubuntu 22.04 / 24.04, WSL2 | [docs/ubuntu.md](docs/ubuntu.md) | `bash install.sh` | [packages/apt-packages.txt](packages/apt-packages.txt) |
| Windows 10 / 11 | [docs/windows.md](docs/windows.md) | `install.ps1` | [packages/winget-packages.json](packages/winget-packages.json) |

## Quick start

macOS / Ubuntu / WSL2:

```bash
git clone https://github.com/kissofjudase23/App-env-installer.git
cd App-env-installer
bash install.sh
```

Windows:

```powershell
git clone https://github.com/kissofjudase23/App-env-installer.git
cd App-env-installer
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

## How it works

1. **`install.sh`** (macOS/Ubuntu) or **`install.ps1`** (Windows) installs the OS packages from [packages/](packages), installs Python (version from [.python-version](.python-version)) and dependencies with [`uv`](https://github.com/astral-sh/uv), bootstraps Go, then runs `install.py`. On macOS/Ubuntu it also switches the default shell to `zsh`.
2. **`install.py`** reads [config.yaml](config.yaml) to link dotfiles into `$HOME` (symlinks on macOS/Linux, stub files on Windows), clone git repositories, install fonts, and install Go tools.

Both stages are idempotent and can be re-run safely.

## Documentation

- [Configuration](docs/configuration.md) – `config.yaml`, dotfiles linked, manual `install.py` usage, per-machine settings, git identity
- [Shell, Go and Editor](docs/shell.md) – zsh/oh-my-zsh, starship, PowerShell profile, Go toolchains, Vim/Neovim
- [CLI tools](docs/cli-tools.md) – eza, fd, bat, ripgrep, fzf, zoxide, delta, jq, gh, network tools
- [Development](docs/development.md) – make targets, tests, CI

AI coding agents (Claude Code, GitHub Copilot): project instructions live in [AGENTS.md](AGENTS.md).
