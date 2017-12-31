""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" autoloading functionality for Ctags
" http://stackoverflow.com/questions/563616/vim-and-ctags-tips-and-tricks
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set tags=./tags;/
"does not work for xshell
"map <C-\> :tab split<CR>:exec("tag ".expand("<cword>"))<CR>
"map <A-]> :vsp <CR>:exec("tag ".expand("<cword>"))<CR>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Taglist options
" http://vim-taglist.sourceforge.net/manual.html
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"Automatically highlight the current tag in the taglist
let Tlist_Auto_Highligh_Tag = 1
"Open the taglist window when Vim starts.
"let Tlist_Auto_Open = 1
"Close Vim if the taglist is the only window
let Tlist_Exit_OnlyWindow = 1

" map TlistToggle to <F3>
nnoremap <silent> <F3> :TlistToggle<CR>
" map TlistClose to <F4>
" nnoremap <silent> <F4> :TlistClose<CR>

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
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*
let g:syntastic_error_symbol ='>>'
let g:syntastic_warning_symbol = '>>'
let g:syntastic_always_populate_loc_list = 0
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 0
let g:syntastic_check_on_wq = 1
let g:syntastic_enable_highlighting= 1
highlight SyntasticErrorSign guifg=white guibg=black

"" use ctrl+w+E to enable/disable 
let g:syntastic_mode_map = { 'mode': 'passive', 'active_filetypes': [],'passive_filetypes': [] }
nnoremap <C-w>E :SyntasticCheck<CR> :SyntasticToggleMode<CR>

" Checker options
" :help syntastic-checkers to read the menual
" use ':SyntasticInfo' to show which checkers are enabled.
" https://github.com/scrooloose/syntastic/wiki to get more info
"
" Python
"
" determine operating system
let os = substitute(system('uname'), "\n", "", "")
"g:syntastic_python_<checker>_exec
if os == "Darwin"
    let g:syntastic_python_python_exec = '/usr/local/bin/python3'
elseif os == "Linux"
    let g:syntastic_python_python_exec = '/usr/bin/python3'
endif
"python requires either flake8 or pylint to be installed and in your $PATH
"let g:syntastic_python_checkers = ['flake8']

" C family languages
"C
let g:syntastic_c_check_header = 1
let b:syntastic_c_cflags = '-I../lib -I./lib '
let g:syntastic_c_include_dirs = ['./lib/', '../lib/', '../Data_Structure' ]
let g:syntastic_c_compiler = 'gcc'

"C++
let g:syntastic_cpp_check_header = 1
let b:syntastic_cpp_cflags = '-I../lib -I./lib '
let g:syntastic_cpp_include_dirs = [ './lib','../lib/', '../Data_Structure' ]
let g:syntastic_cpp_compiler_options = '-std=c++0x'


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
    let g:ycm_python_binary_path = '/usr/local/bin/python3'
    "Restarts the semantic-engine-as-localhost-server for those semantic engines 
    "that work as separate servers that YCM talks to.
    nnoremap <leader>restart :YcmCompleter RestartServer /usr/local/bin/python3.5 <CR>
elseif os == "Linux"
    let g:ycm_python_binary_path = '/usr/bin/python3'
    nnoremap <leader>restart :YcmCompleter RestartServer /usr/bin/python3.5 <CR>
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
let g:bookmark_annotation_sign = '⚑⚑'

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

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Cscope setting
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"autoloading functionality for Cscope 
function! LoadCscope()
    let db = findfile("cscope.out", ".;")
    if (!empty(db))
        let path = strpart(db, 0, match(db, "/cscope.out$"))
        set nocscopeverbose " suppress 'duplicate connection' error
        exe "cs add " . db . " " . path
        set cscopeverbose
    endif
endfunction
"au BufEnter /* call LoadCscope()

" http://vimdoc.sourceforge.net/htmldoc/if_cscop.html#cscope-suggestions
if has("cscope")
    "specifies the command to execute cscope.
    set csprg=/usr/bin/cscope
    "0/1 search cscope/tag  db first.
    set csto=1
    "If 'cscopetag' set, the commands ":tag" and CTRL-] as well as "vim -t"
    "will always use |:cstag| instead of the default :tag behavior.
    "set cst
"   "show verbose message
    set csverb
    "auto load Cscope DB
    au BufEnter /* call LoadCscope()
    "do not show verbose message
    set nocsverb

    nmap <C-_>s :cs find s <C-R>=expand("<cword>")<CR><CR>
    nmap <C-_>g :cs find g <C-R>=expand("<cword>")<CR><CR>
    nmap <C-_>c :cs find c <C-R>=expand("<cword>")<CR><CR>
    nmap <C-_>t :cs find t <C-R>=expand("<cword>")<CR><CR>
    nmap <C-_>e :cs find e <C-R>=expand("<cword>")<CR><CR>
    nmap <C-_>f :cs find f <C-R>=expand("<cfile>")<CR><CR>
    nmap <C-_>i :cs find i ^<C-R>=expand("<cfile>")<CR>$<CR>
    nmap <C-_>d :cs find d <C-R>=expand("<cword>")<CR><CR>

    " Using 'CTRL-spacebar' then a search type makes the vim window
    " split horizontally, with search result displayed in
    " the new window.
    nmap <C-Space>s :scs find s <C-R>=expand("<cword>")<CR><CR>
    nmap <C-Space>g :scs find g <C-R>=expand("<cword>")<CR><CR>
    nmap <C-Space>c :scs find c <C-R>=expand("<cword>")<CR><CR>
    nmap <C-Space>t :scs find t <C-R>=expand("<cword>")<CR><CR>
    nmap <C-Space>e :scs find e <C-R>=expand("<cword>")<CR><CR>
    nmap <C-Space>f :scs find f <C-R>=expand("<cfile>")<CR><CR>
    nmap <C-Space>i :scs find i ^<C-R>=expand("<cfile>")<CR>$<CR>
    nmap <C-Space>d :scs find d <C-R>=expand("<cword>")<CR><CR>

    " Hitting CTRL-space *twice* before the search type does a vertical
    " split instead of a horizontal one
    nmap <C-Space><C-Space>s
        \:vert scs find s <C-R>=expand("<cword>")<CR><CR>
    nmap <C-Space><C-Space>g
        \:vert scs find g <C-R>=expand("<cword>")<CR><CR>
    nmap <C-Space><C-Space>c
        \:vert scs find c <C-R>=expand("<cword>")<CR><CR>
    nmap <C-Space><C-Space>t
        \:vert scs find t <C-R>=expand("<cword>")<CR><CR>
    nmap <C-Space><C-Space>e
        \:vert scs find e <C-R>=expand("<cword>")<CR><CR>
    nmap <C-Space><C-Space>i
        \:vert scs find i ^<C-R>=expand("<cfile>")<CR>$<CR>
    nmap <C-Space><C-Space>d
        \:vert scs find d <C-R>=expand("<cword>")<CR><CR>

    set timeoutlen=4000
    "terminal time out
    set ttimeoutlen=100
endif

