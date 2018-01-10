
" ESC to leave insert mode
tnoremap <Esc> <C-\><C-n>

nmap t<Enter> :bo vsp term://bash<CR>

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


