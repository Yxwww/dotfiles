/**
 * Responsive layout planner for the ports TUI.
 *
 * The TUI is a vertical flex stack: chrome sections with fixed height wrap a
 * port list that absorbs the remaining rows. When the terminal is short the
 * fixed chrome would eat the whole height and collapse the list to nothing, so
 * this planner progressively drops chrome — least useful first — to keep the
 * port rows visible. Pure function: viewport height in, visibility plan out.
 */

export type LayoutPlan = {
  showTitle: boolean;
  showHeader: boolean;
  showSeparator: boolean;
  showStatus: boolean;
  showBorder: boolean;
  /** Rows left for the port list after the shown chrome takes its share. */
  listRows: number;
};

/** How many rows the list keeps before chrome starts getting dropped. */
const MIN_LIST_ROWS = 3;

/** Droppable chrome, ordered least useful first → dropped first. */
const SECTIONS = [
  { key: "separator", cost: 1 },
  { key: "header", cost: 1 },
  { key: "border", cost: 2 },
  { key: "status", cost: 1 },
  { key: "title", cost: 1 },
] as const;

export function planLayout(height: number, minListRows = MIN_LIST_ROWS): LayoutPlan {
  const dropped = new Set<string>();
  const chromeCost = () =>
    SECTIONS.reduce((sum, s) => (dropped.has(s.key) ? sum : sum + s.cost), 0);

  // Drop chrome in priority order until the list clears the minimum.
  for (const s of SECTIONS) {
    if (height - chromeCost() >= minListRows) break;
    dropped.add(s.key);
  }

  return {
    showTitle: !dropped.has("title"),
    showHeader: !dropped.has("header"),
    showSeparator: !dropped.has("separator"),
    showStatus: !dropped.has("status"),
    showBorder: !dropped.has("border"),
    listRows: Math.max(0, height - chromeCost()),
  };
}
