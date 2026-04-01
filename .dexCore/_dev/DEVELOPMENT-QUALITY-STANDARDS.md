# DexHub Development Quality Standards

**Version:** 1.0
**Date:** 2025-11-16
**Status:** MANDATORY
**Applicability:** All DexHub development work

---

## PURPOSE

This document defines **MANDATORY** quality standards for DexHub development to ensure:
- Code quality and reliability
- Integration correctness
- Cross-session continuity
- Prevention of schema mismatches and integration failures

**"5000% muss es ordentlich sitzen"** - Quality is absolute priority.

---

## CORE PRINCIPLES

### 1. Schema-First Development

**RULE:** Define schema BEFORE implementing producer OR consumer.

**Process:**
```
WRONG ❌:
Producer implementation → Output → Consumer implementation → Hope they match

CORRECT ✅:
Schema Definition → Producer implements → Consumer implements → Integration test validates
```

**For DexHub:**
- Profile schema: `.dexCore/_dev/schemas/profile-schema-v1.0.yaml` (single source of truth)
- API contracts: `.dexCore/_dev/schemas/api-contracts/`
- Agent interfaces: `.dexCore/_dev/schemas/agent-interfaces/`

**Enforcement:**
- [ ] Schema file MUST exist before any implementation
- [ ] Schema MUST be versioned (v1.0, v1.1, etc.)
- [ ] Both producer and consumer MUST reference same schema version
- [ ] Breaking changes REQUIRE version bump

**Reference:** `~/.claude/learnings/schema-first-development.md`

---

### 2. Producer-Consumer Contracts

**RULE:** Explicit contract with validation on both sides.

**Contract Components:**
```yaml
contract:
  producer: "Component A (file.md)"
  produces: "path/to/output.yaml"

  consumer: "Component B (file.xml)"
  consumes: "Variables {var_*}"

  validation:
    - Producer validates output against schema
    - Consumer validates input against schema
    - Integration test validates end-to-end
```

**For DexHub:**
- myDex Onboarding → profile.yaml → workflow.xml
- Agent → workflow.xml → Session variables
- Config files → Agents → User experience

**Enforcement:**
- [ ] Producer MUST validate before saving
- [ ] Consumer MUST validate on load
- [ ] Both MUST fail loudly with clear error messages
- [ ] Schema version MUST be checked

**Reference:** `~/.claude/learnings/producer-consumer-contract.md`

---

### 3. Integration Testing is MANDATORY

**RULE:** Integration tests REQUIRED before marking work "complete".

**Test Types:**

1. **Component Integration** (many, fast):
   - Producer → Consumer
   - File Writer → File Reader
   - API Client → API Server

2. **Subsystem Integration** (some, slower):
   - Onboarding → Profile → Workflow → Agent
   - Auth → API → Database

3. **End-to-End** (few, slowest):
   - User action → Full system → Result

**For DexHub:**
```bash
tests/
├── unit/                    # Fast, isolated
│   ├── test_onboarding.py
│   └── test_workflow.py
├── integration/             # Real components together
│   ├── test_profile_integration.sh
│   ├── test_agent_personalization.sh
│   └── test_workflow_loading.sh
└── e2e/                     # Full system
    └── test_user_journey.sh
```

**Enforcement:**
- [ ] Integration test MUST exist before "complete" status
- [ ] Test MUST use ACTUAL components (no mocks at boundaries)
- [ ] Test MUST validate ALL integration points
- [ ] Test MUST cover edge cases (missing data, invalid formats)
- [ ] CI/CD MUST run integration tests on every commit

**Reference:** `~/.claude/learnings/integration-testing-mandatory.md`

---

### 4. Definition of Done

**RULE:** "Complete" means VALIDATED, not just written.

**OLD Definition (WRONG) ❌:**
```
✅ Code written
✅ Committed
= "Complete"
```

**NEW Definition (CORRECT) ✅:**
```
✅ Code written
✅ Self-reviewed (critical read of own code)
✅ Unit tests pass
✅ Integration tests pass
✅ Manual verification performed
✅ Edge cases tested
✅ Documentation updated
✅ Peer reviewed (if applicable)
= "Complete"
```

**For DexHub:**
- Feature: All 8 checkboxes required
- Bug fix: Root cause identified, test added, verified
- Refactoring: All tests pass, no behavior changes
- Documentation: Accurate, complete, reviewed by non-expert

**Enforcement:**
- [ ] NO commit without passing tests
- [ ] NO "complete" without manual verification
- [ ] NO merge without integration test
- [ ] NO assumptions - verify files exist

**Reference:** `~/.claude/learnings/definition-of-done.md`

---

### 5. Trust But Verify

**RULE:** Verify file existence programmatically, never assume.

**Anti-Pattern ❌:**
```xml
<!-- SCHEMA: .dexCore/_dev/schemas/profile.yaml (exists from myDex onboarding) -->
```
**Problem:** File doesn't exist, but comment implies it does.

