#!/bin/bash
# DexHub E2E Test 05 — Saved Consent Tracking (Phase 5.1.c Tier 3.1)
#
# Structural test. No API cost. No opt-in gate.
# Verifies the spec-level contract:
#   - Profile schema v1.2 defines `consents` field
#   - profile.yaml.example shows a consents entry
#   - CONSENT-TRACKING.md pattern doc is present
#   - DexMaster agent has *consents command registered
#   - 3 connector wizards (Atlassian/GitHub/Figma) reference the consent protocol
#
# Does NOT yet prove live behavior — that's a Tier 5.3 follow-up with multi-turn
# walkthrough (user grants consent → second session → consent-found path taken).

set -u

HARNESS="$(cd "$(dirname "$0")/harness" && pwd)"
source "$HARNESS/assertion-lib.sh"

ensure_beta_root
test_banner "05 Saved Consent Tracking (Phase 5.1.c Tier 3.1)"

# ─── Pattern doc ──────────────────────────────────────────────────────
assert_file_exists ".dexCore/_dev/docs/CONSENT-TRACKING.md" \
  "Consent-tracking pattern doc exists"
assert_file_contains ".dexCore/_dev/docs/CONSENT-TRACKING.md" "meta.saved_consent_tracking" \
  "Doc references feature id"
assert_file_contains ".dexCore/_dev/docs/CONSENT-TRACKING.md" "data_handling_context" \
  "Doc defines data_handling_context semantics"
assert_file_contains ".dexCore/_dev/docs/CONSENT-TRACKING.md" "Enterprise Compliance Gate" \
  "Doc clarifies gate-vs-consent ordering"

# ─── Profile schema v1.2 ──────────────────────────────────────────────
assert_file_contains ".dexCore/_dev/schemas/profile-schema-v1.0.yaml" "consents:" \
  "Profile schema defines consents field"
assert_file_contains ".dexCore/_dev/schemas/profile-schema-v1.0.yaml" "v1.2" \
  "Schema declares v1.2 evolution"
assert_file_contains ".dexCore/_dev/schemas/profile-schema-v1.0.yaml" "feature_id" \
  "Schema defines consent entry shape (feature_id)"
assert_file_contains ".dexCore/_dev/schemas/profile-schema-v1.0.yaml" "granted_at" \
  "Schema defines granted_at field"

# ─── profile.yaml.example shows consents ──────────────────────────────
assert_file_contains "myDex/.dex/config/profile.yaml.example" "consents:" \
  "profile.yaml.example shows consents block"

# ─── DexMaster has *consents and *revoke-consent commands ─────────────
assert_file_contains ".dexCore/core/agents/dex-master.md" "\*consents" \
  "DexMaster agent declares *consents command"
assert_file_contains ".dexCore/core/agents/dex-master.md" "\*revoke-consent" \
  "DexMaster agent declares *revoke-consent command"

# ─── Connector agents reference consent protocol ──────────────────────
# Atlassian, GitHub, Figma — 3 cloud connectors that gate on compliance + consent.
for agent in atlassian-onboarding github-onboarding figma-onboarding; do
  assert_file_exists ".github/agents/${agent}.agent.md" \
    "Connector agent present: ${agent}"
  assert_file_contains ".github/agents/${agent}.agent.md" "consent" \
    "Connector agent ${agent} references consent tracking"
done

# ─── Feature registry claim ───────────────────────────────────────────
assert_file_contains ".dexCore/_cfg/features.yaml" "meta.saved_consent_tracking" \
  "features.yaml declares meta.saved_consent_tracking"

test_summary
