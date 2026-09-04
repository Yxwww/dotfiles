"use strict";

// I/O-facing tests for tmux-choose-pi.js: the invariants the startup-perf
// rewrite rests on (one display-message per pane, one git probe per repo,
// mtime-based transcript resolution, and the TAB field contract that lets a
// literal TAB live in the last column without shifting the columns before it).
//
// HERMETIC: a stub `tmux` is first on PATH for the whole process, so no test
// can ever reach the developer's real tmux server. Session/git fixtures live
// under a throwaway mkdtemp dir, and HOME is pointed at them per subprocess.

const { test, after, beforeEach } = require("node:test");
const assert = require("node:assert/strict");
const { spawnSync } = require("node:child_process");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");

const SCRIPT = path.join(__dirname, "tmux-choose-pi.js");
const NODE = process.execPath;

// --------------------------------------------------------------------------
// fixture tree
// --------------------------------------------------------------------------

const ROOT = fs.mkdtempSync(path.join(os.tmpdir(), "tmux-choose-pi-io-"));
const BIN = path.join(ROOT, "bin");
const CANS = path.join(ROOT, "cans");
const EMPTY_HOME = path.join(ROOT, "empty-home"); // no ~/.pi/agent/sessions
const FIX_HOME = path.join(ROOT, "fake-home"); //   ~/.pi/agent/sessions fixtures
const SESS = path.join(FIX_HOME, ".pi", "agent", "sessions");
const REPOS = path.join(ROOT, "repos");
const TABDIR = path.join(REPOS, "we\tird"); // literal TAB in a directory name

for (const d of [BIN, CANS, EMPTY_HOME, SESS, REPOS]) fs.mkdirSync(d, { recursive: true });

// Neutralise the developer's git config so `init -b main` and commit output are
// ours to control, and drop any inherited repo-binding vars.
const EMPTY_CFG = path.join(ROOT, "empty.gitconfig");
fs.writeFileSync(EMPTY_CFG, "");
delete process.env.GIT_DIR;
delete process.env.GIT_WORK_TREE;
delete process.env.GIT_INDEX_FILE;
process.env.GIT_CONFIG_NOSYSTEM = "1";
process.env.GIT_CONFIG_GLOBAL = EMPTY_CFG;
process.env.GIT_CONFIG_SYSTEM = EMPTY_CFG;

// Stub tmux. Canned payloads come from files (a 3000-row list is too big for
// an env var). Anything unrecognised fails loudly instead of silently falling
// through to a real tmux.
const TMUX_STUB = path.join(BIN, "tmux");
fs.writeFileSync(
  TMUX_STUB,
  [
    "#!/bin/sh",
    'case "$1" in',
    '  list-panes) cat "${TMUX_STUB_LIST:-/dev/null}" ;;',
    "  display-message)",
    '    if [ -n "${TMUX_STUB_MSG:-}" ]; then cat "$TMUX_STUB_MSG"; exit "${TMUX_STUB_MSG_RC:-0}"; fi',
    `    echo "can't find pane: \\$4" >&2; exit 1 ;;`,
    `  capture-pane) echo "can't find pane: \\$4" >&2; exit 1 ;;`,
    '  *) echo "stub-tmux: unexpected args: \\$*" >&2; exit 3 ;;',
    "esac",
    "",
  ].join("\n"),
  "utf8"
);
fs.chmodSync(TMUX_STUB, 0o755);

process.env.PATH = BIN + path.delimiter + process.env.PATH;

const m = require("./tmux-choose-pi.js");

function writeCan(name, rows) {
  const p = path.join(CANS, name);
  fs.writeFileSync(p, rows.join("\n") + "\n", "utf8");
  return p;
}

// Environment for subprocesses: stub PATH first, HOME either bare or aimed at
// the session fixtures.
function cliEnv(extra) {
  return Object.assign({ PATH: process.env.PATH, HOME: EMPTY_HOME }, extra);
}

function runCli(args, extraEnv) {
  return spawnSync(NODE, [SCRIPT].concat(args), {
    encoding: "utf8",
    env: cliEnv(extraEnv),
  });
}

const GIT_ID = ["-c", "user.name=t", "-c", "user.email=t@invalid"];

