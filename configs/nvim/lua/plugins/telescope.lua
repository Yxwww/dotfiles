local actions = require("telescope.actions")
local open_with_trouble = function(...)
  return require("trouble.sources.telescope").open(...)
end
local find_files_no_ignore = function()
  local action_state = require("telescope.actions.state")
  local line = action_state.get_current_line()
  LazyVim.pick("find_files", { no_ignore = true, default_text = line })()
end
local find_files_with_hidden = function()
  local action_state = require("telescope.actions.state")
  local line = action_state.get_current_line()
  LazyVim.pick("find_files", { hidden = true, default_text = line })()
end

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
    },
    opts = {
      defaults = {
        path_display = { "truncate" },
        file_ignore_patterns = { "esm", "cjs", "dist" },
        mappings = {
          i = {
            ["<C-Down>"] = actions.cycle_history_next,
            ["<C-Up>"] = actions.cycle_history_prev,
            -- ["<C-n>"] = actions.cycle_history_next,
            -- ["<C-p>"] = actions.cycle_history_prev,

            ["<C-n>"] = actions.move_selection_next,
            ["<C-p>"] = actions.move_selection_previous,

            ["<C-c>"] = actions.close,

            ["<CR>"] = actions.select_default,

            ["<C-u>"] = actions.preview_scrolling_up,
            ["<C-d>"] = actions.preview_scrolling_down,
            --
            ["<PageUp>"] = actions.results_scrolling_up,
            ["<PageDown>"] = actions.results_scrolling_down,

            ["<Tab>"] = actions.toggle_selection + actions.move_selection_worse,
            ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,

            ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,

            ["<c-t>"] = open_with_trouble,
            ["<c-i>"] = find_files_no_ignore,
            ["<c-h>"] = find_files_with_hidden,
          },
        },
      },
      pickers = {
        current_buffer_fuzzy_find = {
          previewer = false,
        },
        buffers = {
          sort_lastused = true,
        },
        diagnostics = {
          theme = "ivy",
          initial_mode = "normal",
        },
      },
    },
  },
}
