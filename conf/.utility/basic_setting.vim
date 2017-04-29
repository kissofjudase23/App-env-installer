""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" basic vim setting
" http://vimdoc.sourceforge.net/htmldoc/options.html for more
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
filetype plugin indent on    " enable filetype-specific plugins
set number                   " enable line numbers
set autoindent               " enable autoindent
set expandtab                " use space instead of tab
set tabstop=4                " insert 4 spaces for a tab
set shiftwidth=4             " the number of space characters inserted for
"map <F2> :retab <CR> :wq! <CR>
"http://vi.stackexchange.com/questions/4244/what-is-softtabstop-used-for
"set softtabstop=4

set listchars=tab:>-,trail:~
set list                     " show invisible characters
set autoread                 " auto read when file is changed from outside
set history=50               " keep 50 lines of command line history
set cursorline               " show a visual lin under the cursor's current line
set clipboard=unnamed        " access system clipboard
set showmatch                " Cursor shows matching ) and }
set showmode                 " Show current mode
set backspace=2              " make backspace work like most other
set hlsearch                 " hightlight search parrtern  
set ruler             " show the line and column number of the cursor position
set cc=80
set splitbelow
set splitright
set encoding=utf-8
set fileformats=unix

" Enable folding with indent
set foldmethod=indent
set foldlevel=99
set foldclose=all
" Enable folding with the spacebar
nnoremap <space> za

"split navigations
"move to the split below
nnoremap <C-K> <C-W><C-J>
"move to the split above
nnoremap <C-I> <C-W><C-K>
"move to the split to the right
nnoremap <C-L> <C-W><C-L>
"move to the split to the left
nnoremap <C-J> <C-W><C-H>

" enable syntax highlighting
syntax on
set t_Co=256
if has('gui_running')
    set background=light
else
    set background=dark
endif




