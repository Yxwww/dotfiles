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
