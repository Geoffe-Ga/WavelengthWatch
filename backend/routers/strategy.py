"""Strategy endpoints."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Query, Response, status
from sqlalchemy.orm import joinedload
from sqlmodel import Session, select

from ..database import get_session
from ..models import Layer, Phase, Strategy
from ..schemas import StrategyCreate, StrategyRead, StrategyUpdate

SessionDep = Annotated[Session, Depends(get_session)]

router = APIRouter(prefix="/strategy", tags=["strategy"])


def _serialize_strategy(strategy: Strategy) -> StrategyRead:
    return StrategyRead.model_validate(strategy)


def _base_query():
    return (
        select(Strategy)
        .options(joinedload(Strategy.layer), joinedload(Strategy.phase))
        .order_by(Strategy.id)
    )


def _get_strategy_or_404(strategy_id: int, session: Session) -> Strategy:
    statement = _base_query().where(Strategy.id == strategy_id)
    strategy = session.exec(statement).first()
    if strategy is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Strategy not found")
    return strategy


def _validate_references(session: Session, layer_id: int, phase_id: int) -> None:
    if session.get(Layer, layer_id) is None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid layer_id")
    if session.get(Phase, phase_id) is None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid phase_id")


@router.get("/", response_model=list[StrategyRead])
def list_strategies(
    *,
    session: SessionDep,
    limit: Annotated[int, Query(ge=1, le=1000)] = 100,
    offset: Annotated[int, Query(ge=0)] = 0,
    layer_id: Annotated[int | None, Query()] = None,
    phase_id: Annotated[int | None, Query()] = None,
) -> list[StrategyRead]:
    statement = _base_query()
    if layer_id is not None:
        statement = statement.where(Strategy.layer_id == layer_id)
    if phase_id is not None:
        statement = statement.where(Strategy.phase_id == phase_id)
    statement = statement.offset(offset).limit(limit)
    rows = session.exec(statement).all()
    return [_serialize_strategy(row) for row in rows]


@router.get("/{strategy_id}", response_model=StrategyRead)
def get_strategy(strategy_id: int, session: SessionDep) -> StrategyRead:
    return _serialize_strategy(_get_strategy_or_404(strategy_id, session))


@router.post("/", response_model=StrategyRead, status_code=status.HTTP_201_CREATED)
def create_strategy(payload: StrategyCreate, session: SessionDep) -> StrategyRead:
    _validate_references(session, payload.layer_id, payload.phase_id)
    strategy = Strategy(**payload.model_dump())
    session.add(strategy)
    session.commit()
    session.refresh(strategy)
    return _serialize_strategy(_get_strategy_or_404(strategy.id, session))


@router.put("/{strategy_id}", response_model=StrategyRead)
def update_strategy(*, strategy_id: int, payload: StrategyUpdate, session: SessionDep) -> StrategyRead:
    strategy = _get_strategy_or_404(strategy_id, session)
    data = payload.model_dump(exclude_unset=True)
    if "layer_id" in data or "phase_id" in data:
        layer_id = data.get("layer_id", strategy.layer_id)
        phase_id = data.get("phase_id", strategy.phase_id)
        _validate_references(session, layer_id, phase_id)
    for key, value in data.items():
        setattr(strategy, key, value)
    session.add(strategy)
    session.commit()
    return _serialize_strategy(_get_strategy_or_404(strategy.id, session))


@router.delete("/{strategy_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_strategy(strategy_id: int, session: SessionDep) -> Response:
    strategy = _get_strategy_or_404(strategy_id, session)
    session.delete(strategy)
    session.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
