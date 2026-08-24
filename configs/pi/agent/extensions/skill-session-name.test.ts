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