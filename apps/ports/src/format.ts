import { classifyProcess, shortenDir, isFromCwd, type PortEntry } from "./ports";

export type PortRow = {
  name: string;
  description: string;
};

const basename = (p: string): string => p.split("/").pop() ?? p;

/**
 * Display a process cwd, collapsing the git root to just the repo name when the
 * cwd lives inside one (e.g. `/Users/yuxi/git/dotfiles/apps/ports` ->
 * `dotfiles/apps/ports`). Falls back to the home-tilde shortening when there is
 * no git root. Pure: the git root is computed upstream and passed in.
 */
export function displayPath(cwd: string, gitRoot: string, home?: string): string {
  if (!cwd) return "";
  if (gitRoot) {
    if (cwd === gitRoot) return basename(gitRoot);
    if (cwd.startsWith(gitRoot + "/")) {
      return `${basename(gitRoot)}/${cwd.slice(gitRoot.length + 1)}`;
    }
  }
  return shortenDir(cwd, home);
}

/**
 * Format a port entry into the two display strings the TUI renders (name line
 * + optional description line). Compact mode collapses to a single line —
 * empty description and the process cwd short-path folded into the name — so
 * short terminals can fit more ports.
 */
export function formatPortRow(
  entry: PortEntry,
  cwd: string,
  opts: { compact?: boolean; home?: string } = {},
): PortRow {
  const here = isFromCwd(entry, cwd);
  const marker = here ? "● " : "  ";
  const label = entry.script || entry.command.slice(0, 14);

  if (opts.compact) {
    const path = displayPath(entry.cwd, entry.gitRoot, opts.home) || entry.project || "—";
    const name = [
      marker,
      String(entry.port).padEnd(8),
      String(entry.pid).padEnd(8),
      label.slice(0, 12).padEnd(14),
      path,
      here ? " ←" : "",
    ].join("");
    return { name, description: "" };
  }

  const cls = classifyProcess(entry);
  const tag = cls === "root" ? "[root]" : cls === "system" ? "[sys]" : "[usr]";
  const proj = entry.project ? `(${entry.project})` : "";

  const name = [
    marker,
    String(entry.port).padEnd(8),
    String(entry.pid).padEnd(8),
    label.slice(0, 14).padEnd(16),
    proj.slice(0, 22).padEnd(24),
    tag,
    here ? "  ← current dir" : "",
  ].join("");

  const description = entry.fullCommand
    ? `→ ${shortenDir(entry.fullCommand, opts.home).slice(0, 80)}`
    : `${entry.command}  ${entry.address}:${entry.port}`;

  return { name, description };
}