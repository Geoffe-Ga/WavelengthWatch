"""Tests for Layer API endpoints."""


def test_list_layers_empty(client):
    """Test listing layers when none exist."""
    response = client.get("/layer")
    assert response.status_code == 200
    assert response.json() == []


def test_list_layers_with_data(client, sample_layer):
    """Test listing layers with data."""
    response = client.get("/layer")
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1
    assert data[0]["id"] == sample_layer.id
    assert data[0]["color"] == sample_layer.color


def test_get_layer_exists(client, sample_layer):
    """Test getting a specific layer that exists."""
    response = client.get(f"/layer/{sample_layer.id}")
    assert response.status_code == 200
    data = response.json()
    assert data["id"] == sample_layer.id
    assert data["color"] == sample_layer.color
    assert data["title"] == sample_layer.title
    assert data["subtitle"] == sample_layer.subtitle


def test_get_layer_not_found(client):
    """Test getting a layer that doesn't exist."""
    response = client.get("/layer/999")
    assert response.status_code == 404
    assert "Layer not found" in response.json()["detail"]


def test_create_layer(client):
    """Test creating a new layer."""
    layer_data = {"color": "Purple", "title": "INHABIT", "subtitle": "(Feel)"}
    response = client.post("/layer", json=layer_data)
    assert response.status_code == 201
    data = response.json()
    assert data["color"] == layer_data["color"]
    assert data["title"] == layer_data["title"]
    assert data["subtitle"] == layer_data["subtitle"]
    assert "id" in data


def test_create_layer_invalid_data(client):
    """Test creating a layer with invalid data."""
    layer_data = {
        "color": "Purple",
        # Missing required fields
    }
    response = client.post("/layer", json=layer_data)
    assert response.status_code == 422


def test_update_layer(client, sample_layer):
    """Test updating an existing layer."""
    update_data = {
        "color": "Updated Purple",
        "title": "UPDATED INHABIT",
        "subtitle": "(Updated Feel)",
    }
    response = client.put(f"/layer/{sample_layer.id}", json=update_data)
    assert response.status_code == 200
    data = response.json()
    assert data["id"] == sample_layer.id
    assert data["color"] == update_data["color"]
    assert data["title"] == update_data["title"]
    assert data["subtitle"] == update_data["subtitle"]


def test_update_layer_partial(client, sample_layer):
    """Test partial update of a layer."""
    update_data = {"color": "Updated Purple"}
    response = client.put(f"/layer/{sample_layer.id}", json=update_data)
    assert response.status_code == 200
    data = response.json()
    assert data["id"] == sample_layer.id
    assert data["color"] == update_data["color"]
    assert data["title"] == sample_layer.title  # Unchanged
    assert data["subtitle"] == sample_layer.subtitle  # Unchanged


def test_update_layer_not_found(client):
    """Test updating a layer that doesn't exist."""
    update_data = {"color": "Purple"}
    response = client.put("/layer/999", json=update_data)
    assert response.status_code == 404
    assert "Layer not found" in response.json()["detail"]


def test_delete_layer(client, sample_layer):
    """Test deleting an existing layer."""
    response = client.delete(f"/layer/{sample_layer.id}")
    assert response.status_code == 204

    # Verify layer is deleted
    response = client.get(f"/layer/{sample_layer.id}")
    assert response.status_code == 404


def test_delete_layer_not_found(client):
    """Test deleting a layer that doesn't exist."""
    response = client.delete("/layer/999")
    assert response.status_code == 404
    assert "Layer not found" in response.json()["detail"]


def test_list_layers_pagination(client):
    """Test pagination parameters."""
    # Create multiple layers
    for i in range(5):
        layer_data = {
            "color": f"Color{i}",
            "title": f"Title{i}",
            "subtitle": f"Subtitle{i}",
        }
        client.post("/layer", json=layer_data)

    # Test limit
    response = client.get("/layer?limit=3")
    assert response.status_code == 200
    assert len(response.json()) == 3

    # Test offset
    response = client.get("/layer?offset=2&limit=2")
    assert response.status_code == 200
    assert len(response.json()) == 2
