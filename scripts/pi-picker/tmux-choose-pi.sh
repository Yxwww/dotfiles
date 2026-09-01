#!/usr/bin/env bash
# Jump to a pi coding-agent pane via an fzf picker with live TUI preview.
set -euo pipefail

# Resolve the script's own dir (handles invocation via ~/.tmux/scripts symlink).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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

target="${chosen%%$'\t'*}"   # field 1: session:window.pane
session="${target%%:*}"      # everything before the first ':'

tmux switch-client -t "$session" \; select-window -t "$target" \; select-pane -t "$target"