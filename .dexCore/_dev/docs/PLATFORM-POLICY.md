# DexHub Enterprise Beta — Platform Policy

> **Status:** Layer-1 binding rule (elevated to truth-manifest class).
> **Created:** 2026-04-20 after violation discovered same day.
> **See also:** `LEARNINGS-CLAUDE-CODE-REMOVABILITY.md` (learning that produced this policy), `ENTERPRISE-BUILD.md` (the build-strip mechanism that enforces it).

---

## The rule

**DexHub Enterprise Beta is built for GitHub Copilot.**

Nothing else.

All other platforms — Claude Code, Cursor, IntelliJ, Continue.dev, Ollama, direct API — are **optional integration modules**. They may ride alongside the Beta product in the development repo (areanatic), but they MUST be strippable for any enterprise push.

## Why

- Enterprise Beta targets one specific deployment environment (GitHub Copilot inside corporate IDEs).
- Any second-platform coupling creates support burden we haven't accepted and licensing surfaces we haven't vetted.
- Integration modules can evolve independently, version independently, and ship later as optimized targets (Claude Code optimization, Cursor optimization, IntelliJ optimization — all future work, currently out of scope).
- Dev convenience (using `claude -p` for test harnesses) is fine when the dev convenience is **physically separable** from the shipped product.

## Primary vs integration

| Category | Primary (ships in Beta) | Integration Module (removable) |
|---|---|---|
| Native user surface | `.github/copilot-instructions.md`, `.github/agents/*.agent.md`, `.github/copilot-chatmodes/*.md` | `.claude/CLAUDE.md`, `.claude/settings.json`, `.claude/agents/`, `.claude/skills/`, etc. |
| Skills / hooks | Copilot-native skills (future: `.github/copilot-skills/`) | Claude Code skills / hooks |
| Test harness | Platform-agnostic structural tests (file-existence, YAML parse, cross-reference) | Tests using `claude -p` or any platform-specific CLI |
| Docs | Platform-agnostic user docs (README.md, CONTRIBUTING.md, `.dexCore/_dev/docs/*`) | Platform-specific tutorials |

## Directory conventions

Files that are **platform-agnostic** (ship in Beta + all integration bundles):
- `.dexCore/` (framework internals: SSOT, agents source, schemas, workflows)
- `.github/` (Copilot native — the primary target)
- `myDex/` (user workspace; `.example` files tracked)
- `tests/e2e/` (structural tests, platform-agnostic harness)
- `tests/e2e/harness/assertion-lib.sh` (pure bash, no platform dependency)
- `CONTRIBUTING.md`, `LICENSE`, `NOTICE`, `README.md`

Files that are **removable integration modules** (stripped for enterprise push):
- `.claude/` (entire folder — Claude Code specific)
- `tests/e2e/integrations/claude-code/` (Claude-Code-requiring tests + `claude-runner.sh`)
- Future: `tests/e2e/integrations/cursor/`, `tests/e2e/integrations/intellij/`, etc.

## How features.yaml reflects this

Every feature declares its platform stance:

```yaml
- id: onboarding.smart_v5
  primary_target: github_copilot        # Where it ships in Beta
  secondary_targets: [claude_code]      # Works there too (as dev convenience)
  integration_module: null              # Null = core, not a module
  status: enabled

- id: quality.walkthrough_smart_v5_full
  primary_target: null                  # N/A — this is test infra, not user feature
  integration_module: claude-code       # REMOVABLE for enterprise build
  status: enabled
```

Fields:
- `primary_target` — the platform this feature ships to. For Beta, almost always `github_copilot` or `null` (infra).
- `secondary_targets` — list of platforms this feature happens to also work on. Not a promise.
- `integration_module` — if set, this feature lives in a removable module and disappears from enterprise builds.

## How build-for-enterprise.sh enforces this

`.dexCore/_dev/tools/build-for-enterprise.sh` produces a clean enterprise bundle:

1. Copies the repo to a scratch directory.
2. Removes `.claude/`.
3. Removes `tests/e2e/integrations/*/` (all integration modules).
4. Removes any file with a tag `integration_module: <non-null>` in features.yaml + validates no core file references these paths.
5. Runs `validate.sh` against the stripped tree — if structural checks still pass, the build is clean.
6. Outputs `dexhub-enterprise-beta-<date>.tar.gz` ready for enterprise push.

The current repo (areanatic main) is NOT stripped — it's the dev playground. The build script runs only when preparing an enterprise push.

## How validate.sh §25 enforces this

New validation section checks:

- **Purity:** no file outside `tests/e2e/integrations/` references `claude-runner.sh`, `claude -p`, or Claude-Code-specific env vars
- **Self-containment:** `tests/e2e/integrations/claude-code/` is self-sufficient — moving it out doesn't break anything else
- **Feature tagging:** every feature referencing a path under `tests/e2e/integrations/` must have `integration_module` set

## Future-proofing

When we add Cursor, IntelliJ, or Continue.dev integrations later, the same pattern applies:

- Directory: `tests/e2e/integrations/cursor/`, `tests/e2e/integrations/intellij/`
- features.yaml tag: `integration_module: cursor`, `integration_module: intellij`
- build-for-enterprise.sh: add to the strip list (no code changes needed if it reads from a config)

## Review discipline

This policy is a **Layer-1 binding rule**. It overrides any earlier assumption that "Claude Code is a peer target for Beta". It is not a preference — it is a requirement.

Every session:
- **Before touching `.dexCore/core/` or `tests/e2e/`:** ask "is this file a core artifact, or is it platform-specific?"
- **Before committing:** run mental strip — if `tests/e2e/integrations/` and `.claude/` were removed, does `validate.sh` still pass?
- **Before recommending a next step:** if it names `claude-code`, `wire-claude`, or similar, consider if the Copilot-equivalent is unmet first.

Memory trigger: "Claude Code bias / enterprise purity / removable module" routes here + to the learning doc.
