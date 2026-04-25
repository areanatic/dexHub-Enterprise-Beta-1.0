# myDex - Your Personal Workspace

**Your AI-powered developer workspace in DexHub**

---

## What is myDex?

myDex is your **personal layer** in DexHub where you:
- **Create your developer profile** (onboarding)
- **Organize your projects** (automatic structure creation)
- **Store workflow outputs** (before they become projects)
- **Customize your experience** (preferences, language, agent behavior)

**Data-Local**: Your workspace files stay on disk. No automatic cloud sync, no telemetry. Cloud LLMs (Copilot Enterprise, Claude Code) and connectors (Atlassian, GitHub, Figma) are opt-in only when you explicitly configure them.

---

## 🎯 Two Agents, Two Purposes

myDex is powered by **2 specialized agents** that work together:

### 1. myDex Agent - User Profile & Onboarding

**Trigger**: `*mydex` in dex-master menu

**What it does:**
- **First-time onboarding** - Creates your developer profile
- **Profile management** - View, edit, complete your profile
- **Personalization** - Name, language, role, AI-journey, goals

**Onboarding (single canonical flow per 2026-04-25 D4):**
- **5 questions, ~ein Augenblick**
  → Name, language, experience, team size, data-handling policy
  → Q43 data-handling is the P0 enterprise gate
- Optional: extend profile later via `*profile` editing (former VOLLSTÄNDIG-only fields Q40-41 + Q44-49 are reachable post-onboarding)

**Bilingual Support:** Deutsch / English

**Your Profile Lives Here:**
```
myDex/.dex/config/profile.yaml
```

**Example Profile:**
```yaml
version: "1.0"
created_at: "2025-11-13T14:30:00Z"

personalization:
  name: "Alex"
  language: "deutsch"

identity:
  role: "full-stack-developer"
  experience_years: 5
  team_size: "5-10"

ai:
  readiness_level: "advanced"
  tools_used: ["copilot", "chatgpt"]
  skill_goal: "ai_power_user"

workflow:
  biggest_frustration: "context_switching"
  time_lost_weekly: "5-10_hours"

# ... 37 questions total
```

---

### 2. myDex Project Manager - Project Organization

**Triggers:**
- Automatic after workflow completion (suggests project creation)
- Manual via `*projects` in dex-master menu

**What it does:**
- **Auto-detects** when you have 2+ related outputs
- **Suggests project creation** ("Create project from these files?")
- **Creates DXM-aligned structure** (.dex/ with 4 workflow phases)
- **Migrates files** from outputs/ to project folders
- **Manages projects** (list, switch, info)

**Smart Detection Example:**
```
You have 3 documents about "ai-powerpoint":
- brainstorm-ai-powerpoint-20251104-1430.md
- research-ai-powerpoint-20251104-1500.md
- product-brief-ai-powerpoint-20251104-1630.md

Create a project?
→ Better organization
→ Prevents output clutter
→ .dex/ layer for structure
```

**Project Structure Created:**
```
myDex/projects/ai-powerpoint/
├── src/                         ← Your code (empty initially)
└── .dex/                        ← DXM-Aligned meta-layer
    ├── 1-analysis/              ← Phase 1: Analysis
    │   ├── brainstorm/
    │   ├── research/
    │   └── product-brief/
    ├── 2-planning/              ← Phase 2: Planning
    │   ├── prd/
    │   └── gdd/
    ├── 3-solutioning/           ← Phase 3: Solutioning
    │   ├── architecture/
    │   └── tech-spec/
    ├── 4-implementation/        ← Phase 4: Implementation
    │   ├── stories/
    │   └── sprints/
    ├── sessions/                ← Session logs
    ├── decisions/               ← ADRs
    ├── config/                  ← Project config
    ├── agent-state/             ← Agent memory
    └── INDEX.md                 ← Activity log
```

---

## 🚀 Getting Started

### Step 1: First-Time Onboarding

1. Open DexHub (start dex-master)
2. Type `*mydex` or select "myDex" from menu
3. Start onboarding (5 questions, ~ein Augenblick)
4. Answer questions (type "cancel" anytime to stop)
5. Your profile is saved to `.dex/config/profile.yaml`

**First-Time Experience:**
```
👋 Willkommen bei myDex, Alex!

Dies ist dein persönlicher Workspace in DexHub. Lass uns ihn einrichten!

Onboarding starten:
🚀 5 kurze Fragen — direkt loslegen

(Optional: Profil später erweitern via *profile)
```

---

### Step 2: Work on Projects

1. Run workflows via dex-master (e.g., `*workflow brainstorm`)
2. Outputs save to `myDex/drafts/`
3. After 2+ related outputs, myDex Project Manager suggests project creation
4. Accept → Project created with DXM structure
5. Continue workflows → Now saves directly to project!

**User Journey:**
```
[First Time]
→ *mydex (onboarding)
→ Profile created ✅

[Working]
→ Run workflow → myDex/drafts/brainstorm-idea-20251113.md
→ Run workflow → myDex/drafts/research-idea-20251113.md

[Auto-Suggestion]
→ "2 files about 'idea' detected. Create project?" [Yes/No]
→ Yes → myDex/projects/idea/.dex/ created
→ Files migrated to .dex/1-analysis/

[Project Mode]
→ All workflows now save to current project
→ Switch projects: *projects
```

