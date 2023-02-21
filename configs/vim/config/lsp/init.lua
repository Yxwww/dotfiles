require("mason").setup({
   log_level = vim.log.levels.INFO,
   check_outdated_packages_on_open = true,
})
require("mason-lspconfig").setup({
   ensure_installed = { "lua_ls","rust_analyzer", "tsserver" },
})

require('lspconfig').rust_analyzer.setup {}
require("lspconfig").tsserver.setup {}
require("lspconfig").lua_ls.setup {}
