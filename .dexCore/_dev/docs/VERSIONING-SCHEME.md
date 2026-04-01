# DexHub Versioning Scheme

**Last Updated:** 2025-11-13
**Status:** Official Standard

---

## Overview

DexHub uses **three separate versioning systems** for different purposes. This document clarifies the relationship between them to prevent confusion.

---

## 1. Product Version (User-Facing)

**Current:** Enterprise Alpha 1.0 (EA-1.0)

**Format:** `ea-MAJOR.MINOR`

**Purpose:**
- External user communication
- GitHub releases and tags
- Documentation badges
- Marketing materials

**Where Used:**
- `/README.md` - Badges and version references
- `/.version` - Single source of truth file
- `/.dexCore/_cfg/config.yaml` - System configuration
- `/myDex/.dex/config/profile.yaml` - User profile
- `/CONTRIBUTING.md` - Contributor guidelines

**Audience:**
- External users
- Gilde community
- Enterprise partners
- Contributors

**Version History:**
- EA-1.0 (2025-11-13): Initial Enterprise Alpha Release

**Future Progression:**
- EA-1.0 → EA-1.1 (minor features)
- EA-1.X → EA-2.0 (major breaking changes)

---

## 2. Architecture Version (Internal)

**Current:** V3.1 (SILO Structure)

**Format:** `V<number>.<number>`

**Purpose:**
- Document internal architecture evolution
- Track SILO structure iterations
- Development team reference

**Where Used:**
- `/.dexCore/_dev/docs/SILO-ARCHITECTURE.md`
- Internal development documentation
- Architecture Decision Records (ADRs)

**Audience:**
- Internal development team ONLY
- Never exposed to external users

**Version History:**
- V1.0: Initial SILO concept
- V2.0: Activity-Based structure (deprecated)
- V3.0: DXM-Aligned structure
- V3.1: Extended workflow mapping (current)

---

## 3. Development Branches

**Current:** feature/EX-1 (preparing EX-2 release)

**Format:** `feature/EX-<number>`

**Purpose:**
- Experimental feature development
- Pre-release testing
- Internal development workflow

**Where Used:**
- Git branches
- Internal todos and planning docs
- Development session tracking

**Audience:**
- Internal development team ONLY

**Branch History:**
- EX-1: Silo Architecture Enforcement (complete)
- EX-2: Enterprise Alpha 1.0 Release (current)

---

## Version Relationship Matrix

| Product Version | Architecture Version | Dev Branch | Status |
|-----------------|---------------------|------------|--------|
| EA-1.0 | V3.1 | feature/EX-1 → EX-2 | Current |

**Translation:**
- External users see: "Enterprise Alpha 1.0"
- Internal docs reference: "V3.1 SILO Architecture"
- Development happens on: "feature/EX-2" branch

---

## Critical Rules

### ✅ DO:
- Use EA-1.0 in ALL user-facing documentation
- Reference V3.1 in internal architecture docs WITH context banner
- Keep development branch names internal

### ❌ DON'T:
- Mix version schemes in user-facing docs
- Expose "V3.1" to external users without context
- Use "EX-1" or "EX-2" in public documentation
- Reference internal versions in README or tutorials

---

## Version Bumping Process

### Product Version (EA-X.Y)

**When to bump MAJOR (ea-1.0 → ea-2.0):**
- Breaking changes to agent APIs
- Major architecture restructuring
- Incompatible configuration changes

**When to bump MINOR (ea-1.0 → ea-1.1):**
- New agent features
- New workflows
- Non-breaking improvements
- Bug fixes and optimizations

**Process:**
1. Update `/.version` file
2. Update README badges
3. Update config.yaml files
4. Create git tag: `git tag ea-1.1`
5. Update VERSION-MANAGEMENT.md history

### Architecture Version (V3.X)

**Only updated when:**
- SILO structure fundamentally changes
- Output routing logic evolves
- Phase methodology changes

**Process:**
1. Update SILO-ARCHITECTURE.md header
2. Document changes in version history section
3. Update version context banner

---

## FAQ

**Q: Why "EA-1.0" and not "v1.0"?**
A: "Enterprise Alpha" signals both the maturity level (alpha) and target audience (enterprise/community). The "EA-" prefix distinguishes from previous v1.x releases on GitHub.

**Q: Will EA-1.0 become v1.0 eventually?**
A: No. When we exit alpha, it will be EA-2.0 or later. The "EA-" prefix stays throughout the alpha phase.

**Q: What happened to v1.1.5?**
A: That was the internal development version. EA-1.0 is a fresh start for external users.

**Q: Why keep V3.1 in SILO-ARCHITECTURE.md?**
A: It accurately documents the architecture evolution for developers. The context banner prevents user confusion.

---

## Maintenance

This document should be updated whenever:
- Product version bumps (EA-1.0 → EA-1.1)
- Architecture version changes (V3.1 → V3.2 or V4.0)
- New versioning rules are established
- Version scheme changes (e.g., exiting alpha phase)

**Document Owner:** Development Team
**Review Frequency:** Every major release

---

*This versioning scheme effective as of Enterprise Alpha 1.0 (2025-11-13)*
