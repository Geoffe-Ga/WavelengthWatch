"""Strategy CRUD endpoints."""
from __future__ import annotations

from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, Response, status
from sqlalchemy.orm import selectinload
from sqlmodel import Session, select

from app.database import get_session
from app.models import Strategy
from app.schemas import StrategyCreate, StrategyRead, StrategyUpdate

router = APIRouter(prefix="/strategies", tags=["strategies"])


@router.get("/", response_model=List[StrategyRead])
def list_strategies(
    *,
    session: Session = Depends(get_session),
    limit: int = Query(100, ge=1, le=500),
    offset: int = Query(0, ge=0),
    layer_id: Optional[int] = Query(default=None),
    phase_id: Optional[int] = Query(default=None),
) -> List[Strategy]:
    """List strategies with optional filters."""

    statement = (
        select(Strategy)
        .options(
            selectinload(Strategy.layer),
            selectinload(Strategy.phase),
        )
        .order_by(Strategy.id)
    )

    if layer_id is not None:
        statement = statement.where(Strategy.layer_id == layer_id)
    if phase_id is not None:
        statement = statement.where(Strategy.phase_id == phase_id)

    strategies = session.exec(statement.offset(offset).limit(limit)).all()
    return strategies


@router.get("/{strategy_id}", response_model=StrategyRead)
def get_strategy(
    *, strategy_id: int, session: Session = Depends(get_session)
) -> Strategy:
    """Retrieve a specific strategy."""

    statement = (
        select(Strategy)
        .where(Strategy.id == strategy_id)
        .options(
            selectinload(Strategy.layer),
            selectinload(Strategy.phase),
        )
    )
    strategy = session.exec(statement).one_or_none()
    if strategy is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Strategy not found")
    return strategy


@router.post("/", response_model=StrategyRead, status_code=status.HTTP_201_CREATED)
def create_strategy(
    *, payload: StrategyCreate, session: Session = Depends(get_session)
) -> Strategy:
    """Create a new strategy entry."""

    strategy = Strategy.model_validate(payload)
    session.add(strategy)
    session.commit()
    session.refresh(strategy)
    return strategy


@router.put("/{strategy_id}", response_model=StrategyRead)
def update_strategy(
    *, strategy_id: int, payload: StrategyUpdate, session: Session = Depends(get_session)
) -> Strategy:
    """Update an existing strategy."""

    strategy = session.get(Strategy, strategy_id)
    if strategy is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Strategy not found")

    for key, value in payload.model_dump(exclude_unset=True).items():
        setattr(strategy, key, value)

    session.add(strategy)
    session.commit()
    session.refresh(strategy)
    return strategy


@router.delete(
    "/{strategy_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    response_class=Response,
)
def delete_strategy(
    *, strategy_id: int, session: Session = Depends(get_session)
) -> Response:
    """Delete a strategy entry."""

    strategy = session.get(Strategy, strategy_id)
    if strategy is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Strategy not found")

    session.delete(strategy)
    session.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
