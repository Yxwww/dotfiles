#!/usr/bin/env bash
# Jump to a pi coding-agent pane via an fzf picker with live TUI preview.
set -euo pipefail

# Resolve the script's own dir (handles invocation via ~/.tmux/scripts symlink).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------------------------------------------------------------------------
# jump_to_pane: act on a chosen `list` row.
# ---------------------------------------------------------------------------
#
# Jump by the STABLE pane id (field 2), never by field 1.
#
# Field 1 is `session:window_index.pane_index` -- a positional address. tmux
# renumbers those whenever any window or pane closes, and pane indices compact
# unconditionally (window indices too, with `renumber-windows on`). So between
# `list` printing the row and the user pressing Enter, the same string can name
# a DIFFERENT pane. tmux resolves a stale index happily and exits 0, so the jump
# lands on an unrelated agent with no error at all. `%pane_id` is invariant
# under renumbering.
#
# The session is re-derived from the pane id rather than parsed out of field 1:
# a session rename between list and Enter makes the snapshot's name invalid, and
# field 1's `session:index` split would then target a session that is gone.
jump_to_pane() {
  local line="$1"
  local pane_id session

  # Field 2 of a list row. TAB-delimited; the path is terminal and may itself
  # contain TABs, so only the first three fields are read.
  IFS=$'\t' read -r _target pane_id _ <<<"$line"
  if [ -z "$pane_id" ]; then
    echo "pi-picker: malformed row (no pane id): $line" >&2
    return 1
  fi

  # Resolve against the live server. A pane that died while fzf was open must
  # fail loudly -- the old code silently jumped to whatever the stale index
  # happened to name, which is the bug this replaces.
  if ! session="$(tmux display-message -p -t "$pane_id" '#{session_name}' 2>/dev/null)" \
     || [ -z "$session" ]; then
    echo "pi-picker: pane $pane_id no longer exists" >&2
    return 1
  fi

  tmux switch-client -t "$session" \; select-window -t "$pane_id" \; select-pane -t "$pane_id"
}

# Sourced by the test suite to load jump_to_pane without opening a picker.
if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
  return 0
fi

PREVIEW_CMD="node \"$SCRIPT_DIR/tmux-choose-pi.js\" preview {2}"

rows="$(node "$SCRIPT_DIR/tmux-choose-pi.js" list)"
if [ -z "$rows" ]; then
  echo "No π (pi) agent panes found." >&2
  exit 0
fi

# fzf prints the chosen line on stdout; empty + non-zero exit on cancel.
if ! chosen="$(printf '%s\n' "$rows" | fzf \
  --ansi --delimiter '\t' --with-nth 3 \
  --layout=reverse --border=rounded --border-label ' pi agents ' \
  --preview "$PREVIEW_CMD" \
  --preview-window 'right:45%:wrap:border' --preview-label ' status ' \
  --info=inline --prompt ' jump › ' --pointer '▸' --marker '✓' \
  --header 'enter jump · esc cancel')"; then
  exit 0
fi

jump_to_pane "$chosen"
