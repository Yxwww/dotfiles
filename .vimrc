set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" " alternatively, pass a path where Vundle should install plugins
" "call vundle#begin('~/some/path/here')
"
" " let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'
"
" " The following are examples of different formats supported.
" " Keep Plugin commands between vundle#begin/end.
" " plugin on GitHub repo
Plugin 'tpope/vim-fugitive'
"Plugin 'airblade/vim-gitgutter'
" " plugin from http://vim-scripts.org/vim/scripts.html
Plugin 'L9'
Plugin 'pangloss/vim-javascript'
"Plugin 'isRuslan/vim-es6'
"Plugin 'jelera/vim-javascript-syntax'
Plugin 'scrooloose/nerdtree'
Plugin 'w0rp/ale'
Plugin 'elzr/vim-json'
"Plugin 'scrooloose/syntastic'
"Plugin 'ervandew/supertab'
Plugin 'kien/ctrlp.vim'
"Plugin 'bling/vim-airline'
Plugin 'glench/vim-jinja2-syntax'
Plugin 'tpope/vim-surround'
"Plugin 'scrooloose/nerdcommenter'
Plugin 'tomtom/tcomment_vim'
Plugin 'majutsushi/tagbar'
"Plugin 'shougo/neocomplete.vim'
Plugin 'marijnh/tern_for_vim'
Plugin 'Valloric/YouCompleteMe'
Plugin 'andrewradev/inline_edit.vim' " open proxy buffer from html script tag with :InlineEdit
"Plugin 'easymotion/vim-easymotion'
"Plugin 'yggdroot/indentline'
Plugin 'cakebaker/scss-syntax.vim'
"Plugin 'gregsexton/matchtag'
Plugin 'othree/html5.vim'
"Plugin 'heavenshell/vim-jsdoc'
Plugin 'chriskempson/base16-vim'
Plugin 'tpope/vim-vinegar'
Plugin 'Valloric/MatchTagAlways'
" Bundle 'nikvdp/ejs-syntax'

" UI
" Plugin 'terryma/vim-smooth-scroll'

" Snippet
Plugin 'Sirver/ultisnips'
" Plugin 'webdesus/polymer-ide.vim'
Plugin 'jordwalke/JSDocSnippets'
Plugin 'alexbyk/vim-ultisnips-js-testing'
" END Snippet
"
"Plugin 'davidhalter/jedi-vim' " for python auto completion
" Plugin 'vim-airline/vim-airline'
" Plugin 'vim-airline/vim-airline-themes'
Plugin 'itchyny/lightline.vim'

Plugin 'vimwiki/vimwiki'
" Plugin 'tbabej/taskwiki'

Plugin 'gcmt/taboo.vim'
" Plugin 'xolox/vim-notes'
" Plugin 'xolox/vim-misc'

"" Git plugin not hosted on GitHub
" Plugin 'git://git.wincent.com/command-t.git'
" " git repos on your local machine (i.e. when working on your own plugin)
" Plugin 'file:///home/gmarik/path/to/plugin'
" " The sparkup vim script is in a subdirectory of this repo called vim.
" " Pass the path to set the runtimepath properly.
" Plugin 'rstacruz/sparkup', {'rtp': 'vim/'}
" " Install L9 and avoid a Naming conflict if you've already installed a
" " different version somewhere else.
" Plugin 'ascenator/L9', {'name': 'newL9'}
"
" " All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
" " To ignore plugin indent changes, instead use:
 filetype plugin on
" "
" " Brief help
" " :PluginList       - lists configured plugins
" " :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" " :PluginSearch foo - searches for foo; append `!` to refresh local cache
" " :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
" "
" " see :h vundle for more details or wiki for FAQ
" " Put your non-Plugin stuff after this line:
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Maintainer:
"       Amir Salihefendic
"       http://amix.dk - amix@amix.dk
"
" Version:
"       5.0 - 29/05/12 15:43:36
"
" Blog_post:
"       http://amix.dk/blog/post/19691#The-ultimate-Vim-configuration-on-Github
"
" Awesome_version:
"       Get this config, nice color schemes and lots of plugins!
"
"       Install the awesome version from:
"
"           https://github.com/amix/vimrc
"
" Syntax_highlighted:
"       http://amix.dk/vim/vimrc.html
"
" Raw_version:
"       http://amix.dk/vim/vimrc.txt
"


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => General
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" ejs filetype change
au BufNewFile,BufRead *.ejs set filetype=html

