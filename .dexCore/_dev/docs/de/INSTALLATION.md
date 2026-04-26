# Installation — DexHub Enterprise Beta 1.0

> **🌐 Sprache:** [🇬🇧 EN](../INSTALLATION.md) · **DE** (diese Datei)

**Zielgruppe:** Jede/r, der/die DexHub auf dem eigenen Rechner zum Laufen bringen will. Keine Programmiererfahrung nötig für die Basis-Installation; für erweiterte Features (lokale KI, Parser) helfen wir dir Schritt-für-Schritt.

> **Lesezeit:** 5 min Basis-Setup · 15–20 min mit allen optionalen Komponenten

---

## Überblick: was du wirklich brauchst

DexHub ist **kein Programm**, das du wie eine App installierst. Es ist ein **Ordner mit AI-Agenten + Workflows + Wissen**, den du in deiner Entwicklungsumgebung (IDE) nutzt.

| Komponente | Pflicht? | Zweck | Platz |
|---|---|---|---|
| **IDE mit KI-Support** | ✅ Pflicht | Agenten aufrufen + Workflows ausführen | — |
| **Git** | ✅ Pflicht | Repo klonen + Versionierung | ~100 MB |
| **Bash Terminal** | ✅ Pflicht | `validate.sh` laufen lassen | — |
| Kreuzberg (Parser) | Optional | PDF/Office/Bilder in DexHub ziehen | ~100 MB |
| Ollama + VLM | Optional | Lokale KI für Bild-Parsing | ~2 GB (klein) bis ~8 GB (groß) |
| nomic-embed-text | Optional | Semantische Suche im Wissens-Tank | ~274 MB |

**Plattenplatz gesamt:**
- **Nur Basis:** ~200 MB
- **Basis + lokale KI (Einsteiger):** ~2.5 GB
- **Vollständig mit stärkerem KI-Modell:** ~8.5 GB

---

## Schritt 1: IDE mit KI-Support

Wähle eine IDE mit KI-Integration. DexHub ist primär für **GitHub Copilot Enterprise** gebaut (das ist die Baseline), funktioniert aber auch mit anderen LLM-Clients.

### Empfehlungen

| IDE | KI-Integration | Für wen? |
|---|---|---|
| **VS Code + GitHub Copilot Enterprise** ⭐ | native (Enterprise-Lizenz erforderlich) | Die DexHub-Baseline. Volle Agenten-Unterstützung, offizielle Tests. |
| VS Code + Claude Code | via Anthropic API | Wenn du Claude direkt nutzen willst |
| Cursor | eigene KI-Engine | Wenn du Cursor bereits nutzt |
| Windsurf | eigene KI-Engine | Ähnlich wie Cursor |
| JetBrains + Copilot | Plugin | Für JetBrains-Nutzer |

**GitHub Copilot Enterprise Setup:**
1. Deine Firma muss eine Copilot Enterprise-Lizenz haben
2. Admin muss dein GitHub-Konto zur Org hinzufügen
3. In VS Code: Extension "GitHub Copilot" + "GitHub Copilot Chat" installieren
4. Anmelden mit dem Org-GitHub-Account

Fragen? Siehe [Troubleshooting](TROUBLESHOOTING.md) → "Copilot Auth fails".

---

## Schritt 2: Git installieren

**macOS:**
```bash
# Entweder über Homebrew:
brew install git

# Oder: Xcode Command Line Tools (enthält Git):
xcode-select --install
```

**Linux (Debian/Ubuntu):**
```bash
sudo apt install git
```

