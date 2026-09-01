# AGENTS.md — working on pi-picker

Instructions for AI agents modifying `tmux-choose-pi.js` / `tmux-choose-pi.sh`. Read the source
comments too — they carry the perf rationale that the code cannot express.

## What this is

One dependency-free CommonJS script with two subcommands, driven by a thin bash wrapper that runs
fzf. `list` emits TAB rows, `preview <pane_id>` emits an ANSI status card. Output is consumed by
**fzf and by a shell pipeline simultaneously**, which is why the field layout is a contract rather
than an implementation detail.

## The one rule that matters: forks are the cost

Nothing here is slow except `spawn`/`fork`. The original spent 94% of `list` in `spawnSync` with 56
serial subprocess calls, none individually slow. The rewrite got it to 8 by **deleting** work, not
caching it. Any change you make is measured in subprocesses.

Budget (do not regress without a stated reason):

- **1 `tmux display-message` per pane**, all format fields in one `PANE_FMT`. Never one per field.
- **1 `git` probe per distinct repo**, not per pane, fired concurrently via `execFile` and memoised
  in `_gitCache`. Several panes usually share a repo; per-pane probing made cost scale with panes.
- **Zero `ps`.** The process-tree walk is gone on purpose — it read `PI_SESSION_FILE` via `ps eww`,
  which always returned `null` because pi rewrites its own argv and pushes the env region out of
  reach. It cost ~84ms/`list` and ~23ms/`preview` for nothing. Do not reintroduce it.
- `preview` is the **hot path**: fzf re-runs it on every cursor move. `list` runs once per popup.

Measured baseline, so a regression is visible: `list` 80ms, `preview` 40ms, 8 spawns.

## Non-negotiable invariants

Each is covered by a test. Breaking one silently drops panes or corrupts the picker layout.

1. **`pane_current_path` is the last field and the tail is rejoined** (`f.slice(1).join("\t")` in
   `paneInfo`, `f.slice(3).join("\t")` in `buildRow`). A literal TAB in a directory name must
   overflow only into the terminal field. Nothing may index past field 3 of a `list` row. tmux
   strips control chars from `pane_title`, which is why the title is safe in field 0.
2. **Row field order is frozen**: `target \t pane_id \t display \t path`. The wrapper reads field 1
   to jump; fzf shows field 3 and passes field 2 to `preview`.
3. **Dead-pane detection gates on the payload, not the exit code** — `display-message` on a dead
   pane exits **0 with empty stdout**, so a `status !== 0` check is a dead branch.
4. **`capture-pane` stderr is suppressed**, else `can't find pane` prints into the fzf preview
   window for a pane that just died.
5. **`process.stdout.on("error", …)` EPIPE guard** — `list | head -1` must exit 0, not throw.
6. **`git status --porcelain=v2 --branch` gives branch *and* dirty in one fork**, but exits 128
   outside a work tree. The `symbolic-ref` fallback must stay, or a bare-repo pane loses its branch
   label. Cost is one extra fork in the rare case, zero in the common path.
7. **`lastResultError` is assigned, not OR'd** (`= m.isError === true`). OR-ing pins a pane red
   forever after one failed tool call.
8. **Transcript selection uses mtime, never filename sort.** A resumed session appends to an old
   filename; name-sort picks the stale file.
9. **`_gitCache` is process-scoped and never invalidated** — correct because one invocation is one
   snapshot, and it makes `list` and `preview` agree. Tests must `clear()` between cases.

## Tests

```sh
node --test scripts/pi-picker/*.test.js     # 53 tests: 13 format / 14 transcript / 26 io
```

Conventions, all of them load-bearing:

- `node:test` + `node:assert/strict`. No deps, no runner config, no `package.json` at repo root.
- **Hermetic or it's wrong.** The developer runs this against a live tmux server holding a dozen
  real π panes. Tests must stub `tmux` on `PATH` and point `HOME` at a fixture tree; a test that
  reads the real server passes by accident and rots immediately. Isolate git with
  `GIT_CONFIG_GLOBAL`/`NOSYSTEM` and by deleting `GIT_DIR`/`GIT_WORK_TREE`/`GIT_INDEX_FILE`.
- **Prove non-vacuity by mutation testing.** Break the source (in a `/tmp` copy), confirm the suite
  fails, restore, confirm the checksum. An assertion that cannot fail is worse than none. Verify
  your mutation actually applied — a silently non-matching substitution "proves" coverage that
  doesn't exist.
- **Do not assert column padding.** The row's display column set is in flux (it went 5 columns →
  2 in an uncommitted change). Assert the contract: field indices, tab-safety, that branch/`±N`
  land in field 2. Padding assertions break on cosmetic churn.
- Determinism: inject `now` into `computeStatus`/`turnElapsed`; use fixed `utimesSync` dates for
  mtime tests. Never compare against wall clock.

## Known bugs, some pinned on purpose

Fixed-by-accident or "cleaned up" changes to these will fail a test — update the test deliberately,
not implicitly.

| state | detail |
|---|---|
| **open** | `humanizeAge` passes fractional seconds through: callers pass `(now-ts)/1000`, so an idle pane renders `45.231s`. Needs `Math.floor` in the `s` bucket. Common path, cosmetic. |
| **open, test says `BUG:`** | A bare `null` transcript line **throws** `TypeError`. `JSON.parse("null")` succeeds, then `d.timestamp` dereferences null — the try/catch guards only the parse, not the non-object result. Fix is `if (!d \|\| typeof d !== "object") continue;`; the test asserts the throw, so it must be updated with the fix. |
| **open** | The `<file …>` strip is `/^\s*<file\b[^>]*>\s*/` — opening tag only. Real attachments are `<file name="p">BODY</file> prompt`, so `BODY` and `</file>` stay in `users[]` and still dominate "recent asks"; only `clip(…, 110)` bounds it. Diverges from the comment's intent. |
| **open** | Whitespace check runs *before* the strip, so an attachment-only message pushes `""` → renders a bare `❯ `. |
| **open** | `paneInfo`'s `spawnSync` has no `stdio` override, so a dead pane's `can't find pane` reaches stderr (unlike `capture-pane`). |
| **open** | `transcriptFor` never checks `isFile()`; a directory named `*.jsonl` with the newest mtime is returned. Degrades gracefully to "(unreadable transcript)". |
| **latent** | `parseTs(NaN)` returns `NaN`, not 0 (`typeof NaN === "number"` short-circuits). Unreachable from valid JSON today. |
| **latent** | `cleanTitle(undefined)` returns `undefined`; `shortModel("vendor/")` returns `""`. Both hidden by current callers' `|| "—"` guards. |
| **accepted** | A branch literally named `(detached)` is indistinguishable from git's sentinel → renders with no branch. Pinned as-is. |
| **won't fix here** | Shared-cwd panes resolve to one transcript. Needs pi to publish os-pid → session-file. See README. |

## Drift to check before editing

`git status` on this tool's files. The working copy may differ from the pushed PR — in particular
`cumCost` (cumulative session cost) exists in the pushed diff and was removed locally, so
`analyzeTranscript` currently accumulates no cost and `renderCard` shows only the last turn's.
Don't "restore" it as a bug fix; it was a deliberate UI edit. Verify which state you're in before
proposing changes to the row layout.
