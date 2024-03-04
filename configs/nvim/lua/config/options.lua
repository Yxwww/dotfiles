-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
--

-- Turn off autoformat for now. 
vim.g.autoformat = false


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
