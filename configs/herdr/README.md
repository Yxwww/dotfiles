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
herdr integration install pi claude opencode cursor
herdr integration status
```

This is what makes panes resume their native conversation after a server restart
(`resume_agents_on_restore`) and what gives pi/opencode authoritative `blocked`/`working`
state instead of screen-scraping.

`herdr integration install pi` writes `~/.pi/agent/extensions/herdr-agent-state.ts`. That
file is **generated** — it is gitignored in `configs/pi/agent/.gitignore` and must not be
symlinked from dotfiles like the other pi extensions.

## vim / neovim navigation

`ctrl+h/j/k/l` crosses the editor↔herdr boundary, replacing the broken
`vim-tmux-navigator` behavior. Three cooperating pieces:

| Piece | Location |
| --- | --- |
| herdr keybinds → plugin actions | `config.toml` (`[[keys.command]]`) |
| herdr side: detect vim, else move focus | `~/git/vim-herdr-navigation/navigate.sh` |
| neovim side | `configs/nvim/lua/plugins/ui.lua` |
| vim side | `dotfiles/.vimrc` |

**Why the stock plugin did nothing:** `vim-tmux-navigator` guards on `$TMUX`. Herdr never
sets it, so the plugin hit `if empty($TMUX) → finish` and degraded to plain
`wincmd h/j/k/l` — at a split edge the keypress died instead of moving to the herdr pane.

Both editor hooks guard on `$HERDR_PANE_ID`, so they are inert outside herdr and still
fall back to `TmuxNavigate*` when `$TMUX` is set. `vim-tmux-navigator` is retained purely
as that tmux fallback with `tmux_navigator_no_mappings = 1`.

**Fragility to know about:** the two editors guard in different places.

| Side | Where the guard lives |
| --- | --- |
| vim | self-guarding — `vim-herdr-nav.vim` bails via `empty($HERDR_PANE_ID)` |
| neovim | **caller-side** — `editor/nvim.lua` maps keys unconditionally at load; `ui.lua`'s `if vim.env.HERDR_PANE_ID` is what prevents it loading in tmux |

If the `ui.lua` guard were ever dropped, the nvim module would map the keys in *every*
environment and fight `vim-tmux-navigator`. Single ownership holds today, but on the nvim
side it depends on that caller check.

### Not verified

- `prefix+(` / `prefix+)` pass config validation but their runtime behaviour is
  **unverified** — no CLI surface exposes UI-layer keybindings (`herdr api snapshot`
  returns only agents/panes; the schema has no key fields). Validation proves the key
  *string parses*, not that a keystroke reaches the action.
- `ctrl+1..9` is a **direct** chord, the category herdr's docs flag as
  terminal/keyboard-protocol dependent. Delivery is unverified; behaviour with 0 or >9
  agents is untested.
- The plugin clone is pinned to the revision tested here. Bump `nav_ref` in
  `setup_herdr` deliberately. Note the pin freezes the *code*, not the
  environment it runs in: `navigate.sh` shells out to `herdr` on every keypress.
- **Theme is unverified at runtime.** `name = "terminal"` makes herdr follow the
  host palette, but theme rendering is **client-side** while `server reload-config`
  is a server call. A clean reload proves the value *parses*, not that the client
  applies it.

Other TUIs owning `ctrl+h/j/k/l` (lazygit, k9s) can be passed through:

```
export HERDR_NAV_PASSTHROUGH_RE='^(vi-sql|lazygit|k9s)$'
```

Tradeoff (same as tmux): binding `ctrl+l`/`ctrl+k` globally shadows readline's
clear-screen and kill-line inside non-vim panes. Use `prefix+l` to clear, or move
navigation to `alt+h/j/k/l`.

## Notes

- `HERDR_ENV=1` is set in every managed pane. Shell startup that auto-attaches tmux must
  exclude it (`[[ -z ${TMUX:-} && ${HERDR_ENV:-} != 1 ]]`) or panes nest and flicker.
- `switch_ascii_input_source_in_prefix` is on for IME use: prefix chords still register
  while a non-Latin input source is active.
- `herdr --default-config` prints the full annotated default; `herdr server reload-config`
  applies changes (`prefix+shift+r`).
