"""Shared backend test fixtures."""

from __future__ import annotations

from collections.abc import Iterator

import pytest
from fastapi.testclient import TestClient
from sqlmodel import SQLModel, create_engine

import backend.db as db_module
from backend.db import init_db


@pytest.fixture()
def client(tmp_path_factory: pytest.TempPathFactory, monkeypatch) -> Iterator[TestClient]:
    """Provide an API client backed by an isolated SQLite database."""

    db_dir = tmp_path_factory.mktemp("db")
    test_db = db_dir / "test.db"
    monkeypatch.setattr(db_module, "DATABASE_FILE", test_db)
    monkeypatch.setattr(db_module, "DATABASE_URL", f"sqlite:///{test_db}")
    engine = create_engine(db_module.DATABASE_URL, echo=False)
    monkeypatch.setattr(db_module, "engine", engine)
    init_db()

    from backend.app import app

    api_client = TestClient(app)
    try:
        yield api_client
    finally:
        api_client.close()
        SQLModel.metadata.drop_all(engine)
        engine.dispose()
        if test_db.exists():
            test_db.unlink()
