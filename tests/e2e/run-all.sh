#!/bin/bash
# DexHub E2E Test — Master Runner
# Phase 5.0 Test Harness Foundation (2026-04-19)
#
# Runs all tests/e2e/NN-*.test.sh and aggregates results.

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/../.." || exit 2  # Beta repo root

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

TOTAL_PASS=0
TOTAL_FAIL=0
TOTAL_SKIPPED=0
FAILED_TESTS=()

echo -e "${BOLD}╔═══════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║     DexHub E2E Test Suite                 ║${NC}"
echo -e "${BOLD}║     Phase 5.0 Test Harness Foundation     ║${NC}"
echo -e "${BOLD}╚═══════════════════════════════════════════╝${NC}"

for test_file in tests/e2e/[0-9]*.test.sh; do
  [ -f "$test_file" ] || continue

  # Run test, capture PASS/FAIL counts via export variables
  test_name=$(basename "$test_file" .test.sh)

  # Run in subshell but capture results via tmpfile
  tmpfile=$(mktemp)
  bash "$test_file" > "$tmpfile" 2>&1
  exit_code=$?

  # Display test output
  cat "$tmpfile"

  # Parse counts from test output (match ✓ or ✗ anywhere after leading whitespace+color)
  pass_count=$(grep -c "✓" "$tmpfile" 2>/dev/null || true)
  fail_count=$(grep -c "✗" "$tmpfile" 2>/dev/null || true)
  pass_count="${pass_count:-0}"
  fail_count="${fail_count:-0}"
  # Strip whitespace
  pass_count=$(echo "$pass_count" | tr -d '[:space:]')
  fail_count=$(echo "$fail_count" | tr -d '[:space:]')

  if [ "$exit_code" -eq 77 ]; then
    TOTAL_SKIPPED=$((TOTAL_SKIPPED + 1))
  else
    TOTAL_PASS=$((TOTAL_PASS + pass_count))
    TOTAL_FAIL=$((TOTAL_FAIL + fail_count))
    if [ "$fail_count" -gt 0 ] || [ "$exit_code" -ne 0 ]; then
      FAILED_TESTS+=("$test_name")
    fi
  fi

  rm -f "$tmpfile"
done

TOTAL=$((TOTAL_PASS + TOTAL_FAIL))

echo ""
echo -e "${BOLD}╔═══════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║                 SUMMARY                    ║${NC}"
echo -e "${BOLD}╚═══════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${GREEN}Passed:  $TOTAL_PASS${NC}"
echo -e "  ${RED}Failed:  $TOTAL_FAIL${NC}"
[ "$TOTAL_SKIPPED" -gt 0 ] && echo -e "  ${YELLOW}Skipped: $TOTAL_SKIPPED${NC}"
echo -e "  Total:   $TOTAL"

if [ ${#FAILED_TESTS[@]} -gt 0 ]; then
  echo ""
  echo -e "${RED}${BOLD}Failed tests:${NC}"
  for t in "${FAILED_TESTS[@]}"; do
    echo -e "  ${RED}✗${NC} $t"
  done
fi

echo ""

if [ "$TOTAL_FAIL" -eq 0 ]; then
  echo -e "${GREEN}${BOLD}All E2E tests passed!${NC}"
  exit 0
else
  echo -e "${RED}${BOLD}$TOTAL_FAIL E2E test(s) failed.${NC}"
  exit 1
fi
