#!/usr/bin/env bash
#
# fanout.sh — orchestrate parallel `pi -p` subagents in tmux panes, with an
# optional Devil's Advocate review phase. Companion to the tmux-fanout skill.
#
# PROTOCOL (see SKILL.md for the why):
#   /tmp/pi-fanout/<jobid>/
#     manifest.json        window/pane -> role mapping (for recovery)
#     <role>.brief.md      wrapped brief actually piped to `pi -p`
#     <role>.log           `tee` of the agent's stdout/stderr
#     <role>.done          touched by the agent as its FINAL action
#     <role>.result        structured summary the agent writes before .done
#     reviewer.brief.md    generated from the diff + worker .result files
#     reviewer.{log,done,result} + verdict.json
#
# The script PREPENDS a protocol preamble to each caller-supplied brief so the
# brief author never has to mention .done/.result paths. A worker brief only
# describes the work; the preamble tells the agent how to signal completion.
#
# USAGE
#   fanout.sh run [--no-review] [--timeout 1200] -- <role>=<brief.md> [role=brief.md ...]
#   fanout.sh list
#   fanout.sh status <jobid>
#   fanout.sh kill <jobid>
#   fanout.sh logs <jobid> [role]
#
# Requires: tmux, pi (on $PATH). Run from the repo working tree you want the
# agents to operate in; that cwd is reused by the reviewer for `git diff`.

set -euo pipefail

FANOUT_ROOT="${PI_FANOUT_ROOT:-/tmp/pi-fanout}"
AGENT_CMD="${PI_FANOUT_AGENT:-pi}"   # any CLI that reads a prompt from argv and exits

die() { echo "fanout: $*" >&2; exit 1; }
jobdir() { echo "$FANOUT_ROOT/$1"; }

new_jobid() {
  printf 'job-%s-%s' "$(date +%Y%m%d-%H%M%S)" "$(head -c4 /dev/urandom | base64 | tr -dc 'a-z0-9' | head -c4)"
}