---

## 📂 Directory Structure

```
myDex/
├── .dex/                        ← Your configuration
│   └── config/
│       ├── profile.yaml         ← Your developer profile (from onboarding)
│       ├── preferences.yaml     ← Agent behavior settings
│       └── onboarding-questions.yaml  ← Question database
│
├── outputs/                     ← Draft outputs (before project creation)
│   ├── brainstorm-*.md
│   ├── research-*.md
│   └── product-brief-*.md
│
└── projects/                    ← Your projects
    ├── project-a/               ← DXM-aligned project
    │   ├── src/                 ← Code
    │   └── .dex/                ← Meta-layer (docs, decisions, sessions)
    │
    └── project-b/               ← Another project
        ├── src/
        └── .dex/
```

---

## 🎛️ Commands

### In dex-master menu:

**`*mydex`** - Open myDex Agent
- First time: Onboarding
- Returning: Profile management menu

**`*projects`** - Open myDex Project Manager
- List projects
- Switch projects
- View project info

### In myDex Agent menu:

**`*onboarding`** - Start/resume onboarding
**`*profile`** - View profile summary
**`*projects`** - Manage projects (opens project manager)
**`*outputs`** - View draft outputs
**`*back`** - Return to dex-master

### In myDex Project Manager:

**Automatic triggers:**
- After workflow completion (suggests project if 2+ related files)

**Manual commands:**
- `*project list` - Show all projects
- `*project switch` - Switch to different project
- `*project info` - Current project details

---

## 🔒 Privacy & Safety

### What myDex NEVER does:
- ❌ Auto-create files without consent
- ❌ Auto-delete files without confirmation
- ❌ Send data to cloud
- ❌ Modify config without telling you
- ❌ Share data with third parties

### What myDex ALWAYS does:
- ✅ Ask before creating projects
- ✅ Confirm before migrating files
- ✅ Show what will happen before doing it
- ✅ Allow cancel at any step
- ✅ Keep your working data on disk (LLM + connectors opt-in)
- ✅ Respect your privacy

**User Control:**
- All data in myDex/ is YOURS
- Delete/modify anything manually
- No hidden files, no telemetry
- YAML files = human-readable

---

## 🛠️ Profile Management

### View Your Profile
```bash
cat .dex/config/profile.yaml
```

### Edit Manually
```bash
vim .dex/config/profile.yaml
```

### Restart Onboarding
1. Type `*mydex` in dex-master
2. Select "Onboarding starten/fortsetzen"
3. Onboarding restarts (5 questions, single canonical flow)
4. Existing profile is backed up automatically

### Delete Profile
Delete the file manually:
```bash
rm .dex/config/profile.yaml
```
Next `*mydex` will trigger onboarding again.

---

## 📊 Profile Completion

**Single canonical Onboarding** (5 questions per 2026-04-25 D4):
- Q0 Name
- Q1 Language (de / en / bilingual)
- Q3 Experience level (0-2 / 3-7 / 8-15 / 15+ years)
- Q4 Team size (solo / small / medium / large)
- Q43 Data-handling policy (the P0 enterprise gate: local_only / lan_only / cloud_llm_allowed / hybrid)

**Progressive Enhancement (post-onboarding):**
- Extend profile via `*profile` editing — fields formerly part of VOLLSTÄNDIG variant (Q40-41 + Q44-49) remain reachable
- Profile percentage grows as you fill more fields manually

---

## 🎯 What Makes myDex Different?

### Traditional Dev Setup:
- Generic AI tools (one-size-fits-all)
- Manual project organization
- Scattered outputs (Downloads, Desktop, random folders)
- No personalization

### myDex Approach:
- **Personalized agents** - Know YOUR role, stack, goals
- **Auto-organization** - Suggests projects when outputs pile up
- **DXM-aligned structure** - Professional workflow phases
- **Profile-driven** - Agents adapt to YOUR experience level
- **Data-local** - working data on disk, you control the LLM + connectors

---

## 🌟 Coming in V2

- **Team.dex** - Shared knowledge layer (team profiles, templates)
- **DexHub Hub** - Community marketplace (share custom agents)
- **Agent customization** - Enable/disable agents, set preferences
- **Cross-project** - App-Space for shared assets
- **Guardian integration** - Enterprise governance controls

---

## 📚 Learn More

**Documentation:**
- Agent specs: `.dexCore/core/agents/mydex-agent.md`
- Project manager: `.dexCore/core/agents/mydex-project-manager.md`
- Decision doc: `docs/decisions/DECISION-AGENT-COUNT-39-FINAL.md`

**Questions database:**
- All 37 questions: `.dex/config/onboarding-questions.yaml`
- Profile schema: `.dex/config/profile.yaml.example`

**Implementation pattern:**
- Template-Filling Agent Pattern V1.0
- Docs: `.claude/learnings/template-filling-agent-pattern-v1.md`

---

**Your workspace. Your control. Your way.** 🏠
