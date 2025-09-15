from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from fastapi.testclient import TestClient


def _create_strategy(client: TestClient, *, name: str, color: str, phase: str) -> dict[str, Any]:
    payload = {"color": color, "strategy": name, "phase": phase}
    resp = client.post("/strategies", json=payload)
    assert resp.status_code == 201
    return resp.json()


def test_strategies_endpoint_matches_json(client: TestClient) -> None:
    resp = client.get("/strategies")
    assert resp.status_code == 200
    data = resp.json()
    expected = json.loads(
        Path("backend/data/prod/a-w-strategies.json").read_text(encoding="utf-8")
    )
    assert data == expected


def test_create_strategy_updates_index(client: TestClient) -> None:
    created = _create_strategy(
        client, name="API Added Strategy", color="Silver", phase="Restoration"
    )

    listing = client.get("/strategies/index")
    assert listing.status_code == 200
    payload = listing.json()
    assert any(item["id"] == created["id"] for item in payload)
    assert any(item["strategy"] == "API Added Strategy" for item in payload)

    grouped = client.get("/strategies")
    assert grouped.status_code == 200
    strategies = grouped.json()[created["phase"]]
    assert any(item["strategy"] == "API Added Strategy" for item in strategies)


def test_duplicate_strategy_conflict(client: TestClient) -> None:
    payload = {"name": "Duplicate Strategy", "color": "Amber", "phase": "Rising"}
    created = _create_strategy(
        client,
        name=payload["name"],
        color=payload["color"],
        phase=payload["phase"],
    )
    assert created["strategy"] == payload["name"]

    conflict = client.post(
        "/strategies",
        json={"strategy": payload["name"], "color": payload["color"], "phase": payload["phase"]},
    )
    assert conflict.status_code == 409


def test_strategies_index_filter(client: TestClient) -> None:
    _create_strategy(client, name="Filter Strategy", color="Gold", phase="Restoration")
    resp = client.get("/strategies/index", params={"phase": "Restoration"})
    assert resp.status_code == 200
    data = resp.json()
    assert data
    assert all(item["phase"] == "Restoration" for item in data)
