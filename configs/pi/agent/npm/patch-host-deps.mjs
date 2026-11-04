// Upstream pi extension packages in this tree list host-provided runtime modules
// (typebox and friends) in `dependencies`. Installing them makes npm create
// private copies that bypass the extension loader's shared instance, so extensions
// can end up with duplicate module state. Rewrite those entries to
// `peerDependencies: "*"` after every install.
//
// Scans the whole tree rather than a fixed list: several packages nest older
// copies of each other, and every one of them trips the loader's check.
// See pi's HOST_PROVIDED_EXTENSION_PACKAGES set for the canonical list.
import { readdirSync, readFileSync, statSync, writeFileSync } from "node:fs";
import { basename, join } from "node:path";

// postinstall runs with cwd at the install root (~/.pi/agent/npm); the repo
// copy of this file has no node_modules of its own.
const root = join(process.cwd(), "node_modules");

const HOST_PROVIDED = new Set([
  "@earendil-works/pi-agent-core",
  "@earendil-works/pi-ai",
  "@earendil-works/pi-coding-agent",
  "@earendil-works/pi-tui",
  "@mariozechner/pi-agent-core",
  "@mariozechner/pi-ai",
  "@mariozechner/pi-coding-agent",
  "@mariozechner/pi-tui",
  "@sinclair/typebox",
  "typebox",
]);

// Cheap depth cap; real nesting here is shallow.
const MAX_DEPTH = 6;

let manifests = 0;
let patched = 0;

function walk(dir, depth) {
  let entries;
  try {
    entries = readdirSync(dir, { withFileTypes: true });
  } catch {
    return;
  }

  for (const entry of entries) {
    if (!entry.isDirectory()) {
      if (entry.name !== "package.json") continue;
      manifests++;
      patch(join(dir, entry.name));
      continue;
    }
    // Skip .bin symlink farm; nothing installable lives there.
    if (entry.name === ".bin") continue;
    const child = join(dir, entry.name);
    if (depth === 0) {
      // node_modules/<name> → package dir; @scope → one more level.
      walk(child, entry.name.startsWith("@") ? depth : depth + 1);
      continue;
    }
    walk(child, depth + 1);
  }
}

function patch(path) {
  let manifest;
  try {
    manifest = JSON.parse(readFileSync(path, "utf8"));
  } catch {
    return;
  }

  const deps = manifest.dependencies;
  if (!deps || typeof deps !== "object") return;

  const moved = Object.keys(deps).filter((name) => HOST_PROVIDED.has(name));
  if (moved.length === 0) return;

  for (const name of moved) delete deps[name];
  manifest.peerDependencies ??= {};
  for (const name of moved) manifest.peerDependencies[name] = "*";

  writeFileSync(path, `${JSON.stringify(manifest, null, 2)}\n`);
  console.log(
    `[patch-host-deps] ${path.slice(root.length + 1)}: ${moved.join(", ")} -> peerDependencies`,
  );
  patched++;
}

if (statSync(join(process.cwd(), "node_modules"), { throwIfNoEntry: false })) {
  // node_modules/<pkg> lives one level below the flat dir; scoped packages are
  // handled inside walk via the @scope branch.
  for (const entry of readdirSync(root, { withFileTypes: true })) {
    if (!entry.isDirectory() || entry.name === ".bin") continue;
    if (entry.name.startsWith("@")) {
      for (const scoped of readdirSync(join(root, entry.name), { withFileTypes: true })) {
        if (!scoped.isDirectory()) continue;
        walk(join(root, entry.name, scoped.name), 1);
      }
      continue;
    }
    walk(join(root, entry.name), 1);
  }
}

console.log(`[patch-host-deps] scanned ${manifests} manifests, patched ${patched}`);
if (patched === 0) console.log("[patch-host-deps] nothing to move");
