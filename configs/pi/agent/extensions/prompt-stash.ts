import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

/** Result of the stash-or-restore decision. */
export interface StashResult {
  nextEditorText: string;
  nextStash: string | undefined;
  notification: { text: string; level: "info" | "warning" };
}

/**
 * Pure logic: decide whether to stash or restore.
 * - editor has non-whitespace text → stash it, clear editor
 * - editor empty + stash exists → restore stash into editor
 * - editor empty + no stash → no-op with warning
 */
export function stashOrRestore(
  editorText: string,
  stash: string | undefined,
): StashResult {
  const trimmed = editorText.trim();

  if (trimmed.length > 0) {
    return {
      nextEditorText: "",
      nextStash: editorText,
      notification: { text: "Prompt stashed", level: "info" },
    };
  }

  if (stash !== undefined) {
    return {
      nextEditorText: stash,
      nextStash: stash,
      notification: { text: "Prompt restored", level: "info" },
    };
  }

  return {
    nextEditorText: "",
    nextStash: undefined,
    notification: { text: "Nothing to restore", level: "warning" },
  };
}

export default function (pi: ExtensionAPI) {
  let stash: string | undefined;

  pi.on("session_start", async (_event, ctx) => {
    for (const entry of ctx.sessionManager.getEntries()) {
      if (entry.type === "custom" && entry.customType === "prompt-stash") {
        stash = entry.data?.text as string | undefined;
      }
    }
  });

  pi.registerShortcut("ctrl+s", {
    description: "Stash or restore prompt draft",
    handler: async (ctx) => {
      const current = ctx.ui.getEditorText();
      const result = stashOrRestore(current, stash);
      stash = result.nextStash;

      if (stash !== undefined) {
        pi.appendEntry("prompt-stash", { text: stash });
      }

      ctx.ui.setEditorText(result.nextEditorText);
      ctx.ui.notify(result.notification.text, result.notification.level);
    },
  });
}