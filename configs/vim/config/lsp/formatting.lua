local null_ls = require("null-ls")

-- local lsp_formatting = function(bufnr)
--     vim.lsp.buf.format({
--         filter = function(client)
--             -- apply whatever logic you want (in this example, we'll only use null-ls)
--             return client.name == "null-ls"
--         end,
--         bufnr = bufnr,
--     })
-- end
--
-- -- if you want to set up formatting on save, you can use this as a callback
-- local augroup = vim.api.nvim_create_augroup("LspFormatting", {})
--
-- -- add to your shared on_attach callback
-- local on_attach = function(client, bufnr)
--       if client.supports_method("textDocument/formatting") then
--         print('am I here')
--         vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
--         vim.api.nvim_create_autocmd("BufWritePre", {
--             group = augroup,
--             buffer = bufnr,
--             callback = function()
--                 lsp_formatting(bufnr)
--             end,
--         })
--       end
-- end

-- print(' we aight!')
local augroup = vim.api.nvim_create_augroup("LspFormatting", {})
local sources = {
  null_ls.builtins.formatting.stylua,
  null_ls.builtins.diagnostics.eslint,
  -- null_ls.builtins.completion.spell,
  null_ls.builtins.formatting.prettier,
  -- null_ls.builtins.formatting.prettier.with({
  --   env = {
  --     PRETTIERD_DEFAULT_CONFIG = vim.fn.expand("~/.prettierrc.js"),
  --   },
  --   filetypes = {
  --     "javascript", "typescript", "typescriptreact", "css", "scss", "html", "json", "yaml", "markdown", "graphql", "md", "txt",
  --   },
  -- }),
}

require("null-ls").setup({
  sources = sources,
  -- you can reuse a shared lspconfig on_attach callback here
  on_attach = function(client, bufnr)
    if client.supports_method("textDocument/formatting") then
      print(' we heree?')
      vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
      vim.api.nvim_create_autocmd("BufWritePre", {
        group = augroup,
        buffer = bufnr,
        callback = function()
          -- on 0.8, you should use vim.lsp.buf.format({ bufnr = bufnr }) instead
          vim.lsp.buf.format()
        end,
      })
    end
  end,
})
