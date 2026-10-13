" herdr / tmux / plain navigation dispatch for vim.
"
" Loads exactly one implementation based on the environment, so the herdr module
" and vim-tmux-navigator never both own <C-h/j/k/l>:
"
"   $HERDR_PANE_ID set -> herdr module (crosses into neighbouring herdr panes,
"                         and still falls back to tmux/plain at its own edges)
"   $TMUX set          -> vim-tmux-navigator's own mappings / TmuxNavigate*
"   neither            -> nothing here; plain wincmd is vim's built-in behaviour
"
" Sourced from .vimrc after plug#end(). See configs/herdr/README.md.

if empty($HERDR_PANE_ID)
  finish
endif

if filereadable(expand('~/git/vim-herdr-navigation/editor/vim.vim'))
  source ~/git/vim-herdr-navigation/editor/vim.vim
endif
