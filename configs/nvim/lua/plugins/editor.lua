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
    on_attach = function(client, bufnr)
      vim.notify("attached!")
      if vim.api.nvim_buf_line_count(bufnr) > 10000 then
        vim.notify(vim.api.nvim_buf_line_count(bufnr))
        client.stop()
      end
    end,
  },
  { "hrsh7th/nvim-cmp", enabled = false },
  {
    "saghen/blink.cmp",
    lazy = false, -- lazy loading handled internally
    -- optional: provides snippets for the snippet source
    dependencies = "rafamadriz/friendly-snippets",

    -- use a release tag to download pre-built binaries
    version = "v0.*",
    -- OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
    -- build = 'cargo build --release',
    -- On musl libc based systems you need to add this flag
    -- build = 'RUSTFLAGS="-C target-feature=-crt-static" cargo build --release',

    opts = {
      -- keymap = {
      -- show = "<C-f>",
      -- accept = "<CR>",
      -- select_prev = { "<Up>", "<C-p>" },
      -- select_next = { "<Down>", "<C-n>" },
      -- scroll_documentation_up = "<C-k>",
      -- scroll_documentation_down = "<C-j>",
      -- },
      highlight = {
        -- sets the fallback highlight groups to nvim-cmp's highlight groups
        -- useful for when your theme doesn't support blink.cmp
        -- will be removed in a future release, assuming themes add support
        use_nvim_cmp_as_default = true,
      },
      -- set to 'mono' for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
      -- adjusts spacing to ensure icons are aligned
      nerd_font_variant = "normal",

      -- experimental auto-brackets support
      -- accept = { auto_brackets = { enabled = true } }

      -- experimental signature help support
      -- trigger = { signature_help = { enabled = true } }
    },
  },
  -- {
  --   "iguanacucumber/magazine.nvim",
  --   name = "nvim-cmp",
  -- },
  -- {
  --   "hrsh7th/nvim-cmp",
  --   opts = {
  --     performance = {
  --       debounce = 60,
  --       throttle = 30,
  --       fetching_timeout = 500,
  --     },
  --     completion = {
  --       keyword_length = 2,
  --     },
  --   },
  --   on_attach = function()
  --     vim.print("attached!")
  --   end,
  -- },
  {
    "yetone/avante.nvim",
    event = "VeryLazy",
    lazy = false,
    version = false, -- set this if you want to always pull the latest change
    opts = {
      -- add any opts here
    },
    -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
    build = "make",
    -- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" -- for windows
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "stevearc/dressing.nvim",
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      --- The below dependencies are optional,
      "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
      "zbirenbaum/copilot.lua", -- for providers='copilot'
      {
        -- support for image pasting
        "HakonHarnes/img-clip.nvim",
        event = "VeryLazy",
        opts = {
          -- recommended settings
          default = {
            embed_image_as_base64 = false,
            prompt_for_file_name = false,
            drag_and_drop = {
              insert_mode = true,
            },
            -- required for Windows users
            use_absolute_path = true,
          },
        },
      },
      {
        -- Make sure to set this up properly if you have lazy=true
        "MeanderingProgrammer/render-markdown.nvim",
        opts = {
          file_types = { "markdown", "Avante" },
        },
        ft = { "markdown", "Avante" },
      },
    },
  },
}
