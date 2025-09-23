"""Tests for the aggregated catalog endpoint."""

from __future__ import annotations

from collections.abc import Iterable

from sqlmodel import Session, delete

from backend import database
from backend.models import Curriculum, Journal, Layer, Phase, Strategy
from backend.tools.seed_data import seed_database

PHASE_ORDER = [
    "Rising",
    "Peaking",
    "Withdrawal",
    "Diminishing",
    "Bottoming Out",
    "Restoration",
]

EXPECTED_LAYER_COUNT = 11


def _flatten(entries: Iterable[dict[str, object]]) -> set[int]:
    return {int(item["id"]) for item in entries if isinstance(item["id"], int | str)}


def test_catalog_returns_joined_dataset(client) -> None:
    response = client.get("/catalog")
    assert response.status_code == 200
    payload = response.json()

    assert response.headers.get("cache-control") == "public, max-age=3600"

    assert payload["phase_order"] == PHASE_ORDER
    layers = payload["layers"]
    assert len(layers) == EXPECTED_LAYER_COUNT

    beige = next(layer for layer in layers if layer["id"] == 1)
    assert beige["color"] == "Beige"

    phase_names = [phase["name"] for phase in beige["phases"]]
    assert phase_names == PHASE_ORDER

    rising = next(phase for phase in beige["phases"] if phase["name"] == "Rising")

    medicinal_ids = _flatten(rising["medicinal"])
    toxic_ids = _flatten(rising["toxic"])
    assert medicinal_ids
    assert toxic_ids

    assert rising["medicinal"][0]["dosage"] == "Medicinal"
    assert rising["toxic"][0]["dosage"] == "Toxic"

    strategy_names = {item["strategy"] for item in rising["strategies"]}
    assert "Cold Shower" in strategy_names


def test_catalog_identifiers_can_be_used_for_journaling(client) -> None:
    catalog = client.get("/catalog")
    assert catalog.status_code == 200
    body = catalog.json()

    beige = next(layer for layer in body["layers"] if layer["id"] == 1)
    rising = next(phase for phase in beige["phases"] if phase["name"] == "Rising")

    curriculum_id = int(rising["medicinal"][0]["id"])
    toxic_id = int(rising["toxic"][0]["id"])
    strategy_id = int(rising["strategies"][0]["id"])

    payload = {
        "created_at": "2025-10-01T00:00:00Z",
        "user_id": 1234,
        "curriculum_id": curriculum_id,
        "secondary_curriculum_id": toxic_id,
        "strategy_id": strategy_id,
    }

    created = client.post("/journal", json=payload)
    assert created.status_code == 201
    created_body = created.json()
    assert created_body["curriculum"]["id"] == curriculum_id
    assert created_body["secondary_curriculum"]["id"] == toxic_id
    assert created_body["strategy"]["id"] == strategy_id


def test_catalog_returns_empty_payload_when_database_cleared(client) -> None:
    """The endpoint should gracefully handle an empty catalog."""

    with Session(database.engine) as session:
        session.execute(delete(Journal))
        session.execute(delete(Strategy))
        session.execute(delete(Curriculum))
        session.execute(delete(Layer))
        session.execute(delete(Phase))
        session.commit()

    response = client.get("/catalog")
    assert response.status_code == 200
    assert response.json() == {"phase_order": [], "layers": []}

    with Session(database.engine) as session:
        seed_database(session)
