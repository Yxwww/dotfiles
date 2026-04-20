import { $ } from "bun";

export type PortEntry = {
  pid: number;
  command: string;
  user: string;
  port: number;
  protocol: "IPv4" | "IPv6";
  address: string;
  fd: string;
  fullCommand: string;
  script: string;    // extracted dev tool name: "vite", "next", "webpack", etc.
  project: string;   // extracted project directory name
  cwd: string;       // process working directory (from lsof -d cwd)
};

export type ProcessClass = "system" | "user" | "root";

export type KillResult = {
  pid: number;
  success: boolean;
  error?: string;
};

const SYSTEM_COMMANDS = new Set([
  "rapportd",
  "ControlCe",
  "mDNSResponder",
  "launchd",
  "systemd",
  "WindowServer",
  "loginwindow",
  "UserEventAgent",
  "sharingd",
  "bluetoothd",
  "airportd",
]);

export function classifyProcess(entry: PortEntry): ProcessClass {
  if (entry.user === "root") return "root";
  if (SYSTEM_COMMANDS.has(entry.command) || entry.pid < 200) return "system";
  return "user";
}

export async function scanPorts(): Promise<PortEntry[]> {
  try {
    const result = await $`lsof -iTCP -sTCP:LISTEN -P -n`.text();
    const lines = result.split("\n").filter((l) => l.length > 0);

    if (lines.length < 2) return [];

    const entries: PortEntry[] = [];
    const seen = new Set<string>();

    for (let i = 1; i < lines.length; i++) {
      const cols = lines[i].split(/\s+/);
      if (cols.length < 9) continue;

      const command = cols[0];
      const pid = parseInt(cols[1], 10);
      const user = cols[2];
      const fd = cols[3];
      const type = cols[4];
      const name = cols[cols.length - 1] === "(LISTEN)" ? cols[cols.length - 2] : cols[cols.length - 1];

      // Parse address:port from NAME column like "*:5000" or "127.0.0.1:7246" or "[::1]:2004"
      const lastColon = name.lastIndexOf(":");
      if (lastColon === -1) continue;

      const address = name.slice(0, lastColon);
      const port = parseInt(name.slice(lastColon + 1), 10);
      if (isNaN(port) || isNaN(pid)) continue;

      const key = `${pid}:${port}`;
      if (seen.has(key)) continue;
      seen.add(key);

      entries.push({
        pid,
        command,
        user,
        port,
        protocol: type === "IPv6" ? "IPv6" : "IPv4",
        address,
        fd,
        fullCommand: "",
        script: "",
        project: "",
        cwd: "",
      });
    }

    entries.sort((a, b) => a.port - b.port);

    // Enrich with full command lines from ps
    await enrichEntries(entries);
    await enrichCwd(entries);

    return entries;
  } catch {
    return [];
  }
}

const KNOWN_SCRIPTS = [
  "vite", "next", "nuxt", "webpack", "esbuild", "tsx", "ts-node",
  "nodemon", "parcel", "turbo", "astro", "remix", "svelte-kit",
  "angular", "ng", "gatsby", "nest", "express", "fastify", "hono",
];

function parseScript(fullCmd: string): string {
  // Check for node_modules/.bin/<tool> pattern
  const binMatch = fullCmd.match(/node_modules\/\.bin\/(\S+)/);
  if (binMatch) return binMatch[1];

  // Check for known tool names anywhere in the args
  const lower = fullCmd.toLowerCase();
  for (const name of KNOWN_SCRIPTS) {
    if (lower.includes(name)) return name;
  }

  // Check for "bun run <script>" or "npx <script>" patterns
  const runMatch = fullCmd.match(/(?:bun|npx|pnpm|yarn)\s+(?:run\s+)?(\S+)/);
  if (runMatch) return runMatch[1];

  return "";
}

function parseProject(fullCmd: string): string {
  // Find a project-like path — look for the deepest directory before node_modules
  const nmMatch = fullCmd.match(/(\S+)\/node_modules/);
  if (nmMatch) {
    const parts = nmMatch[1].split("/");
    return parts[parts.length - 1];
  }

  // Look for common project paths like /Users/x/git/<project>/
  const projMatch = fullCmd.match(/\/(?:git|src|projects|code|repos|dev|work)\/([^/\s]+)/i);
  if (projMatch) return projMatch[1];

  return "";
}

