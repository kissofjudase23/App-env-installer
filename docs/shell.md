# Shell, Go and Editor

[← README](../README.md)

## Shell Setup

- **zsh** + [oh-my-zsh](https://ohmyz.sh/), with the [starship](https://starship.rs/) prompt (also used by bash).
- oh-my-zsh plugins: `sudo`, `zsh-autosuggestions`, `zsh-syntax-highlighting`, plus `docker`, `docker-compose`, `golang`, `uv`, `gh`, `zoxide`, `tig`, `tmux`, `fzf` when their tool is installed (see [zshrc.zsh](../assets/shell/zshrc.zsh)).
- Bash and zsh share environment settings via [common.sh](../assets/shell/common.sh).
- Windows: PowerShell 7 loads [profile.ps1](../assets/shell/profile.ps1) through its `$PROFILE` stub. It mirrors `common.sh`: the same eza/bat aliases (as functions), fzf with fd/bat, `GIT_PAGER=delta`, zoxide (`z`, `j`), starship, PSReadLine history prediction, and PSFzf's `Ctrl-T` / `Ctrl-R` when installed.
- Directory jumping uses [zoxide](https://github.com/ajeetdsouza/zoxide): `z <dir>`, or `j <dir>` (alias kept for autojump habits); `zi` / `ji` pick interactively with fzf.
- The installer auto-runs `chsh -s $(which zsh)`. Restart your terminal afterwards.
- The prompt is configured in [starship.toml](../assets/starship/starship.toml) (linked to `~/.config/starship.toml`): the [starship-p10k-rainbow](https://github.com/carlosplanchon/starship-p10k-rainbow) preset with a silver OS icon (Powerlevel10k Rainbow style: one line, ANSI-256 palette; left OS · directory · git, right exit status, duration, jobs, direnv, language versions and user@host on SSH/root). To update it, copy the upstream `starship.toml` over this file, re-apply the local change noted in its header and bump the commit. bash has no right prompt unless [ble.sh](https://github.com/akinomyoga/ble.sh) is installed. Without starship, zsh falls back to the `robbyrussell` theme and bash to a plain prompt. See the [starship config docs](https://starship.rs/config/).
- Recommended font: **MesloLGS Nerd Font** (installed on both macOS and Linux); the prompt icons need a Nerd Font.

Usage of eza, fd, bat, gh and the network tools, and how the shell wires them together: [cli-tools.md](cli-tools.md). Per-machine settings (proxy) and git identity: [configuration.md](configuration.md#machine-specific-settings).

## Go

Go versions are managed by Go's official [toolchain mechanism](https://go.dev/doc/toolchain) (Go ≥ 1.21); no version manager (gvm/goenv) is used.

- A single bootstrap `go` is installed: `brew "go"` on macOS, the official tarball in `/usr/local/go` on Ubuntu, winget `GoLang.Go` on Windows.
- `GOTOOLCHAIN` is left at its default `auto`: inside a module, the `go` / `toolchain` lines of `go.mod` select the version, and newer toolchains are downloaded on demand into the module cache.
- Pin a project: `go get go@1.23.0` (minimum version) or `go get toolchain@go1.23.4` (preferred toolchain).
- Global override: `go env -w GOTOOLCHAIN=go1.23.4+auto` (undo with `go env -u GOTOOLCHAIN`).
- Run a one-off version: `GOTOOLCHAIN=go1.22.0 go version`.
- `${GOBIN:-${GOPATH:-~/go}/bin}` is added to `PATH` by [common.sh](../assets/shell/common.sh); the starship prompt shows the Go version inside Go projects.
- Migrating from gvm: gvm is no longer loaded; remove it with `rm -rf ~/.gvm`.

## Editor

Neovim and Vim share the same config (`assets/editor/vimrc.vim`), linked to `~/.vimrc` and `~/.config/nvim/init.vim` on macOS and Linux. Windows installs Neovim only, loading the config through a stub at `%LOCALAPPDATA%\nvim\init.vim`.

Vim plugins are managed by [vim-plug](https://github.com/junegunn/vim-plug), which bootstraps itself and installs plugins on first launch. Included plugins: molokai, NERDTree, ALE, vim-easy-align, ack.vim, vim-go.

Go: on Neovim ≥ 0.11, `gopls` runs through the native LSP client (with staticcheck); on Vim and older Neovim, vim-go uses `gopls` as its metalinter. ack.vim searches with `ripgrep`.

Keys: `Ctrl-h/j/k/l` move between splits, `[e` / `]e` jump between ALE problems, `F5` toggles NERDTree, `Ctrl-f` starts `:Ack`. Undo history persists across sessions (Vim: `~/.vim/undo`, Neovim: its state dir). Search is case-insensitive unless the pattern has capitals.

To manage plugins later (`:PlugClean` removes plugins dropped from the vimrc, e.g. vim-yaml):

```vim
:PlugInstall
:PlugUpdate
:PlugClean
```
