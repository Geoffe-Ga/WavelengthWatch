# Delegation Rules - WavelengthWatch

## Core Delegation Rules

### Rule 1: Scope Reduction

Each delegation reduces scope by one level:

```text
System → Section → Component → Function
```

### Rule 2: Specification Detail

Each level adds more detail:

```text
Strategic goals → Tactical plans → Implementation details → Code
```

### Rule 3: Autonomy Increase

Lower levels have more implementation freedom, less strategic freedom

### Rule 4: Review Responsibility

Each level reviews the work of the level below

### Rule 5: Escalation Path

Issues escalate one level up until resolved

### Rule 6: Horizontal Coordination

Same-level agents coordinate when sharing resources or dependencies (e.g., API contracts)

## When to Delegate

### Delegate Down When

- ✅ Task is too detailed for current level
- ✅ Specific expertise required (SwiftUI, FastAPI, etc.)
- ✅ Work can be parallelized (frontend + backend)
- ✅ Clear specification can be provided

### Escalate Up When

- ⬆️ Decision exceeds your authority
- ⬆️ Resources needed from higher level
- ⬆️ Blocker cannot be resolved at current level
- ⬆️ Conflicts with other same-level agents (e.g., API contract mismatch)

### Coordinate Horizontally When

- ↔️ Sharing API contracts
- ↔️ Dependencies between frontend and backend
- ↔️ Interface negotiation needed
- ↔️ Cross-cutting concerns (security, performance, data models)

## Delegation Patterns

### Pattern 1: Sequential Delegation

```text
Chief Architect
  ↓ defines architecture
  ↓ delegates to Frontend
Frontend Orchestrator
  ↓ implements UI
  ↓ coordinates with Backend for API
Backend Orchestrator
  ↓ implements API
  ↓ reports completion
```

**Use When**: Tasks have strict dependencies (e.g., API must exist before frontend can integrate)

### Pattern 2: Parallel Delegation

```text
Chief Architect
  ├─> Frontend Orchestrator (parallel)
  ├─> Backend Orchestrator (parallel)
  └─> Testing Orchestrator (parallel)
```

**Use When**: Tasks are independent (API contract already defined)

### Pattern 3: Fan-Out/Fan-In

```text
Chief Architect
  ├─> Frontend Orchestrator ─┐
  ├─> Backend Orchestrator ──┼─> Integration Testing
  └─> Testing Orchestrator ──┘
```

**Use When**: Parallel work needs final integration verification

## WavelengthWatch-Specific Delegation

### Language Boundary Coordination

**Chief Architect (Level 0)** decides:
- API contract structure (request/response schemas)
- Data models shared between Swift and Python
- Offline-first architecture patterns
- Sync strategy

**Frontend Orchestrator** implements:
- Swift models matching API schemas
- Service layer for API communication
- Local data persistence (UserDefaults, local DB)
- UI state management

**Backend Orchestrator** implements:
- Pydantic schemas matching API contract
- SQLModel database models
- Validation and business logic
- API endpoints under `/api/v1/`

### Cross-Section Coordination Examples

**Example 1: New Journal Endpoint**

Chief Architect defines:
```json
{
  "endpoint": "POST /api/v1/journal",
  "request": {
    "primary_feeling_id": "int",
    "notes": "string"
  },
  "response": {
    "id": "int",
    "created_at": "datetime"
  }
}
```

Frontend Orchestrator:
- Creates Swift `JournalSubmissionRequest` struct
- Updates `JournalClient` service
- Handles response in ViewModel

Backend Orchestrator:
- Creates `JournalCreate` Pydantic schema
- Implements POST endpoint in `journal.py` router
- Adds SQLModel database model

**Example 2: API Contract Change**

If Backend changes response structure:
1. Backend Orchestrator escalates to Chief Architect
2. Chief Architect evaluates impact on Frontend
3. Chief Architect coordinates with both orchestrators
4. Both update implementations together

## Status Reporting

### Report Frequency

- **On Task Start**: Confirm understanding of requirements
- **On Blocker**: Immediately escalate
- **On Completion**: Report deliverables and next steps

### Report Template

```markdown
## Status Report

**Agent**: [Agent Name]
**Level**: [0 or 1]
**Task**: [Brief description]

### Progress

- [What was completed]

### Blockers

- [None / Description of blocker]

### Next Steps

- [What happens next]
```

## Handoff Protocol

### When Completing Work

1. **Document What Was Done** (files changed, endpoints created)
2. **List Artifacts Produced** (Swift files, Python routers, tests)
3. **Specify Next Steps** for receiving agent or next phase
4. **Note Any Gotchas** (API limitations, test caveats)

### Handoff Template

```markdown
## Task Handoff

**From**: [Your Agent Name]
**To**: [Next Agent Name / Phase]
**Task**: [Description]

**Completed**:
- [What you implemented]

**Artifacts**:
- `frontend/...` - [Swift files]
- `backend/...` - [Python files]
- `tests/...` - [Test files]

**Next Steps**:
- [What should happen next]

**Notes**:
- [Important context, gotchas, or considerations]
```

## Common Coordination Scenarios

### Scenario 1: New Feature Spanning Frontend + Backend

1. **Chief Architect**:
   - Defines feature requirements
   - Designs API contract
   - Delegates to Frontend and Backend orchestrators

2. **Frontend & Backend Orchestrators** (parallel):
   - Implement their respective sides
   - Coordinate on API contract details
   - Report progress to Chief Architect

3. **Testing Orchestrator**:
   - Creates integration tests
   - Verifies end-to-end flow

### Scenario 2: Frontend-Only Change

- **Skip Chief Architect**: Delegate directly to Frontend Orchestrator
- Frontend Orchestrator handles implementation and testing

### Scenario 3: Backend-Only Change (No API Impact)

- **Skip Chief Architect**: Delegate directly to Backend Orchestrator
- Backend Orchestrator handles implementation and testing

### Scenario 4: API Contract Modification

- **Requires Chief Architect**: Coordinate both Frontend and Backend changes
- Update API documentation
- Ensure backward compatibility if needed

## Skip-Level Delegation

**General Rule**: Follow the hierarchy (don't skip levels). However, for trivial tasks, skip-level delegation is acceptable.

### When Skip-Level Is Acceptable

**Simple Bug Fixes** (< 20 lines, well-defined, no design decisions):
- Typos or obvious errors
- Missing imports
- Formatting issues
- Clear, localized fixes

**Process**: Higher-level agent can delegate directly when:
1. No design decisions needed
2. No architectural impact
3. Fix is obvious and unambiguous
4. < 20 lines of code changes

### When Skip-Level Is NOT Acceptable

**Never skip levels for**:
- New features (any size)
- Refactoring (any scope)
- Performance optimization
- Security fixes
- API changes
- Anything requiring judgment or design

**Rule of Thumb**: If it requires thinking beyond "fix the typo", use the full hierarchy.

## See Also

- [hierarchy.md](hierarchy.md) - Visual hierarchy diagram
- [common-constraints.md](../shared/common-constraints.md) - Shared constraints
- [/prompts/claude-comm/delegation-rules-reference.md](../../prompts/claude-comm/delegation-rules-reference.md) - ml-odyssey reference
