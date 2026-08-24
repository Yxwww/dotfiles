---
name: pr-catchup
description: >-
  Get up to speed on a pull request you're resuming work on — reads the PR, its
  diff and the surrounding code it touches (opening changed files and their
  callers to understand context, not just the hunks), the linked Jira ticket,
  any matching memory notes, local branch hygiene
  (uncommitted/unpushed/behind-base/stashes), and CI/review/merge state, then
  returns a tight status brief. Invoke-only: run this ONLY when the user
  explicitly invokes it as /pr-catchup. Do NOT auto-trigger on phrasing cues
  like "catch me up on this PR" or "read the PR and code changes" — wait for the
  explicit /pr-catchup invocation.
---

# PR Catch-up

You're reloading context on a PR the user is resuming. The goal is a fast,
accurate picture of **what the change does** and **where it stands** — not a
line-by-line diff recital. The user has done this dozens of times manually;
they want the situational summary they'd build in their head, delivered in
seconds.

## What "make sense of what's happening" means here

Cast the full net, then synthesize. The numbered order is **coverage and
synthesis priority**, not strict execution order — batch independent fetches
in one tool block, and keep the two serial bits (the code-reading walk in
step 2, and the final brief) serial. Each step degrades gracefully — if a
source is missing, note it in one clause and move on. Never block the whole
brief waiting on one flaky source.

1. **Resolve the PR.** Default to the current branch: `gh pr view --json
   number,title,body,state,isDraft,url,headRefName,baseRefName,mergeable,mergeStateStatus,additions,deletions,changedFiles`.
   If there's no PR for the branch, say so and ask for a number/URL — don't
   guess or fabricate one.

Once the PR resolves, fan out the independent fetches in one tool block: `gh pr
diff` (step 2's fetch), `jira_get_issue` (step 3), and `gh pr checks` (step 6).
Step 4's memory scan is already in context — zero cost. The serial parts are
step 2's code-reading walk and the final brief.

2. **Read the change.** `gh pr diff` for the actual diff. Skim for the *shape*
   of the change (which files/areas, what kind of edit) — you're building a
   mental model, not reviewing. Read the PR body: it often already states the
   intent and includes example code.

   Then **read the code, not just the delta** — a diff shows changed lines, not
   the context that makes them make sense. Where a hunk isn't self-explanatory,
   open the changed file around the edit (the diff gives you line anchors) to
   see the surrounding function/module, and follow outward when the change's
   purpose is still unclear: who calls the modified function, what type or
   invariant it touches, the sibling code it mirrors. The bar is being able to
   explain *why* the change is shaped this way, not just restate the hunks. This
   is conditional depth — a small, obvious diff (a dependency swap, a one-line
   guard) needs none of it; a subtle logic or architecture change needs you to
   read the neighborhood. Spend the reading budget where the change is load-bearing.

3. **Pull the ticket, if any.** Extract a Jira id (`SDKS-\d+` or similar) from
   the branch name, PR title, or body. If found, fetch it
   with the built-in `jira_get_issue` tool for the acceptance criteria and any
   status/comments. **Many PRs have no
   ticket** (the user's default is no-ticket); if none is present, skip this
   silently — do not invent an id or file one.

4. **Recall what you already know.** Relevant `project_*` / `feedback_*` memory
   notes for this branch are usually **already in your context** via recall
   system-reminders — scan those first (zero tool calls) for a note tied to this
   branch, ticket, or feature. Fold in what's load-bearing (prior decisions,
   gotchas, where a fix landed). Only if nothing relevant surfaced and the PR
   clearly maps to ongoing work, grep the memory index
   (pi has no built-in memory dir; grep your agent's memory index if it keeps
   one, otherwise skip) for matching terms. Treat memory as *what was true when written* — verify a
   named file/flag still exists before leaning on it.

5. **Check the local working tree.** This only needs the branch name, so
   it's independent of step 1 — batch it in the same tool block. When resuming
   a branch, local state is often the first thing that matters — you may have left work uncommitted.
   `git status --short --branch` (uncommitted changes + ahead/behind base),
   `git log --oneline @{u}..` (unpushed commits, if an upstream is set), and —
   scoped to this branch — `git stash list | grep "on $(git branch --show-current):"`.
   The stash stack is **global, not per-branch** (it can hold 100+ entries from
   every branch you've touched); filtering to the current branch is the only way
   the count means anything — never dump the whole list. Call out drift the user would want to
   know before doing anything: dirty tree, unpushed commits, branch behind its
   base (rebase/merge pending), or stashes parked on this branch.

6. **Check where it stands remotely.** `gh pr checks` for CI, and read the review state
   / mergeability from the JSON in step 1. The user's repo has known gates
   worth calling out explicitly when relevant: the `master` ruleset needs a
   human **code-owner** (`@MappedIn/dev`) review — cursor approval alone leaves
   it BLOCKED; post-approval pushes dismiss approvals; the PR-title linter
   (commitlint) needs a lowercase subject ≤100 chars and only re-runs on push.

## Output: tight status brief

Lead with the answer. Use short, scannable sections — dense, no preamble. Adapt
the headers to what's actually notable; omit a section rather than pad it.

```
**<PR title>** · #<num> · <draft|ready> · <branch> → <base>

**What it does** — 1–3 sentences: the intent and approach. Pull from the ticket
/ body / your memory notes, not just the diff.

**Key changes**
- <area/file>: <what changed and why it matters>
- … (group by area; skip trivial/mechanical files)

**Where it stands** — Local (<clean|N uncommitted, M unpushed, behind base,
stash parked>), CI (<pass/fail/pending>), review (<state; name the code-owner
gate if blocking>), mergeable (<yes/conflicts/blocked>). Note the last commit's
intent if it clarifies what's in flight. Lead with local drift — it's what the
user acts on first.

**Open questions / next** — anything unresolved: unaddressed review comments,
failing checks, a half-finished thread from your memory notes. Omit if clean.
```

Keep the whole thing skimmable in ~20 seconds. If something in the diff
contradicts the ticket or the PR body, surface that — a drifted description is
exactly the kind of thing the user resumes work needing to know.
