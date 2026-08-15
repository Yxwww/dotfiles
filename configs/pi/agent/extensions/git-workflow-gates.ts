/**
 * Git Workflow Gates
 *
 * Ports the active Claude hooks into pi extensions:
 * - tool_call (bash): block `git commit` unless the pre-commit skill is driving
 *   it (sentinel /tmp/pi-pre-commit-active), injecting the pre-commit skill as
 *   the reason so the agent runs the "capture the why" workflow first.
 * - tool_result (bash): after a successful `git push` with an open PR, append a
 *   steering note prompting the agent to evaluate updating the PR description.
 *
 * Backed up at configs/pi/agent/extensions/ and symlinked into
 * ~/.pi/agent/extensions/ by linkdotfiles.sh. Skills live at
 * ~/.agents/skills/{pre-commit,pre-push,pr-catchup}/.
 *
 * Security note: git/gh are invoked via execFileSync with argv arrays (never a
 * shell string), so branch names / ref names can't inject shell metacharacters.
 * The commit/push gate regexes run against command text with shell string
 * literals and heredoc bodies stripped, so `git commit` / `git push` appearing
 * inside quotes or a heredoc can't trip the gate.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { isToolCallEventType, isBashToolResult } from "@earendil-works/pi-coding-agent";
import { execFileSync } from "node:child_process";
import { existsSync, readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

const SKILL_PATH = join(homedir(), ".agents", "skills", "pre-commit", "SKILL.md");
const SENTINEL = "/tmp/pi-pre-commit-active";

// Match `git commit` / `git push` as a command word at the start of a command
// segment (after ;, &&, ||, |, newline, or string start). Tested against text
// with shell literals stripped (see stripShellLiterals) so matches inside
// quotes/heredocs are excluded.
const COMMIT_RE = /(^|;|&&|\|\||\||\n)\s*git\s+commit\b/;
const PUSH_RE = /(^|;|&&|\|\||\||\n)\s*git\s+push\b/;

/**
 * Strip shell string literals and heredoc bodies so the command-word regexes
 * can't match `git commit` / `git push` appearing inside quoted text or a
 * heredoc body (e.g. `echo "&& git push"` or `cat <<EOF ... git push ... EOF`).
 * Not a full shell tokenizer; sufficient for gate detection. Hot path: a few
 * regex passes over a typically <1KB string, no GC pressure.
 */
function stripShellLiterals(cmd: string): string {
	// Drop heredoc bodies (<<[-]TAG / <<[-]'TAG' ... TAG), keep the opener line.
	let s = cmd.replace(/<<-?\s*['"]?(\w+)['"]?[^\n]*\n[\s\S]*?\n[ \t]*\1\b/g, (m) => {
		const nl = m.indexOf("\n");
		return nl < 0 ? m : m.slice(0, nl);
	});
	// Drop single- and double-quoted spans (content inside quotes is not a
	// command word). Handles backslash escapes inside the quotes.
	s = s.replace(/'(?:\\.|[^'\\])*'/g, "");
	s = s.replace(/"(?:\\.|[^"\\])*"/g, "");
	return s;
}

/** Run git with argv; returns "" on failure. No shell, so args can't inject. */
function git(args: string[], cwd: string): string {
	try {
		return execFileSync("git", args, { cwd, encoding: "utf-8", stdio: ["pipe", "pipe", "ignore"] }).trim();
	} catch {
		return "";
	}
}

/** Run gh with argv; returns "" on failure. */
function gh(args: string[], cwd: string): string {
	try {
		return execFileSync("gh", args, { cwd, encoding: "utf-8", stdio: ["pipe", "pipe", "ignore"] }).trim();
	} catch {
		return "";
	}
}

function stagedFiles(cwd: string): string[] {
	return git(["diff", "--name-only", "--cached"], cwd).split("\n").filter(Boolean);
}

const TEMPLATE_PATHS = [
	".github/pull_request_template.md",
	".github/PULL_REQUEST_TEMPLATE.md",
	"docs/pull_request_template.md",
	"pull_request_template.md",
];

function prTemplate(cwd: string): string {
	for (const rel of TEMPLATE_PATHS) {
		const p = join(cwd, rel);
		if (existsSync(p)) return readFileSync(p, "utf-8");
	}
	return "";
}

