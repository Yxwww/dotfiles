" MARK: plugged
call plug#begin('~/.vim/plugged')

" base
Plug 'nvim-lua/popup.nvim'
Plug 'nvim-lua/plenary.nvim'


" MARK: Status line
Plug 'hoob3rt/lualine.nvim'
" ui
Plug 'scrooloose/nerdtree'
" Plug 'kyazdani42/nvim-web-devicons'

" MARK: TMUX
Plug 'tmux-plugins/vim-tmux-focus-events'
Plug 'christoomey/vim-tmux-navigator'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-rhubarb'

Plug 'kien/ctrlp.vim'
Plug '/usr/local/opt/fzf'
Plug 'junegunn/fzf.vim'

Plug 'tpope/vim-surround'
Plug 'tpope/vim-dispatch'
Plug 'tpope/vim-sensible'
Plug 'tpope/vim-repeat'

Plug 'vimwiki/vimwiki'

Plug 'rakr/vim-one'
Plug 'NLKNguyen/papercolor-theme'
Plug 'haishanh/night-owl.vim'
Plug 'pineapplegiant/spaceduck', { 'branch': 'main' }

" lsp
Plug 'neovim/nvim-lspconfig'
Plug 'hrsh7th/nvim-compe'
Plug 'onsails/lspkind-nvim'

" LSP config (the mappings used in the default file don't quite work right)
nnoremap gd <cmd>lua vim.lsp.buf.definition()<CR>
nnoremap gD <cmd>lua vim.lsp.buf.declaration()<CR>
nnoremap gr <cmd>lua vim.lsp.buf.references()<CR>
nnoremap gi <cmd>lua vim.lsp.buf.implementation()<CR>
nnoremap rn <cmd>lua vim.lsp.buf.rename()<CR>
" tsserver code action supports auto import
nnoremap ca <cmd>lua vim.lsp.buf.code_action()<CR> 
nnoremap K <cmd>lua vim.lsp.buf.hover()<CR>
nnoremap L <cmd>lua vim.lsp.util.show_line_diagnostics()<CR>
nnoremap <C-k> <cmd>lua vim.lsp.buf.signature_help()<CR>
nnoremap <C-n> <cmd>lua vim.lsp.diagnostic.goto_prev()<CR>
nnoremap <C-p> <cmd>lua vim.lsp.diagnostic.goto_next()<CR>

inoremap <silent><expr> <C-Space> compe#complete()
inoremap <silent><expr> <CR>      compe#confirm('<CR>')
inoremap <silent><expr> <C-e>     compe#close('<C-e>')
inoremap <silent><expr> <C-f>     compe#scroll({ 'delta': +4 })
inoremap <silent><expr> <C-d>     compe#scroll({ 'delta': -4 })

highlight link CompeDocumentation NormalFloat

" auto-format
autocmd BufWritePre *.js lua vim.lsp.buf.formatting_sync(nil, 100)
autocmd BufWritePre *.ts lua vim.lsp.buf.formatting_sync(nil, 100)
autocmd BufWritePre *.svelte lua vim.lsp.buf.formatting_sync(nil, 100)
autocmd BufWritePre *.jsx lua vim.lsp.buf.formatting_sync(nil, 100)
autocmd BufWritePre *.tsx lua vim.lsp.buf.formatting_sync(nil, 100)
autocmd BufWritePre *.py lua vim.lsp.buf.formatting_sync(nil, 100)

Plug 'tomtom/tcomment_vim'

"Snippet
" Plug 'norcalli/snippets.nvim'
Plug 'SirVer/ultisnips'
Plug 'honza/vim-snippets'
Plug 'joaohkfaria/vim-jest-snippets'

" syntax highlight
Plug 'rhysd/vim-wasm'
Plug 'HerringtonDarkholme/yats.vim'
Plug 'tikhomirov/vim-glsl'
Plug 'evanleck/vim-svelte'
Plug 'pangloss/vim-javascript'
Plug 'kristijanhusak/vim-carbon-now-sh'
Plug 'rust-lang/rust.vim'
Plug 'mxw/vim-jsx'


call plug#end()

" Required:
filetype plugin indent on

let mapleader = ","
let g:mapleader = ","

" MARK: Soucing depdendencies
function! SourceIfExists(path) 
  if filereadable(expand(a:path))
    exec 'source ' . a:path
  else
    echo 'depdendency ' . a:path . ' not found'
  endif
endfunction

function! SourceIfExistsLua(path) 
  if filereadable(expand(a:path))
    exec 'luafile ' . a:path
  else
    echo 'lua depdendency ' . a:path . ' not found'
  endif
endfunction

let config_dir = '~/.vim/config'

for depFile in ['theme', 'wiki', 'abbreviation', 'plugin_config', 
      \ 'mappings', 'general', 'formatting', 'tmux', 'plugins/coc_config', 'plugins/fzf_config',
      \ 'misc']
  let sourceFullDir = config_dir . '/' . depFile . '.vim'
  call SourceIfExists(sourceFullDir)
endfor

for depFile in ['lualine','compe-config', 'bash-lsp', 'python-lsp', 'ts-lsp', 'svelte-lsp', 'snippets', 'ccls', 'cssls']
  let sourceFullDir = config_dir . '/' . depFile . '.lua'
  call SourceIfExistsLua(sourceFullDir)
endfor

" Open last opened filee: https://vim.fandom.com/wiki/Open_the_last_edited_file
" Go to last file(s) if invoked without arguments.
autocmd VimLeave * nested if (!isdirectory($HOME . "/.vim")) |
    \ call mkdir($HOME . "/.vim") |
    \ endif |
    \ execute "mksession! " . $HOME . "/.vim/Session.vim"

autocmd VimEnter * nested if argc() == 0 && filereadable($HOME . "/.vim/Session.vim") |
    \ execute "source " . $HOME . "/.vim/Session.vim"

if executable("rg")
  set grepprg=rg\ --vimgrep
endif

if !has('nvim')
  finish
endif
