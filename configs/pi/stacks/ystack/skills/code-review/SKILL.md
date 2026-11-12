---
name: code-review
description: "Three-axis code review of the changes since a fixed point: Standards (does the code follow this repo's documented conventions?), Spec (does it implement what was asked?), and optionally Perf (does it cost what it should on the hot path?). Axes run as parallel sub-agents with independent context and are reported separately. Use when reviewing a branch, a PR, or work-in-progress, or when asked to \"review since X\"."
---

Three-axis review of the diff between a fixed point and `HEAD`:

- **Standards** — does the code follow this repo's documented conventions?
- **Spec** — does it implement what the originating issue or task asked for?
- **Perf** — does it cost what it should, on the paths that actually run often?

Each axis runs as a **sub-agent with a fresh context window** so one axis cannot anchor another, and so a Standards pass can't mask a Spec failure. This skill routes and aggregates; it does not review inline.

The order below is the process. Do not skip ahead to findings.

## 1. Pin the fixed point

Take the ref from the user — a SHA, branch, tag, `main`, `HEAD~5`. If they didn't name one, ask; do not guess `main`.

```bash
git rev-parse <fixed-point>                 # fail here, not inside three sub-agents
git diff <fixed-point>...HEAD --stat        # three-dot = merge-base, not the tip
git log <fixed-point>..HEAD --oneline
git diff <fixed-point>...HEAD
```

Empty diff → stop, say so, don't spawn anyone. Before reviewing, size the change:

```
~100 lines    Good — reviewable in one sitting.
~300 lines    Acceptable if it is a single logical change.
~1000 lines   Too large; ask for a split before reviewing.
```

Watch *file* size as well as diff size. A small diff that pushes a file past ~1000 total lines is a decomposition hint, not a nit. Complete file deletions and mechanical refactors are the exception — the reviewer only verifies intent.

## 2. Find the spec and the standards

**Spec source**, in order: issue/ticket references in the commit messages (`#123`, `Closes #45`, `ABC-42`); a path the user passed; a spec under `docs/`, `specs/`, or `.scratch/` matching the branch. If none exists, ask once — then let the Spec axis report "no spec available" rather than inventing requirements.

**Standards source**: every file in the repo that documents how code should be written. `CODING_STANDARDS.md`, `CONTRIBUTING.md`, `AGENTS.md`, `CLAUDE.md`, and any style doc must all be on the list if present.

## 3. Spawn the axes in parallel

Issue all sub-agent calls together, in the foreground, and aggregate what comes back. Paste each axis's material into its brief — a sub-agent has no other access to it.

### Standards

