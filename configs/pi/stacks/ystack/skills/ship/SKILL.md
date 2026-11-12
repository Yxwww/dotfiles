---
name: ship
description: >
  Ship one change: simplify the diff, review it and fix what's real, then commit and
  push. Each review round is a fresh subagent that both reviews and fixes, so the flow
  never reviews its own work. Bounded at 3 rounds; commits only when nothing Critical
  remains. Composes the simplify, pre-commit and pre-push skills instead of duplicating
  them. Trigger on "ship it", "review and push", "review, fix and commit".
---

# Ship

Simplify, review, fix, commit, push — one change, one pass.

Ystack is usable on its own and by any caller that wants a reviewed, pushed change.

## Before you start

```bash
git status --short     # nothing dirty and nothing staged -> stop, nothing to ship
git diff --stat
```

- **On the default branch** → stop and ask. Offer the default (a new branch here with
  `git switch -c`) and a worktree as the alternative. Do not create a branch or a worktree
  until the user picks.
- **No PR is fine.** Push; skip the body sync. Never create a PR — that is the caller's call.

Run the whole pass under a sentinel, and clear it even on early exit:

```bash
touch /tmp/pi-ship-active
# ... work ...
rm -f /tmp/pi-ship-active
```

While it exists, `git-workflow-gates.ts` skips the post-push PR-body nudge, because Step 4
runs that sync deliberately. A stale sentinel silently disables the nudge for later
sessions.

## Step 1 — Simplify

Run the **simplify** skill on the diff. It applies cleanup to the working tree: reuse,
simplification, efficiency, altitude.

- If it reports a correctness bug, **do not fix it** — Step 2 owns correctness.
- Re-run the repo's verification after it edits. A simplify pass that breaks the build
  isn't one.

## Step 2 — Review and fix

Up to **3 rounds**. Each round is **one fresh subagent** that reviews *and* fixes. The
parent routes and commits; it never edits code in this loop — a parent fixing its own
review findings is self-review, which is what this skill exists to avoid.

Fresh, not forked: a fork inherits the reasoning that produced the code and defends it.

Brief for round N:

```
Review this diff against the code-review skill's rubric (correctness, readability,
architecture, security, performance). Label findings Critical / Required / Optional / Nit.
Critical = security hole, data loss, or broken functionality. Drop anything the current
callers, guards or tests already rule out, and verify by executing code where you can.

Then fix every Critical and Required finding. Do not fix Optional/Nit — list them.
Keep fixes local; if a Required finding means "restructure this module", report it as
blocking instead. Re-run the repo's verification and confirm it passes.

Report: what you fixed, what remains by severity, whether verification passes, and
anything blocking.

Out of scope: bugs that predate this diff. Report them under "pre-existing".

Diff: git diff <base>...
```

**After each round:**

| Round reports | Do |
|---|---|
| Nothing Critical/Required, verification passes | → Step 3 |
| Fixed its findings, verification passes | next round (re-review the fixes) |
| A blocking or structural finding | → Step 4 |
| Verification failing | → Step 4 |
| Same finding two rounds running | → Step 4 (the fix isn't sticking) |

After 3 rounds, → Step 4 with what's outstanding.

`/ship` is one-shot: review against the branch base, not the last commit.

## Step 3 — Commit

Delegate to the **pre-commit** skill: infer the *why* from the conversation and diff, ask
only if genuinely unclear, and commit through its sentinel.

```bash
touch /tmp/pi-pre-commit-active && git commit -m "$(cat <<'EOF'
<first line>

<why body>
EOF
)"; rm -f /tmp/pi-pre-commit-active
```

If the caller specified a title format (e.g. a conventional-commit ticket prefix
like `feat(ABC-1234): …`), that wins — put the prefix on the first line and the *why*
in the body.

Stage what the run touched. **Never** stage secrets (`.env`, credentials, `*.pem`,
`*.key`). If one is dirty, leave it and say so.

One commit. If the fixes were substantial and separable, two commits (fixes separate) is
fine — say which you did.

## Step 4 — Push and sync the PR body

```bash
git push        # add -u origin HEAD on a branch with no upstream
```

Then follow the **pre-push** skill to bring the open PR description up to date. Skip if
there is no PR.

## If it stops

Report and don't commit when:

- a Critical finding survives the loop
- the only fix is a structural/design change
- verification is failing and the cause isn't obvious

```
SHIPPED: no
Round:   N/3
Blocking: <finding> — <why it needs a decision>
Also open: <Optional/Nits, pre-existing issues>
Next: <the decision you need>
```

Then clear the sentinel and stop.

## Report when it ships

```
SHIPPED: <branch> -> <remote>  (<sha>)
Simplify: <what was cleaned, or "nothing">
Rounds:  <N>/3, <n> fixed, <n> declined
Fixed:   - <one line each>
Open:    - <Optional/Nit left alone>
Next:    request independent review
```

Under 10 lines.

## Rules

- The parent never edits code inside the review loop.
- Optional/Nit never blocks. Report it, don't fix it.
- Never expand scope into pre-existing bugs.
- Never `--force` push, `--no-verify`, or amend a pushed commit.
- Never create a PR.
- Always clear both sentinels.
- These rounds catch nits, not blind spots. A green `/ship` is not approval.
