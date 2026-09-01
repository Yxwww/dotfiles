#!/usr/bin/env node
// fzf picker for pi coding-agent panes: list (rows) + preview (status card).
//
// Usage:
//   node tmux-choose-pi.js list          -> one TAB row per π pane
//   node tmux-choose-pi.js preview <id>  -> status card for a pane
//
// Transcript format: newline-delimited JSON events. Relevant types:
//   message      (role user|assistant|toolResult|tool; assistant content is
//                 blocks of thinking|text|toolCall)
//   custom obs-turn (data: inputTokens/outputTokens/cost/tps/model/durationMs)
//   model_change  (modelId)
// Every event carries a `timestamp` (ISO string or epoch millis).

"use strict";

const { spawnSync, execFile } = require("child_process");
const fs = require("fs");
const os = require("os");
const path = require("path");

const HOME = os.homedir();
const SESSIONS = path.join(HOME, ".pi", "agent", "sessions");

const BOLD = "\x1b[1m";
const DIM = "\x1b[2m";
const RED = "\x1b[31m";
const GREEN = "\x1b[32m";
const YELLOW = "\x1b[33m";
const GRAY = "\x1b[90m";
const RESET = "\x1b[0m";

const STALE_AFTER_SEC = 30 * 60; // idle -> stale threshold

// fzf (and shell pipelines) may close the pipe mid-write; exit quietly rather
// than throwing an unhandled EPIPE.
process.stdout.on("error", () => process.exit(0));

// ---------------------------------------------------------------------------
// tmux / process helpers (reused from the previous preview script)
// ---------------------------------------------------------------------------

// Pane probing is dominated by fork/exec, not by work: the original spent 94%
// of `list` inside spawnSync (14x `ps -axo`, 13x `tmux display-message`, 14x
// `git`). fzf re-runs `preview` on every cursor move, so spawns there are paid
// interactively. Budget: one `display-message` per pane, and no `ps` at all.
//
// Field order is deliberate. `pane_current_path` goes last so a literal TAB in
// a directory name can only overflow into the final field, which is rejoined
// below; tmux strips control characters from `pane_title`, so the title cannot
// shift the split.
const PANE_FMT = ["#{pane_title}", "#{pane_current_path}"].join("\t");

// All pane fields we need, in a single display-message.
function paneInfo(paneId) {
  const r = spawnSync(
    "tmux",
    ["display-message", "-p", "-t", paneId, PANE_FMT],
    { encoding: "utf8" }
  );
  // A dead pane exits 0 with empty stdout, so gate on the payload, not status.
  const out = r.error || r.status !== 0 ? "" : r.stdout.replace(/\n$/, "");
  if (!out) return { title: "", path: "" };
  const f = out.split("\t");
  return { title: f[0] || "", path: f.slice(1).join("\t") };
}

