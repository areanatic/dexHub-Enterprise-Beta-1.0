# DexHub Profile Schema Guide v1.0

**Version:** 1.0
**Date:** 2025-11-16
**Status:** Active
**Audience:** Developers & Power Users

---

## Table of Contents

1. [Overview](#overview)
2. [Quick Start](#quick-start)
3. [Schema Structure](#schema-structure)
4. [Field Reference](#field-reference)
5. [Validation](#validation)
6. [Examples](#examples)
7. [Troubleshooting](#troubleshooting)
8. [Developer Guide](#developer-guide)

---

## Overview

### What is a Profile?

Your **personal profile** (`myDex/.dex/config/profile.yaml`) is the single source of truth for how DexHub agents personalize their interactions with you. It contains:

- **Language preference** (German, English, etc.)
- **Communication style** (concise, balanced, detailed)
- **Technical expertise level** (junior, intermediate, senior, expert)
- **Code style preferences** (Airbnb, Google, Standard)
- **Tech stack** (TypeScript, React, Python, etc.)
- **AI tool experience** (beginner to expert)

### Why Does It Matter?

Without a profile:
- Agents speak English by default
- Responses are "balanced" verbosity
- Code examples use "standard" style
- No tech stack prioritization

With a profile:
- Agents speak **your** language
- Responses match **your** preferred detail level
- Code examples use **your** style guide
- Recommendations prioritize **your** tech stack

### How is it Created?

1. **Onboarding:** Run `myDex` onboarding (SMART: 16 questions, 4-5min OR VOLLSTÄNDIG: 37 questions, 15-18min)
2. **Generation:** `mydex-agent.md` generates `profile.yaml` from your answers
3. **Loading:** All 39 agents load your profile via `workflow.xml` Step 0.5
4. **Personalization:** Agents adapt language, verbosity, code style, content complexity to your preferences

---

## Quick Start

### Creating Your Profile

**Option 1: SMART Onboarding (Recommended for Quick Setup)**
```bash
# Start myDex agent
./dex.sh

# Select: [1] myDex - Personal Developer Experience Manager
# Answer 16 questions (4-5 minutes)
# Profile automatically saved to myDex/.dex/config/profile.yaml
```

**Option 2: VOLLSTÄNDIG Onboarding (Comprehensive)**
```bash
# Same as above, but choose VOLLSTÄNDIG variant
# Answer all 37 questions (15-18 minutes)
# More detailed profile generated
```

**Option 3: Manual Creation**
```bash
# Copy example template
cp myDex/.dex/config/profile.yaml.example myDex/.dex/config/profile.yaml

# Edit manually
nano myDex/.dex/config/profile.yaml

# Validate
python tests/validate_profile_schema.py myDex/.dex/config/profile.yaml
```

### Editing Your Profile

```bash
# Edit profile
nano myDex/.dex/config/profile.yaml

# Validate changes
python tests/validate_profile_schema.py myDex/.dex/config/profile.yaml

# Restart agents to pick up changes
# (or they'll auto-reload on next run via workflow.xml Step 0.5)
```

### Validating Your Profile

```bash
# Validate against schema
python tests/validate_profile_schema.py myDex/.dex/config/profile.yaml

# Expected output:
# ✓ VALID - Profile passes all validation checks
```

---

## Schema Structure

### High-Level Structure

```yaml
version: "1.0"                # Schema version (required)
created_at: "2025-11-16..."   # Timestamp (required)
last_updated: "..."           # Timestamp (optional)

personalization:              # Who you are (required)
  name: "Alex"
  language: "de"
  role: "developer"

technical:                    # Your technical preferences (required)
  experience_level: "senior"
  code_style: "airbnb"
  verbosity: "concise"

tech:                         # Your tech stack (required)
  primary_stack: [...]
  secondary_stack: [...]
  interests: [...]

ai:                           # AI tool experience (required)
  readiness: "advanced"
  copilot_enabled: true
  preferred_model: "claude"

communication:                # Communication preferences (required)
  language_preference: "de"   # Alias for personalization.language
  verbosity: "concise"        # Alias for technical.verbosity
  formality: "professional"

work:                         # Work context (optional)
  company: "Acme Corp"
  team: "Platform Team"
  domain: "web"

custom_instructions:          # Custom rules & context (optional, EA-1.0.1)
  always_do: [...]            # Rules agents must follow
  never_do: [...]             # Rules agents must avoid
  domain_knowledge: "..."     # Project/team context
```

### Section Purposes

| Section | Purpose | Used By |
|---------|---------|---------|
| **personalization** | Who you are, language, role | All agents (greetings, language adaptation) |
| **technical** | Code preferences, verbosity, experience | Code examples, content complexity |
| **tech** | Your tech stack | Recommendations, prioritization |
| **ai** | AI tool experience | Feature complexity, tips |
| **communication** | Communication style | Response tone, formality |
| **work** | Work context (optional) | Future: company/team profiles (V1.3) |
| **custom_instructions** | Your custom rules & context (EA-1.0.1) | All agents (Step 3.7) |

---

## Field Reference

### Personalization Section

#### `personalization.name` (required)
- **Type:** string
- **Example:** `"Alex"`
- **Usage:** Personalized greetings in agents ("Hi Alex, ...")
- **Constraints:** 1-100 characters

#### `personalization.language` (required)
- **Type:** enum
- **Values:** `de`, `en`, `es`, `fr`, `it`, `pt`
- **Default:** `en`
- **Example:** `"de"`
- **Usage:** Primary language for all agent responses
- **Note:** Agents translate persona, menu, responses to this language

#### `personalization.role` (required)
- **Type:** enum
- **Values:** `developer`, `architect`, `product_manager`, `designer`, `analyst`, `student`, `other`
- **Default:** `developer`
- **Example:** `"developer"`
- **Usage:** Role-specific content and recommendations

---

### Technical Section

#### `technical.experience_level` (required)
- **Type:** enum
- **Values:** `junior`, `intermediate`, `senior`, `expert`
- **Default:** `intermediate`
- **Example:** `"senior"`
- **Usage:** Content complexity adaptation
- **Mapping:**
  - 0-2 years → `junior`
  - 3-5 years → `intermediate`
  - 6-10 years → `senior`
  - 10+ years → `expert`

#### `technical.code_style` (required)
- **Type:** enum
- **Values:** `airbnb`, `google`, `standard`, `custom`
- **Default:** `standard`
- **Example:** `"airbnb"`
- **Usage:** Code examples follow this style guide
- **Note:** NEW in EA-1.0 (added via Q38 in onboarding)

#### `technical.verbosity` (required)
- **Type:** enum
- **Values:** `concise`, `balanced`, `detailed`
- **Default:** `balanced`
- **Example:** `"concise"`
- **Usage:** Response length adaptation
- **Note:** NEW in EA-1.0 (added via Q39 in onboarding)

---

### Tech Stack Section

#### `tech.primary_stack` (required)
- **Type:** array of strings
- **Min Items:** 1
- **Max Items:** 10
- **Example:** `["typescript", "react", "nodejs"]`
- **Usage:** Prioritized in recommendations, examples
- **Source:** Q10-Q15 in onboarding

#### `tech.secondary_stack` (optional)
- **Type:** array of strings
- **Max Items:** 10
- **Default:** `[]`
- **Example:** `["python", "docker"]`
- **Usage:** Additional context for recommendations
- **Source:** Q16 in onboarding

#### `tech.interests` (optional)
- **Type:** array of strings
- **Max Items:** 10
- **Default:** `[]`
- **Example:** `["rust", "kubernetes"]`
- **Usage:** Learning path suggestions
- **Source:** Q17 in onboarding

---

### AI Preferences Section

#### `ai.readiness` (required)
- **Type:** enum
- **Values:** `beginner`, `intermediate`, `advanced`, `expert`
- **Default:** `intermediate`
- **Example:** `"advanced"`
- **Usage:** AI feature complexity adaptation
- **Note:** Schema uses simple values (not `ai_experimenting` from old schema)

#### `ai.copilot_enabled` (required)
- **Type:** boolean
- **Default:** `false`
- **Example:** `true`
- **Usage:** Copilot-specific features and tips
- **Source:** Q21 in onboarding

#### `ai.preferred_model` (optional)
- **Type:** enum
- **Values:** `claude`, `gpt4`, `gemini`, `local`, `other`
- **Example:** `"claude"`
- **Usage:** Model-specific guidance
- **Source:** Q22 in onboarding

---

### Communication Section

#### `communication.language_preference` (required)
- **Type:** enum
- **Values:** `de`, `en`, `es`, `fr`, `it`, `pt`
- **Example:** `"de"`
- **Usage:** Alias for `personalization.language`
- **Note:** Kept for backward compatibility

#### `communication.verbosity` (required)
- **Type:** enum
- **Values:** `concise`, `balanced`, `detailed`
- **Example:** `"concise"`
- **Usage:** Alias for `technical.verbosity`
- **Note:** Kept for backward compatibility

#### `communication.formality` (optional)
- **Type:** enum
- **Values:** `casual`, `professional`, `academic`
- **Default:** `professional`
- **Example:** `"professional"`
- **Usage:** Tone adaptation in responses
- **Source:** Q30 in onboarding

---

### Work Context Section (Optional)

#### `work.company` (optional)
- **Type:** string
- **Example:** `"Acme Corp"`
- **Usage:** Company-specific context (future use in V1.3)
- **Note:** Placeholder for multi-tier profiles

#### `work.team` (optional)
- **Type:** string
- **Example:** `"Platform Team"`
- **Usage:** Team-specific context (future use in V1.3)
- **Note:** Placeholder for multi-tier profiles

#### `work.domain` (optional)
- **Type:** enum
- **Values:** `web`, `mobile`, `backend`, `devops`, `data`, `ml`, `embedded`, `other`
- **Example:** `"web"`
- **Usage:** Domain-specific recommendations
- **Source:** Q37 in onboarding

---

### Custom Instructions Section (EA-1.0.1)

**New in EA-1.0.1 (2025-11-17):** User-defined rules and context for AI agents.

#### `custom_instructions.always_do` (optional)
- **Type:** array of strings
- **Min Items:** 0
- **Max Items:** 20
- **Item Max Length:** 200 characters
- **Default:** `[]`
- **Example:** `["Use TypeScript strict mode", "Write tests for all features", "Follow Airbnb style guide"]`
- **Usage:** Rules agents MUST follow in EVERY response (enforced in Step 3.7)
- **Source:** Q40 in onboarding (both SMART and VOLLSTÄNDIG variants)
- **Workflow Variable:** `{profile_custom_always_do}`

#### `custom_instructions.never_do` (optional)
- **Type:** array of strings
- **Min Items:** 0
- **Max Items:** 20
- **Item Max Length:** 200 characters
- **Default:** `[]`
- **Example:** `["Use var keyword", "Commit secrets to git", "Skip code reviews"]`
- **Usage:** Rules agents must NEVER violate (enforced in Step 3.7)
- **Source:** Q41 in onboarding (both SMART and VOLLSTÄNDIG variants)
- **Workflow Variable:** `{profile_custom_never_do}`

#### `custom_instructions.domain_knowledge` (optional)
- **Type:** string (multiline)
- **Max Length:** 2000 characters
- **Default:** `""`
- **Example:**
  ```yaml
  domain_knowledge: |
    E-Commerce Platform for Acme Corp
    Payment processing with Stripe and PayPal
    Microservices architecture with Node.js and React
    Kubernetes deployment on AWS EKS
  ```
- **Usage:** Project/team context agents use for context-aware assistance
- **Source:** Q42 in onboarding (VOLLSTÄNDIG variant only)
- **Workflow Variable:** `{profile_custom_domain}`

**Integration with Agents:**
All 19 conversational agents enforce custom instructions via **Step 3.7** (added in EA-1.0.1):
- Read `always_do` array → Follow ALL rules in EVERY response
- Read `never_do` array → NEVER violate these rules
- Read `domain_knowledge` → Apply project/team-specific context

**Example Agent Step 3.7:**
```xml
<step n="3.7">🎯 CUSTOM INSTRUCTIONS (EA-1.0.1):
  <if {profile_loaded} is true AND {profile_custom_instructions_exists} is true>
      <!-- Always Do Rules -->
      <if {profile_custom_always_do} is not empty>
        - Read {profile_custom_always_do} array
        - CRITICAL: Follow ALL always_do rules in EVERY response
      </if>

      <!-- Never Do Rules -->
      <if {profile_custom_never_do} is not empty>
        - Read {profile_custom_never_do} array
        - CRITICAL: NEVER violate never_do rules
      </if>

      <!-- Domain Knowledge -->
      <if {profile_custom_domain} is not empty>
        - Read {profile_custom_domain} string
        - USE domain knowledge for context-aware assistance
      </if>
  </if>
</step>
```

---

## Validation

### Schema Validator

**Location:** `tests/validate_profile_schema.py`

**Usage:**
```bash
python tests/validate_profile_schema.py <profile-path>
```

**Exit Codes:**
- `0` = Valid profile
- `1` = Invalid profile (validation errors)
- `2` = File not found or parse error

**Example Output (Valid):**
```
======================================================================
Profile Schema Validation Report
======================================================================

Profile: myDex/.dex/config/profile.yaml
Schema:  .dexCore/_dev/schemas/profile-schema-v1.0.yaml
Schema Version: 1.0

✓ VALID - Profile passes all validation checks

======================================================================
```

**Example Output (Invalid):**
```
======================================================================
Profile Schema Validation Report
======================================================================

Profile: myDex/.dex/config/profile.yaml
Schema:  .dexCore/_dev/schemas/profile-schema-v1.0.yaml
Schema Version: 1.0

ERRORS (2):
  1. Missing required field: technical.code_style
  2. Invalid enum value at ai.readiness: 'ai_integrating' (allowed: beginner, intermediate, advanced, expert)

✗ INVALID - Profile failed validation

======================================================================
```

### Validation Rules

**Producer (Onboarding) Validation:**
- MUST validate profile before saving
- MUST fail loudly if validation fails
- MUST log validation errors with field name

**Consumer (Workflow) Validation:**
- MUST validate schema version compatibility (v1.x)
- MUST validate all required fields present
- MUST use defaults for missing optional fields
- SHOULD fail gracefully with warning if validation fails

### Common Validation Errors

#### Missing Required Fields
```
Missing required field: technical.code_style
```
**Fix:** Add the missing field with a valid value from allowed enum

#### Invalid Enum Value
```
Invalid enum value at ai.readiness: 'ai_experimenting' (allowed: beginner, intermediate, advanced, expert)
```
**Fix:** Use one of the allowed values: `beginner`, `intermediate`, `advanced`, `expert`

#### Array Constraints
```
Array tech.primary_stack must have at least 1 items, has 0
```
**Fix:** Add at least one item to the array

#### Version Mismatch (Warning)
```
Profile version '0.9' does not match schema version '1.0'
```
**Fix:** Update `version: "1.0"` in profile

---

## Examples

### Minimal Valid Profile

```yaml
version: "1.0"
created_at: "2025-11-16T12:00:00Z"

personalization:
  name: "Alex"
  language: "en"
  role: "developer"

technical:
  experience_level: "intermediate"
  code_style: "standard"
  verbosity: "balanced"

tech:
  primary_stack: ["javascript"]

ai:
  readiness: "intermediate"
  copilot_enabled: false

communication:
  language_preference: "en"
  verbosity: "balanced"
```

### Complete Profile (All Fields)

```yaml
version: "1.0"
created_at: "2025-11-16T12:00:00Z"
last_updated: "2025-11-16T14:00:00Z"

personalization:
  name: "Alex"
  language: "de"
  role: "developer"

technical:
  experience_level: "senior"
  code_style: "airbnb"
  verbosity: "concise"

tech:
  primary_stack: ["typescript", "react", "nodejs"]
  secondary_stack: ["python", "docker"]
  interests: ["rust", "kubernetes"]

ai:
  readiness: "advanced"
  copilot_enabled: true
  preferred_model: "claude"

communication:
  language_preference: "de"
  verbosity: "concise"
  formality: "professional"

work:
  company: "Acme Corp"
  team: "Platform Team"
  domain: "web"

custom_instructions:
  always_do:
    - "Use TypeScript strict mode"
    - "Write tests for all features"
    - "Follow Airbnb style guide"
  never_do:
    - "Use var keyword"
    - "Commit secrets to git"
    - "Skip code reviews"
  domain_knowledge: |
    E-Commerce Platform for Acme Corp
    Payment processing with Stripe and PayPal
    Microservices architecture with Node.js and React
    Kubernetes deployment on AWS EKS
```

### Profile for German Senior Developer

```yaml
version: "1.0"
created_at: "2025-11-16T10:00:00Z"

personalization:
  name: "Markus"
  language: "de"
  role: "architect"

technical:
  experience_level: "expert"
  code_style: "airbnb"
  verbosity: "detailed"

tech:
  primary_stack: ["java", "spring", "kubernetes"]
  secondary_stack: ["python", "terraform"]
  interests: ["rust", "webassembly"]

ai:
  readiness: "advanced"
  copilot_enabled: true
  preferred_model: "claude"

communication:
  language_preference: "de"
  verbosity: "detailed"
  formality: "professional"

work:
  company: "DHL"
  team: "Platform Engineering"
  domain: "backend"
```

### Profile for Junior Frontend Developer

```yaml
version: "1.0"
created_at: "2025-11-16T09:00:00Z"

personalization:
  name: "Sarah"
  language: "en"
  role: "developer"

technical:
  experience_level: "junior"
  code_style: "standard"
  verbosity: "detailed"

tech:
  primary_stack: ["javascript", "react"]
  interests: ["typescript", "nextjs", "tailwind"]

ai:
  readiness: "beginner"
  copilot_enabled: false

communication:
  language_preference: "en"
  verbosity: "detailed"
  formality: "casual"

work:
  domain: "web"
```

---

## Troubleshooting

### Profile Not Loading

**Symptom:** Agents still use default settings (English, balanced, standard)

**Checks:**
```bash
# 1. Does profile exist?
ls -la myDex/.dex/config/profile.yaml

# 2. Is it valid?
python tests/validate_profile_schema.py myDex/.dex/config/profile.yaml

# 3. Check workflow.xml Step 0.5 logs
# (Look for "Profile loaded: true" or errors)
```

**Common Causes:**
- Profile file missing → Run onboarding or create manually
- Invalid YAML syntax → Check for indentation errors
- Failed validation → Run validator to see specific errors

### Validation Errors

**Symptom:** Validator reports errors

**Steps:**
1. Read error message carefully (shows field and expected format)
2. Fix the field in profile.yaml
3. Re-run validator
4. Repeat until ✓ VALID

**Example:**
```bash
# Error: Missing required field: technical.code_style
# Fix: Add to profile.yaml
technical:
  code_style: "standard"  # or "airbnb" or "google"

# Validate
python tests/validate_profile_schema.py myDex/.dex/config/profile.yaml
```

### Onboarding Doesn't Generate Profile

**Symptom:** Completed onboarding, but no profile.yaml created

**Checks:**
```bash
# 1. Check if onboarding completed
ls -la myDex/.dex/config/

# 2. Check onboarding logs for errors
# (Should show "Profile saved to ...")

# 3. Check permissions
chmod 755 myDex/.dex/config/
```

**Workaround:** Create profile manually from example

### Language Not Working

**Symptom:** Agents still respond in English despite `language: "de"`

**Checks:**
1. Profile loaded? (`{profile_loaded} = true` in workflow.xml)
2. Language field correct? (`personalization.language: "de"`)
3. Agent has Step 3.5 (Language Adaptation)?

**Note:** Not all agents may have full translation coverage. Technical terms may remain in English.

---

## Developer Guide

### Producer (Onboarding) Integration

**File:** `.dexCore/core/agents/mydex-agent.md`

**Steps:**
1. Collect answers from onboarding questions
2. Map answers to schema fields
3. Generate profile.yaml
4. **Validate against schema** (REQUIRED):
   ```bash
   python tests/validate_profile_schema.py myDex/.dex/config/profile.yaml
   ```
5. Only save if validation passes
6. Log validation errors if fails

**Example Code:**
```python
import subprocess

# Generate profile dict
profile = build_profile_from_answers(answers)

# Save to file
save_yaml(profile, "myDex/.dex/config/profile.yaml")

# Validate
result = subprocess.run(
    ["python", "tests/validate_profile_schema.py", "myDex/.dex/config/profile.yaml"],
    capture_output=True
)

if result.returncode != 0:
    log_error("Profile validation failed")
    print(result.stdout.decode())
    # Optionally: Delete invalid profile or use defaults
```

### Consumer (Workflow) Integration

**File:** `.dexCore/core/tasks/workflow.xml`

**Step 0.5:**
```xml
<substep n="0.5.3" title="Load Personal Profile">
  <if exists="{project-root}/myDex/.dex/config/profile.yaml">
    <action>Read personal profile</action>
    <parse_yaml>
      Extract fields per schema:
      - personalization.language → {profile_language}
      - technical.code_style → {profile_code_style}
      - technical.verbosity → {profile_verbosity}
      - technical.experience_level → {profile_experience}
      - tech.primary_stack → {profile_primary_stack}
      - tech.secondary_stack → {profile_secondary_stack}
      - ai.readiness → {profile_ai_readiness}
      - ai.copilot_enabled → {profile_copilot_enabled}
    </parse_yaml>

    <set_variables>
      {profile_loaded} = true
      {profile_language} = personalization.language
      {profile_verbosity} = technical.verbosity
      {profile_code_style} = technical.code_style
      {profile_tech_stack} = primary + secondary
    </set_variables>
  </if>
  <else>
    <set_variables>
      {profile_loaded} = false
      {profile_language} = "en"
      {profile_verbosity} = "balanced"
      {profile_code_style} = "standard"
    </set_variables>
  </else>
</substep>
```

### Agent Integration

**Files:** All 39 agents in `.dexCore/core/agents/`, `.dexCore/dxm/agents/`, `.dexCore/dis/agents/`

**Steps 3.5 & 3.6:**
```xml
<step n="3.5">🌐 LANGUAGE ADAPTATION:
  - Priority 1: {profile_language} from profile
  - Priority 2: {communication_language} from config
  - Priority 3: Default "en"
  - Translate ALL persona, menu, responses
</step>

<step n="3.6">🎯 PROFILE PERSONALIZATION:
  <if {profile_loaded} is true>
    - Apply {profile_verbosity}: concise/balanced/detailed
    - Apply {profile_code_style}: airbnb/google/standard
    - Adapt to {profile_experience}: junior/intermediate/senior/expert
    - Prioritize {profile_tech_stack} in recommendations
  </if>
</step>
```

### Schema Versioning

**Current Version:** 1.0

**Version Compatibility:**
- v1.x → All 1.x versions are backward compatible
- v2.0 → Breaking changes (migration guide provided)

**When to Bump Version:**
- **Patch (1.0 → 1.0.1):** Bug fixes, documentation updates
- **Minor (1.0 → 1.1):** New optional fields, backward compatible
- **Major (1.0 → 2.0):** Breaking changes (rename/remove required fields, change structure)

### Testing

**Integration Test:** `tests/integration/test_profile_integration.sh`

**Steps:**
1. Run onboarding → generate profile.yaml
2. Validate against schema
3. Load in workflow.xml
4. Start agent
5. Verify personalization works (language, verbosity, code style)

**Checklist:**
- [ ] Profile generated from onboarding
- [ ] Profile passes schema validation
- [ ] Workflow loads profile successfully
- [ ] All {profile_*} variables set
- [ ] Agents use profile settings
- [ ] Edge cases tested (missing profile, invalid data)

---

## Related Files

**Schema:**
- `.dexCore/_dev/schemas/profile-schema-v1.0.yaml` - Schema definition

**Validation:**
- `tests/validate_profile_schema.py` - Schema validator

**Producer:**
- `myDex/.dex/config/onboarding-questions.yaml` - Questions
- `.dexCore/core/agents/mydex-agent.md` - Profile generation
- `myDex/.dex/config/profile.yaml.example` - Example template

**Consumer:**
- `.dexCore/core/tasks/workflow.xml` - Profile loading (Step 0.5)
- All 39 agents - Profile personalization (Steps 3.5, 3.6)

**Documentation:**
- `.dexCore/_dev/DEVELOPMENT-QUALITY-STANDARDS.md` - Quality standards
- `.dexCore/_dev/learnings/PROFILE-SCHEMA-MISMATCH-2025-11-16.md` - Incident analysis

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.1 | 2025-11-17 | Added Custom Instructions (always_do, never_do, domain_knowledge) |
| 1.0 | 2025-11-16 | Initial schema creation for EA-1.0 |

---

**Document Status:** ✅ Active
**Last Updated:** 2025-11-17
**Author:** Claude Code + Arash Zamani
**Next Review:** After first user feedback on EA-1.0
