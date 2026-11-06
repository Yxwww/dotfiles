#!/bin/sh
# fzf file viewer for Rex.
#
#   view.sh [DIR]
#
# Behaviour:
#   - Empty query + no typing  -> the git dirty file list (staged, unstaged,
#     untracked). Falls back to the tree when the repo is clean or absent.
#   - Typing filters with fzf across all files in the repo/cwd.
#   - Enter renders: markdown via glow, images via chafa, everything else via bat.
#
# fzf shows a live preview of the selection in the pane below/right.
#
# The pane is created with exit.on_completion = false, so it stays open after
# this script exits. Every outcome must therefore leave something readable,
# or an abort would strand an empty pane.

abort() {
  printf '%s\n' "$1"
}

dir=${1:-.}
cd "$dir" || {
  printf 'cannot enter %s\n' "$dir" >&2
  exit 1
}

FZF=/opt/homebrew/bin/fzf

# Resolve sibling scripts from this script's real directory. Follow the symlink
# first so a linked ~/.config/rex/view.sh still finds view-file.sh in the
# dotfiles checkout, not just next to the symlink.
self=$0
while [ -L "$self" ]; do
  target=$(readlink "$self")
  case "$target" in
    /*) self=$target ;;
    *) self=$(dirname -- "$self")/$target ;;
  esac
done
SELF_DIR=$(CDPATH= cd -- "$(dirname -- "$self")" && pwd)

root=$(git rev-parse --show-toplevel 2>/dev/null) || root=$dir

# The viewer used after selection. Shared with the preview so what you see in
# the preview is exactly what you get on Enter.
viewer=$SELF_DIR/view-file.sh

# One entry per line, root-relative, so the viewer can resolve it anywhere.
candidates=$(
  cd "$root" || exit 1
  {
    # Dirty files first: they are what you almost always want.
    git status --porcelain=v1 2>/dev/null \
      | sed 's/^...//' \
      | sed 's/.* -> //' \
      | grep -v '/$'
    # Then everything tracked, so typing can reach any file.
    git ls-files 2>/dev/null
    # Plus untracked non-ignored files deeper than the porcelain list shows.
    git ls-files --others --exclude-standard 2>/dev/null
  } | awk 'NF' | sort -u
)

# No git repo, or an empty one: fall back to a plain file listing.
if [ -z "$candidates" ]; then
  candidates=$(cd "$root" && find . -type f -not -path './.git/*' | sed 's|^\./||' | head -20000)
fi

[ -n "$candidates" ] || {
  printf 'no files in %s\n' "$root"
  sleep 2
  exit 0
}

# Count dirty files to label the prompt honestly.
dirty=$(cd "$root" && git status --porcelain=v1 2>/dev/null | wc -l | tr -d ' ')
if [ "${dirty:-0}" -gt 0 ]; then
  prompt="dirty (${dirty}) > "
else
  prompt="files > "
fi

sel=$(
  printf '%s\n' "$candidates" \
    | "$FZF" \
        --prompt="$prompt " \
        --height=100% \
        --reverse \
        --no-multi \
        --bind='esc:abort' \
        --delimiter='/' \
        --preview="$viewer --preview $root/{}" \
        --preview-window='right,60%,border-left'
) || {
  # fzf exits 130 on Esc, 1 when nothing matched.
  abort "cancelled"
  exit 0
}

[ -n "$sel" ] || {
  abort "cancelled"
  exit 0
}

exec "$viewer" "$root/$sel"
