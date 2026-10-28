# App-env-installer – Agent Instructions

Dotfiles + dev-environment bootstrapper for **macOS**, **Ubuntu** and **Windows** (native PowerShell 7; WSL2 is plain Ubuntu and uses `install.sh`).

## Architecture

Two-stage install:

1. [install.sh](install.sh) (macOS/Ubuntu) or [install.ps1](install.ps1) (Windows) – then `install.py`.
   - `install.ps1` (Windows PowerShell 5.1 compatible, `Set-StrictMode` + `$ErrorActionPreference = 'Stop'`, native commands through `Invoke-Native`): `winget import` of [winget-packages.json](winget-packages.json) (`-Upgrade` drops `--no-upgrade`), reloads `PATH` from the registry, installs the PSScriptAnalyzer + PSFzf modules via pwsh, then `uv python install`, `uv sync`, `uv run install.py -a -y`. No nvim/vim on Windows. Runs `Main` only when executed, so tests can dot-source it.
   - `install.sh` (bash, `set -Eeuo pipefail`) – detects OS, installs system packages, installs Python (version from [.python-version](.python-version)) + deps via `uv`, bootstraps Go (Ubuntu: go.dev tarball → `/usr/local/go` if missing or < 1.21; macOS: Brewfile) and, on Ubuntu (22.04 + 24.04), adds the gh apt repo, links `fdfind`/`batcat` as `fd`/`bat`, and installs fzf (< 0.48), eza, delta, starship (→ `/usr/local/bin`) and neovim (< 0.11 → `/opt/nvim`) from GitHub releases (`--upgrade` reinstalls them even when present), runs `install.py -a -y`, then `chsh` to zsh.
2. [install.py](install.py) (click CLI) – reads [config.yaml](config.yaml) (validated on load: unknown keys, missing dotfile `src`, `dst` outside its base, bad `os`/`base`/`stub`, or the same `(base, dst)` for overlapping `os` → `InstallerError`) and, for entries whose `os` includes the current system:
   - `link_dotfiles` – symlinks `assets/*` into `$HOME` (macOS/Linux); entries with `stub` (Windows) get a small file that includes the repo file (`STUBS`: gitconfig `[include]`, PowerShell dot-source), so no symlink privilege is needed. Skips correct links/stubs; backs up anything else to `<dst>.bak.<YYYYmmddHHMMSS>`. `base: documents` resolves the Windows Documents known folder (`windows_documents`, follows OneDrive redirection).
   - `ensure_gitconfig_local` – creates a commented placeholder `~/.gitconfig.local` (never overwrites).
   - `install_fonts` – `nerd_fonts` archives from the latest ryanoasis/nerd-fonts release (sha256 digest checked, `.ttf` only). Linux: `~/.local/share/fonts/NerdFonts/<name>`, then `fc-cache` (skipped on WSL). Windows: `%LOCALAPPDATA%\Microsoft\Windows\Fonts\NerdFonts\<name>`, registered under HKCU (`register_windows_font`). macOS fonts come from the Brewfile.
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
| Windows packages | [winget-packages.json](winget-packages.json) (`winget import` format; check IDs with `winget show --id <id> --exact`) |
| Dotfile links/stubs, git repos to clone, Linux/Windows Nerd Fonts | [config.yaml](config.yaml) (`src` relative to repo, `dst` relative to `base`; optional `os`, `base`, `stub`) |
| `install.py` tests | [tests/](tests/) (pytest; `Installer` takes `home`/`base_dirs`/`ConfigMgr` so tests use `tmp_path`, never the real `$HOME`; symlink tests skip where symlinks need privileges) |
| Shell dotfile smoke tests | [tests/test_shell.py](tests/test_shell.py) (clean `bash --norc` / `zsh -f`, temp `$HOME`; skipped when the shell is missing and on Windows) |
| PowerShell smoke tests | [tests/test_powershell.py](tests/test_powershell.py) (`pwsh -NoProfile`, temp `USERPROFILE`; skipped without `pwsh`) |
| PowerShell lint rules | [PSScriptAnalyzerSettings.psd1](PSScriptAnalyzerSettings.psd1) |
| Line endings | [.gitattributes](.gitattributes) (LF everywhere) |
| Python deps, ruff config | [pyproject.toml](pyproject.toml) (`uv` project, `package = false`) |
| Python interpreter version | [.python-version](.python-version) – single source of truth; `install.sh` and CI call bare `uv python install`. Bump `requires-python` in [pyproject.toml](pyproject.toml) only if the floor changes. |
| Go version | Go's official toolchain (`GOTOOLCHAIN=auto`, per-project `go.mod` `go`/`toolchain` lines). Only a bootstrap `go` is installed; no gvm/goenv. |
| Go tools (`go install`) | `go_tools` in [config.yaml](config.yaml) |
| CLI tool usage docs | [docs/cli-tools.md](docs/cli-tools.md) – update when tool integrations in `common.sh` change |
| Shell formatting style | [.editorconfig](.editorconfig) (read by shfmt) |
| Shared bash+zsh env | [assets/shell/common.sh](assets/shell/common.sh) |
| PowerShell 7 env (Windows) | [assets/shell/profile.ps1](assets/shell/profile.ps1) – mirror `common.sh` changes here when they apply to Windows |
| Prompt (zsh + bash) | [assets/starship/starship.toml](assets/starship/starship.toml) |
| bash / zsh specific | [bashrc.sh](assets/shell/bashrc.sh), [bash_profile.sh](assets/shell/bash_profile.sh), [zshrc.zsh](assets/shell/zshrc.zsh) |
| vim + nvim (shared config, vim-plug) | [assets/editor/vimrc.vim](assets/editor/vimrc.vim) |
| git | [assets/git/gitconfig](assets/git/gitconfig) |
| tmux (must work on tmux 3.2, Ubuntu 22.04) | [assets/tmux/tmux.conf](assets/tmux/tmux.conf) |
| Agent instructions (all tools) | this file, [AGENTS.md](AGENTS.md) |
| Tool-specific agent config | [CLAUDE.md](CLAUDE.md) + [.claude/settings.json](.claude/settings.json) + [.claude/skills/](.claude/skills/) (Claude Code), [.vscode/settings.json](.vscode/settings.json) (Copilot in VS Code) |

