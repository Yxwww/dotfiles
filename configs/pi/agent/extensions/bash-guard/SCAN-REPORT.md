# Security scan — bash-guard (personal extension)

- **Candidate:** personal extension at `configs/pi/agent/extensions/bash-guard` (symlinked to `~/.pi/agent/extensions/bash-guard`)
- **Date:** 2026-08-26
- **Scanner:** `scan-extension` skill (manual review — not a third-party npm/git package)

## §1 Dependency audit (`npm audit`)

| Severity | Package | Advisory | Applies? |
|----------|---------|----------|----------|
| **Critical** (CVSS 8.1) | `shell-quote@1.8.3` | GHSA-w7jw-4-3-8p — `quote()` does not escape newlines in object `.op` values (CWE-77/78 command injection) | **No** — bash-guard imports `parse` only, never `quote` |
| **High** (CVSS 7.5) | `shell-quote@1.8.3` | GHSA-395f-4hp3-45gv — quadratic-complexity DoS in `parse()` (CWE-407) | **Yes** — `parse(command)` is called on every intercepted bash tool call |

`fixAvailable: true`. Latest is `1.10.0`. Upgrading to `>=1.9.0` clears both advisories (`quote` fixed >1.8.3; `parse` fixed >1.8.4).

## §2 Static review

**package.json highlights:** single runtime dep `shell-quote@^1.8.3`; `private: true`; no `scripts` (no install/postinstall hooks); no `allowScripts`.

Checklist:

- [x] Outbound network calls (`fetch`/`http`/`https`/`undici`/`WebSocket`) — **none**. Zero network I/O.
- [x] Hardcoded external URLs/endpoints — **none**.
- [x] `process.env` reads sent over the network — reads `PI_SUBAGENT_DEPTH` for subagent-detection control flow only; never transmitted.
- [x] `child_process` spawning network tools (`curl`, `wget`) — **none**; it *detects* `curl|sh`/`wget|sh` but never spawns them.
- [x] Install/postinstall scripts — **none**.
- [x] Obfuscated/encoded strings (base64 blobs decoded at runtime) — **none**; all literals are clear.

Other observations:

- **`ctx: any`** (`promptRunOrAbort`, `session_start` handler) — untyped context. Cosmetic/robustness, not a security issue.
- **Subagent detection via `PI_SUBAGENT_DEPTH`** — headless hard-block mode is selected purely by this env var (injected by `pi-subagents`). If it were ever absent/unset in a real headless process, the extension would fall back to the interactive path. This is a correctness edge, not an egress risk, and the direction of failure (prompting) is not dangerous.
- **Effectiveness note (not a vuln):** the hard-block regexes operate on the raw command string rather than the parsed tokens, so adversarial command construction can evade them (e.g. `rm -fr`, `sudo$( )`, newline tricks). The interactive mode uses proper `shell-quote` parsing and is more robust. Worth noting because a guard is only as strong as its matcher.

## §3 Runtime egress capture

Not run — extension performs no network I/O; runtime tap is unnecessary.

## Verdict

**Resolved — 2026-08-26.** `shell-quote` bumped `^1.8.3 → ^1.9.0` (resolves to `1.10.0`). `npm audit` now reports **0 vulnerabilities** — both advisories (critical `quote()` and high `parse()` DoS) cleared. `parse()` API unchanged and verified; the guard still fires correctly (regression-checked by attempting a blocked `rm -rf … | bash`).

**Originally:** issues found — dependency only. No data-egress or injection risk in the extension's own logic (it is a *defense* extension with no outbound calls, no install scripts, no obfuscation).

> Draft verdict — human maintains final approval.