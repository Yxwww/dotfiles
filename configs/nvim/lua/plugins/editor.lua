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
  {
    "iguanacucumber/magazine.nvim",
    name = "nvim-cmp",
  },
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
