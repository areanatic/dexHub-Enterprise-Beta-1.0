# Saved Consent Tracking

> **Status (2026-04-20):** Phase 5.1.c Tier 3.1 — spec-level enforcement shipped.
> **Feature:** `meta.saved_consent_tracking` in `.dexCore/_cfg/features.yaml`
> **Profile schema:** v1.2 (additive; v1.0 and v1.1 profiles remain valid)

## Problem

Every time a user loads a connector (Atlassian, GitHub, Figma) or switches to a cloud-LLM backend, DexHub asks the same consent question: *"this connector sends data to a cloud service. Proceed?"*

If the user's answer is stable across sessions — they've already decided — re-asking is noise. It also trains users to click through consent prompts without reading, which defeats the point of asking.

## What this tracks

A `consents` array on `profile.yaml` records which features the user has explicitly granted consent for, under what data-handling context, and when.

```yaml
consents:
  - feature_id: connectors.github_wizard
    granted_at: "2026-04-20T10:15:00Z"
    granted_by_command: "*github-setup"
    data_handling_context: "cloud_llm_allowed"
    expires_at: null   # null = no expiry; ISO-8601 if set
    notes: "Initial setup. User was on cloud_llm_allowed policy."
```

## Semantics

A stored consent is **valid** when all of these hold:

1. Entry exists for the `feature_id`
2. `data_handling_context` matches `profile.company.data_handling_policy` — if the policy changes, prior consents become invalid (must re-consent)
3. `expires_at` is null OR in the future

If any fail, treat as "never granted" and ask again.

## Agent contract

**Connector wizards** (Atlassian / GitHub / Figma / future cloud tools) follow this protocol:

### Before asking for consent:

1. Read `profile.yaml → consents[]`
2. Find entry where `feature_id` matches the current connector
3. If found AND still valid (see Semantics), announce quietly:
   ```
   (Consent previously granted 2026-04-20 under policy 'cloud_llm_allowed' — not re-asking.)
   ```
   Skip the consent question.
4. Otherwise, ask normally.

### When consent is granted:

1. Append a new entry to `profile.yaml → consents[]`
2. Include `data_handling_context = profile.company.data_handling_policy` at time of grant
3. Set `granted_at = current ISO-8601 timestamp`
4. `expires_at = null` unless the connector defines a policy-specific expiry
5. Write the file. Announce: `📌 Consent für <feature> gespeichert.`

### When consent is revoked (`*revoke-consent <feature>`):

1. Remove the entry (or move to `revoked_consents[]` archive array)
2. Announce: `🚫 Consent für <feature> widerrufen. DexHub fragt beim nächsten Use erneut.`

## DexMaster surface

- **`*consents`** — list current consents with feature_id, granted_at, policy-context
- **`*revoke-consent <feature>`** — remove a consent entry

These commands operate on `profile.yaml` directly. They are short, predictable, auditable.

## Interaction with Enterprise Compliance

Saved consent is **not** a compliance bypass. The Enterprise Compliance Gate (`meta.enterprise_mode_toggle`) runs BEFORE consent check:

```
┌──────────────────────────────────────────────────────────┐
│  1. Enterprise Compliance Gate                           │
│     Does profile.company.data_handling_policy permit     │
│     this feature at all?                                 │
│       → if no: BLOCK (no re-consent possible)            │
│       → if yes: continue                                 │
│                                                          │
│  2. Saved Consent Check                                  │
│     Is there a valid consent entry?                      │
│       → if yes: proceed quietly                          │
│       → if no: ASK, then record if granted               │
└──────────────────────────────────────────────────────────┘
```

If compliance changes (user updates `data_handling_policy`), existing consents become invalid because the `data_handling_context` field won't match. This is intentional — a policy change is a meaningful boundary, and re-asking is the right behavior.

## Honesty label

- **What's enforced today:** the agent prompt contract (spec-level). Connector wizard agents follow the protocol because their `.agent.md` instructs them to.
- **What's NOT enforced:** kernel-level. A rogue agent ignoring its prompt could bypass the check. This matches the rest of the DexHub trust model — we ship a trustworthy prompt to a compliant agent, not sandbox enforcement.
- **Tests:** `tests/e2e/05-consent-tracking.test.sh` checks the structural invariants (schema has `consents`, wizard agents reference the check). Live-behavior test is a Phase 5.1.c Tier 5.3 follow-up.

## Migration

- v1.0 and v1.1 profiles: fully backward compatible. `consents` field is optional, missing = no consents stored yet.
- First write: if the profile lacks a `consents` key, the agent adds `consents: []` then appends. No migration tool needed.
