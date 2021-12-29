set textwidth=0                      " automatically hard wrap at 80 columns
" set wrapmargin=0
set cursorline                        " highlight current line
set tabstop=2                         " spaces per tab

set list                              " show whitespace
set listchars=nbsp:⦸                  " CIRCLED REVERSE SOLIDUS (U+29B8, UTF-8: E2 A6 B8)
set listchars+=tab:>•                " WHITE RIGHT-POINTING TRIANGLE (U+25B7, UTF-8: E2 96 B7)
                                       " + BOX DRAWINGS HEAVY TRIPLE DASH HORIZONTAL (U+2505, UTF-8: E2 94 85)
set listchars+=extends:»              " RIGHT-POINTING DOUBLE ANGLE QUOTATION MARK (U+00BB, UTF-8: C2 BB)
set listchars+=precedes:«             " LEFT-POINTING DOUBLE ANGLE QUOTATION MARK (U+00AB, UTF-8: C2 AB)
set listchars+=trail:•                " BULLET (U+2022, UTF-8: E2 80 A2)
set nojoinspaces                      " don't autoinsert two spaces after '.', '?', '!' for join command
set noshowmatch                       " don't jump between matching brackets

if has('linebreak')
  set linebreak                       " wrap long lines at characters in 'breakat'
endif

set number
if exists('+relativenumber')
	set relativenumber                  " show relative numbers in gutter
endif

set scrolloff=3                       " start scrolling 3 lines before edge of viewport
set shiftround                        " always indent by multiple of shiftwidth
set shiftwidth=2                      " spaces per tab (when shifting)

set shortmess+=a 		      " use abbreviations in messages eg. `[RO]` instead of `[readonly]`
set shortmess+=t                      " truncate file messages at start

""""""""""""""""""""""""""""""
" Returns true if paste mode is enabled
function! HasPaste()
  if &paste
    return 'PASTE MODE  '
  endif
  return ''
endfunction
" Always show the status line
set laststatus=2


" autocmd BufWritePre *.{js,ts,tsx,jsx} Neoformat
" let g:neoformat_try_formatprg = 1
" let g:neoformat_verbose = 1
" let g:neoformat_enabled_typescript = ['prettier']


" auto-format
autocmd BufWritePre *.js lua vim.lsp.buf.formatting_sync(nil, 1000)
autocmd BufWritePre *.json lua vim.lsp.buf.formatting_sync(nil, 1000)
autocmd BufWritePre *.ts lua vim.lsp.buf.formatting_sync(nil, 1000)
autocmd BufWritePre *.tsx lua vim.lsp.buf.formatting_sync(nil, 1000)
autocmd BufWritePre *.jsx lua vim.lsp.buf.formatting_sync(nil, 1000)
autocmd BufWritePre *.svelte lua vim.lsp.buf.formatting_sync(nil, 1000)
autocmd BufWritePre *.lua lua vim.lsp.buf.formatting_sync(nil, 1000)
autocmd BufWritePre *.py lua vim.lsp.buf.formatting_sync(nil, 1000)


