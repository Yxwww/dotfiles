"use strict";

// Coverage for the transcript parser (analyzeTranscript/emptyAnalysis) and the
// `git status --porcelain=v2` string parser. Fixtures are JSONL built from the
// event shapes real pi session files use.

const test = require("node:test");
const assert = require("node:assert/strict");

const {
  emptyAnalysis,
  analyzeTranscript,
  parseGitStatus,
} = require("./tmux-choose-pi.js");

// --- fixture builders -------------------------------------------------------

const ev = (o) => JSON.stringify(o);
const nl = (...l) => l.join("\n");
const T = (sec) => new Date(Date.UTC(2026, 0, 1, 0, 0, sec)).toISOString();

const msg = (sec, message) => ({ type: "message", timestamp: T(sec), message });
const tx = (text) => ({ type: "text", text });
const userMsg = (sec, text) => msg(sec, { role: "user", content: [tx(text)] });
const assistMsg = (sec, ...content) => msg(sec, { role: "assistant", content });
const toolCall = (id, name, args) => ({ type: "toolCall", id, name, arguments: args });
// `extra` lets a case add isError (or omit it entirely, which is its own case).
const resultMsg = (sec, toolCallId, text, extra) =>
  msg(sec, {
    role: "toolResult",
    toolCallId,
    toolName: "bash",
    content: [tx(text)],
    ...extra,
  });
const obsTurn = (sec, data) => ({
  type: "custom",
  customType: "obs-turn",
  timestamp: T(sec),
  data,
});

// --- analyzeTranscript: tool bookkeeping ------------------------------------

test("tool calls open on toolCall and close on a matching toolCallId, in any order", () => {
  const a = analyzeTranscript(
    nl(
      ev(
        assistMsg(
          1,
          toolCall("c1", "read", { path: "a.ts" }),
          toolCall("c2", "bash", { command: "make" }),
          toolCall("c3", "edit", { path: "b.ts" })
        )
      ),
      // results land out of order: c2 (the middle call) finishes first
      ev(resultMsg(2, "c2", "built", { isError: false }))
    )
  );
  // splice-by-id, not stack pop: c2 leaves the middle and the survivors keep
  // call order (a pop would have evicted c3 and left c2 behind).
  assert.deepEqual(a.openTools.map((t) => t.id), ["c1", "c3"]);
  // runningTool is the LAST still-open call, not the oldest one
  assert.deepEqual(a.runningTool, { id: "c3", name: "edit", args: { path: "b.ts" } });

  const allResolved = analyzeTranscript(
    nl(
      ev(assistMsg(1, toolCall("c1", "read", {}), toolCall("c2", "bash", { command: "ls" }))),
      ev(resultMsg(2, "c2", "")),
      ev(resultMsg(3, "c1", ""))
    )
  );
  assert.deepEqual(allResolved.openTools, []);
  assert.equal(allResolved.runningTool, null);

  // a result whose id matches nothing must not close an unrelated call
  const orphan = analyzeTranscript(
    nl(ev(assistMsg(1, toolCall("c1", "read", {}))), ev(resultMsg(2, "nope", "")))
  );
  assert.deepEqual(orphan.openTools.map((t) => t.id), ["c1"]);
});

// --- analyzeTranscript: error flag ------------------------------------------

test("lastResultError is assigned per result, never OR-accumulated", () => {
  const recovered = analyzeTranscript(
    nl(
      ev(resultMsg(1, "c1", "boom", { isError: true })),
      ev(resultMsg(2, "c1", "fine", { isError: false }))
    )
  );
  assert.equal(recovered.lastResultError, false);

  // absent isError is "not an error" and must clear an earlier failure too
  const absent = analyzeTranscript(
    nl(ev(resultMsg(1, "c1", "boom", { isError: true })), ev(resultMsg(2, "c1", "fine")))
  );
  assert.equal(absent.lastResultError, false);

  const failed = analyzeTranscript(nl(ev(resultMsg(1, "c1", "boom", { isError: true }))));
  assert.equal(failed.lastResultError, true);

  // error text survives a later blank result, while the flag still resets --
  // the card only prints the text when the flag is set, so no stale red line
  const blank = analyzeTranscript(
    nl(ev(resultMsg(1, "c1", "boom", { isError: true })), ev(resultMsg(2, "c1", "   ")))
  );
  assert.equal(blank.lastResultError, false);
  assert.equal(blank.lastResultText, "boom\n");

  const ok = analyzeTranscript(nl(ev(resultMsg(1, "c1", "fine"))));
  assert.equal(ok.lastResultText, "fine\n");
});

// --- analyzeTranscript: model + obs-turn ------------------------------------

test("model comes from model_change, obs-turn overrides it, a falsy modelId never clobbers", () => {
  const a = analyzeTranscript(
    nl(
      ev({ type: "model_change", timestamp: T(1), modelId: "anthropic/claude-sonnet-4-5" }),
      ev({ type: "model_change", timestamp: T(2), modelId: "" }),
      ev(obsTurn(3, { model: "mappedin/glm-5.2", cost: 0 })),
      ev({ type: "model_change", timestamp: T(4), modelId: null }),
      // a turn with no model in data keeps whatever is set
      ev(obsTurn(5, { cost: 0.01 }))
    )
  );
  assert.equal(a.model, "mappedin/glm-5.2");
  assert.equal(analyzeTranscript("").model, null);
});

