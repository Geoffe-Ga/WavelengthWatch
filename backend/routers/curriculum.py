"""Curriculum endpoints."""

from __future__ import annotations

from typing import Annotated, cast

from fastapi import APIRouter, Depends, HTTPException, Query, Response, status
from sqlalchemy.orm import joinedload
from sqlalchemy.sql.elements import ColumnElement
from sqlmodel import Session, select

from ..database import get_session
from ..models import Curriculum, Dosage, Layer, Phase
from ..schemas import CurriculumCreate, CurriculumRead, CurriculumUpdate

SessionDep = Annotated[Session, Depends(get_session)]

router = APIRouter(prefix="/curriculum", tags=["curriculum"])


def _serialize_curriculum(curriculum: Curriculum) -> CurriculumRead:
    return CurriculumRead.model_validate(curriculum)


def _base_query():
    return (
        select(Curriculum)
        .options(joinedload(Curriculum.layer), joinedload(Curriculum.phase))
        .order_by(cast(ColumnElement[int], Curriculum.id))
    )


def _get_curriculum_or_404(
    curriculum_id: int, session: Session
) -> Curriculum:
    statement = _base_query().where(Curriculum.id == curriculum_id)
    curriculum = session.exec(statement).first()
    if curriculum is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Curriculum not found",
        )
    return curriculum


def _validate_references(
    session: Session, layer_id: int, phase_id: int
) -> None:
    if session.get(Layer, layer_id) is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid layer_id"
        )
    if session.get(Phase, phase_id) is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid phase_id"
        )


def _ensure_curriculum_id(curriculum: Curriculum) -> int:
    curriculum_id = curriculum.id
    if curriculum_id is None:
        raise RuntimeError("Persisted curriculum is missing a primary key")
    return curriculum_id


@router.get("/", response_model=list[CurriculumRead])
def list_curriculum(
    *,
    session: SessionDep,
    limit: Annotated[int, Query(ge=1, le=1000)] = 100,
    offset: Annotated[int, Query(ge=0)] = 0,
    layer_id: Annotated[int | None, Query()] = None,
    phase_id: Annotated[int | None, Query()] = None,
    dosage: Annotated[Dosage | None, Query()] = None,
) -> list[CurriculumRead]:
    statement = _base_query()
    if layer_id is not None:
        statement = statement.where(Curriculum.layer_id == layer_id)
    if phase_id is not None:
        statement = statement.where(Curriculum.phase_id == phase_id)
    if dosage is not None:
        statement = statement.where(Curriculum.dosage == dosage)
    statement = statement.offset(offset).limit(limit)
    rows = session.exec(statement).all()
    return [_serialize_curriculum(row) for row in rows]


@router.get("/{curriculum_id}", response_model=CurriculumRead)
def get_curriculum(curriculum_id: int, session: SessionDep) -> CurriculumRead:
    return _serialize_curriculum(
        _get_curriculum_or_404(curriculum_id, session)
    )


@router.post(
    "/", response_model=CurriculumRead, status_code=status.HTTP_201_CREATED
)
def create_curriculum(
    payload: CurriculumCreate, session: SessionDep
) -> CurriculumRead:
    # Reference data writes are infrequent but supported for administrative tooling.
    _validate_references(session, payload.layer_id, payload.phase_id)
    curriculum = Curriculum(**payload.model_dump())
    session.add(curriculum)
    session.commit()
    session.refresh(curriculum)
    curriculum_id = _ensure_curriculum_id(curriculum)
    return _serialize_curriculum(
        _get_curriculum_or_404(curriculum_id, session)
    )


@router.put("/{curriculum_id}", response_model=CurriculumRead)
def update_curriculum(
    *, curriculum_id: int, payload: CurriculumUpdate, session: SessionDep
) -> CurriculumRead:
    curriculum = _get_curriculum_or_404(curriculum_id, session)
    data = payload.model_dump(exclude_unset=True)
    if "layer_id" in data or "phase_id" in data:
        layer_id = data.get("layer_id", curriculum.layer_id)
        phase_id = data.get("phase_id", curriculum.phase_id)
        _validate_references(session, layer_id, phase_id)
    for key, value in data.items():
        setattr(curriculum, key, value)
    session.add(curriculum)
    session.commit()
    curriculum_id = _ensure_curriculum_id(curriculum)
    return _serialize_curriculum(
        _get_curriculum_or_404(curriculum_id, session)
    )


@router.delete("/{curriculum_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_curriculum(curriculum_id: int, session: SessionDep) -> Response:
    curriculum = _get_curriculum_or_404(curriculum_id, session)
    session.delete(curriculum)
    session.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
