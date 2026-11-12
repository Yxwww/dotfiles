# rex

Config for [rex](https://rex.dev), the multiplexer for all work.

Rex reads exactly one config file per account: `init.lua` in `$XDG_CONFIG_HOME/rex`
or `~/.config/rex`. It binds keys with `rex.bind` and defines custom actions with
`rex.action`.

## Linked files

`linkdotfiles.sh` symlinks `init.lua`, `view.sh` and `view-file.sh` into
`~/.config/rex/`.

`view.sh` is the fzf picker (`view_pick`) and `view-file.sh` renders one path
(`view_file`). `view-file.sh` picks a renderer by extension: markdown via glow,
images via chafa, diffs and everything else via bat. `view.sh` calls it for its
preview too, so the preview matches what Enter gives you.

The picker opens on the git dirty files (staged, unstaged, untracked) — the
files you are actually working on. `ctrl-a` reloads to every tracked file in the
repo, `ctrl-d` reloads back to dirty. A clean repo opens on the full list
instead, since an empty menu can be neither picked from nor escaped.

After a file renders, any key returns to the menu, so you can walk a set of dirty
files without reopening the pane. Nothing in the script closes the pane: it stays
open until Cmd+W, and Esc at the menu shows a message rather than exiting.

The two lists stay separate and fzf runs them itself via `reload(...)`: merging
them up front would need a `sort` to dedupe, and sorting scatters the dirty files
alphabetically, which is the thing the dirty-first ordering exists to prevent.

Dirty files are read with `git status --porcelain -z`. Plain porcelain quotes
and C-escapes paths containing spaces (`"a file.md"`), which would send the
viewer looking for a file whose name really contains quote characters; `-z` is
NUL-separated and never quoted.

Both are resolved from the config file's own directory at load time
(`debug.getinfo(1, "S")`), and `view.sh` follows its own symlink to find
`view-file.sh`, so the linked dotfiles copy and a machine-local copy both work.

The viewer panes are created with `exit.on_completion = false`, so the rendered
file stays on screen after the viewer exits. Without it the pane closes the
moment the render finishes, because `view-file.sh` always exits 0 so a preview
never kills the fzf session.

Runtime state — `server.sock`, `host-id`, `servers/`, `terminal/` — lives in
`~/.rex` and is machine-local. It is not tracked here.

## Verifying

```sh
rex config check    # load the config and report bindings/actions
rex config reload   # make the running server re-read the config
```
