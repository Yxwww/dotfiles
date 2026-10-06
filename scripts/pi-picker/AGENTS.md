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
2. **Row field order is frozen**: `target \t pane_id \t display \t path`. The wrapper jumps by
   **field 2 (`%pane_id`)**, fzf shows field 3 and passes field 2 to `preview`. Field 1 is kept for
   human/debug readability only -- **never jump by it.** It is `session:window_index.pane_index`, a
   positional address that tmux renumbers whenever a window or pane closes (pane indices compact
   unconditionally; window indices too under `renumber-windows on`). Between `list` printing a row
   and the user pressing Enter the same string can name a **different pane**, and tmux resolves a
   stale index happily with exit 0 -- so the jump lands on an unrelated agent with no error. The
   session is re-derived from the pane id at jump time, because a session rename also invalidates
   field 1's session name. See `jump_to_pane` in the wrapper and `tmux-choose-pi.jump.test.js`.
   Field 3 is `<status dot> <title> · <branch>±<dirty> · <age>`, where `<age>` is a compact
   relative age (`<1m`/`4m`/`2h`/`3d`) or `—` when the pane has no signal at all. The branch
   segment is omitted entirely when there is no branch, so `.match(/·/g).length` is 1 in that case
   and 2 otherwise. `—` is not a padding artifact: it is the no-recency sentinel and is asserted.
3. **`list` sorts rows; `preview` does not.** The sort key is `max(lastHumanTs, lastEventTs)`
   (`recencyOf`), one timeline -- see the `Ordering` header comment in the source for why the two
   alternatives were rejected. Sorting happens on `listRows()` output, so the sort key never enters
   the row string and fzf can be handed the rows unchanged. Do not add `--no-sort` to fzf: typeahead
   ranking is the picker's other half, and fzf's default tiebreak keeps input order for equal scores.
4. **`lastHumanTs` is not `lastUserTs`.** pi injects skill bodies and file attachments as
   `role:user` text, so `lastUserTs` moves on machinery. `humanText()` strips the wrapper and returns
   the prompt typed after it, or `null` for a body-only (or unclosed-tag) injection. Both
   `users[]` and `lastHumanTs` are gated on it, so an injection never appears as an ask and never
   claims human recency -- it still moves `lastEventTs`.
5. **Dead-pane detection gates on the payload, not the exit code** — `display-message` on a dead
   pane exits **0 with empty stdout**, so a `status !== 0` check is a dead branch.
5. **`capture-pane` stderr is suppressed**, else `can't find pane` prints into the fzf preview
   window for a pane that just died.
6. **`process.stdout.on("error", …)` EPIPE guard** — `list | head -1` must exit 0, not throw.
7. **`git status --porcelain=v2 --branch` gives branch *and* dirty in one fork**, but exits 128
   outside a work tree. The `symbolic-ref` fallback must stay, or a bare-repo pane loses its branch
   label. Cost is one extra fork in the rare case, zero in the common path.
8. **`lastResultError` is assigned, not OR'd** (`= m.isError === true`). OR-ing pins a pane red
   forever after one failed tool call.
9. **Transcript selection uses mtime, never filename sort.** A resumed session appends to an old
   filename; name-sort picks the stale file.
10. **`_gitCache` is process-scoped and never invalidated** — correct because one invocation is one
   snapshot, and it makes `list` and `preview` agree. Tests must `clear()` between cases.

## Tests

```sh
node --test scripts/pi-picker/*.test.js     # 66 tests: 19 format / 16 transcript / 28 io / 3 jump
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
  2 in an uncommitted change). Assert the contract: field indices, tab-safety, that branch/`±N`/age
  land in field 2. Padding assertions break on cosmetic churn.
- **Row age is rendered against `Date.now()`.** Anchor time-sensitive fixtures to `Date.now()`, not a
  fixed epoch, or the assertion ends up testing the calendar (a fixture pinned to 2026-01-01 renders
  `278d`, not `1h`, once the clock moves). The pure `recencyAge(ts, now)` form takes `now` explicitly
  and should be preferred for anything not going through `list`.
- **Give each pane its own cwd in ordering tests.** `transcriptFor` resolves a transcript by cwd slug,
  so panes sharing a directory collapse onto ONE transcript and the fixture quietly tests nothing.
  This bit the first version of the `CLI list` ordering test.
- Determinism: inject `now` into `computeStatus`/`turnElapsed`; use fixed `utimesSync` dates for
  mtime tests. Never compare against wall clock.

## Known bugs, some pinned on purpose

Fixed-by-accident or "cleaned up" changes to these will fail a test — update the test deliberately,
not implicitly.

| state | detail |
|---|---|
| **fixed** | `humanizeAge` passed fractional seconds through: callers pass `(now-ts)/1000`, so an idle pane rendered `45.231s`. Now floored in the `s` bucket. Covered by a test. |
| **fixed** | A bare `null` transcript line **threw** `TypeError` (`JSON.parse("null")` succeeds, then `d.timestamp` dereferenced null). Guarded with `if (!d \|\| typeof d !== "object") continue;`. The old test asserted the throw; it was updated deliberately with the fix. |
| **fixed** | The `<file …>` strip was opening-tag-only, so a real attachment's `BODY` and `</file>` dominated `users[]` and could blank the ask entirely. `humanText()` now strips the whole wrapper and keeps only a prompt typed after it; body-only injections are dropped from `users[]` altogether. Same root cause as the `lastHumanTs` filter, so one fix covered both. |
| **open** | `paneInfo`'s `spawnSync` has no `stdio` override, so a dead pane's `can't find pane` reaches stderr (unlike `capture-pane`). |
| **open** | `transcriptFor` never checks `isFile()`; a directory named `*.jsonl` with the newest mtime is returned. Degrades gracefully to "(unreadable transcript)". |
| **open** | `recencyOf` reads `lastHumanTs`/`lastEventTs` off the analysis object, so anything else handed to `sortRows` silently sorts as recency 0 (bottom). `listRows()` is the only production caller and always supplies both. |
| **latent** | `parseTs(NaN)` returns `NaN`, not 0 (`typeof NaN === "number"` short-circuits). Unreachable from valid JSON today. |
| **latent** | `cleanTitle(undefined)` returns `undefined`; `shortModel("vendor/")` returns `""`. Both hidden by current callers' `\|\| "—"` guards. |
| **accepted** | A branch literally named `(detached)` is indistinguishable from git's sentinel → renders with no branch. Pinned as-is. |
| **accepted** | `role: "custom"` messages (`custom_message` entries) are not parsed at all, so an extension-injected message neither appears as an ask nor moves either timestamp. 993 such entries exist in the local corpus; none were observed to be the last entry of a live pane. |
| **accepted** | Ordering is by *activity*, not by "last user message" literally: a pane with agent activity and no human message can outrank one you typed in longer ago. That is the chosen contract — see the `Ordering` comment in the source. |
| **won't fix here** | Shared-cwd panes resolve to one transcript. Needs pi to publish os-pid → session-file. See README. |

## Drift to check before editing

`git status` on this tool's files. The working copy may differ from the pushed PR — in particular
`cumCost` (cumulative session cost) exists in the pushed diff and was removed locally, so
`analyzeTranscript` currently accumulates no cost and `renderCard` shows only the last turn's.
Don't "restore" it as a bug fix; it was a deliberate UI edit. Verify which state you're in before
proposing changes to the row layout.
