"""Tests for journal endpoints."""

from __future__ import annotations


def test_journal_filtering(client) -> None:
    response = client.get("/journal", params={"user_id": 1})
    assert response.status_code == 200
    entries = response.json()
    assert len(entries) == 2
    for entry in entries:
        assert entry["user_id"] == 1
        assert entry["curriculum"]["layer"]["title"]

    range_response = client.get(
        "/journal",
        params={
            "from": "2025-09-14T00:00:00Z",
            "to": "2025-09-15T23:59:59Z",
        },
    )
    assert range_response.status_code == 200
    ranged_entries = range_response.json()
    assert {item["id"] for item in ranged_entries} == {2, 3}


def test_journal_crud(client) -> None:
    create_payload = {
        "created_at": "2025-09-16T12:00:00Z",
        "user_id": 99,
        "curriculum_id": 1,
        "secondary_curriculum_id": 2,
        "strategy_id": 1,
    }
    created = client.post("/journal", json=create_payload)
    assert created.status_code == 201
    body = created.json()
    journal_id = body["id"]
    assert body["strategy"]["id"] == 1

    detail = client.get(f"/journal/{journal_id}")
    assert detail.status_code == 200
    assert detail.json()["curriculum"]["id"] == 1

    update_payload = {
        "strategy_id": None,
        "secondary_curriculum_id": None,
        "user_id": 98,
    }
    updated = client.put(f"/journal/{journal_id}", json=update_payload)
    assert updated.status_code == 200
    updated_body = updated.json()
    assert updated_body["user_id"] == 98
    assert updated_body["strategy"] is None
    assert updated_body["secondary_curriculum"] is None

    delete_response = client.delete(f"/journal/{journal_id}")
    assert delete_response.status_code == 204

    missing = client.get(f"/journal/{journal_id}")
    assert missing.status_code == 404
