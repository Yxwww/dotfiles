-- Title tabs from cwd + git branch.
--
-- Run one daemon per session:  rex do -s <session> titles.lua
--
-- A script hears every session's events with --all, but rex.session.view stays
-- scoped to the session it was started in and windows carry no session_id, so
-- one process cannot read or retitle another session. Hence one daemon each.
--
-- Rex labels a window "Window 89abcdef" until something names it, which says
-- nothing about the work. A branch name already encodes the ticket and the
-- task, so it is the cheapest honest source: no model call, no prompt text
-- leaving the machine, and available the moment a pane appears.
--
-- Titles are only set on windows this script owns. A window the user renamed
-- is frozen forever, so hand-names such as "SDK · diff" are never overwritten.
--
-- This must be a `rex do` script: init.lua is never sent events, and its
-- load-time cannot make API calls (no client context).

local TERMINAL = "com.superlogical.terminal"
-- Rex's placeholder is "Window " + 8 hex chars. Match that shape exactly: a bare
-- prefix test would treat a human's "Window shopping" as untouched.
local DEFAULT_LABEL = "^Window %x%x%x%x%x%x%x%x$"

-- Titles we have set, persisted across restarts. Without this a restarted
-- daemon sees its own previous label as a stranger's and freezes the window
-- forever. Keyed by window_id, valued by the label we wrote.
local STATE_DIR = (os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/rex-titles"
local function state_file(session_id)
  local key = tostring(session_id or rex.session_id or "default"):gsub("[^%w]", "")
  return STATE_DIR .. "/" .. key .. ".state"
end

local state_path = state_file(rex.session_id)

-- window_id -> true once frozen (user-named, or deliberately left alone).
local frozen = {}
-- window_id -> the label this script last set, so we recognise our own writes.
local owned = {}
-- window_id -> that label without a trailing collision number, so a change in
-- how duplicates are numbered does not look like someone else's name.
local owned_base = {}

local function load_state()
  local fh = io.open(state_path, "r")
  if fh == nil then return end
  for line in fh:lines() do
    local wid, label = line:match("^(%S+)\t(.*)$")
    if wid ~= nil and label ~= nil and label ~= "" then
      owned[wid] = label
      -- Also remember the label without a collision number, so changing how
      -- duplicates are numbered does not make us treat our own old title as a
      -- stranger's and freeze the window forever.
      local base = label:match("^(.-) %d+$")
      if base ~= nil then owned_base[wid] = base end
    end
  end
  fh:close()
end

local function save_state()
  -- os.execute is blocked in Rex; rex.exec takes an argv table.
  rex.exec{ "mkdir", "-p", STATE_DIR }
  local fh = io.open(state_path, "w")
  if fh == nil then return end
  for wid, label in pairs(owned) do
    fh:write(wid, "\t", label, "\n")
  end
  fh:close()
end

local function basename(path)
  if path == nil or path == "" then return "" end
  return (path:gsub("/+$", ""):match("([^/]+)$")) or ""
end

-- cwd -> {branch, at}. A poll runs every minute and git costs ~10ms to spawn,
-- so re-asking for the same directory on every tick is the one thing that would
-- make this expensive. The TTL is deliberately shorter than POLL_SECONDS so a
-- real branch switch (git checkout in a pane) is seen on the next tick, not the
-- one after.
local branch_cache = {}
local BRANCH_TTL = 30
local now = os.time

local function git_branch(cwd)
  if cwd == nil or cwd == "" then return nil end
  local hit = branch_cache[cwd]
  if hit ~= nil and now() - hit.at < BRANCH_TTL then return hit.branch end

  local r = rex.exec{ "git", "-C", cwd, "rev-parse", "--abbrev-ref", "HEAD" }
  local branch = nil
  if r ~= nil and r.ok and r.code == 0 and r.stdout ~= nil then
    local b = r.stdout:match("^%s*([^%s]+)")
    if b ~= nil and b ~= "HEAD" then branch = b end
  end
  branch_cache[cwd] = { branch = branch, at = now() }
  return branch
end

-- fix/SDK-575-inject-css-root-node -> "SDK-575 · inject-css-root-node"
local function title_from(repo, branch, fg)
  repo = repo or ""
  fg = fg or "shell"

  if branch == nil then
    if repo ~= "" then return repo end
    return fg
  end

  local ticket = branch:match("(%u[%u%d]+%-%d+)")
  if ticket ~= nil then
    -- Slice rather than gsub: the ticket contains "-", which gsub reads as a
    -- lazy quantifier, so a plain-string pattern silently matches nothing.
    local tail = branch:gsub("^%a+/", "")
    local at = tail:find(ticket, 1, true)
    if at == 1 then tail = tail:sub(#ticket + 1) end
    tail = tail:gsub("^[-_]+", "")
    if tail ~= "" then return ticket .. " · " .. tail end
    return ticket
  end

  local segs = {}
  for s in branch:gmatch("[^/]+") do segs[#segs + 1] = s end

  -- Avoid "security-fixes · security-fixes".
  if segs[#segs] == repo then
    if #segs > 1 then return repo .. " · " .. segs[1] end
    return repo
  end
  if branch == "main" or branch == "master" or branch == "develop" then
    return (repo ~= "" and repo or fg) .. " · " .. fg
  end
  if repo == "" then return branch end
  return repo .. " · " .. branch
end

-- A window carries one title for all its panes. Prefer a pane with a real
-- branch, since a window usually opens where the work is.
local function window_fields(window)
  local best = nil
  for _, layer in ipairs(window.layers or {}) do
    for _, b in ipairs(layer.blocks or {}) do
      local block_id = b.block_id
      if block_id ~= nil then
        local proc = rex.block.call(TERMINAL, "process", { block_id = block_id })
        local fg, cwd = "shell", nil
        if proc ~= nil and proc.foreground ~= nil then
          fg = proc.foreground.name or "shell"
          cwd = proc.foreground.cwd
        end
        local f = { repo = basename(cwd), branch = git_branch(cwd), fg = fg }
        if best == nil then best = f end
        if f.branch ~= nil and (best.branch == nil or best.repo == "") then
          best = f
        end
      end
    end
  end
  return best
end

local function apply_title(window, label)
  local wid = window.window_id
  if wid == nil or frozen[wid] then return end
  if label == nil or label == "" then return end

  local current = window.label
  if current ~= nil and current ~= "" then
    local is_default = current:match(DEFAULT_LABEL) ~= nil
    local is_ours = current == owned[wid]
    if not is_ours and owned_base[wid] ~= nil then
      -- Our own previous title for this window, possibly with a different
      -- number than the one we are about to write.
      is_ours = current == owned_base[wid]
        or current:match("^(.*) %d+$") == owned_base[wid]
    end
    if not is_default and not is_ours then
      -- A human chose this. Leave it alone from now on.
      frozen[wid] = true
      return
    end
  end

  if owned[wid] == label then return end

  -- Skip the write when the ones we would produce is already displayed.
  if current == label then
    owned[wid] = label
    return
  end

  local _, err = rex.session.set_window_label{ window_id = wid, label = label }
  if err ~= nil then
    rex.log("warn", "titles: " .. tostring(err))
  else
    owned[wid] = label
    save_state()
  end
end

-- Collision numbering: two tabs deriving the same base get " 1", " 2"; a
-- unique base stays bare so the number only appears where it does work.
local function number_labels(bases, order)
  local total = {}
  for _, wid in ipairs(order) do
    local b = bases[wid]
    if b ~= nil then total[b] = (total[b] or 0) + 1 end
  end
  local seen, out = {}, {}
  for _, wid in ipairs(order) do
    local b = bases[wid]
    if b ~= nil then
      if total[b] > 1 then
        seen[b] = (seen[b] or 0) + 1
        out[wid] = b .. " " .. seen[b]
      else
        out[wid] = b
      end
    end
  end
  return out
end

local function title_session()
  local view, err = rex.session.view{}
  if view == nil or view.windows == nil then
    if err ~= nil then rex.log("warn", "titles: view failed: " .. tostring(err)) end
    return
  end

  -- One pass over the windows: block calls are IPC per pane, so asking twice
  -- just to count duplicates doubles the cost for nothing.
  local bases = {}
  for _, w in ipairs(view.windows) do
    if not frozen[w.window_id] then
      local f = window_fields(w)
      if f ~= nil then
        local base = title_from(f.repo, f.branch, f.fg)
        if base ~= nil and base ~= "" then bases[w.window_id] = base end
      end
    end
  end

  -- Two tabs in the same repo on the same branch derive the same title, so a
  -- window would be indistinguishable from its sibling. Number the collisions
  -- in window order: "team · node 1", "team · node 2". A unique title stays
  -- bare, so the number only appears where it is doing work.
  local order = {}
  for _, w in ipairs(view.windows) do order[#order + 1] = w.window_id end
  local labels = number_labels(bases, order)
  for _, w in ipairs(view.windows) do
    apply_title(w, labels[w.window_id])
  end
end

-- Events arrive in bursts; coalesce so one layout change costs one pass.
--
-- terminal.pwd_changed and terminal.title_changed are documented but never
-- arrive, and a shell `cd` emits nothing at all (block_created does not fire
-- for a shell tab either). Events alone made this daemon write-once, so a poll
-- carries cwd changes and the events only make layout changes snappy.
--
-- A `cd` is a deliberate act, not a keystroke, and a stale tab title is not
-- harmful for a minute. A pass costs ~2.6ms with the branch cache warm, so 60s
-- is ~0.004% of one core. Set REX_TITLES_POLL=0 to disable polling entirely
-- and rely on layout events alone.
local POLL_SECONDS = tonumber(os.getenv("REX_TITLES_POLL") or "") or 60

local timer = nil

local function schedule()
  if timer ~= nil then timer:cancel() end
  timer = rex.after(0.4, function()
    timer = nil
    title_session()
  end)
end

for _, ev in ipairs{
  "process_changed", "session_view_changed",
  "window_created", "block_created",
  "terminal.pwd_changed", "terminal.title_changed",
} do
  rex.on(ev, function() schedule() end)
end

load_state()

-- The poll compares signatures, so an unchanged tree costs one cheap pass and
-- no label writes. A zero interval disables it.
if POLL_SECONDS > 0 then
  rex.every(POLL_SECONDS, function() title_session() end)
end

-- Windows already open when the script starts have no event to wait for.
schedule()

-- Exposed for titles_test.lua. Only when embedded: `rex do` tries to encode the
-- script's return value as JSON, and a table of functions aborts the daemon.
if TITLES_TEST then
  return {
    title_from = title_from,
    basename = basename,
    is_default_label = function(label)
      return label ~= nil and label:match(DEFAULT_LABEL) ~= nil
    end,
    number_labels = number_labels,
  }
end
