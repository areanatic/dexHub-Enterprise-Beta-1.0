# DexHub Enterprise Build — Strip Integration Modules

> **Purpose:** Prepare a clean enterprise-target bundle from the areanatic dev repo.
> **Script:** `.dexCore/_dev/tools/build-for-enterprise.sh`
> **Policy:** see `PLATFORM-POLICY.md`.

## The one-line story

The areanatic repo is the developer playground. It contains Claude Code tooling, test harnesses using `claude -p`, and other dev conveniences. None of those ship to enterprise — the enterprise build is Copilot-primary only.

## What gets stripped

| Path | Reason |
|---|---|
| `.claude/` | Claude Code session config + cache + hooks. Already in `.gitignore` for sensitive subpaths; this script strips the whole folder for enterprise. |
| `tests/e2e/integrations/claude-code/` | Tests requiring the `claude` CLI; not part of the Beta product surface. |
| `tests/e2e/integrations/*/` | All current and future integration modules (cursor/, intellij/, etc.) |
| Any file tagged with `integration_module: <non-null>` in features.yaml | Catch-all for future tagging. |

## What stays

| Path | Reason |
|---|---|
| `.github/` | Copilot native — the Beta product. Must stay. |
| `.dexCore/` | Framework internals. Stays. |
| `myDex/` | User workspace conventions. Stays. |
| `tests/e2e/` (core tests) | Structural tests that run without any platform CLI. Stay. |
| `tests/e2e/harness/assertion-lib.sh` | Pure bash, platform-agnostic. Stays. |

## Usage

```bash
# Dry run — list what would be stripped, don't actually produce a bundle
bash .dexCore/_dev/tools/build-for-enterprise.sh --dry-run

# Produce bundle
bash .dexCore/_dev/tools/build-for-enterprise.sh \
  --output /tmp/dexhub-enterprise-beta.tar.gz

# Produce + verify: after strip, run validate.sh structurally
bash .dexCore/_dev/tools/build-for-enterprise.sh \
  --output /tmp/dexhub-enterprise-beta.tar.gz \
  --verify
```

## Script contract

1. Copy repo (excluding `.git`, working state) to a scratch directory
2. Delete `.claude/`
3. Delete `tests/e2e/integrations/`
4. (Future) Delete any feature-tagged integration-module paths per features.yaml
5. Run `validate.sh` in scratch directory
   - If structural checks pass (§1-§24 minus integration-module-dependent assertions), build is clean
   - If any structural check fails, abort with error (integration coupling leaked into core)
6. Tar the scratch directory to output path
7. Print summary: files removed, bundle size, validation status

## What this prevents

- Accidentally shipping `.claude/CLAUDE.md` (already caught by global rule)
- Shipping tests that require `claude` CLI — which would fail for enterprise auditors running the test suite
- Coupling the Beta spec to Claude Code semantics (session ID, permission mode, etc.) — which violates the single-platform promise
- Ambiguity in architectural decisions — every future integration has a defined pattern (directory + tag + strip rule)

## What this does NOT do

- Does not push anywhere — output is a local tarball; actual push to enterprise remote is a separate decision + step.
- Does not rewrite history — the areanatic repo is untouched. The script works on a scratch copy.
- Does not enforce the policy continuously — that's `validate.sh §25`'s job. This script operates at release-prep time.

## Future extensions

- Auto-detect new integration modules: scan `tests/e2e/integrations/` and `.dexCore/core/integrations/` dynamically instead of hardcoding paths
- Include a manifest in the bundle: `ENTERPRISE-BUILD-MANIFEST.md` listing what was stripped + why + the validate.sh score
- Integrate with CI: on tag push, auto-produce the bundle and attach to the GitHub release
