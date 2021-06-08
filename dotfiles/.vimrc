" MARK: plugged
call plug#begin('~/.vim/plugged')

filetype plugin on

" base
" Plug 'nvim-lua/popup.nvim'
" Plug 'nvim-lua/plenary.nvim'


" MARK: Status line
Plug 'hoob3rt/lualine.nvim', {'commit': '82f68c42df9d11e52edb52c86113d0eba5be798d'} " use older version of lualine instad of updating neovim https://www.reddit.com/r/neovim/comments/mq2dfi/lualine_load_error/gydzgx8?utm_source=share&utm_medium=web2x&context=3
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
Plug 'ghifarit53/tokyonight-vim'
Plug 'NLKNguyen/papercolor-theme'
Plug 'haishanh/night-owl.vim'
Plug 'pineapplegiant/spaceduck', { 'branch': 'main' }

" lsp
Plug 'neovim/nvim-lspconfig'
" Plug 'glepnir/lspsaga.nvim'
Plug 'hrsh7th/nvim-compe'
" Plug 'onsails/lspkind-nvim'

" colourizer
" Plug 'norcalli/nvim-colorizer.lua'
Plug 'tomtom/tcomment_vim'

"Snippet
Plug 'SirVer/ultisnips'
Plug 'honza/vim-snippets'
Plug 'joaohkfaria/vim-jest-snippets'

" syntax highlight
Plug 'rhysd/vim-wasm'
Plug 'dense-analysis/ale'
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

" MARK: viml configs
for depFile in ['theme', 'wiki', 'abbreviation', 'plugin_config', 
      \ 'mappings', 'general', 'formatting', 'tmux', 'plugins/coc_config', 'plugins/fzf_config', 'plugins/ale',
      \ 'misc']
  let sourceFullDir = config_dir . '/' . depFile . '.vim'
  call SourceIfExists(sourceFullDir)
endfor

" Mark: Lua configs
for depFile in ['lualine', 'compe-config', 'lsp/all-lsp', 'bash-lsp', 'svelte-lsp', 'cssls', 'lsp/clangd']
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
