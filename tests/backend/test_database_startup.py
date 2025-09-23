"""Tests for database startup and schema validation."""

from __future__ import annotations

from sqlmodel import Session, select

from backend import database
from backend.models import Strategy


def test_database_startup_creates_correct_schema(client) -> None:
    """Regression test for ensuring database startup works with correct Strategy schema.

    This test specifically validates that the Strategy table is created with the
    correct 'color_layer_id' column and that seeding works correctly.
    """
    # Test that we can successfully query strategies (would fail with schema mismatch)
    response = client.get("/strategy", params={"color_layer_id": 1})
    assert response.status_code == 200

    # Verify that strategies were seeded and have the correct schema
    strategies = response.json()
    assert strategies, "Expected strategies to be seeded during startup"

    # Verify the strategy has the expected fields including layer_id
    strategy = strategies[0]
    assert "id" in strategy
    assert "strategy" in strategy
    assert "color_layer_id" in strategy  # This is the key field that was causing issues
    assert "phase_id" in strategy
    assert isinstance(strategy["color_layer_id"], int)
    assert isinstance(strategy["phase_id"], int)


def test_database_direct_strategy_query(client) -> None:
    """Direct database test to ensure Strategy model works correctly.

    This test bypasses the API and directly tests the database model to ensure
    the schema is correctly defined and queryable.
    """
    with Session(database.engine) as session:
        # This query would fail if the Strategy table has incorrect schema
        strategies = session.exec(select(Strategy).limit(5)).all()
        assert strategies, "Expected strategies to be seeded"

        # Verify strategy objects have the correct attributes
        strategy = strategies[0]
        assert hasattr(strategy, "id")
        assert hasattr(strategy, "strategy")
        assert hasattr(strategy, "color_layer_id")  # Key field that was missing
        assert hasattr(strategy, "phase_id")
        assert isinstance(strategy.color_layer_id, int)
        assert isinstance(strategy.phase_id, int)


def test_app_startup_completes_successfully(client) -> None:
    """Test that the FastAPI app startup lifecycle completes without errors.

    This test ensures that the lifespan event (which includes database creation
    and seeding) runs successfully during app startup.
    """
    # If we can make any successful request, it means startup completed
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}

    # Verify that database seeding populated data
    response = client.get("/strategy")
    assert response.status_code == 200
    strategies = response.json()
    assert strategies, "Database should be seeded with strategies during startup"
