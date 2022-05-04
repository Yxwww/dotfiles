-- local status_ok, configs = pcall(require, "nvim-treesitter.configs")
-- if not status_ok then
--   return
-- end
--
-- configs.setup {
--   ensure_installed = "maintained", -- one of "all", "maintained" (parsers with maintainers), or a list of languages
--   sync_install = false, -- install languages synchronously (only applied to `ensure_installed`)
--   ignore_install = { "" }, -- List of parsers to ignore installing
--   autopairs = {
--     enable = true,
--   },
--   highlight = {
--     enable = true, -- false will disable the whole extension
--     disable = { "" }, -- list of language that will be disabled
--     additional_vim_regex_highlighting = true,
--   },
--   indent = { enable = true, disable = { "yaml" } },
--   context_commentstring = {
--     enable = true,
--     enable_autocmd = false,
--   }
-- }
require'nvim-treesitter.configs'.setup {
  -- A list of parser names, or "all"
  ensure_installed = { "c", "lua", "rust", "javascript" },

  -- Install parsers synchronously (only applied to `ensure_installed`)
  sync_install = true,

  -- List of parsers to ignore installing (for "all")

  highlight = {
    -- `false` will disable the whole extension
    enable = true,
  },
}
