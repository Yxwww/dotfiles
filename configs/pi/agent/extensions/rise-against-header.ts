/**
 * Rise Against Header
 *
 * Replaces pi's built-in startup header with a Rise Against-style ASCII art
 * badge (the circular "RISE AGAINST" wordmark wrapping a star emblem) plus
 * the same helpful info the default header shows: version line, compact
 * keybinding hints, and a short onboarding tip.
 *
 * Placement: ~/.pi/agent/extensions/rise-against-header.ts (auto-discovered).
 * Hot-reload with /reload. Restore the built-in header with the
 * `:builtin-header` command.
 */

import type { ExtensionAPI, Theme } from "@earendil-works/pi-coding-agent";
import { VERSION } from "@earendil-works/pi-coding-agent";

/**
 * Rise Against-style badge: a framed wordmark with a star emblem.
 * Edit the `rows` array below to tweak the art.
 */
function riseAgainstArt(theme: Theme): string[] {
	const accent = (t: string) => theme.fg("accent", t);
	const dim = (t: string) => theme.fg("dim", t);
	const bold = (t: string) => theme.bold(t);

	// 45-char wide inner panel; everything centered for a clean badge.
	const W = 45;
	const center = (s: string) => {
		const pad = Math.max(0, W - s.length);
		const left = Math.floor(pad / 2);
		return " ".repeat(left) + s + " ".repeat(pad - left);
	};
	const top = "\u2554" + "\u2550".repeat(W) + "\u2557";
	const bot = "\u255a" + "\u2550".repeat(W) + "\u255d";
	const side = (inner: string) => "\u2551" + inner + "\u2551";

	const starRow = "    /     \\V/     \\    ";

	// Band name line.
	const band = "R I S E   A G A I N S T";

	const rows: Array<{ s: string; c: (t: string) => string; name?: boolean }> = [
		{ s: top, c: accent },
		{ s: side(center("")), c: dim },
		{ s: side(center(starRow)), c: dim },
		{ s: side(center(band)), c: accent, name: true },
		{ s: side(center("*  ~  *  ~  *  ~  *")), c: dim },
		{ s: side(center("")), c: dim },
		{ s: bot, c: accent },
	];

	return rows.map(({ s, c, name }) => {
		if (name) {
			const left = s.slice(0, s.indexOf("R"));
			const right = s.slice(s.indexOf("T") + 1);
			return c(left) + bold(band) + c(right);
		}
		return c(s);
	});
}

/**
 * Compact keybinding hint line, mirroring pi's built-in compact header.
 * Defaults: esc=interrupt, ctrl+c=clear, ctrl+d=exit, ctrl+o=expand,
 * /=commands, !=bash.
 */
function hintLine(theme: Theme): string {
	const muted = (t: string) => theme.fg("muted", t);
	const dim = (t: string) => theme.fg("dim", t);
	const parts = [
		`${dim("esc")} interrupt`,
		`${dim("ctrl+c")}/${dim("ctrl+d")} clear/exit`,
		`${dim("/")} commands`,
		`${dim("!")} bash`,
		`${dim("ctrl+o")} expand`,
	];
	return parts.join(muted(" · "));
}

export default function (pi: ExtensionAPI) {
	pi.on("session_start", async (_event, ctx) => {
		if (ctx.mode !== "tui") return;

		ctx.ui.setHeader((_tui, theme) => {
			return {
				render(_width: number): string[] {
					const art = riseAgainstArt(theme);
					const tagline = theme.fg("muted", "   rise against · rise again");
					const version = theme.fg("dim", `   pi v${VERSION}`);
					const hints = `   ${hintLine(theme)}`;
					const onboarding = theme.fg(
						"dim",
						"   Ask pi how to use or extend it. Press ctrl+o to expand the full help.",
					);
					return ["", ...art, "", tagline, version, hints, onboarding, ""];
				},
				invalidate() {},
			};
		});
	});

	// Restore the built-in header on demand.
	pi.registerCommand("builtin-header", {
		description: "Restore pi's built-in startup header",
		handler: async (_args, ctx) => {
			ctx.ui.setHeader(undefined);
			ctx.ui.notify("Built-in header restored", "info");
		},
	});
}
