# App-env-installer – Agent Instructions

Dotfiles + dev-environment bootstrapper for **macOS** and **Ubuntu** only.

## Architecture

Two-stage install:

1. [install.sh](../install.sh) (bash, `set -Eeuo pipefail`) – detects OS, installs system packages, installs Python 3.15 + deps via `uv`, runs `install.py -a -y`, then `chsh` to zsh.
2. [install.py](../install.py) (click CLI) – reads [config.yaml](../config.yaml) and:
   - `link_dotfiles` – symlinks `assets/*` into `$HOME`; skips correct links; backs up real files to `<dst>.bak.<YYYYmmddHHMMSS>`.
   - `ensure_gitconfig_local` – creates a commented placeholder `~/.gitconfig.local` (never overwrites).
   - `install_fonts` – Linux only (MesloLGS NF + `fc-cache`); macOS fonts come from the Brewfile.
   - `clone_git_repos` – skips when `dst/.git` exists.
   - Flags: `-d` (default), `-g`, `-f`, `-a`, `-y`, `--dry-run`. Every side effect must honor `dry_run`.
   - All paths resolve from `ROOT = Path(__file__).resolve().parent`; never rely on cwd.

## Where things live

| Change | Edit |
|---|---|
| macOS packages / casks / fonts | [Brewfile](../Brewfile) |
| Ubuntu packages | [apt-packages.txt](../apt-packages.txt) (`#` comments allowed) |
| Dotfile symlinks, git repos to clone | [config.yaml](../config.yaml) (`src` relative to repo, `dst` relative to `$HOME`) |
| Python deps, ruff config, Python version | [pyproject.toml](../pyproject.toml) (`uv` project, `package = false`) |
| Shared bash+zsh env | [assets/shell/common.sh](../assets/shell/common.sh) |
| bash / zsh specific | [bashrc.sh](../assets/shell/bashrc.sh), [bash_profile.sh](../assets/shell/bash_profile.sh), [zshrc.zsh](../assets/shell/zshrc.zsh) |
| vim + nvim (shared config, vim-plug) | [assets/editor/vimrc.vim](../assets/editor/vimrc.vim) |
| git | [assets/git/gitconfig](../assets/git/gitconfig) |

Untracked, per-machine files (never commit their contents): `~/.shell_local` (e.g. `USE_CORP_PROXY=1`, `CORP_PROXY_URL`), `~/.gitconfig.local` (git `[user]`).

## Critical gotchas

- `~/.assets` is a symlink to this repo's `assets/`, and most dotfiles in `$HOME` are symlinks into it. **Editing or deleting files under `assets/` immediately affects the user's live shell/git/vim.** Never leave them missing or broken.
- `common.sh` is sourced by **both bash and zsh** and runs after the p10k instant prompt: keep it POSIX-ish/bash+zsh compatible and **never print output**.
- Use `${HOMEBREW_PREFIX}` (set by `brew_env`) instead of hardcoded `/usr/local` or `/opt/homebrew`.
- Do not hardcode user names, home paths, emails, or proxy addresses.
- When adding a dotfile, update both `config.yaml` and the "Dotfiles Linked" table in [README.md](../README.md).

## Commands

```bash
make sync        # uv sync
make lint        # ruff check + ruff format --check
make format      # ruff check --fix + ruff format
make shellcheck  # needs shellcheck; or: uvx --from shellcheck-py shellcheck <files>
make check       # lint + shellcheck + install.py -a -y --dry-run
```

Safe testing of `install.py` without touching the real home:

```bash
T=$(mktemp -d) && HOME=$T uv run install.py -d -y && ls -la $T; rm -rf $T
```

Never run `install.sh` for testing (it uses sudo, brew/apt, and chsh).

## Conventions

- Docs and code comments in English; comments only for non-obvious intent, one line.
- Python ≥ 3.15, ruff rules `E,F,I,B,UP,SIM`, line length 100.
- Shell dotfiles start with a `# shellcheck shell=bash` directive.
- CI ([.github/workflows/ci.yml](workflows/ci.yml)) runs ruff, shellcheck, and a dry run on ubuntu + macos.
- Commit messages: see [instructions/copilot-commit-message-instructions.md](instructions/copilot-commit-message-instructions.md).
