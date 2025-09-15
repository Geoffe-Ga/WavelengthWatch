from __future__ import annotations

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


def test_create_and_list_strategies(client: TestClient) -> None:
    payload = {"color": "Blue", "strategy": "Drink Water"}
    resp = client.post("/strategies", json=payload)
    assert resp.status_code == 201
    data = resp.json()
    assert data["color"] == "Blue"
    assert data["strategy"] == "Drink Water"

    resp = client.get("/strategies")
    assert resp.status_code == 200
    items = resp.json()
    assert len(items) == 1
    assert items[0]["strategy"] == "Drink Water"


def test_list_strategies_raw(client: TestClient) -> None:
    resp = client.get("/strategies", params={"raw": True})
    assert resp.status_code == 200
    data = resp.json()
    # legacy format should include phase keys like "Rising"
    assert "Rising" in data
    assert isinstance(data["Rising"], list)


def test_strategy_validation(client: TestClient) -> None:
    payload = {"color": "B" * 101, "strategy": "A"}
    resp = client.post("/strategies", json=payload)
    assert resp.status_code == 422

    inj_payload = {"color": "Blue", "strategy": "1; DROP TABLE"}
    resp = client.post("/strategies", json=inj_payload)
    assert resp.status_code == 201
