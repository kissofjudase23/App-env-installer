# CLI Tools Guide

Quick reference for the modern CLI tools installed by this repo, and for how the dotfiles wire
them together. Each tool has full docs at `<tool> --help` and on its project page.

| Tool | Replaces | macOS | Ubuntu | Windows |
|---|---|---|---|---|
| [eza](https://github.com/eza-community/eza) | `ls`, `tree` | Brewfile | GitHub release → `/usr/local/bin/eza` | winget |
| [fd](https://github.com/sharkdp/fd) | `find` | Brewfile | apt `fd-find`, linked as `fd` | winget |
| [bat](https://github.com/sharkdp/bat) | `cat`, `less` | Brewfile | apt `bat`, linked as `bat` | winget |
| [ripgrep](https://github.com/BurntSushi/ripgrep) (`rg`) | `grep -r` | Brewfile | apt | winget |
| [fzf](https://github.com/junegunn/fzf) | history/file search | Brewfile | GitHub release → `/usr/local/bin/fzf` | winget |
| [zoxide](https://github.com/ajeetdsouza/zoxide) | `cd`, autojump | Brewfile | apt | winget |
| [delta](https://github.com/dandavison/delta) | git's `less` pager | Brewfile `git-delta` | GitHub release → `/usr/local/bin/delta` | winget |
| [jq](https://jqlang.org/) | JSON processing | Brewfile | apt | winget |
| [gron](https://github.com/tomnomnom/gron) | grepping JSON | Brewfile | — (macOS only) | — |
| [yq](https://github.com/mikefarah/yq) | YAML processing | `go_tools` | `go_tools` | `go_tools` |
| [actionlint](https://github.com/rhysd/actionlint) | GitHub Actions workflow checks | `go_tools` | `go_tools` | `go_tools` |
| [direnv](https://direnv.net/) | per-directory environment variables | Brewfile | apt | — |
| [gh](https://cli.github.com/) | GitHub web UI | Brewfile | official apt repo | winget |
| [btop](https://github.com/aristocratos/btop) | `top`, `htop` | Brewfile | apt | — |
| [tig](https://jonas.github.io/tig/) | `git log` browsing | Brewfile | apt | — |
| [tmux](https://github.com/tmux/tmux) | `screen` | Brewfile | apt | — |
| [starship](https://starship.rs/) | shell prompt | Brewfile | GitHub release → `/usr/local/bin/starship` | winget |

Debian and Ubuntu ship fd as `fdfind` and bat as `batcat`. `install.sh` links them as `fd` and
`bat` in `/usr/local/bin`, so the same commands work on both platforms.

## What the dotfiles set up

[common.sh](../assets/shell/common.sh) enables each integration only when its tool is installed,
so nothing breaks on a machine that lacks one.

| Integration | Effect |
|---|---|
| `ls` and friends | Use eza when present; see the alias table under [eza](#eza). `command ls` runs the original |
| `cat` | `bat --paging=never` when bat is present: highlighted in a terminal, plain when piped. `command cat` runs the original |
| `j`, `ji` | Aliases for zoxide's `z` / `zi`, so autojump habits keep working |
| fzf `Ctrl-T` | Lists files with `fd` (including hidden files, excluding `.git`) and previews them with `bat` |
| fzf `Alt-C` | Lists directories with `fd`, then `cd`s into the one you pick |
| fzf `Ctrl-R` | Fuzzy-searches shell history |
| `MANPAGER` | Renders man pages through `bat` with syntax highlighting (set when bat is installed) |
| `GIT_PAGER=delta` | Set when delta is installed, so `git diff/log/show` render through delta |
| Prompt | starship, configured in [starship.toml](../assets/starship/starship.toml), for bash and zsh |

On Windows, [profile.ps1](../assets/shell/profile.ps1) sets up the same integrations for
PowerShell 7, with these differences:

- The `ls`/`l`/`la`/`ll`/`lt`/`lta`/`lm`/`lS`/`ld` and `cat` aliases are PowerShell functions; they
  replace the built-in `ls` and `cat` aliases, so use `Get-ChildItem` / `Get-Content` for the originals.
- fzf `Ctrl-T` / `Ctrl-R` come from the [PSFzf](https://github.com/kelleyma49/PSFzf) module
  (installed by `install.ps1`); `Alt-C` and `MANPAGER` are not set up.
- `~/.shell_local.ps1` replaces `~/.shell_local` for machine-specific settings.

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

Aliases set by common.sh (directories are always listed first):

| Alias | Command | Like |
|---|---|---|
| `ls` | `eza` | `ls` |
| `l` | `eza -F` | `ls -CF` |
| `la` | `eza -a` | `ls -A` |
| `ll` | `eza -al --git` | `ls -alF`, plus git status |
| `lt` | `eza --tree --level=2` | `tree -L 2` |
| `lta` | `eza -a --tree --level=2 --ignore-glob=.git` | `tree -a -L 2 -I .git` |
| `lm` | `eza -al --git --sort=modified` | `ls -altr` (newest last) |
| `lS` | `eza -al --sort=size` | `ls -alSr` (largest last) |
| `ld` | `eza -lD` | directories only |

eza's flags are not fully compatible with ls. For example, `-t` takes a field name
(`ls -lt` fails), so use `lm` instead. Scripts are unaffected because aliases apply only to
interactive shells; run `command ls` for the original ls.

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
When its output is piped, it prints plain text like `cat`. In interactive shells `cat` is
aliased to `bat --paging=never`.

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

## ripgrep

rg searches file contents recursively and, like fd, skips hidden files and respects `.gitignore`.

```bash
rg TODO                      # regex search from the current dir
rg -F 'a.b(c)'               # fixed string, no regex
rg -w path                   # whole words only
rg -i proxy assets/          # case-insensitive, under a directory
rg -t py import              # only Python files (rg --type-list shows all types)
rg -g '*.sh' -g '!install*'  # include/exclude by glob
rg -l HOMEBREW               # file names only
rg -C 2 alias                # 2 lines of context
rg -uu secret                # include hidden and ignored files
```

## fzf

```bash
Ctrl-R                       # search shell history
Ctrl-T                       # insert files (fd + bat preview, see above)
Alt-C                        # cd into a directory
vim **<Tab>                  # fuzzy completion for paths; also kill -9 **<Tab>, ssh **<Tab>
git branch | fzf             # pick from any list
```

Inside fzf, type space-separated terms; `'word` matches exactly, `^start`, `end$`, `!exclude`.
`Tab` multi-selects where supported.

## zoxide

zoxide remembers the directories you `cd` into and ranks them by frequency and recency.

```bash
z proj                       # jump to the best match for "proj"
z app inst                   # all terms must match, in order
z -                          # previous directory
zi                           # pick interactively with fzf (alias ji)
zoxide query -ls             # list entries with scores
zoxide remove <dir>          # forget a directory
```

## delta

delta renders git diffs with syntax highlighting. [gitconfig](../assets/git/gitconfig) enables
`navigate` and `line-numbers`; it is used only when `GIT_PAGER=delta` is set.

```bash
git diff                     # n / N jump between files in the pager
git -c delta.side-by-side=true diff  # side-by-side once
git show HEAD                # also used for log -p, show, stash show -p, blame
delta file_a file_b          # diff two files without git
GIT_PAGER=less git diff      # plain pager for one call
```

## jq and gron

```bash
jq . data.json               # pretty-print
jq -r '.items[].name' data.json        # raw strings, one per line
jq '.items[] | select(.ok) | {id, name}' data.json
jq -s 'length' *.json        # slurp multiple files into one array
curl -s URL | jq -c '.[]'    # one compact object per line
```

gron (macOS only) flattens JSON into greppable `path = value` lines, which helps find where a
field lives:

```bash
gron data.json | rg email    # json.users[3].email = "..."
gron data.json | rg email | gron -u   # back to JSON with only matching paths
```

## yq

```bash
yq '.go_tools' config.yaml   # read a YAML path
yq -o=json config.yaml       # convert YAML to JSON
yq -i '.a.b = 1' file.yaml   # edit a file in place
```

## actionlint

```bash
actionlint                   # check .github/workflows/* from the repo root
actionlint path/to/ci.yml    # check one workflow
```

## direnv

direnv loads a directory's `.envrc` when you enter it and unloads it when you leave. The shell
hook is set up in [zshrc.zsh](../assets/shell/zshrc.zsh) and [bashrc.sh](../assets/shell/bashrc.sh).

```bash
echo 'export API_URL=http://localhost:8080' > .envrc
direnv allow                 # trust this .envrc; required again after each change
direnv deny                  # stop loading it
```

Do not commit an `.envrc` that holds secrets.

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

## Other tools

- **btop**: interactive process, CPU, memory, disk and network monitor. `q` quits, `f` filters,
  `k` kills the selected process.
- **tig**: text UI for git, configured by [tigrc](../assets/tig/tigrc). `tig` browses the log,
  `tig status` stages hunks, `tig blame <file>`, `tig <branch>..<branch>`.
- **tmux**: terminal multiplexer, configured by [tmux.conf](../assets/tmux/tmux.conf). The prefix
  is `Ctrl-a` (screen-like): `prefix c` new window, `prefix n`/`p` next/previous,
  `prefix |` / `prefix -` split (new panes and windows keep the current directory),
  `prefix h/j/k/l` move between panes, `prefix [` enters vi copy mode (`v` select, `y` copy),
  `prefix R` reloads the config, `prefix d` detaches, `tmux a` reattaches.
- **starship**: the prompt; see [shell.md](shell.md) for the preset and how to update it.

## Network tools

| Tool | macOS | Ubuntu | Windows |
|---|---|---|---|
| `curl` | built in | apt `curl` | built in (`curl.exe`; PowerShell 7 has no `curl` alias) |
| `openssl` | built in (LibreSSL) | apt `openssl` | winget `ShiningLight.OpenSSL.Light` |
| `nc` | built in | apt `netcat-openbsd` | not installed; use `Test-NetConnection <host> -Port <port>` |
| `dig` | built in | apt `bind9-dnsutils` | not installed; use `Resolve-DnsName <name>` or `nslookup` |

```bash
curl -sSI https://example.com                      # response headers only
curl -v --resolve example.com:443:1.2.3.4 https://example.com   # pin a host to an IP
openssl s_client -connect example.com:443 -servername example.com < /dev/null
openssl x509 -in cert.pem -noout -subject -issuer -dates
nc -vz example.com 443                             # is the port open?
dig +short example.com                             # A records
dig @1.1.1.1 example.com MX                        # ask a specific resolver
```
