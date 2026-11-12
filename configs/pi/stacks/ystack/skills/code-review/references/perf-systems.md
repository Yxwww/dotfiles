---
name: perf-systems
description: >
  Deep systems-performance review pass for a diff. Grades memory, data layout, CPU, GPU and
  IO/sync cost against the hot-path cost model in AGENTS.md, one axis per parallel sub-agent.
  Gates on a hot/cold triage first, so cold-path setup code gets no findings. Every finding
  must name the per-frame path it runs on and state whether its cost is measured, estimated
  or unverified. Use when a change touches per-frame, per-entity or per-element code, or when
  the user asks for a perf review, a systems review, or a low-level pass on a branch or PR.
---

# Systems Performance Review

Five axes over the diff between `HEAD` and a fixed point. Each axis runs as a parallel
sub-agent with a fresh context, so one axis's findings cannot anchor another's.

The cost model is **`AGENTS.md`** (Hot path vs. cold path, Memory, CPU, GPU). It is the
authority. Where this file and `AGENTS.md` disagree, `AGENTS.md` wins; where the repo's own
`STYLE.md`/`PERFORMANCE.md` documents a rule, the repo wins over this file.

## The evidence model — read before writing any finding

A finding without all three parts is not a finding. Drop it.

| Part | Meaning |
|---|---|
| **Hot-path claim** | Name the per-frame / per-entity / per-element path this code runs on. A caller, a loop, a callback, a tick. "It's called a lot" is not a path. |
| **Measurement status** | `measured` (profiler, counter, benchmark), `estimated` (countable from the code: N allocs/frame, K draw calls), or `unverified` (a hypothesis — say what would confirm it). |
| **Rule invoked** | Cite the section, e.g. `AGENTS.md > Memory: no allocations in hot paths`. No rule, no finding. |

Prefer **directional and countable** over timing: allocations per frame, draw calls added,
bytes copied, indirections per element. Countable claims survive refactoring; guessed
microseconds do not. **Never invent benchmark numbers.** If you did not run it, say
`estimated` or `unverified`.

## Process

### Step 0 — Triage: hot or cold

**This step gates everything. Do not skip to an axis.**

Read the diff and classify each changed hunk:

- **Hot** — reachable from a frame loop, tick, render pass, event handler, per-element
  iteration, or a job-system worker.
- **Cold** — module init, setup/teardown, build/config, one-shot CLI, migration, test.
- **Unknown** — no call path found from a known loop. Trace callers before judging.

Then:

- **All cold → stop.** Report `all changed paths are cold — skipped` and the one line of
  evidence (which entry points you checked). Manufactured cold-path findings are the main
  reason perf reviewers get ignored.
- **All hot → continue**, carrying the named paths forward. Each axis sub-agent gets the
  list, not the diff alone.
- **Mixed → continue**, and every finding must state which path it sits on. A hot change
  buried in a cold diff is still hot.

```text
onFrame(dt)
  updateEntities()        <- changed: per-entity, HOT
  syncBuffers()           <- changed: per-frame, HOT
  buildAtlas()            <- changed, called once at init, COLD — skip
```

Cold code may be written simply rather than fast. Say so explicitly when you skip it, so
the skip is on record rather than looking like an oversight.

**One rule keeps this skill usable: no hot path, no finding.**

### Step 1 — Spawn one sub-agent per axis

Issue all axis calls together, in the foreground, and aggregate the reports verbatim. Each
brief carries: the diff command and commit list, the hot-path list from Step 0, the evidence
model above, and its own checklist below **pasted in full** — the sub-agent has no other
access to this file. Each returns findings only, no fixes and no files edited.

**1. Memory**

- Allocation in a per-frame / per-entity / per-element path: spread, closures created in
  loops, intermediate arrays, `.map().filter().reduce()` chains, string concatenation.
- Object or buffer churn where the code has a preallocation/pool pattern available.
- GC pressure: short-lived objects in a loop that could be reused across frames.
- Ownership discipline: freed what it owns, no reference outliving its use, no leak on the
  error path, no double free, no dangling handle after a resize/destroy.
- Resizes that drop a buffer instead of growing it.
- Brief: "Report allocation and ownership findings. For each: `file:line`, the hot path it
  runs on, allocation count per frame/entity/element if countable, the fix, and the
  `AGENTS.md` rule. Under 300 words."

**2. Layout**

- Array-of-structs where the repo's established pattern is struct-of-arrays or a flat typed
  array — especially when the loop touches one field across all elements.
