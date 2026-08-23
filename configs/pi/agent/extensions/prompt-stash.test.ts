/**
 * Tests for the prompt-stash extension's pure logic.
 * Run: node --import tsx configs/pi/agent/extensions/prompt-stash.test.ts
 */
import test from "node:test";
import assert from "node:assert";

import { stashOrRestore } from "./prompt-stash.ts";

test("stash when editor has text", () => {
  const result = stashOrRestore("my draft", undefined);
  assert.deepStrictEqual(result, {
    nextEditorText: "",
    nextStash: "my draft",
    notification: { text: "Prompt stashed", level: "info" },
  });
});

test("restore when editor empty and stash exists", () => {
  const result = stashOrRestore("", "my draft");
  assert.deepStrictEqual(result, {
    nextEditorText: "my draft",
    nextStash: "my draft",
    notification: { text: "Prompt restored", level: "info" },
  });
});

test("no-op when editor empty and no stash", () => {
  const result = stashOrRestore("", undefined);
  assert.deepStrictEqual(result, {
    nextEditorText: "",
    nextStash: undefined,
    notification: { text: "Nothing to restore", level: "warning" },
  });
});

test("re-stashing overwrites previous stash", () => {
  const result = stashOrRestore("new draft", "old draft");
  assert.deepStrictEqual(result, {
    nextEditorText: "",
    nextStash: "new draft",
    notification: { text: "Prompt stashed", level: "info" },
  });
});

test("whitespace-only editor text is treated as empty", () => {
  const result = stashOrRestore("   ", undefined);
  assert.deepStrictEqual(result, {
    nextEditorText: "",
    nextStash: undefined,
    notification: { text: "Nothing to restore", level: "warning" },
  });
});