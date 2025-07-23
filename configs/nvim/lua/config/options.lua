-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
--

-- Turn off autoformat for now.
vim.g.snacks_animate = false
vim.g.lazyvim_picker = "snacks"
vim.g.autoformat = true
vim.o.foldmethod = "indent"
-- vim.o.foldexpr = "nvim_treesitter#foldexpr()"
vim.o.foldlevel = 100
-- -- vim.o.foldminlines = 2

vim.g.vimwiki_list = { {
  path = "~/my-wiki/",
  syntax = "default",
  ext = ".wiki",
} }
-- local autocmd = vim.api.nvim_create_autocmd
-- local augroup = vim.api.nvim_create_augroup
-- local save_fold = augroup("Persistent Folds", { clear = true })
-- autocmd("BufWinLeave", {
--   pattern = "*.*",
--   callback = function()
--     vim.cmd.mkview()
--   end,
--   group = save_fold,
-- })
-- autocmd("BufWinEnter", {
--   pattern = "*.*",
--   callback = function()
--     vim.cmd.loadview({ mods = { emsg_silent = true } })
--   end,
--   group = save_fold,
-- })

-- local default_cmp_sources = cmp.config.sources({
-- 	{ name = 'nvim_lsp' },
-- 	{ name = 'nvim_lsp_signature_help' },
-- }, {
-- 	{ name = 'vsnip' },
-- 	{ name = 'path' }
-- })
--

-- local bufIsBig = function(bufnr)
-- 	local max_filesize = 100 * 1024 -- 100 KB
-- 	local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(bufnr))
-- 	if ok and stats and stats.size > max_filesize then
-- 		return true
-- 	else
-- 		return false
-- 	end
-- end

-- If a file is too large, I don't want to add to it's cmp sources treesitter, see:
-- https://github.com/hrsh7th/nvim-cmp/issues/1522
-- vim.api.nvim_create_autocmd('BufReadPre', {
-- 	callback = function(t)
-- 		local sources = default_cmp_sources
-- 		if not bufIsBig(t.buf) then
-- 			sources[#sources+1] = {name = 'treesitter', group_index = 2}
-- 		end
-- 	cmp.setup.buffer {
-- 		sources = sources
-- 	}
-- 	end
-- })
