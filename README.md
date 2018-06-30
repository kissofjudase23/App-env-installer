# Supported Unix Distributions
 1. Ubuntu
 2. CentOS
 3. Darwin

# Description
 This project is used to provide basic dotfiles setting.
 1. bash shell setting (.bashrc)
 2. oh-my-zsh setting (.zshrc)
 3. vim and plugins (.vimrc)
 4. screen setting (.screenrc)
 5. git config (.gitconfig) 
 6. gdb config (.gdbinit)

# Auto complete
 1. aws
 2. git
 3. docker 

# Vim plugins  
 1. Use [vundle](https://github.com/VundleVim/Vundle.vim) to manage vim plugins  
 2. Git Wrapper [vim-fugitive](https://github.com/tpope/vim-fugitive)  
 3. A file system explorer for the Vim editor [nerdtree](https://github.com/scrooloose/nerdtree)  
 4. Comment tools [nerdcommenter](https://github.com/scrooloose/nerdcommenter)   
 5. Auto complete engine [YouCompleteMe](https://github.com/Valloric/YouCompleteMe)  
 6. [Color Scheme](https://github.com/flazz/vim-colorschemes)  
 

# Install dotfiles
```bash 
$./install.sh
$ vim
$ :PluginInstall  (install vimplugins)
```

# Prerequisite for [YouCompleteMe](https://github.com/Valloric/YouCompleteMe) 
1. [Installation](https://github.com/Valloric/YouCompleteMe#installation)
2. [User Guide]()<a href="https://github.com/Valloric/YouCompleteMe#user-guide"> User Guide

# Uninstall dotfiles
```bash 
$ ./uninstall.sh
```
