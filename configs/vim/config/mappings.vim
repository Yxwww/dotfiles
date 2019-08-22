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
nmap <leader>z :GFiles<CR>
nnoremap <silent> <Leader>' :Files <C-R>=expand('%:h')<CR><CR>

" Mark: Clipper
let g:ClipperAddress='~/.clipper.sock'
noremap <leader>y :call system('nc -U ~/.clipper.sock', @0)<CR>
noremap <leader>p "*p
noremap <leader>Y "+y
noremap <leader>P "+p



