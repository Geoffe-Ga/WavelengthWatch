# WavelengthWatch Backend

FastAPI + SQLModel service that exposes CRUD APIs for curriculum, layer, phase, strategy, and journal data. The app seeds a SQLite database from curated CSV fixtures on first startup.

## Prerequisites

- Python 3.12+
- `pip`

## Installation

```bash
python -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r backend/requirements.txt
pip install -r backend/requirements-dev.txt
```

## Running the API

```bash
cd backend
python -m uvicorn app:app --reload
```

Alternatively, from the repository root:

```bash
python -m uvicorn backend.app:app --reload
```

The service reads `DATABASE_URL`; if unset it defaults to `sqlite:///./app.db`. On startup it creates tables and seeds them from the embedded CSV constants when tables are empty. You can re-run the seeding script manually:

```bash
python -m backend.tools.seed_data
```

(Ensure the environment variable `DATABASE_URL` is set before running the script to target a specific database.)

## Configuration

- `APP_ENV` controls environment-specific behavior and defaults to `development`.
- `CORS_ALLOWED_ORIGINS` should be a comma-separated list of allowed origins. It is required when `APP_ENV=production`; otherwise the API falls back to localhost defaults for development.

## Privacy & Telemetry Guardrails

- Logging is configured via `backend.logging_config.configure_logging()` (invoked during app startup) to redact sensitive identifiers such as `user_id`, `created_at`, and `secondary_curriculum_id` before any message is emitted. See `tests/backend/test_logging_privacy.py` for coverage.
- The [journal telemetry threat model](../prompts/claude-comm/journal-telemetry-threat-model.md) documents assumptions, identified risks, and required mitigations. Review it before introducing new telemetry sinks or expanding the journal schema.

## Health Check

```bash
curl http://localhost:8000/health
```

## Example Requests

All JSON resources are served under the `/api/v1` prefix without a trailing slash.

### Layers

```bash
curl http://localhost:8000/api/v1/layer
curl http://localhost:8000/api/v1/layer/1
curl -X POST http://localhost:8000/api/v1/layer \
  -H 'Content-Type: application/json' \
  -d '{"color": "Indigo", "title": "TEST", "subtitle": "Example"}'
```

### Phases

```bash
curl http://localhost:8000/api/v1/phase
curl -X PUT http://localhost:8000/api/v1/phase/2 \
  -H 'Content-Type: application/json' \
  -d '{"name": "Updated Phase"}'
```

### Curriculum

```bash
curl 'http://localhost:8000/api/v1/curriculum?layer_id=1&phase_id=1&dosage=Medicinal'
curl http://localhost:8000/api/v1/curriculum/10
curl -X POST http://localhost:8000/api/v1/curriculum \
  -H 'Content-Type: application/json' \
  -d '{"layer_id": 1, "phase_id": 1, "dosage": "Medicinal", "expression": "Testing"}'
```

### Strategies

```bash
curl 'http://localhost:8000/api/v1/strategy?layer_id=1&phase_id=5'
curl http://localhost:8000/api/v1/strategy/1
curl -X PUT http://localhost:8000/api/v1/strategy/1 \
  -H 'Content-Type: application/json' \
  -d '{"strategy": "Updated Strategy"}'
```

### Journal Entries

```bash
curl 'http://localhost:8000/api/v1/journal?user_id=1&from=2025-09-14T00:00:00Z'
curl http://localhost:8000/api/v1/journal/1
curl -X POST http://localhost:8000/api/v1/journal \
  -H 'Content-Type: application/json' \
  -d '{"created_at": "2025-09-16T12:00:00Z", "user_id": 42, "curriculum_id": 1, "strategy_id": 1}'
```

All endpoints support `limit` and `offset` query parameters for pagination. Static reference tables (layers, phases, curriculum) support writes for completeness, but in production they should only change through migration or administrator workflows.
