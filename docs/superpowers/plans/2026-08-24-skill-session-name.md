# Skill Session Name Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** When the user invokes `/skill:<name>` in an unnamed pi session, automatically set the session display name to `<name>` so `/resume` (and `pi -r`) shows `pr-catchup` instead of the expanded `<skill name="…" location="…">…` first-message blob.

**Architecture:** A new pi extension in `configs/pi/agent/extensions/`, same shape as `prompt-stash.ts`: extract a pure function, unit-test it with `node --test`, then wire a thin `pi.on("input")` handler. The `input` event fires **before** skill/template expansion (`agent-session.js` emits `input`, then `_expandSkillCommand`). On `/skill:<name>`, if `pi.getSessionName()` is unset, call `pi.setSessionName(name)`. The picker already prefers `session.name ?? session.firstMessage`, so naming is the only lever we have without forking pi.

**Tech Stack:** TypeScript pi extension (`ExtensionAPI` from `@earendil-works/pi-coding-agent`), `node:test` + `node:assert` (same as `prompt-stash.test.ts`), `node --import tsx`.

**Spec:** This plan is the spec. Approved approach is Option A from the brainstorm: name-on-skill-invoke, do not fight a later `/name`, do not inject skill content.

## Global Constraints

- Do not edit `~/.pi/agent/` copies — they are symlinks. Edit `configs/pi/agent/extensions/` and `linkdotfiles.sh` only.
- Do not change `prompt-stash.ts`, `git-workflow-gates.ts`, or other extensions.
- Do not commit unrelated dirty files (`configs/pi/agent/models.json`, `configs/pi/agent/settings.json`, `configs/pi/agents/skills/pr-catchup/SKILL.md`).
- Do not override an existing session name (user `/name` wins).
- Match pi's own skill-command parse: `text.startsWith("/skill:")`, name is the token after the colon up to the first space. Do **not** trim leading whitespace (pi does not).
- Empty skill name (`/skill:` or `/skill: `) is a no-op.
- Unknown skill names still get named (pi passes unknown `/skill:` through unchanged; a short name is still better than the raw command).
- Tests stay allocation-light and assertion-direct. No mocks of `ExtensionAPI` unless a later task truly needs the handler wired; the pure function is the contract.
- Run tests with: `node --import tsx configs/pi/agent/extensions/skill-session-name.test.ts` from the repo root.

---

### Task 1: Pure naming function + tests (TDD)

**Files:**
- Create: `configs/pi/agent/extensions/skill-session-name.ts`
- Create: `configs/pi/agent/extensions/skill-session-name.test.ts`

**Interfaces:**
- Consumes: nothing
- Produces:
  ```ts
  export interface NameFromSkillResult {
    nextName: string | undefined;
    named: boolean;
  }

  export function nameFromSkillCommand(
    text: string,
    currentName: string | undefined,
  ): NameFromSkillResult
  ```
  `named === true` means the caller should `setSessionName(nextName)`. `named === false` means leave the session name alone (`nextName` is `undefined`).

- [ ] **Step 1: Write the failing tests** (do not create the implementation file yet; if TypeScript import fails, create `skill-session-name.ts` with **only** the exported types and an unimplemented function that throws, so the test file can import it)

Write `configs/pi/agent/extensions/skill-session-name.test.ts`:

```ts
/**
 * Tests for skill-session-name pure logic.
 * Run: node --import tsx configs/pi/agent/extensions/skill-session-name.test.ts
 */
import test from "node:test";
import assert from "node:assert";

import { nameFromSkillCommand } from "./skill-session-name.ts";

test("names an unnamed session from /skill:pr-catchup", () => {
  assert.deepStrictEqual(nameFromSkillCommand("/skill:pr-catchup", undefined), {
    nextName: "pr-catchup",
    named: true,
  });
});

test("strips args after the skill name", () => {
  assert.deepStrictEqual(
    nameFromSkillCommand("/skill:pr-catchup --force", undefined),
    { nextName: "pr-catchup", named: true },
  );
});

test("does not override an existing session name", () => {
  assert.deepStrictEqual(
    nameFromSkillCommand("/skill:pr-catchup", "Refactor auth"),
    { nextName: undefined, named: false },
  );
});

test("treats whitespace-only current name as unnamed", () => {
  assert.deepStrictEqual(nameFromSkillCommand("/skill:pr-catchup", "   "), {
    nextName: "pr-catchup",
    named: true,
  });
});

test("ignores non-skill input", () => {
  assert.deepStrictEqual(nameFromSkillCommand("hello", undefined), {
    nextName: undefined,
    named: false,
  });
});

test("ignores a leading-whitespace skill command (pi does not trim)", () => {
  assert.deepStrictEqual(nameFromSkillCommand(" /skill:pr-catchup", undefined), {
    nextName: undefined,
    named: false,
  });
});

test("ignores empty skill name", () => {
  assert.deepStrictEqual(nameFromSkillCommand("/skill:", undefined), {
    nextName: undefined,
    named: false,
  });
  assert.deepStrictEqual(nameFromSkillCommand("/skill: ", undefined), {
    nextName: undefined,
    named: false,
  });
});

test("names unknown skills (still better than the raw command in /resume)", () => {
  assert.deepStrictEqual(nameFromSkillCommand("/skill:not-a-real-skill", undefined), {
    nextName: "not-a-real-skill",
    named: true,
  });
});
```

