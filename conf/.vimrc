" Vundle
" https://github.com/VundleVim/Vundle.vim
set nocompatible  "iMproved, required 
filetype off      "required

" http://www.erikzaadi.com/2012/03/19/auto-installing-vundle-from-your-vimrc/
" Setting up Vundle - the vim plugin bundler
" If the code below does not work, try git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim 
"let iCanHazVundle=1
"let vundle_readme=expand('~/.vim/bundle/vundle/README.md')
"if !filereadable(vundle_readme)
"   echo "Installing Vundle.."
"   echo ""
"   silent !mkdir -p ~/.vim/bundle
"  silent !git clone https://github.com/gmarik/vundle ~/.vim/bundle/vundle
"   let iCanHazVundle=0
"endif

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
" call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
" https://github.com/VundleVim/Vundle.vim
Plugin 'VundleVim/Vundle.vim'

" https://github.com/tpope/vim-fugitive
Plugin 'tpope/vim-fugitive'


" Pass the path to set the runtimepath properly.
" https://github.com/rstacruz/sparkup
" Plugin 'rstacruz/sparkup', {'rtp': 'vim/'}

" https://github.com/vim-scripts/taglist-plus
Plugin 'taglist-plus'

"https://github.com/fatih/vim-go
Plugin 'fatih/vim-go'

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
" To ignore plugin indent changes, instead use:
" filetype plugin on
"
" Brief help
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to  auto-approve removal
" see :h vundle for more details or wiki for FAQ



" Put your non-Plugin stuff after this line
" general
" Please refer http://vimdoc.sourceforge.net/htmldoc/options.html for more
" info.
filetype plugin indent on    " enable filetype-specific plugins
set number                   " enable line numbers
set autoindent               " enable autoindent
"set expandtab                " use space instead of tab
set tabstop=2                " insert 2 spaces for a tab
set shiftwidth=2             " the number of space characters inserted for

syntax on                    " enable syntax highlighting
set listchars=tab:>-,trail:~ 
set list                     " show invisible characters
set background=dark
set autoread                 " auto read when file is changed from outside
set history=50               " keep 50 lines of command line history
set cursorline               " highlight current line
set clipboard=unnamed        " yank to the system register (*) by
set showmatch                " Cursor shows matching ) and }
set showmode                 " Show current mode
set backspace=2              " make backspace work like most other
set hlsearch                 " hightlight search parrtern  
set ruler             " show the line and column number of the cursor position
set background=dark   " when set to "dark", Vim will try to use colors that look
                      " good on a dark background

" Taglist options setting
" http://vim-taglist.sourceforge.net/manual.html
let Tlist_Auto_Highligh_Tag = 1 "Automatically highlight the current tag in the taglist.
let Tlist_Auto_Open = 1         "Open the taglist window when Vim starts.
let Tlist_Exit_OnlyWindow = 1   "Close Vim if the taglist is the only window

"set mouse=a                  " mouse support
"if has("gui_running")        " GUI color and font settings
"  colors Tomorrow-Night-Bright " vim color scheme
"  set guifont=Monaco:h14
"  set t_Co=256               " 256 color mode
"end
"if has("gui_macvim")         " macvim shift movement
"      let macvim_hig_shift_movement = 1
"endif

"ctags path
set tags=./tags
set tags=../tags
