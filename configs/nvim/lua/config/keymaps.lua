-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--

-- we like s
-- vim.keymap.set("n", "s", "<nop>", {})

-- we like want to move lines
vim.keymap.set("n", "<A-j>", "<nop>", {})
vim.keymap.set("n", "<A-k>", "<nop>", {})
vim.keymap.set("i", "<A-j>", "<nop>", {})
vim.keymap.set("i", "<A-k>", "<nop>", {})
vim.keymap.set("v", "<A-j>", "<nop>", {})
vim.keymap.set("v", "<A-k>", "<nop>", {})

vim.keymap.set("n", "<leader>vs", ":vs<cr>", { desc = "Vertical Split" })
-- " nmap <leader>go :!gh repo view --web<cr>
-- vim.keymap.set("n", "<leader>gp!", ":Git push<cr>")
-- vim.keymap.set("n", "<leader>ga", "<>Gwrite")
-- vim.keymap.set("n", "<leader>gs", "<cmd>Git<cr>", { desc = "Fugitive Git" })
-- vim.keymap.set("n", "<leader>gs", function()
--   require("neogit").open({ kind = "split" })

-- end, { desc = "neogit status" })
vim.keymap.set("n", "<leader>gc", "<cmd>Git commit<cr>", { desc = "Commit" })
-- vim.keymap.set("n", "<leader>gc", function()
--   require("neogit").open({ "commit" })
-- end, { desc = "neogit commit" })
vim.keymap.set("n", "<leader>gl", "<cmd>Git log<cr>", { desc = "Fugitive Log" })
vim.keymap.set("n", "<leader>gp", "<cmd>Git push<cr>", { desc = "Fugitive Push" })
-- vim.keymap.set("n", "<leader>gd", "<cmd>Gdiff<cr>", { desc = "Diff current buffer" })
vim.keymap.set("n", "<leader>gd", function()
  require("mini.diff").toggle_overlay(0)
end, { desc = "mini.diff" })

vim.keymap.set("n", "<C-q>", "<cmd>q<cr>", { desc = "Quit" })
vim.keymap.set("n", "<C-g>", "<cmd>Rg<cr>", { desc = "Rig Grep everything" })
vim.keymap.set("n", "<leader>k", "<cmd>EslintFixAll<cr>", { desc = "Eslint fix everything" })

-- trouble
vim.keymap.set("n", "<leader>xx", function()
  require("trouble").toggle()
end)
vim.keymap.set("n", "<leader>xw", function()
  require("trouble").toggle("workspace_diagnostics")
end)
vim.keymap.set("n", "<leader>xd", function()
  require("trouble").toggle("document_diagnostics")
end)
vim.keymap.set("n", "<leader>xq", function()
  require("trouble").toggle("quickfix")
end)
vim.keymap.set("n", "<leader>xl", function()
  require("trouble").toggle("loclist")
end)
vim.keymap.set("n", "gR", function()
  require("trouble").toggle("lsp_references")
end)

vim.keymap.set("n", "<leader>mp", "<cmd>MarkdownPreview<cr>", { desc = "Markdown Preview" })

vim.keymap.del("n", "H")
vim.keymap.del("n", "L")

vim.keymap.del("n", "<C-b>")
-- vim.keymap.del("n", "<C-i>")

vim.keymap.set("n", "<leader>gs", ":Git<cr>")

-- " Map <Tab> to toggle fold under cursor in Normal mode
-- nnoremap <Tab> za
-- vim.keymap.del("n", "<Tab>")
-- Mapping Tab is nono in terminal and vim https://github.com/neovim/neovim/issues/8317
-- Use a different key for fold toggling to avoid affecting C-i jumplist navigation
vim.keymap.set("n", "<leader>z", "za", { desc = "toggle fold" })
vim.keymap.set("n", "<leader>Z", "zA", { desc = "toggle all folds under cursor" })
-- Remove Tab mapping to restore C-i jumplist functionality
-- vim.keymap.set("n", "<Tab>", "za", { desc = "toggle fold" })
-- vim.keymap.set("n", "<S-Tab>", "zA", { desc = "toggle all folds under cursor" })
