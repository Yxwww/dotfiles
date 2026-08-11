---
name: pre-push
description: >
  Run after pushing to git. Updates the open PR description to accurately reflect what was pushed.
  Trigger when the user says "push", "ready to push", "update the PR", or after git push completes.
  Also auto-triggers via PostToolUse hook after a successful git push.
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

## Step 3: Fill the PR description

Find the PR template (check `.github/pull_request_template.md`, `.github/PULL_REQUEST_TEMPLATE.md`, `docs/pull_request_template.md`).

Fill every REQUIRED section accurately based on what was pushed. Preserve anything the user already wrote. Remove placeholder HTML comments from filled sections. Leave unfilled OPTIONAL sections with their original placeholders.

```bash
gh pr edit <number> --body "<filled body>"
```

Report the PR URL when done.
