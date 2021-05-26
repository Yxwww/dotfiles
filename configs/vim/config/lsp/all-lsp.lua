local nnoremap = function (lhs, rhs)
  vim.api.nvim_buf_set_keymap(0, 'n', lhs, rhs, {noremap = true, silent = true})
end

local on_attach = function ()
  require'completion'.on_attach()
  local mappings = {
    ['<Leader>ld'] = '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>',
    ['<c-]>'] = '<cmd>lua vim.lsp.buf.definition()<CR>',
    ['K'] = '<cmd>lua vim.lsp.buf.hover()<CR>',
    ['gd'] = '<cmd>lua vim.lsp.buf.declaration()<CR>',
  }

  for lhs, rhs in pairs(mappings) do
    nnoremap(lhs, rhs)
  end

  vim.api.nvim_win_set_option(0, 'signcolumn', 'yes')
end

require'lspconfig'.tsserver.setup{on_attach=on_attach}
require'lspconfig'.vimls.setup{on_attach=on_attach}
require'lspconfig'.pyright.setup{on_attach=on_attach}
