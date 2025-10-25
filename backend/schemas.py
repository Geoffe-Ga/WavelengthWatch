"""Pydantic/SQLModel schemas for request and response bodies."""

from __future__ import annotations

from datetime import UTC, datetime

from pydantic import field_validator
from sqlmodel import Field, SQLModel

from .models import Dosage, InitiatedBy


def _coerce_datetime(value: datetime | str | None) -> datetime | None:
    """Parse strings into timezone-aware datetimes in UTC."""

    if value is None:
        return None
    if isinstance(value, str):
        value = datetime.fromisoformat(value.replace("Z", "+00:00"))
    if value.tzinfo is None:
        value = value.replace(tzinfo=UTC)
    return value.astimezone(UTC)


class LayerBase(SQLModel):
    color: str
    title: str
    subtitle: str


class LayerCreate(LayerBase):
    """Payload for creating layers."""


class LayerUpdate(SQLModel):
    color: str | None = None
    title: str | None = None
    subtitle: str | None = None


class LayerRead(LayerBase):
    id: int


class PhaseBase(SQLModel):
    name: str


class PhaseCreate(PhaseBase):
    """Payload for creating phases."""


class PhaseUpdate(SQLModel):
    name: str | None = None


class PhaseRead(PhaseBase):
    id: int


class CurriculumBase(SQLModel):
    layer_id: int
    phase_id: int
    dosage: Dosage
    expression: str


class CurriculumCreate(CurriculumBase):
    """Payload for creating curriculum rows."""


class CurriculumUpdate(SQLModel):
    layer_id: int | None = None
    phase_id: int | None = None
    dosage: Dosage | None = None
    expression: str | None = None


class CurriculumRead(CurriculumBase):
    id: int
    layer: LayerRead | None = None
    phase: PhaseRead | None = None


class StrategyBase(SQLModel):
    strategy: str
    layer_id: int
    color_layer_id: int
    phase_id: int


class StrategyCreate(StrategyBase):
    """Payload for creating strategies."""


class StrategyUpdate(SQLModel):
    strategy: str | None = None
    layer_id: int | None = None
    color_layer_id: int | None = None
    phase_id: int | None = None


class StrategyRead(StrategyBase):
    id: int
    layer: LayerRead | None = None
    color_layer: LayerRead | None = None
    phase: PhaseRead | None = None


class JournalBase(SQLModel):
    created_at: datetime = Field(default_factory=lambda: datetime.now(UTC))
    user_id: int
    curriculum_id: int
    secondary_curriculum_id: int | None = None
    strategy_id: int | None = None
    initiated_by: InitiatedBy = Field(default=InitiatedBy.SELF)

    @field_validator("created_at", mode="before")
    @classmethod
    def _validate_created_at(cls, value: datetime | str | None) -> datetime:
        parsed = _coerce_datetime(value)
        if parsed is None:
            raise ValueError("created_at is required")
        return parsed


class JournalCreate(JournalBase):
    """Payload for creating journals."""


class JournalUpdate(SQLModel):
    created_at: datetime | None = None
    user_id: int | None = None
    curriculum_id: int | None = None
    secondary_curriculum_id: int | None = None
    strategy_id: int | None = None
    initiated_by: InitiatedBy | None = None

    @field_validator("created_at", mode="before")
    @classmethod
    def _validate_created_at(cls, value: datetime | str | None) -> datetime | None:
        return _coerce_datetime(value)


class JournalRead(JournalBase):
    id: int
    curriculum: CurriculumRead | None = None
    secondary_curriculum: CurriculumRead | None = None
    strategy: StrategyRead | None = None
