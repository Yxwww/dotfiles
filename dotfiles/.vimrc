" Specify a directory for plugins
" - For Neovim: ~/.local/share/nvim/plugged
" - Avoid using standard Vim directory names like 'plugin'
call plug#begin('~/.vim/plugged')

" file explorer
Plug 'scrooloose/nerdtree'
"
" Tmux
Plug 'christoomey/vim-tmux-navigator'

" git
Plug 'tpope/vim-fugitive'

Plug 'kien/ctrlp.vim'

Plug '/usr/local/opt/fzf'
Plug 'junegunn/fzf.vim'
Plug 'wincent/ferret'
Plug 'wincent/vcs-jump'
Plug 'wincent/terminus'


Plug 'rking/ag.vim'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-sensible'
Plug 'tpope/vim-repeat'
Plug 'tomtom/tcomment_vim'

" Life
Plug 'vimwiki/vimwiki'

"Snippet
Plug 'honza/vim-snippets'
Plug 'joaohkfaria/vim-jest-snippets'

" syntax highlight
Plug 'sheerun/vim-polyglot'

" themes
Plug 'joshdick/onedark.vim'

" autocompletion
Plug 'neoclide/coc.nvim', {'do': { -> coc#util#install()}}

" ui
Plug 'itchyny/lightline.vim'

" Initialize plugin system
call plug#end()

" Required:
filetype plugin indent on

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => General
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
autocmd BufNewFile,BufRead *.svelte set syntax=html ft=html


" MARK: Cursor Config
" tmux will only forward escape sequences to the terminal if surrounded by a DCS sequence
" http://sourceforge.net/mailarchive/forum.php?thread_name=AANLkTinkbdoZ8eNR1X2UobLTeww1jFrvfJxTMfKSq-L%2B%40mail.gmail.com&forum_name=tmux-users
" NOTE: cursor chagne on mode switching is a terminal feature. MacOS
" terminal does not support cursor change

set guicursor=n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50
  \,a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor
  \,sm:block-blinkwait175-blinkoff150-blinkon175
if exists('$TMUX')
  let &t_SI = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=1\x7\<Esc>\\"
  let &t_SR = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=2\x7\<Esc>\\"
  let &t_EI = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=0\x7\<Esc>\\"
else
  " Turn cursor into line for iTerm-2
  let &t_SI = "\<Esc>]50;CursorShape=1\x7"
  let &t_SR = "\<Esc>]50;CursorShape=2\x7"
  let &t_EI = "\<Esc>]50;CursorShape=0\x7"
endif

" MARK: Tmux Config
let g:tmux_navigator_no_mappings = 1

nnoremap <silent> <C-l> :TmuxNavigateLeft<cr>
nnoremap <silent> <C-j> :TmuxNavigateDown<cr>
nnoremap <silent> <C-k> :TmuxNavigateUp<cr>
nnoremap <silent> <C-l> :TmuxNavigateRight<cr>
" nnoremap <silent> {Previous-Mapping} :TmuxNavigatePrevious<cr>

" MARK: jsx config
let g:jsx_ext_required = 1

" MARK: emmet config
let g:user_emmet_leader_key='<Tab>'
let g:user_emmet_settings = {
\  'javascript' : {
\      'extends' : 'jsx',
\  },
\}

" force load syntax from the start of the page,
" does fix syntax losing issue, but lose performance
" autocmd BufEnter * :syntax sync fromstart

" fix vim losing syntax
" autocmd BufEnter * :syntax sync fromstart

" insert current time in insert mode
:inoremap <F5> <C-R>=strftime("%c")<CR>

" with a map leader it's possible to do extra key combinations
" like <leader>w saves the current file
let mapleader = ","
let g:mapleader = ","
" syntax on

" vim slow fix
set ttyfast
" Fugitive shortcut config
set previewheight=25
nmap <leader>gs :Gstatus<cr>
nmap <leader>gp! :Gpush<cr>
nmap <leader>go :!git open<cr>
nmap <leader>gc :Gcommit<cr>
nmap <leader>ga :Gwrite<cr>
nmap <leader>gl :Glog<cr>
nmap <leader>gd :Gdiff<cr>

" MARK: coc config
"
let g:coc_global_extensions = ['coc-prettier',
      \ 'coc-eslint', 'coc-json', 'coc-tsserver',
      \ 'coc-html', 'coc-css', 'coc-python', 
      \ 'coc-highlight']
" force_debug forces coc to use local built libray instead of prebuild library that fetched from server.
" Usually when using coc we are using the prebuild one from server with `./install.sh nightly`. However, if we turn this on (set it to 1). This will cause "compiled javascript file not found!" error if we call coc#util#install without running "yarn install" in coc directory first.
let g:coc_force_debug = 0

imap <tab> <Plug>(coc-snippets-expand)
" Use <C-j> to select text for visual text of snippet.
vmap <C-b> <Plug>(coc-snippets-select)
" Use <C-j> to jump to forward placeholder, which is default
let g:coc_snippet_next = '<c-j>'
" Use <C-k> to jump to backward placeholder, which is default
let g:coc_snippet_prev = '<c-k>'

" if hidden not set, TextEdit might fail.
set hidden

" Better display for messages
set cmdheight=2

" Smaller updatetime for CursorHold & CursorHoldI
set updatetime=300

" don't give |ins-completion-menu| messages.
set shortmess+=c

" always show signcolumns
set signcolumn=yes

" Use <c-space> for trigger completion.
" inoremap <silent><expr> <c-space> coc#refresh()

" Use <cr> for confirm completion, `<C-g>u` means break undo chain at current position.
" Coc only does snippet and additional edit on confirm.
inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"

" Use `[c` and `]c` for navigate diagnostics
nmap <silent> [c <Plug>(coc-diagnostic-prev)
nmap <silent> ]c <Plug>(coc-diagnostic-next)

" Remap keys for gotos
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" Use K for show documentation in preview window
nnoremap <silent> K :call <SID>show_documentation()<CR>

function! s:show_documentation()
  if &filetype == 'vim'
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction

" Highlight symbol under cursor on CursorHold
" autocmd CursorHold * silent call CocActionAsync('highlight')

" Remap for rename current word
nmap <leader>rn <Plug>(coc-rename)

" Remap for format selected region
" creates :CE command to call eslint.executeAutofix. map <leader>ef to :CE
command! -nargs=0 CE :CocCommand eslint.executeAutofix
nmap <leader>ef  :CE<cr>
vmap <leader>f  <Plug>(coc-format-selected)
nmap <leader>f  <Plug>(coc-format-selected)


augroup mygroup
  autocmd!
  " Setup formatexpr specified filetype(s).
  autocmd FileType typescript,json setl formatexpr=CocAction('formatSelected')
  " Update signature help on jump placeholder
  autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
augroup end

" enable omini function
filetype plugin on
set omnifunc=syntaxcomplete#Complete

" vim-javascript config
let g:javascript_plugin_jsdoc = 1

"ack config
if executable('ag')
  let g:ackprg = 'ag --vimgrep'
  " let g:ackprg = 'ag --nogroup --nocolor --column'
endif
" nmap <M-k>    :Ack! "\b<cword>\b" <CR>
" nmap <C-f> :Ack "\b<cword>\b" <CR>
nmap <Leader>gg  :Ggrep! "\b<cword>\b" <CR>
nmap <C-f>  :Ggrep! "\b<cword>\b" <CR>

"fzf
fun! s:fzf_root()
    let path = finddir(".git", expand("%:p:h").";")
    return fnamemodify(substitute(path, ".git", "", ""), ":p:h")
endfun
set rtp+=/usr/local/opt/fzf " If installed using Homebrew
" let $FZF_DEFAULT_COMMAND = 'ag -a'
nmap ; :Buffers<CR>
nmap ' :exe 'Files ' . <SID>fzf_root()<CR>
nnoremap <silent> <C-p> :exe 'Files ' . <SID>fzf_root()<CR>
imap <c-x><c-l> <plug>(fzf-complete-line)

"ctrlp ignore file
let g:ctrlp_custom_ignore = '\v[\/](.Trash|.sass-cache|temp|build|node_modules|target|.storage|dist)|(\.(DS_STORE|pyc|swp|ico|git|svn|un\~))$'
let g:ctrlp_map = '<c-p>'
let g:ctrlp_working_path_mode='ra'

" force highlight from start
" noremap <F12> <Esc>:syntax sync fromstart<CR>
inoremap <F12> <C-o>:syntax sync fromstart<CR>

" MARK: Normal mode settings
" Avoid unintentional switches to Ex mode.
nmap Q q
noremap Y y$
nnoremap <silent> - :silent edit <C-R>=empty(expand('%')) ? '.' : fnameescape(expand('%:p:h'))<CR><CR>
nnoremap K <nop>

" MARK: buffer movement
nnoremap <c-j> <c-w><c-j>
nnoremap <c-k> <c-w><c-k>
nnoremap <c-l> <c-w><c-l>
nnoremap <c-h> <c-w><c-h>

" MARK: Visual mode mappings.
""""""""""""""""""""""""""""""
" => Visual mode related
""""""""""""""""""""""""""""""
" Visual mode pressing * or # searches for the current selection
" Super useful! From an idea by Michael Naumann
vnoremap <silent> * :<C-u>call VisualSelection('', '')<CR>/<C-R>=@/<CR><CR>
vnoremap <silent> # :<C-u>call VisualSelection('', '')<CR>?<C-R>=@/<CR><CR>
" When you press <leader>r you can search and replace the selected text
" vnoremap <silent> <leader>r :call VisualSelection('replace', '')<CR> 

" MARK: searches
map <space> /
set hlsearch

" Backslash invokes ack.vim
nnoremap \ :Ag<SPACE>

nnoremap <f3> :set hlsearch!<cr>
nnoremap <expr> <F9> ':%s/\<'.expand('<cword>').'\>/<&>/g<CR>'
set completeopt-=preview
set incsearch
set ignorecase
set smartcase

" MARK: NERDTree
let g:NERDTreeMouseMode=2
let g:NERDTreeNodeDelimiter = "\u00a0"
let NERDTreeShowHidden=1
" let NERDTreeChDirMode=2
let g:ctrlp_dont_split = 'nerdtree'
let g:ctrlp_show_hidden = 1
nmap <leader>ne :NERDTreeToggle<cr>
nmap <leader>nf :NERDTreeFind<CR>
let g:NERDTreeMinimalUI=1
let g:NERDTreeCreatePrefix='silent keepalt keepjumps'
nmap <buffer> <expr> - g:NERDTreeMapUpdir
let NERDTreeIgnore = []
for suffix in split(&suffixes, ',')
    let NERDTreeIgnore += [ escape(suffix, '.~') . '$' ]
endfor
let NERDTreeIgnore += ['^\.DS_Store$', '^\.pyc$','^\.bundle$', '^\.bzr$', '^\.git$', '^\.hg$', '^\.sass-cache$', '^\.svn$', '^\.$', '^\.\.$', '^Thumbs\.db$', '^\..next$']


" sets how many lines of history vim has to remember
set history=500

" enable filetype plugins
filetype plugin on
filetype indent on

" set to auto read when a file is changed from the outside
set autoread


" MARK: Leader mapping
" Open vimrc into a split window
noremap <leader>ev :vsplit $MYVIMRC<cr>

" System clipboard copy paste
" noremap <leader>y "*y
" clipper config
let g:ClipperAddress='~/.clipper.sock'
noremap <leader>y :call system('nc -U ~/.clipper.sock', @0)<CR>
noremap <leader>p "*p
noremap <leader>Y "+y
noremap <leader>P "+p
"
" open messages
nmap <leader>m :messages<cr>

" recommended fast saving
noremap <Leader>s :update<CR>

nnoremap <Leader>x :xit<CR>j

nnoremap <Leader>q :quit<CR>
" MARK: vim settings from winston
scriptencoding utf-8

set smartindent
set autoindent                        " maintain indent of current line
set backspace=indent,start,eol        " allow unrestricted backspacing in insert mode

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

set cursorline                        " highlight current line

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

set formatoptions+=n                  " smart auto-indenting inside numbered lists
if has("gui_macvim")                  " turn on ligatures with gui macvim and using Fira Code
  set macligatures
  set guifont=Inconsolata:h14
else                                  " if not on macvim use Fira Mono 
  set guifont=Inconsolata:h14
endif

set guioptions-=T                     " don't show toolbar
set guioptions= 

set hidden                            " allows you to hide buffers with unsaved changes without being prompted

if !has('nvim')
  set highlight+=@:ColorColumn          " ~/@ at end of window, 'showbreak'
  " set highlight+=N:DiffText             " make current line number stand out a little
  set highlight+=c:LineNr               " blend vertical separators with line numbers
endif

set laststatus=2                      " always show status line
set lazyredraw                        " don't bother updating screen during macro playback
set scrolljump=8        " Scroll 8 lines at a time at bottom/top
let html_no_rendering=1 " Don't render italic, bold, links in HTML
set nocursorcolumn      " Don't paint cursor column

if has('linebreak')
  set linebreak                       " wrap long lines at characters in 'breakat'
endif

set list                              " show whitespace
set listchars=nbsp:⦸                  " CIRCLED REVERSE SOLIDUS (U+29B8, UTF-8: E2 A6 B8)
set listchars+=tab:>•                " WHITE RIGHT-POINTING TRIANGLE (U+25B7, UTF-8: E2 96 B7)
                                       " + BOX DRAWINGS HEAVY TRIPLE DASH HORIZONTAL (U+2505, UTF-8: E2 94 85)
set listchars+=extends:»              " RIGHT-POINTING DOUBLE ANGLE QUOTATION MARK (U+00BB, UTF-8: C2 BB)
set listchars+=precedes:«             " LEFT-POINTING DOUBLE ANGLE QUOTATION MARK (U+00AB, UTF-8: C2 AB)
set listchars+=trail:•                " BULLET (U+2022, UTF-8: E2 80 A2)
set nojoinspaces                      " don't autoinsert two spaces after '.', '?', '!' for join command
set noshowmatch                       " don't jump between matching brackets

set number
if exists('+relativenumber')
  set relativenumber                  " show relative numbers in gutter
endif

set scrolloff=3                       " start scrolling 3 lines before edge of viewport
set shiftround                        " always indent by multiple of shiftwidth
set shiftwidth=2                      " spaces per tab (when shifting)
set shortmess+=A                      " ignore annoying swapfile messages
set shortmess+=I                      " no splash screen
set shortmess+=O                      " file-read message overwrites previous
set shortmess+=T                      " truncate non-file messages in middle
set shortmess+=W                      " don't echo "[w]"/"[written]" when writing
set shortmess+=a                      " use abbreviations in messages eg. `[RO]` instead of `[readonly]`
set shortmess+=o                      " overwrite file-written messages
set shortmess+=t                      " truncate file messages at start

if has('linebreak')
  let &showbreak='⤷ '                 " ARROW POINTING DOWNWARDS THEN CURVING RIGHTWARDS (U+2937, UTF-8: E2 A4 B7)
endif

if has('showcmd')
  set showcmd                         " extra info at end of command line
endif

set sidescrolloff=3                   " same as scolloff, but for columns
set smarttab                          " <tab>/<BS> indent/dedent in leading whitespace

if v:progname !=# 'vi'
  set softtabstop=-1                  " use 'shiftwidth' for tab/bs at end of line
endif

if has('syntax')
  set spellcapcheck=                  " don't check for capital letters at start of sentence
endif

if has('windows')
  set splitbelow                      " open horizontal splits below current window
endif

if has('vertsplit')
  set splitright                      " open vertical splits to the right of the current window
endif

" goto right most window
nmap <C-\> <C-w>200l

set switchbuf=usetab                  " try to reuse windows/tabs when switching buffers
set tabstop=2                         " spaces per tab

if has('termguicolors')
  set termguicolors                   " use guifg/guibg instead of ctermfg/ctermbg in terminal
  " hi Search guibg=darkGrey guifg=darkGreen
endif

set textwidth=0                      " automatically hard wrap at 80 columns
set wrapmargin=0
" let &colorcolumn="80,".join(range(120,255),"," )

" undo file directory
if has('persistent_undo')
  if exists('$SUDO_USER')
    set noundofile                    " don't create root-owned files
  else
    let vimtmp = $HOME . '/.vim/tmp/' . 'undo'
    silent! call mkdir(vimtmp, "p", 0700)
    set undodir=~/local/.vim/tmp/undo
    set undodir+=~/.vim/tmp/undo      " keep undo files out of the way
    set undodir+=.
    set undofile                      " actually use undo files
  endif
endif

if has('viminfo')
  if exists('$SUDO_USER')
    set viminfo=                      " don't create root-owned files
  else
    if isdirectory('~/local/.vim/tmp')
      set viminfo+=n~/local/.vim/tmp/viminfo
    else
      set viminfo+=n~/.vim/tmp/viminfo " override ~/.viminfo default
    endif

    if !empty(glob('~/.vim/tmp/viminfo'))
      if !filereadable(expand('~/.vim/tmp/viminfo'))
        echoerr 'warning: ~/.vim/tmp/viminfo exists but is not readable'
      endif
    endif
  endif
endif

if has('mksession')
  if isdirectory('~/local/.vim/tmp')
    set viewdir=~/local/.vim/tmp/view
  else
    set viewdir=~/.vim/tmp/view       " override ~/.vim/view default
  endif
  set viewoptions=cursor,folds        " save/restore just these (with `:{mk,load}view`)
endif

if has('virtualedit')
  set virtualedit=block               " allow cursor to move where there is no text in visual block mode
endif
set visualbell t_vb=                  " stop annoying beeping for non-error errors
set whichwrap=b,h,l,s,<,>,[,],~       " allow <BS>/h/l/<Left>/<Right>/<Space>, ~ to cross line boundaries
set wildcharm=<C-z>                   " substitue for 'wildchar' (<Tab>) in macros
if has('wildignore')
  set wildignore+=*.o,*.rej           " patterns to ignore during file-navigation
endif
if has('wildmenu')
  set wildmenu                        " show options as list when switching buffers etc
endif
set wildmode=longest:full,full        " shell-like autocomplete to unambiguous portion

if !has('nvim')
  set ttymouse=xterm2
endif

let g:lightline = {
    \ 'colorscheme': 'PaperColor',
    \ 'active': {
    \   'left': [ [ 'mode', 'paste' ],
    \             [ 'fugitive', 'readonly', 'filename', 'modified' ] ],
    \   'right': [['lineinfo'], ['percent'], ['readonly', 'linter_warnings', 'linter_errors', 'linter_ok']]
    \ },
    \ 'component_expand': {
    \   'fugitive': 'MyFugitive'
    \ },
    \ 'component_type': {
    \   'readonly': 'error'
    \ },
    \ 'component_function': {
    \   'cocstatus': 'coc#status',
    \   'currentfunction': 'CocCurrentFunction'
    \ },
    \ }

" Update and show lightline but only if it's visible (e.g., not in Goyo)
function! MyFugitive()
  if exists("*fugitive#head")
    let _ = fugitive#head()
    return strlen(_) ? '| '._ : ''
  endif
  return ''
endfunction


""""""""""""""""""""""""""""""
" => Status line
""""""""""""""""""""""""""""""
" Always show the status line
set laststatus=2

" Format the status line
set statusline=\ %{HasPaste()}%F%m%r%h\ %w\ \ CWD:\ %r%{getcwd()}%h\ \ \ Line:\ %l\ \ Column:\ %c

" Helperfunctions
function! CmdLine(str)
    exe "menu Foo.Bar :" . a:str
    emenu Foo.Bar
    unmenu Foo
endfunction

function! VisualSelection(direction, extra_filter) range
    let l:saved_reg = @"
    execute "normal! vgvy"

    let l:pattern = escape(@", "\\/.*'$^~[]")
    let l:pattern = substitute(l:pattern, "\n$", "", "")

    if a:direction == 'gv'
        call CmdLine("Ag '" . l:pattern . "' " )
    elseif a:direction == 'replace'
        call CmdLine("%s" . '/'. l:pattern . '/')
    endif

    let @/ = l:pattern
    let @" = l:saved_reg
endfunction


" Returns true if paste mode is enabled
function! HasPaste()
    if &paste
        return 'PASTE MODE  '
    endif
    return ''
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Moving around, tabs, windows and buffers
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Close the current buffer
" map <leader>bd :Bclose<cr>:tabclose<cr>gT

" build
map <C-b> :make <cr>

" Close all the buffers
" map <leader>ba :bufdo bd<cr>
"
" map <leader>l :bnext<cr>
" map <leader>h :bprevious<cr>

" Useful mappings for managing tabs
map <leader>tn :tabnew<cr>
map <leader>to :tabonly<cr>
map <leader>tc :tabclose
map <leader>tm :tabmove

map <c-1> :1gt

" Let 'tl' toggle between this and the last accessed tab
" let g:lasttab = 1
" nmap <Leader>tl :exe "tabn ".g:lasttab<CR>
" au TabLeave * let g:lasttab = tabpagenr()


" Switch CWD to the directory of the open buffer
" map <leader>cd :cd %:p:h<cr>:pwd<cr>

" Return to last edit position when opening files (You want this!)
au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
autocmd BufWritePost $MYVIMRC source $MYVIMRC

" MARK: Soucing depdendencies

function! SourceIfExists(path) 
  if filereadable(expand(a:path))
    exec 'source ' . a:path
  endif
endfunction

let config_dir = '~/.vim/config'
let abbreviation = config_dir . '/abbreviation.vim'
call SourceIfExists(abbreviation)

let theme = config_dir . '/theme.vim'
call SourceIfExists(theme)

let wiki = config_dir . '/wiki.vim'
call SourceIfExists(wiki)

" if filereadable(expand(abbreviation))
"   echo "loaded abbreviation files"
"   source abbreviation
" endif

"Use 24-bit (true-color) mode in Vim/Neovim when outside tmux.
"If you're using tmux version 2.2 or later, you can remove the outermost $TMUX check and use tmux's 24-bit color support
"(see < http://sunaku.github.io/tmux-24bit-color.html#usage > for more information.)
if (empty($TMUX))
  if (has("nvim"))
    "For Neovim 0.1.3 and 0.1.4 < https://github.com/neovim/neovim/pull/2198 >
    let $NVIM_TUI_ENABLE_TRUE_COLOR=1
  endif
  "For Neovim > 0.1.5 and Vim > patch 7.4.1799 < https://github.com/vim/vim/commit/61be73bb0f965a895bfb064ea3e55476ac175162 >
  "Based on Vim patch 7.4.1770 (`guicolors` option) < https://github.com/vim/vim/commit/8a633e3427b47286869aa4b96f2bfc1fe65b25cd >
  " < https://github.com/neovim/neovim/wiki/Following-HEAD#20160511 >
  if (has("termguicolors"))
    set termguicolors
  endif
endif


