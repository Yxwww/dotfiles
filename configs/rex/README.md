# rex

Config for [rex](https://rex.dev), the multiplexer for all work.

Rex reads exactly one config file per account: `init.lua` in `$XDG_CONFIG_HOME/rex`
or `~/.config/rex`. It binds keys with `rex.bind` and defines custom actions with
`rex.action`.

## Linked files

`linkdotfiles.sh` symlinks `init.lua` and `mdpick.sh` into `~/.config/rex/`.

`mdpick.sh` is resolved from the config file's own directory at load time
(`debug.getinfo(1, "S")`), so a relative `mdpick.sh` reference works whether the
config is the linked dotfiles copy or a machine-local one.

Runtime state — `server.sock`, `host-id`, `servers/`, `terminal/` — lives in
`~/.rex` and is machine-local. It is not tracked here.

## Verifying

```sh
rex config check    # load the config and report bindings/actions
rex config reload   # make the running server re-read the config
```
