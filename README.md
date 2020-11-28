# DATA-DOTFILES
- [Config files](#config-files)
- [Installation](#installation)
- [VIM Plugins](#vim-plugins)
  - [YouCompleteMe](#youcompleteme)
- [Shell](#shell)
  - [zsh](#zsh)
  - [fonts](#fonts)
- [Terminal](#terminal)
  - [iTerm2](#iterm2)
- [Editor](#editor)
  - [neovim](#neovim)

## Config files
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

# 4. Check font if you want to use oh-my-zsh and powerlevel10k
```

## VIM Plugins
### [YouCompleteMe](https://github.com/ycm-core/YouCompleteMe)
*  Compile
* ```bash
  # go to build dir

  cd ~/.vim/bundle/YouCompleteMe

  # show help
  $ ./install.py -h

  # Enable Go semantic completion engine.
  $ ./install.py --go-completer
  ```
## Shell
### zsh
  * [zsh env for mac](https://medium.com/statementdog-engineering/prettify-your-zsh-command-line-prompt-3ca2acc967f)
  * [powerlevel10k](https://github.com/romkatv/powerlevel10k)

### fonts
  * Ubuntu
    * [powerline-font](https://github.com/powerlevel10k/powerlevel10k/wiki/Install-Instructions#step-2-install-a-powerline-font)
      * https://powerline.readthedocs.io/en/latest/installation/linux.html#fonts-installation
      * https://github.com/powerline/fonts

  * Mac:
     * path: ~/Library/Fonts
     * Put your font here

## Terminal
### iTerm2
   * [Color Schemes](https://github.com/mbadolato/iTerm2-Color-Schemes)


## Editor
### neovim
  * Ubuntu
      ```sh
      sudo apt install software-properties-common
      # or sudo add-apt-repository ppa:neovim-ppa/unstable for unstable version
      sudo add-apt-repository ppa:neovim-ppa/stable
      sudo apt update
      sudo apt install -y neovim
      ```