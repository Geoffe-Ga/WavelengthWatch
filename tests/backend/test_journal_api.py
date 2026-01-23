"""Tests for journal endpoints."""

from __future__ import annotations

import uuid
from datetime import UTC, datetime, timedelta


def test_journal_filtering(client) -> None:
    response = client.get("/api/v1/journal", params={"user_id": 1})
    assert response.status_code == 200
    entries = response.json()
    assert len(entries) == 2
    for entry in entries:
        assert entry["user_id"] == 1
        assert entry["curriculum"]["layer"]["title"]

    range_response = client.get(
        "/api/v1/journal",
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
    created = client.post("/api/v1/journal", json=create_payload)
    assert created.status_code == 201
    body = created.json()
    journal_id = body["id"]
    assert body["strategy"]["id"] == 1

    detail = client.get(f"/api/v1/journal/{journal_id}")
    assert detail.status_code == 200
    assert detail.json()["curriculum"]["id"] == 1

    update_payload = {
        "strategy_id": None,
        "secondary_curriculum_id": None,
        "user_id": 98,
    }
    updated = client.put(f"/api/v1/journal/{journal_id}", json=update_payload)
    assert updated.status_code == 200
    updated_body = updated.json()
    assert updated_body["user_id"] == 98
    assert updated_body["strategy"] is None
    assert updated_body["secondary_curriculum"] is None

    delete_response = client.delete(f"/api/v1/journal/{journal_id}")
    assert delete_response.status_code == 204

    missing = client.get(f"/api/v1/journal/{journal_id}")
    assert missing.status_code == 404


def test_journal_initiated_by_field(client) -> None:
    """Test initiated_by field validation and defaults."""
    # Test default value (self)
    payload_without_initiated_by = {
        "created_at": "2025-10-19T12:00:00Z",
        "user_id": 100,
        "curriculum_id": 1,
    }
    response = client.post("/api/v1/journal", json=payload_without_initiated_by)
    assert response.status_code == 201
    body = response.json()
    assert body["initiated_by"] == "self"

    # Test explicit self value
    payload_self = {
        "created_at": "2025-10-19T12:00:00Z",
        "user_id": 101,
        "curriculum_id": 1,
        "initiated_by": "self",
    }
    response = client.post("/api/v1/journal", json=payload_self)
    assert response.status_code == 201
    assert response.json()["initiated_by"] == "self"

    # Test scheduled value
    payload_scheduled = {
        "created_at": "2025-10-19T12:00:00Z",
        "user_id": 102,
        "curriculum_id": 1,
        "initiated_by": "scheduled",
    }
    response = client.post("/api/v1/journal", json=payload_scheduled)
    assert response.status_code == 201
    assert response.json()["initiated_by"] == "scheduled"

    # Test invalid value
    payload_invalid = {
        "created_at": "2025-10-19T12:00:00Z",
        "user_id": 103,
        "curriculum_id": 1,
        "initiated_by": "invalid_value",
    }
    response = client.post("/api/v1/journal", json=payload_invalid)
    assert response.status_code == 422


def test_journal_create_without_idempotency_key(client) -> None:
    """Test creating journal entry without idempotency key (current behavior)."""
    payload = {
        "created_at": "2025-10-20T12:00:00Z",
        "user_id": 200,
        "curriculum_id": 1,
    }

    # First request
    response1 = client.post("/api/v1/journal", json=payload)
    assert response1.status_code == 201
    entry1 = response1.json()

    # Second request with same payload (no idempotency key)
    response2 = client.post("/api/v1/journal", json=payload)
    assert response2.status_code == 201
    entry2 = response2.json()

    # Should create two different entries
    assert entry1["id"] != entry2["id"]


def test_journal_create_with_new_idempotency_key(client) -> None:
    """Test creating journal entry with new idempotency key creates entry."""
    idempotency_key = str(uuid.uuid4())
    payload = {
        "created_at": "2025-10-20T13:00:00Z",
        "user_id": 201,
        "curriculum_id": 1,
    }

    response = client.post(
        "/api/v1/journal",
        json=payload,
        headers={"X-Idempotency-Key": idempotency_key},
    )
    assert response.status_code == 201
    entry = response.json()
    assert entry["user_id"] == 201
    assert entry["curriculum"]["id"] == 1


def test_journal_idempotency_prevents_duplicates(client) -> None:
    """Test same idempotency key twice returns existing entry, no duplicate."""
    idempotency_key = str(uuid.uuid4())
    payload = {
        "created_at": "2025-10-20T14:00:00Z",
        "user_id": 202,
        "curriculum_id": 1,
        "strategy_id": 1,
    }

    # First request
    response1 = client.post(
        "/api/v1/journal",
        json=payload,
        headers={"X-Idempotency-Key": idempotency_key},
    )
    assert response1.status_code == 201
    entry1 = response1.json()
    journal_id = entry1["id"]

    # Second request with same idempotency key
    response2 = client.post(
        "/api/v1/journal",
        json=payload,
        headers={"X-Idempotency-Key": idempotency_key},
    )
    assert response2.status_code == 201
    entry2 = response2.json()

    # Should return same entry, not create duplicate
    assert entry2["id"] == journal_id
    assert entry2["user_id"] == 202
    assert entry2["strategy"]["id"] == 1

    # Verify only one entry exists
    list_response = client.get("/api/v1/journal", params={"user_id": 202})
    assert list_response.status_code == 200
    entries = list_response.json()
    assert len(entries) == 1
    assert entries[0]["id"] == journal_id


def test_journal_idempotency_key_validation(client) -> None:
    """Test idempotency key must be valid UUID format."""
    payload = {
        "created_at": "2025-10-20T15:00:00Z",
        "user_id": 203,
        "curriculum_id": 1,
    }

    # Invalid UUID format
    response = client.post(
        "/api/v1/journal",
        json=payload,
        headers={"X-Idempotency-Key": "not-a-uuid"},
    )
    assert response.status_code == 400
    assert "invalid" in response.json()["detail"].lower()


def test_journal_idempotency_after_expiration(client) -> None:
    """Test idempotency key creates new entry after expiration (> 24 hours).

    Note: Uses direct database access to simulate time passage by manually
    expiring the idempotency record. This is necessary since we cannot
    actually wait 24 hours in a test.
    """
    idempotency_key = str(uuid.uuid4())
    user_id = 204
    payload = {
        "created_at": "2025-10-20T16:00:00Z",
        "user_id": user_id,
        "curriculum_id": 1,
    }

    # First request
    response1 = client.post(
        "/api/v1/journal",
        json=payload,
        headers={"X-Idempotency-Key": idempotency_key},
    )
    assert response1.status_code == 201
    entry1 = response1.json()

    # Manually expire the idempotency record by setting expires_at in past
    # Direct DB access needed to simulate time passage
    from backend.database import get_session
    from backend.models import IdempotencyRecord

    for session in get_session():
        # Composite primary key requires both values
        record = session.get(IdempotencyRecord, (idempotency_key, user_id))
        assert record is not None
        record.expires_at = datetime.now(UTC) - timedelta(hours=1)
        session.add(record)
        session.commit()

    # Second request with same key after expiration
    payload["created_at"] = "2025-10-21T16:00:00Z"  # Different timestamp
    response2 = client.post(
        "/api/v1/journal",
        json=payload,
        headers={"X-Idempotency-Key": idempotency_key},
    )
    assert response2.status_code == 201
    entry2 = response2.json()

    # Should create new entry after expiration
    assert entry2["id"] != entry1["id"]


def test_journal_idempotency_different_users_same_key(client) -> None:
    """Test same idempotency key used by different users creates separate entries."""
    idempotency_key = str(uuid.uuid4())

    # User 205
    payload1 = {
        "created_at": "2025-10-20T17:00:00Z",
        "user_id": 205,
        "curriculum_id": 1,
    }
    response1 = client.post(
        "/api/v1/journal",
        json=payload1,
        headers={"X-Idempotency-Key": idempotency_key},
    )
    assert response1.status_code == 201
    entry1 = response1.json()

    # User 206 with same key (creates new entry - keys scoped per user)
    payload2 = {
        "created_at": "2025-10-20T17:30:00Z",
        "user_id": 206,
        "curriculum_id": 1,
    }
    response2 = client.post(
        "/api/v1/journal",
        json=payload2,
        headers={"X-Idempotency-Key": idempotency_key},
    )
    assert response2.status_code == 201
    entry2 = response2.json()

    # Should create separate entries (idempotency keys are scoped per user)
    assert entry2["id"] != entry1["id"]
    assert entry2["user_id"] == 206  # Different user


def test_idempotency_cleanup_removes_expired_records(client) -> None:
    """Test cleanup function removes expired idempotency records."""
    from backend.database import get_session
    from backend.models import IdempotencyRecord
    from backend.routers.journal import cleanup_expired_idempotency_records

    # Create an expired record manually
    expired_key = str(uuid.uuid4())
    user_id = 207

    for session in get_session():
        # First create a journal entry
        payload = {
            "created_at": "2025-10-20T18:00:00Z",
            "user_id": user_id,
            "curriculum_id": 1,
        }
        response = client.post(
            "/api/v1/journal",
            json=payload,
            headers={"X-Idempotency-Key": expired_key},
        )
        assert response.status_code == 201
        journal_id = response.json()["id"]

        # Manually set expiration to the past
        record = session.get(IdempotencyRecord, (expired_key, user_id))
        assert record is not None
        record.expires_at = datetime.now(UTC) - timedelta(hours=25)
        session.add(record)
        session.commit()

        # Create a non-expired record
        active_key = str(uuid.uuid4())
        active_record = IdempotencyRecord(
            idempotency_key=active_key,
            user_id=user_id,
            journal_id=journal_id,
            created_at=datetime.now(UTC),
            expires_at=datetime.now(UTC) + timedelta(hours=23),
        )
        session.add(active_record)
        session.commit()

        # Run cleanup
        cleanup_expired_idempotency_records(session)

        # Verify expired record removed, active record remains
        assert session.get(IdempotencyRecord, (expired_key, user_id)) is None
        assert session.get(IdempotencyRecord, (active_key, user_id)) is not None
