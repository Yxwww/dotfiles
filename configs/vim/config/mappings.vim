nnoremap <leader>- :edit <C-R>=empty(expand('%')) ? '.' : fnameescape(expand('%:p:h'))<CR><CR>

" MARK: Makefile
nnoremap <C-b> :!yarn build <cr>
" nnoremap <C-r> :make run <cr>

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
" nnoremap <C-h> <C-w>h
" nnoremap <C-j> <C-w>j
" nnoremap <C-k> <C-w>k
" nnoremap <C-l> <C-w>l

set hlsearch
nnoremap <f3> :set hlsearch!<cr>

nmap <leader>gs :Git<cr>
nmap <leader>gp! :Git push<cr>
" nmap <leader>go :!gh repo view --web<cr>
nmap <leader>go :GBrowse<cr>
nmap <leader>gc :Git commit<cr>
nmap <leader>fy :!yarn lint:format:fixcr>
nmap <leader>ga :Gwrite<cr>
nmap <leader>gl :Glog<cr>
nmap <leader>gd :Gdiff<cr>

" MARK: tabs
map <leader>tn :tabnew<cr>
map <leader>to :tabonly<cr>
map <leader>tc :tabclose
map <leader>tm :tabmove


" MARK: fzf
" nmap <leader>b :Buffers<CR>
" nmap <leader>ff :Files<CR>
" nmap <leader>fs :GFiles?<CR>
nnoremap <C-g> :Rg<Cr>

" MARK: telescope
" Find files using Telescope command-line sugar.
nnoremap <leader>ff <cmd>Telescope find_files<cr>
nnoremap <leader>fg <cmd>Telescope live_grep<cr>
nnoremap <leader>fb <cmd>Telescope buffers<cr>
nnoremap <leader>fh <cmd>Telescope help_tags<cr>
nnoremap <leader>gb <cmd>Telescope git_branches<cr>
nnoremap <leader>fs <cmd>Telescope git_status<cr>
nnoremap <leader>fr <cmd>Telescope lsp_references<cr>
nnoremap gr <cmd>Telescope lsp_references<cr>
nnoremap <space>s <cmd>Telescope lsp_dynamic_workspace_symbols<cr>
nnoremap <space>d <cmd>Telescope lsp_document_symbols<cr>
nnoremap <space>e <cmd>Telescope diagnostics<cr>


" MARK: Copy & Paste
noremap <leader>y "*y <CR>
noremap <leader>p "*p <CR>
noremap <leader>Y "+y <CR>
noremap <leader>P "+p <CR>

" MARK: LSP config (the mappings used in the default file don't quite work right)
nnoremap gd <cmd>lua vim.lsp.buf.definition()<CR>
nnoremap gD <cmd>lua vim.lsp.buf.declaration()<CR>
" nnoremap gr <cmd>lua vim.lsp.buf.references()<CR>
nnoremap gi <cmd>lua vim.lsp.buf.implementation()<CR>
" rename
nnoremap rn <cmd>lua vim.lsp.buf.rename()<CR>
" tsserver code action supports auto import
nnoremap ca <cmd>lua vim.lsp.buf.code_action()<CR> 

nnoremap K <cmd>lua vim.lsp.buf.hover()<CR>
nnoremap L <cmd>lua vim.diagnostic.open_float({ border = "rounded" })<CR>
nnoremap [e <cmd>lua vim.diagnostic.goto_prev()<CR>
nnoremap e] <cmd>lua vim.diagnostic.goto_next()<CR>
nnoremap fe <cmd>lua vim.lsp.buf.formatting()<CR>
nnoremap <C-k> <cmd>lua vim.lsp.buf.signature_help()<CR>
