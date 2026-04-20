#!/usr/bin/env bash
# DexHub Parser — Inbox Watcher (parser.inbox_watcher)
# ==========================================================
# Continuously monitors the inbox and auto-processes files as they
# arrive. Wraps inbox-auto-parse.sh so the "drop a file → it shows up
# in the L2 Tank" loop is zero-friction.
#
# Complementary to the one-shot parser.inbox_auto_parse:
#   - inbox-auto-parse.sh = single batch run (manual or cron trigger)
#   - inbox-watch.sh      = long-running process, fires per-file
#
# Detection methods (auto or user-selected via --method):
#   fswatch  — macOS / BSD / cross-platform. brew install fswatch.
#              Real-time (kernel event), negligible CPU.
#   inotify  — Linux. apt install inotify-tools (inotifywait binary).
#              Real-time (kernel event), negligible CPU.
#   poll     — Universal fallback. find-based polling loop (default
#              10s interval). Works everywhere, no install; tiny CPU
#              cost; latency = interval.
#
# NOT a daemon. Runs in foreground until SIGINT/SIGTERM. Users who
# want background: `nohup bash inbox-watch.sh --start &`, tmux/screen,
# or a systemd user service. Daemonization is explicitly out of scope
# (see known_issues for rationale).
#
# Feature: parser.inbox_watcher
# Phase:   5.3.i (first slice — polling + fswatch/inotify scaffold)
#
# Usage:
#   bash inbox-watch.sh --start                   # foreground watch
#   bash inbox-watch.sh --once                    # single pass, exit
#   bash inbox-watch.sh --dry-run                 # plan only, no processing
#   bash inbox-watch.sh --method fswatch --start  # force fswatch method
#   bash inbox-watch.sh --interval 5 --start      # 5s polling (poll only)
#   bash inbox-watch.sh --inbox PATH --start      # custom inbox location
#
# Exit codes:
#   0  normal exit (Ctrl-C, one-shot completed)
#   1  bad args
#   2  missing dependency (inbox-auto-parse.sh)
#   3  inbox dir missing
#   4  method requested but tool not on PATH (e.g., --method fswatch
#      without fswatch installed)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
INBOX_AUTO_PARSE="$SCRIPT_DIR/inbox-auto-parse.sh"
CONFIG_YAML="$REPO_ROOT/.dexCore/_cfg/config.yaml"

MODE="start"
METHOD="auto"
INTERVAL=10
INBOX_OVERRIDE=""
FORMAT=""

while [ $# -gt 0 ]; do
  case "$1" in
    --start)    MODE="start"; shift ;;
    --once)     MODE="once"; shift ;;
    --dry-run)  MODE="dry-run"; shift ;;
    --method)   METHOD="$2"; shift 2 ;;
    --interval) INTERVAL="$2"; shift 2 ;;
    --inbox)    INBOX_OVERRIDE="$2"; shift 2 ;;
    --format)   FORMAT="$2"; shift 2 ;;
    --help|-h)
      sed -n '2,50p' "${BASH_SOURCE[0]}"
      exit 0
      ;;
    -*)
      echo "ERROR: unknown flag: $1" >&2
      exit 1
      ;;
    *)
      echo "ERROR: unexpected positional arg: $1" >&2
      exit 1
      ;;
  esac
done

# ─── Dependency check ──────────────────────────────────────────────
if [ ! -x "$INBOX_AUTO_PARSE" ]; then
  echo "ERROR: inbox-auto-parse.sh missing at $INBOX_AUTO_PARSE" >&2
  exit 2
fi

# ─── Resolve inbox (mirrors inbox-auto-parse.sh precedence) ────────
INBOX=""
if [ -n "$INBOX_OVERRIDE" ]; then
  INBOX="$INBOX_OVERRIDE"
elif [ -n "${DEXHUB_INBOX:-}" ]; then
  INBOX="$DEXHUB_INBOX"
