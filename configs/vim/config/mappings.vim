nnoremap <leader>- :edit <C-R>=empty(expand('%')) ? '.' : fnameescape(expand('%:p:h'))<CR><CR>
"
map <C-b> :make <cr>

" open messages
nmap <leader>m :messages<cr>
nnoremap <Leader>ve :e $MYVIMRC<CR>
nnoremap <Leader>vr :source $MYVIMRC<CR>

nnoremap <Leader>s :update<CR>
nnoremap <Leader>x :xit<CR>j
nnoremap <Leader>q :quit<CR>

nnoremap <silent> <C-h> :TmuxNavigateLeft<cr>
nnoremap <silent> <C-j> :TmuxNavigateDown<cr>
nnoremap <silent> <C-k> :TmuxNavigateUp<cr>
nnoremap <silent> <C-l> :TmuxNavigateRight<cr>

set hlsearch
nnoremap <f3> :set hlsearch!<cr>

nmap <leader>gs :Gstatus<cr>
nmap <leader>gp! :Gpush<cr>
nmap <leader>go :!git open<cr>
nmap <leader>gc :Gcommit<cr>
nmap <leader>ga :Gwrite<cr>
nmap <leader>gl :Glog<cr>
nmap <leader>gd :Gdiff<cr>

" MARK: tabs
map <leader>tn :tabnew<cr>
map <leader>to :tabonly<cr>
map <leader>tc :tabclose
map <leader>tm :tabmove


" MARK: fzf
nmap ; :Buffers<CR>
nmap ' :Files<CR>
nnoremap <C-g> :Rg<Cr>

" Mark: Clipper
let g:ClipperAddress='~/.clipper.sock'
noremap <leader>y :call system('nc -U ~/.clipper.sock', @0)<CR>
noremap <leader>p "*p
noremap <leader>Y "+y
noremap <leader>P "+p

" MARK: coc
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
" Remap for rename current word
nmap <leader>rn <Plug>(coc-rename)

" Remap for format selected region
command! -nargs=0 CE :CocCommand eslint.executeAutofix
nmap <leader>ef  :CE<cr>
vmap <leader>f  <Plug>(coc-format-selected)
nmap <leader>f  <Plug>(coc-format-selected)

" MARK: visual mode
" Visual mode pressing * or # searches for the current selection
" Super useful! From an idea by Michael Naumann
vnoremap <silent> * :<C-u>call VisualSelection('', '')<CR>/<C-R>=@/<CR><CR>
vnoremap <silent> # :<C-u>call VisualSelection('', '')<CR>?<C-R>=@/<CR><CR>
