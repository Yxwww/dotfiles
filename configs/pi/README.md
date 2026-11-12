# pi coding agent

Config for [pi](https://github.com/earendil-works/pi-coding-agent), symlinked
into `~/.pi/agent/` by `linkdotfiles.sh`. Install/restore via
`./setup.sh setup_pi`.

## What's backed up here

| File (under `configs/pi/agent/`) | Lives at | Purpose |
|---|---|---|
| `settings.json` | `~/.pi/agent/settings.json` | theme, `packages`, pi config |
| `observability/settings.json` | `~/.pi/agent/observability/settings.json` | pi-observability footer layout |
| `extensions/rise-against-header.ts` | `~/.pi/agent/extensions/…` | custom startup header |
| `extensions/search.json` | `~/.pi/agent/extensions/search.json` | `web_search`/`web_read` backends (pi-search-hub); keyless only — no secrets |
| `extensions/git-workflow-gates.ts` | `~/.pi/agent/extensions/…` | pre-commit gate + post-push PR-description nudge (ports the active Claude hooks) |
| `extensions/skill-session-name.ts` | `~/.pi/agent/extensions/…` | names an unnamed session from its first real prompt, so `/resume` and the `π - <name> - <cwd>` title say what the session is about. Workflow skills (`pr-catchup`, `code-review`, …) are excluded: they name the process, not the subject, and named every such session identically |
| `npm/package.json` | `~/.pi/agent/npm/package.json` | pinned extension deps |
| `npm/package-lock.json` | `~/.pi/agent/npm/package-lock.json` | reproducible install |
| `agents/skill-lock.json` | `~/.agents/.skill-lock.json` | global skills manifest (see below) |
| `stacks/ystack/STACK.md` | — | **source of truth** for ystack: every dev skill, its origin, and what is excluded. Parsed by `scripts/ystack/install.mjs` |
| `stacks/ystack/skills/<name>/` | `~/.agents/skills/<name>/` | `origin: dotfiles` skills (pre-commit, pre-push, pr-catchup, ship, simplify, code-review, flaky-ci, pf); symlinked by the ystack installer |
| `agents/skills/<name>/` | — | *legacy path, emptied* — skills moved to `stacks/ystack/skills/` |
`AGENTS.md` is symlinked to `configs/claude/personal.md` (shared with Claude
Code's `CLAUDE.md`).

**Not committed** (gitignored in `.gitignore`): `bin/`, `sessions/`,
`auth.json`, `models-store.json`, `models.json`, `node_modules/` — runtime,
secret, or regenerable.

`models.json` is deliberately **not** versioned: it points at the Mappedin
LiteLLM gateway and names internal models, so it stays local-only at
`~/.pi/agent/models.json`. Regenerate it from the gateway's own listing
(`models-store.json`, written by the `pi-provider-litellm` extension) rather
than reconstructing it by hand.

## Web search (`extensions/search.json`)

Backs up `~/.pi/agent/extensions/search.json` for the `pi-search-hub`
extension, which provides the `web_search` and `web_read` tools. Only
**keyless** backends are enabled here, so the file carries no secrets:

- `firecrawl` — keyless, 1k credits/mo (primary).
- `marginalia` — shared public key, rate-limited backup.
- `duckduckgo` — disabled; `ddgs` under system Python 3.9 hits an OpenSSL
  `0x304` error. Re-enable after upgrading to Python 3.11+.

`web_read` uses Jina Reader (`r.jina.ai`), free, no key. To add a keyed
backend, edit the file and set `apiKey` to an ALL_CAPS env var name, a
`!shell command` (e.g. `!pass show api/tavily`), or a literal — **never
commit literal keys**. Recommended free-signup upgrades: Tavily (1k/mo,
best quality), Brave (2k/mo), Exa (1k/mo, fastest), Serper (2.5k one-time).

## Skills

pi loads skills from `~/.pi/agent/skills/` and `~/.agents/skills/` (global),
plus project `.pi/skills/` and `.agents/skills/` when trusted. See pi's
`docs/skills.md` (Agent Skills standard).

This setup has **four skill origin classes** under `~/.agents/skills/`. The
authoritative, machine-readable list is
[`configs/pi/stacks/ystack/STACK.md`](stacks/ystack/STACK.md) — this section is
the narrative version.

**The rule: a skill has exactly one origin, and ystack never copies what another
tool owns.** `scripts/ystack/install.mjs` implements it (`link`, `skills-cli`,
`check`, `doctor`; tests in `install.test.mjs`).

| Origin | Restored by |
|---|---|
| `dotfiles` — authored in `stacks/ystack/skills/` | `install.mjs link` (called by `linkdotfiles.sh`) |
| `skills-cli` — `mattpocock/skills` | `install.mjs skills-cli` (called by `setup_pi`) |
| `cli-installer` — generated stubs (`agent-browser`, `rex`) | re-run the installing tool |
| `excluded` — pstack/gstack domain skills | not installed here |

### 1. `skills` CLI (vercel-labs/skills) — mattpocock skills

The `skills` npm package (v1.5.7, "open agent skills ecosystem",
`github.com/vercel-labs/skills`) manages these. It writes
`~/.agents/.skill-lock.json` (the manifest backed up at
`configs/pi/agents/skill-lock.json`) and installs skill folders into
`~/.agents/skills/`.

Installed (from `mattpocock/skills`): `grill-me`, `grill-with-docs`,
`prd-to-issues`, `tdd`, `write-a-prd`.

Commands:
```sh
npx skills add <github-owner/repo> -g -y   # add global skill
npx skills list -g                          # list global skills
npx skills remove -g                        # interactive remove
npx skills update -g -y                     # update to latest
```

Note: v1.5.7 has **no "restore global from `.skill-lock.json`"** command —
`experimental_install` only reads a *project-level* `skills-lock.json`. So
`setup_pi` re-adds each skill by name from the manifest (idempotent: skips
folders that already exist).

### 2. skill-creator — sparse checkout of anthropics/skills

`skill-creator` is a blob-less sparse checkout of `anthropics/skills`,
scoped to `skills/skill-creator/`:

```
~/.agents/skills/skill-creator-repo/   # git clone --filter=blob:none --sparse
└── skills/skill-creator/
~/.agents/skills/skill-creator -> skill-creator-repo/skills/skill-creator  # symlink
```

`setup_pi` creates this if missing.

### 3. Custom git-workflow + orchestration skills

These now live in `configs/pi/stacks/ystack/skills/` and are declared in
`STACK.md`. `linkdotfiles.sh` calls `install.mjs link`, which links each
`origin: dotfiles` skill into `~/.agents/skills/` and **refuses to overwrite a
real directory** owned by another tool.

> **`code-review` collides with `mattpocock/skills`.** That package ships its own
> `code-review`, so any `npx skills add mattpocock/skills` writes a real directory
> over the ystack symlink. `install.mjs skills-cli` now detects this and refuses
> the whole source (it would clobber an owned name). To restore mattpocock skills
> by hand, install them, then re-run `./linkdotfiles.sh` — but `ln -snf` will not
> replace a non-empty directory, so remove that one directory first.
- **`pre-commit`** — runs before `git commit`, capturing the *why* of the change.
  Uses the sentinel `/tmp/pi-pre-commit-active` to suppress the extension's
  `tool_call` gate; that path **must match** the `git-workflow-gates.ts`
  extension.
- **`pre-push`** — despite the name, a *post*-push workflow: updates the PR
  description after a successful `git push`. Auto-triggered by the extension's
  `tool_result` nudge, not a skill trigger.
- **`pr-catchup`** — invoke-only `/skill:pr-catchup` status brief for resuming
  a PR.
- **`ship`** — one-shot `simplify` → review-and-fix rounds → commit → push. Each
  review round is a **fresh subagent that both reviews and fixes**; the parent only
  routes and commits, so the skill never self-reviews. Bounded at 3 rounds, commits
  only when nothing Critical remains. Composes `simplify`, `pre-commit` and
  `pre-push` rather than duplicating them. Runs under the `/tmp/pi-ship-active`
  sentinel, which makes `git-workflow-gates.ts` skip the post-push PR-body nudge
  (Step 7 runs that sync deliberately); that path **must match** the extension.

`tmux-fanout` was removed; parallel subagent fan-out is done with the
`pi-subagents` `workflowScript` runs API instead.

### Bridging into other agents

The `skills` CLI symlinks each installed skill into per-agent dirs, e.g.
`~/.claude/skills/<name> -> ../../.agents/skills/<name>`. Those links are
managed by the CLI, not by `linkdotfiles.sh` (which only links `apps/ports`
as `~/.claude/skills/pf`).

## Restore on a new machine

```sh
./setup.sh setup_pi   # installs pi, links config, sparse-checkouts skill-creator,
                      # re-adds mattpocock skills from the manifest
```

Then launch `pi`. Its skill manager will pick up `~/.agents/skills/`.
