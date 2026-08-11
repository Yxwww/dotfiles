# pi coding agent

Config for [pi](https://github.com/earendil-works/pi-coding-agent), symlinked
into `~/.pi/agent/` by `linkdotfiles.sh`. Install/restore via
`./setup.sh setup_pi`.

## What's backed up here

| File (under `configs/pi/agent/`) | Lives at | Purpose |
|---|---|---|
| `settings.json` | `~/.pi/agent/settings.json` | theme, `packages`, pi config |
| `models.json` | `~/.pi/agent/models.json` | custom LiteLLM provider (apiKey is `$LITELLM_API_KEY` env ref — no secret) |
| `extensions/rise-against-header.ts` | `~/.pi/agent/extensions/…` | custom startup header |
| `extensions/search.json` | `~/.pi/agent/extensions/search.json` | `web_search`/`web_read` backends (pi-search-hub); keyless only — no secrets |
| `npm/package.json` | `~/.pi/agent/npm/package.json` | pinned extension deps |
| `npm/package-lock.json` | `~/.pi/agent/npm/package-lock.json` | reproducible install |
| `agents/skill-lock.json` | `~/.agents/.skill-lock.json` | global skills manifest (see below) |

`AGENTS.md` is symlinked to `configs/claude/personal.md` (shared with Claude
Code's `CLAUDE.md`).

**Not committed** (gitignored in `.gitignore`): `bin/`, `sessions/`,
`auth.json`, `models-store.json`, `node_modules/` — runtime, secret, or
regenerable.

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

This setup has **two independent skill sources** under `~/.agents/skills/`:

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

## Web search

pi's `web_search` tool picks a backend from `.pi/search.json` (auto = best
configured). Backends: `duckduckgo` (free, needs `pip3 install ddgs`),
`serper`/`tavily`/`exa`/`brave`/`perplexity` (keyed), `searxng` (self-hosted),
`marginalia` (free shared key). Set `combine=true` to fan out across
backends; `combineMode: "targeted"` caps fan-out.

Not currently configured here. See the recommendation in the PR that added
this backup before committing a `search.json`.
