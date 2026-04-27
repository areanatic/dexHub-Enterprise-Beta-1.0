# FAQ — Frequently Asked Questions

> **🌐 Language:** **EN** (this file) · [🇩🇪 DE](de/FAQ.md)

## What is DexHub, exactly?

An **AI development platform with 43 specialized agents** (technically 46 Copilot activations) that work together like a domain team. Every agent has a persona (Jana as Business Analyst, Mona as UX Designer, Kalpana as Test Automation Architect, etc.) and a clearly-scoped expertise.

You use DexHub **inside your IDE** (VS Code, Cursor, JetBrains). No separate program, no login, no cloud installation. Everything is local as Markdown files + workflows.

---

## What does "Data-Local" mean?

- **Your data stays local.** Profiles, decisions, chronicles, project files never leave your machine unless you explicitly configure a connector.
- **Your LLM is your choice.** Run against GitHub Copilot (cloud), Anthropic's CLI (cloud), or Ollama (fully local). DexHub compiles identical instructions for all three.
- **Connectors are optional.** Jira, GitHub, Figma integrations talk to their respective APIs only when configured — always with your explicit setup step, never auto-enabled.

This is why we say "Data-Local, LLM-of-Your-Choice" instead of "100% Local". The data side is local; the LLM side is yours to pick.

---

## Which LLM should I use?

- **GitHub Copilot Enterprise** — works out of the box if your team has it. Cloud, but enterprise-tenant.
- **Anthropic Claude (CLI)** — strong reasoning, cloud, premium.
- **Ollama** — fully local, privacy-first, requires your machine to have RAM (8 GB minimum for small models, 16+ GB for larger).

You can switch any time — DexHub doesn't care. The same agents and workflows work across all three.

---

## How much disk space?

- **Bare minimum** (cloud-LLM only): ~50 MB
- **Plus L2 semantic search** (embed model nomic-embed-text): +280 MB
- **Plus local LLM** (Ollama llama3.2): +2 GB
- **Plus VLM** (image understanding via moondream): +830 MB
- **Per-project workspace**: a few MB to ~100 MB depending on what you do

For typical use: **~3–4 GB** with full local AI. **~50 MB** if you only use cloud LLMs.

---

## Can I build my own agents?

Yes. Use `@dex-builder` (DexBuilder workflow) — it walks you through creating a custom agent in plain language, no coding required. Output is a Markdown file in your repo; you can fork, modify, share via Git.

---

## What's the difference between Agents and Skills?

- **Agents** are personas with menus and active behaviors (e.g., Jana the Analyst runs the PRD workflow). You activate them: `@analyst`, `@architect`, etc.
- **Skills** are knowledge packs — they get lazy-loaded when relevant. E.g., the `dexhub-chronicle` skill teaches agents how to structure session logs. You rarely see skills directly; they're infrastructure.

You can list both:
- `@dex-master *list-agents`
- `@dex-master *list-skills` — structured overview of the 12 skills

---

## What about the test suite?

DexHub ships with 32 E2E tests (26 core tests plus 6 integration tests) covering ~702 individual assertions. Run via:

```bash
bash tests/e2e/run-all.sh
```

Plus a structural quality gate (`bash .dexCore/_dev/tools/validate.sh` — 272 PASS / 0 FAIL / 0 WARN expected).

The features registry (`.dexCore/_cfg/features.yaml`) declares which test covers each feature. 7 enabled features have `tests:[]` — those are documented as test-coverage gaps with `known_issues` and planned for 1.0.1+.

---

## What's the Onboarding flow?

Single canonical onboarding (5 questions, ~ein Augenblick):

1. Name
2. Language (DE / EN / Bilingual)
3. Experience level
4. Team size
5. Data-handling policy (Q43 — the P0 enterprise gate)

Activate via `@mydex` or `@dex-master` then `*mydex`. Result: `myDex/.dex/config/profile.yaml`.

> **Want to extend?** Per `*profile` editing you reach optional fields (Enterprise Compliance Q44–Q49, Custom Instructions Q40–Q41) — these aren't part of onboarding but available post-onboarding.

---

## Can DexHub run offline?

Yes — if you use Ollama for the LLM. The DexHub framework itself (agents, workflows, skills, validate.sh) is pure Markdown + Bash + Ruby — no network calls.

Cloud LLMs (Copilot, Claude API) obviously require internet. Connectors (Atlassian, GitHub, Figma) require internet.

Local LLM + no connectors = fully offline.

---

## Is this open source?

Apache 2.0 license. Source code is at https://github.com/areanatic/dexHub-Enterprise-Beta-1.0.

The vision is "Internal Open-Source / Enterprise Community" — collaborative development, not vendor product. Contributions welcome via standard fork/PR flow.

---

## What's NOT in DexHub Beta 1.0?

Honest limits — see also `.dexCore/_dev/docs/ROADMAP-1.1.md` for the planned-deferred backlog:

- **Native Workflow-Runner backend** — the 46 workflows are guided templates today, not autonomous runners. The runner is on the 1.1 roadmap.
- **Parser Pattern B Phases 2–6** — Pattern A (vector text) + Pattern B Phase 1 (overview) ship today; Phases 2–6 (cluster detect, hi-res crops, per-cluster VLM, synthesis, verify) are deferred.
- **Watcher daemon mode** (systemd / launchd) — foreground watcher works today; daemon-mode planned for 1.1.
- **Mandatory onboarding gate** — the 5-question onboarding exists today, but is not enforced (you can use DexHub without onboarding). Mandatory gate planned for 1.0.1+.

---

## Bilingual support?

Most agents are bilingual (DE/EN) — they switch based on your profile language. Documentation: this is the EN version; full German versions live in [`de/`](de/) for each Non-Dev doc.

---

## Where do bug reports go?

Use Dev-Mode: `@dex-master *dev-mode` → `*bug` (or `*feature` / `*tech-debt`) — captures structured reports, optionally syncs to GitHub Issues.

The Dev-Mode is itself one of the USPs: report bugs / track issues without vendor lock-in. Everything stays in markdown + git.

---

**Want the full German version with extended examples?** See [`de/FAQ.md`](de/FAQ.md).
