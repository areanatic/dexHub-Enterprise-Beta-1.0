#!/usr/bin/env ruby
# DexHub L2 Tank — hybrid ranking helper
# ==========================================================
# Reads two JSON blobs from STDIN (separated by a form-feed byte, \x0c):
#   1. keyword candidates — rows with {id, title, source_path, source_type,
#      content, kw_rank} from FTS5 MATCH (ordered, top-K)
#   2. semantic candidates — rows with {id, title, source_path, source_type,
#      content, embedding} from the embeddings JOIN (all chunks with a vector
#      for the current backend, capped at 500)
#
# Embeds the query via Ollama /api/embeddings, merges keyword + semantic
# candidates by id, computes per-chunk:
#   - kw_score     — BM25 rank normalized to 0..1 across the set
#   - sem_score    — cosine similarity, shifted from [-1,1] to [0,1]
#   - hybrid_score — α·kw_score + (1-α)·sem_score    (for mode=hybrid)
#                 — or sem_score                      (for mode=semantic-only)
# Returns the top-N as a JSON array, shape compatible with keyword-only path.
#
# Called from .dexCore/core/knowledge/l2/l2-query.sh when effective mode is
# hybrid or semantic-only. Extracted from inline ruby so stdin works — the
# previous `ruby - <<HEREDOC` shell pattern conflicted with piped stdin, so
# STDIN.read returned empty and results were always [].
#
# Args (ARGV):
#   0  mode        — "hybrid" | "semantic-only"
#   1  alpha       — float, keyword-side weight when hybrid
#   2  top         — integer, max result count
#   3  endpoint    — Ollama URL (default http://localhost:11434)
#   4  model       — embedding model name ("nomic-embed-text" etc.)
#
# Env:
#   L2_QUERY_TEXT — the user's query string (passed via env to sidestep
#                   shell-escape issues with arbitrary content)
#
# Exit codes:
#   0  success (results printed to STDOUT as JSON array, possibly [])
#   2  query embedding HTTP call failed or returned empty vector

require 'json'
require 'open3'

mode     = ARGV[0] || "hybrid"
alpha    = (ARGV[1] || "0.5").to_f
top      = (ARGV[2] || "5").to_i
endpoint = ARGV[3] || "http://localhost:11434"
model    = ARGV[4] || "nomic-embed-text"

payload = STDIN.read
kw_json, sem_json = payload.split("\x0c", 2)
kw_arr  = (kw_json  && !kw_json.strip.empty?)  ? JSON.parse(kw_json)  : []
sem_arr = (sem_json && !sem_json.strip.empty?) ? JSON.parse(sem_json) : []

# Query embedding — one Ollama call
query_text = ENV["L2_QUERY_TEXT"] || ""
body = JSON.generate({"model" => model, "prompt" => query_text})
out, _err, status = Open3.capture3(
  "curl", "-sS", "--max-time", "60", "-X", "POST",
  endpoint + "/api/embeddings",
  "-H", "Content-Type: application/json",
  "-d", body
)
unless status.success? && !out.empty?
  STDERR.puts "ERROR: query embedding HTTP failed"
  puts "[]"
  exit 2
end

begin
  qresp = JSON.parse(out)
rescue JSON::ParserError => e
  STDERR.puts "ERROR: query embedding response not JSON: #{e.message}"
  puts "[]"
  exit 2
end

qvec = qresp["embedding"]
unless qvec.is_a?(Array) && !qvec.empty?
  STDERR.puts "ERROR: query embedding empty or malformed"
  puts "[]"
  exit 2
end
qnorm = Math.sqrt(qvec.reduce(0.0) { |s, x| s + x * x })

# Merge candidates by id
by_id = {}
kw_arr.each do |row|
  by_id[row["id"]] = { row: row, kw_rank: row["kw_rank"].to_f, embedding: nil }
end
sem_arr.each do |row|
  id = row["id"]
  if by_id[id]
    by_id[id][:embedding] = row["embedding"]
  else
    by_id[id] = { row: row, kw_rank: nil, embedding: row["embedding"] }
  end
end

# Normalize keyword ranks. SQLite FTS5 rank is negative; more-negative is
# better. Flip + range-normalize to 0..1 across the candidate set.
kw_ranks = by_id.values.map { |v| v[:kw_rank] }.compact
if kw_ranks.empty?
  kw_best = nil
  kw_worst = nil
  kw_range = 0
else
  kw_best  = kw_ranks.min  # most negative
  kw_worst = kw_ranks.max  # least negative
  kw_range = kw_worst - kw_best
end

results = []
by_id.each do |id, v|
  # Cosine sim → shift [-1,1] → [0,1]
  sem_score = 0.0
  if v[:embedding] && !v[:embedding].to_s.empty?
    chunk_vec = JSON.parse(v[:embedding]) rescue nil
    if chunk_vec.is_a?(Array) && chunk_vec.length == qvec.length
      dot = 0.0
      cnorm = 0.0
      chunk_vec.each_with_index do |x, i|
        dot += x * qvec[i]
        cnorm += x * x
      end
      cnorm = Math.sqrt(cnorm)
      cos = (qnorm > 0 && cnorm > 0) ? (dot / (qnorm * cnorm)) : 0.0
      sem_score = (cos + 1.0) / 2.0
    end
  end

  # Keyword score 0..1
  kw_score = 0.0
  if v[:kw_rank] && kw_range > 0
    kw_score = (kw_worst - v[:kw_rank]) / kw_range
  elsif v[:kw_rank]
    kw_score = 1.0   # single-candidate case
  end

  hybrid = case mode
           when "hybrid"        then alpha * kw_score + (1.0 - alpha) * sem_score
           when "semantic-only" then sem_score
           else 0.0
           end

  next if mode == "semantic-only" && (v[:embedding].nil? || v[:embedding].to_s.empty?)
  next if mode == "hybrid" && v[:kw_rank].nil? && sem_score == 0.0

  results << {
    "id"             => id,
    "title"          => v[:row]["title"],
    "source_path"    => v[:row]["source_path"],
    "source_type"    => v[:row]["source_type"],
    "content"        => v[:row]["content"],
    "rank"           => hybrid,
    "keyword_score"  => kw_score.round(4),
    "semantic_score" => sem_score.round(4),
    "hybrid_score"   => hybrid.round(4)
  }
end

results.sort_by! { |r| -r["rank"] }
puts JSON.generate(results[0...top])
