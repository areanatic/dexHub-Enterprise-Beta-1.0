#!/bin/bash
# ============================================================================
# migrate-project-structure.sh
# FEATURE-008: Project Structure Standardization Migration Tool
# ============================================================================
#
# Usage: ./migrate-project-structure.sh <project-path> [--dry-run]
#
# This script migrates existing DexHub projects to the FEATURE-008 standard:
#   - Creates INDEX.md if missing
#   - Creates CHANGELOG.md if missing
#   - Creates inputs/ folder with README.md if missing
#   - Removes empty phase folders (anti-pattern)
#
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script location (for finding templates)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="$SCRIPT_DIR/../../dxm/templates/project"

# Arguments
PROJECT_PATH="$1"
DRY_RUN=false

if [[ "$2" == "--dry-run" ]]; then
    DRY_RUN=true
fi

# Validation
if [ -z "$PROJECT_PATH" ]; then
    echo -e "${RED}Error: No project path provided${NC}"
    echo ""
    echo "Usage: ./migrate-project-structure.sh <project-path> [--dry-run]"
    echo ""
    echo "Options:"
    echo "  --dry-run    Preview changes without making them"
    echo ""
    echo "Example:"
    echo "  ./migrate-project-structure.sh myDex/projects/my-project"
    exit 1
fi

# Resolve to absolute path
PROJECT_PATH="$(cd "$PROJECT_PATH" 2>/dev/null && pwd)" || {
    echo -e "${RED}Error: Project path does not exist: $PROJECT_PATH${NC}"
    exit 1
}

PROJECT_NAME=$(basename "$PROJECT_PATH")
DATE=$(date +%Y-%m-%d)

