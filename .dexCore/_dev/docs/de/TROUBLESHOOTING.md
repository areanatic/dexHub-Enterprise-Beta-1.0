# Troubleshooting — DexHub Enterprise Beta 1.0

> **🌐 Sprache:** [🇬🇧 EN](../TROUBLESHOOTING.md) · **DE** (diese Datei)

Pragmatische Hilfe für die häufigsten Probleme. Struktur: **Symptom → Ursache → Fix**.

---

## Installation & Setup

### `@dex-master hi` — keine Antwort

**Ursachen (nach Häufigkeit):**
1. **Copilot nicht eingeloggt** — häufigster Grund. In VS Code rechts unten oder Menü: "GitHub: Sign In". Firma muss Copilot Enterprise-Seat zugewiesen haben.
2. **Extension Chat nicht aktiv** — GitHub Copilot Chat Extension muss zusätzlich installiert sein (nicht nur die Autocomplete-Extension).
3. **Falscher Workspace-Ordner geöffnet** — du musst im Root des geklonten DexHub-Repos sein (dort wo `.github/`, `.dexCore/`, `myDex/` liegen). In einem Sub-Ordner sieht Copilot die Agenten nicht.
4. **Model-Routing falsch** — in Copilot Chat unten rechts ein Dropdown, muss auf einem ausreichend starken Modell stehen (empfohlen: Claude Sonnet 4.5, GPT-4.1, oder gleichwertig).

**Fix-Reihenfolge:**
1. IDE komplett schließen + neu öffnen
2. Copilot re-authenticate (Command Palette → "GitHub Copilot: Sign Out" → neu einloggen)
3. Prüfen ob `.github/agents/dex-master.agent.md` im Repo existiert
4. Model im Chat-Dropdown auf Claude Sonnet 4.5 oder GPT-4.1 stellen

---

### Ich bin in einer anderen IDE (Cursor / Windsurf / JetBrains) — wie geht's?

DexHub ist primär für **GitHub Copilot Enterprise** getestet. In anderen IDEs:
- **Cursor / Windsurf:** Agenten werden als "@"-Tools angesprochen, sollte funktionieren. Achte darauf, dass die Agent-Dateien unter `.github/agents/` liegen (Cursor liest sie von dort).
- **JetBrains + Copilot:** Chat-Fenster öffnen, `@dex-master hi` — funktioniert, aber weniger getestet.
- **VS Code + Claude Code:** Extension muss installiert sein, Agent-Files werden automatisch erkannt.

Wenn nichts funktioniert: lies die Persona-Datei `.dexCore/core/agents/dex-master.md` selbst und gib sie deinem LLM als System-Prompt + "hi" als User-Message.

---

### `kreuzberg --version` → command not found

**macOS (Homebrew-Installation):**
```bash
brew doctor
# falls PATH-Issue: Shell neu starten
source ~/.zshrc  # oder ~/.bash_profile
```

**Linux:**
```bash
# Prüfen wo kreuzberg landete
which kreuzberg
ls ~/.local/bin/kreuzberg

# Falls vorhanden aber nicht im PATH:
export PATH="$HOME/.local/bin:$PATH"
# + permanent in ~/.bashrc / ~/.zshrc eintragen
```

**Windows (Git Bash):** Binary muss in einem Verzeichnis liegen, das Git Bash sieht — am einfachsten `C:\Program Files\Git\usr\local\bin\kreuzberg.exe`. Alternativ: Docker Desktop-Weg.

---

### Ollama "Port 11434 already in use"

**Top-Ursache (9 von 10):** Eine alte Ollama-Instanz läuft noch im Tray / Hintergrund.

**Fix:**
```bash
# macOS/Linux:
lsof -i :11434    # zeigt PID des blockierenden Prozesses
kill -9 <PID>

# Oder einfach: Ollama-App im Tray/Menüleiste → "Quit"
```

**Windows:**
```powershell
netstat -ano | findstr 11434
taskkill /PID <PID> /F
```

Oder: Taskleisten-Icon rechtsklick → "Quit Ollama".

Danach neu starten: `ollama serve` (CLI) oder App neu öffnen.

---

### `ollama pull <modell>` hängt bei "pulling manifest"

**Ursachen:**
1. Ollama-Daemon nicht aktiv → siehe oben (Port 11434)
2. Langsame Internet-Verbindung / Proxy blockiert
3. Disk voll (Modelle liegen in `~/.ollama/models` / `%USERPROFILE%\.ollama\models`)

