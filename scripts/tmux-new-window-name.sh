#!/usr/bin/env bash
# Compute a new tmux window name based on the current window's name and
# the list of already-open window names (read from stdin, one per line).
# Usage: tmux-new-window-name <current_window_name>
#
# Strips a trailing -<digits> from the current name to derive `base`,
# then prints `<base>-<N>` where N is the smallest integer >= 1 such that
# `<base>-<N>` does not already appear in the input list.

set -u

current="$1"
existing=$(cat)

base="${current%-*}"
[[ "$base" == "$current" || ! "${current##*-}" =~ ^[0-9]+$ ]] && base="$current"

n=1
while printf '%s\n' "$existing" | grep -Fxq -- "${base}-${n}"; do
  n=$((n + 1))
done
echo "${base}-${n}"
