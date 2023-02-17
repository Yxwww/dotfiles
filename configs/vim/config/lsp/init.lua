require("mason").setup({
   log_level = vim.log.levels.INFO,
   check_outdated_packages_on_open = true,
})
require("mason-lspconfig").setup({
   ensure_installed = { "sumneko_lua", "rust_analyzer", "tsserver" },
})

require('lspconfig').rust_analyzer.setup {}
require("lspconfig").tsserver.setup {}
