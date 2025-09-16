from __future__ import annotations

from datetime import UTC, datetime, timedelta
from typing import Any

from fastapi.testclient import TestClient


def _create_journal(client: TestClient, ts: datetime) -> int:
    payload = {
        "timestamp": ts.isoformat(),
        "initiated_by": "tester",
        "details": [],
    }
    resp = client.post("/journal", json=payload)
    assert resp.status_code == 201
    return resp.json()["id"]


def _create_strategy(
    client: TestClient,
    name: str,
    *,
    color: str = "Beige",
    phase: str = "Restoration",
) -> dict[str, Any]:
    payload = {"color": color, "strategy": name, "phase": phase}
    resp = client.post("/strategies", json=payload)
    assert resp.status_code == 201
    return resp.json()


def test_create_self_care_log(client: TestClient) -> None:
    journal_id = _create_journal(client, datetime(2024, 1, 1, 12, 0, 0))
    strategy = _create_strategy(client, "Hydrate Now")
    payload = {
        "journal_id": journal_id,
        "strategy_id": strategy["id"],
        "timestamp": datetime(2024, 1, 1, 12, 30, 0).isoformat(),
    }
    resp = client.post("/self-care", json=payload)
    assert resp.status_code == 201
    data = resp.json()
    assert data["journal_id"] == journal_id
    assert data["strategy_id"] == strategy["id"]
    assert data["strategy"] == "Hydrate Now"


def test_create_self_care_missing_journal(client: TestClient) -> None:
    strategy = _create_strategy(client, "Rest Now")
    payload = {
        "journal_id": 999,
        "strategy_id": strategy["id"],
        "timestamp": datetime(2024, 1, 1, 12, 0, 0).isoformat(),
    }
    resp = client.post("/self-care", json=payload)
    assert resp.status_code == 404


def test_list_self_care_by_journal(client: TestClient) -> None:
    journal_id = _create_journal(client, datetime(2024, 1, 1, 12, 0, 0))
    other_id = _create_journal(client, datetime(2024, 1, 2, 12, 0, 0))
    strategies = [
        _create_strategy(client, "Hydrate"),
        _create_strategy(client, "Rest"),
        _create_strategy(client, "Walk"),
    ]
    logs = [
        {
            "journal_id": journal_id,
            "strategy_id": strategies[0]["id"],
            "timestamp": datetime(2024, 1, 1, 13, 0, 0).isoformat(),
        },
        {
            "journal_id": journal_id,
            "strategy_id": strategies[1]["id"],
            "timestamp": datetime(2024, 1, 1, 14, 0, 0).isoformat(),
        },
        {
            "journal_id": other_id,
            "strategy_id": strategies[2]["id"],
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
    assert {item["strategy"] for item in data} == {"Hydrate", "Rest"}


def test_list_self_care_by_date(client: TestClient) -> None:
    journal_id = _create_journal(client, datetime(2024, 1, 1, 12, 0, 0))
    strategy = _create_strategy(client, "Recharge")
    logs = [
        {
            "journal_id": journal_id,
            "strategy_id": strategy["id"],
            "timestamp": datetime(2024, 1, 1, 13, 0, 0).isoformat(),
        },
        {
            "journal_id": journal_id,
            "strategy_id": strategy["id"],
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
    assert data[0]["strategy"] == "Recharge"


def test_timezone_handling(client: TestClient) -> None:
    """Ensure timezone-aware inputs are normalized to UTC."""
    journal_id = _create_journal(client, datetime(2024, 1, 1, 12, 0, 0, tzinfo=UTC))
    strategy = _create_strategy(client, "Stretch")
    payload = {
        "journal_id": journal_id,
        "strategy_id": strategy["id"],
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
    strategy = _create_strategy(client, "Paginated Strategy")
    base = datetime(2024, 1, 1, 10, 0, 0)
    for i in range(3):
        payload = {
            "journal_id": journal_id,
            "strategy_id": strategy["id"],
            "timestamp": (base + timedelta(days=i)).isoformat(),
        }
        assert client.post("/self-care", json=payload).status_code == 201

    resp = client.get("/self-care", params={"limit": 1, "offset": 1})
    assert resp.status_code == 200
    data = resp.json()
    assert len(data) == 1
    assert data[0]["strategy_id"] == strategy["id"]


def test_date_filter_boundaries(client: TestClient) -> None:
    """Ensure start/end filters are inclusive of exact boundaries."""
    journal_id = _create_journal(client, datetime(2024, 1, 1, 12, 0, 0))
    strategy = _create_strategy(client, "Boundary Strategy")
    times = [
        datetime(2024, 1, 1, 13, 0, 0),
        datetime(2024, 1, 2, 13, 0, 0),
        datetime(2024, 1, 3, 13, 0, 0),
    ]
    for ts in times:
        payload = {
            "journal_id": journal_id,
            "strategy_id": strategy["id"],
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
    assert [item["strategy_id"] for item in data] == [strategy["id"], strategy["id"]]


def test_invalid_data(client: TestClient) -> None:
    """Invalid journal id and timestamp should be rejected."""
    journal_id = _create_journal(client, datetime(2024, 1, 1, 12, 0, 0))
    strategy = _create_strategy(client, "Invalid Test")
    bad_payload = {
        "journal_id": journal_id,
        "strategy_id": strategy["id"],
        "timestamp": "not-a-timestamp",
    }
    resp = client.post("/self-care", json=bad_payload)
    assert resp.status_code == 422

    neg_payload = {
        "journal_id": -1,
        "strategy_id": strategy["id"],
        "timestamp": datetime(2024, 1, 1, 12, 0, 0).isoformat(),
    }
    resp = client.post("/self-care", json=neg_payload)
    assert resp.status_code == 404

    missing_strategy = {
        "journal_id": journal_id,
        "timestamp": datetime(2024, 1, 1, 12, 0, 0).isoformat(),
    }
    resp = client.post("/self-care", json=missing_strategy)
    assert resp.status_code == 422


def test_create_self_care_by_strategy_name(client: TestClient) -> None:
    journal_id = _create_journal(client, datetime(2024, 1, 1, 12, 0, 0))
    strategy = _create_strategy(client, "Name Based Logging")
    payload = {
        "journal_id": journal_id,
        "strategy": strategy["strategy"],
        "timestamp": datetime(2024, 1, 1, 12, 15, 0).isoformat(),
    }
    resp = client.post("/self-care", json=payload)
    assert resp.status_code == 201
    data = resp.json()
    assert data["strategy_id"] == strategy["id"]
    assert data["strategy"] == "Name Based Logging"
