---
name: pre-push
description: >
  Run after pushing to git. Updates the open PR description to accurately reflect what was pushed.
  Trigger when the user says "push", "ready to push", "update the PR", or after git push completes.
  Also auto-triggers via the git-workflow-gates extension's tool_result nudge after a successful git push.
---

# Post-Push: Update PR Description

## Step 1: Check for an open PR

```bash
gh pr view --json number,url,body,title 2>/dev/null
```

If no PR exists, stop here.

## Step 2: Understand what was pushed

```bash
git log origin/master..HEAD --oneline
git diff origin/master...HEAD --stat
```

## Step 3: Write the PR description to follow the template

Read the repo's PR template (check `.github/pull_request_template.md`, `.github/PULL_REQUEST_TEMPLATE.md`, `docs/pull_request_template.md`, `pull_request_template.md`).

The body must **follow the template's structure** — keep every section heading, in template order. How you get there depends on the current body:

- **Body already follows the template** — update only the sections whose content changed; leave the rest untouched.
- **Body is empty or still has placeholder HTML comments** — fill every REQUIRED section from the diff/commits.
- **Body is free-form / doesn't match the template** (common for AI-generated descriptions) — **restructure it**: fold the existing prose into the matching template sections, drop prose that has no home, and add any REQUIRED section that's missing. Do not preserve a non-template layout just because it was there first.

Style:
- Concise — bullets over prose. Lead with the change, not the background.
- Checkbox impact sections (Breaking API, CSP, Analytics, Wrappers, Security, Privacy, DevOps): check `[x] Yes` only when the answer is genuinely yes; otherwise leave `[ ] Yes` unchecked with a one-line reason on the next line.
- Remove placeholder HTML comments (`<!-- ... -->`) from sections you filled. Leave them in unfilled OPTIONAL sections.
- Preserve content the user hand-wrote — relocate it into the right section rather than rewriting it.

Write the body to a temp file and use `--body-file` (robust for multi-line bodies, backticks, and code fences — `--body` breaks on those):

```bash
gh pr edit <number> --body-file /tmp/pr-<number>-body.md
```

Report the PR URL when done.
