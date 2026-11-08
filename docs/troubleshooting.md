# Troubleshooting

[← README](../README.md)

## `API rate limit exceeded` from GitHub

Anonymous GitHub API calls are limited to 60 per hour per IP, shared by everyone behind the same NAT. Set a token and re-run, e.g. `GH_TOKEN=$(gh auth token) bash install.sh`; see [GitHub API token](configuration.md#github-api-token).

## The prompt shows boxes or `�` instead of icons

The terminal is not using a Nerd Font. Select *MesloLGS Nerd Font* in the terminal settings: [iTerm2](macos.md#iterm2), [Windows Terminal](windows.md#windows-terminal). On WSL, the font must be installed on the Windows side (`uv run install.py -f` from the Windows checkout).

## After moving the repo, shells start without your settings

`~/.zshrc`, `~/.bashrc` and the other dotfiles are symlinks to the old path, so the shell finds nothing to load (zsh may show its new-user setup menu; press `q`). Re-run `uv run install.py` from the new location; see [Moving the repo](configuration.md#moving-the-repo).

## `git status` shows changes under `assets/shell/` you did not make

Most dotfiles in `$HOME` are symlinks into this repo, so an installer that appends to `~/.zshrc` or `~/.bash_profile` (Docker Desktop, SDKs) edits the repo file. Check with `git diff assets/`, move anything you want to keep into the untracked `~/.shell_local`, then `git checkout -- assets/`.

## `chsh` asks for a password

`install.sh` switches the login shell with `sudo chsh`, which reuses the sudo credentials of earlier steps; if they have expired, sudo asks once more. It runs only when your login shell is not zsh yet.

## Windows: `install.ps1 -Upgrade` fails while replacing a font

A newer Nerd Fonts release is replaced in `%LOCALAPPDATA%\Microsoft\Windows\Fonts\NerdFonts`, and Windows keeps fonts open while an application uses them. Close Windows Terminal (run the upgrade from Windows PowerShell or `cmd`) and re-run it.

## Text copied in tmux does not reach the clipboard

tmux sends copies to the terminal with OSC 52. Windows Terminal accepts them by default; in iTerm2, enable [clipboard access](macos.md#iterm2). Over ssh, the terminal on your local machine must allow it.
