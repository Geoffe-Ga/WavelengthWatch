"""CRUD endpoints for Layer resource."""

from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlmodel import Session, select

from backend.database import get_session_dep
from backend.models import Layer
from backend.schemas import LayerCreate, LayerRead, LayerUpdate

router = APIRouter(prefix="/layer", tags=["layer"])
SessionDep = Annotated[Session, Depends(get_session_dep)]


@router.get("", response_model=list[LayerRead])
def list_layers(
    session: SessionDep,
    limit: int = Query(100, ge=1, le=1000),
    offset: int = Query(0, ge=0),
) -> list[Layer]:
    """Get list of layers with pagination."""
    statement = select(Layer).offset(offset).limit(limit)
    result = session.exec(statement)
    return list(result)


@router.get("/{layer_id}", response_model=LayerRead)
def get_layer(layer_id: int, session: SessionDep) -> Layer:
    """Get a specific layer by ID."""
    layer = session.get(Layer, layer_id)
    if not layer:
        raise HTTPException(status_code=404, detail="Layer not found")
    return layer


@router.post("", response_model=LayerRead, status_code=201)
def create_layer(layer: LayerCreate, session: SessionDep) -> Layer:
    """Create a new layer. Note: Layers are reference data."""
    db_layer = Layer.model_validate(layer)
    session.add(db_layer)
    session.commit()
    session.refresh(db_layer)
    return db_layer


@router.put("/{layer_id}", response_model=LayerRead)
def update_layer(
    layer_id: int, layer: LayerUpdate, session: SessionDep
) -> Layer:
    """Update a layer. Note: Layers are reference data."""
    db_layer = session.get(Layer, layer_id)
    if not db_layer:
        raise HTTPException(status_code=404, detail="Layer not found")

    update_data = layer.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_layer, key, value)

    session.add(db_layer)
    session.commit()
    session.refresh(db_layer)
    return db_layer


@router.delete("/{layer_id}", status_code=204)
def delete_layer(layer_id: int, session: SessionDep) -> None:
    """Delete a layer. Note: Layers are reference data."""
    layer = session.get(Layer, layer_id)
    if not layer:
        raise HTTPException(status_code=404, detail="Layer not found")
    session.delete(layer)
    session.commit()
