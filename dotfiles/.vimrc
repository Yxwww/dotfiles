" Specify a directory for plugins
" - For Neovim: ~/.local/share/nvim/plugged
" - Avoid using standard Vim directory names like 'plugin'
call plug#begin('~/.vim/plugged')

" file explorer
Plug 'scrooloose/nerdtree'

" git
Plug 'tpope/vim-fugitive'

" Plug 'w0rp/ale'
Plug 'elzr/vim-json'
Plug 'kien/ctrlp.vim'

Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'

Plug 'mileszs/ack.vim'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-sensible'
Plug 'tpope/vim-repeat'
Plug 'tomtom/tcomment_vim'

" Life
Plug 'vimwiki/vimwiki'

" syntax highlight
Plug 'pangloss/vim-javascript'
Plug 'maxmellon/vim-jsx-pretty'
Plug 'leafgarland/typescript-vim'
Plug 'plasticboy/vim-markdown'
Plug 'posva/vim-vue'
"
" themes
Plug 'NLKNguyen/papercolor-theme'

" autocompletion
Plug 'neoclide/coc.nvim', {'tag': '*', 'do': { -> coc#util#install()}}

" ui
Plug 'itchyny/lightline.vim'

" misc
Plug 'ashisha/image.vim'

" Initialize plugin system
call plug#end()

" Required:
filetype plugin indent on

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => General
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Open vimrc into a split window
nnoremap <leader>ev :vsplit $MYVIMRC<cr>

" System clipboard copy paste
noremap <Leader>y "*y
noremap <Leader>p "*p
noremap <Leader>Y "+y
noremap <Leader>P "+p

" prettier
nmap <Leader>py <Plug>(Prettier)
autocmd FileType javascript,typescript set formatprg=npx\ prettier-eslint\ --stdin
" autocmd FileType javascript set formatprg=prettier-eslint\ --stdin
" autocmd BufWritePre *.js Neoformat
" function! neoformat#formatters#javascript#prettiereslint() abort
"   return {
"         \ 'exe': 'eslint',
"         \ 'args': ['--fix'],
"         \ }
" endfunction

" window management
:nnoremap <leader>vs :vs<cr>
:nnoremap <leader>sp :sp<cr>

" MARK: jsx config
let g:jsx_ext_required = 1

" MARK: emmet config
let g:user_emmet_leader_key='<Tab>'
let g:user_emmet_settings = {
\  'javascript' : {
\      'extends' : 'jsx',
\  },
\}
" let g:user_emmet_settings = {
"   \  'javascript.jsx' : {
"     \      'extends' : 'jsx',
"     \  },
"   \}

" read workds
nnoremap <silent> <key> :<C-u>call system('say ' . expand('<cword>'))<CR>
"
" vimwiki/vimwiki config
let wiki = {}
let wiki.path = '~/my-wiki/'
let wiki.nested_syntaxes = {'python': 'python', 'c++': 'cpp', 'javascript': 'javascript'}
let wiki.template_default = 'default'
let wiki.custom_wiki2html = 'vimwiki_markdown'
let wiki.template_ext = '.tpl'
let wiki.syntax = 'markdown'
let wiki.ext = '.md'
let g:vimwiki_list = [wiki]

" force load syntax from the start of the page,
" does fix syntax losing issue, but lose performance
" autocmd BufEnter * :syntax sync fromstart

" fix vim losing syntax
" autocmd BufEnter * :syntax sync fromstart

" insert current time in insert mode
:inoremap <F5> <C-R>=strftime("%c")<CR>

" matchtagalways % go to other end of tag
nnoremap <leader>% :MtaJumpToOtherTag<cr>
" with a map leader it's possible to do extra key combinations
" like <leader>w saves the current file
let mapleader = ","
let g:mapleader = ","

" enable syntax highlighting
syntax enable

" disable undo file
":set noundofile
" disable swp file
":set noswapfile

" enable 256 colors palette in gnome terminal
" if $colorterm == 'gnome-terminal'
"     set t_co=256
" endif
"
" set background=dark
"
" if filereadable(expand("~/.vimrc_background"))
"     let base16colorspace=256
"     source ~/.vimrc_background
" endif
"
" try
"     colorscheme base16-tomorrow-night
" catch
"     echo "unable to find theme"
" endtry
set background=light
let g:rehash256 = 1 " Something to do with Molokai?
if (has("termguicolors"))
  set termguicolors
endif
set t_Co=256
colorscheme PaperColor
if !has('gui_running')
  if $TERM == "xterm-256color" || $TERM == "screen-256color" || $COLORTERM == "gnome-terminal"
    set t_Co=256
  elseif has("terminfo")
    colorscheme default
    set t_Co=8
    set t_Sf=[3%p1%dm
    set t_Sb=[4%p1%dm
  else
    colorscheme default
    set t_Co=8
    set t_Sf=[3%dm
    set t_Sb=[4%dm
  endif
  " Disable Background Color Erase when within tmux - https://stackoverflow.com/q/6427650/102704
  if $TMUX != ""
    set t_ut=
  endif
endif
syntax on


" hybrid line number
set number
set relativenumber
" JSDoc Snippet mapping
let g:JSDocSnippetsMapping='<D-C>' " this allow us to cmd-shift-c on top of a function in Insert mode to generate JSDOC
" Config on mac vim
if has("gui_macvim")
    set guioptions-=r
    set guioptions-=L
    set guioptions=
endif

" ale
let g:ale_python_pylint_options = "--init-hook='import sys; sys.path.append(\".\")'"
let g:ale_fixers = {
\   'javascript': ['eslint'],
\   'css': ['prettier'],
\}
let g:ale_fix_on_save = 0
let g:ale_linter_aliases = {'jinja': 'html'}
let g:ale_linters = {
\   'javascript': ['eslint'],
\   'typescript': ['eslint'],
\   'python': ['flake8'],
\   'html': ['eslint'],
\   'css': [ 'stylelint'],
\   'scss': [ 'sass-lint'],
\   'jinja': [''],
\}
" alias ale linter to html
let g:ale_sign_column_always = 1
let g:ale_sign_error = '●' " Less aggressive than the default '>>'
let g:ale_sign_warning = '.'
let g:ale_lint_on_enter = 0 " Less distracting when opening a new file
highlight clear ALEErrorSign
highlight clear ALEWarningSign
let g:ale_statusline_format = ['⨉ %d', '⚠ %d', '⬥ ok']
let g:ale_echo_msg_error_str = 'E'
let g:ale_echo_msg_warning_str = 'W'
let g:ale_echo_msg_format = '[%linter%] %s [%severity%]'
let g:ale_echo_msg_error_str = 'E'
let g:ale_echo_msg_warning_str = 'W'
let g:ale_echo_msg_format = '[%linter%] %s [%severity%]'
let g:ale_change_sign_column_color = 0
let g:ale_sign_column_always = 0
" highlight SignColumn guibg=#383942
" highlight clear SignColumn
nmap <silent> <C-n> <Plug>(ale_previous_wrap)
nmap <silent> <C-N> <Plug>(ale_next_wrap)
" vim slow fix
set ttyfast
" Fugitive shortcut config
set previewheight=25
nmap <leader>f :ALEFix<cr>
nmap <leader>gs :Gstatus<cr>
nmap <leader>gp! :Gpush<cr>
nmap <leader>go :!git open<cr>
nmap <leader>gc :Gcommit<cr>
nmap <leader>ga :Gwrite<cr>
nmap <leader>gl :Glog<cr>
nmap <leader>gd :Gdiff<cr>
nmap <leader>vs :vs<cr>
nmap <leader>sp :sp<cr>

" coc
let g:coc_force_debug = 1


imap <C-l> <Plug>(coc-snippets-expand)
" Use <C-j> to select text for visual text of snippet.
vmap <C-j> <Plug>(coc-snippets-select)
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

" Use tab for trigger completion with characters ahead and navigate.
" Use command ':verbose imap <tab>' to make sure tab is not mapped by other plugin.
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Use <c-space> for trigger completion.
inoremap <silent><expr> <c-space> coc#refresh()

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
autocmd CursorHold * silent call CocActionAsync('highlight')

" Remap for rename current word
nmap <leader>rn <Plug>(coc-rename)

" Remap for format selected region
vmap <leader>f  <Plug>(coc-format-selected)
nmap <leader>f  <Plug>(coc-format-selected)

augroup mygroup
  autocmd!
  " Setup formatexpr specified filetype(s).
  autocmd FileType typescript,json setl formatexpr=CocAction('formatSelected')
  " Update signature help on jump placeholder
  autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
augroup end

" Remap for do codeAction of selected region, ex: `<leader>aap` for current paragraph
vmap <leader>a  <Plug>(coc-codeaction-selected)
nmap <leader>a  <Plug>(coc-codeaction-selected)

" Remap for do codeAction of current line
nmap <leader>ac  <Plug>(coc-codeaction)
" Fix autofix problem of current line
" nmap <leader>qf  <Plug>(coc-fix-current)

" Use `:Format` for format current buffer
command! -nargs=0 Format :call CocAction('format')

" Use `:Fold` for fold current buffer
command! -nargs=? Fold :call     CocAction('fold', <f-args>)

" Using CocList
" " Show all diagnostics
" nnoremap <silent> <space>a  :<C-u>CocList diagnostics<cr>
" " Manage extensions
" nnoremap <silent> <space>e  :<C-u>CocList extensions<cr>
" " Show commands
" nnoremap <silent> <space>c  :<C-u>CocList commands<cr>
" " Find symbol of current document
" nnoremap <silent> <space>o  :<C-u>CocList outline<cr>
" " Search workspace symbols
" nnoremap <silent> <space>s  :<C-u>CocList -I symbols<cr>
" " Do default action for next item.
" nnoremap <silent> <space>j  :<C-u>CocNext<CR>
" " Do default action for previous item.
" nnoremap <silent> <space>k  :<C-u>CocPrev<CR>
" " Resume latest coc list
" nnoremap <silent> <space>p  :<C-u>CocListResume<CR>

" Turn cursor into line for iTerm-2
let &t_SI = "\<Esc>]50;CursorShape=1\x7"
let &t_SR = "\<Esc>]50;CursorShape=2\x7"
let &t_EI = "\<Esc>]50;CursorShape=0\x7"
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
nmap <C-f>   :Ack! "\b<cword>\b" <CR>
" nmap <Leader>gg  :Ggrep! "\b<cword>\b" <CR>
" nmap <Esc>K   :Ggrep! "\b<cword>\b" <CR>

"fzf
fun! s:fzf_root()
    let path = finddir(".git", expand("%:p:h").";")
    return fnamemodify(substitute(path, ".git", "", ""), ":p:h")
endfun
set rtp+=/usr/local/opt/fzf " If installed using Homebrew
" let $FZF_DEFAULT_COMMAND = 'ag -a'
nmap ; :Buffers<CR>
nmap ' :exe 'Files ' . <SID>fzf_root()<CR>
" nmap <Leader>j :Files<CR>
" nmap <Leader>r :Tags<CR>
" nmap <C-p> :Files<CR>
nnoremap <silent> <C-p> :exe 'Files ' . <SID>fzf_root()<CR>
imap <c-x><c-l> <plug>(fzf-complete-line)

"ctrlp ignore file
let g:ctrlp_custom_ignore = '\v[\/](.Trash|.sass-cache|temp|build|node_modules|target|.storage|dist)|(\.(DS_STORE|pyc|swp|ico|git|svn|un\~))$'
let g:ctrlp_map = '<c-p>'
let g:ctrlp_working_path_mode='ra'
nmap <f8> :TagbarToggle<cr>
let g:tagbar_autofocus=1
set pastetoggle=<F2>

" force highlight from start
" noremap <F12> <Esc>:syntax sync fromstart<CR>
inoremap <F12> <C-o>:syntax sync fromstart<CR>

" MARK: Normal mode settings
" Avoid unintentional switches to Ex mode.
nmap Q q
noremap Y y$
nnoremap <silent> - :silent edit <C-R>=empty(expand('%')) ? '.' : fnameescape(expand('%:p:h'))<CR><CR>
nnoremap K <nop>
nnoremap <Tab> za

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
vnoremap <silent> <leader>r :call VisualSelection('replace', '')<CR> 

" xnoremap <C-h> <C-w>h
" xnoremap <C-j> <C-w>j
" xnoremap <C-k> <C-w>k
" xnoremap <C-l> <C-w>l

" MARK: editing mappings
" Remap VIM 0 to first non-blank character
map 0 ^

" Move a line of text using ALT+[jk] or Command+[jk] on mac
" nmap <M-j> mz:m+<cr>`z
" nmap <M-k> mz:m-2<cr>`z
" vmap <M-j> :m'>+<cr>`<my`>mzgv`yo`z
" vmap <M-k> :m'<-2<cr>`>my`<mzgv`yo`z

" if has("mac") || has("macunix")
"   nmap <D-j> <M-j>
"   nmap <D-k> <M-k>
"   vmap <D-j> <M-j>
"   vmap <D-k> <M-k>
" endif

" Delete trailing white space on save, useful for Python and CoffeeScript ;)
" func! DeleteTrailingWS()
"   exe "normal mz"
"   %s/\s\+$//ge
"   exe "normal `z"
" endfunc
" autocmd BufWrite *.py :call DeleteTrailingWS()
" autocmd BufWrite *.js :call DeleteTrailingWS()

" MARK: searches
map <space> /
set hlsearch!
nnoremap <f3> :set hlsearch!<cr>
nnoremap <expr> <F9> ':%s/\<'.expand('<cword>').'\>/<&>/g<CR>'
" nnoremap <Leader>s :%s/\<<C-r><C-w>\>//g<Left><Left>
set completeopt-=preview
set incsearch
set ignorecase
set smartcase

" TComment config
nnoremap <leader>c<Space> :TComment <CR>


" MARK: Typescript tsuquyomi
let g:tsuquyomi_use_vimproc=1 " required fix save on crash
" let g:tsuquyomi_completion_detail = 1
let g:tsuquyomi_disable_quickfix = 1
autocmd FileType typescript setlocal completeopt+=menu,preview




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

" open messages
nmap <leader>m :messages<cr>

" recommended fast saving
nmap <leader>sw :w!<cr>
noremap <Leader>s :update<CR>

nnoremap <Leader>x :xit<CR>j
" Leader mappings.

" <Leader><Leader> -- Open last buffer.
nnoremap <Leader><Leader> <C-^>

nnoremap <Leader>o :only<CR>

" <Leader>p -- Show the path of the current file (mnemonic: path; useful when
" you have a lot of splits and the status line gets truncated).
nnoremap <Leader>p :echo expand('%')<CR>

" <Leader>pp -- Like <Leader>p, but additionally yanks the filename and sends it
" off to Clipper.
nnoremap <Leader>pp :let @0=expand('%') <Bar> :Clip<CR> :echo expand('%')<CR>

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
  set foldlevelstart=1               " start unfolded
endif

if v:version > 703 || v:version == 703 && has('patch541')
  set formatoptions+=j                " remove comment leader when joining comment lines
endif

set formatoptions+=n                  " smart auto-indenting inside numbered lists
if has("gui_macvim")                  " turn on ligatures with gui macvim and using Fira Code
  set macligatures
  set guifont=Fira\ Code:h14
else                                  " if not on macvim use Fira Mono 
  set guifont=Fira\ Mono:h14
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
set listchars+=tab:▷┅                 " WHITE RIGHT-POINTING TRIANGLE (U+25B7, UTF-8: E2 96 B7)
                                      " + BOX DRAWINGS HEAVY TRIPLE DASH HORIZONTAL (U+2505, UTF-8: E2 94 85)
set listchars+=extends:»              " RIGHT-POINTING DOUBLE ANGLE QUOTATION MARK (U+00BB, UTF-8: C2 BB)
set listchars+=precedes:«             " LEFT-POINTING DOUBLE ANGLE QUOTATION MARK (U+00AB, UTF-8: C2 AB)
set listchars+=trail:•                " BULLET (U+2022, UTF-8: E2 80 A2)
set nojoinspaces                      " don't autoinsert two spaces after '.', '?', '!' for join command
set noshowmatch                       " don't jump between matching brackets
set number                            " show line numbers in gutter

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
:nmap <C-\> <C-w>200l

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

" MARK: Autocommands
if has('autocmd')
  augroup WincentAutocmds
    autocmd!

    " autocmd VimResized * execute "normal! \<c-w>="

    " http://vim.wikia.com/wiki/Detect_window_creation_with_WinEnter
    autocmd VimEnter * autocmd WinEnter * let w:created=1
    autocmd VimEnter * let w:created=1

    " Disable paste mode on leaving insert mode.
    autocmd InsertLeave * set nopaste

    if has('folding')
      " Like the autocmd described in `:h last-position-jump` but we add `:foldopen!`.
      autocmd BufWinEnter * if line("'\"") > 1 && line("'\"") <= line('$') | execute "normal! g`\"" | execute 'silent! ' . line("'\"") . 'foldopen!' | endif
    else
      autocmd BufWinEnter * if line("'\"") > 1 && line("'\"") <= line('$') | execute "normal! g`\"" | endif
    endif

    autocmd BufWritePost */spell/*.add silent! :mkspell! %
  augroup END
endif


" MARK: virtual env
" Function to activate a virtualenv in the embedded interpreter for
" omnicomplete and other things like that.
" function LoadVirtualEnv(path)
"     let activate_this = a:path . '/bin/activate_this.py'
"     if getftype(a:path) == "dir" && filereadable(activate_this)
"         python << EOF
" import vim
" activate_this = vim.eval('l:activate_this')
" execfile(activate_this, dict(__file__=activate_this))
" EOF
"     endif
" endfunction
"
" " Load up a 'stable' virtualenv if one exists in ~/.virtualenv
" let defaultvirtualenv = $HOME . "~/git/projects/splash/webstuff"
"
" " Only attempt to load this virtualenv if the defaultvirtualenv
" " actually exists, and we aren't running with a virtualenv active.
" if has("python")
"     if empty($VIRTUAL_ENV) && getftype(defaultvirtualenv) == "dir"
"         call LoadVirtualEnv(defaultvirtualenv)
"     endif
"   endif

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
    \   'fugitive': 'MyFugitive',
    \   'linter_warnings': 'LightlineLinterWarnings',
    \   'linter_errors': 'LightlineLinterErrors',
    \   'linter_ok': 'LightlineLinterOK'
    \ },
    \ 'component_type': {
    \   'readonly': 'error',
    \   'linter_warnings': 'warning',
    \   'linter_errors': 'error'
    \ },
    \ }

function! LightlineLinterWarnings() abort
  let l:counts = ale#statusline#Count(bufnr(''))
  let l:all_errors = l:counts.error + l:counts.style_error
  let l:all_non_errors = l:counts.total - l:all_errors
  return l:counts.total == 0 ? '' : printf('%d ◆', all_non_errors)
endfunction

function! LightlineLinterErrors() abort
  let l:counts = ale#statusline#Count(bufnr(''))
  let l:all_errors = l:counts.error + l:counts.style_error
  let l:all_non_errors = l:counts.total - l:all_errors
  return l:counts.total == 0 ? '' : printf('%d ✗', all_errors)
endfunction

function! LightlineLinterOK() abort
  let l:counts = ale#statusline#Count(bufnr(''))
  let l:all_errors = l:counts.error + l:counts.style_error
  let l:all_non_errors = l:counts.total - l:all_errors
  return l:counts.total == 0 ? '✓ ' : ''
endfunction

autocmd User ALELint call s:MaybeUpdateLightline()

" Update and show lightline but only if it's visible (e.g., not in Goyo)
function! s:MaybeUpdateLightline()
  if exists('#lightline')
    call lightline#update()
  end
endfunction

augroup AutoSyntastic
  autocmd!
  autocmd BufWritePost *.c,*.cpp call s:syntastic()
augroup END

function! MyReadonly()
  if &filetype == "help"
    return ""
  elseif &readonly
    return "l "
  else
    return ""
  endif
endfunction

function! MyFugitive()
  if exists("*fugitive#head")
    let _ = fugitive#head()
    return strlen(_) ? '| '._ : ''
  endif
  return ''
endfunction

function! MyFilename()
  return ('' != MyReadonly() ? MyReadonly() . ' ' : '') .
       \ ('' != expand('%') ? expand('%') : '[NoName]')
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
map <leader>ba :bufdo bd<cr>

map <leader>l :bnext<cr>
map <leader>h :bprevious<cr>

" Useful mappings for managing tabs
map <leader>tn :tabnew<cr>
map <leader>to :tabonly<cr>
map <leader>tc :tabclose
map <leader>tm :tabmove
map <leader>tl :tabnext<cr>
map <leader>a :tabnext<cr>
map <leader>d :tabprevious<cr>
map <leader>th :tabprevious<cr>

map <c-1> :1gt

" Let 'tl' toggle between this and the last accessed tab
let g:lasttab = 1
nmap <Leader>tl :exe "tabn ".g:lasttab<CR>
au TabLeave * let g:lasttab = tabpagenr()


" Opens a new tab with the current buffer's path
" Super useful when editing files in the same directory
map <leader>te :tabedit <c-r>=expand("%:p:h")<cr>/

" Switch CWD to the directory of the open buffer
" map <leader>cd :cd %:p:h<cr>:pwd<cr>

" Specify the behavior when switching between buffers
try
  set switchbuf=useopen,usetab,newtab
  set stal=2
catch
endtry

" Return to last edit position when opening files (You want this!)
" autocmd BufWritePost $MYVIMRC source $MYVIMRC
" au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif


" Don't close window, when deleting a buffer
command! Bclose call <SID>BufcloseCloseIt()
function! <SID>BufcloseCloseIt()
   let l:currentBufNum = bufnr("%")
   let l:alternateBufNum = bufnr("#")

   if buflisted(l:alternateBufNum)
     buffer #
   else
     bnext
   endif

   if bufnr("%") == l:currentBufNum
     new
   endif

   if buflisted(l:currentBufNum)
     execute("bdelete! ".l:currentBufNum)
   endif
endfunction

if has("multi_byte")
  if &termencoding == ""
    let &termencoding = &encoding
  endif
  set encoding=utf-8
  setglobal fileencoding=utf-8
  "setglobal bomb
  set fileencodings=ucs-bom,utf-8,latin1
endif

if filereadable(expand("./abbreviation.vim"))
  source ./abbreviation.vim
endif

