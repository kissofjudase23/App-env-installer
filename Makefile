

.PHONY: install sync lint format shellcheck check

SHELL_SCRIPTS := install.sh assets/shell/common.sh assets/shell/bashrc.sh assets/shell/bash_profile.sh

install:
	bash install.sh

sync:
	uv sync

lint:
	uv run ruff check .
	uv run ruff format --check .

format:
	uv run ruff check --fix .
	uv run ruff format .

shellcheck:
	shellcheck $(SHELL_SCRIPTS)

check: lint shellcheck
	uv run install.py -a -y --dry-run