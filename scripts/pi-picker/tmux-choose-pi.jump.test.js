"use strict";

// Coverage for the jump path in tmux-choose-pi.sh.
//
// The bug: the wrapper jumped with field 1 (`session:window_index.pane_index`),
// an INDEX-BASED address. tmux renumbers indices whenever a window or pane
// closes, so between `list` printing a row and the user pressing Enter the same
// index string can name a DIFFERENT pane -- and tmux resolves it happily, so the
// jump lands somewhere wrong with exit status 0. Field 2 (`%pane_id`) is stable.
//
// These tests stub `tmux` so the jump is observable without a tmux server: the
// stub records the argv of every call and resolves indexes from a canned map,
// which is what lets us simulate "the index moved while fzf was open".

const { test } = require("node:test");
const assert = require("node:assert/strict");
const { spawnSync } = require("node:child_process");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");

const SH = path.join(__dirname, "tmux-choose-pi.sh");
const ROOT = fs.mkdtempSync(path.join(os.tmpdir(), "tmux-choose-pi-jump-"));
const BIN = path.join(ROOT, "bin");
const LOG = path.join(ROOT, "tmux.log");
fs.mkdirSync(BIN, { recursive: true });

// Stub tmux. `display-message -p -t <t> <fmt>` prints the resolved pane id and
// session for <t>, using TMUX_STUB_MAP (target -> "session|pane_id") so a test
// can make an index resolve to whatever it likes, including a moved pane.
const TMUX_STUB = path.join(BIN, "tmux");
fs.writeFileSync(
  TMUX_STUB,
  [
    "#!/bin/sh",
    'printf "%s\\n" "$*" >>"$TMUX_STUB_LOG"',
    'cmd="$1"; shift',
    'case "$cmd" in',
    "  display-message)",
    "    # skip flags, take the value after -t",
    '    target=""; fmt=""',
    '    while [ $# -gt 0 ]; do',
    '      case "$1" in',
    '        -t) target="$2"; shift 2 ;;',
    '        -p) shift ;;',
    '        *) fmt="$1"; shift ;;',
    "      esac",
    "    done",
    '    entry="$(grep -F "${target}|" "$TMUX_STUB_MAP" | head -1)"',
    '    if [ -z "$entry" ]; then echo "can\'t find pane: $target" >&2; exit 1; fi',
    '    rest="${entry#*|}"          # drop target',
    '    sess="${rest%%|*}"          # field 2',
    '    pid="${rest#*|}"            # field 3 (tail: pane ids have no |)',
    '    case "$fmt" in',
    '      *session_name*) echo "$sess" ;;',
    '      *pane_id*) echo "$pid" ;;',
    '      *) echo "$pid" ;;',
    "    esac",
    "    ;;",
    "  switch-client|select-window|select-pane) exit 0 ;;",
    '  *) exit 0 ;;',
    "esac",
    "",
  ].join("\n"),
  "utf8"
);
fs.chmodSync(TMUX_STUB, 0o755);

// Map file the stub reads: "<target>|<session>|<pane_id>" one per line.
const MAP = path.join(ROOT, "map");
function writeMap(entries) {
  fs.writeFileSync(
    MAP,
    Object.keys(entries)
      .map((t) => t + "|" + entries[t].session + "|" + entries[t].pane)
      .join("\n") + "\n",
    "utf8"
  );
}

// Run the jump function in isolation. The script is sourced, so this exercises
// the real shipped code path rather than a copy of it.
function jumpOnce(chosen, map) {
  writeMap(map);
  const driver = path.join(ROOT, "driver.sh");
  fs.writeFileSync(
    driver,
    'source "$1"\n' + 'jump_to_pane "$2"\n',
    "utf8"
  );
  const r = spawnSync("/bin/bash", [driver, SH, chosen], {
    encoding: "utf8",
    env: Object.assign({}, process.env, {
      PATH: BIN + path.delimiter + process.env.PATH,
      TMUX_STUB_LOG: LOG,
      TMUX_STUB_MAP: MAP,
    }),
  });
  const calls = fs.existsSync(LOG) ? fs.readFileSync(LOG, "utf8").split("\n").filter(Boolean) : [];
  fs.writeFileSync(LOG, "");
  return { r, calls };
}

const row = (target, paneId, display) => [target, paneId, display, "/some/path"].join("\t");

test("jump uses the stable pane id, so a renumbered index cannot misroute it", () => {
  // The user clicked the row that was `win:3.1` = %999. While fzf was open the
  // window closed, so `win:3.1` now names %111 -- a different pane. The jump
  // must follow %999, the pane they actually chose.
  const { r, calls } = jumpOnce(row("win:3.1", "%999", "π target"), {
    "%999": { session: "win", pane: "%999" },
    "win:3.1": { session: "win", pane: "%111" },
  });
  assert.equal(r.status, 0, r.stderr);
  const joined = calls.join("\n");
  assert.match(joined, /select-pane -t %999/, joined);
  assert.doesNotMatch(joined, /select-pane -t win:3\.1/, joined);
  assert.doesNotMatch(joined, /%111/, "must not land on the pane the stale index now names");
});

test("jump re-derives the session from the pane id, not from field 1", () => {
  // Field 1's session name is the snapshot's; the pane id is authoritative.
  // A renamed session makes the snapshot name invalid, so derive it live.
  const { r, calls } = jumpOnce(row("old-name:1.1", "%42", "π x"), {
    "%42": { session: "new-name", pane: "%42" },
  });
  assert.equal(r.status, 0, r.stderr);
  assert.match(calls.join("\n"), /switch-client -t new-name/, calls.join("\n"));
});

test("jump reports a pane that no longer exists instead of jumping somewhere wrong", () => {
  const { r } = jumpOnce(row("win:1.1", "%000", "π gone"), {});
  assert.notEqual(r.status, 0, "a vanished pane must not exit 0 as if the jump worked");
  assert.match(r.stderr + r.stdout, /no longer exists|can't find pane/i, r.stderr + r.stdout);
});