// ---------------------------------------------------------------------------
// transcript lookup
// ---------------------------------------------------------------------------
//
// pi exports PI_SESSION_FILE, but nothing outside the process can read it: pi
// rewrites its own argv, which pushes the env region out of reach of `ps eww`
// (verified: 0 of every live pi process exposes it). The old process-tree walk
// cost ~84ms per `list` and ~23ms per `preview` and always returned null, so it
// is deleted rather than merely cached.
//
// KNOWN GAP: panes sharing a cwd resolve to the same transcript -- whichever
// file that directory wrote last. Nothing on the tmux side carries a pane ->
// session id: the `session` event holds only cwd/id/timestamp/version, pi owns
// the pane title, and lsof shows pi does not keep the transcript open. Closing
// this needs pi to publish an os-pid -> session-file pointer.
//
// mtime, not the ISO filename prefix, picks the file: a resumed session appends
// to an old file, so its name sorts stale while it is the live transcript.
function transcriptFor(cwd) {
  if (!cwd) return "";
  const slug = "--" + cwd.replace(/^\/+|\/+$/g, "").replace(/\//g, "-") + "--";
  const dir = path.join(SESSIONS, slug);
  let names;
  try {
    names = fs.readdirSync(dir);
  } catch (e) {
    return "";
  }
  let best = "";
  let bestMs = -1;
  for (const n of names) {
    if (!n.endsWith(".jsonl")) continue;
    const full = path.join(dir, n);
    let st;
    try {
      st = fs.statSync(full);
    } catch (e) {
      continue;
    }
    if (st.mtimeMs > bestMs) {
      bestMs = st.mtimeMs;
      best = full;
    }
  }
  return best;
}

// ---------------------------------------------------------------------------
// small formatting helpers
// ---------------------------------------------------------------------------

function parseTs(v) {
  if (v == null) return 0;
  if (typeof v === "number") return v; // epoch millis
  const t = Date.parse(v);
  return isNaN(t) ? 0 : t;
}

function clip(s, n) {
  s = (s || "").replace(/\s+/g, " ").trim();
  return s.length <= n ? s : s.slice(0, n) + "…";
}

function stripAnsi(s) {
  return s.replace(/\x1b\[[0-9;]*m/g, "");
}

function padRight(s, w) {
  return s + " ".repeat(Math.max(0, w - stripAnsi(s).length));
}
function padLeft(s, w) {
  return " ".repeat(Math.max(0, w - stripAnsi(s).length)) + s;
}

function shortModel(id) {
  if (!id) return null;
  const i = id.lastIndexOf("/");
  return i >= 0 ? id.slice(i + 1) : id;
}

function humanizeAge(sec) {
  if (sec == null || !isFinite(sec)) return "—";
  if (sec < 2) return "now";
  if (sec < 60) return sec + "s";
  if (sec < 3600) return Math.floor(sec / 60) + "m";
  return Math.floor(sec / 3600) + "h";
}

function mmss(ms) {
  const s = Math.max(0, Math.floor(ms / 1000));
  return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
}

function cleanTitle(title) {
  let t = title || "";
  t = t.replace(/^π\s*[-\u2013\u2014:]*\s*/, "");
  t = t.replace(/^pi:\s*/i, "");
  return t || title;
}

// `status --porcelain=v2 --branch` reports the branch header *and* one line per
// dirty entry, so a single fork replaces the old symbolic-ref + status pair.
// Untracked files stay counted so the meaning of ±N is unchanged.
function parseGitStatus(stdout) {
  let branch = "";
  let dirty = 0;
  for (const line of stdout.split("\n")) {
    if (!line) continue;
    if (line[0] === "#") {
      if (line.startsWith("# branch.head ")) branch = line.slice(14);
    } else {
      dirty++;
    }
  }
  // "(detached)" is the only sentinel git documents; the old
  // `symbolic-ref --short -q` yielded "" for that state.
  if (branch === "(detached)" || branch === "(unknown)") branch = "";
  return { branch, dirty };
}

// path -> info, shared by `list` and `preview`. Several pi panes usually sit in
// one repo; probing per pane made git cost scale with pane count instead of
// repo count. Also couples the two callers' answers, which is the point: they
// must agree within a single picker invocation.
const _gitCache = new Map();

function gitInfo(p) {
  const hit = _gitCache.get(p);
  if (hit) return hit;
  const info = probeGit(p);
  _gitCache.set(p, info);
  return info;
}

function probeGit(p) {
  const r = spawnSync("git", ["-C", p, "status", "--porcelain=v2", "--branch"], {
    encoding: "utf8",
  });
  if (!r.error && r.status === 0) return parseGitStatus(r.stdout);
  // `status` refuses to run outside a work tree (a bare repo pane, say) but the
  // branch ref is still meaningful there. Recovering it with the one call that
  // does succeed keeps branch off `status`' success; costs a second fork only
  // in that rare case, never in the common path.
  const b = spawnSync("git", ["-C", p, "symbolic-ref", "--short", "-q", "HEAD"], {
    encoding: "utf8",
  });
  return { branch: b.status === 0 ? b.stdout.trim() : "", dirty: 0 };
}

// Same probe, concurrent. `list` wants every repo at once, and serialising N
// independent `git status` calls was ~65% of its runtime.
function gitInfoAsync(p) {
  const hit = _gitCache.get(p);
  if (hit) return Promise.resolve(hit);
  return new Promise((resolve) => {
    const finish = (info) => {
      _gitCache.set(p, info);
      resolve(info);
    };
    execFile(
      "git",
      ["-C", p, "status", "--porcelain=v2", "--branch"],
      { encoding: "utf8", maxBuffer: 32 << 20 },
      (err, stdout) => {
        if (!err) return finish(parseGitStatus(stdout));
        execFile(
          "git",
          ["-C", p, "symbolic-ref", "--short", "-q", "HEAD"],
          { encoding: "utf8" },
          (e2, out2) =>
            finish(e2 ? { branch: "", dirty: 0 } : { branch: out2.trim(), dirty: 0 })
        );
      }
    );
  });
}

// One-line summary of a tool call's arguments for the card's "running:" line.
function briefArg(tool) {
  const a = tool.args || {};
  if (a.path) return a.path;
  if (a.command) return clip(a.command, 120);
  if (a.action) return a.action;
  if (a.name) return a.name;
  const s = JSON.stringify(a);
  return s === "{}" ? "" : clip(s, 80);
}

// ---------------------------------------------------------------------------
// transcript analysis
// ---------------------------------------------------------------------------

function emptyAnalysis() {
  return {
    users: [],
    assists: [],
    subagents: [],
    openTools: [],
    model: null,
    lastRole: null,
    lastEventTs: 0,
    lastUserTs: 0,
    cumCost: 0,
    sawObsTurn: false,
    lastObs: null,
    lastResultError: false,
    lastResultText: "",
    runningTool: null,
  };
}

// Parse a transcript into a shared status object (used by both list & preview).
function analyzeTranscript(content) {
  const a = emptyAnalysis();

  for (const line of content.split("\n")) {
    const t = line.trim();
    if (!t) continue;
    let d;
    try {
      d = JSON.parse(t);
    } catch (e) {
      continue;
    }

    const ts = parseTs(d.timestamp);
    if (ts) a.lastEventTs = ts;

    if (d.type === "model_change") {
      if (d.modelId) a.model = d.modelId;
    } else if (d.type === "custom" && d.customType === "obs-turn") {
      const data = d.data || {};
      a.lastObs = data;
      a.sawObsTurn = true;
      if (data.model) a.model = data.model;
      if (typeof data.cost === "number") a.cumCost += data.cost;
    } else if (d.type === "message") {
      const m = d.message || {};
      const role = m.role;
      if (role) a.lastRole = role;
      const content = m.content || [];

      if (role === "user") {
        if (ts) a.lastUserTs = ts;
        for (const c of content) {
          if (c && c.type === "text" && c.text && c.text.trim()) {
            a.users.push(c.text.replace(/^\s*<file\b[^>]*>\s*/, "").trim());
          }
        }
      } else if (role === "assistant") {
        let txt = "";
        for (const c of content) {
          if (!c) continue;
          if (c.type === "text") txt += c.text || "";
          else if (c.type === "toolCall") {
            a.openTools.push({ id: c.id, name: c.name, args: c.arguments || {} });
            if (c.name === "subagent") {
              const args = c.arguments || {};
              const label = args.name || args.action || args.agent || "subagent";
              if (!a.subagents.includes(label)) a.subagents.push(label);
            }
          }
        }
        txt = txt.trim();
        if (txt) a.assists.push(txt);
      } else if (role === "toolResult" || role === "tool") {
        if (m.toolCallId) {
          for (let i = a.openTools.length - 1; i >= 0; i--) {
            if (a.openTools[i].id === m.toolCallId) {
              a.openTools.splice(i, 1);
              break;
            }
          }
        }
        let text = "";
        for (const c of content) {
          if (c && c.type === "text" && c.text) text += c.text + "\n";
        }
        if (text.trim()) a.lastResultText = text;
        // `isError` is the authoritative flag on tool-result messages.
        // Assign (not OR) so only the most recent result's state survives.
        a.lastResultError = m.isError === true;
      }
    }
  }

  a.runningTool = a.openTools.length ? a.openTools[a.openTools.length - 1] : null;
  return a;
}

function computeStatus(a, now) {
  const ageSec = a.lastEventTs ? Math.max(0, (now - a.lastEventTs) / 1000) : Infinity;
  if (ageSec < 5) return "working"; // just emitted an event
  const active = ageSec < STALE_AFTER_SEC;
  if (active && (a.openTools.length || a.lastRole === "user")) return "working";
  if (active && a.lastResultError) return "error";
  if (!active) return "stale";
  return "idle";
}

function statusDot(status) {
  switch (status) {
    case "idle":
      return GREEN + "●" + RESET;
    case "working":
      return YELLOW + "◐" + RESET;
    case "error":
      return RED + "✖" + RESET;
    default:
      return GRAY + "○" + RESET;
  }
}

function statusColor(status) {
  switch (status) {
    case "idle":
      return GREEN;
    case "working":
      return YELLOW;
    case "error":
      return RED;
    default:
      return GRAY;
  }
}

function turnElapsed(a, nowMs) {
  if (a.lastUserTs) return nowMs - a.lastUserTs;
  if (a.lastObs && a.lastObs.durationMs) return a.lastObs.durationMs;
  return 0;
}

// ---------------------------------------------------------------------------
// list subcommand
// ---------------------------------------------------------------------------

function listPanes() {
  const r = spawnSync(
    "tmux",
    [
      "list-panes",
      "-a",
      "-F",
      "#{session_name}:#{window_index}.#{pane_index}\t#{pane_id}\t#{pane_title}\t#{pane_current_path}",
    ],
    { encoding: "utf8" }
  );
  if (r.status !== 0) return [];
  const out = [];
  let malformed = 0;
  for (const line of r.stdout.split("\n")) {
    if (!line.trim()) continue;
    const f = line.split("\t");
    // path is the last field and the tail is rejoined, so a TAB in a directory
    // name overflows into it instead of shifting every column after it.
    if (f.length < 4) {
      malformed++;
      continue;
    }
    const title = f[2];
    if (!/^(π|pi:)/.test(title)) continue;
    out.push({ target: f[0], paneId: f[1], title, path: f.slice(3).join("\t") });
  }
  // A newline in a directory name splits a row into fragments. Warn loudly
  // rather than let a pane vanish from the picker in silence.
  if (malformed) {
    process.stderr.write(
      "tmux-choose-pi: skipped " + malformed + " malformed pane row(s)\n"
    );
  }
  return out;
}

function buildRow(pane) {
  const sf = transcriptFor(pane.path);
  let content = "";
  if (sf) {
    try {
      content = fs.readFileSync(sf, "utf8");
    } catch (e) {}
  }
  const a = content ? analyzeTranscript(content) : emptyAnalysis();
  const now = Date.now();
  const status = computeStatus(a, now);
  const ageSec = a.lastEventTs ? Math.max(0, (now - a.lastEventTs) / 1000) : Infinity;

  const g = pane.path ? gitInfo(pane.path) : { branch: "", dirty: 0 };
  const branch = g.branch;
  const dirty = g.dirty;

  // column 1: title · branch±dirty
  let label = cleanTitle(pane.title);
  if (branch) label += " · " + branch + (dirty > 0 ? "±" + dirty : "");

  const model = shortModel(a.model) || "—";
  const tool = status === "working" && a.runningTool ? a.runningTool.name : "—";
  const elapsed =
    status === "working" ? mmss(turnElapsed(a, now)) : humanizeAge(ageSec);
  const cost = a.sawObsTurn ? "$" + a.cumCost.toFixed(4) : "—";

  const dot = statusDot(status);
  const col1 = padRight(label, 32);
  const col2 = padRight(model, 16);
  const col3 = padRight(tool, 18);
  const col4 = padLeft(elapsed, 8);
  const col5 = padLeft(cost, 11);

  const row = `${dot} ${col1}  ${col2}  ${col3}  ${col4}  ${col5}`;
  // Field 4 (path) is TERMINAL: it may contain literal TABs, so nothing
  // downstream may index past field 3. The wrapper reads field 1 (jump target)
  // and fzf reads {2} (pane id) -- both stay correct with tabs in the path.
  return [pane.target, pane.paneId, row, pane.path].join("\t");
}

function listCommand() {
  const panes = listPanes();
  // Probe every distinct repo at once, then build rows off the cache so no pane
  // forks git. Set keeps duplicate-cwd panes from racing the same probe.
  const paths = new Set();
  for (const pane of panes) {
    if (pane.path) paths.add(pane.path);
  }
  return Promise.all(Array.from(paths, gitInfoAsync)).then(() => {
    for (const pane of panes) process.stdout.write(buildRow(pane) + "\n");
  });
}

// ---------------------------------------------------------------------------
// preview subcommand
// ---------------------------------------------------------------------------

function renderCard(paneId) {
  const info = paneInfo(paneId);
  const title = info.title;
  const cwd = info.path;
  const branch = cwd ? gitInfo(cwd).branch : "";
  const sf = transcriptFor(cwd);

  if (!sf) {
    process.stdout.write(BOLD + cleanTitle(title) + RESET + "\n");
    process.stdout.write(DIM + "(no session transcript — pane capture)" + RESET + "\n\n");
    // stderr suppressed: for a pane that just died tmux prints "can't find
    // pane" straight into the fzf preview window.
    spawnSync("tmux", ["capture-pane", "-p", "-t", paneId], {
      stdio: ["ignore", "inherit", "ignore"],
    });
    return;
  }

  let content;
  try {
    content = fs.readFileSync(sf, "utf8");
  } catch (e) {
    process.stdout.write(BOLD + cleanTitle(title) + RESET + "\n");
    process.stdout.write(DIM + "(unreadable transcript)" + RESET + "\n");
    return;
  }

  const a = content ? analyzeTranscript(content) : emptyAnalysis();
  const now = Date.now();
  const status = computeStatus(a, now);
  const ageSec = a.lastEventTs ? Math.max(0, (now - a.lastEventTs) / 1000) : Infinity;

  const out = [];

  // header
  out.push(BOLD + cleanTitle(title) + RESET + (branch ? " (" + branch + ")" : ""));
  out.push(DIM + cwd + RESET);
  out.push("");

  // meta
  out.push(
    DIM + "model" + RESET + ": " + (shortModel(a.model) || "—") +
      "   " + DIM + "status" + RESET + ": " + statusColor(status) + status + RESET +
      "   " + DIM + "activity" + RESET + ": " +
      (status === "working" ? mmss(turnElapsed(a, now)) : humanizeAge(ageSec))
  );

  // running tool
  if (status === "working" && a.runningTool) {
    const arg = briefArg(a.runningTool);
    out.push(
      DIM + "running" + RESET + ": " + YELLOW + a.runningTool.name + RESET +
        (arg ? " " + arg : "")
    );
    out.push(DIM + "turn" + RESET + ": " + mmss(turnElapsed(a, now)));
  }

  // tokens / cost / tps
  if (a.lastObs) {
    const o = a.lastObs;
    const tok = (o.inputTokens || 0) + "/" + (o.outputTokens || 0);
    const cost = typeof o.cost === "number" ? "$" + o.cost.toFixed(4) : "—";
    const tps = o.tps != null && !isNaN(o.tps) ? Number(o.tps).toFixed(1) : "—";
    out.push(
      DIM + "tokens" + RESET + ": " + tok +
        "   " + DIM + "cost" + RESET + ": " + cost +
        "   " + DIM + "tps" + RESET + ": " + tps
    );
  }

  // error flag
  if (status === "error" && a.lastResultText) {
    out.push("");
    out.push(RED + "last result" + RESET + ": " + clip(a.lastResultText, 180));
  }

  // recent asks
  out.push("");
  out.push(DIM + "recent asks" + RESET + ":");
  if (a.users.length) {
    for (const u of a.users.slice(-3)) out.push("  ❯ " + clip(u, 110));
  } else {
    out.push("  (none)");
  }

  // last reply
  out.push("");
  out.push(DIM + "last reply" + RESET + ":");
  out.push(a.assists.length ? "  " + clip(a.assists[a.assists.length - 1], 180) : "  (none yet)");

  // subagents
  if (a.subagents.length) {
    out.push("");
    out.push(DIM + "subagents" + RESET + ": " + a.subagents.join(", "));
  }

  process.stdout.write(out.join("\n") + "\n");
}

function previewCommand(paneId) {
  if (!paneId) return;
  renderCard(paneId);
}

// ---------------------------------------------------------------------------

const cmd = process.argv[2];
if (cmd === "list") {
  listCommand().catch((e) => {
    process.stderr.write(
      "tmux-choose-pi: " + (e && e.message ? e.message : e) + "\n"
    );
    process.exit(1);
  });
} else if (cmd === "preview") {
  previewCommand(process.argv[3]);
}