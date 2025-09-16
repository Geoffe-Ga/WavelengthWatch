"""Journal CRUD endpoints."""
from __future__ import annotations

from datetime import datetime
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, Response, status
from sqlalchemy.orm import selectinload
from sqlmodel import Session, select

from app.database import get_session
from app.models import Curriculum, Journal, Strategy
from app.schemas import JournalCreate, JournalRead, JournalUpdate
from app.utils import ensure_aware


def _normalize_entry(entry: Journal) -> Journal:
    entry.created_at = ensure_aware(entry.created_at)
    return entry

router = APIRouter(prefix="/journal", tags=["journal"])


def _journal_base_statement():
    return select(Journal).options(
        selectinload(Journal.curriculum).selectinload(Curriculum.layer),
        selectinload(Journal.curriculum).selectinload(Curriculum.phase),
        selectinload(Journal.secondary_curriculum).selectinload(Curriculum.layer),
        selectinload(Journal.secondary_curriculum).selectinload(Curriculum.phase),
        selectinload(Journal.strategy).selectinload(Strategy.layer),
        selectinload(Journal.strategy).selectinload(Strategy.phase),
    )


@router.get("/", response_model=List[JournalRead])
def list_journal(
    *,
    session: Session = Depends(get_session),
    limit: int = Query(100, ge=1, le=500),
    offset: int = Query(0, ge=0),
    user_id: Optional[int] = Query(default=None),
    strategy_id: Optional[int] = Query(default=None),
    from_: Optional[datetime] = Query(default=None, alias="from"),
    to: Optional[datetime] = Query(default=None),
) -> List[Journal]:
    """List journal entries with optional filters."""

    statement = _journal_base_statement().order_by(Journal.created_at.desc())

    if user_id is not None:
        statement = statement.where(Journal.user_id == user_id)
    if strategy_id is not None:
        statement = statement.where(Journal.strategy_id == strategy_id)
    if from_ is not None:
        statement = statement.where(Journal.created_at >= ensure_aware(from_))
    if to is not None:
        statement = statement.where(Journal.created_at <= ensure_aware(to))

    journals = session.exec(statement.offset(offset).limit(limit)).all()
    return [_normalize_entry(journal) for journal in journals]


@router.get("/{journal_id}", response_model=JournalRead)
def get_journal(
    *, journal_id: int, session: Session = Depends(get_session)
) -> Journal:
    """Retrieve a specific journal entry."""

    statement = _journal_base_statement().where(Journal.id == journal_id)
    journal = session.exec(statement).one_or_none()
    if journal is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Journal not found")
    return _normalize_entry(journal)


@router.post("/", response_model=JournalRead, status_code=status.HTTP_201_CREATED)
def create_journal(
    *, payload: JournalCreate, session: Session = Depends(get_session)
) -> Journal:
    """Create a new journal entry."""

    journal = Journal.model_validate(payload)
    journal.created_at = ensure_aware(journal.created_at)

    session.add(journal)
    session.commit()
    session.refresh(journal)

    # Reload with relationships for consistent response
    return get_journal(journal_id=journal.id, session=session)


@router.put("/{journal_id}", response_model=JournalRead)
def update_journal(
    *, journal_id: int, payload: JournalUpdate, session: Session = Depends(get_session)
) -> Journal:
    """Update an existing journal entry."""

    journal = session.get(Journal, journal_id)
    if journal is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Journal not found")

    update_data = payload.model_dump(exclude_unset=True)
    if "created_at" in update_data and update_data["created_at"] is not None:
        update_data["created_at"] = ensure_aware(update_data["created_at"])

    for key, value in update_data.items():
        setattr(journal, key, value)

    session.add(journal)
    session.commit()
    session.refresh(journal)

    return get_journal(journal_id=journal.id, session=session)


@router.delete(
    "/{journal_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    response_class=Response,
)
def delete_journal(*, journal_id: int, session: Session = Depends(get_session)) -> Response:
    """Delete a journal entry."""

    journal = session.get(Journal, journal_id)
    if journal is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Journal not found")

    session.delete(journal)
    session.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
