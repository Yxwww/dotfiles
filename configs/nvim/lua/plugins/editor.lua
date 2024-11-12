return {
  {
    "neovim/nvim-lspconfig",
    ---@class PluginLspOpts
    ---@param opts PluginLspOpts
    opts = {
      inlay_hints = {
        enabled = false,
      },
      -- diagnostics = {
      --   update_in_insert = false,
      --   virtual_text = { spacing = 4, prefix = "●" },
      --   severity_sort = true,
      -- },
    },
  },
  { "hrsh7th/nvim-cmp", enabled = false },
  { "folke/flash.nvim", enabled = true },
  {
    "yetone/avante.nvim",
    event = "VeryLazy",
  },
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters = {
        markdownlint = {
          args = { "--config", "~/.markdownlint.jsonc" },
        },
      },
    },
  },
}
