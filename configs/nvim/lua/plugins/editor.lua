return {
  {
    "neovim/nvim-lspconfig",
    ---@class PluginLspOpts
    ---@param opts PluginLspOpts
    opts = function(_, opts)
      opts.inlay_hints.enabled = false;
    end,
  },
}
