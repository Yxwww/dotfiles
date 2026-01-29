-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

-- Notify when LSP is disabled
if vim.env.NVIM_NO_LSP == "1" then
  vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
      vim.notify("LSP is disabled (NVIM_NO_LSP=1)", vim.log.levels.WARN)
    end,
  })
end

-- Customize window separator colors after colorscheme loads
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    -- Set window separator to bright blue - change color as needed
    vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#61afef", bg = "NONE", bold = true })
    -- Alternative colors (uncomment to use):
    -- vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#e06c75", bg = "NONE", bold = true }) -- red
    -- vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#98c379", bg = "NONE", bold = true }) -- green
    -- vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#e5c07b", bg = "NONE", bold = true }) -- yellow
  end,
})
--
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
