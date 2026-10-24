
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" vim-plug
" https://github.com/junegunn/vim-plug
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

set nocompatible

" Before any <leader> mapping, including plugins' ('\' is also the default)
let mapleader = '\'

" Every autocmd joins this group so re-sourcing the vimrc does not duplicate them
augroup vimrc
    autocmd!
augroup END

" vim and nvim keep autoload in different dirs
let s:plug_path = has('nvim')
    \ ? stdpath('data') . '/site/autoload/plug.vim'
    \ : expand('~/.vim/autoload/plug.vim')
if empty(glob(s:plug_path))
    silent execute '!curl -fLo ' . shellescape(s:plug_path) . ' --create-dirs '
        \ . 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
    " autoload dirs created after startup are not on the runtimepath yet
    execute 'source ' . fnameescape(s:plug_path)
    autocmd vimrc VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')
Plug 'tomasr/molokai'
Plug 'preservim/nerdtree'
Plug 'dense-analysis/ale'
Plug 'junegunn/vim-easy-align'
Plug 'mileszs/ack.vim'
Plug 'fatih/vim-go'
call plug#end()

" :PlugInstall / :PlugUpdate / :PlugClean / :PlugStatus

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" nvim
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
if has('nvim')
    " ESC to leave terminal mode
    tnoremap <Esc> <C-\><C-n>

    nnoremap t<Enter> :bo vsp term://zsh<CR>

    " mouse in visual mode only, so the terminal's own selection keeps working
    set mouse=v
endif

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" basic vim setting
" :help option-list
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
filetype plugin indent on    " enable filetype-specific plugins
set number                   " enable line numbers
set autoindent               " enable autoindent
set expandtab                " use space instead of tab
set tabstop=4                " insert 4 spaces for a tab
set shiftwidth=4             " indent by 4 spaces

autocmd vimrc FileType yaml setlocal ts=2 sts=2 sw=2 expandtab

set listchars=tab:>-,trail:~
set list                     " show invisible characters
set autoread                 " auto read when file is changed from outside
set history=10000            " command-line history (nvim's default)
set cursorline               " highlight the cursor's line
set clipboard=unnamed,unnamedplus " access system clipboard (macOS, Linux)
set showmatch                " cursor shows matching ) and }
set showmode                 " show current mode
set backspace=indent,eol,start " backspace over everything in insert mode
set hlsearch                 " highlight search matches
set incsearch                " show matches while typing the pattern
set ignorecase smartcase     " case-insensitive search unless the pattern has capitals
set ruler                    " show the line and column number of the cursor position
set cc=120
set splitbelow
set splitright
set encoding=utf-8
set fileformats=unix

" Persistent undo; vim's default undodir is the file's own dir, nvim's is under stdpath('state')
if !has('nvim')
    set undodir=~/.vim/undo//
    if !isdirectory(expand('~/.vim/undo'))
        call mkdir(expand('~/.vim/undo'), 'p', 0700)
    endif
endif
set undofile

" Enable folding with indent
set foldmethod=indent
set foldlevel=99
set foldclose=all
" Enable folding with the spacebar
nnoremap <space> za

" Split navigation: <C-h/j/k/l> move to the split left/below/above/right
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

syntax on
set t_Co=256
" plugins are missing until the first PlugInstall finishes
silent! colorscheme molokai

" F4 removes all trailing whitespace; F5 toggles NERDTree
nnoremap <F4> :let _s=@/<Bar>:%s/\s\+$//e<Bar>:let @/=_s<Bar><CR>


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" vim-go
" https://github.com/fatih/vim-go
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
    autocmd vimrc LspAttach * nnoremap <buffer> <silent> gd <Cmd>lua vim.lsp.buf.definition()<CR>
endif

" gopls, goimports and dlv come from go_tools in config.yaml (or :GoInstallBinaries)


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Ack.vim
" https://github.com/mileszs/ack.vim
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
if executable('rg')
  let g:ackprg = 'rg --vimgrep --smart-case'
endif

" Ctrl-f starts an :Ack search; :Ack! does not jump to the first result
nnoremap <C-f> :Ack<space>

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
" NERDTree setting
" use ':help NERD_tree.txt' to get more info
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
nnoremap <silent> <F5> :NERDTreeToggle<CR>
let g:NERDTreeDirArrowExpandable = '▸'
let g:NERDTreeDirArrowCollapsible = '▾'

let g:NERDTreeIgnore =
\[ '\.pyc$', '\.pyo$', '\.obj$', '\.o$', '\.so$', '\.egg$', '^\.git$',
\'.*\.so', '.*\.a']

let g:NERDTreeShowHidden=1

" Close Vim if NERDTree is the only window left
autocmd vimrc BufEnter * if (winnr("$") == 1
\&& exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" ALE (Asynchronous Lint Engine)
" https://github.com/dense-analysis/ale
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:ale_sign_warning = '--'
let g:ale_sign_error = '>>'
let g:ale_echo_msg_error_str = 'E'
let g:ale_echo_msg_warning_str = 'W'
let g:ale_echo_msg_format = '[%linter%] %s [%severity%]'

" [e / ]e jump between ALE problems; <C-h/j/k/l> stay on split navigation
nmap <silent> [e <Plug>(ale_previous_wrap)
nmap <silent> ]e <Plug>(ale_next_wrap)

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" python.vim setting
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" enable all Python syntax highlighting features
let g:python_highlight_all = 1
