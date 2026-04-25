# Die ersten 5 Minuten mit DexHub

> **🌐 Sprache:** [🇬🇧 EN](../FIRST-5-MINUTES.md) · **DE** (diese Datei)

**Voraussetzung:** Du hast die [Installation](INSTALLATION.md) durchgezogen (IDE + Git + Clone + `@dex-master hi` antwortet).

Jetzt lernst du DexHub in 5 Minuten real kennen — am echten Beispiel.

---

## Minute 1: Dein Profil anlegen (SMART Onboarding)

In deinem IDE-Chat:
```
@mydex hi
```

Du wirst durch **SMART v5** geführt — **5 kurze Fragen** (ein Augenblick):

1. **Wie möchtest du angesprochen werden?** (dein Name)
2. **Bevorzugte Sprache?** (Deutsch / English / Bilingual)
3. **Wie viele Jahre Erfahrung?** (beeinflusst die Agent-Kommunikation)
4. **Teamgröße + Kontext?** (Solo / Start-up / Enterprise — beeinflusst Empfehlungen)
5. **Data-Handling-Policy?** (Enterprise-Gate: welche LLMs / Connectors darfst du nutzen?)

Deine Antworten landen in `myDex/.dex/config/profile.yaml`. Nur lokal auf deinem Rechner. Kannst du später jederzeit ändern: `@mydex` → Menüpunkt `*mydex-profile`.

> **Profil erweitern?** Per `*profile` editing erreichst du zusätzliche Felder (Enterprise-Compliance Q44-Q49, Custom-Instructions Q40-Q41) — die sind nicht Teil des Onboardings, sondern als optionale Felder verfügbar.

---

## Minute 2: Den Hub kennenlernen

```
@dex-master hi
```

Du siehst das **DexMaster-Menü**. DexMaster ist nicht selber ein Agent-Arbeiter — er ist der **Wegweiser**. Er zeigt dir:

- Welche **Agenten** verfügbar sind (`*list-agents`)
- Welche **Workflows** es gibt (`*list-workflows`)
- Welche **Feature-Flags** aktiv sind (`*features`)
- Welche **Agent-Packs** togglebar sind (`*packs`)

> **Skills** (12 Wissenspakete in `.github/skills/`) werden automatisch von Copilot/Claude geladen wenn sie zum Kontext passen. Strukturierte Übersicht via `@dex-master *list-skills`.

Probier's: `@dex-master *list-agents`. Du siehst eine strukturierte Liste mit menschlichen Namen (Mona, Jana, Kalpana, Yamuna etc.) + technischen Commands (`@ux`, `@analyst`, `@testarch-pro`, `@atlas`).

---

## Minute 3: Einen Agenten direkt sprechen

Agenten sind wie Fach-Kolleginnen und -Kollegen mit Persona + Expertise. Beispiel:

```
@analyst hi
```

Du triffst **Jana**, die Business Analyst. Sie stellt sich vor, fragt dich was du brauchst. Ihre Antworten sind **strukturiert** (Liste, Tabelle), **spezialisiert** (BA-Vokabular, Framework-Denken), und **aktionsorientiert** (sie schlägt Workflows vor).

Weitere Personas zum Ausprobieren:

| Command | Name | Rolle |
|---|---|---|
| `@pm` | Martin | Product Manager |
| `@ux` | Mona | UX Designer |
| `@architect` | Alex | Software Architect |
| `@dev` | Steffi | Developer |
| `@sm` | Arjun | Scrum Master |
| `@testarch-pro` | Kalpana | Test Automation Architect |
| `@atlas` | Yamuna | Knowledge Reconstruction Expert |

**Tipp:** Jeder Agent bleibt in seiner Rolle bis du `*exit` sagst oder einen anderen Agent lädst. DexMaster führt dich zurück mit `@dex-master hi`.

---

## Minute 4: Einen Workflow laufen lassen

Workflows sind **geführte Abläufe** (PRD schreiben, Architektur-Analyse, Code-Review-Session etc.). Beispiel:

```
@analyst *product-brief
```

