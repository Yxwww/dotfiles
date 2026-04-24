import { describe, test, expect } from "bun:test";
import { shortenDir, pickDevScript, pollForNewListener, type PortEntry } from "./ports";

const HOME = "/Users/yuxi";

describe("shortenDir", () => {
  test("replaces home prefix mid-command", () => {
    expect(shortenDir("node /Users/yuxi/git/app/s.js", HOME))
      .toBe("node ~/git/app/s.js");
  });

  test("replaces home at command start", () => {
    expect(shortenDir("/Users/yuxi/git/app/server.ts", HOME))
      .toBe("~/git/app/server.ts");
  });

  test("replaces home at end of string", () => {
    expect(shortenDir("cd /Users/yuxi", HOME)).toBe("cd ~");
  });

  test("replaces multiple occurrences", () => {
    expect(shortenDir("/Users/yuxi/a /Users/yuxi/b", HOME))
      .toBe("~/a ~/b");
  });

  test("does NOT replace partial prefix matches", () => {
    expect(shortenDir("node /Users/yuxiang/git/app/s.js", HOME))
      .toBe("node /Users/yuxiang/git/app/s.js");
  });

  test("no-ops when home absent", () => {
    expect(shortenDir("node /opt/bin/server.js", HOME))
      .toBe("node /opt/bin/server.js");
  });

  test("no-ops on empty input", () => {
    expect(shortenDir("", HOME)).toBe("");
  });

  test("no-ops on empty home", () => {
    expect(shortenDir("node /Users/yuxi/app.js", ""))
      .toBe("node /Users/yuxi/app.js");
  });

  test("uses Bun.env.HOME when home is omitted", () => {
    const home = Bun.env.HOME ?? "";
    // When called without explicit home, it should use the env default
    expect(shortenDir(`node ${home}/app.js`))
      .toBe("node ~/app.js");
  });
});

describe("pickDevScript", () => {
  test("prefers dev over start", () => {
    expect(pickDevScript({ scripts: { dev: "vite", start: "node ." } })).toBe("dev");
  });
  test("falls back to start", () => {
    expect(pickDevScript({ scripts: { start: "node ." } })).toBe("start");
  });
  test("returns null when neither present", () => {
    expect(pickDevScript({ scripts: { build: "tsc" } })).toBeNull();
  });
  test("returns null for missing scripts block", () => {
    expect(pickDevScript({})).toBeNull();
  });
  test("returns null for null input", () => {
    expect(pickDevScript(null)).toBeNull();
  });
});

describe("pollForNewListener", () => {
  const mk = (pid: number, port: number): PortEntry => ({
    pid, port, command: "node", user: "yuxi", protocol: "IPv4",
    address: "*", fd: "3", fullCommand: "", script: "", project: "", cwd: "",
  });

  test("resolves with the new entry once it appears", async () => {
    let call = 0;
    const scan = async () => (++call < 3 ? [] : [mk(9999, 5173)]);
    const entry = await pollForNewListener(9999, { scan, intervalMs: 10, timeoutMs: 500 });
    expect(entry?.port).toBe(5173);
  });

  test("resolves null after timeout", async () => {
    const scan = async () => [] as PortEntry[];
    const entry = await pollForNewListener(9999, { scan, intervalMs: 10, timeoutMs: 50 });
    expect(entry).toBeNull();
  });

  test("ignores entries owned by other pids", async () => {
    const scan = async () => [mk(1234, 3000)];
    const entry = await pollForNewListener(9999, { scan, intervalMs: 10, timeoutMs: 50 });
    expect(entry).toBeNull();
  });
});
