# pf — port finder & process manager

TUI and CLI for listing listening TCP ports on macOS with enriched process info (dev tool name, project directory, full command).

## Install

```bash
cd apps/ports && bun install && bun run install-cli
```

Compiles a self-contained binary and symlinks it to `~/.local/bin/pf`. No `bun` or `node_modules` needed at runtime.

Requires `~/.local/bin` on your PATH (added by this repo's `.zshrc`).

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

## Rebuild

After editing source files:

```bash
bun run build       # recompile binary (symlink still points to it)
```

## Stack

- **Runtime**: Bun (compiled to standalone binary via `bun build --compile`)
- **TUI**: OpenTUI (`@opentui/core`) — Zig native core with TypeScript bindings
- **Platform**: macOS (uses `lsof` and `ps`)
