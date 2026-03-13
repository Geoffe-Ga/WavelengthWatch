---
name: file-naming-conventions
description: >-
  ISO 8601 date-prefix file naming conventions for documents and plans.
  Use when creating dated documents, plan files, analysis reports,
  or any time-sensitive documentation.
  Do NOT use for source code files, configs, or permanent reference docs.
metadata:
  author: Geoff
  version: 1.0.0
---

# File Naming Conventions

Always prefix dated documents with ISO 8601 format (YYYY-MM-DD) for natural chronological sorting.

## Instructions

### Step 1: Determine if the Document Needs a Date Prefix

**Use date prefixes for**: analysis reports, status reports, plans, RCAs, meeting notes, decision records, progress updates, backlog grooming results.

**Skip date prefixes for**: README.md, CLAUDE.md, source code, test files, configs, templates.

### Step 2: Construct the Filename

**Format**: `YYYY-MM-DD_DESCRIPTIVE_NAME.ext`

- Date: 4-digit year, 2-digit month, 2-digit day, separated by hyphens
- Separator: Single underscore between date and description
- Name: ALL_CAPS for major documents, lowercase_with_underscores for supporting docs
- Store in `prompts/claude-comm/` for coordination documents

### Step 3: Handle Special Cases

**Multiple documents same day**: Use descriptive disambiguation:
```
2026-03-13_RCA_ISSUE_295.md
2026-03-13_BACKLOG_GROOMING.md
```

**Versioned documents**: `YYYY-MM-DD_DOCUMENT_NAME_vX.Y.md`

## Examples

### Example 1: Plan and Analysis Files
```
prompts/claude-comm/2026-03-13_LIQUID_GLASS_PHASE_1B_PLAN.md
prompts/claude-comm/2026-03-13_BACKLOG_GROOMING.md
prompts/claude-comm/2026-03-10_RCA_ISSUE_295.md
```

### Example 2: Quick Creation
```bash
DATE=$(date +%Y-%m-%d)
touch "prompts/claude-comm/${DATE}_MY_DOCUMENT.md"
```
