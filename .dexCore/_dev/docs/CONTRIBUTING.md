# Contributing to DexHub

> How to report bugs, suggest features, and contribute to DexHub development.

---

## Quick Start

1. Clone the repo and open in your IDE
2. Say **"Start Dev-Mode"** to your AI assistant
3. Use Dev-Mode commands to create entries

That's it. Dev-Mode handles the formatting and saves entries to the right location.

---

## Dev-Mode Commands

| Command | What it does |
|---------|-------------|
| `*bug` | Report a bug |
| `*feature` | Request a feature |
| `*tech-debt` | Note technical debt |
| `*research` | Suggest research topic |
| `*design` | Propose design change |
| `*discuss` | Start a discussion |
| `*comment` | Add comment to existing entry |
| `*dashboard` | Open the development dashboard |
| `*status` | Show entry statistics |
| `*help` | Show this menu |

### Example

```
You: *bug
Dev-Mode: Title?
You: Greeting menu shows wrong format
Dev-Mode: Description?
You: When I say "hi", the menu format is different each time
Dev-Mode: Priority? [low/medium/high/critical]
You: high
Dev-Mode: Bug BUG-XXX created in todos/bugs.md
```

---

## Submitting Your Feedback

### Via Pull Request (Preferred)

```bash
# 1. Fork the repo on GitHub (click "Fork" button)
# 2. Clone your fork
git clone https://github.com/YOUR-USERNAME/dexHub-Enterprise-Alpha-1.0.git
cd dexHub-Enterprise-Alpha-1.0

# 3. Create your feedback branch
git checkout -b feedback/your-name

# 4. After creating entries with Dev-Mode
git add .dexCore/_dev/todos/
git commit -m "feedback: Add bug report for menu inconsistency"
git push origin feedback/your-name

# 5. Create PR back to the main repo
gh pr create --title "Feedback: [Your Name]" --body "Bug reports and feature requests"
```

### Via GitHub Issues

Open an issue at the repository's Issues page with:
- Clear title
- Steps to reproduce (for bugs)
- Expected vs actual behavior
- Your platform (VS Code + Copilot version, OS)

---

## What Gets Tracked Where

| Type | Location |
|------|----------|
| Bugs | `.dexCore/_dev/todos/bugs.md` |
| Features | `.dexCore/_dev/todos/features.md` |
| Tech Debt | `.dexCore/_dev/todos/technical-debt.md` |
| Roadmap | `.dexCore/_dev/todos/roadmap.md` |
| Changelog | `.dexCore/_dev/CHANGELOG.md` |

---

## Validation

Before submitting, run the automated checks:

```bash
bash .dexCore/_dev/tools/validate.sh
```

This runs 57 automated checks covering file existence, agent consistency, architecture rules, and sanity checks.

---

## Privacy Rules

**NEVER commit these files:**
- `myDex/.dex/config/profile.yaml` (personal data)
- `myDex/.dex/CONTEXT.md` (session state)
- `myDex/projects/*/` (your project work)
- `.env`, `*.key`, `*.pem`, `credentials.json`
- `.mcp.json` (MCP server tokens)

These are already in `.gitignore` but please double-check before pushing:
```bash
git diff --cached --name-only | grep -E "profile\.yaml|CONTEXT\.md|\.env|\.key|\.mcp"
```

---

## Guidelines

- **One issue per entry** — don't combine multiple problems
- **Be specific** — "menu shows wrong format on greeting" > "something is broken"
- **Include platform** — Copilot on Windows/macOS? Which model?
- **Include steps to reproduce** for bugs
- **Explain the why** for feature requests

---

## Development Dashboard

Open the visual dashboard for an overview of all bugs, features, and roadmap:

```bash
# Regenerate with latest data
python3 .dexCore/_dev/tools/generate-dashboard.py

# Open in browser
open .dexCore/_dev/tools/dexhub-dashboard.html
```

---

**Thank you for contributing! Every bug report and feature request makes DexHub better.**

*Part of DexHub Dev-Mode — we use DexHub to build DexHub.*