export function shortenDir(cmd: string, home: string = Bun.env.HOME ?? ""): string {
  if (!home || !cmd) return cmd;
  const len = home.length;
  let result = cmd;
  let offset = 0;
  while (true) {
    const idx = result.indexOf(home, offset);
    if (idx === -1) break;
    const after = idx + len;
    // Boundary check: next char must be '/' or end-of-string
    if (after < result.length && result[after] !== "/") {
      offset = after;
      continue;
    }
    result = result.slice(0, idx) + "~" + result.slice(after);
    offset = idx + 1;
  }
  return result;
}

async function enrichEntries(entries: PortEntry[]): Promise<void> {
  if (entries.length === 0) return;

  const pids = [...new Set(entries.map((e) => e.pid))];

  try {
    const result = await $`ps -o pid=,command= -p ${pids.join(",")}`.text();
    const cmdMap = new Map<number, string>();

    for (const line of result.split("\n")) {
      const trimmed = line.trimStart();
      if (!trimmed) continue;
      const spaceIdx = trimmed.indexOf(" ");
      if (spaceIdx === -1) continue;
      const pid = parseInt(trimmed.slice(0, spaceIdx), 10);
      const cmd = trimmed.slice(spaceIdx + 1).trim();
      if (!isNaN(pid)) cmdMap.set(pid, cmd);
    }

    for (let i = 0; i < entries.length; i++) {
      const full = cmdMap.get(entries[i].pid) ?? "";
      entries[i].fullCommand = full;
      entries[i].script = parseScript(full);
      entries[i].project = parseProject(full);
    }
  } catch {
    // ps failed — leave fields empty
  }
}

async function enrichCwd(entries: PortEntry[]): Promise<void> {
  if (entries.length === 0) return;

  const pids = [...new Set(entries.map((e) => e.pid))];

  try {
    // -Fpn emits field-based output: lines alternate "p<pid>" and "n<path>"
    const result = await $`lsof -a -d cwd -p ${pids.join(",")} -Fpn`.text();
    const cwdMap = new Map<number, string>();
    let curPid = 0;

    for (const line of result.split("\n")) {
      if (!line) continue;
      const tag = line[0];
      const rest = line.slice(1);
      if (tag === "p") {
        const n = parseInt(rest, 10);
        if (!isNaN(n)) curPid = n;
      } else if (tag === "n" && curPid) {
        cwdMap.set(curPid, rest);
      }
    }

    for (let i = 0; i < entries.length; i++) {
      entries[i].cwd = cwdMap.get(entries[i].pid) ?? "";
    }
  } catch {
    // lsof failed — leave cwd empty
  }
}

export function isFromCwd(entry: PortEntry, cwd: string): boolean {
  if (!cwd || !entry.cwd) return false;
  return entry.cwd === cwd || entry.cwd.startsWith(cwd + "/");
}

export function sortCwdFirst<T extends PortEntry>(entries: T[], cwd: string): T[] {
  const sorted = entries.slice();
  sorted.sort((a, b) => {
    const aIn = isFromCwd(a, cwd) ? 0 : 1;
    const bIn = isFromCwd(b, cwd) ? 0 : 1;
    if (aIn !== bIn) return aIn - bIn;
    return a.port - b.port;
  });
  return sorted;
}

export async function openInBrowser(port: number): Promise<{ success: boolean; error?: string }> {
  try {
    await $`open http://localhost:${port}`.quiet();
    return { success: true };
  } catch (e: any) {
    return { success: false, error: String(e.message ?? e).slice(0, 120) };
  }
}

export async function killProcess(
  pid: number,
  signal: number = 15
): Promise<KillResult> {
  try {
    await $`kill -${signal} ${pid}`.quiet();
    return { pid, success: true };
  } catch (e: any) {
    const msg = String(e.stderr ?? e.message ?? e);
    if (msg.includes("Operation not permitted") || msg.includes("EPERM")) {
      return { pid, success: false, error: "Permission denied — try running with sudo" };
    }
    return { pid, success: false, error: msg.slice(0, 120) };
  }
}
