return {
  {
    "stevearc/oil.nvim",
    ---@module 'oil'
    ---@type oil.SetupOpts
    keys = {
      { "-", "<CMD>Oil<CR>", desc = "Open parent directory" },
    },
    opts = {
      -- Buffer-local options to use for oil buffers
      view_options = {
        -- Show files and directories that start with "."
        show_hidden = true,
      },
      keymaps = {
        -- ["g?"] = { "actions.show_help", mode = "n" },
        -- ["<CR>"] = "actions.select",
        ["<C-s>"] = false,
        ["<C-h>"] = false,
        -- ["<C-t>"] = { "actions.select", opts = { tab = true } },
        -- ["<C-p>"] = "actions.preview",
        -- ["<C-c>"] = { "actions.close", mode = "n" },
        -- ["<C-r>"] = "actions.refresh",
        -- ["-"] = { "actions.parent", mode = "n" },
        -- ["_"] = { "actions.open_cwd", mode = "n" },
        -- ["`"] = { "actions.cd", mode = "n" },
        -- ["~"] = { "actions.cd", opts = { scope = "tab" }, mode = "n" },
        -- ["gs"] = { "actions.change_sort", mode = "n" },
        -- ["gx"] = "actions.open_external",
        -- ["g."] = { "actions.toggle_hidden", mode = "n" },
        -- ["g\\"] = { "actions.toggle_trash", mode = "n" },
      },
    },
    -- Optional dependencies
    -- dependencies = { { "echasnovski/mini.icons", opts = {} } },
    -- dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if prefer nvim-web-devicons
  },
  {
    "folke/noice.nvim",
    opts = function(_, opts)
      table.insert(opts.routes, {
        filter = {
          event = "notify",
          find = "No information available",
        },
        opts = { skip = true },
      })

      table.insert(opts.routes, {
        filter = {
          event = "notify",
          find = "Plugin Updates",
        },
        opts = { skip = true },
      })

      table.insert(opts.routes, {
        filter = {
          event = "notify",
          find = "Detached buffer",
        },
        opts = { skip = true },
      })

      -- this is a work around where bigfiles disabled bunch of plugin confuses tsserver
      table.insert(opts.routes, {
        filter = {
          event = "notify",
          find = "Request textDocument/documentHighlight failed with mess",
          cond = function(msg, _)
            local bufnr = vim.api.nvim_get_current_buf()
            return vim.api.nvim_buf_line_count(bufnr) > 10000
          end,
        },
        opts = { skip = true },
      })

      opts.presets.lsp_doc_border = true
    end,
  },
  {
    "b0o/incline.nvim",
    event = "BufReadPre",
    priority = 1200,
    config = function()
      require("incline").setup({
        window = { margin = { vertical = 0, horizontal = 1 } },
        hide = {
          cursorline = true,
        },
        render = function(props)
          local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ":t")
          if vim.bo[props.buf].modified then
            filename = "[+] " .. filename
          end

          local icon, color = require("nvim-web-devicons").get_icon_color(filename)
          return { { icon, guifg = color }, { " " }, { filename } }
        end,
      })
    end,
  },

  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = {
      options = {
        -- globalstatus = false,
      },
    },
  },

  {
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    keys = {
      -- { "<Tab>", "<Cmd>BufferLineCycleNext<CR>", desc = "Next tab" },
      -- { "<S-Tab>", "<Cmd>BufferLineCyclePrev<CR>", desc = "Prev tab" },
    },
    opts = {
      options = {
        mode = "tabs",
        -- separator_style = "slant",
        show_buffer_close_icons = false,
        show_close_icon = false,
      },
    },
  },

  {
    "christoomey/vim-tmux-navigator",
    event = "VeryLazy",
    keys = {

      { "<C-\\>", "<cmd>TmuxNavigatePrevious<cr>", desc = "Go to the previous pane" },

      { "<C-h>", "<cmd>TmuxNavigateLeft<cr>", desc = "Got to the left pane" },

      { "<C-j>", "<cmd>TmuxNavigateDown<cr>", desc = "Got to the down pane" },

      { "<C-k>", "<cmd>TmuxNavigateUp<cr>", desc = "Got to the up pane" },

      { "<C-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Got to the right pane" },
    },
  },

  {
    "fzf-lua",
    event = "VeryLazy",
    keys = {
      { "<leader>gs", false },
    },
  },
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    ---@class snacks.Config
    opts = {
      picker = {
        win = {
          input = {
            keys = {
              ["<c-k>"] = { "history_back", mode = { "i", "n" } },
              ["<c-j>"] = { "history_forward", mode = { "i", "n" } },
            },
          },
        },
      },
      dashboard = {
        preset = {
          header = {
            [[
     ██╗      █████╗ ███████╗██╗   ██╗          Z
     ██║     ██╔══██╗╚══███╔╝╚██╗ ██╔╝      Z
     ██║     ███████║  ███╔╝  ╚████╔╝    z
     ██║     ██╔══██║ ███╔╝    ╚██╔╝   z
     ███████╗██║  ██║███████╗   ██║
     ╚══════╝╚═╝  ╚═╝╚══════╝   ╚═╝
          ]],
          },
        },
      },
    },
  },

  -- {
  --   "nvimdev/dashboard-nvim",
  --   event = "VimEnter",
  --   opts = function(_, opts)
  --     local logo = [[
  -- ]]
  --     --       local logo = [[
  --     -- ██╗   ██╗██╗  ██╗
  --     -- ╚██╗ ██╔╝╚██╗██╔╝
  --     --  ╚████╔╝  ╚███╔╝
  --     --   ╚██╔╝   ██╔██╗
  --     --    ██║   ██╔╝ ██╗
  --     --    ╚═╝   ╚═╝  ╚═╝
  --     --       ]]
  --     logo = string.rep("\n", 8) .. logo .. "\n\n"
  --     opts.config.header = vim.split(logo, "\n")
  --   end,
  -- },
}
