"use strict";

// Pure formatting + status layer of tmux-choose-pi. No tmux, no fs, no git:
// every case below is deterministic input -> observable string.
//
// Run: node --test scripts/tmux-choose-pi.format.test.js

const { test } = require("node:test");
const assert = require("node:assert/strict");

const {
  STALE_AFTER_SEC,
  parseTs,
  clip,
  shortModel,
  humanizeAge,
  mmss,
  cleanTitle,
  briefArg,
  emptyAnalysis,
  computeStatus,
  statusDot,
  statusColor,
  turnElapsed,
} = require("./tmux-choose-pi.js");

// Colour constants are module-private; assert the literal SGR codes instead of
// exporting them, and strip ANSI when only the glyph matters.
const strip = (s) => s.replace(/\x1b\[[0-9;]*m/g, "");
const RESET = "\x1b[0m";
const SGR = { idle: "\x1b[32m", working: "\x1b[33m", error: "\x1b[31m", other: "\x1b[90m" };

// A fixed epoch far from 0 so `0` can never pass as a valid timestamp.
const NOW = 1_700_000_000_000;
const sec = (n) => n * 1000;

/** Analysis object with just the fields computeStatus/turnElapsed read. */
function analysis(over) {
  const a = emptyAnalysis();
  for (const k of Object.keys(over)) a[k] = over[k];
  return a;
}

test("parseTs accepts both transcript encodings and zeroes the rest", () => {
  // epoch millis pass through untouched (no Date round-trip)
  assert.equal(parseTs(1_700_000_000_123), 1_700_000_000_123);
  assert.equal(parseTs(0), 0);
  assert.equal(parseTs("2020-01-01T00:00:00.000Z"), 1_577_836_800_000);
  assert.equal(parseTs("2020-01-01T00:00:00.500Z"), 1_577_836_800_500);
  // explicit offset, so the case is timezone-independent
  assert.equal(parseTs("2020-01-01T01:00:00+01:00"), 1_577_836_800_000);
  // missing / unparseable must be 0, never NaN or a Date-derived surprise
  assert.equal(parseTs(null), 0);
  assert.equal(parseTs(undefined), 0);
  assert.equal(parseTs(""), 0);
  assert.equal(parseTs("not a date"), 0);
  // a numeric *string* is not an epoch here -- Date.parse rejects it
  assert.equal(parseTs("1700000000000"), 0);
});

test("clip collapses whitespace, trims, and only ellipsises real truncation", () => {
  assert.equal(clip("a\tb\nc", 10), "a b c");
  assert.equal(clip("   padded   ", 20), "padded");
  // exactly at the limit: no ellipsis
  assert.equal(clip("abcd", 4), "abcd");
  // one over: slice(0, n) + ellipsis
  assert.equal(clip("abcde", 4), "abcd…");
  // collapse happens before measuring, so the limit counts the flat form
  assert.equal(clip("a  b   c", 3), "a b…");
  assert.equal(clip("", 5), "");
  assert.equal(clip(null, 5), "");
  assert.equal(clip(undefined, 5), "");
  assert.equal(clip("abc", 0), "…");
});

test("shortModel keeps the segment after the last slash", () => {
  assert.equal(shortModel("anthropic/claude-sonnet-4-5"), "claude-sonnet-4-5");
  assert.equal(shortModel("vendor/team/model-x"), "model-x");
  assert.equal(shortModel("gpt-4o"), "gpt-4o");
  assert.equal(shortModel(""), null);
  assert.equal(shortModel(null), null);
  assert.equal(shortModel(undefined), null);
  // trailing slash -> empty, which renderCard falls back to "—" for
  assert.equal(shortModel("a/b/"), "");
});

test("humanizeAge buckets seconds and guards non-finite input", () => {
  assert.equal(humanizeAge(null), "—");
  assert.equal(humanizeAge(Infinity), "—");
  assert.equal(humanizeAge(-Infinity), "—");
  assert.equal(humanizeAge(NaN), "—");
  // "now" covers a fresh event and the clamped-negative case alike
  assert.equal(humanizeAge(0), "now");
  assert.equal(humanizeAge(1.9), "now");
  assert.equal(humanizeAge(-5), "now");
  // s bucket: 2 .. 59
  assert.equal(humanizeAge(2), "2s");
  assert.equal(humanizeAge(59), "59s");
  // m bucket: 60 .. 3599, floored
  assert.equal(humanizeAge(60), "1m");
  assert.equal(humanizeAge(3599), "59m");
  // h bucket: 3600+, floored
  assert.equal(humanizeAge(3600), "1h");
  assert.equal(humanizeAge(7199), "1h");
  assert.equal(humanizeAge(7200), "2h");
});

test("mmss clamps negatives and zero-pads seconds only", () => {
  assert.equal(mmss(-1000), "0:00");
  // negative sub-second still floors to -1s before the clamp
  assert.equal(mmss(-500), "0:00");
  assert.equal(mmss(0), "0:00");
  assert.equal(mmss(999), "0:00");
  assert.equal(mmss(9000), "0:09");
  assert.equal(mmss(65_000), "1:05");
  assert.equal(mmss(600_000), "10:00");
  assert.equal(mmss(3_599_999), "59:59");
  // minutes keep counting past an hour -- no hour field in the card
  assert.equal(mmss(3_661_000), "61:01");
});

test("cleanTitle strips the pi prefix and never blanks the title", () => {
  assert.equal(cleanTitle("π fix the login bug"), "fix the login bug");
  assert.equal(cleanTitle("π-fix the login bug"), "fix the login bug");
  assert.equal(cleanTitle("π - fix"), "fix");
  assert.equal(cleanTitle("π–fix"), "fix"); // en dash
  assert.equal(cleanTitle("π—fix"), "fix"); // em dash
  assert.equal(cleanTitle("π: fix"), "fix");
  assert.equal(cleanTitle("π--:: fix"), "fix");
  // pi: form is case-insensitive, and only with the colon
  assert.equal(cleanTitle("pi: fix"), "fix");
  assert.equal(cleanTitle("PI: fix"), "fix");
  assert.equal(cleanTitle("Pi: fix"), "fix");
  assert.equal(cleanTitle("pi fix"), "pi fix");
  // ^ anchors both patterns
  assert.equal(cleanTitle("api: fix"), "api: fix");
  assert.equal(cleanTitle("the π thing"), "the π thing");
  // both prefixes on one title are stripped in sequence
  assert.equal(cleanTitle("π pi: fix"), "fix");
  // stripping must not blank the label -- fall back to the original
  assert.equal(cleanTitle("π"), "π");
  assert.equal(cleanTitle("π "), "π ");
  assert.equal(cleanTitle("pi:"), "pi:");
  assert.equal(cleanTitle(""), "");
});

test("statusDot pairs glyph, colour and reset; statusColor matches", () => {
  assert.equal(statusDot("idle"), SGR.idle + "●" + RESET);
  assert.equal(statusDot("working"), SGR.working + "◐" + RESET);
  assert.equal(statusDot("error"), SGR.error + "✖" + RESET);
  // stale (and anything unknown) is the hollow grey dot
  assert.equal(statusDot("stale"), SGR.other + "○" + RESET);
  assert.equal(statusDot(undefined), SGR.other + "○" + RESET);

  assert.equal(statusColor("idle"), SGR.idle);
  assert.equal(statusColor("working"), SGR.working);
  assert.equal(statusColor("error"), SGR.error);
  assert.equal(statusColor("stale"), SGR.other);
  assert.equal(statusColor("nope"), SGR.other);

  // glyphs alone must still tell the states apart -- piping `list` anywhere that
  // drops the SGR codes leaves only the dot
  assert.deepEqual(["idle", "working", "error", "stale"].map(statusDot).map(strip), [
    "●",
    "◐",
    "✖",
    "○",
  ]);
});

test("computeStatus: an event under 5s old is working ahead of everything", () => {
  // last event 1s ago beats the error flag and an otherwise-idle shape
  assert.equal(computeStatus(analysis({ lastEventTs: NOW - 1000 }), NOW), "working");
  assert.equal(
    computeStatus(analysis({ lastEventTs: NOW - 1000, lastRole: "assistant", lastResultError: true }), NOW),
    "working"
  );
  // clock skew (pane in the future) clamps the age to 0, not negative
  assert.equal(computeStatus(analysis({ lastEventTs: NOW + 5000 }), NOW), "working");
  // boundary: exactly 5s is no longer "just emitted"
  assert.equal(computeStatus(analysis({ lastEventTs: NOW - 5000 }), NOW), "idle");
});

test("computeStatus: open tools / unanswered prompt mean working", () => {
  const ts = NOW - 30_000;
  assert.equal(computeStatus(analysis({ lastEventTs: ts, openTools: [{ id: "1" }] }), NOW), "working");
  assert.equal(computeStatus(analysis({ lastEventTs: ts, lastRole: "user" }), NOW), "working");
  // toolResult closing the call, and the assistant answering, end "working"
  assert.equal(
    computeStatus(analysis({ lastEventTs: ts, openTools: [], lastRole: "assistant" }), NOW),
    "idle"
  );
});

test("computeStatus: lastResultError only means error while still active", () => {
  assert.equal(
    computeStatus(analysis({ lastEventTs: NOW - 30_000, lastRole: "assistant", lastResultError: true }), NOW),
    "error"
  );
  // error ranks below working while active
  assert.equal(
    computeStatus(
      analysis({ lastEventTs: NOW - 30_000, openTools: [{ id: "1" }], lastResultError: true }),
      NOW
    ),
    "working"
  );
});

test("computeStatus: staleness overrides working, error and the default", () => {
  const old = NOW - (STALE_AFTER_SEC + 10) * 1000;
  assert.equal(computeStatus(analysis({ lastEventTs: old, openTools: [{ id: "1" }] }), NOW), "stale");
  assert.equal(computeStatus(analysis({ lastEventTs: old, lastRole: "user" }), NOW), "stale");
  assert.equal(
    computeStatus(analysis({ lastEventTs: old, lastRole: "assistant", lastResultError: true }), NOW),
    "stale"
  );
  assert.equal(computeStatus(analysis({ lastEventTs: old }), NOW), "stale");
  // no timestamp at all is treated as infinitely old
  assert.equal(computeStatus(analysis({ openTools: [{ id: "1" }] }), NOW), "stale");

  // threshold boundary: STALE_AFTER_SEC exactly is already stale, one second
  // younger is still active
  assert.equal(
    computeStatus(analysis({ lastEventTs: NOW - STALE_AFTER_SEC * 1000, openTools: [{ id: "1" }] }), NOW),
    "stale"
  );
  assert.equal(
    computeStatus(
      analysis({ lastEventTs: NOW - (STALE_AFTER_SEC - 1) * 1000, openTools: [{ id: "1" }] }),
      NOW
    ),
    "working"
  );
});

test("briefArg picks path > command > action > name", () => {
  assert.equal(briefArg({ args: { path: "/etc/hosts" } }), "/etc/hosts");
  assert.equal(briefArg({ args: { path: "/etc/hosts", command: "ls", action: "a", name: "n" } }), "/etc/hosts");
  assert.equal(briefArg({ args: { command: "ls -la", action: "a", name: "n" } }), "ls -la");
  assert.equal(briefArg({ args: { action: "read", name: "n" } }), "read");
  assert.equal(briefArg({ args: { name: "worker" } }), "worker");
  // reads `args`, not the transcript's `arguments` key (analyzeTranscript maps it)
  assert.equal(briefArg({ arguments: { path: "/etc/hosts" } }), "");
  assert.equal(briefArg({}), "");
  assert.equal(briefArg({ args: {} }), "");
  assert.equal(briefArg({ args: null }), "");
  // unknown keys fall back to the JSON, clipped at 80
  assert.equal(briefArg({ args: { query: "hi" } }), '{"query":"hi"}');
  // long command: clipped at 120 chars plus the ellipsis
  const long = briefArg({ args: { command: "x".repeat(130) } });
  assert.equal(long.length, 121);
  assert.equal(long, "x".repeat(120) + "…");
  // whitespace inside a command is flattened before measuring
  assert.equal(briefArg({ args: { command: "a\n   b" } }), "a b");
});

test("turnElapsed prefers the live user-turn delta over the recorded duration", () => {
  assert.equal(turnElapsed(analysis({ lastUserTs: NOW - 4000 }), NOW), 4000);
  // lastUserTs wins even when an obs-turn duration is present
  assert.equal(
    turnElapsed(analysis({ lastUserTs: NOW - 4000, lastObs: { durationMs: 900 } }), NOW),
    4000
  );
  // 0 is falsy, so a turn-less analysis falls through to the recorded duration
  assert.equal(turnElapsed(analysis({ lastUserTs: 0, lastObs: { durationMs: 900 } }), NOW), 900);
  assert.equal(turnElapsed(analysis({ lastObs: { durationMs: 0 } }), NOW), 0);
  assert.equal(turnElapsed(analysis({}), NOW), 0);
  // a future user timestamp yields a negative delta; mmss clamps it for display
  assert.equal(turnElapsed(analysis({ lastUserTs: NOW + 5000 }), NOW), -5000);
  assert.equal(mmss(turnElapsed(analysis({ lastUserTs: NOW + 5000 }), NOW)), "0:00");
});
