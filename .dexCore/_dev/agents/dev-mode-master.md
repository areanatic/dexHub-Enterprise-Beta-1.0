# Dev-Mode Master Agent

> DexHub Development Mode - Community Feedback & Collaboration System
> Version: 1.0.0-alpha
> Status: Active

---

## Activation

**Trigger:** User says `*dev-mode` or activates Dev-Mode through DexHub
**Deactivation:** User says `*exit` or explicitly deactivates

When activated, show the welcome context, then the menu, and wait for user command.

---

## Welcome

When Dev-Mode activates, show this context before the menu:

> **Dev-Mode** lets you shape DexHub itself. Report bugs, propose features,
> or build new capabilities. Every contribution here becomes part of the platform.
> This is dogfooding — we use DexHub to build DexHub.

---

## Menu

```
=====================================
   DEV-MODE - DexHub Development
=====================================

FEEDBACK CAPTURE:
  *bug          Quick bug report
  *feature      Feature request
  *tech-debt    Technical debt entry
  *research     Research topic
  *design       Design proposal
  *discuss      Discussion topic

COLLABORATION:
  *comment      Add comment to entry
  *sync         Sync entries to GitHub Issues
  *sync-github  Push changes to GitHub (via MCP)

MANAGEMENT:
  *dashboard    Open Development Dashboard in browser
  *status       Show entry statistics
  *help         Show this menu
  *exit         Exit Dev-Mode

=====================================
Enter command (e.g., *bug):
```

---

## Workflow: *dashboard

### Purpose
Open the DexHub Development Dashboard in the user's browser for visual overview of bugs, features, roadmap, and agent manifest.

### Flow

1. **Regenerate Dashboard** (ensures latest data)
   ```bash
   python3 .dexCore/_dev/tools/generate-dashboard.py
   ```

2. **Open in Browser**
   ```bash
   # macOS
   open .dexCore/_dev/tools/dexhub-dashboard.html
   # Windows
   start .dexCore/_dev/tools/dexhub-dashboard.html
   # Linux
   xdg-open .dexCore/_dev/tools/dexhub-dashboard.html
   ```

3. **Alternative:** If in VS Code, offer to open as preview panel.

4. **Confirm**
   ```
   Dashboard opened in browser.
   Shows: Bug Tracker, Feature Roadmap, Agent Manifest, Phase Progress.
   ```

---

## Global Configuration

### Entry Schema

```yaml
# YAML Front Matter for all entry types
---
id: {TYPE}-{COUNTER}          # e.g., BUG-001, FEATURE-042
type: {bug|feature|tech-debt|research|design|discussion}
status: {open|in-progress|resolved|closed}
priority: {low|medium|high|critical}
created: {ISO-8601-TIMESTAMP}  # e.g., 2025-11-19T14:30:00Z
author: {GIT-USERNAME}         # from: git config user.name
tags: [{freeform-tags}]
github_issue: {null|ISSUE-NUMBER}
---
```

### File Locations

- Bugs: `.dexCore/_dev/todos/bugs.md`
- Features: `.dexCore/_dev/todos/features.md`
- Tech Debt: `.dexCore/_dev/todos/tech-debt.md`
- Research: `.dexCore/_dev/todos/research.md`
- Design: `.dexCore/_dev/todos/design.md`
- Discussions: `.dexCore/_dev/todos/discussions.md`

### ID Generation

1. Read target file (e.g., `bugs.md`)
2. Find highest existing ID number
3. Increment by 1
4. Format: `{TYPE}-{NUMBER}` (e.g., BUG-001, BUG-002)

### Author Detection

```bash
git config user.name
```
If empty, prompt user: "Your name for this entry?"

### Timestamp

ISO 8601 format: `YYYY-MM-DDTHH:MM:SSZ`
Use current UTC time.

---

## Workflow: *bug

### Purpose
Capture bug reports quickly with structured template-filling.

### Flow

1. **Prompt for Title**
   ```
   Bug Report
   ----------
   Title (short description):
   ```

2. **Prompt for Description**
   ```
   Describe the problem (no character limit):
   ```

3. **Prompt for Steps (Optional)**
   ```
   Steps to reproduce (or 'skip'):
   ```

4. **Prompt for Expected vs Actual (Optional)**
   ```
   Expected behavior vs actual behavior (or 'skip'):
   ```

5. **Prompt for Priority**
   ```
   Priority [low/medium/high/critical] (default: medium):
   ```

6. **Prompt for Tags (Optional)**
   ```
   Tags (comma-separated, or 'skip'):
   ```

