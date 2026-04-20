import { scanPorts, classifyProcess, shortenDir, sortCwdFirst, isFromCwd } from "./ports";

const C = {
  reset: "\x1b[0m",
  dim: "\x1b[2m",
  green: "\x1b[32m",
  red: "\x1b[31m",
  blue: "\x1b[34m",
  yellow: "\x1b[33m",
  cyan: "\x1b[36m",
  bold: "\x1b[1m",
} as const;

function colorForClass(cls: string): string {
  if (cls === "root") return C.red;
  if (cls === "system") return C.dim;
  return C.green;
}

export async function snapshot() {
  const raw = await scanPorts();

  if (raw.length === 0) {
    console.log(`${C.dim}No listening ports found (some may require sudo)${C.reset}`);
    process.exit(0);
  }

  const cwd = process.cwd();
  const entries = sortCwdFirst(raw, cwd);

  console.log(`\n${C.dim}Current dir:${C.reset} ${shortenDir(cwd)}`);

  const header = [
    "  ",
    "PORT".padEnd(8),
    "PID".padEnd(8),
    "SCRIPT".padEnd(14),
    "PROJECT".padEnd(20),
    "COMMAND".padEnd(16),
    "ADDRESS".padEnd(16),
  ].join("");

  console.log(`\n${C.bold}${C.blue}${header}${C.reset}`);
  console.log(`${C.dim}${"─".repeat(84)}${C.reset}`);

  let cwdCount = 0;
  for (let i = 0; i < entries.length; i++) {
    const e = entries[i];
    const cls = classifyProcess(e);
    const c = colorForClass(cls);
    const here = isFromCwd(e, cwd);
    if (here) cwdCount++;
    const marker = here ? `${C.cyan}${C.bold}● ${C.reset}` : "  ";
    const script = (e.script || "—").slice(0, 12);
    const project = (e.project || "—").slice(0, 18);
    const row = [
      String(e.port).padEnd(8),
      String(e.pid).padEnd(8),
      script.padEnd(14),
      project.padEnd(20),
      e.command.slice(0, 14).padEnd(16),
      e.address.padEnd(16),
    ].join("");
    const tail = here ? ` ${C.cyan}← current dir${C.reset}` : "";
    console.log(`${marker}${c}${row}${C.reset}${tail}`);

    // Show full command on next line for dev processes
    if (e.fullCommand && cls === "user") {
      console.log(`${C.dim}    → ${shortenDir(e.fullCommand).slice(0, 100)}${C.reset}`);
    }
  }

  const summary = cwdCount > 0
    ? `${entries.length} listening port(s) — ${cwdCount} from ${shortenDir(cwd)}`
    : `${entries.length} listening port(s)`;
  console.log(`\n${C.dim}${summary}${C.reset}\n`);
}