" vim wiki config
let wiki = {}
let wiki.nested_syntaxes = {'python': 'python', 'c++': 'cpp', 'javascript': 'javascript'}
let g:vimwiki_list = [wiki]

" force load syntax from the start of the page,
" does fix syntax losing issue, but lose performance
autocmd BufEnter * :syntax sync fromstart

" fix vim losing syntax
autocmd BufEnter * :syntax sync fromstart

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
if $colorterm == 'gnome-terminal'
    set t_co=256
endif

set background=dark

if filereadable(expand("~/.vimrc_background"))
    let base16colorspace=256
    source ~/.vimrc_background
endif

try
    colorscheme base16-tomorrow-night
catch
    echo "unable to find theme"
endtry


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
"let g:syntastic_error_symbol = '❌'
"let g:syntastic_style_error_symbol = '!?'
"let g:syntastic_warning_symbol = '!'
"let g:syntastic_style_warning_symbol = '💩'
let g:ale_python_pylint_options = "--init-hook='import sys; sys.path.append(\".\")'"
let g:ale_linter_aliases = {'jinja': 'html'}
let g:ale_linters = {
\   'javascript': ['eslint'],
\   'python': ['flake8'],
\   'html': [ 'htmlhint', 'eslint'],
\   'css': [ 'stylelint'],
\   'scss': [ 'stylelint'],
\   'jinja': [ 'htmlhint'],
\}
" alias ale linter to html
let g:ale_sign_column_always = 1
let g:ale_sign_error = '❌'
let g:ale_sign_warning = '⚠️'
highlight clear ALEErrorSign
highlight clear ALEWarningSign
let g:ale_statusline_format = ['⨉ %d', '⚠ %d', '⬥ ok']
let g:ale_echo_msg_error_str = 'E'
let g:ale_echo_msg_warning_str = 'W'
let g:ale_echo_msg_format = '[%linter%] %s [%severity%]'
let g:ale_echo_msg_error_str = 'E'
let g:ale_echo_msg_warning_str = 'W'
let g:ale_echo_msg_format = '[%linter%] %s [%severity%]'
" vim slow fix
set ttyfast
" Fugitive shortcut config
set previewheight=25
nmap <leader>gs :Gstatus<cr>
nmap <leader>gc :Gcommit<cr>
nmap <leader>ga :Gwrite<cr>
nmap <leader>gl :Glog<cr>
nmap <leader>gd :Gdiff<cr>
" Snippet
" YouCompleteMe and UltiSnips compatibility.
"   tern
autocmd FileType javascript setlocal omnifunc=tern#Complete
let g:UltiSnipsExpandTrigger = '<tab>'
let g:UltiSnipsJumpForwardTrigger = '<tab>'
let g:UltiSnipsJumpBackwardTrigger = '<S-Tab>'

" Prevent UltiSnips from removing our carefully-crafted mappings.
let g:UltiSnipsMappingsToIgnore = ['autocomplete']

if has('autocmd')
  augroup WincentAutocomplete
    autocmd!
    autocmd! User UltiSnipsEnterFirstSnippet
    "autocmd User UltiSnipsEnterFirstSnippet call autocomplete#setup_mappings()
    autocmd! User UltiSnipsExitLastSnippet
    "autocmd User UltiSnipsExitLastSnippet call autocomplete#teardown_mappings()
    Plugin 'honza/vim-snippets'
  augroup END
endif

" MARK: Plugins/YouCompleteMe
let g:ycm_auto_trigger = 1
" let g:ycm_path_to_python_interpreter =  '/usr/local/bin/python'
" the next line help setup python virtual env autocomplete (w/ Jedi) it ensures
" to use the current python file. (note: wait for a bit for Jedi to kickin
let g:ycm_python_binary_path = 'python'
let g:ycm_goto_buffer_command = 'vertical-split'
let g:ycm_server_keep_logfiles = 1
let g:ycm_server_use_vim_stdout = 1
let g:ycm_server_log_level = 'debug'
let g:ycm_key_list_select_completion = ['<C-j>', '<Down>']
let g:ycm_key_list_previous_completion = ['<C-k>', '<Up>']
let g:ycm_key_list_accept_completion = ['<C-y>']
" these are the tweaks i apply to ycm's config, you don't need them but they might help.
" " ycm gives you popups and splits by default that some people might not like, so these should tidy it up a bit for you.
 let g:ycm_add_preview_to_completeopt=0
 let g:ycm_confirm_extra_conf=0
 let g:ycm_autoclose_preview_window_after_completion=1