- Pointer or object-graph chasing where an index into a flat array would do.
- Struct size and padding: hot structs reordered so frequently-read fields share a cache
  line; false sharing across job-system workers writing adjacent fields.
- Access order vs memory order: iterating columns over row-major data, or vice versa.
- Indirection added in a hot loop: a getter, proxy, or wrapper between the loop and the data.
- Brief: "Report data-layout findings. Name the loop and the element count that makes the
  layout matter; if the collection is small or cold, do not report. Under 300 words."

**3. CPU**

- Branch predictability: data-dependent branches in a hot loop, a branch that could be a
  branchless select, an unpredictable early-out added inside the inner loop.
- Invariant work inside a loop that could be hoisted — including property lookups, bounds
  recomputation, and repeated function results.
- Devirtualization: a megamorphic call site or interface dispatch in an inner loop where the
  call could be hoisted out or the type narrowed.
- Loop shape: bounds checks recomputed per iteration; division or modulo by a loop-invariant
  where a multiply or a precomputed reciprocal would do.
- Redundant recomputation across call sites that a cached result would cover.
- Brief: "Report CPU findings. For a branch claim, state whether the branch data is
  predictable and why. Prefer countable cost (ops per element) over timing. Under 300 words."

**4. GPU**

- Draw calls: a new draw call where the geometry could be batched or instanced; a per-entity
  draw in a loop.
- Resource reuse: materials, textures, programs, and buffers recreated instead of reused;
  a shader recompiled per frame.
- Per-frame churn: uniform or buffer uploads every frame when nothing changed; a missing
  dirty flag on an update path; full re-upload when a sub-range changed.
- Overdraw and fill: translucent or oversized quads stacked; a full-screen pass added.
- Sync points: readbacks, `map`/`unmap` stalls, `glFinish`, `await` on GPU work mid-frame.
- Brief: "Report GPU findings. Name the pass and the per-frame count (draw calls added,
  bytes uploaded per frame). A resource created once at init is cold — skip it. Under 300
  words."

**5. IO / Sync**

- A syscall, `stat`, file open, or network round-trip inside a per-element loop where one
  batched call covers it.
- Locks held in a hot path, or a lock acquired per element where the whole batch could take
  it once.
- Allocation under a lock, and lock ordering that inverts.
- Unbatched writes: N small writes that one buffered write covers.
- Brief: "Report IO and synchronization findings. State the per-frame call count and what
  batching would reduce it to. Under 300 words."

### Step 2 — Aggregate

Present each axis under its own heading (`## Memory`, `## Layout`, `## CPU`, `## GPU`,
`## IO/Sync`), killed findings included, with a one-line reason. Do not rerank across axes —
a layout problem cannot mask a GPU one if they are reported apart.

Within an axis, order by the harm of getting it wrong, then by measurement status:
`measured` before `estimated` before `unverified`.

### Step 3 — The verdict

```text
Perf: 2 findings — 2 hot-path, 1 cold-path skipped
Hot paths
  onFrame -> updateEntities   per-entity | onFrame -> syncBuffers   per-frame
Worst
  Memory  render/batch.ts:88  +1 array per entity per frame, estimated
Unverified
  Layout  scene/nodes.ts:41   AoS defeats SoA pattern — needs a profile
Skipped (cold)
  render/atlas.ts:12          init-only; simplicity wins
```

End with the one number a reader cares about: what this diff adds per frame, or `net zero`.

## Not this skill

Web-backend and UI-framework concerns live elsewhere — do not look for them here, and do not
report them under these axes:

- N+1 queries, missing pagination, unbounded data fetches
- Unnecessary UI re-renders, memoization of props, bundle size
- Caching strategy, HTTP/CDN behavior, connection pooling
- Async-vs-sync at the request level

Correctness bugs found while tracing a hot path are out of scope for this pass — note them
under `Out of scope` and hand them to `code-review`. A perf review that reports a null deref
has stopped being a perf review.

## Rules

- **Never flag cold-path cost.** Init, setup, teardown, and migrations may be clear over fast.
- **Reject clarity-for-nothing trades.** If the gain is unmeasurable and the code gets
  harder, report it as `considered and declined`, not as a finding.
- **The repo's cost model beats yours.** Read `AGENTS.md` first; a CRUD handler is not a frame loop.
- **No invented measurements.** `unverified` is honest; a fabricated millisecond figure is not.
- **Declining is a valid result.** A clean diff gets `no findings` plus the paths checked.