test("obs-turn keeps the newest snapshot; other custom events are not turns", () => {
  const a = analyzeTranscript(
    nl(
      ev(obsTurn(1, { turnIndex: 0, inputTokens: 8769, outputTokens: 347, cost: 0, durationMs: 4076, tps: 85.1, model: "mappedin/glm-5.2" })),
      ev(obsTurn(2, { turnIndex: 1, inputTokens: 31704, outputTokens: 356, cost: 0.0412, durationMs: 4275, tps: 83.2, model: "mappedin/glm-5.2" })),
      // not a turn: must not touch model nor lastObs
      ev({ type: "custom", customType: "compaction", timestamp: T(3), data: { model: "other" } })
    )
  );
  assert.equal(a.sawObsTurn, true);
  assert.equal(a.lastObs.turnIndex, 1);
  assert.equal(a.lastObs.cost, 0.0412);
  assert.equal(a.lastObs.inputTokens, 31704);
  assert.equal(a.model, "mappedin/glm-5.2");

  const none = analyzeTranscript(nl(ev(userMsg(1, "hi"))));
  assert.equal(none.sawObsTurn, false);
  assert.equal(none.lastObs, null);

  // an obs-turn missing `data` still marks the turn and stores an empty object
  const bare = analyzeTranscript(nl(ev({ type: "custom", customType: "obs-turn", timestamp: T(1) })));
  assert.equal(bare.sawObsTurn, true);
  assert.deepEqual(bare.lastObs, {});
});

// --- analyzeTranscript: message text ----------------------------------------

test("blank user text is dropped and a leading <file> tag is stripped", () => {
  const a = analyzeTranscript(
    nl(
      ev(userMsg(1, "   \n\t ")),
      ev(msg(2, { role: "user", content: [{ type: "text" }] })),
      ev(msg(3, { role: "user", content: [] })),
      ev(userMsg(4, "first real ask")),
      // one message may carry several text blocks; each becomes its own ask
      ev(msg(5, { role: "user", content: [tx("one"), tx("two")] })),
      ev(userMsg(6, '<file name="/tmp/a.md">pasted dump</file> what does it say?'))
    )
  );
  // only the opening `<file ...>` tag is stripped; a body pasted on later lines
  // (plus its </file>) stays in the ask -- clip() is what bounds the card.
  assert.deepEqual(a.users, [
    "first real ask",
    "one",
    "two",
    'pasted dump</file> what does it say?',
  ]);

  // realistic multi-line attachment
  const dump = analyzeTranscript(
    ev(userMsg(1, '<file name="/tmp/notes.md">\nBODY\n</file>\nwhy is this slow?'))
  );
  assert.deepEqual(dump.users, ["BODY\n</file>\nwhy is this slow?"]);

  // an attachment-only message leaves an empty ask behind (cosmetic bug)
  assert.deepEqual(analyzeTranscript(ev(userMsg(1, '<file name="a.md">'))).users, [""]);
});

test("assistant text accumulates across blocks; thinking and blank text are dropped", () => {
  const a = analyzeTranscript(
    nl(
      // real pi replies carry thinking + a blank text block + the toolCall
      ev(
        assistMsg(
          1,
          { type: "thinking", thinking: "let me look", thinkingSignature: "reasoning_content" },
          tx("\n\n\n"),
          toolCall("c1", "bash", { command: "ls" })
        )
      ),
      ev(assistMsg(2, tx("Done "), tx("now."))),
      ev(assistMsg(3, tx("   ")))
    )
  );
  assert.deepEqual(a.assists, ["Done now."]);
  assert.deepEqual(a.openTools.map((t) => t.id), ["c1"]);
  assert.equal(a.lastRole, "assistant");
});

// --- analyzeTranscript: subagent labels -------------------------------------

test("subagent labels prefer name > action > agent, fall back, and de-dup", () => {
  const a = analyzeTranscript(
    nl(
      ev(assistMsg(1, toolCall("s1", "subagent", { name: "scout", action: "steer", agent: "worker" }))),
      ev(assistMsg(2, toolCall("s2", "subagent", { action: "recon", agent: "worker" }))),
      ev(assistMsg(3, toolCall("s3", "subagent", { agent: "researcher" }))),
      ev(assistMsg(4, toolCall("s4", "subagent"))),
      ev(assistMsg(5, toolCall("s5", "subagent", { name: "scout" }))),
      // other tools never contribute a label, but still open
      ev(assistMsg(6, toolCall("t1", "bash", { name: "not-a-label" })))
    )
  );
  assert.deepEqual(a.subagents, ["scout", "recon", "researcher", "subagent"]);
  assert.equal(a.openTools.length, 6);
});

// --- analyzeTranscript: robustness + timestamps -----------------------------

