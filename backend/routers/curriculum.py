"""Curriculum endpoints."""

from __future__ import annotations

from typing import List

from fastapi import APIRouter, Depends, HTTPException, Query, Response, status
from sqlalchemy.orm import joinedload
from sqlmodel import Session, select

from ..database import get_session
from ..models import Curriculum, Dosage, Layer, Phase
from ..schemas import CurriculumCreate, CurriculumRead, CurriculumUpdate

router = APIRouter(prefix="/curriculum", tags=["curriculum"])


def _serialize_curriculum(curriculum: Curriculum) -> CurriculumRead:
    return CurriculumRead.model_validate(curriculum)


def _base_query():
    return (
        select(Curriculum)
        .options(joinedload(Curriculum.layer), joinedload(Curriculum.phase))
        .order_by(Curriculum.id)
    )


def _get_curriculum_or_404(curriculum_id: int, session: Session) -> Curriculum:
    statement = _base_query().where(Curriculum.id == curriculum_id)
    curriculum = session.exec(statement).first()
    if curriculum is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Curriculum not found")
    return curriculum


def _validate_references(session: Session, layer_id: int, phase_id: int) -> None:
    if session.get(Layer, layer_id) is None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid layer_id")
    if session.get(Phase, phase_id) is None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid phase_id")


@router.get("/", response_model=List[CurriculumRead])
def list_curriculum(
    *,
    session: Session = Depends(get_session),
    limit: int = Query(100, ge=1, le=1000),
    offset: int = Query(0, ge=0),
    layer_id: int | None = Query(default=None),
    phase_id: int | None = Query(default=None),
    dosage: Dosage | None = Query(default=None),
) -> List[CurriculumRead]:
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
def get_curriculum(curriculum_id: int, session: Session = Depends(get_session)) -> CurriculumRead:
    return _serialize_curriculum(_get_curriculum_or_404(curriculum_id, session))


@router.post("/", response_model=CurriculumRead, status_code=status.HTTP_201_CREATED)
def create_curriculum(payload: CurriculumCreate, session: Session = Depends(get_session)) -> CurriculumRead:
    # Reference data writes are infrequent but supported for administrative tooling.
    _validate_references(session, payload.layer_id, payload.phase_id)
    curriculum = Curriculum(**payload.model_dump())
    session.add(curriculum)
    session.commit()
    session.refresh(curriculum)
    return _serialize_curriculum(_get_curriculum_or_404(curriculum.id, session))


@router.put("/{curriculum_id}", response_model=CurriculumRead)
def update_curriculum(
    *, curriculum_id: int, payload: CurriculumUpdate, session: Session = Depends(get_session)
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
    return _serialize_curriculum(_get_curriculum_or_404(curriculum.id, session))


@router.delete("/{curriculum_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_curriculum(curriculum_id: int, session: Session = Depends(get_session)) -> Response:
    curriculum = _get_curriculum_or_404(curriculum_id, session)
    session.delete(curriculum)
    session.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
