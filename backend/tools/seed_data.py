"""Seed the database from CSV fixtures stored on disk."""

from __future__ import annotations

import csv
from collections.abc import Iterable
from datetime import UTC, datetime
from pathlib import Path

from sqlmodel import Session, SQLModel, select

from ..models import Curriculum, Dosage, InitiatedBy, Journal, Layer, Phase, Strategy

DATA_DIR = Path(__file__).resolve().parent / "data"


def _iter_rows(filename: str) -> Iterable[dict[str, str]]:
    csv_path = DATA_DIR / filename
    with csv_path.open(newline="", encoding="utf-8-sig") as csv_file:
        reader = csv.DictReader(csv_file)
        for row in reader:
            if not row:
                continue
            if all(
                (value is None or str(value).strip() == "") for value in row.values()
            ):
                continue
            yield {key: (value or "") for key, value in row.items()}


def _table_has_rows(session: Session, model: type[SQLModel]) -> bool:
    return session.exec(select(model).limit(1)).first() is not None


def _load_layers() -> list[Layer]:
    records: list[Layer] = []
    for row in _iter_rows("layer.csv"):
        records.append(
            Layer(
                id=int(row["id"]),
                color=row["color"].strip(),
                title=row["title"].strip(),
                subtitle=row["subtitle"].strip(),
            )
        )
    return records


def _load_phases() -> list[Phase]:
    records: list[Phase] = []
    for row in _iter_rows("phase.csv"):
        records.append(Phase(id=int(row["id"]), name=row["name"].strip()))
    return records


def _load_curriculum() -> list[Curriculum]:
    records: list[Curriculum] = []
    for row in _iter_rows("curriculum.csv"):
        records.append(
            Curriculum(
                id=int(row["id"]),
                layer_id=int(row["stage_id"]),
                phase_id=int(row["phase_id"]),
                dosage=Dosage(row["dosage"].strip()),
                expression=row["expression"].strip(),
            )
        )
    return records


def _load_strategies() -> list[Strategy]:
    records: list[Strategy] = []
    for row in _iter_rows("strategy.csv"):
        records.append(
            Strategy(
                id=int(row["id"]),
                strategy=row["strategy"].strip(),
                layer_id=int(row["layer_id"]),
                color_layer_id=int(row["color_layer_id"]),
                phase_id=int(row["phase_id"]),
            )
        )
    return records


def _parse_optional_int(value: str) -> int | None:
    value = value.strip()
    if not value or value.upper() == "NULL":
        return None
    return int(float(value))


def _load_journal() -> list[Journal]:
    records: list[Journal] = []
    for row in _iter_rows("journal.csv"):
        created_at = datetime.fromisoformat(
            row["created_at"].replace("Z", "+00:00")
        ).astimezone(UTC)

        # Parse initiated_by, defaulting to SELF if not present
        initiated_by_str = row.get("initiated_by", "self").strip().lower()
        initiated_by = (
            InitiatedBy.SCHEDULED
            if initiated_by_str == "scheduled"
            else InitiatedBy.SELF
        )

        records.append(
            Journal(
                id=int(row["id"]),
                created_at=created_at,
                user_id=int(row["user_id"]),
                curriculum_id=int(row["curriculum_id"]),
                secondary_curriculum_id=_parse_optional_int(
                    row["secondary_curriculum_id"]
                ),
                strategy_id=_parse_optional_int(row["strategy_id"]),
                initiated_by=initiated_by,
            )
        )
    return records


def seed_database(session: Session) -> None:
    """Populate the database with seed data when tables are empty."""

    changes = False
    if not _table_has_rows(session, Layer):
        session.add_all(_load_layers())
        changes = True
    if not _table_has_rows(session, Phase):
        session.add_all(_load_phases())
        changes = True
    if not _table_has_rows(session, Curriculum):
        session.add_all(_load_curriculum())
        changes = True
    if not _table_has_rows(session, Strategy):
        session.add_all(_load_strategies())
        changes = True
    if not _table_has_rows(session, Journal):
        session.add_all(_load_journal())
        changes = True
    if changes:
        session.commit()


__all__ = ["seed_database"]


if __name__ == "__main__":  # pragma: no cover - manual execution helper
    from ..database import create_db_and_tables, engine

    create_db_and_tables()
    with Session(engine) as _session:
        seed_database(_session)
