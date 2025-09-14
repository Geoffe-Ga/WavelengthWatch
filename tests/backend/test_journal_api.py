from __future__ import annotations

from datetime import datetime
from typing import Any

import pytest
from fastapi.testclient import TestClient
from sqlmodel import create_engine

import backend.db as db_module
from backend.db import init_db


@pytest.fixture(name="client")
def fixture_client(tmp_path, monkeypatch) -> TestClient:
    """Provide a TestClient with an isolated database."""
    test_db = tmp_path / "test.db"
    monkeypatch.setattr(db_module, "DATABASE_FILE", test_db)
    monkeypatch.setattr(db_module, "DATABASE_URL", f"sqlite:///{test_db}")
    engine = create_engine(db_module.DATABASE_URL, echo=False)
    monkeypatch.setattr(db_module, "engine", engine)
    init_db()
    from backend.app import app

    return TestClient(app)


def _sample_payload(ts: datetime) -> dict[str, Any]:
    return {
        "timestamp": ts.isoformat(),
        "initiated_by": "tester",
        "details": [
            {"stage": 1, "phase": 1, "dosage": 1.0, "position": 1},
        ],
    }


def test_create_journal_entry_with_details(client: TestClient) -> None:
    payload = _sample_payload(datetime(2024, 1, 1, 12, 0, 0))
    response = client.post("/journal", json=payload)
    assert response.status_code == 201
    data = response.json()
    assert data["initiated_by"] == "tester"
    assert len(data["details"]) == 1
    assert data["details"][0]["stage"] == 1


def test_create_journal_empty_details(client: TestClient) -> None:
    ts = datetime(2024, 1, 1, 12, 0, 0)
    payload = {
        "timestamp": ts.isoformat(),
        "initiated_by": "tester",
        "details": [],
    }
    response = client.post("/journal", json=payload)
    assert response.status_code == 201
    assert response.json()["details"] == []


def test_create_journal_multiple_details(client: TestClient) -> None:
    ts = datetime(2024, 1, 1, 12, 0, 0)
    payload = _sample_payload(ts)
    payload["details"].append(
        {"stage": 2, "phase": 2, "dosage": 2.0, "position": 2}
    )
    response = client.post("/journal", json=payload)
    assert response.status_code == 201
    assert len(response.json()["details"]) == 2


def test_create_journal_validation_error(client: TestClient) -> None:
    payload = {"timestamp": datetime(2024, 1, 1).isoformat(), "details": []}
    response = client.post("/journal", json=payload)
    assert response.status_code == 422


def test_list_journal_filtered_by_date(client: TestClient) -> None:
    early = datetime(2024, 1, 1, 12, 0, 0)
    late = datetime(2024, 2, 1, 12, 0, 0)
    client.post("/journal", json=_sample_payload(early))
    client.post("/journal", json=_sample_payload(late))

    params = {
        "start": datetime(2024, 1, 15).isoformat(),
        "end": datetime(2024, 3, 1).isoformat(),
    }
    response = client.get("/journal", params=params)
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1
    assert data[0]["timestamp"].startswith("2024-02-01")


def test_list_journal_boundary_dates(client: TestClient) -> None:
    ts = datetime(2024, 1, 1, 12, 0, 0)
    client.post("/journal", json=_sample_payload(ts))
    params = {"start": ts.isoformat(), "end": ts.isoformat()}
    response = client.get("/journal", params=params)
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1


def test_list_journal_invalid_date_format(client: TestClient) -> None:
    response = client.get("/journal", params={"start": "not-a-date"})
    assert response.status_code == 422
