/**
 * Name the current pi session from the work it is about, so /resume and the
 * terminal title ("π - <name> - <cwd>") say what the session is doing.
 *
 * Earlier versions named unnamed sessions after the /skill:<name> that started
 * them. A skill is a workflow, not a subject, so every pr-catchup session got
 * the name "pr-catchup" — three different workstreams, one indistinguishable
 * name. Skill names are now excluded and the prompt supplies the name instead.
 *
 * Pure logic lives here; the extension default export only wires pi events.
 * Backed up at configs/pi/agent/extensions/ and symlinked by linkdotfiles.sh.
 */

/** Skills whose name says nothing about the task, so it must never become the session name. */
export const NOISE_SKILLS: ReadonlySet<string> = new Set([
  "pr-catchup",
  "pr",
  "pre-commit",
  "pre-push",
  "code-review",
  "simplify",
  "grilling",
  "retro",
  "research",
  "tdd",
  "retro-facilitator",
  "chief-of-staff",
]);

/** Prefixes pi uses for its own agent-internal sessions; naming them leaks noise. */
const INTERNAL_PREFIXES = ["subagent-", "worker-"];

const MAX_NAME_LEN = 48;

/** Leading filler that carries no meaning once the prompt becomes a name. */
const FILLER_PREFIXES = [
  "can you ",
  "could you ",
  "would you ",
  "please ",
  "pls ",
  "i want you to ",
  "i need you to ",
  "i want to ",
  "i want ",
  "i need to ",
  "i need ",
  "i'd like to ",
  "let's ",
  "lets ",
  "help me ",
  "okay so ",
  "ok so ",
  "so, you know, ",
  "so ",
  "hey ",
  "hi ",
  "just ",
  "now ",
];

/** Prompts too thin to name anything; naming from them is worse than leaving the cwd fallback. */
const THIN_PROMPTS: ReadonlySet<string> = new Set([
  "hi",
  "hey",
  "hello",
  "yo",
  "sup",
  "ok",
  "okay",
  "k",
  "thanks",
  "thank you",
  "ty",
  "yes",
  "no",
  "y",
  "n",
  "continue",
  "go",
  "go on",
  "yes please",
  "go ahead",
]);

export interface NameResult {
  nextName: string | undefined;
  named: boolean;
}

const NOOP: NameResult = { nextName: undefined, named: false };

/**
 * Take the first complete thought: the opening sentence or clause. A title is
 * the subject of the request, not the first 48 characters of it.
 */
function firstThought(text: string): string {
  const sentence = text.search(/\.\s|\?\s|!\s|\.$|\?$|!$/);
  if (sentence >= 6) return text.slice(0, sentence);
  return text;
}

function isInternalName(name: string): boolean {
  const lower = name.toLowerCase();
  for (const prefix of INTERNAL_PREFIXES) {
    if (lower.startsWith(prefix)) return true;
  }
  return false;
}

/** True when the session already carries a name that should be kept. */
function hasName(currentName: string | undefined): boolean {
  if (currentName === undefined) return false;
  return currentName.trim().length > 0;
}

/**
 * pi names its own agent sessions. Renaming those would put subagent prompts in
 * /resume, so they are left untouched even though their name is internal.
 */
function isInternalSession(currentName: string | undefined): boolean {
  return currentName !== undefined && isInternalName(currentName.trim());
}

/**
 * Reduce a URL to something title-sized: a PR/issue number when it has one,
 * else just the host, so a link never crowds out the rest of the subject.
 */
function condenseUrls(text: string): string {
  return text.replace(/https?:\/\/\S+/g, (url) => {
    const pr = /\/(?:pull|issues|discussions)\/(\d+)/.exec(url);
    if (pr !== null) return `#${pr[1]}`;
    const host = /^https?:\/\/(?:www\.)?([^/]+)/.exec(url);
    return host !== null ? host[1] : "link";
  });
}

/**
 * Drop text that would read as noise in a title: leading filler, surrounding
 * quotes, markdown, paths that are just the cwd, and trailing punctuation.
 */
