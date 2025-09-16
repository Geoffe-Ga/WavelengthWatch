"""CRUD endpoints for Curriculum resource."""

from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import selectinload
from sqlmodel import Session, select

from backend.database import get_session_dep
from backend.models import Curriculum, DosageEnum
from backend.schemas import (
    CurriculumCreate,
    CurriculumRead,
    CurriculumReadWithRelations,
    CurriculumUpdate,
)

router = APIRouter(prefix="/curriculum", tags=["curriculum"])
SessionDep = Annotated[Session, Depends(get_session_dep)]


@router.get("", response_model=list[CurriculumReadWithRelations])
def list_curriculum(
    session: SessionDep,
    layer_id: int | None = None,
    phase_id: int | None = None,
    dosage: DosageEnum | None = None,
    limit: int = Query(100, ge=1, le=1000),
    offset: int = Query(0, ge=0),
) -> list[Curriculum]:
    """Get list of curriculum with optional filters and pagination."""
    statement = select(Curriculum).options(
        selectinload(Curriculum.layer),  # type: ignore[arg-type]
        selectinload(Curriculum.phase),  # type: ignore[arg-type]
    )

    if layer_id is not None:
        statement = statement.where(Curriculum.layer_id == layer_id)
    if phase_id is not None:
        statement = statement.where(Curriculum.phase_id == phase_id)
    if dosage is not None:
        statement = statement.where(Curriculum.dosage == dosage)

    statement = statement.offset(offset).limit(limit)
    result = session.exec(statement)
    return list(result)


@router.get("/{curriculum_id}", response_model=CurriculumReadWithRelations)
def get_curriculum(curriculum_id: int, session: SessionDep) -> Curriculum:
    """Get a specific curriculum by ID."""
    statement = (
        select(Curriculum)
        .where(Curriculum.id == curriculum_id)
        .options(
            selectinload(Curriculum.layer),  # type: ignore[arg-type]
            selectinload(Curriculum.phase),  # type: ignore[arg-type]
        )
    )
    curriculum = session.exec(statement).first()
    if not curriculum:
        raise HTTPException(status_code=404, detail="Curriculum not found")
    return curriculum


@router.post("", response_model=CurriculumRead, status_code=201)
def create_curriculum(
    curriculum: CurriculumCreate, session: SessionDep
) -> Curriculum:
    """Create a new curriculum. Note: Curriculum are reference data."""
    db_curriculum = Curriculum.model_validate(curriculum)
    session.add(db_curriculum)
    session.commit()
    session.refresh(db_curriculum)
    return db_curriculum


@router.put("/{curriculum_id}", response_model=CurriculumRead)
def update_curriculum(
    curriculum_id: int,
    curriculum: CurriculumUpdate,
    session: SessionDep,
) -> Curriculum:
    """Update a curriculum. Note: Curriculum are reference data."""
    db_curriculum = session.get(Curriculum, curriculum_id)
    if not db_curriculum:
        raise HTTPException(status_code=404, detail="Curriculum not found")

    update_data = curriculum.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_curriculum, key, value)

    session.add(db_curriculum)
    session.commit()
    session.refresh(db_curriculum)
    return db_curriculum


@router.delete("/{curriculum_id}", status_code=204)
def delete_curriculum(curriculum_id: int, session: SessionDep) -> None:
    """Delete a curriculum. Note: Curriculum are reference data."""
    curriculum = session.get(Curriculum, curriculum_id)
    if not curriculum:
        raise HTTPException(status_code=404, detail="Curriculum not found")
    session.delete(curriculum)
    session.commit()
