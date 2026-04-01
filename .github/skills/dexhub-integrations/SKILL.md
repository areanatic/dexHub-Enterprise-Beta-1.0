---
name: dexhub-integrations
description: "Integration onboarding for all external tools: Atlassian (Jira/Confluence), GitHub Enterprise, Figma. Setup guides, token management, troubleshooting. Use when user asks about connecting tools or setting up integrations."
---

# DexHub Integrations — Onboarding & Setup

## Available Integrations

| Integration | Status | Auth | Path |
|------------|--------|------|------|
| **Atlassian** (Jira + Confluence) | Production | PAT / OAuth | `.dexCore/core/integrations/atlassian-mcp/` |
| **GitHub Enterprise** (<enterprise-git-host>) | Production | `gh auth` / PAT | `.dexCore/core/integrations/github-mcp/` |
| **Figma** (Design Files) | Production | Access Token (REST API) | `.dexCore/core/integrations/figma-mcp/` |

## Unified Entry Point

```bash
bash .dexCore/core/integrations/connect.sh <integration>
```

| Command | What it does |
|---------|-------------|
| `connect.sh atlassian` | Jira + Confluence setup (VPN required) |
| `connect.sh github` | GitHub Enterprise setup (VPN required) |
| `connect.sh figma` | Figma REST API setup (no VPN needed) |
| `connect.sh all` | Setup all integrations sequentially |

---

## Response Pattern

When user asks "Kann ich X integrieren?" / "How do I connect Y?":

**RICHTIG:**
```
Ja klar! Mit DexHub hast du bereits ein vollstaendiges Setup.
In 3 einfachen Schritten: 1. ... 2. ... 3. ...
Automatisch oder manuell? Was moechtest du?
```

**FALSCH:**
- Lange technische Erklaerungen
- Befehle zum Kopieren statt ausfuehren
- Option A, B, C, D...

---

## Atlassian (Jira + Confluence)

### Voraussetzungen
- DHL VPN verbunden
- VS Code + GitHub Copilot Chat
- Atlassian-Account mit API-Zugriff

### Setup (3 Schritte)
1. **VPN verbinden** (DHL-Netzwerk)
2. **Setup starten:** `bash .dexCore/core/integrations/connect.sh atlassian`
3. **Token eingeben** (Browser oeffnet sich automatisch fuer Token-Erstellung)

### Zwei Atlassian-Welten

| | On-Premise (Server) | Cloud |
|---|---|---|
| Auth | Personal Access Token (PAT) | OAuth 2.0 |
| URL | `https://company.domain/confluence1` | `https://company.atlassian.net` |
| VPN | Ja (meistens) | Nein |

### Token erstellen
1. Browser oeffnet: `https://id.atlassian.com/manage-profile/security/api-tokens`
2. "Create API token" klicken
3. Name: "DexHub MCP"
4. Token kopieren + im Terminal einfuegen

### Troubleshooting
- **"Connection failed"** → VPN verbunden? `ping dhl.atlassian.net`
- **"Permission denied"** → Atlassian-Zugriff pruefen, IT kontaktieren
- **"Token expired"** → Neuen Token erstellen (gleicher Weg)

---

## GitHub Enterprise

### Voraussetzungen
- DHL VPN verbunden
- VS Code + GitHub Copilot Chat
- `gh` CLI installiert

### Setup (3 Schritte)
1. **VPN verbinden**
2. **Setup starten:** `bash .dexCore/core/integrations/connect.sh github`
3. **Im Browser authentifizieren** (`gh auth login`)

### Token-Verwaltung
```bash
# Status pruefen
gh auth status --hostname <enterprise-git-host>

# Token erneuern
gh auth refresh --hostname <enterprise-git-host>

# Neu einloggen
gh auth login --hostname <enterprise-git-host>
```

### Troubleshooting
- **"Binary not found"** → `install.sh` erneut ausfuehren
- **"Token expired"** → `gh auth refresh`
- **"Permission denied"** → `gh auth login --hostname <enterprise-git-host>`

---

## Figma

### Voraussetzungen
- Figma-Account (Professional oder Enterprise fuer sinnvolle Nutzung)
- Kein VPN noetig (Figma ist oeffentlich)

### Setup (3 Schritte)
1. **Figma oeffnen:** figma.com → Settings → Security → Personal Access Tokens
2. **Token erstellen:** Name "DexHub", Read-Scopes auswaehlen, Token kopieren (faengt mit `figd_` an)
3. **Token speichern:** In `.env` Datei im Projektverzeichnis ablegen

### Token-Datei (.env)
```env
FIGMA_ACCESS_TOKEN=<dein-token-hier>
FIGMA_FILE_KEY=<optional-file-key>
```

**Wichtig:** `.env` ist gitignored — Token wird NIE committed.

### Zugriff testen
```bash
cd myDex/projects/figma-integration-pocs
python3 figma_rest_client.py --analyze
```

### Warum REST API statt MCP?
- MCP-Server-Discovery in VS Code ist unzuverlaessig (bekanntes Problem)
- REST API ist direkt, transparent, sofort debuggbar
- Gleiche Daten, gleiche Berechtigungen
- Token in lokaler `.env` statt in VS Code Config-Pipeline
- Details: `myDex/projects/figma-integration-pocs/INTEGRATION-JOURNEY.md`

### Rate Limits
| Plan | Limit |
|------|-------|
| Free/Starter | 6 Calls/Monat (unbrauchbar) |
| Professional | Per-Minute Limits |
| Enterprise | Per-Minute Limits, hohe Obergrenze |

### Troubleshooting
- **"401 Forbidden"** → Token pruefen, Scopes pruefen
- **"Rate limit"** → Plan checken (Starter = 6/Monat)
- **"File not found"** → File-Key aus Figma URL extrahieren (zwischen `/design/` und `/`)
- **Token abgelaufen** → Neuen Token erstellen (gleicher Weg), `.env` aktualisieren

---

## Setup-Dateien (alle Integrations)

| Datei | Zweck |
|-------|-------|
| `connect.sh` | Unified Entry Point (Router) |
| `install.sh` | Per-Integration Installer |
| `auto-auth.sh` | Browser-basierte Authentifizierung |
| `config-template.json` | VS Code MCP Config Template |
| `tools.yaml` | Tool-Referenz Dokumentation |
| `README.md` | Quick Start + Troubleshooting |

---

## Neue Integration hinzufuegen (fuer DexHub-Entwickler)

1. Verzeichnis: `.dexCore/core/integrations/<name>-mcp/`
2. Dateien erstellen: `install.sh`, `auto-auth.sh`, `config-template.json`, `tools.yaml`, `README.md`
3. `connect.sh` updaten (neuer Case + Funktion)
4. Diesen Skill updaten (neue Sektion)
5. Optional: Agent erstellen (wenn eigene Analyse-Capabilities)
