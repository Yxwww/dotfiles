#!/usr/bin/env node
// Render a status card for a pi agent pane (fzf preview).
//
// Usage: tmux-choose-pi-preview.js <pane_id>
//
// Resolves the pane's session transcript (via the running process's
// PI_SESSION_FILE, falling back to the newest session file in the pane's cwd)
// and renders: model, idle/working status, recent user asks, and the last reply.

"use strict";

const { spawnSync } = require("child_process");
const fs = require("fs");
const os = require("os");
const path = require("path");

const HOME = os.homedir();
const SESSIONS = path.join(HOME, ".pi", "agent", "sessions");

const BOLD = "\x1b[1m";
const DIM = "\x1b[2m";
const YELLOW = "\x1b[33m";
const GREEN = "\x1b[32m";
const RESET = "\x1b[0m";

function tmux(pane, fmt) {
  const r = spawnSync("tmux", ["display-message", "-p", "-t", pane, fmt], {
    encoding: "utf8",
  });
  if (r.error || r.status !== 0) return "";
  return r.stdout.trim();
}

// Read PI_* vars from a process's environment via `ps eww`.
function envOf(pid) {
  const r = spawnSync("ps", ["eww", "-p", String(pid)], { encoding: "utf8" });
  if (r.error || r.status !== 0) return {};
  const out = r.stdout;
  const env = {};
  for (const tok of out.replace(/\n/g, " ").split(/\s+/)) {
    if (tok.startsWith("PI_") && tok.includes("=")) {
      const idx = tok.indexOf("=");
      env[tok.slice(0, idx)] = tok.slice(idx + 1);
    }
  }
  return env;
}

function childPids(pid) {
  // macOS `pgrep` has no -P (parent) flag (that's a Linux/procps option);
  // list all procs via ps and filter on ppid instead.
  const r = spawnSync("ps", ["-axo", "pid=,ppid="], { encoding: "utf8" });
  if (r.error || r.status !== 0) return [];
  const out = [];
  for (const line of r.stdout.split("\n")) {
    const parts = line.trim().split(/\s+/);
    if (parts.length === 2 && parts[1] === String(pid)) {
      out.push(parseInt(parts[0], 10));
    }
  }
  return out;
}

// Walk the process tree under `pid` for the first PI_SESSION_FILE.
function findSession(pid, depth = 0) {
  if (depth > 8) return null;
  const sf = envOf(pid).PI_SESSION_FILE;
  if (sf) return sf;
  for (const c of childPids(pid)) {
    const r = findSession(c, depth + 1);
    if (r) return r;
  }
  return null;
}

function resolveSession(pane) {
  const ppid = tmux(pane, "#{pane_pid}");
  if (/^\d+$/.test(ppid)) {
    const sf = findSession(parseInt(ppid, 10));
    if (sf) return sf;
  }
  // Fallback: newest transcript in the pane cwd's slug dir.
  const cwd = tmux(pane, "#{pane_current_path}");
  const slug = "--" + cwd.replace(/^\/+|\/+$/g, "").replace(/\//g, "-") + "--";
  let files;
  try {
    files = fs
      .readdirSync(path.join(SESSIONS, slug))
      .filter((f) => f.endsWith(".jsonl"))
      .map((f) => path.join(SESSIONS, slug, f))
      .sort((a, b) => fs.statSync(b).mtimeMs - fs.statSync(a).mtimeMs);
  } catch (e) {
    files = [];
  }
  return files.length ? files[0] : "";
}

function clip(s, n) {
  s = s.split(/\s+/).filter(Boolean).join(" ");
  return s.length <= n ? s : s.slice(0, n) + "…";
}

function render(pane) {
  const title = tmux(pane, "#{pane_title}");
  const sf = resolveSession(pane);

  if (!sf) {
    process.stdout.write(BOLD + title + RESET + "\n");
    process.stdout.write(DIM + "(no session transcript — pane capture)" + RESET + "\n\n");
    spawnSync("tmux", ["capture-pane", "-p", "-t", pane], { stdio: "inherit" });
    return;
  }

  let content;
  try {
    content = fs.readFileSync(sf, "utf8");
  } catch (e) {
    process.stdout.write(BOLD + title + RESET + "\n" + DIM + "(unreadable transcript)" + RESET + "\n");
    return;
  }

  const users = [];
  const assists = [];
  let model = null;
  let lastRole = null;

  for (const line of content.split("\n")) {
    const trimmed = line.trim();
    if (!trimmed) continue;
    let d;
    try {
      d = JSON.parse(trimmed);
    } catch (e) {
      continue;
    }
    const t = d.type;
    if (t === "message") {
      const m = d.message || {};
      const role = m.role;
      let txt = "";
      for (const c of m.content || []) {
        if (c.type === "text") txt += c.text || "";
      }
      txt = txt.trim();
      if (role === "user") {
        if (txt) users.push(txt);
      } else if (role === "assistant") {
        if (txt) assists.push(txt);
      }
      if (role) lastRole = role;
    } else if (t === "model_change") {
      model = d.modelId;
    }
  }

  const age = Math.floor(Date.now() / 1000 - fs.statSync(sf).mtimeMs / 1000);
  let status, color;
  if (lastRole === "user" || age < 5) {
    status = "working";
    color = YELLOW;
  } else if (lastRole === "assistant") {
    status = "idle";
    color = GREEN;
  } else {
    status = "—";
    color = DIM;
  }
  const ago = age < 5 ? "just now" : age < 120 ? age + "s ago" : Math.floor(age / 60) + "m ago";

  const out = [];
  out.push(BOLD + title + RESET);
  out.push(
    DIM + "model" + RESET + ": " + (model || "—") + "   " +
    DIM + "status" + RESET + ": " + color + status + RESET + "   " +
    DIM + "activity" + RESET + ": " + ago
  );
  out.push("");
  out.push(DIM + "recent user asks" + RESET + ":");
  if (users.length) {
    for (const u of users.slice(-3)) out.push("  ❯ " + clip(u, 110));
  } else {
    out.push("  (none)");
  }
  out.push("");
  out.push(DIM + "last reply" + RESET + ":");
  out.push(assists.length ? "  " + clip(assists[assists.length - 1], 180) : "  (none yet)");
  process.stdout.write(out.join("\n") + "\n");
}

if (process.argv.length < 3) {
  process.exit(0);
}
render(process.argv[2]);