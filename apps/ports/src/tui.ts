import {
  createCliRenderer,
  type CliRenderer,
  BoxRenderable,
  TextRenderable,
  SelectRenderable,
  SelectRenderableEvents,
  type SelectOption,
  type KeyEvent,
  t,
  dim,
  bold,
  green,
  red,
  yellow,
  cyan,
} from "@opentui/core";
import { scanPorts, classifyProcess, killProcess, openInBrowser, shortenDir, sortCwdFirst, isFromCwd, type PortEntry } from "./ports";

type Mode = "browse" | "confirm-kill";

const state = {
  entries: [] as PortEntry[],
  mode: "browse" as Mode,
  pendingKill: null as PortEntry | null,
  refreshing: false,
};

let renderer: CliRenderer;
let titleText: TextRenderable;
let select: SelectRenderable;
let statusText: TextRenderable;
let confirmBox: BoxRenderable;
let confirmText: TextRenderable;

function formatOption(entry: PortEntry, cwd: string): SelectOption {
  const cls = classifyProcess(entry);
  const tag = cls === "root" ? "[root]" : cls === "system" ? "[sys]" : "[usr]";
  const label = entry.script || entry.command.slice(0, 14);
  const proj = entry.project ? `(${entry.project})` : "";
  const here = isFromCwd(entry, cwd);
  const marker = here ? "● " : "  ";
  const baseDesc = entry.fullCommand
    ? `→ ${shortenDir(entry.fullCommand).slice(0, 80)}`
    : `${entry.command}  ${entry.address}:${entry.port}`;
  return {
    name: [
      marker,
      String(entry.port).padEnd(8),
      String(entry.pid).padEnd(8),
      label.slice(0, 14).padEnd(16),
      proj.slice(0, 22).padEnd(24),
      tag,
      here ? "  ← current dir" : "",
    ].join(""),
    description: baseDesc,
    value: entry,
  };
}

async function refresh() {
  if (state.refreshing) return;
  state.refreshing = true;
  statusText.content = t`${dim("scanning...")}`;

  const raw = await scanPorts();
  const cwd = process.cwd();
  const entries = sortCwdFirst(raw, cwd);
  state.entries = entries;

  const cwdCount = entries.filter((e) => isFromCwd(e, cwd)).length;
  select.options = entries.map((e) => formatOption(e, cwd));
  const titleTail = cwdCount > 0 ? ` · ${cwdCount} from cwd ` : " ";
  titleText.content = t`${bold(` Ports (${entries.length} listening)${titleTail}`)}`;
  statusText.content = t`${dim(" q quit  d kill  o open  r refresh  j/↓ k/↑")}`;
  state.refreshing = false;
}

function showConfirm(entry: PortEntry) {
  state.mode = "confirm-kill";
  state.pendingKill = entry;
  const label = entry.script || entry.command;
  confirmText.content = t`${yellow(`Kill PID ${entry.pid} (${label}) on port ${entry.port}?`)}  ${dim("y/n")}`;
  confirmBox.visible = true;
}

function hideConfirm() {
  state.mode = "browse";
  state.pendingKill = null;
  confirmBox.visible = false;
}

async function executeKill() {
  const entry = state.pendingKill;
  if (!entry) return;
  hideConfirm();

  const result = await killProcess(entry.pid);
  if (result.success) {
    statusText.content = t`${green(`Killed PID ${entry.pid} (${entry.command})`)}`;
    await refresh();
  } else {
    statusText.content = t`${red(result.error ?? "Kill failed")}`;
  }
}

export async function startTui() {
  renderer = await createCliRenderer({
    exitOnCtrlC: true,
    useAlternateScreen: true,
    useMouse: false,
  });

  const root = renderer.root;

  // Outer container
  const outer = new BoxRenderable(renderer, {
    width: "100%",
    height: "100%",
    flexDirection: "column",
    border: true,
    borderStyle: "rounded",
    borderColor: "#585b70",
    title: " ports ",
    backgroundColor: "#1e1e2e",
  });
  root.add(outer);

  // Title
  titleText = new TextRenderable(renderer, {
    content: t`${bold(" Ports (scanning...) ")}`,
    height: 1,
    paddingLeft: 1,
  });
  outer.add(titleText);

  // Column header
  const headerRow = [
    "  ",
    "PORT".padEnd(8),
    "PID".padEnd(8),
    "SCRIPT".padEnd(16),
    "PROJECT".padEnd(24),
    "TYPE",
  ].join("");

  const header = new TextRenderable(renderer, {
    content: t`${cyan(` ${headerRow}`)}`,
    height: 1,
    paddingLeft: 1,
  });
  outer.add(header);

  // Separator
  const sep = new TextRenderable(renderer, {
    content: t`${dim(` ${"─".repeat(72)}`)}`,
    height: 1,
    paddingLeft: 1,
  });
  outer.add(sep);

  // Select list
  select = new SelectRenderable(renderer, {
    flexGrow: 1,
    options: [],
    backgroundColor: "#1e1e2e",
    textColor: "#a6adc8",
    selectedBackgroundColor: "#313244",
    selectedTextColor: "#cdd6f4",
    descriptionColor: "#6c7086",
    selectedDescriptionColor: "#89b4fa",
    showDescription: true,
    showScrollIndicator: true,
    wrapSelection: true,
    paddingLeft: 1,
  });
  outer.add(select);

  // Status bar
  statusText = new TextRenderable(renderer, {
    content: t`${dim(" q quit  d kill  o open  r refresh  j/↓ k/↑")}`,
    height: 1,
    paddingLeft: 1,
  });
  outer.add(statusText);

  // Confirmation overlay (hidden initially)
  confirmBox = new BoxRenderable(renderer, {
    position: "absolute",
    top: "40%",
    left: "10%",
    width: "80%",
    height: 3,
    border: true,
    borderStyle: "rounded",
    borderColor: "#f9e2af",
    backgroundColor: "#313244",
    visible: false,
    zIndex: 10,
    justifyContent: "center",
    alignItems: "center",
  });
  root.add(confirmBox);

  confirmText = new TextRenderable(renderer, {
    content: "",
    height: 1,
  });
  confirmBox.add(confirmText);

  // Focus the select list for keyboard nav
  select.focus();

  // Keyboard handling
  renderer.keyInput.on("keypress", (key: KeyEvent) => {
    if (state.mode === "confirm-kill") {
      if (key.name === "y") {
        executeKill();
        return;
      }
      if (key.name === "n" || key.name === "escape") {
        hideConfirm();
        return;
      }
      return;
    }

    // Browse mode
    if (key.name === "q") {
      renderer.destroy();
      process.exit(0);
    }
    if (key.name === "d") {
      const opt = select.getSelectedOption();
      if (opt?.value) showConfirm(opt.value as PortEntry);
      return;
    }
    if (key.name === "o") {
      const opt = select.getSelectedOption();
      if (opt?.value) {
        const entry = opt.value as PortEntry;
        openInBrowser(entry.port).then((res) => {
          statusText.content = res.success
            ? t`${green(`Opened http://localhost:${entry.port}`)}`
            : t`${red(res.error ?? "Failed to open browser")}`;
        });
      }
      return;
    }
    if (key.name === "r") {
      refresh();
      return;
    }
  });

  // Item selected via enter — also triggers kill confirm
  select.on(SelectRenderableEvents.ITEM_SELECTED, () => {
    const opt = select.getSelectedOption();
    if (opt?.value) showConfirm(opt.value as PortEntry);
  });

  // Initial data load
  await refresh();

  renderer.start();
}
