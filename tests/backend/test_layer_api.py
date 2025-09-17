"""Tests for the layer endpoints."""

from __future__ import annotations


def test_layers_seeded(client) -> None:
    response = client.get("/layer")
    assert response.status_code == 200
    payload = response.json()
    assert len(payload) == 11
    first = payload[0]
    assert first["id"] == 0
    assert first["title"] == "SELF-CARE"
    assert first["subtitle"] == "(For Surfing)"


def test_layer_crud(client) -> None:
    create_payload = {"color": "Test", "title": "Layer", "subtitle": "Demo"}
    created = client.post("/layer", json=create_payload)
    assert created.status_code == 201
    created_body = created.json()
    layer_id = created_body["id"]
    assert created_body["color"] == "Test"

    update_payload = {"title": "Layer Updated"}
    updated = client.put(f"/layer/{layer_id}", json=update_payload)
    assert updated.status_code == 200
    assert updated.json()["title"] == "Layer Updated"

    delete_response = client.delete(f"/layer/{layer_id}")
    assert delete_response.status_code == 204

    missing = client.get(f"/layer/{layer_id}")
    assert missing.status_code == 404
