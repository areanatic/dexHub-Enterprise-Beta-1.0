# Claude Code Integration Module — `tests/e2e/integrations/claude-code/`

> **Status:** Removable integration module.
> **Policy:** `.dexCore/_dev/docs/PLATFORM-POLICY.md`.
> **Stripped by:** `.dexCore/_dev/tools/build-for-enterprise.sh`.

## What lives here

Everything in this directory requires the **Claude Code CLI** (`claude -p`, `claude --resume`) to execute meaningfully. It is development-convenience infrastructure for the areanatic playground repo.

**It does NOT ship in Enterprise Beta.**

Contents:
- `claude-runner.sh` — headless-claude harness (start_conversation, resume_conversation, permission-mode flags, cost gates)
- `02-onboarding-walkthrough.test.sh` — multi-turn session-resume plumbing proof
- `03-onboarding-smart-v5-full-walk.test.sh` — SMART v5 full walkthrough → profile.yaml produced
- `06-onboarding-existing-profile.test.sh` — Tier 5.5.1 existing-profile cancel path
- `07-onboarding-overwrite-reject-confirm.test.sh` — Tier 5.5.3 confirm-gate reject path
- `08-onboarding-view-profile.test.sh` — Tier 5.5.4 view-profile read-only
- `09-onboarding-complete-only.test.sh` — Tier 5.5.2 partial-profile fill-in

All 6 live-portion tests are opt-in gated (`CLAUDE_E2E_LIVE_WALKTHROUGH=1`). Structural assertions within each test still run in default mode — they verify the spec is in place, independent of whether the claude CLI is installed.

## Why this module is removable

Enterprise Beta targets GitHub Copilot. Users running the enterprise bundle have no `claude` CLI on their path, so these tests could not pass there. Shipping them would mis-signal that Claude Code is a first-class target.

The `build-for-enterprise.sh` script deletes this entire directory before producing the enterprise tarball. `run-all.sh --enterprise` simulates the stripped state locally — core tests still pass with 108 assertions (23 assertions from this module drop out).

## How the stubs work

`tests/e2e/harness/assertion-lib.sh` defines no-op fallbacks for `check_claude_installed`, `live_mode_enabled`, `walkthrough_mode_enabled`, `claude_prompt`, etc. When a test in this directory is loaded:

1. Test sources `../../harness/assertion-lib.sh` → stubs in place
2. Test sources `./claude-runner.sh` (in this directory) → real implementations replace stubs

When this module is stripped, only step 1 runs — stubs stay, `live_mode_enabled` returns 1, live portions cleanly skip.

This same pattern allows test `01-onboarding-smart.test.sh` (in the core `tests/e2e/`) to have an opt-in live portion that uses `claude_prompt`: test 01 conditionally sources `integrations/claude-code/claude-runner.sh` if present, otherwise relies on stubs. Test 01 structural still passes both with and without this module.

## How to add tests here

If a new test requires the `claude` CLI:

```bash
#!/bin/bash
# New integration test
set -u
HARNESS="$(cd "$(dirname "$0")/../../harness" && pwd)"
CC_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$HARNESS/assertion-lib.sh"
source "$CC_DIR/claude-runner.sh"

ensure_beta_root
test_banner "NN Your test"

# ... assertions ...
test_summary
```

Drop the test file in this directory with a numeric prefix. `run-all.sh` enumerates both `tests/e2e/[0-9]*.test.sh` and `tests/e2e/integrations/*/[0-9]*.test.sh` automatically.

## Future-proofing

When other integration modules arrive (Cursor, IntelliJ, Continue.dev, Ollama), they follow the same pattern:

```
tests/e2e/integrations/cursor/       (Cursor-specific tests + cursor-runner.sh)
tests/e2e/integrations/intellij/     (IntelliJ-specific tests)
tests/e2e/integrations/ollama/       (local-Ollama-requiring tests)
```

Each gets its own README.md, its own stubs are shared via `harness/assertion-lib.sh`, and each is stripped by `build-for-enterprise.sh`.

The binding rule: **primary Beta target is GitHub Copilot. All other platforms live here, are removable.**
