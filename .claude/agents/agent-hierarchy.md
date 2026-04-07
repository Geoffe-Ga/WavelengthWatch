# Agent Hierarchy - Complete Specification

## Overview

This document defines the complete 2-level agent hierarchy for the WavelengthWatch project. Each level has
distinct responsibilities, scope, and delegation patterns.

## Hierarchy Diagram

```text
Level 0: Meta-Orchestrator
    │
    ├─> Chief Architect Agent
    │       │
    │       ▼
Level 1: Section Orchestrators
    │
    ├─> Frontend Orchestrator (watchOS SwiftUI)
    ├─> Backend Orchestrator (FastAPI + SQLModel)
    ├─> Testing Orchestrator
    ├─> CI/CD Orchestrator
    └─> Documentation Orchestrator
```

---

## Level 0: Meta-Orchestrator

### Chief Architect Agent

**Scope**: Entire repository ecosystem

**Responsibilities**:
- Plan features that span frontend and backend
- Define repository-wide architectural patterns
- Establish API contracts between watch and backend
- Coordinate across all section orchestrators
- Resolve conflicts between section orchestrators
- Make technology stack decisions
- Monitor overall project health

**Inputs**:
- User requirements
- Feature requests
- GitHub issues
- Project goals

**Outputs**:
- High-level roadmap
- Architectural decision records (ADRs)
- API contract definitions
- Section assignments
- Cross-section dependency coordination

**Delegates To**: Section Orchestrators (Level 1)

**Coordinates With**: External stakeholders, product requirements

**Decision Scope**: System-wide (multiple sections)

**Workflow Phase**: Primarily Plan phase, oversight in all phases

**Configuration File**: `.claude/agents/chief-architect.md`

---

## Level 1: Section Orchestrators

### Frontend Orchestrator

**Scope**: watchOS SwiftUI application

**Responsibilities**:
- Coordinate SwiftUI view development
- Manage ViewModels and state management
- Oversee navigation patterns (TabView, dual-axis scrolling)
- Integrate with backend services via JournalClient and other services
- Ensure watchOS-specific patterns are followed
- Coordinate frontend testing with XCTest

**Delegates To**: Implementation tasks (SwiftUI code, ViewModels, Services)

**Artifacts**: SwiftUI views, ViewModels, Service layer code, frontend tests

**Technologies**:
- Swift 5.9+
- SwiftUI for watchOS
- Combine for reactive patterns
- UserDefaults for local storage
- SQLite for local journal entries

**Configuration File**: `.claude/agents/frontend-orchestrator.md`

### Backend Orchestrator

**Scope**: FastAPI backend service

**Responsibilities**:
- Design and implement API endpoints under `/api/v1/`
- Manage SQLModel database models
- Create Pydantic schemas for validation
- Implement business logic and data processing
- Ensure >90% test coverage
- Coordinate backend testing with pytest

**Delegates To**: Implementation tasks (routers, schemas, models)

**Artifacts**: FastAPI routers, SQLModel models, Pydantic schemas, backend tests

**Technologies**:
- Python 3.11+
- FastAPI for API framework
- SQLModel for ORM
- Pydantic for validation
- SQLite for database
- pytest for testing

**Configuration File**: `.claude/agents/backend-orchestrator.md`

### Testing Orchestrator

**Scope**: Test strategy across frontend and backend

**Responsibilities**:
- Design comprehensive test strategies
- Coordinate >90% backend test coverage
- Plan frontend XCTest suite
- Create integration test plans
- Coordinate manual testing when needed
- Ensure quality gates are met

**Delegates To**: Test implementation tasks

**Artifacts**: Test plans, test cases, coverage reports, quality metrics

**Technologies**:
- pytest (backend)
- XCTest (frontend)
- GitHub Actions for CI testing

**Configuration File**: `.claude/agents/testing-orchestrator.md`

### CI/CD Orchestrator

**Scope**: Continuous integration and deployment

**Responsibilities**:
- Design and maintain GitHub Actions workflows
- Manage pre-commit hooks
- Ensure quality gates are enforced
- Coordinate build automation
- Monitor CI/CD pipeline health

**Delegates To**: Workflow implementation and maintenance

**Artifacts**: GitHub Actions workflows, pre-commit configs, build scripts

**Technologies**:
- GitHub Actions
- pre-commit hooks
- SwiftFormat
- Ruff (Python linter)
- Mypy (Python type checker)

**Configuration File**: `.claude/agents/cicd-orchestrator.md`

### Documentation Orchestrator

**Scope**: Repository documentation

**Responsibilities**:
- Maintain README and setup guides
- Create and update API documentation
- Write architecture documentation
- Document development processes
- Ensure documentation stays current with code changes

**Delegates To**: Documentation writing and updates

**Artifacts**: README files, API docs, architecture docs, process guides

**Technologies**:
- Markdown
- GitHub wiki (if used)
- Code comments and docstrings

**Configuration File**: `.claude/agents/documentation-orchestrator.md`

---

## WavelengthWatch-Specific Patterns

### Offline-First Architecture

**Chief Architect** coordinates:
- Local-first data storage strategy
- Sync strategy with backend
- Conflict resolution patterns

**Frontend Orchestrator** implements:
- Local journal entry storage (SQLite)
- Sync status tracking
- Optimistic UI updates

**Backend Orchestrator** implements:
- Journal sync endpoints
- Conflict detection and resolution

### Dual-Axis Navigation

**Frontend Orchestrator** handles:
- Outer TabView (vertical layers: Strategies, Beige, Purple, etc.)
- Inner TabView (horizontal phases: Rising, Peaking, etc.)
- 90° rotation for vertical scrolling
- Navigation state management

