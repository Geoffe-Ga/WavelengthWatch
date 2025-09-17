"""Phase CRUD endpoints."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Query, Response, status
from sqlmodel import Session, select

from ..database import get_session
from ..models import Phase
from ..schemas import PhaseCreate, PhaseRead, PhaseUpdate

SessionDep = Annotated[Session, Depends(get_session)]

router = APIRouter(prefix="/phase", tags=["phase"])


def _serialize_phase(phase: Phase) -> PhaseRead:
    return PhaseRead.model_validate(phase)


def _get_phase_or_404(phase_id: int, session: Session) -> Phase:
    phase = session.get(Phase, phase_id)
    if phase is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Phase not found")
    return phase


@router.get("/", response_model=list[PhaseRead])
def list_phases(
    *,
    session: SessionDep,
    limit: Annotated[int, Query(ge=1, le=1000)] = 100,
    offset: Annotated[int, Query(ge=0)] = 0,
) -> list[PhaseRead]:
    statement = select(Phase).order_by(Phase.id).offset(offset).limit(limit)
    phases = session.exec(statement).all()
    return [_serialize_phase(phase) for phase in phases]


@router.get("/{phase_id}", response_model=PhaseRead)
def get_phase(phase_id: int, session: SessionDep) -> PhaseRead:
    return _serialize_phase(_get_phase_or_404(phase_id, session))


@router.post("/", response_model=PhaseRead, status_code=status.HTTP_201_CREATED)
def create_phase(payload: PhaseCreate, session: SessionDep) -> PhaseRead:
    # Reference data writes are allowed but are typically rare in production.
    phase = Phase(**payload.model_dump())
    session.add(phase)
    session.commit()
    session.refresh(phase)
    return _serialize_phase(phase)


@router.put("/{phase_id}", response_model=PhaseRead)
def update_phase(*, phase_id: int, payload: PhaseUpdate, session: SessionDep) -> PhaseRead:
    phase = _get_phase_or_404(phase_id, session)
    for key, value in payload.model_dump(exclude_unset=True).items():
        setattr(phase, key, value)
    session.add(phase)
    session.commit()
    session.refresh(phase)
    return _serialize_phase(phase)


@router.delete("/{phase_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_phase(phase_id: int, session: SessionDep) -> Response:
    phase = _get_phase_or_404(phase_id, session)
    session.delete(phase)
    session.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
