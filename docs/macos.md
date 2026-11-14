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

Behind a shared office NAT, set a [GitHub API token](configuration.md#github-api-token) to avoid the anonymous rate limit.

`install.sh` will:
1. Install Homebrew (if missing) and run `brew bundle` with the [Brewfile](../packages/Brewfile) (includes Nerd Fonts).
2. Run `uv python install --default` (version read from [.python-version](../.python-version); new shells get `python3` from uv through `~/.local/bin`), `uv sync` and `uv run install.py -a -y` ([what it does](../README.md#how-it-works)).
3. Add `zsh` to `/etc/shells` if needed and switch your login shell to it (`sudo chsh`).

Both stages are idempotent and can be re-run safely. See [configuration.md](configuration.md) for what gets linked and how to run `install.py` by hand.

## What Gets Installed

See [packages/Brewfile](../packages/Brewfile): formulae, `claude` (Claude Desktop), `claude-code`, `copilot-cli`, Meslo/Mononoki Nerd Fonts. Go is the Homebrew `go` formula (see [shell.md](shell.md#go)).

`curl`, `openssl` (LibreSSL), `nc` and `dig` ship with macOS, so they are not in the Brewfile (Homebrew's `curl` is keg-only and would not be on `PATH`). Usage: [cli-tools.md](cli-tools.md#network-tools).

To add a package, edit the Brewfile and re-run `bash install.sh`, which only installs what is missing. `bash install.sh --upgrade` (or `make upgrade`) runs `brew update`, upgrades outdated Brewfile packages and reinstalls the Go tools ([what each run updates](configuration.md#updating)).

## iTerm2

- **Font**: Preferences → Profiles → Text → Font → *MesloLGS Nerd Font*
- **Clipboard**: tick Preferences → General → Selection → *Applications in terminal may access clipboard*, so text copied in tmux (`y` in copy mode, or a mouse selection) reaches the macOS clipboard.
- **Transparency**: if Profiles → Window → Transparency is above 0, also tick *Keep background colors opaque*, otherwise the starship blocks look darker than their arrow edges.
- **Color schemes** (bundled in [assets/iterm2_themes/](../assets/iterm2_themes)):
  - Tomorrow Night, Tomorrow Night Blue, Tomorrow Night Bright, Tomorrow Night Burns, Tomorrow Night Eighties
  - Import via: Preferences → Profiles → Colors → Color Presets → Import
- More themes: [iTerm2-Color-Schemes](https://github.com/mbadolato/iTerm2-Color-Schemes)

> Note: Homebrew has no formula for `.itermcolors` files — they must be imported through iTerm2.

## Next steps

- Set your git identity in `~/.gitconfig.local` ([configuration.md](configuration.md#git-identity)).
- Restart the terminal so zsh and the starship prompt load ([shell.md](shell.md)).
