# Ubuntu (24.04, 26.04) and WSL2

[← README](../README.md)

## Prerequisites

Ubuntu 24.04 or 26.04 (`install.sh` refuses older releases; both are tested in CI), with
`git`, `curl`, `bash` and `sudo` (for apt installs and `/etc/shells`). Python (the version
pinned in [.python-version](../.python-version)) is installed by `uv`; no system Python is
required.

## Installation

```bash
git clone https://github.com/kissofjudase23/App-env-installer.git
cd App-env-installer
bash install.sh   # or: make install
bash install.sh --help
```

Behind a shared office NAT, set a [GitHub API token](configuration.md#github-api-token) to avoid the anonymous rate limit.

`install.sh` will:
1. Add the gh apt repo, install [apt-packages.txt](../packages/apt-packages.txt) and the GitHub-release tools (fzf, neovim, eza, delta, starship), install `uv` into `~/.local/bin` (without letting its installer edit your shell rc files), and install the latest stable Go from [go.dev](https://go.dev/dl/) into `/usr/local/go` if `go` is missing or older than 1.21.
2. Run `uv python install --default` (version read from [.python-version](../.python-version); new shells get `python3` from uv through `~/.local/bin`), `uv sync` and `uv run install.py -a -y` ([what it does](../README.md#how-it-works); fonts go to `~/.local/share/fonts/NerdFonts/`).
3. Add `zsh` to `/etc/shells` if needed and switch your login shell to it (`sudo chsh`).

Both stages are idempotent and can be re-run safely. See [configuration.md](configuration.md) for what gets linked and how to run `install.py` by hand.

## What Gets Installed

See [packages/apt-packages.txt](../packages/apt-packages.txt), which includes `make` for the [make targets](development.md). `gh` comes from the official cli.github.com apt repo and `uv` from its install script. `fzf`, `neovim` (≥ 0.11, in `/opt/nvim`), `eza`, `delta` and `starship` come from their GitHub releases, verified by sha256, because apt lacks them or ships versions that are too old. `fdfind`/`batcat` are linked as `fd`/`bat`.

Network tools: `curl`, `openssl`, `nc` (`netcat-openbsd`) and `dig` (`bind9-dnsutils`); usage in [cli-tools.md](cli-tools.md#network-tools).

To add a package, edit apt-packages.txt and re-run `bash install.sh`.

Re-running `install.sh` skips GitHub-release tools, Go tools and Nerd Fonts that are already installed (and recent enough). To update them, run `bash install.sh --upgrade` (or `make upgrade`), which reinstalls the latest fzf, eza, delta, starship and Neovim releases and the Go tools, and replaces fonts from an older Nerd Fonts release ([details](configuration.md#manual-installpy-usage)).

## WSL2

Ubuntu on WSL2 is a regular Ubuntu install, so the steps above apply unchanged:

```powershell
wsl --install -d Ubuntu-26.04   # or Ubuntu-24.04; `wsl --list --online` shows the names
```

Then, inside Ubuntu, clone the repo into the Linux file system (e.g. `~/App-env-installer`, not under `/mnt/c`, which is slow and has no Unix permissions) and run `bash install.sh`. `install.py` detects WSL and skips the Linux font install, because Windows Terminal renders with fonts installed on the Windows side (run the native [Windows install](windows.md), or `uv run install.py -f` on Windows, to get them).

## Next steps

- Set your git identity in `~/.gitconfig.local` ([configuration.md](configuration.md#git-identity)).
- Restart the terminal so zsh and the starship prompt load ([shell.md](shell.md)); use a Nerd Font (*MesloLGS Nerd Font*) in your terminal emulator.