function git(args, cwd) {
  const r = spawnSync("git", args, { cwd, encoding: "utf8", env: cliEnv() });
  assert.equal(r.status, 0, "git " + args.join(" ") + " -> " + r.stderr);
  return r.stdout;
}

function makeRepo(dir, opts) {
  const o = opts || {};
  fs.mkdirSync(dir, { recursive: true });
  git(o.bare ? ["init", "-q", "--bare", "-b", "main", dir] : ["init", "-q", "-b", "main", dir]);
  if (o.commit) {
    fs.writeFileSync(path.join(dir, "a.txt"), "1\n");
    git(["add", "a.txt"], dir);
    git(GIT_ID.concat(["commit", "-q", "--no-gpg-sign", "-m", "c1"]), dir);
  }
  return dir;
}

// -- repos ------------------------------------------------------------------

const REPO_CLEAN = makeRepo(path.join(REPOS, "clean"), { commit: true });
const REPO_MEMO = makeRepo(path.join(REPOS, "memo"), { commit: true });
const REPO_DIRTY = makeRepo(path.join(REPOS, "dirty"), { commit: true });
fs.appendFileSync(path.join(REPO_DIRTY, "a.txt"), "2\n");
fs.writeFileSync(path.join(REPO_DIRTY, "untracked.txt"), "u\n");
const REPO_BARE = makeRepo(path.join(REPOS, "bare.git"), { bare: true });
const REPO_DETACHED = makeRepo(path.join(REPOS, "detached"), { commit: true });
fs.writeFileSync(path.join(REPO_DETACHED, "b.txt"), "2\n");
git(["add", "b.txt"], REPO_DETACHED);
git(GIT_ID.concat(["commit", "-q", "--no-gpg-sign", "-m", "c2"]), REPO_DETACHED);
git(["checkout", "-q", "HEAD~1"], REPO_DETACHED);
const REPO_TAB = makeRepo(TABDIR, { commit: true });
const NOT_A_REPO = path.join(REPOS, "plain");
fs.mkdirSync(NOT_A_REPO, { recursive: true });

// -- session fixtures -------------------------------------------------------

// files: name -> { content, mtime }
function sessionDir(slug, files) {
  const d = path.join(SESS, slug);
  fs.mkdirSync(d, { recursive: true });
  for (const name of Object.keys(files)) {
    const full = path.join(d, name);
    fs.writeFileSync(full, files[name].content, "utf8");
    if (files[name].mtime) fs.utimesSync(full, files[name].mtime, files[name].mtime);
  }
  return d;
}

const EVENT = '{"type":"message","timestamp":"2024-01-01T00:00:00.000Z"}\n';
const OLD = new Date(Date.UTC(2020, 0, 1));
const MID = new Date(Date.UTC(2022, 0, 1));
const NEW = new Date(Date.UTC(2024, 0, 1));

// Name order and mtime order deliberately disagree: a resumed session appends
// to an OLD filename, so name-sorting would pick the stale file.
const D_MTIME = sessionDir("--Users-me-repo--", {
  "2026-09-01T00-00-00_stale-name.jsonl": { content: EVENT, mtime: OLD },
  "2024-02-02T00-00-00_resumed.jsonl": { content: EVENT, mtime: NEW },
  "2025-01-01T00-00-00_mid.jsonl": { content: EVENT, mtime: MID },
  "zzz-not-a-transcript.txt": { content: "junk", mtime: new Date(Date.UTC(2030, 0, 1)) },
});
const D_SLUG = sessionDir("--a-b--", { "one.jsonl": { content: EVENT, mtime: MID } });
sessionDir("--only-txt--", { "notes.txt": { content: "junk", mtime: NEW } });

// transcriptFor resolves against SESSIONS, captured at module load from
// os.homedir() (which honours $HOME on POSIX) -> probe it in a subprocess with
// HOME=fixture instead of mutating HOME here.
const TRANSCRIPT_HELPER = path.join(ROOT, "transcript-helper.js");
fs.writeFileSync(
  TRANSCRIPT_HELPER,
  "const m = require(process.argv[2]);\n" +
    "const cases = JSON.parse(process.argv[3]);\n" +
    "const out = {};\n" +
    "for (const k of Object.keys(cases)) out[k] = m.transcriptFor(cases[k]);\n" +
    "process.stdout.write(JSON.stringify(out));\n",
  "utf8"
);

