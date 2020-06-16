" MARK: plugged
call plug#begin('~/.vim/plugged')

Plug 'christoomey/vim-tmux-navigator'

Plug 'scrooloose/nerdtree'
" Plug 'justinmk/vim-dirvish'
"
" Plug 'kristijanhusak/vim-dirvish-git'
" Plug 'fsharpasharp/vim-dirvinist'
" let g:dirvish_mode = 1

Plug 'tpope/vim-fugitive'
" Plug 'jreybert/vimagit'
Plug 'tpope/vim-rhubarb'

Plug 'kien/ctrlp.vim'
Plug '/usr/local/opt/fzf'
Plug 'junegunn/fzf.vim'

Plug 'tpope/vim-surround'
Plug 'tpope/vim-dispatch'
Plug 'tpope/vim-sensible'
Plug 'tpope/vim-repeat'

Plug 'vimwiki/vimwiki'

" Plug 'chriskempson/base16-vim'
" Plug 'joshdick/onedark.vim'
" Plug 'vim-scripts/wombat256.vim'
" Plug 'NLKNguyen/papercolor-theme'
Plug 'morhetz/gruvbox'
Plug 'ayu-theme/ayu-vim'
Plug 'haishanh/night-owl.vim'

Plug 'neoclide/coc.nvim', {'do': { -> coc#util#install()}}

Plug 'tomtom/tcomment_vim'

"Snippet
Plug 'honza/vim-snippets'
Plug 'joaohkfaria/vim-jest-snippets'

" syntax highlight
Plug 'rhysd/vim-wasm'
Plug 'sheerun/vim-polyglot'
Plug 'evanleck/vim-svelte'
" Plug 'HerringtonDarkholme/yats.vim'
" ui
Plug 'itchyny/lightline.vim'

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

let config_dir = '~/.vim/config'

for depFile in ['theme', 'wiki', 'abbreviation', 'plugin_config', 
      \ 'mappings', 'general', 'formatting', 'tmux', 'plugins/coc_config', 'plugins/fzf_config',
      \ 'misc']
  let sourceFullDir = config_dir . '/' . depFile . '.vim'
  call SourceIfExists(sourceFullDir)
endfor

" autocmd BufNewFile,BufRead *.svelte set syntax=html ft=html
autocmd BufNewFile,BufRead *.tsx set syntax=typescript.jsx ft=typescriptreact

" Open last opened filee: https://vim.fandom.com/wiki/Open_the_last_edited_file
" Go to last file(s) if invoked without arguments.
autocmd VimLeave * nested if (!isdirectory($HOME . "/.vim")) |
    \ call mkdir($HOME . "/.vim") |
    \ endif |
    \ execute "mksession! " . $HOME . "/.vim/Session.vim"

autocmd VimEnter * nested if argc() == 0 && filereadable($HOME . "/.vim/Session.vim") |
    \ execute "source " . $HOME . "/.vim/Session.vim"


if !has('nvim')
  finish
endif
