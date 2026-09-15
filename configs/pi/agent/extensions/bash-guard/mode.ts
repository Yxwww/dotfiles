// Guard mode state. Kept as pure functions so the default/opt-in contract is
// testable and can't silently flip back during a refactor.
//
// `disabled === true` means the guard is OFF (autonomous; catastrophic floor
// still applies). `enabledFlag` mirrors `--bash-guard-enabled`.

export function initialDisabled(enabledFlag: boolean): boolean {
	return !enabledFlag;
}

export function toggleDisabled(current: boolean): boolean {
	return !current;
}