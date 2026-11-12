#!/usr/bin/env node
// Run: node --test "scripts/ystack/*.test.mjs"
// Exercises the pure parsers and the link/doctor behaviour against a tmp skills dir.

import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, mkdirSync, writeFileSync, symlinkSync, readdirSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { execFileSync } from "node:child_process";
import { parseManifest, parseLock, planSkillsCli } from "./install.mjs";

const MANIFEST = join(import.meta.dirname, "..", "..", "configs", "pi", "stacks", "ystack", "STACK.md");

test("parseManifest reads the real STACK.md", () => {
  const m = parseManifest(execFileSync("cat", [MANIFEST], { encoding: "utf-8" }));

  // dotfiles skills: every table row in the origin: dotfiles section.
  assert.deepEqual(m.dotfiles, [
    "pre-commit",
    "pre-push",
    "pr-catchup",
    "ship",
    "simplify",
    "code-review",
    "flaky-ci",
    "pf",
  ]);

  // cli-installer: generated stubs, never copied.
  assert.deepEqual(m.cliInstaller, ["agent-browser", "rex"]);

  // excluded: domain-stack skills, and no prose leaks in (e.g. words outside backticks).
  for (const n of ["bump-sdk", "dev-flow", "review-loop", "sdk-browser", "sdk-issue-report", "task-board"]) {
    assert.ok(m.excluded.includes(n), `${n} should be excluded`);
  }
  // A wrapped list must not silently drop names — that bug under-counted by 2.
  assert.equal(m.excluded.length, 6);
  assert.ok(!m.dotfiles.includes("agent-browser"), "cli-installer must not leak into dotfiles");
  assert.ok(!m.excluded.includes("the"), "only backticked names count as excluded");
});

test("parseManifest ignores headings outside the three it knows", () => {
  const m = parseManifest(
    [
      "# title",
      "| `nope` | not under a section |",
      "## `origin: dotfiles`",
      "| Skill | Purpose |",
      "|---|---|",
      "| `alpha` | a |",
      "| `beta-x` | b |",
      "## `origin: skills-cli`",
      "| `gamma` | belongs to the CLI |",
      "## `excluded`",
      "prose mentioning `delta`",
      "- `epsilon`, `zeta` live elsewhere",
    ].join("\n"),
  );
  assert.deepEqual(m.dotfiles, ["alpha", "beta-x"]);
  assert.deepEqual(m.cliInstaller, []);
  // Bare prose line is not a bullet, so `delta` is ignored.
  assert.deepEqual(m.excluded, ["epsilon", "zeta"]);
});

test("parseLock sorts names and tolerates a missing skills map", () => {
  assert.deepEqual(parseLock({ skills: { b: {}, a: {} } }), ["a", "b"]);
  assert.deepEqual(parseLock({}), []);
});

// --- behaviour: link / doctor against an isolated skills dir -----------------

function sandbox() {
  const root = mkdtempSync(join(tmpdir(), "ystack-test-"));
  const skills = join(root, "skills");
  mkdirSync(skills, { recursive: true });
  const run = (cmd) =>
    execFileSync("node", [join(import.meta.dirname, "install.mjs"), cmd], {
      env: { ...process.env, AGENT_SKILLS_DIR: skills },
      encoding: "utf-8",
      stdio: "pipe",
    });
  return { root, skills, run, done: () => rmSync(root, { recursive: true, force: true }) };
}

test("link creates one symlink per dotfiles skill, idempotently", () => {
  const s = sandbox();
  try {
    s.run("link");
    const linked = readdirSync(s.skills).sort();
    assert.deepEqual(linked, ["code-review", "flaky-ci", "pf", "pr-catchup", "pre-commit", "pre-push", "ship", "simplify"]);
    // Second run must not fail on existing links.
    assert.doesNotThrow(() => s.run("link"));
    assert.deepEqual(readdirSync(s.skills).sort(), linked);
  } finally {
    s.done();
  }
});

test("link refuses to clobber a real directory owned by another tool", () => {
  const s = sandbox();
  try {
    // Simulate the skills CLI having installed `code-review` as a real dir.
    mkdirSync(join(s.skills, "code-review"));
    writeFileSync(join(s.skills, "code-review", "SKILL.md"), "upstream");
    s.run("link");
    // ...the CLI's file survives, so `npx skills update -g` ownership is intact.
    assert.equal(readdirSync(join(s.skills, "code-review")).join(), "SKILL.md");
  } finally {
    s.done();
  }
});

test("doctor reports drift and passes when clean", () => {
  const s = sandbox();
  try {
    assert.throws(() => s.run("doctor"), /Command failed/);
    s.run("link");
    assert.doesNotThrow(() => s.run("doctor"));
  } finally {
    s.done();
  }
});

test("link repairs a stale symlink left by a previous layout", () => {
  const s = sandbox();
  try {
    // Simulate the pre-stack layout: same name, wrong destination.
    mkdirSync(join(s.root, "old", "pf"), { recursive: true });
    symlinkSync(join(s.root, "old", "pf"), join(s.skills, "pf"), "dir");
    s.run("link");
    assert.doesNotThrow(() => s.run("doctor"));
  } finally {
    s.done();
  }
});

test("doctor flags a link that points outside the stack", () => {
  const s = sandbox();
  try {
    s.run("link");
    const other = join(s.root, "impostor");
    mkdirSync(other);
    rmSync(join(s.skills, "pf"), { force: true });
    symlinkSync(other, join(s.skills, "pf"), "dir");
    try {
      s.run("doctor");
      assert.fail("doctor should have failed");
    } catch (e) {
      assert.match(String(e.stderr), /pf: links to .*impostor/);
    }
  } finally {
    s.done();
  }
});

// --- skills-cli: never install a package that would overwrite an owned name ---

test("planSkillsCli flags a source whose package contains an owned skill", () => {
  // `code-review` ships inside mattpocock/skills, so restoring any other skill
  // from that repo drags it in and clobbers the ystack copy. Regression: this
  // actually happened and replaced the symlink with a real directory.
  const plan = planSkillsCli({
    owned: ["code-review"],
    installed: ["grilling"],
    lock: {
      skills: {
        grilling: { source: "mattpocock/skills" },
        "code-review": { source: "mattpocock/skills" },
        tdd: { source: "mattpocock/skills" },
      },
    },
  });
  // `tdd` is missing from disk, but its package also ships the owned
  // `code-review`, so the whole source is refused rather than installed.
  assert.deepEqual(plan.sources, []);
  assert.deepEqual(plan.blocked, [{ source: "mattpocock/skills", collides: ["code-review"] }]);
});

test("planSkillsCli does nothing when every tracked skill is installed", () => {
  const plan = planSkillsCli({
    owned: ["code-review"],
    installed: ["tdd", "code-review"],
    lock: { skills: { tdd: { source: "mattpocock/skills" }, "code-review": { source: "mattpocock/skills" } } },
  });
  assert.deepEqual(plan.sources, []);
  assert.deepEqual(plan.blocked, []);
});

test("planSkillsCli ignores installed skills when deciding what is missing", () => {
  // A tracked skill that is present must not trigger a restore just because
  // its source also has absent siblings.
  const plan = planSkillsCli({
    owned: [],
    installed: ["a"],
    lock: { skills: { a: { source: "s/one" } } },
  });
  assert.deepEqual(plan.sources, []);
});
