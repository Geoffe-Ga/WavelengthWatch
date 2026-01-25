"""Tests for REST entry type functionality in journal API."""

from __future__ import annotations


def test_create_rest_entry_without_curriculum(client) -> None:
    """REST entries can be created without curriculum_id."""
    payload = {
        "created_at": "2025-09-16T12:00:00Z",
        "user_id": 200,
        "entry_type": "rest",
        "curriculum_id": None,
    }
    response = client.post("/api/v1/journal", json=payload)
    assert response.status_code == 201
    body = response.json()
    assert body["entry_type"] == "rest"
    assert body["curriculum_id"] is None
    assert body["curriculum"] is None


def test_create_rest_entry_with_curriculum(client) -> None:
    """REST entries can optionally include curriculum_id."""
    payload = {
        "created_at": "2025-09-16T12:00:00Z",
        "user_id": 201,
        "entry_type": "rest",
        "curriculum_id": 1,
    }
    response = client.post("/api/v1/journal", json=payload)
    assert response.status_code == 201
    body = response.json()
    assert body["entry_type"] == "rest"
    assert body["curriculum_id"] == 1
    assert body["curriculum"]["id"] == 1


def test_create_emotion_entry_requires_curriculum(client) -> None:
    """EMOTION entries must have curriculum_id."""
    payload = {
        "created_at": "2025-09-16T12:00:00Z",
        "user_id": 202,
        "entry_type": "emotion",
        "curriculum_id": None,
    }
    response = client.post("/api/v1/journal", json=payload)
    assert response.status_code == 400
    assert "curriculum_id is required for emotion entries" in response.json()["detail"]


def test_create_emotion_entry_with_curriculum(client) -> None:
    """EMOTION entries work normally with curriculum_id."""
    payload = {
        "created_at": "2025-09-16T12:00:00Z",
        "user_id": 203,
        "entry_type": "emotion",
        "curriculum_id": 1,
    }
    response = client.post("/api/v1/journal", json=payload)
    assert response.status_code == 201
    body = response.json()
    assert body["entry_type"] == "emotion"
    assert body["curriculum_id"] == 1


def test_entry_type_defaults_to_emotion(client) -> None:
    """If entry_type is not specified, it defaults to EMOTION."""
    payload = {
        "created_at": "2025-09-16T12:00:00Z",
        "user_id": 204,
        "curriculum_id": 1,
    }
    response = client.post("/api/v1/journal", json=payload)
    assert response.status_code == 201
    body = response.json()
    assert body["entry_type"] == "emotion"
    assert body["curriculum_id"] == 1


def test_rest_entries_excluded_from_emotion_landscape(client) -> None:
    """REST entries are excluded from emotional landscape analytics."""
    # Create mix of emotion and rest entries
    # Emotion entry with layer 1
    emotion_payload = {
        "created_at": "2025-09-16T12:00:00Z",
        "user_id": 205,
        "entry_type": "emotion",
        "curriculum_id": 1,
    }
    client.post("/api/v1/journal", json=emotion_payload)

    # Rest entry (should be excluded)
    rest_payload = {
        "created_at": "2025-09-16T13:00:00Z",
        "user_id": 205,
        "entry_type": "rest",
        "curriculum_id": None,
    }
    client.post("/api/v1/journal", json=rest_payload)

    # Get emotional landscape
    response = client.get(
        "/api/v1/analytics/emotional-landscape",
        params={
            "user_id": 205,
            "start_date": "2025-09-16T00:00:00Z",
            "end_date": "2025-09-16T23:59:59Z",
        },
    )
    assert response.status_code == 200
    landscape = response.json()

    # Only the emotion entry should count
    total_entries = sum(item["count"] for item in landscape["layer_distribution"])
    assert total_entries == 1
