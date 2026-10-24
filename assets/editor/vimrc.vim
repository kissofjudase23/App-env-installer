
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" vim-plug
" https://github.com/junegunn/vim-plug
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

set nocompatible

" vim and nvim keep autoload in different dirs
let s:plug_path = has('nvim')
    \ ? stdpath('data') . '/site/autoload/plug.vim'
    \ : expand('~/.vim/autoload/plug.vim')
if empty(glob(s:plug_path))
    silent execute '!curl -fLo ' . shellescape(s:plug_path) . ' --create-dirs '
        \ . 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
    " autoload dirs created after startup are not on the runtimepath yet
    execute 'source ' . fnameescape(s:plug_path)
    autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')
Plug 'tomasr/molokai'
Plug 'preservim/nerdtree'
Plug 'dense-analysis/ale'
Plug 'junegunn/vim-easy-align'
Plug 'mileszs/ack.vim'
Plug 'fatih/vim-go'
Plug 'avakhov/vim-yaml'
" Plug 'pearofducks/ansible-vim'
call plug#end()

" :PlugInstall / :PlugUpdate / :PlugClean / :PlugStatus


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Include Other run time path
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" set the runtime path to include self defined vim setting
" set rtp+=~/.utility/vim/
" runtime ./vim_plugin_setting.vim

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" nvim
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
if has('nvim')
    " ESC to leave insert mode
    tnoremap <Esc> <C-\><C-n>

    nmap t<Enter> :bo vsp term://zsh<CR>

    " The mouse can be enabled for different modes:
        " n   Normal mode
        " v   Visual mode
        " i   Insert mode
        " c   Command-line mode
        " h   all previous modes when editing a help file
        " a   all previous modes
        " r   for |hit-enter| and |more-prompt| prompt
     " Normally you would enable the mouse in all four modes with:
     " :set mouse=a
    set mouse=v
endif


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

autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab


set listchars=tab:>-,trail:~
set list                     " show invisible characters
set autoread                 " auto read when file is changed from outside
set history=50               " keep 50 lines of command line history
set cursorline               " show a visual lin under the cursor's current line
set clipboard=unnamed,unnamedplus " access system clipboard (macOS, Linux)
set showmatch                " Cursor shows matching ) and }
set showmode                 " Show current mode
set backspace=2              " make backspace work like most other
set hlsearch                 " hightlight search parrtern
set ruler             " show the line and column number of the cursor position
set cc=120
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
nnoremap <C-J> <C-W><C-J>
"move to the split above
nnoremap <C-K> <C-W><C-K>
"move to the split to the right
nnoremap <C-L> <C-W><C-L>
"move to the split to the left
nnoremap <C-H> <C-W><C-H>

" tell vim the background color
" if has('gui_running')
    " set background=light
" else
    " set background=dark
" enable syntax highlighting
"
syntax on
set t_Co=256
"wombat/molokai
" plugins are missing until the first PlugInstall finishes
silent! colorscheme molokai

"Remove all trailing whitespace by pressing F4
nnoremap <F4> :let _s=@/<Bar>:%s/\s\+$//e<Bar>:let @/=_s<Bar><CR>
" F3 is resevered for TagList
" F5 is reservered for NERDTree
" F8~F10 are resevered for screen


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" fatih/vim-go.git'
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:go_fmt_command = "goimports"
let g:go_highlight_functions = 1
let g:go_highlight_methods = 1
let g:go_highlight_structs = 1
let g:go_highlight_operators = 1
let g:go_highlight_build_constraints = 1
let g:go_auto_type_info = 1
let g:go_highlight_array_whitespace_error = 1
let g:go_highlight_chan_whitespace_error = 1
let g:go_highlight_space_tab_error = 1
let g:go_highlight_trailing_whitespace_error = 1
let g:go_fmt_autosave = 1
let g:go_metalinter_autosave = 1
let g:go_list_type = "quickfix"
" golint is deprecated; gopls runs vet + staticcheck analyzers
let g:go_metalinter_command = 'gopls'
let g:go_gopls_staticcheck = 1

