" NOTE: keep code commented out it will message up rendering

nnoremap <leader>ne :NERDTreeToggle<cr>
nnoremap <leader>nf :NERDTreeFind<CR>
let g:NERDTreeMinimalUI=1

" MARK: completion-nvim
" Set completeopt to have a better completion experience
set completeopt=menuone,noinsert,noselect
" Avoid showing message extra message when using completion
set shortmess+=c