// -- canned tmux output -----------------------------------------------------

// Field order matches listPanes' format: target, pane id, title, path.
// A lone TAB line is blank (ignorable), not malformed.
const CAN_MIXED = writeCan("mixed.tsv", [
  "1.0\t%1\tπ dot repo\t" + NOT_A_REPO,
  "1.1\t%2\tpi: colon repo\t" + REPO_CLEAN,
  "1.2\t%3\tzsh\t" + NOT_A_REPO,
  "1.3\t%4\tPixel pane\t" + NOT_A_REPO,
  "\t",
  "garbage-with-no-tabs",
  "2.1\t%6",
  "3.0\t%7\tπ tabbed dir\t" + TABDIR,
]);
const CAN_NONE = writeCan("none.tsv", ["1.0\t%1\tzsh\t" + NOT_A_REPO]);
const CAN_EMPTY = writeCan("empty.tsv", [""]);
const CAN_E2E = writeCan("msg-e2e.tsv", ["π e2e pane\t/e2e/work"]);

// 3000 rows sharing one cwd: big enough to outrun `head`, and the shared path
// keeps the git probe to one fork instead of 3000.
const BIG_ROWS = [];
for (let i = 0; i < 3000; i++) {
  BIG_ROWS.push("1." + i + "\t%" + i + "\tpi: pane " + i + "\t" + NOT_A_REPO);
}
const CAN_BIG = writeCan("big.tsv", BIG_ROWS);

// Control for the EPIPE test: listCommand()'s write loop with no stdout guard.
const EPIPE_CONTROL = path.join(ROOT, "epipe-control.js");
fs.writeFileSync(
  EPIPE_CONTROL,
  'const { spawnSync } = require("child_process");\n' +
    'const r = spawnSync("tmux", ["list-panes", "-a", "-F", "x"], { encoding: "utf8" });\n' +
    'for (const line of r.stdout.split("\\n")) process.stdout.write(line + "\\n");\n',
  "utf8"
);

// preview end-to-end: pane path /e2e/work -> slug --e2e-work--
sessionDir("--e2e-work--", {
  "2026-01-01T00-00-00_e2e.jsonl": {
    content: [
      { type: "session", cwd: "/e2e/work", id: "e2e", version: "1" },
      {
        type: "message",
        timestamp: new Date(Date.now() - 1000).toISOString(),
        message: { role: "user", content: [{ type: "text", text: "the exact ask" }] },
      },
      {
        type: "message",
        timestamp: new Date(Date.now() - 500).toISOString(),
        message: { role: "assistant", content: [{ type: "text", text: "the exact reply" }] },
      },
      {
        type: "custom",
        customType: "obs-turn",
        timestamp: new Date(Date.now() - 500).toISOString(),
        data: { model: "anthropic/sonnet-4-5", inputTokens: 10, outputTokens: 5, cost: 0.001, tps: 42 },
      },
    ]
      .map((e) => JSON.stringify(e))
      .join("\n"),
  },
});

after(() => {
  process.env.PATH = process.env.PATH.slice(BIN.length + 1);
  fs.rmSync(ROOT, { recursive: true, force: true });
});

// The git cache deliberately outlives a call; clear it so cases stay isolated,
// and drop any per-test stub knobs.
beforeEach(() => {
  m._gitCache.clear();
  delete process.env.TMUX_STUB_MSG;
  delete process.env.TMUX_STUB_MSG_RC;
});

// --------------------------------------------------------------------------
// hermeticity
// --------------------------------------------------------------------------

test("stub tmux shadows any real tmux on PATH", () => {
  const r = spawnSync("/bin/sh", ["-c", "command -v tmux"], { encoding: "utf8" });
  assert.equal(r.stdout.trim(), TMUX_STUB);
});

