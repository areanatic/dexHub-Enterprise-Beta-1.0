#!/usr/bin/env bash
# DexHub Parser — MIME / type detection helper
# ==========================================================
# Maps a file path to a coarse type label the router cares about.
# Deliberately extension-first: we're picking a backend, not identifying
# arbitrary formats. Magic-byte sniffing can be added later if extension
# proves unreliable (5.3.b+). For Beta 1.0 scope, extension is enough.
#
# Output labels (stable contract):
#   text       — .txt, .md, .markdown, .rst, .log, .csv, .tsv
#   pdf        — .pdf
#   office     — .docx, .xlsx, .pptx, .doc, .xls, .ppt, .odt, .ods, .odp
#   image      — .png, .jpg, .jpeg, .gif, .bmp, .webp, .tiff, .svg
#   code       — .py, .js, .ts, .rb, .go, .rs, .java, .c, .cpp, .h, .sh
#   data       — .json, .yaml, .yml, .toml, .xml
#   archive    — .zip, .tar, .gz, .7z, .rar (not yet parsed)
#   email      — .eml, .mbox
#   unknown    — anything else
#
# Also emits approximate byte size (for oversize decision in router).
#
# Usage:
#   bash detect-mime.sh <filepath>                    # text: "pdf 1048576"
#   bash detect-mime.sh --format json <filepath>      # JSON { type, size_bytes, ... }
#
# Exit codes:
#   0   success (even for unknown / missing files — router decides)
#   1   bad args

set -uo pipefail

FORMAT="text"
FILE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --format) FORMAT="$2"; shift 2 ;;
    --help|-h)
      sed -n '2,24p' "${BASH_SOURCE[0]}"
      exit 0
      ;;
    -*)
      echo "ERROR: unknown flag: $1" >&2
      exit 1
      ;;
    *)
      FILE="$1"
      shift
      ;;
  esac
done

if [ -z "$FILE" ]; then
  echo "ERROR: file path required" >&2
  exit 1
fi

# Extract extension (lowercased, without leading dot)
EXT="${FILE##*.}"
# If the filename has no dot, $FILE == $EXT — treat as no extension
case "$FILE" in
  *.*) ;;
  *) EXT="" ;;
esac
EXT="$(printf "%s" "$EXT" | tr '[:upper:]' '[:lower:]')"

# Size (bytes). Missing file → 0, reported cleanly (router handles).
SIZE=0
if [ -f "$FILE" ]; then
  SIZE=$(wc -c < "$FILE" 2>/dev/null | tr -d ' ' || echo 0)
fi

# Classify
case "$EXT" in
  txt|md|markdown|rst|log|csv|tsv)
    TYPE="text" ;;
  pdf)
    TYPE="pdf" ;;
  docx|xlsx|pptx|doc|xls|ppt|odt|ods|odp)
    TYPE="office" ;;
  png|jpg|jpeg|gif|bmp|webp|tiff|tif|svg)
    TYPE="image" ;;
  py|js|ts|jsx|tsx|rb|go|rs|java|c|cpp|h|hpp|sh|bash|zsh|fish|yml|pl|php|swift|kt|scala)
    TYPE="code" ;;
  json|yaml|toml|xml|ini|conf)
    TYPE="data" ;;
  zip|tar|gz|tgz|7z|rar|bz2|xz)
    TYPE="archive" ;;
  eml|mbox|msg)
    TYPE="email" ;;
  "")
    TYPE="unknown" ;;
  *)
    TYPE="unknown" ;;
esac

EXISTS="true"
[ ! -f "$FILE" ] && EXISTS="false"

if [ "$FORMAT" = "json" ]; then
  printf '{"path":"%s","exists":%s,"extension":"%s","type":"%s","size_bytes":%s}\n' \
    "$(printf "%s" "$FILE" | sed 's/"/\\"/g')" \
    "$EXISTS" \
    "$EXT" \
    "$TYPE" \
    "$SIZE"
else
  printf "%s %s\n" "$TYPE" "$SIZE"
fi
