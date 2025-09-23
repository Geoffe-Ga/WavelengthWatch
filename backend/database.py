"""Database configuration and session utilities."""

from __future__ import annotations

import os
from collections.abc import Iterator
from typing import Any

from sqlalchemy import event, inspect
from sqlalchemy.engine import Engine
from sqlmodel import Session, SQLModel, create_engine

_DATABASE_URL_ENV = "DATABASE_URL"
_SQLITE_PREFIXES = ("sqlite:///", "sqlite:////")


def _is_sqlite(url: str) -> bool:
    return url.startswith(_SQLITE_PREFIXES)


def _create_engine(url: str) -> Engine:
    connect_args: dict[str, object] = {}
    if _is_sqlite(url):
        connect_args["check_same_thread"] = False
    engine = create_engine(url, connect_args=connect_args, echo=False)
    if _is_sqlite(url):

        @event.listens_for(engine, "connect")
        def _set_sqlite_pragma(
            dbapi_connection: Any, connection_record: Any
        ) -> None:  # pragma: no cover - thin wrapper around SQLAlchemy internals
            cursor = dbapi_connection.cursor()
            try:
                cursor.execute("PRAGMA foreign_keys=ON")
            finally:
                cursor.close()

    return engine


DATABASE_URL = os.getenv(_DATABASE_URL_ENV, "sqlite:///./app.db")
engine: Engine = _create_engine(DATABASE_URL)


def configure_engine(url: str | None = None) -> Engine:
    """Reconfigure the global engine, useful for tests."""

    global engine, DATABASE_URL
    env_url = os.getenv(_DATABASE_URL_ENV, "sqlite:///./app.db")
    target_url = url if url is not None else env_url
    if engine is not None:
        engine.dispose()
    engine = _create_engine(target_url)
    DATABASE_URL = target_url
    return engine


def get_session() -> Iterator[Session]:
    """FastAPI dependency that yields a transactional session."""

    with Session(engine) as session:
        yield session


def create_db_and_tables() -> None:
    """Create all database tables if they do not exist."""

    SQLModel.metadata.create_all(engine)
    _refresh_outdated_tables()


def _refresh_outdated_tables() -> None:
    """Rebuild tables whose on-disk schema is missing required columns."""

    inspector = inspect(engine)
    try:
        columns = inspector.get_columns("journal")
    except Exception:  # pragma: no cover - guard against inspect edge cases
        return

    column_names = {column["name"] for column in columns}
    required_columns = {"source"}
    if required_columns.issubset(column_names):
        return

    journal_table = SQLModel.metadata.tables.get("journal")
    if journal_table is None:  # pragma: no cover - metadata drift safeguard
        return

    journal_table.drop(engine, checkfirst=True)
    journal_table.create(engine, checkfirst=True)


__all__ = [
    "engine",
    "configure_engine",
    "get_session",
    "create_db_and_tables",
    "DATABASE_URL",
]
