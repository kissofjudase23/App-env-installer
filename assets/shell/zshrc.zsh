source ~/.assets/shell/common.sh

####### prompt #######
# starship (assets/starship/starship.toml) draws the prompt; fall back to a built-in theme
if (( $+commands[starship] )); then
  ZSH_THEME=""
else
  ZSH_THEME="robbyrussell"
fi

####### oh-my-zsh #######
export ZSH=$HOME/.oh-my-zsh

HYPHEN_INSENSITIVE="true"
COMPLETION_WAITING_DOTS="true"

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