function normalizePromptText(text: string): string {
  let out = text.trim();

  // A prompt is often one shell/agent command; its argv tail is more useful
  // than the program name alone, so keep the whole first line.
  const newline = out.indexOf("\n");
  if (newline !== -1) out = out.slice(0, newline);

  out = out.replace(/^[`'"*_\s]+/, "").replace(/[`'"*_\s]+$/, "");

  let changed = true;
  while (changed) {
    changed = false;
    const lower = out.toLowerCase();
    for (const filler of FILLER_PREFIXES) {
      if (lower.startsWith(filler)) {
        out = out.slice(filler.length);
        changed = true;
        break;
      }
    }
  }

  out = condenseUrls(out);
  out = out.replace(/[.?!,;:]+$/, "").replace(/\s+/g, " ").trim();
  return out;
}

/** A dangling connector makes a truncated name look broken. */
function stripDanglingWord(text: string): string {
  let out = text.replace(/[\s.,;:-]+$/, "");
  // Loop: one pass can uncover another connector ("...loading and the").
  for (;;) {
    const next = out
      .replace(/\s+(?:a|an|the|to|of|and|or|for|in|on|at|by|with|from|that|this)$/i, "")
      .replace(/[\s.,;:-]+$/, "");
    if (next === out) return out;
    out = next;
  }
}

/** Cut at a word boundary so a truncated name stays readable. */
function truncate(text: string, max: number): string {
  if (text.length <= max) return text;

  const cut = text.slice(0, max);

  // Prefer the last clause boundary, so a long prompt becomes the first
  // complete thought instead of a mid-sentence fragment.
  const clause = Math.max(
    cut.lastIndexOf(". "),
    cut.lastIndexOf(" - "),
    cut.lastIndexOf(": "),
  );
  if (clause >= max * 0.35) {
    return stripDanglingWord(cut.slice(0, clause));
  }

  const space = cut.lastIndexOf(" ");
  // Only back off to a space when it keeps most of the text; otherwise a long
  // first word would collapse to nothing.
  return stripDanglingWord(space > max * 0.6 ? cut.slice(0, space) : cut);
}

export function nameFromSkillCommand(
  text: string,
  currentName: string | undefined,
): NameResult {
  if (hasName(currentName)) return NOOP;
  if (isInternalSession(currentName)) return NOOP;
  if (!text.startsWith("/skill:")) return NOOP;

  const spaceIndex = text.indexOf(" ");
  const skillName = (spaceIndex === -1 ? text.slice(7) : text.slice(7, spaceIndex)).trim();
  if (skillName.length === 0) return NOOP;
  if (NOISE_SKILLS.has(skillName.toLowerCase())) return NOOP;

  return { nextName: skillName, named: true };
}

/** The text after "/skill:<name> " — usually the subject (a PR number, a path). */
export function skillCommandArgs(text: string): string {
  if (!text.startsWith("/skill:")) return "";
  const spaceIndex = text.indexOf(" ");
  return spaceIndex === -1 ? "" : text.slice(spaceIndex + 1).trim();
}

/**
 * Name the session from the first real prompt. Runs on every input until the
 * session gets a name, so it must stay cheap and return a no-op once named.
 */
export function nameFromPrompt(
  text: string,
  currentName: string | undefined,
): NameResult {
  if (hasName(currentName)) return NOOP;
  if (isInternalSession(currentName)) return NOOP;

  const raw = text.trim();
  if (raw.length === 0) return NOOP;
  if (raw.startsWith("!")) return NOOP;
  // Slash commands are not prompts. /skill: is handled by nameForSession.
  if (raw.startsWith("/")) return NOOP;

  // Defensive only: pi emits input handlers before skill expansion, so a
  // literal <skill …> blob should not arrive here. Naming from one would be
  // the noise this extension exists to prevent.
  if (/^<skill\b/i.test(raw)) return NOOP;

  // A pasted blob is not a title.
  if (raw.length > 2000) return NOOP;

  const name = nameFromText(raw);
  if (name === undefined) return NOOP;
  return { nextName: name, named: true };
}

/** Shared core: turn one piece of text into a title-sized name, or undefined. */
function nameFromText(text: string): string | undefined {
  const normalized = normalizePromptText(text);
  if (normalized.length < 3) return;
  if (THIN_PROMPTS.has(normalized.toLowerCase())) return;

  // Collapse the request to its subject before truncating, so a long prompt
  // yields a complete phrase rather than a cut-off fragment.
  const subject = firstThought(normalized);
  if (subject.length < 3) return;
  if (THIN_PROMPTS.has(subject.toLowerCase())) return;

  const name = truncate(subject, MAX_NAME_LEN);
  if (name.length < 3) return;
  if (isInternalName(name)) return;

  return name;
}

/** Combined policy: keep a real name, otherwise derive one from this input. */
export function nameForSession(
  text: string,
  currentName: string | undefined,
): NameResult {
  const fromSkill = nameFromSkillCommand(text, currentName);
  if (fromSkill.named) return fromSkill;

  // A workflow skill is not a title, but its argument usually is the subject:
  // "/skill:pr-catchup 152" should read as "152", not go unnamed.
  const trimmed = text.trim();
  if (trimmed.startsWith("/skill:")) {
    if (hasName(currentName) || isInternalSession(currentName)) return NOOP;
    const args = skillCommandArgs(trimmed);
    if (args.length === 0) return NOOP;
    const name = nameFromText(args);
    if (name === undefined) return NOOP;
    return { nextName: name, named: true };
  }

  return nameFromPrompt(text, currentName);
}

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  pi.on("input", async (event) => {
    const result = nameForSession(event.text, pi.getSessionName());
    if (result.named && result.nextName !== undefined) {
      pi.setSessionName(result.nextName);
    }
    return { action: "continue" as const };
  });
}