**Correct Pattern ✅:**
```python
# Verify schema exists
schema_path = ".dexCore/_dev/schemas/profile-schema-v1.0.yaml"
if not os.path.exists(schema_path):
    raise FileNotFoundError(f"Schema file missing: {schema_path}")

# Then use it
validator.validate(schema_path)
```

**For DexHub:**
- [ ] Remove aspirational comments
- [ ] Add pre-flight file existence checks
- [ ] Fail fast if dependencies missing
- [ ] Log what was expected vs what exists

**Reference:** `~/.claude/learnings/trust-but-verify.md`

---

### 6. Cross-Session Continuity

**RULE:** Context MUST transfer between sessions.

**Process:**

**Before Ending Session:**
1. Save critical decisions to `.dexCore/_dev/CRITICAL-DECISIONS.md`
2. Update `.claude/session-registry.json` with session summary
3. Document assumptions made during session
4. List files created/modified
5. Note pending work and dependencies

**When Starting Session:**
1. Review previous session summary
2. Read CRITICAL-DECISIONS.md
3. Verify assumptions still valid
4. Check for changes in dependencies
5. Understand context before proceeding

**For DexHub:**
- Session logs: `.claude/sessions/{topic}-{date}.md`
- Critical decisions: `.dexCore/_dev/CRITICAL-DECISIONS.md`
- Memory Bridge: For complex multi-session work
- Session Registry: `.claude/session-registry.json`

**Reference:** `~/.claude/learnings/cross-session-continuity.md`

---

## MANDATORY CHECKLISTS

### Before Starting Work

**Planning Phase:**
- [ ] Requirements are clear and documented
- [ ] Schema defined (if data crosses boundaries)
- [ ] Integration points identified
- [ ] Test strategy planned
- [ ] Definition of done agreed upon

**Context Review (if continuing work):**
- [ ] Reviewed previous session summary
- [ ] Read CRITICAL-DECISIONS.md
- [ ] Verified assumptions still valid
- [ ] Checked for dependency changes
- [ ] Understand full context

---

### During Development

**For Every Code Change:**
- [ ] Code written
- [ ] Self-reviewed (critical read)
- [ ] Assumptions documented
- [ ] Tests written alongside code
- [ ] No security vulnerabilities introduced

**For Schema Changes:**
- [ ] Schema file updated FIRST
- [ ] Version bumped if breaking change
- [ ] All producers updated
- [ ] All consumers updated
- [ ] Integration tests updated

**For Integration Points:**
- [ ] Contract explicitly defined
- [ ] Producer validates output
- [ ] Consumer validates input
- [ ] Integration test exists
- [ ] Edge cases covered

---

### Before Marking "Done"

**Self-Review Checkpoint:**
- [ ] Read code as if reviewing someone else's
- [ ] Question every assumption
- [ ] Check for edge cases
- [ ] Verify no copy-paste errors
- [ ] Remove debug code and TODOs

**Testing Checkpoint:**
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual verification performed
- [ ] Edge cases tested
- [ ] Error cases handled

**Documentation Checkpoint:**
- [ ] Code comments (why, not what)
- [ ] README updated
- [ ] API docs updated
- [ ] Breaking changes noted
- [ ] Migration path documented (if applicable)

**Validation Checkpoint:**
- [ ] Runs in clean environment
- [ ] Works with real data
- [ ] No hardcoded values
- [ ] Configuration documented
- [ ] File dependencies verified

---

### Before Committing

**Quality Gate 1: Self-Review**
- [ ] Read your own code critically
- [ ] Question every assumption made
- [ ] Test edge cases manually
- [ ] Fix what you find

**Quality Gate 2: Automated Tests**
- [ ] All unit tests pass
- [ ] All integration tests pass
- [ ] Linters pass
- [ ] Build succeeds

**Quality Gate 3: Manual Verification**
- [ ] Run it yourself
- [ ] Test with real data
- [ ] Try to break it
- [ ] Document findings

**Quality Gate 4: Files Verified**
- [ ] All referenced files exist
- [ ] No aspirational comments
- [ ] Schema versions match
- [ ] Dependencies available

---

### Before Merging

**Integration Verification:**
- [ ] Integration tests pass on target branch
- [ ] No conflicts with main
- [ ] All related components updated
- [ ] System works end-to-end

**Peer Review (if applicable):**
- [ ] Another developer reviewed
- [ ] Feedback addressed
- [ ] Re-tested after changes
- [ ] Both approve

---

### Before Ending Session

**Context Preservation:**
- [ ] Session summary written
- [ ] Critical decisions documented
- [ ] Assumptions recorded
- [ ] Pending work listed
- [ ] Dependencies noted

**Quality Verification:**
- [ ] All commits have clear messages
- [ ] No work-in-progress left uncommitted
- [ ] Tests still passing
- [ ] Documentation up-to-date

---

## ANTI-PATTERNS TO AVOID

### ❌ "Ship it, we'll fix bugs later"
**Problem:** Bugs are expensive to fix later, user trust damaged, technical debt accumulates

**Solution:** Fix it right the first time

---

### ❌ "Tests are slowing me down"
**Problem:** Untested code = broken code, debug time >> test time

