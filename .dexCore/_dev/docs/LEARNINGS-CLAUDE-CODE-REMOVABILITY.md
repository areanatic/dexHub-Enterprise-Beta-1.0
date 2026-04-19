# Learning: Claude Code is an Integration Module, not a Beta Target

> **Date:** 2026-04-20
> **Context:** 9 Beta commits today added Claude-Code-coupled test infrastructure directly into `tests/e2e/`. User correction made it clear this violates the spirit of Enterprise Beta = Copilot-primary.
> **Severity:** architectural (touches multiple commits)
> **Global mirror:** `~/.claude/learnings/claude-code-not-primary-for-beta-2026-04-20.md`
> **Policy this produced:** `PLATFORM-POLICY.md`
> **Enforcement:** `ENTERPRISE-BUILD.md` + `validate.sh` §25

---

## What happened

During the "ballert durch" session 2026-04-20 I shipped:
- `tests/e2e/harness/claude-runner.sh` (Claude-Code-specific harness)
- `tests/e2e/02-onboarding-walkthrough.test.sh` (uses claude-runner)
- `tests/e2e/03-onboarding-smart-v5-full-walk.test.sh` (uses claude-runner)
- `tests/e2e/06-onboarding-existing-profile.test.sh` (uses claude-runner)
- `tests/e2e/07-onboarding-overwrite-reject-confirm.test.sh` (uses claude-runner)
- `tests/e2e/08-onboarding-view-profile.test.sh` (uses claude-runner)
- `tests/e2e/09-onboarding-complete-only.test.sh` (uses claude-runner)

All in core `tests/e2e/`. I also wrote `L1-WIKI-INJECTION.md` with milestones listed "wire-claude-code" *before* "wire-copilot" and recommended the Claude-Code wire-up as Option 1 for the next session slice.

## Why this is a violation

Enterprise Beta targets GitHub Copilot. Only. Everything else is an integration module. See `PLATFORM-POLICY.md` for the binding rule.

My work was correct structurally (the tests gate their live portions, the loaders are platform-agnostic) but architecturally wrong (the tests live in core paths, implying Claude Code is a first-class target).

## Why I missed it

1. **Tool-of-hand blindness** — `claude -p` was the easiest headless runner on my machine, so I used it. Didn't ask "what platform does the product target?" before structuring the test directory.

2. **Narrow rule-matching** — I'd registered "don't push `.claude/`" as a folder-specific rule. I didn't generalize to "don't ship ANY Claude Code coupling".

3. **Long-session context drift** — the Beta-Copilot-primary rule was clear at session start from CLAUDE.md. Across 9 commits I lost sight of it.

## The fix (this commit set)

1. **Restructure:** move `claude-runner.sh` + tests 02/03/06-09 into `tests/e2e/integrations/claude-code/`. Pattern works for future integrations too.
2. **Graceful fallback:** `harness/assertion-lib.sh` defines no-op stubs for `check_claude_installed`, `walkthrough_mode_enabled`, `live_mode_enabled` — if `integrations/claude-code/claude-runner.sh` isn't loaded, all live assertions auto-skip cleanly.
3. **Policy doc:** `PLATFORM-POLICY.md` — binding rule with directory conventions and features.yaml tagging.
4. **Build-strip:** `build-for-enterprise.sh` — produces a clean enterprise bundle by removing `.claude/` and `tests/e2e/integrations/`.
5. **Validator:** `validate.sh` §25 — checks that no core file references `claude-runner.sh` or `claude -p`, and that the tagging is consistent.
6. **features.yaml audit:** add `integration_module` field, tag all 7 affected features (6 test entries + `quality.walkthrough_multi_turn`).
7. **L1-WIKI-INJECTION.md fix:** reorder milestones — `5.2.d-wire-copilot` before `5.2.d-wire-claude-code`. Add "Enterprise Build Constraint" section.

## Review-point carry-forward

Add to session-start checklist (and enforce via validate.sh §25):

> **Before every commit that touches `tests/e2e/`, `.dexCore/core/`, or anywhere outside `integrations/`:** ask "could this file survive `build-for-enterprise.sh`?" If it requires `claude` CLI or any non-Copilot tool, it belongs in `integrations/<platform>/`.

## Specific corrections made

| Artifact | Before | After |
|---|---|---|
| `tests/e2e/harness/claude-runner.sh` | in core harness | moved to `tests/e2e/integrations/claude-code/` |
| Tests 02/03/06/07/08/09 | in `tests/e2e/` | moved to `tests/e2e/integrations/claude-code/` |
| Test 01 live block | sources `harness/claude-runner.sh` unconditionally | sources conditionally; degrades to structural-only when module absent |
| `L1-WIKI-INJECTION.md` milestones | wire-claude-code FIRST | wire-copilot FIRST |
| features.yaml `integration_module` | field did not exist | field added; 7+ entries tagged |
| `validate.sh` | no purity check | new §25 checks platform purity |
| `.dexCore/_dev/tools/` | no build-for-enterprise.sh | new script ships |

## What this does not fix

- **The recurring context-drift problem.** Across long sessions I lose sight of binding rules. Possible mitigation: `validate.sh §25` fires on every commit, so even if I forget, the check catches. But human-in-loop review at session checkpoints is still the right habit.
- **Future platform integrations** (Cursor, IntelliJ) will need the same pattern applied. This fix establishes the template.
- **Test-coverage regression.** Moving tests to `integrations/claude-code/` means they don't run in the default `tests/e2e/run-all.sh` enterprise-path. That's the whole point — enterprise doesn't need those tests to pass. But developer-path should still exercise them. `run-all.sh` is updated to enumerate integration modules by default (developer path) and skip them under `--enterprise-build` (enterprise path).
