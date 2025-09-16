"""Tests for Journal API endpoints."""


def test_list_journal_empty(client):
    """Test listing journal entries when none exist."""
    response = client.get("/journal")
    assert response.status_code == 200
    assert response.json() == []


def test_list_journal_with_data(
    client, sample_journal, sample_curriculum, sample_strategy
):
    """Test listing journal entries with data."""
    response = client.get("/journal")
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1
    assert data[0]["id"] == sample_journal.id
    assert data[0]["user_id"] == sample_journal.user_id
    assert data[0]["curriculum"]["id"] == sample_curriculum.id
    assert data[0]["strategy"]["id"] == sample_strategy.id


def test_get_journal_exists(client, sample_journal):
    """Test getting a specific journal entry that exists."""
    response = client.get(f"/journal/{sample_journal.id}")
    assert response.status_code == 200
    data = response.json()
    assert data["id"] == sample_journal.id
    assert data["user_id"] == sample_journal.user_id
    assert data["curriculum_id"] == sample_journal.curriculum_id


def test_get_journal_not_found(client):
    """Test getting a journal entry that doesn't exist."""
    response = client.get("/journal/999")
    assert response.status_code == 404
    assert "Journal entry not found" in response.json()["detail"]


def test_create_journal(client, sample_curriculum, sample_strategy):
    """Test creating a new journal entry."""
    journal_data = {
        "created_at": "2025-09-16T15:30:00Z",
        "user_id": 1,
        "curriculum_id": sample_curriculum.id,
        "strategy_id": sample_strategy.id,
    }
    response = client.post("/journal", json=journal_data)
    assert response.status_code == 201
    data = response.json()
    assert data["user_id"] == journal_data["user_id"]
    assert data["curriculum_id"] == journal_data["curriculum_id"]
    assert data["strategy_id"] == journal_data["strategy_id"]
    assert "id" in data


def test_create_journal_with_secondary_curriculum(client, sample_curriculum):
    """Test creating a journal entry with secondary curriculum."""
    journal_data = {
        "created_at": "2025-09-16T15:30:00Z",
        "user_id": 1,
        "curriculum_id": sample_curriculum.id,
        "secondary_curriculum_id": sample_curriculum.id,  # Use same curriculum for test
    }
    response = client.post("/journal", json=journal_data)
    assert response.status_code == 201
    data = response.json()
    assert data["curriculum_id"] == journal_data["curriculum_id"]
    assert (
        data["secondary_curriculum_id"]
        == journal_data["secondary_curriculum_id"]
    )


def test_create_journal_optional_fields(client, sample_curriculum):
    """Test creating a journal entry with minimal required fields."""
    journal_data = {
        "created_at": "2025-09-16T15:30:00Z",
        "user_id": 1,
        "curriculum_id": sample_curriculum.id,
        # strategy_id and secondary_curriculum_id are optional
    }
    response = client.post("/journal", json=journal_data)
    assert response.status_code == 201
    data = response.json()
    assert data["user_id"] == journal_data["user_id"]
    assert data["curriculum_id"] == journal_data["curriculum_id"]
    assert data["strategy_id"] is None
    assert data["secondary_curriculum_id"] is None


def test_create_journal_invalid_data(client):
    """Test creating a journal entry with invalid data."""
    journal_data = {
        "created_at": "2025-09-16T15:30:00Z",
        "user_id": 1,
        # Missing required curriculum_id
    }
    response = client.post("/journal", json=journal_data)
    assert response.status_code == 422


def test_update_journal(client, sample_journal):
    """Test updating an existing journal entry."""
    update_data = {"user_id": 2}
    response = client.put(f"/journal/{sample_journal.id}", json=update_data)
    assert response.status_code == 200
    data = response.json()
    assert data["id"] == sample_journal.id
    assert data["user_id"] == update_data["user_id"]


def test_update_journal_not_found(client):
    """Test updating a journal entry that doesn't exist."""
    update_data = {"user_id": 2}
    response = client.put("/journal/999", json=update_data)
    assert response.status_code == 404
    assert "Journal entry not found" in response.json()["detail"]


def test_delete_journal(client, sample_journal):
    """Test deleting an existing journal entry."""
    response = client.delete(f"/journal/{sample_journal.id}")
    assert response.status_code == 204

    # Verify journal entry is deleted
    response = client.get(f"/journal/{sample_journal.id}")
    assert response.status_code == 404


def test_delete_journal_not_found(client):
    """Test deleting a journal entry that doesn't exist."""
    response = client.delete("/journal/999")
    assert response.status_code == 404
    assert "Journal entry not found" in response.json()["detail"]


def test_filter_journal_by_user(client, sample_journal):
    """Test filtering journal entries by user_id."""
    response = client.get(f"/journal?user_id={sample_journal.user_id}")
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1
    assert data[0]["id"] == sample_journal.id

    # Test with non-existent user
    response = client.get("/journal?user_id=999")
    assert response.status_code == 200
    assert response.json() == []


def test_filter_journal_by_strategy(client, sample_journal):
    """Test filtering journal entries by strategy_id."""
    response = client.get(
        f"/journal?strategy_id={sample_journal.strategy_id}"
    )
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1
    assert data[0]["id"] == sample_journal.id

    # Test with non-existent strategy
    response = client.get("/journal?strategy_id=999")
    assert response.status_code == 200
    assert response.json() == []


def test_filter_journal_by_date_range(client, sample_journal):
    """Test filtering journal entries by date range."""
    # Test from date before the entry
    response = client.get("/journal?from=2025-09-15T00:00:00Z")
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1

    # Test from date after the entry
    response = client.get("/journal?from=2025-09-17T00:00:00Z")
    assert response.status_code == 200
    assert response.json() == []

    # Test to date after the entry
    response = client.get("/journal?to=2025-09-17T00:00:00Z")
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1

    # Test to date before the entry
    response = client.get("/journal?to=2025-09-15T00:00:00Z")
    assert response.status_code == 200
    assert response.json() == []


def test_journal_entries_ordered_by_created_at(client, sample_curriculum):
    """Test that journal entries are returned in descending order by created_at."""
    # Create multiple journal entries with different timestamps
    journal_data_1 = {
        "created_at": "2025-09-16T10:00:00Z",
        "user_id": 1,
        "curriculum_id": sample_curriculum.id,
    }
    journal_data_2 = {
        "created_at": "2025-09-16T12:00:00Z",
        "user_id": 1,
        "curriculum_id": sample_curriculum.id,
    }

    # Create entries (newer one first)
    client.post("/journal", json=journal_data_2)
    client.post("/journal", json=journal_data_1)

    # Get all entries
    response = client.get("/journal")
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 2

    # Verify they're ordered by created_at desc (newer first)
    assert data[0]["created_at"] > data[1]["created_at"]
