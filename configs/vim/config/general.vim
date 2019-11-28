set laststatus=2                      " always show status line
set lazyredraw                        " don't bother updating screen during macro playback
set scrolljump=8        " Scroll 8 lines at a time at bottom/top
" sets how many lines of history vim has to remember
set history=500
set autoread 			       " set to auto read when a file is changed from the outside

set switchbuf=usetab                  " try to reuse windows/tabs when switching buffers

if !has('nvim')
	set ttymouse=xterm2
	set highlight+=@:ColorColumn          " ~/@ at end of window, 'showbreak'
	set highlight+=N:DiffText             " make current line number stand out a little
	set highlight+=c:LineNr               " blend vertical separators with line numbers<Paste>
endif

if has('termguicolors')
  set termguicolors                   " use guifg/guibg instead of ctermfg/ctermbg in terminal
  " hi Search guibg=darkGrey guifg=darkGreen
endif

if v:progname !=# 'vi'
  set softtabstop=-1                  " use 'shiftwidth' for tab/bs at end of line
endif

if has('windows')
  set splitbelow                      " open horizontal splits below current window
endif

if has('vertsplit')
  set splitright                      " open vertical splits to the right of the current window
endif

if exists('$SUDO_USER')
  ;cho 'SUDO USER!'
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

" MARK: search config
set ignorecase " set default to case insensitive search. Use: \C at the end of search to enable case sensitivity

