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

