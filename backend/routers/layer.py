"""Layer CRUD endpoints."""

from __future__ import annotations

from typing import Annotated, cast

from fastapi import APIRouter, Depends, HTTPException, Query, Response, status
from sqlalchemy.sql.elements import ColumnElement
from sqlmodel import Session, select

from ..database import get_session
from ..models import Layer
from ..schemas import LayerCreate, LayerRead, LayerUpdate

SessionDep = Annotated[Session, Depends(get_session)]

router = APIRouter(prefix="/layer", tags=["layer"])


def _serialize_layer(layer: Layer) -> LayerRead:
    return LayerRead.model_validate(layer)


def _get_layer_or_404(layer_id: int, session: Session) -> Layer:
    layer = session.get(Layer, layer_id)
    if layer is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Layer not found"
        )
    return layer


@router.get("/", response_model=list[LayerRead])
def list_layers(
    *,
    session: SessionDep,
    limit: Annotated[int, Query(ge=1, le=1000)] = 100,
    offset: Annotated[int, Query(ge=0)] = 0,
) -> list[LayerRead]:
    statement = (
        select(Layer)
        .order_by(cast(ColumnElement[int], Layer.id))
        .offset(offset)
        .limit(limit)
    )
    layers = session.exec(statement).all()
    return [_serialize_layer(layer) for layer in layers]


@router.get("/{layer_id}", response_model=LayerRead)
def get_layer(layer_id: int, session: SessionDep) -> LayerRead:
    return _serialize_layer(_get_layer_or_404(layer_id, session))


@router.post(
    "/", response_model=LayerRead, status_code=status.HTTP_201_CREATED
)
def create_layer(payload: LayerCreate, session: SessionDep) -> LayerRead:
    # Reference data writes are allowed but typically performed during initial setup.
    layer = Layer(**payload.model_dump())
    session.add(layer)
    session.commit()
    session.refresh(layer)
    return _serialize_layer(layer)


@router.put("/{layer_id}", response_model=LayerRead)
def update_layer(
    *, layer_id: int, payload: LayerUpdate, session: SessionDep
) -> LayerRead:
    layer = _get_layer_or_404(layer_id, session)
    for key, value in payload.model_dump(exclude_unset=True).items():
        setattr(layer, key, value)
    session.add(layer)
    session.commit()
    session.refresh(layer)
    return _serialize_layer(layer)


@router.delete("/{layer_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_layer(layer_id: int, session: SessionDep) -> Response:
    layer = _get_layer_or_404(layer_id, session)
    session.delete(layer)
    session.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
