"""CRUD endpoints for Journal resource."""

from datetime import datetime
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import selectinload
from sqlmodel import Session, select

from backend.database import get_session_dep
from backend.models import Journal
from backend.schemas import (
    JournalCreate,
    JournalRead,
    JournalReadWithRelations,
    JournalUpdate,
)

router = APIRouter(prefix="/journal", tags=["journal"])
SessionDep = Annotated[Session, Depends(get_session_dep)]


@router.get("", response_model=list[JournalReadWithRelations])
def list_journal_entries(
    session: SessionDep,
    user_id: int | None = None,
    strategy_id: int | None = None,
    from_date: Annotated[datetime | None, Query(alias="from")] = None,
    to_date: Annotated[datetime | None, Query(alias="to")] = None,
    limit: int = Query(100, ge=1, le=1000),
    offset: int = Query(0, ge=0),
) -> list[Journal]:
    """Get list of journal entries with optional filters and pagination."""
    statement = (
        select(Journal)
        .options(
            selectinload(Journal.curriculum),  # type: ignore[arg-type]
            selectinload(Journal.secondary_curriculum),  # type: ignore[arg-type]
            selectinload(Journal.strategy),  # type: ignore[arg-type]
        )
        .order_by(Journal.created_at.desc())  # type: ignore[attr-defined]
    )

    if user_id is not None:
        statement = statement.where(Journal.user_id == user_id)
    if strategy_id is not None:
        statement = statement.where(Journal.strategy_id == strategy_id)
    if from_date is not None:
        statement = statement.where(Journal.created_at >= from_date)
    if to_date is not None:
        statement = statement.where(Journal.created_at <= to_date)

    statement = statement.offset(offset).limit(limit)
    result = session.exec(statement)
    return list(result)


@router.get("/{journal_id}", response_model=JournalReadWithRelations)
def get_journal_entry(journal_id: int, session: SessionDep) -> Journal:
    """Get a specific journal entry by ID."""
    statement = (
        select(Journal)
        .where(Journal.id == journal_id)
        .options(
            selectinload(Journal.curriculum),  # type: ignore[arg-type]
            selectinload(Journal.secondary_curriculum),  # type: ignore[arg-type]
            selectinload(Journal.strategy),  # type: ignore[arg-type]
        )
    )
    journal = session.exec(statement).first()
    if not journal:
        raise HTTPException(status_code=404, detail="Journal entry not found")
    return journal


@router.post("", response_model=JournalRead, status_code=201)
def create_journal_entry(
    journal: JournalCreate, session: SessionDep
) -> Journal:
    """Create a new journal entry."""
    db_journal = Journal.model_validate(journal)
    session.add(db_journal)
    session.commit()
    session.refresh(db_journal)
    return db_journal


@router.put("/{journal_id}", response_model=JournalRead)
def update_journal_entry(
    journal_id: int, journal: JournalUpdate, session: SessionDep
) -> Journal:
    """Update a journal entry."""
    db_journal = session.get(Journal, journal_id)
    if not db_journal:
        raise HTTPException(status_code=404, detail="Journal entry not found")

    update_data = journal.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_journal, key, value)

    session.add(db_journal)
    session.commit()
    session.refresh(db_journal)
    return db_journal


@router.delete("/{journal_id}", status_code=204)
def delete_journal_entry(journal_id: int, session: SessionDep) -> None:
    """Delete a journal entry."""
    journal = session.get(Journal, journal_id)
    if not journal:
        raise HTTPException(status_code=404, detail="Journal entry not found")
    session.delete(journal)
    session.commit()
