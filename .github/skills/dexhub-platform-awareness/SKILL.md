---
name: dexhub-platform-awareness
description: "Platform differences between GitHub Copilot and Claude Code. Use when discussing platform capabilities, limitations, workarounds, or cross-platform strategy."
---

# DexHub Platform Awareness

DexHub runs on two platforms with different capabilities. Understanding these differences prevents false assumptions.

## Platform Comparison

| Capability | GitHub Copilot | Claude Code |
|-----------|---------------|-------------|
| File system access | Via agent mode only | Full access |
| PDF/image reading | No (text-based only) | Yes (multimodal) |
| Session memory | Stateless (no persistence between chats) | Stateless (but DexMemory workaround) |
| Tool execution | Agent mode with approval | Full terminal access |
| Model routing | Via .agent.md `model:` field | Via model selection |
| Skills/knowledge | Lazy-loaded via .github/skills/ | Via CLAUDE.md + .claude/skills/ |
| .agent.md files | Native Copilot Agents | Not used |
| MCP tools | Via Copilot Extensions | Via MCP servers |
| Streaming | Native | Native |
| Context window | Varies by model | Varies by model |

## Copilot Limitations and Workarounds

| Limitation | Workaround |
|-----------|-----------|
| No file read in chat mode | Use agent mode: "@workspace" or agent names |
| No PDF analysis | User pastes text content, or use MCP tools |
| Stateless sessions | DexMemory: Read CONTEXT.md on start, write on save |
| No vision/screenshots | User describes UI or pastes text representation |
| Limited tool use | Skills provide inline knowledge without tool calls |
| No terminal access | Guide user to run commands manually |

## Awareness Levels

1. **Basic Awareness:** Know which platform you are running on
2. **Feature Awareness:** Know what this platform can and cannot do
3. **Adaptation Awareness:** Adjust behavior based on platform capabilities

## Dual-Platform Strategy

DexHub is designed **Copilot-first** but developed in **Claude Code**:
- **Copilot** = Production target (where users work)
- **Claude Code** = Development playground (where we build)
- **Skills** = Cross-platform knowledge (works on both)
- **.agent.md** = Copilot-only (agent routing)
- **CLAUDE.md** = Claude Code-only (orchestration)

## Key Rule

Never assume a feature works on both platforms. If it was only tested in Claude Code, it is UNVALIDATED for Copilot. Always note which platform a feature was tested on.
