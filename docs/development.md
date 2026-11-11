# Development

[← README](../README.md)

This project uses `uv` for Python dependency management.

Run `make` (or `make help`) to list all targets with descriptions. On Windows, `make` (installed by `install.ps1`) runs its recipes in PowerShell 7, and `install`/`upgrade`/`check` use the Windows variants.

| Target              | Description                                                                                                  |
| ------------------- | ------------------------------------------------------------------------------------------------------------ |
| `make help`         | Default target. Lists all targets and their descriptions.                                                    |
| `make install`      | Full bootstrap via `install.sh` (Windows: `install.ps1`): OS packages, Python (from `.python-version`), `install.py -a -y`, `chsh` to zsh. Uses `sudo` and modifies `$HOME`. |
| `make upgrade`      | Like `install`, plus `--upgrade`: reinstalls Go tools, updates Nerd Fonts, and on Ubuntu the GitHub-release tools (Windows: also upgrades winget packages). |
| `make sync`         | Creates/updates `.venv` with the Python deps pinned in `uv.lock` (`uv sync`).                                |
| `make lint`         | `ruff check` + `ruff format --check`; reports issues without modifying files (same as CI).                   |
| `make format`       | `ruff check --fix` + `ruff format`; fixes lint issues and reformats Python code in place.                    |
| `make test`         | Runs `pytest` against a temporary `$HOME`: `install.py` unit tests, plus shell smoke tests (syntax, and `common.sh` / non-interactive bash must print nothing; skipped on Windows) and PowerShell smoke tests (`profile.ps1` must print nothing; skipped without `pwsh`). |
| `make shellcheck`   | Runs `shellcheck` on `install.sh`, `common.sh`, `bashrc.sh`, `bash_profile.sh` (`shellcheck` is installed by `install.sh`). |
| `make shfmt`        | Checks shell formatting with `shfmt` (style in `.editorconfig`).                                             |
| `make format-shell` | Rewrites the shell scripts in place with `shfmt`.                                                            |
| `make actionlint`   | Lints `.github/workflows/*` with [actionlint](https://github.com/rhysd/actionlint) (a dev dependency pinned in `uv.lock`, so no separate install). |
| `make pslint`       | Runs PSScriptAnalyzer on `install.ps1` and `profile.ps1` (settings in `PSScriptAnalyzerSettings.psd1`).      |
| `make check`        | Pre-commit gate: `lint` + `test` + `shellcheck` + `shfmt` + `actionlint` + `install.py -a -y --dry-run` (Windows: plus `pslint`). Makes no changes. |

> Running `make` with no arguments only shows help; use `make install` explicitly to bootstrap.

AI coding agents (Claude Code, GitHub Copilot): project instructions live in [AGENTS.md](../AGENTS.md).

Without a local `shellcheck`, run it via `uvx --from shellcheck-py shellcheck <files>`.

To test `install.py` without touching your real home directory:

```bash
T=$(mktemp -d) && HOME=$T uv run install.py -d -y && ls -la $T; rm -rf $T
```

Python deps and tool config live in [pyproject.toml](../pyproject.toml); `uv.lock` pins versions.

## CI

| Workflow | Runs on | Triggers | What it does |
| --- | --- | --- | --- |
| [ci.yml](../.github/workflows/ci.yml) | Ubuntu, macOS, Windows | every push to `master` and PR | ruff, pytest and an `install.py` dry run; shellcheck, shfmt and actionlint on Ubuntu; PSScriptAnalyzer on Windows |
| [install-ubuntu.yml](../.github/workflows/install-ubuntu.yml) | Ubuntu 24.04 container | weekly, pushes / PRs touching the install path, manual | real `install.sh`, then `install.sh --upgrade`, then checks tools, the login shell, silent dotfiles and an unchanged repo |
| [install-macos.yml](../.github/workflows/install-macos.yml) | macOS runner | weekly, pushes / PRs touching the install path, manual | real `install.sh` (Homebrew + Brewfile), then `--upgrade`, with the same checks |
| [install-windows.yml](../.github/workflows/install-windows.yml) | Windows runner | weekly, pushes / PRs touching the install path, manual | real `install.ps1` from Windows PowerShell 5.1, then `-Upgrade`, then tool, stub and Neovim plugin checks and `make check` |

Each install workflow lists the files that affect installation once, under `push.paths`, and reuses them for `pull_request` through a YAML anchor. Run one by hand from Actions → *workflow name* → Run workflow.

Actions are pinned by commit SHA with the version in a comment. [Dependabot](../.github/dependabot.yml) bumps those pins and `uv.lock` monthly.