test("require() is silent and runs no subcommand", () => {
  // argv[2] deliberately looks like a subcommand: requiring must never dispatch.
  const r = spawnSync(NODE, ["-e", "require(" + JSON.stringify(SCRIPT) + ")", "x", "list"], {
    encoding: "utf8",
    env: cliEnv({ TMUX_STUB_LIST: CAN_BIG }),
  });
  assert.equal(r.status, 0);
  assert.equal(r.stdout, "");
  assert.equal(r.stderr, "");
});

// --------------------------------------------------------------------------
// one display-message per pane, tabs in the path
// --------------------------------------------------------------------------

test("PANE_FMT keeps pane_current_path last", () => {
  assert.equal(m.PANE_FMT, "#{pane_title}\t#{pane_current_path}");
});

test("paneInfo rejoins a path containing a literal TAB", () => {
  process.env.TMUX_STUB_MSG = writeCan("msg-tab.tsv", ["π x\t" + TABDIR]);
  const info = m.paneInfo("%1");
  assert.equal(info.title, "π x");
  assert.equal(info.path, TABDIR);
});

test("paneInfo on a dead pane yields empty info, no throw", () => {
  process.env.TMUX_STUB_MSG_RC = "1"; // stub: exit 1, nothing on stdout
  assert.deepEqual(m.paneInfo("%99999"), { title: "", path: "" });
});

// --------------------------------------------------------------------------
// transcriptFor
// --------------------------------------------------------------------------

test("transcriptFor: slug, mtime wins over name, non-jsonl ignored", () => {
  const cases = {
    mtimeWins: "/Users/me/repo",
    slugBare: "/a/b",
    slugTrailing: "/a/b/",
    slugDouble: "//a/b//",
    onlyNonJsonl: "/only/txt",
    missingDir: "/no/such/dir",
    emptyCwd: "",
  };
  const r = spawnSync(NODE, [TRANSCRIPT_HELPER, SCRIPT, JSON.stringify(cases)], {
    encoding: "utf8",
    env: cliEnv({ HOME: FIX_HOME }),
  });
  assert.equal(r.status, 0, r.stderr);
  assert.equal(r.stderr, "");
  const got = JSON.parse(r.stdout);

  assert.equal(got.mtimeWins, path.join(D_MTIME, "2024-02-02T00-00-00_resumed.jsonl"));
  // Pin the premise: newest-by-name is a DIFFERENT file, so the line above
  // really is testing mtime and not name order.
  const byName = fs.readdirSync(D_MTIME).filter((n) => n.endsWith(".jsonl")).sort();
  assert.equal(byName[byName.length - 1], "2026-09-01T00-00-00_stale-name.jsonl");

  // leading/trailing slashes stripped, interior "/" -> "-"
  assert.equal(got.slugBare, path.join(D_SLUG, "one.jsonl"));
  assert.equal(got.slugTrailing, path.join(D_SLUG, "one.jsonl"));
  assert.equal(got.slugDouble, path.join(D_SLUG, "one.jsonl"));

  // the .jsonl filter holds even when the non-jsonl file is newest on disk
  assert.equal(got.onlyNonJsonl, "");
  assert.equal(got.missingDir, "");
  assert.equal(got.emptyCwd, "");
});

// --------------------------------------------------------------------------
// gitInfo / gitInfoAsync
// --------------------------------------------------------------------------

test("gitInfo: branch and dirty count", () => {
  assert.deepEqual(m.gitInfo(REPO_CLEAN), { branch: "main", dirty: 0 });
  assert.deepEqual(m.gitInfo(REPO_DIRTY), { branch: "main", dirty: 2 });
  assert.deepEqual(m.gitInfo(REPO_TAB), { branch: "main", dirty: 0 });
});

test("gitInfo: bare repo falls back to symbolic-ref and keeps the branch", () => {
  // `git status` exits 128 here; branch must not ride on status' success.
  assert.deepEqual(m.gitInfo(REPO_BARE), { branch: "main", dirty: 0 });
});

test("gitInfo: detached HEAD reports no branch", () => {
  assert.deepEqual(m.gitInfo(REPO_DETACHED), { branch: "", dirty: 0 });
});

test("gitInfo: non-repo dir yields empty info and does not throw", () => {
  assert.deepEqual(m.gitInfo(NOT_A_REPO), { branch: "", dirty: 0 });
});

