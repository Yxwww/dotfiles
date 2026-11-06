-- Rex config — migrated from tmux, Herdr and Ghostty.
-- iTerm2 had no readable settings (see report).

-- tmux ~/.tmux.conf
rex.bind("ctrl+b>r", "client.config.reload")

-- Repeat mode: tmux's `bind -r` repeat without the prefix.
rex.mode("repeat", { exclusive = true })
rex.bind("ctrl+b>ctrl+r", "client.mode.enter", { name = "repeat" })
rex.bind("repeat/enter", "client.mode.exit")
rex.bind("repeat/escape", "client.mode.exit")

-- tmux splits
rex.bind("ctrl+b>shift+5", "pane.split", { direction = "right" })
rex.bind("ctrl+b>shift+'", "pane.split", { direction = "down" })

-- Herdr ~/.config/herdr/config.toml
rex.bind("ctrl+b>v", "pane.split", { direction = "right" })
rex.bind("ctrl+b>shift+\\", "pane.split", { direction = "right" })

rex.bind("ctrl+b>left", "pane.resize", { direction = "left" })
rex.bind("ctrl+b>down", "pane.resize", { direction = "down" })
rex.bind("ctrl+b>up", "pane.resize", { direction = "up" })
rex.bind("ctrl+b>right", "pane.resize", { direction = "right" })

rex.bind("ctrl+b>shift+9", "session.previous")
rex.bind("ctrl+b>shift+0", "session.next")

-- Markdown viewer: split a pane to the right running glow. The pane stays open
-- after glow exits so the rendered doc is readable.
-- The Rex server's PATH is short and lacks /opt/homebrew/bin, and shell = "none"
-- skips the login shell, so resolve glow absolutely at load time.
local GLOW = "/opt/homebrew/bin/glow"
local TERMINAL = "com.superlogical.terminal"
local SHELL = "com.superlogical.terminal.shell"
-- Derive the config dir from this chunk's own path, so the dotfiles symlink and
-- a machine-local copy both resolve mdpick.sh correctly.
local CONFIG_DIR = (debug.getinfo(1, "S").source:gsub("^@", "")):match("^(.*)/[^/]*$")
local MDPICK = CONFIG_DIR .. "/mdpick.sh"

-- A terminal only reports pwd once a shell emits OSC 7, so read the foreground
-- process's cwd. Non-shell foregrounds (glow, vim) omit cwd, so fall back to
-- list_dir, which resolves against the block's own directory. Returns "".
local function block_cwd(block_id)
  local proc = rex.block.call(TERMINAL, "process", { block_id = block_id })
  if proc ~= nil and proc.foreground ~= nil and proc.foreground.cwd ~= nil then
    return proc.foreground.cwd
  end
  local listing = rex.block.call(TERMINAL, "list_dir", { block_id = block_id, path = "." })
  if listing ~= nil and listing.path ~= nil then return listing.path end
  return ""
end

-- Resolve a path against the calling pane's cwd, so a relative arg works.
local function abs_path(block_id, path)
  if path:sub(1, 1) == "/" then return path end
  local cwd = block_cwd(block_id)
  if cwd == "" then return path end
  return cwd .. "/" .. path
end

-- Spawn the viewer pane for an explicit file.
local function open_viewer(ctx, abs_file, label)
  local cwd = block_cwd(ctx.block_id)
  local result, err = rex.session.new_split{
    anchor_id = ctx.block_id,
    direction = "horizontal",
    side = "after",
    ratio = 0.5,
    focus = true,
    layout = rex.layout.block{
      flavor = SHELL,
      label = label,
      options = {
        command = { GLOW, "-p", abs_file },
        shell = "none",
        cwd = cwd ~= "" and cwd or nil,
      },
    },
  }
  if err ~= nil then error(err, 0) end
  return { block_ids = result.block_ids }
end

-- Explicit path. This is the one to use for a file that isn't in the cwd.
rex.action{
  name = "markdown_pane",
  title = "Markdown: View File",
  description = "Render a markdown file with glow in a pane split to the right.",
  category = "Markdown",
  keywords = "md glow preview file path",
  args = { file = "string" },
  run = function(ctx, args)
    return open_viewer(ctx, abs_path(ctx.block_id, args.file), "md: " .. args.file)
  end,
}

-- Generic picker: fzf lists the markdown in the calling pane's directory, glow
-- renders the choice. The pane is left to exit on its own (no exit.on_completion
-- and no trailing read), so Esc and ctrl-c both close it without extra handling.
rex.action{
  name = "markdown_pick",
  title = "Markdown: Pick and View",
  description = "Choose a markdown file in this directory with fzf and render it.",
  category = "Markdown",
  keywords = "md glow fzf pick choose fuzzy search",
  args = { query = "string?" },
  run = function(ctx, args)
    local cwd = block_cwd(ctx.block_id)
    if cwd == "" then error("cannot determine the pane's directory", 0) end
    local result, err = rex.session.new_split{
      anchor_id = ctx.block_id,
      direction = "horizontal",
      side = "after",
      ratio = 0.5,
      focus = true,
      layout = rex.layout.block{
        flavor = SHELL,
        label = "md: pick",
        options = {
          command = { MDPICK, cwd, args.query or "" },
          shell = "none",
          cwd = cwd,
        },
      },
    }
    if err ~= nil then error(err, 0) end
    return { block_ids = result.block_ids }
  end,
}

rex.bind("cmd+m", "markdown_pick")
rex.bind("cmd+shift+m", "markdown_pick")
rex.bind("ctrl+b>m", "markdown_pick")