# Wrap a caller brief with the completion protocol. $1=jobid $2=role $3=brief path
write_wrapped_brief() {
  local jid="$1" role="$2" src="$3" out; out="$(jobdir "$jid")/${role}.brief.md"
  {
    echo "# Worker: ${role}"
    echo
    cat <<EOF
## Completion protocol (injected by fanout.sh — do not omit these steps)

You are one of several parallel subagents. When you finish your work, do BOTH,
in this order, as your final actions:

1. Write a concise structured summary to: $(jobdir "$jid")/${role}.result
   Include: what you did, every file you created/edited, how you verified it,
   and any deviations from the brief or blockers you hit. Be specific — a
   downstream reviewer agent will read this to challenge your work.
2. Then run exactly: \`touch $(jobdir "$jid")/${role}.done\`
   This file is the orchestrator's completion signal. Without it the
   orchestrator will keep waiting and eventually time out the whole job.

Do not commit. Do not touch files outside the scope below. Do not wait for
input — this brief is the only instruction you will receive.

---

EOF
    cat "$src"
  } > "$out"
}

cmd_run() {
  local review=1 timeout=1200
  while [ $# -gt 0 ]; do
    case "$1" in
      --no-review) review=0; shift;;
      --timeout) timeout="$2"; shift 2;;
      --) shift; break;;
      *) die "unknown option: $1";;
    esac
  done
  [ $# -ge 1 ] || die "usage: fanout.sh run [--no-review] [--timeout N] -- role=brief.md [...]"
  command -v tmux >/dev/null || die "tmux not found"
  command -v "$AGENT_CMD" >/dev/null || die "$AGENT_CMD not found on PATH"

  local jid; jid="$(new_jobid)"; local jd; jd="$(jobdir "$jid")"
  mkdir -p "$jd"
  local cwd="$PWD"

  local roles=()
  for pair in "$@"; do
    local role="${pair%%=*}" brief="${pair#*=}"
    [ "$role" != "$pair" ] || die "expected role=path.md, got: $pair"
    [ -f "$brief" ] || die "brief not found for $role: $brief"
    [[ "$role" =~ ^[a-zA-Z0-9_-]+$ ]] || die "bad role name: $role (alnum/_/- only)"
    write_wrapped_brief "$jid" "$role" "$brief" >/dev/null
    roles+=("$role")
  done

  local win
  win="$(tmux new-window -d -n "fanout-$jid" -c "$cwd" -P -F '#{window_id}')"
  local first_pane; first_pane="$(tmux list-panes -t "$win" -F '#{pane_id}' | head -1)"
  local panes=("$first_pane") pane_role=("${roles[0]}")
  for i in "${!roles[@]}"; do
    [ "$i" -eq 0 ] && continue
    local p; p="$(tmux split-window -h -t "$win" -c "$cwd" -P -F '#{pane_id}')"
    panes+=("$p"); pane_role+=("${roles[$i]}")
  done
  tmux select-layout -t "$win" tiled >/dev/null 2>&1 || true

  {
    echo "{"
    echo "  \"jobid\": \"$jid\","
    echo "  \"window\": \"$win\","
    echo "  \"cwd\": \"$cwd\","
    echo "  \"review\": $review,"
    echo "  \"panes\": ["
    for i in "${!panes[@]}"; do
      local comma=""; [ "$i" -gt 0 ] && comma=","
      printf '%s    {"role": "%s", "pane": "%s"}\n' "$comma" "${pane_role[$i]}" "${panes[$i]}"
    done
    echo "  ]"
    echo "}"
  } > "$jd/manifest.json"

  for i in "${!panes[@]}"; do
    local role="${pane_role[$i]}" pane="${panes[$i]}" brief="$jd/${pane_role[$i]}.brief.md"
    tmux send-keys -t "$pane" \
      "$AGENT_CMD -p \"\$(cat $(printf %q "$brief"))\" 2>&1 | tee $(printf %q "$jd/$role.log"); echo \"EXIT=\$?\" >> $(printf %q "$jd/$role.log")" \
      C-m
  done

  echo "fanout: job $jid launched in window $win ($(IFS=,; echo "${roles[*]}"))"
  echo "fanout: jobdir $jd"
  echo "fanout: tail -f $jd/*.log   # watch progress"

  local start=$SECONDS
  while true; do
    local missing=()
    for r in "${roles[@]}"; do
      [ -f "$jd/$r.done" ] || missing+=("$r")
    done
    if [ ${#missing[@]} -eq 0 ]; then
      echo "fanout: all workers done."
      break
    fi
    if [ $((SECONDS - start)) -ge "$timeout" ]; then
      echo "fanout: TIMEOUT after ${timeout}s. Still waiting on: ${missing[*]}" >&2
      echo "fanout: inspect with: fanout.sh status $jid ; fanout.sh logs $jid" >&2
      exit 2
    fi
    for r in "${missing[@]}"; do
      local p; p="$(pane_for_role "$jid" "$r")"
      local cmd; cmd="$(tmux display -p -t "$p" '#{pane_current_command}' 2>/dev/null || echo gone)"
      if [[ "$cmd" =~ ^(zsh|bash|sh|fish)$ ]] && grep -q '^EXIT=' "$jd/$r.log" 2>/dev/null; then
        echo "fanout: worker '$r' exited without signaling .done (pane now $cmd). Check $jd/$r.log" >&2
      fi
    done
    sleep 3
  done

  if [ "$review" -eq 1 ]; then
    run_reviewer "$jid" "$win" "$cwd" "$timeout"
  fi
  echo "fanout: done. verdict: $jd/verdict.json  (summary: $jd/reviewer.result)"
}

pane_for_role() {
  local jd; jd="$(jobdir "$1")" role="$2"
  grep -A2 "\"role\": \"$role\"" "$jd/manifest.json" | grep -o '"pane": "[^"]*"' | head -1 | cut -d'"' -f4
}

run_reviewer() {
  local jid="$1" win="$2" cwd="$3" timeout="$4"; local jd; jd="$(jobdir "$jid")"
  echo "fanout: launching Devil's Advocate reviewer..."
  local rb="$jd/reviewer.brief.md"
  {
    echo "# Devil's Advocate review for job $jid"
    echo
    echo "You are the reviewer for a parallel subagent run. Your job is to NOT"
    echo "rubber-stamp. Challenge every claim, demand evidence, and verify by"
    echo "running commands — do not reason from the summaries alone."
    echo
    echo "Working directory: \`$cwd\` (cd there first)."
    echo "Job directory (write all outputs here): \`$jd\`"
    echo
    echo "## Worker summaries"
    for f in "$jd"/*.result; do
      [ -f "$f" ] || continue
      local r; r="$(basename "$f" .result)"
      [ "$r" = "reviewer" ] && continue
      echo
      echo "### $r"
      echo '```'
      cat "$f"
      echo '```'
    done
    echo
    cat <<'WHATDO'
## What to do

1. Read every worker summary above. Then independently verify each claim:
   - `cd <cwd>` and run `git status --short` and `git diff --stat` to see what
     actually changed.
   - For each file a worker claims to have created/edited, open it and check it
     exists and does what's claimed. Run any tests/type-checks/build the workers
     claim passed — do not trust, re-run.
   - Grep for the things workers say they wired up (symlinks, imports, config
     keys). A missing symlink or un-wired import is the most common failure.
2. Look for cross-worker conflicts: two workers editing the same file, dangling
   references, or one worker's output assuming another's that didn't land.
3. Look for over-claims: "verified" without evidence, "tests pass" without a
   re-run, sentinel/path mismatches between coupled files.

## Output

WHATDO
    echo "Write your verdict to $jd/verdict.json with this shape:"
    echo
    cat <<'JSONEOF'
```json
{
  "approved": true,
  "per_role": [
    {"role": "<name>", "issues": ["..."], "verified": ["git diff", "ran bun build", ...]}
  ],
  "blocking": ["issue that must be fixed before merge", ...],
  "nits": ["non-blocking", ...]
}
```

Set `approved: false` if any `blocking` entry exists.
JSONEOF
    echo "Then write a short prose summary to $jd/reviewer.result, and finally"
    echo "run: touch $jd/reviewer.done"
    echo "Do not fix the work yourself — only report. Do not commit."
    echo "report. Do not commit."
  } > "$rb"

  local pane; pane="$(tmux split-window -h -t "$win" -c "$cwd" -P -F '#{pane_id}')"
  tmux send-keys -t "$pane" \
    "$AGENT_CMD -p \"\$(cat $(printf %q "$rb"))\" 2>&1 | tee $(printf %q "$jd/reviewer.log"); echo \"EXIT=\$?\" >> $(printf %q "$jd/reviewer.log")" \
    C-m

  local start=$SECONDS
  while true; do
    [ -f "$jd/reviewer.done" ] && { echo "fanout: reviewer done."; break; }
    if [ $((SECONDS - start)) -ge "$timeout" ]; then
      echo "fanout: reviewer TIMEOUT after ${timeout}s." >&2; exit 3
    fi
    sleep 3
  done
}

