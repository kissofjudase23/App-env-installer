# Copilot Commit Message Instructions

Based on [Conventional Commits](https://www.conventionalcommits.org/).

### Format

```
<type>(<scope>): <subject>

<body>

Refs: #<taskID>
```
- **type**: Required, the commit type
- **scope**: Optional, the affected module or component
- **subject**: Required, a short description (max 50 characters)
- **body**: Optional, detailed explanation

### Types

| Type       | Description                                                  |
| ---------- | ------------------------------------------------------------ |
| `feat`     | A new feature                                                |
| `fix`      | A bug fix                                                    |
| `docs`     | Documentation only changes                                   |
| `style`    | Formatting changes (no logic impact)                         |
| `refactor` | Code change that neither fixes a bug nor adds a feature      |
| `perf`     | Performance improvement                                      |
| `test`     | Adding or updating tests                                     |
| `build`    | Build system or external dependency changes (e.g. npm, make) |
| `ci`       | CI configuration changes (e.g. pipeline, GitHub Actions)     |
| `chore`    | Other changes that don't affect src or test                  |
| `revert`   | Reverts a previous commit                                    |

### Scopes

Use a single scope matching the main area changed; omit it if the change spans many areas.

| Scope       | Area                                                          |
| ----------- | ------------------------------------------------------------- |
| `install`   | `install.sh` (system packages, Python/Go bootstrap, `chsh`)   |
| `installer` | `install.py` (dotfile links, fonts, git repos, go tools)      |
| `config`    | `config.yaml` (dotfiles, `git_repos`, `go_tools`)             |
| `brew`      | `Brewfile` (macOS packages, casks, fonts)                     |
| `apt`       | `apt-packages.txt` (Ubuntu packages)                          |
| `python`    | `.python-version`, `pyproject.toml`, `uv.lock`                |
| `shell`     | `assets/shell/*` (common, bash, zsh, p10k)                    |
| `vim`       | `assets/editor/vimrc.vim` (vim + nvim)                        |
| `git`       | `assets/git/*`                                                |
| `tmux`      | `assets/tmux/*`                                               |
| `ci`        | `.github/workflows/*`                                         |
| `make`      | `Makefile`                                                    |
| `readme`    | `README.md`                                                   |
| `copilot`   | `.github/copilot-instructions.md`, `.github/instructions/*`   |

### Rules

- Use **imperative mood** in subject: `add` not `added` or `adds`
- Subject starts with **lowercase**, **no period** at the end
- Use lowercase for **type** and **scope**
- Wrap lines at **72 characters** (body / footer)
- For Breaking Changes, add `BREAKING CHANGE:` in footer or append `!` after type
- Always include `Refs: #<taskID>` as footer to link the related task

### Examples

```text
feat(brew): add copilot-cli cask

Refs: #123456
```

```text
feat(config): add gopls to go_tools

Refs: #123457
```

```text
fix(installer): skip go tools when go is missing

Print a warning instead of failing so the rest of the install
continues on machines without a Go toolchain.

Refs: #123458
```

```text
fix(shell): use HOMEBREW_PREFIX instead of /opt/homebrew

Refs: #123459
```

```text
refactor(vim): remove unused plugins

Refs: #123460
```

```text
build(python): bump python to 3.15

Refs: #123461
```

```text
ci: add shellcheck job for ubuntu and macos

Refs: #123462
```

```text
docs(readme): add tigrc to dotfiles linked table

Refs: #123463
```

```text
feat(installer)!: back up existing dotfiles with timestamp

BREAKING CHANGE: backups are now written to <dst>.bak.<YYYYmmddHHMMSS>
instead of <dst>.bak
Refs: #123464
```

## Bad Examples

❌ `update` → Too vague
❌ `feat(instructions, ci, install.sh, Makefile): update python` → Multiple scopes; split the commit or omit the scope
❌ `feat(Brewfile): Added shellcheck.` → Scope not lowercase, past tense, trailing period
❌ `feat(install): add go bootstrap and update zshrc` → Doing too many things
