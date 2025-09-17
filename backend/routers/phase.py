"""Phase CRUD endpoints."""

from __future__ import annotations

from typing import List

from fastapi import APIRouter, Depends, HTTPException, Query, Response, status
from sqlmodel import Session, select

from ..database import get_session
from ..models import Phase
from ..schemas import PhaseCreate, PhaseRead, PhaseUpdate

router = APIRouter(prefix="/phase", tags=["phase"])


def _serialize_phase(phase: Phase) -> PhaseRead:
    return PhaseRead.model_validate(phase)


def _get_phase_or_404(phase_id: int, session: Session) -> Phase:
    phase = session.get(Phase, phase_id)
    if phase is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Phase not found")
    return phase


@router.get("/", response_model=List[PhaseRead])
def list_phases(
    *, session: Session = Depends(get_session), limit: int = Query(100, ge=1, le=1000), offset: int = Query(0, ge=0)
) -> List[PhaseRead]:
    statement = select(Phase).order_by(Phase.id).offset(offset).limit(limit)
    phases = session.exec(statement).all()
    return [_serialize_phase(phase) for phase in phases]


@router.get("/{phase_id}", response_model=PhaseRead)
def get_phase(phase_id: int, session: Session = Depends(get_session)) -> PhaseRead:
    return _serialize_phase(_get_phase_or_404(phase_id, session))


@router.post("/", response_model=PhaseRead, status_code=status.HTTP_201_CREATED)
def create_phase(payload: PhaseCreate, session: Session = Depends(get_session)) -> PhaseRead:
    # Reference data writes are allowed but are typically rare in production.
    phase = Phase(**payload.model_dump())
    session.add(phase)
    session.commit()
    session.refresh(phase)
    return _serialize_phase(phase)


@router.put("/{phase_id}", response_model=PhaseRead)
def update_phase(
    *, phase_id: int, payload: PhaseUpdate, session: Session = Depends(get_session)
) -> PhaseRead:
    phase = _get_phase_or_404(phase_id, session)
    for key, value in payload.model_dump(exclude_unset=True).items():
        setattr(phase, key, value)
    session.add(phase)
    session.commit()
    session.refresh(phase)
    return _serialize_phase(phase)


@router.delete("/{phase_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_phase(phase_id: int, session: Session = Depends(get_session)) -> Response:
    phase = _get_phase_or_404(phase_id, session)
    session.delete(phase)
    session.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
