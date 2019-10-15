" MARK: plugged
call plug#begin('~/.vim/plugged')

Plug 'christoomey/vim-tmux-navigator'

Plug 'scrooloose/nerdtree'

Plug 'tpope/vim-fugitive'

Plug 'kien/ctrlp.vim'
Plug '/usr/local/opt/fzf'
Plug 'junegunn/fzf.vim'

Plug 'tpope/vim-surround'
Plug 'tpope/vim-sensible'
Plug 'tpope/vim-repeat'

Plug 'vimwiki/vimwiki'

Plug 'joshdick/onedark.vim'
Plug 'NLKNguyen/papercolor-theme'

Plug 'neoclide/coc.nvim', {'do': { -> coc#util#install()}}

Plug 'tomtom/tcomment_vim'

"Snippet
Plug 'honza/vim-snippets'
Plug 'joaohkfaria/vim-jest-snippets'

" syntax highlight
Plug 'sheerun/vim-polyglot'

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

autocmd BufNewFile,BufRead *.svelte set syntax=html ft=html
