# Description
 This project is used to provide basic development setting.
 1. bash shell setting (.bashrc)
 2. vim editor with several plugins (.vimrc), use <a href="https://github.com/VundleVim/Vundle.vim"> vundle <a> to configure them<br>
	a.<a href="https://github.com/tpope/vim-fugitive"> vim-fugitive </a> (git plugin) <br>
	b.<a href="https://github.com/scrooloose/nerdtree"> nerdtree </a> (display files and directories) <br> 
	c.<a href="https://github.com/scrooloose/syntastic"> syntastic (syntax checking) </a> <br>
	d.<a href="https://github.com/Valloric/YouCompleteMe"> YouCompleteMe </a> ( code-completion engine )<br>
 3. screen setting (.screenrc)
 4. git config (.gitconfig) 
 5. gdb config (.gdbinit)

# Install dotfiles
<pre><code>$ ./install.sh
$ vim
$ :PluginInstall
</code></pre>

# Prerequisite for <a href="https://github.com/Valloric/YouCompleteMe"> YouCompleteMe </a> 
1. <a href="https://github.com/Valloric/YouCompleteMe/wiki/Building-Vim-from-source"> Building Vim from source </a> <br>
2. <a href="https://github.com/Valloric/YouCompleteMe#ubuntu-linux-x64"> Quick installation </a>

# Prerequisite for Darwin 
1. xCode (git) <br>

# Uninstall dotfiles
<pre><code>$ ./un_install.sh
</code></pre>
