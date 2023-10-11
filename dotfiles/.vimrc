" MARK: plugged
call plug#begin('~/.vim/plugged')

filetype plugin on

" base
Plug 'nvim-lua/popup.nvim'
Plug 'nvim-lua/plenary.nvim'

" telescope
Plug 'nvim-telescope/telescope.nvim'
Plug 'nvim-telescope/telescope-fzf-native.nvim', { 'do': 'make' }

" MARK: Status line
Plug 'nvim-lualine/lualine.nvim'

" ui
Plug 'scrooloose/nerdtree'

" MARK: TMUX
Plug 'christoomey/vim-tmux-navigator'
Plug 'tpope/vim-fugitive'
Plug 'rbong/vim-flog'
Plug 'tpope/vim-rhubarb'

Plug 'ctrlpvim/ctrlp.vim'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

Plug 'windwp/nvim-autopairs'

Plug 'tpope/vim-surround'
Plug 'tpope/vim-dispatch'
Plug 'tpope/vim-sensible'
Plug 'tpope/vim-repeat'

" Plug 'vimwiki/vimwiki'


" Theme
Plug 'arcticicestudio/nord-vim'
Plug 'folke/tokyonight.nvim', { 'branch': 'main' }
Plug 'machakann/vim-highlightedyank'

" lsp
Plug 'williamboman/mason.nvim'
Plug 'williamboman/mason-lspconfig.nvim'
Plug 'neovim/nvim-lspconfig'
Plug 'nvimdev/lspsaga.nvim'
Plug 'lewis6991/gitsigns.nvim'



Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-cmdline'
Plug 'hrsh7th/nvim-cmp' " The completion 


" snippet
Plug 'L3MON4D3/LuaSnip'
Plug 'saadparwaiz1/cmp_luasnip' " snippet completions
Plug 'rafamadriz/friendly-snippets'

" syntax highlight
Plug 'sheerun/vim-polyglot'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'numToStr/Comment.nvim'

"Formatting
Plug 'jose-elias-alvarez/null-ls.nvim'

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

let lua_deps = ['cmp', 'lsp/init', 'lsp/formatting',  'luasnip' , 'treesitter', 'telescope', 'lualine', 'comment', 'common']

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
