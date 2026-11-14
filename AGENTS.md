# App-env-installer – Agent Instructions

Dotfiles + dev-environment bootstrapper for **macOS**, **Ubuntu** and **Windows** (native PowerShell 7; WSL2 is plain Ubuntu and uses `install.sh`).

## Architecture

Two-stage install:

1. [install.sh](install.sh) (macOS/Ubuntu) or [install.ps1](install.ps1) (Windows) – then `install.py`.
   - `install.ps1` (Windows PowerShell 5.1 compatible, `Set-StrictMode` + `$ErrorActionPreference = 'Stop'`, native commands through `Invoke-Native`): `winget import` of [packages/winget-packages.json](packages/winget-packages.json) with `--no-upgrade` (`-Upgrade` adds a second import without it, leaving out `GitHub.Copilot`, whose portable exe updates itself so winget refuses to remove the "modified" package, and `Microsoft.PowerShell` while any pwsh runs, since its MSI cannot replace a running pwsh), reloads `PATH` from the registry, installs the PSScriptAnalyzer + PSFzf modules via pwsh, then `uv python install`, `uv sync`, `uv run install.py -a -y` (`-Upgrade` adds `--upgrade`). Neovim comes from winget (no vim on Windows). Runs `Main` only when executed, so tests can dot-source it.
   - `install.sh` (bash, `set -Eeuo pipefail`) – detects OS (Ubuntu 24.04+; `detect_os` refuses older releases), then installs system packages. Without `--upgrade` it only installs what is missing (`brew bundle install --no-upgrade`, `apt-get install --no-upgrade`, like winget's `--no-upgrade`); `--upgrade` runs `brew update` and upgrades them. macOS: `brew bundle` of `packages/Brewfile` (includes Go). Ubuntu: adds the gh apt repo, installs the apt packages (`DEBIAN_FRONTEND=noninteractive` through `sudo env`) and uv (its installer runs with `UV_NO_MODIFY_PATH=1`, so it never edits rc files; `--upgrade` runs `uv self update`), links `fdfind`/`batcat` as `fd`/`bat`, bootstraps Go (go.dev tarball → `/usr/local/go` when missing or older than 1.21), and installs fzf (when missing or older than 0.48), eza, delta, starship (when missing from `RELEASE_BIN_DIR`, `/usr/local/bin`, which wins over apt's older copies on PATH) and Neovim (when missing or older than 0.11 → `/opt/nvim`) from GitHub releases (`--upgrade` reinstalls them even when present). Then installs Python (version from [.python-version](.python-version)) + deps via `uv`, runs `install.py -a -y` (plus `--upgrade`), and `sudo chsh` to zsh when `login_shell` (dscl/getent, not the stale `$SHELL`) differs.
