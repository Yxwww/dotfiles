" MARK: plugged
call plug#begin('~/.vim/plugged')

filetype plugin on

" base
Plug 'nvim-lua/popup.nvim'
Plug 'nvim-lua/plenary.nvim'

" telescope
Plug 'nvim-telescope/telescope.nvim'

" MARK: Status line
Plug 'nvim-lualine/lualine.nvim'

" ui
Plug 'scrooloose/nerdtree'

" MARK: TMUX
Plug 'tmux-plugins/vim-tmux-focus-events'
Plug 'christoomey/vim-tmux-navigator'
Plug 'tpope/vim-fugitive'
Plug 'rbong/vim-flog'
Plug 'tpope/vim-rhubarb'

" Plug 'kien/ctrlp.vim'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

Plug 'tpope/vim-surround'
Plug 'tpope/vim-dispatch'
Plug 'tpope/vim-sensible'
Plug 'tpope/vim-repeat'
Plug 'tomtom/tcomment_vim'

Plug 'vimwiki/vimwiki'


" Theme
Plug 'arcticicestudio/nord-vim'

" snippet
Plug 'L3MON4D3/LuaSnip'

" lsp
Plug 'neovim/nvim-lspconfig'
Plug 'williamboman/nvim-lsp-installer'
Plug 'hrsh7th/nvim-cmp' " The completion 
Plug 'hrsh7th/cmp-buffer' " buffer completions
Plug 'hrsh7th/cmp-path' " path completions
Plug 'hrsh7th/cmp-cmdline' " cmdline completions
Plug 'saadparwaiz1/cmp_luasnip' " snippet completions
Plug 'hrsh7th/cmp-nvim-lsp'


" syntax highlight
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'p00f/nvim-ts-rainbow'

"Formatting
Plug 'sbdchd/neoformat'

call plug#end()

set rtp+=~/.fzf

" Required:
filetype plugin indent on

let mapleader = ","
let g:mapleader = ","


let vim_deps = [
      \ 'theme', 'wiki', 'abbreviation',
      \ 'plugin_config', 
      \ 'mappings', 'general', 'formatting', 'tmux', 'plugins/fzf_config',
      \ 'misc']

let lua_deps = ['lsp/init', 'cmp', 'treesitter', 'telescope', 'lualine']


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
for depFile in vim_deps
  let sourceFullDir = config_dir . '/' . depFile . '.vim'
  call SourceIfExists(sourceFullDir)
endfor


" Mark: Lua configs
for depFile in lua_deps
  let sourceFullDir = config_dir . '/' . depFile . '.lua'
  call SourceIfExistsLua(sourceFullDir)
endfor


autocmd VimEnter * nested if argc() == 0 && filereadable($HOME . "/.vim/Session.vim") |
    \ execute "source " . $HOME . "/.vim/Session.vim"

if executable("rg")
  set grepprg=rg\ --vimgrep
endif

if !has('nvim')
  finish
endif
