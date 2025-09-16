"""Database configuration and session management utilities."""
from __future__ import annotations

import os
from collections.abc import Generator
from typing import Any

from sqlmodel import Session, SQLModel, create_engine
from sqlalchemy.pool import StaticPool

DATABASE_URL_ENV = "DATABASE_URL"
DEFAULT_SQLITE_URL = "sqlite:///./app.db"


def _create_engine() -> Any:
    """Create a SQLModel compatible engine with sensible defaults."""
    database_url = os.getenv(DATABASE_URL_ENV, DEFAULT_SQLITE_URL)
    engine_kwargs: dict[str, Any] = {"echo": False}

    if database_url.startswith("sqlite"):
        connect_args = {"check_same_thread": False}
        engine_kwargs["connect_args"] = connect_args
        if database_url in {"sqlite://", "sqlite:///:memory:"}:
            engine_kwargs["poolclass"] = StaticPool

    return create_engine(database_url, **engine_kwargs)


engine = _create_engine()


def create_db_and_tables() -> None:
    """Create database tables based on SQLModel metadata."""
    SQLModel.metadata.create_all(engine)


def get_session() -> Generator[Session, None, None]:
    """Yield a SQLModel session to interact with the database."""
    with Session(engine) as session:
        yield session
