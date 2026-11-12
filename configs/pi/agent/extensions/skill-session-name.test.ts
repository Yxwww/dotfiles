/**
 * Tests for skill-session-name pure logic.
 * Run: bun test configs/pi/agent/extensions/skill-session-name.test.ts
 */
import test from "node:test";
import assert from "node:assert";

import {
  nameForSession,
  nameFromPrompt,
  nameFromSkillCommand,
} from "./skill-session-name.ts";

test("noise skills never become the session name", () => {
  // A skill is a workflow, not a subject. pr-catchup named 211 sessions alike.
  for (const skill of ["pr-catchup", "code-review", "simplify", "grilling", "retro"]) {
    assert.deepStrictEqual(
      nameFromSkillCommand(`/skill:${skill}`, undefined),
      { nextName: undefined, named: false },
      skill,
    );
  }
});

test("names an unnamed session from a subject-bearing skill", () => {
  assert.deepStrictEqual(nameFromSkillCommand("/skill:bump-sdk", undefined), {
    nextName: "bump-sdk",
    named: true,
  });
});

test("strips args after the skill name", () => {
  assert.deepStrictEqual(
    nameFromSkillCommand("/skill:bump-sdk --force", undefined),
    { nextName: "bump-sdk", named: true },
  );
});

test("does not override an existing session name", () => {
  assert.deepStrictEqual(nameFromSkillCommand("/skill:bump-sdk", "Refactor auth"), {
    nextName: undefined,
    named: false,
  });
});

test("treats whitespace-only current name as unnamed", () => {
  assert.deepStrictEqual(nameFromSkillCommand("/skill:bump-sdk", "   "), {
    nextName: "bump-sdk",
    named: true,
  });
});

test("ignores a leading-whitespace skill command (pi does not trim)", () => {
  assert.deepStrictEqual(nameFromSkillCommand(" /skill:bump-sdk", undefined), {
    nextName: undefined,
    named: false,
  });
  assert.deepStrictEqual(nameFromSkillCommand("/skill:", undefined), {
    nextName: undefined,
    named: false,
  });
});

test("names from the prompt, dropping filler and trailing punctuation", () => {
  const cases: [string, string][] = [
    ["Can you figure out why storybook is red?", "figure out why storybook is red"],
    ["please bump the sdk to 6.19.1 canary.", "bump the sdk to 6.19.1 canary"],
    ["I want to add a depth-sorted label renderer", "add a depth-sorted label renderer"],
    ['"fix the flaky checkout test"', "fix the flaky checkout test"],
  ];
  for (const [input, expected] of cases) {
    assert.deepStrictEqual(nameFromPrompt(input, undefined), {
      nextName: expected,
      named: true,
    }, input);
  }
});

test("only the first line of a multi-line prompt names the session", () => {
  assert.deepStrictEqual(
    nameFromPrompt("why is storybook red\n\nDetails: PR #206 merged...", undefined),
    { nextName: "why is storybook red", named: true },
  );
});

test("refuses thin prompts so the cwd fallback survives", () => {
  for (const thin of ["hi", "ok", "thanks", "continue", "yes please", "  ", "a"]) {
    assert.deepStrictEqual(nameFromPrompt(thin, undefined), {
      nextName: undefined,
      named: false,
    }, JSON.stringify(thin));
  }
});

test("ignores commands, shell escapes and pasted blobs", () => {
  assert.deepStrictEqual(nameFromPrompt("/model", undefined), {
    nextName: undefined,
    named: false,
  });
  assert.deepStrictEqual(nameFromPrompt("!git status", undefined), {
    nextName: undefined,
    named: false,
  });
  assert.deepStrictEqual(nameFromPrompt("x".repeat(2001), undefined), {
    nextName: undefined,
    named: false,
  });
});

test("truncates long prompts at a word boundary", () => {
  const long = "make the shadow embed respect the parent container width on resize";
  const result = nameFromPrompt(long, undefined);
  assert.ok(result.named);
  assert.ok(result.nextName!.length <= 48);
  assert.ok(!result.nextName!.endsWith(" "));
  assert.ok(long.startsWith(result.nextName!));
});