Untracked, per-machine files (never commit their contents): `~/.shell_local` (e.g. `USE_CORP_PROXY=1`, `CORP_PROXY_URL`), `~/.gitconfig.local` (git `[user]`).

## Critical gotchas

- `~/.assets` is a symlink to this repo's `assets/`, and most dotfiles in `$HOME` are symlinks into it. **Editing or deleting files under `assets/` immediately affects the user's live shell/git/vim.** Never leave them missing or broken. Installers (e.g. Docker Desktop) may append machine-specific lines to `~/.bash_profile`/`~/.zshrc` through these symlinks; never commit them (revert, or move them to `~/.shell_local`).
- `common.sh` is sourced by **both bash and zsh**: keep it POSIX-ish/bash+zsh compatible and **never print output** (it breaks scp and the prompt). `profile.ps1` must not print either, and guards optional tools with `Test-Command`.
- On Windows, dotfiles are stubs pointing at absolute repo paths (no `~/.assets`); moving the repo means re-running `install.py`. Never add a Windows dotfile entry without `stub` – symlinks need Developer Mode or admin.
- `install.ps1` must stay ASCII and Windows PowerShell 5.1 compatible (5.1 reads BOM-less files as ANSI; no `??`, ternaries or `&&`).
- Shell integrations for optional tools (eza, fd, bat, delta, zsh plugins) must be guarded by `command -v` so a missing tool never errors or prints.
- Never set `core.pager` / `interactive.diffFilter` to delta in `gitconfig`; `common.sh` sets `GIT_PAGER` only when delta exists.
- Use `${HOMEBREW_PREFIX}` (set by `brew_env`) instead of hardcoded `/usr/local` or `/opt/homebrew`.
- Do not hardcode user names, home paths, emails, or proxy addresses.
- When adding a dotfile, update both `config.yaml` and the "Dotfiles Linked" table in [README.md](README.md) (including its OS column; a test compares them).

## Commands

```bash
make sync        # uv sync
make lint        # ruff check + ruff format --check
make format      # ruff check --fix + ruff format
make test        # pytest (tests/): install.py on a temp $HOME with subprocess/network blocked; shell dotfiles in clean bash/zsh (syntax, no output)
make shellcheck  # needs shellcheck; or: uvx --from shellcheck-py shellcheck <files>
make shfmt       # shfmt -d (style from .editorconfig); make format-shell to fix
make pslint      # PSScriptAnalyzer on install.ps1 + profile.ps1 (needs pwsh + module)
make check       # lint + test + shellcheck + shfmt + install.py -a -y --dry-run (Windows: + pslint)
```

On Windows the Makefile runs recipes in `pwsh` (`ifeq ($(OS),Windows_NT)`); target descriptions use `##` (all), `##u` (Unix only) or `##w` (Windows only) so `make help` lists each target once.

Safe testing of `install.py` without touching the real home:

```bash
T=$(mktemp -d) && HOME=$T uv run install.py -d -y && ls -la $T; rm -rf $T
```

Never run `install.sh`, `install.ps1`, `make install` or `make upgrade` for testing (they use sudo, brew/apt/winget, and chsh).

## Conventions

- Docs and code comments in English; comments only for non-obvious intent, one line.
- Python ≥ 3.14 (Dependabot supports up to 3.14), ruff rules `E,F,I,B,UP,SIM`, line length 100.
- Shell dotfiles start with a `# shellcheck shell=bash` directive.
- New `install.py` behavior gets a test in [tests/test_install.py](tests/test_install.py); side effects must be covered by `test_dry_run_changes_nothing`.
- CI ([.github/workflows/ci.yml](.github/workflows/ci.yml)) runs ruff, pytest, and the dry run on ubuntu + macos + windows; shellcheck and shfmt run on ubuntu only, PSScriptAnalyzer on windows only. [install-ubuntu.yml](.github/workflows/install-ubuntu.yml) runs the real `install.sh` (+ `--upgrade`) in Ubuntu 22.04/24.04 containers and [install-windows.yml](.github/workflows/install-windows.yml) the real `install.ps1` (+ `-Upgrade`, then `make check`) on a Windows runner – the only places they are executed; both run weekly, and on push to `master` / PRs only when their `paths` filters match, so keep each workflow's two lists in sync with files that affect installation.
- Commit messages (all agents): follow [.github/instructions/copilot-commit-message-instructions.md](.github/instructions/copilot-commit-message-instructions.md).
