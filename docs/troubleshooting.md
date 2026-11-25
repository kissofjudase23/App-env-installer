# Troubleshooting

[← README](../README.md)

## Finding the step that failed

`install.sh` and `install.ps1` print their steps up front, then each one under a `==> [i/N] <step>` heading; `install.py` numbers its own actions as `--> [i/N] <action>`. When a step fails, the error names it (`Error: step [3/7] Bootstrap Go failed`). Scroll up to that heading for the output of the failing command. Headings are colored only on a terminal; set `NO_COLOR=1` to turn the colors off there too.

## GitHub API rate limit (`returned error: 403` / `HTTP Error 403`)

Anonymous GitHub API calls are limited to 60 per hour per IP, shared by everyone behind the same NAT. When the limit is hit, `install.sh` stops with `curl: (22) The requested URL returned error: 403` (or `429`) and `install.py` with `error: HTTP Error 403: ...`. Set a token and re-run, e.g. `GH_TOKEN=$(gh auth token) bash install.sh`; see [GitHub API token](configuration.md#github-api-token).

## The prompt shows boxes or `�` instead of icons

The terminal is not using a Nerd Font. Select *MesloLGS Nerd Font* in the terminal settings: [iTerm2](macos.md#iterm2), [Windows Terminal](windows.md#windows-terminal). On WSL, the font must be installed on the Windows side (`uv run install.py -f` from the Windows checkout).

## zsh starts without oh-my-zsh plugins or completions

`~/.oh-my-zsh` is missing: `uv run install.py` without flags only links the dotfiles, or the clone failed. `zshrc.zsh` then skips oh-my-zsh instead of failing. Clone it with `uv run install.py -g` and open a new shell.

## After moving the repo, shells start without your settings

`~/.zshrc`, `~/.bashrc` and the other dotfiles are symlinks to the old path, so the shell finds nothing to load (zsh may show its new-user setup menu; press `q`). Re-run `uv run install.py` from the new location; see [Moving the repo](configuration.md#moving-the-repo).

## `git status` shows changes under `assets/` you did not make

Most dotfiles in `$HOME` are symlinks into this repo, so an installer that appends to `~/.zshrc` or `~/.bash_profile` (Docker Desktop, SDKs) edits the repo file. Check with `git diff assets/`, move anything you want to keep into the untracked `~/.shell_local`, then `git checkout -- assets/`.

`git config --global` does the same: it writes through the `~/.gitconfig` link into `assets/git/gitconfig`, so a `git config --global user.email ...` would end up in a commit. Keep such settings in the untracked `~/.gitconfig.local` instead, e.g. `git config --file ~/.gitconfig.local user.email you@example.com`. On Windows, `git config --global` writes into the `~/.gitconfig` stub, which the next `install.py` run backs up and replaces.

## `chsh` asks for a password

`install.sh` switches the login shell with `sudo chsh`, which reuses the sudo credentials of earlier steps; if they have expired, sudo asks once more. It runs only when your login shell differs from the first `zsh` on `PATH`; on macOS that is Homebrew's zsh, so a login shell of `/bin/zsh` is switched too.

## tmux still opens bash after the switch to zsh

`tmux.conf` starts panes with `$SHELL`, which keeps the old login shell until you log in again, and a running tmux server keeps the environment it started with. Log out and back in (a new ssh session is enough), stop the old server with `tmux kill-server`, then start tmux again.

## Vim or Neovim shows errors on the first launch

The first launch downloads vim-plug from GitHub with `curl` and then runs `:PlugInstall`. Offline, or behind a proxy that is not configured yet ([Machine-specific settings](configuration.md#machine-specific-settings)), the download fails. Fix the network and restart the editor: the download is retried as long as `plug.vim` is missing (`~/.vim/autoload/plug.vim`; Neovim: `stdpath('data')/site/autoload/plug.vim`).

## `apt-get update` fails with `Conflicting values set for option Signed-By`

An apt repo that `install.sh --cloud` adds was set up by hand before, with another keyring: typically `/etc/apt/sources.list.d/azure-cli.sources` from Microsoft's instructions. Remove that file, keep the `.list` file `install.sh` wrote, and re-run. (`google-cloud-sdk.list` and `hashicorp.list` are overwritten, since `install.sh` uses the same names as the vendors' instructions.)

## Windows: `install.ps1 -Upgrade` fails while replacing a font

A newer Nerd Fonts release is replaced in `%LOCALAPPDATA%\Microsoft\Windows\Fonts\NerdFonts`, and Windows keeps fonts open while an application uses them. Close Windows Terminal (run the upgrade from Windows PowerShell or `cmd`) and re-run it.

## Text copied in tmux does not reach the clipboard

tmux sends copies to the terminal with OSC 52. Windows Terminal accepts them by default; in iTerm2, enable [clipboard access](macos.md#iterm2). Over ssh, the terminal on your local machine must allow it.
