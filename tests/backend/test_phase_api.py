"""Tests for Phase API endpoints."""


def test_list_phases_empty(client):
    """Test listing phases when none exist."""
    response = client.get("/phase")
    assert response.status_code == 200
    assert response.json() == []


def test_list_phases_with_data(client, sample_phase):
    """Test listing phases with data."""
    response = client.get("/phase")
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1
    assert data[0]["id"] == sample_phase.id
    assert data[0]["name"] == sample_phase.name


def test_get_phase_exists(client, sample_phase):
    """Test getting a specific phase that exists."""
    response = client.get(f"/phase/{sample_phase.id}")
    assert response.status_code == 200
    data = response.json()
    assert data["id"] == sample_phase.id
    assert data["name"] == sample_phase.name


def test_get_phase_not_found(client):
    """Test getting a phase that doesn't exist."""
    response = client.get("/phase/999")
    assert response.status_code == 404
    assert "Phase not found" in response.json()["detail"]


def test_create_phase(client):
    """Test creating a new phase."""
    phase_data = {"name": "Peaking"}
    response = client.post("/phase", json=phase_data)
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == phase_data["name"]
    assert "id" in data


def test_create_phase_invalid_data(client):
    """Test creating a phase with invalid data."""
    phase_data = {
        # Missing required name field
    }
    response = client.post("/phase", json=phase_data)
    assert response.status_code == 422


def test_update_phase(client, sample_phase):
    """Test updating an existing phase."""
    update_data = {"name": "Updated Rising"}
    response = client.put(f"/phase/{sample_phase.id}", json=update_data)
    assert response.status_code == 200
    data = response.json()
    assert data["id"] == sample_phase.id
    assert data["name"] == update_data["name"]


def test_update_phase_not_found(client):
    """Test updating a phase that doesn't exist."""
    update_data = {"name": "Rising"}
    response = client.put("/phase/999", json=update_data)
    assert response.status_code == 404
    assert "Phase not found" in response.json()["detail"]


def test_delete_phase(client, sample_phase):
    """Test deleting an existing phase."""
    response = client.delete(f"/phase/{sample_phase.id}")
    assert response.status_code == 204

    # Verify phase is deleted
    response = client.get(f"/phase/{sample_phase.id}")
    assert response.status_code == 404


def test_delete_phase_not_found(client):
    """Test deleting a phase that doesn't exist."""
    response = client.delete("/phase/999")
    assert response.status_code == 404
    assert "Phase not found" in response.json()["detail"]