" Additional UltiSnips config.
"let g:UltiSnipsSnippetsDir = $HOME . '/.vim/ultisnips'
"let g:UltiSnipsSnippetDirectories = [
      "\ $HOME . '/.vim/ultisnips',
      "\ $HOME . '/.vim/ultisnips-private'
      "\ ]

" Additional YouCompleteMe config.
let g:ycm_complete_in_comments = 1
"let g:ycm_collect_identifiers_from_comments_and_strings = 1
let g:ycm_seed_identifiers_with_syntax = 1
nnoremap <leader>gt :YcmCompleter GoToDefinitionElseDeclaration<CR>

"let g:ycm_extra_conf_globlist = ['~/code/masochist-pages/*']

" Disable unhelpful semantic completions.
"let g:ycm_filetype_specific_completion_to_disable = {
      "\   'c': 1,
      "\   'gitcommit': 1,
      "\   'haskell': 1,
      "\   'javascript': 1,
      "\   'ruby': 1
      "\ }

let g:ycm_semantic_triggers = {
      \   'haskell': [
      \     '.',
      \     '(',
      \     ',',
      \     ', '
      \   ],
      \   'mail': [
      \     're!^Bcc:(.*, ?| ?)',
      \     're!^Cc:(.*, ?| ?)',
      \     're!^From:(.*, ?| ?)',
      \     're!^Reply-To:(.*, ?| ?)',
      \     're!^To:(.*, ?| ?)'
      \   ],
      \   'markdown': [
      \     ']('
      \   ],
      \  'css': [
      \     're!^\s{4}',
      \      're!:\s+'
      \   ],
      \   'html': ['<', '"', '</', ' '],
      \   'jinja': ['<', '"', '</', ' '],
      \   'vim' : ['re![_a-za-z]+[_\w]*\.'],
      \   'scss': [ 're!^\s{4}', 're!:\s+' ],
      \   'cs,java,javascript,d,python,perl6,scala,vb,elixir,go' : ['.'],
      \ }

" Same as default, but with "mail", "markdown" and "text" removed.
let g:ycm_filetype_blacklist = {
      \   'notes': 1,
      \   'unite': 1,
      \   'tagbar': 1,
      \   'pandoc': 1,
      \   'qf': 1,
      \   'vimwiki': 1,
      \   'infolog': 1,
      \ }

"call defer#packadd('YouCompleteMe', 'youcompleteme.vim')

" autoload when .vimrc saved , 'nested' will keep powerline color
autocmd! BufWritePost vimrc nested :source ~/.vimrc
:nnoremap <silent> <F5> :let _s=@/ <Bar> :%s/\s\+$//e <Bar> :let @/=_s <Bar> :nohl <Bar> :unlet _s <CR>
"autocmd BufWritePre * %s/\s\+$//e
" open my vimrc file
:nnoremap <leader>ev :vsplit $MYVIMRC<cr>
" yank works with clipboard
set clipboard=unnamed
"set mouse=a


" Turn cursor into line for iTerm-2
let &t_SI = "\<Esc>]50;CursorShape=1\x7"
let &t_SR = "\<Esc>]50;CursorShape=2\x7"
let &t_EI = "\<Esc>]50;CursorShape=0\x7"
" enable omini function
filetype plugin on
set omnifunc=syntaxcomplete#Complete

" vim-javascript config
let g:javascript_plugin_jsdoc = 1

"ctrlp ignore file
let g:ctrlp_custom_ignore = '\v[\/](static|.Trash|.sass-cache|temp|build|lib|bower_components|node_modules|target|dist)|(\.(DS_STORE|pyc|swp|ico|git|svn|un\~))$'
let g:ctrlp_map = '<c-p>'
"let g:ctrlp_working_path_mode='ra'
nmap <f8> :TagbarToggle<cr>
let g:tagbar_autofocus=1
set pastetoggle=<F2>

" MARK: Normal mode settings
" Avoid unintentional switches to Ex mode.
nmap Q q
noremap Y y$
nnoremap <silent> - :silent edit <C-R>=empty(expand('%')) ? '.' : fnameescape(expand('%:p:h'))<CR><CR>
nnoremap K <nop>
nnoremap <Tab> za

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

xnoremap <C-h> <C-w>h
xnoremap <C-j> <C-w>j
xnoremap <C-k> <C-w>k
xnoremap <C-l> <C-w>l

" MARK: editing mappings
" Remap VIM 0 to first non-blank character
map 0 ^

" Move a line of text using ALT+[jk] or Command+[jk] on mac
nmap <M-j> mz:m+<cr>`z
nmap <M-k> mz:m-2<cr>`z
vmap <M-j> :m'>+<cr>`<my`>mzgv`yo`z
vmap <M-k> :m'<-2<cr>`>my`<mzgv`yo`z