Jana führt dich durch den **Product Brief Workflow**: Fragen zum Zielmarkt, Problem-Statement, User-Persona, Success Metrics. Am Ende hast du ein strukturiertes Markdown-Dokument, das in `myDex/drafts/` oder (wenn du ein Projekt angelegt hast) direkt in `myDex/projects/{dein-projekt}/.dex/1-analysis/` landet.

DexHub hat **46 Workflows** über 5 Phasen:
- **1-Analysis:** Product-Brief, Brainstorm, Research, Market-Analysis, …
- **2-Planning:** PRD, Epic-Breakdown, Tech-Spec, Sprint-Planning, …
- **3-Solutioning:** Architecture, UX-Design, Solutioning-Gate, …
- **4-Testing:** Test-Strategy, Framework-Generation, Quality-Gates, …
- **5-Implementation:** Create-Story, Dev-Story, Code-Review, …

Siehe `@dex-master *list-workflows`.

---

## Minute 5: Ein Projekt anlegen

Bisher lagen deine Outputs in `myDex/drafts/` (oder `docs/` je nach Workflow — siehe `dxm/config.yaml`). Sobald du ernst wirst:

```
@mydex
*projects
```

Im Projekt-Management-Menü wählst du **1. Neues Projekt erstellen**. Du bekommst ein **strukturiertes Projekt-Workspace**:
```
myDex/projects/dein-projekt/
├── src/               ← dein Code
└── .dex/              ← alle Projekt-Metadaten
    ├── inputs/
    ├── 1-analysis/
    ├── 2-planning/
    ├── 3-solutioning/
    ├── 4-implementation/
    ├── chronicle/     ← tägliche Session-Logs
    ├── decisions/     ← ADRs
    └── INDEX.md
```

Von jetzt ab routen alle Workflow-Outputs automatisch in diesen Projekt-Ordner. Jeder Agent, den du mit `@...` aufrufst, nutzt den Kontext des aktiven Projekts.

Im selben `@mydex` → `*projects` Menü:
- **2. Projekt wechseln** (zwischen mehreren Projekten)
- **3. Projekt-Info anzeigen** (aktueller Status)
- **4. Projekt nachrüsten** (existierenden Code-Ordner um `.dex/` erweitern)
- **5. Migrations-Hilfe** (alte Projekt-Strukturen aktualisieren)

---

## Was als nächstes?

- **Dokumenten-Parser aktivieren:** Du hast Kreuzberg + Ollama installiert? `@dex-master *inbox` zieht PDFs, Word-Dokumente, Screenshots etc. in dein Wissen-Tank.
- **Jira / Confluence verbinden:** `@atlassian-onboarding hi` (braucht deine Firma-URL + Token)
- **Skills entdecken:** Die 12 Wissenspakete liegen in `.github/skills/`. Sie werden auto-geladen von Copilot/Claude wenn passend (Guardrails, Chronicle, DHL DS, etc.). Strukturierte Übersicht via `@dex-master *list-skills`.
- **Agent-Packs togglen:** `@dex-master *packs` → aktiviere/deaktiviere Agent-Pakete je nach Arbeitsmodus (z.B. Meta-Agents nur bei Brownfield-Arbeit)

---

## Stolperfallen in den ersten 5 Minuten

| Problem | Fix |
|---|---|
| `@dex-master hi` zeigt kein Menü | Du bist in Code-Modus — sag einfach "hi" oder "hallo" nochmal |
| Agent antwortet in falscher Sprache | `@mydex *mydex-profile` → Sprache anpassen, neu laden |
| Workflow läuft nicht | Prüfe: bist du in einem Projekt? `@mydex status` |
| `myDex/projects/` ist leer | Normal bei Erstinstallation — leg ein Projekt an (siehe Minute 5) |

Mehr in [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

---

## Merke dir diese 3 Commands

```
@dex-master hi           ← Wegweiser, Menü, zurück-zur-Basis
@mydex                   ← Profil verwalten, Projekte verwalten (Menü)
*list-agents             ← alle verfügbaren Fach-Kollegen
```

Alles andere ergibt sich. Viel Spaß mit deinem KI-Team.
