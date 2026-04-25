# First 5 Minutes with DexHub

> **🌐 Language:** **EN** (this file) · [🇩🇪 DE](de/FIRST-5-MINUTES.md)

**Prerequisite:** You completed [Installation](INSTALLATION.md) (IDE + Git + Clone + `@dex-master hi` responds).

Now let's get to know DexHub in 5 minutes — through real examples.

---

## Minute 1: Set up your profile (Onboarding)

```
@mydex
```

DexHub's myDex agent activates and offers the canonical onboarding (5 short questions):

1. **Name** — How should we call you?
2. **Language** — DE / EN / Bilingual
3. **Experience** — Your years in your field
4. **Team Size** — Solo / Small / Medium / Large
5. **Data-Handling Policy** — The Enterprise Compliance gate (which LLMs / connectors can you use?)

Your answers go into `myDex/.dex/config/profile.yaml`. Local on your machine only. You can change anytime: `@mydex` → menu item `*profile`.

> **Want to extend your profile?** Via `*profile` editing you reach additional fields (Enterprise Compliance Q44–Q49, Custom Instructions Q40–Q41) — those aren't part of onboarding but available as optional fields.

---

## Minute 2: Meet the hub

```
@dex-master *help
```

You see DexMaster's full menu. The structure:

- **`*mydex`** — your personal workspace
- **`*list-agents`** — the 46 specialized AI agents (filterable by enabled packs)
- **`*list-workflows`** — 46 structured workflows (Analysis → Planning → Solutioning → Implementation)
- **`*list-skills`** — the 12 lazy-loaded knowledge packs
- **`*features`** — feature registry (what's enabled / deferred / known-broken)
- **`*packs`** — toggle agent groups on/off
- **`*inbox`** — auto-process files dropped into `myDex/inbox/`
- **`*council-mode`** — multi-agent collaboration
- **`*about`** — what is DexHub

> **Tip:** Skills (12 knowledge packs in `.github/skills/`) are auto-loaded by Copilot/Claude when contextually relevant. Structured overview via `@dex-master *list-skills`.

---

## Minute 3: Run a workflow

```
@analyst
```

The Business Analyst (Jana) activates. She offers her menu — pick a workflow like "Brainstorm Project" or "Create PRD". Each workflow walks you step-by-step through structured output generation (templates + validation).

Output lands in `myDex/drafts/` by default. Once you're happy with a draft, promote it to a project via `@mydex *projects`.

---

## Minute 4: Start a real project

Two paths:

**A) Natural language:**
```
@mydex
ich möchte ein Projekt starten
```
(or in EN: "I want to start a project")

myDex catches the intent, opens a sparring conversation ("What's it about? What do you want to build?"), then creates the project structure.

**B) Menu:**
```
@mydex
*new-project
```

Either way you end up with `myDex/projects/{name}/.dex/` containing the structured 12-folder skeleton (analysis / planning / solutioning / implementation / chronicle / etc.).

---

## Minute 5: See what's there + what's coming

```
@dex-master *features
```

Honest view of every capability — what's `enabled` and tested today, what's `deferred` to 1.1+, what's known-broken with workarounds.

Want to inspect a specific feature deeper? See `.dexCore/_cfg/features.yaml`.

```
@dex-master *list-workflows
```

Shows all 46 workflows organized by phase. Pick one and the related agent will guide you.

```
@dex-master *list-skills
```

Shows the 12 knowledge packs grouped by category (DexHub Core / Operations / DHL Design System).

---

## Where to go next

- **Build your first custom agent:** `@dex-builder` (DexBuilder — agent-creation workflow)
- **Multi-agent expert collaboration:** `*council-mode`
- **Process documents end-to-end:** drop files into `myDex/inbox/`, then `*inbox` (router + extract + ingest)
- **Set up Atlassian / GitHub / Figma connectors:** see `*packs` → `onboarding_pack`

For deeper documentation:
- [FAQ](FAQ.md) — frequently asked questions
- [Troubleshooting](TROUBLESHOOTING.md) — symptom → cause → fix
- [Enterprise Compliance Matrix](ENTERPRISE-COMPLIANCE.md) — per-feature compliance stance

---

**Want the full German version with extended examples?** See [`de/FIRST-5-MINUTES.md`](de/FIRST-5-MINUTES.md).
