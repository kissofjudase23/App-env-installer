

.PHONY: help install upgrade sync lint format test shellcheck shfmt format-shell pslint check

.DEFAULT_GOAL := help

SHELL_SCRIPTS := install.sh assets/shell/common.sh assets/shell/bashrc.sh assets/shell/bash_profile.sh
PS_SCRIPTS := install.ps1 assets/shell/profile.ps1
PSLINT := $$r = foreach ($$f in "$(PS_SCRIPTS)".Split(" ")) { Invoke-ScriptAnalyzer -Settings PSScriptAnalyzerSettings.psd1 -Path $$f }; $$r; exit [int][bool]$$r

# Windows has no sh/grep/awk by default: recipes run in PowerShell 7 there.
# Target descriptions: `##` everywhere, `##u` Unix only, `##w` Windows only (shown by help).
ifeq ($(OS),Windows_NT)
SHELL := pwsh.exe
.SHELLFLAGS := -NoProfile -NonInteractive -Command

help: ##w Show available targets and their descriptions (default target)
	@Select-String -Path $(firstword $(MAKEFILE_LIST)) -Pattern '^([a-zA-Z_-]+):.*##w? (.*)' | ForEach-Object { '  {0,-12} {1}' -f $$_.Matches[0].Groups[1].Value, $$_.Matches[0].Groups[2].Value }

install: ##w Full bootstrap: winget packages, Python via uv (.python-version), install.py -a -y (modifies $HOME)
	powershell -NoProfile -ExecutionPolicy Bypass -File install.ps1

upgrade: ##w Like install, but also upgrade installed winget packages (install.ps1 -Upgrade)
	powershell -NoProfile -ExecutionPolicy Bypass -File install.ps1 -Upgrade
else
help: ##u Show available targets and their descriptions (default target)
	@grep -E '^[a-zA-Z_-]+:.*##u? ' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*##u? "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

install: ##u Full bootstrap: OS packages (brew/apt), Python via uv (.python-version), install.py -a -y, chsh to zsh (uses sudo, modifies $HOME)
	bash install.sh

upgrade: ##u Like install, but also update fzf, eza, delta, starship, nvim on Ubuntu (bash install.sh --upgrade)
	bash install.sh --upgrade
endif

sync: ## Create/update .venv with Python deps pinned in uv.lock (uv sync)
	uv sync

lint: ## Check Python lint and formatting with ruff, without modifying files (same as CI)
	uv run ruff check .
	uv run ruff format --check .

format: ## Auto-fix ruff lint issues and reformat Python code in place
	uv run ruff check --fix .
	uv run ruff format .

test: ## Run pytest: install.py unit tests and shell/PowerShell dotfile smoke tests (temp $HOME, no side effects)
	uv run pytest

shellcheck: ## Run shellcheck on install.sh and bash dotfiles (requires shellcheck in PATH)
	shellcheck $(SHELL_SCRIPTS)

shfmt: ## Check shell formatting with shfmt (style from .editorconfig), without modifying files
	shfmt -d $(SHELL_SCRIPTS)

format-shell: ## Reformat shell scripts in place with shfmt
	shfmt -w $(SHELL_SCRIPTS)

ifeq ($(OS),Windows_NT)
pslint: ##w Run PSScriptAnalyzer on install.ps1 and profile.ps1 (installed by install.ps1)
	$(PSLINT)

check: lint test pslint shellcheck shfmt ##w Pre-commit gate: lint + test + pslint + shellcheck + shfmt + install.py -a -y --dry-run (no changes made)
	uv run install.py -a -y --dry-run
else
pslint: ##u Run PSScriptAnalyzer on install.ps1 and profile.ps1 (requires pwsh and the PSScriptAnalyzer module)
	pwsh -NoProfile -NonInteractive -Command '$(PSLINT)'

check: lint test shellcheck shfmt ##u Pre-commit gate: lint + test + shellcheck + shfmt + install.py -a -y --dry-run (no changes made)
	uv run install.py -a -y --dry-run
endif
