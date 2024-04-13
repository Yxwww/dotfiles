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
-- vim.keymap.set("n", "<leader>gs", "<cmd>Git<cr>", { desc = "Fugitive Git" })
vim.keymap.set("n", "<leader>gs", function()
  require("neogit").open({ kind = "split" })
end, { desc = "neogit status" })
vim.keymap.set("n", "<leader>go", "<cmd>GBrowse<cr>", { desc = "Open In Browser" })
-- vim.keymap.set("n", "<leader>gc", "<cmd>Git commit<cr>", { desc = "Commit" })
vim.keymap.set("n", "<leader>gc", function()
  require("neogit").open({ "commit" })
end, { desc = "neogit commit" })
vim.keymap.set("n", "<leader>gl", "<cmd>Git log<cr>", { desc = "Fugitive Log" })
-- vim.keymap.set("n", "<leader>gd", "<cmd>Gdiff<cr>", { desc = "Diff current buffer" })
vim.keymap.set("n", "<leader>gd", function()
  require("mini.diff").toggle_overlay(0)
end, { desc = "mini.diff" })

vim.keymap.set("n", "C-g", "<cmd>Rg<cr>", { desc = "Rig Grep everything" })
vim.keymap.set("n", ",fe", "<cmd>EslintFixAll<cr>", { desc = "Eslint fix everything" })

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
