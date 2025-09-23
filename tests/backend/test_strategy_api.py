"""Tests for strategy endpoints."""

from __future__ import annotations


def test_strategy_filtering(client) -> None:
    response = client.get("/strategy", params={"color_layer_id": 1, "phase_id": 5})
    assert response.status_code == 200
    strategies = response.json()
    assert strategies, "Expected seeded strategies"
    for item in strategies:
        assert item["color_layer_id"] == 1
        assert item["phase_id"] == 5
        assert item["color_layer"]["title"]
        assert item["phase"]["name"]


def test_strategy_crud(client) -> None:
    create_payload = {
        "strategy": "Test Strategy",
        "layer_id": 0,
        "color_layer_id": 1,
        "phase_id": 1,
    }
    created = client.post("/strategy", json=create_payload)
    assert created.status_code == 201
    strategy_id = created.json()["id"]

    updated = client.put(
        f"/strategy/{strategy_id}",
        json={"strategy": "Updated Strategy", "phase_id": 2},
    )
    assert updated.status_code == 200
    body = updated.json()
    assert body["strategy"] == "Updated Strategy"
    assert body["phase_id"] == 2

    delete_response = client.delete(f"/strategy/{strategy_id}")
    assert delete_response.status_code == 204
    missing = client.get(f"/strategy/{strategy_id}")
    assert missing.status_code == 404
