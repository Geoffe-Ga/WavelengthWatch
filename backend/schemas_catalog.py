"""Pydantic models for the aggregated catalog payload."""

from __future__ import annotations

from sqlmodel import SQLModel

from .models import Dosage


class CatalogStrategy(SQLModel):
    """Serializable representation of a strategy available in a phase."""

    id: int
    strategy: str
    color: str


class CatalogCurriculumEntry(SQLModel):
    """Serializable curriculum entry containing dosage metadata."""

    id: int
    dosage: Dosage
    expression: str


class CatalogPhase(SQLModel):
    """Aggregated view of curriculum entries and strategies for a phase."""

    id: int
    name: str
    medicinal: list[CatalogCurriculumEntry]
    toxic: list[CatalogCurriculumEntry]
    strategies: list[CatalogStrategy]


class CatalogLayer(SQLModel):
    """Layer representation with ordered phases for client consumption."""

    id: int
    color: str
    title: str
    subtitle: str
    phases: list[CatalogPhase]


class CatalogResponse(SQLModel):
    """Top-level catalog payload delivered to clients."""

    phase_order: list[str]
    layers: list[CatalogLayer]


__all__ = [
    "CatalogCurriculumEntry",
    "CatalogLayer",
    "CatalogPhase",
    "CatalogResponse",
    "CatalogStrategy",
]
