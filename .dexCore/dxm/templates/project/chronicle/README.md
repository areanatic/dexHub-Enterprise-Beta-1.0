# Chronicle

Tägliche Detail-Logs für dieses Projekt.

---

## Was ist Chronicle?

Chronicle ist Tier 2 des 3-Tier Documentation Systems:

| Tier | Datei | Granularität | Zweck |
|------|-------|--------------|-------|
| 1 | CHANGELOG.md | Wochen/Meilensteine | Was hat sich geändert? |
| **2** | **chronicle/*.md** | **Tage/Sessions** | **Was wurde gemacht?** |
| 3 | INDEX.md Activity Log | Rolling | Wo stehen wir? |

---

## Struktur

```
chronicle/
├── README.md           # Diese Datei
├── 2026-02-21.md       # Heute
├── 2026-02-20.md       # Gestern
├── ...
└── archive/            # Logs älter als 30 Tage
    └── 2026-01/
        └── 2026-01-31.md
```

---

## Inhalt pro Tag

Jedes Daily-Log enthält:

1. **Summary** - Kurze Zusammenfassung
2. **Sessions** - Detailliert pro Session
   - Focus
   - What was done
   - Decisions made
   - Insights
   - Blockers
   - Files changed
3. **Open Questions** - Offene Fragen
4. **Tomorrow's Plan** - Nächste Schritte
5. **Context** - Zusätzlicher Kontext (politisch, emotional)

---

## Wann wird geloggt?

- **Session-Start:** Agent prüft auf bestehendes Log
- **Session-Ende:** Agent bietet Logging an
- **Bei Entscheidungen:** Agent fragt nach Rationale

---

## Konfiguration

In `.dex/config/project.yaml`:

```yaml
chronicle:
  enabled: true
  detail_level: high  # low | medium | high | verbose
```

---

## RAG-Integration

Chronicle-Files sind optimiert für semantische Suche:
- Ein Chunk pro Tag
- Strukturierte Sections
- Durchsuchbare Entscheidungen und Insights
