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

Run these from inside the repo, where `uv` finds the project and its dependencies; `install.py` itself resolves every path from its own location, so the working directory does not change what it links. Without `--upgrade`, Go tools whose binary already exists in `$GOBIN` (default `~/go/bin`) and fonts that are already installed are skipped. With `--upgrade`, every Go tool is reinstalled at the version in `config.yaml` (`@latest`), and a font is replaced only when the latest Nerd Fonts release differs from the one recorded in its `.release` file. `bash install.sh --upgrade` and `install.ps1 -Upgrade` pass `--upgrade` through.

## Updating

Dotfiles are symlinks (stubs on Windows) into this repo, so after a `git pull` new shells pick up changed dotfiles right away. Re-run the installer (`bash install.sh`, or `install.ps1` on Windows) when the pull changes `config.yaml` or `packages/`; everything already in place is skipped.

What a re-run updates, with and without `--upgrade` (`-Upgrade` on Windows):

| Component | Plain re-run | With `--upgrade` |
| --- | --- | --- |
| Brewfile packages (macOS) | Installs missing ones, upgrades outdated ones | Same |
| apt packages (Ubuntu) | `apt-get update`, then installs missing ones and upgrades the listed ones | Same |
| winget packages (Windows) | Installs missing ones | Also upgrades installed ones, except GitHub Copilot CLI and, while `pwsh` runs, PowerShell 7 ([why](windows.md#installation)) |
| fzf, eza, delta, starship, Neovim (Ubuntu) | Installs missing ones, and replaces fzf older than 0.48 and Neovim older than 0.11 | Reinstalls the latest GitHub releases |
| Go tools | Installs those missing from `$GOBIN` | Reinstalls all at the version in `config.yaml` |
| Nerd Fonts (Linux, Windows) | Installs missing ones | Replaces fonts from an older release |
| Dotfiles | Links missing ones, replaces stale links and stubs | Same |

On macOS, shells set up by this repo export `HOMEBREW_NO_AUTO_UPDATE=1`, so `brew bundle` compares against the package index Homebrew last fetched; run `brew update` first to get the newest versions.

Neither kind of run updates the following; update them yourself:

| Component | How |
| --- | --- |
| oh-my-zsh | `omz update` (oh-my-zsh also offers updates by itself every couple of weeks) |
| Vim / Neovim plugins | `:PlugUpdate`, and `:PlugUpgrade` for vim-plug itself |
| Go in `/usr/local/go` (Ubuntu) | Usually not needed: projects get newer Go versions through `GOTOOLCHAIN`. For a newer bootstrap, `sudo rm -rf /usr/local/go` and re-run `install.sh` |
| uv (Ubuntu) | `uv self update` |
| Python patch releases | `uv python upgrade` |
| PSFzf, PSScriptAnalyzer (Windows) | `Update-PSResource PSFzf, PSScriptAnalyzer` in `pwsh` |

## GitHub API token

GitHub's API allows 60 anonymous requests per hour per IP, which a shared office NAT can exhaust. If `GITHUB_TOKEN` or `GH_TOKEN` is set, `install.sh` and `install.py` send it to `api.github.com` only (never to download hosts), e.g. `GH_TOKEN=$(gh auth token) bash install.sh`.

## Moving the repo

Symlinks (macOS, Linux) and stubs (Windows) point at absolute paths in this repo. After moving or renaming the clone, the old links break and new shells start without these settings. Re-run `uv run install.py` from the new location: it replaces stale symlinks and rewrites stubs without creating backups.

## Undo / uninstall

1. Remove the links or stubs listed under [Dotfiles Linked](#dotfiles-linked) (`rm ~/.zshrc ~/.assets ...`; on Windows, the `~/.gitconfig`, PowerShell `$PROFILE` and `%LOCALAPPDATA%\nvim\init.vim` stubs). `~/.gitconfig.local` holds your git identity; delete it only if you no longer need it.
2. Restore any backups: `install.py` renamed each file it replaced to `<file>.bak.<YYYYmmddHHMMSS>`, e.g. `mv ~/.zshrc.bak.20260101120000 ~/.zshrc`.
3. Switch the login shell back if you like: `chsh -s /bin/bash`.
4. Packages stay installed; remove them with `brew uninstall`, `apt remove` or `winget uninstall`. Everything else the installers put in place:

| OS | What | Remove with |
| --- | --- | --- |
| macOS, Linux | oh-my-zsh | `rm -rf ~/.oh-my-zsh` |
| All | Vim / Neovim plugins and Vim's undo history | `rm -rf ~/.vim` (Neovim's copy of vim-plug lives in `stdpath('data')/site/autoload`) |
| All | Go tools | Delete them from `$(go env GOPATH)/bin` |
| All | Python installed by uv | `uv python uninstall --all` |
| Linux | Nerd Fonts | `rm -rf ~/.local/share/fonts/NerdFonts && fc-cache -f` |
| Ubuntu | GitHub-release tools, and the `fd` / `bat` links to `fdfind` / `batcat` | `sudo rm /usr/local/bin/{fzf,eza,delta,starship,nvim,fd,bat}` and `sudo rm -rf /opt/nvim` |
| Ubuntu | Go bootstrap | `sudo rm -rf /usr/local/go` |
| Ubuntu | gh apt repository | `sudo rm /etc/apt/keyrings/githubcli-archive-keyring.gpg /etc/apt/sources.list.d/github-cli.list` |
| Ubuntu | uv | `rm ~/.local/bin/uv ~/.local/bin/uvx` |
| macOS, Ubuntu | zsh in `/etc/shells` | `sudoedit /etc/shells`, only if you also remove zsh |
| Windows | Nerd Fonts | Delete `%LOCALAPPDATA%\Microsoft\Windows\Fonts\NerdFonts` and the matching values under `HKCU\Software\Microsoft\Windows NT\CurrentVersion\Fonts` |
| Windows | PowerShell modules | `Uninstall-PSResource PSFzf, PSScriptAnalyzer` in `pwsh` |

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

Both files are loaded first, before `common.sh` or `profile.ps1` sets anything else. They can provide inputs such as the proxy settings above, but cannot override what is set later (`EDITOR`, `LANG`, `GIT_PAGER`, the aliases). `NO_PROXY` is always `127.0.0.1,localhost`; to add internal domains, change `network_setting` in `common.sh` (and the proxy block in `profile.ps1`).

## Git identity

`gitconfig` does not contain a user. Set it in `~/.gitconfig.local` (created by the installer, included by `~/.gitconfig`):

```ini
[user]
    name = Your Name
    email = you@example.com
```
