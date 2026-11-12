#!/usr/bin/env node
// ystack installer. See STACK.md — that file is the source of truth, this reads it.
//
// Subcommands:
//   link       symlink origin:dotfiles skills into ~/.agents/skills
//   skills-cli re-add tracked skills-cli skills missing from ~/.agents/skills
//   check      report state, mutate nothing
//   doctor     verify every declared skill resolves; non-zero exit on drift
//
// AGENT_SKILLS_DIR overrides the target (tests use a tmpdir).

import { execFileSync } from "node:child_process";
import {
  existsSync,
  lstatSync,
  mkdirSync,
  readFileSync,
  readlinkSync,
  readdirSync,
  symlinkSync,
  unlinkSync,
} from "node:fs";
import { homedir } from "node:os";
import { join, dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const HERE = dirname(fileURLToPath(import.meta.url));
// scripts/ystack/ -> repo root
const REPO = resolve(HERE, "..", "..");
const STACK = join(REPO, "configs", "pi", "stacks", "ystack");
const MANIFEST = join(STACK, "STACK.md");
const LOCK = join(REPO, "configs", "pi", "agents", "skill-lock.json");

/**
 * Parse the title of every `## ` section in STACK.md, returning
 * { dotfiles: string[], cliInstaller: string[], excluded: string[] }.
 *
 * Manifest format (cold path, runs once per invocation):
 *   ## `origin: dotfiles`        -> a table, first column is the skill name
 *   ## `origin: cli-installer`   -> a table, first column is the skill name
 *   ## `excluded`               -> bullets; names live inside backticks
 *
 * Pure: string in, plain object out. Deliberately not a YAML/TOML dependency —
 * STACK.md must stay readable as documentation and as data.
 */
export function parseManifest(md) {
  const out = { dotfiles: [], cliInstaller: [], excluded: [] };
  let section = null;
  for (const line of md.split("\n")) {
    const h = /^##\s+(.*)$/.exec(line);
    if (h) {
      // Unescape the backticks the heading uses for prose styling.
      const title = h[1].replace(/`/g, "");
      section = title.startsWith("origin: dotfiles")
        ? "dotfiles"
        : title.startsWith("origin: cli-installer")
          ? "cliInstaller"
          : title.startsWith("excluded")
            ? "excluded"
            : null;
      continue;
    }
    if (!section) continue;
    if (section === "excluded") {
      // Bullets only; skip prose. Names are backticked.
      if (!/^\s*-\s/.test(line)) continue;
      for (const m of line.matchAll(/`([a-z0-9][a-z0-9-]*)`/g)) out.excluded.push(m[1]);
      continue;
    }
    // Table row: `| `name` | purpose |` — first cell, skip the header/divider.
    const cells = /^\|\s*(.+?)\s*\|/.exec(line);
    if (!cells) continue;
    const m = /^`([a-z0-9][a-z0-9-]*)`$/.exec(cells[1].trim());
    if (m) out[section].push(m[1]);
  }
  return out;
}

/** Skill names tracked in the skills-CLI lockfile. */
export function parseLock(lock) {
  return Object.keys(lock?.skills ?? {}).sort();
}

/**
 * Decide which `skills` CLI sources to install, and which to refuse.
 *
 * Restoring is all-or-nothing per source: `npx skills add <repo>` installs every
 * skill in that repo. So a source is only safe when none of the names it ships
 * are owned by ystack — otherwise the CLI writes a real directory over the
 * ystack symlink (this clobbered `code-review` once already).
 *
 * Pure: { owned, installed, lock } -> { sources, blocked }.
 */
export function planSkillsCli({ owned, installed, lock }) {
  const present = new Set(installed);
  const ownedSet = new Set(owned);
  const missing = Object.entries(lock?.skills ?? {}).filter(([name, s]) => !present.has(name) && s?.source);

  // source -> every skill name it ships, from the lockfile.
  const bySource = new Map();
  for (const [name, s] of Object.entries(lock?.skills ?? {})) {
    if (!s?.source) continue;
    if (!bySource.has(s.source)) bySource.set(s.source, []);
    bySource.get(s.source).push(name);
  }

  const need = new Set(missing.map(([, s]) => s.source));
  const sources = [];
  const blocked = [];
  for (const src of need) {
    const collides = (bySource.get(src) ?? []).filter((n) => ownedSet.has(n)).sort();
    if (collides.length) blocked.push({ source: src, collides });
    else sources.push(src);
  }
  return { sources, blocked };
}

// ---------------------------------------------------------------------------

function readManifest() {
  if (!existsSync(MANIFEST)) {
    console.error(`missing manifest: ${MANIFEST}`);
    process.exit(1);
  }
  return parseManifest(readFileSync(MANIFEST, "utf-8"));
}

function skillsDir() {
  return process.env.AGENT_SKILLS_DIR ?? join(homedir(), ".agents", "skills");
}

function inspect(name) {
  const link = join(skillsDir(), name);
  const src = join(STACK, "skills", name);
  let st;
  try {
    st = lstatSync(link);
  } catch {
    return { name, link, src, kind: "missing" };
  }
  if (st.isSymbolicLink()) {
    const dest = resolve(dirname(link), readlinkSync(link));
    return { name, link, src, kind: dest === src ? "ok" : "foreign-link", dest };
  }
  return { name, link, src, kind: "dir" };
}

const C = process.stdout.isTTY
  ? { ok: "\x1b[32m", warn: "\x1b[33m", bad: "\x1b[31m", dim: "\x1b[2m", off: "\x1b[0m" }
  : { ok: "", warn: "", bad: "", dim: "", off: "" };

function cmdCheck({ quiet = false } = {}) {
  const m = readManifest();
  const rows = m.dotfiles.map(inspect);
  const cli = m.cliInstaller.map(inspect);
  let drift = 0;
  if (!quiet) console.log(`ystack @ ${STACK}\n`);
  for (const r of rows) {
    const bad = r.kind !== "ok";
    if (bad) drift++;
    if (quiet && !bad) continue;
    const col = r.kind === "ok" ? C.ok : C.warn;
    console.log(`  ${col}${r.kind.padEnd(12)}${C.off} ${r.name}${bad ? `  ${C.dim}${r.link}${C.off}` : ""}`);
  }
  for (const r of cli) {
    if (quiet) continue;
    const present = r.kind !== "missing";
    console.log(`  ${present ? C.ok : C.dim}${(present ? "present" : "absent").padEnd(12)}${C.off} ${r.name} ${C.dim}(cli-installer — restored by its own tool)${C.off}`);
  }
  if (!quiet) console.log(`\n  ${rows.length} dotfiles · ${cli.length} cli-installer · ${m.excluded.length} excluded names`);
  return drift;
}

function cmdLink() {
  const m = readManifest();
  mkdirSync(skillsDir(), { recursive: true });
  let linked = 0;
  let skipped = 0;
  for (const name of m.dotfiles) {
    const r = inspect(name);
    if (!existsSync(r.src)) {
      console.error(`  ${C.bad}MISSING SRC${C.off} ${name} — declared in STACK.md but ${r.src} does not exist`);
      process.exitCode = 1;
      continue;
    }
    if (r.kind === "dir") {
      // The skills CLI or a manual install owns this real directory. Do not
      // clobber it — that loses whatever the other tool put there.
      console.log(`  ${C.warn}SKIP${C.off}   ${name} — real directory exists (remove it to let ystack own this name)`);
      skipped++;
      continue;
    }
    if (r.kind === "foreign-link") {
      // Stale link from an earlier layout. Never do this to a real directory.
      unlinkSync(r.link);
    }
    if (r.kind !== "ok") {
      symlinkSync(r.src, r.link, "dir");
      console.log(`  ${C.ok}LINKED${C.off} ${name}`);
      linked++;
      continue;
    }
    linked++;
  }
  if (skipped) console.error(`\n  ${C.warn}${skipped} skill(s) skipped${C.off} — another tool owns the directory`);
  else console.log(`\n  ${linked} linked`);
  return 0;
}

function cmdSkillsCli() {
  if (!existsSync(LOCK)) {
    console.error(`missing lockfile: ${LOCK}`);
    return 1;
  }
  const lock = JSON.parse(readFileSync(LOCK, "utf-8"));
  const { dotfiles } = readManifest();
  const installed = existsSync(skillsDir()) ? readdirSync(skillsDir()) : [];
  const { sources, blocked } = planSkillsCli({ owned: dotfiles, installed, lock });

  for (const b of blocked) {
    console.error(
      `  ${C.bad}REFUSED${C.off} ${b.source} — its package also ships ${b.collides.join(", ")}, which ystack owns`,
    );
    console.error(`          installing it would overwrite the ystack symlink. Install that source by hand, then re-link.`);
  }
  if (sources.length === 0 && blocked.length === 0) {
    console.log("  all skills-CLI skills present");
    return 0;
  }
  for (const src of sources) {
    console.log(`  adding ${src}`);
    execFileSync("npx", ["-y", "skills@1.5.7", "add", src, "-g", "-y"], { stdio: "inherit" });
  }
  return blocked.length ? 1 : 0;
}

function cmdDoctor() {
  const m = readManifest();
  const problems = [];
  for (const name of m.dotfiles) {
    const r = inspect(name);
    if (!existsSync(r.src)) problems.push(`${name}: source missing at ${r.src}`);
    else if (r.kind === "dir") problems.push(`${name}: real directory shadows ystack (run: rm -rf ${r.link})`);
    else if (r.kind === "missing") problems.push(`${name}: not linked (run: install.mjs link)`);
    else if (r.kind === "foreign-link") problems.push(`${name}: links to ${r.dest}, not the stack`);
  }
  if (problems.length === 0) {
    console.log(`  ${C.ok}ok${C.off} — ${m.dotfiles.length} dotfiles skills resolve, ${m.excluded.length} excluded`);
    return 0;
  }
  for (const p of problems) console.error(`  ${C.bad}drift${C.off} ${p}`);
  return 1;
}

// ---------------------------------------------------------------------------

// Only run the CLI when executed directly, so tests can import the parsers.
const invokedDirectly =
  process.argv[1] && resolve(process.argv[1]) === resolve(fileURLToPath(import.meta.url));

if (invokedDirectly) {
  const [, , cmd = "check"] = process.argv;
  switch (cmd) {
    case "link":
      process.exit(cmdLink());
    case "skills-cli":
      process.exit(cmdSkillsCli());
    case "check":
      process.exit(cmdCheck() ? 1 : 0);
    case "doctor":
      process.exit(cmdDoctor());
    default:
      console.error(`unknown subcommand: ${cmd}\n  link | skills-cli | check | doctor`);
      process.exit(2);
  }
}
