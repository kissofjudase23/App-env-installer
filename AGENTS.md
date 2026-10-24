# App-env-installer – Agent Instructions

Dotfiles + dev-environment bootstrapper for **macOS** and **Ubuntu** only.

## Architecture

Two-stage install:

1. [install.sh](install.sh) (bash, `set -Eeuo pipefail`) – detects OS, installs system packages, installs Python (version from [.python-version](.python-version)) + deps via `uv`, bootstraps Go (Ubuntu: go.dev tarball → `/usr/local/go` if missing or < 1.21; macOS: Brewfile) and, on Ubuntu (22.04 + 24.04), adds the gh apt repo, links `fdfind`/`batcat` as `fd`/`bat`, and installs fzf (< 0.48), eza, delta, starship (→ `/usr/local/bin`) and neovim (< 0.11 → `/opt/nvim`) from GitHub releases (`--upgrade` reinstalls them even when present), runs `install.py -a -y`, then `chsh` to zsh.
2. [install.py](install.py) (click CLI) – reads [config.yaml](config.yaml) (validated on load: unknown keys, missing dotfile `src`, `dst` outside `$HOME` or duplicated → `InstallerError`) and:
   - `link_dotfiles` – symlinks `assets/*` into `$HOME`; skips correct links; backs up real files to `<dst>.bak.<YYYYmmddHHMMSS>`.
   - `ensure_gitconfig_local` – creates a commented placeholder `~/.gitconfig.local` (never overwrites).
   - `install_fonts` – Linux only: `nerd_fonts` archives from the latest ryanoasis/nerd-fonts release (sha256 digest checked, `.ttf` only) → `~/.local/share/fonts/NerdFonts/<name>`, then `fc-cache`; macOS fonts come from the Brewfile.
   - `clone_git_repos` – skips when `dst/.git` exists.
   - `install_go_tools` – `go install` each `go_tools` entry; skips with a warning if `go` is missing.
   - Flags: `-d` (default), `-g`, `-f`, `-t`, `-a`, `-y`, `--dry-run`. Every side effect must honor `dry_run`.
   - All paths resolve from `ROOT = Path(__file__).resolve().parent`; never rely on cwd.

For any new GitHub-hosted binary on Ubuntu, reuse `github_release_asset` / `install_github_binary` in `install.sh` (they verify the sha256 digest from the GitHub API); call them directly, not inside `$(...)`, and guard them with `keep_installed` so `--upgrade` works. GitHub API calls go through `github_api` (shell) / `fetch` (Python), which add `GITHUB_TOKEN`/`GH_TOKEN` for `api.github.com` only; never print or log the token. `install.sh` runs `main` only when executed, so tests can `source` it.

## Where things live

| Change | Edit |
|---|---|
| macOS packages / casks / fonts | [Brewfile](Brewfile) |
| Ubuntu packages | [apt-packages.txt](apt-packages.txt) (`#` comments allowed) |
| Dotfile symlinks, git repos to clone, Linux Nerd Fonts | [config.yaml](config.yaml) (`src` relative to repo, `dst` relative to `$HOME`) |
| `install.py` tests | [tests/](tests/) (pytest; `Installer` takes `home`/`ConfigMgr` so tests use `tmp_path`, never the real `$HOME`) |
| Shell dotfile smoke tests | [tests/test_shell.py](tests/test_shell.py) (clean `bash --norc` / `zsh -f`, temp `$HOME`; skipped when the shell is missing) |
| Python deps, ruff config | [pyproject.toml](pyproject.toml) (`uv` project, `package = false`) |
| Python interpreter version | [.python-version](.python-version) – single source of truth; `install.sh` and CI call bare `uv python install`. Bump `requires-python` in [pyproject.toml](pyproject.toml) only if the floor changes. |
| Go version | Go's official toolchain (`GOTOOLCHAIN=auto`, per-project `go.mod` `go`/`toolchain` lines). Only a bootstrap `go` is installed; no gvm/goenv. |
| Go tools (`go install`) | `go_tools` in [config.yaml](config.yaml) |
| CLI tool usage docs | [docs/cli-tools.md](docs/cli-tools.md) – update when tool integrations in `common.sh` change |
| Shell formatting style | [.editorconfig](.editorconfig) (read by shfmt) |
| Shared bash+zsh env | [assets/shell/common.sh](assets/shell/common.sh) |
| Prompt (zsh + bash) | [assets/starship/starship.toml](assets/starship/starship.toml) |
| bash / zsh specific | [bashrc.sh](assets/shell/bashrc.sh), [bash_profile.sh](assets/shell/bash_profile.sh), [zshrc.zsh](assets/shell/zshrc.zsh) |
| vim + nvim (shared config, vim-plug) | [assets/editor/vimrc.vim](assets/editor/vimrc.vim) |
| git | [assets/git/gitconfig](assets/git/gitconfig) |
| tmux (must work on tmux 3.2, Ubuntu 22.04) | [assets/tmux/tmux.conf](assets/tmux/tmux.conf) |
| Agent instructions (all tools) | this file, [AGENTS.md](AGENTS.md) |
| Tool-specific agent config | [CLAUDE.md](CLAUDE.md) + [.claude/settings.json](.claude/settings.json) (Claude Code), [.vscode/settings.json](.vscode/settings.json) (Copilot in VS Code) |

