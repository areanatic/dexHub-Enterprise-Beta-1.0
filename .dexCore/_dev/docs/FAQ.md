# FAQ — Häufig gestellte Fragen

## Was ist DexHub eigentlich?

Eine **KI-Entwicklungsplattform mit 43 spezialisierten Agenten** (technisch: 46 Copilot-Activations), die wie ein Fach-Team zusammenarbeiten. Jeder Agent hat eine Persona (Jana als Business Analyst, Mona als UX-Designerin, Kalpana als Test-Automation-Architektin etc.) und eine klar umrissene Expertise.

Du nutzt DexHub **in deiner IDE** (VS Code, Cursor, JetBrains). Kein separates Programm, kein Login, keine Cloud-Installation. Alles ist lokal als Markdown-Dateien + Workflows.

---

## Was heißt "Data-Local"?

**Deine Arbeitsdaten** (Code, Profile, Entscheidungen, Chroniken) bleiben auf deinem Rechner. Was Cloud sein **darf** (weil Enterprise-approved):

- **GitHub Copilot Enterprise** (unsere Baseline-LLM-Engine — die Anfrage geht zu GitHub / Azure, aber im Enterprise-Vertrag deiner Firma)
- **Atlassian Jira / Confluence Cloud** (wenn du verbindest — nur API-Calls zu deinem Workspace)
- **Figma / GitHub Enterprise** (analog — wenn du verbindest)

Was Cloud **nicht ist**:
- Die Agent-Dateien selbst (liegen in deinem Git-Repo)
- Deine Profile + Entscheidungen + Projekte (liegen in `myDex/`)
- Keine Telemetrie, kein Analytics, kein "Phone home"

> Wenn du auch die LLM-Engine lokal willst: Ollama mit einem Modell deiner Wahl (siehe unten).

---

## Welches LLM brauche ich? Cloud vs. lokal?

| Option | Wann sinnvoll? | Kosten | Aufwand |
|---|---|---|---|
| **GitHub Copilot Enterprise** ⭐ | Deine Firma hat Enterprise-Lizenz. Der DexHub-Baseline-Path. | Enterprise-Abo | IDE installieren, anmelden |
| **Claude Code / Anthropic API** | Du willst Claude-Modelle direkt (z.B. Claude Opus für komplexere Aufgaben) | Per-Token Abrechnung | API-Key holen |
| **Cursor / Windsurf** | Du nutzt diese IDEs bereits | Abo | Kompatibel, aber nicht die Baseline |
| **Ollama lokal** | Kein Internet / strikte Offline-Requirements / Kostenkontrolle | Einmalig Hardware | Mehr Setup (siehe INSTALLATION.md) |

DexHub ist so gebaut, dass die Agenten **auf jeder ausreichend leistungsfähigen LLM** funktionieren — sie sind "plain markdown" mit klarer Persona. Es gibt keinen Vendor-Lock-In.

---

## Wie viel Plattenplatz brauche ich?

Baseline-DexHub (ohne lokale KI): **~200 MB** (der Repo + Git-History).

Mit optionaler lokaler KI:

| Setup | Was drin | Platz |
|---|---|---|
| Basis | nur DexHub + Kreuzberg für PDFs | **~300 MB** |
| Einsteiger-KI | + Ollama mit `moondream` (kleines Vision-Modell) + `nomic-embed-text` | **~2.5 GB** |
| Sweet-Spot | + Ollama mit `llava:7b` | **~5.5 GB** |
| Power-User | + Ollama mit `llama3.2-vision` | **~8.5 GB** |
| Max | alle Vision-Modelle | **~15 GB** |

Platzsparer-Tipp: Du kannst **ein** Vision-Modell installieren und andere später nachladen (`ollama pull X`) oder entfernen (`ollama rm X`).

---

## Welches Ollama-Vision-Modell soll ich nehmen?

Kurze Empfehlung:

| Dein Mac / PC | Modell | Warum? |
|---|---|---|
| 8 GB RAM, kein GPU | `moondream` (1.7 GB, 1.8B Parameter) | Schnell genug auf CPU. Für Screenshots + einfache PDFs ausreichend. |
| 16 GB RAM | `llava:7b` (4.7 GB, 7B Parameter) | Ollama-Default. Solider Allrounder. Diagramme, UI, OCR leicht. |
| 16+ GB RAM oder dedicated GPU | `llama3.2-vision` (7.8 GB, 11B Parameter) | Beste Qualität für Text-in-Bild (OCR-nah). Langsamer auf CPU. |

Installieren: `ollama pull <name>`. Probieren: `@dex-master *inbox` mit einem Test-Bild.

---

## Muss meine Firma GitHub Copilot Enterprise haben?

Für die **DexHub-Baseline** ja — das ist der offiziell getestete Pfad. Aber:

- Wenn deine Firma **Claude Enterprise / Azure OpenAI** nutzt, funktioniert das auch (DexHub-Agenten sind LLM-agnostisch)
- Wenn du **solo** arbeitest, kannst du mit einem persönlichen Copilot-Abo oder Claude-API starten
- Wenn du **komplett offline** musst: Ollama-Setup mit genug Hardware (32+ GB RAM ideal)

Die Agent-Personas + Workflows funktionieren grundsätzlich mit jedem ausreichend starken LLM. Die Qualität variiert je nach Modell.

