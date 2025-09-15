from __future__ import annotations

from datetime import UTC, datetime, timedelta

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


def _create_journal(client: TestClient, ts: datetime) -> int:
    payload = {
        "timestamp": ts.isoformat(),
        "initiated_by": "tester",
        "details": [],
    }
    resp = client.post("/journal", json=payload)
    assert resp.status_code == 201
    return resp.json()["id"]


def test_create_self_care_log(client: TestClient) -> None:
    journal_id = _create_journal(client, datetime(2024, 1, 1, 12, 0, 0))
    payload = {
        "journal_id": journal_id,
        "strategy": "drink water",
        "timestamp": datetime(2024, 1, 1, 12, 30, 0).isoformat(),
    }
    resp = client.post("/self-care", json=payload)
    assert resp.status_code == 201
    data = resp.json()
    assert data["journal_id"] == journal_id
    assert data["strategy"] == "drink water"


def test_create_self_care_missing_journal(client: TestClient) -> None:
    payload = {
        "journal_id": 999,
        "strategy": "sleep",
        "timestamp": datetime(2024, 1, 1, 12, 0, 0).isoformat(),
    }
    resp = client.post("/self-care", json=payload)
    assert resp.status_code == 404


def test_list_self_care_by_journal(client: TestClient) -> None:
    journal_id = _create_journal(client, datetime(2024, 1, 1, 12, 0, 0))
    other_id = _create_journal(client, datetime(2024, 1, 2, 12, 0, 0))
    logs = [
        {
            "journal_id": journal_id,
            "strategy": "hydrate",
            "timestamp": datetime(2024, 1, 1, 13, 0, 0).isoformat(),
        },
        {
            "journal_id": journal_id,
            "strategy": "rest",
            "timestamp": datetime(2024, 1, 1, 14, 0, 0).isoformat(),
        },
        {
            "journal_id": other_id,
            "strategy": "walk",
            "timestamp": datetime(2024, 1, 2, 13, 0, 0).isoformat(),
        },
    ]
    for log in logs:
        assert client.post("/self-care", json=log).status_code == 201

    resp = client.get("/self-care", params={"journal_id": journal_id})
    assert resp.status_code == 200
    data = resp.json()
    assert len(data) == 2
    assert all(item["journal_id"] == journal_id for item in data)


def test_list_self_care_by_date(client: TestClient) -> None:
    journal_id = _create_journal(client, datetime(2024, 1, 1, 12, 0, 0))
    logs = [
        {
            "journal_id": journal_id,
            "strategy": "hydrate",
            "timestamp": datetime(2024, 1, 1, 13, 0, 0).isoformat(),
        },
        {
            "journal_id": journal_id,
            "strategy": "rest",
            "timestamp": datetime(2024, 1, 5, 13, 0, 0).isoformat(),
        },
    ]
    for log in logs:
        assert client.post("/self-care", json=log).status_code == 201

    params = {
        "start": datetime(2024, 1, 2).isoformat(),
        "end": datetime(2024, 1, 6).isoformat(),
    }
    resp = client.get("/self-care", params=params)
    assert resp.status_code == 200
    data = resp.json()
    assert len(data) == 1
    assert data[0]["strategy"] == "rest"


def test_timezone_handling(client: TestClient) -> None:
    """Ensure timezone-aware inputs are normalized to UTC."""
    journal_id = _create_journal(client, datetime(2024, 1, 1, 12, 0, 0, tzinfo=UTC))
    payload = {
        "journal_id": journal_id,
        "strategy": "stretch",
        "timestamp": "2024-01-01T14:00:00+02:00",
    }
    assert client.post("/self-care", json=payload).status_code == 201

    params = {
        "start": "2024-01-01T13:00:00+01:00",
        "end": "2024-01-01T13:00:00+01:00",
    }
    resp = client.get("/self-care", params=params)
    assert resp.status_code == 200
    data = resp.json()
    assert len(data) == 1
    assert data[0]["timestamp"] == "2024-01-01T12:00:00"


def test_self_care_pagination(client: TestClient) -> None:
    """Verify limit and offset parameters."""
    journal_id = _create_journal(client, datetime(2024, 1, 1, 12, 0, 0))
    base = datetime(2024, 1, 1, 10, 0, 0)
    for i in range(3):
        payload = {
            "journal_id": journal_id,
            "strategy": f"s{i}",
            "timestamp": (base + timedelta(days=i)).isoformat(),
        }
        assert client.post("/self-care", json=payload).status_code == 201

    resp = client.get("/self-care", params={"limit": 1, "offset": 1})
    assert resp.status_code == 200
    data = resp.json()
    assert len(data) == 1
    assert data[0]["strategy"] == "s1"


def test_date_filter_boundaries(client: TestClient) -> None:
    """Ensure start/end filters are inclusive of exact boundaries."""
    journal_id = _create_journal(client, datetime(2024, 1, 1, 12, 0, 0))
    times = [
        datetime(2024, 1, 1, 13, 0, 0),
        datetime(2024, 1, 2, 13, 0, 0),
        datetime(2024, 1, 3, 13, 0, 0),
    ]
    for i, ts in enumerate(times):
        payload = {
            "journal_id": journal_id,
            "strategy": f"t{i}",
            "timestamp": ts.isoformat(),
        }
        assert client.post("/self-care", json=payload).status_code == 201

    params = {
        "start": times[0].isoformat(),
        "end": times[1].isoformat(),
    }
    resp = client.get("/self-care", params=params)
    assert resp.status_code == 200
    data = resp.json()
    assert [item["strategy"] for item in data] == ["t1", "t0"]


def test_invalid_data(client: TestClient) -> None:
    """Invalid journal id and timestamp should be rejected."""
    journal_id = _create_journal(client, datetime(2024, 1, 1, 12, 0, 0))
    bad_payload = {
        "journal_id": journal_id,
        "strategy": "oops",
        "timestamp": "not-a-timestamp",
    }
    resp = client.post("/self-care", json=bad_payload)
    assert resp.status_code == 422

    neg_payload = {
        "journal_id": -1,
        "strategy": "bad",
        "timestamp": datetime(2024, 1, 1, 12, 0, 0).isoformat(),
    }
    resp = client.post("/self-care", json=neg_payload)
    assert resp.status_code == 404
