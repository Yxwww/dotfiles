## Programming Style

Write like a low-level systems or game-engine programmer: treat memory, CPU, and GPU as scarce
and push efficiency to the limit. Linux kernel and game-engine conventions are the reference point.

**Hot path vs. cold path** — Spend the complexity budget where it runs often. Per-frame,
per-entity, and per-element code is the hot path: make it allocation-free and branch-lean even
at the cost of readability. One-time setup/teardown is the cold path: keep it simple and clear.
When a trick hurts readability, justify it with the hot path or don't do it.

Structure:

- Prefer plain data objects over class instances
- Prefer parameterized functions over class methods
- Prefer pure functions
  - Inside pure functions: mutate in place rather than creating new objects
  - At function boundaries: clone objects going in and out to prevent shared mutation

Memory:

- No allocations in hot paths — preallocate, reuse buffers, pool objects
- Prefer flat typed arrays and struct-of-arrays over array-of-objects for cache locality
- Avoid spread, closures, and intermediate arrays in loops — they allocate and pressure GC
- Free what you own; never hold references that outlive their use

CPU:

- Prefer `for` loops over `.map().filter().reduce()` chains in hot code
- Use early returns; keep branches predictable
- Hoist invariant work out of loops; cache results of repeated computation
- Batch work to amortize per-call overhead

GPU:

- Minimize draw calls — batch and instance geometry
- Reuse materials, textures, and GPU buffers; never recreate per frame
- Update only what changed (dirty flags); avoid per-frame uniform/buffer churn

## Code Comments

- Comment the "why", not the "what" — the code already shows what it does.
- Be very concise with code comments.

## Testing

- Don't write test for what type system already guarantees
- When writing tests:
  - Be concise — combine related cases in one test when they share the same logic
  - Assert outputs directly — never use conditional logic to force tests to pass

## Teams

- IMPORTANT: **Every team** must include a **Devil's Advocate** role:
  - Challenges all hypotheses and decisions from other agents
  - Demands evidence before signing off — no assumptions pass unchecked
  - Verifies by running tests locally when possible
  - When reproduction is hard in Node (e.g. visual/interaction bugs), uses the browser to verify
  - Only approves when proof is solid

## Debugging

- IMPORTANT: When asked to debug, **always spawn a team**:
  - **Investigator** — reproduces the bug, forms hypotheses, proposes fixes
  - **Devil's Advocate** — (see Teams section above)
- **Reproduce first** — prove the bug with observable output before reading code or proposing fixes. If reproduction is blocked, ask for help — don't guess.

## General Workflows

- Always open PRs as Draft.
- During planning, when a step involves verifying with `agent-browser`, add it as a task in the task list — do not skip or omit verification steps.

## Browser Automation

Use `agent-browser` for web automation. Run `agent-browser --help` for all commands.

Core workflow:

1. `agent-browser open <url>` - Navigate to page
2. `agent-browser snapshot -i` - Get interactive elements with refs (@e1, @e2)
3. `agent-browser click @e1` / `fill @e2 "text"` - Interact using refs
4. Re-snapshot after page changes

- WebGL fails in headless mode (SwiftShader can't create context). Always use `--headed` for WebGL pages.

