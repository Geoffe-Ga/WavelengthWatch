from __future__ import annotations

from datetime import datetime

import pytest
from sqlmodel import create_engine, select

import backend.db as db_module
from backend.db import get_session, init_db
from backend.models import EntryDetail, JournalEntry


@pytest.fixture(name="setup_db")
def fixture_setup_db(tmp_path, monkeypatch):
    """Configure an isolated SQLite database for each test."""

    test_db = tmp_path / "test.db"
    monkeypatch.setattr(db_module, "DATABASE_FILE", test_db)
    monkeypatch.setattr(db_module, "DATABASE_URL", f"sqlite:///{test_db}")
    engine = create_engine(db_module.DATABASE_URL, echo=False)
    monkeypatch.setattr(db_module, "engine", engine)
    init_db()


def _create_sample_entry() -> int:
    """Helper to persist a journal entry with two details.

    Returns the primary key of the created ``JournalEntry``.
    """

    with get_session() as session:
        entry = JournalEntry(
            timestamp=datetime(2024, 1, 1, 12, 0, 0),
            initiated_by="tester",
        )
        entry.details.append(
            EntryDetail(stage=1, phase=1, dosage=1.0, position=1)
        )
        entry.details.append(
            EntryDetail(stage=2, phase=2, dosage=2.0, position=2)
        )
        session.add(entry)
        session.commit()
        return entry.id  # type: ignore[return-value]


def test_models_persist_and_relate(setup_db):
    entry_id = _create_sample_entry()

    with get_session() as session:
        loaded = session.get(JournalEntry, entry_id)
        assert loaded is not None
        assert len(loaded.details) == 2
        assert {d.position for d in loaded.details} == {1, 2}


def test_cascade_delete_removes_details(setup_db):
    entry_id = _create_sample_entry()

    with get_session() as session:
        entry = session.get(JournalEntry, entry_id)
        assert entry is not None
        session.delete(entry)
        session.commit()

    with get_session() as session:
        remaining = session.exec(select(EntryDetail)).all()
        assert remaining == []
