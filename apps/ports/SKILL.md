---
name: pf
description: "Port finder and process manager CLI. Use this skill whenever the user mentions port conflicts, wants to see what's listening on a port, needs to kill a dev server, asks 'what's running on port X', wants to free up a port, or is debugging EADDRINUSE / address-already-in-use errors. Also trigger when the user mentions pf directly, or asks about processes occupying ports. Even if they say 'kill port 3000' or 'something is using 5173' without mentioning pf — this skill knows how."
---

# pf — port finder & process manager

`pf` is a local CLI tool (aliased in .zshrc) that lists all listening TCP ports on this machine, enriched with the actual dev tool name (vite, next, webpack, etc.) and project directory — not just the generic `node` process name.

## When to reach for pf

- User gets `EADDRINUSE` or "address already in use"
- User asks what's running on a port
- User wants to kill a stuck dev server
- User wants a snapshot of all listening ports
- You need port info programmatically (e.g., to pick a free port or check if a server is up)

## Commands

### Inspect

```bash
pf list                  # Plain table, no color — safe to pipe/parse
pf json                  # Full JSON with all fields (script, project, fullCommand)
pf json --compact        # Single-line JSON
pf find <query>          # Search by port number, process name, script, project, or command substring
pf --snapshot            # Colored table for human reading
```

### Act

```bash
pf kill <target>         # Kill by port number, PID, script name, project name, or command substring
                         # Uses SIGTERM (graceful). Accepts fuzzy match.
```

### Interactive

```bash
pf                       # Full-screen TUI — navigate with j/k, kill with d or enter, refresh with r, quit with q
```

## Output fields

Each port entry contains:

| Field         | Example                          | Notes                                      |
|---------------|----------------------------------|---------------------------------------------|
| `port`        | `5173`                           | The listening TCP port                      |
| `pid`         | `88252`                          | OS process ID                               |
| `command`     | `node`                           | Short process name from lsof                |
| `script`      | `vite`                           | Extracted dev tool name from full command    |
| `project`     | `security-dashboard-app`         | Extracted from path before node_modules     |
| `fullCommand` | `node /Users/.../bin/vite --port 5173` | Full argv from ps                    |
| `address`     | `127.0.0.1` or `*` or `[::1]`   | Bind address                                |
| `protocol`    | `IPv4` / `IPv6`                  |                                             |
| `user`        | `yuxi`                           | OS user owning the process                  |

## Choosing the right command

- **Need to read the output yourself or show the user?** Use `pf list` or `pf --snapshot`.
- **Need structured data to act on programmatically?** Use `pf json` and parse it.
- **User asked about a specific port/process?** Use `pf find <query>` first to confirm, then `pf kill` if needed.
- **User just says "kill port 3000"?** Go straight to `pf kill 3000`.
- **User wants to browse everything interactively?** Suggest `pf` (the TUI) — but note this is interactive and blocks the terminal, so don't run it from a script or subagent.

## Examples

**"Something is using port 3000"**
```bash
pf find 3000
# Output:
# 3000   42156   next   my-app
#   → node /Users/yuxi/git/my-app/node_modules/.bin/next dev
```

**"Kill whatever vite server is running"**
```bash
pf kill vite
# Output:
# killed 88252 (vite) on port 5173
```

**"What dev servers do I have running?"**
```bash
pf list
```

**"Free up port 8080 for me"**
```bash
pf kill 8080
```

**Check programmatically if a port is in use:**
```bash
pf json --compact | jq '.[] | select(.port == 3000)'
```

## Important notes

- `pf kill` uses SIGTERM (signal 15), not SIGKILL — processes get a chance to clean up. If a process doesn't die, the user may need `kill -9 <pid>` manually.
- Some system ports require `sudo` to see or kill. If `pf list` shows fewer ports than expected, suggest `sudo pf list`.
- The `script` field is extracted heuristically from the full command — it catches most Node.js dev servers (vite, next, nuxt, webpack, esbuild, etc.) but may be empty for non-standard setups.
- Don't launch `pf` (the TUI) in non-interactive contexts. Use `pf list`, `pf json`, or `pf find` instead.