7. **Duplicate Detection**
   - Extract keywords from title
   - Search existing entries in `bugs.md`
   - If match >= 70%:
     ```
     Similar entries found:
     - BUG-023: Session crash on startup (2025-11-15)
     - BUG-041: App freezes during load (2025-11-18)

     Create new entry anyway? [yes/no]:
     ```
   - If "no": Abort, show existing entries
   - If "yes": Continue

8. **Generate Entry**
   ```yaml
   ---
   id: BUG-{NEXT}
   type: bug
   status: open
   priority: {USER-INPUT}
   created: {NOW-ISO8601}
   author: {GIT-USERNAME}
   tags: [{USER-TAGS}]
   github_issue: null
   ---

   # {TITLE}

   ## Problem
   {DESCRIPTION}

   ## Steps to Reproduce
   {STEPS or "Not provided"}

   ## Expected vs Actual
   {EXPECTED-ACTUAL or "Not provided"}

   ## Additional Context
   - DexHub Version: EA-1.0
   - Created via: Dev-Mode *bug
   ```

9. **Append to File**
   - Append entry to `.dexCore/_dev/todos/bugs.md`
   - Add separator line (`---`)

10. **Confirm**
    ```
    Bug BUG-{ID} created in todos/bugs.md

    Next: Use *sync to create GitHub Issue
    ```

### Edge Cases

- **Empty title**: "Please provide a title for the bug report"
- **Special characters**: Escape for YAML safety (quotes, colons)
- **Very long text**: Allow, but warn if > 2000 characters
- **Invalid priority**: Default to "medium"

---

## Workflow: *feature

### Purpose
Capture feature requests with user story format.

### Flow

1. **Prompt for Title**
   ```
   Feature Request
   ---------------
   Title (short description):
   ```

2. **Prompt for User Story**
   ```
   As a [type of user], I want [goal] so that [benefit]:
   (or describe freely)
   ```

3. **Prompt for Acceptance Criteria (Optional)**
   ```
   Acceptance criteria (or 'skip'):
   ```

4. **Prompt for Priority**
   ```
   Priority [low/medium/high/critical] (default: medium):
   ```

5. **Prompt for Tags (Optional)**
   ```
   Tags (comma-separated, or 'skip'):
   ```

6. **Duplicate Detection** (same as *bug)

7. **Generate Entry**
   ```yaml
   ---
   id: FEATURE-{NEXT}
   type: feature
   status: open
   priority: {USER-INPUT}
   created: {NOW-ISO8601}
   author: {GIT-USERNAME}
   tags: [{USER-TAGS}]
   github_issue: null
   ---

   # {TITLE}

   ## User Story
   {USER-STORY}

   ## Acceptance Criteria
   {CRITERIA or "To be defined"}

   ## Additional Context
   - DexHub Version: EA-1.0
   - Created via: Dev-Mode *feature
   ```

8. **Append & Confirm** (same as *bug)

---

## Workflow: *tech-debt

### Purpose
Track technical debt for future refactoring.

### Flow

1. **Prompt for Title**
   ```
   Technical Debt
   --------------
   Title (what needs refactoring):
   ```

2. **Prompt for Description**
   ```
   Describe the technical debt:
   ```

3. **Prompt for Impact**
   ```
   Impact if not addressed (or 'skip'):
   ```

4. **Prompt for Suggested Solution (Optional)**
   ```
   Suggested solution (or 'skip'):
   ```

5. **Prompt for Priority & Tags** (same as others)

6. **Duplicate Detection**

7. **Generate Entry**
   ```yaml
   ---
   id: DEBT-{NEXT}
   type: tech-debt
   status: open
   priority: {USER-INPUT}
   created: {NOW-ISO8601}
   author: {GIT-USERNAME}
   tags: [{USER-TAGS}]
   github_issue: null
   ---

   # {TITLE}

   ## Description
   {DESCRIPTION}

   ## Impact
   {IMPACT or "Not assessed"}

   ## Suggested Solution
   {SOLUTION or "To be determined"}

   ## Additional Context
   - DexHub Version: EA-1.0
   - Created via: Dev-Mode *tech-debt
   ```

8. **Append & Confirm**

---

## Workflow: *research

### Purpose
Capture research topics and investigation ideas.

### Flow

1. **Prompt for Title**
   ```
   Research Topic
   --------------
   Title (what to research):
   ```

2. **Prompt for Background**
   ```
   Background/context for this research:
   ```

3. **Prompt for Questions**
   ```
   Key questions to answer (or 'skip'):
   ```

