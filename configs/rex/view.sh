#!/bin/sh
# fzf file viewer for Rex.
#
#   view.sh [DIR]
#
# Opens on the git dirty files (staged, unstaged, untracked) — the files you
# are actually working on. ctrl-a reloads to every tracked file in the repo,
# ctrl-d reloads back to dirty. Enter renders the choice with view-file.sh.
#
# The picker is a loop: after a file renders, any key returns you to the menu,
# so you can walk a set of dirty files without reopening the pane. Nothing in
# here closes the pane — that is Cmd+W — so there is no exit path to strand a
# frozen pane on.
#
# Uses fzf's own reload binding rather than merging the two lists up front: a
# merged list has to be sorted to dedupe, and sorting scatters the dirty files
# alphabetically, which is exactly what this is trying to avoid.
#
# The pane is created with exit.on_completion = false, so it stays open after
# this script exits. Every outcome must leave something readable, and nothing
# here exits on purpose: a pane is closed with Cmd+W, not from this script.

dir=${1:-.}
cd "$dir" || {
  printf 'cannot enter %s\n' "$dir" >&2
  exit 1
}

FZF=/opt/homebrew/bin/fzf

# Rendering needs a keypress to return, and `read -n` is a bashism: plain POSIX
# read would wait for Enter and, worse, a shell without -n fails and loops with
# an empty key forever. Test for it once and skip the pause if it is missing.
CAN_READ_KEY=no
if [ -t 0 ] && printf 'x' | { IFS= read -r -n 1 -s _ 2>/dev/null; } ; then
  CAN_READ_KEY=yes
fi

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

# The two candidate lists, as shell functions. Each prints root-relative paths,
# one per line, in the order git gives them. They are functions rather than
# quoted one-liners so fzf's reload binding can name them instead of re-quoting
# a whole pipeline inside a --bind argument.
#
# `-z` is what makes paths with spaces work. Plain porcelain quotes and
# C-escapes such names ("a file.md"), and the viewer would then look for a file
# whose name really contains quote characters. `-z` output is NUL-separated and
# never quoted, so swap the NULs for newlines and parse the porcelain status
# prefix: two status columns, a space, then the path. Renames and copies put the
# destination first and the source in a second field, which the skip consumes.
# Untracked directories arrive as "dir/" and are dropped, because the viewer
# cannot open a directory.
list_dirty() {
  git status --porcelain=v1 -z 2>/dev/null | tr '\0' '\n' | awk '
    skip { skip = 0; next }
    {
      st = substr($0, 1, 2)
      path = substr($0, 4)
      if (st ~ /[RC]/) skip = 1
      if (path == "" || path ~ /\/$/) next
      print path
    }'
}
list_all() {
  git ls-files -z 2>/dev/null | tr '\0' '\n'
}

# No git repo: fall back to the file tree, and there is nothing to reload to.
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  list_dirty() {
    find . -type f -not -path './.git/*' | sed 's|^\./||'
  }
  list_all() { list_dirty; }
fi

cd "$root" || {
  printf 'cannot enter %s\n' "$root" >&2
  exit 1
}

# A clean repo has no dirty files, so opening on the dirty list would show an
# empty menu that nothing can be picked from. Open on the full list instead,
# with a prompt that says so rather than lying about being dirty.
initial=list_dirty
initial_prompt='dirty> '
if [ -z "$(list_dirty)" ]; then
  initial=list_all
  initial_prompt='files> '
fi

# fzf runs the list commands itself, so no shell variable ever holds the file
# list. It inherits these functions, so the reload bindings can call them.
#
# The loop is what makes "back to search" work: the viewer runs in this shell
# instead of replacing it with exec, so after it exits we can return to fzf.
while :; do
  sel=$(
    "$initial" | "$FZF" \
      --prompt="$initial_prompt" \
      --height=100% \
      --reverse \
      --no-multi \
      --bind='esc:abort' \
      --bind='ctrl-c:abort' \
      --bind='ctrl-a:reload(list_all)+change-prompt(all> )' \
      --bind='ctrl-d:reload(list_dirty)+change-prompt(dirty> )' \
      --delimiter='/' \
      --preview="$viewer --preview \"$root/{}\"" \
      --preview-window='right,60%,border-left'
  ) || sel=

  # Esc or ctrl-c at the menu: nothing chosen. Say so and wait for a key before
  # redrawing, or fzf would wipe the message instantly and this would spin. With
  # no keypress available, fall through and redraw once rather than hang.
  if [ -z "$sel" ]; then
    clear
    printf 'nothing picked — press any key for the menu, Cmd+W to close this pane\n'
    if [ "$CAN_READ_KEY" = yes ]; then
      IFS= read -r -n 1 -s _ || :
    fi
    continue
  fi

  # Render in this shell rather than exec'ing, so the loop can resume. Start
  # from a clean screen, or the rendered file would stack under the last one.
  clear
  "$viewer" "$root/$sel"

  # Any key returns to the menu, q and Esc included. Keep the pane useful when
  # stdin is not a terminal or the shell cannot read a single key: without a
  # keypress to read, let the render stand rather than looping forever.
  if [ "$CAN_READ_KEY" = yes ]; then
    printf '\n\n-- %s --  press any key for the list, Cmd+W to close --\n' "$sel"
    # Read one key without newline, so a single press returns. -r keeps
    # backslashes literal; -s hides the keystroke.
    IFS= read -r -n 1 -s _ || :
  fi
done
