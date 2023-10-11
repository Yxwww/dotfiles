require("mason").setup({
   log_level = vim.log.levels.INFO,
   check_outdated_packages_on_open = true,
})
require("mason-lspconfig").setup({
   ensure_installed = { "lua_ls", "rust_analyzer", "tsserver", "svelte" },
})

local on_attach = function(client, bufnr)
  -- format on save
  if client.server_capabilities.documentFormattingProvider then
    vim.api.nvim_create_autocmd("BufWritePre", {
      group = vim.api.nvim_create_augroup("Format", { clear = true }),
      buffer = bufnr,
      callback = function() vim.lsp.buf.formatting_seq_sync() end
    })
  end
end


require('lspconfig').rust_analyzer.setup {}
require("lspconfig").tsserver.setup {
   on_attach,
}
require("lspconfig").lua_ls.setup {}
require("lspconfig").svelte.setup {}
require('lspsaga').setup({})


