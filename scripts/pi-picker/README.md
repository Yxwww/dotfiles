# pi-picker — tmux pane switcher for pi agents

Jump between running [pi](https://github.com/badlogic/pi-mono) coding-agent panes with one
keystroke, and see what each agent is *doing* before you land on it.

`prefix-P` opens an fzf popup: a list of every pi pane on the left, a live status card for the
highlighted pane on the right. Enter jumps, Esc cancels.

```
 π agents
 jump › ▸ ● dotfiles · master              │ pr-catchup - dotfiles
         ◐ sdk-repos · SDKS-3886 ±3        │ /Users/yuxi/git/mappedin/sdk-repos
         ○ graduation · yx/graduation      │
                                           │ model: beta   status: working
                                           │ activity: 3:01
                                           │ running: bash cd /Users/…
 jump · esc cancel
```

## Requirements

`tmux`, `node` (v18+, developed on v24), `fzf`, and `git` for the branch/dirty column. macOS and
Linux; the transcript lookup assumes `~/.pi/agent/sessions/`.

## Install

```sh
./linkdotfiles.sh          # symlinks scripts/ -> ~/.tmux/scripts
```

The binding lives in `dotfiles/.tmux.conf`:

```tmux
bind-key P display-popup -E -w 120 -h 90% "~/.tmux/scripts/pi-picker/tmux-choose-pi.sh"
```

No build step, no dependencies. Reload tmux (`prefix-r`) after changing the binding.

## What the rows mean

Only panes whose `pane_title` matches `/^(π|pi:)/` are listed — pi sets that title itself, so the
picker finds its own panes without any configuration.

| glyph | state | meaning |
|---|---|---|
| `●` green | idle | last event was an assistant reply |
| `◐` yellow | working | an event landed <5s ago, a tool is open, or the last message was yours |
| `✖` red | error | the most recent tool result had `isError` set |
| `○` grey | stale | nothing for 30 min (`STALE_AFTER_SEC`) |

Followed by `title · branch±N`, where `±N` is the count of dirty entries from
`git status --porcelain=v2` (untracked files included). The preview card adds model, elapsed turn
time, running tool, token/cost/tps, recent asks, last reply, and subagent labels.

## Running it by hand

Worth doing when something looks wrong — both subcommands are plain stdout and easy to inspect.

```sh
node scripts/pi-picker/tmux-choose-pi.js list            # one TAB row per pi pane
node scripts/pi-picker/tmux-choose-pi.js preview %257    # status card for one pane
node scripts/pi-picker/tmux-choose-pi.js list | head -1  # pipe-close must not error
```

`list` prints `target \t pane_id \t display_row \t cwd`. `tmux-choose-pi.sh` reads field 1 to jump,
fzf shows field 3 (`--with-nth 3`) and passes field 2 (`{2}`) to `preview`.

## Performance

Startup is the whole product — the binding exists to hop between agents fast, so it used to feel
broken at ~0.6s. A CPU profile put 94% of `list` inside `spawnSync`: 56 serial forks, none
individually slow. Forks were removed, not cached.

| | before | after |
|---|---|---|
| `list` (median of 7) | 300ms | **80ms** |
| `preview` (per cursor move) | 76ms | **40ms** |
| spawns per `list` | 56 | **8** |

fzf re-runs `--preview` on **every cursor move**, so anything there is paid interactively — treat
`preview` as the hot path and `list` as warm. Budget: one `display-message` per pane, one `git`
probe per *repo* (probed concurrently, memoised), zero `ps`. See `AGENTS.md` before adding a
subprocess call.

## Tests

```sh
node --test scripts/pi-picker/*.test.js     # 53 tests, no deps
```

| file | covers |
|---|---|
| `tmux-choose-pi.format.test.js` | pure formatters + `computeStatus` precedence |
| `tmux-choose-pi.transcript.test.js` | transcript event parsing, `parseGitStatus` |
| `tmux-choose-pi.io.test.js` | transcript lookup, real temp git repos, the TAB field contract, CLI smoke |

The suite is hermetic: it stubs `tmux` on `PATH` and points `HOME` at a fixture tree, so it never
touches your real tmux server or session files. That is a hard requirement, not a nicety — see
`AGENTS.md`.

## Known limitation: two panes in the same directory

Panes sharing a cwd resolve to the **same** transcript — whichever file that directory wrote last —
so two panes in one repo render identical cards. This is not fixable from the tmux side: the
transcript is picked by cwd because `PI_SESSION_FILE` is unreadable from outside (pi rewrites its
own argv, pushing the env region out of reach of `ps eww`), no tmux field carries a pane→session
mapping, and `lsof` shows pi does not hold the transcript open. Closing it needs pi to publish an
**os-pid → session-file pointer**.

## Troubleshooting

- **No panes listed** — check `tmux list-panes -a -F '#{pane_title}'`. Titles must start with `π`
  or `pi:`.
- **`skipped N malformed pane row(s)` on stderr** — a pane path contains a newline, which splits a
  row. The pane is dropped rather than shown wrong; the warning is deliberate so it can't vanish
  silently.
- **Card shows `(no session transcript — pane capture)`** — no `.jsonl` found for the pane cwd; it
  falls back to dumping the pane's screen.
- **Branch label missing in a bare repo** — `git status` exits 128 there; the code falls back to
  `symbolic-ref`. If it still disappears, that fallback regressed (covered by a test).
- **Popup opens slowly no matter what** — fzf's own first-draw floor measured ~0.5s in a pty
  harness, independent of this script.