echo ""
echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  FEATURE-008 Migration Tool${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""
echo -e "Project: ${GREEN}$PROJECT_NAME${NC}"
echo -e "Path:    $PROJECT_PATH"
echo -e "Date:    $DATE"
if [ "$DRY_RUN" = true ]; then
    echo -e "Mode:    ${YELLOW}DRY RUN (no changes will be made)${NC}"
fi
echo ""

# ============================================================================
# Check for .dex/ folder
# ============================================================================

echo -e "${BLUE}[1/5] Checking .dex/ structure...${NC}"

if [ ! -d "$PROJECT_PATH/.dex" ]; then
    echo -e "  ${YELLOW}⚠ No .dex/ folder found${NC}"
    if [ "$DRY_RUN" = false ]; then
        echo -e "  ${GREEN}✓ Creating .dex/ folder${NC}"
        mkdir -p "$PROJECT_PATH/.dex"
    else
        echo -e "  ${YELLOW}→ Would create .dex/ folder${NC}"
    fi
else
    echo -e "  ${GREEN}✓ .dex/ folder exists${NC}"
fi

# ============================================================================
# Create INDEX.md if missing
# ============================================================================

echo -e "${BLUE}[2/5] Checking INDEX.md...${NC}"

if [ ! -f "$PROJECT_PATH/.dex/INDEX.md" ]; then
    echo -e "  ${YELLOW}⚠ INDEX.md missing${NC}"

    if [ "$DRY_RUN" = false ]; then
        echo -e "  ${GREEN}✓ Creating INDEX.md${NC}"

        cat > "$PROJECT_PATH/.dex/INDEX.md" << EOF
# Project: $PROJECT_NAME

**Created:** $DATE (migrated)
**Status:** Active
**Type:** DexHub-Native
**Owner:** TBD

---

## Project Vision

> TODO: Add project vision - what does this project achieve?

---

## Product Context

**Problem:** TODO - What problem does this solve?
**Users:** TODO - Who is this for?
**Success:** TODO - How do we know it's done?

---

## Activity Log

### $DATE - Migrated to FEATURE-008 Standard
- INDEX.md created via migration tool
- Project structure standardized
- Next: Fill in Project Vision and Product Context

---

## Knowledge Gaps

- [ ] Define Project Vision
- [ ] Define Product Context (Problem/Users/Success)
- [ ] Review existing project files

---

## Key Files

| File | Purpose | Status |
|------|---------|--------|
| \`.dex/INDEX.md\` | Project dashboard | Active |
| \`.dex/inputs/\` | External inputs | Active |

---

## Notes

This project was migrated to FEATURE-008 standard on $DATE.
Please review and update the Vision and Product Context sections.

---

**Last Updated:** $DATE
EOF
    else
        echo -e "  ${YELLOW}→ Would create INDEX.md${NC}"
    fi
else
    echo -e "  ${GREEN}✓ INDEX.md exists${NC}"
fi

# ============================================================================
# Create CHANGELOG.md if missing
# ============================================================================

echo -e "${BLUE}[3/5] Checking CHANGELOG.md...${NC}"

if [ ! -f "$PROJECT_PATH/.dex/CHANGELOG.md" ]; then
    echo -e "  ${YELLOW}⚠ CHANGELOG.md missing${NC}"

    if [ "$DRY_RUN" = false ]; then
        echo -e "  ${GREEN}✓ Creating CHANGELOG.md${NC}"

        cat > "$PROJECT_PATH/.dex/CHANGELOG.md" << EOF
# Changelog: $PROJECT_NAME

All notable project changes documented here.

Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)

---

## [Unreleased]

### Added
-

### Changed
-

---

## [$DATE] - Migration

### Added
- Migrated to FEATURE-008 standard
- INDEX.md created
- CHANGELOG.md created
- inputs/ folder standardized

### Changed
- Project structure updated to match DexHub standards

---

<!--
CATEGORIES:
- Added: New requirements, features, documents
- Changed: Modifications, scope changes
- Decided: Architecture/technology decisions
- Removed: Deprecated items
- Learned: Insights, mistakes to avoid
- Fixed: Corrections
-->
EOF
    else
        echo -e "  ${YELLOW}→ Would create CHANGELOG.md${NC}"
    fi
else
    echo -e "  ${GREEN}✓ CHANGELOG.md exists${NC}"
fi

# ============================================================================
# Create inputs/ folder if missing
# ============================================================================

echo -e "${BLUE}[4/5] Checking inputs/ folder...${NC}"

if [ ! -d "$PROJECT_PATH/.dex/inputs" ]; then
    echo -e "  ${YELLOW}⚠ inputs/ folder missing${NC}"

    if [ "$DRY_RUN" = false ]; then
        echo -e "  ${GREEN}✓ Creating inputs/ folder${NC}"
        mkdir -p "$PROJECT_PATH/.dex/inputs"

        cat > "$PROJECT_PATH/.dex/inputs/README.md" << EOF
# Project Inputs

External documents and files for $PROJECT_NAME.

---

## Purpose

This folder contains all external inputs for the project:
- PDFs, specifications, requirements documents
- Images, diagrams, screenshots
- Reference materials, research
- Exported data from other systems

---

## Organization

### For Small Projects (<20 files)
Simply place files here. No indexing required.

### For Medium Projects (20-50 files)
Organize into subfolders:
\`\`\`
inputs/
├── requirements/
├── research/
├── media/
└── reference/
\`\`\`

### For Large Projects (>50 files)
Use \`manifest.csv\` for tracking.

---

## Contents

| File | Description | Added |
|------|-------------|-------|
| README.md | This file | $DATE |

---

**Last Updated:** $DATE
EOF
    else
        echo -e "  ${YELLOW}→ Would create inputs/ folder with README.md${NC}"
    fi
else
    echo -e "  ${GREEN}✓ inputs/ folder exists${NC}"

    # Check for README.md in inputs/
    if [ ! -f "$PROJECT_PATH/.dex/inputs/README.md" ]; then
        echo -e "  ${YELLOW}⚠ inputs/README.md missing${NC}"
        if [ "$DRY_RUN" = false ]; then
            echo -e "  ${GREEN}✓ Creating inputs/README.md${NC}"
            # Create README (same as above)
            cat > "$PROJECT_PATH/.dex/inputs/README.md" << EOF
# Project Inputs

External documents and files for $PROJECT_NAME.

---

## Contents

| File | Description | Added |
|------|-------------|-------|
| README.md | This file | $DATE |

---

**Last Updated:** $DATE
EOF
        else
            echo -e "  ${YELLOW}→ Would create inputs/README.md${NC}"
        fi
    fi
fi

# ============================================================================
# Remove empty phase folders (Anti-Pattern)
# ============================================================================

echo -e "${BLUE}[5/5] Checking for empty phase folders...${NC}"

EMPTY_FOLDERS=0
for PHASE in "1-analysis" "2-planning" "3-solutioning" "4-implementation" "session-logs" "config" "agents"; do
    PHASE_PATH="$PROJECT_PATH/.dex/$PHASE"
    if [ -d "$PHASE_PATH" ]; then
        # Check if directory is empty (excluding hidden files)
        if [ -z "$(ls -A "$PHASE_PATH" 2>/dev/null)" ]; then
            EMPTY_FOLDERS=$((EMPTY_FOLDERS + 1))
            echo -e "  ${YELLOW}⚠ Empty folder: $PHASE/${NC}"
            if [ "$DRY_RUN" = false ]; then
                echo -e "  ${GREEN}✓ Removing empty folder: $PHASE/${NC}"
                rmdir "$PHASE_PATH"
            else
                echo -e "  ${YELLOW}→ Would remove empty folder: $PHASE/${NC}"
            fi
        fi
    fi
done

if [ $EMPTY_FOLDERS -eq 0 ]; then
    echo -e "  ${GREEN}✓ No empty phase folders found${NC}"
fi

# ============================================================================
# Summary
# ============================================================================

echo ""
echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  Migration Summary${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}DRY RUN completed. No changes were made.${NC}"
    echo ""
    echo "To apply changes, run without --dry-run:"
    echo "  ./migrate-project-structure.sh $PROJECT_PATH"
else
    echo -e "${GREEN}Migration completed successfully!${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Review and update INDEX.md:"
    echo "     - Fill in Project Vision"
    echo "     - Define Product Context (Problem/Users/Success)"
    echo ""
    echo "  2. Add historical entries to CHANGELOG.md"
    echo ""
    echo "  3. Consider creating PROJECT-AGENT.md if:"
    echo "     - Project has complex domain knowledge"
    echo "     - Multiple stakeholders with political context"
    echo "     - Project should be portable/standalone"
fi

echo ""
echo -e "${BLUE}============================================${NC}"
