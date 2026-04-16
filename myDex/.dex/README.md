# .dex - Your DexHub Profile

## What is this?

This folder contains YOUR DexHub profile - how agents behave for you.

**Privacy:** Everything stays local. You control all data.

---

## Structure

```
.dex/
├── config/
│   ├── preferences.yaml      # Your agent settings
│   └── workflow-notes.md     # Context for workflows
└── agent-state/
    └── (auto-generated)       # Session continuity data
```

---

## Quick Start

1. **Copy template:**
   ```bash
   cp config/preferences.yaml.example config/preferences.yaml
   ```

2. **Edit your profile:**
   ```yaml
   user:
     name: "Your Name"
     experience_level: senior  # senior/mid/junior/beginner

   stack:
     primary_language: TypeScript
     framework: React
   ```

3. **Done!** Agents now adapt to YOUR preferences.

---

## How It Works

### Config Override
```
Default:     .dexCore/_cfg/config.yaml
Your config: myDex/.dex/config/preferences.yaml
Result:      Your config wins
```

### Runtime Detection
Agents check: "Does myDex/.dex/config/preferences.yaml exist?"
- **Yes:** Use your settings
- **No:** Use .dexCore defaults

---

## What to Configure

### User Settings
- `experience_level`: How much agents explain
- `communication_style`: Concise vs detailed
- `preferred_language`: en/de

### Stack Preferences
- `primary_language`: Code examples use this
- `framework`: Workflow suggestions adapt
- `ide`: Tool recommendations

### Agent Behavior
- `default_mode`: expert/teaching/pair-programming
- `explanation_depth`: minimal/medium/detailed
- `auto_save_outputs`: true/false

---

## Privacy

**What's stored:**
- Your configuration (you edit manually)
- Workflow context (opt-in, you control)
- Agent state for session continuity (optional)

**What's NOT stored:**
- No telemetry
- No cloud sync
- No automatic tracking

---

## Brownfield Projects

Using DexHub with existing code?

Create `.dex/` in your project root:
```
your-existing-project/
├── .dex/              # DexHub meta-layer
│   ├── config/
│   └── workflows/
├── src/               # Your existing code
└── package.json
```

This keeps DexHub separate from your codebase.

---

**Need help?** Ask any agent: "Explain my .dex profile"
