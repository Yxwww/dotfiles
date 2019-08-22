" sets how many lines of history vim has to remember
set history=500
set autoread 			       " set to auto read when a file is changed from the outside

if exists('$SUDO_USER')
  set nobackup                        " don't create root-owned files
  set nowritebackup                   " don't create root-owned files
else
  let vimtmp = $HOME . '/.vim/tmp/' . 'backup'
  silent! call mkdir(vimtmp, "p", 0700)
  set backupdir=~/local/.vim/tmp/backup
  set backupdir+=~/.vim/tmp/backup    " keep backup files out of the way
  set backupdir+=.
endif

if exists('&belloff')
  set belloff=all                     " never ring the bell for any reason
endif

if has('linebreak')
  set breakindent                     " indent wrapped lines to match start
  if exists('&breakindentopt')
    set breakindentopt=shift:2        " emphasize broken lines by indenting them
  endif
endif

if exists('+colorcolumn')
  " Highlight up to 255 columns (this is the current Vim max) beyond 'textwidth'
  let &l:colorcolumn='+' . join(range(0, 254), ',+')
endif

" swp file directory
if exists('$SUDO_USER')
  set noswapfile                      " don't create root-owned files
else
  let vimtmp = $HOME . '/.vim/tmp/' . 'swap'
  silent! call mkdir(vimtmp, "p", 0700)
  set directory=~/local/.vim/tmp/swap/
  set directory+=~/.vim/tmp/swap/    " keep swap files out of the way
  set directory+=.
endif

set expandtab                         " always use spaces instead of tabs

if has('folding')
  if has('windows')
    set fillchars=vert:┃              " BOX DRAWINGS HEAVY VERTICAL (U+2503, UTF-8: E2 94 83)
  endif
  set foldmethod=syntax               " not as cool as syntax, but faster
  set foldlevelstart=99               " start unfolded
  set foldtext=wincent#settings#foldtext()
endif

if v:version > 703 || v:version == 703 && has('patch541')
  set formatoptions+=j                " remove comment leader when joining comment lines
endif

