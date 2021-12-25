nnoremap <leader>- :edit <C-R>=empty(expand('%')) ? '.' : fnameescape(expand('%:p:h'))<CR><CR>

" MARK: Makefile
nnoremap <C-b> :make build <cr>
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

set hlsearch
nnoremap <f3> :set hlsearch!<cr>

nmap <leader>gs :Git<cr>
nmap <leader>gp! :Git push<cr>
nmap <leader>go :!hub browse<cr>
nmap <leader>gc :Git commit<cr>
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
nmap <leader>fs :GFiles?<CR>
nnoremap <C-g> :Rg<Cr>

" MARK: telescope
" Find files using Telescope command-line sugar.
nnoremap <leader>ff <cmd>Telescope find_files<cr>
nnoremap <leader>fg <cmd>Telescope live_grep<cr>
nnoremap <leader>fb <cmd>Telescope buffers<cr>
nnoremap <leader>fh <cmd>Telescope help_tags<cr>

" Using Lua functions
nnoremap <leader>ff <cmd>lua require('telescope.builtin').find_files()<cr>
nnoremap <leader>fg <cmd>lua require('telescope.builtin').live_grep()<cr>
nnoremap <leader>fb <cmd>lua require('telescope.builtin').buffers()<cr>
nnoremap <leader>fh <cmd>lua require('telescope.builtin').help_tags()<cr>

" MARK: Copy & Paste
noremap <leader>y "*y <CR>
noremap <leader>p "*p <CR>
noremap <leader>Y "+y <CR>
noremap <leader>P "+p <CR>

" MARK: coc
" Use <cr> for confirm completion, `<C-g>u` means break undo chain at current position.
" Coc only does snippet and additional edit on confirm.
" inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"

" Search for selected text, forwards or backwards.
vnoremap <silent> * :<C-U>
  \let old_reg=getreg('"')<Bar>let old_regtype=getregtype('"')<CR>
  \gvy/<C-R><C-R>=substitute(
  \escape(@", '/\.*$^~['), '\_s\+', '\\_s\\+', 'g')<CR><CR>
  \gV:call setreg('"', old_reg, old_regtype)<CR>
vnoremap <silent> # :<C-U>
  \let old_reg=getreg('"')<Bar>let old_regtype=getregtype('"')<CR>
  \gvy?<C-R><C-R>=substitute(
  \escape(@", '?\.*$^~['), '\_s\+', '\\_s\\+', 'g')<CR><CR>
  \gV:call setreg('"', old_reg, old_regtype)<CR>


" MARK: LSP config (the mappings used in the default file don't quite work right)
nnoremap gd <cmd>lua vim.lsp.buf.definition()<CR>
nnoremap gD <cmd>lua vim.lsp.buf.declaration()<CR>
nnoremap gr <cmd>lua vim.lsp.buf.references()<CR>
nnoremap gi <cmd>lua vim.lsp.buf.implementation()<CR>
" rename
nnoremap rn <cmd>lua vim.lsp.buf.rename()<CR>
" tsserver code action supports auto import
nnoremap ca <cmd>lua vim.lsp.buf.code_action()<CR> 

nnoremap K <cmd>lua vim.lsp.buf.hover()<CR>
nnoremap L <cmd>lua vim.lsp.diagnostic.show_line_diagnostics({ border = "rounded" })<CR>
nnoremap [e <cmd>lua vim.lsp.diagnostic.goto_prev({ border = "rounded" })<CR>
nnoremap e] <cmd>lua vim.lsp.diagnostic.goto_prev({ border = "rounded" })<CR>
" nnoremap <C-k> <cmd>lua vim.lsp.buf.signature_help()<CR>

highlight link CompeDocumentation NormalFloat

