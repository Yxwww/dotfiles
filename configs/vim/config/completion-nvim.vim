let g:completion_auto_change_source=1
let g:completion_chain_complete_list = {
      \       'default' : {
      \           'default': [
      \               {'complete_items': ['lsp', 'snippet']},
      \               {'complete_items': ['path'], 'triggered_only': ['/']},
      \               {'mode': '<c-p>'},
      \               {'mode': '<c-n>'}
      \           ]
      \       }
      \   }
let g:completion_matching_strategy_list=['exact', 'substring', 'fuzzy']
let g:completion_enable_snippet='UltiSnips'
let g:completion_trigger_on_delete=1
