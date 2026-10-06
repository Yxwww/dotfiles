# pi-picker — tmux pane switcher for pi agents

Jump between running [pi](https://github.com/badlogic/pi-mono) coding-agent panes with one
keystroke, and see what each agent is *doing* before you land on it.

`prefix-P` opens an fzf popup: a list of every pi pane on the left, a live status card for the
highlighted pane on the right. Enter jumps, Esc cancels.

```
 π agents
 jump › ▸ ◐ dotfiles · master · <1m       │ pr-catchup - dotfiles
         ◐ sdk-repos · SDKS-3886 ±3 · 4m   │ /Users/yuxi/git/mappedin/sdk-repos
         ● graduation · yx/graduation · 2h │
         ○ legacy-tooling · main · 3d      │ model: beta   status: working
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

Followed by `title · branch±N · age`, where `±N` is the count of dirty entries from
`git status --porcelain=v2` (untracked files included), and `age` is how long since the pane was
last active (`<1m`, `4m`, `2h`, `3d`, or `—` when it has no activity at all). The branch segment is
omitted when there is no branch. The preview card adds model, elapsed turn time, running tool,
token/cost/tps, recent asks, last reply, and subagent labels.

## What order the panes are in

Most recently active first, not tmux's pane order. Typing into a pane or opening one both move it
to the top, so the list answers "which of these should I look at now".

"Active" is a single timeline: **whichever is newer of the last human message and the last event of
any kind.** Two simpler rules were rejected:

| rule | why not |
|---|---|
| last **human** message only | a pane you just opened has no typed message, so it would sink below panes you spoke to hours ago — backwards, since a fresh pane is usually the one you want |
| last **event** of any kind only | ranks a pane as fresh whenever pi emits anything, including background work you never engaged with |

Taking the newer of the two needs no fallback case and keeps the sort and the `age` column reading
the same number, so they can never disagree. A pane with no activity at all sorts last; ties keep
tmux's order.

Two consequences worth knowing:

- **`age` means "since any activity", not "since you last typed".** A pane where the agent has been
  working for 20 minutes while you waited reads `<1m`, not `20m`.
- **Injected context is not human activity.** pi delivers skill bodies and file attachments as
  large `role: user` text blocks, so they are excluded from both the ask list and the human-recency
  signal — otherwise a pane nobody has touched would show a 30 KB skill body as its latest ask. They
  still count as activity, so such a pane stays ordered by real events.

fzf re-ranks as you type; its default tiebreak keeps this order for equal scores, so the ordering
is the starting point and a filter once you narrow. `--no-sort` is deliberately not used.

## Running it by hand

Worth doing when something looks wrong — both subcommands are plain stdout and easy to inspect.

```sh
node scripts/pi-picker/tmux-choose-pi.js list            # one TAB row per pi pane
node scripts/pi-picker/tmux-choose-pi.js preview %257    # status card for one pane
node scripts/pi-picker/tmux-choose-pi.js list | head -1  # pipe-close must not error
```

`list` prints `target \t pane_id \t display_row \t cwd`, sorted newest-activity-first. fzf shows
field 3 (`--with-nth 3`) and passes field 2 (`{2}`) to `preview`.

The jump uses **field 2, the `%pane_id`** — not field 1. Field 1 is
`session:window_index.pane_index`, a *positional* address: tmux renumbers indices whenever a window
or pane closes, so between `list` running and you pressing Enter the same string can name a
**different pane**, and tmux resolves it happily with exit 0. Jumping by the stable pane id removes
that race. The session is re-derived from the pane id at jump time, so a session rename can't
misroute it either. If the pane is gone by the time you press Enter, the picker says so instead of
jumping somewhere wrong.

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
node --test scripts/pi-picker/*.test.js     # 66 tests, no deps
```

| file | covers |
|---|---|
| `tmux-choose-pi.format.test.js` | pure formatters + `computeStatus` precedence |
| `tmux-choose-pi.transcript.test.js` | transcript event parsing, `parseGitStatus` |
| `tmux-choose-pi.io.test.js` | transcript lookup, real temp git repos, the TAB field contract, CLI smoke |
| `tmux-choose-pi.jump.test.js` | the wrapper's jump path: pane-id targeting, session re-derivation, vanished-pane error |

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
- **A row points at a shell prompt, not a running agent** — pi exited but left its pane open, and
  the pane kept pi's `π` title, so the picker still lists it. tmux reports the pane as perfectly
  alive (`pane_dead=0`), it just has no pi in it; the screen usually still shows
  `To resume this session: pi --session …`. Check with
  `tmux display-message -p -t %ID '#{pane_current_command}'` — `zsh` means pi is gone, `node` means
  it is running. This is not a stale-entry bug: `list` re-queries tmux on every run and caches
  nothing. Distinguishing the two needs a liveness signal tmux doesn't provide for this case
  (see the shared-cwd limitation below for the same root cause).
- **A row jumps to the wrong pane** — should not happen since the jump was switched to field 2
  (`%pane_id`). If it recurs, something is jumping by field 1 again; see `jump_to_pane` and its test.
- **Popup opens slowly no matter what** — fzf's own first-draw floor measured ~0.5s in a pty
  harness, independent of this script.
