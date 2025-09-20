"""Tests for phase CRUD endpoints."""

from __future__ import annotations


def test_phases_seeded(client) -> None:
    response = client.get("/phase")
    assert response.status_code == 200
    phases = response.json()
    assert len(phases) == 6
    assert phases[0]["name"] == "Rising"


def test_phase_crud(client) -> None:
    created = client.post("/phase", json={"name": "Experiment"})
    assert created.status_code == 201
    body = created.json()
    phase_id = body["id"]

    updated = client.put(
        f"/phase/{phase_id}", json={"name": "Experimentation"}
    )
    assert updated.status_code == 200
    assert updated.json()["name"] == "Experimentation"

    delete_response = client.delete(f"/phase/{phase_id}")
    assert delete_response.status_code == 204
    missing = client.get(f"/phase/{phase_id}")
    assert missing.status_code == 404
