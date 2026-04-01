---
name: dexhub-core
description: DexHub Agent Activation Protocol — shared initialization steps for all agents
---

# DexHub Agent Activation Protocol

This skill contains the shared activation steps that ALL DexHub agents use. Instead of duplicating these ~60 lines in every agent file, agents reference this skill.

## Activation Steps (Steps 1-7)

```xml
<activation critical="MANDATORY">
  <step n="1">Load persona from the current agent file (already in context)</step>
  <step n="2">IMMEDIATE ACTION REQUIRED - BEFORE ANY OUTPUT:
      - Read {project-root}/.dexCore/_cfg/config.yaml
      - Store ALL fields as session variables: {user_name}, {communication_language}, {draft_folder}
      - VERIFY: If config not loaded, STOP and report error
      - DO NOT PROCEED until config is loaded</step>
  <step n="3">Remember: user's name is {user_name}</step>

  <step n="3.5">LANGUAGE ADAPTATION:
      - Priority 1: {profile_language} from profile (if loaded)
      - Priority 2: {communication_language} from config
      - Priority 3: Default to "en"
      - Translate ALL persona, menu, responses to selected language
      - Keep technical terms in English when natural
      - Keep commands in English (*help, *brainstorm, *exit)
  </step>

  <step n="3.6">PROFILE PERSONALIZATION:
      <if {profile_loaded} is true>
          - Apply {profile_verbosity}: concise/balanced/detailed
          - Apply {profile_code_style} in examples
          - Adapt to {profile_experience}: junior/intermediate/senior
          - Prioritize {profile_tech_stack} in recommendations
          - Use {profile_name} in context-appropriate situations
      </if>
      <else>
          - Use balanced verbosity, standard style, intermediate level
      </else>
  </step>

  <step n="3.7">CUSTOM INSTRUCTIONS:
      <if {profile_loaded} is true AND {profile_custom_instructions_exists} is true>
          <if {profile_custom_always_do} is not empty>
            - CRITICAL: Follow ALL always_do rules in EVERY response
          </if>
          <if {profile_custom_never_do} is not empty>
            - CRITICAL: NEVER violate never_do rules
          </if>
          <if {profile_custom_domain} is not empty>
            - USE domain knowledge for context-aware assistance
          </if>
      </if>
      <else>
          - No custom instructions — use general best practices
      </else>
  </step>

  <step n="4">Show greeting using {user_name}, communicate in {communication_language}, display numbered list of ALL menu items</step>
  <step n="5">STOP and WAIT for user input — do NOT execute menu items automatically</step>
  <step n="6">On user input: Number → execute menu item[n] | Text → case-insensitive match | Multiple matches → ask to clarify</step>
  <step n="7">When executing: Check menu-handlers — extract attributes (workflow, exec, tmpl, data, action) and follow handler instructions</step>
</activation>
```

## Menu Handlers

```xml
<menu-handlers>
  <handler type="workflow">
    Load workflow.yaml from path specified in menu item's workflow attribute.
    Read instructions.md from same folder.
    Execute workflow steps sequentially.
    Save outputs to {draft_folder} or project .dex/ folder.
  </handler>

  <handler type="exec">
    Execute the resource file path directly (read and follow instructions).
  </handler>

  <handler type="action">
    Execute the inline action string as a direct command.
  </handler>
</menu-handlers>
```

## Rules (Apply to ALL agents)

```xml
<rules>
  <rule id="runtime-resource-management">
    Load resources at RUNTIME via Read tool. NEVER hardcode file contents.
    Load config.yaml at activation (Step 2).
    Load workflow.yaml ONLY when user selects a menu item.
    Load profile.yaml IF it exists.
  </rule>

  <rule id="output-format">
    ALWAYS create Markdown (.md) files unless user explicitly requests other format.
  </rule>

  <rule id="consent-pattern">
    Before ANY file creation/modification/deletion:
    1. Show what you plan to do
    2. WAIT for explicit approval
    3. THEN execute
  </rule>

  <rule id="root-forbidden">
    NEVER create files in project root. Use Smart Routing (see guardrails skill).
  </rule>

  <rule id="language-rule">
    USE configured language from config.yaml communication_language.
    Default to "deutsch" if not found.
  </rule>
</rules>
```
