"""Shared backend test fixtures for the FastAPI service."""

from __future__ import annotations

from collections.abc import Iterator
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

from backend import database
from backend.app import create_application


@pytest.fixture()
def client(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> Iterator[TestClient]:
    """Yield an API client backed by an isolated SQLite database."""

    db_path = tmp_path / "app.db"
    database_url = f"sqlite:///{db_path}"
    monkeypatch.setenv("DATABASE_URL", database_url)

    engine = database.configure_engine(database_url)

    app = create_application()

    with TestClient(app) as api_client:
        yield api_client

    engine.dispose()
    if db_path.exists():
        db_path.unlink()
