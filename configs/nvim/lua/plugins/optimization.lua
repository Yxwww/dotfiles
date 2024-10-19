-- local nvimcmp = {
--   name = "hrsh7th/nvim-cmp", -- name
--   opts = {
--     defer = false, -- set to true if `disable` should be called on `BufReadPost` and not `BufReadPre`
--   },
--   disable = function(buf) -- called to disable the feature
--     require("cmp").setup.buffer({ enabled = false })
--   end,
-- }

local indentscope = {
  name = "mini.indentscope", -- name
  opts = {
    defer = false, -- set to true if `disable` should be called on `BufReadPost` and not `BufReadPre`
  },
  disable = function(buf) -- called to disable the feature
    vim.b[buf].nvimcmp_disable = true
  end,
}

return {
  {
    "LunarVim/bigfile.nvim",
    opts = {
      filesize = 1,
      features = { -- features to disable
        "indent_blankline",
        "illuminate",
        "syntax",
        "matchparen",
        "vimopts",
        "filetype",
        nvimcmp,
        indentscope,
      },
    },
  },
}
