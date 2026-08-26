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
import { scanPorts, killProcess, openInBrowser, shortenDir, sortCwdFirst, isFromCwd, spawnDevServer, pollForNewListener, type PortEntry } from "./ports";
import { formatPortRow } from "./format";
import { planLayout } from "./layout";
import { jumpTarget } from "./jump";

type Mode = "browse" | "confirm-kill";

const state = {
  entries: [] as PortEntry[],
  mode: "browse" as Mode,
  pendingKill: null as PortEntry | null,
  refreshing: false,
  compact: false,
};

let renderer: CliRenderer;
let titleText: TextRenderable;
let select: SelectRenderable;
let statusText: TextRenderable;
let confirmBox: BoxRenderable;
let confirmText: TextRenderable;

function formatOption(entry: PortEntry, cwd: string, compact: boolean): SelectOption {
  const row = formatPortRow(entry, cwd, { compact });
  return { name: row.name, description: row.description, value: entry };
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
  rebuildOptions();
  const titleTail = cwdCount > 0 ? ` · ${cwdCount} from cwd ` : " ";
  titleText.content = t`${bold(` Ports (${entries.length} listening)${titleTail}`)}`;
  statusText.content = t`${dim(" q quit  d kill  s start  o open  r refresh  j/↓ k/↑")}`;
  state.refreshing = false;
}

function rebuildOptions() {
  const cwd = process.cwd();
  select.options = state.entries.map((e) => formatOption(e, cwd, state.compact));
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

async function startDevServer() {
  const cwd = process.cwd();

  const existing = state.entries.find((e) => isFromCwd(e, cwd));
  if (existing) {
    statusText.content = t`${yellow(`Port already listening for this project (PID ${existing.pid}, port ${existing.port}) — starting anyway`)}`;
  } else {
    statusText.content = t`${dim(`Starting pnpm ... in ${shortenDir(cwd)}`)}`;
  }

  const res = await spawnDevServer(cwd);
  if (!res.success) {
    statusText.content = t`${red(res.error)}`;
    return;
  }

  statusText.content = t`${green(`Spawned PID ${res.pid} (pnpm ${res.script}), logs: ${res.logPath}`)}`;

  pollForNewListener(res.pid, { scan: scanPorts, intervalMs: 500, timeoutMs: 30000 }).then(
    async (hit) => {
      if (!hit) {
        statusText.content = t`${yellow(`Server started but no port appeared in 30s — check ${res.logPath}`)}`;
        return;
      }
      await refresh();
      const idx = state.entries.findIndex((e) => e.pid === hit.pid && e.port === hit.port);
      if (idx >= 0) select.setSelectedIndex(idx);
      statusText.content = t`${green(`Dev server up on port ${hit.port} (PID ${hit.pid})`)}`;
    },
  );
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
    content: t`${dim(" q quit  d kill  s start  o open  r refresh  j/↓ k/↑")}`,
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

  // Responsive chrome: shed sections (least useful first) as the terminal
  // shrinks so the port rows always survive instead of being squeezed out.
  function applyLayout() {
    const plan = planLayout(renderer.terminalHeight);
    titleText.visible = plan.showTitle;
    header.visible = plan.showHeader;
    sep.visible = plan.showSeparator;
    statusText.visible = plan.showStatus;
    outer.border = plan.showBorder;
    state.compact = plan.compact;
    select.showDescription = !plan.compact;
    rebuildOptions();
  }
  applyLayout();
  renderer.on("resize", applyLayout);

  // Auto-refresh when the terminal window regains focus — the listening ports
  // likely changed while we were away. Skip mid-confirm so a re-scan doesn't
  // reshuffle the list out from under the pending kill.
  renderer.on("focus", () => {
    if (state.mode === "browse") refresh();
  });

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
    if (key.name === "s") {
      startDevServer();
      return;
    }
    if (key.name === "g" || key.name === "G") {
      const idx = jumpTarget(key.name, select.options.length);
      if (idx !== null) select.setSelectedIndex(idx);
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

  // On-demand rendering: DO NOT call renderer.start(). start() pins the render
  // loop to _isRunning=true, repainting the (unchanged) screen at targetFps
  // (~30/s) forever — ~4% idle CPU. Leaving the renderer idle makes it paint
  // only when a renderable mutates and fires requestRender() (nav, refresh,
  // resize, focus, keypress). Safe here: no animated/live renderables exist.
  renderer.requestRender();
}
