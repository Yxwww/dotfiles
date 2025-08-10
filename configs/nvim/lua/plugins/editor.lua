return {
  {
    "neovim/nvim-lspconfig",
    ---LSP Server Settings
    ---@type lspconfig.options
    opts = {
      inlay_hints = {
        enabled = false,
      },
      servers = {
        vtsls = {
          enabled = true,
        },
        eslint = {
          enabled = false,
        },
        emmet_ls = {
          enabled = false,
        },
      },
    },
  },
  {
    "mini.pairs",
    enabled = false,
  },
  {
    "blink.cmp",
    event = "VeryLazy",
    opts = {
      completion = {
        accept = {
          auto_brackets = {
            enabled = false,
          },
        },
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
  {
    "tikhomirov/vim-glsl",
  },
  {
    "iamcco/markdown-preview.nvim",
  },
}
