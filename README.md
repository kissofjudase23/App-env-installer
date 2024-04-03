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
 * Prequisites: git and python3.x
 * step1:
   * `bash install.sh`
 * step2:
   * Install vim plugins
      * `vim ~/.vimrc`
      *  `:PluginInstall`
 * step3:
   * [Compile YouCompleteMe](https://github.com/ycm-core/YouCompleteMe#installation)

   * `cd ~/.vim/bundle/YouCompleteMe`
   * `./install.py --go-completer` , support golang and python

 * step4:
   * Check the shell configuration


## Shell
  * zsh
    * [zsh env for mac](https://medium.com/statementdog-engineering/prettify-your-zsh-command-line-prompt-3ca2acc967f)
  * zsh scheme
    * [powerlevel10k](https://github.com/romkatv/powerlevel10k)
  * [font](https://github.com/romkatv/powerlevel10k?tab=readme-ov-file#fonts) for special scheme


## Terminal
  * iTerm2
     * Change Fonts
       * Preferences -> Profiles -> Text -> Font
     * Change Color Schems
       * Preferences -> Profiles -> Color
       * [Color Schemes](https://github.com/mbadolato/iTerm2-Color-Schemes)

## Editor
### neovim
  * Ubuntu
      ```bash
      sudo apt install software-properties-common
      # or sudo add-apt-repository ppa:neovim-ppa/unstable for unstable version
      sudo add-apt-repository ppa:neovim-ppa/stable
      sudo apt update
      sudo apt install -y neovim
      ```