- [ ] **Step 2: Run tests to verify they fail**

Run from repo root:

```bash
node --import tsx configs/pi/agent/extensions/skill-session-name.test.ts
```

Expected: FAIL because `nameFromSkillCommand` is missing or throws. Must not pass. If it passes, the tests are wrong — stop and fix the tests.

- [ ] **Step 3: Write the minimal implementation**

Write `configs/pi/agent/extensions/skill-session-name.ts` (replace any throw stub):

```ts
/**
 * Name the current pi session from a /skill:<name> invocation so /resume
 * shows the skill name instead of the expanded <skill …> first-message blob.
 *
 * Pure logic lives here; the extension default export only wires pi events.
 * Backed up at configs/pi/agent/extensions/ and symlinked by linkdotfiles.sh.
 */

export interface NameFromSkillResult {
  nextName: string | undefined;
  named: boolean;
}

/** Same parse as pi's _expandSkillCommand: no leading-trim, name up to first space. */
export function nameFromSkillCommand(
  text: string,
  currentName: string | undefined,
): NameFromSkillResult {
  const noop: NameFromSkillResult = { nextName: undefined, named: false };
  if (currentName !== undefined && currentName.trim().length > 0) return noop;
  if (!text.startsWith("/skill:")) return noop;
  const spaceIndex = text.indexOf(" ");
  const skillName = (spaceIndex === -1 ? text.slice(7) : text.slice(7, spaceIndex)).trim();
  if (skillName.length === 0) return noop;
  return { nextName: skillName, named: true };
}

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  pi.on("input", async (event) => {
    const result = nameFromSkillCommand(event.text, pi.getSessionName());
    if (result.named && result.nextName !== undefined) {
      pi.setSessionName(result.nextName);
    }
    return { action: "continue" as const };
  });
}
```

Keep the `import type` at the bottom or hoist it — either is fine. Do not transform the input text. Always `continue` so skill expansion still runs.

- [ ] **Step 4: Run tests to verify they pass**

```bash
node --import tsx configs/pi/agent/extensions/skill-session-name.test.ts
```

Expected: all 8 tests PASS. If any fail, fix the implementation, not the tests, unless a test contradicts the Global Constraints.

- [ ] **Step 5: Do not commit yet** — wait until Task 2 wires the symlink and README so one commit covers the feature.

---

### Task 2: Wire symlink + document

**Files:**
- Modify: `linkdotfiles.sh` (the pi extensions block around the existing `git-workflow-gates.ts` symlink)
- Modify: `configs/pi/README.md` (the "What's backed up here" table and any extension list)

**Interfaces:**
- Consumes: `skill-session-name.ts` from Task 1
- Produces: `~/.pi/agent/extensions/skill-session-name.ts` symlink after `./linkdotfiles.sh` (or the one-line `ln -sf` equivalent)

- [ ] **Step 1: Add the symlink next to the other extension links**

In `linkdotfiles.sh`, immediately after the `git-workflow-gates.ts` line, add:

```sh
ln -sf "$(pwd)"/configs/pi/agent/extensions/skill-session-name.ts ~/.pi/agent/extensions/skill-session-name.ts
```

- [ ] **Step 2: Document in `configs/pi/README.md`**

Add a table row under "What's backed up here":

```
| `extensions/skill-session-name.ts` | `~/.pi/agent/extensions/…` | on `/skill:<name>` in an unnamed session, set the session display name so `/resume` shows the skill name |
```

If the README lists extensions in prose, mention it there too in one sentence. Do not rewrite the README.

