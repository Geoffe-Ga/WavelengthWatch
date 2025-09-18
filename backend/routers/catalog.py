"""Router exposing the aggregated catalog endpoint."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, Response
from sqlmodel import Session

from ..database import get_session
from ..schemas_catalog import CatalogResponse
from ..services.catalog import build_catalog

SessionDep = Annotated[Session, Depends(get_session)]

router = APIRouter(prefix="/catalog", tags=["catalog"])


@router.get("/", response_model=CatalogResponse)
def get_catalog(*, response: Response, session: SessionDep) -> CatalogResponse:
    """Return the cached catalog payload for clients."""

    response.headers["Cache-Control"] = "public, max-age=3600"
    return build_catalog(session)


__all__ = ["router"]
