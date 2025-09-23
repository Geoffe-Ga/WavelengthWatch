"""Tests for curriculum endpoints and filtering."""

from __future__ import annotations


def test_curriculum_filtering_and_relations(client) -> None:
    response = client.get(
        "/api/v1/curriculum",
        params={"layer_id": 1, "phase_id": 1, "dosage": "Medicinal"},
    )
    assert response.status_code == 200
    items = response.json()
    assert items, "Expected at least one medicinal curriculum entry"
    for item in items:
        assert item["layer_id"] == 1
        assert item["phase_id"] == 1
        assert item["dosage"] == "Medicinal"
        assert item["layer"]["title"]
        assert item["phase"]["name"]

    paginated = client.get("/api/v1/curriculum", params={"limit": 2, "offset": 1})
    assert paginated.status_code == 200
    assert len(paginated.json()) == 2


def test_curriculum_crud(client) -> None:
    create_payload = {
        "layer_id": 1,
        "phase_id": 1,
        "dosage": "Medicinal",
        "expression": "Integration Testing",
    }
    created = client.post("/api/v1/curriculum", json=create_payload)
    assert created.status_code == 201
    curriculum_id = created.json()["id"]

    detail = client.get(f"/api/v1/curriculum/{curriculum_id}")
    assert detail.status_code == 200
    assert detail.json()["expression"] == "Integration Testing"

    update_payload = {"expression": "Updated Expression", "dosage": "Toxic"}
    updated = client.put(f"/api/v1/curriculum/{curriculum_id}", json=update_payload)
    assert updated.status_code == 200
    updated_body = updated.json()
    assert updated_body["expression"] == "Updated Expression"
    assert updated_body["dosage"] == "Toxic"

    delete_response = client.delete(f"/api/v1/curriculum/{curriculum_id}")
    assert delete_response.status_code == 204

    missing = client.get(f"/api/v1/curriculum/{curriculum_id}")
    assert missing.status_code == 404
