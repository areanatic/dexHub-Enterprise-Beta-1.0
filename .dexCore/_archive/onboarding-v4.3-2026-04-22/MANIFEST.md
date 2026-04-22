# Archive: Onboarding v4.3 YAML — 2026-04-22

**Archived during:** Session 10, P0-I Option A (Registry Consolidation)

## What's in this archive

- `onboarding-questions.yaml` — the v4.3 onboarding question set
  - Variants: `smart` (18 Q) + `vollständig` (42 Q)
  - This was the DEFAULT onboarding path before v5.0 was promoted.

## Why archived

User directive (Session 10, 2026-04-22): "Einen brauchen wir. Ab jetzt haben wir nur
noch einen für die Beta. Keine anderen Varianten." — The v4.3 YAML has been
replaced by the v5.0 YAML (renamed to `onboarding-questions.yaml` in the live
.dexCore/_cfg/ after the archive).

## Corresponding feature-registry changes

Removed from features.yaml:
- `onboarding.smart_v4_3_1` (referenced this YAML)
- `onboarding.vollstandig_v4_3` (referenced this YAML)
- `onboarding.legacy_path_preserved` (depended on vollstandig_v4_3 + preserved
  the *mydex-advanced engagement path to the v4.3 flow)

## Restore procedure (if ever needed)

1. `cp .dexCore/_archive/onboarding-v4.3-2026-04-22/onboarding-questions.yaml
   /tmp/onboarding-v4.3.yaml`
2. Consider whether the 3 removed features should be re-added to features.yaml
3. Update mydex-agent R1-routing if reintroducing the legacy path

## Integrity

SHA-256 sum in `SHA256SUMS.txt`. Do not modify archived files.
