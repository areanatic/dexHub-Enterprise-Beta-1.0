# DexHub Backend Adapter Pattern

Every optional backend (parser, embedding, voice, …) that DexHub CAN use but shouldn't REQUIRE follows the same shell-adapter contract. This doc codifies that contract so each new adapter (ollama_vlm, pattern_a, future cloud OCR) stays aligned.

Reference implementations at time of writing:

- **Embedding:** `.dexCore/core/knowledge/l2/l2-detect-backend.sh` + `l2-embed.sh`
- **Parser:** `.dexCore/core/parser/backends/kreuzberg.sh`

If you're about to create a new backend adapter, copy one of those files and modify per this doc.

---

## Principles

1. **Never block.** An adapter must exit 0 by default when its backend isn't available. "Not installed" is an answer, not an error. Callers opt into hard-fail via `--require`.
2. **Probe cheaply.** `--detect` uses `command -v` + a single version probe. No network, no file ops, no side effects. Detection runs on every router invocation — must be fast.
3. **Honest hints.** When a backend is missing, the adapter emits a concrete install command (brew / cargo / docker / pip / `ollama pull …`). Never recommend we automate the install for the user.
4. **Identical JSON contract.** Every adapter returns the same top-level fields so downstream code can treat them interchangeably.
5. **Graceful degradation documented.** Callers (router, orchestrators) assume adapters might be missing. Adapters never panic.

---

## Required flags

| Flag | Meaning |
|---|---|
| `--detect` | Probe mode. Emit status JSON. Always exits 0. |
| `--extract PATH` | Run mode. Invoke the backend on a file. Returns content + metadata JSON. |
| `--format json` | Default. Structured output for machines. |
| `--format text` | Human-readable. Used by `l2-status.sh`-style dashboards. |
| `--require` | Flip graceful-exit-0 to exit 2 when backend missing. For scripts that need hard-fail. |
| `--help` / `-h` | Print usage. |

Additional flags are allowed but MUST be optional (`--endpoint`, `--model`, `--min-confidence` for VLM, …). Default behavior must work without any non-standard flags.

---

## Status vocabulary (for `--detect`)

Exactly one of:

| Status | Meaning |
|---|---|
| `ready` | Backend installed + reachable + policy allows |
| `not_installed` | Nothing on PATH / binary missing |
| `probe_failed` | Binary found but version call errored (unusual) |
| `blocked` | Policy forbids this backend (cloud + `local_only` policy, etc.) |
| `partial` | Reserved: installed but missing a required sub-dependency (e.g. Ollama running but model not pulled) |
| `deferred` | Reserved: backend category not yet implemented (scaffolded only) |

---

## JSON shape

### `--detect` output

```json
{
  "backend": "<string, matches entry in capabilities.yaml>",
  "binary": "<absolute path or empty>",
  "version": "<version string or empty>",
  "status": "<one of the vocabulary above>",
  "setup_hint": "<concrete next step>",
  "supported": ["<format1>", "<format2>"],
  "compliance": "ok" | "local_vlm_required" | "cloud_only"
}
```

Extensions are allowed as siblings (e.g. VLM adapters may add `model` or `endpoint`). Do not rename the core fields.

### `--extract PATH` output

```json
{
  "backend": "<string>",
  "file": "<path>",
  "status": "ok" | "not_installed" | "extract_failed" | "probe_failed",
  "content": "<extracted text>" | null,
  "error": "<human message on failure>",
  "hint": "<concrete next step on failure>"
}
```

Vision adapters may add `confidence[]`, `model_used`, `bboxes[]`, etc. as siblings. Do not rename `content`.

---

## Exit code contract

| Code | Meaning |
|---|---|
| 0 | Success OR graceful-degradation (default) |
| 1 | Bad args / unknown flag / no-args |
| 2 | `--extract --require` AND backend not ready |
| 3 | `--extract` called on a missing file |
| 4 | `--extract` crashed — backend bug or unsupported format |

`--detect` always exits 0. `--extract` exits 0 by default even when backend missing (graceful); `--require` promotes missing-backend to exit 2.

---

## Parameterize vs copy

When adding a new adapter, **copy** the entire shape of `kreuzberg.sh` (arg parse, help text, JSON generation, exit codes) and **modify only** these regions:

- `probe_<backend>()` body — how this specific backend reports version
- `extract_<backend>()` invocation — the actual CLI call (`kreuzberg extract`, `ollama run <model>`, etc.)
- `supported[]` list — what formats this backend handles
- `compliance` value — `ok` for local-text, `local_vlm_required` for vision, `cloud_only` for remote
- `setup_hint` text — install commands for THIS backend
- Flag additions must be OPTIONAL (defaults make the adapter work without them)

---

## Enterprise compliance gating (NEVER in the adapter itself)

Adapters do NOT read `profile.company.data_handling_policy`. Enterprise policy gating is one layer UP — the orchestrator (router, l2-embed.sh, inbox_auto_parse) reads policy and refuses to call an adapter whose compliance level violates it.

Rationale: an adapter is a capability, not a decision-maker. This mirrors `l2-embed.sh`'s handling of `l2_tank_enterprise_compliance` — the embed script reads policy, the detect adapter doesn't.

Exception: if an adapter's backend has its own internal policy (e.g. Ollama is LAN-only by default), report that honestly in `compliance`. Gate in the caller.

---

## Test discipline

Every adapter ships with a structural test (`tests/e2e/NN-parser-<backend>-backend.test.sh` for parser adapters) that asserts, with no external dependency:

1. Script exists, is executable, bash-parses cleanly.
2. `--help`, `--detect`, `--extract` all respond.
3. `--detect` JSON has the 7 required fields + valid status vocabulary.
4. `--extract` on a missing file returns exit 3.
5. `--extract` without the backend installed returns graceful exit 0 + JSON status=not_installed.
6. `--extract --require` without backend returns exit 2.
7. `features.yaml` entry is registered + `tests[]` references this file + known_issues documents the install requirement.

Opt-in live test (gated behind `CLAUDE_E2E_LIVE_<BACKEND>=1` env var) asserts real extraction round-trip. Skipped when `--detect` status != ready.

Match `tests/e2e/23-parser-kreuzberg-backend.test.sh` as the template.

---

## Sub-features to register

Every new adapter lands with:

1. One `- id: parser.<backend>_backend` (or `knowledge.<backend>_backend` etc.) entry in `features.yaml` with status=enabled, tests[] ref, compliance level, optional_deps list, 3-5 candid known_issues.
2. One line in `capabilities.yaml.example` under `parser.backends.<backend>` so users can flip `installed: true` after they install.
3. Mention in the relevant architecture doc (e.g. `L2-TANK.md` milestones table).

---

## Non-goals

- **Adapters do NOT manage installation.** `brew`/`pip`/`cargo` calls belong to the user or the future `guided_setup_wizard` (`parser.guided_setup_wizard`, 5.3.g).
- **Adapters do NOT write `capabilities.yaml`.** Read-only access. `guided_setup_wizard` owns writes.
- **Adapters do NOT chain to other backends.** Fallback chains live in the router (`parse-route.sh`) or orchestrator (`inbox_auto_parse`).
- **Adapters do NOT implement enterprise policy.** Declare compliance; let the caller gate.

---

## Authoritative location

This doc lives at `.dexCore/_dev/docs/BACKEND-ADAPTER-PATTERN.md` and is the canonical reference. When the pattern evolves (e.g. we add a `partial` status code to handle "Ollama running but model missing"), update this doc first, then update `l2-detect-backend.sh` + `kreuzberg.sh` to match, then propagate to the next adapter.
