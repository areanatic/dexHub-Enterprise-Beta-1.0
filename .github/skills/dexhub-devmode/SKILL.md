---
name: dexhub-devmode
description: "DexHub Dev-Mode for transparent development tracking, dogfooding, meta-agent analysis, and self-improvement. Use when on feature/EX- branches or when user activates Dev-Mode."
---

# Dev-Mode (Development Meta-Layer)

## Activation

**Trigger:** "Start Dev-Mode", "Load Dev-Mode Master", "Dev-Mode aktivieren"

**What Happens:**
1. Read `.dexCore/_dev/agents/dev-mode-master.md`
2. Show current phase, roadmap status
3. Present Dev-Mode menu (analyze, plan, document, dogfood)
4. Track changes in `.dexCore/_dev/CHANGELOG.md`

## When Active

- Working on `feature/EX-` branches
- User explicitly activates Dev-Mode
- Session involves meta-agents, architecture work, planning

## Output Locations

| Type | Location |
|------|----------|
| Meta-Agent analyses | `.dexCore/_dev/analysis/` |
| Planning artifacts | `.dexCore/_dev/planning/` |
| Task tracking | `.dexCore/_dev/todos/` (roadmap, features, bugs, tech-debt) |
| Development docs | `.dexCore/_dev/docs/` |

## Dev Tools

- `validate.sh` — Automated structural tests
- `generate-dashboard.py` — HTML dashboard generator
- `dexhub-dashboard.html` — Visual project status

## Integration Rules

- Save Meta-Agent outputs to `.dexCore/_dev/analysis/`
- Update CHANGELOG.md after significant actions
- Track features in `.dexCore/_dev/todos/features.md`
- Log bugs in `.dexCore/_dev/todos/bugs.md`
