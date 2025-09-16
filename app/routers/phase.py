"""Phase CRUD endpoints."""
from __future__ import annotations

from typing import List

from fastapi import APIRouter, Depends, HTTPException, Query, Response, status
from sqlalchemy.orm import selectinload
from sqlmodel import Session, select

from app.database import get_session
from app.models import Phase
from app.schemas import PhaseCreate, PhaseRead, PhaseUpdate

router = APIRouter(prefix="/phases", tags=["phases"])


@router.get("/", response_model=List[PhaseRead])
def list_phases(
    *,
    session: Session = Depends(get_session),
    limit: int = Query(100, ge=1, le=500),
    offset: int = Query(0, ge=0),
) -> List[Phase]:
    """List phases with pagination."""

    statement = select(Phase).options(selectinload(Phase.curriculum_items))
    phases = session.exec(statement.offset(offset).limit(limit)).all()
    return phases


@router.get("/{phase_id}", response_model=PhaseRead)
def get_phase(*, phase_id: int, session: Session = Depends(get_session)) -> Phase:
    """Retrieve a specific phase."""

    phase = session.exec(select(Phase).where(Phase.id == phase_id)).one_or_none()
    if phase is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Phase not found")
    return phase


@router.post("/", response_model=PhaseRead, status_code=status.HTTP_201_CREATED)
def create_phase(*, payload: PhaseCreate, session: Session = Depends(get_session)) -> Phase:
    """Create a new phase entry."""

    phase = Phase.model_validate(payload)
    session.add(phase)
    session.commit()
    session.refresh(phase)
    return phase


@router.put("/{phase_id}", response_model=PhaseRead)
def update_phase(
    *, phase_id: int, payload: PhaseUpdate, session: Session = Depends(get_session)
) -> Phase:
    """Update an existing phase."""

    phase = session.get(Phase, phase_id)
    if phase is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Phase not found")

    for key, value in payload.model_dump(exclude_unset=True).items():
        setattr(phase, key, value)

    session.add(phase)
    session.commit()
    session.refresh(phase)
    return phase


@router.delete("/{phase_id}", status_code=status.HTTP_204_NO_CONTENT, response_class=Response)
def delete_phase(*, phase_id: int, session: Session = Depends(get_session)) -> Response:
    """Delete a phase."""

    phase = session.get(Phase, phase_id)
    if phase is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Phase not found")

    session.delete(phase)
    session.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