**Windows:**
1. [git-scm.com/download/win](https://git-scm.com/download/win) herunterladen
2. Installer ausführen, Defaults akzeptieren
3. **Git Bash** wird mitinstalliert — das nutzen wir als Terminal

Verify: `git --version` sollte `git version 2.x.x` oder höher zeigen.

---

## Schritt 3: DexHub klonen

```bash
git clone https://github.com/areanatic/dexHub-Enterprise-Beta-1.0.git
cd dexHub-Enterprise-Beta-1.0
```

Öffne den Ordner in deiner IDE:
- VS Code: `code .` (oder Datei → Ordner öffnen)
- JetBrains: über Open Project

---

## Schritt 4: Erster Test

Im IDE-Chat (Copilot/Claude Code/Cursor) eintippen:
```
@dex-master hi
```

Du solltest eine Begrüßung und ein Menü bekommen. **Funktioniert?** → weiter zu [FIRST-5-MINUTES.md](FIRST-5-MINUTES.md).

**Funktioniert nicht?** → [TROUBLESHOOTING.md](TROUBLESHOOTING.md) → "Agent antwortet nicht".

---

## Schritt 5 (optional): Parser für Dokumente

Willst du PDFs, Word-Dokumente, Screenshots, etc. in DexHubs Wissens-Tank ziehen? Dann brauchst du **Kreuzberg** (Parser) und optional **Ollama** (lokale KI für Bilder).

### 5a. Kreuzberg (PDF/Office-Parser)

**macOS (empfohlen — einfachster Weg):**
```bash
brew install kreuzberg-dev/tap/kreuzberg
```

**Linux:**
```bash
curl -fsSL https://raw.githubusercontent.com/kreuzberg-dev/kreuzberg/main/scripts/install.sh | bash
```

**Windows:** [Binary von Kreuzberg Releases](https://github.com/kreuzberg-dev/kreuzberg/releases) herunterladen und in eine Shell-PATH-Location ablegen, ODER Docker Desktop verwenden.

Verify:
```bash
kreuzberg --version
```

### 5b. Ollama + Vision-Modell (optional — für Bild-Parsing)

**Ollama herunterladen:** [ollama.com/download](https://ollama.com/download) — es gibt einen Installer für macOS / Windows / Linux.

Nach der Installation ein **Vision-Modell** pullen. Empfehlung je nach Hardware:

| Hardware | Modell | Platz | Geschwindigkeit |
|---|---|---|---|
| 8 GB RAM, CPU | `moondream` | 1.7 GB | schnell (Einsteiger) |
| 16 GB RAM | `llava:7b` | 4.7 GB | mittel (Sweet Spot) |
| 16+ GB RAM oder GPU | `llama3.2-vision` | 7.8 GB | langsamer (beste Qualität, OCR) |

```bash
# Einsteiger-Empfehlung:
ollama pull moondream

# Sweet-Spot:
ollama pull llava:7b

# Power-User:
ollama pull llama3.2-vision
```

### 5c. nomic-embed-text (optional — semantische Suche)

Für das **L2-Wissen-Tank-Feature** (semantische Suche statt nur Stichwort):
```bash
ollama pull nomic-embed-text
```
(~274 MB, läuft mit 1–2 GB RAM)

### Probe: was erkennt DexHub?
```bash
bash .dexCore/core/parser/capabilities-probe.sh
```
Der Befehl scannt deinen Rechner und zeigt dir welche Parser + Modelle verfügbar sind.

---

## Schritt 6 (optional): Enterprise-Setup

Wenn du DexHub in einer Firma nutzt, kannst du deinen Workspace mit **Jira / Confluence / GitHub Enterprise / Figma** verbinden:

1. Im IDE-Chat: `@dex-master hi`, dann Menüeintrag **Integrations**
2. Oder direkt: `@atlassian-onboarding hi` (für Jira + Confluence), `@github-onboarding hi`, `@figma-onboarding hi`
3. Der Wizard fragt dich nach URL + Credentials und richtet MCP-Verbindungen ein
4. **VPN / Proxy nötig?** Die Wizards erkennen Cloud vs. Self-Hosted automatisch; bei Self-Hosted müssen VPN / Proxy vorher aktiv sein

Siehe auch: [ENTERPRISE-COMPLIANCE.md](ENTERPRISE-COMPLIANCE.md) für die Datenfluss-Matrix pro Connector.

---

## Validierung — ist alles intakt?

```bash
bash .dexCore/_dev/tools/validate.sh
```

Erwartung: `272 PASS / 0 FAIL / 0 WARN`. Wenn FAIL: [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

---

## Nächste Schritte

- **Erste 5 Minuten:** [FIRST-5-MINUTES.md](FIRST-5-MINUTES.md)
- **Häufige Fragen:** [FAQ.md](FAQ.md)
- **Etwas klappt nicht:** [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- **Welche Agenten gibt es:** [README.md → Agents](../../../README.md#meet-your-ai-team)

---

## Häufigste Stolperfallen (Quick-Reference)

| Symptom | Ursache | Fix |
|---|---|---|
| `@dex-master hi` → keine Antwort | Copilot nicht authenticated | IDE neu starten, GitHub-Account re-authenticate |
| `kreuzberg: command not found` | PATH nicht gesetzt | `brew doctor` (macOS) / Shell neu starten |
| `ollama pull` hängt | Port 11434 belegt | Ollama-App im Tray schließen, `ollama serve` neu |
| `validate.sh` rot | .dexcore-session-anchor fehlt | Du bist in stripped Enterprise-Bundle — das ist ok |

Ausführliche Ursachen-Forschung: [TROUBLESHOOTING.md](TROUBLESHOOTING.md).
