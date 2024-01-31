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

-- vim.keymap.set("n", "<leader>gs", ":Git<cr>");
-- " nmap <leader>go :!gh repo view --web<cr>
-- vim.keymap.set("n", "<leader>gp!", ":Git push<cr>")
-- vim.keymap.set("n", "<leader>ga", "<>Gwrite")
vim.keymap.set("n", "<leader>gs", "<cmd>Git<cr>", { desc = "Fugitive Git" })
vim.keymap.set("n", "<leader>go", "<cmd>GBrowse<cr>", { desc = "Open In Browser" })
vim.keymap.set("n", "<leader>gc", "<cmd>Git commit<cr>", { desc = "Commit" })
vim.keymap.set("n", "<leader>gl", "<cmd>Git log<cr>", { desc = "Fugitive Log" })
vim.keymap.set("n", "<leader>gd", "<cmd>Gdiff<cr>", { desc = "Diff current buffer" })

vim.keymap.set("n", "C-g", "<cmd>Rg<cr>", { desc = "Rig Grep everything" })
