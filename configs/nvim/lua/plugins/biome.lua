-- Biome (format + lint + organize imports) for projects that have a biome.json.
-- In those projects Biome owns these filetypes and prettier is skipped; elsewhere
-- prettier still runs, so the formatting.prettier extra keeps working.
-- conform resolves `biome` from the project's node_modules, so the repo's own
-- Biome version is used rather than a global one.
--
-- Why not LazyVim's idiomatic `extras.lang.typescript.biome`? Measured against
-- it, two failures: (1) it does `table.insert(formatters_by_ft[ft], "biome-check")`
-- after prettier has already added itself, so both run per save -- and a
-- .prettierrc in a subdir of a Biome project still yields {prettier, biome-check}.
-- (2) The documented remedy, vim.g.lazyvim_prettier_needs_config = true, makes
-- prettier skip any project without a .prettierrc, so such files get NO formatter
-- at all -- a silent failure, global to every repo, worse than the collision.
-- What the extra does better: it wires the `biome` LSP for diagnostics, which
-- this file does not. If you want that, add the `biome` server in lsp/editor.lua
-- rather than switching to the extra.
-- To switch anyway: enable `lang.typescript.biome` in lazyvim.json, set the flag,
-- delete this file, then verify conform.list_formatters_to_run(0) is biome-check
-- alone -- and that a project with no .prettierrc still reports a formatter.
local biome_filetypes = {
  "javascript",
  "javascriptreact",
  "typescript",
  "typescriptreact",
  "json",
  "jsonc",
  "css",
  "html",
  "graphql",
}

-- A biome.json alone is not enough: conform's `biome-check` runs
-- `node_modules/.bin/biome` resolved upward from the buffer, else the bare name
-- `biome` on PATH. Requiring the config AND a real executable keeps a stale
-- biome.json in a project with no installed CLI from routing to a formatter that
-- cannot run, which would silently mean "no formatting" instead of prettier.
local function biome_available(buf)
  local dir = vim.fs.dirname(vim.api.nvim_buf_get_name(buf))

  local config = vim.fs.find({ "biome.json", "biome.jsonc", ".biome.json", ".biome.jsonc" }, {
    path = dir,
    upward = true,
    limit = 1,
  })[1]
  if not config then
    return false
  end

  if vim.fn.executable("biome") == 1 then
    return true
  end
  return vim.fs.find("node_modules/.bin/biome", { path = dir, upward = true, limit = 1 })[1] ~= nil
end

return {
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      for _, ft in ipairs(biome_filetypes) do
        opts.formatters_by_ft[ft] = function(buf)
          if biome_available(buf) then
            return { "biome-check" }
          end
          -- nil = fall through to prettier; LazyVim crashes on a nil entry.
          return { "prettier" }
        end
      end
    end,
  },
}
