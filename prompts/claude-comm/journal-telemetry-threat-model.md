# Journal Telemetry Threat Model

**Last Reviewed:** 2024-07-15

## Scope
- **Assets**: Journal entries (`user_id`, `created_at`, curriculum/strategy identifiers), request metadata, background seeding operations, diagnostic logs.
- **Actors**: Watch app clients, backend maintainers, observability tooling, malicious network observers.
- **Assumptions**:
  - Requests terminate behind HTTPS (FastAPI is deployed behind TLS termination).
  - The pseudo-user identifier on the watch is the only stable identifier persisted for journal events.
  - Backend staff access production logs/metrics via authenticated channels only.

## Data Flow Summary
1. The watch gathers an anonymized pseudo-user identifier and the selected curriculum/strategy context.
2. The client POSTs to `/api/v1/journal` and reads data through the same endpoint family.
3. The FastAPI service validates the payload, persists the event, and returns a hydrated response (joined with curriculum metadata for ease of display).
4. Default Python logging captures startup events and request diagnostics; no third-party telemetry SDKs are present yet.

## Identified Threats & Mitigations
| Threat | Impact | Mitigation | Residual Risk |
| --- | --- | --- | --- |
| **PII leakage via request logs** (user_id + timestamps can re-identify a person when correlated with other data). | Medium | Added a log-record factory + filter that recursively redacts `user_id`, `created_at`, `secondary_curriculum_id`, `notes`, and other user-derived fields before any handler formats the message. Exercised by `tests/backend/test_logging_privacy.py`. | Low – structured logging sanitization covers nested dicts & sequences. |
| **Over-collection of journal content** (future free-form text) being stored without review. | High | Keep schema restricted to structured identifiers only; any future free text must trigger a privacy review and storage justification. Documented in this threat model + backend README guardrail. | Medium – depends on future feature discipline. |
| **Insecure transport during local development** allowing network sniffing. | Low | Development instructions require running behind localhost. Deployment checklist mandates HTTPS termination before exposing the API. | Low |
| **Accidental exposure through analytics exporters** when instrumentation is added later. | Medium | Require new telemetry sinks to consume sanitized log records or structured events that omit identifiers. The logging filter is reusable for exporters. | Medium – enforcement relies on code review. |

## Guardrails for Contributors
- Call `backend.logging_config.configure_logging()` before wiring new background jobs or CLI scripts so sanitization applies consistently.
- Treat any addition of user-written text fields as a schema change requiring a fresh privacy review.
- Prefer aggregation-level metrics (counts, durations) over raw event streams; when detailed traces are needed, rely on redacted identifiers only.

## Validation Checklist
- [x] Unit tests cover recursive redaction and ensure log output never contains raw `user_id`/timestamps.
- [x] Backend README surfaces the privacy controls so future contributors see the guardrails during onboarding.
