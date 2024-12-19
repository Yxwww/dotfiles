return {
  {
    "stevearc/oil.nvim",
    ---@module 'oil'
    ---@type oil.SetupOpts
    keys = {
      { "-", "<CMD>Oil<CR>", desc = "Open parent directory" },
    },
    opts = {},
    -- Optional dependencies
    dependencies = { { "echasnovski/mini.icons", opts = {} } },
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
    "snacks.nvim",
    ---@type snacks.Config
    opts = {
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
        sections = {
          { section = "header" },
          {
            pane = 2,
            section = "terminal",
            -- cmd = "colorscript -e square",
            cmd = "",
            height = 5,
            padding = 1,
          },
          { section = "keys", gap = 1, padding = 1 },
          {
            pane = 2,
            icon = " ",
            desc = "Browse Repo",
            padding = 1,
            key = "b",
            action = function()
              Snacks.gitbrowse()
            end,
          },
          function()
            local in_git = Snacks.git.get_root() ~= nil
            local cmds = {
              -- {
              --   title = "Notifications",
              --   cmd = "",
              --   -- cmd = "gh notify -s -a -n5",
              --   action = function()
              --     vim.ui.open("https://github.com/notifications")
              --   end,
              --   key = "n",
              --   icon = " ",
              --   height = 5,
              --   enabled = true,
              -- },
              {
                title = "Open Issues",
                cmd = "gh issue list -L 3",
                key = "i",
                action = function()
                  vim.fn.jobstart("gh issue list --web", { detach = true })
                end,
                icon = " ",
                height = 7,
              },
              {
                icon = " ",
                title = "Open PRs",
                cmd = "gh pr list -L 3",
                key = "p",
                action = function()
                  vim.fn.jobstart("gh pr list --web", { detach = true })
                end,
                height = 7,
              },
              {
                icon = " ",
                title = "Git Status",
                cmd = "git --no-pager diff --stat -B -M -C",
                height = 10,
              },
            }
            return vim.tbl_map(function(cmd)
              return vim.tbl_extend("force", {
                pane = 2,
                section = "terminal",
                enabled = in_git,
                padding = 1,
                ttl = 5 * 60,
                indent = 3,
              }, cmd)
            end, cmds)
          end,
          { section = "startup" },
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
