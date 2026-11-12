#!/bin/sh
# Keep one titles.lua daemon running per Rex session.
#
# A rex do script is bound to one session (cross-session view is refused with
# 409 and rex.session.attach does not re-scope it), so titling every session
# means one daemon each. Re-run this after opening a new session; it only
# starts daemons for sessions that do not have one yet.
#
# Usage:  rex-titles.sh          start daemons
#         rex-titles.sh --stop   stop them
set -eu

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SCRIPT="$HERE/titles.lua"
RUN_DIR="${XDG_RUNTIME_DIR:-/tmp}/rex-titles"
mkdir -p "$RUN_DIR"

if [ "${1:-}" = "--stop" ]; then
  for pidfile in "$RUN_DIR"/*.pid; do
    [ -e "$pidfile" ] || continue
    pid=$(cat "$pidfile")
    if ps -p "$pid" -o command= 2>/dev/null | grep -q 'titles\.lua'; then
      kill "$pid" 2>/dev/null || true
    fi
    rm -f "$pidfile"
  done
  echo "stopped"
  exit 0
fi

[ -r "$SCRIPT" ] || { echo "missing $SCRIPT" >&2; exit 1; }

rex ls --json | jq -r '.sessions[] | "\(.session_id)\t\(.label)"' |
while IFS="$(printf '\t')" read -r sid label; do
  [ -n "$sid" ] || continue
  key=$(printf '%s' "$sid" | tr -cd 'a-zA-Z0-9')
  pidfile="$RUN_DIR/$key.pid"

  # Trust a pidfile only when the process is still one of our daemons; a
  # recycled PID would otherwise skip this session forever.
  if [ -f "$pidfile" ]; then
    pid=$(cat "$pidfile")
    if kill -0 "$pid" 2>/dev/null && ps -p "$pid" -o command= 2>/dev/null | grep -q 'titles\.lua'; then
      continue
    fi
  fi

  rex do -s "$sid" "$SCRIPT" >"$RUN_DIR/$key.log" 2>&1 &
  echo $! >"$pidfile"
  echo "titles: $label"
done