cmd_list() {
  tmux list-windows -a -F '#{window_name} #{window_id}' 2>/dev/null | grep '^fanout-' || echo "(no fanout windows)"
}

cmd_status() {
  [ -n "${1:-}" ] || die "usage: fanout.sh status <jobid>"
  local jd; jd="$(jobdir "$1")"; [ -d "$jd" ] || die "no such job: $1"
  echo "job $1  ($jd)"
  for f in "$jd"/*.result; do
    [ -f "$f" ] || continue
    local r; r="$(basename "$f" .result)"
    local done="pending"; [ -f "$jd/$r.done" ] && done="done"
    printf '  %-16s %s\n' "$r" "$done"
  done
  [ -f "$jd/verdict.json" ] && { echo "verdict:"; cat "$jd/verdict.json"; }
}

cmd_logs() {
  [ -n "${1:-}" ] || die "usage: fanout.sh logs <jobid> [role]"
  local jd; jd="$(jobdir "$1")"; [ -d "$jd" ] || die "no such job: $1"
  if [ -n "${2:-}" ]; then tail -n50 "$jd/$2.log" 2>/dev/null || die "no log for $2"
  else for f in "$jd"/*.log; do echo "===== $(basename "$f") ====="; tail -n20 "$f"; done; fi
}

cmd_kill() {
  [ -n "${1:-}" ] || die "usage: fanout.sh kill <jobid>"
  local jd; jd="$(jobdir "$1")"
  local win; win="$(grep -o '"window": "[^"]*"' "$jd/manifest.json" 2>/dev/null | cut -d'"' -f4)"
  [ -n "$win" ] && tmux kill-window -t "$win" 2>/dev/null && echo "fanout: killed window $win"
  rm -rf "$jd" && echo "fanout: removed $jd"
}

case "${1:-}" in
  run) shift; cmd_run "$@";;
  list) cmd_list;;
  status) shift; cmd_status "$@";;
  logs) shift; cmd_logs "$@";;
  kill) shift; cmd_kill "$@";;
  ""|-h|--help) sed -n '1,34p' "$0";;
  *) die "unknown command: $1 (try: run, list, status, logs, kill)";;
esac
