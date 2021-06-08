let g:ale_linter_aliases = {'typescriptreact': 'typescript', 'javascriptreact': 'javascript'}
let b:ale_fixers = {'javascript': ['prettier', 'eslint'], 'typescript': ['prettier', 'eslint']}
let b:ale_linters = {'javascript': ['prettier', 'eslint'], 'typescript': ['prettier', 'eslint']}
let g:ale_fix_on_save = 1

let g:ale_sign_error = '✘'
let g:ale_sign_warning = '⚠'
highlight ALEErrorSign ctermbg=NONE ctermfg=red
highlight ALEWarningSign ctermbg=NONE ctermfg=yellow
