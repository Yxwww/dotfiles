return {
  {
    "neovim/nvim-lspconfig",
    ---@class PluginLspOpts
    ---@param opts PluginLspOpts
    opts = {
      servers = {
        -- tsserver got renamed to ts_ls. disabled it in favour of vtsls
        ts_ls = {
          enabled = false,
        },
      },
      inlay_hints = {
        enabled = false,
      },
      diagnostics = {
        update_in_insert = false,
        virtual_text = { spacing = 4, prefix = "●" },
        severity_sort = true,
      },
    },
    -- dependencies = { "saghen/blink.cmp" },
    -- config = function(_, opts)
    --   local lspconfig = require("lspconfig")
    --   for server, config in pairs(opts.servers) do
    --     config.capabilities = require("blink.cmp").get_lsp_capabilities(config.capabilities)
    --     lspconfig[server].setup(config)
    --   end
    -- end,
  },
  { "hrsh7th/nvim-cmp", enabled = false },
  { "folke/flash.nvim", enabled = false },
  -- {
  --   "zbirenbaum/copilot.lua",
  --   config = function()
  --     require("copilot").setup({
  --       suggestion = { enabled = false },
  --       panel = { enabled = false },
  --     })
  --   end,
  -- },
  -- {
  --   "zbirenbaum/copilot-cmp",
  --   dependencies = { "zbirenbaum/copilot.lua" },
  --   config = function()
  --     require("copilot_cmp").setup()
  --   end,
  -- },
  {
    "saghen/blink.cmp",
    event = "VeryLazy",
    -- lazy = false, -- lazy loading handled internally
    -- -- optional: provides snippets for the snippet source
    -- dependencies = "rafamadriz/friendly-snippets",
    --
    -- -- use a release tag to download pre-built binaries
    -- version = "v0.*",
    -- -- OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
    -- -- build = 'cargo build --release',
    -- -- On musl libc based systems you need to add this flag
    -- -- build = 'RUSTFLAGS="-C target-feature=-crt-static" cargo build --release',
    --
    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      keymap = { preset = "enter" },

      highlight = {
        -- sets the fallback highlight groups to nvim-cmp's highlight groups
        -- useful for when your theme doesn't support blink.cmp
        -- will be removed in a future release, assuming themes add support
        use_nvim_cmp_as_default = true,
      },
      -- set to 'mono' for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
      -- adjusts spacing to ensure icons are aligned
      nerd_font_variant = "mono",
    },
  },
  {
    "yetone/avante.nvim",
    event = "VeryLazy",
    opts = {
      -- add any opts here
      behavior = {
        -- auto_suggestions = true,
      },
    },
  },
}
