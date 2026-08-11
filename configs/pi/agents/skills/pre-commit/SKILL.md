---
name: pre-commit
description: >
  Run before committing to git. Ensures the commit message captures WHY the change was made
  (the motivation, not the mechanics). Infers the why from conversation context and diff when
  possible; asks the user when it's unclear. Then runs the commit.
  Trigger when the user says "commit", "ready to commit", or when about to run git commit.
  Also auto-triggers via PreToolUse hook on git commit commands.
---

# Pre-Commit Workflow

## Step 1: Gather context

```bash
git diff --name-only --cached
git diff --cached
git log --oneline -5
```

Also review the conversation history — what did the user ask for? What problem were they solving?

## Step 2: Determine the WHY

The "why" is the **motivation behind the change** — not what the code does, but why it was changed.

Good whys sound like:
- "Users reported the modal was unresponsive on mobile"
- "Preparing for the auth middleware swap next sprint"
- "Simplify the build so new contributors can onboard faster"

Bad whys (these are just restating WHAT):
- "Update the config file"
- "Refactor the component"
- "Fix the function"

Try to infer the why from these sources, in priority order:
1. **Conversation context** — what the user asked you to do and why. This is your strongest signal.
2. **The diff itself** — sometimes the nature of the change makes the motivation obvious (e.g., a security patch, a performance fix with a comment explaining the bottleneck).
3. **Recent git history** — the surrounding commits may reveal an ongoing initiative.

## Step 3: Confirm or ask

**If the user's original command already has a `-m` message that contains a clear why** — respect it. Don't second-guess a message like `git commit -m "fix auth timeout — users getting logged out after 30s"`. Just run it.

**If you can confidently infer the why from conversation context** — state your understanding in one line and proceed. Example: "Committing: refocused pre-commit hook to capture change motivation instead of architecture docs."

**If the why is unclear or ambiguous** — use **AskUserQuestion** to ask. Be specific, not generic. Reference what you see in the diff to ground the question:

- Good: "I see you changed the retry logic from 3→5 attempts and added a backoff. What prompted this — were there failures in production, or is this preventative?"
- Bad: "What's the motivation behind this change?"

The question should show you've looked at the diff and just need the missing piece — the *why*.

## Step 4: Craft commit message and run the commit

Write a commit message where:
- **First line**: concise summary of WHAT changed (imperative mood, <72 chars)
- **Body** (when the why isn't obvious from the first line): 1-2 sentences capturing the WHY

Use the sentinel to prevent the hook from re-triggering:
```bash
touch /tmp/pi-pre-commit-active && git commit -m "$(cat <<'EOF'
<first line>

<why body>
EOF
)"; rm -f /tmp/pi-pre-commit-active
```
