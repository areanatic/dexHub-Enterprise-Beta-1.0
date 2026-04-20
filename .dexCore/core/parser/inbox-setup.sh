#!/usr/bin/env bash
# DexHub Parser — Inbox desktop-shortcut setup (parser.inbox_shortcut_setup)
# ==========================================================
# Creates (or removes) a Desktop shortcut pointing at myDex/inbox/ so
# users can drop files into DexHub with a drag-and-drop, without
# navigating the repo tree every time.
#
# Platform support:
#   macOS   → symlink at ~/Desktop/<name>
#              (Finder renders the symlink with the curved-arrow shortcut
#              badge; double-click opens the inbox folder.)
#   Linux   → .desktop file at ~/Desktop/<name>.desktop (Type=Link,
#              URL=file://<inbox>). Works in GNOME, KDE, XFCE, Cinnamon.
#              .desktop files need executable bit to be trusted as
#              shortcuts (we set it).
#   Windows → deferred to 1.1 roadmap (needs PowerShell .lnk recipe)
#
# Reversible: `--remove` deletes the shortcut. Idempotent: re-running
# create without --force against an existing shortcut returns exit 5
# and touches nothing. User opt-out is always possible.
#
# Locality:
#   Only touches ~/Desktop/<name>. No changes to the repo. Safe to run
#   without repo write permissions.
#
# Feature: parser.inbox_shortcut_setup
# Phase:   5.3.h (first slice — macOS + Linux; Windows is 1.1 roadmap)
#
# Usage:
#   bash inbox-setup.sh                       # create shortcut (platform default)
#   bash inbox-setup.sh --dry-run             # show plan, no filesystem change
#   bash inbox-setup.sh --force               # overwrite existing shortcut
#   bash inbox-setup.sh --name "My Inbox"     # custom shortcut name
#   bash inbox-setup.sh --inbox PATH          # override inbox location
#   bash inbox-setup.sh --remove              # delete existing shortcut
#   bash inbox-setup.sh --format json         # machine-readable
#
# Inbox location precedence (same as inbox-auto-parse.sh):
#   1. --inbox PATH flag
#   2. $DEXHUB_INBOX environment variable
#   3. inbox_folder field in .dexCore/_cfg/config.yaml
#   4. Default: <repo-root>/myDex/inbox/
#
# Exit codes:
#   0   success (created, removed, or dry-run OK)
#   1   bad args
#   2   unsupported platform (Windows today; unknown OS)
#   3   ~/Desktop missing (run shouldn't auto-create user dirs)
#   4   inbox directory missing at resolved path
#   5   shortcut exists and --force not set (create without clobber)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
CONFIG_YAML="$REPO_ROOT/.dexCore/_cfg/config.yaml"

ACTION="create"
NAME="DexHub-Inbox"
FORCE=0
DRY_RUN=0
FORMAT=""
INBOX_OVERRIDE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --remove)    ACTION="remove"; shift ;;
    --force)     FORCE=1; shift ;;
    --dry-run)   DRY_RUN=1; shift ;;
    --format)    FORMAT="$2"; shift 2 ;;
    --name)      NAME="$2"; shift 2 ;;
    --inbox)     INBOX_OVERRIDE="$2"; shift 2 ;;
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

# ─── Validate --name (Agent-β finding 2026-04-22 session-7) ────────
# Reject control characters (newline, tab, NUL) and path separators in
# the shortcut name. These would produce malformed filenames on disk,
# corrupt .desktop files on Linux, or create unfixable Desktop state.
# Printable chars (spaces, punctuation, UTF-8) are allowed — we only
# block the truly dangerous ones.
if [ -z "$NAME" ]; then
  echo "ERROR: --name must not be empty" >&2
  exit 1
