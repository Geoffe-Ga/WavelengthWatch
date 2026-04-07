# Claude Agent System

This directory contains the agent orchestration system for WavelengthWatch, adapted from the ml-odyssey repository.

## Overview

The agent system provides a hierarchical structure for delegating complex tasks to specialized agents. This ensures focused expertise, clear responsibility boundaries, and efficient collaboration.

## Directory Structure

```
.claude/
├── README.md              # This file
├── agents/                # Agent definitions
│   ├── chief-architect.md           # Level 0: Strategic orchestrator
│   ├── frontend-orchestrator.md     # Level 1: Frontend implementation
│   ├── backend-orchestrator.md      # Level 1: Backend implementation
│   ├── testing-orchestrator.md      # Level 1: Testing strategy
│   ├── cicd-orchestrator.md         # Level 1: CI/CD & automation
│   └── documentation-orchestrator.md # Level 1: Documentation
├── shared/                # Shared constraints and rules
│   ├── common-constraints.md
│   ├── documentation-rules.md
│   └── error-handling.md
├── skills/                # Reusable skills (reserved for future use)
└── commands/              # Custom commands (reserved for future use)
```

## Agent Hierarchy

For detailed hierarchy information, see:
- **[agents/hierarchy.md](agents/hierarchy.md)** - Visual diagram and quick reference
- **[agents/agent-hierarchy.md](agents/agent-hierarchy.md)** - Complete specification with examples
- **[agents/delegation-rules.md](agents/delegation-rules.md)** - Coordination and delegation patterns

### Level 0: Chief Architect
**File:** `agents/chief-architect.md`
**Model:** opus
**Role:** Strategic orchestrator for system-wide decisions

**When to use:**
- Repository-wide architectural decisions
- Cross-section coordination (frontend + backend)
- Feature epic planning
- Technology stack decisions
- Breaking down large initiatives into coordinated tasks

**Delegates to:**
- Frontend Orchestrator
- Backend Orchestrator
- Testing Orchestrator
- CI/CD Orchestrator
- Documentation Orchestrator

### Level 1: Section Orchestrators

#### Frontend Orchestrator
**File:** `agents/frontend-orchestrator.md`
**Model:** sonnet
**Role:** watchOS SwiftUI implementation

**Responsibilities:**
- SwiftUI views and components
- ViewModels and state management
- Navigation patterns
- Service layer integration
- UI testing

#### Backend Orchestrator
**File:** `agents/backend-orchestrator.md`
**Model:** sonnet
**Role:** FastAPI backend implementation

**Responsibilities:**
- API endpoints and routers
- SQLModel database models
- Pydantic schemas
- Business logic
- Backend testing

#### Testing Orchestrator
**File:** `agents/testing-orchestrator.md`
**Model:** sonnet
**Role:** Comprehensive testing strategy

**Responsibilities:**
- Test planning and implementation
- Coverage analysis (>90% backend)
- Manual testing coordination
- Quality gates

#### CI/CD Orchestrator
**File:** `agents/cicd-orchestrator.md`
**Model:** sonnet
**Role:** Pipeline and automation

**Responsibilities:**
- GitHub Actions workflows
- Pre-commit hooks
- Quality gates
- Build automation

#### Documentation Orchestrator
**File:** `agents/documentation-orchestrator.md`
**Model:** sonnet
**Role:** Documentation strategy

**Responsibilities:**
- README and guide maintenance
- API documentation
- Architecture documentation
- Process documentation

## How to Use

### Using the Chief Architect

When you have a large, complex task that spans multiple areas:

```
@chief-architect I need to implement a new feature that allows users to
view their journal history in a SwiftUI list view, backed by a new API
endpoint. Please coordinate the implementation across frontend, backend,
and testing.
```

The chief-architect will:
1. Analyze the requirements
2. Define the architecture and interfaces
3. Break down into subtasks
4. Delegate to appropriate orchestrators
5. Monitor progress and resolve conflicts

### Using Section Orchestrators

When you have a task scoped to a specific area:

```
@frontend-orchestrator Implement the JournalHistoryView SwiftUI component
according to the design in issue #126.
```

```
@backend-orchestrator Create a new /api/v1/journal/history endpoint that
returns paginated journal entries for a user.
```

### Agent Selection Guide

| Task Type | Agent to Use |
|-----------|-------------|
| Large epic spanning multiple areas | chief-architect |
| Frontend UI implementation | frontend-orchestrator |
| Backend API endpoint | backend-orchestrator |
| Test strategy or coverage | testing-orchestrator |
| CI/CD pipeline update | cicd-orchestrator |
| Documentation creation/update | documentation-orchestrator |

## Shared Constraints

All agents follow the constraints defined in `shared/`:

### Common Constraints
- **Minimal changes principle**: Make the smallest change that solves the problem
- **Scope discipline**: Complete assigned task, nothing more
- **No work without issue**: All work must be tracked via GitHub issues

### Documentation Rules
- Never create documentation files unless explicitly requested
- Always prefer editing existing docs to creating new ones
- Keep documentation concise and actionable

### Error Handling
- Fix root causes, not symptoms
- No shortcuts or workarounds
- Never comment out failing tests
- Never use linter bypass comments

## Why This is Gitignored

This `.claude/` directory is copied from the ml-odyssey repository and is NOT checked into version control for WavelengthWatch.

**Reasons:**
1. **Experimental**: Agent system is still evolving
2. **Local tool**: Intended for development workflow, not production code
3. **Easy updates**: Can pull latest from ml-odyssey without conflicts
4. **Repository-specific**: May diverge from ml-odyssey over time

**To update from ml-odyssey:**
```bash
# From WavelengthWatchRoot/
cp -r ../ml-odyssey/.claude/agents/*.md .claude/agents/
cp -r ../ml-odyssey/.claude/shared/*.md .claude/shared/
```

## Examples

### Example 1: Multi-Step Emotion Logging Flow (Epic #92)

**Chief Architect coordinates:**
1. Frontend Orchestrator → Implement SwiftUI flow views
2. Backend Orchestrator → Create journal submission endpoint
3. Testing Orchestrator → Implement integration tests
4. Documentation Orchestrator → Update API docs

### Example 2: Bug Fix (Black screen crash #123)

**Direct to Frontend Orchestrator:**
- No need for chief-architect (single-area task)
- Frontend Orchestrator investigates and fixes the crash
- Testing Orchestrator verifies fix with tests

### Example 3: New Feature (Journal History View)

**Chief Architect coordinates:**
1. Define API contract between frontend/backend
2. Delegate frontend ListView to Frontend Orchestrator
3. Delegate backend pagination endpoint to Backend Orchestrator
4. Delegate tests to Testing Orchestrator
5. Monitor integration and resolve any contract mismatches

## Tips for Effective Use

1. **Start with Chief Architect** for anything touching multiple areas
2. **Use specific orchestrators** for focused, single-area tasks
3. **Reference GitHub issues** - all agents expect issue numbers
4. **Be explicit** about requirements and constraints
5. **Review delegation** - agents will explain their plan before executing

## Future Enhancements

- Custom skills for WavelengthWatch-specific patterns
- Custom commands for common workflows
- Specialist agents for specific tasks (SwiftUI animations, API optimization)
- Integration with GitHub workflows

---

**Source:** Adapted from [ml-odyssey/.claude](../../ml-odyssey/.claude)
**Last Updated:** 2025-12-07
