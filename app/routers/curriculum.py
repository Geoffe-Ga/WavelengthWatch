"""Curriculum CRUD endpoints."""
from __future__ import annotations

from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, Response, status
from sqlalchemy.orm import selectinload
from sqlmodel import Session, select

from app.database import get_session
from app.models import Curriculum
from app.schemas import CurriculumCreate, CurriculumRead, CurriculumUpdate

router = APIRouter(prefix="/curriculum", tags=["curriculum"])


@router.get("/", response_model=List[CurriculumRead])
def list_curriculum(
    *,
    session: Session = Depends(get_session),
    limit: int = Query(100, ge=1, le=500),
    offset: int = Query(0, ge=0),
    stage_id: Optional[int] = Query(default=None),
    phase_id: Optional[int] = Query(default=None),
    dosage: Optional[str] = Query(default=None),
) -> List[Curriculum]:
    """List curriculum items with optional filtering."""

    statement = (
        select(Curriculum)
        .options(
            selectinload(Curriculum.layer),
            selectinload(Curriculum.phase),
        )
        .order_by(Curriculum.id)
    )

    if stage_id is not None:
        statement = statement.where(Curriculum.stage_id == stage_id)
    if phase_id is not None:
        statement = statement.where(Curriculum.phase_id == phase_id)
    if dosage is not None:
        statement = statement.where(Curriculum.dosage == dosage)

    curriculum_items = session.exec(statement.offset(offset).limit(limit)).all()
    return curriculum_items


@router.get("/{curriculum_id}", response_model=CurriculumRead)
def get_curriculum(
    *, curriculum_id: int, session: Session = Depends(get_session)
) -> Curriculum:
    """Retrieve a curriculum entry by identifier."""

    statement = (
        select(Curriculum)
        .where(Curriculum.id == curriculum_id)
        .options(
            selectinload(Curriculum.layer),
            selectinload(Curriculum.phase),
        )
    )
    curriculum = session.exec(statement).one_or_none()
    if curriculum is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Curriculum not found")
    return curriculum


@router.post("/", response_model=CurriculumRead, status_code=status.HTTP_201_CREATED)
def create_curriculum(
    *, payload: CurriculumCreate, session: Session = Depends(get_session)
) -> Curriculum:
    """Create a new curriculum entry.

    Curriculum rows are typically reference data but can be adjusted via this endpoint.
    """

    curriculum = Curriculum.model_validate(payload)
    session.add(curriculum)
    session.commit()
    session.refresh(curriculum)
    return curriculum


@router.put("/{curriculum_id}", response_model=CurriculumRead)
def update_curriculum(
    *, curriculum_id: int, payload: CurriculumUpdate, session: Session = Depends(get_session)
) -> Curriculum:
    """Update an existing curriculum entry."""

    curriculum = session.get(Curriculum, curriculum_id)
    if curriculum is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Curriculum not found")

    for key, value in payload.model_dump(exclude_unset=True).items():
        setattr(curriculum, key, value)

    session.add(curriculum)
    session.commit()
    session.refresh(curriculum)
    return curriculum


@router.delete(
    "/{curriculum_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    response_class=Response,
)
def delete_curriculum(
    *, curriculum_id: int, session: Session = Depends(get_session)
) -> Response:
    """Delete a curriculum entry."""

    curriculum = session.get(Curriculum, curriculum_id)
    if curriculum is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Curriculum not found")

    session.delete(curriculum)
    session.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