- [ ] **Step 3: Apply the symlink now** so the live `~/.pi/agent/extensions/` picks it up without a full `linkdotfiles.sh` run (safer — that script touches many things):

```bash
ln -sf /Users/yuxi/git/dotfiles/configs/pi/agent/extensions/skill-session-name.ts /Users/yuxi/.pi/agent/extensions/skill-session-name.ts
```

Confirm with `ls -l ~/.pi/agent/extensions/skill-session-name.ts`.

- [ ] **Step 4: Re-run unit tests**

```bash
node --import tsx configs/pi/agent/extensions/skill-session-name.test.ts
```

Expected: PASS.

---

### Task 3: Verify the `/resume` display contract

**Files:**
- None (throwaway verification only; do not commit fixtures)

**Interfaces:**
- Consumes: picker rule `displayText = session.name ?? session.firstMessage` (pi `session-selector.js`)
- Produces: evidence that a named skill session would render as `pr-catchup`

- [ ] **Step 1: Prove the picker contract with a throwaway session snippet**

Create `/tmp/pi-skill-session-name-verify.jsonl` (not in the repo):

```jsonl
{"type":"session","version":3,"id":"verify-skill-name","timestamp":"2026-08-24T00:00:00.000Z","cwd":"/tmp"}
{"type":"session_info","id":"aaaaaaaa","parentId":null,"timestamp":"2026-08-24T00:00:01.000Z","name":"pr-catchup"}
{"type":"message","id":"bbbbbbbb","parentId":"aaaaaaaa","timestamp":"2026-08-24T00:00:02.000Z","message":{"role":"user","content":"<skill name=\"pr-catchup\" location=\"/Users/yuxi/.agents/skills/pr-catchup/SKILL.md\">\nReferences are relative to /Users/yuxi/.agents/skills/pr-catchup.\n\n# PR Catch-up\n</skill>","timestamp":1756000000000}}
```

Then run this one-liner (no repo files):

```bash
node --input-type=module -e '
import { readFileSync } from "node:fs";
const lines = readFileSync("/tmp/pi-skill-session-name-verify.jsonl","utf8").trim().split("\n").map(JSON.parse);
const name = [...lines].reverse().find(e => e.type === "session_info")?.name;
const first = lines.find(e => e.type === "message" && e.message?.role === "user")?.message?.content ?? "";
const display = name ?? first;
console.log("PICKER_DISPLAY=" + JSON.stringify(display));
if (display !== "pr-catchup") process.exit(1);
if (String(first).includes("<skill")) console.log("firstMessage still has skill block (expected); picker hides it via name");
'
```

Expected: `PICKER_DISPLAY="pr-catchup"` and exit 0.

- [ ] **Step 2: Live `pi --resume` check if a throwaway session can be pointed at**

Prefer a **non-interactive** check first. If `pi --help` / `pi --session` can open the verify file without launching a model turn, do that and confirm `/session` (or the session header) shows name `pr-catchup`.

Do **not** invoke `/skill:pr-catchup` against a real Mappedin PR just to verify — that skill hits `gh` + Jira. The unit tests plus Step 1 are sufficient proof of the picker contract.

If a live picker is easy (`pi -r` is interactive and should **not** be driven unattended), skip it and report that the live TUI was not opened.

- [ ] **Step 3: Commit only the feature files**

```bash
git add \
  configs/pi/agent/extensions/skill-session-name.ts \
  configs/pi/agent/extensions/skill-session-name.test.ts \
  linkdotfiles.sh \
  configs/pi/README.md
git commit -m "$(cat <<'EOF'
Name unnamed pi sessions from /skill:<name> so /resume stays readable.

The resume picker shows session.name ?? firstMessage, and a skill
invocation expands into a long <skill> block. Set the display name
on first /skill: invoke so the picker shows just the skill name.
EOF
)"
```

Only if the user/environment allows commit. If a pre-commit gate blocks, follow the pre-commit skill (capture the why — already in the message above). Do not stage the unrelated dirty files.

---

## Self-review

1. **Spec coverage:** Name-on-invoke ✅, don't fight `/name` ✅, no skill-content injection ✅, `/resume` shows skill name ✅, TDD ✅, symlink + README ✅, verify picker contract ✅.
2. **Placeholders:** none.
3. **Types:** `nameFromSkillCommand(text, currentName) -> { nextName, named }` is the only shared contract; Task 2/3 consume it, they do not redefine it.
