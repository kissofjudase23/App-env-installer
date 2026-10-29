# macOS

[← README](../README.md)

## Prerequisites

`git`, `curl` and `bash` (all preinstalled). Homebrew is installed by `install.sh` if missing.
Python (the version pinned in [.python-version](../.python-version)) is installed by `uv`; no
system Python is required.

## Installation

```bash
git clone https://github.com/kissofjudase23/App-env-installer.git
cd App-env-installer
bash install.sh   # or: make install
bash install.sh --help
```

GitHub's API allows 60 anonymous requests per hour per IP, which a shared office NAT can exhaust. If `GITHUB_TOKEN` or `GH_TOKEN` is set, `install.sh` and `install.py` send it to `api.github.com` only (never to download hosts), e.g. `GH_TOKEN=$(gh auth token) bash install.sh`.

`install.sh` will:
1. Install Homebrew (if missing) and run `brew bundle` with the [Brewfile](../packages/Brewfile) (includes Nerd Fonts).
2. Run `uv python install` (version read from [.python-version](../.python-version)) and `uv sync`.
3. Run `uv run install.py -a -y`, which:
   - Symlinks dotfiles from [assets/](../assets) into `$HOME` (existing files are backed up as `<file>.bak.<timestamp>`).
   - Creates `~/.gitconfig.local` if missing.
   - Clones git repos (oh-my-zsh).
   - Installs Go tools with `go install`.
4. Add `zsh` to `/etc/shells` if needed and switch your default shell to it.

Both stages are idempotent and can be re-run safely. See [configuration.md](configuration.md) for what gets linked and how to run `install.py` by hand.

## What Gets Installed

See [packages/Brewfile](../packages/Brewfile): formulae, `claude` (Claude Desktop), `claude-code`, `copilot-cli`, Meslo/Mononoki Nerd Fonts. Go is the Homebrew `go` formula (see [shell.md](shell.md#go)).

`curl`, `openssl` (LibreSSL), `nc` and `dig` ship with macOS, so they are not in the Brewfile (Homebrew's `curl` is keg-only and would not be on `PATH`). Usage: [cli-tools.md](cli-tools.md#network-tools).

To add a package, edit the Brewfile and re-run `bash install.sh`. `brew bundle` already upgrades outdated packages, so `--upgrade` changes nothing on macOS.

## iTerm2

- **Font**: Preferences → Profiles → Text → Font → *MesloLGS Nerd Font*
- **Transparency**: if Profiles → Window → Transparency is above 0, also tick *Keep background colors opaque*, otherwise the starship blocks look darker than their arrow edges.
- **Color schemes** (bundled in [assets/iterm2_themes/](../assets/iterm2_themes)):
  - Tomorrow Night, Tomorrow Night Blue, Tomorrow Night Bright, Tomorrow Night Burns, Tomorrow Night Eighties
  - Import via: Preferences → Profiles → Colors → Color Presets → Import
- More themes: [iTerm2-Color-Schemes](https://github.com/mbadolato/iTerm2-Color-Schemes)

> Note: Homebrew has no formula for `.itermcolors` files — they must be imported through iTerm2.

## Next steps

- Set your git identity in `~/.gitconfig.local` ([configuration.md](configuration.md#git-identity)).
- Restart the terminal so zsh and the starship prompt load ([shell.md](shell.md)).