elif [ -f "$CONFIG_YAML" ]; then
  cfg_inbox=$(ruby -e '
    val = nil
    File.foreach(ARGV[0]) do |line|
      next unless line =~ /^inbox_folder:\s*(.+?)(\s*#.*)?$/
      v = $1.strip
      v = v[1..-2] if v.length >= 2 && ((v.start_with?("\"") && v.end_with?("\"")) || (v.start_with?("'"'"'") && v.end_with?("'"'"'")))
      val = v
      break
    end
    puts val if val
  ' "$CONFIG_YAML" 2>/dev/null)
  if [ -n "$cfg_inbox" ]; then
    case "$cfg_inbox" in
      ./*) INBOX="$REPO_ROOT/${cfg_inbox#./}" ;;
      /*)  INBOX="$cfg_inbox" ;;
      *)   INBOX="$REPO_ROOT/$cfg_inbox" ;;
    esac
  fi
fi
[ -z "$INBOX" ] && INBOX="$REPO_ROOT/myDex/inbox"

if [ ! -d "$INBOX" ]; then
  echo "ERROR: inbox directory missing at $INBOX" >&2
  echo "       Create it first: mkdir -p \"$INBOX\"" >&2
  exit 3
fi

# ─── Interval validation ────────────────────────────────────────────
if ! [[ "$INTERVAL" =~ ^[0-9]+$ ]] || [ "$INTERVAL" -lt 1 ]; then
  echo "ERROR: --interval must be a positive integer (seconds); got: $INTERVAL" >&2
  exit 1
fi

# ─── Method resolution ──────────────────────────────────────────────
# auto: prefer fswatch (macOS) → inotifywait (Linux) → poll.
# explicit method: honor if tool available, else exit 4.
resolve_method() {
  local requested="$1"
  case "$requested" in
    fswatch)
      command -v fswatch >/dev/null 2>&1 && { echo "fswatch"; return; }
      echo "ERROR: --method fswatch but fswatch not on PATH. Install: brew install fswatch (macOS) or apt install fswatch (Linux)." >&2
      return 1
      ;;
    inotify)
      command -v inotifywait >/dev/null 2>&1 && { echo "inotify"; return; }
      echo "ERROR: --method inotify but inotifywait not on PATH. Install: apt install inotify-tools (Linux)." >&2
      return 1
      ;;
    poll)
      echo "poll"
      return
      ;;
    auto)
      if command -v fswatch >/dev/null 2>&1; then echo "fswatch"; return; fi
      if command -v inotifywait >/dev/null 2>&1; then echo "inotify"; return; fi
      echo "poll"
      return
      ;;
    *)
      echo "ERROR: --method must be one of: fswatch, inotify, poll, auto (got: $requested)" >&2
      return 1
      ;;
  esac
}
RESOLVED_METHOD=$(resolve_method "$METHOD") || exit 4

# ─── Banner ─────────────────────────────────────────────────────────
# Startup summary so users see what's running. Suppressed in JSON mode
# (used by tests + scripts that parse output).
if [ "$FORMAT" != "json" ] && [ "$MODE" != "dry-run" ]; then
  printf '%s\n' "╔═══ DexHub Inbox Watcher ════════════════════════╗"
  printf '  %-12s %s\n' "Inbox:" "$INBOX"
  printf '  %-12s %s\n' "Method:" "$RESOLVED_METHOD"
  [ "$RESOLVED_METHOD" = "poll" ] && printf '  %-12s %ds\n' "Interval:" "$INTERVAL"
  printf '  %-12s %s\n' "Mode:" "$MODE"
  printf '%s\n' "  Press Ctrl-C to stop."
  printf '%s\n' "╚═════════════════════════════════════════════════╝"
fi

# ─── Process one round ──────────────────────────────────────────────
# Delegate to inbox-auto-parse.sh — it already handles the per-file
# logic (route → extract → ingest → archive). Watcher only decides
# WHEN to call it; WHAT-to-do is inbox-auto-parse's job.
process_once() {
  local extra_args=()
  [ -n "$INBOX_OVERRIDE" ] && extra_args+=(--inbox "$INBOX_OVERRIDE")
  if [ "$FORMAT" = "json" ]; then
    extra_args+=(--format json)
  else
    extra_args+=(--format text)
  fi
  bash "$INBOX_AUTO_PARSE" "${extra_args[@]}"
}

# ─── Dry-run: show plan, don't do anything ─────────────────────────
if [ "$MODE" = "dry-run" ]; then
  if [ "$FORMAT" = "json" ]; then
    ruby -rjson -e '
      puts JSON.pretty_generate({
        "mode"     => "dry-run",
        "inbox"    => ARGV[0],
        "method"   => ARGV[1],
        "interval" => ARGV[2].to_i,
        "would"    => "repeatedly invoke inbox-auto-parse.sh on new files"
      })
    ' "$INBOX" "$RESOLVED_METHOD" "$INTERVAL"
  else
    printf "Dry-run: would watch %s via %s" "$INBOX" "$RESOLVED_METHOD"
    [ "$RESOLVED_METHOD" = "poll" ] && printf " every %ds" "$INTERVAL"
    printf "\n  No processing performed.\n"
  fi
  exit 0
fi

# ─── One-shot mode: single pass, exit ──────────────────────────────
if [ "$MODE" = "once" ]; then
  process_once
  exit 0
fi

# ─── --start (continuous) ──────────────────────────────────────────
# Method-specific loop. Each method calls process_once when it thinks
# a file arrived. process_once internally decides the details (it
# processes WHATEVER is in the inbox, so over-firing is harmless —
# empty inbox + auto-parse = quick no-op).

trap 'echo ""; echo "Watcher stopped."; exit 0' INT TERM

case "$RESOLVED_METHOD" in
  poll)
    # Universal fallback. Signal = any file appeared under INBOX
    # (except dotfiles + README.md, which inbox-auto-parse already
    # skips). We just invoke inbox-auto-parse on each tick — it's
    # idempotent + cheap on empty inbox.
    while true; do
      process_once
      sleep "$INTERVAL"
    done
    ;;
  fswatch)
    # fswatch emits one line per filesystem event. -l 1 batches
    # bursts (e.g., editor saves) into single events per second.
    # --event-flag-separator=|  stable for parsing if we ever need
    # event-type detail; today we just react to any event.
    fswatch -l 1 -e ".*/\.processed/.*" -- "$INBOX" | while IFS= read -r _; do
      process_once
    done
    ;;
  inotify)
    # inotifywait: -m (monitor, don't exit) -e close_write,moved_to
    # covers drag-drop + downloads + editor-save. Excludes .processed/
    # to avoid re-firing on archive moves.
    inotifywait -m -q -e close_write,moved_to --exclude '\.processed' "$INBOX" 2>/dev/null | while IFS= read -r _; do
      process_once
    done
    ;;
esac

# Reached only if the method loop exited unexpectedly
echo "WARNING: watch loop exited (method=$RESOLVED_METHOD)" >&2
exit 0
