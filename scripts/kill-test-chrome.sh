#!/usr/bin/env bash
# Kill Chrome-for-Testing processes spawned by Playwright / agent-browser.
# Usage: kill-test-chrome.sh [-n|--dry-run]
#
# Matches the Playwright fingerprint only — the chromium binary under
# ms-playwright/ and the throwaway --user-data-dir=...playwright... profile —
# so your everyday Chrome / Chrome for Testing sessions are left alone.
#
# Sends SIGTERM first for a clean shutdown, waits briefly, then SIGKILLs any
# stragglers (e.g. reparented crashpad handlers).

set -u

# Single source of truth for "is this a Playwright-launched browser?".
PATTERN='ms-playwright/chromium|user-data-dir=[^ ]*playwright'

dry_run=0
case "${1:-}" in
  -n|--dry-run) dry_run=1 ;;
  -h|--help)    sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  "")           ;;
  *)            echo "Unknown arg: $1 (try --help)" >&2; exit 2 ;;
esac

pids=$(pgrep -f "$PATTERN" || true)
if [ -z "$pids" ]; then
  echo "No Playwright/agent-browser Chrome processes found."
  exit 0
fi

count=$(echo "$pids" | wc -l | tr -d ' ')

if [ "$dry_run" -eq 1 ]; then
  echo "Would kill $count process(es):"
  pgrep -fl "$PATTERN"
  exit 0
fi

echo "$pids" | xargs kill -TERM 2>/dev/null
sleep 1
# Anything that ignored SIGTERM gets SIGKILL.
stragglers=$(pgrep -f "$PATTERN" || true)
[ -n "$stragglers" ] && echo "$stragglers" | xargs kill -KILL 2>/dev/null

remaining=$(pgrep -cf "$PATTERN" || true)
echo "Killed $count process(es); $remaining remaining."
