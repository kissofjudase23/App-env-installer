source ~/.assets/shell/common.sh

####### prompt #######
# starship (assets/starship/starship.toml) draws the prompt; fall back to a built-in theme
if (( $+commands[starship] )); then
  ZSH_THEME=""
else
  ZSH_THEME="robbyrussell"
fi


####### oh-my-zsh #######
# Set list of themes to load
# Setting this variable when ZSH_THEME=random
# cause zsh load theme from this variable instead of
# looking in ~/.oh-my-zsh/themes/
# An empty array have no effect
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.

# Path to your oh-my-zsh installation
# git clone https://github.com/ohmyzsh/ohmyzsh.git ~/.oh-my-zsh
export ZSH=$HOME/.oh-my-zsh

plugins=(sudo)

# Load tool plugins only when their command exists (some warn at startup otherwise)
for _plugin _cmd in \
  docker docker \
  docker-compose docker \
  golang go \
  uv uv \
  gh gh \
  zoxide zoxide \
  tig tig \
  tmux tmux \
  fzf fzf; do
  (( $+commands[$_cmd] )) && plugins+=($_plugin)
done
unset _plugin _cmd

# Bundled with recent oh-my-zsh; zsh-syntax-highlighting must be the last plugin
for _plugin in zsh-autosuggestions zsh-syntax-highlighting; do
  [[ -d $ZSH/plugins/$_plugin || -d ${ZSH_CUSTOM:-$ZSH/custom}/plugins/$_plugin ]] && plugins+=($_plugin)
done
unset _plugin

source $ZSH/oh-my-zsh.sh

# oh-my-zsh defines its own ll/la/l; re-apply the shared aliases from common.sh
alias_setting

(( $+commands[starship] )) && eval "$(starship init zsh)"

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/rsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
