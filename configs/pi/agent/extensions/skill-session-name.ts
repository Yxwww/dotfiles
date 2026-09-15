/**
 * Name the current pi session from a /skill:<name> invocation so /resume
 * shows the skill name instead of the expanded <skill …> first-message blob.
 *
 * Pure logic lives here; the extension default export only wires pi events.
 * Backed up at configs/pi/agent/extensions/ and symlinked by linkdotfiles.sh.
 */

export interface NameFromSkillResult {
  nextName: string | undefined;
  named: boolean;
}

/** Same parse as pi's _expandSkillCommand: no leading-trim, name up to first space. */
export function nameFromSkillCommand(
  text: string,
  currentName: string | undefined,
): NameFromSkillResult {
  const noop: NameFromSkillResult = { nextName: undefined, named: false };
  if (currentName !== undefined && currentName.trim().length > 0) return noop;
  if (!text.startsWith("/skill:")) return noop;
  const spaceIndex = text.indexOf(" ");
  const skillName = (spaceIndex === -1 ? text.slice(7) : text.slice(7, spaceIndex)).trim();
  if (skillName.length === 0) return noop;
  return { nextName: skillName, named: true };
}

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  pi.on("input", async (event) => {
    const result = nameFromSkillCommand(event.text, pi.getSessionName());
    if (result.named && result.nextName !== undefined) {
      pi.setSessionName(result.nextName);
    }
    return { action: "continue" as const };
  });
}