fi
case "$NAME" in
  */*)
    echo "ERROR: --name must not contain path separators (/) — got: $NAME" >&2
    exit 1
    ;;
esac
# Check for control characters (POSIX [:cntrl:] class)
if [ "$(printf '%s' "$NAME" | LC_ALL=C tr -d '[:cntrl:]')" != "$NAME" ]; then
  echo "ERROR: --name must not contain control characters (newline/tab/NUL)" >&2
  exit 1
fi

# ─── Resolve inbox path (mirrors inbox-auto-parse.sh) ───────────────
INBOX=""
INBOX_SOURCE="default"
if [ -n "$INBOX_OVERRIDE" ]; then
  INBOX="$INBOX_OVERRIDE"
  INBOX_SOURCE="--inbox flag"
elif [ -n "${DEXHUB_INBOX:-}" ]; then
  INBOX="$DEXHUB_INBOX"
  INBOX_SOURCE="DEXHUB_INBOX env"
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
    INBOX_SOURCE="config.yaml"
  fi
fi
[ -z "$INBOX" ] && { INBOX="$REPO_ROOT/myDex/inbox"; INBOX_SOURCE="default"; }

# Normalize to absolute (resolves symlinks if the dir exists)
if [ -d "$INBOX" ]; then
  INBOX_ABS="$(cd "$INBOX" && pwd)"
else
  INBOX_ABS="$INBOX"
fi

# ─── Output format default ──────────────────────────────────────────
if [ -z "$FORMAT" ]; then
  if [ -t 1 ]; then FORMAT="text"; else FORMAT="json"; fi
fi

# ─── Detect platform ────────────────────────────────────────────────
UNAME_S="$(uname -s)"
case "$UNAME_S" in
  Darwin)                PLATFORM="macos"   ;;
  Linux)                 PLATFORM="linux"   ;;
  MINGW*|CYGWIN*|MSYS*)  PLATFORM="windows" ;;
  *)                     PLATFORM="unknown" ;;
esac

# Helper: emit a result record and exit with the given code
emit() {
  local status="$1"; shift
  local exit_code="$1"; shift
  local error_msg="${1:-}"
  local path="${2:-}"

  if [ "$FORMAT" = "json" ]; then
    ruby -rjson -e '
      h = {
        "action" => ARGV[0],
        "platform" => ARGV[1],
        "status" => ARGV[2],
        "inbox" => ARGV[3],
        "inbox_source" => ARGV[4],
        "shortcut_name" => ARGV[5],
        "shortcut_path" => (ARGV[6].empty? ? nil : ARGV[6]),
        "dry_run" => ARGV[7] == "1",
        "error" => (ARGV[8].empty? ? nil : ARGV[8])
      }
      puts JSON.pretty_generate(h)
    ' "$ACTION" "$PLATFORM" "$status" "$INBOX_ABS" "$INBOX_SOURCE" "$NAME" "$path" "$DRY_RUN" "$error_msg"
  else
    printf "%-14s %s\n" "action:" "$ACTION"
    printf "%-14s %s\n" "platform:" "$PLATFORM"
    printf "%-14s %s\n" "status:" "$status"
    printf "%-14s %s (%s)\n" "inbox:" "$INBOX_ABS" "$INBOX_SOURCE"
    printf "%-14s %s\n" "shortcut:" "$NAME"
    [ -n "$path" ] && printf "%-14s %s\n" "path:" "$path"
    [ "$DRY_RUN" = "1" ] && printf "%-14s %s\n" "dry-run:" "YES (no filesystem change)"
    [ -n "$error_msg" ] && printf "%-14s %s\n" "error:" "$error_msg"
  fi

  exit "$exit_code"
}

# ─── Platform-support guard ─────────────────────────────────────────
# Windows is now supported via PowerShell .lnk (shipped 2026-04-21 session-7).
# Unknown platforms still exit cleanly with an honest error.
case "$PLATFORM" in
  unknown)
    emit "unsupported_platform" 2 "Unrecognized platform: $UNAME_S"
    ;;
esac

# ─── Desktop dir resolution ─────────────────────────────────────────
# Priority:
#   1. $XDG_DESKTOP_DIR env var (most explicit — user knows what they want)
#   2. $XDG_CONFIG_HOME/user-dirs.dirs line for XDG_DESKTOP_DIR
#      (set by xdg-user-dirs-update on Linux; respects locale, so
#      German systems have "Schreibtisch", French "Bureau", Chinese
#      "桌面", Japanese "デスクトップ", etc.). Closes session-7 XDG
#      known_issue — previously only env-var + hard-coded default,
#      broke for localized Linux desktop environments.
#   3. Default: $HOME/Desktop (works on macOS always, works on
#      English-locale Linux, works when no xdg setup exists)
resolve_desktop_dir() {
  if [ -n "${XDG_DESKTOP_DIR:-}" ]; then
    printf '%s' "$XDG_DESKTOP_DIR"
    return
  fi
  local user_dirs="${XDG_CONFIG_HOME:-$HOME/.config}/user-dirs.dirs"
  if [ -f "$user_dirs" ]; then
    # Extract XDG_DESKTOP_DIR value via pure shell — no sed/ruby regex
    # gymnastics. Earlier attempts (sed with triple-escaped quotes; ruby
    # with complex regex) failed on CI (Ubuntu) while passing on macOS
    # due to subtle tool-version differences in how escape sequences
    # were interpreted. Pure shell pipeline is predictable on any POSIX
    # system + avoids process spawn overhead for a simple lookup.
    # Handles:
    #   XDG_DESKTOP_DIR="$HOME/Schreibtisch"   (default quoted form)
    #   XDG_DESKTOP_DIR=/custom/path           (unquoted absolute)
    #   XDG_DESKTOP_DIR='single-quoted'        (alt quote)
    #   # XDG_DESKTOP_DIR=...                  (commented — skipped)
    local parsed
    # Step 1: grab the first non-comment line defining XDG_DESKTOP_DIR
    parsed=$(grep -E '^[[:space:]]*XDG_DESKTOP_DIR=' "$user_dirs" 2>/dev/null \
             | grep -vE '^[[:space:]]*#' \
             | head -1)
    if [ -n "$parsed" ]; then
      # Step 2: strip leading whitespace + key prefix
      parsed="${parsed#"${parsed%%[![:space:]]*}"}"    # ltrim whitespace
      parsed="${parsed#XDG_DESKTOP_DIR=}"
      # Step 3: strip trailing whitespace
      parsed="${parsed%"${parsed##*[![:space:]]}"}"
      # Step 4: strip surrounding quote pair (double OR single) if present
      case "$parsed" in
        \"*\") parsed="${parsed#\"}"; parsed="${parsed%\"}" ;;
        \'*\') parsed="${parsed#\'}"; parsed="${parsed%\'}" ;;
      esac
      # Step 5: substitute $HOME literal (xdg-user-dirs convention).
      parsed="${parsed//\$HOME/$HOME}"
      printf '%s' "$parsed"
      return
    fi
  fi
  printf '%s' "$HOME/Desktop"
}
DESKTOP=$(resolve_desktop_dir)
if [ ! -d "$DESKTOP" ]; then
  emit "desktop_missing" 3 "Desktop directory not found at $DESKTOP — create it first or pass --dry-run."
fi

# ─── Compute shortcut path per platform ─────────────────────────────
case "$PLATFORM" in
  macos)   SHORTCUT_PATH="$DESKTOP/$NAME" ;;
  linux)   SHORTCUT_PATH="$DESKTOP/${NAME}.desktop" ;;
  windows) SHORTCUT_PATH="$DESKTOP/${NAME}.lnk" ;;
esac

# ─── ACTION: remove ─────────────────────────────────────────────────
if [ "$ACTION" = "remove" ]; then
  if [ ! -e "$SHORTCUT_PATH" ] && [ ! -L "$SHORTCUT_PATH" ]; then
    emit "not_found" 0 "No shortcut at $SHORTCUT_PATH (nothing to remove)." "$SHORTCUT_PATH"
  fi

  if [ "$DRY_RUN" = "1" ]; then
    emit "would_remove" 0 "" "$SHORTCUT_PATH"
  fi

  rm -f "$SHORTCUT_PATH"
  if [ ! -e "$SHORTCUT_PATH" ] && [ ! -L "$SHORTCUT_PATH" ]; then
    emit "removed" 0 "" "$SHORTCUT_PATH"
  else
    emit "remove_failed" 4 "Could not delete $SHORTCUT_PATH" "$SHORTCUT_PATH"
  fi
fi

# ─── ACTION: create (default) ───────────────────────────────────────

# Inbox must exist — don't auto-create here (inbox-auto-parse.sh is the
# script that manages .processed/; this one is a shortcut-only tool).
if [ ! -d "$INBOX_ABS" ]; then
  emit "inbox_missing" 4 "Inbox directory missing at $INBOX_ABS. Run inbox-auto-parse.sh first (it creates the inbox + .processed/ subdir), or mkdir -p \"$INBOX_ABS\" manually."
fi

# Existence guard — don't clobber without --force
if [ -e "$SHORTCUT_PATH" ] || [ -L "$SHORTCUT_PATH" ]; then
  if [ "$FORCE" = "0" ]; then
    emit "exists" 5 "Shortcut already at $SHORTCUT_PATH. Re-run with --force to overwrite, or --remove to delete." "$SHORTCUT_PATH"
  fi
  # With --force, we'll overwrite below (respecting --dry-run)
fi

if [ "$DRY_RUN" = "1" ]; then
  emit "would_create" 0 "" "$SHORTCUT_PATH"
fi

# ─── Platform-specific create ───────────────────────────────────────
case "$PLATFORM" in
  macos)
    # Symlink. Simple, reversible, no TCC / Automation permission prompt.
    # Finder renders it with a shortcut-arrow badge.
    rm -f "$SHORTCUT_PATH" 2>/dev/null  # safe: --force gate above
    if ln -s "$INBOX_ABS" "$SHORTCUT_PATH" 2>/dev/null; then
      emit "created" 0 "" "$SHORTCUT_PATH"
    else
      emit "create_failed" 4 "ln -s failed writing $SHORTCUT_PATH" "$SHORTCUT_PATH"
    fi
    ;;
  linux)
    # .desktop Type=Link file. Works in most desktop environments
    # (GNOME Files, KDE Dolphin, XFCE Thunar). Executable bit required
    # for the file manager to treat it as trusted.
    rm -f "$SHORTCUT_PATH" 2>/dev/null
    {
      printf '[Desktop Entry]\n'
      printf 'Type=Link\n'
      printf 'Name=%s\n' "$NAME"
      printf 'Comment=DexHub inbox — drop files here to parse into the Knowledge Tank.\n'
      printf 'URL=file://%s\n' "$INBOX_ABS"
      printf 'Icon=folder\n'
    } > "$SHORTCUT_PATH" 2>/dev/null
    if [ -f "$SHORTCUT_PATH" ]; then
      chmod +x "$SHORTCUT_PATH" 2>/dev/null
      emit "created" 0 "" "$SHORTCUT_PATH"
    else
      emit "create_failed" 4 "Could not write $SHORTCUT_PATH" "$SHORTCUT_PATH"
    fi
    ;;
  windows)
    # PowerShell COM-based .lnk creator. Works in Git Bash / MSYS2 / Cygwin /
    # WSL (via powershell.exe interop) as long as PowerShell is on PATH.
    # 2026-04-21 session-7 scaffold — graceful when PS missing, uses cygpath
    # for bash↔Windows path conversion when available, honest hint otherwise.
    POWERSHELL=""
    if command -v pwsh.exe >/dev/null 2>&1; then
      POWERSHELL="pwsh.exe"
    elif command -v powershell.exe >/dev/null 2>&1; then
      POWERSHELL="powershell.exe"
    else
      emit "missing_dependency" 2 "Windows shortcut creation requires PowerShell on PATH (pwsh.exe or powershell.exe). Install PowerShell 7+ from https://aka.ms/powershell, or run from Git Bash / MSYS2 / WSL where powershell.exe is reachable. Manual workaround: Right-click the inbox folder in Explorer → Send To → Desktop (create shortcut)."
    fi
    # Convert bash-style paths to Windows-native when cygpath is around
    # (Git Bash / Cygwin / MSYS2 ship it). Without cygpath, pass bash
    # paths directly — works on WSL where PowerShell handles both.
    if command -v cygpath >/dev/null 2>&1; then
      INBOX_WIN=$(cygpath -w "$INBOX_ABS" 2>/dev/null || printf '%s' "$INBOX_ABS")
      SHORTCUT_WIN=$(cygpath -w "$SHORTCUT_PATH" 2>/dev/null || printf '%s' "$SHORTCUT_PATH")
    else
      INBOX_WIN="$INBOX_ABS"
      SHORTCUT_WIN="$SHORTCUT_PATH"
    fi
    rm -f "$SHORTCUT_PATH" 2>/dev/null
    # The PS one-liner: create a WScript.Shell COM object, build the
    # shortcut, point at inbox, save. Path arguments wrapped in PS
    # single-quoted strings (double-quotes would trigger variable
    # interpolation we do not want). Literal apostrophes in paths
    # (e.g., name "Arash's Inbox") break single-quoted PS strings —
    # PS's own escape rule is to DOUBLE the apostrophe. Escape here
    # in bash before injecting. Fixes session-7 Agent-B critical
    # finding: common user names with apostrophes silently broke
    # the PS command.
    INBOX_WIN_PS="${INBOX_WIN//\'/\'\'}"
    SHORTCUT_WIN_PS="${SHORTCUT_WIN//\'/\'\'}"
    "$POWERSHELL" -NoProfile -Command \
      "\$s = (New-Object -ComObject WScript.Shell).CreateShortcut('$SHORTCUT_WIN_PS'); \$s.TargetPath = '$INBOX_WIN_PS'; \$s.Description = 'DexHub inbox — drag files here to parse into the Knowledge Tank'; \$s.Save()" \
      >/dev/null 2>&1
    PS_EXIT=$?
    if [ "$PS_EXIT" = "0" ] && [ -f "$SHORTCUT_PATH" ]; then
      emit "created" 0 "" "$SHORTCUT_PATH"
    else
      emit "create_failed" 4 "PowerShell .lnk creation failed (exit $PS_EXIT). Check: $POWERSHELL on PATH; Desktop folder writable; no antivirus blocking COM object creation." "$SHORTCUT_PATH"
    fi
    ;;
esac

# Unreachable — all platform branches above emit + exit.
emit "internal_error" 99 "Fell through platform switch — this is a bug" ""
