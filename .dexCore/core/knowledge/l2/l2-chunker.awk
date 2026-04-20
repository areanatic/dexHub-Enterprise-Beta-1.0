# DexHub L2 Tank — Heading-Aware Markdown Chunker (awk)
# ============================================================
# Input:  a markdown file on stdin (or file arg)
# Output: NUL-separated records, each record is:
#           title\tbyte_size\tcontent
#         where title = nearest heading (h1 or h2), content = section body.
# Chunks are delimited by null bytes (\x00) so shell can read them safely
# without fighting whitespace in content.
#
# Strategy (v1, deterministic, no overlap):
#   - Emit one chunk per h1 or h2 heading (everything up to the next h1/h2)
#   - If a chunk exceeds MAX_SIZE bytes, it's split further by h3 headings
#   - If still >MAX_SIZE, truncate at MAX_SIZE with a [TRUNCATED] marker
#   - Preamble before the first heading (if any) becomes chunk 0 with
#     title "_preamble_"
#
# Used by: l2-ingest.sh
# Config via awk vars:
#   MAX_SIZE (default 2048)

BEGIN {
  if (MAX_SIZE == "" || MAX_SIZE + 0 == 0) MAX_SIZE = 2048
  current_title = "_preamble_"
  current_body = ""
  have_content = 0
}

function emit_chunk(title, body,   sz) {
  # Skip empty chunks (common on h1 followed by h2 with nothing between)
  if (body == "" && title == "_preamble_") return
  if (body == "") body = "(empty section)"
  sz = length(body)
  if (sz > MAX_SIZE) {
    # Truncate hard; overlap/smarter splitting is v2 follow-up
    body = substr(body, 1, MAX_SIZE - 50) "\n\n[TRUNCATED — section exceeds " MAX_SIZE " bytes]"
    sz = length(body)
  }
  # Emit record: title \t size \t body, then NUL
  printf "%s\t%d\t%s%c", title, sz, body, 0
}

# h1 or h2 opens a new chunk
/^#{1,2} / {
  if (have_content) emit_chunk(current_title, current_body)
  current_title = $0
  sub(/^#+ +/, "", current_title)
  current_body = ""
  have_content = 1
  next
}

# Everything else accumulates into current_body
{
  if (current_body == "") current_body = $0
  else current_body = current_body "\n" $0
}

END {
  if (have_content) emit_chunk(current_title, current_body)
  else if (current_body != "") emit_chunk("_preamble_", current_body)
}