2. [install.py](install.py) (click CLI) – reads [config.yaml](config.yaml) (validated on load: unknown top-level or entry keys, missing dotfile `src`, `dst` outside its base, bad `os`/`base`/`stub`, the same `(base, dst)` for overlapping `os`, or a `go_tools` entry without `@version` → `InstallerError`) and, for entries whose `os` includes the current system:
   - `link_dotfiles` – symlinks `assets/*` into `$HOME` (macOS/Linux); entries with `stub` (Windows) get a small file that includes the repo file (`STUBS`: gitconfig `[include]`, PowerShell dot-source, Vimscript `source`), so no symlink privilege is needed. Skips correct links/stubs; backs up anything else to `<dst>.bak.<YYYYmmddHHMMSS>`. `base: documents` resolves the Windows Documents known folder (`windows_documents`, follows OneDrive redirection); `base: local_app_data` is `%LOCALAPPDATA%`.
   - `ensure_gitconfig_local` – creates a commented placeholder `~/.gitconfig.local` (never overwrites).
   - `install_fonts` – `nerd_fonts` archives from the latest ryanoasis/nerd-fonts release (sha256 digest checked, `.ttf` only). Linux: `~/.local/share/fonts/NerdFonts/<name>`, then `fc-cache` (skipped on WSL). Windows: `%LOCALAPPDATA%\Microsoft\Windows\Fonts\NerdFonts\<name>`, registered under HKCU (`register_windows_font`; values of files a newer release dropped are removed). macOS fonts come from `packages/Brewfile`. Installed fonts are skipped; with `--upgrade`, a font is replaced only when its `.release` file (`FONT_RELEASE_FILE`) differs from the latest release tag.
   - `clone_git_repos` – skips when `dst/.git` exists.
   - `install_go_tools` – `go install` each `go_tools` entry whose binary (`go_tool_binary`) is missing from the Go bin dir (`go_bin_dir`: `go env GOBIN GOPATH`, which also sees `go env -w`; environment variables when `go` is missing), or every entry with `--upgrade`; skips with a warning if `go` is missing.
   - Flags: `-d` (default), `-g`, `-f`, `-t`, `-a`, `-y`, `--upgrade`, `--dry-run`. Every side effect must honor `dry_run`.
   - All paths resolve from `ROOT = Path(__file__).resolve().parent`; never rely on cwd.

