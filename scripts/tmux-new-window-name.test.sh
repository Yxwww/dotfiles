#!/usr/bin/env bash
# Tests for tmux-new-window-name.sh
# Run: bash scripts/tmux-new-window-name.test.sh

set -u

SCRIPT="$(dirname "$0")/tmux-new-window-name.sh"
fail=0
pass=0

assert_eq() {
  local name="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    pass=$((pass + 1))
    printf '  ok  %s\n' "$name"
  else
    fail=$((fail + 1))
    printf '  FAIL %s\n    expected: %q\n    actual:   %q\n' "$name" "$expected" "$actual"
  fi
}

# T1: simple case — only the current window exists, no suffix
out=$(printf 'foo\n' | "$SCRIPT" foo)
assert_eq "T1 foo + [foo] -> foo-1" "foo-1" "$out"

# T2: increment when -1 already taken
out=$(printf 'foo\nfoo-1\n' | "$SCRIPT" foo)
assert_eq "T2 foo + [foo, foo-1] -> foo-2" "foo-2" "$out"

# T3: current name already has -N suffix; strip to derive base
out=$(printf 'foo-1\n' | "$SCRIPT" foo-1)
assert_eq "T3 foo-1 + [foo-1] -> foo-2" "foo-2" "$out"

# T4: unrelated bases don't influence the count
out=$(printf 'foo\nfoo-1\nbar\n' | "$SCRIPT" bar)
assert_eq "T4 bar + [foo, foo-1, bar] -> bar-1" "bar-1" "$out"

# T5: prefix-only matches (foobar) are not siblings of foo
out=$(printf 'foo\nfoobar\n' | "$SCRIPT" foo)
assert_eq "T5 foo + [foo, foobar] -> foo-1" "foo-1" "$out"

# T6: name with non-numeric dash chunk should not be stripped (foo-bar -> foo-bar-1)
out=$(printf 'foo-bar\n' | "$SCRIPT" foo-bar)
assert_eq "T6 foo-bar + [foo-bar] -> foo-bar-1" "foo-bar-1" "$out"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[[ $fail -eq 0 ]]
