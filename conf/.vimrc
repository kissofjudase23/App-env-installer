""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Vundle
" https://github.com/VundleVim/Vundle.vim
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" http://www.erikzaadi.com/2012/03/19/auto-installing-vundle-from-your-vimrc/
" Setting up Vundle - the vim plugin bundler
" If the code below does not work,
" git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim

"let iCanHazVundle=1
"let vundle_readme=expand('~/.vim/bundle/vundle/README.md')
"if !filereadable(vundle_readme)
"   echo "Installing Vundle.."
"   echo ""
"   silent !mkdir -p ~/.vim/bundle
"  silent !git clone https://github.com/gmarik/vundle ~/.vim/bundle/vundle
"   let iCanHazVundle=0
"endif
"
set nocompatible  "iMproved, required 
filetype off      "required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
" call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
" https://github.com/VundleVim/Vundle.vim
Plugin 'VundleVim/Vundle.vim'

Plugin 'https://github.com/tpope/vim-fugitive.git'
Plugin 'https://github.com/vim-scripts/taglist.vim.git'
Plugin 'https://github.com/fatih/vim-go.git'
Plugin 'https://github.com/vim-scripts/python.vim.git'
Plugin 'https://github.com/scrooloose/nerdtree.git'
Plugin 'https://github.com/scrooloose/syntastic.git'
" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
" To ignore plugin indent changes, instead use:
" filetype plugin on
"
" <<<< Brief help>>>>
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to  auto-approve removal
" see :h vundle for more details or wiki for FAQ


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" general setting
" http://vimdoc.sourceforge.net/htmldoc/options.html for more
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
filetype plugin indent on    " enable filetype-specific plugins
set number                   " enable line numbers
set autoindent               " enable autoindent
"set expandtab                " use space instead of tab
set tabstop=4                " insert 4 spaces for a tab
"http://vi.stackexchange.com/questions/4244/what-is-softtabstop-used-for
set softtabstop=4
set shiftwidth=4             " the number of space characters inserted for
syntax enable                " enable syntax highlighting
set listchars=tab:>-,trail:~ 
set list                     " show invisible characters
set background=dark
set autoread                 " auto read when file is changed from outside
set history=50               " keep 50 lines of command line history
set cursorline               " show a visual lin under the cursor's current line
set clipboard=unnamed        " access system clipboard
set showmatch                " Cursor shows matching ) and }
set showmode                 " Show current mode
set backspace=2              " make backspace work like most other
set hlsearch                 " hightlight search parrtern  
set ruler             " show the line and column number of the cursor position
set background=dark   " when set to "dark", Vim will try to use colors that look
                      " good on a dark background
set cc=80
set splitbelow
set splitright
set encoding=utf-8

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
let Tlist_Auto_Highligh_Tag = 1 "Automatically highlight the current tag in
								"the taglist
"Open the taglist window when Vim starts.
"let Tlist_Auto_Open = 1
"Close Vim if the taglist is the only window
"let Tlist_Exit_OnlyWindow = 1

" map TlistToggle to <F3>
nnoremap <silent> <F3> :TlistToggle<CR>
" map TlistClose to <F4>
nnoremap <silent> <F4> :TlistClose<CR>


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" NETDTree setting
" use ':help NERD_tree.txt' to get more info
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" map NERDTreeToggle to <F5>
nnoremap <silent> <F5> :NERDTreeToggle<CR>
" map NERDTreeClose  to <F6>
nnoremap <silent> <F6> :NERDTreeClose<CR>
" default arrows
let g:NERDTreeDirArrowExpandable = '▸'
let g:NERDTreeDirArrowCollapsible = '▾'

"Open the NERDTree window when Vim starts.
"autocmd StdinReadPre * let s:std_in=1
"autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif
"Close Vim if the NETDTree is the only window
"autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") \
"&& b:NERDTree.isTabTree()) | q | endif


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Syntastic setting
" https://github.com/scrooloose/syntastic
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0

"Checker options
" use ':SyntasticInfo' to showwhich checkers are enabled.

"C option
let g:syntastic_c_include_dirs = [ '../lib/']
"C++ option
let g:syntastic_cpp_include_dirs = [ '../lib/']
"let g:syntastic_cpp_compiler_options = ' -std=c++0x'
"
"
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
"	"show verbose message
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

