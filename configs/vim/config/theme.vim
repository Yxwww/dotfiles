" enable syntax highlighting
syntax enable
let $NVIM_TUI_ENABLE_TRUE_COLOR=1
set t_Co=256

if exists('+termguicolors')
  let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
  let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
  " this is likely causing screen flickering in alarcritty
  " https://github.com/neovim/neovim/issues/2528#issuecomment-490734273
  set termguicolors 
endif

" Example config in VimScript
let g:tokyonight_style = "storm"
let g:tokyonight_italic_functions = 1
let g:tokyonight_italic_comments = 1
let g:tokyonight_italic_keywords = 1
let g:tokyonight_lualine_bold = 1

" Change the "hint" color to the "orange" color, and make the "error" color bright red

if system("defaults read -g AppleInterfaceStyle") =~ '^Dark'
  try
    colorscheme tokyonight
  catch /^Vim\%((\a\+)\)\=:E185/
    colorscheme default
    set background=dark
  endtry
else
  "True Color Support
  "Credit joshdick
  "Use 24-bit (true-color) mode in Vim/Neovim when outside tmux.
  "If you're using tmux version 2.2 or later, you can remove the outermost $TMUX check and use tmux's 24-bit color support
  "(see < http://sunaku.github.io/tmux-24bit-color.html#usage > for more information.)
  if (empty($TMUX))
    if (has("nvim"))
      "For Neovim 0.1.3 and 0.1.4 < https://github.com/neovim/neovim/pull/2198 >
      let $NVIM_TUI_ENABLE_TRUE_COLOR=1
    endif
  endif

  try
    set background=light
    colorscheme tokyonight
  catch /^Vim\%((\a\+)\)\=:E185/
    colorscheme default
    set background=light
  endtry
endif
