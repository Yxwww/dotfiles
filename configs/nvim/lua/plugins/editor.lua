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
    init = function()
      require("avante_lib").load()
    end,
    event = "VeryLazy",
    -- we want to use head for now, since the releases are not frequent
    version = false,
    opts = {
      hints = { enabled = false },
    },
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
