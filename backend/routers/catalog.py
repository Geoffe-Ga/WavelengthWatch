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


@router.get(
    "",
    response_model=CatalogResponse,
    summary="Retrieve the complete curriculum catalog",
    response_description=(
        "Aggregated layers, phases, curriculum entries, and strategies."
    ),
)
def get_catalog(*, response: Response, session: SessionDep) -> CatalogResponse:
    """Return the cached catalog payload for clients.

    The payload nests medicinal/toxic curriculum entries alongside strategies so
    the watch app can render the full archetypal context. A typical response
    looks like::

        {
            "phase_order": ["Rising", "Peaking", "Withdrawal"],
            "layers": [
                {
                    "id": 1,
                    "color": "Beige",
                    "title": "SELF-CARE",
                    "subtitle": "(For Surfing)",
                    "phases": [
                        {
                            "id": 1,
                            "name": "Rising",
                            "medicinal": [
                                {
                                    "id": 10,
                                    "dosage": "Medicinal",
                                    "expression": "Commitment",
                                }
                            ],
                            "toxic": [
                                {
                                    "id": 11,
                                    "dosage": "Toxic",
                                    "expression": "Overcommitment",
                                }
                            ],
                            "strategies": [
                                {"id": 5, "strategy": "Cold Shower"}
                            ]
                        }
                    ]
                }
            ]
        }
    """

    response.headers["Cache-Control"] = "public, max-age=3600"
    return build_catalog(session)


__all__ = ["router"]
