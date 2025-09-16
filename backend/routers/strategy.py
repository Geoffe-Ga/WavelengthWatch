"""CRUD endpoints for Strategy resource."""

from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import selectinload
from sqlmodel import Session, select

from backend.database import get_session_dep
from backend.models import Strategy
from backend.schemas import (
    StrategyCreate,
    StrategyRead,
    StrategyReadWithRelations,
    StrategyUpdate,
)

router = APIRouter(prefix="/strategy", tags=["strategy"])
SessionDep = Annotated[Session, Depends(get_session_dep)]


@router.get("", response_model=list[StrategyReadWithRelations])
def list_strategies(
    session: SessionDep,
    layer_id: int | None = None,
    phase_id: int | None = None,
    limit: int = Query(100, ge=1, le=1000),
    offset: int = Query(0, ge=0),
) -> list[Strategy]:
    """Get list of strategies with optional filters and pagination."""
    statement = select(Strategy).options(
        selectinload(Strategy.layer),  # type: ignore[arg-type]
        selectinload(Strategy.phase),  # type: ignore[arg-type]
    )

    if layer_id is not None:
        statement = statement.where(Strategy.layer_id == layer_id)
    if phase_id is not None:
        statement = statement.where(Strategy.phase_id == phase_id)

    statement = statement.offset(offset).limit(limit)
    result = session.exec(statement)
    return list(result)


@router.get("/{strategy_id}", response_model=StrategyReadWithRelations)
def get_strategy(strategy_id: int, session: SessionDep) -> Strategy:
    """Get a specific strategy by ID."""
    statement = (
        select(Strategy)
        .where(Strategy.id == strategy_id)
        .options(
            selectinload(Strategy.layer),  # type: ignore[arg-type]
            selectinload(Strategy.phase),  # type: ignore[arg-type]
        )
    )
    strategy = session.exec(statement).first()
    if not strategy:
        raise HTTPException(status_code=404, detail="Strategy not found")
    return strategy


@router.post("", response_model=StrategyRead, status_code=201)
def create_strategy(
    strategy: StrategyCreate, session: SessionDep
) -> Strategy:
    """Create a new strategy."""
    db_strategy = Strategy.model_validate(strategy)
    session.add(db_strategy)
    session.commit()
    session.refresh(db_strategy)
    return db_strategy


@router.put("/{strategy_id}", response_model=StrategyRead)
def update_strategy(
    strategy_id: int, strategy: StrategyUpdate, session: SessionDep
) -> Strategy:
    """Update a strategy."""
    db_strategy = session.get(Strategy, strategy_id)
    if not db_strategy:
        raise HTTPException(status_code=404, detail="Strategy not found")

    update_data = strategy.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_strategy, key, value)

    session.add(db_strategy)
    session.commit()
    session.refresh(db_strategy)
    return db_strategy


@router.delete("/{strategy_id}", status_code=204)
def delete_strategy(strategy_id: int, session: SessionDep) -> None:
    """Delete a strategy."""
    strategy = session.get(Strategy, strategy_id)
    if not strategy:
        raise HTTPException(status_code=404, detail="Strategy not found")
    session.delete(strategy)
    session.commit()
