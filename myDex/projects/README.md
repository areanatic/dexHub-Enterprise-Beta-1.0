# myDex Projects

**Dein Projekt-Workspace** — hier leben alle deine Projekte, an denen DexHub-Agenten mit dir arbeiten.

## Ein neues Projekt anlegen

Am einfachsten über DexMaster:

```
*mydex create-project
```

Oder manuell als Unterordner:

```
myDex/projects/dein-projekt-name/
├── src/          ← dein Code
└── .dex/         ← alle Projekt-Metadaten (Analyse, Planung, Chronik)
    ├── 1-analysis/
    ├── 2-planning/
    ├── 3-solutioning/
    ├── 4-implementation/
    ├── chronicle/      ← tägliche Session-Logs (pro Projekt)
    ├── decisions/      ← ADRs für dieses Projekt
    └── INDEX.md
```

## Ein bestehendes Projekt importieren (ab v1.1)

Drop-In-Detection, Pull-Repo und Push-Repo-Agents sind für Release 1.1 geplant. Bis dahin:

```bash
# Fremdes Projekt hierher kopieren
cp -R /pfad/zu/fremdem-projekt myDex/projects/

# Danach: DexMaster erkennt es automatisch beim nächsten `hi` und schlägt
# Migration zur v1.1-Struktur vor.
```

## Was gehört NICHT hierher?

- **Onboarding-Antworten** → `myDex/.dex/config/profile.yaml`
- **Globale Chronik** → `myDex/.dex/chronicle/` (wird in v1.1 per-Projekt)
- **Draft-Outputs ohne Projekt-Kontext** → `myDex/drafts/`
- **Finale Artefakte zum Teilen** → `myDex/export/`

---

*Dieser Ordner ist bei Erstinstallation leer — das ist Absicht. Leg dein erstes Projekt an!*
