# App-env-installer – Agent Instructions

Dotfiles + dev-environment bootstrapper for **macOS** and **Ubuntu** only.

## Architecture

Two-stage install:

1. [install.sh](install.sh) (bash, `set -Eeuo pipefail`) – detects OS, installs system packages, installs Python (version from [.python-version](.python-version)) + deps via `uv`, bootstraps Go (Ubuntu: go.dev tarball → `/usr/local/go` if missing or < 1.21; macOS: Brewfile), runs `install.py -a -y`, then `chsh` to zsh.
2. [install.py](install.py) (click CLI) – reads [config.yaml](config.yaml) and:
   - `link_dotfiles` – symlinks `assets/*` into `$HOME`; skips correct links; backs up real files to `<dst>.bak.<YYYYmmddHHMMSS>`.
   - `ensure_gitconfig_local` – creates a commented placeholder `~/.gitconfig.local` (never overwrites).
   - `install_fonts` – Linux only (MesloLGS NF + `fc-cache`); macOS fonts come from the Brewfile.
   - `clone_git_repos` – skips when `dst/.git` exists.
   - `install_go_tools` – `go install` each `go_tools` entry; skips with a warning if `go` is missing.
   - Flags: `-d` (default), `-g`, `-f`, `-t`, `-a`, `-y`, `--dry-run`. Every side effect must honor `dry_run`.
   - All paths resolve from `ROOT = Path(__file__).resolve().parent`; never rely on cwd.

## Where things live

| Change | Edit |
|---|---|
| macOS packages / casks / fonts | [Brewfile](Brewfile) |
| Ubuntu packages | [apt-packages.txt](apt-packages.txt) (`#` comments allowed) |
| Dotfile symlinks, git repos to clone | [config.yaml](config.yaml) (`src` relative to repo, `dst` relative to `$HOME`) |
| Python deps, ruff config | [pyproject.toml](pyproject.toml) (`uv` project, `package = false`) |
| Python interpreter version | [.python-version](.python-version) – single source of truth; `install.sh` and CI call bare `uv python install`. Bump `requires-python` in [pyproject.toml](pyproject.toml) only if the floor changes. |
| Go version | Go's official toolchain (`GOTOOLCHAIN=auto`, per-project `go.mod` `go`/`toolchain` lines). Only a bootstrap `go` is installed; no gvm/goenv. |
| Go tools (`go install`) | `go_tools` in [config.yaml](config.yaml) |
| Shared bash+zsh env | [assets/shell/common.sh](assets/shell/common.sh) |
| bash / zsh specific | [bashrc.sh](assets/shell/bashrc.sh), [bash_profile.sh](assets/shell/bash_profile.sh), [zshrc.zsh](assets/shell/zshrc.zsh) |
| vim + nvim (shared config, vim-plug) | [assets/editor/vimrc.vim](assets/editor/vimrc.vim) |
| git | [assets/git/gitconfig](assets/git/gitconfig) |
| Agent instructions (all tools) | this file, [AGENTS.md](AGENTS.md) |
| Tool-specific agent config | [CLAUDE.md](CLAUDE.md) + [.claude/settings.json](.claude/settings.json) (Claude Code), [.vscode/settings.json](.vscode/settings.json) (Copilot in VS Code) |

Untracked, per-machine files (never commit their contents): `~/.shell_local` (e.g. `USE_CORP_PROXY=1`, `CORP_PROXY_URL`), `~/.gitconfig.local` (git `[user]`).

## Critical gotchas

- `~/.assets` is a symlink to this repo's `assets/`, and most dotfiles in `$HOME` are symlinks into it. **Editing or deleting files under `assets/` immediately affects the user's live shell/git/vim.** Never leave them missing or broken.
- `common.sh` is sourced by **both bash and zsh** and runs after the p10k instant prompt: keep it POSIX-ish/bash+zsh compatible and **never print output**.
- Use `${HOMEBREW_PREFIX}` (set by `brew_env`) instead of hardcoded `/usr/local` or `/opt/homebrew`.
- Do not hardcode user names, home paths, emails, or proxy addresses.
- When adding a dotfile, update both `config.yaml` and the "Dotfiles Linked" table in [README.md](README.md).

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

Never run `install.sh` or `make install` for testing (they use sudo, brew/apt, and chsh).

## Conventions

- Docs and code comments in English; comments only for non-obvious intent, one line.
- Python ≥ 3.15, ruff rules `E,F,I,B,UP,SIM`, line length 100.
- Shell dotfiles start with a `# shellcheck shell=bash` directive.
- CI ([.github/workflows/ci.yml](.github/workflows/ci.yml)) runs ruff and the dry run on ubuntu + macos; shellcheck runs on ubuntu only.
- Commit messages (all agents): follow [.github/instructions/copilot-commit-message-instructions.md](.github/instructions/copilot-commit-message-instructions.md).
