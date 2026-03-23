# CLAUDE.md — apps/ports

## What this is

`pf` — a Bun CLI/TUI for listing and killing processes on listening TCP ports. Aliased as `pf` in `.zshrc`.

## Commands

```
bun run src/index.ts              # or just `pf` via alias
bun run src/index.ts list         # pipe-friendly plain table
bun run src/index.ts json         # structured output
bun run src/index.ts find <q>     # search ports/processes
bun run src/index.ts kill <t>     # kill by port, pid, name, or project
bun run src/index.ts --snapshot   # colored table
```

## Architecture

```
src/
  index.ts      Entry point — CLI arg routing, subcommands
  ports.ts      Data layer — lsof parsing, ps enrichment, kill. Pure functions, no UI.
  snapshot.ts   Non-interactive colored output (ANSI escapes, no OpenTUI dependency)
  tui.ts        Interactive TUI (OpenTUI renderer, SelectRenderable, keyboard handling)
```

- `ports.ts` is the only file that shells out (`lsof`, `ps`, `kill`). Everything else consumes its output.
- `snapshot.ts` has zero OpenTUI dependency — it works even if OpenTUI has issues.
- `tui.ts` uses OpenTUI's imperative API (`createCliRenderer`, `BoxRenderable`, `SelectRenderable`). Don't launch it in non-interactive contexts.

## Key decisions

- **SelectRenderable over manual ScrollBox**: Select handles j/k nav, scroll, and selection state internally. Rows are formatted as padded strings (monospace terminal makes this look tabular).
- **Single `ps` call for enrichment**: All PIDs are batched into one `ps -o pid=,command= -p <pids>` call rather than N individual calls.
- **`script` field heuristic**: Extracted from `node_modules/.bin/<tool>` in the full command, falling back to keyword matching against known dev tools (vite, next, webpack, etc.).
- **SIGTERM not SIGKILL**: `pf kill` sends signal 15 to allow graceful shutdown.

## Modifying

- To add new subcommands, add a `case` to the switch in `index.ts`.
- To recognize new dev tools, add to `KNOWN_SCRIPTS` in `ports.ts`.
- To change TUI layout/colors, edit `tui.ts`. Colors use hex strings consumed by OpenTUI's `ColorInput`.
- The SKILL.md in this directory is symlinked to `~/.claude/skills/pf/` — update it when CLI surface changes.