test("keeps a single very long word rather than collapsing to nothing", () => {
  const word = "a".repeat(70);
  assert.deepStrictEqual(nameFromPrompt(word, undefined), {
    nextName: word.slice(0, 48),
    named: true,
  });
});

test("never renames a session that already has a real name", () => {
  assert.deepStrictEqual(nameFromPrompt("why is storybook red", "bump-sdk"), {
    nextName: undefined,
    named: false,
  });
});

test("pi-internal agent session names do not count and are never produced", () => {
  // Renaming a subagent session by prompt would surface noise in /resume.
  assert.deepStrictEqual(nameFromPrompt("why is storybook red", "subagent-worker-a58e"), {
    nextName: undefined,
    named: false,
  });
  assert.deepStrictEqual(nameFromPrompt("worker-123 investigate the flake", undefined), {
    nextName: undefined,
    named: false,
  });
});

test("ignores a literal <skill …> blob defensively (pi expands after the input event)", () => {
  for (const blob of [
    '<skill name="pr-catchup" location="/Users/x/.agents/skills/pr-catchup/SKILL.md">',
    "<skill\tname=\"x\"",
    "<SKILL name=\"x\"",
  ]) {
    assert.deepStrictEqual(nameFromPrompt(blob, undefined), {
      nextName: undefined,
      named: false,
    }, blob);
  }
});

test("strips 'I want you to' without leaving a dangling 'you to'", () => {
  assert.deepStrictEqual(
    nameFromPrompt("I want you to triage the overdue security tickets", undefined),
    { nextName: "triage the overdue security tickets", named: true },
  );
});

test("condenses a URL to its PR number so the subject survives", () => {
  assert.deepStrictEqual(
    nameFromPrompt("I want to review https://github.com/MappedIn/app-framework/pull/152 and check the diff", undefined),
    { nextName: "review #152 and check the diff", named: true },
  );
  assert.deepStrictEqual(
    nameFromPrompt("summarize https://example.com/some/deep/path?x=1", undefined),
    { nextName: "summarize example.com", named: true },
  );
});

test("does not strip a content word that can legitimately end a title", () => {
  // 50 chars -> truncated at the last space, leaving "...master is"; "is" is not
  // a connector, so it stays rather than being chomped like "and" would be.
  assert.deepStrictEqual(
    nameFromPrompt("Someone told me the app framework master is broken", undefined),
    { nextName: "Someone told me the app framework master is", named: true },
  );
  assert.deepStrictEqual(
    nameFromPrompt("figure out why the embed is not loading and the map is blank please", undefined),
    { nextName: "figure out why the embed is not loading", named: true },
  );
});

test("a noise skill names the session from its argument, not from the skill", () => {
  // "/skill:pr-catchup 152" is the headline invocation; it must not go unnamed.
  assert.deepStrictEqual(nameForSession("/skill:pr-catchup 152", undefined), {
    nextName: "152",
    named: true,
  });
  assert.deepStrictEqual(
    nameForSession("/skill:pr-catchup https://github.com/MappedIn/app-framework/pull/152", undefined),
    { nextName: "#152", named: true },
  );
  assert.deepStrictEqual(
    nameForSession("/skill:code-review review the SDK-575 diff", undefined),
    { nextName: "review the SDK-575 diff", named: true },
  );
  // No argument and no subject: leave the cwd fallback alone.
  assert.deepStrictEqual(nameForSession("/skill:pr-catchup", undefined), {
    nextName: undefined,
    named: false,
  });
  // An existing name still wins.
  assert.deepStrictEqual(nameForSession("/skill:pr-catchup 152", "mine"), {
    nextName: undefined,
    named: false,
  });
});

test("slash commands are never named", () => {
  for (const cmd of ["/model", "/compact", "/tree"]) {
    assert.deepStrictEqual(nameForSession(cmd, undefined), {
      nextName: undefined,
      named: false,
    }, cmd);
  }
});

test("prompt naming applies after a noise skill so the session still gets a name", () => {
  assert.deepStrictEqual(
    nameForSession("/skill:pr-catchup", undefined),
    { nextName: undefined, named: false },
  );
  assert.deepStrictEqual(
    nameForSession("review the SDK-575 diff", undefined),
    { nextName: "review the SDK-575 diff", named: true },
  );
});