" nvim >= 0.11: native LSP replaces vim-go's and ALE's own gopls clients
if has('nvim-0.11')
    let g:go_gopls_enabled = 0
    let g:go_metalinter_autosave = 0
    " these vim-go features call gopls; native LSP provides K, <C-]>, omnifunc and gr* maps
    let g:go_auto_type_info = 0
    let g:go_def_mapping_enabled = 0
    let g:go_doc_keywordprg_enabled = 0
    let g:go_code_completion_enabled = 0
    let g:ale_disable_lsp = 1
    lua vim.lsp.config('gopls', { cmd = { 'gopls' }, filetypes = { 'go', 'gomod', 'gowork', 'gotmpl' }, root_markers = { 'go.work', 'go.mod', '.git' }, settings = { gopls = { staticcheck = true } } })
    lua vim.lsp.enable('gopls')
    augroup vimrc_lsp
        autocmd!
        autocmd LspAttach * nnoremap <buffer> <silent> gd <Cmd>lua vim.lsp.buf.definition()<CR>
    augroup END
endif

" install plugins
":GoInstallBinaries

"update plugins
" :GoUpdateBinaries


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Ack.vim
" https://github.com/mileszs/ack.vim
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
if executable('rg')
  let g:ackprg = 'rg --vimgrep --smart-case'
endif

" ctrl + f to auto insert Ack
map <c-f> :Ack<space>

" Use :Ack! if you don't want to jump to the first result automatically.


" Keyboard Shortcuts
" ?    a quick summary of these keys, repeat to close
" o    to open (same as Enter)
" O    to open and close the quickfix window
" go   to preview file, open but maintain focus on ack.vim results
" t    to open in new tab
" T    to open in new tab without moving to it
" h    to open in horizontal split
" H    to open in horizontal split, keeping focus on the results
" v    to open in vertical split
" gv   to open in vertical split, keeping focus on the results
" q    to close the quickfix window


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Easy Align setting
" https://github.com/junegunn/vim-easy-align
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Start interactive EasyAlign in visual mode (e.g. vipga)
xmap ga <Plug>(EasyAlign)

" Start interactive EasyAlign for a motion/text object (e.g. gaip)
nmap ga <Plug>(EasyAlign)

" vipga=
" visual-select inner paragraph
" Start EasyAlign command (ga)
" Align around =
"
" gaip=
" Start EasyAlign command (ga) for inner paragraph
" Align around =

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" NETDTree setting
" use ':help NERD_tree.txt' to get more info
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" map NERDTreeToggle to <F5>
nnoremap <silent> <F5> :NERDTreeToggle<CR>
" map NERDTreeClose  to <F6>
" nnoremap <silent> <F6> :NERDTreeClose<CR>
" default arrows
let g:NERDTreeDirArrowExpandable = '▸'
let g:NERDTreeDirArrowCollapsible = '▾'

let NERDTreeIgnore =
\[ '\.pyc$', '\.pyo$', '\.obj$', '\.o$', '\.so$', '\.egg$', '^\.git$',
\'.*\.so', '.*\.a']

let g:NERDTreeShowHidden=1

"Open the NERDTree window when Vim starts.
"autocmd StdinReadPre * let s:std_in=1
"autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif
"Close Vim if the NETDTree is the only window
autocmd bufenter * if (winnr("$") == 1
\&& exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" ale  setting (Asychronous Lint Engine)
" https://github.com/Valloric/YouCompleteMe
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:ale_sign_warning = '--'
let g:ale_sign_error = '>>'
let g:ale_echo_msg_error_str = 'E'
let g:ale_echo_msg_warning_str = 'W'
let g:ale_echo_msg_format = '[%linter%] %s [%severity%]'

nmap <silent> <C-k> <Plug>(ale_previous_wrap)
nmap <silent> <C-j> <Plug>(ale_next_wrap)

"default map leader is '\'
let mapleader = '\'

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" python.vim setting
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" enable all Python syntax highlighting features
let python_highlight_all = 1