**Fix:**
```bash
# Disk prüfen:
du -sh ~/.ollama   # (macOS/Linux)

# Bei Proxy: OLLAMA_HOST + HTTP_PROXY setzen
export HTTPS_PROXY=http://proxy.firma.de:8080
ollama serve &    # Daemon neu starten mit Proxy-Config
```

---

## Agent & Workflow Issues

### Agent antwortet auf Englisch, ich will Deutsch

```
@mydex *mydex-profile
```
Sprache ändern → speichern → `@dex-master hi` neu starten.

Funktioniert's immer noch nicht? Sag dem Agent direkt: "Bitte auf Deutsch antworten". Die `{communication_language}`-Variable wird pro Session gesetzt und sollte sticky bleiben.

---

### "Ich möchte ein Projekt starten" → wo finde ich das?

`@mydex create-project` als Direkt-Befehl existiert nicht (das war ein Doku-Drift). Der reale Pfad heute ist über das Menü:

1. `@mydex` aktivieren → myDex-Agent zeigt sein Menü
2. Wähle Menüpunkt **🚀 Neues Projekt** (Sub-Menu öffnet sich) — oder direkt natürlich-sprachlich sagen "Ich möchte ein Projekt starten"
3. Agent fragt nach Project-Name + kurzem Sparring (Worum geht's? Was willst du machen?)
4. Agent erstellt `myDex/projects/{name}/.dex/` Skeleton + initialen Draft

**Wenn nichts passiert:**
1. `myDex/projects/` existiert nicht als Ordner → (seit Beta 1.0 existiert das Skeleton; falls nicht: `mkdir myDex/projects/`)
2. Agent hat Schreib-Permission-Problem → prüfe ob du `.gitignore`-Exception für dein neues Projekt brauchst
3. Consent-Gate noch nicht durchlaufen — Agent fragt vor dem Schreiben um Bestätigung (G5)

**Geplant für 1.0.1+:** DexMaster Intent-Detection — du tippst "ich möchte ein Projekt starten" auf DexMaster-Ebene, und DexMaster routet dich direkt zu `#create-new-project` ohne Menü-Klicks.

---

### Workflow bricht mittendrin ab

Prüfen:
1. Ist Profile komplett? `@mydex status` — fehlen required Fields?
2. Ist Projekt aktiv? `@mydex switch-project` falls nötig
3. Logs? Agents schreiben kein strukturiertes Log — schaue den Chat-History durch für Fehlermeldungen

Nicht-triviale Fehler → GitHub Issue mit:
- Workflow-Name
- Letzte 5 Messages
- Output von `validate.sh`
- Profile-Datei (`myDex/.dex/config/profile.yaml`) — **vorher Private-Felder schwärzen**

---

## Parser / Inbox Issues

### `*inbox` → "Parser not installed"

**Bedeutung:** Kreuzberg ist nicht im PATH oder nicht installiert.

**Fix:** siehe INSTALLATION.md Schritt 5a. Verify: `kreuzberg --version` sollte Version zeigen.

Probe, was DexHub erkennt:
```bash
bash .dexCore/core/parser/capabilities-probe.sh
```

Der Output zeigt dir, welche Parser/Modelle DexHub findet. Zeilen mit `"status": "not_installed"` sind deine Installations-Lücken.

---

### `*inbox` mit Bild → "VLM not available"

**Bedeutung:** Kein Vision-Modell installiert. Für Bild-Parsing brauchst du Ollama + ein VLM.

**Fix:**
```bash
ollama pull moondream       # oder llava:7b, llama3.2-vision
```

Probe:
```bash
ollama list                 # zeigt installierte Modelle
bash .dexCore/core/parser/capabilities-probe.sh
```

---

## Enterprise / Connectors

### Atlassian-Wizard "Can't reach your instance"

Ursachen:
1. **VPN nicht verbunden** — Self-Hosted Jira braucht oft Firmen-VPN
2. **URL falsch** — Cloud ist `<subdomain>.atlassian.net`, Self-Hosted ist deine firma-URL
3. **Token falsch / abgelaufen** — Atlassian-Tokens laufen ab, neu in Atlassian-Account generieren

**Debug:**
```bash
# VPN ok?
curl -I https://deine-instanz.atlassian.net     # sollte HTTP 200 zurückgeben
```

---

### GitHub-Wizard "Unauthorized"

- Fine-grained Token mit richtigen Scopes? Benötigt: `repo`, `workflow`, `read:org`
- Token noch gültig? GitHub-Settings → Developer Settings → Tokens prüfen
- Enterprise-GitHub? `GITHUB_ENTERPRISE_URL`-Environment muss gesetzt sein

---

## Validation / Build

### `validate.sh` zeigt FAIL

Häufige Ursachen:

**§4 — "Required file missing: `.dexCore/_dev/agents/dev-mode-master.md`"**  
Du bist in einem **stripped Enterprise-Bundle**. Das ist OK — §4 hat eine `HAS_CLAUDE_TAIL`-Branch die Dev-Files im Bundle als optional behandelt. Falls nicht: das Repo wurde falsch gestripped — siehe [ADR-004](adr/ADR-004-non-destructive-only.md) und re-clone vom Original.

**§21 — "DEPRECATED_PHRASES: `100% Local-First` still found in peer files"**  
SSOT-Drift. Lauf `bash .dexCore/_dev/tools/build-instructions.sh build` — das generiert CLAUDE.md + copilot-instructions.md neu aus SHARED.md.

**§23 — "features.yaml: feature X references test Y which does not exist"**  
Du hast ein Test-File gelöscht oder umbenannt. Entweder Test wiederherstellen oder `tests:` Feld im Feature-Entry updaten.

**§25 — "README feature counts mismatch"**  
Du hast ein Feature hinzugefügt/entfernt aber den `counts_block` in features.yaml oder die README Feature-Matrix-Tabelle nicht angepasst.

**§26 — "counts_block does not match actual registry"**  
Ähnlich zu §25, aber intern in features.yaml. Siehe Kommentare am Ende der features.yaml.

---

### `build-for-enterprise.sh --verify` → FAIL

Das heißt: validate.sh läuft sauber auf deinem Dev-Repo, aber im stripped Bundle nicht. Häufig:
- Eine Datei die gestripped wurde, wird doch noch referenziert
- Test-File in `tests/e2e/integrations/` wird von Feature X gebraucht aber das Integration-Verzeichnis ist stripped

**Debug:**
```bash
bash .dexCore/_dev/tools/build-for-enterprise.sh --dry-run
# Zeigt was gestripped würde — check ob etwas dabei ist, das du eigentlich brauchst
```

---

## Git / Push Issues

### `git push origin main` → rejected

**Non-fast-forward:** Remote hat Commits die du lokal nicht hast.
```bash
git fetch origin
git log HEAD..origin/main --oneline    # zeigt was dir fehlt
git pull --rebase origin main          # wenn kompatibel
```

Bei echten Konflikten: manuell lösen — **niemals `--force` ohne Review**.

---

### Ich habe aus Versehen auf einen tombstoned Remote gepusht

Siehe Ground Rule #4 + #10 in CLAUDE.md. DexHub's `origin` zeigt auf **areanatic** (safe). Falls du einen andren Remote hinzugefügt hast und dorthin gepusht hast:
1. Source-of-truth-Repo (areanatic) sauber halten
2. Falschen Remote entfernen: `git remote remove <name>`
3. Bei einem tombstoned Enterprise-Remote: nichts mehr dorthin pushen — prüfe `git remote -v` und entferne den unerwünschten Remote

---

## Wenn gar nichts mehr hilft

**Option 1:** Reset zum letzten bekannt guten Stand:
```bash
git log --oneline -10          # zeig die letzten 10 Commits
git reset --hard <commit-hash> # zurück zum guten Stand (Achtung: verliert lokale Änderungen)
```

**Option 2:** Fresh clone:
```bash
cd ..
git clone https://github.com/areanatic/dexHub-Enterprise-Beta-1.0.git dexhub-fresh
cd dexhub-fresh
# profile + projekte aus altem Clone rüberkopieren:
cp -R ../dexHub-Enterprise-Beta-1.0/myDex ./
```

**Option 3:** GitHub Issue mit:
- `validate.sh`-Output
- Letzte 5 Git-Commits (`git log --oneline -5`)
- IDE + OS
- Symptom + was du erwartet hast

Öffne ein GitHub Issue im Repo oder nutze Dev-Mode: `@dex-master *dev-mode` → `*bug`.
