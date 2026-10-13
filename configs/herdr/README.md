# herdr

[herdr](https://herdr.dev) — terminal workspace manager for AI coding agents. Runs as a
background server owning real PTYs; clients attach/detach. `ctrl+b` is the prefix.

## Files

- `config.toml` — linked to `~/.config/herdr/config.toml` by `linkdotfiles.sh`.
  Everything else in `~/.config/herdr/` (sockets, logs, `session.json`, `plugins/`,
  `session-snapshots/`) is machine-local runtime state and deliberately untracked.

## Agent integrations

Installed by `setup_herdr` in `setup.sh`; re-run to refresh after a herdr upgrade.

```
# one target at a time — multi-arg is rejected with a usage error
for a in pi claude opencode cursor; do herdr integration install "$a"; done
herdr integration status
```

This is what makes panes resume their native conversation after a server restart
(`resume_agents_on_restore`) and what gives pi/opencode authoritative `blocked`/`working`
state instead of screen-scraping.

`herdr integration install pi` writes `~/.pi/agent/extensions/herdr-agent-state.ts`. That
file is **generated** — it is gitignored in `configs/pi/agent/.gitignore` and must not be
symlinked from dotfiles like the other pi extensions.

## Pane navigation

`ctrl+h/j/k/l` are **not bound** to anything here. They previously drove the
`vim-herdr-navigation` plugin, which was removed deliberately: it required a third-party
clone on the critical path, plus matching hooks in `~/.vimrc` and the neovim config. The
pane keys are herdr's own; use `prefix+` arrows or `prefix+h/j/k/l`.

If the integration is ever wanted back: `herdr plugin link <clone>`,
four `[[keys.command]]` blocks in `config.toml`, and an editor-side hook. Note that
`vim-tmux-navigator` alone does **not** work — it guards on `$TMUX`, which herdr never
sets, so it degrades to plain `wincmd` and dies at a split edge.

### Not verified

- `prefix+v` / `prefix+|`, `prefix+(` / `prefix+)`, and `prefix+left/down/up/right`
  pass config validation but their runtime behaviour is **unverified** — no CLI surface
  exposes UI-layer keybindings (`herdr api snapshot` returns only agents/panes; the schema
  has no key fields). Validation proves the key *string parses*, not that a keystroke
  reaches the action.
- `ctrl+1..9` is a **direct** chord, the category herdr's docs flag as
  terminal/keyboard-protocol dependent. Delivery is unverified; behaviour with 0 or >9
  agents is untested.
- **Theme is unverified at runtime.** `name = "terminal"` makes herdr follow the
  host palette, but theme rendering is **client-side** while `server reload-config`
  is a server call. A clean reload proves the value *parses*, not that the client
  applies it.

### `reload-config` does not validate keybindings

Do not read `{"status":"applied","diagnostics":[]}` as "these keys work". Given a
`[keys]` value that is not a real key, the two commands disagree:

```
$ herdr config check
config: issues found
invalid keybinding: keys.resize_pane_up = "prefix+boguskey"; disabling binding

$ herdr server reload-config
{"status":"applied","diagnostics":[]}      # reports success anyway
```

Reproducible across repeated reloads. `config check` is the only one that validates, and
it **exits 0 even on `issues found`**, so its status cannot be used as a pass/fail signal
either — read its output. herdr silently disables a bad binding rather than failing, which
is the same class of trap as the exit-0 behaviours elsewhere in this file.

## Notes

- `HERDR_ENV=1` is set in every managed pane. Shell startup that auto-attaches tmux must
  exclude it (`[[ -z ${TMUX:-} && ${HERDR_ENV:-} != 1 ]]`) or panes nest and flicker.
- `switch_ascii_input_source_in_prefix` is on for IME use: prefix chords still register
  while a non-Latin input source is active.
- `herdr --default-config` prints the full annotated default; `herdr server reload-config`
  applies changes (`prefix+shift+r`).
