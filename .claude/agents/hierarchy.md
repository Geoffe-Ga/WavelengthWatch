# Agent Hierarchy - Visual Diagram and Quick Reference

## Hierarchy Diagram

```text
┌─────────────────────────────────────────────────────────────┐
│                    Level 0: Meta-Orchestrator                │
│                   Chief Architect Agent                      │
│      (System-wide decisions, feature planning)               │
└───────────────────────────┬─────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        ▼                   ▼                   ▼
┌──────────────────┐ ┌──────────────────┐ ┌──────────────────┐
│   Level 1:       │ │   Level 1:       │ │    Level 1:      │
│   Frontend       │ │    Backend       │ │    Testing       │
│  Orchestrator    │ │  Orchestrator    │ │  Orchestrator    │
└────────┬─────────┘ └────────┬─────────┘ └────────┬─────────┘
         │                    │                     │
         └────────────────────┼─────────────────────┘
                              ▼
            ┌─────────────────────────────────────┐
            │   Level 1: CI/CD & Documentation    │
            ├─────────────────────────────────────┤
            │  • CI/CD Orchestrator               │
            │  • Documentation Orchestrator       │
            └─────────────────────────────────────┘
```

## Level Summaries

### Level 0: Meta-Orchestrator

- **Agents**: 1 (Chief Architect)
- **Scope**: Entire repository
- **Decisions**: Strategic (feature planning, architecture, tech stack)
- **Phase**: Primarily Plan
- **Language Context**: Coordinates Swift (watchOS) and Python (FastAPI) integration

### Level 1: Section Orchestrators

- **Agents**: 5 (Frontend, Backend, Testing, CI/CD, Documentation)
- **Scope**: Repository sections
- **Decisions**: Tactical (module organization, dependencies, implementation)
- **Phase**: Plan, Implementation, Testing
- **Language Context**:
  - Frontend uses Swift/SwiftUI for watchOS
  - Backend uses Python/FastAPI
  - Testing uses pytest (backend) and XCTest (frontend)

## Agent Count

| Level | Name | Count |
|-------|------|-------|
| 0     | Meta-Orchestrator | 1 |
| 1     | Section Orchestrators | 5 |
| **Total** | **All Agents** | **6** |

## Quick Reference

### When to Use Each Level

**Use Level 0 (Chief Architect)** when:
- Planning new features that span frontend and backend
- Making system-wide architectural decisions
- Resolving cross-section conflicts (e.g., API contract changes)
- Coordinating major initiatives (epics)

**Use Level 1 (Section Orchestrators)** when:
- Implementing frontend features (SwiftUI views, ViewModels)
- Creating backend endpoints (FastAPI routers, SQLModel schemas)
- Designing test strategies (frontend or backend)
- Updating CI/CD pipelines
- Creating or updating documentation

## Coordination Rules

1. **Delegate Down**: When task is too detailed for current level
2. **Escalate Up**: When decision exceeds current authority
3. **Coordinate Laterally**: When sharing resources or dependencies (e.g., API contracts)
4. **Report Status**: Keep superior informed of progress
5. **Document Decisions**: Capture rationale for future reference

## WavelengthWatch-Specific Considerations

### Frontend (watchOS SwiftUI)

**Frontend Orchestrator handles:**
- SwiftUI views and navigation
- ViewModels and state management
- Service layer integration
- UI testing
- watchOS-specific patterns (dual-axis scrolling, complications)

### Backend (FastAPI + SQLModel)

**Backend Orchestrator handles:**
- API endpoints under `/api/v1/`
- SQLModel database models
- Pydantic schemas with validation
- Business logic
- Backend testing with pytest

### Integration Patterns

**Chief Architect coordinates:**
- API contract definitions (request/response schemas)
- Data flow between watch and backend
- Offline-first architecture decisions
- Journal sync strategy

### Testing Strategy

**Testing Orchestrator handles:**
- >90% backend test coverage
- Frontend XCTest suite coordination
- Integration test planning
- Manual testing coordination

## Delegation Flow

### Top-Down (Task Decomposition)

```text
Feature Planning (Level 0)
    ↓
Frontend Implementation (Level 1)
Backend Implementation (Level 1)
Testing Implementation (Level 1)
    ↓
Integration & Deployment
```

### Bottom-Up (Status Reporting)

```text
Implementation Progress (Level 1)
    ↑
Feature Completion (Level 0)
    ↑
Product Readiness
```

## See Also

- [README.md](../README.md) - Agent system overview
- [delegation-rules.md](delegation-rules.md) - Detailed coordination patterns
- [agent-hierarchy.md](agent-hierarchy.md) - Complete detailed specification
- [/prompts/claude-comm/](../../prompts/claude-comm/) - Reference docs from ml-odyssey
