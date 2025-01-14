
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Vundle
" https://github.com/VundleVim/Vundle.vim
" http://www.erikzaadi.com/2012/03/19/auto-installing-vundle-from-your-vimrc/
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

set nocompatible  "iMproved, required
filetype off      "required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" let Vundle manage Vundle, required
" https://github.com/VundleVim/Vundle.vim
Plugin 'VundleVim/Vundle.vim'
Plugin 'https://github.com/flazz/vim-colorschemes.git'
Plugin 'https://github.com/MattesGroeger/vim-bookmarks.git'
Plugin 'https://github.com/tpope/vim-fugitive.git'
" Plugin 'https://github.com/vim-scripts/taglist.vim.git'
Plugin 'https://github.com/scrooloose/nerdtree.git'
Plugin 'https://github.com/scrooloose/nerdcommenter.git'
" Plugin 'https://github.com/scrooloose/syntastic.git'
Plugin 'https://github.com/w0rp/ale'
Plugin 'https://github.com/Valloric/YouCompleteMe.git'
Plugin 'https://github.com/junegunn/vim-easy-align.git'

Plugin 'https://github.com/mileszs/ack.vim.git'
Plugin 'https://github.com/fatih/vim-go.git'
Plugin 'avakhov/vim-yaml'

"Plugin 'pearofducks/ansible-vim'
" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
" To ignore plugin indent changes, instead use:
" filetype plugin on

" <<<< Brief help>>>>
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to  auto-approve removal
" see :h vundle for more details or wiki for FAQ


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
set clipboard=unnamed        " access system clipboard
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
colorscheme molokai

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
let g:go_metalinter_enabled = ['vet', 'golint', 'errcheck']

" install plugins
":GoInstallBinaries

"update plugins
" :GoUpdateBinaries


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Ack.vim
" https://github.com/mileszs/ack.vim
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
if executable('ag')
  let g:ackprg = 'ag --vimgrep '
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
" NETDCommenter
" use ':help nerdcommenter' to get more info
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Default mapping
"
" [count]<leader>cc |NERDComComment|
" Comment out the current line or text selected in visual mode.
"
" [count]<leader>cn |NERDComNestedComment|
" Same as cc but forces nesting.
"
" [count]<leader>cu |NERDComUncommentLine|
" Uncomments the selected line(s).

" Add spaces after comment delimiters by default
let g:NERDSpaceDelims = 1

" Use compact syntax for prettified multi-line comments
let g:NERDCompactSexyComs = 1

" Allow commenting and inverting empty lines (useful when commenting a region)
let g:NERDCommentEmptyLines = 1

" Enable trimming of trailing whitespace when uncommenting
let g:NERDTrimTrailingWhitespace = 1

" Align line-wise comment delimiters flush left instead of following code
" indentation
"let g:NERDDefaultAlign = 'left'

" Set a language to use its alternate delimiters by default
"let g:NERDAltDelims_java = 1

" Add your own custom formats or override the defaults
"let g:NERDCustomDelimiters = { 'c': { 'left': '/**','right': '*/' } }


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Syntastic setting
" https://github.com/scrooloose/syntastic
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" set statusline+=%#warningmsg#
" set statusline+=%{SyntasticStatuslineFlag()}
" set statusline+=%*
" let g:syntastic_error_symbol ='>>'
" let g:syntastic_warning_symbol = '>>'
" let g:syntastic_always_populate_loc_list = 1
" let g:syntastic_auto_loc_list = 1
" let g:syntastic_check_on_open = 1
" let g:syntastic_check_on_wq = 0
" let g:syntastic_enable_highlighting= 1
" highlight SyntasticErrorSign guifg=white guibg=black

"" use ctrl+w+E to enable/disable
" let g:syntastic_mode_map = { 'mode': 'passive', 'active_filetypes': [],'passive_filetypes': [] }
" nnoremap <C-w>E :SyntasticCheck<CR> :SyntasticToggleMode<CR>

" Checker options
" :help syntastic-checkers to read the menual
" use ':SyntasticInfo' to show which checkers are enabled.
" https://github.com/scrooloose/syntastic/wiki to get more info
"
" Python
"
" determine operating system
" let os = substitute(system('uname'), "\n", "", "")
" "g:syntastic_python_<checker>_exec
" if os == "Darwin"
    " let g:syntastic_python_python_exec = '/usr/local/bin/python3'
" elseif os == "Linux"
    " let g:syntastic_python_python_exec = '/usr/bin/python3'
" endif
" "python requires either flake8 or pylint to be installed and in your $PATH
" let g:syntastic_python_checkers = ['prospector']

" C family languages
"C
" let g:syntastic_c_check_header = 1
" let b:syntastic_c_cflags = '-I../lib -I./lib '
" let g:syntastic_c_include_dirs = ['./lib/', '../lib/', '../Data_Structure' ]
" let g:syntastic_c_compiler = 'gcc'
"
" "C++
" let g:syntastic_cpp_check_header = 1
" let b:syntastic_cpp_cflags = '-I../lib -I./lib '
" let g:syntastic_cpp_include_dirs = [ './lib','../lib/', '../Data_Structure' ]
" let g:syntastic_cpp_compiler_options = '-std=c++0x'

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

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" YouCompleteMe  setting
" https://github.com/Valloric/YouCompleteMe
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"close the preview automatically
let g:ycm_autoclose_preview_window_after_completion = 1
let g:ycm_autoclose_preview_window_after_insertion = 1

