<!-- Claude Code specific tail. Appended to SHARED.md when building .claude/CLAUDE.md. -->

---

## 💾 Memory Bridge Agent (ALPHA - Optional)

**Status:** Alpha feature — may change in future releases

**Purpose:** Cross-session context preservation for complex, multi-session development work

**Note:** This is an experimental feature still being refined. Basic session continuity is handled via `myDex/.dex/config/profile.yaml`.

---

## Claude Code Specific Activation

- Agent delegation uses the **Task tool** with `subagent_type` parameter
- For broad exploration: prefer `subagent_type=Explore`
- For implementation planning: prefer `subagent_type=Plan`
- Subagent results return once per tool call — not visible to user unless relayed

**Ready to start? Say "Hi" to activate the Dex Master!**
