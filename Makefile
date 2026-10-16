

.PHONY: help install sync lint format shellcheck check

.DEFAULT_GOAL := help

SHELL_SCRIPTS := install.sh assets/shell/common.sh assets/shell/bashrc.sh assets/shell/bash_profile.sh

help: ## Show available targets and their descriptions (default target)
	@grep -E '^[a-zA-Z_-]+:.*## ' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

install: ## Full bootstrap: OS packages (brew/apt), Python 3.15 via uv, install.py -a -y, chsh to zsh (uses sudo, modifies $HOME)
	bash install.sh

sync: ## Create/update .venv with Python deps pinned in uv.lock (uv sync)
	uv sync

lint: ## Check Python lint and formatting with ruff, without modifying files (same as CI)
	uv run ruff check .
	uv run ruff format --check .

format: ## Auto-fix ruff lint issues and reformat Python code in place
	uv run ruff check --fix .
	uv run ruff format .

shellcheck: ## Run shellcheck on install.sh and bash dotfiles (requires shellcheck in PATH)
	shellcheck $(SHELL_SCRIPTS)

check: lint shellcheck ## Pre-commit gate: lint + shellcheck + install.py -a -y --dry-run (no changes made)
	uv run install.py -a -y --dry-run