"""Tests for journal entry_type behavior in the journal API."""

from __future__ import annotations


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


def test_rest_entry_type_is_rejected(client) -> None:
    """The removed 'rest' entry_type is no longer accepted (#435)."""
    payload = {
        "created_at": "2025-09-16T12:00:00Z",
        "user_id": 206,
        "entry_type": "rest",
        "curriculum_id": 1,
    }
    response = client.post("/api/v1/journal", json=payload)
    assert response.status_code == 422
