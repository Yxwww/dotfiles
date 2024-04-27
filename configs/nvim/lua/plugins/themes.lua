return {
  {
    "scottmckendry/cyberdream.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("cyberdream").setup({
        -- Recommended - see "Configuring" below for more config options
        -- transparent = true,
        italic_comments = true,
        hide_fillchars = true,
        borderless_telescope = true,
        terminal_colors = true,
      })
      vim.cmd("colorscheme cyberdream") -- set the colorscheme
    end,
  },
  {
    "catppuccin/nvim",
    lazy = false,
    name = "catppuccin",
    -- you can do it like this with a config function
    config = function()
      require("catppuccin").setup({
        -- configurations
        flavour = "mocha",
      })
    end,
    -- or just use opts table
    opts = {
      -- configurations
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "cyberdream",
    },
  },
}
