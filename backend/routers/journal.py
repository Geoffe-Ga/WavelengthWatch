"""Journal endpoints."""

from __future__ import annotations

from datetime import datetime
from typing import Annotated, cast

from fastapi import APIRouter, Depends, HTTPException, Query, Response, status
from sqlalchemy import desc
from sqlalchemy.engine import ScalarResult
from sqlalchemy.orm import joinedload
from sqlalchemy.sql.elements import ColumnElement
from sqlmodel import Session, select
from sqlmodel.sql.expression import SelectOfScalar

from ..cache import analytics_cache
from ..database import get_session
from ..models import Curriculum, Journal, Strategy
from ..schemas import JournalCreate, JournalRead, JournalUpdate

SessionDep = Annotated[Session, Depends(get_session)]

router = APIRouter(prefix="/journal", tags=["journal"])


def _serialize_journal(journal: Journal) -> JournalRead:
    return JournalRead.model_validate(journal)


def _base_query() -> SelectOfScalar[Journal]:
    created_at = cast(ColumnElement[datetime], Journal.created_at)
    return (
        select(Journal)
        .options(
            joinedload(Journal.curriculum).joinedload(Curriculum.layer),
            joinedload(Journal.curriculum).joinedload(Curriculum.phase),
            joinedload(Journal.secondary_curriculum).joinedload(Curriculum.layer),
            joinedload(Journal.secondary_curriculum).joinedload(Curriculum.phase),
            joinedload(Journal.strategy).joinedload(Strategy.color_layer),
            joinedload(Journal.strategy).joinedload(Strategy.phase),
        )
        .order_by(desc(created_at), cast(ColumnElement[int], Journal.id))
    )


def _get_journal_or_404(journal_id: int, session: Session) -> Journal:
    statement = _base_query().where(Journal.id == journal_id)
    result = cast(ScalarResult[Journal], session.exec(statement))
    journal = result.one_or_none()
    if journal is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Journal not found"
        )
    return journal


def _validate_references(
    session: Session,
    *,
    curriculum_id: int,
    secondary_curriculum_id: int | None,
    strategy_id: int | None,
) -> None:
    if session.get(Curriculum, curriculum_id) is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid curriculum_id",
        )
    if (
        secondary_curriculum_id is not None
        and session.get(Curriculum, secondary_curriculum_id) is None
    ):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid secondary_curriculum_id",
        )
    if strategy_id is not None and session.get(Strategy, strategy_id) is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid strategy_id",
        )


def _ensure_journal_id(journal: Journal) -> int:
    journal_id = journal.id
    if journal_id is None:
        raise RuntimeError("Persisted journal entry is missing a primary key")
    return journal_id


@router.get("", response_model=list[JournalRead])
def list_journal_entries(
    *,
    session: SessionDep,
    limit: Annotated[int, Query(ge=1, le=1000)] = 100,
    offset: Annotated[int, Query(ge=0)] = 0,
    user_id: Annotated[int | None, Query()] = None,
    strategy_id: Annotated[int | None, Query()] = None,
    from_: Annotated[datetime | None, Query(alias="from")] = None,
    to: Annotated[datetime | None, Query()] = None,
) -> list[JournalRead]:
    statement = _base_query()
    if user_id is not None:
        clause = cast(ColumnElement[bool], Journal.user_id == user_id)
        statement = statement.where(clause)
    if strategy_id is not None:
        clause = cast(ColumnElement[bool], Journal.strategy_id == strategy_id)
        statement = statement.where(clause)
    if from_ is not None:
        clause = cast(ColumnElement[bool], Journal.created_at >= from_)
        statement = statement.where(clause)
    if to is not None:
        clause = cast(ColumnElement[bool], Journal.created_at <= to)
        statement = statement.where(clause)
    statement = statement.offset(offset).limit(limit)
    result = cast(ScalarResult[Journal], session.exec(statement))
    return [_serialize_journal(row) for row in result.all()]


@router.get("/{journal_id}", response_model=JournalRead)
def get_journal(journal_id: int, session: SessionDep) -> JournalRead:
    return _serialize_journal(_get_journal_or_404(journal_id, session))


@router.post("", response_model=JournalRead, status_code=status.HTTP_201_CREATED)
def create_journal(payload: JournalCreate, session: SessionDep) -> JournalRead:
    _validate_references(
        session,
        curriculum_id=payload.curriculum_id,
        secondary_curriculum_id=payload.secondary_curriculum_id,
        strategy_id=payload.strategy_id,
    )
    journal = Journal(**payload.model_dump())
    session.add(journal)
    session.commit()
    session.refresh(journal)

    # Invalidate analytics cache for this user since their data changed
    analytics_cache.invalidate_user(payload.user_id)

    journal_id = _ensure_journal_id(journal)
    return _serialize_journal(_get_journal_or_404(journal_id, session))


@router.put("/{journal_id}", response_model=JournalRead)
def update_journal(
    *, journal_id: int, payload: JournalUpdate, session: SessionDep
) -> JournalRead:
    journal = _get_journal_or_404(journal_id, session)
    data = payload.model_dump(exclude_unset=True)
    if data:
        curriculum_id = data.get("curriculum_id", journal.curriculum_id)
        secondary_curriculum_id = data.get(
            "secondary_curriculum_id", journal.secondary_curriculum_id
        )
        strategy_id = data.get("strategy_id", journal.strategy_id)
        _validate_references(
            session,
            curriculum_id=curriculum_id,
            secondary_curriculum_id=secondary_curriculum_id,
            strategy_id=strategy_id,
        )
        for key, value in data.items():
            setattr(journal, key, value)
        session.add(journal)
        session.commit()
        session.refresh(journal)
    journal_id = _ensure_journal_id(journal)
    return _serialize_journal(_get_journal_or_404(journal_id, session))


@router.delete("/{journal_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_journal(journal_id: int, session: SessionDep) -> Response:
    journal = _get_journal_or_404(journal_id, session)
    session.delete(journal)
    session.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
