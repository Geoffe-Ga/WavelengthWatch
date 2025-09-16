"""Tests for Strategy API endpoints."""


def test_list_strategies_empty(client):
    """Test listing strategies when none exist."""
    response = client.get("/strategy")
    assert response.status_code == 200
    assert response.json() == []


def test_list_strategies_with_data(
    client, sample_strategy, sample_layer, sample_phase
):
    """Test listing strategies with data."""
    response = client.get("/strategy")
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1
    assert data[0]["id"] == sample_strategy.id
    assert data[0]["strategy"] == sample_strategy.strategy
    assert data[0]["layer"]["id"] == sample_layer.id
    assert data[0]["phase"]["id"] == sample_phase.id


def test_get_strategy_exists(client, sample_strategy):
    """Test getting a specific strategy that exists."""
    response = client.get(f"/strategy/{sample_strategy.id}")
    assert response.status_code == 200
    data = response.json()
    assert data["id"] == sample_strategy.id
    assert data["strategy"] == sample_strategy.strategy
    assert data["layer_id"] == sample_strategy.layer_id
    assert data["phase_id"] == sample_strategy.phase_id


def test_get_strategy_not_found(client):
    """Test getting a strategy that doesn't exist."""
    response = client.get("/strategy/999")
    assert response.status_code == 404
    assert "Strategy not found" in response.json()["detail"]


def test_create_strategy(client, sample_layer, sample_phase):
    """Test creating a new strategy."""
    strategy_data = {
        "strategy": "New Strategy",
        "layer_id": sample_layer.id,
        "phase_id": sample_phase.id,
    }
    response = client.post("/strategy", json=strategy_data)
    assert response.status_code == 201
    data = response.json()
    assert data["strategy"] == strategy_data["strategy"]
    assert data["layer_id"] == strategy_data["layer_id"]
    assert data["phase_id"] == strategy_data["phase_id"]
    assert "id" in data


def test_create_strategy_invalid_data(client):
    """Test creating a strategy with invalid data."""
    strategy_data = {
        "strategy": "Test Strategy",
        # Missing layer_id and phase_id
    }
    response = client.post("/strategy", json=strategy_data)
    assert response.status_code == 422


def test_update_strategy(client, sample_strategy):
    """Test updating an existing strategy."""
    update_data = {"strategy": "Updated Strategy"}
    response = client.put(f"/strategy/{sample_strategy.id}", json=update_data)
    assert response.status_code == 200
    data = response.json()
    assert data["id"] == sample_strategy.id
    assert data["strategy"] == update_data["strategy"]
    assert data["layer_id"] == sample_strategy.layer_id  # Unchanged
    assert data["phase_id"] == sample_strategy.phase_id  # Unchanged


def test_update_strategy_not_found(client):
    """Test updating a strategy that doesn't exist."""
    update_data = {"strategy": "Updated"}
    response = client.put("/strategy/999", json=update_data)
    assert response.status_code == 404
    assert "Strategy not found" in response.json()["detail"]


def test_delete_strategy(client, sample_strategy):
    """Test deleting an existing strategy."""
    response = client.delete(f"/strategy/{sample_strategy.id}")
    assert response.status_code == 204

    # Verify strategy is deleted
    response = client.get(f"/strategy/{sample_strategy.id}")
    assert response.status_code == 404


def test_delete_strategy_not_found(client):
    """Test deleting a strategy that doesn't exist."""
    response = client.delete("/strategy/999")
    assert response.status_code == 404
    assert "Strategy not found" in response.json()["detail"]


def test_filter_strategies_by_layer(client, sample_strategy):
    """Test filtering strategies by layer_id."""
    response = client.get(f"/strategy?layer_id={sample_strategy.layer_id}")
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1
    assert data[0]["id"] == sample_strategy.id

    # Test with non-existent layer
    response = client.get("/strategy?layer_id=999")
    assert response.status_code == 200
    assert response.json() == []


def test_filter_strategies_by_phase(client, sample_strategy):
    """Test filtering strategies by phase_id."""
    response = client.get(f"/strategy?phase_id={sample_strategy.phase_id}")
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1
    assert data[0]["id"] == sample_strategy.id

    # Test with non-existent phase
    response = client.get("/strategy?phase_id=999")
    assert response.status_code == 200
    assert response.json() == []


def test_filter_strategies_multiple_params(client, sample_strategy):
    """Test filtering strategies with multiple parameters."""
    response = client.get(
        f"/strategy?layer_id={sample_strategy.layer_id}"
        f"&phase_id={sample_strategy.phase_id}"
    )
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1
    assert data[0]["id"] == sample_strategy.id

    # Test with conflicting filters
    response = client.get(
        f"/strategy?layer_id={sample_strategy.layer_id}" "&phase_id=999"
    )
    assert response.status_code == 200
    assert response.json() == []
