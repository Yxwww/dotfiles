import { describe, expect, test } from "bun:test";
import { initialDisabled, toggleDisabled } from "./mode";

describe("bash-guard mode state", () => {
	test("defaults to OFF (disabled) without an opt-in flag", () => {
		expect(initialDisabled(false)).toBe(true);
	});

	test("opts IN to ON (enabled) when --bash-guard-enabled is passed", () => {
		expect(initialDisabled(true)).toBe(false);
	});

	test("toggle flips between enabled and disabled", () => {
		expect(toggleDisabled(true)).toBe(false);
		expect(toggleDisabled(false)).toBe(true);
	});
});