local lsp_installer = require("nvim-lsp-installer")


local util = require("lspconfig.util")
local tsserver_root_dir = util.root_pattern("package.json")
local denols_root_dir = util.root_pattern("deno.json") --".git") distinguigsh deno repo with deno.json
local tailwind_root_dir = util.root_pattern("tailwind.config.js")

-- Register a handler that will be called for all installed servers.
-- Alternatively, you may also register handlers on specific server instances instead (see example below).
lsp_installer.on_server_ready(function(server)
  local opts = {}
  if server.name == "denols" then
    opts.root_dir = denols_root_dir
  elseif server.name == "tailwindcss" then
    opts.root_dir = tailwind_root_dir
  end

  -- (optional) Customize the options passed to the server
  -- if server.name == "tsserver" then
  --     opts.root_dir = function() ... end
  -- end

  -- This setup() function is exactly the same as lspconfig's setup function.
  -- Refer to https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md
  server:setup(opts)
end)

