# CLI Tools Guide

Quick reference for the modern CLI tools installed by this repo, and for how the dotfiles wire
them together. Each tool has full docs at `<tool> --help` and on its project page.

| Tool | Replaces | macOS | Ubuntu |
|---|---|---|---|
| [eza](https://github.com/eza-community/eza) | `ls`, `tree` | Brewfile | GitHub release → `/usr/local/bin/eza` |
| [fd](https://github.com/sharkdp/fd) | `find` | Brewfile | apt `fd-find`, linked as `fd` |
| [bat](https://github.com/sharkdp/bat) | `cat`, `less` | Brewfile | apt `bat`, linked as `bat` |
| [gh](https://cli.github.com/) | GitHub web UI | Brewfile | official apt repo |

Debian and Ubuntu ship fd as `fdfind` and bat as `batcat`. `install.sh` links them as `fd` and
`bat` in `/usr/local/bin`, so the same commands work on both platforms.

## What the dotfiles set up

[common.sh](../assets/shell/common.sh) enables each integration only when its tool is installed,
so nothing breaks on a machine that lacks one.

| Integration | Effect |
|---|---|
| `ll`, `la`, `l` | Use eza when present (`ll` = `eza -al --git --group-directories-first`); plain `ls` is unchanged |
| fzf `Ctrl-T` | Lists files with `fd` (including hidden files, excluding `.git`) and previews them with `bat` |
| fzf `Alt-C` | Lists directories with `fd`, then `cd`s into the one you pick |
| `MANPAGER` | Renders man pages through `bat` with syntax highlighting (set when bat is installed) |
| `GIT_PAGER=delta` | Set when delta is installed, so `git diff/log/show` render through delta |

## eza

```bash
eza                          # like ls, with colors
eza -l                       # long listing
eza -la --git                # include hidden files and per-file git status
eza -l --sort=modified       # newest last (add -r to reverse)
eza -lD                      # directories only
eza --tree --level=2         # tree view, two levels deep
eza --tree --git-ignore      # tree view without files ignored by .gitignore
eza -l --icons               # file-type icons (needs a Nerd Font, which this repo installs)
```

Tip: `ll` already gives you `eza -al --git --group-directories-first`.

## fd

fd matches by **regex** against file names, skips hidden files, and respects `.gitignore` by default.

```bash
fd config                    # names containing "config", searched from the current dir
fd config assets/            # search under a given directory
fd -e py                     # by extension
fd -g '*.zsh'                # glob instead of regex
fd -t d shell                # directories only (-t f files, -t l symlinks)
fd -H .env                   # include hidden files
fd -I node_modules           # include files ignored by .gitignore
fd --changed-within 1d       # modified in the last day
fd -e sh -x shellcheck       # run a command once per result ({} is the path)
fd -e py -X ruff check       # run a command once with all results as arguments
```

## bat

bat adds syntax highlighting, line numbers, and git change markers, and pages long files.
When its output is piped, it prints plain text like `cat`.

```bash
bat install.sh               # highlighted view with line numbers and git markers
bat -p config.yaml           # plain: no line numbers or header (-pp also disables the pager)
bat -r 40:60 install.py      # only lines 40-60
bat -l json < response.txt   # set the language when it cannot be detected
bat -A Makefile              # show tabs, spaces, and line endings
bat --diff install.sh        # only the lines changed relative to git
bat --list-themes            # preview themes; pick one with: export BAT_THEME="..."
```

`man` pages are already highlighted by bat: common.sh sets
`MANPAGER="sh -c 'col -bx | bat -l man -p'"` (plus `MANROFFOPT=-c` for Linux groff).
To turn it off for one call, run `MANPAGER=less man <page>`.

## gh

Sign in once per machine. Auth is stored per user and is never committed to this repo.

```bash
gh auth login                # interactive login (browser or token)
gh auth status               # check which account and scopes are active
```

Repositories:

```bash
gh repo clone owner/name     # clone using your auth
gh repo view --web           # open the current repo in the browser
gh browse install.sh         # open a file in the browser
```

Pull requests:

```bash
gh pr create --fill          # open a PR from the current branch, using commit messages
gh pr list                   # open PRs
gh pr checkout 42            # check out PR #42 locally
gh pr view 42 --web          # open a PR in the browser
gh pr checks                 # CI status of the current branch's PR
gh pr merge --squash --delete-branch
```

Issues and CI:

```bash
gh issue list --assignee @me
gh issue create --title "..." --body "..."
gh run list                  # recent GitHub Actions runs
gh run watch                 # follow the latest run live
gh run view --log-failed     # logs of the failed steps only
```

Scripting: `gh api repos/{owner}/{repo}/pulls --jq '.[].title'` calls the REST API with your
auth, and `--jq` filters the result the same way jq does.
