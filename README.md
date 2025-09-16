# WavelengthWatch FastAPI Service

This project exposes the WavelengthWatch reference data and journal entries through a
FastAPI + SQLModel application backed by SQLite (configurable via `DATABASE_URL`).
Reference tables (layers, phases, curriculum, strategies) are seeded from CSV fixtures
at startup, along with sample journal entries. The `journal` resource is designed to
scale with runtime usage while the other tables act as curated reference data.

## Project Layout

```
app/
  main.py           # FastAPI instantiation and router registration
  database.py       # Engine creation and session dependency
  models.py         # SQLModel ORM tables and relationships
  schemas.py        # Pydantic/SQLModel DTOs
  routers/          # CRUD routers for each resource
  seed_data.py      # CSV constants and seeding helpers
  utils.py          # Datetime helpers
pyproject.toml      # Dependencies and tooling configuration
README.md           # This file
tests/test_journal.py  # Happy-path CRUD test for journal entries
```

## Requirements

* Python 3.11+
* Poetry or pip for dependency management

Install dependencies with pip:

```bash
python -m venv .venv
source .venv/bin/activate
pip install -e .[dev]
```

## Running the API

```bash
export DATABASE_URL="sqlite:///./app.db"  # optional, defaults to this value
python -m uvicorn app.main:app --reload
```

On startup the application will create tables (if needed) and seed the database from the
embedded CSV fixtures. The known values for `curriculum.dosage` are `Medicinal` and `Toxic`.

## Example Requests

List layers:

```bash
curl http://localhost:8000/layers
```

Create a new journal entry:

```bash
curl -X POST http://localhost:8000/journal \
  -H 'Content-Type: application/json' \
  -d '{
        "created_at": "2025-10-01T12:00:00Z",
        "user_id": 42,
        "curriculum_id": 1,
        "secondary_curriculum_id": 2,
        "strategy_id": 1
      }'
```

Filter curriculum by stage and dosage:

```bash
curl "http://localhost:8000/curriculum?stage_id=1&dosage=Medicinal"
```

Retrieve a single strategy:

```bash
curl http://localhost:8000/strategies/1
```

Delete a journal entry:

```bash
curl -X DELETE http://localhost:8000/journal/1
```

A health check is exposed at `GET /health`.

## Testing

Run the automated tests (which exercise seeding and CRUD for journal entries):

```bash
pytest
```
