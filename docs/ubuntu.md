# Ubuntu (22.04, 24.04) and WSL2

[← README](../README.md)

## Prerequisites

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

GitHub's API allows 60 anonymous requests per hour per IP, which a shared office NAT can exhaust. If `GITHUB_TOKEN` or `GH_TOKEN` is set, `install.sh` and `install.py` send it to `api.github.com` only (never to download hosts), e.g. `GH_TOKEN=$(gh auth token) bash install.sh`.

`install.sh` will:
1. Add the gh apt repo, install [apt-packages.txt](../packages/apt-packages.txt) and the GitHub-release tools (fzf, neovim, eza, delta, starship), install `uv`, and install the latest stable Go from [go.dev](https://go.dev/dl/) into `/usr/local/go` if `go` is missing or older than 1.21.
2. Run `uv python install` (version read from [.python-version](../.python-version)) and `uv sync`.
3. Run `uv run install.py -a -y`, which:
   - Symlinks dotfiles from [assets/](../assets) into `$HOME` (existing files are backed up as `<file>.bak.<timestamp>`).
   - Creates `~/.gitconfig.local` if missing.
   - Installs the Meslo and Mononoki Nerd Fonts from the official [Nerd Fonts](https://github.com/ryanoasis/nerd-fonts) release (sha256-verified) into `~/.local/share/fonts/NerdFonts/`.
   - Clones git repos (oh-my-zsh).
   - Installs Go tools with `go install`.
4. Add `zsh` to `/etc/shells` if needed and switch your default shell to it.

Both stages are idempotent and can be re-run safely. See [configuration.md](configuration.md) for what gets linked and how to run `install.py` by hand.

## What Gets Installed

See [packages/apt-packages.txt](../packages/apt-packages.txt). `gh` comes from the official cli.github.com apt repo and `uv` from its install script. `fzf`, `neovim` (≥ 0.11, in `/opt/nvim`), `eza`, `delta` and `starship` come from their GitHub releases, verified by sha256, because apt lacks them or ships versions that are too old. `fdfind`/`batcat` are linked as `fd`/`bat`.

Network tools: `curl`, `openssl`, `nc` (`netcat-openbsd`) and `dig` (`bind9-dnsutils`); usage in [cli-tools.md](cli-tools.md#network-tools).

To add a package, edit apt-packages.txt and re-run `bash install.sh`.

Re-running `install.sh` skips GitHub-release tools that are already installed (and recent enough). To update them, run `bash install.sh --upgrade` (or `make upgrade`), which reinstalls the latest fzf, eza, delta, starship and Neovim releases.

## WSL2

Ubuntu on WSL2 is a regular Ubuntu install, so the steps above apply unchanged:

```powershell
wsl --install -d Ubuntu-24.04
```

Then, inside Ubuntu, clone the repo into the Linux file system (e.g. `~/App-env-installer`, not under `/mnt/c`, which is slow and has no Unix permissions) and run `bash install.sh`. `install.py` detects WSL and skips the Linux font install, because Windows Terminal renders with fonts installed on the Windows side (run the native [Windows install](windows.md), or `uv run install.py -f` on Windows, to get them).

## Next steps

- Set your git identity in `~/.gitconfig.local` ([configuration.md](configuration.md#git-identity)).
- Restart the terminal so zsh and the starship prompt load ([shell.md](shell.md)); use a Nerd Font (*MesloLGS Nerd Font*) in your terminal emulator.
