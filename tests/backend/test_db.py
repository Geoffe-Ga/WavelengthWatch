from sqlmodel import Field, SQLModel, select

import backend.db as db_module
from backend.db import get_session, init_db


class Sample(SQLModel, table=True):
    id: int | None = Field(default=None, primary_key=True)
    name: str


def test_session_persists_and_reads_row(tmp_path, monkeypatch):
    # Use temporary database for testing
    test_db = tmp_path / "test.db"
    monkeypatch.setattr(db_module, "DATABASE_FILE", test_db)
    monkeypatch.setattr(db_module, "DATABASE_URL", f"sqlite:///{test_db}")
    init_db()
    with get_session() as session:
        sample = Sample(name="example")
        session.add(sample)
        session.commit()
        session.refresh(sample)
        sample_id = sample.id

    with get_session() as session:
        statement = select(Sample).where(Sample.id == sample_id)
        result = session.exec(statement).first()
    assert result is not None
    assert result.name == "example"