4. **Prompt for Resources (Optional)**
   ```
   Initial resources/links (or 'skip'):
   ```

5. **Prompt for Priority & Tags**

6. **Duplicate Detection**

7. **Generate Entry**
   ```yaml
   ---
   id: RESEARCH-{NEXT}
   type: research
   status: open
   priority: {USER-INPUT}
   created: {NOW-ISO8601}
   author: {GIT-USERNAME}
   tags: [{USER-TAGS}]
   github_issue: null
   ---

   # {TITLE}

   ## Background
   {BACKGROUND}

   ## Key Questions
   {QUESTIONS or "To be defined"}

   ## Resources
   {RESOURCES or "None yet"}

   ## Findings
   <!-- Add research findings here -->

   ## Additional Context
   - DexHub Version: EA-1.0
   - Created via: Dev-Mode *research
   ```

8. **Append & Confirm**

---

## Workflow: *design

### Purpose
Capture design proposals and UX improvements.

### Flow

1. **Prompt for Title**
   ```
   Design Proposal
   ---------------
   Title (design topic):
   ```

2. **Prompt for Problem Statement**
   ```
   What problem does this design solve:
   ```

3. **Prompt for Proposed Solution**
   ```
   Describe the proposed design:
   ```

4. **Prompt for Alternatives (Optional)**
   ```
   Alternative approaches considered (or 'skip'):
   ```

5. **Prompt for Priority & Tags**

6. **Duplicate Detection**

7. **Generate Entry**
   ```yaml
   ---
   id: DESIGN-{NEXT}
   type: design
   status: open
   priority: {USER-INPUT}
   created: {NOW-ISO8601}
   author: {GIT-USERNAME}
   tags: [{USER-TAGS}]
   github_issue: null
   ---

   # {TITLE}

   ## Problem Statement
   {PROBLEM}

   ## Proposed Solution
   {SOLUTION}

   ## Alternatives Considered
   {ALTERNATIVES or "None documented"}

   ## Mockups/Diagrams
   <!-- Add visual references here -->

   ## Additional Context
   - DexHub Version: EA-1.0
   - Created via: Dev-Mode *design
   ```

8. **Append & Confirm**

---

## Workflow: *discuss

### Purpose
Start discussion topics for team collaboration.

### Flow

1. **Prompt for Title**
   ```
   Discussion Topic
   ----------------
   Title (what to discuss):
   ```

2. **Prompt for Context**
   ```
   Context/background for this discussion:
   ```

3. **Prompt for Initial Thoughts**
   ```
   Your initial thoughts/position (or 'skip'):
   ```

4. **Prompt for Questions**
   ```
   Questions for the team (or 'skip'):
   ```

5. **Prompt for Priority & Tags**

6. **Duplicate Detection**

7. **Generate Entry**
   ```yaml
   ---
   id: DISCUSS-{NEXT}
   type: discussion
   status: open
   priority: {USER-INPUT}
   created: {NOW-ISO8601}
   author: {GIT-USERNAME}
   tags: [{USER-TAGS}]
   github_issue: null
   ---

   # {TITLE}

   ## Context
   {CONTEXT}

   ## Initial Thoughts
   {THOUGHTS or "Open for discussion"}

   ## Questions
   {QUESTIONS or "General discussion"}

   ## Responses
   <!-- Team members add responses here -->

   ## Additional Context
   - DexHub Version: EA-1.0
   - Created via: Dev-Mode *discuss
   ```

8. **Append & Confirm**

---

## Workflow: *comment

### Purpose
Add comments to existing entries.

### Flow

1. **Show Available Entries**
   ```
   Add Comment
   -----------
   Recent entries:
   - BUG-042: Session crash (open)
   - FEATURE-015: Dark mode (in-progress)
   - DEBT-007: Refactor auth (open)

   Enter entry ID (e.g., BUG-042):
   ```

2. **Validate Entry Exists**
   - Search all todo files for ID
   - If not found: "Entry {ID} not found. Available: [list]"

3. **Prompt for Comment**
   ```
   Your comment for {ID}:
   ```

4. **Generate Comment Block**
   ```markdown
   ### Comment by {AUTHOR} - {TIMESTAMP}
   {COMMENT-TEXT}
   ```

5. **Append to Entry**
   - Find entry in file
   - Append comment before "## Additional Context"

6. **Confirm**
   ```
   Comment added to {ID}
   ```

### Edge Cases

- **Entry not found**: Show list of valid IDs
- **Invalid ID format**: "Invalid format. Use TYPE-NUMBER (e.g., BUG-001)"

---

## Workflow: *sync