For any new GitHub-hosted binary on Ubuntu, reuse `github_release_asset` / `install_github_binary` in `install.sh` (they verify the sha256 digest from the GitHub API); call them directly, not inside `$(...)`, check for the binary in `RELEASE_BIN_DIR` (not `command -v`, which also finds apt's older copies), and guard them with `keep_installed` so `--upgrade` works. curl calls take `"${CURL_RETRY[@]}"`, except `curl | sh`, where a retry could append to what the shell already read. GitHub API calls go through `github_api` (shell) / `fetch` (Python), which add `GITHUB_TOKEN`/`GH_TOKEN` for `api.github.com` only; never print or log the token. `install.sh` runs `main` only when executed, so tests can `source` it.

## Where things live

| Change | Edit |
|---|---|
| macOS packages / casks / fonts | [packages/Brewfile](packages/Brewfile) |
| Ubuntu packages | [packages/apt-packages.txt](packages/apt-packages.txt) (`#` comments allowed) |
| Windows packages | [packages/winget-packages.json](packages/winget-packages.json) (`winget import` format; check IDs with `winget show --id <id> --exact`) |
| Dotfile links/stubs, git repos to clone, Linux/Windows Nerd Fonts | [config.yaml](config.yaml) (`src` relative to repo, `dst` relative to `base`; optional `os`, `base`, `stub`) |
| `install.py` tests | [tests/](tests/) (pytest; `Installer` takes `home`/`base_dirs`/`ConfigMgr` so tests use `tmp_path`, never the real `$HOME`; symlink tests skip where symlinks need privileges) |
| Shell tests | [tests/test_shell.py](tests/test_shell.py) (dotfile smoke tests in clean `bash --norc` / `zsh -f` with a temp `$HOME`, plus unit tests of the `source`d `install.sh` functions; skipped when the shell is missing and on Windows) |
| PowerShell tests | [tests/test_powershell.py](tests/test_powershell.py) (`profile.ps1` smoke tests with `pwsh -NoProfile` and a temp `USERPROFILE`, plus unit tests of the dot-sourced `install.ps1`; skipped without `pwsh`, so `make check` on a machine without it does not run them; pinned to one xdist worker because concurrent pwsh startups crash on macOS) |
| Config file parse checks | [tests/test_assets.py](tests/test_assets.py) (`gitconfig` via `git config --list`, `starship.toml` via `tomllib`, `tmux.conf` via `tmux source-file -n`; skipped when the tool is missing) |
| PowerShell lint rules | [PSScriptAnalyzerSettings.psd1](PSScriptAnalyzerSettings.psd1) |
| Line endings | [.gitattributes](.gitattributes) (LF everywhere) |
| Python deps, ruff config | [pyproject.toml](pyproject.toml) (`uv` project, `package = false`) |
| Python interpreter version | [.python-version](.python-version) – single source of truth; `install.sh` calls `uv python install --default`, `install.ps1` and CI a bare `uv python install`, all without a version. Bump `requires-python` in [pyproject.toml](pyproject.toml) only if the floor changes. |
| Go version | Go's official toolchain (`GOTOOLCHAIN=auto`, per-project `go.mod` `go`/`toolchain` lines). Only a bootstrap `go` is installed; no gvm/goenv. |
| Go tools (`go install`) | `go_tools` in [config.yaml](config.yaml) |
| CLI tool usage docs | [docs/cli-tools.md](docs/cli-tools.md) – update when tool integrations in `common.sh`, `bashrc.sh`, `zshrc.zsh` or `profile.ps1` change |
| User docs | [README.md](README.md) is only the entry page; per-OS guides [docs/macos.md](docs/macos.md), [docs/ubuntu.md](docs/ubuntu.md), [docs/windows.md](docs/windows.md); shared [docs/configuration.md](docs/configuration.md), [docs/shell.md](docs/shell.md), [docs/development.md](docs/development.md), [docs/troubleshooting.md](docs/troubleshooting.md); the make target table in development.md must list every `.PHONY` target in order (a test compares them) |
| Shell formatting style | [.editorconfig](.editorconfig) (read by shfmt) |
| Shared bash+zsh env | [assets/shell/common.sh](assets/shell/common.sh) |
| PowerShell 7 env (Windows) | [assets/shell/profile.ps1](assets/shell/profile.ps1) – mirror `common.sh` changes here when they apply to Windows |
| Prompt (zsh + bash) | [assets/starship/starship.toml](assets/starship/starship.toml) |
| bash / zsh specific | [bashrc.sh](assets/shell/bashrc.sh), [bash_profile.sh](assets/shell/bash_profile.sh), [zshrc.zsh](assets/shell/zshrc.zsh) |
| vim + nvim (shared config, vim-plug) | [assets/editor/vimrc.vim](assets/editor/vimrc.vim) |
| git | [assets/git/gitconfig](assets/git/gitconfig) |
| tmux (must work on tmux 3.4, Ubuntu 24.04) | [assets/tmux/tmux.conf](assets/tmux/tmux.conf) |
| Agent instructions (all tools) | this file, [AGENTS.md](AGENTS.md) |
| Tool-specific agent config | [CLAUDE.md](CLAUDE.md) + [.claude/settings.json](.claude/settings.json) + [.claude/skills/](.claude/skills/) (Claude Code), [.vscode/settings.json](.vscode/settings.json) (Copilot in VS Code) |

Untracked, per-machine files (never commit their contents): `~/.shell_local` / `~/.shell_local.ps1` on Windows (e.g. `USE_CORP_PROXY=1`, `CORP_PROXY_URL`, `CORP_NO_PROXY`), `~/.gitconfig.local` (git `[user]`).

## Critical gotchas

- `~/.assets` is a symlink to this repo's `assets/`, and most dotfiles in `$HOME` are symlinks into it. **Editing or deleting files under `assets/` immediately affects the user's live shell/git/vim.** Never leave them missing or broken. Installers (e.g. Docker Desktop) may append machine-specific lines to `~/.bash_profile`/`~/.zshrc` through these symlinks; never commit them (revert, or move them to `~/.shell_local`).
- `common.sh` is sourced by **both bash and zsh**: keep it POSIX-ish/bash+zsh compatible and **never print output** (it breaks scp and the prompt). It also runs for non-interactive shells (`scp`, `ssh host cmd`), so keep it cheap. `profile.ps1` must not print either, and guards optional tools with `Test-Command`.
- `~/.shell_local` (`~/.shell_local.ps1`) is sourced first, so it can only provide inputs such as the proxy flags, not override what `common.sh` (`profile.ps1`) sets later.
- `common.sh` leaves `alias_setting` defined on purpose: `bashrc.sh` unsets it, `zshrc.zsh` re-runs it after oh-my-zsh and then unsets it (a test checks).
- On Windows, dotfiles are stubs pointing at absolute repo paths (no `~/.assets`); moving the repo means re-running `install.py`. Never add a Windows dotfile entry without `stub` – symlinks need Developer Mode or admin.
- `install.ps1` must stay ASCII and Windows PowerShell 5.1 compatible (5.1 reads BOM-less files as ANSI; no `??`, ternaries or `&&`).
- Shell integrations for optional tools (eza, fd, bat, delta, zsh plugins, oh-my-zsh itself) must be guarded (`command -v` in bash/`common.sh`, `$+commands` or a file test in zsh, `Test-Command` in PowerShell) so a missing tool never errors or prints.
- Never set `core.pager` / `interactive.diffFilter` to delta in `gitconfig`; `common.sh` sets `GIT_PAGER` only when delta exists.
- Use `${HOMEBREW_PREFIX}` (set by `brew_env`) instead of hardcoded `/usr/local` or `/opt/homebrew`.
- Do not hardcode user names, home paths, emails, or proxy addresses.
- When adding a dotfile, update both `config.yaml` and the "Dotfiles Linked" table in [docs/configuration.md](docs/configuration.md) (including its OS column; a test compares them).

## Commands

```bash
make sync        # uv sync
make lint        # ruff check + ruff format --check
make format      # ruff check --fix + ruff format
make test        # pytest (tests/, parallel via pytest-xdist): install.py on a temp $HOME with subprocess/network blocked; shell dotfiles in clean bash/zsh (syntax, no output); install.sh / install.ps1 functions
make shellcheck  # needs shellcheck; or: uvx --from shellcheck-py shellcheck <files>
make shfmt       # shfmt -d (style from .editorconfig); make format-shell to fix
make actionlint  # actionlint on .github/workflows (dev dependency in uv.lock)
make pslint      # PSScriptAnalyzer on install.ps1 + profile.ps1 (needs pwsh + module)
make check       # lint + test + shellcheck + shfmt + actionlint + install.py -a -y --dry-run (Windows: + pslint)
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
- Bash dotfiles (`*.sh`) start with a `# shellcheck shell=bash` directive (shellcheck does not read zsh, so `zshrc.zsh` is not linted).
- New `install.py` behavior gets a test in [tests/test_install.py](tests/test_install.py); side effects must be covered by `test_dry_run_changes_nothing`.
- CI ([.github/workflows/ci.yml](.github/workflows/ci.yml)) runs ruff, pytest, and the dry run on ubuntu + macos + windows; shellcheck, shfmt and actionlint run on ubuntu only, PSScriptAnalyzer on windows only. [install-ubuntu.yml](.github/workflows/install-ubuntu.yml) runs the real `install.sh` (+ `--upgrade`, then `make check`) in Ubuntu 24.04 and 26.04 containers and [install-windows.yml](.github/workflows/install-windows.yml) the real `install.ps1` (+ `-Upgrade`, then `make check`) on a Windows runner, and [install-macos.yml](.github/workflows/install-macos.yml) the real `install.sh` (+ `--upgrade`) on a macOS runner – the only places they are executed; all run weekly, and on push to `master` / PRs only when their `paths` filters match, so keep each workflow's `paths: &paths` list (reused by `pull_request` through the anchor) in sync with files that affect installation or its Verify step; files that only affect tests or linting stay out, since ci.yml checks them on every push. `cancel-in-progress` applies to pull requests only, so a push to `master` never cancels the weekly run. Actions are pinned by commit SHA with a version comment.
- Commit messages (all agents): follow [.github/instructions/copilot-commit-message-instructions.md](.github/instructions/copilot-commit-message-instructions.md).
