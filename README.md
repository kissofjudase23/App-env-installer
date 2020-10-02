# DATA-DOTFILES
 This project is used to provide fast env setting.


# Table of Contents
- [DATA-DOTFILES](#data-dotfiles)
- [Table of Contents](#table-of-contents)
  - [Dot Files](#dot-files)
  - [Vim Plugins](#vim-plugins)
  - [Installation](#installation)
  - [Reference](#reference)
    - [Compile YCM (YouCompleteMe) Engine](#compile-ycm-youcompleteme-engine)
    - [zsh](#zsh)
    - [font](#font)


## Config file
 * [config.yaml](./config.yaml)
   * git_repos
     * git repositorys will be cloned.
   * dotfiles
     * dotfiles will be linked.
   * brew_pkgs
     * Packages for Mac OS (brew)
   * ubuntu_pkgs
     * Packages for Ubuntu (apt)
   * centos_pkgs
     * Packages for CentOS (dnt or yum)


## Installation
```bash
# 1. install pkgs
bash ./install.sh

# 2. install vim plugins
vim ~/.vimrc
:PluginInstall

# 3. Compile YCM (YouCompleteMe) Engine

# 4. Check font if you want to use oh-my-zsh and powerlevel9k
```

## Reference
### Compile YCM (YouCompleteMe) Engine
*  Note
   *  your vim (or nvim) have to compiled with python plugins.

* ```bash
  # go to build dir

  cd ~/.vim/bundle/YouCompleteMe

  # show help
  $ ./install.py -h

  # Enable Go semantic completion engine.
  $ ./install.py --go-completer

  # C-family languages
  --clang-completer  # libclang
  --clangd-completer # clangd
  # rust
  --rust-completer

  ```
* Ref:
  * https://github.com/ycm-core/YouCompleteMe
### zsh
  * [zsh env for mac](https://medium.com/statementdog-engineering/prettify-your-zsh-command-line-prompt-3ca2acc967f)
  * [zsh themem, powerlevel9k](https://github.com/bhilburn/powerlevel9k)

### font
  * Ubuntu
    * [powerline-font](https://github.com/Powerlevel9k/powerlevel9k/wiki/Install-Instructions#step-2-install-a-powerline-font)
      * https://powerline.readthedocs.io/en/latest/installation/linux.html#fonts-installation
      * https://github.com/powerline/fonts
  * Latest neovim in Ubuntu
    * ```sh
      sudo apt install software-properties-common
      # or sudo add-apt-repository ppa:neovim-ppa/unstable for unstable version
      sudo add-apt-repository ppa:neovim-ppa/stable
      sudo apt update
      sudo apt install -y neovim
      ```