test("gitInfo: memoised per path, stale after the repo changes", () => {
  const first = m.gitInfo(REPO_MEMO);
  assert.equal(m.gitInfo(REPO_MEMO), first); // same object identity

  fs.writeFileSync(path.join(REPO_MEMO, "new-untracked.txt"), "x\n");
  const again = m.gitInfo(REPO_MEMO);
  assert.equal(again, first);
  assert.deepEqual(again, { branch: "main", dirty: 0 }); // cache, not disk

  m._gitCache.clear();
  assert.deepEqual(m.gitInfo(REPO_MEMO), { branch: "main", dirty: 1 });
});

test("gitInfoAsync agrees with gitInfo", async () => {
  const cases = [REPO_CLEAN, REPO_DIRTY, REPO_BARE, REPO_DETACHED, REPO_TAB, NOT_A_REPO];
  for (const p of cases) {
    m._gitCache.clear();
    const sync = m.gitInfo(p);
    m._gitCache.clear();
    assert.deepEqual(await m.gitInfoAsync(p), sync, p);
  }
});

test("gitInfoAsync fills the cache that buildRow reads", async () => {
  await m.gitInfoAsync(REPO_DIRTY);
  const cached = m._gitCache.get(REPO_DIRTY);
  assert.deepEqual(cached, { branch: "main", dirty: 2 });
  assert.equal(m.gitInfo(REPO_DIRTY), cached); // no second fork off the async probe
});

// --------------------------------------------------------------------------
// listPanes
// --------------------------------------------------------------------------

test("listPanes: only pi panes become rows; blank lines are not malformed", () => {
  process.env.TMUX_STUB_LIST = CAN_MIXED;
  // Capture the malformed-row warning: it goes to stderr, which is the TAP stream.
  const realWrite = process.stderr.write;
  let warned = "";
  process.stderr.write = (s) => {
    warned += s;
    return true;
  };
  let panes;
  try {
    panes = m.listPanes();
  } finally {
    process.stderr.write = realWrite;
  }
  assert.equal(warned, "tmux-choose-pi: skipped 2 malformed pane row(s)\n");
  assert.deepEqual(
    panes.map((p) => [p.target, p.paneId, p.title]),
    [
      ["1.0", "%1", "π dot repo"],
      ["1.1", "%2", "pi: colon repo"],
      ["3.0", "%7", "π tabbed dir"],
    ]
  );
  assert.equal(panes[2].path, TABDIR); // tail rejoined across the TAB
});

test("listPanes: no pi panes -> empty list, no crash", () => {
  process.env.TMUX_STUB_LIST = CAN_NONE;
  assert.deepEqual(m.listPanes(), []);
});

// --------------------------------------------------------------------------
// buildRow: the TAB contract
// --------------------------------------------------------------------------

test("buildRow: TAB-separated fields survive a TAB inside the path", () => {
  const nested = path.join(REPOS, "a\tb\tc"); // two embedded TABs
  fs.mkdirSync(nested, { recursive: true });
  for (const p of [TABDIR, nested]) {
    const line = m.buildRow({ target: "4.2", paneId: "%42", title: "π some repo", path: p });
    const f = line.split("\t");
    // The wrapper jumps on field 0 and fzf reads the pane id from field 1:
    // both must stay put however many TABs the path carries.
    assert.equal(f[0], "4.2");
    assert.equal(f[1], "%42");
    assert.ok(f[2].includes("some repo"), f[2]);
    assert.equal(f.slice(3).join("\t"), p); // path is TERMINAL and exact
  }
});

test("buildRow: branch and dirty count land in the row field, not the path", () => {
  const clean = m.buildRow({ target: "1.0", paneId: "%1", title: "π x", path: REPO_CLEAN });
  const dirty = m.buildRow({ target: "1.0", paneId: "%1", title: "π x", path: REPO_DIRTY });
  assert.ok(clean.split("\t")[2].endsWith(" · main"), clean);
  assert.ok(dirty.split("\t")[2].endsWith(" · main±2"), dirty);
  assert.equal(dirty.split("\t").slice(3).join("\t"), REPO_DIRTY);
});

