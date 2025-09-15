from __future__ import annotations

from datetime import datetime

import pytest
from sqlmodel import create_engine, select

import backend.db as db_module
from backend.db import get_session, init_db
from backend.models import (
    EntryDetail,
    JournalEntry,
    SelfCareLog,
    SelfCareStrategy,
)


@pytest.fixture(name="setup_db")
def fixture_setup_db(tmp_path, monkeypatch):
    """Configure an isolated SQLite database for each test."""

    test_db = tmp_path / "test.db"
    monkeypatch.setattr(db_module, "DATABASE_FILE", test_db)
    monkeypatch.setattr(db_module, "DATABASE_URL", f"sqlite:///{test_db}")
    engine = create_engine(db_module.DATABASE_URL, echo=False)
    monkeypatch.setattr(db_module, "engine", engine)
    init_db()


def _create_sample_entry() -> tuple[int, int]:
    """Persist a sample entry with detail and self-care log.

    Returns the primary keys of the created ``JournalEntry`` and
    ``SelfCareStrategy``.
    """

    with get_session() as session:
        strategy = SelfCareStrategy(color="Blue", strategy="deep breathing")
        session.add(strategy)
        session.commit()

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
        entry.self_care_logs.append(
            SelfCareLog(
                strategy_id=strategy.id,  # type: ignore[arg-type]
                timestamp=datetime(2024, 1, 1, 12, 30, 0),
            )
        )
        session.add(entry)
        session.commit()
        return entry.id, strategy.id  # type: ignore[return-value]


def test_models_persist_and_relate(setup_db):
    entry_id, strategy_id = _create_sample_entry()

    with get_session() as session:
        loaded = session.get(JournalEntry, entry_id)
        assert loaded is not None
        assert len(loaded.details) == 2
        assert {d.position for d in loaded.details} == {1, 2}
        assert len(loaded.self_care_logs) == 1
        assert loaded.self_care_logs[0].strategy_id == strategy_id
        assert loaded.self_care_logs[0].strategy.strategy == "deep breathing"


def test_cascade_delete_removes_related_records(setup_db):
    entry_id, strategy_id = _create_sample_entry()

    with get_session() as session:
        entry = session.get(JournalEntry, entry_id)
        assert entry is not None
        session.delete(entry)
        session.commit()

    with get_session() as session:
        remaining_details = session.exec(select(EntryDetail)).all()
        remaining_logs = session.exec(select(SelfCareLog)).all()
        remaining_strategies = session.exec(select(SelfCareStrategy)).all()
        assert remaining_details == []
        assert remaining_logs == []
        # Strategies are global and should not be deleted when logs are removed
        assert len(remaining_strategies) == 1
        assert remaining_strategies[0].id == strategy_id
