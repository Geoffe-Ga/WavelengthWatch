"""Integration tests for the journal endpoints."""
from __future__ import annotations

import os
from datetime import datetime

import pytest
from httpx import AsyncClient, ASGITransport
from sqlmodel import SQLModel, Session

os.environ.setdefault("DATABASE_URL", "sqlite://")

from app.main import app  # noqa: E402  # pylint: disable=wrong-import-position
from app.database import engine  # noqa: E402
from app.seed_data import seed_data  # noqa: E402


@pytest.fixture(autouse=True)
def prepare_database() -> None:
    """Ensure a clean database with seeded data for each test."""

    SQLModel.metadata.drop_all(engine)
    SQLModel.metadata.create_all(engine)
    with Session(engine) as session:
        seed_data(session)
    yield
    SQLModel.metadata.drop_all(engine)


@pytest.mark.asyncio
async def test_journal_crud_flow() -> None:
    """Exercise the happy-path CRUD flow for journal entries."""

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        list_response = await client.get("/journal/")
        assert list_response.status_code == 200
        starting_count = len(list_response.json())

        payload = {
            "created_at": "2025-10-01T12:00:00Z",
            "user_id": 42,
            "curriculum_id": 1,
            "secondary_curriculum_id": 2,
            "strategy_id": 1,
        }
        create_response = await client.post("/journal/", json=payload)
        assert create_response.status_code == 201, create_response.text
        created = create_response.json()
        created_id = created["id"]

        parsed_created_at = datetime.fromisoformat(created["created_at"].replace("Z", "+00:00"))
        expected_created_at = datetime.fromisoformat(payload["created_at"].replace("Z", "+00:00"))
        assert parsed_created_at == expected_created_at
        assert created["curriculum"]["id"] == payload["curriculum_id"]
        assert created["secondary_curriculum"]["id"] == payload["secondary_curriculum_id"]
        assert created["strategy"]["id"] == payload["strategy_id"]

        detail_response = await client.get(f"/journal/{created_id}")
        assert detail_response.status_code == 200
        assert detail_response.json()["id"] == created_id

        update_payload = {"strategy_id": 2}
        update_response = await client.put(f"/journal/{created_id}", json=update_payload)
        assert update_response.status_code == 200
        assert update_response.json()["strategy"]["id"] == update_payload["strategy_id"]

        delete_response = await client.delete(f"/journal/{created_id}")
        assert delete_response.status_code == 204

        # Confirm the entry is gone and count restored
        final_list = await client.get("/journal/")
        assert final_list.status_code == 200
        assert len(final_list.json()) == starting_count

        missing_response = await client.get(f"/journal/{created_id}")
        assert missing_response.status_code == 404