test("buildRow: no branch -> no separator, path untouched", () => {
  const line = m.buildRow({ target: "9.9", paneId: "%9", title: "pi: bare title", path: NOT_A_REPO });
  const f = line.split("\t");
  assert.ok(!f[2].includes("\u00b7"), f[2]);
  assert.ok(f[2].includes("bare title"), f[2]);
  assert.equal(f.slice(3).join("\t"), NOT_A_REPO);
});

// --------------------------------------------------------------------------
// CLI
// --------------------------------------------------------------------------

test("CLI list: rows, pane ids, and the malformed-row warning", () => {
  const r = runCli(["list"], { TMUX_STUB_LIST: CAN_MIXED });
  assert.equal(r.status, 0, r.stderr);
  const lines = r.stdout.split("\n").filter((l) => l.length);
  assert.equal(lines.length, 3);
  assert.deepEqual(
    lines.map((l) => l.split("\t")[1]),
    ["%1", "%2", "%7"]
  );
  const last = lines[2].split("\t");
  assert.equal(last[0], "3.0");
  assert.equal(last.slice(3).join("\t"), TABDIR);
  // a pane must never vanish silently
  assert.match(r.stderr, /^tmux-choose-pi: skipped 2 malformed pane row\(s\)\n$/);
});

test("CLI list: empty pane list is silent success", () => {
  const r = runCli(["list"], { TMUX_STUB_LIST: CAN_EMPTY });
  assert.equal(r.status, 0, r.stderr);
  assert.equal(r.stdout, "");
  assert.equal(r.stderr, "");
});

// fzf and shell pipelines close the pipe mid-write. `piped` reports node's
// exit status, not the consumer's.
function piped(target, consumer) {
  const cmd =
    "node " +
    [target].concat(target === SCRIPT ? ["list"] : []).map(JSON.stringify).join(" ") +
    " | " +
    consumer +
    " >/dev/null; exit \"${PIPESTATUS[0]}\"";
  return spawnSync("/bin/bash", ["-c", cmd], {
    encoding: "utf8",
    env: cliEnv({ TMUX_STUB_LIST: CAN_BIG }),
    cwd: __dirname,
  });
}

// The control proves this pipeline shape really does spill a stack trace
// without the module's stdout guard, so the next test is not vacuous.
test("control: without the stdout guard the same pipeline dies on EPIPE", () => {
  const r = piped(EPIPE_CONTROL, "head -1");
  assert.match(r.stderr, /EPIPE/);
  assert.match(r.stderr, /\n\s+at /);
  assert.equal(r.status, 1);
});

test("CLI list: early pipe close exits 0 with nothing on stderr", () => {
  for (const consumer of ["head -1", "head -c 1"]) {
    const r = piped(SCRIPT, consumer);
    assert.equal(r.stderr, "", consumer);
    assert.equal(r.status, 0, consumer);
  }
});

test("CLI preview: no arg exits silently", () => {
  const r = runCli(["preview"], { TMUX_STUB_LIST: CAN_MIXED });
  assert.equal(r.status, 0);
  assert.equal(r.stdout, "");
  assert.equal(r.stderr, "");
});

test("CLI preview: nonexistent pane prints no stack trace", () => {
  const r = runCli(["preview", "%99999"], { TMUX_STUB_LIST: CAN_MIXED });
  assert.equal(r.status, 0, r.stderr);
  assert.ok(!/Error/.test(r.stderr), r.stderr);
  assert.ok(!/\n\s+at /.test(r.stderr), r.stderr);
  assert.match(r.stdout, /no session transcript/);
});

test("CLI preview: resolves the transcript via the cwd slug", () => {
  const r = runCli(["preview", "%5"], { HOME: FIX_HOME, TMUX_STUB_MSG: CAN_E2E });
  assert.equal(r.status, 0, r.stderr);
  assert.match(r.stdout, /e2e pane/);
  assert.match(r.stdout, /the exact ask/);
  assert.match(r.stdout, /the exact reply/);
  assert.match(r.stdout, /sonnet-4-5/);
});

test("CLI: unknown subcommand exits 0 quietly", () => {
  const r = runCli(["bogus", "--loud"], { TMUX_STUB_LIST: CAN_BIG });
  assert.equal(r.status, 0);
  assert.equal(r.stdout, "");
  assert.equal(r.stderr, "");
});
