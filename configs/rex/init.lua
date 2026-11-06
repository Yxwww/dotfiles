-- Rex config — migrated from tmux, Herdr and Ghostty.
-- iTerm2 had no readable settings (see report).

-- tmux ~/.tmux.conf
rex.bind("ctrl+b>r", "client.config.reload")

-- Repeat mode: tmux's `bind -r` repeat without the prefix.
rex.mode("repeat", { exclusive = true })
rex.bind("ctrl+b>ctrl+r", "client.mode.enter", { name = "repeat" })
rex.bind("repeat/enter", "client.mode.exit")
rex.bind("repeat/escape", "client.mode.exit")

-- tmux splits. | = split right, - = split down, matching tmux's divide keys.
rex.bind("ctrl+b>shift+5", "pane.split", { direction = "right" })
rex.bind("ctrl+b>shift+'", "pane.split", { direction = "down" })
rex.bind("ctrl+b>-", "pane.split", { direction = "down" })

-- Herdr ~/.config/herdr/config.toml
rex.bind("ctrl+b>v", "pane.split", { direction = "right" })
rex.bind("ctrl+b>shift+\\", "pane.split", { direction = "right" })

rex.bind("ctrl+b>left", "pane.resize", { direction = "left" })
rex.bind("ctrl+b>down", "pane.resize", { direction = "down" })
rex.bind("ctrl+b>up", "pane.resize", { direction = "up" })
rex.bind("ctrl+b>right", "pane.resize", { direction = "right" })

-- Vim-style pane focus. pane.focus wraps by default, so an edge press
-- continues from the opposite side, which is what makes hjkl cycle.
rex.bind("ctrl+b>h", "pane.focus.left")
rex.bind("ctrl+b>j", "pane.focus.down")
rex.bind("ctrl+b>k", "pane.focus.up")
rex.bind("ctrl+b>l", "pane.focus.right")

-- Vim's :split / :vsplit, alongside the tmux and Herdr split keys above.
rex.bind("ctrl+b>s", "pane.split", { direction = "down" })

rex.bind("ctrl+b>shift+9", "session.previous")
rex.bind("ctrl+b>shift+0", "session.next")

-- File viewer: split a pane to the right running view.sh (fzf picker) or
-- view-file.sh (single file). Markdown renders with glow, images with chafa,
-- everything else with bat; the scripts pick the renderer by extension.
--
-- The Rex server's PATH is short and lacks /opt/homebrew/bin, and shell = "none"
-- skips the login shell, so the scripts are invoked by absolute path and
-- resolve their own tools absolutely.
local TERMINAL = "com.superlogical.terminal"
local SHELL = "com.superlogical.terminal.shell"
-- Derive the config dir from this chunk's own path, so the dotfiles symlink and
-- a machine-local copy both resolve the sibling scripts correctly.
local CONFIG_DIR = (debug.getinfo(1, "S").source:gsub("^@", "")):match("^(.*)/[^/]*$")
local VIEW_PICK = CONFIG_DIR .. "/view.sh"
local VIEW_FILE = CONFIG_DIR .. "/view-file.sh"

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

-- Spawn a viewer pane split to the right, running cmd in the calling pane's cwd.
-- The pane is left to exit on its own (no exit.on_completion and no trailing
-- read), so Esc and ctrl-c both close it without extra handling.
local function open_pane(ctx, cmd, label)
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
        command = cmd,
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
  name = "view_file",
  title = "View: File",
  description = "Render a file (markdown via glow, images via chafa, else bat).",
  category = "View",
  keywords = "view preview file md image glow chafa bat path",
  args = { file = "string" },
  run = function(ctx, args)
    return open_pane(ctx, { VIEW_FILE, abs_path(ctx.block_id, args.file) }, "view: " .. args.file)
  end,
}

-- Generic picker: fzf lists the files in the calling pane's repository, with
-- dirty files first, and the viewer renders the choice.
rex.action{
  name = "view_pick",
  title = "View: Pick and Open",
  description = "Choose a file in this repo with fzf and render it.",
  category = "View",
  keywords = "view pick choose fuzzy fzf md image glow chafa bat dirty git",
  run = function(ctx)
    return open_pane(ctx, { VIEW_PICK }, "view: pick")
  end,
}

rex.bind("cmd+m", "view_pick")
rex.bind("cmd+shift+m", "view_pick")
rex.bind("ctrl+b>m", "view_pick")
