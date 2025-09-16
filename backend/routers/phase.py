"""CRUD endpoints for Phase resource."""

from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlmodel import Session, select

from backend.database import get_session_dep
from backend.models import Phase
from backend.schemas import PhaseCreate, PhaseRead, PhaseUpdate

router = APIRouter(prefix="/phase", tags=["phase"])
SessionDep = Annotated[Session, Depends(get_session_dep)]


@router.get("", response_model=list[PhaseRead])
def list_phases(
    session: SessionDep,
    limit: int = Query(100, ge=1, le=1000),
    offset: int = Query(0, ge=0),
) -> list[Phase]:
    """Get list of phases with pagination."""
    statement = select(Phase).offset(offset).limit(limit)
    result = session.exec(statement)
    return list(result)


@router.get("/{phase_id}", response_model=PhaseRead)
def get_phase(phase_id: int, session: SessionDep) -> Phase:
    """Get a specific phase by ID."""
    phase = session.get(Phase, phase_id)
    if not phase:
        raise HTTPException(status_code=404, detail="Phase not found")
    return phase


@router.post("", response_model=PhaseRead, status_code=201)
def create_phase(phase: PhaseCreate, session: SessionDep) -> Phase:
    """Create a new phase. Note: Phases are reference data."""
    db_phase = Phase.model_validate(phase)
    session.add(db_phase)
    session.commit()
    session.refresh(db_phase)
    return db_phase


@router.put("/{phase_id}", response_model=PhaseRead)
def update_phase(
    phase_id: int, phase: PhaseUpdate, session: SessionDep
) -> Phase:
    """Update a phase. Note: Phases are reference data."""
    db_phase = session.get(Phase, phase_id)
    if not db_phase:
        raise HTTPException(status_code=404, detail="Phase not found")

    update_data = phase.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_phase, key, value)

    session.add(db_phase)
    session.commit()
    session.refresh(db_phase)
    return db_phase


@router.delete("/{phase_id}", status_code=204)
def delete_phase(phase_id: int, session: SessionDep) -> None:
    """Delete a phase. Note: Phases are reference data."""
    phase = session.get(Phase, phase_id)
    if not phase:
        raise HTTPException(status_code=404, detail="Phase not found")
    session.delete(phase)
    session.commit()
