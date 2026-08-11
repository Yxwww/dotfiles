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
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { isToolCallEventType, isBashToolResult } from "@earendil-works/pi-coding-agent";
import { execSync } from "node:child_process";
import { existsSync, readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

const SKILL_PATH = join(homedir(), ".agents", "skills", "pre-commit", "SKILL.md");
const SENTINEL = "/tmp/pi-pre-commit-active";

// Match `git commit` / `git push` as a distinct command, not a substring of
// e.g. `git log` or a filename.
const COMMIT_RE = /(^|&&|\|\||;|\n)\s*git commit\b/;
const PUSH_RE = /(^|&&|\|\||;|\n)\s*git push\b/;

function sh(cmd: string, cwd: string): string {
	try {
		return execSync(cmd, { cwd, encoding: "utf-8", stdio: ["pipe", "pipe", "ignore"] }).trim();
	} catch {
		return "";
	}
}

function stagedFiles(cwd: string): string[] {
	return sh("git diff --name-only --cached", cwd).split("\n").filter(Boolean);
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
		if (!COMMIT_RE.test(command)) return undefined;
		// Skill is driving the commit (sentinel file or inline sentinel token).
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
		if (!PUSH_RE.test(command)) return undefined;
		if (event.isError) return undefined; // only successful pushes
		const cwd = ctx.cwd;

		const branch = sh("git rev-parse --abbrev-ref HEAD", cwd);
		if (!branch || branch === "HEAD") return undefined;

		const prJson = sh(`gh pr view ${JSON.stringify(branch)} --json number,url,body`, cwd);
		if (!prJson) return undefined;

		let pr: { number?: number; url?: string; body?: string };
		try {
			pr = JSON.parse(prJson);
		} catch {
			return undefined;
		}
		if (!pr.number || !pr.url) return undefined;

		const base =
			sh("git symbolic-ref refs/remotes/origin/HEAD", cwd).replace(/^refs\/remotes\/origin\//, "") ||
			"master";
		const diffStat =
			sh(`git diff --stat ${JSON.stringify(`origin/${base}...HEAD`)}`, cwd).split("\n").pop() || "";
		const commitCount =
			sh(`git rev-list --count ${JSON.stringify(`origin/${base}..HEAD`)}`, cwd) || "0";
		const body = pr.body ?? "";
		const template = prTemplate(cwd);

		const note =
			`Branch "${branch}" was pushed to PR #${pr.number} (${pr.url}).\n` +
			`Diff: ${diffStat} | Commits: ${commitCount} | PR body length: ${body.length} chars\n\n` +
			`EVALUATE whether the PR description needs updating before taking action:\n` +
			`- SKIP if the current body already accurately describes the changes.\n` +
			`- UPDATE if the body is empty, has unfilled template placeholders, or the changes diverged from the description.\n` +
			`- If UNSURE, ask the user whether they want the PR description updated.\n\n` +
			`If you decide to update, run: gh pr edit ${pr.number} --body "<filled body>"\n\n` +
			`Rules:\n` +
			`- Fill every REQUIRED section accurately.\n` +
			`- Review commits and diff for context.\n` +
			`- Preserve sections the user already filled.\n` +
			`- Remove placeholder HTML comments from filled sections.\n` +
			`- Keep unfilled OPTIONAL sections with their original placeholders.\n\n` +
			`Template:\n${template}\n\nCurrent body:\n${body}`;

		const content = [...event.content, { type: "text" as const, text: note }];
		return { content };
	});
}
