# Troubleshooting

[← README](../README.md)

## GitHub API rate limit (`returned error: 403` / `HTTP Error 403`)

Anonymous GitHub API calls are limited to 60 per hour per IP, shared by everyone behind the same NAT. When the limit is hit, `install.sh` stops with `curl: (22) The requested URL returned error: 403` (or `429`) and `install.py` with `error: HTTP Error 403: ...`. Set a token and re-run, e.g. `GH_TOKEN=$(gh auth token) bash install.sh`; see [GitHub API token](configuration.md#github-api-token).

## The prompt shows boxes or `�` instead of icons

The terminal is not using a Nerd Font. Select *MesloLGS Nerd Font* in the terminal settings: [iTerm2](macos.md#iterm2), [Windows Terminal](windows.md#windows-terminal). On WSL, the font must be installed on the Windows side (`uv run install.py -f` from the Windows checkout).

## zsh starts without oh-my-zsh plugins or completions

`~/.oh-my-zsh` is missing: `uv run install.py` without flags only links the dotfiles, or the clone failed. `zshrc.zsh` then skips oh-my-zsh instead of failing. Clone it with `uv run install.py -g` and open a new shell.

## After moving the repo, shells start without your settings

`~/.zshrc`, `~/.bashrc` and the other dotfiles are symlinks to the old path, so the shell finds nothing to load (zsh may show its new-user setup menu; press `q`). Re-run `uv run install.py` from the new location; see [Moving the repo](configuration.md#moving-the-repo).

## `git status` shows changes under `assets/shell/` you did not make

Most dotfiles in `$HOME` are symlinks into this repo, so an installer that appends to `~/.zshrc` or `~/.bash_profile` (Docker Desktop, SDKs) edits the repo file. Check with `git diff assets/`, move anything you want to keep into the untracked `~/.shell_local`, then `git checkout -- assets/`.

## `chsh` asks for a password

`install.sh` switches the login shell with `sudo chsh`, which reuses the sudo credentials of earlier steps; if they have expired, sudo asks once more. It runs only when your login shell is not zsh yet.

## tmux still opens bash after the switch to zsh

`tmux.conf` starts panes with `$SHELL`, which keeps the old login shell until you log in again, and a running tmux server keeps the environment it started with. Log out and back in (a new ssh session is enough), stop the old server with `tmux kill-server`, then start tmux again.

## Vim or Neovim shows errors on the first launch

The first launch downloads vim-plug from GitHub with `curl` and then runs `:PlugInstall`. Offline, or behind a proxy that is not configured yet ([Machine-specific settings](configuration.md#machine-specific-settings)), the download fails. Fix the network and restart the editor: the download is retried as long as `plug.vim` is missing (`~/.vim/autoload/plug.vim`; Neovim: `stdpath('data')/site/autoload/plug.vim`).

## Windows: `install.ps1 -Upgrade` fails while replacing a font

A newer Nerd Fonts release is replaced in `%LOCALAPPDATA%\Microsoft\Windows\Fonts\NerdFonts`, and Windows keeps fonts open while an application uses them. Close Windows Terminal (run the upgrade from Windows PowerShell or `cmd`) and re-run it.

## Text copied in tmux does not reach the clipboard

tmux sends copies to the terminal with OSC 52. Windows Terminal accepts them by default; in iTerm2, enable [clipboard access](macos.md#iterm2). Over ssh, the terminal on your local machine must allow it.
