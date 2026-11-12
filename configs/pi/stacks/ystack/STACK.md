# ystack

Domain-agnostic development skills. The counterpart to **pstack** (personal/domain)
and **gstack** (Mappedin): those are pinned to a product, this one is not.

**A skill has exactly one origin. ystack never copies what another tool owns.**
This file is the machine-readable source of truth — `install.mjs` parses it.

## `origin: dotfiles`

Authored here, under `skills/`. Restore = symlink into `~/.agents/skills/`.
`linkdotfiles.sh` calls `install.mjs link`, which owns that loop.

| Skill | Purpose |
|---|---|
| `pre-commit` | before `git commit`; captures the *why*. Must use sentinel `/tmp/pi-pre-commit-active` — matches `git-workflow-gates.ts` |
| `pre-push` | *post*-push PR body sync. Triggered by the extension's nudge, not a skill trigger |
| `pr-catchup` | invoke-only `/pr-catchup` status brief for resuming a PR |
| `ship` | simplify → review-fix rounds → commit → push. Runs under `/tmp/pi-ship-active`; that path **must** match the extension |
| `simplify` | cleanup-only review: reuse, simplification, efficiency, altitude |
| `code-review` | three-axis review: Standards / Spec / Perf. The Perf axis delegates to its `references/perf-systems.md` for a five-axis systems pass (memory, layout, cpu, gpu, io). **Shadows** the `skills` CLI copy from `mattpocock/skills` |
| `flaky-ci` | CI-vs-local flake diagnosis; bounded local repro, then instrument CI |
| `pf` | port finder / process manager CLI |

### Shadows

These names also exist in the `skills` CLI manifest. The dotfiles copy wins, and
`npx skills update -g` will revert it for `code-review`:

- `code-review` → supersedes `mattpocock/skills`.

To keep the local version, skip the CLI update for that skill, or re-run
`./linkdotfiles.sh` after removing the CLI's real directory (`ln -snf` will not
replace a non-empty directory).

## `origin: skills-cli`

Installed by `npx skills add <repo> -g`, tracked in `~/.agents/.skill-lock.json`
(backed up at `configs/pi/agents/skill-lock.json`). **Not copied into dotfiles.**

- `mattpocock/skills` — 29 skills, including `grilling`, `tdd`, `research`, `pr`,
  `teach`, `retro`, `chief-of-staff`, `codebase-design`, `diagnosing-bugs`,
  `domain-modeling`, `grill-with-docs`, `prototype`, `writing-for-agents`.

`install.mjs skills-cli` re-adds any tracked skill whose folder is missing.
Membership is read from the lockfile, not from this file, because the CLI owns
that list.

## `origin: cli-installer`

Skills that are **generated stubs** from a CLI you installed. Restore = re-run the
tool; never commit a copy — the tool rewrites the file on upgrade.

| Skill | Install | Regenerate skill |
|---|---|---|
| `agent-browser` | `brew install agent-browser` | `agent-browser skills install` |
| `rex` | Rex app (`com.superlogical.rex`) | `rex skill setup` |

Both stubs say so themselves: `agent-browser` points at `agent-browser skills get core`,
`rex` at `rex __internal skill`. Backing either up would freeze a stale pointer.

## `excluded`

Belongs to another stack. ystack neither installs nor links these:

- **pstack / Mappedin** — private repo `Yxwww/mpdin`, cloned at
  `~/git/mappedin/skills/` (one directory per skill, flattened to the repo root):
  - `bump-sdk`
  - `dev-flow`
  - `review-loop`
  - `sdk-browser`
  - `sdk-issue-report`
- **gstack** — `task-board` (Mappedin Rally MCP wrapper). Also in the private
  `Yxwww/mpdin` clone at `~/git/mappedin/skills/task-board`.

## Usage

```sh
./scripts/ystack/install.mjs check     # report state, change nothing
./scripts/ystack/install.mjs link      # symlink origin:dotfiles, remove stale ystack links
./scripts/ystack/install.mjs skills-cli # restore missing skills-CLI skills from the lockfile
./scripts/ystack/install.mjs doctor    # verify every declared skill resolves
```

`install.mjs link` is called by `linkdotfiles.sh`; `skills-cli` is called by
`setup.sh setup_pi`.
