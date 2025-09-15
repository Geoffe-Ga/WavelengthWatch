from __future__ import annotations

import json
from collections.abc import Iterator
from contextlib import contextmanager
from pathlib import Path

from sqlmodel import Session, SQLModel, create_engine, select

# Import models so that SQLModel is aware of them before table creation.
# The imported module is not used directly but ensures that metadata
# includes all model definitions when `init_db` is called.
from . import models  # noqa: F401
from .constants import PHASE_ORDER

# Database location
DATABASE_FILE = Path(__file__).with_name("database.db")
DATABASE_URL = f"sqlite:///{DATABASE_FILE}"

# Create the engine that manages connections to the SQLite database.
engine = create_engine(DATABASE_URL, echo=False)


def init_db() -> None:
    """Create database tables for all SQLModel subclasses."""
    SQLModel.metadata.create_all(engine)
    _seed_self_care_strategies()


def _seed_self_care_strategies() -> None:
    """Populate default self-care strategies if the table is empty."""

    from .models import SelfCareStrategy

    data_file = Path(__file__).with_name("data") / "prod" / "a-w-strategies.json"
    if not data_file.exists():
        return

    with Session(engine) as session:
        exists = session.exec(select(SelfCareStrategy.id).limit(1)).first()
        if exists is not None:
            return

        payload: dict[str, list[dict[str, str]]] = json.loads(
            data_file.read_text(encoding="utf-8")
        )

        for phase in PHASE_ORDER:
            for item in payload.get(phase, []):
                session.add(
                    SelfCareStrategy(
                        color=item["color"],
                        strategy=item["strategy"],
                        phase=phase,
                    )
                )

        for phase, items in payload.items():
            if phase in PHASE_ORDER:
                continue
            for item in items:
                session.add(
                    SelfCareStrategy(
                        color=item["color"],
                        strategy=item["strategy"],
                        phase=phase,
                    )
                )
        session.commit()


@contextmanager
def get_session() -> Iterator[Session]:
    """Yield a database session scoped to a context manager."""
    with Session(engine) as session:
        yield session


def get_session_dep() -> Iterator[Session]:
    """FastAPI dependency that yields a database session."""
    with get_session() as session:
        yield session
