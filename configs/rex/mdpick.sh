#!/bin/sh
# Pick a markdown file in $1 (default: cwd) with fzf, then render it with glow
# in the same pane. Exits non-zero if nothing was chosen, so Rex closes the pane.
#
# Run as: mdpick.sh [DIR] [QUERY]
#   DIR    directory to search. Relative paths resolve against the cwd.
#   QUERY  initial fzf query, e.g. "AGENT".

dir=${1:-.}
query=${2:-}

cd "$dir" || {
  printf 'cannot enter %s\n' "$dir" >&2
  exit 1
}

# fzf's Homebrew path: the Rex server's PATH lacks /opt/homebrew/bin.
FZF=/opt/homebrew/bin/fzf
GLOW=/opt/homebrew/bin/glow

# Bail out early when there is nothing to choose: an empty fzf list would just
# sit there waiting. Reads the list twice, which is cheap at this size.
count=$(find . -maxdepth 1 -name '*.md' -not -name '.*' -type f -print | wc -l | tr -d ' ')
if [ "$count" -eq 0 ]; then
  printf 'no .md files in %s\n' "$dir"
  sleep 2
  exit 0
fi

sel=$(
  find . -maxdepth 1 -name '*.md' -not -name '.*' -type f -print \
    | sed 's|^\./||' \
    | LC_ALL=C sort \
    | "$FZF" \
        --prompt='markdown> ' \
        --height=100% \
        --reverse \
        --no-multi \
        --query="$query" \
        --bind='esc:abort'
) || exit 0   # fzf exits 130 on Esc, 1 when nothing matched

[ -n "$sel" ] || exit 0

exec "$GLOW" -p "$sel"
