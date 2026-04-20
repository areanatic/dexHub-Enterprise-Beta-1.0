# Inbox

Staging area for files you want DexHub to parse + ingest.

## Current state (Beta 1.0)

Auto-parsing (drop-a-file → auto-route → auto-ingest) is **not yet wired** — ships in Phase 5.3.f (`parser.inbox_auto_parse`).

Today the inbox is a convenience directory. The tooling runs when you run it.

## Manual workflow today

```bash
# 1. Decide which backend handles your file
bash .dexCore/core/parser/parse-route.sh myDex/inbox/your-file.pdf

# 2a. If route says backend=kreuzberg (PDF, DOCX, etc.)
bash .dexCore/core/parser/backends/kreuzberg.sh --extract myDex/inbox/your-file.pdf

# 2b. If route says backend=ollama_vlm (PNG, JPG, screenshots)
bash .dexCore/core/parser/backends/ollama-vlm.sh --extract myDex/inbox/your-image.png

# 2c. If route says backend=native (TXT, MD, code) — just read it
cat myDex/inbox/your-file.md

# 3. Pipe extracted text into the L2 Knowledge Tank
bash .dexCore/core/knowledge/l2/l2-ingest.sh --source <extracted.md>
```

## Auto-detection

Run this once per machine (or after installing a new parser backend):

```bash
bash .dexCore/core/parser/capabilities-probe.sh
```

It detects which backends are installed (Ollama, Kreuzberg) and writes `myDex/.dex/config/capabilities.yaml`. The parser router reads that file and decides per-extension which backend to use.

**First-run behavior:** if `capabilities.yaml` doesn't exist yet, `parse-route.sh` auto-invokes the probe transparently. You can always re-run it to refresh.

## Coming in 5.3.f (parser.inbox_auto_parse)

- A `*inbox` DexMaster command that lists pending files + routes each
- A watcher that auto-triggers on new file drops
- Auto-archive of originals after successful ingest
- Optional: configurable inbox location (e.g. on your Desktop) + desktop shortcut

Until then, this directory + the manual steps above are the contract.

## Supported inputs (today)

| Type                     | Backend           | Install                                                                     |
|--------------------------|-------------------|-----------------------------------------------------------------------------|
| `.txt` `.md` `.json`     | native (no tool)  | nothing                                                                     |
| `.pdf` `.docx` `.xlsx`   | kreuzberg         | `brew install kreuzberg-dev/tap/kreuzberg` or `cargo install kreuzberg-cli` |
| `.png` `.jpg` `.webp`    | ollama_vlm        | Install Ollama + `ollama pull llama3.2-vision`                              |
| Large `.pdf` (≥ 100 MB)  | *deferred* (1.1)  | —                                                                           |

See `.dexCore/_cfg/features.yaml` for the feature registry.
