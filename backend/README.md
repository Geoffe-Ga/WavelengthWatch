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

## Health Check

```bash
curl http://localhost:8000/health
```

## Example Requests

### Layers

```bash
curl http://localhost:8000/layer
curl http://localhost:8000/layer/1
curl -X POST http://localhost:8000/layer \
  -H 'Content-Type: application/json' \
  -d '{"color": "Indigo", "title": "TEST", "subtitle": "Example"}'
```

### Phases

```bash
curl http://localhost:8000/phase
curl -X PUT http://localhost:8000/phase/2 \
  -H 'Content-Type: application/json' \
  -d '{"name": "Updated Phase"}'
```

### Curriculum

```bash
curl 'http://localhost:8000/curriculum?layer_id=1&phase_id=1&dosage=Medicinal'
curl http://localhost:8000/curriculum/10
curl -X POST http://localhost:8000/curriculum \
  -H 'Content-Type: application/json' \
  -d '{"layer_id": 1, "phase_id": 1, "dosage": "Medicinal", "expression": "Testing"}'
```

### Strategies

```bash
curl 'http://localhost:8000/strategy?layer_id=1&phase_id=5'
curl http://localhost:8000/strategy/1
curl -X PUT http://localhost:8000/strategy/1 \
  -H 'Content-Type: application/json' \
  -d '{"strategy": "Updated Strategy"}'
```

### Journal Entries

```bash
curl 'http://localhost:8000/journal?user_id=1&from=2025-09-14T00:00:00Z'
curl http://localhost:8000/journal/1
curl -X POST http://localhost:8000/journal \
  -H 'Content-Type: application/json' \
  -d '{"created_at": "2025-09-16T12:00:00Z", "user_id": 42, "curriculum_id": 1, "strategy_id": 1}'
```

All endpoints support `limit` and `offset` query parameters for pagination. Static reference tables (layers, phases, curriculum) support writes for completeness, but in production they should only change through migration or administrator workflows.
