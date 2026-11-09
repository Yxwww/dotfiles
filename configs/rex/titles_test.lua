-- Tests for titles.lua's pure logic. Run: lua configs/rex/titles_test.lua
--
-- titles.lua registers handlers and starts timers when it loads, so the stubs
-- below have to accept and ignore every call it makes.
TITLES_TEST = true

rex = {
  on = function() end,
  every = function() return { cancel = function() end } end,
  after = function() return { cancel = function() end } end,
  log = function() end,
  exec = function() return { ok = true, code = 0, stdout = "" } end,
  session_id = "session:test",
  block = { call = function() return nil end },
  session = {
    view = function() return { windows = {} } end,
    set_window_label = function() return true end,
  },
}

local path = arg and arg[0] or ""
local dir = path:match("^(.*)/[^/]*$") or "."
local titles = assert(loadfile(dir .. "/titles.lua"))()

local failures = 0
local function check(label, got, want)
  if got ~= want then
    failures = failures + 1
    print(string.format("FAIL %-46s got=%s want=%s", label, tostring(got), tostring(want)))
  end
end

-- title_from(repo, branch, foreground)
local cases = {
  { "sdk", "fix/SDK-575-inject-css-root-node", "pi", "SDK-575 · inject-css-root-node" },
  { "sdk", "SDK-575", "pi", "SDK-575" },
  { "fde-projects", "spike/shadow-embed", "zsh", "fde-projects · spike/shadow-embed" },
  { "security-fixes", "vt-remediation/security-fixes", "nvim", "security-fixes · vt-remediation" },
  { "app-framework", "jj/planning-ahead", "nvim", "app-framework · jj/planning-ahead" },
  { "dotfiles", "rex-config", "pi", "dotfiles · rex-config" },
  { "team", "main", "pi", "team · pi" },
  { "chore", "master", "shell", "chore · shell" },
  { "x", nil, "shell", "x" },
  { "", "some-branch", "sh", "some-branch" },
  { "", nil, "nvim", "nvim" },
}
for _, c in ipairs(cases) do
  check(("%s | %s | %s"):format(c[1], tostring(c[2]), c[3]),
        titles.title_from(c[1], c[2], c[3]), c[4])
end

-- basename
check("basename /a/b/c", titles.basename("/a/b/c"), "c")
check("basename /a/b/ (trailing slash)", titles.basename("/a/b/"), "b")
check("basename empty", titles.basename(""), "")
check("basename nil", titles.basename(nil), "")

-- Rex's placeholder is "Window " + 8 hex. A bare prefix test would treat a
-- human's "Window shopping" as untouched and overwrite it.
check("default Window 9f723776", titles.is_default_label("Window 9f723776"), true)
check("default Window 89abcdef", titles.is_default_label("Window 89abcdef"), true)
check("NOT default: Window shopping", titles.is_default_label("Window shopping"), false)
check("NOT default: Window 9f72377g", titles.is_default_label("Window 9f72377g"), false)
check("NOT default: PR-152", titles.is_default_label("PR-152"), false)
check("NOT default: empty", titles.is_default_label(""), false)
check("NOT default: nil", titles.is_default_label(nil), false)

if failures == 0 then
  print(("ok - %d checks"):format(#cases + 10))
else
  print(("%d FAILED"):format(failures))
  os.exit(1)
end
