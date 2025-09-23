"""Strategy endpoints."""

from __future__ import annotations

from typing import Annotated, cast

from fastapi import APIRouter, Depends, HTTPException, Query, Response, status
from sqlalchemy.engine import ScalarResult
from sqlalchemy.orm import joinedload
from sqlalchemy.sql.elements import ColumnElement
from sqlmodel import Session, select
from sqlmodel.sql.expression import SelectOfScalar

from ..database import get_session
from ..models import Layer, Phase, Strategy
from ..schemas import StrategyCreate, StrategyRead, StrategyUpdate

SessionDep = Annotated[Session, Depends(get_session)]

router = APIRouter(prefix="/strategy", tags=["strategy"])


def _serialize_strategy(strategy: Strategy) -> StrategyRead:
    return StrategyRead.model_validate(strategy)


def _base_query() -> SelectOfScalar[Strategy]:
    return (
        select(Strategy)
        .options(joinedload(Strategy.color_layer), joinedload(Strategy.phase))
        .order_by(cast(ColumnElement[int], Strategy.id))
    )


def _get_strategy_or_404(strategy_id: int, session: Session) -> Strategy:
    statement = _base_query().where(Strategy.id == strategy_id)
    result = cast(ScalarResult[Strategy], session.exec(statement))
    strategy = result.one_or_none()
    if strategy is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Strategy not found"
        )
    return strategy


def _validate_references(
    session: Session, color_layer_id: int, phase_id: int
) -> None:
    if session.get(Layer, color_layer_id) is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid color_layer_id",
        )
    if session.get(Phase, phase_id) is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid phase_id"
        )


def _ensure_strategy_id(strategy: Strategy) -> int:
    strategy_id = strategy.id
    if strategy_id is None:
        raise RuntimeError("Persisted strategy is missing a primary key")
    return strategy_id


@router.get("/", response_model=list[StrategyRead])
def list_strategies(
    *,
    session: SessionDep,
    limit: Annotated[int, Query(ge=1, le=1000)] = 100,
    offset: Annotated[int, Query(ge=0)] = 0,
    color_layer_id: Annotated[int | None, Query()] = None,
    phase_id: Annotated[int | None, Query()] = None,
) -> list[StrategyRead]:
    statement = _base_query()
    if color_layer_id is not None:
        statement = statement.where(Strategy.color_layer_id == color_layer_id)
    if phase_id is not None:
        clause = cast(ColumnElement[bool], Strategy.phase_id == phase_id)
        statement = statement.where(clause)
    statement = statement.offset(offset).limit(limit)
    result = cast(ScalarResult[Strategy], session.exec(statement))
    return [_serialize_strategy(row) for row in result.all()]


@router.get("/{strategy_id}", response_model=StrategyRead)
def get_strategy(strategy_id: int, session: SessionDep) -> StrategyRead:
    return _serialize_strategy(_get_strategy_or_404(strategy_id, session))


@router.post(
    "/", response_model=StrategyRead, status_code=status.HTTP_201_CREATED
)
def create_strategy(
    payload: StrategyCreate, session: SessionDep
) -> StrategyRead:
    _validate_references(session, payload.color_layer_id, payload.phase_id)
    strategy = Strategy(**payload.model_dump())
    session.add(strategy)
    session.commit()
    session.refresh(strategy)
    strategy_id = _ensure_strategy_id(strategy)
    return _serialize_strategy(_get_strategy_or_404(strategy_id, session))


@router.put("/{strategy_id}", response_model=StrategyRead)
def update_strategy(
    *, strategy_id: int, payload: StrategyUpdate, session: SessionDep
) -> StrategyRead:
    strategy = _get_strategy_or_404(strategy_id, session)
    data = payload.model_dump(exclude_unset=True)
    if "color_layer_id" in data or "phase_id" in data:
        color_layer_id = data.get("color_layer_id", strategy.color_layer_id)
        phase_id = data.get("phase_id", strategy.phase_id)
        _validate_references(session, color_layer_id, phase_id)
    for key, value in data.items():
        setattr(strategy, key, value)
    session.add(strategy)
    session.commit()
    strategy_id = _ensure_strategy_id(strategy)
    return _serialize_strategy(_get_strategy_or_404(strategy_id, session))


@router.delete("/{strategy_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_strategy(strategy_id: int, session: SessionDep) -> Response:
    strategy = _get_strategy_or_404(strategy_id, session)
    session.delete(strategy)
    session.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
