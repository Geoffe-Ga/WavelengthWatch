from __future__ import annotations

from collections.abc import Iterator
from contextlib import contextmanager
from pathlib import Path

from sqlmodel import Session, SQLModel, create_engine

# Import models so that SQLModel is aware of them before table creation.
# The imported module is not used directly but ensures that metadata
# includes all model definitions when `init_db` is called.
from . import models  # noqa: F401

# Database location
DATABASE_FILE = Path(__file__).with_name("database.db")
DATABASE_URL = f"sqlite:///{DATABASE_FILE}"

# Create the engine that manages connections to the SQLite database.
engine = create_engine(DATABASE_URL, echo=False)


def init_db() -> None:
    """Create database tables for all SQLModel subclasses."""
    SQLModel.metadata.create_all(engine)


@contextmanager
def get_session() -> Iterator[Session]:
    """Yield a database session scoped to a context manager."""
    with Session(engine) as session:
        yield session


def get_session_dep() -> Iterator[Session]:
    """FastAPI dependency that yields a database session."""
    with get_session() as session:
        yield session
