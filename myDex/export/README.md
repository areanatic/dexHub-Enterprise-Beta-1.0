# Export

Default-Speicherort für fertige Exports und finale Outputs.

## Verwendung

- Workflows mit **explizitem Export-Schritt** speichern hier
- **Finale Deliverables** für Kunden/Team
- **Bereit zum Teilen** außerhalb von DexHub
- **Archivierung** abgeschlossener Arbeit

## Beispiele

```bash
# Finales PRD exportieren
myDex/export/prd-mobile-app-v1.0-final.md

# Präsentation für Stakeholder
myDex/export/pitch-deck-q4-2025.pdf

# Technische Dokumentation
myDex/export/api-documentation-v2.3.md

# Code-Release
myDex/export/release-notes-v1.5.0.md
```

## Unterschied zu Drafts

| Aspekt | Drafts | Export |
|--------|--------|--------|
| **Zweck** | Temporär, Work-in-Progress | Final, Ready to Share |
| **Qualität** | Entwurf, kann Fehler haben | Reviewed, polished |
| **Lebensdauer** | Kurz (regelmäßig löschen) | Lang (archivieren) |
| **Teilen** | Intern (nur du) | Extern (Team, Kunden) |

## Organisation

Empfohlene Struktur für große Projekte:

```
export/
├── 2025-11/
│   ├── prd-feature-x.md
│   └── architecture-decision.md
├── 2025-12/
│   └── release-notes.md
└── archive/
    └── 2024/
```

## Siehe auch

- `drafts/` - Temporäre Workflow-Outputs
- `projects/` - Projektbezogene Dateien mit .dex/ Layer
- `inbox/` - Input-Files für Verarbeitung

---

**Feature seit:** EA-1.0 Folder Redesign