**Solution:** Test while developing, not after

---

### ❌ "Documentation can wait"
**Problem:** You'll forget why you did it, others can't understand it

**Solution:** Document as you go

---

### ❌ "It works on my machine"
**Problem:** Different environment = different bugs, missing dependencies

**Solution:** Test in clean environment

---

### ❌ "We'll define the schema later"
**Problem:** Results in mismatched implementations, refactoring harder than getting it right first

**Solution:** Schema-First Development (ALWAYS)

---

### ❌ "The other team knows what we need"
**Problem:** Assumptions lead to mismatches, different mental models

**Solution:** Explicit schema both sides commit to

---

### ❌ "We'll integration test later"
**Problem:** Later = when it's already broken, harder to debug after both sides "complete"

**Solution:** Integration test BEFORE marking complete

---

### ❌ "Comments are documentation"
**Problem:** Comments aren't validated, get out of sync with code

**Solution:** Actual schema files that are validated

---

### ❌ "Trust the producer"
**Problem:** Producer bugs happen, schema can drift

**Solution:** Consumer validates even if producer does

---

## ENFORCEMENT

### Code Review Requirements

**Every commit MUST:**
- Have passing unit tests
- Have passing integration tests (if applicable)
- Follow schema-first if data crosses boundaries
- Include updated documentation
- Have clear commit message

**Reviewers MUST verify:**
- [ ] All quality gates passed
- [ ] Integration tests exist and pass
- [ ] Schema versions match (if applicable)
- [ ] No assumptions without verification
- [ ] Edge cases covered

### CI/CD Pipeline

**Every push MUST trigger:**
1. Linting (ESLint, Prettier)
2. Unit tests
3. Integration tests
4. Schema validation
5. Build verification

**Merge blocked if:**
- Any test fails
- Linting errors exist
- Schema validation fails
- Integration tests missing

### Definition of "Complete"

**Work is NOT complete until:**
- ✅ Code written and reviewed
- ✅ All tests pass (unit + integration)
- ✅ Manual verification performed
- ✅ Edge cases tested
- ✅ Documentation updated
- ✅ Peer reviewed (if applicable)
- ✅ Quality gates passed

**Only then:** Mark as "Complete" and commit.

---

## LESSONS FROM INCIDENTS

### Profile Schema Mismatch (2025-11-16)

**What Happened:**
- Onboarding created profile.yaml with 8-category schema
- workflow.xml expected different field structure
- Only 18% field match (2 of 11 fields)
- Would have caused 100% integration failure

**Root Causes:**
1. No schema-first development
2. Independent development without coordination
3. Assumptions instead of verification
4. No integration testing
5. Time pressure influenced decisions

**Prevention:**
- ✅ Schema-First Development (MANDATORY)
- ✅ Producer-Consumer Contract with validation
- ✅ Integration tests REQUIRED
- ✅ Cross-session continuity tools
- ✅ Trust but verify (no assumptions)
- ✅ "Complete" = validated, not just written

**Detailed Analysis:** `.dexCore/_dev/learnings/PROFILE-SCHEMA-MISMATCH-2025-11-16.md`

---

## QUALITY STANDARDS SUMMARY

### The Golden Rules

1. **Schema-First**: Define schema BEFORE implementation
2. **Contract-Based**: Explicit contracts with validation
3. **Test-Driven**: Integration tests are MANDATORY
4. **Verify Everything**: Trust but verify (no assumptions)
5. **Complete = Validated**: Not just written, but tested
6. **Context Preserved**: Cross-session continuity required

### The Quality Equation

```
Quality = Code + Tests + Validation + Documentation + Review
```

**Not:**
```
Quality = Code + "Hope it works"
```

### The Time Equation

```
Time (proper) = Planning + Implementation + Testing + Review
Time (rework) = Implementation + Debug + Fix + Re-test + Re-review

Time (proper) < Time (rework)
```

**"5000% muss es ordentlich sitzen"** means:
- Quality over speed
- Validation over assumptions
- Testing over hoping
- Documentation over memory

---

## RELATED DOCUMENTATION

**Universal Patterns:**
- `~/.claude/learnings/schema-first-development.md`
- `~/.claude/learnings/producer-consumer-contract.md`
- `~/.claude/learnings/integration-testing-mandatory.md`
- `~/.claude/learnings/cross-session-continuity.md`
- `~/.claude/learnings/trust-but-verify.md`
- `~/.claude/learnings/definition-of-done.md`

**DexHub Specific:**
- `.dexCore/_dev/learnings/PROFILE-SCHEMA-MISMATCH-2025-11-16.md` (root cause analysis)
- `.dexCore/_dev/schemas/` (schema files)
- `tests/integration/` (integration test suite)

---

## REVISION HISTORY

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2025-11-16 | Initial creation after Profile Schema Mismatch incident | Claude Code + Arash Zamani |

---

**Document Status:** ✅ ACTIVE
**Next Review:** After first major feature using these standards
**Feedback:** Report issues or improvements to project lead
