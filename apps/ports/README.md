# pf — port finder & process manager

TUI and CLI for listing listening TCP ports on macOS with enriched process info (dev tool name, project directory, full command).

## Install

```bash
cd apps/ports && bun install
```

The `pf` alias and Claude skill are set up by `linkdotfiles.sh`.

## Usage

```
pf                  Interactive TUI
pf list             Plain table (pipe-friendly)
pf json             JSON output (--compact for single line)
pf find <query>     Search by port, name, project, or command
pf kill <target>    Kill by port, PID, name, or project
pf --snapshot       Colored snapshot
```

## Interactive keys

```
j/↓  down   k/↑  up   d/enter  kill   r  refresh   q  quit
```

## Stack

- **Runtime**: Bun
- **TUI**: OpenTUI (`@opentui/core`) — Zig native core with TypeScript bindings
- **Platform**: macOS (uses `lsof` and `ps`)
