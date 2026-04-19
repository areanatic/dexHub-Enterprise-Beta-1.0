#!/bin/bash
# DexHub E2E Test 12 — L2 Tank scaffold (Phase 5.2.b-scaffold)
#
# Verifies the L2 Tank scaffold shipped today. Does NOT test ingest or
# query behavior (those are stubs — see L2-TANK.md phase milestones).
# What we CAN test structurally:
#   - Design doc in place + names expected phases
#   - Directory + schema.sql exist
#   - l2-init.sh actually creates a valid DB with expected tables
#   - Stub scripts emit [L2 STUB] markers (honesty label)
#   - Gitignore protects user's private tank DB
#   - features.yaml declares the L2 sub-features
#
# No API cost. Runs in every E2E default + --enterprise pass.

set -u

HARNESS="$(cd "$(dirname "$0")/harness" && pwd)"
source "$HARNESS/assertion-lib.sh"

ensure_beta_root
test_banner "12 L2 Tank scaffold (Phase 5.2.b-scaffold)"

# ─── Design doc ──────────────────────────────────────────────────────
assert_file_exists ".dexCore/_dev/docs/L2-TANK.md" \
  "L2 Tank design doc present"
assert_file_contains ".dexCore/_dev/docs/L2-TANK.md" "Architectural fit review" \
  "Design doc includes architectural-fit review"
assert_file_contains ".dexCore/_dev/docs/L2-TANK.md" "Enterprise compliance" \
  "Design doc documents enterprise compliance per embedding backend"
assert_file_contains ".dexCore/_dev/docs/L2-TANK.md" "Phase milestones" \
  "Design doc defines phase milestones"

# ─── Directory scaffold ──────────────────────────────────────────────
assert_dir_exists ".dexCore/core/knowledge/l2" \
  "L2 code directory exists"
assert_file_exists ".dexCore/core/knowledge/l2/schema.sql" \
  "schema.sql present"
assert_file_exists ".dexCore/core/knowledge/l2/l2-init.sh" \
  "l2-init.sh present"
assert_file_exists ".dexCore/core/knowledge/l2/l2-ingest.sh" \
  "l2-ingest.sh present (stub)"
assert_file_exists ".dexCore/core/knowledge/l2/l2-query.sh" \
  "l2-query.sh present (stub)"
assert_file_exists "myDex/.dex/l2/README.md" \
  "User-workspace L2 README present (framework-shipped)"

# Executable bits
for s in l2-init.sh l2-ingest.sh l2-query.sh; do
  if [ -x ".dexCore/core/knowledge/l2/$s" ]; then
    pass "$s is executable"
  else
    fail "$s not executable"
  fi
done

# Syntax valid
for s in l2-init.sh l2-ingest.sh l2-query.sh; do
  if bash -n ".dexCore/core/knowledge/l2/$s" 2>/dev/null; then
    pass "$s bash-parses cleanly"
  else
    fail "$s has syntax errors"
  fi
done

# ─── Schema valid SQL (parse with sqlite3 in-memory) ─────────────────
if command -v sqlite3 >/dev/null 2>&1; then
  if sqlite3 :memory: < .dexCore/core/knowledge/l2/schema.sql 2>/dev/null; then
    pass "schema.sql applies cleanly to fresh sqlite3 in-memory DB"
  else
    fail "schema.sql has SQL errors"
  fi
else
  echo -e "\033[1;33m  ⊘\033[0m sqlite3 not available — schema parse check skipped"
fi

# ─── l2-init.sh actually creates a valid DB (fixture) ────────────────
if command -v sqlite3 >/dev/null 2>&1; then
  FIXTURE_DB=$(mktemp -u -t dexhub-l2-test-XXXXXX).sqlite
  if bash .dexCore/core/knowledge/l2/l2-init.sh --db "$FIXTURE_DB" >/dev/null 2>&1; then
    pass "l2-init.sh creates DB at custom --db path"

    # Verify --check reports success
    if bash .dexCore/core/knowledge/l2/l2-init.sh --db "$FIXTURE_DB" --check >/dev/null 2>&1; then
      pass "l2-init.sh --check returns 0 on initialized DB"
    else
      fail "l2-init.sh --check failed on freshly-created DB"
    fi

    # Verify expected tables
    TABLES=$(sqlite3 "$FIXTURE_DB" "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name" 2>/dev/null)
    for expected in chunks embeddings ingest_runs meta; do
      if echo "$TABLES" | grep -q "^${expected}$"; then
        pass "Table created: $expected"
      else
        fail "Table missing: $expected"
      fi
    done

    # Verify FTS5 virtual table
    if sqlite3 "$FIXTURE_DB" "SELECT * FROM chunks_fts LIMIT 0" >/dev/null 2>&1; then
      pass "FTS5 virtual table chunks_fts queryable"
    else
      fail "FTS5 virtual table chunks_fts not functional"
    fi

    # Verify meta.schema_version
    SV=$(sqlite3 "$FIXTURE_DB" "SELECT value FROM meta WHERE key='schema_version'" 2>/dev/null)
    if [ "$SV" = "1" ]; then
      pass "meta.schema_version = 1"
    else
      fail "meta.schema_version unexpected: '$SV'"
    fi

    # Cleanup fixture
    rm -f "$FIXTURE_DB" "${FIXTURE_DB}-wal" "${FIXTURE_DB}-shm"
  else
    fail "l2-init.sh failed to create fixture DB"
  fi
fi

# ─── Stubs emit honesty signal ────────────────────────────────────────
INGEST_OUT=$(bash .dexCore/core/knowledge/l2/l2-ingest.sh --source /tmp/nope 2>&1 || true)
if echo "$INGEST_OUT" | grep -q "\[L2 STUB\]"; then
  pass "l2-ingest.sh emits [L2 STUB] honesty signal"
else
  fail "l2-ingest.sh missing [L2 STUB] signal — user may mistake scaffold for working pipeline"
fi

QUERY_OUT=$(bash .dexCore/core/knowledge/l2/l2-query.sh "test query" 2>&1 || true)
if echo "$QUERY_OUT" | grep -q "\[L2 STUB\]"; then
  pass "l2-query.sh emits [L2 STUB] honesty signal"
else
  fail "l2-query.sh missing [L2 STUB] signal"
fi

# ─── Gitignore protection ────────────────────────────────────────────
assert_file_contains ".gitignore" "myDex/.dex/l2/tank.sqlite" \
  "gitignore protects tank.sqlite (user-private)"
assert_file_contains ".gitignore" "!myDex/.dex/l2/README.md" \
  "gitignore tracks framework-shipped README.md"

# ─── Feature registry ─────────────────────────────────────────────────
assert_file_contains ".dexCore/_cfg/features.yaml" "knowledge.l2_tank_schema" \
  "features.yaml declares knowledge.l2_tank_schema"
assert_file_contains ".dexCore/_cfg/features.yaml" "knowledge.l2_tank_init" \
  "features.yaml declares knowledge.l2_tank_init"

test_summary
