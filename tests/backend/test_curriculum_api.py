"""Tests for Curriculum API endpoints."""


def test_list_curriculum_empty(client):
    """Test listing curriculum when none exist."""
    response = client.get("/curriculum")
    assert response.status_code == 200
    assert response.json() == []


def test_list_curriculum_with_data(
    client, sample_curriculum, sample_layer, sample_phase
):
    """Test listing curriculum with data."""
    response = client.get("/curriculum")
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1
    assert data[0]["id"] == sample_curriculum.id
    assert data[0]["expression"] == sample_curriculum.expression
    assert data[0]["layer"]["id"] == sample_layer.id
    assert data[0]["phase"]["id"] == sample_phase.id


def test_get_curriculum_exists(client, sample_curriculum):
    """Test getting a specific curriculum that exists."""
    response = client.get(f"/curriculum/{sample_curriculum.id}")
    assert response.status_code == 200
    data = response.json()
    assert data["id"] == sample_curriculum.id
    assert data["expression"] == sample_curriculum.expression
    assert data["dosage"] == sample_curriculum.dosage.value


def test_get_curriculum_not_found(client):
    """Test getting a curriculum that doesn't exist."""
    response = client.get("/curriculum/999")
    assert response.status_code == 404
    assert "Curriculum not found" in response.json()["detail"]


def test_create_curriculum(client, sample_layer, sample_phase):
    """Test creating a new curriculum."""
    curriculum_data = {
        "layer_id": sample_layer.id,
        "phase_id": sample_phase.id,
        "dosage": "Medicinal",
        "expression": "New Expression",
    }
    response = client.post("/curriculum", json=curriculum_data)
    assert response.status_code == 201
    data = response.json()
    assert data["layer_id"] == curriculum_data["layer_id"]
    assert data["phase_id"] == curriculum_data["phase_id"]
    assert data["dosage"] == curriculum_data["dosage"]
    assert data["expression"] == curriculum_data["expression"]
    assert "id" in data


def test_create_curriculum_invalid_dosage(client, sample_layer, sample_phase):
    """Test creating a curriculum with invalid dosage."""
    curriculum_data = {
        "layer_id": sample_layer.id,
        "phase_id": sample_phase.id,
        "dosage": "Invalid",  # Should be Medicinal or Toxic
        "expression": "Expression",
    }
    response = client.post("/curriculum", json=curriculum_data)
    assert response.status_code == 422


def test_update_curriculum(client, sample_curriculum):
    """Test updating an existing curriculum."""
    update_data = {"expression": "Updated Expression", "dosage": "Toxic"}
    response = client.put(
        f"/curriculum/{sample_curriculum.id}", json=update_data
    )
    assert response.status_code == 200
    data = response.json()
    assert data["id"] == sample_curriculum.id
    assert data["expression"] == update_data["expression"]
    assert data["dosage"] == update_data["dosage"]


def test_update_curriculum_not_found(client):
    """Test updating a curriculum that doesn't exist."""
    update_data = {"expression": "Updated"}
    response = client.put("/curriculum/999", json=update_data)
    assert response.status_code == 404
    assert "Curriculum not found" in response.json()["detail"]


def test_delete_curriculum(client, sample_curriculum):
    """Test deleting an existing curriculum."""
    response = client.delete(f"/curriculum/{sample_curriculum.id}")
    assert response.status_code == 204

    # Verify curriculum is deleted
    response = client.get(f"/curriculum/{sample_curriculum.id}")
    assert response.status_code == 404


def test_delete_curriculum_not_found(client):
    """Test deleting a curriculum that doesn't exist."""
    response = client.delete("/curriculum/999")
    assert response.status_code == 404
    assert "Curriculum not found" in response.json()["detail"]


def test_filter_curriculum_by_layer(client, sample_curriculum):
    """Test filtering curriculum by layer_id."""
    response = client.get(
        f"/curriculum?layer_id={sample_curriculum.layer_id}"
    )
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1
    assert data[0]["id"] == sample_curriculum.id

    # Test with non-existent layer
    response = client.get("/curriculum?layer_id=999")
    assert response.status_code == 200
    assert response.json() == []


def test_filter_curriculum_by_phase(client, sample_curriculum):
    """Test filtering curriculum by phase_id."""
    response = client.get(
        f"/curriculum?phase_id={sample_curriculum.phase_id}"
    )
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1
    assert data[0]["id"] == sample_curriculum.id

    # Test with non-existent phase
    response = client.get("/curriculum?phase_id=999")
    assert response.status_code == 200
    assert response.json() == []


def test_filter_curriculum_by_dosage(client, sample_curriculum):
    """Test filtering curriculum by dosage."""
    response = client.get(
        f"/curriculum?dosage={sample_curriculum.dosage.value}"
    )
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1
    assert data[0]["id"] == sample_curriculum.id

    # Test with opposite dosage
    opposite_dosage = (
        "Toxic"
        if sample_curriculum.dosage.value == "Medicinal"
        else "Medicinal"
    )
    response = client.get(f"/curriculum?dosage={opposite_dosage}")
    assert response.status_code == 200
    assert response.json() == []


def test_filter_curriculum_multiple_params(client, sample_curriculum):
    """Test filtering curriculum with multiple parameters."""
    response = client.get(
        f"/curriculum?layer_id={sample_curriculum.layer_id}"
        f"&phase_id={sample_curriculum.phase_id}"
        f"&dosage={sample_curriculum.dosage.value}"
    )
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1
    assert data[0]["id"] == sample_curriculum.id
