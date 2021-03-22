" MARK: NERDTree
let g:NERDTreeWinSize=40
let g:NERDTreeMouseMode=2
let g:NERDTreeNodeDelimiter = "\u00a0"
let NERDTreeShowHidden=1
" let NERDTreeChDirMode=2
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


" Better display for messages
set cmdheight=2

" Smaller updatetime for CursorHold & CursorHoldI
set updatetime=300

" don't give |ins-completion-menu| messages.
set shortmess+=c

" always show signcolumns
set signcolumn=yes

" Highlight symbol under cursor on CursorHold
" autocmd CursorHold * silent call CocActionAsync('highlight')
" creates :CE command to call eslint.executeAutofix. map <leader>ef to :CE

" Update and show lightline but only if it's visible (e.g., not in Goyo)
function! MyFugitive()
	if exists("*fugitive#head")
		let _ = fugitive#head()
		return strlen(_) ? '| '._ : ''
	endif
	return ''
endfunction

function! CocCurrentFunction()
    return get(b:, 'coc_current_function', '')
endfunction

let g:lightline = {
    \ 'colorscheme': 'spaceduck',
    \ 'active': {
    \   'left': [ [ 'mode', 'paste' ],
    \             [ 'cocstatus','fugitive', 'filename', 'modified' ] ],
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
set previewheight=20 " set the hight of the preview window to 25

" MARK: ctrlp
"ctrlp ignore file
let g:ctrlp_dont_split = 'nerdtree'
let g:ctrlp_show_hidden = 1
let g:ctrlp_custom_ignore = '\v[\/](.Trash|.sass-cache|temp|build|node_modules|target|.storage|dist)|(\.(DS_STORE|pyc|swp|ico|git|svn|un\~))$'
let g:ctrlp_map = '<c-p>'
let g:ctrlp_working_path_mode='ra'

" MARK: emmet config
let g:user_emmet_settings = {
      \  'javascript' : {
      \      'extends' : 'jsx',
      \  },
      \}