---

## Was ist der Unterschied zwischen Agenten und Skills?

- **Agenten** sind Personas mit klarer Rolle — du sprichst mit Jana der Business Analyst (`@analyst`), sie antwortet als Jana, schlägt Workflows vor, bleibt in ihrer Rolle bis du sie verlässt.

- **Skills** sind **Wissenspakete** — sie werden lazy-geladen wenn sie gebraucht werden. Z.B. das `dexhub-chronicle` Skill erklärt Agenten wie Session-Logs strukturiert werden. Du siehst Skills selten direkt; sie sind Infrastruktur.

Sehen kannst du beide via:
- `@dex-master *list-agents`
- `@dex-master *list-skills` (coming 1.1)

---

## Kann ich meine eigenen Agenten bauen?

Ja. DexHub kommt mit dem `@dex-builder` Agenten, der dich durch das Erstellen eines neuen Agenten führt. Das Format ist einfach: Markdown mit XML-Tags für Persona, Activation, Guardrails, Commands.

Siehe: `@dex-builder create-agent`. Dein neuer Agent landet in `.dexCore/custom-agents/`.

---

## Meine Firma hat strenge Data-Handling-Regeln. Funktioniert das?

Ja — genau dafür gibt's die **Enterprise-Compliance-Matrix**:

- Jedes Feature hat einen `enterprise_compliance`-Status (`ok` / `cloud_with_consent` / `local_vlm_required` / `research_pending`)
- Siehe [ENTERPRISE-COMPLIANCE.md](ENTERPRISE-COMPLIANCE.md) für die komplette Übersicht
- Die SMART-v5-Onboarding-Frage Q5 (Data-Handling-Policy) **filtert** welche Features dir angeboten werden. Wählst du "No cloud LLMs allowed" → DexHub schlägt nur lokale Ollama-Pfade vor.

---

## Ich bin Non-Dev. Kann ich DexHub trotzdem nutzen?

Ja — die Basis-Installation ist auch für Non-Devs machbar (siehe [INSTALLATION.md](INSTALLATION.md)). Was du gewinnst:

- **Geführte Workflows:** Du musst nicht wissen, wie man einen PRD schreibt — Jana fragt dich Schritt für Schritt durch.
- **Bilinguale Agenten:** Deutsch + Englisch out of the box.
- **Keine Coding-Pflicht:** Für reine Analyse / Planung / Documentation brauchst du keinen Code-Editor-Kenntnisse.

Für reine Entwicklungs-Workflows (Dev-Story, Code-Review) wirst du mehr IDE-Vertrautheit brauchen.

---

## Ich habe Agent X gerufen und er antwortet nicht in meiner Sprache

Schnellfix: `@mydex *mydex-profile` → Sprache setzen → `@dex-master hi` neu starten.

Wenn das nicht reicht, kannst du dem Agent explizit sagen: "Bitte auf Deutsch" oder "Please in English". Alle Agenten haben `{communication_language}` als Session-Variable.

---

## Kann ich DexHub in mehreren Projekten gleichzeitig nutzen?

Ja. Jedes Projekt bekommt sein eigenes `myDex/projects/<name>/.dex/`-Verzeichnis mit eigener Chronik, eigenen Entscheidungen, eigenen Analysen. Du wechselst via `@mydex switch-project`.

---

## Wird meine Arbeit irgendwo gespiegelt oder gesichert?

DexHub selber macht **kein automatisches Backup oder Sync**. Deine Arbeit liegt in `myDex/` — du bist verantwortlich für:
- Git-Commits (versionierte Snapshots)
- Optional: Git-Push zu einem Remote-Repo (GitHub, GitLab, etc.)
- Optional: Dein eigenes Backup-Setup

`myDex/projects/` ist per `.gitignore` ausgeschlossen — das ist **Absicht** (private Arbeit bleibt privat). Wenn du teilen willst: eigener Branch oder separates Repo.

---

## Was ist wenn ich bei einer Frage / Entscheidung feststecke?

1. **Forensik:** `@dex-master *features` zeigt dir welche Features in welchem Status sind
2. **Wissen:** 12 Skills liegen in `.github/skills/` — auto-geladen von Copilot/Claude bei passendem Kontext (explizites `*list-skills` Menü kommt 1.1)
3. **Dokus:** [INSTALLATION.md](INSTALLATION.md), [FIRST-5-MINUTES.md](FIRST-5-MINUTES.md), [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
4. **Community / Issue:** Auf GitHub im Repo ein Issue aufmachen (für ITS / DHL-interne Nutzer: nimm Kontakt zu Arash Zamani auf)

---

## Zählungen check — wie viele Agenten / Workflows / Skills gibt's wirklich?

Stand **Beta 1.0** (verifiziert gegen Dateisystem):

| Komponente | Anzahl |
|---|---|
| Source-Agent-Personas | 43 (siehe `.dexCore/_cfg/agent-manifest.csv`) |
| Copilot-Activations (.agent.md) | 46 (manche Agenten haben mehrere Entry-Points) |
| Workflows | 46 (über alle Module verteilt) |
| Skills | 12 (in `.github/skills/`) |

Diese Zahlen sind geprüft per `validate.sh` (§25 README ↔ Counts).
