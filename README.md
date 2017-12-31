# Supported Distributions
 1. Ubuntu
 2. CentOS
 3. Darwin

# Description
 This project is used to provide basic development setting.
 1. bash shell setting (.bashrc)
 2. vim and plugins (.vimrc)
 3. screen setting (.screenrc)
 4. git config (.gitconfig) 
 5. gdb config (.gdbinit)

# Auto complete for git 
 1. [git prompt](https://github.com/git/git/tree/master/contrib/completion)  
 2. [git completion](https://github.com/git/git/tree/master/contrib/completion)  

# Vim plugins  
 1. Use [vundle](https://github.com/VundleVim/Vundle.vim) to manage vim plugins  
 2. Git Wrapper [vim-fugitive](https://github.com/tpope/vim-fugitive)  
 3. A file system explorer for the Vim editor [nerdtree](https://github.com/scrooloose/nerdtree)  
 4. Comment tools [nerdcommenter](https://github.com/scrooloose/nerdcommenter)   
 5. Auto complete engine [YouCompleteMe](https://github.com/Valloric/YouCompleteMe)  
 6. [Color Scheme](https://github.com/flazz/vim-colorschemes)  
 7. [Syntax Check](https://github.com/scrooloose/syntastic)


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