"When set, this option turns on YCM's diagnostic display features
"This option also makes YCM remove all Syntastic checkers set for
"the c, cpp, objc and objcpp filetypes since this would conflict with YCM's
"own diagnostics UI.
let g:ycm_show_diagnostics_ui = 0
let g:ycm_error_symbol = '>'
let g:ycm_warning_symbol = '>'

"When this option is set to 1 YCM will ask once per .ycm_extra_conf.py file if
"it is safe to be loaded. This is to prevent execution of malicious code from
"a .ycm_extra_conf.py file you didn't write.
let g:ycm_confirm_extra_conf = 1

"default map leader is '\'
let mapleader = '\'
"
" determine operating system
let os = substitute(system('uname'), "\n", "", "")
"Python
if os == "Darwin"
    "By default YCM runs jedi with the same Python interpreter used by the
    "ycmd server, so if you would like to use a different interpreter, use the
    "following option specifying the Python binary to use. For example, to
    "provide Python 3 completion in your project, set:
    " let g:ycm_python_binary_path = 'python'
    "Restarts the semantic-engine-as-localhost-server for those semantic engines
    "that work as separate servers that YCM talks to.
    " nnoremap <leader>restart :YcmCompleter RestartServer /usr/local/bin/python3.5 <CR>
elseif os == "Linux"
    " let g:ycm_python_binary_path = 'python'
    " nnoremap <leader>restart :YcmCompleter RestartServer /usr/bin/python3.5 <CR>
endif

"let g:ycm_collect_identifiers_from_tag_files = 1
"
"YCM SubCommands
"This command attempts to find all of the references within the project to the
"identifier under the cursor and populates the quickfix list with those
"locations.
" Supported in filetypes: [javascript, python, typescript]
nnoremap <leader>fref :YcmCompleter GoToReferences<CR>

"Looks up the symbol under the cursor and jumps to its declaration.
"Supported in filetypes: [c, cpp, objc, objcpp, cs, go, python, rust]
nnoremap <leader>gdec :YcmCompleter GoToDeclaration<CR>

"Looks up the symbol under the cursor and jumps to its definition.
"NOTE: For C-family languages this only works in certain situations, namely
"when the definition of the symbol is in the current translation unit. A
"translation unit consists of the file you are editing and all the files you
"are including with #include directives (directly or indirectly) in that file.
"Supported in filetypes: [c, cpp, objc, objcpp, cs, go, javascript, python,
"rust, typescript]
nnoremap <leader>gdef :YcmCompleter GoToDefinition <CR>

"This command tries to perform the "most sensible" GoTo operation it can.
"Supported in filetypes: [c, cpp, objc, objcpp, cs, go, javascript, python,
"rust]
nnoremap <leader>gt :YcmCompleter GoTo<CR>

"Displays the preview window prpulated with qick info
"Supported in filetypes: [c, cpp, objc, objcpp, cs, python, typescript,
"                         javascript]
nnoremap <leader>getdoc :YcmCompleter GetDoc<CR>

"Echos the type of the variable or method under the cursor, and where it
"differs, the derived type.
nnoremap <leader>gettype :YcmCompleter GetType<CR>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" vim-bookmarks  setting
" https://github.com/MattesGroeger/vim-bookmarks
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" disable default key mapping
" basic usage:
" 1.Add/remove bookmark at current line mm  :BookmarkToggle
" 2.Add/edit/remove annotation at current line" mi  :BookmarkAnnotate <TEXT>
"
" 3.Jump to next bookmark in buffer mn  :BookmarkNext
" 4.Jump to previous bookmark in buffer mp  :BookmarkPrev
"
" 5.Show all bookmarks (toggle) ma  :BookmarkShowAll
"
" 6.Clear bookmarks in current buffer only  mc  :BookmarkClear
" 7.Clear bookmarks in all buffers  mx  :BookmarkClearAll
" 8.Move up bookmark at current line    mkk :BookmarkMoveUp
" 9.Move down bookmark at current line  mjj :BookmarkMoveDown
"
" 10.Save all bookmarks to a file       :BookmarkSave <FILE_PATH>
" 11.Load bookmarks from a file     :BookmarkLoad <FILE_PATH>
"

" let g:bookmark_no_default_key_mappings = 1
" nnoremap <Leader><Leader> <Plug>BookmarkToggle
" nnoremap <Leader>i <Plug>BookmarkAnnotate
" nnoremap <Leader>a <Plug>BookmarkShowAll
" nnoremap <Leader>j <Plug>BookmarkNext
" nnoremap <Leader>k <Plug>BookmarkPrev
" nnoremap <Leader>c <Plug>BookmarkClear
" nnoremap <Leader>x <Plug>BookmarkClearAll
" nnoremap <Leader>kk <Plug>BookmarkMoveUp
" nnoremap <Leader>jj <Plug>BookmarkMoveDown
"
" default ⚑
let g:bookmark_sign = '♥♥'

" default ☰
let g:bookmark_annotation_sign = '⚑♥♥'

" Automatically close bookmarks split when jumping to a bookmark
let g:bookmark_auto_close = 1

" This feature allows the grouping of bookmarks per root directory. This way
" bookmarks from other projects are not interfering. This is done by saving a
" file called .vim-bookmarks into the current working directory (the folder
" you opened vim from).
" You should add the filename .vim-bookmarks to your (global) .gitignore
" file so it doesn't get checked into version control.
"
let g:bookmark_save_per_working_dir = 1
let g:bookmark_auto_save = 1


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" python.vim setting
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" enable all Python syntax highlighting features
let python_highlight_all = 1
