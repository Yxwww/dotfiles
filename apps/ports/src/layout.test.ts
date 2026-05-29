import { describe, test, expect } from "bun:test";
import { planLayout } from "./layout";

describe("planLayout", () => {
  test("tall viewport shows all chrome and gives the rest to the list", () => {
    const plan = planLayout(40);
    expect(plan.showTitle).toBe(true);
    expect(plan.showHeader).toBe(true);
    expect(plan.showSeparator).toBe(true);
    expect(plan.showStatus).toBe(true);
    expect(plan.showBorder).toBe(true);
    // 40 - (title 1 + header 1 + separator 1 + status 1 + border 2) = 34
    expect(plan.listRows).toBe(34);
  });

  test("drops the separator first when rows fall below the minimum", () => {
    // height 8: full chrome (6) would leave only 2 rows (< min 3),
    // so the lowest-priority chrome — the separator — is dropped.
    const plan = planLayout(8);
    expect(plan.showSeparator).toBe(false);
    expect(plan.showTitle).toBe(true);
    expect(plan.showHeader).toBe(true);
    expect(plan.showStatus).toBe(true);
    expect(plan.showBorder).toBe(true);
    expect(plan.listRows).toBe(3);
  });

  test("tiny viewport drops all chrome and gives every row to the list", () => {
    const plan = planLayout(2);
    expect(plan.showTitle).toBe(false);
    expect(plan.showHeader).toBe(false);
    expect(plan.showSeparator).toBe(false);
    expect(plan.showStatus).toBe(false);
    expect(plan.showBorder).toBe(false);
    expect(plan.listRows).toBe(2);
  });

  test("never reports negative rows for a zero-height viewport", () => {
    expect(planLayout(0).listRows).toBe(0);
  });

  test("drops chrome in priority order: separator, header, border, status, title", () => {
    // Each step removes exactly enough chrome to restore the 3-row minimum,
    // so walking the height down reveals the drop sequence.
    expect(planLayout(8).showSeparator).toBe(false); // first to go
    const afterHeader = planLayout(7);
    expect(afterHeader.showHeader).toBe(false);
    expect(afterHeader.showBorder).toBe(true);
    const afterBorder = planLayout(6);
    expect(afterBorder.showBorder).toBe(false);
    expect(afterBorder.showStatus).toBe(true);
    const afterStatus = planLayout(4);
    expect(afterStatus.showStatus).toBe(false);
    expect(afterStatus.showTitle).toBe(true);
    const afterTitle = planLayout(3);
    expect(afterTitle.showTitle).toBe(false);
  });
});
