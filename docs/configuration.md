# Configuration

[← README](../README.md)

## `config.yaml`

[config.yaml](../config.yaml) drives `install.py`:

| Key          | Description                                                  |
| ------------ | ------------------------------------------------------------ |
| `git_repos`  | Repositories to clone (oh-my-zsh)                            |
| `dotfiles`   | Files in `assets/` to link into `$HOME`                      |
| `nerd_fonts` | Nerd Fonts release archives installed on Linux and Windows (Meslo, Mononoki) |
| `go_tools`   | Packages installed with `go install` (gopls, goimports, dlv, yq, actionlint) |

`dotfiles` and `git_repos` entries take `src` and `dst` plus optional keys:

| Key    | Description                                                                                  |
| ------ | -------------------------------------------------------------------------------------------- |
| `os`   | Subset of `[darwin, linux, windows]` the entry applies to; all when omitted                  |
| `base` | `home` (default), `documents` (the Windows Documents folder) or `local_app_data` (`%LOCALAPPDATA%`); `dst` is relative to it |
| `stub` | Dotfiles only: `gitconfig`, `powershell` or `vim` writes a file that includes `src` instead of a symlink |

OS packages live in [packages/](../packages): [Brewfile](../packages/Brewfile) (macOS), [apt-packages.txt](../packages/apt-packages.txt) (Ubuntu), [winget-packages.json](../packages/winget-packages.json) (Windows).

## Dotfiles Linked

On macOS and Linux, symlinks are created from this repo into `$HOME`. On Windows, `install.py` writes small **stub files** instead, which include the repo file (gitconfig `[include]`, PowerShell dot-source, Vimscript `source`), so no Developer Mode or admin rights are needed and edits in the repo still apply immediately. `Documents/` is the Windows Documents folder (follows OneDrive redirection).

| Source                          | Target                                                   | OS            |
| ------------------------------- | -------------------------------------------------------- | ------------- |
| `assets/editor/vimrc.vim`       | `~/.vimrc`                                               | darwin, linux |
| `assets/editor/vimrc.vim`       | `~/.config/nvim/init.vim`                                | darwin, linux |
| `assets/editor/vimrc.vim`       | `%LOCALAPPDATA%/nvim/init.vim`                           | windows       |
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

## Manual `install.py` usage

```bash
uv run install.py --help
uv run install.py                 # link dotfiles (default)
uv run install.py -g              # only clone git repositories
uv run install.py -f              # only install fonts (Linux, Windows)
uv run install.py -t              # only install Go tools (go install)
uv run install.py -a              # all actions
uv run install.py -a --dry-run    # print what would happen
uv run install.py -a -y           # skip confirmation prompts
uv run install.py -a --upgrade    # also reinstall Go tools and update Nerd Fonts
```

`install.py` can be run from any directory. Without `--upgrade`, Go tools whose binary already exists in `$GOBIN` (default `~/go/bin`) and fonts that are already installed are skipped. With `--upgrade`, every Go tool is reinstalled at the version in `config.yaml` (`@latest`), and a font is replaced only when the latest Nerd Fonts release differs from the one recorded in its `.release` file. `bash install.sh --upgrade` and `install.ps1 -Upgrade` pass `--upgrade` through.

## GitHub API token

GitHub's API allows 60 anonymous requests per hour per IP, which a shared office NAT can exhaust. If `GITHUB_TOKEN` or `GH_TOKEN` is set, `install.sh` and `install.py` send it to `api.github.com` only (never to download hosts), e.g. `GH_TOKEN=$(gh auth token) bash install.sh`.

## Moving the repo

Symlinks (macOS, Linux) and stubs (Windows) point at absolute paths in this repo. After moving or renaming the clone, the old links break and new shells start without these settings. Re-run `uv run install.py` from the new location: it replaces stale symlinks and rewrites stubs without creating backups.

## Undo / uninstall

1. Remove the links or stubs listed under [Dotfiles Linked](#dotfiles-linked) (`rm ~/.zshrc ~/.assets ...`).
2. Restore any backups: `install.py` renamed each file it replaced to `<file>.bak.<YYYYmmddHHMMSS>`, e.g. `mv ~/.zshrc.bak.20260101120000 ~/.zshrc`.
3. Switch the login shell back if you like: `chsh -s /bin/bash`.
4. Packages, fonts, Go tools and `~/.oh-my-zsh` stay installed; remove them with your package manager or `rm -rf`.

## Machine-specific settings

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

## Git identity

`gitconfig` does not contain a user. Set it in `~/.gitconfig.local` (created by the installer, included by `~/.gitconfig`):

```ini
[user]
    name = Your Name
    email = you@example.com
```
