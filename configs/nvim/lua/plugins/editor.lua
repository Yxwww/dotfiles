return {
  {
    "neovim/nvim-lspconfig",
    ---@class PluginLspOpts
    ---@param opts PluginLspOpts
    opts = {
      servers = {
        -- tsserver got renamed to ts_ls. disabled it in favour of vtsls
        ts_ls = {
          enabled = false,
        },
      },
      inlay_hints = {
        enabled = false,
      },
      diagnostics = {
        update_in_insert = false,
        virtual_text = { spacing = 4, prefix = "●" },
        severity_sort = true,
      },
    },
    on_attach = function(client, bufnr)
      vim.notify("attached!")
      if vim.api.nvim_buf_line_count(bufnr) > 10000 then
        vim.notify(vim.api.nvim_buf_line_count(bufnr))
        client.stop()
      end
    end,
  },
  {
    "hrsh7th/nvim-cmp",
    opts = {
      performance = {
        debounce = 60,
        throttle = 30,
        fetching_timeout = 500,
      },
      completion = {
        keyword_length = 2,
      },
    },
    on_attach = function()
      vim.print("attached!")
    end,
  },
}
