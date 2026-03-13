import { scanPorts, classifyProcess } from "./ports";

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
  const entries = await scanPorts();

  if (entries.length === 0) {
    console.log(`${C.dim}No listening ports found (some may require sudo)${C.reset}`);
    process.exit(0);
  }

  const header = [
    "PORT".padEnd(8),
    "PID".padEnd(8),
    "SCRIPT".padEnd(14),
    "PROJECT".padEnd(20),
    "COMMAND".padEnd(16),
    "ADDRESS".padEnd(16),
  ].join("");

  console.log(`\n${C.bold}${C.blue}${header}${C.reset}`);
  console.log(`${C.dim}${"─".repeat(82)}${C.reset}`);

  for (let i = 0; i < entries.length; i++) {
    const e = entries[i];
    const cls = classifyProcess(e);
    const c = colorForClass(cls);
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
    console.log(`${c}${row}${C.reset}`);

    // Show full command on next line for dev processes
    if (e.fullCommand && cls === "user") {
      console.log(`${C.dim}  → ${e.fullCommand.slice(0, 100)}${C.reset}`);
    }
  }

  console.log(`\n${C.dim}${entries.length} listening port(s)${C.reset}\n`);
}
