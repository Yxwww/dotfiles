import { describe, test, expect } from "bun:test";
import { jumpTarget } from "./jump";

describe("jumpTarget", () => {
  test("g jumps to the top of the list", () => {
    expect(jumpTarget("g", 5)).toBe(0);
  });

  test("G jumps to the bottom of the list", () => {
    expect(jumpTarget("G", 5)).toBe(4);
  });

  test("empty list has nowhere to jump", () => {
    expect(jumpTarget("g", 0)).toBe(null);
    expect(jumpTarget("G", 0)).toBe(null);
  });

  test("unrelated keys do not jump", () => {
    expect(jumpTarget("q", 5)).toBe(null);
    expect(jumpTarget("j", 5)).toBe(null);
  });
});