export default function (pi: ExtensionAPI) {
	// Pre-commit gate: force the "capture the why" workflow before committing.
	pi.on("tool_call", async (event, ctx) => {
		if (!isToolCallEventType("bash", event)) return undefined;
		const command = event.input.command;
		if (!COMMIT_RE.test(stripShellLiterals(command))) return undefined;
		// Skill is driving the commit. Sentinel file is the normal path; the
		// inline-token check covers single chained commands like
		// `touch /tmp/pi-pre-commit-active && git commit ...`.
		if (existsSync(SENTINEL) || command.includes("pi-pre-commit-active")) return undefined;
		const staged = stagedFiles(ctx.cwd);
		if (staged.length === 0) return undefined;
		// Skip trivial changes (only lockfiles / json configs).
		if (!staged.some((f) => !/\.(lock|json)$/.test(f))) return undefined;
		if (!existsSync(SKILL_PATH)) return undefined;
		const skill = readFileSync(SKILL_PATH, "utf-8");
		return {
			block: true,
			reason: `Run the pre-commit workflow before committing:\n\n${skill}`,
		};
	});

	// Post-push: nudge the agent to keep the PR description in sync.
	pi.on("tool_result", async (event, ctx) => {
		if (!isBashToolResult(event)) return undefined;
		const command = (event.input as { command?: string }).command ?? "";
		if (!PUSH_RE.test(stripShellLiterals(command))) return undefined;
		if (event.isError) return undefined; // only successful pushes
		const cwd = ctx.cwd;

		const branch = git(["rev-parse", "--abbrev-ref", "HEAD"], cwd);
		if (!branch || branch === "HEAD") return undefined;

		const prJson = gh(["pr", "view", branch, "--json", "number,url,body"], cwd);
		if (!prJson) return undefined;

		let pr: { number?: number; url?: string; body?: string };
		try {
			pr = JSON.parse(prJson);
		} catch {
			return undefined;
		}
		if (!pr.number || !pr.url) return undefined;

		// Prefer the PR's own base ref (always correct) over symbolic-ref, which
		// is unset on fresh clones. Fall back to origin/HEAD, then master.
		let base = gh(["pr", "view", branch, "--json", "baseRefName"], cwd);
		if (base) {
			try {
				base = JSON.parse(base).baseRefName ?? "";
			} catch {
				base = "";
			}
		}
		if (!base) {
			base =
				git(["symbolic-ref", "refs/remotes/origin/HEAD"], cwd).replace(
					/^refs\/remotes\/origin\//,
					"",
				) || "master";
		}
		const diffStat =
			git(["diff", "--stat", `origin/${base}...HEAD`], cwd).split("\n").pop() || "";
		const commitCount = git(["rev-list", "--count", `origin/${base}..HEAD`], cwd) || "0";
		const body = pr.body ?? "";
		const template = prTemplate(cwd);

		const note =
			`Branch "${branch}" was pushed to PR #${pr.number} (${pr.url}).\n` +
			`Diff: ${diffStat} | Commits: ${commitCount} | PR body length: ${body.length} chars\n\n` +
			`EVALUATE whether the PR description needs updating before taking action:\n` +
			`- SKIP only if the body already follows the template structure AND accurately describes the changes.\n` +
			`- UPDATE if the body is empty, has unfilled placeholders, diverged from the changes, or is free-form and does not follow the template (restructure it into the template — see Rules).\n` +
			`- If UNSURE, ask the user whether they want the PR description updated.\n\n` +
			`If you decide to update, write the body to a temp file and use --body-file (robust for multi-line bodies, backticks, and code fences):\n` +
			`  gh pr edit ${pr.number} --body-file /tmp/pr-${pr.number}-body.md\n\n` +
			`Rules:\n` +
			`- Follow the template structure exactly: keep every section heading, in template order.\n` +
			`- If the existing body is free-form / non-template, restructure it — fold existing prose into the matching template sections, drop prose with no home, add missing REQUIRED sections. Do not preserve a non-template layout.\n` +
			`- Be concise: bullets over prose. Lead with the change, not the background.\n` +
			`- Checkbox impact sections (Breaking, CSP, Analytics, Wrappers, Security, Privacy, DevOps): check [x] Yes only when the answer is genuinely yes; otherwise leave [ ] Yes unchecked with a one-line reason.\n` +
			`- Review commits and diff for context. Preserve content the user hand-wrote — relocate it into the right section rather than rewriting it.\n` +
			`- Remove placeholder HTML comments from filled sections; leave them in unfilled OPTIONAL sections.\n\n` +
			`Template:\n${template}\n\nCurrent body:\n${body}`;

		const content = [...event.content, { type: "text" as const, text: note }];
		return { content };
	});
}