Untracked, per-machine files (never commit their contents): `~/.shell_local` (e.g. `USE_CORP_PROXY=1`, `CORP_PROXY_URL`), `~/.gitconfig.local` (git `[user]`).

## Critical gotchas

- `~/.assets` is a symlink to this repo's `assets/`, and most dotfiles in `$HOME` are symlinks into it. **Editing or deleting files under `assets/` immediately affects the user's live shell/git/vim.** Never leave them missing or broken. Installers (e.g. Docker Desktop) may append machine-specific lines to `~/.bash_profile`/`~/.zshrc` through these symlinks; never commit them (revert, or move them to `~/.shell_local`).
- `common.sh` is sourced by **both bash and zsh**: keep it POSIX-ish/bash+zsh compatible and **never print output** (it breaks scp and the prompt).
- Shell integrations for optional tools (eza, fd, bat, delta, zsh plugins) must be guarded by `command -v` so a missing tool never errors or prints.
- Never set `core.pager` / `interactive.diffFilter` to delta in `gitconfig`; `common.sh` sets `GIT_PAGER` only when delta exists.
- Use `${HOMEBREW_PREFIX}` (set by `brew_env`) instead of hardcoded `/usr/local` or `/opt/homebrew`.
- Do not hardcode user names, home paths, emails, or proxy addresses.
- When adding a dotfile, update both `config.yaml` and the "Dotfiles Linked" table in [README.md](README.md).

## Commands

```bash
make sync        # uv sync
make lint        # ruff check + ruff format --check
make format      # ruff check --fix + ruff format
make test        # pytest (tests/): install.py on a temp $HOME with subprocess/network blocked; shell dotfiles in clean bash/zsh (syntax, no output)
make shellcheck  # needs shellcheck; or: uvx --from shellcheck-py shellcheck <files>
make shfmt       # shfmt -d (style from .editorconfig); make format-shell to fix
make check       # lint + test + shellcheck + shfmt + install.py -a -y --dry-run
```

Safe testing of `install.py` without touching the real home:

```bash
T=$(mktemp -d) && HOME=$T uv run install.py -d -y && ls -la $T; rm -rf $T
```

Never run `install.sh`, `make install` or `make upgrade` for testing (they use sudo, brew/apt, and chsh).

## Conventions

- Docs and code comments in English; comments only for non-obvious intent, one line.
- Python ≥ 3.14 (Dependabot supports up to 3.14), ruff rules `E,F,I,B,UP,SIM`, line length 100.
- Shell dotfiles start with a `# shellcheck shell=bash` directive.
- New `install.py` behavior gets a test in [tests/test_install.py](tests/test_install.py); side effects must be covered by `test_dry_run_changes_nothing`.
- CI ([.github/workflows/ci.yml](.github/workflows/ci.yml)) runs ruff, pytest, and the dry run on ubuntu + macos; shellcheck and shfmt run on ubuntu only. [install-ubuntu.yml](.github/workflows/install-ubuntu.yml) runs the real `install.sh` (+ `--upgrade`) in Ubuntu 22.04/24.04 containers – the only place `install.sh` is executed; it runs weekly, and on push to `master` / PRs only when its `paths` filters match, so keep both lists in sync with files that affect installation.
- Commit messages (all agents): follow [.github/instructions/copilot-commit-message-instructions.md](.github/instructions/copilot-commit-message-instructions.md).
