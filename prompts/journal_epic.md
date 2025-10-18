# Journal Feature Epic Roadmap

This roadmap follows the "Tracer Code" philosophy: every milestone delivers a runnable, testable vertical slice before layering in richer behavior. Tasks flagged **(S)** must be executed in sequence, while tasks flagged **(P)** can be worked on in parallel once their dependencies are satisfied. Each task includes the reasoning behind its inclusion and mandates associated tests.

## Milestone 0 – Discovery & Guardrails

| ID | Task Stub | Mode | Reasoning & Acceptance Tests | Dependencies |
|----|-----------|------|------------------------------|---------------|
| 0.1 | Product requirements alignment workshop | **(S)** | Validate the UX narrative, confirm timer cadence expectations, define notification behavior in watchOS constraints, and agree on backend retention rules. Acceptance: documented decisions in `prompts/journal_requirements.md`. Include unit tests for any assumptions codified in requirements fixtures if applicable. | None |
| 0.2 | Telemetry & privacy threat modeling | **(P)** | Ensures persisted journal data complies with privacy expectations and secure transmission. Acceptance: documented mitigations and added tests (e.g., verifying PII scrubbed from logs). | 0.1 |

## Milestone 1 – Tracer Vertical Slice (End-to-End MVP)

| ID | Task Stub | Mode | Reasoning & Acceptance Tests | Dependencies |
|----|-----------|------|------------------------------|---------------|
| 1.1 | Define journal domain schema (backend SQLModel + migrations placeholder) | **(S)** | Establish `JournalEntry` and `SelfCareSelection` models with required fields (`curriculum_id`, `timestamp`, `initiated_by`, etc.). Tests: SQLModel unit tests verifying field defaults, validation, and serialization. | 0.1 |
| 1.2 | Seed curriculum lookup fixtures with unique identifiers | **(S)** | Guarantee `curriculum_id` references match UX combos by augmenting seed data. Tests: fixture loading test ensuring IDs exist and are stable. | 1.1 |
| 1.3 | Implement minimal journal POST endpoint | **(S)** | Provide FastAPI route storing primary combo with timestamp. Tests: API integration test covering successful create and validation errors. | 1.2 |
| 1.4 | Implement watch app client data service (Tracer) | **(S)** | Create lightweight Swift service hitting the new endpoint with hardcoded combo for now. Tests: unit test with mock network verifying payload structure. | 1.3 |
| 1.5 | Create temporary watch UI prompt | **(S)** | Simple button triggering the service with stub data to prove end-to-end flow. Tests: snapshot/UI test verifying button state and action wiring. | 1.4 |

Deliverable: A developer-triggered journal entry reaches the backend and is persisted, visible through temporary admin inspection script.

## Milestone 2 – Scheduling & Notifications

| ID | Task Stub | Mode | Reasoning & Acceptance Tests | Dependencies |
|----|-----------|------|------------------------------|---------------|
| 2.1 | Scheduling UX exploration & wireframes | **(S)** | Define placement (e.g., 3-dot menu), user flows, and timer edit interactions. Tests: snapshot tests of wireframes if represented as Swift previews; ensures design spec committed. | 1.5 |
| 2.2 | WatchOS schedule storage & settings view | **(P)** | Implement persistent storage for user-configured prompts (e.g., using `UserDefaults` or CoreData). Tests: unit tests verifying CRUD of schedule entries. | 2.1 |
| 2.3 | Notification scheduling service | **(P)** | Build background scheduler aligning with watchOS notification APIs. Tests: integration tests with `UNUserNotificationCenter` mocks verifying triggers fire at configured times. | 2.1 |
| 2.4 | Backend audit endpoint for schedule sync (optional) | **(P)** | If schedule sync to backend is required for analytics, expose endpoint. Tests: API tests ensuring schedule payload validation. | 2.1 |
| 2.5 | End-to-end scheduled notification test plan | **(P)** | QA automation scenario ensuring notifications display and tap-through loads journal flow. Tests: UI test harness simulating notification receipt. | 2.2, 2.3 |

## Milestone 3 – Journal Entry UX Expansion

