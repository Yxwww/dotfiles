return {
  {
    "neovim/nvim-lspconfig",
    ---@class PluginLspOpts
    ---@param opts PluginLspOpts
    opts = {
      inlay_hints = {
        enabled = false,
      },
    },
  },
  { "hrsh7th/nvim-cmp", enabled = false },
  { "folke/flash.nvim", enabled = true },
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
