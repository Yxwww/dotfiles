local actions = require('telescope.actions')require('telescope').setup{
  pickers = {
    buffers = {
      sort_lastused = true
    },
    diagnostics = {
      theme = "ivy",
      initial_mode = "normal",
    },
  }
}
-- local path_display = require("telescope.builtin").find_files{ path_display = { "truncate" } }

-- local function filenameFirst(_, path)
--   local tail = vim.fs.basename(path)
--   local parent = vim.fs.dirname(path)
--   if parent == "." then return tail end
--   return string.format("%s\t\t%s", tail, parent)
-- end
--
-- vim.api.nvim_create_autocmd("FileType", {
--   pattern = "TelescopeResults",
--   callback = function(ctx)
--     vim.api.nvim_buf_call(ctx.buf, function()
--       vim.fn.matchadd("TelescopeParent", "\t\t.*$")
--       vim.api.nvim_set_hl(0, "TelescopeParent", { link = "Comment" })
--     end)
--   end,
-- })


return {
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
        config = function()
          require("telescope").load_extension("fzf")
        end,
      },
      -- {
      --   "nvim-telescope/telescope-file-browser.nvim",
      --   config = function (_, opts) 
      --     local fb_actions = require("telescope").extensions.file_browser.actions
      --     opts.extensions =  {
      --       file_browser = {
      --         theme = "dropdown",
      --         -- disables netrw and use telescope-file-browser in its place
      --         hijack_netrw = true,
      --         mappings = {
      --           -- your custom insert mode mappings
      --           ["n"] = {
      --             -- your custom normal mode mappings
      --             ["N"] = fb_actions.create,
      --             ["h"] = fb_actions.goto_parent_dir,
      --             ["/"] = function()
      --               vim.cmd("startinsert")
      --             end,
      --             ["<C-u>"] = function(prompt_bufnr)
      --               for i = 1, 10 do
      --                 actions.move_selection_previous(prompt_bufnr)
      --               end
      --             end,
      --             ["<C-d>"] = function(prompt_bufnr)
      --               for i = 1, 10 do
      --                 actions.move_selection_next(prompt_bufnr)
      --               end
      --             end,
      --             ["<PageUp>"] = actions.preview_scrolling_up,
      --             ["<PageDown>"] = actions.preview_scrolling_down,
      --           },
      --         },
      --       },
      --     }
      --     local telescope = require('telescope')
      --     telescope.load_extension("file_browser")
      --   end
      -- }
    },
    -- keys = {
    --   {
    --     "<leader>fm",
    --     function()
    --       local telescope = require("telescope")
    --
    --       local function telescope_buffer_dir()
    --         return vim.fn.expand("%:p:h")
    --       end
    --
    --       telescope.extensions.file_browser.file_browser({
    --         path = "%:p:h",
    --         cwd = telescope_buffer_dir(),
    --         respect_gitignore = false,
    --         hidden = true,
    --         grouped = true,
    --         previewer = false,
    --         initial_mode = "normal",
    --         layout_config = { height = 40 },
    --       })
    --     end,
    --     desc = "Open File Browser with the path of the current buffer",
    --   }
    -- },

		--   dependencies = {
		-- 	{
		-- 		"nvim-telescope/telescope-fzf-native.nvim",
		-- 		build = "make",
		-- 	},
		-- 	"nvim-telescope/telescope-file-browser.nvim",
		-- },
		--   keys = {
		-- 		";f",
		-- 		function()
		-- 			local telescope = require("telescope")
		--
		-- 			local function telescope_buffer_dir()
		-- 				return vim.fn.expand("%:p:h")
		-- 			end
		--
		-- 			telescope.extensions.file_browser.file_browser({
		-- 				path = "%:p:h",
		-- 				cwd = telescope_buffer_dir(),
		-- 				respect_gitignore = false,
		-- 				hidden = true,
		-- 				grouped = true,
		-- 				previewer = false,
		-- 				initial_mode = "normal",
		-- 				layout_config = { height = 40 },
		-- 			})
		-- 		end,
		-- 		desc = "Open File Browser with the path of the current buffer",
		--   },
    opts = {
      defaults = {
        path_display = { 'truncate' },
        file_ignore_patterns = {"esm", "cjs", "dist"},
        mappings = {
          i = {
            ["<C-n>"] = actions.cycle_history_next,
            ["<C-p>"] = actions.cycle_history_prev,

            ["<C-j>"] = actions.move_selection_next,
            ["<C-k>"] = actions.move_selection_previous,

            ["<C-c>"] = actions.close,

            ["<CR>"] = actions.select_default,

            ["<C-u>"] = actions.preview_scrolling_up,
            ["<C-d>"] = actions.preview_scrolling_down,

            ["<PageUp>"] = actions.results_scrolling_up,
            ["<PageDown>"] = actions.results_scrolling_down,

            ["<Tab>"] = actions.toggle_selection + actions.move_selection_worse,
            ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,

            ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
          }
        }
      },
      
    },
  },


  -- add telescope-fzf-native
  -- {
  --   "telescope.nvim",
  --   dependencies = {
  --     "nvim-telescope/telescope-fzf-native.nvim",
  --     build = "make",
  --     config = function()
  --       require("telescope").load_extension("fzf")
  --     end,
  --   },
  -- },

}