test("junk and truncated lines are skipped; lastEventTs is the last parseable one", () => {
  const truncated = ev(assistMsg(9, tx("cut off mid-write while the reader was copying"))).slice(0, 40);
  const a = analyzeTranscript(
    [
      "",
      "   ",
      "not json at all",
      "{broken",
      ev(42),
      ev("a bare string"),
      ev(true),
      ev([1, 2, 3]),
      ev(userMsg(1, "hi")),
      ev({ type: "session", version: 3, timestamp: 1767225600123, cwd: "/x" }),
      "}}} nonsense",
      truncated,
    ].join("\n")
  );
  assert.equal(a.lastEventTs, 1767225600123); // epoch millis pass through unparsed
  assert.deepEqual(a.users, ["hi"]);
  assert.equal(a.lastUserTs, 1767225601000);

  const empty = analyzeTranscript("");
  assert.equal(empty.lastEventTs, 0);
  assert.equal(empty.lastUserTs, 0);
  assert.equal(empty.lastRole, null);
});

// Known gap, reported not fixed: `null` is valid JSON but not an object, and
// the timestamp read sits outside the parse guard.
test("BUG: a bare `null` line throws instead of being skipped", () => {
  assert.throws(() => analyzeTranscript("null"), TypeError);
});

test("lastRole tracks the newest message; lastUserTs only moves with a timestamped user message", () => {
  const a = analyzeTranscript(
    nl(
      ev(userMsg(1, "ask one")),
      ev(assistMsg(2, tx("reply"))),
      ev(userMsg(30, "ask two")),
      ev(assistMsg(40, tx("reply two"))),
      ev(resultMsg(50, "c1", "done")),
      ev(msg(60, { content: [] })) // role-less message must not clobber
    )
  );
  assert.equal(a.lastRole, "toolResult");
  assert.equal(a.lastUserTs, 1767225630000);
  assert.equal(a.lastEventTs, Date.parse(T(60)));

  const b = analyzeTranscript(
    nl(ev(userMsg(30, "asked")), ev({ type: "message", message: { role: "user", content: [] } }))
  );
  assert.equal(b.lastUserTs, 1767225630000);
  assert.equal(b.lastRole, "user");
  assert.equal(b.lastEventTs, 1767225630000);
});

// --- emptyAnalysis ----------------------------------------------------------

test("emptyAnalysis hands out fresh arrays on every call", () => {
  const a = emptyAnalysis();
  const b = emptyAnalysis();
  for (const k of ["users", "assists", "subagents", "openTools"]) {
    assert.deepEqual(a[k], []);
    assert.notStrictEqual(a[k], b[k]); // shared template would alias
  }
  a.users.push("x");
  a.openTools.push({ id: "c1" });
  assert.deepEqual(b.users, []);
  assert.deepEqual(b.openTools, []);
  assert.equal(a.lastResultError, false);
  assert.equal(a.lastResultText, "");
  assert.equal(a.model, null);
  assert.equal(a.runningTool, null);
});

// --- parseGitStatus ---------------------------------------------------------

test("parseGitStatus reads the branch header and counts every non-header line", () => {
  const out =
    "# branch.oid 7e01b9f9ca6491563cc497a28b44127304af8f9a\n" +
    "# branch.head perf/tmux-pi-picker-startup\n" +
    "# branch.upstream origin/perf/tmux-pi-picker-startup\n" +
    "# branch.ab +0 -0\n" +
    "1 .M N... 100644 100644 100644 feb3063 256ea10 scripts/tmux-choose-pi.js\n" +
    "2 .R N... 100644 100644 100644 feb3063 256ea10 R100 old.txt new.txt\n" +
    "? pi-config/\n";
  // staged modify + staged rename + untracked = 3, headers count 0
  assert.deepEqual(parseGitStatus(out), {
    branch: "perf/tmux-pi-picker-startup",
    dirty: 3,
  });
  assert.deepEqual(parseGitStatus(""), { branch: "", dirty: 0 });
  assert.deepEqual(parseGitStatus("\n\n"), { branch: "", dirty: 0 });
  assert.deepEqual(parseGitStatus("# branch.head main"), { branch: "main", dirty: 0 });
});

test("parseGitStatus maps the (detached)/(unknown) sentinels to an empty branch", () => {
  // the old implementation used `symbolic-ref --short -q`, which is empty here
  assert.deepEqual(parseGitStatus("# branch.head (detached)\n1 .M N... 100644 100644 100644 a b f.ts"), {
    branch: "",
    dirty: 1,
  });
  assert.deepEqual(parseGitStatus("# branch.head (unknown)"), { branch: "", dirty: 0 });
  // accepted divergence: git cannot tell a sentinel from a branch of that name
  assert.deepEqual(parseGitStatus("# branch.head (detached)"), { branch: "", dirty: 0 });
});

test("parseGitStatus keeps odd branch names intact", () => {
  assert.deepEqual(parseGitStatus("# branch.head feat#42 hash"), { branch: "feat#42 hash", dirty: 0 });
  assert.deepEqual(parseGitStatus("# branch.head #wip"), { branch: "#wip", dirty: 0 });
  assert.deepEqual(parseGitStatus("# branch.head 日本語/ünïcødé"), { branch: "日本語/ünïcødé", dirty: 0 });
});
