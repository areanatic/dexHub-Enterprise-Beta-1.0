# Inbox

Lege hier Files ab, die du für ein Projekt verarbeiten möchtest.

## Workflow

1. **File hierhin kopieren** (z.B. PDF, Markdown, Code, Bilder)
2. **`*inbox`** im myDex-Agent aktivieren
3. **File auswählen** + Zielprojekt angeben
4. **AI verarbeitet** und migriert nach `projects/{name}/src/`
5. **Original wird automatisch gelöscht** (keine Duplikate!)

## Beispiel

```bash
# 1. File in Inbox legen
cp ~/Downloads/requirements.pdf myDex/inbox/

# 2. In DexHub aktivieren
# User: "*inbox"

# 3. AI fragt
# "Welche Datei verarbeiten? requirements.pdf"
# "Für welches Projekt? my-app"

# 4. Ergebnis
# File verarbeitet → myDex/projects/my-app/src/requirements-processed.md
# Original gelöscht → myDex/inbox/requirements.pdf (weg!)
```

## Unterstützte Dateitypen

- **Text & Code:** .md, .txt, .js, .py, .java, etc.
- **Dokumente:** .pdf (werden analysiert)
- **Bilder:** .png, .jpg (werden beschrieben)
- **Daten:** .json, .csv, .yaml

## Siehe auch

- `projects/` - Zielordner für verarbeitete Files
- `drafts/` - Temporäre Outputs ohne Projekt-Kontext
- `export/` - Fertige Deliverables

---

**Feature seit:** EA-1.0 Inbox Workflow
