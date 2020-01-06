# DATA-DOTFILES
 This project is used to provide dev env setting.


# Table of Contents
- [Dot Files](#dot-files)
- [Vim Plugins](#vim-plugins)
- [Installation](#installation)
- [Uninstallation](#uninstallation)
- [Reference](#reference)
- [zsh](#zsh)


## Dot Files
 * bash
   * [.bashrc](https://github.com/kissofjudase23/Data-dotfiles/blob/master/conf/.bashrc)
 * zsh
   * [.zshrc](https://github.com/kissofjudase23/Data-dotfiles/blob/master/conf/.zshrc)
 * vim
   * [.vimrc](https://github.com/kissofjudase23/Data-dotfiles/blob/master/conf/.vimrc)
 * nvim
   * link ~/.config/nvim/init.vim to [.vimrc](https://github.com/kissofjudase23/Data-dotfiles/blob/master/conf/.vimrc)
 * screen
   * [.screenrc](https://github.com/kissofjudase23/Data-dotfiles/blob/master/conf/.screenrc)
 * tmux
   * [.tmux.conf](https://github.com/kissofjudase23/Data-dotfiles/blob/master/conf/.tmux.conf)
 * git
   * [.gitconfig](https://github.com/kissofjudase23/Data-dotfiles/blob/master/conf/.gitconfig)


## [Vim Plugins](https://github.com/kissofjudase23/Data-dotfiles/blob/master/conf/.vimrc#L26-L50)
 * [vundle](https://github.com/VundleVim/Vundle.vim):
   * manage plugins
 * [vim-fugitive](https://github.com/tpope/vim-fugitive):
   * git plugins
 * [nerdtree](https://github.com/scrooloose/nerdtree):
   * file system explorer
 * [nerdcommenter](https://github.com/scrooloose/nerdcommenter):
   * comment tools
 * [YouCompleteMe](https://github.com/Valloric/YouCompleteMe):
   * Auto complete engine
 * [ale](https://github.com/w0rp/ale)
   * Asychronous Lint Engine


## Installation
```bash
# 1. install pkgs
bash ./install.sh

# 2. install vim plugins
vim ~/.vimrc
:PluginInstall

# 3. compile auto complete engine
# note, your vim (or nvim) have to compiled with python plugins.
# https://github.com/ycm-core/YouCompleteMe

# 4. Check font if you want to use oh-my-zsh and powerlevel9k
```

## Uninstallation
```bash
$ bash ./uninstall.sh
```


## Reference
### zsh
  * [zsh env for mac](https://medium.com/statementdog-engineering/prettify-your-zsh-command-line-prompt-3ca2acc967f)
  * [zsh themem, powerlevel9k](https://github.com/bhilburn/powerlevel9k)


