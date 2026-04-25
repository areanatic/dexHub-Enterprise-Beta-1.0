# Troubleshooting — DexHub Enterprise Beta 1.0

> **🌐 Language:** **EN** (this file) · [🇩🇪 DE](de/TROUBLESHOOTING.md)

Pragmatic help for the most common problems. Structure: **Symptom → Cause → Fix**.

---

## Installation & Setup

### `@dex-master hi` — no response

**Causes:**
1. The Copilot / Claude / IDE chat panel isn't loaded yet
2. Wrong working directory — your IDE chat is in a different folder
3. Custom-instructions file isn't being read (see "DexMaster doesn't activate")

**Fix:**
```bash
# Verify you're in the DexHub repo root
pwd  # should be the dexHub-Enterprise-Beta-1.0 directory
ls .github/copilot-instructions.md  # should exist
ls .claude/CLAUDE.md  # should exist
```

If your IDE doesn't pick up the custom instructions, restart the IDE in the repo root.

---

### Validate.sh fails

**Symptom:** `bash .dexCore/_dev/tools/validate.sh` returns non-zero.

**First debug step:** look at the FAIL lines in the output — each one is annotated with what's missing.

**Common causes:**
1. **Hash mismatch** for a critical file → run `bash .dexCore/_dev/tools/build-instructions.sh build` to regenerate, then validate again
2. **Missing test files** referenced in features.yaml → either the test was deleted (check `git log`) or the path is wrong
3. **Drift in counts** between README and features.yaml → README was updated separately from the registry

If validate.sh is genuinely confused, see the per-section commit history: `git log .dexCore/_dev/tools/validate.sh`.

---

### Ollama port 11434 already in use

Another process is bound to Ollama's default port.

**Fix:**
```bash
lsof -i :11434  # find the process
# Either: kill it, or:
ollama serve --port 11435  # start Ollama on a different port
# Then point DexHub at the new port via .dexCore/_cfg/config.yaml
```

---

### Git push rejected

**Symptom:** `git push` fails with "Updates were rejected because the remote contains work that you do not have locally."

**Cause:** Someone (or another session) pushed to the remote since your last pull.

**Fix:**
```bash
git pull --rebase
# Resolve any conflicts
git push
```

**WARNING:** If you're on a colleague-shared branch, NEVER force-push. Communicate first.

---

### Build-Instructions.sh shows .claude/CLAUDE.md as modified after every run

**Was a known issue (B3) — fixed 2026-04-25.**

After the fix, `build-instructions.sh build` only rewrites the output files if the actual content changed (Generated: timestamp alone no longer dirties the file). If you still see this issue:

```bash
# Make sure you have the fix
git log --grep="idempotency" .dexCore/_dev/tools/build-instructions.sh
```

If no commit found, pull latest from main.

---

## Onboarding

### Onboarding doesn't start when I type `@mydex`

**Causes:**
1. profile.yaml already exists and is complete → DexMaster shows the menu instead of starting onboarding
2. The custom-instructions file isn't being read by your IDE

**Fix:**
- To re-onboard: `*mydex` → menu → `*onboarding` → onboarding-menu → "1. Onboarding starten"
- To wipe profile: `rm myDex/.dex/config/profile.yaml` then `@mydex` again

---

### "I want to start a project" — where do I find that?

`@mydex create-project` as a direct command does not exist (that was a docs drift). The real path today is via menu:

1. Activate `@mydex` → myDex agent shows its menu
2. Pick **🚀 New Project** menu item (sub-menu opens) — or just say natural-language "ich möchte ein Projekt starten" / "I want to start a project"
3. Agent asks for project name + short sparring (What's it about? What do you want to build?)
4. Agent creates `myDex/projects/{name}/.dex/` skeleton + initial draft

**If nothing happens:**
1. `myDex/projects/` doesn't exist as a folder → (since Beta 1.0 the skeleton exists; if not: `mkdir myDex/projects/`)
2. Agent has a write-permission problem → check if you need a `.gitignore` exception for your new project
3. Consent gate not yet completed — agent asks for confirmation before writing (G5)

**Planned for 1.0.1+:** DexMaster intent-detection — you type "I want to start a project" at DexMaster level, and DexMaster routes you directly to `#create-new-project` without menu clicks.

---

### Workflow stops in the middle

**Check:**
1. Is profile complete? `@mydex status` — are required fields missing?
2. Is a project active? `@mydex switch-project` if needed
3. Logs? Agents don't write structured logs — scroll the chat history for error messages

For non-trivial errors → file a GitHub Issue with:
- Workflow name
- Last 5 messages
- Output of `validate.sh`
- Profile file (`myDex/.dex/config/profile.yaml`) — **redact private fields first**

---

## Parser & Inbox

### `*inbox` doesn't process my files

**Check the parser-setup status:**
```
@dex-master *parser-setup
```

Probably one of these:
- Backend not installed (kreuzberg / ollama_vlm / pdftotext) → install via the hint shown
- File extension not supported → see `.dexCore/core/parser/capabilities.yaml`
- File too large or malformed → check `.processed/` for the archived original + log

---

### PDF returns gibberish text

**Cause:** A binary-copy regression OR the source PDF is image-based (scanned PDF without OCR layer).

**Fix:**
- If pdftotext-shipping: should error correctly (not silent ok). The 2026-04-21 binary-copy bug was fixed.
- For image-based PDFs: install Ollama VLM + a vision model (`ollama pull moondream`) and route through the ollama_vlm backend.

---

## Agents & Workflows

### Agent introduces itself with the wrong name

**Was a known issue with persona renames (Kalpana, Yamuna).** Fixed 2026-04-25.

If you still see e.g. "TestArch Pro" instead of "Kalpana", check:
- The agent's persona file: `.dexCore/dxm/agents/testarch-pro.md`
- The Copilot stub: `.github/agents/testarch-pro.agent.md`

If they say "Kalpana" but the chat says "TestArch Pro": your IDE has stale custom-instructions cached. Restart the IDE chat panel.

---

### `*list-skills` doesn't appear in the menu

**Was a known issue — fixed 2026-04-25 (D5).**

`*list-skills` is now in DexMaster menu between `*list-workflows` and `*features`. If you don't see it:
```bash
git log --grep="list-skills" .dexCore/core/agents/dex-master.md
```
If no commit found, pull latest from main.

---

## Performance

### DexHub is slow / laggy

**Likely causes:**
1. **Large repo** — DexHub indexes content; very large repos can take time
2. **L2 semantic search building** — first time index can take minutes; subsequent queries are sub-second
3. **Cloud LLM rate-limit** — if you're hitting API limits, switch temporarily to local Ollama

---

### My agent doesn't remember context from earlier in the session

**This is expected.** Agents are stateless per turn. State persists via:
- `myDex/.dex/CONTEXT.md` (system state)
- `myDex/projects/{name}/.dex/CONTEXT.md` (per-project state)
- `myDex/.dex/chronicle/YYYY-MM-DD.md` (session logs)

If you want the agent to remember something explicitly, ask it to save to one of these.

---

## When in doubt

```bash
bash .dexCore/_dev/tools/validate.sh
```

273 PASS / 0 FAIL / 0 WARN = your installation is structurally sound.

For semantic issues (agent says X but reality is Y), check:
```bash
git log --oneline -20  # what changed recently?
git status  # what's modified locally?
```

And as last resort: file a GitHub Issue or use Dev-Mode (`@dex-master *dev-mode` → `*bug`).

---

**Want the full German version with extended examples?** See [`de/TROUBLESHOOTING.md`](de/TROUBLESHOOTING.md).
