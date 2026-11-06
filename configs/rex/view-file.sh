#!/bin/sh
# Render one file in the terminal. Used both as the fzf preview and as the
# final viewer, so a preview is never a lie about what you will get.
#
#   view-file.sh [--preview] PATH
#
# Markdown -> glow, images -> chafa, everything else -> bat (or plain).
# Always exits 0 so a preview failure never kills the fzf session.

GLOW=/opt/homebrew/bin/glow
CHAFA=/opt/homebrew/bin/chafa
BAT=/Users/yuxi/.cargo/bin/bat
FFMPEG=/opt/homebrew/bin/ffmpeg

# Rex runs blocks with shell = "none" and a short PATH where glow's default
# pager (less) may be missing, so never let glow or bat page: render to stdout
# and let the pane's own scrollback hold the output.
PAGER=cat
LESS=
MANPAGER=cat
GIT_PAGER=cat
export PAGER LESS MANPAGER GIT_PAGER

preview=0
if [ "$1" = "--preview" ]; then
  preview=1
  shift
fi

path=$1
[ -n "$path" ] || exit 0

if [ ! -e "$path" ]; then
  printf 'not found: %s\n' "$path"
  exit 0
fi

# Directories are listed rather than viewed.
if [ -d "$path" ]; then
  ls -la "$path" 2>/dev/null | head -200
  exit 0
fi

name=$(basename "$path")
lower=$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]')

ext=${lower##*.}
[ "$ext" = "$lower" ] && ext=""

# Terminals only render text, so images are drawn as character art. The
# preview pane is narrower, so size it differently from the full pane.
art_size() {
  if [ "$preview" -eq 1 ]; then
    printf '%s' "70x"   # fzf sizes the height from the window
  else
    printf '%s' "100x"
  fi
}

case "$ext" in
  # ---- images: character art ----------------------------------------------
  png|jpg|jpeg|gif|webp|bmp|tif|tiff|avif|heic|ico|svg)
    # chafa is the only renderer that works here: Rex does not implement the
    # kitty or iterm pixel protocols, so pixel graphics come out blank.
    if [ "$ext" = "svg" ]; then
      # chafa reads a limited set of SVG; fall back to the raw source.
      if "$CHAFA" --size="$(art_size)" "$path" 2>/dev/null; then
        exit 0
      fi
      head -c 20000 "$path"
      exit 0
    fi

    # Animated formats: show the first frame, and say how long the clip is.
    case "$ext" in
      gif|webp|avif)
        if command -v "$FFMPEG" >/dev/null 2>&1; then
          tmp=$(mktemp -t viewframe) || tmp=
          if [ -n "$tmp" ] && "$FFMPEG" -y -v error -i "$path" -frames:v 1 "$tmp.png" 2>/dev/null; then
            "$CHAFA" --size="$(art_size)" "$tmp.png"
            # The Duration banner is printed at info level, so probe with -v info
            # (not -v error, which suppresses it). -f null keeps it from wanting
            # an output file.
            info=$("$FFMPEG" -hide_banner -v info -i "$path" -f null - 2>&1 | grep -o 'Duration: [0-9:.]*' | head -1)
            [ -n "$info" ] && printf '\n%s\n' "$info"
            rm -f "$tmp" "$tmp.png"
            exit 0
          fi
          [ -n "$tmp" ] && rm -f "$tmp" "$tmp.png"
        fi
        ;;
    esac

    if ! "$CHAFA" --size="$(art_size)" "$path" 2>/dev/null; then
      printf 'cannot render %s\n' "$name"
      printf 'no image decoder for this format\n'
    fi
    exit 0
    ;;

  # ---- markdown ------------------------------------------------------------
  md|markdown|mdown|mkd)
    # Always render to stdout: `glow -p` needs a pager on Rex's short PATH and
    # would otherwise trap the pane. Preview and final view are identical, so
    # the preview is never a lie about what you get.
    "$GLOW" -s dark "$path" 2>/dev/null || head -c 20000 "$path"
    exit 0
    ;;

  # ---- diffs / patches: show as a diff, not as text ------------------------
  diff|patch)
    "$BAT" --style=plain --color=always --pager=never "$path" 2>/dev/null || cat "$path"
    exit 0
    ;;
esac

# ---- everything else: highlight, or dump if it looks binary --------------
# A NUL byte in the first 4 KiB is the usual "this is binary" signal. Stream
# the first 4 KiB through `tr -d '\0'` and compare byte counts with the raw
# read: never round-trip binary through a shell variable (it cannot hold NUL),
# and never build a grep pattern from `$(printf '\0')` (it expands to "" and
# then matches every line).
raw_bytes=$(head -c 4096 "$path" 2>/dev/null | wc -c | tr -d ' ')
text_bytes=$(head -c 4096 "$path" 2>/dev/null | LC_ALL=C tr -d '\0' | wc -c | tr -d ' ')
if [ "$raw_bytes" -ne "$text_bytes" ]; then
  printf '%s\n' "$name"
  ls -lh "$path" 2>/dev/null | awk '{print $5, $6, $7, $8}'
  printf '\n(binary file, not shown)\n'
  exit 0
fi

if [ "$preview" -eq 1 ]; then
  "$BAT" --style=plain --color=always --pager=never --line-range=:500 "$path" 2>/dev/null \
    || head -c 20000 "$path"
else
  "$BAT" --style=plain --pager=never --line-range=:2000 "$path" \
    || head -c 20000 "$path"
fi
