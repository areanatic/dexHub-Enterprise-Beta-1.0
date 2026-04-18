# DexHub E2E Test Suite

**Phase 5.0 Test Harness Foundation (2026-04-19)**
**Phase 5.1.a Live claude-runner layer (2026-04-19)**

Automated tests that validate DexHub features actually work end-to-end — not just that files exist. This complements `validate.sh` (which checks structural invariants) with **feature-function validation**.

---

## Why E2E tests?

The 2026-04-18 audit of DexHub Beta found "features exist in files" but we had NO evidence they worked end-to-end. User surfaced the critical distinction:

> "Corrected from 'missing' to 'exists' is NOT the same as 'confirmed working end-to-end'."

These tests are the mechanism that bridges that gap. Every user-facing feature gets a test. No test = not shipped.

## Structure

```
tests/e2e/
├── harness/
│   ├── assertion-lib.sh      # pass/fail/assert_* helpers
│   └── claude-runner.sh      # Claude Code headless mode wrapper
├── fixtures/                 # Test data (sample PDFs, mock configs, scripted answers)
├── NN-*.test.sh              # Individual tests (numbered for order)
├── run-all.sh                # Master runner
└── README.md                 # This file
```

## Running locally

```bash
# Structural tests only (fast, no API cost) — DEFAULT
bash tests/e2e/run-all.sh

# Structural + LIVE claude-runner assertions (opt-in, uses API tokens)
bash tests/e2e/run-all.sh --live

# Single test
bash tests/e2e/00-fresh-install.test.sh

# Verbose (show claude stderr etc.)
bash tests/e2e/run-all.sh --verbose
# or:
CLAUDE_E2E_VERBOSE=1 bash tests/e2e/run-all.sh
```

### Live mode — what it does

With `--live` (or `CLAUDE_E2E_LIVE=1`), tests invoke `claude -p` headlessly to exercise DexHub behavior against a real LLM. Each invocation:

- Costs API tokens (your Claude Code subscription / API key).
- Takes ~10-60 seconds per assertion.
- Auto-unsets `CLAUDECODE` so tests can run from inside a dev session.

If `claude` CLI is missing, live assertions fail with a clear message. Structural assertions always run regardless.

## Current tests

| # | Test | Requires | Structural | Live (--live) |
|---|------|----------|-----------|---------------|
| 00 | `00-fresh-install.test.sh` | None | 36 assertions | — |
| 01 | `01-onboarding-smart.test.sh` | Ruby / Python+YAML | 15 assertions | 4 assertions (DexMaster greeting, menu render, *mydex entrypoint) |

## Coming next (Phase 5.1+)

- `10-agent-load-analyst.test.sh` — Load Jana → first response as Jana (not DexMaster) [needs claude-runner]
- `11-agent-identity-stick.test.sh` — Jana 10 turns → say "hi" → stays Jana
- `12-agent-switch.test.sh` — Jana → Alex → CONTEXT.md correctly updated
- `20-workflow-prd.test.sh` — PRD workflow produces real PRD.md
- `30-connector-atlassian-mock.test.sh` — Wizard with mock URL → config written
- `40-parser-pdf.test.sh` — Sample.pdf in inbox → text extracted (after Phase 5.3)
- `50-knowledge-ingest.test.sh` — Docs ingested → query returns chunks (after Phase 5.2)

## Writing a new test

```bash
#!/bin/bash
# DexHub E2E Test NN — Description

set -u
HARNESS="$(cd "$(dirname "$0")/harness" && pwd)"
source "$HARNESS/assertion-lib.sh"

ensure_beta_root
test_banner "NN Descriptive Name"

# Your assertions here
assert_file_exists "path/to/thing" "Description"
assert_file_contains "file.md" "pattern" "Description"
# ... etc

test_summary
```

Mark executable: `chmod +x tests/e2e/NN-*.test.sh`.

## Assertion helpers

- `pass "description"` — record a pass
- `fail "description" ["detail"]` — record a fail with optional detail
- `assert_file_exists <path> [desc]`
- `assert_dir_exists <path> [desc]`
- `assert_file_contains <path> <pattern> [desc]`
- `assert_file_not_contains <path> <pattern> [desc]`
- `assert_equal <actual> <expected> [desc]`
- `assert_command_succeeds <cmd> [desc]`
- `assert_yaml_valid <path> [desc]`
- `assert_claude_response_contains <prompt> <pattern> [desc]` (requires claude-runner.sh sourced)

## CI integration

`.github/workflows/e2e.yml` runs structural tests on every PR to main. Live tests are NOT run in CI by default — they need Claude Code installed + API credentials. A separate `e2e-live` job guarded by a repository secret + manual dispatch will follow.

## First live finding (2026-04-19)

Live-mode proved DexMaster greeting works end-to-end — not a structural claim, a measured one:

- `claude -p "hi"` from Beta root returns 870 chars naming "Dex Master"
- Menu items 1-7 render cleanly
- `*mydex` onboarding entrypoint is visible in the menu

This is the first measured confirmation that the SSOT→compiled CLAUDE.md→DexMaster greeting chain actually works in headless Claude Code. Structurally green ≠ measurement green; the live layer closes that gap.

## Relationship to validate.sh

- **validate.sh**: Structural checks (file existence, hash integrity, manifest consistency, cross-platform source alignment)
- **E2E tests**: Feature-function checks (does the feature produce expected output when exercised?)

Both must pass for ship. validate.sh runs in ~3 seconds. E2E suite currently runs in <1 second (will grow).

## Philosophy

**Every audit claim about functionality requires E2E test evidence.** This discipline prevents the "exists = works" conflation that burned the 2026-04-18 audit.
