# Development

[← README](../README.md)

This project uses `uv` for Python dependency management.

Run `make` (or `make help`) to list all targets with descriptions. On Windows, `make` (installed by `install.ps1`) runs its recipes in PowerShell 7, and `install`/`upgrade`/`check` use the Windows variants.

| Target            | Description                                                                                                  |
| ----------------- | ------------------------------------------------------------------------------------------------------------ |
| `make help`       | Default target. Lists all targets and their descriptions.                                                    |
| `make install`    | Full bootstrap via `install.sh` (Windows: `install.ps1`): OS packages, Python (from `.python-version`), `install.py -a -y`, `chsh` to zsh. Uses `sudo` and modifies `$HOME`. |
| `make sync`       | Creates/updates `.venv` with the Python deps pinned in `uv.lock` (`uv sync`).                                |
| `make lint`       | `ruff check` + `ruff format --check`; reports issues without modifying files (same as CI).                   |
| `make test`       | Runs `pytest` against a temporary `$HOME`: `install.py` unit tests, plus shell smoke tests (syntax, and `common.sh` / non-interactive bash must print nothing; skipped on Windows) and PowerShell smoke tests (`profile.ps1` must print nothing; skipped without `pwsh`). |
| `make format`     | `ruff check --fix` + `ruff format`; fixes lint issues and reformats Python code in place.                    |
| `make shfmt`      | Checks shell formatting with `shfmt` (style in `.editorconfig`); `make format-shell` rewrites in place.        |
| `make shellcheck` | Runs `shellcheck` on `install.sh`, `common.sh`, `bashrc.sh`, `bash_profile.sh` (`shellcheck` is installed by `install.sh`). |
| `make pslint`     | Runs PSScriptAnalyzer on `install.ps1` and `profile.ps1` (settings in `PSScriptAnalyzerSettings.psd1`).      |
| `make check`      | Pre-commit gate: `lint` + `test` + `shellcheck` + `shfmt` + `install.py -a -y --dry-run` (Windows: plus `pslint`). Makes no changes. |

> Running `make` with no arguments only shows help; use `make install` explicitly to bootstrap.

AI coding agents (Claude Code, GitHub Copilot): project instructions live in [AGENTS.md](../AGENTS.md).

Without a local `shellcheck`, run it via `uvx --from shellcheck-py shellcheck <files>`.

To test `install.py` without touching your real home directory:

```bash
T=$(mktemp -d) && HOME=$T uv run install.py -d -y && ls -la $T; rm -rf $T
```

Python deps and tool config live in [pyproject.toml](../pyproject.toml); `uv.lock` pins versions. CI ([.github/workflows/ci.yml](../.github/workflows/ci.yml)) runs ruff, pytest and an `install.py` dry run on Ubuntu, macOS and Windows, plus shellcheck and shfmt on Ubuntu and PSScriptAnalyzer on Windows. [install-windows.yml](../.github/workflows/install-windows.yml) runs the real `install.ps1` and `install.ps1 -Upgrade` on a fresh Windows runner, followed by `make check`, on the same schedule and triggers as the Ubuntu one. [install-ubuntu.yml](../.github/workflows/install-ubuntu.yml) runs the real `install.sh` and `install.sh --upgrade` in fresh Ubuntu 22.04 and 24.04 containers weekly, on pushes to `master` and PRs that touch the install path, or on demand (Actions → Install (Ubuntu) → Run workflow). Dependabot ([.github/dependabot.yml](../.github/dependabot.yml)) keeps the actions and `uv.lock` current.