| ID | Task Stub | Mode | Reasoning & Acceptance Tests | Dependencies |
|----|-----------|------|------------------------------|---------------|
| 3.1 | Layer/Phase/Dosage picker component | **(S)** | Build navigable picker reflecting curriculum hierarchy. Tests: SwiftUI snapshot tests and unit tests for selection state logic. | 1.5 |
| 3.2 | Secondary combo selection UX | **(P)** | Allow optional second selection with reuse of picker component. Tests: ensure data model handles multiple combos and UI toggles. | 3.1 |
| 3.3 | Initiation context capture | **(P)** | Add UI toggle for self-initiated vs. scheduled and ensure backend payload flag. Tests: UI test verifying toggle state, API test verifying field persistence. | 3.1 |
| 3.4 | Timestamp management & time zone handling | **(P)** | Confirm accurate timestamp capture, especially across time zones. Tests: unit tests for date formatting, backend tests ensuring UTC storage. | 3.1 |
| 3.5 | Error states & offline queue | **(P)** | Provide retry flow and offline caching. Tests: unit tests covering queue persistence, integration test verifying replay succeeds. | 3.1 |

## Milestone 4 – Self-Care Strategy Surfacing

| ID | Task Stub | Mode | Reasoning & Acceptance Tests | Dependencies |
|----|-----------|------|------------------------------|---------------|
| 4.1 | Backend self-care lookup endpoint enhancements | **(S)** | Ensure endpoint returns strategies keyed by curriculum phase. Tests: API test verifying data richness and caching. | 3.2, 3.3 |
| 4.2 | Watch UI self-care display view | **(P)** | Show strategies after submission. Tests: snapshot tests verifying layout and accessibility labels. | 4.1 |
| 4.3 | Self-care selection persistence API | **(P)** | Extend backend to accept optional strategy IDs with timestamps. Tests: API integration tests for create and error cases. | 4.1 |
| 4.4 | Watch interaction logging | **(P)** | Allow user to tap strategy and confirm persistence. Tests: UI test verifying dialog flow and network call. | 4.2, 4.3 |

## Milestone 5 – Data Quality & Analytics Readiness

| ID | Task Stub | Mode | Reasoning & Acceptance Tests | Dependencies |
|----|-----------|------|------------------------------|---------------|
| 5.1 | Backend analytics views & queries | **(S)** | Create SQL views or query helpers summarizing entries for future visualization. Tests: unit tests validating aggregations (e.g., frequency by hour). | 4.3 |
| 5.2 | Data export API for visualization team | **(P)** | Provide paginated endpoint exposing journal entries with necessary joins. Tests: API contract tests ensuring fields align with visualization needs. | 5.1 |
| 5.3 | Watch telemetry instrumentation | **(P)** | Emit metrics (success/failure) for journal submissions to aid monitoring. Tests: unit tests verifying telemetry events fire. | 5.1 |

## Milestone 6 – Polish & Hardening

| ID | Task Stub | Mode | Reasoning & Acceptance Tests | Dependencies |
|----|-----------|------|------------------------------|---------------|
| 6.1 | Accessibility & localization audit | **(P)** | Ensure all strings localized and UI accessible. Tests: snapshot tests with dynamic type, localization unit tests ensuring keys exist. | 3.5, 4.2 |
| 6.2 | Security & compliance review | **(P)** | Review data storage, encryption, and consent flows. Tests: automated security scans or linting for secrets. | 5.2 |
| 6.3 | Performance profiling & battery impact test | **(P)** | Evaluate scheduler and networking impact on watch battery. Tests: profiling scripts ensuring thresholds met. | 5.3 |
| 6.4 | Release readiness checklist | **(S)** | Final QA pass, regression tests, documentation updates, and sign-off. Tests: run full CI suite, manual test checklist recorded. | All prior |

## Parallelization Notes

- Tasks marked **(P)** can proceed concurrently once their dependencies are complete. For example, after 2.1, tasks 2.2, 2.3, and 2.4 can run in parallel, accelerating schedule delivery.
- Sequenced tasks **(S)** generally represent tracer-path dependencies or critical design decisions; they intentionally serialize to protect architectural coherence.
- Each milestone should conclude with a demo of completed tracer functionality to maintain visibility and confidence.

## Testing Strategy Summary

- Every task stub explicitly calls out required automated tests; completion criteria must include passing tests in CI.
- Milestones should culminate in a dedicated regression test run covering both backend (`pytest`, linters) and frontend (Swift tests, UI automation).
- Maintain shared fixtures for curriculum IDs so backend/frontend remain synchronized; add contract tests to catch schema drift.

