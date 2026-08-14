---
name: tmux-fanout
disable-model-invocation: true
description: >-
  Fan out a coding task across multiple `pi -p` subagents running in parallel
  tmux panes, with an orchestrator that waits for completion and a Devil's
  Advocate reviewer agent that verifies the workers' claims by re-running
  commands. Use when the user wants to parallelize work across agents, split a
  task between subagents, run agents in tmux panes, orchestrate multiple pi
  agents, add a reviewer/devil's-advocate to agent work, or speed up a task by
  dividing it. Also use when the user mentions "fan out", "split work between
  agents", "parallel subagents", "divide and conquer", or wants one agent to
  review another's work. This skill bundles the tmux plumbing, the completion
  protocol, and the reviewer phase so you don't reinvent them each time.
---

# tmux-fanout

Run several `pi -p` subagents in parallel tmux panes, wait for all of them, then
launch a Devil's Advocate reviewer that verifies their work by re-running
commands — not by trusting their summaries. Born from a real run that split a
migration across two agents; the script and protocol below are the hardened
version of what that run did ad hoc.

## Read these limits first — they define when this skill is the wrong tool

tmux fan-out is for **coarse-grained, parallel-independent** work. It is the
wrong tool for tightly-coupled collaboration. Specifically:

- **No pane-to-pane messaging.** tmux `send-keys` is one-way (orchestrator →
  pane). There is no bus between worker panes. If agents need to talk to each
  other at runtime, do not use this skill — use one agent with tool calls, or
  pi's `--mode rpc` for real bidirectional structured I/O. Pretending tmux
  solves this produces races and deadlocks.
