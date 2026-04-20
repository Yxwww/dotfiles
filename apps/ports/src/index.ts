#!/usr/bin/env bun

import { scanPorts, killProcess, shortenDir, sortCwdFirst, isFromCwd } from "./ports";

const args = process.argv.slice(2);
const cmd = args[0] ?? "";

switch (cmd) {
  case "list":
  case "ls": {
    const raw = await scanPorts();
    const cwd = process.cwd();
    const entries = sortCwdFirst(raw, cwd);
    console.log(`Current dir: ${shortenDir(cwd)}`);
    console.log(
      ["  ", "PORT".padEnd(8), "PID".padEnd(8), "SCRIPT".padEnd(16), "PROJECT".padEnd(22), "ADDRESS"].join("")
    );
    for (const e of entries) {
      const here = isFromCwd(e, cwd);
      const marker = here ? "● " : "  ";
      const tail = here ? "  ← current dir" : "";
      console.log(
        marker +
          [
            String(e.port).padEnd(8),
            String(e.pid).padEnd(8),
            (e.script || e.command).padEnd(16),
            (e.project || "—").slice(0, 20).padEnd(22),
            e.address,
          ].join("") +
          tail
      );
    }
    break;
  }

  case "json": {
    const entries = await scanPorts();
    console.log(JSON.stringify(entries, null, args.includes("--compact") ? 0 : 2));
    break;
  }

  case "kill": {
    const target = args[1];
    if (!target) {
      console.error("Usage: pf kill <port|pid|name>");
      process.exit(1);
    }
    const entries = await scanPorts();
    const num = parseInt(target, 10);
    const matches = entries.filter(
      (e) =>
        e.port === num ||
        e.pid === num ||
        e.command.toLowerCase().includes(target.toLowerCase()) ||
        e.script.toLowerCase().includes(target.toLowerCase()) ||
        e.project.toLowerCase().includes(target.toLowerCase())
    );
    if (matches.length === 0) {
      console.error(`No process found matching "${target}"`);
      process.exit(1);
    }
    const pids = [...new Set(matches.map((e) => e.pid))];
    for (const pid of pids) {
      const e = matches.find((m) => m.pid === pid)!;
      const label = e.script || e.command;
      const result = await killProcess(pid);
      if (result.success) {
        console.log(`killed ${pid} (${label}) on port ${e.port}`);
      } else {
        console.error(`failed ${pid}: ${result.error}`);
      }
    }
    break;
  }

  case "find": {
    const query = args[1];
    if (!query) {
      console.error("Usage: pf find <query>");
      process.exit(1);
    }
    const entries = await scanPorts();
    const q = query.toLowerCase();
    const hits = entries.filter(
      (e) =>
        e.command.toLowerCase().includes(q) ||
        e.script.toLowerCase().includes(q) ||
        e.project.toLowerCase().includes(q) ||
        e.fullCommand.toLowerCase().includes(q) ||
        String(e.port) === query
    );
    if (hits.length === 0) {
      console.error(`No match for "${query}"`);
      process.exit(1);
    }
    for (const e of hits) {
      console.log(`${e.port}\t${e.pid}\t${e.script || e.command}\t${e.project || "—"}`);
      if (e.fullCommand) console.log(`  → ${shortenDir(e.fullCommand)}`);
    }
    break;
  }

  case "--snapshot":
  case "-s": {
    const { snapshot } = await import("./snapshot");
    await snapshot();
    break;
  }

  case "help":
  case "--help":
  case "-h":
    console.log(`pf — list and manage listening TCP ports

Usage:
  pf                  Interactive TUI
  pf list             Plain table (no color, pipe-friendly)
  pf json             JSON output (--compact for single line)
  pf find <query>     Search by port, name, project, or command
  pf kill <target>    Kill by port number, PID, name, or project
  pf --snapshot       Colored snapshot

Interactive keys:
  j/↓  down   k/↑  up   d/enter  kill   r  refresh   q  quit`);
    break;

  case "": {
    const { startTui } = await import("./tui");
    await startTui();
    break;
  }

  default:
    console.error(`Unknown command: ${cmd}\nRun "pf help" for usage.`);
    process.exit(1);
}