if has("mac") || has("macunix")
  nmap <D-j> <M-j>
  nmap <D-k> <M-k>
  vmap <D-j> <M-j>
  vmap <D-k> <M-k>
endif

" Delete trailing white space on save, useful for Python and CoffeeScript ;)
func! DeleteTrailingWS()
  exe "normal mz"
  %s/\s\+$//ge
  exe "normal `z"
endfunc
autocmd BufWrite *.py :call DeleteTrailingWS()
autocmd BufWrite *.js :call DeleteTrailingWS()

" MARK: searches
map <Space> /
set hlsearch!
nnoremap <f3> :set hlsearch!<cr>
nnoremap <expr> <F9> ':%s/\<'.expand('<cword>').'\>/<&>/g<CR>'
nnoremap <Leader>s :%s/\<<C-r><C-w>\>//g<Left><Left>
set completeopt-=preview
set incsearch
set ignorecase
set smartcase

" TComment config
nnoremap <leader>c<Space> :TComment <CR>



" MARK: NERDTree
let g:NERDTreeMouseMode=2
let NERDTreeShowHidden=1
let NERDTreeChDirMode=2
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
let NERDTreeIgnore += ['^\.DS_Store$', '^\.pyc$','^\.bundle$', '^\.bzr$', '^\.git$', '^\.hg$', '^\.sass-cache$', '^\.svn$', '^\.$', '^\.\.$', '^Thumbs\.db$']


" sets how many lines of history vim has to remember
set history=500

" enable filetype plugins
filetype plugin on
filetype indent on

" set to auto read when a file is changed from the outside
set autoread


" MARK: Leader mapping
" fast saving
nmap <leader>w :w!<cr>
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

set autoindent                        " maintain indent of current line
set backspace=indent,start,eol        " allow unrestricted backspacing in insert mode

if exists('$SUDO_USER')
  set nobackup                        " don't create root-owned files
  set nowritebackup                   " don't create root-owned files
else
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

if exists('$SUDO_USER')
  set noswapfile                      " don't create root-owned files
else
  set directory=~/local/.vim/tmp/swap//
  set directory+=~/.vim/tmp/swap//    " keep swap files out of the way
  set directory+=.
endif

set expandtab                         " always use spaces instead of tabs

if has('folding')
  if has('windows')
    set fillchars=vert:┃              " BOX DRAWINGS HEAVY VERTICAL (U+2503, UTF-8: E2 94 83)
  endif
  set foldmethod=syntax               " not as cool as syntax, but faster
  set foldlevelstart=99               " start unfolded
endif

if v:version > 703 || v:version == 703 && has('patch541')
  set formatoptions+=j                " remove comment leader when joining comment lines
endif

set formatoptions+=n                  " smart auto-indenting inside numbered lists
"set guifont=Source\ Code\ Pro\ Light:h13
set guifont=Inconsolata\ for\ Powerline:h15

set guioptions-=T                     " don't show toolbar
set guioptions= 

set hidden                            " allows you to hide buffers with unsaved changes without being prompted
set highlight+=@:ColorColumn          " ~/@ at end of window, 'showbreak'
" set highlight+=N:DiffText             " make current line number stand out a little
set highlight+=c:LineNr               " blend vertical separators with line numbers
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
  hi Search guibg=darkGrey guifg=darkGreen
endif

set textwidth=0                      " automatically hard wrap at 80 columns
set wrapmargin=0
" let &colorcolumn="80,".join(range(120,255),"," )

if has('persistent_undo')
  if exists('$SUDO_USER')
    set noundofile                    " don't create root-owned files
  else
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

" MARK: lightline config
let g:lightline = {
      \ 'colorscheme': 'wombat',
      \ 'active': {
      \   'left': [ [ 'mode', 'paste' ],
      \             [ 'fugitive', 'readonly', 'filename', 'modified' ] ]
      \ },
      \ 'component_function': {
      \   'fugitive': 'MyFugitive',
      \   'readonly': 'MyReadonly',
      \   'filename': 'MyFilename',
      \ },
      \ 'separator': { 'left': '>', 'right': '<' },
      \ 'subseparator': { 'left': '>', 'right': '<' }
      \ }

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
"map <leader>te :tabedit <c-r>=expand("%:p:h")<cr>/

" Switch CWD to the directory of the open buffer
map <leader>cd :cd %:p:h<cr>:pwd<cr>

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
