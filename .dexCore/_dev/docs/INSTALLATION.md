# Installation — DexHub Enterprise Beta 1.0

> **🌐 Language:** **EN** (this file) · [🇩🇪 DE](de/INSTALLATION.md)

**Audience:** Anyone who wants to get DexHub running on their own machine. No programming experience required for basic install; for advanced features (local LLM, document parser) we walk you through step-by-step.

> **Reading time:** 5 min basic setup · 15–20 min with all optional components

---

## Overview: what you actually need

| Component | Required? | What for |
|---|---|---|
| **IDE with AI integration** | yes | Where you "talk to" DexHub |
| **Git** | yes | DexHub lives in a git repository |
| **Cloud LLM** (Copilot Enterprise / Anthropic API) | one of cloud or local | Which AI model executes the prompts |
| **Local LLM** (Ollama) | one of cloud or local | Privacy-first alternative |
| **Document Parser** | optional | If you want `*inbox` (drag PDF/Office/image into DexHub) |
| **Disk space** | ~200 MB | Repo + indexed knowledge base |

Pick: **at least one IDE**, **at least one LLM** (cloud or local). Everything else is opt-in.

---

## Step 1: Install IDE

DexHub is IDE-agnostic. Pick what you already use, or install one of these:

- **VS Code** (most common, free): https://code.visualstudio.com
- **Cursor** (VS Code fork with built-in AI): https://cursor.sh
- **JetBrains** (IntelliJ / PyCharm / WebStorm): https://www.jetbrains.com
- **Windsurf** (Codeium's IDE): https://codeium.com/windsurf

For VS Code: also install the **GitHub Copilot extension** (or **Claude Code extension** if you have Anthropic CLI access).

---

## Step 2: Install Git

If you don't have git yet:
- **macOS:** `brew install git` or comes with Xcode Command Line Tools
- **Windows:** https://git-scm.com/download/win
- **Linux:** `sudo apt install git` / `sudo dnf install git`

Verify: `git --version` → should print `git version 2.x`

---

## Step 3: Clone DexHub

```bash
git clone https://github.com/areanatic/dexHub-Enterprise-Beta-1.0.git
cd dexHub-Enterprise-Beta-1.0
```

You now have ~300 MB of DexHub on disk. Open the folder in your IDE (VS Code: `code .`).

---

## Step 4: First contact with DexMaster

In your IDE's chat panel:

```
@dex-master hi
```

DexMaster should respond with a greeting + numbered menu.

If nothing happens: see [Troubleshooting](TROUBLESHOOTING.md) → "@dex-master no response".

---

## Step 5: LLM choice — cloud or local

### Option 5a: GitHub Copilot (cloud, default)

If your IDE already has GitHub Copilot logged in: **you're done with LLM setup**. DexHub uses Copilot to execute prompts.

### Option 5b: Anthropic Claude (cloud, alternative)

Install Claude Code CLI: https://claude.com/claude-code
Login: `claude auth login`
DexHub will pick this up automatically.

### Option 5c: Ollama (local, privacy-first)

Install Ollama: https://ollama.com
Pull a model:

```bash
ollama pull llama3.2
ollama pull moondream  # for image parsing
ollama pull nomic-embed-text  # for L2 semantic search
```

DexHub auto-detects Ollama on default port 11434. Verify with `*parser-setup` in DexMaster.

---

## Step 6: Optional — Document Parser

If you want to drag PDFs / Office files / images into DexHub via `*inbox`:

```bash
# macOS
brew install poppler              # gets pdftotext (PDF text extraction)
brew install kreuzberg-dev/tap/kreuzberg  # multi-format parser

# Linux
sudo apt install poppler-utils  # gets pdftotext
# kreuzberg via install script — see https://kreuzberg.dev
curl -fsSL https://raw.githubusercontent.com/kreuzberg-dev/kreuzberg/main/scripts/install.sh | bash
```

Verify: `*parser-setup` in DexMaster shows installed backends.

---

## Step 7: Verify everything works

```bash
bash .dexCore/_dev/tools/validate.sh
# Expected: 272 PASS / 0 FAIL / 0 WARN
```

If green: you're set up. Continue with [First 5 Minutes](FIRST-5-MINUTES.md).

If red: see [Troubleshooting](TROUBLESHOOTING.md).

---

## Disk space breakdown

- **DexHub repo itself:** ~50 MB (markdown files, agents, workflows)
- **Optional Ollama model (llama3.2):** ~2 GB
- **Optional embed model (nomic-embed-text):** ~280 MB
- **Optional VLM model (moondream):** ~830 MB
- **L2 semantic index** (built on demand): ~50–500 MB depending on repo size

For minimal setup with cloud-LLM only: **~50 MB**. For full local-AI setup: **~3–4 GB**.

---

## Next steps

- [First 5 Minutes with DexHub](FIRST-5-MINUTES.md) — guided first walkthrough
- [FAQ](FAQ.md) — frequent questions
- [Troubleshooting](TROUBLESHOOTING.md) — symptom → cause → fix

---

**Need a deeper walkthrough in German?** See [`de/INSTALLATION.md`](de/INSTALLATION.md) for the original German version with extended explanations.
