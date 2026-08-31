#!/usr/bin/env bash
# Jump to a pi coding-agent pane via an fzf picker with live TUI preview.
set -euo pipefail

TAB=$'\t'

# List every π/pi: pane, tab-delimited, title enriched with the git branch:
#   field 1: session:window.pane   field 2: pane_id   field 3: title (branch)   field 4: cwd
list_panes() {
  local target pid title path branch disp
  while IFS="$TAB" read -r target pid title path; do
    branch="$(git -C "$path" symbolic-ref --short -q HEAD 2>/dev/null || true)"
    if [ -n "$branch" ]; then
      disp="$title ($branch)"
    else
      disp="$title"
    fi
    printf '%s\t%s\t%s\t%s\n' "$target" "$pid" "$disp" "$path"
  done < <(tmux list-panes -a -F \
    "#{session_name}:#{window_index}.#{pane_index}${TAB}#{pane_id}${TAB}#{pane_title}${TAB}#{pane_current_path}" \
    | awk -F "$TAB" '$3 ~ /^(π|pi:)/')
}

panes="$(list_panes)"

if [ -z "$panes" ]; then
  echo "No π (pi) agent panes found." >&2
  exit 0
fi

# fzf prints the full chosen line on stdout; empty + non-zero exit on cancel.
if ! chosen="$(printf '%s\n' "$panes" | fzf \
  --with-nth 3 \
  --delimiter '\t' \
  --preview '~/.tmux/scripts/tmux-choose-pi-preview.js {2}' \
  --preview-window 'right:55%:wrap' \
  --header 'PI agents — enter to jump, esc to cancel')"; then
  exit 0
fi

target="${chosen%%$'\t'*}"   # field 1: session:window.pane
session="${target%%:*}"      # everything before the first ':'

tmux switch-client -t "$session" \; select-window -t "$target" \; select-pane -t "$target"