### Journal System Integration

**Chief Architect** defines:
- Journal data model across Swift and Python
- API contract for journal submission
- Local vs cloud storage strategy

**Frontend Orchestrator** implements:
- `LocalJournalEntry` model
- Journal submission UI flow
- Local SQLite storage

**Backend Orchestrator** implements:
- `Journal` SQLModel table
- POST `/api/v1/journal` endpoint
- Hydrated responses with relationships

### Curriculum and Strategy Data

**Chief Architect** coordinates:
- Embedded JSON strategy (offline-first)
- Backend refresh strategy
- Data versioning approach

**Frontend Orchestrator** implements:
- Bundled JSON parsing
- Background refresh from `/api/v1/catalog`
- Data model updates

**Backend Orchestrator** implements:
- `/api/v1/catalog` endpoint
- CSV to JSON conversion (build-time)
- Database seeding from fixtures

---

## Delegation Patterns for WavelengthWatch

### Pattern 1: New Feature Epic (Multi-Section)

```text
Chief Architect
  ├─> Defines feature requirements
  ├─> Designs API contracts
  ├─> Delegates to Frontend Orchestrator
  ├─> Delegates to Backend Orchestrator
  └─> Delegates to Testing Orchestrator
```

**Example**: Multi-step emotion logging flow
- Chief defines: UI flow stages, API submission contract, data models
- Frontend implements: SwiftUI views, ViewModels, service integration
- Backend implements: Journal endpoint, validation, database storage
- Testing verifies: End-to-end flow, edge cases, error handling

### Pattern 2: Frontend-Only Feature

```text
Frontend Orchestrator
  ├─> Implements SwiftUI views
  ├─> Creates ViewModels
  └─> Adds frontend tests
```

**Example**: New animation or UI improvement
- No Chief Architect coordination needed (no backend changes)

### Pattern 3: Backend-Only Enhancement

```text
Backend Orchestrator
  ├─> Implements new endpoint or logic
  ├─> Updates database models
  └─> Adds backend tests
```

**Example**: Performance optimization or new analytics query
- No Chief Architect coordination needed (no API contract change)

### Pattern 4: API Contract Change

```text
Chief Architect
  ├─> Analyzes impact on frontend and backend
  ├─> Coordinates contract update
  ├─> Delegates to Frontend Orchestrator (update models/services)
  ├─> Delegates to Backend Orchestrator (update schemas/endpoints)
  └─> Delegates to Testing Orchestrator (update integration tests)
```

**Example**: Adding new field to journal submission
- Requires coordination to ensure both sides update together

---

## Decision Authority Matrix

| Decision Type | Chief Architect | Section Orchestrator |
|---------------|-----------------|---------------------|
| Feature planning | ✅ Owns | Provides input |
| API contract definition | ✅ Owns | Implements |
| Technology stack | ✅ Owns | Provides expertise |
| Implementation approach | Provides guidance | ✅ Owns |
| Code structure | Provides patterns | ✅ Owns |
| Testing strategy | Provides goals | ✅ Owns details |
| Documentation structure | Provides vision | ✅ Owns execution |

---

## Escalation Paths

### When to Escalate to Chief Architect

**Frontend Orchestrator escalates when**:
- API contract doesn't match needs
- Architectural pattern unclear
- Conflict with backend implementation
- Feature scope ambiguous

**Backend Orchestrator escalates when**:
- API contract change needed
- Database schema migration required
- Performance requires architectural change
- Security concern identified

**Testing Orchestrator escalates when**:
- Quality gates not achievable
- Integration issues across sections
- Test infrastructure changes needed

**CI/CD Orchestrator escalates when**:
- Workflow changes affect multiple sections
- Quality gate definitions needed
- Build process architectural changes

**Documentation Orchestrator escalates when**:
- Documentation structure changes needed
- Cross-section documentation conflicts

---

## Coordination Examples

### Example 1: Journal History Feature

**Chief Architect**:
1. Defines API contract: `GET /api/v1/journal/history?user_id=X&limit=50`
2. Specifies response schema with pagination
3. Delegates implementation

**Frontend Orchestrator**:
- Creates `JournalHistoryView` SwiftUI list
- Updates `JournalClient` with history fetch
- Implements pagination UI

**Backend Orchestrator**:
- Creates `/api/v1/journal/history` endpoint
- Implements pagination logic
- Returns hydrated entries with relationships

**Testing Orchestrator**:
- Tests pagination edge cases
- Verifies frontend-backend integration
- Ensures offline behavior works

### Example 2: Performance Bug (Black Screen Crash)

**Direct to Frontend Orchestrator** (no Chief Architect needed):
- Investigate crash in `ContentView`
- Fix `@StateObject` initialization
- Add regression test
- Report completion

### Example 3: New Sync Strategy

**Chief Architect coordinates**:
- Evaluates current sync limitations
- Designs new sync strategy (incremental vs full)
- Defines sync API contract
- Delegates to orchestrators

**Frontend & Backend Orchestrators**:
- Implement respective sides of sync
- Coordinate on sync protocol details
- Add sync status indicators (frontend)
- Add sync endpoints (backend)

---

## See Also

- [hierarchy.md](hierarchy.md) - Visual hierarchy quick reference
- [delegation-rules.md](delegation-rules.md) - Detailed delegation patterns
- [common-constraints.md](../shared/common-constraints.md) - Shared constraints
- [README.md](../README.md) - Agent system overview
- [/CLAUDE.md](../../CLAUDE.md) - Repository-wide development guidelines
