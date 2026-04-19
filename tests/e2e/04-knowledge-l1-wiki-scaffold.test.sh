#!/bin/bash
# DexHub E2E Test 04 — L1 Wiki scaffold (Phase 5.2.a)
#
# Structural test only. No API cost. No opt-in gate.
# Proves the scaffold that makes the L1 Knowledge Layer usable exists:
#   - Pattern doc is in place
#   - Framework-shipped templates are in place
#   - User-wiki README (onboarding instructions) is in place
#
# Does NOT yet prove: session-start injection — that's Phase 5.2.d.

set -u

HARNESS="$(cd "$(dirname "$0")/harness" && pwd)"
source "$HARNESS/assertion-lib.sh"

ensure_beta_root
test_banner "04 L1 Wiki scaffold (Phase 5.2.a)"

# ─── Pattern documentation ─────────────────────────────────────────────
assert_file_exists ".dexCore/_dev/docs/L1-WIKI-PATTERN.md" \
  "L1 Wiki pattern doc exists"
assert_file_contains ".dexCore/_dev/docs/L1-WIKI-PATTERN.md" "L1 Wiki" \
  "Pattern doc titled 'L1 Wiki'"
assert_file_contains ".dexCore/_dev/docs/L1-WIKI-PATTERN.md" "session-start" \
  "Pattern doc explains session-start injection contract"

# ─── Framework-shipped templates ──────────────────────────────────────
assert_dir_exists ".dexCore/core/wiki-templates" \
  "Templates directory exists"
assert_file_exists ".dexCore/core/wiki-templates/README.md" \
  "Template index README exists"
assert_file_exists ".dexCore/core/wiki-templates/institutional-knowledge.template.md" \
  "Template: institutional-knowledge"
assert_file_exists ".dexCore/core/wiki-templates/project-glossary.template.md" \
  "Template: project-glossary"
assert_file_exists ".dexCore/core/wiki-templates/architecture-notes.template.md" \
  "Template: architecture-notes"

# Every template carries the frontmatter we promise users
for tpl in institutional-knowledge project-glossary architecture-notes; do
  assert_file_contains ".dexCore/core/wiki-templates/${tpl}.template.md" "last_reviewed:" \
    "Template ${tpl}: last_reviewed frontmatter present"
  assert_file_contains ".dexCore/core/wiki-templates/${tpl}.template.md" "status:" \
    "Template ${tpl}: status frontmatter present"
  assert_file_contains ".dexCore/core/wiki-templates/${tpl}.template.md" "why_l1:" \
    "Template ${tpl}: why_l1 frontmatter present"
done

# ─── User-wiki README (framework-shipped, tracked) ────────────────────
assert_file_exists "myDex/.dex/wiki/README.md" \
  "User wiki README exists"
assert_file_contains "myDex/.dex/wiki/README.md" "L1" \
  "User wiki README mentions L1 Knowledge Layer"
assert_file_contains "myDex/.dex/wiki/README.md" "template" \
  "User wiki README guides user to templates"

# ─── Gitignore rules ──────────────────────────────────────────────────
# User's wiki entries should be gitignored (privacy), except README.md (framework-shipped).
assert_file_contains ".gitignore" "myDex/.dex/wiki/" \
  "gitignore has wiki entry rules"

# ─── Feature registry claim ───────────────────────────────────────────
assert_file_contains ".dexCore/_cfg/features.yaml" "knowledge.l1_wiki" \
  "features.yaml declares knowledge.l1_wiki"

test_summary
