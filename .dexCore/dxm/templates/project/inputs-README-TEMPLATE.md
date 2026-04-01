# Project Inputs

External documents and files for this project.

---

## Purpose

This folder contains all external inputs for the project:
- PDFs, specifications, requirements documents
- Images, diagrams, screenshots
- Reference materials, research
- Exported data from other systems

---

## Organization

### Small Projects (<20 files)
Simply place files here. No indexing required.

### Medium Projects (≥20 files)
Agent creates `manifest.csv` automatically to track files.

### Large Projects (≥50 files)
Agent suggests organizing into subfolders:
```
inputs/
├── requirements/
├── research/
├── media/
└── reference/
```

### Very Large Projects (≥100 files)
Enable Knowledge Base (FEATURE-007) for semantic search.

### Threshold Summary
| Files | Action |
|-------|--------|
| <20 | No indexing required |
| ≥20 | manifest.csv auto-created |
| ≥50 | Subfolders suggested |
| ≥100 | RAG/FEATURE-007 recommended |

### manifest.csv Format
```csv
file,type,category,description,source,created
"spec.pdf","pdf","requirements","Main specification","Confluence","2026-02-20"
```

---

## Contents

| File | Description | Added |
|------|-------------|-------|
| README.md | This file | {{DATE}} |

---

## Import Workflow

1. Drop file here or in `myDex/inbox/`
2. Agent will offer to import and categorize
3. For >20 files, agent maintains `manifest.csv`
4. All imports logged in `../INDEX.md`

---

## Notes

- **Brownfield projects:** Can reference external files instead of copying
- **Large files:** Consider symlinks for files >10MB
- **Sensitive data:** Mark with `[CONFIDENTIAL]` prefix

---

**Last Updated:** {{DATE}}
