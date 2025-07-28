-- LSP configuration with conditional disabling based on environment variable
local disable_lsp = vim.env.NVIM_NO_LSP == "1"

if disable_lsp then
  -- Disable all LSP-related plugins when NVIM_NO_LSP=1
  return {
    { "neovim/nvim-lspconfig", enabled = false },
    { "williamboman/mason.nvim", enabled = false },
    { "williamboman/mason-lspconfig.nvim", enabled = false },
    { "hrsh7th/cmp-nvim-lsp", enabled = false },
    { "nvimtools/none-ls.nvim", enabled = false },
    { "stevearc/conform.nvim", enabled = false },
    { "mfussenegger/nvim-lint", enabled = false },
    { "folke/trouble.nvim", enabled = false },
    { "folke/neodev.nvim", enabled = false },
    { "folke/neoconf.nvim", enabled = false },
    { "b0o/SchemaStore.nvim", enabled = false },
  }
else
  -- Return empty table to use default LSP configuration
  return {}
end