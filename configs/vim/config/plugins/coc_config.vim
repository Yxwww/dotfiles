" MARK: coc config
"

" autocmd BufNew,BufEnter *.json,*.vim,*.lua,*.frag,*.vert,*.glsl execute "silent! CocDisable"
" autocmd BufLeave *.json,*.vim,*.lua,*.frag,*.vert,*.glsl execute "silent! CocEnable"

let g:coc_global_extensions = ['coc-prettier',
      \ 'coc-eslint', 'coc-json', 'coc-tsserver',
      \ 'coc-html', 'coc-stylelint', 'coc-python', 
      \ 'coc-highlight', 'coc-snippets', 'coc-rls']
" force_debug forces coc to use local built libray instead of prebuild library that fetched from server.
" Usually when using coc we are using the prebuild one from server with `./install.sh nightly`. However, if we turn this on (set it to 1). This will cause "compiled javascript file not found!" error if we call coc#util#install without running "yarn install" in coc directory first.
let g:coc_force_debug = 0

" imap <tab> <Plug>(coc-snippets-expand)
" Use <C-j> to select text for visual text of snippet.
" vmap <C-b> <Plug>(coc-snippets-select)
" Use <C-j> to jump to forward placeholder, which is default
let g:coc_snippet_next = '<c-j>'
" Use <C-k> to jump to backward placeholder, which is default
let g:coc_snippet_prev = '<c-k>'

" if hidden not set, TextEdit might fail.
set hidden

" Better display for messages
set cmdheight=2

" Smaller updatetime for CursorHold & CursorHoldI
set updatetime=300

" don't give |ins-completion-menu| messages.
set shortmess+=c

" always show signcolumns
set signcolumn=yes

" Use <c-space> for trigger completion.
" inoremap <silent><expr> <c-space> coc#refresh()

" nnoremap <space> /

" Use <cr> for confirm completion, `<C-g>u` means break undo chain at current position.
" Coc only does snippet and additional edit on confirm.
inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"

" Use `[c` and `]c` for navigate diagnostics
nmap <silent> [c <Plug>(coc-diagnostic-prev)
nmap <silent> ]c <Plug>(coc-diagnostic-next)

" Remap keys for gotos
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" Use K for show documentation in preview window
nnoremap <silent> K :call <SID>show_documentation()<CR>

function! s:show_documentation()
  if &filetype == 'vim'
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction

" Highlight symbol under cursor on CursorHold
" autocmd CursorHold * silent call CocActionAsync('highlight')

" Remap for rename current word
nmap <leader>rn <Plug>(coc-rename)

" Remap for format selected region
" creates :CE command to call eslint.executeAutofix. map <leader>ef to :CE
command! -nargs=0 CE :CocCommand eslint.executeAutofix
nmap <leader>ef  :CE<cr>
vmap <leader>f  <Plug>(coc-format-selected)
nmap <leader>f  <Plug>(coc-format-selected)

" Find symbol of current document
nnoremap <silent> <space>o  :<C-u>CocList outline<cr>
" Search workspace symbols
nnoremap <silent> <space>s  :<C-u>CocList -I symbols<cr>
" Use `:Fold` to fold current buffer
command! -nargs=? Fold :call     CocAction('fold', <f-args>)

augroup mygroup
  autocmd!
  " Setup formatexpr specified filetype(s).
  autocmd FileType typescript,json setl formatexpr=CocAction('formatSelected')
  " Update signature help on jump placeholder
  autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
augroup end

