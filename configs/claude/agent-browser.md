# agent-browser

Machine-local notes for `agent-browser` — the things the CLI's own guide can't tell you.
Kept out of `personal.md` because that file is loaded on every turn of every session;
this one is read on demand.

## Install

Homebrew, native Rust binary at `/opt/homebrew/bin/agent-browser`. Upgrade with
`brew upgrade agent-browser`.

Replaced a pnpm 0.13.0 shim at `~/Library/pnpm/agent-browser` on 2026-09-15; the shim
was deleted.

## The guide is served by the binary — never copy it

```sh
agent-browser skills get core        # workflows, patterns, troubleshooting
agent-browser skills get core --full # + full command reference and templates
agent-browser skills list            # electron, slack, dogfood, derive-client, ...
```

Session claiming, daemon lifecycle, and the command reference all live in `core`. Read it
there; a copy here would drift.

`~/.agents/skills/agent-browser/SKILL.md` (symlinked into `~/.claude/skills/`) is a
discovery stub copied verbatim from the package, with no `references/` or `templates/`
directory on purpose — its whole job is routing to `skills get core`.

**Why it stays a stub:** the previous hand-written copy sat on v0.13 content while the CLI
had moved to v0.37 — 24 minor versions of stale command guidance, with nothing to signal
it. CLI-served content matches the installed version by construction. The standalone
`dogfood` skill was removed for the same reason; the stub routes QA requests to
`agent-browser skills get dogfood`.

Refresh the stub after an upgrade (the path is version-independent):

```sh
cp "$(agent-browser skills path agent-browser)/SKILL.md" ~/.agents/skills/agent-browser/SKILL.md
```

Because that overwrites the file, local findings belong in this doc, not in the stub. The
stub's `hidden: true` frontmatter is inert in Claude Code — unrecognized fields are ignored,
and the skill still appears (verified). Neither this skill nor `core` is tracked in
`~/.agents/.skill-lock.json`, which lists only the `mattpocock/skills` entries, so no
updater touches them.

## WebGL and WebGPU render headless on this Mac

Measured 2026-09-15 — M1 Max, agent-browser 0.37.1:

- Headless WebGL 2.0 runs on the **ANGLE Metal Renderer** — real hardware.
- `agent-browser doctor --webgpu` passes both render and headless screenshot (`apple metal-3`).

So headless (the default) is the right choice, and `--headed` is for watching a run, not for
getting a context. A black WebGPU canvas is fixed by `--webgpu` — see `references/webgpu.md`
via `skills get core --full`.

This supersedes an earlier rule that read "WebGL fails in headless mode (SwiftShader can't
create a context), always use `--headed`." SwiftShader is the Linux/CI software fallback; it
was never the path on this machine.