- **Asynchronous handoff only, via scratch files.** The only safe
  cross-agent channel is files in the job dir (e.g. agent B reads agent A's
  `.result` after A's `.done` appears). That means a downstream agent can only
  start after its upstream finishes — which is a sequential dependency, not
  parallelism. If the dependency is tight, don't split it.
- **`pi -p` is fire-and-forget.** The agent reads the prompt and exits; it
  cannot ask you a question mid-run. Therefore every worker brief must be
  fully self-sufficient — every decision pre-made, every default stated. An
  ambiguous brief produces a silent wrong turn, not a clarifying question.
  Over-specify on purpose; that's a feature, not waste.
- **No live progress, no heartbeats.** You get completion (a `.done` file) and
  logs (a `tee`'d file). You do not get streaming status. If you need
  streaming, again, use RPC.

When in doubt about whether a task fits: if you can hand each agent a disjoint
file set and a brief with zero "wait for the other agent" steps, it fits. If
you can't, it doesn't.

## The model

```
                 ┌────────────────────────┐
   orchestrator  │  fanout.sh run -- A=.. B=.. │   (you, or the skill user)
  (this script)  └────────────┬───────────┘
                               │ tmux new-window + split-window
        ┌──────────────────────┼──────────────────────┐
        ▼                      ▼                      ▼
   ┌─────────┐            ┌─────────┐            ┌─────────┐
   │ worker A │            │ worker B │   ...      │ worker N │   pi -p, disjoint files
   │ pi -p    │            │ pi -p    │            │ pi -p    │
   └────┬─────┘            └────┬─────┘            └────┬─────┘
        │ writes A.result      │ writes B.result       │
        │ touch A.done         │ touch B.done          │
        └──────────────────────┴───────────────────────┘
                               │ orchestrator sees all *.done
                               ▼
                        ┌──────────────┐
                        │ Devil's       │  reads *.result + git diff,
                        │ Advocate      │  re-runs verification, writes
                        │ reviewer      │  verdict.json + reviewer.done
                        └──────────────┘
```

Three roles: **orchestrator** (you + `fanout.sh`), **workers** (parallel `pi -p`
agents with disjoint ownership), **reviewer** (a final `pi -p` agent that
challenges the workers' claims by re-executing). The orchestrator never
reasons about the work; it only moves files and waits on signals. The
reviewer is the quality gate.

## The protocol (why `.done` and `.result` exist)

A real run that just grepped logs for the word "Done." and checked whether a
pane had returned to `zsh` was fragile: an agent can print "Done." mid-work,
or hang silently, and "pane is zsh" is true before the agent even starts. The
fix is an explicit, unambiguous signal:

- **`<role>.result`** — the agent's structured summary (what it did, files
  touched, how it verified, deviations). Written *before* `.done`. This is the
  reviewer's primary input.
- **`<role>.done`** — an empty file the agent `touch`es as its **final**
  action. Existence of this file is the orchestrator's only completion signal.

The orchestrator prepends a preamble telling each agent to do exactly this, so
brief authors don't repeat the plumbing. The contract is: `.result` before
`.done`, and `.done` is terminal. If a worker pane returns to the shell with an
`EXIT=` in its log but no `.done`, the orchestrator flags it as a crash rather
than a completion — that's the failure mode the protocol exists to catch.

Everything lives under `/tmp/pi-fanout/<jobid>/`, and the tmux window is named
`fanout-<jobid>` so a dead orchestrator can be found and cleaned up (see
Recovery).

## Writing a worker brief

Use `assets/brief-template.md`. The non-negotiable rules, and why:

1. **Disjoint file ownership.** Name the exact files each agent may touch, and
   explicitly list the off-limits ones (including other agents' files). Why:
   with no inter-pane lock, two agents editing the same file corrupt it. The
   only thing making a parallel run safe is that the file sets don't overlap.
2. **Pre-make every decision.** If a step could go two ways, state which way.
   Why: `pi -p` can't ask. A "use your judgment" brief is a coin flip you
   can't correct until the run is over.
3. **Mandatory self-verification.** End every brief with the exact command(s)
   the agent must run to prove its work (a build, a load test, a `ls -lL` on a
   symlink, a grep for a wired-up import). Why: the reviewer re-runs these, and
   a worker that didn't verify has nothing for the reviewer to confirm — which
   the reviewer will report as a blocking issue.
4. **No commit.** Workers never commit; the orchestrator/you review first.
   Why: the reviewer's whole job is to catch problems before anything is
   committed, and a draft-PR workflow wants the diff staged, not committed.

The orchestrator injects the completion protocol, so the brief itself only
describes the work. Don't put `.done`/`.result` instructions in the brief.

## Running it

The skill bundles `scripts/fanout.sh`. Resolve its path against this skill's
directory (the parent of `SKILL.md`). Make it executable once:

```sh
chmod +x <skill-dir>/scripts/fanout.sh
```

Then, from the repo working tree you want the agents to operate in:

```sh
<skill-dir>/scripts/fanout.sh run -- \
  agentA=/abs/path/briefA.md \
  agentB=/abs/path/briefB.md
```

By default the Devil's Advocate reviewer runs after the workers. Skip it with
`--no-review` (only for trivial, fully-verified work). Raise the cap with
`--timeout 1800` (seconds; default 1200). The script prints the job id, the
tmux window, and the job dir; watch live with `tail -f /tmp/pi-fanout/<jobid>/*.log`.

While workers run you are free to do other things; the script blocks only on
the poll loop. When it returns, read `verdict.json`:

```sh
cat /tmp/pi-fanout/<jobid>/verdict.json
```

If `approved` is `false`, fix the `blocking` items — either yourself, or by
re-running a single worker with a corrected brief (its `.done`/`.result` are
per-role, so one redo doesn't disturb the others' artifacts).

Support commands:

```sh
fanout.sh list                 # active fanout windows
fanout.sh status <jobid>       # per-role done/pending + verdict
fanout.sh logs <jobid> [role]  # tail logs
fanout.sh kill <jobid>         # kill window + remove job dir
```

## The Devil's Advocate reviewer

The reviewer is a `pi -p` agent launched in a new pane after all workers
signal `.done`. Its auto-generated brief embeds every worker's `.result` and
instructs it to:

1. `cd` to the orchestrator's cwd and run `git status`/`git diff` to see what
   *actually* changed — not what workers claimed.
2. Re-run each worker's stated verification (build, load test, grep for wired
   imports). The most common real failure is a "verified" symlink/import that
   was never actually wired up; re-running catches it.
3. Check for cross-worker conflicts (two agents touching the same file,
   dangling references, one agent assuming another's output that didn't land).
4. Write `verdict.json` (`approved`, per-role `issues`/`verified`, `blocking`,
   `nits`) and a prose `reviewer.result`, then `touch reviewer.done`.

This mirrors the **Devil's Advocate** role the project's `AGENTS.md` already
mandates for teams — challenges hypotheses, demands evidence, verifies by
running. It does not fix anything; it only reports. That separation keeps the
reviewer honest (it has no incentive to rubber-stamp its own fixes).

Keep the reviewer on by default. Turning it off should be a conscious choice
for work you've already verified yourself.

## Recovery (when the orchestrator dies mid-run)

Because the window is named `fanout-<jobid>` and state lives in
`/tmp/pi-fanout/<jobid>/`, a killed orchestrator leaves a recoverable trail:

```sh
fanout.sh list                         # find the orphaned window id
fanout.sh status <jobid>               # see which workers finished
fanout.sh logs <jobid> agentA          # see where a worker got stuck
fanout.sh kill <jobid>                 # tear it all down
```

If workers are still running in the orphaned window, you can either let them
finish (then `status` will show `.done` files) or `kill` the window to stop
them. The job dir survives a window kill until you `kill` the job.

## Communication between agents (the honest answer)

There is no live channel. The supported pattern, when genuinely needed, is
**scratch-file handoff under the job dir**: agent A writes
`/tmp/pi-fanout/<jobid>/artifactX`, and a downstream agent B's brief tells it
to read that path *only after* `agentA.done` exists. The orchestrator does not
enforce ordering across agents — if you need B to wait for A, you have two
options, both of which mean you're really running a pipeline, not a fan-out:

1. Run A first (a one-worker `fanout.sh run -- A=...`), then B as a second run
   whose brief points at A's `.result`/artifacts. Sequential, simple.
2. Use one agent with tool calls instead of two panes. Often this is just
   better.

If you find yourself wanting bidirectional or streaming communication, stop —
this skill is the wrong tool. Use `pi --mode rpc`.

## A note on cost

Each worker is a full `pi -p` session with its own context window. Fan-out pays
for parallelism with duplicated context (each agent re-reads overlapping repo
state). It wins when the work is genuinely parallel and each agent's context is
mostly distinct; it loses when agents re-read the same large files. For a task
where three agents would each load the same 2000-line file, a single agent is
usually cheaper and faster.
