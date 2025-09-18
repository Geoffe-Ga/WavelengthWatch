"""Service helpers for assembling the catalog payload."""

from __future__ import annotations

from typing import cast

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


def _require_identifier(entity: str, value: int | None) -> int:
    """Ensure primary keys are present in seeded reference data."""

    if value is None:
        msg = f"{entity} rows must have an identifier"
        raise ValueError(msg)
    return value


def build_catalog(session: Session) -> CatalogResponse:
    """Load all catalog data and aggregate it for API consumers."""

    phase_rows = [
        (
            _require_identifier("Phase", phase.id),
            phase,
        )
        for phase in session.exec(
            select(Phase).order_by(cast(ColumnElement[int], Phase.id))
        ).all()
    ]
    phase_order = [phase.name for _, phase in phase_rows]
    phase_index = {phase_id: index for index, (phase_id, _) in enumerate(phase_rows)}

    layer_rows = [
        (
            _require_identifier("Layer", layer.id),
            layer,
        )
        for layer in session.exec(
            select(Layer).order_by(cast(ColumnElement[int], Layer.id))
        ).all()
    ]

    layer_map: dict[int, CatalogLayer] = {}
    for layer_id, layer_record in layer_rows:
        layer_map[layer_id] = CatalogLayer(
            id=layer_id,
            color=layer_record.color,
            title=layer_record.title,
            subtitle=layer_record.subtitle,
            phases=[
                CatalogPhase(
                    id=phase_id,
                    name=phase.name,
                    medicinal=[],
                    toxic=[],
                    strategies=[],
                )
                for phase_id, phase in phase_rows
            ],
        )

    curriculum_rows = session.exec(
        select(Curriculum).order_by(
            cast(ColumnElement[int], Curriculum.layer_id),
            cast(ColumnElement[int], Curriculum.phase_id),
            cast(ColumnElement[int], Curriculum.id),
        )
    ).all()
    for row in curriculum_rows:
        catalog_layer = layer_map.get(row.layer_id)
        if catalog_layer is None:
            continue
        index = phase_index.get(row.phase_id)
        if index is None:
            continue
        target_phase = catalog_layer.phases[index]
        entry = CatalogCurriculumEntry(
            id=_require_identifier("Curriculum", row.id),
            dosage=row.dosage,
            expression=row.expression,
        )
        if row.dosage == Dosage.MEDICINAL:
            target_phase.medicinal.append(entry)
        else:
            target_phase.toxic.append(entry)

    strategy_rows = session.exec(
        select(Strategy).order_by(
            cast(ColumnElement[int], Strategy.layer_id),
            cast(ColumnElement[int], Strategy.phase_id),
            cast(ColumnElement[int], Strategy.id),
        )
    ).all()
    for strategy in strategy_rows:
        catalog_layer = layer_map.get(strategy.layer_id)
        if catalog_layer is None:
            continue
        index = phase_index.get(strategy.phase_id)
        if index is None:
            continue
        catalog_layer.phases[index].strategies.append(
            CatalogStrategy(
                id=_require_identifier("Strategy", strategy.id),
                strategy=strategy.strategy,
            )
        )

    ordered_layers = [layer_map[layer_id] for layer_id, _ in layer_rows]
    return CatalogResponse(phase_order=phase_order, layers=ordered_layers)


__all__ = ["build_catalog"]
