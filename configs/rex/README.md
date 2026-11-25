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

## Terminfo (not linked)

Rex's terminals support capabilities plain `xterm-256color` does not advertise:
extended underline (`Smulx`), synchronized output (`Sync`), and the
modifyOtherKeys flags (`XM`, `Ms`). Neovim takes a slow per-key timeout path when
it cannot see them, which is what makes typing feel janky.

`rex terminfo setup` runs once per account, not per repo. `setup.sh setup_rex`
runs it, and it is idempotent. It writes two machine-local files that are
deliberately not symlinked here:

- `~/.terminfo/x/xterm-rex` — the compiled entry, so a terminal can claim it.
- `~/.config/rex/ssh_config` — an ssh guard for hosts lacking the entry. Rex
  also adds an `Include` line at the top of `~/.ssh/config` pointing at it.

Like `~/.rex`, both are generated state rather than config: tracking them would
pin one machine's output and fight regeneration. Same reason `ssh_config` is not
in the "Linked files" list above.

Terminfo is read by a process at startup, so a program launched before the
install keeps its old `TERM` and stays slow. Open a new pane; no config reload
and no server restart is needed, since the server reads the entry fresh per pane.

```sh
rex terminfo status   # what a new terminal would be given, and why
rex terminfo setup    # install the entry + ssh guard (once per account)
rex terminfo host     # same entry on a remote host you use over ssh
```

Verify from inside the new nvim: `:lua print(vim.env.TERM)` prints `xterm-rex`.

## Sidebar

`cmd+b` toggles the sidebar (`client.sidebar.toggle`), replacing the shipped
`cmd+/`. The config stacks above the client's own bindings, so the `rex.bind`
alone wins; `rex.unbind` cannot remove a client default, only a binding this
file made, so it is not used here.

Runtime state — `server.sock`, `host-id`, `servers/`, `terminal/` — lives in
`~/.rex` and is machine-local. It is not tracked here.

## Verifying

```sh
rex config check    # load the config and report bindings/actions
rex config reload   # make the running server re-read the config
```
