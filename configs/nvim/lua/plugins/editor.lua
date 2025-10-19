return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    opts = {
      code = {
        enabled = false,
        sign = true,
        width = "block",
        right_pad = 1,
      },
    },
  },

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
        rust_analyzer = {
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
      linters_by_ft = {
        markdown = {},
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