Brief includes the diff command, commit list, the standards files, and [the smell baseline](#the-smell-baseline) pasted in full.

> Report, per file/hunk, (a) every place the diff violates a documented standard — cite the file and rule; (b) any baseline smell — name it and quote the hunk. Documented breaches may be hard violations; baseline smells are always judgement calls. A documented repo standard always overrides the baseline. Skip anything tooling enforces. Under 400 words.

Also ask this axis to **check the tests by experiment, not by reading**: invert one condition the change adds (drop a negation, swap `&&` for `||`), run the suite, restore the file from a copy. A mutation that stays green is a finding — name the missing test case. A green suite that survives a deliberate break is evidence of nothing.

### Spec

Brief includes the diff command, commit list, and the spec text or path.

> Report: (a) requirements the spec asked for that are missing or partial; (b) behaviour in the diff that wasn't asked for (scope creep); (c) requirements that look implemented but where the implementation looks wrong. Quote the spec line for each. Under 400 words.

No spec → skip this axis and say so. Do not manufacture requirements.

### Perf

Perf is **its own pass, not a table of web-backend smells**. Full detail lives in [references/perf-systems.md](references/perf-systems.md) — read it before spawning this axis.

Three rules govern it:

1. **Triage hot vs cold first.** The axis only exists for code on a path that runs per-frame, per-entity, or per-element. Setup, teardown, and one-shot work are cold; simple beats fast there.
2. **All cold → skip the axis and say so.** That is the most common correct answer, not a failure to review.
3. **Every finding names the path** it runs on and carries a measurement status: `measured` | `estimated` | `unverified`. If you cannot name the per-frame path, it is not a finding. Every finding also cites the cost-model rule it invokes — no rule, no finding.

## 4. Aggregate

Report under `## Standards`, `## Spec`, `## Perf` — separate, lightly cleaned, **not merged and not reranked across axes**. Keeping them apart is the point: clean Standards must not bury a Spec failure.

Within each axis, order by leverage. Label every finding:

| Prefix | Meaning | Author action |
|---|---|---|
| **Critical:** | Blocks merge — vulnerability, data loss, broken behaviour | Must fix |
| *(no prefix)* | Required change | Must fix before merge |
| **Optional:** / **Consider:** | Suggestion | Worth weighing |
| **Nit:** | Formatting, style preference | May ignore |
| **FYI** | Context only | No action |

Before reporting, check each finding against callers, guards, and tests that reach the changed code — drop it if they rule it out. Label pre-existing defects separately from regressions this change introduces. **Zero findings is a valid result; do not invent one.**

End with one line per axis: count, and the worst issue *within* that axis.

### Structural remedies

When flagging structure, propose the move, not just the complaint. Reach for a named restructuring: replace a conditional chain with a typed model or dispatcher; collapse duplicate branches; separate orchestration from logic; move feature logic out of a shared module; reuse the canonical helper; make a type boundary explicit; delete a pass-through wrapper. Prefer the remedy that removes moving pieces over one that spreads the same complexity around.

### Dependency discipline

A dependency change is code review. Ask: does the existing stack already solve this, how large is it, is it maintained, any known vulnerabilities, what licence? Prefer the standard library — every dependency is a liability.

For upgrades, separately:

1. **Read the changelog, not the version number.** Semver is a promise maintainers do not always keep.
2. **One dependency per change.** A bulk bump that breaks the build hides which package did it.
3. **Let the tests decide** — green before *and* after. Thin coverage around the dependency is the real finding; add the test first.
4. **Mind the transitive graph.** Review the lockfile diff, not just the manifest.
5. **Keep the lockfile honest.** Commit it, review its diff, never hand-edit it.

### Dead code

After a refactor, list what the change orphaned — unreachable functions, unused constants, superseded components — and **ask before deleting**:

```
DEAD CODE IDENTIFIED:
- formatLegacyDate() in src/utils/date.ts — replaced by formatDate()
→ Safe to remove these?
```

Don't leave it lying around; don't silently delete what you aren't sure about.

## Honesty and disagreement

- **Don't rubber-stamp.** "LGTM" with no evidence of review helps nobody.
- **Don't soften real issues.** "Might be a minor concern" for a production bug is dishonest.
- **Quantify** where you can — "this runs per entity, ~10k times a frame" beats "this could be slow".
- **Push back on approaches with clear problems.** Sycophancy is a review failure mode.
- **Accept override gracefully.** The author may hold context you don't; comment on code, not people.

When resolving a dispute: technical facts override opinion, style guides own style, design is judged on engineering principles, and codebase consistency is acceptable unless it degrades health. **Don't accept "I'll clean it up later"** — require it before submission, or a filed bug with an owner.

## Report

```markdown
## Review: <change> since <fixed-point>

## Standards
<findings, labelled>

## Spec
<findings, labelled — or "no spec available">

## Perf
<findings, or "all changed paths are cold — skipped">

## Checklist
- [ ] Change matches the spec
- [ ] Edge and error paths handled
- [ ] Tests cover the change (mutation-checked, not just green)
- [ ] Names and control flow clear
- [ ] Fits existing patterns; no feature logic in shared modules
- [ ] No secrets, untrusted input validated at boundaries
- [ ] Hot paths allocation-free; cold paths left simple
- [ ] Dependencies reviewed against changelog + lockfile diff
- [ ] Verification story documented

## Verdict
- [ ] **Approve** — ready to merge
- [ ] **Request changes** — required findings must be addressed
```

**Approval standard:** approve when the change definitely improves overall code health, even if imperfect. Don't block for not being written the way you would have written it. Do block for anything Critical, for a Spec mismatch, or for a hot-path regression that is `measured` or `estimated`.

## The smell baseline

Applies even when a repo documents nothing. Two rules bind it: **the repo overrides** — a documented standard always wins where it endorses something flagged here; and **always a judgement call** — each is a labelled heuristic ("possible Feature Envy"), never a hard violation. Skip anything tooling already enforces.

- **Mysterious Name**: a function, variable, or type whose name doesn't reveal what it does or holds. → rename it; if no honest name comes, the design's murky.
- **Duplicated Code**: the same logic shape appears in more than one hunk or file in the change. → extract the shared shape, call it from both.
- **Feature Envy**: a method that reaches into another object's data more than its own. → move the method onto the data it envies.
- **Data Clumps**: the same few fields or params keep travelling together (a type wanting to be born). → bundle them into one type, pass that.
- **Primitive Obsession**: a primitive or string standing in for a domain concept that deserves its own type. → give the concept its own small type.
- **Repeated Switches**: the same `switch`/`if`-cascade on the same type recurs across the change. → replace with polymorphism, or one map both sites share.
- **Shotgun Surgery**: one logical change forces scattered edits across many files in the diff. → gather what changes together into one module.
- **Divergent Change**: one file or module is edited for several unrelated reasons. → split so each module changes for one reason.
- **Speculative Generality**: abstraction, parameters, or hooks added for needs the spec doesn't have. → delete it; inline back until a real need shows.
- **Message Chains**: long `a.b().c().d()` navigation the caller shouldn't depend on. → hide the walk behind one method on the first object.
- **Middle Man**: a class or function that mostly just delegates onward. → cut it, call the real target direct.
- **Refused Bequest**: a subclass or implementer that ignores or overrides most of what it inherits. → drop the inheritance, use composition.

## Rationalizations

| Rationalization | Reality |
|---|---|
| "It works, that's good enough" | Unreadable, insecure, or misdesigned code compounds into debt. |
| "I wrote it, so I know it's correct" | Authors are blind to their own assumptions. |
| "We'll clean it up later" | Later never comes. The review is the gate. |
| "AI-generated code is probably fine" | It needs more scrutiny, not less — confident and plausible even when wrong. |
| "The tests pass, so it's good" | Necessary, not sufficient. A mutation that stays green proves little. |
| "The refactor makes it cleaner" | Relocating complexity isn't reducing it. Prefer the version where branches disappear. |
| "It's only a small addition" | Small diffs still grow big files and bolt branches onto unrelated flows. |
| "It's just a version bump" | A bump is behaviour you didn't write. Read the changelog. |
| "It can't be slow, it's not a loop" | Cost lives on the path, not in the syntax. Check what runs per frame. |
| "Optimize it anyway" | A perf finding with no hot path and no measurement is noise. |

## See also

- [references/perf-systems.md](references/perf-systems.md) — the systems/perf axis in full: hot/cold triage, memory, data layout, CPU, GPU, IO.