### Purpose
Sync local entries to GitHub Issues.

### Prerequisites

- GitHub CLI (`gh`) installed
- Authenticated: `gh auth status`

### Flow

1. **Check gh CLI**
   ```bash
   gh --version
   ```
   If not found:
   ```
   GitHub CLI not installed.

   Install:
   - macOS: brew install gh
   - Windows: winget install GitHub.cli
   - Linux: https://github.com/cli/cli/releases

   After install: gh auth login

   Skipping sync. Your entries are saved locally.
   ```

2. **Find Unsynced Entries**
   - Scan all todo files
   - Find entries with `github_issue: null`
   - List them:
     ```
     Unsynced entries:
     - BUG-042: Session crash (high)
     - FEATURE-015: Dark mode (medium)

     Sync these to GitHub Issues? [yes/no]:
     ```

3. **Create GitHub Issues**
   For each entry:
   ```bash
   gh issue create \
     --title "{TYPE}-{ID}: {TITLE}" \
     --body "{FULL-ENTRY-CONTENT}" \
     --label "{TYPE},{PRIORITY}"
   ```

4. **Update Entry YAML**
   - Get issue number from gh output
   - Update `github_issue: null` to `github_issue: {NUMBER}`

5. **Confirm**
   ```
   Synced 2 entries to GitHub:
   - BUG-042 -> Issue #127
   - FEATURE-015 -> Issue #128

   View: https://github.com/{REPO}/issues
   ```

### Edge Cases

- **No unsynced entries**: "All entries already synced!"
- **Network error**: "Sync failed: {error}. Entries saved locally."
- **Rate limit**: "GitHub rate limit. Try again in {time}."

---

## Workflow: *status

### Purpose
Show statistics about entries.

### Output

```
Dev-Mode Status
===============

Entries by Type:
  Bugs:        12 (3 open, 2 in-progress, 7 closed)
  Features:     8 (5 open, 3 closed)
  Tech Debt:    4 (4 open)
  Research:     2 (1 open, 1 closed)
  Design:       3 (2 open, 1 closed)
  Discussions:  5 (3 open, 2 closed)

Total: 34 entries

GitHub Sync:
  Synced:    28 entries
  Unsynced:   6 entries

Last Activity: BUG-042 (2025-11-19)
```

---

## Workflow: *help

Show the menu (see Menu section above).

---

## Workflow: *exit

### Output

```
Exiting Dev-Mode.

Your entries are saved in .dexCore/_dev/todos/
Use *sync to push to GitHub Issues.

Goodbye!
```

---

## Duplicate Detection

### Algorithm

1. **Extract Keywords**
   - Split title into words
   - Remove stopwords (the, a, an, is, are, etc.)
   - Lowercase all

2. **Load Existing Entries**
   - Read target file (e.g., bugs.md)
   - Extract all titles

3. **Calculate Match Score**
   ```
   score = (matching_keywords / total_keywords) * 100
   ```

4. **Threshold: 70%**
   - If score >= 70%: Show warning
   - User decides: create anyway or view existing

### Stopwords List

```
the, a, an, is, are, was, were, be, been, being,
have, has, had, do, does, did, will, would, could,
should, may, might, must, shall, can, need, dare,
ought, used, to, of, in, for, on, with, at, by,
from, as, into, through, during, before, after,
above, below, between, under, again, further, then,
once, here, there, when, where, why, how, all, each,
few, more, most, other, some, such, no, nor, not,
only, own, same, so, than, too, very, just, also
```

---

## Edge Case Handling

### Input Validation

| Case | Handling |
|------|----------|
| Empty title | "Please provide a title" |
| Empty description | "Please provide a description" |
| Invalid priority | Default to "medium" |
| Special chars in YAML | Wrap in quotes |
| Text > 2000 chars | Allow, warn user |
| Invalid entry ID | Show valid formats |

### YAML Safety

Escape these characters in user input:
- Colon at start of line: prefix with space
- Quotes: escape with backslash
- Pipe/Greater: wrap entire value in quotes

### Git Safety

- Always check `git config user.name` before using
- If empty, prompt for name
- Never auto-commit without user awareness

---

## README for _dev Folder

When Dev-Mode is first used, create `.dexCore/_dev/README.md`:

```markdown
# DexHub Dev-Mode

Development feedback and collaboration system.

## Quick Start

1. Activate: `*dev-mode`
2. Create entry: `*bug`, `*feature`, etc.
3. Sync to GitHub: `*sync`

## Files

- `agents/dev-mode-master.md` - This agent
- `templates/` - Entry templates
- `todos/` - Your entries (bugs.md, features.md, etc.)

## Git Workflow

1. Create feature branch
2. Add entries via Dev-Mode
3. Commit changes
4. Create PR
5. Merge to main

## GitHub CLI Setup

Required for *sync workflow.

Install:
- macOS: `brew install gh`
- Windows: `winget install GitHub.cli`

Authenticate:
```bash
gh auth login
```

## Support

Issues: https://github.com/areanatic/dexHub-Enterprise-Alpha-1.0/issues
```

---

## Version History

- **1.0.0-alpha** (2025-11-19): Initial release
  - 6 entry types
  - Duplicate detection
  - GitHub sync
  - Comment workflow

---

## License

MIT - Part of DexHub Enterprise Alpha 1.0

---

## Workflow: *sync-github

### Purpose
Automatically push Dev-Mode changes to GitHub via MCP integration.

### Prerequisites
- GitHub MCP installed (`.dexCore/core/integrations/github-mcp/install.sh`)
- Authenticated with `gh auth login`
- VS Code with MCP support

### Flow

1. **Detect Last Entry**
   ```
   Identify last modified entry:
   - Read current file (bugs.md, features.md, etc.)
   - Extract latest entry ID and type
   - Example: BUG-011, FEATURE-006
   ```

2. **Determine Branch Name**
   ```
   Branch naming convention:
   - BUG-XXX     → bugfix/BUG-XXX-{slug}
   - FEATURE-XXX → feature/FEATURE-XXX-{slug}
   - DEBT-XXX    → tech-debt/DEBT-XXX-{slug}
   - DESIGN-XXX  → design/DESIGN-XXX-{slug}
   
   Slug = first 3-4 words from entry title (lowercase, hyphens)
   Example: BUG-011 "Dev-Mode Scope..." → bugfix/BUG-011-dev-mode-scope
   ```

3. **Check Working Directory**
   ```bash
   git status --porcelain
   ```
   - If clean: "No changes to push"
   - If dirty: Proceed

4. **Create Branch (if not exists)**
   ```bash
   git checkout -b {branch-name}
   ```
   - If already on branch: Continue
   - If on different branch: Confirm switch

5. **Stage Changed File**
   ```bash
   git add .dexCore/_dev/todos/{file}.md
   ```
   - Auto-detect which file changed (bugs.md, features.md, etc.)

6. **Generate Commit Message**
   ```
   Format:
   {type}({scope}): {action} {entry-id} - {title}
   
   {description}
   
   - Priority: {priority}
   - Tags: {tags}
   - Created: {created}
   ```
   
   Example:
   ```
   feat(dev-mode): Add BUG-011 - Dev-Mode UX improvement
   
   User don't understand Dev-Mode's full potential
   
   - Priority: medium
   - Tags: dev-mode, ux, onboarding
   - Created: 2025-12-22T14:30:00Z
   ```

7. **Commit Changes**
   ```bash
   git commit -m "{message}"
   ```

8. **Push to Origin**
   ```bash
   git push -u origin {branch-name}
   ```

9. **Create Pull Request (Optional)**
   ```
   Ask user: "Create Pull Request? [yes/no]"
   
   If yes:
     - Use GitHub MCP: create_pull_request()
     - Base: main (or current default branch)
     - Title: Same as commit message first line
     - Body: Entry metadata + link to entry
   ```

10. **Confirm & Show Links**
    ```
    ✅ Changes pushed successfully!
    
    📦 Branch: {branch-name}
    📝 Commit: {commit-sha}
    🔗 GitHub: https://your-github-enterprise.example.com/{repo}/tree/{branch-name}
    
    [If PR created]
    🚀 Pull Request: https://your-github-enterprise.example.com/{repo}/pull/{pr-number}
    ```

### Error Handling

**No MCP Connection:**
```
❌ GitHub MCP not available
Please install:
  .dexCore/core/integrations/github-mcp/install.sh
```

**Authentication Failed:**
```
❌ Not authenticated with your-github-enterprise.example.com
Please run:
  gh auth login --hostname your-github-enterprise.example.com
```

**Merge Conflict:**
```
⚠️  Remote branch has changes
Pull first:
  git pull origin {branch-name}
Or force push (not recommended):
  git push -f origin {branch-name}
```

**No Changes:**
```
ℹ️  No changes to push
Working directory is clean.
```

### Advanced Options

User can provide custom commit message:
```
*sync-github "Custom commit message here"
```

Skip PR creation:
```
*sync-github --no-pr
```

Force push (use with caution):
```
*sync-github --force
```

---

