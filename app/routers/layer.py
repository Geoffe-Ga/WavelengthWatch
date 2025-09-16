"""Layer CRUD endpoints."""
from __future__ import annotations

from typing import List

from fastapi import APIRouter, Depends, HTTPException, Query, Response, status
from sqlalchemy.orm import selectinload
from sqlmodel import Session, select

from app.database import get_session
from app.models import Layer
from app.schemas import LayerCreate, LayerRead, LayerUpdate

router = APIRouter(prefix="/layers", tags=["layers"])


@router.get("/", response_model=List[LayerRead])
def list_layers(
    *,
    session: Session = Depends(get_session),
    limit: int = Query(100, ge=1, le=500),
    offset: int = Query(0, ge=0),
) -> List[Layer]:
    """List layers with pagination."""

    statement = select(Layer).options(selectinload(Layer.curriculum_items))
    layers = session.exec(statement.offset(offset).limit(limit)).all()
    return layers


@router.get("/{layer_id}", response_model=LayerRead)
def get_layer(*, layer_id: int, session: Session = Depends(get_session)) -> Layer:
    """Retrieve a single layer by identifier."""

    statement = select(Layer).where(Layer.id == layer_id)
    layer = session.exec(statement).one_or_none()
    if layer is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Layer not found")
    return layer


@router.post("/", response_model=LayerRead, status_code=status.HTTP_201_CREATED)
def create_layer(*, payload: LayerCreate, session: Session = Depends(get_session)) -> Layer:
    """Create a new layer.

    Even though layers are typically reference data, the endpoint allows creation for
    administrative tooling.
    """

    layer = Layer.model_validate(payload)
    session.add(layer)
    session.commit()
    session.refresh(layer)
    return layer


@router.put("/{layer_id}", response_model=LayerRead)
def update_layer(
    *, layer_id: int, payload: LayerUpdate, session: Session = Depends(get_session)
) -> Layer:
    """Update an existing layer."""

    layer = session.get(Layer, layer_id)
    if layer is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Layer not found")

    for key, value in payload.model_dump(exclude_unset=True).items():
        setattr(layer, key, value)

    session.add(layer)
    session.commit()
    session.refresh(layer)
    return layer


@router.delete("/{layer_id}", status_code=status.HTTP_204_NO_CONTENT, response_class=Response)
def delete_layer(*, layer_id: int, session: Session = Depends(get_session)) -> Response:
    """Delete a layer entry."""

    layer = session.get(Layer, layer_id)
    if layer is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Layer not found")

    session.delete(layer)
    session.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
