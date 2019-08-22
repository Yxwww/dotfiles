" MARK: NERDTree
let g:NERDTreeWinSize=40
let g:NERDTreeMouseMode=2
let g:NERDTreeNodeDelimiter = "\u00a0"
let NERDTreeShowHidden=1
" let NERDTreeChDirMode=2
let g:ctrlp_dont_split = 'nerdtree'
let g:ctrlp_show_hidden = 1
nnoremap <leader>ne :NERDTreeToggle<cr>
nnoremap <leader>nf :NERDTreeFind<CR>
let g:NERDTreeMinimalUI=1
let g:NERDTreeCreatePrefix='silent keepalt keepjumps'
" nnoremap <buffer> <expr> - g:NERDTreeMapUpdir
let NERDTreeIgnore = []
for suffix in split(&suffixes, ',')
    let NERDTreeIgnore += [ escape(suffix, '.~') . '$' ]
endfor
let NERDTreeIgnore += ['^\.DS_Store$', '^\.pyc$','^\.bundle$', '^\.bzr$', '^\.git$', '^\.hg$', '^\.sass-cache$', '^\.svn$', '^\.$', '^\.\.$', '^Thumbs\.db$', '^\..next$']


" MARK: coc config
let g:coc_global_extensions = ['coc-prettier',
      \ 'coc-eslint', 'coc-json', 'coc-tsserver',
      \ 'coc-html', 'coc-css', 'coc-python', 
      \ 'coc-highlight', 'coc-rls']

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

nnoremap <space> /

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

" MARK: lightline 

" Update and show lightline but only if it's visible (e.g., not in Goyo)
function! MyFugitive()
	if exists("*fugitive#head")
		let _ = fugitive#head()
		return strlen(_) ? '| '._ : ''
	endif
	return ''
endfunction
let g:lightline = {
    \ 'colorscheme': 'PaperColor',
    \ 'active': {
    \   'left': [ [ 'mode', 'paste' ],
    \             [ 'fugitive', 'readonly', 'filename', 'modified' ] ],
    \   'right': [['lineinfo'], ['percent'], ['readonly', 'linter_warnings', 'linter_errors', 'linter_ok']]
    \ },
    \ 'component_expand': {
    \   'fugitive': 'MyFugitive'
    \ },
    \ 'component_type': {
    \   'readonly': 'error'
    \ },
    \ 'component_function': {
    \   'cocstatus': 'coc#status',
    \   'currentfunction': 'CocCurrentFunction'
    \ },
    \ }


" MARK: Fugitive 
" set previewheight=25
