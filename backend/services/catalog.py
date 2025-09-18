"""Service helpers for assembling the catalog payload."""

from __future__ import annotations

from typing import cast

from sqlalchemy.orm import selectinload
from sqlalchemy.sql.elements import ColumnElement
from sqlmodel import Session, select

from ..models import Curriculum, Dosage, Layer, Phase, Strategy
from ..schemas_catalog import (
    CatalogCurriculumEntry,
    CatalogLayer,
    CatalogPhase,
    CatalogResponse,
    CatalogStrategy,
)


class CatalogDataError(RuntimeError):
    """Raised when reference catalog records lack required identifiers."""


def _require_identifier(entity: str, value: int | None) -> int:
    """Ensure primary keys are present in seeded reference data."""

    if value is None:
        msg = f"{entity} rows must have a persisted identifier"
        raise CatalogDataError(msg)
    return value


def build_catalog(session: Session) -> CatalogResponse:
    """Load all catalog data and aggregate it for API consumers."""

    phase_template = [
        (
            _require_identifier("Phase", phase.id),
            phase.name,
        )
        for phase in session.exec(
            select(Phase).order_by(cast(ColumnElement[int], Phase.id))
        ).all()
    ]
    phase_order = [name for _, name in phase_template]
    phase_index = {phase_id: index for index, (phase_id, _) in enumerate(phase_template)}

    layers = (
        session.exec(
            select(Layer)
            .options(
                selectinload(Layer.curriculum_items).selectinload(Curriculum.phase),
                selectinload(Layer.strategies).selectinload(Strategy.phase),
            )
            .order_by(cast(ColumnElement[int], Layer.id))
        )
        .unique()
        .all()
    )

    ordered_layers: list[CatalogLayer] = []
    for layer in layers:
        layer_id = _require_identifier("Layer", layer.id)
        catalog_phases = [
            CatalogPhase(
                id=phase_id,
                name=name,
                medicinal=[],
                toxic=[],
                strategies=[],
            )
            for phase_id, name in phase_template
        ]
        catalog_layer = CatalogLayer(
            id=layer_id,
            color=layer.color,
            title=layer.title,
            subtitle=layer.subtitle,
            phases=catalog_phases,
        )

        for curriculum in sorted(
            layer.curriculum_items,
            key=lambda item: (
                phase_index.get(item.phase_id, float("inf")),
                _require_identifier("Curriculum", item.id),
            ),
        ):
            phase_id = curriculum.phase_id
            if phase_id is None:
                continue
            index = phase_index.get(phase_id)
            if index is None or index >= len(catalog_layer.phases):
                continue
            catalog_phase = catalog_layer.phases[index]
            entry = CatalogCurriculumEntry(
                id=_require_identifier("Curriculum", curriculum.id),
                dosage=curriculum.dosage,
                expression=curriculum.expression,
            )
            if curriculum.dosage == Dosage.MEDICINAL:
                catalog_phase.medicinal.append(entry)
            else:
                catalog_phase.toxic.append(entry)

        for strategy in sorted(
            layer.strategies,
            key=lambda item: (
                phase_index.get(item.phase_id, float("inf")),
                _require_identifier("Strategy", item.id),
            ),
        ):
            phase_id = strategy.phase_id
            if phase_id is None:
                continue
            index = phase_index.get(phase_id)
            if index is None or index >= len(catalog_layer.phases):
                continue
            catalog_layer.phases[index].strategies.append(
                CatalogStrategy(
                    id=_require_identifier("Strategy", strategy.id),
                    strategy=strategy.strategy,
                )
            )

        ordered_layers.append(catalog_layer)

    return CatalogResponse(phase_order=phase_order, layers=ordered_layers)


__all__ = ["build_catalog", "CatalogDataError"]
