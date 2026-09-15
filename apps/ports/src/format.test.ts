import { describe, test, expect } from "bun:test";
import { formatPortRow, displayPath } from "./format";
import type { PortEntry } from "./ports";

const HOME = "/Users/yuxi";

const entry: PortEntry = {
  pid: 88252,
  command: "node",
  user: "yuxi",
  port: 5173,
  protocol: "IPv4",
  address: "[::1]",
  fd: "3",
  fullCommand: "node /Users/yuxi/git/my-app/node_modules/.bin/vite --port 5173",
  script: "vite",
  project: "my-app",
  cwd: "/Users/yuxi/git/my-app",
  gitRoot: "",
};

const cwd = "/Users/yuxi/git/my-app";

describe("formatPortRow compact mode", () => {
  test("single line: empty description, short path inline on the name", () => {
    const row = formatPortRow(entry, cwd, { compact: true, home: HOME });
    expect(row.description).toBe("");
    expect(row.name).toContain("~/git/my-app");
    expect(row.name).toContain("5173");
    expect(row.name).toContain("vite");
  });

  test("keeps the pid and marks current-dir rows even when compact", () => {
    const row = formatPortRow(entry, cwd, { compact: true, home: HOME });
    expect(row.name).toContain("88252");
    expect(row.name.startsWith("● ")).toBe(true);
  });

  test("non-compact keeps the full command on the description, not the name", () => {
    const row = formatPortRow(entry, cwd, { home: HOME });
    expect(row.description).toContain("~");
    expect(row.description).toContain("vite --port 5173");
    expect(row.name).toContain("(my-app)");
    expect(row.name).not.toContain("/my-app");
  });

  test("compact shows the git-root-relative path when inside a repo", () => {
    const gitEntry: PortEntry = {
      ...entry,
      cwd: "/Users/yuxi/git/dotfiles/apps/ports",
      gitRoot: "/Users/yuxi/git/dotfiles",
      project: "my-app",
    };
    const row = formatPortRow(gitEntry, gitEntry.cwd, { compact: true, home: HOME });
    expect(row.name).toContain("dotfiles/apps/ports");
  });
});

describe("displayPath", () => {
  test("collapses to repo name + inner path when inside a git root", () => {
    expect(displayPath("/Users/yuxi/git/dotfiles/apps/ports", "/Users/yuxi/git/dotfiles", HOME))
      .toBe("dotfiles/apps/ports");
  });

  test("shows repo name alone when cwd is the git root", () => {
    expect(displayPath("/Users/yuxi/git/dotfiles", "/Users/yuxi/git/dotfiles", HOME))
      .toBe("dotfiles");
  });

  test("falls back to home-shortened path without a git root", () => {
    expect(displayPath("/Users/yuxi/git/my-app", "", HOME)).toBe("~/git/my-app");
  });

  test("empty cwd is empty", () => {
    expect(displayPath("", "", HOME)).toBe("");
  });
});