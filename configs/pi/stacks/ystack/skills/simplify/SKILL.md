---
name: simplify
description: "Cleanup-only review of recently changed code along four axes: reuse, simplification, efficiency, and altitude. Finds duplication of existing helpers, dead abstraction, wasted work, and code written at the wrong level. Applies the fixes to the working tree. Use when the user says simplify, clean up, tidy, reduce duplication, or wants a diff de-complicated after it works. Not a bug hunt — use code-review for correctness."
---

Cleanup review of the diff between the working tree and a fixed point. Four axes:

- **Reuse** — does this re-implement something the repo already has?
- **Simplification** — is there a simpler formulation that does the same thing?
- **Efficiency** — does it do work it doesn't need to do?
- **Altitude** — is each piece written at the right level of abstraction?

The premise: **the code already works.** You are not hunting bugs. If you find a correctness bug, note it under `Out of scope` and move on — `code-review` owns that. Never let a "while I'm here" fix become a behavior change.

## Process

### 1. Pin the diff

Whatever the user named is the fixed point. If they named nothing, default to the working tree against `HEAD` plus any staged changes:

```sh
git rev-parse <fixed-point>            # confirm the ref resolves
git diff <fixed-point>...HEAD --stat   # three-dot: compare against merge-base
git diff HEAD                          # uncommitted work
git status --short
```

State the resolved ref and the file count in one line before proceeding. An unresolvable ref or an empty diff stops here — don't burn an axis sweep on nothing.

If the diff exceeds ~800 changed lines, ask whether to narrow to specific paths. Four axes over a huge diff degrades into generic advice.

### 2. Read the surrounding code, not just the hunks

The Reuse axis is unanswerable from the diff alone. Before flagging anything as duplication you must know what the repo already provides:

```sh
rg -n "<the helper being re-implemented>" --type <lang>
```

Read the callers of every function the diff touches. A change that looks redundant in isolation is often deliberate — a hot path inlined to avoid a call, a cache added because a caller is per-frame.

### 3. Sweep the four axes

Run these as read-only passes. Report findings; do not edit yet.

**Reuse**

- A new function whose body already exists under another name.
- A hand-rolled loop over a collection the language/stdlib/repo helper already covers.
- A second copy of a constant, regex, schema, or type that has a single source of truth elsewhere.
- New dependency imported for something already vendored.

Ignore apparent reuse where the two implementations are deliberately decoupled (e.g. two services that must not share a deploy boundary). Say so when you skip it.

**Simplification**

- Nesting that early-return removes.
- A conditional whose branches are identical.
- An intermediate variable used once, or a variable that only renames its input.
- Boolean gymnastics: `!(a && !b)`, double negation, a `flag ? true : false`.
- Comments restating the next line. Per this repo: comment the *why*, never the *what*.
- Nested ternaries → `switch` or an if/else chain.

**Efficiency**

Grade against the cost model in `AGENTS.md`. Cite the hot-path rule you're invoking.

- Allocation in a per-frame / per-entity / per-element path: spread, closures created in loops, intermediate arrays, `.map().filter().reduce()` chains.
- Recomputing an invariant inside a loop that could be hoisted.
- Missing dirty flag — updating a GPU buffer or uniform every frame when nothing changed.
- Per-element object churn where a flat typed array or struct-of-arrays is the established pattern.
- An O(n²) pass over something that has an O(n) index available.

Do **not** flag cost in cold paths — setup/teardown is allowed to be simple over fast. Explicitly skip it and say why.

Also reject micro-optimizations that trade real clarity for unmeasurable gain. If you can't name the per-frame path it runs on, it isn't an efficiency finding.

**Altitude**

- A function doing work two levels above or below its name.
- Business logic in a presentation layer, or rendering concerns in a data layer.
- A helper that serves exactly one caller and adds nothing but a name — inline it.
- Configuration or constants buried inside a function instead of at the level that owns them.
- Test scaffolding leaking into production code.

### 4. Triage

For each finding record: axis, `file:line`, the concrete problem, the concrete fix, and the behavior-preservation argument. Drop anything you cannot state a fix for.

Order: Efficiency in hot paths first, then Reuse, then Altitude, then Simplification — matching the harm of getting it wrong.

Present the list and **stop**. Do not start editing until the user picks. If they said "just do it", enumerate first, then apply in one pass — the enumeration is the audit trail, not a checkpoint.

### 5. Apply

Edit directly. One finding, one edit. Then:

```sh
git diff <fixed-point>
```

Re-read the full resulting diff. You are looking for two things:

- **Behavior drift you introduced.** Any change to a branch condition, evaluation order, or side effect counts. Revert it.
- **A net increase in lines** where the finding was simplification. That usually means you replaced a local idiom with a generic one. Revert and report it as not-worth-fixing.

### 6. Verify

Run whatever gate the repo has — `npm test`, `task lint`, `cargo test`. If the diff touched a live path, confirm it still runs.

Cleanup that breaks tests is not cleanup. If a test fails, you changed behavior; revert to the last good state and report which finding caused it.

### 7. Report

```
Simplified <ref>..worktree — <n> files, <m> findings applied, <k> skipped

Efficiency
  path/file.ts:142  hoisted `projection` out of the per-entity loop
Reuse
  path/other.ts:31  replaced hand-rolled clamp with `clamp` from path/util.ts
Skipped
  path/third.ts:88  looks duplicated but the two callers must not share a
                    deploy boundary — left as-is
Out of scope
  path/file.ts:200  off-by-one in the pagination bound (correctness — code-review)
```

`Skipped` is not filler. It records that you considered something and declined, which stops the next reviewer re-litigating it.

## Rules

- **Preserve behavior.** No output, ordering, or side-effect changes. Not even "obviously equivalent" ones.
- **The diff is the scope.** Never simplify code the user didn't touch unless asked.
- **`AGENTS.md` beats your taste.** Hot-path allocation rules, in-place mutation, and plain data objects outrank conventional style advice. Not every repo is a hot-path repo — read `AGENTS.md` before invoking its rules, and don't apply them to a CRUD handler.
- **Repo convention beats external best practice.** If the repo does it one way consistently, that way wins even if it reads oddly.
- **Declining is a valid result.** If the diff is already clean, say so. Don't manufacture findings to look useful.
- **No drive-by edits.** Unrelated typo, stale comment, or nearby refactor outside the diff → report it, don't touch it.
